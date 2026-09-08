// Cup Season — THE PRINTED CARD (D294 / IOS-067, `UI_SYSTEM` §3.3, §16).
//
// The owner: *"Our scorecard looks good lets show it off."* This is the object
// he means, lifted out of the course page and made into a component, so the
// round's receipt and the artifact that leaves the app are the SAME OBJECT at
// two sizes rather than two drawings that will drift.
//
// **IT FOLDS, LIKE A REAL CARD.** Nine columns and a total, then nine more.
// That is why a paper scorecard fits a back pocket, and it is why this one
// fits a 375pt phone at a reading size with no sideways scroller: eighteen
// columns need 542pt and never fit; two blocks of nine need 308pt and always
// do. The shipped `ScorecardSheet` scrolls sideways because it carries a ROW
// PER PLAYER and cannot fold; a round has one golfer and can.
//
// **ONE METAL, NOT A RAINBOW** (§33). A cell under par is `gold` — the
// system's EARNED metal, the same one the podium rule and the settlement card
// use. Everything else is ink. A card that paints five results in five colours
// is a heat map with golf written on it, and covering real golf with
// decoration is the one thing §33 names outright. The number says the bogey.
//
// **L-44 IS THE CALLER'S JOB AND THE COMPONENT HELPS.** A row is drawn only if
// it is handed to this view; a cell with no answer draws the gap glyph and
// never a zero. Nothing here invents a par, a hole or a total.
//
// **ONE VOICEOVER ELEMENT PER ROW.** Eighteen cells read one at a time is not
// a scorecard, it is a lottery draw; each row says its own sentence
// ("Your round, out: four, five, three…"), which is what `CourseCardLeaf`
// learned and what the audit asked for.

import SwiftUI

// MARK: - what a card is made of

public struct CSScorecardCell: Sendable, Equatable {
  /// Empty = a hole with no answer. Drawn as the gap glyph, never a zero.
  public let text: String
  /// The one metal. True paints `gold` — under par, and nothing else.
  public let earned: Bool
  public init(_ text: String, earned: Bool = false) { self.text = text; self.earned = earned }
}

public struct CSScorecardRow: Sendable, Equatable {
  /// **Three voices, and the middle one is the point.** `key` is the hole
  /// numbers — the thing every other row is read against. `quiet` is the
  /// course's own facts, par and the index, which belong to the paper rather
  /// than to the golfer. `score` is the golfer's round, and it is the only row
  /// in ink.
  public enum Voice: Sendable, Equatable { case key, quiet, score }
  public let label: String
  public let cells: [CSScorecardCell]
  /// The tenth column — `Out`, `In`, `Tot`. Empty draws an empty cell, which
  /// is what the stroke-index row wants (an index has no total).
  public let total: String
  public let voice: Voice
  /// One sentence for the whole row. The caller builds it, because only the
  /// caller knows whether these are pars, indexes or strokes.
  public let spoken: String

  public init(label: String, cells: [CSScorecardCell], total: String, voice: Voice, spoken: String) {
    self.label = label; self.cells = cells; self.total = total; self.voice = voice; self.spoken = spoken
  }
}

public struct CSScorecardBlock: Sendable, Equatable {
  /// `OUT` · `IN` · `TOT` — the head over the tenth column.
  public let totalHead: String
  public let rows: [CSScorecardRow]
  public init(totalHead: String, rows: [CSScorecardRow]) {
    self.totalHead = totalHead; self.rows = rows
  }
}

// MARK: - the geometry, as numbers a test can hold

/// **Why two blocks of nine and not one row of eighteen**, stated as
/// arithmetic rather than as an opinion. `CSScorecardTests` asserts these
/// against the narrowest phone the product supports, so the claim in the file
/// header is checked on every build rather than believed.
public enum CSScorecardMetrics {
  public static let cell: CGFloat = 26
  public static let cellA11y: CGFloat = 33
  public static let total: CGFloat = 34
  public static let totalA11y: CGFloat = 42
  public static let label: CGFloat = 40
  public static let labelA11y: CGFloat = 46
  public static let row: CGFloat = 20
  public static let rowA11y: CGFloat = 26

