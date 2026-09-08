// Cup Season — the card's rules, asserted rather than photographed
// (D294 / IOS-067).
//
// Every L-44 rule in this feature is arithmetic, and a screenshot cannot hold
// arithmetic: "the strokes must sum to the gross printed above them" is either
// true of a value or it is not, and the only way to know it stays true is to
// ask it on every build.

import XCTest
@testable import CupSeasonKit

final class RoundScorecardTests: XCTestCase {

  private func json(_ s: String) -> JSONValue {
    try! JSONDecoder().decode(JSONValue.self, from: Data(s.utf8))
  }

  // MARK: - the gross seal, which is the whole of the fallback path

  /// The state build 733 is in TODAY: `round_scorecard` is unpushed, so the
  /// card comes back from `round_holes_of` as rows, and the seal the server
  /// would have applied has to be applied here.
  func testWholeSetThatSumsToTheGrossIsTheCard() {
    let rows = (1...18).map { (hole: $0, strokes: 5) }
    let card = RoundScorecard.fromHoleRows(rows, gross: 90, holesPlayed: 18)
    XCTAssertNotNil(card)
    XCTAssertEqual(card?.total, 90)
    XCTAssertEqual(card?.out, 45)
    XCTAssertEqual(card?.inn, 45)
    XCTAssertEqual(card?.holes.count, 18)
    XCTAssertFalse(card?.hasPar ?? true, "the fallback has rows and nothing else — it must not invent a par")
  }

  /// **A card whose columns do not add up to the number printed above them is
  /// worse than no card.** All six sets in prod pass today; this is the line
  /// between a future bug and a card that lies.
  func testASetThatDoesNotSumToTheGrossIsNotThisRoundsCard() {
    let rows = (1...18).map { (hole: $0, strokes: 5) }   // 90
    XCTAssertNil(RoundScorecard.fromHoleRows(rows, gross: 84, holesPlayed: 18))
  }

  func testAGapMakesItNotACard() {
    var rows = (1...18).map { (hole: $0, strokes: 5) }
    rows.remove(at: 6)                                    // hole 7 never scored
    XCTAssertNil(RoundScorecard.fromHoleRows(rows, gross: 85, holesPlayed: 18),
                 "seventeen holes is not an eighteen-hole card, whatever they add to")
  }

  func testNoGrossToCheckAgainstMeansNoCard() {
    let rows = (1...18).map { (hole: $0, strokes: 5) }
    XCTAssertNil(RoundScorecard.fromHoleRows(rows, gross: nil, holesPlayed: 18))
  }

  /// A nine is nine rows, 1…9, and eighteen rows on a nine is not the nine's
  /// card either.
  func testANineTakesNineRows() {
    let nine = (1...9).map { (hole: $0, strokes: 4) }
    let card = RoundScorecard.fromHoleRows(nine, gross: 36, holesPlayed: 9)
    XCTAssertEqual(card?.holes.count, 9)
    XCTAssertEqual(card?.total, 36)
    XCTAssertNil(card?.inn, "a nine has no back nine to total")
  }

  // MARK: - the fold

  func testEighteenFoldsIntoOutAndIn() {
    let rows = (1...18).map { (hole: $0, strokes: $0 <= 9 ? 4 : 5) }
    let card = RoundScorecard.fromHoleRows(rows, gross: 81, holesPlayed: 18)!
    XCTAssertEqual(card.blocks.count, 2)
    XCTAssertEqual(card.blocks[0].totalLabel, "Out")
    XCTAssertEqual(card.blocks[0].strokes, 36)
    XCTAssertEqual(card.blocks[1].totalLabel, "In")
    XCTAssertEqual(card.blocks[1].strokes, 45)
  }

  /// **A nine's tenth column is `Tot`, never `Out`.** `round_holes` numbers a
  /// nine 1…9 whichever nine was walked, so calling it OUT would be the product
  /// asserting the front nine on no evidence — the same reason the server
  /// refuses to give a nine a par row.
  func testANinesTotalIsNotCalledOut() {
    let card = RoundScorecard.fromHoleRows((1...9).map { (hole: $0, strokes: 4) },
                                           gross: 36, holesPlayed: 9)!
    XCTAssertEqual(card.blocks.count, 1)
    XCTAssertEqual(card.blocks[0].totalLabel, "Tot")
  }

