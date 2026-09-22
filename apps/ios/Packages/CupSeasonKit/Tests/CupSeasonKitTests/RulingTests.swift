import Testing
import Foundation
@testable import CupSeasonKit

/// D376 · the Pro's pen says the same words on both clients.
@Suite struct RulingTests {
  @Test func theDoneSentenceIsTheDesks() {
    #expect(RulingCopy.done("Danny", delta: 3, total: 41) == "Ruled — Danny +3 points. Now 41. It’s on the board.")
    #expect(RulingCopy.done("Danny", delta: -1, total: nil) == "Ruled — Danny −1 point. It’s on the board.")
    #expect(RulingCopy.done("Danny", delta: -12, total: 0) == "Ruled — Danny −12 points. Now 0. It’s on the board.")
  }

  @Test func theBoundsAreCheckedBeforeTheServerIsAsked() {
    #expect(RulingCopy.refusal(delta: nil, reason: "Wrong card") == RulingCopy.deltaRefused)
    #expect(RulingCopy.refusal(delta: 0, reason: "Wrong card") == RulingCopy.deltaRefused)
    #expect(RulingCopy.refusal(delta: 51, reason: "Wrong card") == RulingCopy.deltaRefused)
    #expect(RulingCopy.refusal(delta: -50, reason: "  ok ") == RulingCopy.reasonRefused)
    #expect(RulingCopy.refusal(delta: -50, reason: String(repeating: "x", count: 241)) == RulingCopy.reasonRefused)
    #expect(RulingCopy.refusal(delta: 3, reason: "Wrong card on the 7th") == nil)
  }

  @Test func theWordsArePinnedAgainstTheDesk() {
    #expect(RulingCopy.what == "A ruling moves points in the ledger with a reason. It posts to the board and every golfer can open it. Rounds are never changed. Once the Final window opens the ledger is closed — the crew settles it.")
    #expect(RulingCopy.notYet == "Rulings need the latest update — try again shortly.")
    #expect(RulingCopy.ledgerLine(month: "2026-09-01", reason: "Wrong card on the 7th") == "Sep · The Pro ruled · Wrong card on the 7th")
    #expect(RulingCopy.ledgerLine(month: nil, reason: nil) == "The Pro ruled · a ruling")
  }
}
