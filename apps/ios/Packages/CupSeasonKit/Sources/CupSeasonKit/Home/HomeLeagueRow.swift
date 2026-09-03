// Cup Season — D121 · one compact row per OTHER league under the Home hero.
//
// A golfer living two real leagues (the audit's A7) saw only one of them on
// Home and reached the other through a toast. The row is the fix: every
// membership that is not the one the hero is rendering gets one line that
// says where it stands, in the vocabulary of the board (D47), and is a door
// to re-render Home around that league (D218 owns where the door lands).
//
// Pure: (Membership, today) → row. Skew-safe: a v1 payload with no names says
// "back of the lead"; a league with no season yet says its stage.

import Foundation

public struct HomeLeagueRow: Sendable, Equatable, Identifiable {
  /// The league id — the door's target.
  public let id: UUID
  public let name: String
  /// The one line under the name — see `sub(_:today:)`.
  public let sub: String
  /// A live season (in season or in its Cup Final). These rows sort first.
  public let isSeason: Bool

  public init(id: UUID, name: String, sub: String, isSeason: Bool) {
    self.id = id; self.name = name; self.sub = sub; self.isSeason = isSeason
  }

  /// One row per membership other than `current`, in-season leagues first,
  /// then by name — the same order every load, so the screen can be learned.
  /// Drawn from `HomeMode.pool`: a wrapped league beside a live one gets no
  /// row, because its door could not land (the hero would snap to the live
  /// league and the row would still be there — a door that lies).
  public static func rows(_ memberships: [Me.Membership], excluding current: UUID?, today: String = CSDate.today(),
                          calendar: Calendar = .current) -> [HomeLeagueRow] {
    HomeMode.pool(memberships, today: today).filter { $0.league_id != current }
      .map { make($0, today: today, calendar: calendar) }
      .sorted { a, b in
        if a.isSeason != b.isSeason { return a.isSeason }
        let n = a.name.localizedCaseInsensitiveCompare(b.name)
        return n == .orderedSame ? a.id.uuidString < b.id.uuidString : n == .orderedAscending
      }
  }

  public static func make(_ m: Me.Membership, today: String = CSDate.today(), calendar: Calendar = .current) -> HomeLeagueRow {
    let phase = SeasonPhase.of(m, today: today)
    let live: Bool
    switch phase { case .season, .cupFinal: live = true; default: live = false }
    return HomeLeagueRow(id: m.league_id, name: m.name, sub: sub(m, today: today, calendar: calendar), isSeason: live)
  }

  /// The line, by stage:
  ///   season    "Week 7 of 26 · 1st of 2, 22 clear of Jade · $150 on the books · $0 collected"
  ///             "Week 5 of 13 · 3rd of 10, 12 back of Galen"
  ///             "Week 5 of 13 · 2nd of 10, level with Galen"
  ///             the money clause is `HomeHeroCopy.footMoney` — nothing on a
  ///             $0 league (D70), no "collected" on a v1 payload.
  ///   preseason "First tee Sat Sep 5 · 5 on the roster"
  ///   cup final "Cup Final · 2 weeks left" / "· 1 week left" — never the season's place: the
  ///             Final is scored fresh (§14.3), so the table's rank is not its rank
  ///   complete  "Season complete" (`LeagueCopy.seasonNote`)
  ///   forming   "Forming" / "Squads drawing" (`LeagueCopy.Stage.label`)
  public static func sub(_ m: Me.Membership, today: String = CSDate.today(), calendar: Calendar = .current) -> String {
    switch SeasonPhase.of(m, today: today) {
    case .season(let w, let n):
      var s = "Week \(w) of \(n)"
      if let st = m.standing {
        s += " · \(CSCopy.ordinal(st.rank)) of \(st.of)"
        if let race = race(st) { s += ", \(race)" }
      }
      if let money = HomeHeroCopy.footMoney(m) { s += " · \(money)" }
      return s
    case .preseason:
      var s = "First tee \(m.season.map { LeagueDates.dowMonDay($0.starts_on, calendar: calendar) } ?? "—")"
      // "on the roster" — the row's own noun for a headcount (D207's phone
      // note); "N in" is the calendar's word for RSVPs and the pot's retired
      // word for buy-ins. The number is the ROOM's: `membership.members` is
      // every league_members row, suspended and tombstoned included — what
      // the room's "N players", the Members sheet and the Pot pane print,
      // and this row is a Home lens whose hero opens that room (D218). The
      // D207 count behind `headcount` drops both and can read one lower; it
      // is what a rule gates on, and only the fallback here (v1, or the
      // server could not count).
      if let n = m.members, n > 0 { s += " · \(n) on the roster" }
      else if let n = m.headcount { s += " · \(n) on the roster" }
      return s
    case .cupFinal(let left):
      return "\(LeagueCopy.Stage.final.label) · \(HomeHeroCopy.finalClock(left))"
    case .wrapped:
      return LeagueCopy.seasonNote(.complete, firstTee: nil, short: true)
    case .forming:
      return (m.phase == "draft" ? LeagueCopy.Stage.drawing : LeagueCopy.Stage.forming).label
    }
  }

  /// "22 clear of Jade" / "12 back of Galen" / "level with Galen"; the pre-v2
  /// sentences when the names have not arrived; nil with nothing to say.
  static func race(_ st: Me.Standing) -> String? {
    if st.rank == 1 {
      let gap = st.gap_to_next ?? ((st.points != nil && st.runner_up_points != nil) ? (st.points! - st.runner_up_points!) : nil)
      guard let other = HomeHeroCopy.clean(st.runner_up_name) else {
        // A v1 payload never carries the top row's margin — claim none, not a tie.
        if let g = gap, g > 0 { return "\(CSCopy.points(g)) clear" }
        return nil
      }
      guard let g = gap else { return nil }
      return g > 0 ? "\(CSCopy.points(g)) clear of \(other)" : "level with \(other)"
    }
    guard let g = st.gap_to_leader else { return nil }
    guard let leader = HomeHeroCopy.clean(st.leader_name) else {
      return g > 0 ? "\(CSCopy.points(g)) back of the lead" : "level with the lead"
    }
    return g > 0 ? "\(CSCopy.points(g)) back of \(leader)" : "level with \(leader)"
  }
}