  // MARK: - the payload

  func testAPinnedTeeCarriesParTheIndexAndItsName() {
    let card = RoundScorecard(json("""
      {"holes_played":18,"gross":90,"tee_name":"Black","par_source":"tee",
       "par_out":35,"par_in":35,"par_total":70,"out":42,"inn":48,"total":90,
       "holes":[{"hole":1,"par":4,"si":5,"strokes":5}]}
    """))
    XCTAssertEqual(card?.teeName, "Black")
    XCTAssertEqual(card?.parSource, .tee)
    XCTAssertEqual(card?.parTotal, 70)
    XCTAssertTrue(card?.hasPar ?? false)
    XCTAssertTrue(card?.hasIndex ?? false)
  }

  /// **Par without an index is the ordinary case, not a degraded one.** 56 of
  /// 87 cached courses agree on par across their tees; only 31 agree on the
  /// index, because it is printed per gender.
  func testParAndTheIndexArriveIndependently() {
    let card = RoundScorecard(json("""
      {"holes_played":18,"par_source":"course","par_total":72,
       "holes":[{"hole":1,"par":4,"strokes":5},{"hole":2,"par":3,"strokes":3}]}
    """))
    XCTAssertTrue(card?.hasPar ?? false)
    XCTAssertFalse(card?.hasIndex ?? true)
    XCTAssertNil(card?.teeName, "no tee was identified on the course route, so none is named")
    XCTAssertEqual(card?.parSource, .course)
  }

  func testANullAnswerIsNoCard() {
    XCTAssertNil(RoundScorecard(json("null")))
    XCTAssertNil(RoundScorecard(nil))
  }

  // MARK: - the one metal

  func testUnderParIsTheOnlyMarkThatEarnsTheMetal() {
    XCTAssertEqual(RoundScorecardHole(hole: 1, par: 5, strokes: 4).mark, .under)
    XCTAssertEqual(RoundScorecardHole(hole: 1, par: 4, strokes: 4).mark, .level)
    XCTAssertEqual(RoundScorecardHole(hole: 1, par: 4, strokes: 6).mark, .over)
    XCTAssertEqual(RoundScorecardHole(hole: 1, par: nil, strokes: 3).mark, .unknown,
                   "with no par there is nothing to be under — a strokes-only card carries no gold")
  }

  // MARK: - nothing to draw is nothing

  func testACardWithNeitherParNorStrokesIsEmpty() {
    let bare = RoundScorecard(holesPlayed: 18, holes: (1...18).map { RoundScorecardHole(hole: $0) })
    XCTAssertTrue(bare.isEmpty, "an eighteen-column grid of gaps is exactly what L-44 forbids")
  }

  func testAStrokesOnlyCardIsNotEmpty() {
    let card = RoundScorecard.fromHoleRows((1...18).map { (hole: $0, strokes: 5) },
                                           gross: 90, holesPlayed: 18)!
    XCTAssertFalse(card.isEmpty)
  }

  // MARK: - the line under the card

  func testTheDatelineNamesOnlyWhatThePayloadProved() {
    let pinned = RoundScorecard(json("""
      {"holes_played":18,"tee_name":"Black","par_source":"tee","par_total":70,
       "holes":[{"hole":1,"par":4,"strokes":5}]}
    """))
    XCTAssertEqual(pinned?.dateline, "Black · Par 70")

    let agreed = RoundScorecard(json("""
      {"holes_played":18,"par_source":"course","par_total":72,
       "holes":[{"hole":1,"par":4,"strokes":5}]}
    """))
    XCTAssertEqual(agreed?.dateline, "Par 72", "no tee was identified, so no tee is named")

    let bare = RoundScorecard.fromHoleRows((1...18).map { (hole: $0, strokes: 5) },
                                           gross: 90, holesPlayed: 18)!
    XCTAssertEqual(bare.dateline, RoundCopy.cardStrokesOnly,
                   "it says what the card IS rather than apologising for what it is not")
  }

  // MARK: - the call

  func testTheCallDropsNothing() {
    XCTAssertEqual(RoundScorecardCall.name, "round_scorecard")
    XCTAssertTrue(RoundScorecardCall.optionalArgs.isEmpty,
                  "a retry that dropped p_round would ask for no round at all")
  }
}
