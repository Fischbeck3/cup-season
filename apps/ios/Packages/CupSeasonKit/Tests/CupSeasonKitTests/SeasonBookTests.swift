import Foundation
import Testing
@testable import CupSeasonKit

struct SeasonBookTests {
  private func data(_ name: String) throws -> Data { try Data(contentsOf:Bundle.module.url(forResource:name,withExtension:"json")!) }
  private func book(_ name: String = "squads") throws -> SeasonBookSnapshot { try JSONDecoder().decode(SeasonBookSnapshot.self,from:data(name)) }
  private func changed(_ edit: (inout [String:Any]) -> Void) throws -> SeasonBookSnapshot {
    var json=try JSONSerialization.jsonObject(with:data("squads")) as! [String:Any];edit(&json)
    return try JSONDecoder().decode(SeasonBookSnapshot.self,from:JSONSerialization.data(withJSONObject:json))
  }
  @Test func realSQLPayloadsValidate() throws {
    for name in ["squads","tie","upcoming","finished"] {
      let b=try book(name);try b.validate(league:b.league_id,season:b.season_id)
    }
  }
  @Test func rejectsWrongSeasonVersionAndPartialRead() throws {
    let b=try book();#expect(throws:SeasonBookReadError.self) { try b.validate(league:b.league_id,season:UUID()) }
    for edit: (inout [String:Any])->Void in [{ $0["version"]=2 },{ $0["coverage_complete"]=false },{ json in var rows=json["rows"] as! [[String:Any]];rows[0]["points"]=9999;json["rows"]=rows },{ json in var rows=json["rows"] as! [[String:Any]];rows[0]["cells"]=[];json["rows"]=rows }] {
      let bad=try changed(edit);#expect(throws:SeasonBookReadError.self) { try bad.validate(league:bad.league_id,season:bad.season_id) }
    }
  }
  @Test func everyScopeReconcilesAndFloorsKeepTheirActualMeaning() throws {
    let b=try book();#expect(b.rows.count==36)
    for row in b.rows.filter({ $0.kind == "squad" }) {
      let rounds=b.rows.filter { $0.kind == "contribution" && $0.squad_id == row.squad_id }.reduce(0) { $0+$1.points }
      #expect(rounds+row.entries.filter { !$0.isRound }.reduce(0) { $0+$1.contribution } == row.points)
    }
    let floor=try #require(b.rows.filter { $0.kind == "golfer" }.flatMap(\.entries).first { $0.kind == "floor_penalty" })
    #expect(floor.points == -5 && floor.contribution == 0 && floor.week == 9)
  }
  @Test func sameWeekRoundsDropsAndFutureWeeksRemainDistinct() throws {
    let b=try book(), mine=try #require(b.rows.first { $0.kind == "golfer" && $0.mine })
    let es=SeasonBookSnapshot.selectedEntries(mine,week:12,cumulative:false)
    #expect(es.filter(\.isRound).count==2);#expect(es.contains { $0.count_state == "dropped" })
    #expect(SeasonBookSnapshot.label(row:mine,cell:mine.cells[11],cumulative:false).contains("D"))
    #expect(SeasonBookSnapshot.label(row:mine,cell:mine.cells[14],cumulative:false)=="•")
  }
  @Test func tiesAndThresholdAgreeWithTheBoard() throws {
    let b=try book("tie");#expect(b.rows.allSatisfy { $0.points==41 && $0.standing=="1st · Tied" })
    #expect(!SeasonBookSnapshot.prominent(fieldSize:2,hasSquads:false))
    #expect(SeasonBookSnapshot.prominent(fieldSize:10,hasSquads:false))
    #expect(SeasonBookSnapshot.prominent(fieldSize:2,hasSquads:true))
  }
  @Test func completedRulesAndOutsideAssessmentsAreHonest() throws {
    #expect(try book("finished").rules_note != nil)
    let b=try book(), row=try #require(b.rows.first { $0.unplaced_points == 2 })
    #expect(row.entries.contains { $0.week == nil && $0.contribution == 2 && $0.recorded_on == "2026-10-20" })
    #expect(try book("upcoming").current_week==0)
  }
  @Test func raceKeepsNegativeValuesAndEarlierPeaks() throws {
    let altered=try changed { json in
      var rows=json["rows"] as! [[String:Any]];var cells=rows[0]["cells"] as! [[String:Any]]
      cells[0]["cumulative"]=12;cells[1]["cumulative"] = -8;rows[0]["cells"]=Array(cells.prefix(2));json["rows"]=[rows[0]]
    }
    #expect(SeasonBookSnapshot.raceDomain(altered.rows) == -8...12)
  }
  @Test @MainActor func failedReadRetriesWithoutRetainingOldPoints() async throws {
    let b=try book();var attempts=0
    let store=SeasonBookStore(read:{ _,_ in attempts += 1; if attempts == 1 { throw SeasonBookReadError.unavailable }; return b })
    await store.load(league:b.league_id,season:b.season_id)
    #expect(store.snapshot == nil && store.error != nil && !store.loading)
    await store.load(league:b.league_id,season:b.season_id)
    #expect(store.snapshot?.season_id == b.season_id && store.error == nil && !store.loading)
  }
  @Test @MainActor func lateOldSeasonCannotReplaceTheNewSelection() async throws {
    let a=try book(), b=try book("tie")
    var pending: CheckedContinuation<SeasonBookSnapshot,any Error>?
    let store=SeasonBookStore(read:{ _,season in
      if season == a.season_id { return try await withCheckedThrowingContinuation { pending=$0 } }
      return b
    })
    let old=Task { await store.load(league:a.league_id,season:a.season_id) }
    while pending == nil { await Task.yield() }
    await store.load(league:b.league_id,season:b.season_id)
    pending?.resume(returning:a);await old.value
    #expect(store.snapshot?.season_id == b.season_id && store.error == nil)
  }

  @Test func youUsesTheSamePointsTieAndOnlyTheRecordedChampionWins() throws {
    let b=try book("tie"), first=b.rows[0].member_id!, second=b.rows[1].member_id!
    let season=Me.Season(id:b.season_id,number:1,starts_on:b.starts_on,ends_on:b.ends_on,status:"complete",timezone:nil,grace_hours:nil,champion_squad_id:nil,champion_member_id:second,points_king_member_id:nil,tiebreak_rung:nil)
    let rows=b.rows.map { IndividualStanding(season_id:b.season_id,member_id:$0.member_id!,points:Double($0.points),rounds_posted:12) }
    for id in [first,second] {
      let finish=LeagueRecord.finish(phase:"complete",season:season,standings:rows,myMemberId:id)
      #expect(finish?.finish == 1 && finish?.tied == true)
      #expect(finish?.won == (id == second))
      #expect(LeagueRecord.line(phase:"complete",season:season,standings:rows,myMemberId:id,today:"2026-09-24").contains("1ST · TIED"))
    }
  }

}
