// Cup Season — the pot's arithmetic (index.html 6973–7050, 11465–11508;
// audit 06 §1.3). A ledger, never a balance. The champion absorbs the
// rounding; per-seat pennies ride the earliest seats — the parts always sum
// to the whole, "money between friends never loses a penny".

import Foundation

public enum PotMath {
  /// `Math.round` — half away from zero, like JS on positives.
  static func jsRound(_ v: Double) -> Int { Int(v.rounded()) }

  /// `csSplitCents`: an even split in cents, remainder to the earliest seats.
  public static func splitCents(_ total: Int, _ n: Int) -> [Int] {
    guard n > 0 else { return [] }
    let base = total / n
    var rem = total - base * n
    return (0..<n).map { _ in
      let c = base + (rem > 0 ? 1 : 0)
      if rem > 0 { rem -= 1 }
      return c
    }
  }

  /// The pot pane's trio in DOLLARS (7001–7003): round(total × pct / 100).
  public static func trioDollars(total: Int, payout: [Int]) -> (champ: Int, runner: Int, king: Int) {
    let p = payout.count == 3 ? payout : [60, 25, 15]
    return (jsRound(Double(total) * Double(p[0]) / 100), jsRound(Double(total) * Double(p[1]) / 100), jsRound(Double(total) * Double(p[2]) / 100))
  }

  /// The settlement split in CENTS (11483–11487): runner and king round, the champion absorbs.
  public static func settlementCents(pot: Int, payout: [Int]) -> (champ: Int, runner: Int, king: Int) {
    let p = payout.count == 3 ? payout : [60, 25, 15]
    let runner = jsRound(Double(pot) * Double(p[1]) / 100)
    let king = jsRound(Double(pot) * Double(p[2]) / 100)
    return (max(0, pot - runner - king), runner, king)
  }

  /// `csMoney`: "$180" or "$75.50".
  public static func money(_ cents: Int) -> String { CSCopy.dollars(cents: cents) }
  /// `fmt$` on dollars.
  public static func dollars(_ d: Int) -> String { "$\(d)" }

  // MARK: settlement (D66)

  public struct SettlementRow: Sendable, Equatable, Identifiable {
    public let profileId: UUID
    public let name: String
    public let cents: Int
    public let why: [String]
    public var id: UUID { profileId }
    public init(profileId: UUID, name: String, cents: Int, why: [String]) { self.profileId = profileId; self.name = name; self.cents = cents; self.why = why }
  }

  public struct Settlement: Sendable, Equatable {
    public let potCents: Int
    /// D106: the cash that exists; equals `potCents` when everyone paid or on the preview path.
    public let collectedCents: Int
    /// D106: who still owes the pot (names), only when the ledger is short.
    public let owing: [String]
    public let rows: [SettlementRow]
    public let champName: String
    public let runName: String
    public let kingName: String
    public let mine: SettlementRow?
    public let s1: Double?
    public let s2: Double?
    public let rung: String?
    /// true when the rows came from `season_payouts`; false = client math, labelled "preview".
    public let fromLedger: Bool
    /// a share with no eligible finisher — measured against what was actually split (collected)
    public var unclaimedCents: Int { max(0, collectedCents - rows.reduce(0) { $0 + $1.cents }) }
    /// D106: what the roster still owes the pot.
    public var stillOwedCents: Int { max(0, potCents - collectedCents) }
  }

  static let reasonOrder = ["Cup champion", "Runner-up", "Points king"]

