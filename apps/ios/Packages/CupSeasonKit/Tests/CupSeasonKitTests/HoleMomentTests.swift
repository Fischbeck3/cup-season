// F13 · the good holes, recognised once and only when they are real.
// Every test here is a refusal the finding asked for.
import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct HoleMomentTests {

  @Test func oneUnderIsABirdieAndTwoUnderIsAnEagle() {
    #expect(HoleMoment.of(strokes: 3, par: 4, parIsKnown: true) == .birdie)
    #expect(HoleMoment.of(strokes: 3, par: 5, parIsKnown: true) == .eagle)
    #expect(HoleMoment.of(strokes: 1, par: 4, parIsKnown: true) == .eagle, "two or better is an eagle")
    #expect(HoleMoment.of(strokes: 4, par: 4, parIsKnown: true) == nil, "a par is not a moment")
    #expect(HoleMoment.of(strokes: 5, par: 4, parIsKnown: true) == nil)
    #expect(HoleMoment.birdie.word == "Birdie" && HoleMoment.eagle.word == "Eagle")
    #expect(HoleMoment.birdie.spoken(hole: 7) == "Birdie on 7")
  }

  /// **An estimated par cannot declare an eagle.** The card often carries pars
  /// guessed from nothing, and a confident claim off a guess is the failure
  /// this rule exists to prevent.
  @Test func anUnknownParClaimsNothing() {
    #expect(HoleMoment.of(strokes: 3, par: 5, parIsKnown: false) == nil)
    #expect(HoleMoment.of(strokes: 3, par: nil, parIsKnown: true) == nil)
    #expect(HoleMoment.of(strokes: nil, par: 4, parIsKnown: true) == nil)
    #expect(HoleMoment.of(strokes: 0, par: 4, parIsKnown: true) == nil, "an empty cell is not an eagle")
  }

  /// A commit speaks once. The same revision arriving again — a re-render, a
  /// remote echo — says nothing.
  @Test func theSameCommitNeverFiresTwice() {
    var l = HoleMomentLedger()
    #expect(l.commit(player: "me", hole: 7, revision: 1, strokes: 3, par: 4, parIsKnown: true) == .birdie)
    #expect(l.commit(player: "me", hole: 7, revision: 1, strokes: 3, par: 4, parIsKnown: true) == nil)
  }

  /// **Hydration and sync are not play.** Reopening the card or reconnecting
  /// replays every score; arming the ledger silently means none of them fires.
  @Test func hydrationAndSyncAreSilent() {
    var l = HoleMomentLedger()
    l.seen(player: "me", hole: 7, revision: 1, strokes: 3, par: 4, parIsKnown: true)
    #expect(l.commit(player: "me", hole: 7, revision: 1, strokes: 3, par: 4, parIsKnown: true) == nil)
    // and the tally still knows the birdie is on the card
    #expect(l.tallyLine(player: "me") == "1 birdie")
  }

  /// A correction clears the recognition, and putting the score back does not
  /// replay the reward through undo and re-entry.
  @Test func aCorrectionRevisesRatherThanReplaying() {
    var l = HoleMomentLedger()
    #expect(l.commit(player: "me", hole: 7, revision: 1, strokes: 3, par: 4, parIsKnown: true) == .birdie)
    #expect(l.commit(player: "me", hole: 7, revision: 2, strokes: 5, par: 4, parIsKnown: true) == nil, "a bogey is not a moment")
    #expect(l.tallyLine(player: "me") == nil, "the corrected birdie left the tally")
    // back to three: a NEW revision, so it may stand again — but the tally is
    // one birdie, never two
    #expect(l.commit(player: "me", hole: 7, revision: 3, strokes: 3, par: 4, parIsKnown: true) == .birdie)
    #expect(l.tallyLine(player: "me") == "1 birdie")
  }

  /// The quiet factual line — and it is a tally, not a claim about form.
  @Test func theTallyIsFactsAndNotAStreak() {
    var l = HoleMomentLedger()
    _ = l.commit(player: "me", hole: 2, revision: 1, strokes: 3, par: 5, parIsKnown: true)
    _ = l.commit(player: "me", hole: 7, revision: 1, strokes: 3, par: 4, parIsKnown: true)
    _ = l.commit(player: "me", hole: 9, revision: 1, strokes: 4, par: 4, parIsKnown: true)
    #expect(l.tallyLine(player: "me") == "1 eagle · 1 birdie")
    #expect(l.tally(player: "me").eagles == 1 && l.tally(player: "me").birdies == 1)
    // nothing in the producer says "heating up" — that needs its own ruling
    #expect(!(l.tallyLine(player: "me") ?? "").lowercased().contains("heat"))
  }

  /// One golfer's card is not another's: a playing partner's birdie is not
  /// mine, and the tally is per player.
  @Test func eachGolfersCardIsTheirOwn() {
    var l = HoleMomentLedger()
    _ = l.commit(player: "me", hole: 7, revision: 1, strokes: 3, par: 4, parIsKnown: true)
    _ = l.commit(player: "galen", hole: 7, revision: 1, strokes: 3, par: 4, parIsKnown: true)
    #expect(l.tallyLine(player: "me") == "1 birdie")
    #expect(l.tallyLine(player: "galen") == "1 birdie")
    #expect(l.tallyLine(player: "nobody") == nil)
  }

  @Test func pluralsAreRight() {
    var l = HoleMomentLedger()
    for h in [2, 5] { _ = l.commit(player: "me", hole: h, revision: 1, strokes: 3, par: 5, parIsKnown: true) }
    for h in [7, 9, 11] { _ = l.commit(player: "me", hole: h, revision: 1, strokes: 3, par: 4, parIsKnown: true) }
    #expect(l.tallyLine(player: "me") == "2 eagles · 3 birdies")
  }
}
