import Foundation
import Supabase

/// Profile metadata is authoritative: an old storage object is not a profile photo.
public enum ProfilePhotoResult: Sendable, Equatable {
  case photo(URL), noPhoto, unavailable
}

/// Shared, account-scoped lookup for avatars on every native surface. Visible
/// faces batch their reads; guests never ask this store for a profile.
public actor ProfilePhotos {
  public static let shared = ProfilePhotos()
  typealias Loader = @Sendable ([UUID]) async -> [UUID: ProfilePhotoResult]
  private struct Entry { let result: ProfilePhotoResult; let expires: Date }
  private var owner: UUID?
  private var epoch = 0
  private var entries: [UUID: Entry] = [:]
  private var waiting: [UUID: [CheckedContinuation<ProfilePhotoResult, Never>]] = [:]
  private var inFlight: Set<UUID> = []
  private var scheduled = false
  private let load: Loader
  private let now: @Sendable () -> Date
  private let delay: Duration

  public init() {
    load = Self.fetch; now = Date.init; delay = .milliseconds(20)
  }
  init(load: @escaping Loader, now: @escaping @Sendable () -> Date = Date.init,
       delay: Duration = .milliseconds(20)) {
    self.load = load; self.now = now; self.delay = delay
  }

  /// Only the composition root changes ownership. An old view cannot claim an
  /// old account again after sign-out or a switch.
  public func claim(_ next: UUID?) {
    guard next != owner else { return }
    owner = next; entries = [:]; resetRequests()
  }

  public func photo(_ id: UUID, owner caller: UUID?) async -> ProfilePhotoResult {
    guard let caller, caller == owner else { return .unavailable }
    if let entry = entries[id], entry.expires > now() { return entry.result }
    return await withCheckedContinuation { continuation in
      waiting[id, default: []].append(continuation)
      guard !inFlight.contains(id), !scheduled else { return }
      scheduled = true
      let started = epoch
      Task {
        try? await Task.sleep(for: delay)
        await flush(started)
      }
    }
  }

  public func invalidate(_ id: UUID) {
    if case .photo(let url) = entries[id]?.result {
      URLCache.shared.removeCachedResponse(for: URLRequest(url: url))
    }
    entries[id] = nil
    resetRequests()
  }

  private func resetRequests() {
    epoch += 1; scheduled = false; inFlight = []
    let pending = waiting; waiting = [:]
    for continuations in pending.values {
      for continuation in continuations { continuation.resume(returning: .unavailable) }
    }
  }

  private func flush(_ started: Int) async {
    guard started == epoch else { return }
    scheduled = false
    let ids = waiting.keys.filter { !inFlight.contains($0) }
    guard !ids.isEmpty else { return }
    inFlight.formUnion(ids)
    let fresh = await load(Array(ids))
    guard started == epoch else { return }
    for id in ids {
      let result = fresh[id] ?? .unavailable
      let ttl: TimeInterval
      switch result { case .photo: ttl = 300; case .noPhoto: ttl = 60; case .unavailable: ttl = 10 }
      entries[id] = Entry(result: result, expires: now().addingTimeInterval(ttl))
      inFlight.remove(id)
      for continuation in waiting.removeValue(forKey: id) ?? [] {
        continuation.resume(returning: result)
      }
    }
  }

  private struct Row: Decodable { let id: UUID; let photo_path: String? }
  private static func fetch(_ ids: [UUID]) async -> [UUID: ProfilePhotoResult] {
    let svc = SupabaseService.shared
    var result: [UUID: ProfilePhotoResult] = [:]
    // Bound PostgREST URLs even when a large roster becomes visible together.
    for start in stride(from: 0, to: ids.count, by: 100) {
      let batch = Array(ids[start..<min(start + 100, ids.count)])
      do {
        let rows: [Row] = try await svc.client.from("profiles").select("id, photo_path")
          .in("id", values: batch).execute().value
        // Metadata stays authoritative even if signing another person's photo fails.
        for id in batch { result[id] = .noPhoto }
        for row in rows where !(row.photo_path ?? "").isEmpty { result[row.id] = .unavailable }
        let paths = Array(Set(rows.compactMap(\.photo_path).filter { !$0.isEmpty }))
        var urls: [String: URL] = [:]
        if !paths.isEmpty {
          let signed = (try? await svc.client.storage.from("media").createSignedURLs(paths: paths, expiresIn: 3600)) ?? []
          urls = Dictionary(signed.filter { $0.error == nil }.compactMap { row in
            row.signedURL.map { (row.path, $0) }
          }, uniquingKeysWith: { _, last in last })
        }
        for row in rows {
          guard let path = row.photo_path, !path.isEmpty else { continue }
          result[row.id] = urls[path].map(ProfilePhotoResult.photo) ?? .unavailable
        }
      } catch {
        for id in batch { result[id] = .unavailable }
      }
    }
    return result
  }
}

public extension Notification.Name {
  static let csProfilePhotoChanged = Notification.Name("csProfilePhotoChanged")
}
