// Cup Season — the nine roles (UI_SYSTEM §1, D268). Fourteen symbols, and no
// surface may name a size that is not one of them.
//
//   figure   the board face, tabular — 56 / 40 / 27 / 20. A golf number is a
//            visual object, not a string in a sentence.
//   display  the screen's name, once — 34 / 24, caps.
//   name     a person or a title on the board — 17 / 15, caps.
//   social   the same face, title case, for a person in a row of prose.
//   lead     New York bold 28 — the one sentence a screen slows you down for.
//   story    New York regular 20 — the chapter.
//   body     SF Pro — everything the product actually SAYS.
//   agate    the metadata voice — 12 / 11, the eyebrow, the label, the column
//            head, the unit under a figure.
//   column   Plex Mono — figures in columns, codes, handles, times.
//
// THREE THINGS HERE ARE NOT OBVIOUS AND ALL THREE ARE LOAD-BEARING.
//
// 1 · `Font.custom(_:size:relativeTo:)` OFFERS NO CEILING. `figure`, `display`
//     and `agate` are capped (×1.45–×2.2), so they cannot use it: a capped role
//     reads `\.dynamicTypeSize`, computes
//     `min(UIFontMetrics.scaledValue(for: base), base * cap)` and passes the
//     result to `Font.custom(_:fixedSize:)`. That is why those eight symbols
//     take a `DynamicTypeSize` and the other six do not.
//
// 2 · THE METRICS ARE READ AGAINST THE ENVIRONMENT'S SIZE, NOT THE DEVICE'S.
//     `UIFontMetrics.scaledValue(for:)` with no trait collection reads the
//     SYSTEM content-size category. `-cs_dev_text_size AX3` (IOS-051) pins
//     `\.dynamicTypeSize` and never touches the system's, so every capped role
//     would have photographed at the default size while every uncapped one grew
//     — the AX3 evidence would have been a lie in the direction that flatters.
//     `scaled(_:_:_:)` passes `UITraitCollection(preferredContentSizeCategory:)`
//     built from the environment value, so the capture hatch and the roles agree.
//
// 3 · TRACKING IS A RATIO OF THE RENDERED SIZE, NEVER A LENGTH. `.tracking()`
//     takes absolute points and does not scale, so a role that hard-coded 1.6pt
//     would lose its letterspacing at AX3 exactly where a caps line needs it
//     most. `CSTypeStyle` multiplies the ratio by the size it is ACTUALLY
//     drawing at — and it is the one `.tracking(` call site in the product
//     (`LINT-07` exempts this file and nothing else).

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public enum CSType {
  // MARK: the four face names — the ONLY `.custom(` strings in the product
  //
  // Read from each file's own `name` table (id 6), never remembered: D258
  // shipped `"IBMPlexMono"`, a name none of the three files carries, and 296
  // sites rendered in SF Pro for weeks with no crash and no log. The board
  // cuts are worse — the brief predicted `IBMPlexSansCondensed-SemiBold` and
  // the file says `IBMPlexSansCond-SmBld`.
  public static let boardSemi = CSFont.boardSemibold    // "IBMPlexSansCond-SmBld"
  public static let boardBold = CSFont.boardBold        // "IBMPlexSansCond-Bold"
  public static let monoRegular = CSFont.monoRegular
  public static let monoMedium = CSFont.monoMedium

  // MARK: the nine roles, as fourteen symbols

  /// Every role, with its whole specification. A role is a face, a size, a
  /// tracking RATIO, a leading, a case law and a text style — nine roles that
  /// each declare all six, against the shipped eighteen that declared none.
  public enum Role: String, CaseIterable, Sendable {
    case figureXL, figureL, figureM, figureS
    case display, displayS
    case name, nameS, social
    case lead, story
    case body, bodyS
    case agate, agateS
    case column, columnM, columnS

    /// The default point size — what the role measures at Large.
    public var size: CGFloat {
      switch self {
      case .figureXL: 56
      case .figureL: 40
      case .figureM: 27
      case .figureS: 20
      case .display: 34
      case .displayS: 24
      case .name, .social, .body, .column: 17
      case .nameS, .bodyS: 15
      case .lead: 28
      case .story: 20
      case .agate: 12
      case .agateS, .columnS: 11.5   // agateS is 11; columnS is 12, both floored at 11
      case .columnM: 14
      }
    }

    /// Tracking as a ratio of the RENDERED size (`CSTokens.Track`).
    public var track: Double {
      switch self {
      case .figureXL, .figureL, .figureM, .figureS,
           .social, .story, .body, .bodyS, .column, .columnS: CSTokens.Track.flat
      case .display: CSTokens.Track.d1
      case .displayS: CSTokens.Track.d2
      case .name: CSTokens.Track.caps
      case .nameS: CSTokens.Track.caps2
      case .lead, .columnM: CSTokens.Track.tight
      case .agate: CSTokens.Track.agate
      case .agateS: CSTokens.Track.agateS
      }
    }

    /// Leading as a multiplier of the point size. **Every role declares one** —
    /// none of the shipped eighteen did, which is why the product's paragraphs
    /// and its column heads breathed the same.
    public var leading: CGFloat {
      switch self {
      case .figureXL: 0.92
      case .figureL: 0.94
      case .figureM: 0.96
      case .figureS: 1.00
      case .display: 0.98
      case .displayS: 1.05
      case .name, .nameS, .social: 1.16
      case .lead: 1.14
      case .story: 1.34
      case .body, .bodyS: 1.45
      case .agate, .agateS: 1.20
      case .column: 1.30
      case .columnM: 1.25
      case .columnS: 1.20
      }
    }

    /// The growth ceiling, as a multiple of the base size. `nil` = uncapped,
    /// which is every role a person reads for MEANING rather than as a label.
    public var cap: CGFloat? {
      switch self {
      case .figureXL, .figureL: 1.5
      case .figureM: 1.45          // load-bearing: two digits inside the 44pt rail at AX3
      case .display: 1.6
      case .displayS: 1.8
      case .agate, .agateS: 2.2
      default: nil
      }
    }

    /// Case is the role's job, and it is produced with `.textCase`, never with
    /// `.uppercased()` on a string (`LINT-14`) — which breaks VoiceOver and
    /// localisation. `agate` is `nil` here and takes its case from the caller:
    /// caps for a LABEL, sentence for a PHRASE A PERSON COULD READ ALOUD.
    public var textCase: Text.Case? {
      switch self {
      case .display, .displayS, .name, .nameS: .uppercase
      default: nil
      }
    }

    /// Digits that line up in columns. The whole board depends on it.
    public var tabular: Bool {
      switch self {
      case .figureXL, .figureL, .figureM, .figureS, .columnM, .columnS: true
      default: false
      }
    }

    #if canImport(UIKit)
    var uiStyle: UIFont.TextStyle {
      switch self {
      case .figureXL, .figureL, .display, .lead: .largeTitle
      case .figureM: .title1
      case .figureS, .story: .title3
      case .displayS: .title2
      case .name, .social, .body, .column: .headline
      case .nameS, .bodyS, .columnM: .subheadline
      case .agate: .caption1
      case .agateS, .columnS: .caption2
      }
    }
    #endif

    var swiftUIStyle: Font.TextStyle {
      switch self {
      case .figureXL, .figureL, .display, .lead: .largeTitle
      case .figureM: .title
      case .figureS, .story: .title3
      case .displayS: .title2
      case .name, .social, .body, .column: .headline
      case .nameS, .bodyS, .columnM: .subheadline
      case .agate: .caption
      case .agateS, .columnS: .caption2
      }
    }

    /// Which family sets it — the fence in §1.4 made data.
    public enum Family: Sendable { case board, mono, sans, serif }
    public var family: Family {
      switch self {
      case .figureXL, .figureL, .figureM, .figureS, .display, .displayS,
           .name, .nameS, .social, .agate, .agateS: .board
      case .column, .columnM, .columnS: .mono
      case .body, .bodyS: .sans
      case .lead, .story: .serif
      }
    }
  }

  // MARK: the metric

  /// The size this role actually renders at, for a golfer reading at `d`.
  /// **The floor is 11pt at the default size and nothing goes under it**
  /// (preflight 34/39); the ceiling is the role's own cap.
  public static func renderedSize(_ role: Role, _ d: DynamicTypeSize) -> CGFloat {
    let base = role.size
    #if canImport(UIKit)
    let grown = UIFontMetrics(forTextStyle: role.uiStyle)
      .scaledValue(for: base, compatibleWith: UITraitCollection(preferredContentSizeCategory: d.uiCategory))
    #else
    let grown = base
    #endif
    guard let cap = role.cap else { return grown }
    return min(grown, base * cap)
  }

  /// The role's font, resolved for `d`. Capped roles are `fixedSize` because
  /// `relativeTo:` has no ceiling; uncapped roles scale on their own.
  public static func font(_ role: Role, _ d: DynamicTypeSize = .large) -> Font {
    let pt = renderedSize(role, d)
    switch role.family {
    case .board:
      let face = (role == .name || role == .nameS || role == .social
                  || role == .agate || role == .agateS) ? boardSemi : boardBold
      #if canImport(UIKit)
      if role.tabular, let ui = tabularUIFont(face, pt) { return Font(ui) }
      #endif
      return role.cap == nil
        ? Font.custom(face, size: role.size, relativeTo: role.swiftUIStyle)
        : Font.custom(face, fixedSize: pt)
    case .mono:
      let face = role == .columnS ? monoRegular : monoMedium
      return Font.custom(face, size: role.size, relativeTo: role.swiftUIStyle).monospacedDigit()
    case .sans:
      return Font.system(role.swiftUIStyle, design: .default)
        .weight(role == .body ? .regular : .regular)
    case .serif:
      // D268 · New York, reached through `design: .serif` and NEVER by
      // PostScript string — which is what retires Charter and what keeps
      // `LINT-01` at four names.
      //
      // **AND IT IS SCALED BY HAND, BECAUSE `Font.system(size:weight:design:)`
      // DOES NOT SCALE.** `relativeTo:` exists on `Font.custom` and on the
      // text-style initialiser, and on neither of the two that take a point
      // size AND a design. So `lead` and `story` stood still at every content
      // size: Wave 1's AX3 shot has the product's one serif sentence — the
      // thing the screen slows a golfer down for — rendering SMALLER than the
      // sans standfirst under it. The metric is the same one the capped roles
      // use, read against the ENVIRONMENT's size so the capture hatch and the
      // roles agree; the serif is uncapped, because it is read for meaning.
      return Font.system(size: pt, weight: role == .lead ? .bold : .regular, design: .serif)
    }
  }

  #if canImport(UIKit)
  /// `csTabular()` is `.monospacedDigit()`, which Apple documents for SYSTEM
  /// fonts; on a `Font.custom` it resolves through the descriptor's
  /// `kNumberSpacingType` and works only if the face carries the feature.
  /// Every column in this system — the rail, points, the gap, the form row,
  /// the receipt — depends on it, so the board face asks for it EXPLICITLY
  /// rather than hoping. `CSDesignTests.theBoardFaceAdvancesTabularly` is the
  /// assertion (`LINT-02`).
  public static func tabularUIFont(_ face: String, _ pt: CGFloat) -> UIFont? {
    guard let base = UIFont(name: face, size: pt) else { return nil }
    let d = base.fontDescriptor.addingAttributes([
      .featureSettings: [[
        UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
        UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector,
      ]],
    ])
    return UIFont(descriptor: d, size: pt)
  }
  #endif

  // MARK: the fourteen symbols — the contract (BUILD_BRIEF §3.3)

  public static func figureXL(_ d: DynamicTypeSize) -> Font { font(.figureXL, d) }
  public static func figureL(_ d: DynamicTypeSize) -> Font { font(.figureL, d) }
  /// The rail's 27. Its ×1.45 cap is what keeps two digits inside 44pt at AX3.
  public static func figureM(_ d: DynamicTypeSize) -> Font { font(.figureM, d) }
  public static func figureS(_ d: DynamicTypeSize) -> Font { font(.figureS, d) }

  public static func display(_ d: DynamicTypeSize) -> Font { font(.display, d) }
  public static func displayS(_ d: DynamicTypeSize) -> Font { font(.displayS, d) }

  public static var name: Font { font(.name) }
  public static var nameS: Font { font(.nameS) }
  public static var social: Font { font(.social) }
  public static var lead: Font { font(.lead) }
  public static var story: Font { font(.story) }
  public static var body: Font { font(.body) }
  public static var bodyS: Font { font(.bodyS) }

  public static func agate(_ d: DynamicTypeSize) -> Font { font(.agate, d) }
  public static func agateS(_ d: DynamicTypeSize) -> Font { font(.agateS, d) }

  public static var column: Font { font(.column) }
  public static var columnM: Font { font(.columnM) }
  public static var columnS: Font { font(.columnS) }
}

