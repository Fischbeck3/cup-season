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

  // N4-092 · Charter is gone (D268): the serif is New York, reached through
  // `design: .serif` and never by name, as CSType's `lead` and `story` reach
  // it. There are no Charter constants left for a new use to find.

  // MARK: mono

  // N4-090 · the mono eyebrow face is gone: a label is the agate role in
  // caps (`.csEyebrow()`), so nothing can reach for mono as a label voice.
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

  // MARK: serif — the system serif (D268), at the text styles' own sizes so it
  // scales with Dynamic Type. `hero` and `figure` had no users and are gone.

  /// A page's title in the serif: 28, bold (`title`).
  public static let heroSmall = Font.system(.title, design: .serif).weight(.bold)
  /// The standings sentence, the band line — a sentence in the honor voice.
  public static let sentence = Font.system(.body, design: .serif)
  public static let sentenceBold = Font.system(.body, design: .serif).weight(.bold)
  /// The wordmark.
  public static let wordmark = Font.system(.largeTitle, design: .serif).weight(.bold)

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
    // N4-090 · **MONO IS NEVER A LABEL VOICE** (UI_SYSTEM §1.4). Every section
    // head and eyebrow was Plex Mono at 12 with a hand-set tracking; they are
    // the agate role in caps, the web's label role, and the tracking is the
    // role's own (LINT-07: one call site). One modifier, every site.
    content
      .csType(.agate, caps: true)
      .foregroundStyle(color ?? cs.mut)
  }
}

public extension View {
  /// The agate role, in caps · `mut` (or a given colour). N4-090: it was mono.
  func csEyebrow(_ color: Color? = nil) -> some View { modifier(CSEyebrowStyle(color: color)) }
  /// Digits that line up in columns.
  func csTabular() -> some View { monospacedDigit() }
}
