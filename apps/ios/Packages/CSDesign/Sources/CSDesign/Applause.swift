// Cup Season — the applause mark (D365, redrawn for F9).
//
// **THE FIRST DRAWING DID NOT READ AS APPLAUSE.** The owner, on the shipped
// build: it is not recognisable. He was right, and the failure is visible the
// moment the glyph is put on a page instead of reasoned about — a narrow,
// largely mirrored path with a central upright finger reads as a DOWNWARD
// ARROW into a cup at 22pt, which is what the review saw.
//
// This is ONE hand — a palm with three fingers and a thumb heel — drawn
// TWICE, at two angles, the back hand rotated away and the front hand
// rotated toward it. Two hands at an angle to each other is what makes the
// mark read as applause rather than as a wave or a pair of mittens; the
// composition was chosen by rendering four of them side by side at 22, 34 and
// 110 points in both themes and looking.
//
// **The given state fills the FRONT hand only.** F9 asks for a filled
// silhouette rather than the translucent wash the first version used, and a
// solid fill on BOTH hands merges them into an amorphous blob with no hands
// in it at any size — a worse failure than the one being fixed. One filled
// hand overlapping one outlined hand keeps both readable and still reads as
// unmistakably "on".
//
// The web twin (`applauseGlyph` in index.html) draws the same path with the
// same two transforms, so the mark is one drawing on both clients.

import SwiftUI

public struct CSApplauseGlyph: View {
  /// One hand on the 24 grid: the palm, three fingers and the thumb heel.
  static let hand = "M13.4 20.4 A3.0 3.0 0 0 0 16.9 17.9 L18.1 12.4 A1.4 1.4 0 0 0 15.4 11.7 L14.9 14.0 L16.0 8.2 A1.4 1.4 0 0 0 13.3 7.6 L12.4 12.6 L12.9 9.0 A1.4 1.4 0 0 0 10.2 8.6 L9.4 14.2 A4.2 4.2 0 0 0 13.4 20.4 Z"
  /// Two short marks off the meeting edge — the sound, kept to two so they
  /// stay legible at 22pt rather than becoming noise.
  static let sparks = "M20.0 5.6l1.8-1.6M21.2 9.2l2.0-.6"

  /// `translate(tx, ty) rotate(deg, 13, 14) scale(s)` — the SVG nesting the
  /// web twin uses, in the order Core Graphics applies it.
  static func place(tx: CGFloat, ty: CGFloat, deg: CGFloat, s: CGFloat) -> CGAffineTransform {
    CGAffineTransform.identity
      .translatedBy(x: tx, y: ty)
      .translatedBy(x: 13, y: 14)
      .rotated(by: deg * .pi / 180)
      .translatedBy(x: -13, y: -14)
      .scaledBy(x: s, y: s)
  }
  static let back = place(tx: -5.6, ty: 0.4, deg: -30, s: 0.92)
  static let front = place(tx: 1.8, ty: 0.6, deg: 18, s: 0.92)

  public let size: CGFloat
  public let filled: Bool
  public let labelled: Bool

  public init(points: CGFloat = 22, filled: Bool = false, labelled: Bool = false) {
    self.size = max(17, points); self.filled = filled; self.labelled = labelled
  }

  public var body: some View {
    let k = size / 24
    let fit = CGAffineTransform(scaleX: k, y: k)
    let hand = SVGPath.path(Self.hand)
    let backHand = hand.applying(Self.back.concatenating(fit))
    let frontHand = hand.applying(Self.front.concatenating(fit))
    let marks = SVGPath.path(Self.sparks).applying(fit)
    let stroke = StrokeStyle(lineWidth: 1.7 * k, lineCap: .round, lineJoin: .round)
    ZStack {
      backHand.stroke(style: stroke)
      // the front hand is filled when given, and its own stroke keeps its
      // edge off the hand behind it
      if filled { frontHand.fill(.primary) }
      frontHand.stroke(style: stroke)
      marks.stroke(style: stroke)
    }
    .frame(width: size, height: size)
    .accessibilityLabel(labelled ? "Applause" : "")
    .accessibilityHidden(!labelled)
  }
}
