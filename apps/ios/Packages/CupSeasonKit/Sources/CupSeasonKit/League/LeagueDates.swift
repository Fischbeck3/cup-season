// Cup Season — the season's calendar arithmetic (index.html 11767–11801,
// 9406–9500), on calendar days, never on UTC instants.

import Foundation

public enum LeagueDates {
  public static let dow = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
  /// The weekday said out loud — the story line's grain ("changed hands on
  /// Sunday"), where the table's chip says SUN.
  public static let dowLong = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
  public static let mos = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  public static let monthsLong = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

  /// "Sat Sep 5" — `firstTeeText()`, verbatim shape.
  public static func dowMonDay(_ iso: String, calendar: Calendar = .current) -> String {
    guard let d = CSDate.local(iso, calendar: calendar) else { return iso }
    let c = calendar.dateComponents([.weekday, .month, .day], from: d)
    return "\(dow[(c.weekday ?? 1) - 1]) \(mos[(c.month ?? 1) - 1]) \(c.day ?? 0)"
  }

  /// "Sep 5"
  public static func monDay(_ iso: String, calendar: Calendar = .current) -> String {
    guard let d = CSDate.local(iso, calendar: calendar) else { return iso }
    let c = calendar.dateComponents([.month, .day], from: d)
    return "\(mos[(c.month ?? 1) - 1]) \(c.day ?? 0)"
  }

  public static func addDays(_ iso: String, _ n: Int, calendar: Calendar = .current) -> String {
    guard let d = CSDate.local(iso, calendar: calendar), let e = calendar.date(byAdding: .day, value: n, to: d) else { return iso }
    return CSDate.iso(e, calendar: calendar)
  }

  // MARK: - D246 · the ONE week producer

  /// **The week.** `native_home.season.week_no` is the answer, and this is the
  /// only place either client reads it.
  ///
  /// "What week is it" used to be computed in at least six places with at
  /// least two different bases — `snapshot_week` (0-based, day-7 start),
  /// `open_week_clash`/`home_clash`/`settle` (1-based), `sandbox_week`, the
  /// web's `weekCloseDate` (0-based), the web hero (1-based, `+1`), the web's
  /// weeks-left `Math.ceil`, and `LeagueDates.currentWeek` here — so the same
  /// season could be week 7 on one surface and week 6 on another. That is
  /// L-44's exact failure and it cannot be fixed by a lint, only by ruling the
  /// producer (D246).
  ///
  /// The **declared fallback** is `currentWeek` below, and it fires only for a
  /// payload that predates the v3 migration — the client renders what it
  /// renders today rather than a blank, and the two clients agree again the
  /// moment the migration lands.
  public static func week(_ s: Me.Season?, today: String = CSDate.today(), calendar: Calendar = .current) -> Int {
    guard let s else { return 1 }
    if let w = s.week_no, w > 0 { return w }
    return currentWeek(start: s.starts_on, end: s.ends_on, today: today, calendar: calendar)
  }

  /// How many weeks the season runs — `season.weeks_total`, with `totalWeeks`
  /// as the declared fallback.
  public static func weeksTotal(_ s: Me.Season?, calendar: Calendar = .current) -> Int {
    guard let s else { return 1 }
    if let n = s.weeks_total, n > 0 { return n }
    return totalWeeks(start: s.starts_on, end: s.ends_on, calendar: calendar)
  }

  /// The day this week closes — `season.week_ends_on`, with `weekClose` as the
  /// declared fallback. The league's OWN closing weekday, never a Sunday.
  public static func weekEnds(_ s: Me.Season?, today: String = CSDate.today(), calendar: Calendar = .current) -> String? {
    guard let s else { return nil }
    if let d = s.week_ends_on, !d.isEmpty { return d }
    return weekClose(start: s.starts_on, today: today, calendar: calendar)
  }

  /// The day the Cup Final opens — `season.final_opens_on`, with
  /// `cupFinalStart` as the declared fallback. nil on a points-table season,
  /// which has no Final to open, and the caller renders nothing.
  public static func finalOpens(_ s: Me.Season?, finish: String?, calendar: Calendar = .current) -> String? {
    guard let s else { return nil }
    if let d = s.final_opens_on, !d.isEmpty { return d }
    guard (finish?.isEmpty == false ? finish! : "cup_final") == "cup_final" else { return nil }
    return cupFinalStart(end: s.ends_on, calendar: calendar)
  }

