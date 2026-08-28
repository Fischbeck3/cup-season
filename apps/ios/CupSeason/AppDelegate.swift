// Cup Season — UIKit hooks the SwiftUI app cannot express: the APNs token,
// and the MetricKit subscription (IOS-024 — the phone's crash source).

import UIKit
import CupSeasonKit

final class AppDelegate: NSObject, UIApplicationDelegate {
  /// Retained for the life of the process; MetricKit holds it weakly.
  private let metrics = MetricsSubscriber()

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    metrics.start()
    return true
  }
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Task { @MainActor in PushService.shared.didRegister(deviceToken: deviceToken) }
  }
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    Task { @MainActor in PushService.shared.didFailToRegister(error) }
  }
}
