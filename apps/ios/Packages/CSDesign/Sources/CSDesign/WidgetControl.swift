import SwiftUI

/// The ordinary action treatment at a widget's 44pt target size.
public struct CSWidgetReplyStyle: ButtonStyle {
  let primary: Bool
  let palette: CSPalette
  public init(primary: Bool, palette: CSPalette) { self.primary = primary; self.palette = palette }
  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .frame(maxWidth: .infinity, minHeight: CSTokens.Space.rail)
      .foregroundStyle(primary ? CSInk.on(palette.act) : palette.ink)
      .background(primary ? palette.act : palette.bg2,
                  in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      .opacity(configuration.isPressed ? 1 - CSTokens.Alpha.a16 : 1)
  }
}
