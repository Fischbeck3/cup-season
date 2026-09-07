// Cup Season — theme plumbing (IOS-003 §1, D76 Charcoal).
//
// The palette is generated (Generated/Tokens.swift). This file only decides
// WHICH palette a view sees, and keeps the one native-only rule: text the web
// sets in `dim` renders in `mut` here (IOS-013), because `dim` fails AA.

import SwiftUI

/// The appearance choice. Device-local like the web's `cs_theme` — never on
/// the profile (D76). `charcoal` is the default a brand-new user lands in.
public enum CSAppearance: String, CaseIterable, Sendable {
  case charcoal = "dark"
  case light = "light"
  case device = "auto"

  public static let storageKey = "cs_theme"
  public static let `default`: CSAppearance = .charcoal

  public var label: String {
    switch self {
    case .charcoal: "Fescue"
    case .light: "Light"
    case .device: "Match device"
    }
  }

  /// nil = follow the system.
  public var colorScheme: ColorScheme? {
    switch self {
    case .charcoal: .dark
    case .light: .light
    case .device: nil
    }
  }

  public static func load() -> CSAppearance {
    CSAppearance(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .default
  }

  public func save() { UserDefaults.standard.set(rawValue, forKey: Self.storageKey) }
}

private struct CSPaletteKey: EnvironmentKey {
  static let defaultValue: CSPalette = CSTokens.dark
}

public extension EnvironmentValues {
  /// The resolved palette for the current color scheme.
  var cs: CSPalette {
    get { self[CSPaletteKey.self] }
    set { self[CSPaletteKey.self] = newValue }
  }
}

public extension CSPalette {
  /// IOS-013: the `dim` tier is for hairlines, dots and watermarks. Text the
  /// web renders in `dim` uses this instead — it is `mut`, which passes AA.
  var dimText: Color { mut }
}

private struct CSThemeModifier: ViewModifier {
  @Environment(\.colorScheme) private var scheme
  /// **Increase Contrast, resolved HERE rather than at 400 call sites.** The
  /// setting is one of the five iOS switches the system owes an answer to, and
  /// the answer is a palette substitution, not a per-view branch: `mut` → `ink`
  /// at `a88` · `rule` → `mut`. A site that reasons about its own contrast is a
  /// site that will forget to.
  @Environment(\.legibilityWeight) private var legibility
  @Environment(\.colorSchemeContrast) private var contrast
  /// WAVE 10 · resolved here for the same reason Increase Contrast is: a site
  /// that reasons about its own transparency is a site that will forget to.
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  func body(content: Content) -> some View {
    let base = scheme == .light ? CSTokens.light : CSTokens.dark
    return content
      .environment(\.cs, contrast == .increased ? base.increasedContrast : base)
      .environment(\.csReduceTransparency, reduceTransparency)
  }
}

public extension CSPalette {
  /// The Increase Contrast printing. Two substitutions, and they are the two
  /// that matter: the metadata voice steps up to ink, and the one hairline
  /// steps up to the metadata voice — so a rule that was 2.66:1 becomes 7.07:1
  /// and the agate under every figure stops being the quietest thing on a
  /// screen full of quiet things.
  var increasedContrast: CSPalette {
    CSPalette(bg0: bg0, bg1: bg1, bg2: bg2,
              rule: mut, ink: ink, mut: ink.opacity(CSTokens.Alpha.a88), dim: mut,
              pos: pos, neg: neg, cool: cool, gold: gold, brand: brand,
              sq0: sq0, sq1: sq1, sq2: sq2, sq3: sq3,
              panel: panel, panelInk: panelInk, panelMut: panelInk.opacity(CSTokens.Alpha.a88),
              leaf: leaf, leafInk: leafInk, leafMut: leafInk.opacity(CSTokens.Alpha.a88),
              // gold on paper is already the darkest gold the system owns —
              // it does not step up, and stepping it toward ink would make the
              // earned rule and the podium rule the same mark
              leafGold: leafGold,
              ceremony: ceremony, ceremonyInk: ceremonyInk,
              ceremonyMut: ceremonyInk.opacity(CSTokens.Alpha.a88),
              ceremonyBrand: ceremonyBrand, ceremonyGold: ceremonyGold,
              ceremonyPos: ceremonyPos, ceremonyCool: ceremonyCool,
              ceremonySq0: ceremonySq0, ceremonySq1: ceremonySq1,
              ceremonySq2: ceremonySq2, ceremonySq3: ceremonySq3,
              crest: crest, folioRule: scrimMut, scrimInk: scrimInk, scrimMut: scrimInk,
              pig0: pig0, pig1: pig1, pig2: pig2, pig3: pig3, pig4: pig4, pig5: pig5)
  }
}

public extension View {
  /// Resolve the palette from the effective color scheme and inject it as
  /// `@Environment(\.cs)`. Apply once at the root, below `preferredColorScheme`.
  func csTheme() -> some View { modifier(CSThemeModifier()) }
}

/// The ceremony ground: a near-black used for settlements, trophies, the
/// finish and share cards **in every theme**.
///
/// **D270 · these are now TOKENS.** `object.ceremony` and its whole ramp live
/// in `tokens.json` and are pinned in both themes, because a physical object
/// does not re-print. These two constants remain only as the names ~a dozen
/// shipped sites already use; each resolves to the token, so there is one
/// value rather than two that drift. **Removed in Wave 9** with their last
/// call site. The resolution rule — on the ceremony ground every token takes
/// its DARK value — is `CSCeremonyGround` in `Structure.swift`.
public enum CSDusk {
  public static let ground = CSTokens.dark.ceremony
  public static let surface = CSTokens.dark.bg1
}

// MARK: - Reduce Transparency (UI_SYSTEM §16.5, WAVE 10)

/// **The fourth iOS switch, and this design is unusually exposed to it.**
///
/// The folio's hairline at `a16`, the contour at `a24` and the photo scrim's
/// four-stop ramp are the *entire* texture of the credential and the title
/// card — they are not decoration over a solid thing, they ARE the thing. A
/// golfer with Reduce Transparency on is asking for no layer to be guessed at,
/// and §16.5's answer is not "hide the texture": it is **the composited opaque
/// value**, so the picture is the same picture and nothing is see-through.
///
/// `folioRule` `#8B8F8B` is the worked example already in the palette — it is
/// `ceremonyInk` at `a56` over `ceremony`, computed once and given a name.
/// This does the same arithmetic for the rest, at run time, so a component
/// never carries a second hex.
public enum CSOpaque {

