// Cup Season — the printed card's geometry and its rows (D294 / IOS-067).
//
// Two claims live here that a screenshot cannot make:
//
//   1 · **WHY IT FOLDS.** Eighteen columns never fit a 375pt phone and two
//       blocks of nine always do. That is the entire reason the card is drawn
//       as a card rather than as a sideways scroller, and it is arithmetic.
//   2 · **WHICH ROWS EXIST.** `RoundCardBlocks.build` is where L-44 lands on
//       the phone: a row is built only when its fact is there. Asserting the
//       row COUNT is asserting that the product cannot draw a par it does not
//       have, at every size and in both themes at once.

import XCTest
import CSDesign
import CupSeasonKit
@testable import CupSeason

final class RoundCardTests: XCTestCase {

  // MARK: - fixtures

  private func full(_ n: Int = 18) -> RoundScorecard {
    let pars = [4, 3, 5, 4, 3, 4, 4, 3, 5, 3, 5, 4, 4, 3, 4, 5, 3, 4]
    let sis  = [5, 15, 3, 1, 9, 11, 7, 13, 17, 16, 18, 12, 2, 6, 4, 14, 8, 10]
    let str  = [5, 4, 4, 6, 4, 5, 5, 3, 6, 5, 6, 5, 7, 4, 7, 4, 4, 6]
    let holes = (1...n).map {
      RoundScorecardHole(hole: $0, par: pars[$0 - 1], si: sis[$0 - 1], strokes: str[$0 - 1])
    }
    return RoundScorecard(holesPlayed: n, holes: holes, teeName: "Black", parSource: .tee,
                          out: 42, inn: n == 18 ? 48 : nil, total: n == 18 ? 90 : 42,
                          parOut: 35, parIn: n == 18 ? 35 : nil, parTotal: n == 18 ? 70 : 35)
  }

  private func strokesOnly() -> RoundScorecard {
    RoundScorecard.fromHoleRows((1...18).map { (hole: $0, strokes: 5) },
                                gross: 90, holesPlayed: 18)!
  }

  // MARK: - 1 · why the card folds

  /// **THE CLAIM THE WHOLE DESIGN RESTS ON.** The SE 3 is 375pt; the page
  /// gutter takes 20 either side and the leaf's own padding takes 12 either
  /// side, which leaves 311. One block of nine needs 308 and fits with 3pt to
  /// spare; eighteen in a row needs 542 and never has.
  func testNineColumnsFitTheNarrowestPhoneAndEighteenNeverDo() {
    let measure = CSScorecardMetrics.measure(screenWidth: 375)
    XCTAssertEqual(measure, 311, accuracy: 0.01)
    XCTAssertLessThanOrEqual(CSScorecardMetrics.blockWidth(columns: 9), measure,
                             "the fold is the reason there is no sideways scroller at a reading size")
    XCTAssertGreaterThan(CSScorecardMetrics.blockWidth(columns: 18), measure,
                         "if eighteen ever fitted, the fold would be decoration and should be deleted")
  }

  /// It fits the wide phones too — the fold is not a small-screen concession,
  /// it is the shape of a scorecard.
  func testTheFoldFitsEveryPhoneTheProductSupports() {
    for width in [375.0, 402.0, 440.0] {
      XCTAssertLessThanOrEqual(CSScorecardMetrics.blockWidth(columns: 9),
                               CSScorecardMetrics.measure(screenWidth: width),
                               "a block of nine must fit a \(Int(width))pt phone")
    }
  }

  /// At an accessibility size the block is DELIBERATELY wider than the phone —
  /// that is what the horizontal scroller is for (D-5), and if it ever stopped
  /// being true the scroller would be dead chrome.
  func testAtAnAccessibilitySizeTheBlockOverflowsOnPurpose() {
    XCTAssertGreaterThan(CSScorecardMetrics.blockWidth(columns: 9, a11y: true),
                         CSScorecardMetrics.measure(screenWidth: 375))
  }

  // MARK: - 2 · which rows exist

  func testAPinnedTeeDrawsAllFourRows() {
    let blocks = RoundCardBlocks.build(full(), mine: true)
    XCTAssertEqual(blocks.count, 2)
    XCTAssertEqual(blocks[0].rows.map(\.label), ["Hole", "Par", "HCP", "You"])
    XCTAssertEqual(blocks[0].totalHead, "Out")
    XCTAssertEqual(blocks[1].totalHead, "In")
  }

  /// The state build 733 is in today: strokes from `round_holes_of`, no par
  /// anywhere. Two rows, and the product does not pretend otherwise.
  func testAStrokesOnlyCardDrawsTwoRows() {
    let blocks = RoundCardBlocks.build(strokesOnly(), mine: true)
    XCTAssertEqual(blocks[0].rows.map(\.label), ["Hole", "You"])
  }

  /// Par agreed across the course's tees; the index did not. Three rows.
  func testParWithoutAnIndexDrawsThreeRows() {
    let card = RoundScorecard(
      holesPlayed: 18,
      holes: (1...18).map { RoundScorecardHole(hole: $0, par: 4, si: nil, strokes: 5) },
      parSource: .course, parTotal: 72)
    let blocks = RoundCardBlocks.build(card, mine: true)
    XCTAssertEqual(blocks[0].rows.map(\.label), ["Hole", "Par", "You"])
  }

  func testSomebodyElsesRoundIsNotLabelledYou() {
    let mine = RoundCardBlocks.build(full(), mine: true)[0].rows.last!
    let theirs = RoundCardBlocks.build(full(), mine: false)[0].rows.last!
    XCTAssertEqual(mine.label, "You")
    XCTAssertEqual(theirs.label, "Score")
  }

  // MARK: - 3 · the one metal

  /// §33 · under par is gold and NOTHING ELSE IS. The fixture's front nine has
  /// exactly one hole under par (the 3rd, a 4 on a par 5) and eight that are
  /// not, including a level par 3.
  func testOnlyTheHolesUnderParAreMarked() {
    let you = RoundCardBlocks.build(full(), mine: true)[0].rows.last!
    XCTAssertEqual(you.cells.map(\.earned), [false, false, true, false, false, false, false, false, false])
  }

  func testAStrokesOnlyCardCarriesNoMetalAtAll() {
    let you = RoundCardBlocks.build(strokesOnly(), mine: true)[0].rows.last!
    XCTAssertFalse(you.cells.contains { $0.earned },
                   "with no par there is nothing to be under, so nothing is gold")
  }

  // MARK: - 4 · one VoiceOver sentence per row, and it counts the gaps

  func testARowSpeaksAsOneSentenceAndSaysItsGapsOutLoud() {
    let card = RoundScorecard(
      holesPlayed: 18,
      holes: (1...18).map { RoundScorecardHole(hole: $0, par: 4, strokes: $0 == 3 ? nil : 5) },
      parSource: .course, parTotal: 72)
    let you = RoundCardBlocks.build(card, mine: true)[0].rows.last!
    XCTAssertTrue(you.spoken.hasPrefix("Your round: "))
    XCTAssertTrue(you.spoken.contains("no score"),
                  "a reader counting along the row has to hear the hole that was never scored")
  }

  // MARK: - 5 · the copy is the producer's

  func testTheHeadAndTheShareReadFromRoundCopy() {
    XCTAssertEqual(RoundCopy.cardHead, "The card")
    XCTAssertEqual(RoundCopy.cardShare, "Share the card")
    XCTAssertFalse(RoundCopy.cardStrokesOnly.isEmpty)
  }
}
