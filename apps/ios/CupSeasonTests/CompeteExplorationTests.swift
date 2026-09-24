#if DEBUG
import XCTest
@testable import CupSeason
import CupSeasonKit

@MainActor final class CompeteExplorationTests: XCTestCase {
  func testTieUsesTheTableStandingAndEveryTotalHasReceipts() {
    let f = CompeteFixture.exploration("tie")
    XCTAssertEqual(f.standings.map(\.pts), [41, 41])
    XCTAssertEqual(f.ranks, [1, 1])
    XCTAssertEqual(f.standings.map { f.rank($0) }, ["1st · Tied", "1st · Tied"])
    for team in f.standings { XCTAssertEqual(f.total(f.teamEntries(team)), Int(team.pts)) }
  }
  func testAllSixPayloadsReconcileWithTheRealSeasonModel() {
    for kind in ["tie", "field", "squads", "upcoming", "finished", "multi"] {
      let f = CompeteFixture.exploration(kind)
      for team in f.standings {
        XCTAssertEqual(f.total(f.teamEntries(team)), Int(team.pts), "\(kind): \(team.name)")
        XCTAssertEqual((1...15).map { week in f.total(f.teamEntries(team).filter { $0.week == week }) }.reduce(0, +), Int(team.pts))
      }
      XCTAssertEqual(Set(f.entries.map(\.id)).count, f.entries.count)
      XCTAssertTrue(f.entries.allSatisfy { !$0.reason.isEmpty && (1...15).contains($0.week) })
    }
  }
  func testFourSquadsEachHaveFourGolfersAndNoLostContributions() {
    let f = CompeteFixture.exploration("squads")
    XCTAssertEqual(f.model.squads.map { $0.squad_members.count }, [4, 4, 4, 4])
    XCTAssertEqual(f.total(f.entries), f.standings.reduce(0) { $0 + Int($1.pts) })
    XCTAssertEqual(f.names.count, 16)
    XCTAssertEqual(f.story, "Mudsharks leads.")
  }
  func testDroppedRoundsAreRetainedAndAdjustmentKindsAreReceipted() {
    let f = CompeteFixture.exploration("finished")
    XCTAssertEqual(f.entries.filter { !$0.counted }.count, 17)
    XCTAssertTrue(f.entries.filter { !$0.counted }.allSatisfy { $0.contribution == 0 && $0.points == 5 })
    XCTAssertEqual(Set(f.entries.filter { !$0.round }.map(\.kind)), ["bye", "floor_penalty", "matchup_bonus"])
    XCTAssertEqual(f.standings.first?.name, "Galen Marr")
  }
  func testFixtureCountFlagsRespectSettingsAndTheFieldIsNotAllTied() {
    for kind in ["field", "squads", "finished"] {
      let f = CompeteFixture.exploration(kind)
      for member in f.names.indices {
        let months = Dictionary(grouping: f.memberEntries(member).filter { $0.round && $0.counted },
                                by: { String(f.weekDate($0.week).prefix(7)) })
        XCTAssertTrue(months.values.allSatisfy { $0.count <= (f.model.settings?.counting_cap ?? 31) })
      }
      XCTAssertGreaterThan(Set(f.standings.map(\.pts)).count, 1)
    }
  }
  func testMissingFutureByeDroppedAndMixedCellsAreDistinct() {
    let f = CompeteFixture.exploration("field")
    let mine = f.memberEntries(1)
    XCTAssertEqual(SeasonBookCell.label(mine, week: 8, currentWeek: 12), "—")
    XCTAssertEqual(SeasonBookCell.label(mine, week: 15, currentWeek: 12), "•")
    XCTAssertEqual(SeasonBookCell.label(mine, week: 4, currentWeek: 12), "D")
    XCTAssertEqual(SeasonBookCell.label(mine, week: 12, currentWeek: 12), "12D")
    XCTAssertEqual(SeasonBookCell.label(f.memberEntries(15), week: 9, currentWeek: 12), "B")
    XCTAssertEqual(SeasonBookCell.label(f.memberEntries(14), week: 9, currentWeek: 12), "-5*")
    XCTAssertEqual(SeasonBookCell.label(mine, week: 1, currentWeek: 12, cumulative: true), "7")
  }
  func testUpcomingHasNoRankOrPretendRoundsAndMultiHasThreeSeasons() {
    let f = CompeteFixture.exploration("upcoming")
    XCTAssertTrue(f.entries.isEmpty)
    XCTAssertFalse(f.live)
    XCTAssertTrue(f.standings.allSatisfy { f.rank($0) == "Not started" })
    XCTAssertEqual(CompeteFixture.explorationSeasons("multi").count, 3)
  }
}
#endif
