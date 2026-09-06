// Cup Season — IOS-034 · what the home screen is allowed to know.
//
// COMPILED INTO BOTH TARGETS, the way `CSRoundActivity.swift` already is
// (`project.yml`): the app writes it, the widget extension reads it, and the
// extension keeps no network client of its own — it depends on CSDesign and
// nothing else, deliberately. So this file imports Foundation and nothing
// else. A type that reaches for `MeStripCopy` here would drag the whole Kit
// into an extension whose entire job is to draw eight words.
//
// Three rules are built in rather than left to the drawing code:
//
//   L-44 · IT NEVER LIES ABOUT TIME. The snapshot stamps the moment it was
//     written. Past `staleAfter` (24 h) the widget says AS OF SAT · OPEN TO
//     REFRESH and `verb` returns nil — a door that may no longer open is not
//     offered. The Live Activity's 45-minute rule, at a day's scale.
//
//   L-10 · MONEY NEVER APPEARS. A member's unpaid state is self-only and a
//     home screen is not private, so `Fact.money` cannot be constructed:
//     `sanitised` drops it on the way in, and `WidgetSnapshotTests` proves the
//     drop rather than trusting the caller.
//
//   L-34 · ONE FACT, ONE PLACE. The four facts are the ME strip's own, in the
//     strip's order, produced ONCE by `MeStripCopy` and copied here — never
//     re-derived from a payload the widget cannot read anyway.

import Foundation

/// The App Group the app and the widget share. Registered in the developer
/// portal by the owner (IOS-034 steps 1 and 4); both entitlements files name
/// this exact string, and `project.yml` writes both of them.
public enum CSAppGroup {
  public static let id = "group.app.cupseason.shared"
  public static let snapshotKey = "home.dispatch.snapshot"
}

/// What the app hands the home screen after a successful `home_dispatch`.
public struct DispatchSnapshot: Codable, Sendable, Equatable {
  /// One of the ME strip's four facts, flattened to two strings.
  public struct Fact: Codable, Sendable, Equatable {
    public let label: String
    public let value: String
    public init(label: String, value: String) { self.label = label; self.value = value }
  }

  /// `FELLAS · WEEK 7 OF 26 · SEASON LIVE` — the season row, verbatim.
  public let seasonRow: String?
  /// The strip's facts, in the strip's order. Money is never among them.
  public let facts: [Fact]
  /// The lead card's own eyebrow, headline and verb, and the route its door
  /// lands on. Any of them may be absent; an absent headline means the app had
  /// no lead, which the widget renders as the season row alone.
  public let leadEyebrow: String?
  public let leadHeadline: String?
  public let leadVerb: String?
  public let leadRoute: String?
  /// When the app wrote this.
  public let savedAt: Date

  /// Labels a home screen may never carry (L-10). Matched case-insensitively
  /// on the label the strip produced, so a reworded money fact is still caught.
  public static let bannedLabels = ["still owe", "owe", "pot", "buy-in"]

  public init(seasonRow: String?, facts: [Fact], leadEyebrow: String? = nil, leadHeadline: String? = nil,
              leadVerb: String? = nil, leadRoute: String? = nil, savedAt: Date = Date()) {
    self.seasonRow = seasonRow
    self.facts = DispatchSnapshot.sanitised(facts)
    self.leadEyebrow = leadEyebrow
    self.leadHeadline = leadHeadline
    self.leadVerb = leadVerb
    self.leadRoute = leadRoute
    self.savedAt = savedAt
  }

  /// L-10 — the money fact cannot reach a lock screen, whoever passes it.
  public static func sanitised(_ facts: [Fact]) -> [Fact] {
    facts.filter { f in
      let l = f.label.lowercased()
      return !bannedLabels.contains { l == $0 || l.hasPrefix($0 + " ") || l.hasSuffix(" " + $0) }
    }
  }

  public static let staleAfter: TimeInterval = 24 * 60 * 60

  public func isStale(now: Date = Date()) -> Bool { now.timeIntervalSince(savedAt) >= Self.staleAfter }

  /// `AS OF 2:22 PM` while it is fresh; `AS OF SAT · OPEN TO REFRESH` once it
  /// is not. The widget never draws a bare time.
  public func asOf(now: Date = Date(), calendar: Calendar = .current, locale: Locale = .current) -> String {
    var cal = calendar
    cal.locale = locale
    if isStale(now: now) {
      let day = cal.shortWeekdaySymbols[cal.component(.weekday, from: savedAt) - 1].uppercased()
      return "AS OF \(day) · OPEN TO REFRESH"
    }
    // C-15 · the LOCALE's own hour cycle. `%d:%02d` off `.hour` printed a
    // 24-hour clock on every device, so a US home screen read AS OF 14:22
    // beside a phone that says 2:22p everywhere else.
    let f = DateFormatter()
    f.locale = locale
    f.calendar = cal
    f.timeZone = cal.timeZone
    f.setLocalizedDateFormatFromTemplate("jmm")
    return "AS OF \(f.string(from: savedAt).uppercased())"
  }

  /// The lead's verb, and nothing once the snapshot is stale: offering an act
  /// off a day-old read is the lie L-44 forbids.
  public func verb(now: Date = Date()) -> String? { isStale(now: now) ? nil : leadVerb }

  /// Where a tap lands. The lead's own route while fresh, Home otherwise.
  public func url(now: Date = Date()) -> URL {
    if !isStale(now: now), let r = leadRoute, let u = URL(string: r) { return u }
    return URL(string: "cupseason://home")!
  }

  // MARK: the shared container

  public static func read(_ defaults: UserDefaults? = UserDefaults(suiteName: CSAppGroup.id)) -> DispatchSnapshot? {
    guard let data = defaults?.data(forKey: CSAppGroup.snapshotKey) else { return nil }
    return try? JSONDecoder().decode(DispatchSnapshot.self, from: data)
  }

  /// P3f · the HOME SCREEN is not behind a session. The snapshot is a season
  /// row, an index, a last round and a lead headline sitting on a widget that
  /// anyone holding the phone can read, and it survived a sign-out — so a
  /// golfer who signed out kept broadcasting their season to the next person
  /// to pick the phone up. `SessionStore.signOut()` clears it. The offline
  /// COURSE books are different and deliberately outlive a sign-out (OE-2):
  /// they sit inside the app behind a session, and every door onto them does
  /// too. A widget has no door.
  public static func forget(_ defaults: UserDefaults? = UserDefaults(suiteName: CSAppGroup.id)) {
    defaults?.removeObject(forKey: CSAppGroup.snapshotKey)
  }

  @discardableResult
  public func write(_ defaults: UserDefaults? = UserDefaults(suiteName: CSAppGroup.id)) -> Bool {
    guard let d = defaults, let data = try? JSONEncoder().encode(self) else { return false }
    d.set(data, forKey: CSAppGroup.snapshotKey)
    return true
  }
}
