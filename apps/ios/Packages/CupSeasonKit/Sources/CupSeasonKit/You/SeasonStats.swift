// Cup Season — "This season · <league>": the four-stat strip (index.html
// `renderIndStatsReal` 11250–11268, rows built at 14480–14506).
//
// Off the same views the server scores with — `v_individual_standings` for
// the count and `v_rounds_ranked` for the lens — no demo-shaped math anywhere
// near a real league. The figures are the allowance PvI, labelled "vs your
// playing number" (D209).

import Foundation

public struct SeasonStats: Sendable, Equatable {
  /// `rounds_posted` from the standings view
  public let rounds: Int
  /// how many of my ranked rounds carry a figure — the ones the strip averages
  public let counting: Int
  /// mean pvi across my ranked rounds
  public let avg: Double?
  /// max pvi — the best round against the playing number this season
  public let best: Double?
  /// `index_at_post` last − first, when there are 2+ rounds
  public let delta: Double?

  public init(rounds: Int, counting: Int = 0, avg: Double?, best: Double?, delta: Double?) {
    self.rounds = rounds; self.counting = counting; self.avg = avg; self.best = best; self.delta = delta
  }

  public static let empty = SeasonStats(rounds: 0, avg: nil, best: nil, delta: nil)

  /// - rows: every `v_rounds_ranked` row for the season (all members).
  public static func compute(rows: [RankedRound], standings: [IndividualStanding], myMemberId: UUID) -> SeasonStats {
    let mine = rows.filter { $0.member_id == myMemberId }.sorted { ($0.played_on ?? "") < ($1.played_on ?? "") }
    let pvis = mine.compactMap(\.pvi)
    let r = standings.first { $0.member_id == myMemberId }?.rounds_posted ?? 0
    var delta: Double? = nil
    if mine.count > 1, let a = mine.first?.index_at_post, let b = mine.last?.index_at_post { delta = b - a }
    return SeasonStats(rounds: r, counting: pvis.count, avg: pvis.isEmpty ? nil : pvis.reduce(0, +) / Double(pvis.count), best: pvis.max(), delta: delta)
  }

  public var roundsText: String { String(rounds) }
  /// `me.r ? sgn(me.avg) : '—'`
  public var avgText: String { rounds > 0 ? (avg.map(RoundCopy.signed) ?? "—") : "—" }
  public var bestText: String { best.map(RoundCopy.signed) ?? "—" }
  /// Y-14 · what the best and the average are computed OVER — the same line on
  /// both, because they are read off the same set (`Career.figureScope` is its
  /// all-time twin; the two panels speak one grammar).
  public var figureScope: String { counting == 0 ? YouCopy.noCountingRounds : YouCopy.acrossCounting(counting) }
  /// `|d| ≥ 0.05 ? (d<0 ? '▼ ' : '▲ ') + |d|.toFixed(1)` — and, Y-28, "Held"
  /// when two rounds bracket no move at all; a dash only when there is no
  /// second round to measure from (`deltaSub` says so).
  public var deltaText: String {
    guard let d = delta else { return "—" }
    guard abs(d) >= 0.05 else { return YouCopy.held }
    return (d < 0 ? "▼ " : "▲ ") + RoundCopy.f1(abs(d))
  }
  /// the row's sub: why the cell is a dash, or its scope
  public var deltaSub: String { delta == nil ? YouCopy.needsTwoRounds : YouCopy.seasonToDate }
}
