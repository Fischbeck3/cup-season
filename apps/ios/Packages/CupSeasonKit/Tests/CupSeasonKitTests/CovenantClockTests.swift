import Testing
import Foundation
@testable import CupSeasonKit

/// W4 · the covenant says where the season stands before the money (owner E,
/// critique B). `Covenant.clockLine` is the twin of the web's
/// `csCovenantClock`, and the first four tests are the web's four app-tests
/// (tests/app-tests.js "W4: …"), word for word; the rest walk every branch
/// the web function has.
@Suite struct CovenantClockTests {
  private static let cal: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "America/Phoenix")!
    return c
  }()

  /// The web's `nine`: thirteen weeks from Sun Aug 9, ending in a Cup Final.
  private static func nine(structure: String? = nil, floor: Int = 0, finish: String? = "cup_final",
                           endsOn: String? = nil, weeks: Int? = 13, startsOn: String? = "2026-08-09") -> Covenant {
    Covenant(name: "North Grove (fixture)", buyinCents: 7500, preset: "standard", floor: floor, finish: finish,
             startsOn: startsOn, weeks: weeks, endsOn: endsOn, structure: structure)
  }

  private func clock(_ c: Covenant, _ today: String) -> String? { c.clockLine(today: today, calendar: Self.cal) }

  // MARK: - the web's four

  @Test func weekEightOfThirteenOnTheThinnestSquadWithNoMinimumUntilNextMonth() {
    #expect(clock(Self.nine(structure: "squads2", floor: 2), "2026-09-28")
            == "You’d join in week 8 of 13, on the squad with the fewest golfers; your rounds count for it from that day. There’s no minimum to clear until October.")
  }

  /// L-23 · an individual season assesses no minimum, so none is promised.
  @Test func aSoloSeasonSaysTheWeekAndPromisesNoMinimum() {
    #expect(clock(Self.nine(structure: "solo", floor: 2), "2026-09-28") == "You’d join in week 8 of 13.")
  }

  /// D382 · a Final's squads are held, so no late seat is promised inside one.
  @Test func insideTheCupFinalNoLateSeatIsPromised() {
    #expect(clock(Self.nine(structure: "squads2", floor: 2, endsOn: "2026-11-07"), "2026-10-20")
            == "You’d join in week 11 of 13, during the Cup Final.")
  }

  /// The length already says when; after the last week there is nothing to join.
  @Test func beforeTheFirstTeeAndAfterTheLastWeekItSaysNothing() {
    #expect(clock(Self.nine(), "2026-08-08") == nil)
    #expect(clock(Self.nine(), "2026-11-08") == nil)
    #expect(clock(Self.nine(startsOn: nil), "2026-09-28") == nil)
  }

  // MARK: - every other branch

  /// L-44 · no length, or a garbled date, is no read — never a guess.
  @Test func aClockWithoutItsTwoFactsSaysNothing() {
    #expect(clock(Self.nine(weeks: nil), "2026-09-28") == nil)
    #expect(clock(Self.nine(weeks: 0), "2026-09-28") == nil)
    #expect(clock(Self.nine(startsOn: ""), "2026-09-28") == nil)
    #expect(clock(Self.nine(startsOn: "soon"), "2026-09-28") == nil)
  }

  /// The first tee is week 1; the last day of the thirteenth week still says it.
  @Test func theWeekIsCountedFromThePayloadsOwnFirstTee() {
    #expect(clock(Self.nine(finish: "points_table"), "2026-08-09") == "You’d join in week 1 of 13.")
    #expect(clock(Self.nine(finish: "points_table"), "2026-08-15") == "You’d join in week 1 of 13.")
    #expect(clock(Self.nine(finish: "points_table"), "2026-08-16") == "You’d join in week 2 of 13.")
    #expect(clock(Self.nine(finish: "points_table"), "2026-11-07") == "You’d join in week 13 of 13.")
    // a timestamp is read as its day, as the web slices it
    #expect(clock(Self.nine(finish: "points_table", startsOn: "2026-08-09T00:00:00"), "2026-08-16") == "You’d join in week 2 of 13.")
  }

  /// The Final opens at `ends_on − 27` (§14.0): the day before it is still a
  /// late seat, and with no `ends_on` the end is the first tee plus the length.
  @Test func theFinalOpensTwentySevenDaysFromTheEnd() {
    #expect(clock(Self.nine(structure: "squads2"), "2026-10-10")
            == "You’d join in week 9 of 13, on the squad with the fewest golfers; your rounds count for it from that day.")
    #expect(clock(Self.nine(structure: "squads2"), "2026-10-11") == "You’d join in week 10 of 13, during the Cup Final.")
    #expect(clock(Self.nine(structure: "squads2", endsOn: ""), "2026-10-11") == "You’d join in week 10 of 13, during the Cup Final.")
  }

  /// No Final to be inside of: a points table, and a season under six weeks
  /// (D384), say the week as any other.
  @Test func onlyACupFinalSeasonOfSixWeeksOrMoreHasAFinalToBeInside() {
    #expect(clock(Self.nine(structure: "squads2", finish: "points_table"), "2026-10-20")
            == "You’d join in week 11 of 13, on the squad with the fewest golfers; your rounds count for it from that day.")
    let four = Self.nine(structure: "squads4", weeks: 4)
    #expect(clock(four, "2026-08-24") == "You’d join in week 3 of 4, on the squad with the fewest golfers; your rounds count for it from that day.")
  }

  /// D386 · the seat on the thinnest squad is said for a squads season only;
  /// D161 · the join-month waiver only where a minimum exists — an older
  /// server with no structure keeps it, because a minimum is still assessed.
  @Test func theSeatAndTheWaiverAreSaidOnlyWhereTheRuleExists() {
    #expect(clock(Self.nine(structure: "squads3", floor: 0), "2026-09-28")
            == "You’d join in week 8 of 13, on the squad with the fewest golfers; your rounds count for it from that day.")
    #expect(clock(Self.nine(structure: nil, floor: 2), "2026-09-28")
            == "You’d join in week 8 of 13. There’s no minimum to clear until October.")
    #expect(clock(Self.nine(structure: "solo", floor: 0), "2026-09-28") == "You’d join in week 8 of 13.")
  }

  /// The waiver runs out at the next month's turn, including the year's.
  @Test func decemberWaivesUntilJanuary() {
    let fall = Self.nine(structure: "squads3", floor: 1, startsOn: "2026-11-01")
    #expect(clock(fall, "2026-12-15")
            == "You’d join in week 7 of 13, on the squad with the fewest golfers; your rounds count for it from that day. There’s no minimum to clear until January.")
  }

  /// Calendar days, never 24-hour periods: the spring-forward week is 167
  /// hours long, and it is still one week (the web rounds for the same reason).
  @Test func theWeekCountsCalendarDaysAcrossAClockChange() {
    var eastern = Calendar(identifier: .gregorian)
    eastern.timeZone = TimeZone(identifier: "America/New_York")!
    // clocks go forward at 2am on Sun Mar 8, inside the first week of a Monday season
    let c = Self.nine(finish: "points_table", startsOn: "2026-03-02")
    #expect(c.clockLine(today: "2026-03-08", calendar: eastern) == "You’d join in week 1 of 13.")
    #expect(c.clockLine(today: "2026-03-09", calendar: eastern) == "You’d join in week 2 of 13.")
  }

  // MARK: - the sheet's splice

  /// Right after the length and before the money, as the web's `showCovenant`
  /// splices it; without a clock the pinned order is untouched.
  @Test func theClockIsSaidAfterTheLengthAndBeforeTheMoney() {
    let c = Self.nine(structure: "squads2", floor: 2)
    let facts = c.facts(today: "2026-09-28", calendar: Self.cal)
    #expect(facts.map(\.0) == [.length, .joining, .structure, .rules, .ending, .stake, .ledger])
    #expect(facts.first { $0.0 == .joining }?.1 == c.clockLine(today: "2026-09-28", calendar: Self.cal))
    #expect(!c.facts().map(\.0).contains(.joining))
    #expect(!c.facts(today: "2026-08-08", calendar: Self.cal).map(\.0).contains(.joining))
  }
}
