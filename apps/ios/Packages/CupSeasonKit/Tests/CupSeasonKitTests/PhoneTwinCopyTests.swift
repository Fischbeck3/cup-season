import Testing
@testable import CupSeasonKit

@Suite struct PhoneTwinCopyTests {
  @Test func scoreButtonsNameTheSameParEntryAndThenTheirOwnDirection() {
    var s = LiveRoundState.fresh(players: [.init(n: "Avery Fixture", i: 12, ci: 0, guest: false)])
    s.hole = 0
    for by in [-1, 1] { #expect(LiveCopy.stepperLabel(s, player: 0, by: by) == "Enter par (4) for Avery Fixture, hole 1") }
    s.scores[0][0] = 5
    #expect(LiveCopy.stepperLabel(s, player: 0, by: -1) == "One stroke fewer for Avery Fixture, hole 1, now 5")
    #expect(LiveCopy.stepperLabel(s, player: 0, by: 1) == "One more stroke for Avery Fixture, hole 1, now 5")
  }

  @Test func ceremonyExitNamesTheClose() { #expect(PostCeremony.backLabel == "Close") }

}
