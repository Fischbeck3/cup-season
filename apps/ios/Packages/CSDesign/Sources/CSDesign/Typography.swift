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
  // PostScript names of the bundled IBM Plex Mono files (OFL) — read from the
  // files' own `name` table (id 6), not remembered.
  //
  // D258 · **THIS WAS `"IBMPlexMono"`, WHICH IS NOT A NAME ANY OF THE THREE
  // FILES CARRIES.** The Regular face is `IBMPlexMono-Regular` in PostScript
  // and `IBM Plex Mono` as a family; `IBMPlexMono` is neither, so
  // `Font.custom` resolved nothing and fell back to the system sans. Every
  // role built on this constant — `label`, `mono`, `monoSmall` — had been
  // rendering in SF Pro since the faces were bundled: `YOUR NUMBER` under the
  // strip's figure was NOT the record voice, while `SAT · SEP 5` beside it
  // (built on `monoMedium`, whose name does resolve) was. Two of the three
  // type voices, silently one voice.
  //
  // It surfaced because `MeStripLayout` does arithmetic on a monospaced
  // advance and the arithmetic kept disagreeing with the screen: a probe set
  // in `label` measured 24.0 points a character where the rendered label took
  // 29.9. A layout that measures its own type is a layout that can catch this;
  // preflight 38 now catches it before the push.
  public static let monoRegular = "IBMPlexMono-Regular"
  public static let monoMedium = "IBMPlexMono-Medium"
  public static let monoSemibold = "IBMPlexMono-SemiBold"

  // D268 · THE BOARD FACE — IBM Plex Sans Condensed, bundled with this build
  // (OFL 1.1, ~225KB for the two cuts). It is the brand's own voice: the
  // figure, the rank rail, every title.
  //
  // **AND THESE ARE NOT THE NAMES THE BUILD BRIEF PREDICTED.** The brief says
  // `IBMPlexSansCondensed-SemiBold` / `-Bold`; the files' own `name` table
  // (id 6) says `IBMPlexSansCond-SmBld` and `IBMPlexSansCond-Bold`, and the
  // SemiBold file's family (id 1) is `IBM Plex Sans Cond SmBld` with a
  // subfamily of `Regular`. Had the brief's names been typed from memory,
  // both cuts would have resolved to nothing and every figure in the product
  // would have rendered in SF Pro — silently, exactly as D258 did, on the
  // face that carries 46% of the type. Read from the file, never remembered;
  // preflight 38(b) now asserts these two the way it asserts the mono three,
  // and `CupSeasonTests.BundledFaceTests` resolves them at runtime.
  public static let boardSemibold = "IBMPlexSansCond-SmBld"
  public static let boardBold = "IBMPlexSansCond-Bold"

  // Charter ships on iOS as a system face — no bundling. D268 RETIRES it in
  // favour of New York, which is reached through `design: .serif` rather than
  // by PostScript string; the roles move in the component wave, not here, so
  // that a face swap and a role re-cut are not one commit.
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
  /// The one figure a screen is about — the live gross on the composer (IOS-020).
  public static let figure = Font.custom(serifBold, size: 64, relativeTo: .largeTitle)
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
