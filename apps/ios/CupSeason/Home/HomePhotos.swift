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

  private(set) var states: [String: State] = [:]
  private var tasks: [String: Task<Void, Never>] = [:]
  private var urls: [String: URL] = [:]
  /// counts, for the tests and the probe: how many fetches actually went out
  private(set) var fetches = 0
  private let fetch: Fetcher
  private let maxPixel: Int

  init(fetch: Fetcher? = nil, maxPixel: Int = 1400) {
    self.fetch = fetch ?? HomePhotoStore.networkFetch
    self.maxPixel = maxPixel
  }

  func state(for path: String?) -> State {
    guard let path, !path.isEmpty else { return .none }
    return states[path] ?? .none
  }

  /// Bring one round's photograph up to date. Called by the band when it
  /// appears and whenever its URL changes. A URL the store has already loaded
  /// is not fetched again — returning Home reuses what it has.
  func load(path: String?, url: URL?) {
    guard let path, !path.isEmpty else { return }
    guard let url else {
      // the row says there is an attachment but nothing could sign it: gone,
      // or not ours any more. A picture from a previous session's grant does
      // not stay up on a credential that no longer exists.
      cancel(path); states[path] = .removed; urls[path] = nil
      return
    }
    if urls[path] == url, let s = states[path], !s.isLoading, s.image != nil { return }
    if urls[path] == url, tasks[path] != nil { return }
    if urls[path] == url, case .removed = states[path] { return }   // gone is gone until the URL changes
    if urls[path] == url, case .failed = states[path] { return }    // a miss is retried by the next load's URL, not by every appearance
    cancel(path)
    urls[path] = url
    let prior = states[path]?.image
    states[path] = .loading(prior: prior)
    fetches += 1
    let fetch = self.fetch, maxPixel = self.maxPixel
    tasks[path] = Task { [weak self] in
      let outcome = await fetch(url)
      guard !Task.isCancelled, let self else { return }
      guard self.urls[path] == url else { return }   // superseded by a newer URL
      switch outcome {
      case .data(let d):
        if let img = await Self.decode(d, maxPixel: maxPixel) { self.states[path] = .loaded(img) }
        else { self.states[path] = .failed(prior: prior) }
      case .transient:
        self.states[path] = .failed(prior: prior)
      case .gone:
        self.states[path] = .removed
      }
      self.tasks[path] = nil
    }
  }

  /// A load told us which paths the wire holds now. Any path we remember that
  /// the wire no longer carries is a photograph that was removed or replaced.
  func reconcile(paths present: [String]) {
    let keep = Set(present)
    for p in states.keys where !keep.contains(p) { cancel(p); states[p] = nil; urls[p] = nil }
  }

  /// Sign-out or an account change: nothing survives.
  func clear() {
    for p in tasks.keys { cancel(p) }
    states.removeAll(); urls.removeAll()
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