// MARK: - The modifier

/// A role, applied whole: face, size, tracking, leading and case, in one place.
///
/// A `Font` alone cannot carry tracking or leading, which is how the shipped
/// eighteen roles ended up with **17 tracking values across 175 hand-set
/// sites**. `.csType(_:)` is the only way a role reaches the screen, and it is
/// the only place in the product that multiplies a tracking ratio by a size.
public struct CSTypeStyle: ViewModifier {
  @Environment(\.dynamicTypeSize) private var typeSize
  @Environment(\.legibilityWeight) private var legibility
  let role: CSType.Role
  /// `agate` sets caps for a LABEL and sentence case for a PHRASE (§1.3). The
  /// caller says which, because only the caller knows whether the words can be
  /// read aloud — and only the caps form counts against the budget of ten.
  let caps: Bool?

  public init(_ role: CSType.Role, caps: Bool? = nil) { self.role = role; self.caps = caps }

  public func body(content: Content) -> some View {
    let pt = CSType.renderedSize(role, typeSize)
    let upper = caps ?? (role.textCase == .uppercase)
    return content
      .font(font(pt))
      .tracking(pt * role.track)          // the ONE tracking call site — LINT-07
      .lineSpacing(max(0, pt * (role.leading - 1)))
      .textCase(upper ? .uppercase : nil)
      // §1.5 / §1.2 · the two budgets that carry the identity are counted on
      // the thing they are about — a screen — because a grep sees one agate
      // line in four files and misses the fourteen on the viewport.
      .modifier(CSBudgetTick(display: role == .display ? 1 : 0,
                             agateCaps: (role == .agate || role == .agateS) && upper ? 1 : 0))
  }

