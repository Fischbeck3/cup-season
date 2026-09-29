// W4 twin · the hole strip, said in one sentence — counted from the cells the
// strip draws (the web's `holeStripSummary`).

import Testing
@testable import CupSeasonKit

@Suite struct LiveHoleStripSummaryTests {
  @Test func theStripIsSaidAsOneSentence() {
    let cells: [LiveCell?] = [.a, .a, .b, .h, .a, .b, .a, .c, .a]
    let open = LiveLedger(mode: "sides", cells: cells, played: 9, closedOut: false, hot: .a, legend: "Blake & Casey", holes: 18)
    #expect(open.summary(hot: "a", hotName: "Blake & Casey", otherName: "Quinn")
            == "Blake & Casey won 5 holes, Quinn won 2, 1 halved, 1 carried, through 9.")
    #expect(open.drawsHalved && open.drawsCarried)
    let shut = LiveLedger(mode: "sides", cells: [.a, .a, .a, .b], played: 4, closedOut: true, hot: .a, legend: nil, holes: 9)
    #expect(shut.summary(hot: "a", hotName: nil, otherName: nil)
            == "The subject won 3 holes, the other side won 1, closed on 4.")
    #expect(!shut.drawsHalved && !shut.drawsCarried)
    let one = LiveLedger(mode: "sides", cells: [.b], played: 1, closedOut: false, hot: .a, legend: nil, holes: 18)
    #expect(one.summary(hot: "a", hotName: "You", otherName: "Blake") == "You won 0 holes, Blake won 1, through 1.")
  }
}
