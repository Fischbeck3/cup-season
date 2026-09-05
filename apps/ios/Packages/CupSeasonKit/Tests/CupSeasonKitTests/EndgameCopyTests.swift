// Cup Season — the endgame in two pieces (D235, amending D126(2) at UI level).
//
// D126(2) requires the endgame to be a sentence you can always see. It shipped
// as a forty-word paragraph in Home's hero foot, which is why the shipped
// Home's first screenful was a standing and a paragraph. D235 splits it:
//
//   the CLAUSE   — "TOP 2 INTO THE FINAL, OPENS DEC 4" — in the ME strip, on
//                  every Home open, in every state with a season. It survives
//                  a scroll; the hero's paragraph did not.
//   the SENTENCE — the whole of it, permanently under the season page's table,
//                  where the mechanic it describes is.
//
// These are two GRAINS OF ONE FACT (L-34), and this suite is the proof they
// cannot drift: both are produced from the same finish, the same structure and
// the same dates, so they name the same date or neither renders.

import Testing
import Foundation
@testable import CupSeasonKit

private func season(starts: String = "2026-07-05", ends: String = "2027-01-03",
                    status: String = "active", finalOpens: String? = nil) -> Me.Season {
  Me.Season(id: UUID(), number: 1, starts_on: starts, ends_on: ends, status: status, timezone: "America/Phoenix",
            grace_hours: nil, champion_squad_id: nil, champion_member_id: nil, points_king_member_id: nil,
            tiebreak_rung: nil, week_no: 9, weeks_total: 26, week_ends_on: nil,
            days_to_first_tee: nil, days_left: 120, final_opens_on: finalOpens)
}

private func membership(structure: String = "solo", finish: String = "cup_final",
                        of: Int = 8, phase: String = "season",
                        season s: Me.Season? = season()) -> Me.Membership {
  Me.Membership(
    league_id: UUID(), name: "Fellas", code: "ABCD", phase: phase, sandbox: false, role: "member",
    member_id: UUID(), marker: "saguaro", commissioner_name: "Galen Ortiz",
    settings: Me.Settings(structure: structure, preset: nil, counting_cap: 3, participation_floor: 2,
                          floor_penalty: nil, handicap_allowance: 95, buyin_cents: 0,
                          payout_champ: 60, payout_runnerup: 25, payout_king: 15, finish: finish, locked_at: nil),
    season: s, squad: nil,
    standing: Me.Standing(rank: 2, of: of, points: 27, prev_rank: nil, leader_squad_id: nil, leader_points: 31,
                          gap_to_leader: 4, gap_to_next: 4, leader_name: "Galen", runner_up_name: nil,
                          runner_up_points: nil, seed: nil, finalists: nil, next_up: nil, next_down: nil),
    pulse: nil, buy_in: nil, roster: of, members: of, pro_name: "Galen")
}

/// A fixed calendar, so a date in a sentence is the same date on every machine.
private let cal = Calendar(identifier: .gregorian)

@Suite("D235 — the endgame in two pieces")
struct EndgameCopyTests {

  @Test("the clause renders in every state that has a season")
  func clauseAlwaysRenders() {
    for phase in ["season", "draft", "setup"] {
      for status in ["active", "cup_final", "complete"] {
        let m = membership(phase: phase, season: season(status: status))
        #expect(MeStripCopy.endgameClause(m, calendar: cal) != nil,
                "no clause in phase \(phase) / status \(status)")
      }
    }
  }

  @Test("no season, no clause — a fact with no read renders nothing (L-44)")
  func noSeasonNoClause() {
    #expect(MeStripCopy.endgameClause(membership(season: nil), calendar: cal) == nil)
  }

  @Test("the sentence under the table is the whole mechanic, and it ends on §14.3's ladder")
  func theSentence() {
    let m = membership()
    let sentence = SeasonFacts.footEndgame(m, calendar: cal)
    #expect(sentence == "The top 2 golfers go into a four-week Cup Final from Mon Dec 7 — scored fresh, "
                      + "so the weeks before it decide who is in, not who wins. Level on points? Months won breaks it.")
    // D126's own phrase survives; §14.3 is the ladder it names
    #expect(sentence?.contains("scored fresh") == true)
    #expect(sentence?.hasSuffix("Level on points? Months won breaks it.") == true)
  }

  @Test("the clause and the sentence name the SAME date, from the same inputs (L-34)")
  func twoGrainsOneFact() {
    for ends in ["2027-01-03", "2026-12-19", "2026-10-31"] {
      let m = membership(season: season(ends: ends))
      let clause = MeStripCopy.endgameClause(m, calendar: cal)
      let sentence = SeasonFacts.footEndgame(m, calendar: cal)
      let opens = LeagueDates.cupFinalStart(end: ends, calendar: cal)
      #expect(clause?.contains(LeagueDates.monDay(opens, calendar: cal).uppercased()) == true)
      #expect(sentence?.contains(LeagueDates.dowMonDay(opens, calendar: cal)) == true)
    }
  }

  @Test("a points-table season says the points table, in both grains")
  func pointsTable() {
    let m = membership(finish: "points_table")
    #expect(MeStripCopy.endgameClause(m, calendar: cal) == "POINTS TABLE CROWNS IT JAN 3")
    #expect(SeasonFacts.footEndgame(m, calendar: cal)
            == "The points table crowns it on Jan 3 — every round counts to the last day. "
             + "Level on points? Months won breaks it.")
  }

  @Test("SA-3 · at a field of two the clause never says 'top two' — that is a tautology")
  func fieldOfTwo() {
    #expect(MeStripCopy.endgameClause(membership(of: 2), calendar: cal)
            == "A FINAL BETWEEN THE TWO OF YOU, OPENS DEC 7")
    #expect(MeStripCopy.endgameClause(membership(of: 8), calendar: cal)
            == "TOP 2 INTO THE FINAL, OPENS DEC 7")
  }

  @Test("squads2 keeps the leader's head start; every other structure does not claim it")
  func headStart() {
    #expect(SeasonFacts.footEndgame(membership(structure: "squads2"), calendar: cal)?
              .contains("The leader carries +10 in.") == true)
    #expect(SeasonFacts.footEndgame(membership(structure: "squads4"), calendar: cal)?
              .contains("+10") == false)
    #expect(SeasonFacts.footEndgame(membership(structure: "solo"), calendar: cal)?
              .contains("+10") == false)
  }
}
