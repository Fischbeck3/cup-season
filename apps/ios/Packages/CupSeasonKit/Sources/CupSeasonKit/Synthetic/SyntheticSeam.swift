// Cup Season — `-cs_dev_synthetic <scenario>`: the fixture SEAM, and only the
// seam (the 10/10 program's S2/C3 lane, 2026-09-28).
//
// WHY IT EXISTS. Every signed-in screen sits behind `store.me != nil`, and the
// only way to reach one was a real account. Real accounts are real golfers, so
// the review could photograph none of it. This seam lets a DEBUG simulator
// build run the REAL SessionStore, repositories and decoders against invented
// data: a synthetic session sits in an in-memory auth store, and every request
// the Supabase clients (and `URLSession.shared`, which loads photographs) make
// is answered on the device by a responder the app installs. The fixture data,
// the scenarios and the router live in the app target (`Dev/Synthetic/`).
//
// WHAT IT CANNOT DO, by construction:
//   · exist in Release — every line of this file is `#if DEBUG`, and the three
//     call sites (Config, SupabaseService) are inside `#if DEBUG` too;
//   · run on a phone — `scenario` is nil outside the simulator, so a DEBUG
//     build on a golfer's device can never wipe or impersonate anything;
//   · reach a network — the base URL is an `.invalid` host (RFC 6761), the
//     transport answers every request in-process, and an unanswered request
//     FAILS LOUDLY in the log rather than falling through;
//   · touch a real session — the Keychain storage is never constructed in
//     synthetic mode; the synthetic session lives in memory and dies with it.

#if DEBUG
import Foundation
import Supabase

public enum SyntheticSeam {
  /// The scenario named after `-cs_dev_synthetic`, on a simulator only.
  public static let scenario: String? = {
    #if targetEnvironment(simulator)
    let a = ProcessInfo.processInfo.arguments
    guard let i = a.firstIndex(of: "-cs_dev_synthetic") else { return nil }
    let next = i + 1 < a.count ? a[i + 1] : ""
    return next.isEmpty || next.hasPrefix("-") ? "season-live" : next
    #else
    return nil
    #endif
  }()

  public static var on: Bool { scenario != nil }

  /// RFC 6761 reserves `.invalid`: nothing resolves it, so a request that ever
  /// escaped the transport would fail at DNS instead of reaching a backend.
  public static let supabaseURL = URL(string: "https://synthetic.cupseason.invalid")!
  public static let publishableKey = "sb_publishable_synthetic_fixture_only"

  /// The auth store the SDK reads in synthetic mode. Never the Keychain.
  public static let authStorage = SyntheticAuthStorage()

  // MARK: the responder the app installs

  public typealias Responder = @Sendable (URLRequest, Data?) -> SyntheticReply
  private static let box = Locked<Responder?>(nil)

  /// Installed once by the app's composition root, before the first request.
  public static func install(_ responder: @escaping Responder) { box.set(responder) }
  static var responder: Responder? { box.get() }

  // MARK: a clean sandbox per launch

  private static let prepared = Locked(false)

  /// Every synthetic launch starts from the same on-device state: the app's
  /// own defaults, its App Group defaults and the files it keeps (course books,
  /// live and offline rounds, share artifacts, caches) are removed BEFORE any
  /// store reads them. Simulator only, because `scenario` is. Idempotent.
  public static func prepareSandboxOnce() {
    guard on, !prepared.get() else { return }
    prepared.set(true)
    if let bundle = Bundle.main.bundleIdentifier {
      UserDefaults.standard.removePersistentDomain(forName: bundle)
    }
    UserDefaults.standard.removePersistentDomain(forName: CSAppGroup.id)
    let fm = FileManager.default
    var dirs = [fm.temporaryDirectory]
    for d in [FileManager.SearchPathDirectory.documentDirectory, .applicationSupportDirectory, .cachesDirectory] {
      dirs += fm.urls(for: d, in: .userDomainMask)
    }
    for dir in dirs {
      for item in (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? [] where item.lastPathComponent != logURL.lastPathComponent {
        try? fm.removeItem(at: item)
      }
    }
    URLCache.shared.removeAllCachedResponses()
    URLProtocol.registerClass(SyntheticTransport.self)
    // The log is the one file that survives, so a runner can read every launch
    // of a batch; each launch opens with its own separator and arguments.
    log("=== launch \(ProcessInfo.processInfo.arguments.dropFirst().joined(separator: " "))")
    log("boot scenario=\(scenario ?? "-") sandbox=clean")
  }

  // MARK: the session

  /// Seeds the in-memory auth store with a session the SDK will emit as its
  /// initial session. The token is not a JWT and is never sent anywhere; the
  /// expiry is far enough out that the SDK never tries to refresh it.
  public static func seedSession(userId: UUID, email: String) {
    let now = Date()
    let user = User(id: userId, appMetadata: ["provider": "email"], userMetadata: [:], aud: "authenticated",
                    email: email, createdAt: now.addingTimeInterval(-86_400 * 200), confirmedAt: now,
                    emailConfirmedAt: now, lastSignInAt: now, role: "authenticated", updatedAt: now)
    let session = Session(accessToken: "synthetic-access-\(userId.uuidString.lowercased())", tokenType: "bearer",
                          expiresIn: 86_400 * 365, expiresAt: now.addingTimeInterval(86_400 * 365).timeIntervalSince1970,
                          refreshToken: "synthetic-refresh", user: user)
    authStorage.seed(session)
  }

  // MARK: the log

  private static let logURL = FileManager.default.temporaryDirectory.appendingPathComponent("cs-synthetic.log")
  private static let logLock = NSLock()

  /// One line per event, to stdout (`simctl launch --console`) and to
  /// `tmp/cs-synthetic.log` in the app's container (the capture runner and the
  /// UI tests read it). A fixture gap prints `MISS`, never a silent empty.
  public static func log(_ line: String) {
    let stamped = "[cs-synth] \(line)"
    print(stamped)
    logLock.lock(); defer { logLock.unlock() }
    let data = Data((stamped + "\n").utf8)
    if let h = try? FileHandle(forWritingTo: logURL) {
      h.seekToEndOfFile(); h.write(data); try? h.close()
    } else {
      try? data.write(to: logURL)
    }
  }
}

/// What the responder answers: a status, headers and a body — or a transport
/// error (`offline`), optionally after a delay (the loading geometry).
public struct SyntheticReply: Sendable {
  public var status: Int
  public var headers: [String: String]
  public var body: Data
  public var error: URLError.Code?
  public var delay: TimeInterval

