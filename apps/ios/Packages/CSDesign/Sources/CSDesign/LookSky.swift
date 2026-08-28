// Cup Season — the sky (D103b).
//
// A vertical band of the look's accent, ~22% at the very top fading to
// nothing by ~260pt, under the scroll content and behind the page header or
// the league hero; it ignores the top safe area so the tint runs to the
// status bar. Homebase = ember at 10%, so Fescue-only still has warmth at the
// top. Never on the door, ceremonies, settlement, share cards or the pot
// pane — those keep their own grounds. Nothing here animates.

import SwiftUI

public struct CSLookSky: View {
  @Environment(\.csLookAccent) private var la
  let height: CGFloat
  public init(height: CGFloat = 260) { self.height = height }
  public var body: some View {
    LinearGradient(colors: [la.accent.opacity(la.skyStrength), la.accent.opacity(0)],
                   startPoint: .top, endPoint: .bottom)
      .frame(height: height)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .ignoresSafeArea(edges: .top)
      .allowsHitTesting(false)
      .accessibilityHidden(true)
  }
}

public extension View {
  /// The screen's ground with the sky on it: `bg0`, then the band at the top.
  /// Goes where `.background(cs.bg0)` went — on the scroll, under the content.
  func csLookGround() -> some View { modifier(CSLookGround()) }
}

private struct CSLookGround: ViewModifier {
  @Environment(\.cs) private var cs
  func body(content: Content) -> some View {
    content
      .background(alignment: .top) { CSLookSky() }
      .background(cs.bg0)
  }
}
