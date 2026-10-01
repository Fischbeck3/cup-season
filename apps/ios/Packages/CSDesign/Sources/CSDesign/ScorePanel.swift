import SwiftUI

/// D401 · matte result content. The owning record supplies its semantic paint;
/// this object has no action and does not inherit a personal look's panel tint.
public struct CSScorePanel: View {
  let value: String
  let label: String
  let fill: Color
  let ink: Color

  public init(_ value: String, label: String, fill: Color, ink: Color) {
    self.value = value; self.label = label; self.fill = fill; self.ink = ink
  }

  public var body: some View {
    VStack(spacing: CSTokens.Space.s1) {
      Text(value).csType(.figureL)
      Text(label).csType(.agateS, caps: true)
    }
    .foregroundStyle(ink)
    .padding(CSTokens.Space.s2)
    .frame(minWidth: 72, minHeight: 80)
    .fixedSize(horizontal: true, vertical: true)
    .background(fill, in: RoundedRectangle(cornerRadius: CSTokens.Radius.p))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(value), \(label)")
  }
}
