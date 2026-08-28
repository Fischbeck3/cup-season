// Cup Season — the toast (the web's `toast()`; IOS-003 §2.4).
//
// A pill, ink on bg0, above the tab bar, that rolls out — "never a bounce —
// golf doesn't bounce, it rolls to a stop." One at a time; a new toast
// replaces the old.

import SwiftUI

@MainActor
@Observable
public final class CSToastCenter {
  public struct Item: Equatable { public let id: UUID; public let text: String }
  public private(set) var current: Item?
  private var hide: Task<Void, Never>?

  nonisolated public init() {}

  public func show(_ text: String, seconds: Double = 2.6) {
    current = Item(id: UUID(), text: text)
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
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let center: CSToastCenter
  func body(content: Content) -> some View {
    content
      .environment(\.toast, center)
      .overlay(alignment: .bottom) {
        if let item = center.current {
          Text(item.text)
            .font(CSFont.subhead)
            .foregroundStyle(cs.bg0)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(cs.ink, in: Capsule())
            .padding(.bottom, 92)
            // reduced motion: the pill fades in place — no roll (IOS-003 §2.7)
            .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            .id(item.id)
            .accessibilityAddTraits(.updatesFrequently)
        }
      }
      .animation(.timingCurve(0.16, 0.84, 0.36, 1, duration: 0.32), value: center.current)
  }
}

public extension View {
  /// Install once at the root. Views post with `@Environment(\.toast)`.
  func csToasts(_ center: CSToastCenter) -> some View { modifier(CSToastHost(center: center)) }
}
