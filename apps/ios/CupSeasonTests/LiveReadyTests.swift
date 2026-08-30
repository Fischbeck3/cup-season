// D153 · the play view promotes "Finish round & post to season" exactly when
// the finish sheet would raise no warning. Two notions of "the round is done"
// is how a screen ends up promoting a button the sheet then refuses, so both
// read `LiveCopy.cardHoles` through `roundReadyToPost`. These tests pin the
// three cases that rule actually turns on.

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

  @Test func midRoundIsNotReady() {
    // fourteen holes in — the seeded review round, and the case the owner saw
    let s = state(holes: 18, scores: [card(14), card(14)])
    #expect(LiveCopy.roundReadyToPost(s) == false)
    #expect(LiveCopy.finishSheet(s).warning != nil)
  }

  @Test func everyCardCompleteIsReady() {
    let s = state(holes: 18, scores: [card(18), card(18)])
    #expect(LiveCopy.roundReadyToPost(s) == true)
    #expect(LiveCopy.finishSheet(s).warning == nil)
  }

  @Test func oneOpenCardHoldsTheWholeRoundBack() {
    // the promote must be unanimous: one unfinished card and the sheet warns,
    // so the button must not have claimed the round was done
    let s = state(holes: 18, scores: [card(18), card(17)])
    #expect(LiveCopy.roundReadyToPost(s) == false)
    #expect(LiveCopy.finishSheet(s).warning != nil)
  }

  @Test func cleanFrontNineOnANineHoleRoundIsReady() {
    // D73 · on a nine, holes 10–18 are legitimately empty and never "missing"
    let s = state(holes: 9, scores: [card(9), card(9)])
    #expect(LiveCopy.roundReadyToPost(s) == true)
    #expect(LiveCopy.finishSheet(s).warning == nil)
  }

  @Test func noSeatsIsNotReady() {
    // an unmapped round has nothing to post; readiness must not vacuously pass
    var s = state(holes: 18, scores: [card(18)])
    s.pmap = nil
    #expect(LiveCopy.roundReadyToPost(s) == false)
  }

  @Test func teachingCopyGateFlipsOnTheFirstScore() {
    #expect(state(holes: 18, scores: [card(0), card(0)]).anyScored == false)
    #expect(state(holes: 18, scores: [card(1), card(0)]).anyScored == true)
  }
}
