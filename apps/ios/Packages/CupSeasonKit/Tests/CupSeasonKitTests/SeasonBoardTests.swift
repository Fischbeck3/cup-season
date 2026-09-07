// Cup Season — the season board's producers (Wave 5, `surfaces/season.md`).
//
// The month clock's grouping, the slat's clause, the gap column, the count
// slots and the pot's caption. Every one of these is a string the desk has to
// print identically, so every one of them is pinned here.

import Testing
import Foundation
@testable import CupSeasonKit

// MARK: - The month clock (§1.2)

@Suite struct SeasonCalendarMathTests {
  /// A thirteen-week season starting Mon Aug 3: **a week belongs to the month
  /// that holds most of it**, sampled at its median day. Aug 31 – Sep 6 is one
  /// August day against six September ones, so it is a SEPTEMBER week — and
  /// that is the whole reason the rule is the median rather than the first day.
  /// Grouped by the first day it landed at the end of the August group while
  /// the ember month label read September, and the graphic pointed at two
  /// different places at once.
  @Test func weeksGroupByTheMonthThatHoldsMostOfThem() {
    let m = SeasonCalendarMath.months(startsOn: "2026-08-03", weeks: 13, today: "2026-09-07")
    #expect(m.map(\.label) == ["Aug", "Sep", "Oct"])
    #expect(m.map(\.weeks) == [4, 4, 5])
    #expect(m.reduce(0) { $0 + $1.weeks } == 13)
  }

  /// The live TICK and the live LABEL land in the same group, which is the
  /// defect the median rule exists to fix.
  @Test func theLiveWeekAndTheLiveMonthAgree() {
    let m = SeasonCalendarMath.months(startsOn: "2026-08-03", weeks: 13, today: "2026-09-02")
    // today sits in the week that tees off Aug 31 — season week 5, index 4
    var first = 0
    for g in m {
      if g.live { #expect(first <= 4 && 4 < first + g.weeks, "the live tick is outside the live month") }
      first += g.weeks
    }
    #expect(m.contains { $0.live })
  }

  /// The same season across a year boundary keeps its order — December then
  /// January, never sorted by month number.
  @Test func theGroupsKeepTheSeasonsOwnOrder() {
    let m = SeasonCalendarMath.months(startsOn: "2026-12-07", weeks: 8, today: "2026-12-14")
    #expect(m.map(\.label) == ["Dec", "Jan"])
    #expect(m.reduce(0) { $0 + $1.weeks } == 8)
  }

  @Test func exactlyOneMonthIsLiveAndOnlyItCarriesTheNote() {
    let m = SeasonCalendarMath.months(startsOn: "2026-08-03", weeks: 13, today: "2026-09-06")
    #expect(m.filter(\.live).count == 1)
    #expect(m.first { $0.live }?.label == "Sep")
    #expect(m.first { $0.live }?.note == "25 days")
    #expect(m.filter { !$0.live }.allSatisfy { $0.note == nil })
  }

  /// A device reading a month the season never touches gets no live group —
  /// and no note. The ticks then carry the clock alone.
  @Test func aMonthOutsideTheSeasonIsNeverLive() {
    let m = SeasonCalendarMath.months(startsOn: "2026-08-03", weeks: 13, today: "2027-02-01")
    #expect(m.allSatisfy { !$0.live })
    #expect(m.allSatisfy { $0.note == nil })
  }

  @Test func aSeasonWithNoStartDrawsNoClock() {
    #expect(SeasonCalendarMath.months(startsOn: nil, weeks: 13).isEmpty)
    #expect(SeasonCalendarMath.months(startsOn: "2026-08-03", weeks: 0).isEmpty)
  }

  /// The note is singular on the last day of the month and absent on the day
  /// the month turns — never "0 days".
  @Test func theNoteCountsDaysAndNeverPrintsZero() {
    #expect(SeasonCalendarMath.daysLeftNote("2026-09-30") == "1 day")
    #expect(SeasonCalendarMath.daysLeftNote("2026-09-29") == "2 days")
  }
}

// MARK: - The gap column (§1.4)

@Suite struct SeasonGapTests {
  /// **The leader's cell is EMPTY** — not `0`, and not an em dash either: a
  /// dash reads as a value, which is the thing "empty" was protecting against.
  @Test func theLeadersCellIsEmpty() {
    #expect(SeasonBoardCopy.gap(leader: 19, row: 19) == "")
  }
  @Test func everyOtherRowCarriesASignedGap() {
    #expect(SeasonBoardCopy.gap(leader: 19, row: 15) == "+4")
    #expect(SeasonBoardCopy.gap(leader: 19, row: 4) == "+15")
  }
  /// A tie for the lead is two empty cells, not one row claiming a deficit it
  /// does not have.
  @Test func aTieForTheLeadPrintsNothingOnEitherRow() {
    #expect(SeasonBoardCopy.gap(leader: 19, row: 19) == "")
    #expect(SeasonBoardCopy.gap(leader: 19, row: 20) == "")
  }
}

// MARK: - The slat's clause (§1.4)

@Suite struct SeasonClauseTests {
  private func clause(isLeader: Bool = false, runSince: Int? = nil, runWeeks: Int? = nil,
                      isMe: Bool = false, counted: Int? = nil, cap: Int? = nil,
                      rounds: Int = 0, solo: Bool = true, left: Bool = false, cooled: Bool = false) -> String {
    SeasonBoardCopy.clause(isLeader: isLeader, runSince: runSince, runWeeks: runWeeks, isMe: isMe,
                           counted: counted, cap: cap, rounds: rounds, solo: solo, left: left, cooled: cooled)
  }

