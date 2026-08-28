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
  func body(content: Content) -> some View {
    content.environment(\.cs, scheme == .light ? CSTokens.light : CSTokens.dark)
  }
}

public extension View {
  /// Resolve the palette from the effective color scheme and inject it as
  /// `@Environment(\.cs)`. Apply once at the root, below `preferredColorScheme`.
  func csTheme() -> some View { modifier(CSThemeModifier()) }
}

/// The ceremony ground (`.room-dusk` on the web): a warmer near-black used for
/// settlements, trophies, the finish and share cards in EVERY theme. The two
/// values are the web's, verbatim; they are not in tokens.json because the web
/// hard-codes them in the `.room-dusk` rule rather than as tokens.
public enum CSDusk {
  public static let ground = Color(hex: 0x0A0908)
  public static let surface = Color(hex: 0x191614)
}
