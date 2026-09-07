// Cup Season — the toast (the web's `toast()`; IOS-003 §2.4).
//
// A pill, ink on bg0, above the tab bar, that rolls out — "never a bounce —
// golf doesn't bounce, it rolls to a stop." One at a time; a new toast
// replaces the old.

import SwiftUI

@MainActor
@Observable
public final class CSToastCenter {
  /// **Shape AND colour.** 133 `toast.show(...)` sites carried `id` and `text`
  /// and nothing else, so "Round posted: +9 pts" and "Reaction did not save."
  /// were the same grey pill. A toast now carries a KIND — a 3pt leading rail
  /// plus a drawn glyph in the same colour — and at most one action.
  ///
  /// What it is NOT: an arrival. A notification and a confirmation are
  /// different objects. The toast confirms **the golfer's own action**;
  /// something that happened elsewhere arrives as a row in the wire and as a
  /// badge.
  public enum Kind: Sendable {
    case confirmed, failed, neutral
    var glyph: CSGlyph.Name? {
      switch self {
      case .confirmed: .check
      case .failed: .cross
      case .neutral: nil
      }
    }
  }
  public struct Item: Equatable, @unchecked Sendable {
    public let id: UUID
    public let text: String
    public let kind: Kind
    public let actionLabel: String?
    let action: (() -> Void)?
    public static func == (a: Item, b: Item) -> Bool { a.id == b.id }
  }
  public private(set) var current: Item?
  private var hide: Task<Void, Never>?

  nonisolated public init() {}

  public func show(_ text: String, kind: Kind = .neutral, seconds: Double = 2.6,
                   actionLabel: String? = nil, action: (() -> Void)? = nil) {
    current = Item(id: UUID(), text: text, kind: kind, actionLabel: actionLabel, action: action)
    hide?.cancel()
    hide = Task { [weak self] in
      try? await Task.sleep(for: .seconds(seconds))
      if !Task.isCancelled { self?.current = nil }
    }
  }
}

private struct CSToastCenterKey: EnvironmentKey {
  static let defaultValue: CSToastCenter = CSToastCenter()
}
public extension EnvironmentValues {
  /// `@Environment(\.toast) var toast` → `toast.show("Card saved")`.
  var toast: CSToastCenter {
    get { self[CSToastCenterKey.self] }
    set { self[CSToastCenterKey.self] = newValue }
  }
}

private struct CSToastHost: ViewModifier {
  @Environment(\.cs) private var cs
  func rail(_ k: CSToastCenter.Kind) -> Color {
    switch k {
    case .confirmed: cs.pos
    case .failed: cs.neg
    case .neutral: cs.rule
    }
  }
  /// what the floating tab bar actually covers, measured by `CSTabBarProbe`
  /// (0 off the tabs — the door, the covers, the ceremonies).
  @Environment(\.csBarInset) private var barInset
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let center: CSToastCenter
  func body(content: Content) -> some View {
    content
      .environment(\.toast, center)
      .overlay(alignment: .bottom) {
        if let item = center.current {
          // 46pt, `rc` 10, `bg2` fill, `body` 15 in `ink`, a 3pt leading kind
          // rail and a drawn glyph. There is no pill: a chip is a 3pt rectangle,
          // a toast is a 10pt block, a badge is a circle because it holds a count.
          HStack(spacing: CSTokens.Space.s3) {
            Rectangle().fill(rail(item.kind)).frame(width: 3)
            if let g = item.kind.glyph {
              CSGlyph(g, size: .row).foregroundStyle(rail(item.kind))
            }
            Text(item.text).csType(.bodyS).foregroundStyle(cs.ink).lineLimit(1)
            if let label = item.actionLabel, let run = item.action {
              Spacer(minLength: CSTokens.Space.s2)
              Button(label, action: run).buttonStyle(.csTertiary(.content))
            }
          }
          .padding(.horizontal, CSTokens.Space.s3)
          .frame(minHeight: 46)
          .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
          .padding(.horizontal, CSTokens.Space.gutter)
            // 92 is the floor (off the tabs); on a tab it clears the measured pill
            .padding(.bottom, max(92, barInset + 24))
            // reduced motion: the pill fades in place — no roll (IOS-003 §2.7)
            .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            .id(item.id)
            .accessibilityAddTraits(.updatesFrequently)
        }
      }
      .csAnimation(CSMotion.roll, value: center.current)
  }
}

public extension View {
  /// Install once at the root. Views post with `@Environment(\.toast)`.
  func csToasts(_ center: CSToastCenter) -> some View { modifier(CSToastHost(center: center)) }
}
