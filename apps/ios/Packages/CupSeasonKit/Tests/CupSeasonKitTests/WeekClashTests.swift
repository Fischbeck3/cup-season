// Cup Season — the weekly clash (D108): the row decode and the pick logic,
// pinned to migration 20260829091000's shapes.

import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct WeekClashTests {
  @Test func decodesASettledWalkoverRow() throws {
    let json = """
    [{"id":"11111111-1111-1111-1111-111111111111","week_no":3,
      "a_member":"22222222-2222-2222-2222-222222222222",
      "b_member":"33333333-3333-3333-3333-333333333333",
      "opened_at":"2026-08-23T00:10:00+00:00","settled_at":"2026-08-30T00:10:12+00:00",
      "winner_member":"22222222-2222-2222-2222-222222222222",
      "a_best":{"round_id":"44444444-4444-4444-4444-444444444444","played_on":"2026-08-27","points":12,"pvi":3.1,"band":"Torched it"},
      "b_best":null}]
    """
    let wc = try #require(JSONDecoder().decode([LeagueRoom.WeekClash].self, from: Data(json.utf8)).first)
    #expect(wc.week_no == 3)
    #expect(wc.settled)
    #expect(wc.winner_member == wc.a_member)      // one side idle = a walkover W
    #expect(wc.a_best?.round_id != nil && wc.a_best?.band == "Torched it" && wc.a_best?.points == 12)
    #expect(wc.b_best == nil)
  }

  @Test func latestPicksTheHighestWeekAndAnOpenRowDecodes() throws {
    func mk(_ wk: Int) -> String {
      "{\"id\":\"\(UUID().uuidString)\",\"week_no\":\(wk),\"a_member\":\"22222222-2222-2222-2222-222222222222\",\"b_member\":\"33333333-3333-3333-3333-333333333333\",\"opened_at\":null,\"settled_at\":null,\"winner_member\":null,\"a_best\":null,\"b_best\":null}"
    }
    let rows = try JSONDecoder().decode([LeagueRoom.WeekClash].self, from: Data("[\(mk(2)),\(mk(5)),\(mk(4))]".utf8))
    let latest = try #require(LeagueRoom.WeekClash.latest(rows))
    #expect(latest.week_no == 5)
    #expect(!latest.settled && latest.a_best == nil)
    #expect(LeagueRoom.WeekClash.latest([]) == nil)
  }

  @Test func bestSoFarMakesTheSettlePick() {
    let m = UUID()
    func r(_ day: String, _ pts: Double, _ pvi: Double, _ rank: Int) -> LeagueRoom.RankedRound {
      LeagueRoom.RankedRound(member_id: m, round_id: UUID(), pvi: pvi, points: pts, month_rank: rank,
                             floor_credit: 1, played_on: day, index_at_post: 12, holes_played: 18)
    }
    let win = ClashMath.window(startsOn: "2026-08-06", week: 2)
    #expect(win == ("2026-08-13", "2026-08-19"))
    let rounds = [
      r("2026-08-12", 12, 4.0, 1),   // outside the window — never picked
      r("2026-08-14", 9, 1.4, 1),
      r("2026-08-16", 12, 3.2, 5),   // bumped past the cap — not counting
      r("2026-08-18", 9, 2.8, 2),    // same band, higher pvi — the pick
    ]
    let best = ClashMath.bestSoFar(rounds, member: m, window: win, capN: 4)
    #expect(best?.played_on == "2026-08-18" && best?.band == "Beat your number")
    #expect(ClashMath.bestSoFar(rounds, member: UUID(), window: win, capN: 4) == nil)
  }
}
