// Cup Season — the roster door (D180). One reader for "can a code still get in,
// and when does that stop", so the Pro's screen and the server's `_join_gate`
// cannot drift.
//
// Five of the seven locked leagues in production were born with a DEAD join
// code — Fellas locked 2026-07-20 with a first tee of 2026-07-20, and its code
// has never worked once. D161 wrote the window as [lock, first tee) assuming
// lock comes BEFORE first tee, and never handled lock >= first tee. Meanwhile
// nothing in the schema could CLOSE a code, so a league that filled on day one
// with a first tee a month out had a live link for a month.
//
//   opens   at lock
//   closes  when the Pro closes it — or at first tee if they never do
//   floor   a league locked ON OR AFTER first tee gets a week regardless,
//           so a link is never born dead
//
// The floor is a backstop, not a rule anyone has to learn: it exists only so
// "lock opens the invite link" is true in every case. It does NOT widen the
// window for a league locked before first tee — that is D161's ruling, intact.
//
// This is the ROSTER, not the season. `seasons.starts_on` still begins the
// season and still drives week numbers, clash windows, month closes and the
// Cup Final trigger. Conflating the two is what caused the bug.

import Foundation

public enum RosterDoor: Sendable, Equatable {
  /// Open until the Pro closes it or first tee arrives, whichever is first.
  case open(closesOn: String?)
  /// Open only because of the lock floor — a league locked at or after its own
  /// first tee. This is the case that used to be dead on arrival.
  case grace(closesOn: String)
  /// The Pro closed it.
  case closedByPro(on: Date?)
  /// First tee passed (or the floor ran out) and nobody closed it — the date
  /// rule shut it on its own.
  case closedByTime

  public var isOpen: Bool {
    switch self { case .open, .grace: return true; case .closedByPro, .closedByTime: return false }
  }

  /// `settings.locked_at` / `settings.roster_closed_at` + the season's first
  /// tee. `today` and `calendar` are injected so this is testable without a
  /// clock — and so the date maths never touches an ISO parser (CSDate rule).
  public static func of(lockedAt: Date?,
                        closedAt: Date?,
                        startsOn: String?,
                        today: String = CSDate.today(),
                        calendar: Calendar = .current) -> RosterDoor {
    if let closedAt { return .closedByPro(on: closedAt) }
    // no locked season yet: the door is simply open, with nothing to report
    guard let startsOn, !startsOn.isEmpty else { return .open(closesOn: nil) }
    if today < startsOn { return .open(closesOn: startsOn) }

    // the floor — only for a league locked ON OR AFTER its own first tee
    guard let lockedAt else { return .closedByTime }
    let lockDay = CSDate.iso(lockedAt, calendar: calendar)
    guard lockDay >= startsOn else { return .closedByTime }
    let last = LeagueDates.addDays(lockDay, 7, calendar: calendar)
    return today <= last ? .grace(closesOn: last) : .closedByTime
  }

  /// The Pro's line. States the door, never scolds the Pro for the date they
  /// picked — D179 shipped a warning here and it was the wrong instrument.
  public func line(_ calendar: Calendar = .current) -> String {
    switch self {
    case .open(let on):
      guard let on else { return "The invite link works until you close the roster." }
      return "Works until you close it, or until first tee — \(LeagueDates.dowMonDay(on, calendar: calendar))."
    case .grace(let on):
      return "Works until you close it, or until \(LeagueDates.dowMonDay(on, calendar: calendar))."
    case .closedByPro:
      return "You closed the roster. Add anyone yourself until the halfway turn."
    case .closedByTime:
      return "The link has closed. Add anyone yourself until the halfway turn."
    }
  }

  /// The eyebrow over it: "ROSTER OPEN · 5 IN".
  public func eyebrow(members: Int) -> String {
    (isOpen ? "ROSTER OPEN" : "ROSTER CLOSED") + " · \(members) IN"
  }
}
