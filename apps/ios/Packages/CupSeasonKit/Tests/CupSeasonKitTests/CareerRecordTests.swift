// Cup Season — the record's two season counts, and the clause that waits for
// its fact (R12, D232, D67).
//
// `career_record.seasons_done` counts DISTINCT seasons in `season_payouts`,
// and `season_payouts` holds **0 rows for every profile in prod**. So the
// record told every golfer they had finished no seasons — including the
// golfers in the one season that actually completed. The figure is not wrong
// as a MONEY denominator; it is wrong as an answer to "how many seasons have
// you played", and the fix is to stop asking one number two questions.
//
// The "since March" clause has the same shape of defect waiting inside it:
// `profiles.created_at` is the ACCOUNT, not the golf, and rendering it as
// "since" would be a fact the app cannot support (L-44). R12 adds
// `first_round_on`; without it the clause does not render at all.

import Testing
import Foundation
@testable import CupSeasonKit

private func parse(_ s: String) throws -> CareerRecord {
  CareerRecord.parse(try JSONDecoder().decode(JSONValue.self, from: Data(s.utf8)))
}

/// What the SHIPPED function returns today — no `seasons_played`, no
/// `first_round_on`.
private let preR12 = """
{ "cups": 1, "runner_ups": 0, "crowns": 0, "majors": 0, "events": 0, "trophies": 1,
  "earnings_cents": 0, "seasons_done": 0, "leagues": 2 }
"""

/// What R12 returns: the two counts split, and the earliest counting round.
private let postR12 = """
{ "cups": 1, "runner_ups": 1, "crowns": 0, "majors": 0, "events": 0, "trophies": 2,
  "earnings_cents": 15000, "seasons_done": 1, "seasons_played": 3,
  "first_round_on": "2026-03-22", "leagues": 2 }
"""

@Suite struct CareerRecordTests {

  // MARK: seasons_played ≠ seasons_done

  @Test func theTwoSeasonCountsAreDifferentNumbers() throws {
    let r = try parse(postR12)
    #expect(r.seasonsDone == 1)
    #expect(r.seasonsPlayed == 3)
    #expect(r.seasonsPlayed != r.seasonsDone)
  }

  @Test func theMoneyLineKeepsTheDenominatorItIsDenominatedIn() throws {
    let r = try parse(postR12)
    let money = try #require(r.moneyLine)
    // "Settled across 1 season" — the PAID count, not the played count. The
    // money line is the one place `seasons_done` is the right answer.
    #expect(money.sub == "Settled across 1 season")
    #expect(!money.sub.contains("3"))
  }

  @Test func theSeasonsLineUsesThePlayedCount() throws {
    let r = try parse(postR12)
    #expect(r.seasonsLine == "3 seasons played")
  }

  @Test func aPayloadThatPredatesR12RendersNoSeasonsLine() throws {
    let r = try parse(preR12)
    // The whole defect, held as a case: the shipped payload reads 0 for
    // everybody, and printing "0 seasons played" to a golfer who has finished
    // one is the lie. Absent means absent.
    #expect(r.seasonsPlayed == nil)
    #expect(r.seasonsLine == nil)
  }

  @Test func aRealZeroIsStillNotALine() throws {
    let r = try parse("""
    { "cups": 0, "earnings_cents": 0, "seasons_done": 0, "seasons_played": 0, "leagues": 1 }
    """)
    // A golfer genuinely mid-first-season has finished nothing, and "0 seasons
    // played" is a stat about nothing (L-44).
    #expect(r.seasonsPlayed == 0)
    #expect(r.seasonsLine == nil)
  }

  // MARK: the "since" clause renders only when first_round_on is present

  @Test func theSinceClauseRendersOnlyWithFirstRoundOn() throws {
    #expect(try parse(postR12).sinceClause == "since March 2026")
    #expect(try parse(preR12).sinceClause == nil)
  }

  @Test func theSinceClauseNeverFallsBackToTheAccount() throws {
    // `member_since` / `created_at` is on the card and is deliberately NOT an
    // input here: the account is not the golf.
    let r = try parse("""
    { "cups": 0, "earnings_cents": 0, "seasons_done": 0, "leagues": 0,
      "member_since": "2025-01-04T00:00:00+00:00" }
    """)
    #expect(r.firstRoundOn == nil)
    #expect(r.sinceClause == nil)
  }

  @Test func theSinceClauseReadsTheDateByParts() throws {
    // L-07 · a calendar date is a String, read by parts, never through an ISO
    // parser that would move it a day in Phoenix.
    #expect(CareerRecord.monthYear("2026-01-01") == "January 2026")
    #expect(CareerRecord.monthYear("2026-12-31") == "December 2026")
    #expect(CareerRecord.monthYear("2026-13-01") == nil)
    #expect(CareerRecord.monthYear("not a date") == nil)
  }

  // MARK: the titles, unchanged

  @Test func zeroCountTitlesAreOmittedRatherThanShownAsNoughts() throws {
    let r = try parse(postR12)
    #expect(r.items.map(\.key) == ["cups", "runner_ups"])
    #expect(r.items.first?.label == "Cup")          // singular at one
    #expect(r.items.last?.label == "Runner-up")
  }

  @Test func nothingSettledMeansNoMoneyLine() throws {
    #expect(try parse(preR12).moneyLine == nil)
  }

  @Test func theMoneyNoteIsTheLedgerLineVerbatim() {
    // L-09 · the ledger sentence comes from `MoneyCopy.ledger` and is never
    // retyped beside it.
    #expect(CareerRecord.moneyNote.hasSuffix(MoneyCopy.ledger))
  }
}
