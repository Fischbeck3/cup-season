// Cup Season — D152: landscape, for exactly one screen.
//
// The app is portrait everywhere. Live scoring is the one place a wider window
// earns something — the whole card instead of one hole — so landscape is
// DECLARED as supported in the Info.plist and then handed out only while a live
// round is on screen.
//
// The mechanism is UIKit's, not a hosting-controller shim:
// `application(_:supportedInterfaceOrientationsFor:)` is consulted every time
// the system considers a rotation, so flipping this flag is enough. Everything
// else in the app keeps answering `.portrait`, which means no other screen has
// to be audited for a rotation it will never be asked to perform.
//
// Web sibling: `index.html`'s `.playgrid` breakpoint + `body.cardview`.

import SwiftUI

/// Whether the live round is currently allowed to rotate.
///
/// Main-actor isolated on purpose: `supportedInterfaceOrientationsFor` is a
/// main-thread callback, and the only writers are `.onAppear`/`.onDisappear`.
@MainActor
final class OrientationGate {
  static let shared = OrientationGate()
  private init() {}

  /// Set while `LiveRoundHost` has a live round up. Read by the app delegate.
  private(set) var landscapeAllowed = false

  func allowLandscape(_ on: Bool) {
    guard landscapeAllowed != on else { return }
    landscapeAllowed = on
    // Leaving the round must not strand the phone sideways on a portrait-only
    // screen: ask the window back to portrait rather than waiting for the user
    // to physically rotate it.
    if !on { Self.forcePortrait() }
  }

  #if DEBUG
  /// `-cs_dev_landscape` — start the live round sideways, so the card can be
  /// reviewed on a headless simulator (osascript cannot send the rotate
  /// keystroke without Accessibility permission).
  static var forceLandscapeForReview: Bool {
    ProcessInfo.processInfo.arguments.contains("-cs_dev_landscape")
  }
  static func requestLandscape() {
    guard let scene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive })
    else { return }
    scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
  }
  #endif

  private static func forcePortrait() {
    guard let scene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive })
    else { return }
    scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
    scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
  }
}

/// Attach to the screen that may rotate.
private struct LandscapeAllowed: ViewModifier {
  func body(content: Content) -> some View {
    content
      .onAppear {
        OrientationGate.shared.allowLandscape(true)
        #if DEBUG
        if OrientationGate.forceLandscapeForReview {
          Task { try? await Task.sleep(for: .milliseconds(700)); OrientationGate.requestLandscape() }
        }
        #endif
      }
      .onDisappear { OrientationGate.shared.allowLandscape(false) }
  }
}

extension View {
  /// D152 · this screen may be viewed sideways; every other screen may not.
  func csAllowsLandscape() -> some View { modifier(LandscapeAllowed()) }
}
