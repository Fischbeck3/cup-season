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
    case .primary: cs.bg0
    case .quiet: cs.ink
    case .gold: Color(hex: 0x171204)   // the web's gold-button ink, verbatim
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
