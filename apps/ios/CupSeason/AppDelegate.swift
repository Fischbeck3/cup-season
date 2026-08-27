// Cup Season — UIKit hooks the SwiftUI app cannot express: the APNs token.

import UIKit
import CupSeasonKit

final class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Task { @MainActor in PushService.shared.didRegister(deviceToken: deviceToken) }
  }
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    Task { @MainActor in PushService.shared.didFailToRegister(error) }
  }
}
