// WCAG arithmetic on RESOLVED colours, for the contrast suites (F05).
//
// `ContrastTableTests` reads a resolved colour's channels and ignores its
// alpha, which is right for every opaque token it checks and wrong for the
// three things a control actually paints: a label at 92%, a fill at 84% and
// Increase Contrast's `ink` at `a88`. A translucent ink is not the colour a
// golfer reads — the colour under it shows through — so this flattens every
// layer onto the one beneath it (source-over, in sRGB, which is how the
// screen composites them) BEFORE it measures anything.

import SwiftUI
@testable import CSDesign

enum ContrastMath {
  /// A gamma-encoded sRGB triple: the colour as the screen shows it.
  struct RGB: Equatable, CustomStringConvertible {
    var r: Double, g: Double, b: Double
    var description: String {
      "#" + [r, g, b].map { String(format: "%02X", Int(($0 * 255).rounded())) }.joined()
    }
  }

  static func resolved(_ c: Color) -> (rgb: RGB, alpha: Double) {
    let x = c.resolve(in: EnvironmentValues())
    return (RGB(r: Double(x.red), g: Double(x.green), b: Double(x.blue)), Double(x.opacity))
  }

  /// `c`, at its own alpha times `opacity`, flattened onto an opaque ground.
  static func flat(_ c: Color, opacity: Double = 1, over ground: RGB) -> RGB {
    let (rgb, a0) = resolved(c)
    let a = max(0, min(1, a0 * opacity))
    return RGB(r: rgb.r * a + ground.r * (1 - a),
               g: rgb.g * a + ground.g * (1 - a),
               b: rgb.b * a + ground.b * (1 - a))
  }

  /// An opaque colour (a ground) as a triple. A ground with alpha is a bug in
  /// the caller, so it is flattened onto black rather than silently trusted.
  static func opaque(_ c: Color) -> RGB { flat(c, over: RGB(r: 0, g: 0, b: 0)) }

  static func luminance(_ c: RGB) -> Double {
    func lin(_ v: Double) -> Double { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
    return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b)
  }

  static func ratio(_ a: RGB, _ b: RGB) -> Double {
    let (la, lb) = (luminance(a), luminance(b))
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
  }

  /// The ratio of `ink` (at `opacity`) against the opaque `ground` it sits on.
  static func ratio(_ ink: Color, opacity: Double = 1, on ground: Color) -> Double {
    let g = opaque(ground)
    return ratio(flat(ink, opacity: opacity, over: g), g)
  }

  /// Every palette a golfer can be looking at: homebase and each of the
  /// catalogue's looks, in both printings, with and without Increase Contrast.
  struct Case: CustomStringConvertible {
    let look: CSLookSpec?
    let theme: CSTheme
    let increased: Bool
    var palette: CSPalette {
      let base = (theme == .light ? CSTokens.light : CSTokens.dark).wearing(look, theme: theme)
      return increased ? base.increasedContrast : base
    }
    var description: String {
      "\(look?.key ?? "homebase") \(theme)\(increased ? " +IC" : "")"
    }
  }

  static var everyPalette: [Case] {
    var out: [Case] = []
    for look in [nil] + CSLooks.all.map(Optional.some) {
      for theme in [CSTheme.dark, .light] {
        for increased in [false, true] { out.append(Case(look: look, theme: theme, increased: increased)) }
      }
    }
    return out
  }
}
