// Cup Season — what is left of the M0 component set (IOS-003 §2.4), and what
// is on its way out.
//
// D266 / IOS-045, CLOSED BY D278 / IOS-053 · `CSCard`, `CSStat`,
// `CSEmptyState` and `CSButton` ARE GONE. They were kept as declarations for
// eight waves with their removal wave named IN THIS FILE — Waves 1–7 took the
// seven surfaces, Wave 8 the remainder, **Wave 9 deleted the declarations** —
// and `LINT-30` counted the sites at a baseline that could only fall, so
// nothing new could be written against them while they waited. It worked:
// 157 → 111 → 14 → 0.
//
//   CSCard        → band · rule · rail · panel · leaf
//   CSStat        → CSFigure, the rule-and-figure
//   CSEmptyState  → CSEmpty, whose door is non-optional (LINT-21)
//   CSButton      → CSPrimaryStyle / CSSecondaryStyle / CSTertiaryStyle
//   CSButtonStyle.gold → THE TIER NEVER EXISTED AGAIN. Gold may never touch a
//                   control (`LINT-11`); a disabled primary is never ember.
//
// A shim with no named removal is not a shim; it is a second system. That is
// the whole reason these were removable at all, and it is the pattern anything
// retired after this should copy.
//
// What genuinely survives, and why: `CSHaptic` (IOS-003 §2.8's vocabulary,
// verbatim), `CSNote`, `CSTone`, the tab-bar room plumbing and
// `CSTabBarChrome` — the last of which becomes `CSTabBand`'s measurement.
// `CSField` moved to `Controls.swift`, where it gained the label, the caption,
// the error, the counter, the disabled and the loading states it never had.

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Note (status line in voice)

public enum CSTone { case mut, pos, neg, gold }

public struct CSNote: View {
  @Environment(\.cs) private var cs
  let text: String
  let tone: CSTone

  public init(_ text: String, tone: CSTone = .mut) { self.text = text; self.tone = tone }

  public var body: some View {
    Text(text)
      .font(CSFont.subhead)
      .foregroundStyle(color)
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityAddTraits(.updatesFrequently)
  }
  private var color: Color {
    switch tone {
    case .mut: cs.mut
    case .pos: cs.pos
    case .neg: cs.neg
    case .gold: cs.gold
    }
  }
}

// MARK: - Haptics (IOS-003 §2.8, IOS-022 item 6)

/// The whole vocabulary lives here. Imperative calls (`CSHaptic.success()`)
/// for handlers; `.csFeedback(_:trigger:)` — `sensoryFeedback` (iOS 17) —
/// for moments a view state announces (a ceremony appearing, a rank moving
/// on load, the tee-off). No haptic on scroll, on navigation, or on errors
/// that already toast.
public enum CSHaptic {
  /// One case per moment, so a screen names the MOMENT, never a generator.
  public enum Kind: Sendable {
    /// Stroke ±, reaction tap, marker pick, a pane switch.
    case selection
    /// Rank moved up on open (light) · hole complete, the tee-off, the ⊕ presenting (medium) · skins carry ≥2 (rigid).
    case rankUp, holeComplete, teeOff, present, skinsCarry
    /// POSTED ✓ / the finish ceremony — the thock.
    case posted
    /// Two-tap destructive arm ("Sure?").
    case armed

    public var sensory: SensoryFeedback {
      switch self {
      case .selection: .selection
      case .rankUp: .impact(weight: .light)
      case .holeComplete, .teeOff, .present: .impact(weight: .medium)
      case .skinsCarry: .impact(flexibility: .rigid)
      case .posted: .success
      case .armed: .warning
      }
    }
  }

  /// The ⊕ presenting over a tab (IOS-022 item 3).
  public static func present() { impact(.medium) }
  /// Stroke ±, reaction tap, marker pick.
  public static func selection() {
    #if canImport(UIKit)
    UISelectionFeedbackGenerator().selectionChanged()
    #endif
  }
  public enum Impact { case light, medium, rigid }
  /// Hole complete (medium), rank moved (light), skins carry ≥2 (rigid).
  public static func impact(_ style: Impact = .medium) {
    #if canImport(UIKit)
    let s: UIImpactFeedbackGenerator.FeedbackStyle = switch style {
    case .light: .light
    case .medium: .medium
    case .rigid: .rigid
    }
    UIImpactFeedbackGenerator(style: s).impactOccurred()
    #endif
  }
  /// POSTED ✓ — the thock.
  public static func success() {
    #if canImport(UIKit)
    UINotificationFeedbackGenerator().notificationOccurred(.success)
    #endif
  }
  /// Two-tap destructive arm.
  public static func warning() {
    #if canImport(UIKit)
    UINotificationFeedbackGenerator().notificationOccurred(.warning)
    #endif
  }
}

