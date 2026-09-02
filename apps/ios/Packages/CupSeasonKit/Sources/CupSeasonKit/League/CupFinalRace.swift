// Cup Season — the Cup Final race (D105; migration 20260828170100).
//
// `cup_final_race(season)` is the ONE window expression, shared with
// close_season: per finalist the seed, the head start, the window points,
// rounds used, the total, and the rounds behind it. The phone never computes
// the race — it reads it, like the web (spec §16: figure and receipt are one
// path). Before the seeds lock the server answers {status:"pending"} and the
// room keeps the D4 foreshadow (season_scenarios).
//
// Hand-rolled `RpcCall` until the snapshot refresh mints `Rpc.cup_final_race`
// (tools/build-db.mjs); the mirror is byte-for-byte on the SQL signature.

import Foundation

public struct CupFinalRace: Decodable, Sendable, Equatable {
  public struct Round: Decodable, Sendable, Equatable, Identifiable {
    public let round_id: UUID?
    public let played_on: String
    public let points: Double
    public let month_rank: Int?
    public let pvi: Double?
    public let holes_played: Int?
    public let member_id: UUID?
    public let golfer: String?
    public var id: String { round_id?.uuidString ?? "\(played_on)-\(member_id?.uuidString ?? "")" }
  }
  public struct Finalist: Decodable, Sendable, Equatable, Identifiable {
    public let seed: Int
    public let head_start: Double
    public let seed_rung: String?
    public let squad_id: UUID?
    public let member_id: UUID?
    public let name: String
    public let color: Int?
    public let window_points: Double
    public let rounds_used: Int
    public let last_round_on: String?
    public let total: Double
    public let rounds: [Round]
    /// The row the standings table keys on — the squad, or the member in a solo league.
    public var teamId: UUID? { squad_id ?? member_id }
    public var id: Int { seed }
  }
  public let status: String            // pending · live · complete
  public let season_status: String?
  public let solo: Bool?
  public let window_start: String?
  public let window_end: String?
  public let cap_n: Int?
  /// D212 · "Best 3 per calendar month still applies — a round posted before
  /// the window can hold a slot." Server-written (`cup_final_race`), null when
  /// the league sets no cap; absent entirely until that migration is pushed.
  public let cap_note: String?
  public let days_left: Int?
  public let finalists: [Finalist]
  public let seed_rung: String?

  public var isLive: Bool { status == "live" }
  /// Finalists in race order — the leader first, seed order on a level total.
  public var race: [Finalist] {
    finalists.sorted { $0.total != $1.total ? $0.total > $1.total : $0.seed < $1.seed }
  }
  public func seed(for teamId: UUID) -> Int? { finalists.first { $0.teamId == teamId }?.seed }

  public static func decode(_ v: JSONValue) -> CupFinalRace? {
    guard case .object = v, v["status"] != nil, let data = try? JSONEncoder().encode(v) else { return nil }
    return try? JSONDecoder().decode(CupFinalRace.self, from: data)
  }

  struct Call: RpcCall {
    static let name = "cup_final_race"
    static let optionalArgs: [String] = []
    typealias Returns = JSONValue
    let p_season: UUID
  }
  /// nil on any error (an un-migrated database, a non-member) — the room then
  /// renders exactly as before D105.
  public static func fetch(season: UUID, svc: SupabaseService = .shared) async -> CupFinalRace? {
    guard let v = try? await svc.call(Call(p_season: season)) else { return nil }
    return decode(v)
  }
}
