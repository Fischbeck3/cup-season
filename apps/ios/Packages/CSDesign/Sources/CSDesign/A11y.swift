// Cup Season — the accessibility helpers (wave 8, docs/ios/accessibility.md).
//
// Three small tools every screen reaches for:
//   A11yStack        a row that becomes a column at the accessibility sizes,
//                    so a fixed-width trailing figure never squeezes a name
//   .a11yHitSlop     a 44pt hit area around a small glyph or a text link
//                    WITHOUT changing the layout the eye sees
//   .a11yMinTarget   a control that is at least 44 × 44, full stop
//
// Every layout tolerates AX3 at minimum (IOS-003 §2.1); the stack is the
// one-line branch that gets a row there.

import SwiftUI

public extension DynamicTypeSize {
  /// `.accessibility1` and up — the sizes at which a row becomes a column.
  var isA11y: Bool { isAccessibilitySize }
}

/// An `HStack` at reading sizes, a `VStack` at the accessibility sizes.
///
/// Children keep their order; `Spacer()`s are fine in the row and harmless in
/// the column (a column in a scroll has no slack to give them). Alignment
/// follows the column: `alignment` is the horizontal alignment used when the
/// stack is vertical, `rowAlignment` the vertical one used when it is a row.
public struct A11yStack<Content: View>: View {
  @Environment(\.dynamicTypeSize) private var typeSize
  let alignment: HorizontalAlignment
  let rowAlignment: VerticalAlignment
  let spacing: CGFloat?
  let columnSpacing: CGFloat?
  /// Force the column regardless of the type size (a caller with its own reason).
  let forceColumn: Bool
  let content: Content

  public init(alignment: HorizontalAlignment = .leading, rowAlignment: VerticalAlignment = .center,
              spacing: CGFloat? = nil, columnSpacing: CGFloat? = nil, forceColumn: Bool = false,
              @ViewBuilder content: () -> Content) {
    self.alignment = alignment; self.rowAlignment = rowAlignment
    self.spacing = spacing; self.columnSpacing = columnSpacing
    self.forceColumn = forceColumn; self.content = content()
  }

  public var body: some View {
    if forceColumn || typeSize.isA11y {
      VStack(alignment: alignment, spacing: columnSpacing ?? spacing) { content }
    } else {
      HStack(alignment: rowAlignment, spacing: spacing) { content }
    }
  }
}

public extension View {
  /// A hit area `vertical`/`horizontal` points larger than the drawn view on
  /// every side, without moving anything: the padding sets the shape, the
  /// negative padding hands the space back to the layout. Put it INSIDE the
  /// `Button`'s label. 12 × 8 turns a 20pt text link into a 44pt target.
  func a11yHitSlop(vertical: CGFloat = 12, horizontal: CGFloat = 8) -> some View {
    padding(.vertical, vertical).padding(.horizontal, horizontal)
      .contentShape(Rectangle())
      .padding(.vertical, -vertical).padding(.horizontal, -horizontal)
  }

  /// At least 44 × 44, and the whole frame taps. Put it INSIDE the label.
  func a11yMinTarget(alignment: Alignment = .center) -> some View {
    frame(minWidth: 44, minHeight: 44, alignment: alignment).contentShape(Rectangle())
  }
}

#Preview("A11yStack · reading vs accessibility") {
  VStack(alignment: .leading, spacing: 24) {
    A11yStack {
      Text("Galen Ross").font(CSFont.subhead)
      Spacer()
      Text("27").font(CSFont.stat)
    }
    A11yStack(forceColumn: true) {
      Text("Galen Ross").font(CSFont.subhead)
      Spacer()
      Text("27").font(CSFont.stat)
    }
  }
  .padding(20)
  .csTheme()
}