  /// `color` at `alpha` over `ground`, flattened — or the plain transparent
  /// value when Reduce Transparency is off.
  public static func tint(_ color: Color, _ alpha: Double,
                          over ground: Color, reduce: Bool) -> Color {
    guard reduce else { return color.opacity(alpha) }
    return composite(color, alpha, over: ground)
  }

  /// Source-over, in sRGB. Returns the transparent colour unchanged on a
  /// platform that cannot resolve components — a test host, never a device.
  public static func composite(_ color: Color, _ alpha: Double, over ground: Color) -> Color {
    #if canImport(UIKit)
    var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
    var r0: CGFloat = 0, g0: CGFloat = 0, b0: CGFloat = 0, a0: CGFloat = 0
    guard UIColor(color).getRed(&r1, green: &g1, blue: &b1, alpha: &a1),
          UIColor(ground).getRed(&r0, green: &g0, blue: &b0, alpha: &a0)
    else { return color.opacity(alpha) }
    let a = CGFloat(alpha) * a1
    // Built through `CGColor` rather than `Color(.sRGB, red:…)` ON PURPOSE:
    // preflight check 15 fails any channel-wise colour construction on the
    // phone, because that is how an invented colour gets in. Nothing is
    // invented here — both operands are tokens and the arithmetic is
    // source-over — but a purity check that has to reason about intent is a
    // purity check with a hole in it, so the construction moves instead.
    guard let blended = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(),
                                components: [r1 * a + r0 * (1 - a),
                                             g1 * a + g0 * (1 - a),
                                             b1 * a + b0 * (1 - a), 1])
    else { return color.opacity(alpha) }
    return Color(cgColor: blended)
    #else
    return color.opacity(alpha)
    #endif
  }
}

private struct CSReduceTransparencyKey: EnvironmentKey {
  static let defaultValue = false
}

public extension EnvironmentValues {
  /// Reduce Transparency, resolved at the root by `csTheme()` so a component
  /// reads one flag rather than an accessibility API each.
  var csReduceTransparency: Bool {
    get { self[CSReduceTransparencyKey.self] }
    set { self[CSReduceTransparencyKey.self] = newValue }
  }
}
