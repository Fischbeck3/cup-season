import Testing
import SwiftUI
import CupSeasonKit
@testable import CupSeason

@MainActor @Suite struct OwnerQ15CovenantTests {
  @Test func theSheetNamesOnlyGroupsItCanSay() throws {
    for stake in [0, 5000] {
      for width: CGFloat in [375, 402] {
        let c = Covenant(name: "North Grove (fixture)", buyinCents: stake, preset: "standard",
                         floor: 2, finish: "cup_final", proName: "Blake Sample", rosterCount: 8,
                         startsOn: "2026-09-12", weeks: 13, countingCap: 3,
                         split: .init(champion: 60, runnerUp: 25, pointsKing: 15), structure: "squads2")
        let host = HostedLayout(CovenantSheet(covenant: c, postedRounds: 0, onJoin: {}, onNo: {}),
                                width: width, height: 4000, typeSize: .accessibility3)
        defer { host.tearDown() }
        let heads = host.elements(prefix: "covenant.group.").map(\.identifier)
        #expect(heads == (stake == 0 ? ["covenant.group.who", "covenant.group.scores"]
                                    : ["covenant.group.who", "covenant.group.scores", "covenant.group.money"]))
        #expect(host.horizontalScrollers.isEmpty)
      }
    }
  }
}
