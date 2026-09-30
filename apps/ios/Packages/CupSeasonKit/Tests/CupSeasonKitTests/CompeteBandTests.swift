// Cup Season — W5's Compete twins (the desk's `csSeasonRowFacts` and
// `csEditionDay`, merged at 4a703402).
//
// The Scoreboard band states a standing, and in a squads season the standing
// is the SQUAD's: it printed "137 points · 2nd · You are 34 back from Fixture
// Javelinas" and never said the 137 was Fixture Wrens'. An upcoming band said
// "not yet" twice and never the day. A finished Ryder read "Final" beside the
// live one of the same name, and said "Final" twice on its own row.

import Testing
import Foundation
@testable import CupSeasonKit

private let cal = Calendar(identifier: .gregorian)

private func season(_ status: String = "active", starts: String, ends: String,
                    week: Int? = nil, of: Int? = nil, toFirstTee: Int? = nil) -> Me.Season {
  Me.Season(id: UUID(), number: 1, starts_on: starts, ends_on: ends, status: status, timezone: nil,
            grace_hours: nil, champion_squad_id: nil, champion_member_id: nil, points_king_member_id: nil,
            tiebreak_rung: nil, week_no: week, weeks_total: of, week_ends_on: nil,
            days_to_first_tee: toFirstTee, days_left: nil, final_opens_on: nil)
}

private func standing(place: Int, of: Int, points: Double, gap: Double?, leader: String?, tied: Bool = false) -> Me.Standing {
  Me.Standing(rank: place, of: of, points: points, prev_rank: place, leader_squad_id: nil, leader_points: nil,
              gap_to_leader: gap, gap_to_next: nil, leader_name: leader, points_rank: place, points_tied: tied)
}

private func member(squad: String? = nil, season s: Me.Season, standing st: Me.Standing?) -> Me.Membership {
  Me.Membership(
    league_id: UUID(), name: "North Grove (fixture)", code: "GROVE", phase: "season", sandbox: false, role: "player",
    member_id: UUID(), marker: "saguaro", commissioner_name: nil,
    settings: Me.Settings(structure: squad == nil ? "solo" : "squads4", preset: nil, counting_cap: 3, participation_floor: 2,
                          floor_penalty: nil, handicap_allowance: 95, buyin_cents: 0,
                          payout_champ: 60, payout_runnerup: 25, payout_king: 15,
                          finish: "cup_final", locked_at: nil),
    season: s, squad: squad.map { Me.Squad(id: UUID(), name: $0, color: 1) }, standing: st, pulse: nil,
    roster: 16, members: 16)
}

private func band(_ m: Me.Membership, today: String) -> CompeteRoot.Row? {
  CompeteRoot.make(Me(profile: nil, memberships: [m]), today: today, calendar: cal).seasons.first
}

private func event(_ status: String, starts: String?) -> Me.Event? {
  let on = starts.map { "\"\($0)\"" } ?? "null"
  return try? JSONDecoder().decode(Me.Event.self, from: Data("""
    {"id":"\(UUID().uuidString)","name":"The North Grove Ryder (fixture)","kind":"ryder",
     "status":"\(status)","starts_on":\(on),"my_team_slot":1}
    """.utf8))
}

@Suite("W5 — the Compete band says whose standing it is, and when")
struct CompeteBandTests {

  /// The panels' own case, word for word: the standing names the side and
  /// the story is the gap, drawn on two lines.
  @Test("a squads band names the side, and the gap loses its 'You are'")
  func aSquadsBandNamesTheSide() {
    let m = member(squad: "Fixture Wrens", season: season(starts: "2026-07-06", ends: "2026-10-18", week: 13, of: 15),
                   standing: standing(place: 2, of: 4, points: 137, gap: 34, leader: "Fixture Javelinas"))
    let row = band(m, today: "2026-09-29")
    #expect(row?.pointsStanding == "Fixture Wrens · 2nd")
    #expect(row?.competitionLine == "34 back of Fixture Javelinas.")
    #expect(row?.points == 137)
  }

