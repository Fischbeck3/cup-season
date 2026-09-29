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
    for name in ["squads","tie","upcoming","finished","audit-live","audit-withdrawn"] {
      let b=try book(name);try b.validate(league:b.league_id,season:b.season_id)
    }
  }
  @Test func integratedFrozenBookKeepsWithdrawnContributionsAndLiveBookSeatEligibility() throws {
    let live=try book("audit-live"), frozen=try book("audit-withdrawn")
    let withdrawn=try #require(frozen.rows.flatMap(\.entries).first { $0.withdrawn == true })
    #expect(withdrawn.contribution > 0 && withdrawn.reason.contains("Withdrawn by the golfer"))
    #expect(frozen.rules_note?.contains("closed with") == true)
    for b in [live,frozen] { try b.validate(league:b.league_id,season:b.season_id) }
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
  /// F11 · a cell is its figure and its status marks, drawn apart. "33D" read
  /// as a number; `parts` keeps the figure a figure and the marks a note, and
  /// `label` stays their concatenation for every caller that wants the string.
  @Test func aCellIsAFigureWithItsMarksBesideIt() throws {
    let b=try book(), mine=try #require(b.rows.first { $0.kind == "golfer" && $0.mine })
    let dropped=SeasonBookSnapshot.parts(row:mine,cell:mine.cells[11],cumulative:false)
    #expect(Int(dropped.fig) != nil && dropped.marks.contains("D"))
    #expect(SeasonBookSnapshot.label(row:mine,cell:mine.cells[11],cumulative:false) == dropped.fig + dropped.marks)
    #expect(SeasonBookSnapshot.parts(row:mine,cell:mine.cells[14],cumulative:false) == .init(fig:"•",marks:""))
    // Totals carry no marks: a running total is not a week's status
    #expect(SeasonBookSnapshot.parts(row:mine,cell:mine.cells[11],cumulative:true).marks.isEmpty)
    var sawStar=false, sawD=false
    for name in ["squads","tie","upcoming","finished","audit-live","audit-withdrawn"] {
      let book=try book(name)
      for row in book.rows { for cell in row.cells { for cumulative in [false,true] {
        let p=SeasonBookSnapshot.parts(row:row,cell:cell,cumulative:cumulative)
        let spoken=SeasonBookSnapshot.spoken(row:row,cell:cell,cumulative:cumulative)
        #expect(SeasonBookSnapshot.label(row:row,cell:cell,cumulative:cumulative) == p.fig + p.marks)
        #expect(p.marks.allSatisfy { $0 == "*" || $0 == "D" })
        if cumulative { #expect(p.marks.isEmpty) }
        // the marks are a NOTE, never another digit of the figure
        if !p.marks.isEmpty { #expect(Int(p.fig) != nil) }
        // …and the cell says each one in words (its accessible name)
        if p.marks.contains("D") { sawD=true; #expect(spoken.contains("dropped rounds retained in receipt")) }
        if p.marks.contains("*") { sawStar=true; #expect(spoken.contains("adjustment or bye recorded")) }
        // §16 · the figure IS the cell, and the cell's receipts add up to it
        if let figure=Int(p.fig) {
          let points=cumulative ? cell.cumulative : cell.points
          #expect(figure == points)
          let receipts=SeasonBookSnapshot.selectedEntries(row,week:cell.week,cumulative:cumulative)
          #expect(receipts.reduce(0) { $0+$1.contribution } == figure)
        }
      } } }
    }
    #expect(sawStar && sawD)
  }
  /// The Book's head reads its dates as dates — "Jul 6 – Oct 18, 2026", the
  /// week columns' own form — never the raw 2026-07-06 – 2026-10-18.
  @Test func theHeadReadsItsDatesAsDates() throws {
    #expect(try book().span == "Jul 6 – Oct 18, 2026")
    let odd = try changed { $0["starts_on"] = "not a date" }
    #expect(odd.span == "not a date – Oct 18, 2026")
  }
  @Test func aCellThatIsOnlyAStatusStandsAlone() throws {
    let b=try book()
    let cells=b.rows.flatMap { row in row.cells.map { (row,$0) } }
    let allDropped=try #require(cells.first { row,cell in
      let es=SeasonBookSnapshot.selectedEntries(row,week:cell.week,cumulative:false)
      return !cell.future && cell.points != nil && !es.isEmpty && es.allSatisfy { $0.count_state == "dropped" }
    })
    #expect(SeasonBookSnapshot.parts(row:allDropped.0,cell:allDropped.1,cumulative:false) == .init(fig:"D",marks:""))
    // a past week with nothing in it (the live audit Book carries some)
    let live=try book("audit-live")
    let empty=live.rows.flatMap { row in row.cells.map { (row,$0) } }
    let none=try #require(empty.first { !$0.1.future && $0.1.points == nil })
    #expect(SeasonBookSnapshot.parts(row:none.0,cell:none.1,cumulative:false) == .init(fig:"—",marks:""))
    #expect(SeasonBookSnapshot.spoken(row:none.0,cell:none.1,cumulative:false) == "No round or adjustment recorded")
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
