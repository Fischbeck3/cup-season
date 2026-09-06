// Cup Season — what a round is worth (R-K, D256, D257).
//
// The rules these tests exist to hold:
//   · the SUM matches `public.round_worth`, case for case — the table in
//     20261001090000's header, which tests/db-checks.sql pins on the server
//   · it is a CEILING, never a probability (D24): every sentence says "up to"
//   · absent facts produce SILENCE, never a guess (L-44)
//   · the climb's own sentence is unchanged by the move (D201: one producer)
//   · the plan sheet's subject is "This round", because the sheet's header
//     already carries the day and the course (L-34, DEF-2)

import Testing
import Foundation
@testable import CupSeasonKit

@Suite("What a round is worth")
struct RoundWorthTests {

  // MARK: - the sum, against the server's own table

  @Test func theSumIsTheServers() {
    #expect(RoundWorth.gain(cap: 4, used: 2, worst: 6) == 12)      // a slot is open: it ADDS
    #expect(RoundWorth.gain(cap: 4, used: 4, worst: 6) == 6)       // full: it BUMPS the 6
    #expect(RoundWorth.gain(cap: 4, used: 4, worst: 12) == 0)      // full of top-band rounds
    #expect(RoundWorth.gain(cap: 4, used: 4, worst: nil) == nil)   // full, counter unknown
    #expect(RoundWorth.gain(cap: nil, used: 9, worst: nil) == 12)  // uncapped: everything counts
    #expect(RoundWorth.gain(cap: 0, used: 0, worst: nil) == 12)    // a zero cap is not a cap
  }

  @Test func theTopBandComesFromTheOneBandTable() {
    #expect(RoundWorth.topBand == Double(CSBands.cupPoints(3)))
  }

  @Test func slotsInHandIsTheFence() {
    #expect(RoundWorth.slotsLeft(cap: 4, used: 2) == 2)
    #expect(RoundWorth.slotsLeft(cap: 4, used: 4) == 0)
    #expect(RoundWorth.slotsLeft(cap: 4, used: 9) == 0)   // never negative
    #expect(RoundWorth.slotsLeft(cap: nil, used: 2) == nil)
  }

  // MARK: - the sentences

  @Test func theOwnersSentence() {
    #expect(RoundWorth.line(subject: "Tomorrow at Papago", cap: 4, used: 2)
              == "Tomorrow at Papago is worth up to 12. Your best 4 count and you have 2.")
  }

  @Test func aFullMonthSaysWhatItBumps() {
    #expect(RoundWorth.line(subject: "This round", cap: 4, used: 4, worst: 7)
              == "This round is worth up to 5 more. Your best 4 count this month and your worst is a 7.")
  }

  @Test func everySentenceIsACeiling() {
    let said = [RoundWorth.line(subject: "This round", cap: 4, used: 2),
                RoundWorth.line(subject: "This round", cap: 4, used: 4, worst: 7),
                RoundWorth.line(subject: "This round", cap: nil, used: 3)].compactMap { $0 }
    #expect(said.count == 3)
    #expect(said.allSatisfy { $0.contains("up to") })
    // D24 · nothing here weighs a chance.
    #expect(said.allSatisfy { !$0.lowercased().contains("likely") && !$0.lowercased().contains("chance") })
  }

  @Test func silenceWhereTheFactsAreAbsent() {
    #expect(RoundWorth.line(subject: "This round", cap: 4, used: 4, worst: nil) == nil)
    #expect(RoundWorth.lines([]).isEmpty)
  }

  @Test func aMaxedMonthIsToldTheTruthRatherThanAZero() {
    let s = RoundWorth.line(subject: "This round", cap: 4, used: 4, worst: 12)
    #expect(s == "This round cannot add to your points this month — your best 4 already count. It still builds your number.")
  }

  @Test func anUncappedLeagueCountsEverything() {
    #expect(RoundWorth.line(subject: "This round", cap: nil, used: 3)
              == "This round is worth up to 12. Every round you post this month counts.")
  }

  // MARK: - the rows, as they arrive

  @Test func theSeasonIsNamedOnlyWhenThereIsMoreThanOne() {
    let a = RoundWorth.Counters(leagueId: nil, leagueName: "The Fellas", cap: 4, used: 2, worst: nil)
    let b = RoundWorth.Counters(leagueId: nil, leagueName: "PIGL", cap: 3, used: 0, worst: nil)
    #expect(RoundWorth.lines([a]) == ["This round is worth up to 12. Your best 4 count and you have 2."])
    let both = RoundWorth.lines([a, b])
    #expect(both.count == 2)
    #expect(both[0].contains("in The Fellas"))
    #expect(both[1].contains("in PIGL"))
  }

  @Test func threeSeasonsDoNotBecomeAWallOfArithmetic() {
    let rows = (0..<3).map { RoundWorth.Counters(leagueId: nil, leagueName: "S\($0)", cap: 4, used: 1, worst: nil) }
    #expect(RoundWorth.lines(rows).count == 2)
  }

  @Test func aRoundYouAreOnlyWatchingIsWorthNothingToYou() {
    // The server sends `[]` for a viewer who is neither host nor tagged; the
    // sheet must then print nothing at all rather than a hopeful default.
    let d = RoundDetail(id: UUID(), profileId: nil, ownerName: "Galen", ownerMarker: nil, mine: false, taggedMe: false,
                        playOn: "2026-09-07", teeTime: nil, note: nil, courseLabel: "Papago", courseId: nil,
                        myRsvp: nil, course: nil, rsvp: [], comments: [])
    #expect(d.worthLines.isEmpty)
  }

  // MARK: - the climb is unchanged by the move (D201)

  @Test func theClimbStillSaysWhatItSaid() {
    // one top-band round closes a four-point gap with a slot open
    #expect(ClimbMath.closer(gap: 4, countingPoints: [6, 9], capN: 4) == "One round in the top band closes it.")
    // full month: the round bumps a 9, so it is worth 3 and does not close 4
    #expect(ClimbMath.closer(gap: 4, countingPoints: [9, 9, 9, 9], capN: 4) == nil)
    // full month: it bumps a 5, worth 7, and closes 4
    #expect(ClimbMath.closer(gap: 4, countingPoints: [5, 9, 9, 9], capN: 4) != nil)
    // no gap, no sentence
    #expect(ClimbMath.closer(gap: 0, countingPoints: [6], capN: 4) == nil)
    // uncapped
    #expect(ClimbMath.closer(gap: 11, countingPoints: [], capN: nil) != nil)
    #expect(ClimbMath.closer(gap: 13, countingPoints: [], capN: nil) == nil)
  }
}
