// Cup Season — a signed URL is a fetch credential, not an identity (D361).
//
// Every Home load signed the circle's photo paths again, and a signed URL
// carries a fresh token every time — so the URL string changed on every
// refresh, `AsyncImage(url:)` saw a new identity, threw the picture it had
// away and started over, and `URLCache` never once matched because no two
// loads ever asked for the same URL. That is the whole mechanism behind "the
// photo disappears": the object never moved, the credential did.
//
// This keeps a signed URL for as long as it is good. A path is re-signed only
// when its URL is within five minutes of expiry, so a refresh, a returning
// tab and a scroll all ask for the same bytes at the same URL, and the
// system's own HTTP cache — which the storage responses already permit with a
// `Cache-Control: max-age` — answers without a download.
//
// Sign-out clears it, because a credential outlives its session only as a
// leak. A path that stops being signable (removed, or access withdrawn) is
// simply not returned, and the caller reads that absence as what it is.

import Foundation

public actor SignedURLCache {
  public static let shared = SignedURLCache()

  public struct Entry: Sendable { public let url: URL; public let expires: Date }
  /// What signing one path said. `denied` is the storage's own refusal (4xx —
  /// gone, or not ours); `unavailable` is everything else (offline, 5xx, a
  /// timeout) and says nothing about the object.
  public enum Outcome: Sendable, Equatable { case url(URL), denied, unavailable }
  public struct Resolution: Sendable {
    public var urls: [String: URL] = [:]
    public var denied: Set<String> = []
    /// paths that could not be signed this time for a reason that is not the object's
    public var unavailable: Set<String> = []
  }
  private var entries: [String: Entry] = [:]
  /// bumped by `clear()`: a signing call that started under an older epoch may
  /// not write its answers into a cache that has since been cleared for a new
  /// account (Codex, 2026-09-14)
  private var epoch = 0
  /// re-sign this close to expiry rather than serve a URL about to go stale
  private let margin: TimeInterval = 300

  public init() {}

  /// The full answer: URLs for what is cached or newly signed, the paths the
  /// storage refused, and the paths that could not be reached. The caller
  /// decides what each means for a picture already on screen.
  public func resolve(_ paths: [String], expiresIn: Int = 3600,
                      sign: ([String]) async -> [String: Outcome]) async -> Resolution {
    let now = Date()
    var out = Resolution()
    var missing: [String] = []
    for p in Set(paths.filter { !$0.isEmpty }) {
      if let e = entries[p], e.expires.timeIntervalSince(now) > margin { out.urls[p] = e.url } else { missing.append(p) }
    }
    if !missing.isEmpty {
      let started = epoch
      let fresh = await sign(missing.sorted())
      let expires = now.addingTimeInterval(TimeInterval(expiresIn))
      for (p, o) in fresh {
        switch o {
        case .url(let u):
          if epoch == started { entries[p] = Entry(url: u, expires: expires) }
          out.urls[p] = u
        case .denied: out.denied.insert(p); entries[p] = nil
        case .unavailable: out.unavailable.insert(p)
        }
      }
      for p in missing where fresh[p] == nil { out.unavailable.insert(p) }
    }
    return out
  }

  /// The URLs for `paths`: unexpired ones from the cache, the rest signed in
  /// ONE call through `sign`, which returns path ⇒ URL for what it could sign.
  public func urls(for paths: [String], expiresIn: Int = 3600,
                   sign: ([String]) async -> [String: URL]) async -> [String: URL] {
    let now = Date()
    var out: [String: URL] = [:]
    var missing: [String] = []
    for p in Set(paths.filter { !$0.isEmpty }) {
      if let e = entries[p], e.expires.timeIntervalSince(now) > margin { out[p] = e.url } else { missing.append(p) }
    }
    if !missing.isEmpty {
      let fresh = await sign(missing.sorted())
      let expires = now.addingTimeInterval(TimeInterval(expiresIn))
      for (p, u) in fresh { entries[p] = Entry(url: u, expires: expires); out[p] = u }
    }
    return out
  }

  /// Forget one path — a photograph replaced or removed gets a new credential
  /// next time, never the old object from the cache.
  public func forget(_ path: String) { entries[path] = nil }

  /// Sign-out, or an account change: nothing signed for the last session
  /// may answer for the next — including a signing call still in flight.
  public func clear() { entries.removeAll(); epoch += 1 }

  /// For tests and the probe: how many paths are currently held.
  public var count: Int { entries.count }
}