  /// Bold Text moves `agate`, `name` and `social` from SemiBold to Bold. Both
  /// cuts are bundled, so honouring the setting costs nothing.
  private func font(_ pt: CGFloat) -> Font {
    guard legibility == .bold, role.family == .board, role.cap != nil || role == .name || role == .nameS || role == .social else {
      return CSType.font(role, typeSize)
    }
    return role.cap == nil
      ? Font.custom(CSType.boardBold, size: role.size, relativeTo: role.swiftUIStyle)
      : Font.custom(CSType.boardBold, fixedSize: pt)
  }
}

public extension View {
  /// Set this view in one of the nine roles. `caps` overrides the role's own
  /// case law and exists for `agate`'s one switch (§1.3).
  func csType(_ role: CSType.Role, caps: Bool? = nil) -> some View {
    modifier(CSTypeStyle(role, caps: caps))
  }
}

// MARK: - The environment's size, as a UIKit category

public extension DynamicTypeSize {
  #if canImport(UIKit)
  /// The UIKit category this SwiftUI size means. Needed because
  /// `UIFontMetrics` reads a trait collection and the capture hatch pins the
  /// environment only.
  var uiCategory: UIContentSizeCategory {
    switch self {
    case .xSmall: .extraSmall
    case .small: .small
    case .medium: .medium
    case .large: .large
    case .xLarge: .extraLarge
    case .xxLarge: .extraExtraLarge
    case .xxxLarge: .extraExtraExtraLarge
    case .accessibility1: .accessibilityMedium
    case .accessibility2: .accessibilityLarge
    case .accessibility3: .accessibilityExtraLarge
    case .accessibility4: .accessibilityExtraExtraLarge
    case .accessibility5: .accessibilityExtraExtraExtraLarge
    @unknown default: .large
    }
  }
  #endif
}
