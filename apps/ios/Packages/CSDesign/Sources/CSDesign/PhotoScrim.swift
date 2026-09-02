// Cup Season — copy over a photograph.
//
// A photograph can be any tone; the copy that rides it cannot. This is the
// one place that argument is settled, so a panel putting a name over a
// picture does not re-invent it, and so a change to it is a change with a
// test under it (`CSDesignTests.PhotoScrimTests`).
//
// TWO layers, two jobs, and they are not interchangeable:
//
//   SETTLE — the panel's long dissolve into the card it sits in. Its job is
//     the SEAM. Run it to full and it bleaches the picture: D202 shipped it
//     at full `bg1` over 230pt and the light theme lost the golfer's belt,
//     shorts and legs to milk.
//   PLATE — the short, shaped ground under the copy's own band. Its job is
//     the LETTERS. It is as tall as the copy is and no taller, and it does
//     almost nothing until its last third — so the smallest line gets the
//     ink it needs while the photograph above it keeps every tone it had.
//
// Lightening the settle alone was the D202 fix, and it was right about the
// picture and wrong about the copy. Measured on the simulator in charcoal,
// the credential's smallest line (footnote `mut`, AA wants 4.5:1) fell from
// 5.56:1 to 4.49:1 over a real photograph, and to 4.02:1 over the near-white
// `-cs_dev_cred photo` subject the fixture exists to be the worst case of.
// The plate is where that contrast comes back — locally, under the letters,
// and not by flattening the whole panel again.
//
// The two ramps are DATA, and `groundUnderCopy` composes them, so the
// guarantee is arithmetic rather than a hope: lighten a ramp without
// re-measuring and the test says so.

import SwiftUI

public enum CSPhotoScrim {
  /// One stop of an alpha ramp: how much ground at how far down.
  public struct Stop: Sendable, Equatable {
    public let alpha: Double
    public let at: Double
    public init(_ alpha: Double, _ at: Double) { self.alpha = alpha; self.at = at }
  }

  // MARK: the ramps

  /// The dissolve. 175pt — under half a square panel, so everything above the
  /// copy is the photograph and nothing else — thin through the middle (0.60
  /// where D202 had 0.86) and capped short of full at the seam.
  public static let settleRamp: [Stop] = [
    Stop(0.00, 0.00), Stop(0.20, 0.24), Stop(0.60, 0.62), Stop(0.92, 1.00)
  ]
  public static let settleHeight: CGFloat = 175

  /// The copy's own ground, sized to the copy. Flat for its first third (the
  /// name is large, bold and wears a halo — it needs the photograph more than
  /// it needs ground), then it climbs, and the smallest line at the foot gets
  /// nearly two thirds of `bg1` on its own account.
  public static let plateRamp: [Stop] = [
    Stop(0.00, 0.00), Stop(0.08, 0.32), Stop(0.36, 0.64), Stop(0.66, 0.86), Stop(0.70, 1.00)
  ]

  /// Where the SMALLEST line of copy sits in each ramp. Measured, not
  /// guessed: on an iPhone 17 Pro at the reading sizes the credential's band
  /// is 116pt tall against a 361pt panel, and the "GHIN … · est. …" line's
  /// box centres 0.85 of the way down the band and 0.895 of the way down the
  /// settle. The accessibility sizes take the copy off the panel entirely
  /// (D199/D202), so this is the only geometry the guarantee has to hold for.
  public static let copyLine: (settle: Double, plate: Double) = (0.895, 0.85)

  /// The ramp's alpha at `t` (0 = its top edge, 1 = the panel's foot), the
  /// same linear interpolation `LinearGradient` draws.
  public static func alpha(_ ramp: [Stop], at t: Double) -> Double {
    guard let first = ramp.first else { return 0 }
    if t <= first.at { return first.alpha }
    for (a, b) in zip(ramp, ramp.dropFirst()) where t <= b.at {
      let span = b.at - a.at
      guard span > 0 else { return b.alpha }
      return a.alpha + (b.alpha - a.alpha) * (t - a.at) / span
    }
    return ramp[ramp.count - 1].alpha
  }

  /// How much of the card's own ground the two layers present together where
  /// the smallest line of copy sits — which is the only number the smallest
  /// line's contrast depends on, whatever the photograph is doing.
  public static var groundUnderCopy: Double {
    1 - (1 - alpha(settleRamp, at: copyLine.settle)) * (1 - alpha(plateRamp, at: copyLine.plate))
  }

  // MARK: the layers

  /// The panel's dissolve into the card. Bottom-anchored on the PANEL.
  /// `ground` is the card's own `bg1`, so a light-theme card gets a light
  /// dissolve and dark ink — the panel stays part of the card instead of
  /// becoming a dark rectangle inside it.
  /// The height is not a knob: `copyLine` is measured against THIS one, and a
  /// panel that ran the dissolve over some other distance would put the copy
  /// somewhere else in the ramp and quietly invalidate `groundUnderCopy`.
  public static func settle(_ ground: Color) -> some View {
    ramp(settleRamp, ground).frame(height: settleHeight).allowsHitTesting(false)
  }

  /// The copy's own ground. Put it on the BAND the copy occupies, never on
  /// the panel — its whole argument is that it is only as tall as the words.
  public static func plate(_ ground: Color) -> some View {
    ramp(plateRamp, ground).allowsHitTesting(false)
  }

  private static func ramp(_ stops: [Stop], _ ground: Color) -> LinearGradient {
    LinearGradient(stops: stops.map { .init(color: ground.opacity($0.alpha), location: $0.at) },
                   startPoint: .top, endPoint: .bottom)
  }
}
