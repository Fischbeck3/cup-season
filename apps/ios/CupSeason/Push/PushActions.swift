// Cup Season — the lock-screen answers (push-contract §3). Three categories,
// registered at launch; each action runs in the background — no
// `.foreground` — through the SAME RPC the screen would call, then the
// badge is recomputed (§4). On failure a local line in voice, so the golfer
// knows to open the app; the lock screen already asked, so Decline / Can’t
// never ask twice.

import Foundation
import UserNotifications
import CupSeasonKit

enum PushCategories {
  /// Idempotent; call once at launch before any notification can arrive.
  static func register() {
    let cats = PushCategory.allCases.map { c in
      UNNotificationCategory(
        identifier: c.rawValue,
        actions: c.actions.map { UNNotificationAction(identifier: $0.id, title: $0.title, options: []) },
        intentIdentifiers: [],
        options: [])
    }
    UNUserNotificationCenter.current().setNotificationCategories(Set(cats))
  }
}

enum PushActionRunner {
  /// The failure line, in voice.
  static let failedBody = "That one didn’t take — open the app."

  /// Run one action, recompute the badge, tell the golfer if it failed.
  @MainActor
  static func run(_ call: PushActionCall, kind: String, title: String) async {
    do {
      try await call.run()
      CSTelemetry.event("push_action", ["kind": .string(kind), "ok": .bool(true)])
    } catch {
      CSTelemetry.event("push_action", ["kind": .string(kind), "ok": .bool(false)])
      await didNotTake(title: title)
    }
    await PushBadge.refresh()
  }

  private static func didNotTake(title: String) async {
    let content = UNMutableNotificationContent()
    content.title = title.isEmpty ? "Cup Season" : title
    content.body = failedBody
    content.sound = .default
    content.threadIdentifier = "you"
    let req = UNNotificationRequest(identifier: "action-failed-\(UUID().uuidString)", content: content, trigger: nil)
    try? await UNUserNotificationCenter.current().add(req)
  }
}
