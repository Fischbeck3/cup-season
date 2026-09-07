// Cup Season — THE RECEIPT, ON A LEAF (Wave 7, `surfaces/leaderboard.md` §6).
//
// `BRIEF` §16's second half: a 74 is worth what it is worth, and the receipt is
// why. A receipt is a PRINTED GRID, which is the one thing §3.3 licenses a leaf
// for — so this is the leaf, and it is the only container on the surface.
//
// **`ReceiptRows.build` is untouched.** Nothing here invents a row, reorders
// one, or decides which rows exist: the producer already decides, including the
// `.note` case where a round posted with no number replaces the number rows
// with one sentence. This file is the printing.
//
// THE ANATOMY, top to bottom:
//   · a caption row — `WHAT THIS ROUND WAS WORTH` left, the dateline right
//   · the rows: `body` labels at `leafInk` (the arithmetic and the two handicap
//     nouns at `leafMut`, because they are the working and not the answer),
//     values in `column` tabular, hairlines at `a16` of `leafInk`
//   · the verdict's band word hanging in `agateS` UNDER its figure
//   · **the total under a 2pt `leafInk` rule, its value in `figure` 20** — a
//     receipt ends in a figure, which is the whole point of a receipt
//
// **Gold ink never touches a leaf** (1.68:1). A won or earned figure takes a
// 2pt gold rule beneath it — `CSLeafRule.earned()` — and its ink stays leaf ink.

import SwiftUI
import CSDesign
import CupSeasonKit

struct ReceiptLeaf: View {
  @Environment(\.cs) private var cs
  let caption: String
  let dateline: String?
  let rows: [ReceiptRow]
  /// Which label ends the receipt. Everything from it down sits under the 2pt
  /// rule; the producer's order decides where that falls, never this view.
  var totalLabel: String = "Points"

  var body: some View {
    CSLeaf(padding: CSTokens.Space.s3) {
      head
      ForEach(Array(split.before.enumerated()), id: \.offset) { i, row in
        line(row, first: i == 0)
      }
      if !split.total.isEmpty {
        CSRule(.heavy, over: .leaf).padding(.top, CSTokens.Space.s1)
        ForEach(Array(split.total.enumerated()), id: \.offset) { i, row in
          // the total, then its own sub-clauses: `THIS MONTH · COUNTING #2 OF
          // 4` is the figure's caption, not three more rows of body
          line(row, first: true, total: i == 0, tail: i > 0)
        }
      }
    }
  }

  private var head: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(caption).csType(.agateS, caps: true).foregroundStyle(cs.leafMut)
        .fixedSize(horizontal: false, vertical: true)
      Spacer(minLength: CSTokens.Space.s2)
      if let dateline {
        Text(dateline).csType(.agateS, caps: true).foregroundStyle(cs.leafMut).lineLimit(1)
      }
    }
    .accessibilityElement(children: .combine)
  }

  /// The producer emits the total last; the rule goes above it. `POINTS` is the
  /// label that ends a round's receipt and `THE POT` a settlement's, so the
  /// caller names it rather than this view guessing from a string.
  private var split: (before: [ReceiptRow], total: [ReceiptRow]) {
    guard let i = rows.firstIndex(where: {
      if case .math(let l, _, _) = $0 { return l.caseInsensitiveCompare(totalLabel) == .orderedSame }
      return false
    }) else { return (rows, []) }
    return (Array(rows[..<i]), Array(rows[i...]))
  }

  @ViewBuilder private func line(_ row: ReceiptRow, first: Bool, total: Bool = false,
                                 tail: Bool = false) -> some View {
    switch row {
    case .math(let label, let value, let sub):
      mathRow(label: label, value: value, sub: sub, total: total, first: first, tail: tail)
    case .note(let sentence):
      // D124 (i) — a sentence standing where the verdict row would, on the
      // same grid. It is the one line of prose a leaf may hold, because the
      // producer put it in a row's place.
      VStack(spacing: 0) {
        if !first { hair }
        Text(sentence).csType(.body).foregroundStyle(cs.leafInk)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical, tail ? CSTokens.Space.s1 : CSTokens.Space.s2)
          .fixedSize(horizontal: false, vertical: true)
      }
    case .playedWith, .scorecard:
      // Both live OUTSIDE the leaf — one is a credit line and one is a door,
      // and a leaf holds a grid. The sheets draw them under it (§6.8).
      EmptyView()
    }
  }

  @ViewBuilder private func mathRow(label: String, value: String, sub: Bool, total: Bool,
                                    first: Bool, tail: Bool = false) -> some View {
    // The verdict arrives from the producer as `−7.6 — BEAT YOUR NUMBER`: one
    // string, because one producer writes it for three renderers. The band
    // word HANGS UNDER ITS FIGURE here, so the split is on the producer's own
    // separator rather than on a guess about prose.
    let parts = value.components(separatedBy: " — ")
    VStack(spacing: 0) {
      if !first && !total { hair }
      A11yStack(rowAlignment: .firstTextBaseline, spacing: CSTokens.Space.s3, columnSpacing: 2) {
        // **THE RECEIPT ENDS IN A FIGURE, NOT IN PROSE** (non-negotiable 3).
        // The total was `Points` in sentence-case `body` beside `6` at
        // `figureS` — one more row, at a size barely above the rows it sums,
        // so the 2pt `leafInk` rule above it separated nothing from nothing.
        // `lb-score-object.png` sets it as the climax it is: the label in
        // board caps, the figure at 27.
        Text(label)
          .csType(total ? .name : (tail ? .agateS : .body), caps: total || tail)
          .foregroundStyle(tail || sub ? cs.leafMut : cs.leafInk)
          .fixedSize(horizontal: false, vertical: true)
        Spacer(minLength: CSTokens.Space.s2)
        VStack(alignment: .trailing, spacing: 1) {
          if total {
            Text(parts[0]).csType(.figureM).foregroundStyle(cs.leafInk)
          } else {
            Text(parts[0]).csType(tail ? .agateS : .columnM, caps: tail)
              .foregroundStyle(tail || sub ? cs.leafMut : cs.leafInk)
              .multilineTextAlignment(.trailing)
          }
          if parts.count > 1 {
            Text(parts[1]).csType(.agateS, caps: true).foregroundStyle(cs.leafMut)
              .multilineTextAlignment(.trailing)
          }
        }
      }
      .padding(.vertical, tail ? CSTokens.Space.s1 : CSTokens.Space.s2)
      .accessibilityElement(children: .combine)
    }
  }

  /// The leaf's own hairline — `a16` of `leafInk`, never the page's `rule`, which is
  /// cut for the page's ground and disappears on bone.
  private var hair: some View {
    Rectangle().fill(cs.leafInk.opacity(CSTokens.Alpha.a16)).frame(height: CSTokens.Space.hair)
  }
}
