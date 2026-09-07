// Cup Season — THE SEASON BOARD's own producers (Wave 5, `surfaces/season.md`).
//
// Everything the board prints that is not already a producer: the month
// grouping behind `CSSeasonCalendar`, the slat's clause of why, the gap
// column, and the section heads' count slots. All of it is arithmetic over
// rows the client already holds (§6) — **nothing here reads the network and
// nothing here invents a fact**, so a test pins every sentence and the web
// half can be written from the same rules.
//
// WHY IT IS IN THE KIT AND NOT IN THE VIEW. The clause under a name and the
// figure in a count slot are COPY, and copy is produced once and rendered
// twice (D234). A string built inside `StandingsTableView` is a string the
// desk cannot reach.

import Foundation

/// One calendar month's share of a season, for the month clock (§1.2).
public struct SeasonMonth: Sendable, Equatable, Identifiable {
  /// `AUG` — the month's short name, in the copy's own case; the role uppercases.
  public let label: String
  /// How many of the season's weeks this month counts.
  public let weeks: Int
  /// `25 days` — **the live month only**. The days remaining in the calendar
  /// month, which is the clock the monthly minimum actually runs on.
  public let note: String?
  public let live: Bool
  public var id: String { label }
  public init(label: String, weeks: Int, note: String? = nil, live: Bool = false) {
    self.label = label; self.weeks = weeks; self.note = note; self.live = live
  }
}

/// The month clock's arithmetic. **A season week belongs to the month that
/// holds most of it** — its median day, the fourth of the seven.
///
/// Grouping by the week's FIRST day was the first cut and the screenshot
/// killed it: the week of Aug 31 – Sep 6 sat at the end of the August group
/// while the label under September was the live one, so the ember tick and
/// the ember month name pointed at two different places on the same graphic.
/// The median puts them together on every day of the year but the two or three
/// at a boundary, and it is a rule a reader can state.
public enum SeasonCalendarMath {
  public static func months(startsOn: String?, weeks: Int, today: String = CSDate.today(),
                            calendar: Calendar = .current) -> [SeasonMonth] {
    guard let start = startsOn, weeks > 0, CSDate.local(start, calendar: calendar) != nil else { return [] }
    let liveKey = LeagueDates.monthKey(today)
    var order: [String] = []
    var counts: [String: Int] = [:]
    for w in 0..<weeks {
      let day = LeagueDates.addDays(start, w * 7 + 3, calendar: calendar)
      let key = LeagueDates.monthKey(day)
      if counts[key] == nil { order.append(key); counts[key] = 0 }
      counts[key]! += 1
    }
    return order.map { key in
      let live = key == liveKey
      let m = Int(key.suffix(2)) ?? 1
      let label = LeagueDates.mos[max(0, min(11, m - 1))]
      return SeasonMonth(label: label, weeks: counts[key] ?? 1,
                         note: live ? daysLeftNote(today, calendar: calendar) : nil, live: live)
    }
  }

  /// `25 days` — never `25 days left`: the label already sits on a clock.
  public static func daysLeftNote(_ today: String, calendar: Calendar = .current) -> String? {
    guard let n = CSDate.days(from: today, to: LeagueDates.firstOfNextMonth(today, calendar: calendar)),
          n > 0 else { return nil }
    return "\(n) day\(n == 1 ? "" : "s")"
  }
}

/// The board's own words.
public enum SeasonBoardCopy {

  // MARK: - the count slots (§16A.2 — a count and nothing else)

  /// `EIGHT IN THE FIELD`. Spelled to twelve, a figure past it.
  public static func field(_ n: Int) -> String {
    "\(SeasonStoryCopy.word(n)) in the field"
  }
  /// `FOUR SIDES` — the squad table's slot.
  public static func sides(_ n: Int) -> String { "\(SeasonStoryCopy.word(n)) sides" }
  /// `EIGHT IN` — the pot's slot. The count, never the stake: the stake is the
  /// figure's own caption, and a section names its count once.
  public static func potIn(_ n: Int) -> String { "\(SeasonStoryCopy.word(n)) in" }
  /// `SIX OF EIGHT` — who has actually paid.
  public static func paid(_ paid: Int, of n: Int) -> String {
    "\(SeasonStoryCopy.word(paid)) of \(SeasonStoryCopy.word(n))"
  }

  // MARK: - the gap column

  /// `+4` · **the leader's cell is EMPTY** — not `0`, and not an em dash
  /// either: a dash reads as a value, which is the thing "empty" was
  /// protecting against.
  public static func gap(leader: Double, row: Double) -> String {
    let d = leader - row
    return d > 0 ? "+\(CSCopy.points(d))" : ""
  }

  // MARK: - the slat's clause of why