public extension View {
  /// `sensoryFeedback` through the one vocabulary: fires when `trigger` changes.
  func csFeedback<T: Equatable>(_ kind: CSHaptic.Kind, trigger: T) -> some View {
    sensoryFeedback(kind.sensory, trigger: trigger)
  }
}

// MARK: - The floating tab bar

/// How much room a page must leave at its foot for the floating tab bar: what
/// the pill COVERS, minus what the system already reserves for it. The shell
/// measures it from the live bar and applies `csTabBarRoom` once, so no screen
/// has to know the number — but a surface that floats above the bar on its own
/// (the toast) can read it here rather than carrying a hard-coded gap. Off the
/// tabs — a cover, the door, the orientation screen — it is 0.
private struct CSBarInsetKey: EnvironmentKey { static let defaultValue: CGFloat = 0 }

public extension EnvironmentValues {
  var csBarInset: CGFloat {
    get { self[CSBarInsetKey.self] }
    set { self[CSBarInsetKey.self] = newValue }
  }
}

public extension View {
  /// Room at the foot for the floating tab bar. Applied ONCE, by the tab
  /// shell, to the `TabView` — every tab and every screen pushed inside one
  /// inherits it, including the screens that paint their own ground and would
  /// otherwise each have to carry the number.
  ///
  /// `inset` is what the shell measured: the pill's footprint less the safe
  /// area the system already gives tab content. A screen already clear of the
  /// bar therefore gets nothing added, and cannot be inset twice.
  func csTabBarRoom(_ inset: CGFloat) -> some View {
    safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: max(0, inset)) }
      .environment(\.csBarInset, max(0, inset))
  }

  /// The other half of the same defect: a scroll edge the page cannot be READ
  /// through. The bar's own background is the system's to draw in the floating
  /// design — `CSTabBarChrome` still dresses it, and is honoured on the older
  /// bar and in compatibility mode — so what a page owes it is this. `.hard` is
  /// the delineated edge: rows fade out under the pill instead of sitting at
  /// full contrast behind it and around its rounded corners. The pill stays a
  /// pill; nothing becomes a full-width slab.
  ///
  /// Applied per tab STACK, not to the shell, so a full-screen cover — which
  /// has no tab bar and no floating pill — never inherits it.
  @ViewBuilder func csTabBarEdge() -> some View {
    if #available(iOS 26, *) {
      scrollEdgeEffectStyle(.hard, for: .bottom)
    } else {
      self
    }
  }
}

#if canImport(UIKit)
/// The bar's backdrop. The system pill is TRANSPARENT at a scroll edge by
/// default, which is why page content — orange section heads, a handle line —
/// read clean through it and collided with the tab labels. This gives the bar
/// the system's own material with a raised-token tint over it, on both the
/// standard and the scroll-edge appearance, in both themes. The system fills
/// its own shape, so the rounded corners are covered with it.
///
/// Honoured on the pre-Liquid-Glass bar and in compatibility mode; the new
/// floating bar draws its own glass and ignores background customisation, and
/// there the work is done by `csTabBarEdge`'s hard scroll edge.
@MainActor public enum CSTabBarChrome {
  /// Dress the live bar AND the proxy: the proxy catches a bar built later,
  /// the instance catches the one already on screen. Once only — assigning an
  /// appearance forces a layout pass, and the shell asks on a poll.
  private static var dressed = false
  public static func dress(_ bar: UITabBar) {
    guard !dressed else { return }
    dressed = true
    let a = appearance()
    bar.standardAppearance = a
    bar.scrollEdgeAppearance = a
    UITabBar.appearance().standardAppearance = a
    UITabBar.appearance().scrollEdgeAppearance = a
  }

  private static func appearance() -> UITabBarAppearance {
    let a = UITabBarAppearance()
    a.configureWithDefaultBackground()      // the system material …
    a.backgroundColor = tint                // … and the raised ground over it
    return a
  }

  /// `bg2` — the raised ground — at the opacity where nothing reads through.
  /// One dynamic colour so the bar turns over with the appearance on its own.
  private static let tint: UIColor = {
    let dark = UIColor(CSTokens.dark.bg2).withAlphaComponent(0.94)
    let light = UIColor(CSTokens.light.bg2).withAlphaComponent(0.94)
    return UIColor { $0.userInterfaceStyle == .dark ? dark : light }
  }()
}
#endif
