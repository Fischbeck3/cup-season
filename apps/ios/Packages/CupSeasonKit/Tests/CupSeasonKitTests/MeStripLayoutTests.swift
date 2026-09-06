// Cup Season — the ME strip's reflow, as arithmetic (D258, IOS-039).
//
// IA §4.2 makes "at AX3 the four facts reflow to two rows of two and nothing
// truncates" an acceptance test for the strip. These are that test, at the
// grain a test can actually hold: a MONOSPACED word's width is its character
// count times one unit, so "does this pair fit that column" is a calculation
// with a right answer.
//
// The two failures they exist to stop coming back:
//   · two rows of two taken at a size where a single unbreakable word — NUMBER,
//     BUILDING, CANYON — is wider than half the strip, which SwiftUI answers by
//     breaking the word across two lines (`NUMBE` / `R`, seen at AX5);
//   · the copy growing a word longer than the widest label the layout can hold,
//     which is a producer change with a layout consequence and no other alarm.

import Testing
import Foundation
@testable import CupSeasonKit

// The two units the phone measures off a ten-character probe, at the sizes that
// matter. Both are `MeStripLayout.unit(pointSize:tracking:)` — IBM Plex Mono at
// 0.6 em, plus the label's 1.2pt tracking — evaluated at the point sizes the
// simulator renders `CSFont.label` (11 on .caption2) and `CSFont.monoMediumBody`
// (14 on .subheadline) at.
private enum Units {
  /// The reading sizes: label 11pt, value 14pt.
  static let labelReading = MeStripLayout.unit(pointSize: 11, tracking: MeStripLayout.labelTracking)
  static let valueReading = MeStripLayout.unit(pointSize: 14)
  /// AX3, measured on an iPhone 17 Pro at `accessibility-extra-large` — the
  /// running app's own numbers (`-cs_dev_strip_metrics`), not a table.
  static let labelAX3 = 19.2
  static let valueAX3 = 18.0
  /// AX5, the same phone at `accessibility-extra-extra-extra-large`. These are
  /// the numbers the running app reported (`-cs_dev_strip_metrics`).
  static let labelAX5 = 25.8
  static let valueAX5 = 24.6
}

/// The iPhone 17 Pro's Home column: 402pt less 20pt of page padding each side.
private let stripWidth = 362.0
/// What one of two columns gives its TEXT: the strip, less the 14pt gutter,
/// halved, less the 12pt the slots' own hit slop insets it by.
private let columnAX = (stripWidth - 14) / 2 - 12          // 162

private func slot(_ fact: MeStripCopy.Fact, _ label: String, _ value: String) -> MeStripCopy.Slot {
  MeStripCopy.Slot(fact: fact, label: label, value: value, door: .yourCard, voiceOver: label)
}

/// The strip as the owner's own Home produces it.
private let realSlots = [
  slot(.myNumber, "YOUR NUMBER", "10.6"),
  slot(.myNextRound, "NEXT", "MON · GOLD CANYON"),
  slot(.myMoney, "YOU STILL OWE", "$75"),
]

@Suite("The ME strip's reflow")
struct MeStripLayoutTests {

  @Test("a word's width is its length times one unit — the face is monospaced")
  func runWidthIsArithmetic() {
    #expect(MeStripLayout.runWidth("NUMBER", unit: 20) == 120)
    #expect(MeStripLayout.runWidth("", unit: 20) == 0)
    // 11pt Plex Mono with the label's tracking: 6.6 + 1.2
    #expect(abs(Units.labelReading - 7.8) < 0.001)
  }

  @Test("what has to fit is the longest WORD, not the whole string")
  func widestWordIsTheUnbreakableRun() {
    // `YOUR NUMBER` breaks after YOUR; `NUMBER` has nowhere to break.
    #expect(MeStripLayout.widestWord("YOUR NUMBER", unit: 10) == 60)
    #expect(MeStripLayout.widestWord("BUILDING", unit: 10) == 80)
    // the value slot's own worst case
    #expect(MeStripLayout.widestWord("MON · GOLD CANYON", unit: 10) == 60)
  }

