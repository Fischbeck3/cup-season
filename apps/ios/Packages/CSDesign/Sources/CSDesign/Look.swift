// Cup Season — the look in the environment (D103a, IOS-025).
//
// `\.csLook` is the resolved look for the surface a view sits on — nil is
// homebase (Fescue). `CSLookAccent` reads it beside the palette so a surface
// asks "what is my accent?" once and never spells a colour. The law a look
// cannot break: gold is EARNED. A caller that passes gold keeps gold; a look
// only fills the seat ember would have taken.

import SwiftUI

private struct CSLookKey: EnvironmentKey {
  static let defaultValue: CSLookSpec? = nil
}

public extension EnvironmentValues {
  /// The look this surface wears. nil = homebase.
  var csLook: CSLookSpec? {
    get { self[CSLookKey.self] }
    set { self[CSLookKey.self] = newValue }
  }

  /// The look's colours for the current theme, with homebase fallbacks.
  var csLookAccent: CSLookAccent {
    CSLookAccent(look: csLook, cs: cs, theme: colorScheme == .light ? .light : .dark)
  }
}

/// `accent` · `accent2` · `wash` for the current look and theme. With no
/// look: ember, ember, ember — exactly what the surfaces wore before D103a.
public struct CSLookAccent: Sendable {
  public let look: CSLookSpec?
  public let cs: CSPalette
  public let theme: CSTheme

  public init(look: CSLookSpec?, cs: CSPalette, theme: CSTheme) {
    self.look = look; self.cs = cs; self.theme = theme
  }

  public var active: Bool { look != nil }
  /// The spine, the halo tint, the eyebrow word's colour.
  public var accent: Color { look?.accent(theme) ?? cs.brand }
  /// The partner colour — the swatch's second half, a chip's stroke.
  public var accent2: Color { look?.accent2(theme) ?? cs.brand }

  /// The spine a surface should wear: gold when EARNED (never overridden), else the accent.
  public func spine(earned: Bool) -> Color { earned ? cs.gold : accent }

  // MARK: D103b — how far a look reaches

  /* D278 · `washStrength` and `skyStrength` are DELETED with the two views
     that read them. `CSWash` and `CSLookSky` were the product's only
     atmosphere, D270 named both in its "still owed" list, and a strength for a
     wash nothing paints is a number waiting to be painted again. **A look now
     reaches exactly three channels: the tick, the eyebrow and the spine** —
     all three of them a MARK, none of them a field of colour over a page. */
  /// The page header's tick: accent → accent2 under a look; flat ember on
  /// homebase. D270 deleted `effect.grad` — BRIEF §4 names the amber→ember
  /// gradient as a do-not, and a two-stop ramp of one hue is not a gradient.
  public var tick: [Color] { active ? [accent, accent2] : [cs.brand, cs.brand] }
  /// An eyebrow or section head's colour: the accent at full strength under a
  /// look; nil = `.csEyebrow()`'s default `mut`. Gold eyebrows are the caller's.
  public var eyebrow: Color? { active ? accent : nil }
}
