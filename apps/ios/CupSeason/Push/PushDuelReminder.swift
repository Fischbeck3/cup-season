// Cup Season — the local reminder (push-contract §7). The room's load hands
// its `EventRoom` here; `PushDuelPlan` says what to schedule and what to
// cancel, and this file is the only place that talks to the notification
// center about it. The reminder carries a contract payload of its own
// (`kind: event`), so a tap lands in the room through the same router.

import Foundation
import UserNotifications
import CupSeasonKit

enum PushDuelReminder {
  /// Reconcile the room's sessions with what is scheduled.
  @MainActor
  static func sync(room: EventRoom) async {
    let me = await SupabaseService.shared.currentSession()?.user.id
    let plan = PushDuelPlan.make(room: room, me: me)
    let center = UNUserNotificationCenter.current()
    if !plan.cancel.isEmpty { center.removePendingNotificationRequests(withIdentifiers: plan.cancel) }
    guard !plan.schedule.isEmpty else { return }
    let status = await center.notificationSettings().authorizationStatus
    guard status == .authorized || status == .provisional else { return }
    let tz = TimeZone(identifier: room.event.tz ?? PushDuelPlan.defaultTimeZone) ?? TimeZone(identifier: PushDuelPlan.defaultTimeZone)!
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = tz
    for r in plan.schedule {
      let content = UNMutableNotificationContent()
      content.title = PushDuelPlan.title
      content.body = PushDuelPlan.body
      content.subtitle = r.eventName
      content.sound = .default
      content.threadIdentifier = room.event.id.uuidString.lowercased()
      content.userInfo = ["cs": ["v": PushPayload.version, "kind": PushKind.event.rawValue, "event_id": room.event.id.uuidString.lowercased()]]
      var comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: r.fireAt)
      comps.timeZone = tz
      let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
      try? await center.add(UNNotificationRequest(identifier: r.identifier, content: content, trigger: trigger))
    }
  }

  /// A round just posted: every duel reminder is moot (one card serves every
  /// open session). The next room load re-plans whatever still stands.
  static func cancelAll() async {
    let center = UNUserNotificationCenter.current()
    let ids = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix("duel-") }
    if !ids.isEmpty { center.removePendingNotificationRequests(withIdentifiers: ids) }
  }
}