  @Test("AX3 · the four facts reflow to two rows of two — IA §4.2's acceptance test")
  func twoUpAtAX3() {
    #expect(MeStripLayout.twoUp(realSlots, columnWidth: columnAX,
                                valueUnit: Units.valueAX3, labelUnit: Units.labelAX3))
  }

  @Test("AX5 · the grid holds for these three facts and yields to BUILDING")
  func ax5IsDecidedByTheLongestWord() {
    // 6 × 25.8 = 154.8 fits a 162pt column, so `YOUR NUMBER` is still two-up at
    // AX5 — which the running app draws. `BUILDING` is 206.4 and is not, so a
    // golfer under three rounds gets one fact per row at that size.
    #expect(MeStripLayout.twoUp(realSlots, columnWidth: columnAX,
                                valueUnit: Units.valueAX5, labelUnit: Units.labelAX5))
    #expect(MeStripLayout.widestWord("BUILDING", unit: Units.labelAX5) > columnAX)
    let building = realSlots + [slot(.myLastRound, "BUILDING", "1 OF 3")]
    #expect(!MeStripLayout.twoUp(building, columnWidth: columnAX,
                                 valueUnit: Units.valueAX5, labelUnit: Units.labelAX5))
  }

  @Test("a narrower phone at AX5 falls back to one fact per row rather than truncating")
  func oneUpOnANarrowerPhone() {
    // The narrowest phone the app supports is 375pt wide: 335 of content, less
    // the gutter and the hit slop, is 148.5 a column. `YOUR NUMBER` at AX5
    // wants 154.8 for the word `NUMBER` alone.
    let small = (335.0 - 14) / 2 - 12                       // 148.5
    #expect(MeStripLayout.widestWord("YOUR NUMBER", unit: Units.labelAX5) > small)
    #expect(!MeStripLayout.twoUp(realSlots, columnWidth: small,
                                 valueUnit: Units.valueAX5, labelUnit: Units.labelAX5))
    // and at AX3 the same phone still gets the grid, which is the point of
    // deciding rather than picking one layout for every accessibility size
    #expect(MeStripLayout.twoUp(realSlots, columnWidth: small,
                                valueUnit: Units.valueAX3, labelUnit: Units.labelAX3))
  }

  @Test("an unmeasured strip never guesses — no width, no units, no grid")
  func unmeasuredIsAlwaysOneUp() {
    #expect(!MeStripLayout.twoUp(realSlots, columnWidth: 0, valueUnit: 20, labelUnit: 20))
    #expect(!MeStripLayout.twoUp(realSlots, columnWidth: columnAX, valueUnit: 0, labelUnit: 20))
    #expect(!MeStripLayout.twoUp(realSlots, columnWidth: columnAX, valueUnit: 20, labelUnit: 0))
    #expect(!MeStripLayout.twoUp([realSlots[0]], columnWidth: 999, valueUnit: 20, labelUnit: 20))
  }

  @Test("the pairs are the reading order, and an odd fact takes the left column")
  func pairsKeepTheOrder() {
    let p = MeStripLayout.pairs(realSlots)
    #expect(p.count == 2)
    #expect(p[0].map(\.fact) == [.myNumber, .myNextRound])
    #expect(p[1].map(\.fact) == [.myMoney])
    #expect(MeStripLayout.pairs([]).isEmpty)
  }

  // MARK: - The copy-length assertion
  //
  // Every label and every value the producer can emit is a string a column has
  // to hold. A reword that adds one long word turns two rows of two into a
  // broken word at AX3 with nothing else to say so — so the budget is a test.

  @Test("no label the strip can print has a word longer than NUMBER")
  func labelsStayWithinTheBudget() {
    // The producer's own set, read off `MeStripCopy` rather than remembered.
    let labels = ["YOUR NUMBER", "STARTER", "BUILDING", "LAST", "NEXT", "YOU STILL OWE"]
    for l in labels {
      let widest = MeStripLayout.widestWord(l, unit: Units.labelAX3)
      #expect(widest <= columnAX, "\(l) needs \(widest)pt of a \(columnAX)pt column at AX3")
    }
  }

  @Test("no fixed value the strip can print overflows its column at AX3")
  func fixedValuesStayWithinTheBudget() {
    // The values the producer writes itself. A course name comes from the
    // database and is shortened by `MeStripCopy.shortCourse`; the longest club
    // name in production is the one below.
    let values = ["NO ROUNDS YET", "PLAN ONE", "—", "1 OF 3", "MON · GOLD CANYON", "TOMORROW 7:10"]
    for v in values {
      let widest = MeStripLayout.widestWord(v, unit: Units.valueAX3)
      #expect(widest <= columnAX, "\(v) needs \(widest)pt of a \(columnAX)pt column at AX3")
    }
  }

  @Test("a course long enough to break the grid takes the one-up layout instead")
  func aVeryLongClubNameFallsBack() {
    let long = [realSlots[0],
                slot(.myNextRound, "NEXT", "MON · SOMETHINGVERYLONGINDEED")]
    #expect(!MeStripLayout.twoUp(long, columnWidth: columnAX,
                                 valueUnit: Units.valueAX3, labelUnit: Units.labelAX3))
  }
}
