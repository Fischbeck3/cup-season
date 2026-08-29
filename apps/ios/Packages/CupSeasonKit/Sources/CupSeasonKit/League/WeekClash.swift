// Cup Season — the weekly clash (D108, D52's mechanic; migration
// 20260829091000). One spotlighted pairing per season week; the daily tick is
// the only writer — the clients only READ `week_clashes` (member-scoped
// SELECT). Never cup points (§5's parallel-ledger law). The card mirrors the
// web chip: mid-week the pair with each side's best counting round so far
// (the same pick `settle_week_clash` makes), the result once settled.

import Foundation

extension LeagueRoom {
  /// One `week_clashes` row — exactly the columns the clients select.
  public struct WeekClash: Decodable, Sendable, Identifiable, Equatable {
    /// `a_best` / `b_best` — the settle snapshot: the counting round the W (or
    /// the square) stands on, so every figure taps to its round (§16).
    public struct Best: Decodable, Sendable, Equatable {
      public let round_id: UUID?
      public let played_on: String?
      public let points: Double?
      public let pvi: Double?
      public let band: String?
      public init(round_id: UUID? = nil, played_on: String? = nil, points: Double? = nil, pvi: Double? = nil, band: String? = nil) {
        self.round_id = round_id; self.played_on = played_on; self.points = points; self.pvi = pvi; self.band = band
      }
    }
    public let id: UUID
    public let week_no: Int
    public let a_member: UUID
    public let b_member: UUID
    public let opened_at: String?
    public let settled_at: String?
    public let winner_member: UUID?
    public let a_best: Best?
    public let b_best: Best?
    public init(id: UUID, week_no: Int, a_member: UUID, b_member: UUID, opened_at: String? = nil, settled_at: String? = nil,
                winner_member: UUID? = nil, a_best: Best? = nil, b_best: Best? = nil) {
      self.id = id; self.week_no = week_no; self.a_member = a_member; self.b_member = b_member; self.opened_at = opened_at
      self.settled_at = settled_at; self.winner_member = winner_member; self.a_best = a_best; self.b_best = b_best
    }
    public var settled: Bool { settled_at != nil }
    /// The current spotlight: the highest week, whatever order rows arrive.
    public static func latest(_ rows: [WeekClash]) -> WeekClash? {
      rows.max { $0.week_no < $1.week_no }
    }
  }
}

/// The clash's pure arithmetic — the week window and the mid-week pick.
public enum ClashMath {
  /// The week's window as ISO dates: `[starts_on + 7·(week−1), +6]` —
  /// calendar days (§14.0's real first-tee weekday), the settle's expression.
  public static func window(startsOn: String, week: Int, calendar: Calendar = .current) -> (start: String, end: String) {
    (LeagueDates.addDays(startsOn, (week - 1) * 7, calendar: calendar),
     LeagueDates.addDays(startsOn, week * 7 - 1, calendar: calendar))
  }

  /// Mid-week best-so-far: the settle pick — the highest-points COUNTING round
  /// inside the window (points, then pvi, then the earlier date). The BAND
  /// decides the W, so the card speaks named bands, never raw differential.
  public static func bestSoFar(_ ranked: [LeagueRoom.RankedRound], member: UUID,
                               window: (start: String, end: String), capN: Int) -> LeagueRoom.WeekClash.Best? {
    let top = ranked.filter {
      $0.member_id == member && ($0.month_rank ?? 1) <= capN
        && $0.played_on >= window.start && $0.played_on <= window.end
    }.sorted { a, b in
      let ap = a.points ?? 0, bp = b.points ?? 0
      if ap != bp { return ap > bp }
      let av = a.pvi ?? 0, bv = b.pvi ?? 0
      if av != bv { return av > bv }
      return a.played_on < b.played_on
    }.first
    guard let top else { return nil }
    return .init(round_id: top.round_id, played_on: top.played_on, points: top.points, pvi: top.pvi,
                 band: top.pvi.map(CSBands.bandName))
  }

  /// "Sat" — the weekday of an ISO calendar date (the REAL weekday, §14.0).
  public static func dowShort(_ iso: String, calendar: Calendar = .current) -> String {
    guard let d = CSDate.local(iso, calendar: calendar) else { return "" }
    return LeagueDates.dow[calendar.component(.weekday, from: d) - 1]
  }
}