  /// `standings_snapshots.week_no` is **0-based** (`snapshot_week`), and every
  /// surface that shows one to a golfer must relabel it. It is relabelled at
  /// READ time and never recomputed client-side: the snapshot's own number is
  /// the record of which window it captured, and rewriting it would break the
  /// history it is.
  public static func snapshotWeekLabel(_ snapshotWeekNo: Int) -> Int { snapshotWeekNo + 1 }

  /// `totalWeeks()` — max(1, ceil((e−s)/7d)). **The declared fallback for
  /// `weeksTotal(_:)`, not a producer** (D246): call it only through that.
  public static func totalWeeks(start: String, end: String, calendar: Calendar = .current) -> Int {
    let days = CSDate.days(from: start, to: end, calendar: calendar) ?? 0
    return max(1, Int((Double(days) / 7).rounded(.up)))
  }

  /// `currentWeek()` — floor(days since start / 7) + 1, clamped to the season.
  /// **The declared fallback for `week(_:)`, not a producer** (D246): it fires
  /// only on a payload that predates `native_home` v3. Call it only through
  /// `week(_:today:)`.
  public static func currentWeek(start: String, end: String, today: String, calendar: Calendar = .current) -> Int {
    let since = CSDate.days(from: start, to: today, calendar: calendar) ?? 0
    let w = Int((Double(since) / 7).rounded(.down)) + 1
    return min(max(1, w), totalWeeks(start: start, end: end, calendar: calendar))
  }

  /// `cupFinalStart()` — ends_on − 27 days (§14.0/§14.3).
  public static func cupFinalStart(end: String, calendar: Calendar = .current) -> String { addDays(end, -27, calendar: calendar) }

  /// `seasonSpanText()` — "Sat Sep 5 → Sat Mar 6 · 26 wks", real weekdays (S2-01).
  public static func spanText(start: String, end: String, calendar: Calendar = .current) -> String {
    "\(dowMonDay(start, calendar: calendar)) → \(dowMonDay(end, calendar: calendar)) · \(totalWeeks(start: start, end: end, calendar: calendar)) wks"
  }

  /// `durLabel` — "6 wk" under eight weeks, months above.
  public static func durLabel(_ weeks: Int) -> String {
    weeks < 8 ? "\(weeks) wk" : "\(Int((Double(weeks) / 4.345).rounded())) mo"
  }

  /// `curMonth()` — the device's current month, long.
  public static func monthLong(_ today: String, calendar: Calendar = .current) -> String {
    guard let d = CSDate.local(today, calendar: calendar) else { return "" }
    return monthsLong[(calendar.component(.month, from: d)) - 1]
  }

  /// "YYYY-MM" of a calendar date — the key `myMonth` filters on.
  public static func monthKey(_ iso: String) -> String { String(iso.prefix(7)) }

  /// First day of the month that holds `today`, as ISO (the bye's `p_month`).
  public static func firstOfMonth(_ today: String) -> String { monthKey(today) + "-01" }

  /// M-17 / §14.0 · the day the CURRENT clash week closes — the last day of
  /// the seven-day window that holds `today`, keyed to the season's real
  /// first-tee weekday (`ClashMath.window`), never a hardcoded Sunday. A
  /// season that tees off on a Wednesday closes its weeks on Tuesdays.
  /// Before first tee this is the first week's close.
  public static func weekClose(start: String, today: String, calendar: Calendar = .current) -> String {
    let since = max(0, CSDate.days(from: start, to: today, calendar: calendar) ?? 0)
    return addDays(start, (since / 7) * 7 + 6, calendar: calendar)
  }

  /// Next Sunday on or after `today` (today when it is Sunday).
  public static func nextSunday(_ today: String, calendar: Calendar = .current) -> String {
    guard let d = CSDate.local(today, calendar: calendar) else { return today }
    let wd = calendar.component(.weekday, from: d) - 1   // 0 = Sunday
    return addDays(today, (7 - wd) % 7, calendar: calendar)
  }

  public static func firstOfNextMonth(_ today: String, calendar: Calendar = .current) -> String {
    guard let d = CSDate.local(today, calendar: calendar),
          let next = calendar.date(byAdding: .month, value: 1, to: d) else { return today }
    let c = calendar.dateComponents([.year, .month], from: next)
    return String(format: "%04d-%02d-01", c.year ?? 0, c.month ?? 1)
  }

  public static func daysInMonth(_ today: String, calendar: Calendar = .current) -> Int {
    guard let d = CSDate.local(today, calendar: calendar), let r = calendar.range(of: .day, in: .month, for: d) else { return 30 }
    return r.count
  }
}
