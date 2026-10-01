// Cup Season — D286 · COMPETE'S SEASON ROW SAYS WHERE YOU STAND, ONCE.
//
// The owner installed the overhaul and read the product as a wall of similar
// text. On Compete the cause was two objects: section heads no louder than
// their rows, and a season row whose STANDING — the one fact the tab exists
// to answer — was the fourth clause of a grey sentence.
//
// The head is a drawing and its evidence is a screenshot. The standing is a
// PRODUCER, and this is its evidence: the row carries the rank as two numbers,
// the sentence stops printing it, and the three phases that have no honest
// standing carry no figure at all.

import Testing
import Foundation
@testable import CupSeasonKit

private let cal = Calendar(identifier: .gregorian)

private func season(_ status: String = "active", starts: String, ends: String,
                    week: Int? = nil, of: Int? = nil, toFirstTee: Int? = nil) -> Me.Season {
  Me.Season(id: UUID(), number: 2, starts_on: starts, ends_on: ends, status: status, timezone: nil,
            grace_hours: nil, champion_squad_id: nil, champion_member_id: nil, points_king_member_id: nil,
            tiebreak_rung: nil, week_no: week, weeks_total: of, week_ends_on: nil,
            days_to_first_tee: toFirstTee, days_left: nil, final_opens_on: nil)
}

private func membership(phase: String = "season", buyin: Int = 0, role: String = "player",
                        season s: Me.Season?,
                        standing: Me.Standing? = Me.Standing(rank: 2, of: 8, points: 15, prev_rank: 2,
                                                             leader_squad_id: nil, leader_points: 19,
                                                             gap_to_leader: 4, gap_to_next: nil,
                                                             leader_name: "Blake", runner_up_name: nil,
                                                             runner_up_points: nil, seed: nil, finalists: nil,
                                                             next_up: nil, next_down: nil),
                        last: Me.Membership.LastSeason? = nil) -> Me.Membership {
  Me.Membership(
    league_id: UUID(), name: "North Grove (fixture)", code: "NGFX26", phase: phase, sandbox: false, role: role,
    member_id: UUID(), marker: "saguaro", commissioner_name: "Blake",
    settings: Me.Settings(structure: "solo", preset: nil, counting_cap: 4, participation_floor: 2,
                          floor_penalty: nil, handicap_allowance: 95, buyin_cents: buyin,
                          payout_champ: 60, payout_runnerup: 25, payout_king: 15,
                          finish: "cup_final", locked_at: nil),
    season: s, squad: nil, standing: standing, pulse: nil, buy_in: nil,
    roster: 8, members: 8, pro_name: "Blake", last_season: last)
}

private func rows(_ m: Me.Membership, today: String) -> CompeteRoot.List {
  CompeteRoot.make(Me(profile: nil, memberships: [m]), today: today, calendar: cal)
}

@Suite("D286 — the standing is a figure, and it is said once")
struct CompeteStandingTests {

  /// The owner's own shape: week 8 of 15, second of two, four back of Blake.
  @Test("a running season hands the row two numbers")
  func aRunningSeasonCarriesItsRank() {
    let m = membership(season: season(starts: "2026-07-13", ends: "2026-10-26", week: 8, of: 15))
    let row = rows(m, today: "2026-09-07").seasons.first
    #expect(row?.rank?.place == 2)
    #expect(row?.rank?.of == 8)
  }

  /// **AND THE SENTENCE STOPS SAYING IT.** A row that prints `2ND / OF 8` in
  /// 27pt board type and *"2nd of 8"* in 15pt sans beneath it has told the
  /// golfer his position twice in two voices — which is the defect, not the fix.
  @Test("the rank leaves the sentence, and the race stays in it")
  func theSentenceDropsTheRankAndKeepsTheRace() {
    let m = membership(season: season(starts: "2026-07-13", ends: "2026-10-26", week: 8, of: 15))
    let sub = rows(m, today: "2026-09-07").seasons.first?.sub ?? ""
    #expect(!sub.contains("2nd of 8"), "the rank is drawn, not printed — got: \(sub)")
    #expect(sub.contains("back of Blake"), "the race is the story and it stays — got: \(sub)")
  }

  /// The producer's third grain, tested on the producer rather than through
  /// the screen: money survives the rank coming out, and so does the week.
  @Test("seasonLine(rank:) drops only the rank")
  func theProducerHasThreeGrains() {
    let m = membership(buyin: 6000, season: season(starts: "2026-07-13", ends: "2026-10-26", week: 8, of: 15))
    let withRank = SeasonFacts.seasonLine(m, week: true, rank: true, today: "2026-09-07", calendar: cal)
    let without = SeasonFacts.seasonLine(m, week: true, rank: false, today: "2026-09-07", calendar: cal)
    #expect(withRank.contains("2nd of 8"))
    #expect(!without.contains("2nd of 8"))
    #expect(without.contains("Week 8 of 15") && without.contains("back of Blake"))
    #expect(without.contains("on the books"), "the money clause is not collateral damage")
    #expect(!without.contains("· ·") && !without.contains(", ,"), "no orphan separator where the rank was")
  }

