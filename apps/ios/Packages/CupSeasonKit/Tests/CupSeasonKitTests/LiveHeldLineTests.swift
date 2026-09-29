import Testing
@testable import CupSeasonKit

/// TEN / W6 (critique A2, P1) · "Change setup" mid-round holds the round, and
/// the setup says so first. The words are the web's `csLiveHeldLine` in its
/// three forms, as root pinned them; the count is a hole any golfer has a
/// number on.
@Suite struct LiveHeldLineTests {
  @Test func theThreeFormsAreTheWebs() {
    #expect(LiveCopy.heldLine(scored: 1)
            == "Your round is still on, and its 1 hole scored stays with it. Change the course, the tee or the holes here.")
    #expect(LiveCopy.heldLine(scored: 3)
            == "Your round is still on, and its 3 holes scored stay with it. Change the course, the tee or the holes here.")
    #expect(LiveCopy.heldLine(scored: 0)
            == "Your round is still on. Change the course, the tee or the holes here.")
    #expect(LiveCopy.backToRound == "Back to the round")
  }

  @Test func aHoleCountsWhenAnyGolferHasANumberOnIt() {
    var s = LiveRoundState.fresh(players: [LivePlayer(n: "Avery Fixture", i: 10.6, ci: 1, guest: false),
                                           LivePlayer(n: "Blake Fixture", i: 12.0, ci: 1, guest: false)])
    #expect(s.holesScored == 0)
    s.scores[0][0] = 4; s.scores[1][0] = 5   // both on the 1st: one hole
    s.scores[1][1] = 3                        // one golfer on the 2nd: still a hole scored
    s.scores[0][4] = 6                        // the 5th
    #expect(s.holesScored == 3)
  }
}