  public init(status: Int = 200, headers: [String: String] = ["Content-Type": "application/json"],
              body: Data = Data(), error: URLError.Code? = nil, delay: TimeInterval = 0) {
    self.status = status; self.headers = headers; self.body = body; self.error = error; self.delay = delay
  }
}

/// The in-process transport. Installed on the tuned session's configuration and
/// registered for `URLSession.shared`, so REST, RPC, storage, functions, auth
/// and every photograph `AsyncImage` loads are all answered here.
public final class SyntheticTransport: URLProtocol {
  private let cancelled = Locked(false)

  public override class func canInit(with request: URLRequest) -> Bool {
    guard SyntheticSeam.on, let scheme = request.url?.scheme else { return false }
    return scheme == "https" || scheme == "http"
  }
  public override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  public override func startLoading() {
    let request = self.request
    let body = Self.body(of: request)
    guard let responder = SyntheticSeam.responder else {
      SyntheticSeam.log("MISS no-responder \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "-")")
      client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
      return
    }
    let reply = responder(request, body)
    // URLProtocol is not Sendable; the client callbacks are made from the
    // delivery closure exactly as a real protocol makes them from its queue.
    nonisolated(unsafe) let this = self
    let deliver: @Sendable () -> Void = { this.deliver(reply, for: request) }
    if reply.delay > 0 {
      DispatchQueue.global().asyncAfter(deadline: .now() + reply.delay, execute: deliver)
    } else {
      deliver()
    }
  }

  private func deliver(_ reply: SyntheticReply, for request: URLRequest) {
    guard !cancelled.get() else { return }
    if let code = reply.error {
      client?.urlProtocol(self, didFailWithError: URLError(code))
      return
    }
    guard let url = request.url,
          let response = HTTPURLResponse(url: url, statusCode: reply.status, httpVersion: "HTTP/1.1", headerFields: reply.headers)
    else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    if !reply.body.isEmpty { client?.urlProtocol(self, didLoad: reply.body) }
    client?.urlProtocolDidFinishLoading(self)
  }

  public override func stopLoading() { cancelled.set(true) }

  /// URLSession hands a protocol its body as a STREAM, never `httpBody`.
  private static func body(of request: URLRequest) -> Data? {
    if let b = request.httpBody { return b }
    guard let stream = request.httpBodyStream else { return nil }
    stream.open(); defer { stream.close() }
    var out = Data()
    var buffer = [UInt8](repeating: 0, count: 16_384)
    while stream.hasBytesAvailable {
      let n = stream.read(&buffer, maxLength: buffer.count)
      if n <= 0 { break }
      out.append(buffer, count: n)
    }
    return out
  }
}

/// The SDK's local storage, in memory. `seed` is the whole of sign-in.
public final class SyntheticAuthStorage: AuthLocalStorage, @unchecked Sendable {
  private let lock = NSLock()
  private var store: [String: Data] = [:]
  private var seeded: Data?

  func seed(_ session: Session) {
    lock.lock(); defer { lock.unlock() }
    seeded = try? JSONEncoder().encode(session)
  }

  public func store(key: String, value: Data) throws { lock.lock(); defer { lock.unlock() }; store[key] = value }
  public func retrieve(key: String) throws -> Data? {
    lock.lock(); defer { lock.unlock() }
    if let v = store[key] { return v }
    // The SDK asks for its session under `sb-<ref>-auth-token`; the seed is
    // that session and nothing else (no code verifier, no legacy key).
    return key.hasSuffix("-auth-token") ? seeded : nil
  }
  public func remove(key: String) throws {
    lock.lock(); defer { lock.unlock() }
    store[key] = nil
    if key.hasSuffix("-auth-token") { seeded = nil }
  }
}

/// A value behind a lock — the seam's only shared state.
final class Locked<T>: @unchecked Sendable {
  private let lock = NSLock()
  private var value: T
  init(_ value: T) { self.value = value }
  func get() -> T { lock.lock(); defer { lock.unlock() }; return value }
  func set(_ v: T) { lock.lock(); defer { lock.unlock() }; value = v }
}
#endif
