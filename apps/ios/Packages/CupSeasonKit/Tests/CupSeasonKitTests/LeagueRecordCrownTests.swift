import Testing
import Foundation
@testable import CupSeasonKit

/// Launch audit S3 · the record reads the crown (L-03), shares a tie (L-15) and
/// keeps every season (L-21). The rows come from `my_league_record()`.
@Suite struct LeagueRecordCrownTests {
  let league = UUID(), s1 = UUID(), s2 = UUID()

  func row(season: UUID, number: Int, status: String, place: Int?, of: Int?, won: Bool = false,
           tied: Bool = false, points: Double? = nil, structure: String = "solo", phase: String = "season",
           startsOn: String = "2026-06-07") -> JSONValue {
    var o: [String: JSONValue] = [
      "league_id": .string(league.uuidString), "league_name": .string("C·Cup Done"),
      "season_id": .string(season.uuidString), "number": .number(Double(number)),
      "status": .string(status), "phase": .string(phase), "structure": .string(structure),
      "starts_on": .string(startsOn), "tied": .bool(tied), "won": .bool(won)]
    if let place { o["place"] = .number(Double(place)) }
    if let of { o["of"] = .number(Double(of)) }
    if let points { o["points"] = .number(points) }
    return .object(o)
  }

  @Test func theFinalsLoserIsSecondEvenWhenTheTableSaysFirst() {
    // Lee led the table on 91 and lost the Final: the server says place 2, not won
    let rows = LeagueRecord.rows(from: .array([row(season: s1, number: 1, status: "complete", place: 2, of: 6, points: 91)]),
                                 today: "2026-09-24")
    #expect(rows.count == 1)
    #expect(rows[0].finish == 2 && rows[0].won == false)
    #expect(rows[0].line == "FINISHED 2ND OF 6 · 91 PTS")
  }

  @Test func theChampionWonWhateverTheTableSays() {
    let rows = LeagueRecord.rows(from: .array([row(season: s1, number: 1, status: "complete", place: 1, of: 6, won: true, points: 83)]),
                                 today: "2026-09-24")
    #expect(rows[0].finish == 1 && rows[0].won)
    #expect(rows[0].line == "FINISHED 1ST OF 6 · 83 PTS")
  }

  @Test func aLiveTieIsSaidAsATie() {
    let rows = LeagueRecord.rows(from: .array([row(season: s1, number: 1, status: "active", place: 1, of: 2, tied: true, points: 48,
                                                   startsOn: "2026-07-01")]), today: "2026-09-24")
    #expect(rows[0].finish == 1 && !rows[0].won)
    #expect(rows[0].line == "TIED 1ST OF 2 · 48 PTS")
  }

  @Test func runItBackKeepsSeasonOneAndOpensTheLeague() {
    // newest first from the server; oldest first out, so the leaf's reversed() reads newest first
    let rows = LeagueRecord.rows(from: .array([
      row(season: s2, number: 2, status: "active", place: nil, of: 6, phase: "season", startsOn: "2026-10-01"),
      row(season: s1, number: 1, status: "complete", place: 1, of: 6, won: true, points: 83)]), today: "2026-09-24")
    #expect(rows.map(\.id) == [s1, s2])
    #expect(rows.allSatisfy { $0.leagueId == league })
    #expect(rows[1].line.hasPrefix("FIRST TEE"))
  }

  @Test func aFinishedSeasonNeverReadsAsDrawingEvenWhileTheLeagueDraws() {
    // season two is being drawn; season one is finished and must say so
    let rows = LeagueRecord.rows(from: .array([row(season: s1, number: 1, status: "complete", place: 1, of: 2, won: true,
                                                   structure: "squads2", phase: "draft")]), today: "2026-09-24")
    #expect(rows[0].line == "FINISHED 1ST OF 2 SQUADS")
    #expect(rows[0].finish == 1 && rows[0].won)
  }
  @Test func anUnstartedSeasonHasNoPlacementEvenWhenThePayloadRanksZeroPoints() {
    let rows = LeagueRecord.rows(from: .array([row(season: s2, number: 2, status: "active", place: 1, of: 6,
                                                   startsOn: "2026-10-01")]), today: "2026-09-24")
    #expect(rows[0].finish == nil && rows[0].of == nil)
    #expect(rows[0].line.hasPrefix("FIRST TEE"))
  }

}
