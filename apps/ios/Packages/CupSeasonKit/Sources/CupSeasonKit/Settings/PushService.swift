// Cup Season — APNs registration (audit 05 §2G; index.html 14011–14090).
//
// One toggle, one transport. The server side — `device_tokens`, the
// `register_device_token` / `unregister_device_token` RPCs and the push
// function's APNs branch — is built; delivery lights when the APNs secrets
// are set (IOS-005 M4/wave 7). The phone's job today is the web's: ask, get
// a token, register it, re-register silently on every signed-in launch when
// permission already stands (APNs re-issues tokens), unregister on toggle-off.
// Push must never be able to fail a boot.

import Foundation
import Observation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
public final class PushService {
  public static let shared = PushService()
  public static let tokenKey = "cs_apns_token"   // the web's APNS_KEY

  public private(set) var enabled: Bool
  public private(set) var busy = false
  private var pendingRegistration: CheckedContinuation<String?, Never>?
  private let svc = SupabaseService.shared

  private init() {
    enabled = UserDefaults.standard.string(forKey: Self.tokenKey) != nil
  }

  /// Called by the app delegate with Apple's token.
  public func didRegister(deviceToken: Data) {
    let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
    pendingRegistration?.resume(returning: hex)
    pendingRegistration = nil
  }

  public func didFailToRegister(_ error: Error) {
    pendingRegistration?.resume(returning: nil)
    pendingRegistration = nil
  }

  private func requestAppleToken() async -> String? {
    #if canImport(UIKit)
    await withCheckedContinuation { c in
      pendingRegistration = c
      UIApplication.shared.registerForRemoteNotifications()
    }
    #else
    nil
    #endif
  }

  /// `syncNativePush` — re-register only if permission already stands.
  public func syncOnLaunch() async {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    guard settings.authorizationStatus == .authorized else { return }
    guard let tok = await requestAppleToken() else { return }
    do {
      try await svc.call(Rpc.register_device_token(p_token: tok, p_platform: "ios"))
      UserDefaults.standard.set(tok, forKey: Self.tokenKey)
      enabled = true
    } catch {}
  }

  /// `enablePush` — returns the toast copy to show.
  public func enable() async -> String {
    busy = true
    defer { busy = false }
    let center = UNUserNotificationCenter.current()
    var status = await center.notificationSettings().authorizationStatus
    if status != .authorized {
      _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
      status = await center.notificationSettings().authorizationStatus
    }
    guard status == .authorized else { return "Notifications blocked: allow them in Settings" }
    guard let tok = await requestAppleToken() else { return "Could not get a device token from Apple. Try again." }
    do {
      try await svc.call(Rpc.register_device_token(p_token: tok, p_platform: "ios"))
    } catch {
      return AuthRules.human(error, fallback: "Could not save this device.")
    }
    UserDefaults.standard.set(tok, forKey: Self.tokenKey)
    enabled = true
    return "Notifications on. The board will find you."
  }

  /// `disablePush` — the row must go or the phone keeps buzzing after the
  /// toggle says off.
  public func disable() async -> String {
    busy = true
    defer { busy = false }
    if let tok = UserDefaults.standard.string(forKey: Self.tokenKey) {
      try? await svc.call(Rpc.unregister_device_token(p_token: tok))
    }
    UserDefaults.standard.removeObject(forKey: Self.tokenKey)
    enabled = false
    return "Notifications off on this device"
  }
}