  /// A season that has not teed off ranks everybody 1st of N on zero points.
  /// Printing `1ST` over that is a lie in 27pt type.
  @Test("preseason draws no figure")
  func preseasonHasNoStandingToDraw() {
    let m = membership(season: season(starts: "2026-09-18", ends: "2027-03-18", toFirstTee: 11))
    let row = rows(m, today: "2026-09-07").seasons.first
    #expect(row?.rank == nil)
    #expect(row?.sub.contains("First tee") == true, "the sentence is unchanged where the figure is absent")
  }

  /// D138 · through the Final, `rank` is the live table and never the locked
  /// seed. A figure there is the one number a finalist must not be told twice.
  @Test("the Cup Final draws no figure")
  func theCupFinalHasNoFigure() {
    let m = membership(season: season("cup_final", starts: "2026-05-01", ends: "2026-09-28"))
    #expect(rows(m, today: "2026-09-07").seasons.first?.rank == nil)
  }

  /// N4-119 · the row's eyebrow is CUP FINAL, so its sentence says the clock
  /// alone: "Cup Final · 3 weeks left" under it was the phase twice.
  @Test("the Cup Final's row says its phase once")
  func theCupFinalSaysItsPhaseOnce() {
    let m = membership(season: season("cup_final", starts: "2026-05-01", ends: "2026-09-28"))
    let row = rows(m, today: "2026-09-07").seasons.first
    #expect(row?.eyebrow == "CUP FINAL")
    #expect(row?.sub.contains("Cup Final") == false, "got: \(row?.sub ?? "")")
    #expect(row?.sub.hasSuffix("left") == true, "the clock stays — got: \(row?.sub ?? "")")
    // the other grain, for a surface whose eyebrow does not say the stage
    #expect(SeasonFacts.seasonLine(m, today: "2026-09-07", calendar: cal).hasPrefix("Cup Final · "))
    // root's ruling (PAR-03) · the Pro's row is the Final's clock and that they
    // run it, and nothing ranks it: the Final is scored fresh (D138)
    let pro = rows(membership(role: "commissioner", season: season("cup_final", starts: "2026-05-01", ends: "2026-09-28")),
                   today: "2026-09-07").seasons.first
    #expect(pro?.sub.hasSuffix(" left · you run it") == true, "got: \(pro?.sub ?? "")")
    #expect(pro?.rank == nil && pro?.points == nil && pro?.pointsStanding == nil && pro?.competitionLine == nil)
  }

  /// A wrapped season's finish comes from `last_season` — the payload's own
  /// final answer — and is ABSENT rather than guessed when it never sent one.
  @Test("a finished season takes its finish from last_season, or takes none")
  func aWrappedSeasonTakesItsFinish() {
    let ranked = membership(phase: "complete",
                            season: season("complete", starts: "2026-01-05", ends: "2026-07-01"),
                            standing: nil,
                            last: .init(number: 2, ended_on: "2026-07-01", champion_name: "Gray",
                                        champion_is_me: false, my_rank: 3, of: 8))
    #expect(rows(ranked, today: "2026-09-07").finished.first?.rank?.place == 3)
    #expect(rows(ranked, today: "2026-09-07").finished.first?.rank?.of == 8)

    // A squads member's own rank is not a number this payload has (LastSeason's
    // own note), and a v1 payload has none at all.
    let unranked = membership(phase: "complete",
                              season: season("complete", starts: "2026-01-05", ends: "2026-07-01"),
                              standing: nil,
                              last: .init(number: 2, ended_on: "2026-07-01", champion_name: "Gray",
                                          champion_is_me: false, my_rank: nil, of: nil))
    #expect(rows(unranked, today: "2026-09-07").finished.first?.rank == nil)
  }

  /// §7 · do not make every item visually equal. A moment has no standing, so
  /// it carries no figure and is quieter for it.
  @Test("a moment and a weekend carry no figure")
  func onlySeasonsCarryFigures() {
    let e = try? JSONDecoder().decode(Me.Event.self, from: Data("""
      {"id":"C50F0000-0000-4000-8000-000000000050","name":"The Cup","kind":"ryder",
       "status":"live","starts_on":"2026-09-09"}
      """.utf8))
    let me = Me(profile: nil, memberships: [], events: e.map { [$0] } ?? [])
    let list = CompeteRoot.make(me, today: "2026-09-07", calendar: cal)
    #expect(list.moments.count == 1)
    #expect(list.moments.first?.rank == nil)
  }

  /// A season with a standing the server never filled still says something
  /// true, and still draws nothing (L-32/L-44).
  @Test("no standing at all is no figure and no invented sentence")
  func noStandingIsNoFigure() {
    let m = membership(season: season(starts: "2026-07-13", ends: "2026-10-26", week: 8, of: 15),
                       standing: nil)
    let row = rows(m, today: "2026-09-07").seasons.first
    #expect(row?.rank == nil)
    #expect(row?.sub == "Standings start at the first posted round.")
  }
}

/// N4-204 · the Pro's season row says they run it, as the web's does; a
/// player's does not.
@Suite struct CompeteRowProClauseTests {
  @Test func theProReadsThatTheyRunIt() {
    let s = season(starts: "2026-07-13", ends: "2026-10-26", week: 8, of: 15)
    let pro = rows(membership(role: "commissioner", season: s), today: "2026-09-07").seasons.first
    #expect(pro?.sub.hasSuffix(" · you run it") == true, "\(pro?.sub ?? "nil")")
    let player = rows(membership(season: s), today: "2026-09-07").seasons.first
    #expect(player?.sub.contains("you run it") == false, "\(player?.sub ?? "nil")")
  }
}
