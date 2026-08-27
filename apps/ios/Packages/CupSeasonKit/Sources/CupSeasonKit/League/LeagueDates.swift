// Cup Season — the season's calendar arithmetic (index.html 11767–11801,
// 9406–9500), on calendar days, never on UTC instants.

import Foundation

public enum LeagueDates {
  public static let dow = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
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

  /// `totalWeeks()` — max(1, ceil((e−s)/7d)).
  public static func totalWeeks(start: String, end: String, calendar: Calendar = .current) -> Int {
    let days = CSDate.days(from: start, to: end, calendar: calendar) ?? 0
    return max(1, Int((Double(days) / 7).rounded(.up)))
  }

  /// `currentWeek()` — floor(days since start / 7) + 1, clamped to the season.
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
