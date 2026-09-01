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
  /// A Debug build holds a SANDBOX APNs token; TestFlight / App Store builds
  /// hold production ones. The sender routes each token to its own host
  /// (migration 20260828010000) — so a tethered dev phone and a TestFlight
  /// phone receive push side by side.
  #if DEBUG
  public static let platform = "ios-sandbox"
  #else
  public static let platform = "ios"
  #endif

  public private(set) var enabled: Bool
  public private(set) var busy = false
  /// The toggle says ON off a local key; this says whether the SERVER agrees.
  /// A launch sync that fails leaves a phone that believes it is registered and
  /// a `device_tokens` table that has never heard of it — the runbook's
  /// "permission granted, no token, nothing ever arrives", with nothing said.
  public private(set) var unconfirmed = false
  private var pendingRegistration: CheckedContinuation<String?, Never>?
  /// Which ask a resume belongs to — a late timeout must never answer the next one.
  private var askGeneration = 0
  private let svc = SupabaseService.shared

  private init() {
    enabled = UserDefaults.standard.string(forKey: Self.tokenKey) != nil
  }

  /// Called by the app delegate with Apple's token.
  public func didRegister(deviceToken: Data) {
    let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
    finishAsk(hex)
  }

  public func didFailToRegister(_ error: Error) { finishAsk(nil) }

  /// Exactly one resume per ask, whoever gets here first.
  private func finishAsk(_ token: String?) {
    guard let c = pendingRegistration else { return }
    pendingRegistration = nil
    askGeneration += 1
    c.resume(returning: token)
  }

  /// Apple answers on the app delegate; a continuation bridges the gap. Two
  /// rules, both learned from the shape this had: only ONE ask may be in flight
  /// (a second overwrote the first continuation, leaking it — a checked
  /// continuation misuse trap in Debug), and an ask must always END. APNs can
  /// simply never call back (no network, no APNs socket, a device that has not
  /// finished waking) and this awaited forever, taking the launch task with it.
  private func requestAppleToken(timeout: Duration = .seconds(10)) async -> String? {
    #if canImport(UIKit)
    guard pendingRegistration == nil else { return nil }   // one ask at a time
    askGeneration += 1
    let gen = askGeneration
    return await withCheckedContinuation { (c: CheckedContinuation<String?, Never>) in
      pendingRegistration = c
      UIApplication.shared.registerForRemoteNotifications()
      Task { @MainActor in
        try? await Task.sleep(for: timeout)
        guard self.askGeneration == gen else { return }    // already answered
        self.finishAsk(nil)
      }
    }
    #else
    nil
    #endif
  }

  /// `syncNativePush` — re-register only if permission already stands.
  /// A cold launch routinely races the network, so one failure is not a verdict:
  /// try twice, then SAY so rather than swallowing it (`catch {}` was how a
  /// tester could carry a phone all weekend with the toggle reading ON and no
  /// row on the server).
  public func syncOnLaunch() async {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    guard settings.authorizationStatus == .authorized else { return }
    guard let tok = await requestAppleToken() else { unconfirmed = enabled; return }
    for attempt in 1...2 {
      do {
        try await svc.call(Rpc.register_device_token(p_token: tok, p_platform: Self.platform))
        UserDefaults.standard.set(tok, forKey: Self.tokenKey)
        enabled = true
        unconfirmed = false
        return
      } catch {
        if attempt == 1 { try? await Task.sleep(for: .seconds(2)) }
      }
    }
    unconfirmed = true
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
      try await svc.call(Rpc.register_device_token(p_token: tok, p_platform: Self.platform))
    } catch {
      return AuthRules.human(error, fallback: "Could not save this device.")
    }
    UserDefaults.standard.set(tok, forKey: Self.tokenKey)
    enabled = true
    unconfirmed = false
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
    unconfirmed = false
    return "Notifications off on this device"
  }
}
