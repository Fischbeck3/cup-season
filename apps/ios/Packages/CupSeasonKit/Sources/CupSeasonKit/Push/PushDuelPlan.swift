// Cup Season — the local reminder's arithmetic (push-contract §7). For an
// open Ryder session that closes TODAY (league time) where I am in a pending
// duel and my side has no round: one reminder at 18:00 that day, identifier
// `duel-<session_id>`. Every other session of the room gets its reminder
// cancelled — the round posted, or the session resolved. Pure: the room in,
// a plan of schedules and cancels out; the notification center is the
// caller's.

import Foundation

public struct PushDuelPlan: Sendable, Equatable {
  public struct Reminder: Sendable, Equatable {
    public let identifier: String
    public let sessionId: UUID
    public let fireAt: Date
    public let eventName: String
  }
  /// Requests to (re)schedule.
  public let schedule: [Reminder]
  /// Identifiers to remove — every session of the room that no longer qualifies.
  public let cancel: [String]

  public static let hour = 18
  public static let defaultTimeZone = "America/Phoenix"
  public static func identifier(_ session: UUID) -> String { "duel-\(session.uuidString.lowercased())" }

  /// `me` is my profile id; nil (signed out, unknown) plans only cancels.
  public static func make(room: EventRoom, me: UUID?, now: Date = Date()) -> PushDuelPlan {
    let tz = TimeZone(identifier: room.event.tz ?? defaultTimeZone) ?? TimeZone(identifier: defaultTimeZone)!
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = tz
    let today = CSDate.iso(now, calendar: cal)
    let myPlayer = me.flatMap { pid in room.players.first { $0.profileId == pid }?.id }

    var schedule: [Reminder] = []
    var cancel: [String] = []
    for s in room.sessions {
      let id = identifier(s.id)
      guard s.isOpen, s.closes_on == today, let mine = myPlayer, !room.event.isMajor else { cancel.append(id); continue }
      // my pending duel this session, my side still without a card
      let waiting = room.duels.contains { d in
        d.session_id == s.id && d.isPending &&
          ((d.a_player == mine && d.a_round == nil) || (d.b_player == mine && d.b_round == nil))
      }
      guard waiting, let fire = CSDate.local(s.closes_on, calendar: cal).flatMap({ cal.date(bySettingHour: hour, minute: 0, second: 0, of: $0) }),
            fire > now else { cancel.append(id); continue }
      schedule.append(Reminder(identifier: id, sessionId: s.id, fireAt: fire, eventName: room.event.name))
    }
    return PushDuelPlan(schedule: schedule, cancel: cancel)
  }

  /// The words (§7), verbatim.
  public static let title = "Your duel closes tonight"
  public static let body = "You haven’t posted."
}
