import Foundation
import Testing
import Supabase
@testable import CupSeasonKit

/// D403 (review of a3115801) · a consent choice, and a scan, leave only as the golfer who
/// made them. The race lives in the SDK: the shared client resolves the CURRENT session's
/// token when a request is sent, and supabase-swift's adapter overwrites any
/// `Authorization` the caller set. These run the real supabase-swift request path against
/// a recording transport.
@Suite struct ConsentOwnershipTests {
  /// Records every request's Authorization; answers like PostgREST and the Edge function.
  final class Recorder: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var seen: [String] = []
    static let lock = NSLock()
    static func saw(_ value: String) -> Bool { lock.lock(); defer { lock.unlock() }; return seen.contains(value) }
    static func count(_ needle: String) -> Int { lock.lock(); defer { lock.unlock() }; return seen.filter { $0.contains(needle) }.count }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
      Self.lock.lock(); Self.seen.append(request.value(forHTTPHeaderField: "Authorization") ?? "-"); Self.lock.unlock()
      let rpc = request.url?.path.contains("/rest/v1/rpc/") == true
      let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1",
                                     headerFields: ["Content-Type": "application/json"])!
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: Data((rpc ? "true" : #"{"ok":false}"#).utf8))
      client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
  }
  private struct Memory: AuthLocalStorage {
    func store(key: String, value: Data) throws {}
    func retrieve(key: String) throws -> Data? { nil }
    func remove(key: String) throws {}
  }
  private struct Body: Encodable { let image = "AAAA"; let media_type = "image/jpeg" }
  private func transport() -> URLSession {
    let c = URLSessionConfiguration.ephemeral
    c.protocolClasses = [Recorder.self]
    return URLSession(configuration: c)
  }

  /// Why a3115801's phone scan bound nothing: an Authorization set by the caller is replaced
  /// with whoever's session the client resolves when the request is sent.
  @Test func theSharedClientSendsTheCurrentSessionWhateverTheCallerSet() async throws {
    let a = "A-\(UUID().uuidString)", b = "B-\(UUID().uuidString)"
    let shared = SupabaseClient(
      supabaseURL: URL(string: "http://127.0.0.1:54321")!, supabaseKey: "local-development-key",
      options: .init(auth: .init(storage: Memory(), autoRefreshToken: false, accessToken: { b }),   // B is signed in at send time
                     global: .init(session: transport())))
    let _: JSONValue = try await shared.functions.invoke("scan", options: .init(headers: ["Authorization": "Bearer \(a)"], body: Body()))
    #expect(Recorder.saw("Bearer \(b)"))
    #expect(!Recorder.saw("Bearer \(a)"))
  }

  /// The fix: a client bound to a golfer's token sends exactly that token, on the consent
  /// RPC and on the scan.
  @Test func aBoundClientSendsOnlyItsGolfersToken() async throws {
    let a = "A-\(UUID().uuidString)"
    let bound = SupabaseService.boundClient(token: a, transport: transport())
    let saved: Bool = try await bound.rpc(Rpc.set_scan_consent.name, params: Rpc.set_scan_consent(p_on: true)).execute().value
    #expect(saved)
    let _: JSONValue = try await bound.functions.invoke("scan", options: .init(body: Body()))
    #expect(Recorder.count(a) == 2)
    #expect(Recorder.saw("Bearer \(a)"))
  }

  /// The consent write resolves the CHOOSING golfer's token when it is sent: an account
  /// change before that sends nothing; after it, the write still carries that golfer's token.
  @Test func aConsentWriteIsSentAsTheGolferWhoChoseOrNotAtAll() async throws {
    let a = UUID(), b = UUID()
    final class World: @unchecked Sendable {
      let lock = NSLock()
      var signedIn: UUID?
      var sent: [String] = []
      var holding = false
      var hold: CheckedContinuation<Void, Never>?
      func with<T>(_ f: (World) -> T) -> T { lock.lock(); defer { lock.unlock() }; return f(self) }
    }
    let w = World()
    w.with { $0.signedIn = a; $0.holding = true }
    let write = ScanConsentStore.boundWrite(
      tokenOf: { owner in
        if w.with({ $0.holding }) { await withCheckedContinuation { c in w.with { $0.hold = c } } }
        return w.with { $0.signedIn == owner ? "token-\(owner)" : nil }
      },
      send: { on, token in w.with { $0.sent.append(token) }; return on })

    // the account changes while A's write resolves its token: nothing is sent
    let first = Task { try await write(true, a) }
    while w.with({ $0.hold == nil }) { await Task.yield() }
    w.with { $0.signedIn = b; $0.holding = false }
    w.with { $0.hold }?.resume()
    await #expect(throws: ScanConsentStore.NotTheirs.self) { _ = try await first.value }
    #expect(w.with { $0.sent }.isEmpty)

    // A's token resolved while A is signed in: the write carries it
    w.with { $0.signedIn = a }
    #expect(try await write(false, a) == false)
    #expect(w.with { $0.sent } == ["token-\(a)"])
  }
}
