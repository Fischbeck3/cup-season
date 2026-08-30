// Cup Season — UIKit hooks the SwiftUI app cannot express: the APNs token,
// the MetricKit subscription (IOS-024 — the phone's crash source), and the
// notification center delegate (D104 — a tap routes, an action answers).

import UIKit
import UserNotifications
import CupSeasonKit

final class AppDelegate: NSObject, UIApplicationDelegate {
  /// Retained for the life of the process; MetricKit holds it weakly.
  private let metrics = MetricsSubscriber()

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    metrics.start()
    UNUserNotificationCenter.current().delegate = self
    PushCategories.register()
    // a cold start from a notification tap: stash it; the tab shell drains it at `.ready`
    if let info = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
      PushRouter.shared.open(userInfo: info)
    }
    return true
  }
  /// D152 · landscape is declared in the Info.plist but handed out only while a
  /// live round is on screen (OrientationGate). Every other screen answers
  /// portrait, so none of them had to be audited for a rotation they will never
  /// be asked to perform. UIKit re-asks this on every rotation attempt, so the
  /// gate flipping is enough — no hosting-controller subclass needed.
  @MainActor
  func application(_ application: UIApplication,
                   supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    OrientationGate.shared.landscapeAllowed ? [.portrait, .landscapeLeft, .landscapeRight] : .portrait
  }

  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Task { @MainActor in PushService.shared.didRegister(deviceToken: deviceToken) }
  }
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    Task { @MainActor in PushService.shared.didFailToRegister(error) }
  }
}

// MARK: - UNUserNotificationCenterDelegate (push-contract §2, §3)

extension AppDelegate: UNUserNotificationCenterDelegate {
  /// Foreground: a banner and the sound — never a badge bump from the
  /// payload; the badge is the actionable count and the app recomputes it.
  nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                          willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
    #if DEBUG
    if PushDev.autoOpen, let p = PushPayload(userInfo: notification.request.content.userInfo) {
      await MainActor.run { PushRouter.shared.open(p) }
    }
    #endif
    return [.banner, .list, .sound]
  }

  /// A tap, or a lock-screen action. Everything the response carries is read
  /// here, on the delegate's thread, into Sendable values before the hop.
  nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
    let content = response.notification.request.content
    let action = response.actionIdentifier
    let title = content.title
    let payload = PushPayload(userInfo: content.userInfo)
    let unreadable = payload == nil

    switch action {
    case UNNotificationDismissActionIdentifier:
      return
    case UNNotificationDefaultActionIdentifier:
      await MainActor.run {
        if let payload { PushRouter.shared.open(payload) } else if unreadable { PushRouter.shared.pending = .home }
      }
    default:
      // a category action — background, the screen's own RPC, then the badge
      guard let payload, let call = PushActionCall.resolve(category: payload.category, action: action, payload: payload) else { return }
      await PushActionRunner.run(call, kind: payload.kind?.rawValue ?? "unknown", title: title)
    }
  }
}