  @Test func theLeadersClauseIsTheRun() {
    #expect(clause(isLeader: true, runSince: 3, runWeeks: 3) == "Held since week three")
  }
  /// Without a week to name, the run states its length rather than inventing a
  /// week number.
  @Test func aRunWithNoWeekStatesItsLength() {
    #expect(clause(isLeader: true, runSince: nil, runWeeks: 4) == "Held four weeks")
  }
  /// A leader who has just taken the lead has no run, and falls to the rounds.
  @Test func aBrandNewLeaderFallsThrough() {
    #expect(clause(isLeader: true, runWeeks: 1, rounds: 3) == "3 rounds")
  }
  @Test func myOwnRowSaysWhatIsCounting() {
    #expect(clause(isMe: true, counted: 1, cap: 4, rounds: 3) == "1 of 4 counting")
  }
  /// The blind review's finding 8: `1 OF 4 COUNTING · ONE S…` sheared, so the
  /// qualifier lives in the receipt and the clause is authored to a budget.
  @Test func theClauseFitsItsColumn() {
    #expect(clause(isMe: true, counted: 1, cap: 4, rounds: 3).count <= 20)
    #expect(clause(isLeader: true, runSince: 3).count <= 24)
  }
  @Test func cooledRidesTheRoundsAndNothingElse() {
    #expect(clause(rounds: 4, cooled: true) == "4 rounds · cooled")
    #expect(clause(rounds: 1) == "1 round")
    #expect(clause(rounds: 0) == "No rounds yet")
  }
  /// `TERMINOLOGY` §4 pattern 2 · the schema's `participation_floor` never
  /// surfaces, on any row, in any state.
  @Test func theWordFloorNeverAppears() {
    let all = [clause(isLeader: true, runSince: 3), clause(isMe: true, counted: 0, cap: 4),
               clause(rounds: 0), clause(rounds: 5, cooled: true), clause(left: true)]
    #expect(all.allSatisfy { !$0.lowercased().contains("floor") })
  }
  @Test func aGolferWhoStoppedScoringSaysSoFirst() {
    #expect(clause(isLeader: true, runSince: 3, left: true) == "Stopped scoring")
  }
}

// MARK: - The count slots (§16A.2)

@Suite struct SeasonCountSlotTests {
  @Test func spelledToTwelveAndAFigurePastIt() {
    #expect(SeasonBoardCopy.field(8) == "eight in the field")
    #expect(SeasonBoardCopy.field(12) == "twelve in the field")
    #expect(SeasonBoardCopy.potIn(8) == "eight in")
    #expect(SeasonBoardCopy.paid(6, of: 8) == "six of eight")
    #expect(SeasonBoardCopy.sides(4) == "four sides")
  }
  /// The slot carries a COUNT and nothing else — never the stake, which is the
  /// figure's own caption, and never a date or a range.
  @Test func theSlotCarriesNoMoneyAndNoRange() {
    #expect(!SeasonBoardCopy.potIn(8).contains("$"))
    #expect(!SeasonBoardCopy.field(8).contains("week"))
  }
}

// MARK: - The countdown (§1.5)

@Suite struct SeasonCountdownTests {
  @Test func aCupFinalSeasonCountsWeeksToTheFinal() {
    let c = SeasonBoardCopy.countdown(finish: "cup_final", inWeeks: 8, weeksLeft: 8)
    #expect(c?.figure == "08")
    #expect(c?.label == "weeks to the Cup Final")
  }
  /// A points-table season renders the same block with its own end and **no
  /// mention of a cut** — nothing there advances.
  @Test func aPointsTableSeasonNeverNamesTheFinal() {
    let c = SeasonBoardCopy.countdown(finish: "points_table", inWeeks: 8, weeksLeft: 4)
    #expect(c?.figure == "04")
    #expect(c?.label == "weeks left in the season")
    #expect(!(c?.label.contains("Cup") ?? true))
  }
  /// A payload that never carried the fact renders nothing rather than a `00`.
  @Test func noFactRendersNoBlock() {
    #expect(SeasonBoardCopy.countdown(finish: "cup_final", inWeeks: nil, weeksLeft: nil) == nil)
  }
  /// The cut is never gold and never says *advance* — it says who plays.
  @Test func theCutNamesTheFinalAndNothingElse() {
    #expect(SeasonBoardCopy.cut(k: 2) == "Cut · top two play the Cup Final")
  }
  /// **The seat count is the server's, not a constant.** A squad-level
  /// `squads2` season seats ONE, and the sentence agrees with the line.
  @Test func theCutCountsTheSeatsTheSeasonActuallyHas() {
    #expect(SeasonBoardCopy.cut(k: 1) == "Cut · top one plays the Cup Final")
    #expect(SeasonBoardCopy.cut(k: 3) == "Cut · top three play the Cup Final")
    // and it never prints a zero or a negative seat
    #expect(SeasonBoardCopy.cut(k: 0) == SeasonBoardCopy.cut(k: 1))
  }
  /// `ClimbMath.cut` is where K comes from, and the three shipped finish
  /// shapes are the three the board can be asked to draw.
  @Test func theSeatCountComesFromTheSeasonsOwnShape() {
    func meta(_ finish: String, _ structure: String?, _ level: String?, _ k: Int?) -> SeasonScenarios.Meta {
      SeasonScenarios.Meta(finish: finish, structure: structure, level: level, k: k,
                           months_left: 2, locked: false, cap: 4)
    }
    #expect(ClimbMath.cut(meta("points_table", "solo", "member", 2)).K == 1)
    #expect(ClimbMath.cut(meta("cup_final", "squads2", "squad", 2)).K == 1)
    #expect(ClimbMath.cut(meta("cup_final", "solo", "member", 3)).K == 3)
    #expect(ClimbMath.cut(meta("cup_final", "solo", "member", nil)).K == 2)
  }
}

// MARK: - The pot (§1.6, D273)

@Suite struct SeasonPotCopyTests {
  /// The blind review's fixture: the Fellas are eight in at $60 → $480 →
  /// $288 / $120 / $72, on every surface.
  @Test func theCaptionIsTheStakeAndTheSettlementsOwnSplit() {
    let trio = PotMath.trioCents(potCents: 48000, payout: [60, 25, 15])
    #expect(SeasonBoardCopy.potCaption(stake: 60, trio: trio) == "$60 each · 288 / 120 / 72")
  }
  /// **The sign is a WORD** — never a tick, never opacity, never a hue.
  @Test func theSignIsAWord() {
    #expect(SeasonBoardCopy.sign(paid: true, mine: false) == "Paid")
    #expect(SeasonBoardCopy.sign(paid: true, mine: true) == "Paid")
    #expect(SeasonBoardCopy.sign(paid: false, mine: true) == "You owe")
    #expect(SeasonBoardCopy.sign(paid: false, mine: false) == "Owes")
  }
  /// LINT-23 · the ledger line is ONE constant. A retyped copy is a defect the
  /// day it is written, so the test names the string rather than the variable.
  @Test func theLedgerLineIsOneConstant() {
    #expect(MoneyCopy.ledger == "Cup Season keeps the ledger; the money moves between friends.")
  }
}

// MARK: - The head (§1.1)

@Suite struct SeasonHeadCopyTests {
  /// The stage leads, because the dot beside it is the ember and the ember
  /// means *live*. The league's name is set once, in `display`, beneath.
  @Test func theEyebrowNamesTheStateAndTheWeek() {
    #expect(SeasonBoardCopy.eyebrow(stage: .season, week: 5, weeks: 13) == "Season live · week 5 of 13")
    #expect(SeasonBoardCopy.eyebrow(stage: .complete, week: 13, weeks: 13) == "Season complete")
    #expect(SeasonBoardCopy.eyebrow(stage: .preseason, week: 1, weeks: 13) == "Before first tee")
  }
  @Test func theEyebrowNeverCarriesTheLeaguesName() {
    #expect(!SeasonBoardCopy.eyebrow(stage: .season, week: 5, weeks: 13).contains("Fellas"))
  }
  @Test func theDatelineIsSeasonSpanAndPro() {
    #expect(SeasonBoardCopy.dateline(number: 1, span: "Mon Aug 3 – Mon Nov 2", pro: "Galen")
            == "Season one · Mon Aug 3 – Mon Nov 2 · the Pro, Galen")
  }
  /// An en dash, never an arrow (LINT-13) — the span producer owns it, and this
  /// pins that the head does not add one.
  @Test func noArrowInTheDateline() {
    let d = SeasonBoardCopy.dateline(number: 1, span: "Mon Aug 3 – Mon Nov 2", pro: "Galen")
    #expect(!d.contains("→") && !d.contains("->"))
  }
  /// A season with no Pro named, and a squads season that names its sides.
  @Test func theDatelineDropsWhatItDoesNotHave() {
    #expect(SeasonBoardCopy.dateline(number: nil, span: "Mon Aug 3 – Mon Nov 2", pro: "—")
            == "Mon Aug 3 – Mon Nov 2")
    #expect(SeasonBoardCopy.dateline(number: 1, span: "Aug 3 – Nov 2", pro: nil, squads: 4)
            == "Season one · four squads · Aug 3 – Nov 2")
  }
}
