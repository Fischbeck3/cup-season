// Cup Season — the M0 component set (IOS-003 §2.4).
//
// Card with the spine · Button (primary ember / quiet / gold-earned) · Field ·
// Stat tile · Eyebrow · Empty state · Note line · Haptics vocabulary.

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Card

/// bg1 · 1px line · radius 16 · padding 16, with the 3.5pt left spine that
/// tells you live (ember) vs earned (gold) vs squad vs nothing.
public struct CSCard<Content: View>: View {
  @Environment(\.cs) private var cs
  let spine: Color?
  let padding: CGFloat
  let content: Content

  public init(spine: Color? = nil, padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
    self.spine = spine; self.padding = padding; self.content = content()
  }

  public var body: some View {
    content
      .padding(padding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).stroke(cs.line, lineWidth: 1))
      .overlay(alignment: .leading) {
        if let spine {
          RoundedRectangle(cornerRadius: 2).fill(spine).frame(width: 3.5).padding(.vertical, 10)
        }
      }
  }
}

// MARK: - Button

public enum CSButtonStyle { case primary, quiet, gold }

public struct CSButton: View {
  @Environment(\.cs) private var cs
  let label: String
  let style: CSButtonStyle
  let busy: Bool
  let action: () -> Void

  public init(_ label: String, style: CSButtonStyle = .primary, busy: Bool = false, action: @escaping () -> Void) {
    self.label = label; self.style = style; self.busy = busy; self.action = action
  }

  public var body: some View {
    Button(action: action) {
      ZStack {
        Text(label).font(CSFont.button).opacity(busy ? 0 : 1)
        if busy { ProgressView().tint(fg) }
      }
      .frame(maxWidth: .infinity, minHeight: 50)
      .foregroundStyle(fg)
      .background(bg, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(border, lineWidth: 1))
    }
    .disabled(busy)
    .buttonStyle(.plain)
  }

  private var bg: Color {
    switch style {
    case .primary: cs.brand
    case .quiet: cs.bg2
    case .gold: cs.gold
    }
  }
  private var fg: Color {
    switch style {
    // `bg0` is the ink that turns over with the theme — near-black on the
    // dark grounds, paper-white on the light one. It is the phone's form of
    // the web's F1 rule (dark ink on the light-theme ember misses AA; white
    // ink clears it), and it needs no per-theme branch to say so.
    case .primary: cs.bg0
    case .quiet: cs.ink
    // D211 stepped the light gold darker for text, which took the web's
    // near-black gold-button ink (#171204) down to 3.4:1 on it. `bg0` reads
    // the same on the dark champagne (9.3:1, was 9.3) and clears 4.9:1 on
    // the light metal.
    case .gold: cs.bg0
    }
  }
  private var border: Color { style == .quiet ? cs.line2 : .clear }
}

// MARK: - Field

/// Mono · bg2 · radius 10 · 44pt · focus ring in `focus`.
public struct CSField: View {
  @Environment(\.cs) private var cs
  let placeholder: String
  @Binding var text: String
  let font: Font
  @FocusState private var focused: Bool

  public init(_ placeholder: String, text: Binding<String>, font: Font = CSFont.mono) {
    self.placeholder = placeholder; _text = text; self.font = font
  }

  public var body: some View {
    TextField(placeholder, text: $text)
      .font(font)
      .foregroundStyle(cs.ink)
      .padding(.horizontal, 14)
      .frame(minHeight: 48)
      .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous)
        .stroke(focused ? cs.focus : cs.line, lineWidth: focused ? 2 : 1))
      .focused($focused)
  }
}

// MARK: - Stat

public struct CSStat: View {
  @Environment(\.cs) private var cs
  let label: String
  let value: String
  let tone: Color?
  let sub: String?

  public init(_ label: String, value: String, tone: Color? = nil, sub: String? = nil) {
    self.label = label; self.value = value; self.tone = tone; self.sub = sub
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label).font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.dimText)
      Text(value).font(CSFont.stat).csTabular().foregroundStyle(tone ?? cs.ink)
      if let sub { Text(sub).font(CSFont.monoSmall).foregroundStyle(cs.mut) }
    }
    .padding(.vertical, 14).padding(.horizontal, 14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).stroke(cs.line, lineWidth: 1))
  }
}

// MARK: - Empty state

/// "a quiet icon, one line in voice, one next step … Every dead end becomes a
/// next move." (index.html 11085)
public struct CSEmptyState: View {
  @Environment(\.cs) private var cs
  let icon: String
  let line: String
  let cta: String?
  let action: (() -> Void)?

  public init(icon: String, line: String, cta: String? = nil, action: (() -> Void)? = nil) {
    self.icon = icon; self.line = line; self.cta = cta; self.action = action
  }

  public var body: some View {
    VStack(spacing: 12) {
      Text(icon).font(.system(size: 28)).accessibilityHidden(true)
      Text(line).font(CSFont.subhead).foregroundStyle(cs.mut).multilineTextAlignment(.center)
      if let cta, let action {
        Button(action: action) {
          Text(cta).font(CSFont.button).foregroundStyle(cs.brand).a11yMinTarget()
        }
        .buttonStyle(.plain)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 28)
  }
}

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