  /// What a block of `columns` holes needs: the key column, the cells, the
  /// tenth column.
  public static func blockWidth(columns: Int, a11y: Bool = false) -> CGFloat {
    (a11y ? labelA11y : label) + CGFloat(columns) * (a11y ? cellA11y : cell) + (a11y ? totalA11y : total)
  }

  /// What a leaf on the page leaves the card: the page gutter on both sides,
  /// then the leaf's own padding on both sides.
  public static func measure(screenWidth: CGFloat) -> CGFloat {
    screenWidth - 2 * CSTokens.Space.gutter - 2 * CSTokens.Space.s3
  }
}

// MARK: - the view

public struct CSScorecard: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize

  let blocks: [CSScorecardBlock]
  /// **Which ground the card is printed on**, and the system already has this
  /// vocabulary: `CSRule.Ground`. On the page's paper it reads `leaf*`; on a
  /// share artifact it reads `ceremony*`, because a leaf inside a dark
  /// artifact is a second object inside the object (§32) and the artifact IS
  /// the paper. One parameter rather than a palette rebuilt at the call site.
  let over: CSRule.Ground
  /// **The artifact printing.** A share PNG is a fixed canvas that must render
  /// the same picture on every phone, so it names its own geometry and its own
  /// point sizes and ignores the reader's text size entirely — the same reason
  /// `csFixed` exists (§1.2). `nil` is the screen, where the metric rules.
  let fixed: Fixed?

  public struct Fixed: Sendable {
    let cell: CGFloat
    let total: CGFloat
    let label: CGFloat
    let row: CGFloat
    let key: CGFloat
    let score: CGFloat
    /// **THE FOLD HAS TO READ AS A FOLD.** The gap between OUT and IN carries
    /// the whole idea that this is two nines and not one eight-row table; at
    /// 20pt rows the page's own `s3` says it, and at the artifact's 62pt rows
    /// the same 12 disappears and the card reads as one block. Caught in
    /// `17pro-card-artifact.png` on the first render.
    let blockGap: CGFloat
    public init(cell: CGFloat, total: CGFloat, label: CGFloat, row: CGFloat,
                key: CGFloat, score: CGFloat, blockGap: CGFloat) {
      self.cell = cell; self.total = total; self.label = label; self.row = row
      self.key = key; self.score = score; self.blockGap = blockGap
    }
  }

  public init(_ blocks: [CSScorecardBlock], over: CSRule.Ground = .leaf, fixed: Fixed? = nil) {
    self.blocks = blocks; self.over = over; self.fixed = fixed
  }

  private var inkColour: Color { over == .ceremony ? cs.ceremonyInk : cs.leafInk }
  private var mutColour: Color { over == .ceremony ? cs.ceremonyMut : cs.leafMut }
  private var goldColour: Color { over == .ceremony ? cs.ceremonyGold : cs.leafGold }

  // MARK: geometry
  //
  // The three widths that make two blocks of nine fit a 375pt phone: the page
  // gutter takes 40, the leaf's own padding takes 24, and 311 is left. A 40pt
  // key column plus nine 26pt cells plus a 34pt total is 308. That is the
  // whole of "no sideways scroller at a reading size", and `RoundCardTests`
  // asserts the arithmetic rather than trusting this comment.
  //
  // AT AN ACCESSIBILITY SIZE THE COLUMNS ARE COMPUTED, NOT GUESSED. The first
  // build pinned them at 33/42/46 and AX3 photographed as a ruin: every
  // two-digit cell truncated to `…`, every row label to `H…`, and the
  // horizontal scroller had nothing to scroll because a `.frame(width:)`
  // CLIPS rather than overflows. The widths now come from the metric —
  // `CSType.renderedSize` — so a column is always wide enough for the widest
  // thing in it, at every size, and the scroller has real width to move.
  private typealias M = CSScorecardMetrics
  /// One mono digit's advance at the role's rendered size. IBM Plex Mono's
  /// advance is 0.6 em; the extra 0.02 pays for the role's own tracking.
  private func advance(_ role: CSType.Role) -> CGFloat {
    CSType.renderedSize(role, typeSize) * 0.62
  }
  private var cellW: CGFloat {
    if let fixed { return fixed.cell }
    guard typeSize.isA11y else { return M.cell }
    return max(M.cellA11y, 2 * advance(.columnM) + CSTokens.Space.s2)
  }
  private var totalW: CGFloat {
    if let fixed { return fixed.total }
    guard typeSize.isA11y else { return M.total }
    return max(M.totalA11y, 3 * advance(.columnS) + CSTokens.Space.s2)
  }
  private var labelW: CGFloat {
    if let fixed { return fixed.label }
    guard typeSize.isA11y else { return M.label }
    return max(M.labelA11y, 5 * advance(.columnS) + CSTokens.Space.s2)
  }
  private var rowH: CGFloat {
    if let fixed { return fixed.row }
    guard typeSize.isA11y else { return M.row }
    return max(M.rowA11y, CSType.renderedSize(.columnM, typeSize) * 1.6)
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: fixed?.blockGap ?? CSTokens.Space.s3) {
      ForEach(Array(blocks.enumerated()), id: \.offset) { _, b in
        block(b)
      }
    }
  }

  @ViewBuilder private func block(_ b: CSScorecardBlock) -> some View {
    // D-5 · at the accessibility sizes the numerals outgrow any measure, so
    // the block scrolls sideways with its ROW LABELS PINNED. The label is not
    // a column head — it is the key the row is read against — and hiding it
    // makes the card unreadable, which is the one thing §16.3's column rule
    // must not be applied to.
    if typeSize.isA11y && fixed == nil {
      HStack(alignment: .top, spacing: 0) {
        labels(b)
        ScrollView(.horizontal, showsIndicators: false) { grid(b) }
      }
      .overlay(alignment: .topLeading) { keyRule }
    } else {
      HStack(alignment: .top, spacing: 0) {
        labels(b)
        grid(b)
      }
      .overlay(alignment: .topLeading) { keyRule }
    }
  }

  /// The one rule the card carries, and it spans the WHOLE block — the key
  /// column included — because a scorecard's line runs the width of the paper.
  private var keyRule: some View {
    CSRule(over: over).offset(y: rowH + CSTokens.Space.s1 / 2)
  }

  private func labels(_ b: CSScorecardBlock) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      ForEach(Array(b.rows.enumerated()), id: \.offset) { _, r in
        text(r.label, voice: .key, caps: true)
          .frame(minWidth: labelW, minHeight: rowH, alignment: .leading)
      }
    }
    .accessibilityHidden(true)
  }

  private func grid(_ b: CSScorecardBlock) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      ForEach(Array(b.rows.enumerated()), id: \.offset) { i, r in
        row(r, head: i == 0 ? b.totalHead : nil)
      }
    }
  }

  private func row(_ r: CSScorecardRow, head: String?) -> some View {
    HStack(spacing: 0) {
      ForEach(Array(r.cells.enumerated()), id: \.offset) { _, c in
        text(c.text.isEmpty ? Self.gap : c.text, voice: r.voice, earned: c.earned)
          .frame(minWidth: cellW, minHeight: rowH)
      }
      text(head ?? r.total, voice: head != nil ? .key : r.voice, caps: head != nil)
        .frame(minWidth: totalW, minHeight: rowH, alignment: .trailing)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(r.spoken)
  }

  /// A hole with no answer. The middle dot, not a zero and not a dash — a zero
  /// is a score and a dash is a subtraction.
  private static let gap = "\u{00B7}"

  @ViewBuilder private func text(_ s: String, voice: CSScorecardRow.Voice,
                                 earned: Bool = false, caps: Bool = false) -> some View {
    let ink: Color = earned ? goldColour : (voice == .score ? inkColour : mutColour)
    // `.fixedSize` is the fix for the AX3 ruin: a cell is never truncated, and
    // the `minWidth` floors above keep the columns square when the content is
    // narrower than the column.
    if let fixed {
      Text(s)
        .csFixed(voice == .score ? .columnM : .columnS, voice == .score ? fixed.score : fixed.key)
        .textCase(caps ? .uppercase : nil)
        .foregroundStyle(ink)
        .csTabular()
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
    } else {
      Text(s)
        .csType(voice == .score ? .columnM : .columnS, caps: caps)
        .foregroundStyle(ink)
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
    }
  }
}