  @Test("a tied squad says Tied after its place")
  func aTiedSquadSaysSo() {
    let m = member(squad: "Fixture Wrens", season: season(starts: "2026-07-06", ends: "2026-10-18", week: 13, of: 15),
                   standing: standing(place: 1, of: 4, points: 171, gap: 0, leader: "Fixture Wrens", tied: true))
    let row = band(m, today: "2026-09-29")
    #expect(row?.pointsStanding == "Fixture Wrens · 1st · Tied")
    #expect(row?.competitionLine == "The lead is shared.")
  }

  /// A golfer's own standing is his, so the solo band keeps "You are".
  @Test("a solo band keeps its sentence and names no side")
  func aSoloBandIsTheGolfers() {
    let m = member(season: season(starts: "2026-07-06", ends: "2026-10-18", week: 13, of: 15),
                   standing: standing(place: 3, of: 8, points: 41, gap: 6, leader: "Fixture Quail"))
    let row = band(m, today: "2026-09-29")
    #expect(row?.pointsStanding == "3rd")
    #expect(row?.competitionLine == "You are 6 back of Fixture Quail.")
    let leading = band(member(season: season(starts: "2026-07-06", ends: "2026-10-18", week: 13, of: 15),
                              standing: standing(place: 1, of: 8, points: 47, gap: 0, leader: "Fixture Quail")),
                       today: "2026-09-29")
    #expect(leading?.competitionLine == "You lead the season.")
  }

  /// The upcoming fixture's own date: Oct 5, 2026 is a Monday.
  @Test("an upcoming band says the first tee's day and how far off it is")
  func anUpcomingBandSaysWhen() {
    let week = member(season: season(starts: "2026-10-05", ends: "2027-01-17", toFirstTee: 7), standing: nil)
    #expect(band(week, today: "2026-09-28")?.competitionLine == "The first tee is Mon Oct 5, in 7 days.")
    #expect(band(week, today: "2026-09-28")?.pointsStanding == nil, "a season that has not teed off has no standing")
    let tomorrow = member(season: season(starts: "2026-10-05", ends: "2027-01-17", toFirstTee: 1), standing: nil)
    #expect(band(tomorrow, today: "2026-10-04")?.competitionLine == "The first tee is Mon Oct 5, tomorrow.")
    // no days_to_first_tee on the payload: the calendar counts, and a first
    // tee in another year says its year
    let nextYear = member(season: season(starts: "2027-01-04", ends: "2027-04-05"), standing: nil)
    #expect(band(nextYear, today: "2026-12-20")?.competitionLine == "The first tee is Mon Jan 4, 2027, in 15 days.")
  }

  @Test("a date says its year only when it is not this one")
  func theYearTail() {
    #expect(CompeteRoot.yearTail("2026-08-13", today: "2026-09-29") == "")
    #expect(CompeteRoot.yearTail("2025-08-14", today: "2026-09-29") == ", 2025")
    #expect(CompeteRoot.yearTail("not a date", today: "2026-09-29") == "")
  }

  /// A finished edition is dated by the day it started, and "Final" is said
  /// once on its row — by the sub, which already said it.
  @Test("a finished edition is dated by its day and says Final once")
  func aFinishedEditionIsDated() throws {
    let editions = [event("complete", starts: "2026-08-13"), event("complete", starts: "2025-08-14"),
                    event("complete", starts: nil), event("live", starts: "2026-09-30")].compactMap { $0 }
    #expect(editions.count == 4)
    let list = CompeteRoot.make(Me(profile: nil, memberships: [], events: editions), today: "2026-09-29", calendar: cal)
    #expect(list.finished.map(\.eyebrow) == ["AUG 13", "AUG 14, 2025", "FINAL"])
    let dated = try #require(list.finished.first)
    #expect(dated.sub == "The Ryder · Final")
    let said = "\(dated.eyebrow) \(dated.sub)".lowercased().components(separatedBy: "final").count - 1
    #expect(said == 1, "the state word is said once — got \(dated.eyebrow) / \(dated.sub)")
    // the live edition keeps its day token, unchanged
    #expect(list.moments.first?.eyebrow == "WED SEP 30")
  }
}
