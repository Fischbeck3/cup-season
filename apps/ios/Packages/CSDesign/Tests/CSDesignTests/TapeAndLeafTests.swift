// Cup Season — the meeting tape and the record leaf (Wave 3,
// `surfaces/profile.md` §7 and §10, `UI_SYSTEM` §9.8 and §9.10).
//
// Both are printed diagrams, and both have exactly one arithmetic each that a
// screenshot would not catch: the tape's tick has to shrink so a long rivalry
// stays ONE row, and the leaf's earned mark has to tell a WIN from a podium
// from a top-of-a-field-of-three.

import Testing
import SwiftUI
@testable import CSDesign

@Suite struct TapeTests {

  /// The tick is 17 × 16 at the design's own count, and shrinks rather than
  /// wrapping. **Two rows would be two chronologies on one page.**
  @Test func theTickShrinksRatherThanWrapping() {
    let eleven = (0..<11).map { CSTape.Meeting(id: $0, viewer: $0 % 2 == 0) }
    let tape = CSTape(meetings: eleven, key: "One square is one win.")
    // 285pt of measure across eleven meetings — the profile's own case
    #expect(tape.slotWidth(285) > 17)          // room to spare, so the tick caps at 17
    #expect(tape.tick(285) == 17)
    // a rivalry four times as long still fits on one rule
    let long = (0..<44).map { CSTape.Meeting(id: $0, viewer: true) }
    let big = CSTape(meetings: long, key: "One square is one win.")
    #expect(big.tick(285) >= 6 && big.tick(285) < 17)
  }

  /// **A halved meeting belongs to neither row.** It is drawn as a flat bar on
  /// the rule rather than above or below it — the one channel the graphic uses
  /// is position, and putting a half on one side would be a lie in it.
  @Test func aHalvedMeetingIsNeitherAboveNorBelow() {
    let m = CSTape.Meeting(id: 0, viewer: nil)
    #expect(m.viewer == nil)
  }

  /// The tape is ONE VoiceOver element, in the product's voice. Eleven ticks
  /// read one at a time is a golfer counting squares out loud.
  @Test func theTapeSpeaksAsOneThing() {
    let tape = CSTape(meetings: [.init(id: 0, viewer: true)],
                      key: "One square is one win.",
                      spoken: "Eleven meetings. You won six, Galen won five.")
    #expect(tape.spokenLabel == "Eleven meetings. You won six, Galen won five.")
    // with no sentence given, the key line is what it says
    #expect(CSTape(meetings: [], key: "One square is one win.").spokenLabel == "One square is one win.")
  }
}

/// `@MainActor`, and the reason is worth keeping: `CSRecordLeaf` is a `View`,
/// so its nested `Row` inherits main-actor isolation — and a `contains` over
/// `[Row]` from a background test hits `_swift_task_checkIsolatedSwift` and
/// SIGTRAPs rather than failing an assertion. It looks exactly like a hung
/// runner in the log.
@MainActor
@Suite struct RecordLeafTests {

  private func row(finish: Int?, won: Bool, line: String? = nil) -> CSRecordLeaf.Row {
    CSRecordLeaf.Row(id: "s", year: "2026", competition: "The Fellas", qualifier: "Season one",
                     finish: finish, line: line, won: won)
  }

  /// §7 / D-5 · **a win takes the gold rule; a podium takes an ink rule.**
  /// §9.8 gave gold to both, and 2nd of 8 is not silverware.
  @Test func onlyAWinIsGold() {
    #expect(row(finish: 1, won: true).podium == false)     // a win is not a podium — it is a win
    #expect(row(finish: 2, won: false).podium)
    #expect(row(finish: 3, won: false).podium)
    #expect(row(finish: 4, won: false).podium == false)
    #expect(row(finish: nil, won: false).podium == false)  // no rank, no mark
  }

  /// §14.1's degrade: a season with no ranked table prints its `line` in the
  /// finish column and hangs no rule off it.
  @Test func anUnrankedSeasonPrintsItsLineAndNoMark() {
    let r = row(finish: nil, won: false, line: "FIRST TEE SAT AUG 30")
    #expect(r.finish == nil && r.line == "FIRST TEE SAT AUG 30" && !r.won && !r.podium)
  }

  /// The money column is DROPPED, not zeroed, when nothing produces it —
  /// `season_payouts` holds no rows in prod and four zeroes is not a table.
  @Test func theMoneyColumnDropsRatherThanZeroing() {
    #expect(CSRecordLeaf.showsMoney([row(finish: 2, won: false)]) == false)
    let paid = CSRecordLeaf.Row(id: "s", year: "2026", competition: "The Fellas",
                                qualifier: nil, finish: 2, line: nil, won: false, money: "$40")
    #expect(CSRecordLeaf.showsMoney([paid]))
  }
}
