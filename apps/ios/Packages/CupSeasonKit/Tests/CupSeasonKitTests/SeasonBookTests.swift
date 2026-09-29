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
  /// W5 · a negative figure is drawn with a true minus (U+2212), which `Int()`
  /// does not read: the checks read the figure back as the number it states.
  private func figure(_ fig: String) -> Int? { Int(fig.replacingOccurrences(of:"\u{2212}",with:"-")) }
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
  /// W7-120 · the finished fixture is the booked finish, as season_book
  /// answers it (20261205090000: still envelope version 1, with the additive
  /// `frozen`): the lines the season closed with.
  @Test func theFinishedBookIsTheBookedFinish() throws {
    let b=try book("finished");#expect(b.version==1)
    #expect(b.rules_note=="These are the lines the season closed with. Later rule changes, posts and deletions do not move them.")
    try b.validate(league:b.league_id,season:b.season_id)
  }
  /// W7-120 · the rules line's minimum names its unit, as the web's Book does
  @Test func theRulesLineNamesTheMinimumsUnit() throws {
    let two=try changed { $0["counting_cap"]=4; $0["participation_floor"]=2 }
    #expect(two.rules=="Best 4 per calendar month · minimum 2 rounds")
    let one=try changed { $0["counting_cap"]=NSNull(); $0["participation_floor"]=1 }
    #expect(one.rules=="All rounds count · minimum 1 round")
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
    #expect(figure(dropped.fig) != nil && dropped.marks.contains("D"))
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
        // the marks are a NOTE, never another digit of the figure (read
        // through `figure`: the tie fixture's week 12 is −30 with its mark)
        if !p.marks.isEmpty { #expect(figure(p.fig) != nil) }
        // W5 · a signed figure takes a true minus, never a hyphen
        #expect(!p.fig.contains("-"), "a hyphen in \(p.fig)")
        // …and the cell says each one in words (its accessible name)
        if p.marks.contains("D") { sawD=true; #expect(spoken.contains("dropped rounds retained in receipt")) }
        if p.marks.contains("*") { sawStar=true; #expect(spoken.contains("adjustment or bye recorded")) }
        // §16 · the figure IS the cell, and the cell's receipts add up to it
        if let value=figure(p.fig) {
          let points=cumulative ? cell.cumulative : cell.points
          #expect(value == points)
          let receipts=SeasonBookSnapshot.selectedEntries(row,week:cell.week,cumulative:cumulative)
          #expect(receipts.reduce(0) { $0+$1.contribution } == value)
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

  // MARK: W5 · the Book reads as a book (the desk's twin, merged at 4a703402)

  /// A signed figure takes a true minus wherever the Book prints one — the
  /// tie fixture's week 12 is a negative cell.
  @Test func aSignedFigureTakesATrueMinus() throws {
    #expect(SeasonBookSnapshot.num(-3) == "\u{2212}3")
    #expect(SeasonBookSnapshot.num(0) == "0" && SeasonBookSnapshot.num(41) == "41")
    let b=try book("tie")
    let negative=try #require(b.rows.flatMap { row in row.cells.map { (row,$0) } }.first { !$0.1.future && ($0.1.points ?? 0) < 0 })
    let p=SeasonBookSnapshot.parts(row:negative.0,cell:negative.1,cumulative:false)
    #expect(p.fig.hasPrefix("\u{2212}") && p.fig == SeasonBookSnapshot.num(negative.1.points ?? 0))
  }
  /// "Applies to 2026-08" printed the raw month; an assessed month reads as a
  /// golfer reads one.
  @Test func anAssessedMonthReadsAsAMonth() throws {
    #expect(SeasonBookSnapshot.month("2026-08-01") == "Aug 2026")
    #expect(SeasonBookSnapshot.month("2026-08") == "Aug 2026")
    #expect(SeasonBookSnapshot.month("not a month") == "not a month")
    let months=try book().rows.flatMap(\.entries).compactMap(\.affected_month)
    #expect(!months.isEmpty && months.allSatisfy { !SeasonBookSnapshot.month($0).contains("-") })
  }
  /// The race labels each line at its end — its name and where it stands
  /// today — draws no legend of glyphs, and never lays one label over another.
  @Test func theRaceIsLabelledAtItsLineEnds() throws {
    let b=try book("finished"), golfers=b.rows.filter { $0.kind == "golfer" }
    let plotted=SeasonBookSnapshot.racePlotted(golfers,follow:"leaders")
    #expect(plotted.count == 3)
    // equal points read in alphabetical order (D381): the level top is drawn
    // in the same order on every load
    #expect(plotted[0].points == plotted[1].points)
    #expect(plotted[0].name.localizedCompare(plotted[1].name) == .orderedAscending)
    for row in plotted {
      let end=try #require(SeasonBookSnapshot.raceEnd(row))
      #expect(end.week == b.current_week && end.points == row.points)
      #expect(SeasonBookSnapshot.raceLabel(row) == "\(row.name) \(row.points)")
      #expect(!SeasonBookSnapshot.raceLabel(row).contains { "━┄┈".contains($0) })
    }
    // the golfer followed leads, and the leaders fill the other two lines
    let followed=try #require(golfers.last)
    #expect(SeasonBookSnapshot.racePlotted(golfers,follow:followed.id).first?.id == followed.id)
    // one label per line, in a column: level ends stack, the top clamps, and
    // a column past the bottom lifts as a whole
    #expect(SeasonBookSnapshot.raceSlots([100,100,100],gap:16,top:8,bottom:200) == [100,116,132])
    #expect(SeasonBookSnapshot.raceSlots([2,50],gap:16,top:8,bottom:200) == [8,50])
    #expect(SeasonBookSnapshot.raceSlots([195,190],gap:16,top:8,bottom:200) == [200,184])
  }
  private func stored(_ b: SeasonBookSnapshot, champion: UUID?, rung: String? = nil, id: UUID? = nil) -> Me.Season {
    Me.Season(id:id ?? b.season_id,number:b.number,starts_on:b.starts_on,ends_on:b.ends_on,status:"complete",timezone:nil,grace_hours:nil,
              champion_squad_id:nil,champion_member_id:champion,points_king_member_id:nil,tiebreak_rung:rung)
  }
  /// Two "1st · Tied" rows and no champion left the reader to guess. With no
  /// crown stored for this Book's season, a level top says what the D388
  /// ladder does with a tie, and names no one.
  @Test func aLevelTopWithNoCrownSaysTheLadder() throws {
    let b=try book("finished")
    let ladder=SeasonBookSnapshot.Crown(label:"Level at the top",text:SeasonBookSnapshot.tieLadder)
    #expect(SeasonBookSnapshot.tieLadder == "A tie at the top goes to head-to-head months won, then the best single month, then the fewest rounds used, then a coin flip.")
    #expect(b.crown(stored:nil) == ladder)
    // a crown stored for ANOTHER season is not this Book's
    #expect(b.crown(stored:stored(b,champion:b.rows.first { $0.kind == "golfer" }?.member_id,id:UUID())) == ladder)
    // a live Book, and one before its first tee, name no crown
    #expect(try book().crown(stored:nil) == nil)
    #expect(try book("upcoming").crown(stored:nil) == nil)
  }
  /// The stored crown names the champion, and the rung that settled a level top.
  @Test func theStoredCrownNamesTheChampionAndTheRung() throws {
    let b=try book("finished")
    let champion=try #require(b.rows.filter { $0.kind == "golfer" && $0.points_rank == 1 }.last)
    #expect(b.crown(stored:stored(b,champion:champion.member_id,rung:"months won"))
            == SeasonBookSnapshot.Crown(label:"Champion",text:"\(champion.name) · level at the top, decided on head-to-head months won"))
    #expect(b.crown(stored:stored(b,champion:champion.member_id,rung:"coin flip"))?.text.hasSuffix("decided on a coin flip") == true)
    #expect(b.crown(stored:stored(b,champion:champion.member_id)) == SeasonBookSnapshot.Crown(label:"Champion",text:champion.name))
  }

}

/// W5 twin (csSeasonBookReceipt, csRoundDay) · a receipt dates its rounds as
/// every receipt does, and a week's receipt says its week once.
@Suite struct SeasonBookReceiptWordsTests {
  @Test func aRoundsDayIsTheReceiptsForm() {
    var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "America/Phoenix")!
    #expect(LeagueDates.roundDay("2026-09-21", today: "2026-09-29", calendar: cal) == "Mon Sep 21")
    #expect(LeagueDates.roundDay("2025-09-21T10:00:00Z", today: "2026-09-29", calendar: cal) == "Sun Sep 21, 2025")
  }

  @Test func aWeeksReceiptSaysItsWeekOnce() throws {
    let url = try #require(Bundle.module.url(forResource: "tie", withExtension: "json"))
    let book = try JSONDecoder().decode(SeasonBookSnapshot.self, from: Data(contentsOf: url))
    let entry = try #require(book.rows.flatMap(\.entries).first { $0.week != nil })
    #expect(entry.place(inWeek: true) == nil, "the week's head already says it")
    #expect(entry.place(inWeek: false) == "Week \(entry.week!)")
  }
}

/// W5 twin · the reader's own row says "You", before its standing.
@Suite struct SeasonBookYouRowTests {
  @Test func theReadersRowIsMarked() throws {
    let url = try #require(Bundle.module.url(forResource: "tie", withExtension: "json"))
    let book = try JSONDecoder().decode(SeasonBookSnapshot.self, from: Data(contentsOf: url))
    #expect(book.rows.contains { $0.mine }, "the fixture holds the reader's row")
    for row in book.rows {
      if row.mine { #expect(row.standingLine?.hasPrefix("You") == true, "\(row.name): \(row.standingLine ?? "nil")") }
      else { #expect(row.standingLine?.hasPrefix("You") != true) }
    }
  }
}
