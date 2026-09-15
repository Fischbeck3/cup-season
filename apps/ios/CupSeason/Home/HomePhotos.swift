// Cup Season — each Home round owns its photograph's state (D361).
//
// The owner's case: two adjacent photo rounds, and loading one removed the
// other. `AsyncImage(url:)` was the picture's only memory, and it forgot on
// any change of URL — which every refresh caused, because a signed URL is
// minted fresh each load — and on any transient failure, which it rendered as
// "no photograph" (the record slat) in place of a picture it had already shown.
//
// This is the memory. It is keyed by the round's `photo_path` — the object's
// identity — and never by the URL, which is only how the object is fetched
// today. Five states, and the difference between them is the whole point:
//
//   none        the round has no attachment                → the record
//   loading     fetching, with the LAST GOOD picture kept   → that picture, or
//               the band's frame with score and course if there never was one
//   loaded      the picture                                 → the band
//   failed      a transient miss, the last good picture kept → that picture,
//               or the record if there never was one
//   removed     the attachment is gone or access withdrawn → the record
//
// "Loading another image never removes an already displayed photograph" is a
// consequence of the shape: a round's entry is touched only by its own path.
// Decoding is downsampled at the source (ImageIO thumbnail at 1400px on the
// long side — twice the band's width on a 3× phone), so a 12MP upload never
// becomes a 48MB bitmap on a scroll.

import SwiftUI
import UIKit
import ImageIO
import CupSeasonKit

@MainActor @Observable
final class HomePhotoStore {
  /// One memory for the app's Home, so leaving the tab and coming back finds
  /// the pictures where they were — nothing is reloaded that has not changed.
  static let shared = HomePhotoStore()

  enum State: Equatable {
    case none
    case loading(prior: UIImage?)
    case loaded(UIImage)
    case failed(prior: UIImage?)
    case removed

    var image: UIImage? {
      switch self {
      case .loaded(let i): return i
      case .loading(let p), .failed(let p): return p
      case .none, .removed: return nil
      }
    }
    var isLoading: Bool { if case .loading = self { return true } else { return false } }
  }

  /// What a fetch may say back: the bytes, a transient miss (network, 5xx,
  /// a timeout), or a definitive one (the object is gone or forbidden).
  enum Outcome { case data(Data), transient, gone }
  typealias Fetcher = @Sendable (URL) async -> Outcome
  typealias Decoder = @Sendable (Data, Int) async -> UIImage?

  /// What this load could say about a round's picture. A URL is a way to
  /// fetch it; `denied` is the storage's own refusal (gone, or not ours);
  /// `unavailable` is a credential this load could not get, which says nothing
  /// about the picture — a picture already up stays up (Codex, 2026-09-14).
  enum Credential: Equatable { case url(URL), denied, unavailable }

  private(set) var states: [String: State] = [:]
  private var tasks: [String: Task<Void, Never>] = [:]
  private var urls: [String: URL] = [:]
  /// bounded recovery for a URL that missed: how many times, and not before when
  private var attempts: [String: Int] = [:]
  private var retryAfter: [String: Date] = [:]
  /// bumped by `clear` and `reconcile`: a decode that finishes after either
  /// may not write into state that has moved on
  private var generation = 0
  /// counts, for the tests and the probe: how many fetches actually went out
  private(set) var fetches = 0
  private let fetch: Fetcher
  private let decoder: Decoder
  private let maxPixel: Int
  /// 2 s, 8 s, 30 s — then nothing until a new credential or a pull
  static let backoff: [TimeInterval] = [2, 8, 30]

  init(fetch: Fetcher? = nil, decode: Decoder? = nil, maxPixel: Int = 1400) {
    self.fetch = fetch ?? HomePhotoStore.networkFetch
    self.decoder = decode ?? { data, px in await HomePhotoStore.decode(data, maxPixel: px) }
    self.maxPixel = maxPixel
  }

  func state(for path: String?) -> State {
    guard let path, !path.isEmpty else { return .none }
    return states[path] ?? .none
  }

  /// Bring one round's photograph up to date. Called by the band when it
  /// appears and whenever its URL changes. A URL the store has already loaded
  /// is not fetched again — returning Home reuses what it has.
  /// The convenience the fixture and the tests use: a URL, or nothing to sign.
  func load(path: String?, url: URL?) {
    load(path: path, credential: url.map { .url($0) } ?? .unavailable)
  }

