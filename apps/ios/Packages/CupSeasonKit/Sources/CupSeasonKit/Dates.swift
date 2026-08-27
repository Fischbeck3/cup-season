// Cup Season — calendar dates, by parts.
//
// The landmine (CLAUDE.md): `new Date('YYYY-MM-DD')` parses as UTC midnight
// and renders the PREVIOUS day in Phoenix. Swift's ISO8601 parsers do the same
// thing. So a calendar date is a String of the form YYYY-MM-DD everywhere in
// the contract (the generator maps `date` to String on purpose), and the ONLY
// way through to a Date is here, in the device's calendar.

import Foundation

public enum CSDate {
  /// "2026-08-27" → the local-midnight Date of that calendar day.
  public static func local(_ iso: String, calendar: Calendar = .current) -> Date? {
    let parts = iso.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return nil }
    return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
  }

  /// A Date → "YYYY-MM-DD" in the device's calendar. Never `ISO8601`.
  public static func iso(_ date: Date, calendar: Calendar = .current) -> String {
    let c = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
  }

  public static func today(calendar: Calendar = .current) -> String { iso(Date(), calendar: calendar) }

  /// Whole days from `from` to `to` (calendar days, not 24h periods).
  public static func days(from: String, to: String, calendar: Calendar = .current) -> Int? {
    guard let a = local(from, calendar: calendar), let b = local(to, calendar: calendar) else { return nil }
    return calendar.dateComponents([.day], from: a, to: b).day
  }

  /// "Sat, Aug 22" — the label the hero and tee sheet use.
  public static func short(_ iso: String, calendar: Calendar = .current) -> String {
    guard let d = local(iso, calendar: calendar) else { return iso }
    let f = DateFormatter()
    f.calendar = calendar
    f.setLocalizedDateFormatFromTemplate("EEE MMM d")
    return f.string(from: d)
  }
}
