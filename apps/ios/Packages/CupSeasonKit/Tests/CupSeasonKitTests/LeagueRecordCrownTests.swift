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
    // W2 · the tie is said in the LINE; a live season has no finish to set
    // it on (it read `finish == 1` until the record stopped ranking live play)
    #expect(rows[0].finish == nil && !rows[0].won)
    #expect(rows[0].line == "TIED 1ST OF 2 · 48 PTS")
  }

  /// W2 · a season still being played has no finish and no podium mark — a
  /// place today is not a result. It reads "In play", and its line says where
  /// it stands (the web's `loadLeagueRecord` / `csRecordLeaf`).
  @Test func aLiveSeasonIsInPlayNotFinished() {
    // newest first from the server, oldest first out (as run-it-back reads it)
    let rows = LeagueRecord.rows(from: .array([
      row(season: s2, number: 2, status: "active", place: 2, of: 6, points: 41, startsOn: "2026-07-01"),
      row(season: s1, number: 1, status: "complete", place: 2, of: 6, points: 91)]),
                                 today: "2026-09-24")
    let live = rows[1]
    #expect(live.live && live.finish == nil && live.of == nil && !live.won)
    #expect(live.finishWord == "In play")
    #expect(live.line == "2ND OF 6 · 41 PTS")
    #expect(live.spoken == "Season 2, in play, 2nd of 6 · 41 pts")
    // the finished season beside it keeps its finish, and says no "In play"
    #expect(!rows[0].live && rows[0].finish == 2 && rows[0].finishWord == nil)
    // the Cup Final is still play; a live row with no place says only that
    let cup = LeagueRecord.rows(from: .array([row(season: s2, number: 2, status: "cup_final", place: 1, of: 2, points: 60,
                                                  startsOn: "2026-07-01")]), today: "2026-09-24")[0]
    #expect(cup.live && cup.finish == nil && cup.line == "CUP FINAL · 1ST OF 2 · 60 PTS")
    let unplaced = LeagueRecord.rows(from: .array([row(season: s2, number: 2, status: "active", place: nil, of: nil,
                                                       startsOn: "2026-07-01")]), today: "2026-09-24")[0]
    #expect(unplaced.live && unplaced.line.isEmpty && unplaced.spoken == "Season 2, in play")
    // not yet teed off is not in play
    let early = LeagueRecord.rows(from: .array([row(season: s2, number: 2, status: "active", place: 1, of: 6,
                                                    startsOn: "2026-10-01")]), today: "2026-09-24")[0]
    #expect(!early.live && early.finishWord == nil)
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

/// W2 twin · one rule for a season under way, on both record paths.
@Suite struct LeagueRecordLiveRuleTests {
  @Test func aSeasonUnderWayIsPastItsFirstTeeAndNotFinished() {
    #expect(LeagueRecord.isLive(status: "active", phase: "season", startsOn: "2026-07-05", today: "2026-09-29"))
    #expect(!LeagueRecord.isLive(status: "active", phase: "season", startsOn: "2026-10-05", today: "2026-09-29"))
    #expect(!LeagueRecord.isLive(status: "complete", phase: "complete", startsOn: "2026-05-03", today: "2026-09-29"))
    #expect(!LeagueRecord.isLive(status: nil, phase: "setup", startsOn: "2026-07-05", today: "2026-09-29"))
    #expect(LeagueRecord.isLive(status: "cup_final", phase: "season", startsOn: "2026-07-05", today: "2026-09-29"))
  }
}
