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

// MARK: - The three named geometries (UI_SYSTEM §10.3, D272)

/// "One scrim" was THREE in the first draft — a left-to-right three-stop on the
/// wire band, a top-to-bottom four-stop on the course hero, and a third with
/// different offsets on the credential: three geometries and two directions, in
/// the mockups that illustrated the claim that there was one. There are now
/// exactly three, they are named, and nothing else is legal.
///
/// Copy over any of them takes `scrimInk` (a name, a headline) or `scrimMut` (a
/// credit, a caption) — the two named tokens, so the off-palette greys four
/// specs had invented are gone.
public extension CSPhotoScrim {
  /// Bottom-anchored, for **a name reversed out of a plate** — the course hero,
  /// the credential, the event's title card. Top → bottom.
  static let title: [Stop] = [Stop(0.00, 0.00), Stop(0.24, 0.44), Stop(0.72, 0.72), Stop(0.88, 1.00)]

  /// Leading-anchored, for **a wire photo band** where the copy sets at the
  /// left. Leading → trailing.
  static let band: [Stop] = [Stop(0.88, 0.00), Stop(0.56, 0.46), Stop(0.00, 1.00)]

  /// For any plate that runs full-bleed **under the status bar**. Without it
  /// the credit line, the system back chevron and the status clock sit on raw
  /// image — and over a real sunrise photograph, which is rung 1 of the ladder
  /// and the whole point of it, the credit computes at **1.48:1** on the bright
  /// band. `0% ceremony a72 → clear` over the first 96pt.
  static let top: [Stop] = [Stop(0.72, 0.00), Stop(0.00, 1.00)]
  static let topHeight: CGFloat = 96

  /// **A SIXTH ARITHMETIC CONFLICT, FOUND BY TESTING IT.** §10.3 says copy over
  /// a scrim takes `scrimInk` (a name, a headline) or `scrimMut` (a credit, a
  /// caption). That holds on `.title` and `.band`, which reach `a88`. It does
  /// **not** hold on `.top`, which reaches only `a72` — deliberately, because
  /// `.top`'s whole job is to protect the status bar WITHOUT blacking out the
  /// head of the picture. Over the brightest subject the product prints, a
  /// `scrimMut` credit under `.top` computes at **4.15:1**: better than the
  /// 1.48:1 it fixes, and still under AA.
  ///
  /// So the ink is a function of the geometry rather than a habit each surface
  /// keeps: **on `.top`, a caption takes `scrimInk` too.** Stated here, once,
  /// so no course page and no event card resolves it by omission.
  static func ink(_ stops: [Stop], caption: Bool) -> Color {
    guard caption, stops.last?.alpha ?? 0 >= 0.88 || stops.first?.alpha ?? 0 >= 0.88 else {
      return CSTokens.dark.scrimInk
    }
    return CSTokens.dark.scrimMut
  }

  /// The geometry, drawn. `ceremony` is the ground in BOTH printings: a
  /// photograph carries its own dusk and a light-theme scrim would bleach it.
  static func layer(_ stops: [Stop], leading: Bool = false) -> some View {
    CSScrimLayer(stops: stops, leading: leading)
  }

  /// **Reduce Transparency, on a scrim** (§16.5, WAVE 10).
  ///
  /// The other three exposed textures — the folio's hairline, the contour, the
  /// crest — sit on a known opaque ground, so "the composited opaque value" is
  /// exact arithmetic and nothing is lost. A scrim does not: the thing
  /// underneath it is a photograph, and flattening a `.title` ramp to its
  /// darkest stop would paint the whole plate solid and **erase the picture**,
  /// which is not an accessibility win by any reading.
  ///
  /// So the resolution is the SHAPE rather than the alpha: the ramp becomes
  /// **two stops with a hard edge at the point the original crossed half its
  /// darkest value** — clear above, the darkest value below. Nothing fades
  /// into anything; the copy's ground is a uniform band; the top of the
  /// photograph survives; and the copy's contrast strictly IMPROVES, because
  /// every point in the band now carries the ramp's own maximum.
  static func hardEdge(_ stops: [Stop]) -> [Stop] {
    guard let darkest = stops.map(\.alpha).max(), darkest > 0 else { return stops }
    let half = darkest / 2
    let sorted = stops.sorted { $0.at < $1.at }
    var edge = sorted.last?.at ?? 1
    for (a, b) in zip(sorted, sorted.dropFirst()) where (a.alpha - half) * (b.alpha - half) <= 0 {
      let span = b.alpha - a.alpha
      edge = abs(span) < 0.0001 ? a.at : a.at + (half - a.alpha) / span * (b.at - a.at)
      break
    }
    let clearFirst = (sorted.first?.alpha ?? 0) < (sorted.last?.alpha ?? 0)
    return clearFirst
      ? [Stop(0, 0), Stop(0, edge), Stop(darkest, edge), Stop(darkest, 1)]
      : [Stop(darkest, 0), Stop(darkest, edge), Stop(0, edge), Stop(0, 1)]
  }
}

/// The scrim as a view, so it can read `\.csReduceTransparency`. `layer` was a
/// static function and a static function has no environment.
public struct CSScrimLayer: View {
  @Environment(\.csReduceTransparency) private var reduce
  let stops: [CSPhotoScrim.Stop]
  let leading: Bool
  public init(stops: [CSPhotoScrim.Stop], leading: Bool = false) {
    self.stops = stops; self.leading = leading
  }
  public var body: some View {
    let s = reduce ? CSPhotoScrim.hardEdge(stops) : stops
    LinearGradient(stops: s.map { .init(color: CSTokens.dark.ceremony.opacity($0.alpha), location: $0.at) },
                   startPoint: leading ? .leading : .top,
                   endPoint: leading ? .trailing : .bottom)
      .allowsHitTesting(false)
  }
}