  /// `csSettlement()` (11479–11508), with the server's rows preferred when they exist.
  public static func settlement(season: LeagueRoom.Season, members: [LeagueRoom.Member], squads: [LeagueRoom.Squad], solo: Bool,
                                stakeDollars: Int, payout: [Int], payouts: [LeagueRoom.Payout], myProfileId: UUID?,
                                owing: [String] = []) -> Settlement {
    // D106: the server's two numbers when the season closed on a D106 database; the roster × stake preview otherwise
    let fromLedger = !payouts.isEmpty
    let potCents = (fromLedger ? season.pot_cents : nil) ?? jsRound(Double(stakeDollars) * 100) * members.count
    let collectedCents = (fromLedger ? season.collected_cents : nil) ?? potCents
    let byId = { (id: UUID?) -> LeagueRoom.Member? in id.flatMap { i in members.first { $0.id == i } } }
    let byPid = { (pid: UUID) -> LeagueRoom.Member? in members.first { $0.profile_id == pid } }
    let sqName = { (sid: UUID?) -> String in sid.flatMap { s in squads.first { $0.id == s } }?.name ?? "" }
    let sqPids = { (sid: UUID?) -> [UUID] in
      (sid.flatMap { s in squads.first { $0.id == s } }?.squad_members ?? []).compactMap { seat in byId(seat.member_id)?.profile_id }
    }

    var rows: [SettlementRow]
    if fromLedger {
      var tally: [UUID: SettlementRow] = [:]
      var order: [UUID] = []
      for p in payouts {
        if tally[p.profile_id] == nil { order.append(p.profile_id) }
        let prev = tally[p.profile_id]
        var why = prev?.why ?? []
        if !why.contains(p.reason) { why.append(p.reason) }
        why.sort { (reasonOrder.firstIndex(of: $0) ?? 9) < (reasonOrder.firstIndex(of: $1) ?? 9) }
        tally[p.profile_id] = SettlementRow(profileId: p.profile_id, name: byPid(p.profile_id)?.name ?? "A golfer", cents: (prev?.cents ?? 0) + p.cents, why: why)
      }
      rows = order.compactMap { tally[$0] }
    } else {
      let (champC, runnerC, kingC) = settlementCents(pot: potCents, payout: payout)
      var tally: [UUID: SettlementRow] = [:]
      var order: [UUID] = []
      func add(_ pid: UUID?, _ cents: Int, _ why: String) {
        guard let pid, let m = byPid(pid) else { return }
        if tally[pid] == nil { order.append(pid) }
        let prev = tally[pid]
        var whys = prev?.why ?? []
        if !whys.contains(why) { whys.append(why) }
        tally[pid] = SettlementRow(profileId: pid, name: m.profile?.display_name ?? "A golfer", cents: (prev?.cents ?? 0) + cents, why: whys)
      }
      let champIds = solo ? (byId(season.champion_member_id).map { [$0.profile_id] } ?? []) : sqPids(season.champion_squad_id)
      let runIds = solo ? (byId(season.runnerup_member_id).map { [$0.profile_id] } ?? []) : sqPids(season.runnerup_squad_id)
      for (i, c) in splitCents(champC, champIds.count).enumerated() { add(champIds[i], c, "Cup champion") }
      for (i, c) in splitCents(runnerC, runIds.count).enumerated() { add(runIds[i], c, "Runner-up") }
      if let k = season.points_king_member_id { add(byId(k)?.profile_id, kingC, "Points king") }
      rows = order.compactMap { tally[$0] }
    }
    rows.sort { $0.cents > $1.cents }

    return Settlement(
      potCents: potCents, collectedCents: collectedCents, owing: collectedCents < potCents ? owing : [], rows: rows,
      champName: solo ? (byId(season.champion_member_id)?.profile?.display_name ?? "The champion") : (sqName(season.champion_squad_id).isEmpty ? "The champion" : sqName(season.champion_squad_id)),
      runName: solo ? (byId(season.runnerup_member_id)?.profile?.display_name ?? "") : sqName(season.runnerup_squad_id),
      kingName: byId(season.points_king_member_id)?.profile?.display_name ?? "",
      mine: myProfileId.flatMap { me in rows.first { $0.profileId == me } },
      s1: season.champion_score, s2: season.runnerup_score, rung: season.tiebreak_rung, fromLedger: fromLedger)
  }

  /// `n()` in the ceremony: whole numbers plain, else one decimal.
  public static func score(_ v: Double?) -> String {
    guard let v else { return "" }
    return v == v.rounded() ? String(Int(v.rounded())) : String(format: "%.1f", v)
  }
}
