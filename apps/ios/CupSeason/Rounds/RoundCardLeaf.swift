// Cup Season — the round's own card, on the round's own page (D294 / IOS-067).
//
// The owner: *"Our scorecard looks good lets show it off."*
//
// THE MAPPING IS A PURE FUNCTION AND THAT IS DELIBERATE. `RoundCardBlocks`
// turns a `RoundScorecard` into the rows `CSScorecard` draws, and every L-44
// rule in this feature is a line in it: a row is BUILT only when its fact
// exists, so "the card does not draw a par it does not have" is not a `if let`
// buried in a view body — it is a value a test can hold, and `RoundCardTests`
// holds it.
//
// **THE GOLFER WHO PLAYED THE ROUND SEES IT.** The audit's finding 9 is that
// the settlement card — *"the product's most beautiful object"* — exists ONLY
// as a share PNG, so the golfer who won the match reads a bulleted list while
// the beautiful thing goes to everybody else. The card is drawn HERE first, on
// his own receipt, in his own theme, at his own text size; the artifact is the
// same object rendered for people who are not holding his phone.

import SwiftUI
import CSDesign
import CupSeasonKit

enum RoundCardBlocks {
  /// The four rows a scorecard can have, in the order paper prints them, and
  /// **each one appears only if its fact does**:
  ///
  ///   * `Hole` — always, because a card with no key is a list of numbers.
  ///   * `Par` — only when the server proved a par (a pinned tee, or every
  ///     cached tee at the course agreeing). Never for a nine: nothing records
  ///     WHICH nine was walked.
  ///   * `HCP` — only when the index was proved SEPARATELY. It agrees far less
  ///     often than par does, because it is printed per gender, so a card with
  ///     par and no index is the ordinary case (TERMINOLOGY §3.1 rules `SI` out
  ///     as an engine word; the column is `HCP`).
  ///   * the golfer's strokes — only when the set is whole and sums to the
  ///     gross printed above it.
  static func build(_ card: RoundScorecard, mine: Bool) -> [CSScorecardBlock] {
    card.blocks.map { b in
      var rows: [CSScorecardRow] = []
      let holes = b.holes

      rows.append(CSScorecardRow(
        label: "Hole",
        cells: holes.map { CSScorecardCell("\($0.hole)") },
        total: "", voice: .key,
        spoken: "Holes \(holes.first?.hole ?? 1) through \(holes.last?.hole ?? 1)."))

      if card.hasPar {
        rows.append(CSScorecardRow(
          label: "Par",
          cells: holes.map { CSScorecardCell($0.par.map(String.init) ?? "") },
          total: b.par.map(String.init) ?? "", voice: .quiet,
          spoken: say("Pars", holes.map(\.par), total: b.par, label: b.totalLabel)))
      }

      if card.hasIndex {
        rows.append(CSScorecardRow(
          label: "HCP",                                   // TERMINOLOGY §3.1
          cells: holes.map { CSScorecardCell($0.si.map(String.init) ?? "") },
          total: "", voice: .quiet,
          spoken: say("Stroke indexes", holes.map(\.si), total: nil, label: b.totalLabel)))
      }

      if card.hasStrokes {
        rows.append(CSScorecardRow(
          label: mine ? "You" : "Score",
          cells: holes.map { h in
            CSScorecardCell(h.strokes.map(String.init) ?? "", earned: h.mark == .under)
          },
          total: b.strokes.map(String.init) ?? "", voice: .score,
          spoken: say(mine ? "Your round" : "The round", holes.map(\.strokes),
                      total: b.strokes, label: b.totalLabel)))
      }

      return CSScorecardBlock(totalHead: b.totalLabel, rows: rows)
    }
  }

  /// One sentence per row. A hole with no answer is said as "no score", never
  /// skipped — a VoiceOver reader counting along the row has to hear the gap.
  private static func say(_ head: String, _ values: [Int?], total: Int?, label: String) -> String {
    let body = values.map { $0.map(String.init) ?? "no score" }.joined(separator: ", ")
    let tail = total.map { ". \(label) \($0)" } ?? ""
    return "\(head): \(body)\(tail)."
  }
}

/// The card, printed on paper, on the round's page.
struct RoundCardLeaf: View {
  @Environment(\.cs) private var cs
  let card: RoundScorecard
  let mine: Bool

  var body: some View {
    CSLeaf {
      // The leaf's own title, in `CourseCardLeaf`'s shape and place: the tee's
      // name and the par it plays to, or — when the cache cannot prove either
      // — what the card IS rather than an apology for what it is not. The
      // section head above already says THE CARD; saying it twice on one
      // screen is §27's repetitive header with two lines between them.
      if let d = card.dateline {
        Text(d).csType(.agateS, caps: true).foregroundStyle(cs.leafMut)
          .fixedSize(horizontal: false, vertical: true)
      }
      CSScorecard(RoundCardBlocks.build(card, mine: mine))
    }
  }
}