  /// Bring one round's photograph up to date. Called by the band when it
  /// appears and whenever its credential changes. A URL the store has already
  /// loaded is not fetched again — returning Home reuses what it has.
  func load(path: String?, credential: Credential) {
    guard let path, !path.isEmpty else { return }
    switch credential {
    case .denied:
      // the storage's own answer: gone, or not ours any more. A picture from a
      // previous grant does not stay up on a credential that no longer exists.
      cancel(path); states[path] = .removed; urls[path] = nil; attempts[path] = nil
      return
    case .unavailable:
      // no credential THIS time — a temporary condition, never a verdict on
      // the picture. What is up stays up; what was never up is a miss that the
      // next load's credential retries.
      if tasks[path] != nil { return }
      let prior = states[path]?.image
      if case .removed = states[path] { return }
      states[path] = .failed(prior: prior)
      return
    case .url(let url):
      if urls[path] == url, let s = states[path], !s.isLoading, s.image != nil { return }
      if urls[path] == url, tasks[path] != nil { return }
      if urls[path] == url, case .removed = states[path] { return }   // gone is gone until the credential changes
      if urls[path] == url, case .failed = states[path] {
        // bounded recovery on the same URL: not on every appearance, not forever
        let n = attempts[path] ?? 0
        guard n < Self.backoff.count, Date() >= (retryAfter[path] ?? .distantPast) else { return }
      }
      if urls[path] != url { attempts[path] = nil; retryAfter[path] = nil }
      start(path: path, url: url)
    }
  }

  private func start(path: String, url: URL) {
    cancel(path)
    urls[path] = url
    let prior = states[path]?.image
    states[path] = .loading(prior: prior)
    fetches += 1
    let fetch = self.fetch, decoder = self.decoder, maxPixel = self.maxPixel
    let gen = generation
    tasks[path] = Task { [weak self] in
      let outcome = await fetch(url)
      guard !Task.isCancelled, let self, self.generation == gen, self.urls[path] == url else { return }
      switch outcome {
      case .data(let d):
        let img = await decoder(d, maxPixel)
        // checked AGAIN after the decode: the state may have been cleared, the
        // path dropped, or a newer credential started while the bytes decoded
        guard !Task.isCancelled, self.generation == gen, self.urls[path] == url else { return }
        if let img { self.states[path] = .loaded(img); self.attempts[path] = nil; self.retryAfter[path] = nil }
        else { self.miss(path, prior: prior) }
      case .transient:
        self.miss(path, prior: prior)
      case .gone:
        self.states[path] = .removed
      }
      self.tasks[path] = nil
    }
  }

  private func miss(_ path: String, prior: UIImage?) {
    states[path] = .failed(prior: prior)
    let n = (attempts[path] ?? 0) + 1
    attempts[path] = n
    retryAfter[path] = Date().addingTimeInterval(Self.backoff[min(n, Self.backoff.count) - 1])
  }

  /// A pull-to-refresh: every miss tries again now, on the credential it has.
  /// The band's `.task(id:)` does not re-fire for an unchanged credential, so
  /// the store restarts the misses itself rather than waiting to be asked.
  func retryMisses() {
    attempts.removeAll(); retryAfter.removeAll()
    for (path, state) in states {
      if case .failed = state, tasks[path] == nil, let url = urls[path] { start(path: path, url: url) }
    }
  }

  /// A load told us which paths the wire holds now. Any path we remember that
  /// the wire no longer carries is a photograph that was removed or replaced.
  func reconcile(paths present: [String]) {
    let keep = Set(present)
    var dropped = false
    for p in states.keys where !keep.contains(p) { cancel(p); states[p] = nil; urls[p] = nil; attempts[p] = nil; dropped = true }
    if dropped { generation += 1 }
  }

  /// Sign-out or an account change: nothing survives, and nothing in flight
  /// may land afterwards.
  func clear() {
    for p in tasks.keys { cancel(p) }
    states.removeAll(); urls.removeAll(); attempts.removeAll(); retryAfter.removeAll()
    generation += 1
  }

  private func cancel(_ path: String) { tasks[path]?.cancel(); tasks[path] = nil }

  // MARK: - the network, and the decode

  private static let networkFetch: Fetcher = { url in
    do {
      // the storage responses carry no Cache-Control (measured 2026-09-14), so
      // the HTTP cache is asked explicitly before the network is
      let (data, resp) = try await URLSession.shared.data(for: URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad))
      guard let http = resp as? HTTPURLResponse else { return .data(data) }
      switch http.statusCode {
      case 200..<300: return .data(data)
      case 400, 401, 403, 404, 410: return .gone
      default: return .transient
      }
    } catch { return .transient }
  }

  nonisolated static func decode(_ data: Data, maxPixel: Int) async -> UIImage? {
    await Task.detached(priority: .userInitiated) {
      guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
      let opts: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceShouldCacheImmediately: true,
      ]
      guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
      return UIImage(cgImage: cg)
    }.value
  }
}
