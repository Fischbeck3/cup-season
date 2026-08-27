// Cup Season — the one Supabase service (IOS-002 §12).
//
// Two clients, deliberately:
//   `client`   auth + PostgREST + storage. Session in the Keychain (the SDK's
//              default on iOS), auto-refresh bound to the app lifecycle by the
//              SDK.
//   `realtime` a DEDICATED client for channels. The landmine (CLAUDE.md):
//              channel joins on the busy client fail with CHANNEL_ERROR /
//              transport failure — verified with a raw socket and a fresh
//              client on the same machine and token. Not used until M1; its
//              token is forwarded on every auth change from day one so the
//              rule cannot be forgotten later.
//
// `call(_:)` is the RPC path, and it encodes the deploy-skew rule that cost a
// boot on the web: retry on ANY error by dropping the optional args, never on
// the message (the `photo_path` 42501 never named its column). A second
// failure is real and is thrown with what was dropped.

import Foundation
import Supabase

public struct RpcError: LocalizedError, Sendable {
  public let name: String
  public let underlying: String
  public let droppedArgs: [String]
  public var errorDescription: String? { "\(name): \(underlying)" }
  /// PostgREST's "function not found in schema cache" / 42883 — the phone is
  /// ahead of the database (a migration not yet pushed). Callers may fall back.
  public var isMissingFunction: Bool {
    let s = underlying.lowercased()
    return s.contains("schema cache") || s.contains("42883") || s.contains("pgrst202") || s.contains("could not find the function")
  }
}

public final class SupabaseService: Sendable {
  public static let shared = SupabaseService()

  public let client: SupabaseClient
  public let realtime: SupabaseClient

  private init() {
    client = SupabaseClient(
      supabaseURL: CSConfig.supabaseURL,
      supabaseKey: CSConfig.supabasePublishableKey,
      options: SupabaseClientOptions(
        auth: .init(flowType: .implicit, emitLocalSessionAsInitialSession: true),
        global: .init(headers: ["x-client-info": "cupseason-ios"])
      )
    )
    realtime = SupabaseClient(
      supabaseURL: CSConfig.supabaseURL,
      supabaseKey: CSConfig.supabasePublishableKey,
      options: SupabaseClientOptions(
        auth: .init(storage: EphemeralStorage(), autoRefreshToken: false),
        global: .init(headers: ["x-client-info": "cupseason-ios-rt"])
      )
    )
  }

  // MARK: - Auth (the encoded rules)

  /// An email, and nothing else. There is deliberately no options parameter,
  /// because that is where a redirect URL would be added by someone who did
  /// not know why it must not be.
  public func requestEmailCode(_ email: String) async throws {
    let to = AuthRules.normalizeEmail(email)
    guard AuthRules.looksLikeEmail(to) else {
      throw RpcError(name: "requestEmailCode", underlying: "That does not look like an email address.", droppedArgs: [])
    }
    try await client.auth.signInWithOTP(email: to)
  }

  /// Verify a code. Accepts raw input — normalisation happens here so no
  /// caller has to remember to do it.
  @discardableResult
  public func verifyEmailCode(email: String, code: String) async throws -> Session {
    let to = AuthRules.normalizeEmail(email)
    let token = AuthRules.normalizeCode(code)
    guard token.count == AuthRules.otpLength else {
      throw RpcError(name: "verifyEmailCode", underlying: "Type all \(AuthRules.otpLength) digits from the email.", droppedArgs: [])
    }
    let r = try await client.auth.verifyOTP(email: to, token: token, type: .email)
    guard let s = r.session else {
      throw RpcError(name: "verifyEmailCode", underlying: "The code was accepted but no session came back.", droppedArgs: [])
    }
    return s
  }

  /// The reviewer door. Only ever reached for `AuthRules.reviewerEmail`.
  public func signInReviewer(email: String, password: String) async throws {
    _ = try await client.auth.signIn(email: AuthRules.normalizeEmail(email), password: password)
  }

  public func currentSession() async -> Session? {
    try? await client.auth.session
  }

  public func signOut() async throws {
    try await client.auth.signOut()
  }

  /// Forward the token to the realtime client. Call on every auth change.
  public func forwardRealtimeAuth(_ session: Session?) async {
    await realtime.realtimeV2.setAuth(session?.accessToken)
  }

  // MARK: - RPC with the skew retry

  public func call<C: RpcCall>(_ call: C) async throws -> C.Returns {
    do {
      return try await invoke(C.name, params: call, as: C.Returns.self)
    } catch {
      let droppable = C.optionalArgs
      let first = RpcError(name: C.name, underlying: Self.describe(error), droppedArgs: [])
      guard !droppable.isEmpty else { throw first }
      let data = try Self.encoder.encode(call)
      guard var dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw first }
      let present = droppable.filter { dict[$0] != nil }
      guard !present.isEmpty else { throw first }
      for k in present { dict.removeValue(forKey: k) }
      let slim = try JSONDecoder().decode(JSONValue.self, from: JSONSerialization.data(withJSONObject: dict))
      do {
        return try await invoke(C.name, params: slim, as: C.Returns.self)
      } catch {
        throw RpcError(name: C.name, underlying: Self.describe(error), droppedArgs: present)
      }
    }
  }

  private func invoke<R: Decodable & Sendable>(_ name: String, params: some Encodable & Sendable, as: R.Type) async throws -> R {
    if R.self == RpcVoid.self {
      try await client.rpc(name, params: params).execute()
      return RpcVoid() as! R
    }
    return try await client.rpc(name, params: params).execute().value
  }

  static let encoder: JSONEncoder = {
    let e = JSONEncoder()
    e.dateEncodingStrategy = .iso8601
    return e
  }()

  static func describe(_ error: Error) -> String {
    if let e = error as? PostgrestError { return [e.code, e.message].compactMap { $0 }.joined(separator: " ") }
    if let e = error as? LocalizedError, let d = e.errorDescription { return d }
    return String(describing: error)
  }
}

/// The realtime client keeps no session of its own; the token is forwarded.
private struct EphemeralStorage: AuthLocalStorage {
  private final class Box: @unchecked Sendable { var store: [String: Data] = [:]; let lock = NSLock() }
  private let box = Box()
  func store(key: String, value: Data) throws { box.lock.lock(); defer { box.lock.unlock() }; box.store[key] = value }
  func retrieve(key: String) throws -> Data? { box.lock.lock(); defer { box.lock.unlock() }; return box.store[key] }
  func remove(key: String) throws { box.lock.lock(); defer { box.lock.unlock() }; box.store[key] = nil }
}
