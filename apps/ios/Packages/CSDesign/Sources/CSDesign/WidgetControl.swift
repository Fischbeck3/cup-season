import SwiftUI

/// The ordinary action treatment at a widget's 44pt target size.
public struct CSWidgetReplyStyle: ButtonStyle {
  let primary: Bool
  let palette: CSPalette
  let live: Bool
  public init(primary: Bool, palette: CSPalette, live: Bool = false) { self.primary = primary; self.palette = palette; self.live = live }
  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .frame(maxWidth: .infinity, minHeight: CSTokens.Space.rail)
      .foregroundStyle(primary ? CSInk.on(live ? palette.brand : palette.act) : palette.ink)
      .background(primary ? (live ? palette.brand : palette.act) : palette.bg2,
                  in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      .opacity(configuration.isPressed ? 1 - CSTokens.Alpha.a16 : 1)
  }
}

/// Review-only framing uses system-like silhouettes; WidgetKit owns them on device.
public struct CSActivityReviewSurface: ViewModifier {
  let compact: Bool
  public init(compact: Bool = false) { self.compact = compact }
  public func body(content: Content) -> some View {
    if compact { content.background(CSTokens.dark.bg0, in: Capsule()) }
    else { content.background(CSTokens.dark.bg0, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rx)) }
  }
}