  /// The sub-line under a name, **sentence case, one line, authored to a
  /// character budget** (the blind review's finding 8: `1 OF 4 COUNTING · ONE
  /// S…` sheared, so the qualifier lives in the receipt).
  ///
  /// The leader's clause is the run — *"Held since week three"* — which is the
  /// one fact the table can state that the points cannot. Everyone else gets
  /// what is counting if it is theirs, and the rounds posted if it is not.
  /// **Never the word *floor*** (`TERMINOLOGY` §4 pattern 2).
  /// - tied: **the row shares its position with the row beside it.** A tie is a
  ///   real state of a points table and it is stated in words as well as by the
  ///   shared rail numeral, because two golfers reading `04` twice with no
  ///   explanation is the rendering error a shared numeral looks like.
  public static func clause(isLeader: Bool, runSince: Int?, runWeeks: Int?,
                            isMe: Bool, counted: Int?, cap: Int?,
                            rounds: Int, solo: Bool, left: Bool, cooled: Bool = false,
                            tied: Bool = false) -> String {
    if left { return "Stopped scoring" }
    // A tie outranks the run and the count: it is the only thing on the row
    // that explains why two positions read the same, and §3's hard case says
    // the sub-line says so.
    if tied { return "Tied" }
    if isLeader {
      if let s = runSince, s > 0 { return "Held since week \(SeasonStoryCopy.word(s))" }
      if let w = runWeeks, w > 1 { return "Held \(SeasonStoryCopy.word(w)) weeks" }
    }
    if isMe, let c = counted, let cap, cap > 0 { return "\(c) of \(cap) counting" }
    if !solo { return "" }
    if rounds == 0 { return "No rounds yet" }
    let r = "\(rounds) round\(rounds == 1 ? "" : "s")"
    return cooled ? "\(r) · cooled" : r
  }

  // MARK: - the countdown (§1.5)

  /// The block under the last slat: a figure, its label, and the rule's metal.
  /// **A clock that is running is ember**; a points-table season counts its own
  /// weeks down to its own end date and never mentions a cut.
  public struct Countdown: Sendable, Equatable {
    public let figure: String
    public let label: String
    public init(figure: String, label: String) { self.figure = figure; self.label = label }
  }

  public static func countdown(finish: String?, inWeeks: Int?, weeksLeft: Int?) -> Countdown? {
    let cup = (finish ?? "cup_final") == "cup_final"
    let n = cup ? inWeeks : weeksLeft
    guard let n, n >= 0 else { return nil }
    return Countdown(figure: String(format: "%02d", n),
                     label: cup ? "weeks to the Cup Final" : "weeks left in the season")
  }

  /// `CUT · TOP TWO PLAY THE CUP FINAL` — and **never gold**: nothing here is
  /// won yet.
  public static let cut = "Cut · top two play the Cup Final"

  // MARK: - the pot

  /// `$60 EACH · 288 / 120 / 72` — the figure's own caption. The head carries
  /// the count; the caption carries the stake and the split (§16A.2).
  public static func potCaption(stake: Int, trio: (champ: Int, runner: Int, king: Int)) -> String {
    "\(PotMath.dollars(stake)) each · \(bare(trio.champ)) / \(bare(trio.runner)) / \(bare(trio.king))"
  }
  static func bare(_ cents: Int) -> String {
    let s = PotMath.money(cents)
    return s.hasPrefix("$") ? String(s.dropFirst()) : s
  }

  /// The leaf's sign column — **a WORD, never a colour** (D273).
  public static func sign(paid: Bool, mine: Bool) -> String {
    paid ? "Paid" : (mine ? "You owe" : "Owes")
  }
}

// MARK: - The head (§1.1)

public extension SeasonBoardCopy {
  /// The live eyebrow: `Season live · week 5 of 13`. **The stage first**,
  /// because the dot beside it is the ember and the ember means *live* — the
  /// name it needs is the state, not the league, and the league is set in
  /// `display` directly beneath. Same parts as `SeasonStoryCopy.dateline`,
  /// same vocabulary (D120), re-ordered for a head that carries the name once.
  static func eyebrow(stage: LeagueCopy.Stage, week: Int?, weeks: Int?) -> String {
    var parts = [stage.label]
    if let w = week, let t = weeks, stage == .season || stage == .final { parts.append("week \(w) of \(t)") }
    return parts.joined(separator: " · ")
  }

  /// `Season one · Mon Aug 3 – Mon Nov 2 · the Pro, Galen`.
  ///
  /// **An en dash, never `→`** (LINT-13), and **no week count**: the eyebrow
  /// directly above already reads `WEEK 5 OF 13`, and one fact gets one
  /// encoding per viewport (§16A.4). That is why this builds its own span
  /// instead of taking `RoomClock.spanText`, which carries both.
  static func span(startsOn: String?, endsOn: String?, calendar: Calendar = .current) -> String? {
    guard let s = startsOn, let e = endsOn,
          CSDate.local(s, calendar: calendar) != nil, CSDate.local(e, calendar: calendar) != nil else { return nil }
    return "\(LeagueDates.dowMonDay(s, calendar: calendar)) \u{2013} \(LeagueDates.dowMonDay(e, calendar: calendar))"
  }

  static func dateline(number: Int?, span: String, pro: String?, squads: Int? = nil) -> String {
    var parts: [String] = []
    if let n = number { parts.append("Season \(SeasonStoryCopy.word(n))") }
    if let s = squads, s > 1 { parts.append("\(SeasonStoryCopy.word(s)) squads") }
    parts.append(span)
    if let p = pro, p != "—", !p.isEmpty { parts.append("the Pro, \(p)") }
    return parts.joined(separator: " · ")
  }
}
