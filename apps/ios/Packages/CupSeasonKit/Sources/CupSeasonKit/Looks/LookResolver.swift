// Cup Season — which look a surface wears (D103a, IOS-025).
//
// Pure. Three dials, one precedence, top wins:
//   1. a league's PHASE look   — cup_final → `cupfinal`, wrapped → `wrap`
//   2. a league's curated look — the Pro's `leagues.look`
//   3. the person's own dial   — the calendar (default) · one look · none
//   4. nothing                 — homebase (Fescue)
// A league dial only counts when a league is in scope (its room, its hero).
// An unknown key is treated as absent — the phone fails closed to homebase,
// never to a colour it cannot name. Gold is never this file's business: a
// look proposes an accent; the surface keeps gold when it has earned it.

import Foundation
import CSDesign

/// The person's dial — device-local like the theme (`cs_look`), never on the profile.
public enum PersonalLook: Equatable, Sendable {
  /// The calendar look whose window holds today, or homebase between windows.
  case calendar
  /// One look, all year.
  case fixed(String)
  /// Fescue only.
  case none

  public static let storageKey = "cs_look"
  public static let `default`: PersonalLook = .calendar

  public var rawValue: String {
    switch self {
    case .calendar: "calendar"
    case .none: "none"
    case .fixed(let k): k
    }
  }

  public init(rawValue: String?) {
    switch rawValue {
    case nil, "", "calendar": self = .calendar
    case "none": self = .none
    case let k?: self = .fixed(k)
    }
  }

  public static func load(_ defaults: UserDefaults = .standard) -> PersonalLook {
    PersonalLook(rawValue: defaults.string(forKey: storageKey))
  }

  public func save(_ defaults: UserDefaults = .standard) {
    defaults.set(rawValue, forKey: Self.storageKey)
  }
}

public enum LookResolver {
  /// The calendar look for a date: the first spec whose window holds the day.
  /// The Ryder (`oddYearsOnly`) shows in 2025, 2027… and yields to Fall in even years.
  public static func calendarLook(date: Date, calendar: Calendar = .current) -> CSLookSpec? {
    let c = calendar.dateComponents([.year, .month, .day], from: date)
    guard let y = c.year, let m = c.month, let d = c.day else { return nil }
    return CSLooks.calendar.first { spec in
      guard let w = spec.window else { return false }
      if spec.oddYearsOnly && y % 2 == 0 { return false }
      return Occasion.inWindow(w, month: m, day: d)
    }
  }

  /// The phase look a league's season turns on — nil outside the two phases.
  public static func phaseLook(_ phase: SeasonPhase?) -> CSLookSpec? {
    switch phase {
    case .cupFinal: CSLooks.spec("cupfinal")
    case .wrapped: CSLooks.spec("wrap")
    default: nil
    }
  }

  /// The person's dial, resolved for a date. An unknown fixed key is homebase.
  public static func personalLook(_ personal: PersonalLook, date: Date, calendar: Calendar = .current) -> CSLookSpec? {
    switch personal {
    case .calendar: calendarLook(date: date, calendar: calendar)
    case .fixed(let key): CSLooks.spec(key)
    case .none: nil
    }
  }

  /// D103a precedence. `leaguePhase` non-nil means a league is in scope;
  /// `leagueLook` is that league's curated key (nil = the Pro left it to the
  /// calendar). A league key the catalogue does not know, or a phase key
  /// where a calendar key belongs, counts as absent.
  public static func resolve(date: Date = Date(), calendar: Calendar = .current,
                             leaguePhase: SeasonPhase?, leagueLook: String?, personal: PersonalLook) -> CSLookSpec? {
    if let p = phaseLook(leaguePhase) { return p }
    if leaguePhase != nil, let k = leagueLook, let s = CSLooks.spec(k), s.window != nil { return s }
    return personalLook(personal, date: date, calendar: calendar)
  }
}

/// Copy for the two dials — short, in the app's voice.
public enum LookCopy {
  private static let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

  /// "Jul 10 – 24" · "Mar 28 – Apr 13" · "odd years · Sep 18 – Oct 5".
  public static func window(_ spec: CSLookSpec) -> String? {
    guard let w = spec.window else { return nil }
    let m1 = months[max(0, min(11, w.0 - 1))], m2 = months[max(0, min(11, w.2 - 1))]
    let span = w.0 == w.2 ? "\(m1) \(w.1) – \(w.3)" : "\(m1) \(w.1) – \(m2) \(w.3)"
    return spec.oddYearsOnly ? "odd years · \(span)" : span
  }

  /// The "Follow the calendar" sub-line: "Claret · Jul 10 – 24" or "Fescue · no look this week".
  public static func calendarLine(_ current: CSLookSpec?) -> String {
    guard let current, let w = window(current) else { return "Fescue · no look this week" }
    return "\(current.name) · \(w)"
  }

  /// The member's read-only line on the League pane.
  public static func roomLine(_ spec: CSLookSpec?) -> String {
    guard let spec else { return "Room look · follows the calendar" }
    return "Room look · \(spec.name) · set by the Pro"
  }

  /// The Pro's toast after a write.
  public static func dressed(_ spec: CSLookSpec?) -> String {
    guard let spec else { return "The room follows the calendar" }
    return "The room's wearing \(spec.name)"
  }
}
