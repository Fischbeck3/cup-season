// Cup Season — the applause mark (D365).
//
// Two hands meeting, three sparks above — drawn in the glyph family's own
// hand: a 24 × 24 grid, one stroke weight, round caps and joins, `currentColor`.
// The comparison study the owner approved is a composition reference, not
// geometry; this is the code-native glyph. It is never smaller than 17pt (the
// reaction rule) and it draws two ways: OUTLINE at rest, and FILLED — the
// hands filled in the ordinary-action green — once you have applauded. The
// sparks stay a stroke in both, so the filled state reads as hands, not a blob.

import SwiftUI

public struct CSApplauseGlyph: View {
  /// The two hands: left rising to a finger, right mirrored and behind.
  static let hands = "M11.2 21.2L6.6 16.9a2.1 2.1 0 0 1 2.9-3l1.7 1.6V8.3a1.4 1.4 0 0 1 2.8 0v6.5M12.8 21.2l4.6-4.3a2.1 2.1 0 0 0-2.9-3l-1.7 1.6M11.2 21.2h1.6"
  /// Three sparks — the sound.
  static let sparks = "M8.6 5.6L7.6 3.9M15.4 5.6l1-1.7M12 4.6V2.6"

  public let size: CGFloat
  public let filled: Bool
  public let labelled: Bool

  public init(points: CGFloat = 22, filled: Bool = false, labelled: Bool = false) {
    self.size = max(17, points); self.filled = filled; self.labelled = labelled
  }

  public var body: some View {
    let scale = size / 24
    let hands = SVGPath.path(Self.hands).applying(CGAffineTransform(scaleX: scale, y: scale))
    let sparks = SVGPath.path(Self.sparks).applying(CGAffineTransform(scaleX: scale, y: scale))
    let stroke = StrokeStyle(lineWidth: (filled ? 2.0 : 1.7) * scale, lineCap: .round, lineJoin: .round)
    ZStack {
      if filled { hands.fill(.primary.opacity(0.28)) }
      hands.stroke(style: stroke)
      sparks.stroke(style: stroke)
    }
    .frame(width: size, height: size)
    .accessibilityLabel(labelled ? "Applause" : "")
    .accessibilityHidden(!labelled)
  }
}
