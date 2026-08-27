// Cup Season — the three type voices, on Dynamic Type (IOS-003 §2.1).
//
//   mono  = the scorer's tent  (eyebrows, labels, stats, codes, inputs)
//   serif = memory & honor     (hero numbers, the standings sentence, trophies)
//   sans  = now                (body, buttons)
//
// Every role is a text style plus a face, so it scales with the user's
// setting. Nothing here renders below 11pt at the default size.

import SwiftUI

public enum CSFont {
  // PostScript names of the bundled IBM Plex Mono files (OFL).
  static let monoRegular = "IBMPlexMono"
  static let monoMedium = "IBMPlexMono-Medium"
  static let monoSemibold = "IBMPlexMono-SemiBold"
  // Charter ships on iOS as a system face — no bundling.
  static let serifRegular = "Charter-Roman"
  static let serifBold = "Charter-Bold"

  // MARK: mono

  /// Section header: mono, uppercase, tracked. Pair with `.csEyebrow()`.
  public static let eyebrow = Font.custom(monoMedium, size: 12, relativeTo: .caption)
  /// Stat / table / tile labels. Never below 11pt (the web went to 8.5).
  public static let label = Font.custom(monoRegular, size: 11, relativeTo: .caption2)
  /// The number on a stat tile.
  public static let stat = Font.custom(monoSemibold, size: 21, relativeTo: .title2)
  /// Inputs, codes, the handle, the build line.
  public static let mono = Font.custom(monoRegular, size: 16, relativeTo: .body)
  public static let monoSmall = Font.custom(monoRegular, size: 13, relativeTo: .footnote)
  public static let monoMediumBody = Font.custom(monoMedium, size: 14, relativeTo: .subheadline)
  /// The eight digits.
  public static let code = Font.custom(monoMedium, size: 28, relativeTo: .largeTitle)

  // MARK: serif

  /// Hero numbers: rank, index, the pot.
  public static let hero = Font.custom(serifBold, size: 40, relativeTo: .largeTitle)
  public static let heroSmall = Font.custom(serifBold, size: 28, relativeTo: .title)
  /// The standings sentence, the band line — a sentence in the honor voice.
  public static let sentence = Font.custom(serifRegular, size: 17, relativeTo: .callout)
  public static let sentenceBold = Font.custom(serifBold, size: 17, relativeTo: .callout)
  /// The wordmark.
  public static let wordmark = Font.custom(serifBold, size: 34, relativeTo: .largeTitle)

  // MARK: sans

  public static let body = Font.body
  public static let subhead = Font.subheadline
  public static let footnote = Font.footnote
  public static let button = Font.body.weight(.semibold)
  public static let title = Font.title3.weight(.bold)
}

public struct CSEyebrowStyle: ViewModifier {
  @Environment(\.cs) private var cs
  let color: Color?
  public func body(content: Content) -> some View {
    content
      .font(CSFont.eyebrow)
      .tracking(1.6)
      .textCase(.uppercase)
      .foregroundStyle(color ?? cs.mut)
  }
}

public extension View {
  /// Mono · 12pt · .16em · uppercase · `mut` (or a given colour).
  func csEyebrow(_ color: Color? = nil) -> some View { modifier(CSEyebrowStyle(color: color)) }
  /// Digits that line up in columns.
  func csTabular() -> some View { monospacedDigit() }
}
