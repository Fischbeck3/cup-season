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
  func body(content: Content) -> some View {
    let base = scheme == .light ? CSTokens.light : CSTokens.dark
    return content.environment(\.cs, contrast == .increased ? base.increasedContrast : base)
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
