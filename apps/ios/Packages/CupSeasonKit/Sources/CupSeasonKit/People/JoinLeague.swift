// Cup Season — join by code (audit 02 §1.3 E; index.html 15176–15220,
// 17257–17267, 17313–17318, 17560–17575).
//
// Three entrances on the web, one RPC at the end (`join_league`). The phone
// keeps the same keys (`cs_code`, `cs_code_name`) so a code that arrives by
// Universal Link before sign-in is consumed after the card gate, exactly as
// `resumeAfterProfile` does it — and is REMOVED before the attempt so a
// failure can never loop.

import Foundation

public enum JoinIntent {
  public static let codeKey = "cs_code"
  public static let nameKey = "cs_code_name"

  /// Codes are typed in any case; the RPCs compare upper (15198).
  public static func normalize(_ raw: String) -> String {
    raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
  }

  public static func store(_ code: String, name: String? = nil, defaults: UserDefaults = .standard) {
    defaults.set(normalize(code), forKey: codeKey)
    if let name { defaults.set(name, forKey: nameKey) } else { defaults.removeObject(forKey: nameKey) }
  }

  public static func pending(defaults: UserDefaults = .standard) -> (code: String, name: String?)? {
    guard let c = defaults.string(forKey: codeKey), !c.isEmpty else { return nil }
    return (c, defaults.string(forKey: nameKey))
  }

  public static func clear(defaults: UserDefaults = .standard) {
    defaults.removeObject(forKey: codeKey)
    defaults.removeObject(forKey: nameKey)
  }

  /// `/?join=CODE` (17560): the only query the app claims besides `?claim=`.
  public static func code(from url: URL) -> String? {
    guard let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
          let v = items.first(where: { $0.name == "join" })?.value, !v.isEmpty else { return nil }
    return normalize(v)
  }
}

/// `league_by_code` returns `text` that is NULL for an unknown code (15202–15204).
/// The generator maps a scalar return to a non-optional; this declaration
/// keeps the null so "no league" and "the RPC failed" stay distinguishable.
struct LeagueByCodeCall: RpcCall {
  static let name = "league_by_code"
  static let optionalArgs: [String] = []
  typealias Returns = String?
  let p_code: String
}

/// `join_covenant_info` (setup-QA S3-01): the stake, named BEFORE join_league.
public struct Covenant: Sendable, Equatable, Identifiable {
  public var id: String { name }
  public let name: String
  public let buyinCents: Int
  public let preset: String?
  public let floor: Int
  public let finish: String?

  public init(name: String, buyinCents: Int, preset: String?, floor: Int, finish: String?) {
    self.name = name; self.buyinCents = buyinCents; self.preset = preset; self.floor = floor; self.finish = finish
  }

  public init?(_ v: JSONValue) {
    guard case .object = v else { return nil }
    self.init(name: v["name"]?.string ?? "this league",
              buyinCents: v["buyin_cents"]?.int ?? Int(v["buyin_cents"]?.string ?? "") ?? 0,
              preset: v["preset"]?.string,
              floor: v["floor"]?.int ?? Int(v["floor"]?.string ?? "") ?? 0,
              finish: v["finish"]?.string)
  }

  /// `Math.round(buyin_cents/100)`
  public var usd: Int { Int((Double(buyinCents) / 100).rounded()) }
  /// "$50 / player · on the pot sheet"
  public var buyinLine: String { "$\(usd) / player · on the pot sheet" }
  /// "Standard"
  public var presetLine: String? { preset.map { $0.prefix(1).uppercased() + $0.dropFirst() } }
  /// "2 rounds / mo"
  public var floorLine: String? { floor > 0 ? "\(floor) round\(floor == 1 ? "" : "s") / mo" : nil }
  /// "Points table crowns it" / "Cup Final · final 4 weeks"
  public var finishLine: String { finish == "points_table" ? "Points table crowns it" : "Cup Final · final 4 weeks" }
  public var potLine: String { "Joining puts you on the pot sheet for $\(usd). " + MoneyCopy.ledger }
  public var joinLabel: String { "Join — I’m in for $\(usd)" }
}

public struct JoinService: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  /// nil = no league with that code. Throws when the lookup itself failed.
  public func leagueName(_ code: String) async throws -> String? {
    try await svc.call(LeagueByCodeCall(p_code: JoinIntent.normalize(code)))
  }

  /// The gate. nil = a $0 league, one-tap join. On the phone a missing or
  /// failing RPC is an ERROR (fails closed) — the web fell open to the plain
  /// join; a stake that goes unnamed is exactly what S3-01 exists to prevent.
  public func covenant(_ code: String) async throws -> Covenant? {
    let info = try await svc.call(Rpc.join_covenant_info(p_code: JoinIntent.normalize(code)))
    guard let c = Covenant(info), c.buyinCents > 0 else { return nil }
    return c
  }

  /// `join_league` → the league id.
  public func join(_ code: String) async throws -> UUID {
    try await svc.call(Rpc.join_league(p_code: JoinIntent.normalize(code)))
  }

  /// Error copy (17150, 15338): an "invalid" code reads as the Pro's problem.
  public static func joinError(_ error: Error) -> String {
    let m = ((error as? LocalizedError)?.errorDescription ?? String(describing: error)).lowercased()
    return m.contains("invalid") ? "No league with that code. Check with your Pro" : HumanError.text(error, prefix: "Could not join.")
  }
}
