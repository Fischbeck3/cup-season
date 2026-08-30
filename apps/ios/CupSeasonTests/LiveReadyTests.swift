// D153b · the play view promotes "Finish round & post to season" when every
// seated card has every hole IN PLAY — `roundComplete`, which is strictly
// stronger than the sheet's "can this card post". Promoting on postability
// turned the button brand at the TURN of an eighteen and quiet again on hole
// 10, because `cardHoles` scores a clean front nine as 9 whatever the round was
// set up as. The invariant these pin is one-directional: complete ⇒ the sheet
// raises no warning. The reverse is deliberately NOT true.

import Testing
import Foundation
@testable import CupSeasonKit

struct LiveReadyTests {

  private func state(holes: Int, scores: [[Int?]]) -> LiveRoundState {
    let players = scores.indices.map {
      LivePlayer(id: "p\($0)", n: "P\($0)", i: 10, ci: $0, guest: false)
    }
    var s = LiveRoundState.fresh(players: players)
    s.holes = holes
    s.scores = scores
    s.pmap = players.map { _ in UUID() }
    return s
  }

  private func card(_ n: Int, of total: Int = 18) -> [Int?] {
    (0..<18).map { $0 < n && $0 < total ? 4 : nil }
  }

  @Test func midRoundIsNotComplete() {
    // fourteen holes in — the seeded review round
    let s = state(holes: 18, scores: [card(14), card(14)])
    #expect(LiveCopy.roundComplete(s) == false)
    #expect(LiveCopy.finishSheet(s).warning != nil)
  }

  @Test func everyCardCompleteIsComplete() {
    let s = state(holes: 18, scores: [card(18), card(18)])
    #expect(LiveCopy.roundComplete(s) == true)
    #expect(LiveCopy.finishSheet(s).warning == nil)
  }

  @Test func oneOpenCardHoldsTheWholeRoundBack() {
    // the promote must be unanimous: one unfinished card and the sheet warns,
    // so the button must not have claimed the round was done
    let s = state(holes: 18, scores: [card(18), card(17)])
    #expect(LiveCopy.roundComplete(s) == false)
    #expect(LiveCopy.finishSheet(s).warning != nil)
  }

  @Test func aNineHoleRoundCompletesAtNine() {
    // D73 · on a nine, holes 10–18 are legitimately empty and never "missing"
    let s = state(holes: 9, scores: [card(9), card(9)])
    #expect(LiveCopy.roundComplete(s) == true)
    #expect(LiveCopy.finishSheet(s).warning == nil)
  }

  @Test func theTurnOfAnEighteenDoesNotPromote() {
    // D153b, the bug this rule exists for: a clean front nine is POSTABLE, so
    // the sheet is happy — but the round is not over, and the button must not
    // say it is, only to go quiet again the moment someone scores hole 10.
    let turn = state(holes: 18, scores: [card(9), card(9)])
    #expect(LiveCopy.everyCardPostable(turn) == true)
    #expect(LiveCopy.finishSheet(turn).warning == nil)
    #expect(LiveCopy.roundComplete(turn) == false)

    var tenth = turn
    tenth.scores[0][9] = 4
    #expect(LiveCopy.roundComplete(tenth) == false)   // and it stays down
  }

  @Test func completeAlwaysImpliesTheSheetIsSilent() {
    // the one-directional invariant, swept: never promote a button the sheet
    // would then warn about
    for holes in [9, 18] {
      for a in 0...18 {
        for b in [0, 9, 17, 18] {
          let s = state(holes: holes, scores: [card(a), card(b)])
          if LiveCopy.roundComplete(s) {
            #expect(LiveCopy.finishSheet(s).warning == nil,
                    "promoted at holes=\(holes) a=\(a) b=\(b) but the sheet warns")
          }
        }
      }
    }
  }

  @Test func noSeatsIsNotComplete() {
    // an unmapped round has nothing to post; completeness must not vacuously pass
    var s = state(holes: 18, scores: [card(18)])
    s.pmap = nil
    #expect(LiveCopy.roundComplete(s) == false)
  }

  @Test func theStatusLineSaysWhatIsTrue() {
    #expect(LiveCopy.finishStatus(state(holes: 18, scores: [card(0), card(0)])) == nil)
    #expect(LiveCopy.finishStatus(state(holes: 18, scores: [card(14), card(14)]))
            == "THRU 14 · 4 TO PLAY")
    #expect(LiveCopy.finishStatus(state(holes: 18, scores: [card(18), card(18)]))
            == "ALL 18 IN · 2 CARDS READY")
    #expect(LiveCopy.finishStatus(state(holes: 9, scores: [card(9), card(9)]))
            == "ALL 9 IN · 2 CARDS READY")
    // the turn of an eighteen: postable, not over, and the line says both
    #expect(LiveCopy.finishStatus(state(holes: 18, scores: [card(9), card(9)]))
            == "THRU 9 · 2 CARDS READY IF YOU STOP HERE")
    // one player is simply a hole ahead — the ordinary state of every group.
    // This must NOT read "1 card is short"; somebody always enters first.
    var ahead = state(holes: 18, scores: [card(9), card(9)])
    ahead.scores[0][9] = 4
    #expect(LiveCopy.finishStatus(ahead) == "THRU 9 · 9 TO PLAY")
    // seventeen apiece, one still to card the last — a count, not an accusation
    #expect(LiveCopy.finishStatus(state(holes: 18, scores: [card(18), card(17)]))
            == "THRU 17 · 1 TO PLAY")
    // a genuinely SKIPPED hole — a gap before that card's own last score
    var skipped = state(holes: 18, scores: [card(18), card(18)])
    skipped.scores[1][4] = nil
    #expect(LiveCopy.finishStatus(skipped) == "P1’S CARD IS SHORT")
    // every hole in play filled and it still will not post: "0 to play" would
    // be true and useless
    var stray = state(holes: 9, scores: [card(9), card(9)])
    stray.scores[1][12] = 5
    #expect(LiveCopy.finishStatus(stray) == "A CARD HAS SCORES PAST HOLE 9")
  }

  @Test func aNineCarryingStrayBackNineScoresIsNamedForWhatItIs() {
    // reachable: start an eighteen, score past the turn, Change setup → 9.
    // `setHoles` does not clear holes 10–18 and `backToSetup` keeps the scores.
    var s = state(holes: 9, scores: [card(9), card(9)])
    s.scores[1][12] = 5
    #expect(LiveCopy.everyCardPostable(s) == false)   // the server would refuse it
    #expect(LiveCopy.roundComplete(s) == false)       // …so the button must not promote
    let w = LiveCopy.finishSheet(s).warning
    #expect(w?.contains("has scores past hole 9") == true)
    #expect(w?.contains("missing hole") == false)     // never the empty-list nonsense
  }

  @Test func teachingCopyGateFlipsOnTheFirstScore() {
    #expect(state(holes: 18, scores: [card(0), card(0)]).anyScored == false)
    #expect(state(holes: 18, scores: [card(1), card(0)]).anyScored == true)
  }
}
