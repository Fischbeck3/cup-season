// Cup Season — ONE week producer (D246).
//
// "What week is it" was computed in at least six places across two clients
// with at least two different bases — `snapshot_week` (0-based, day-7 start),
// `open_week_clash`/`home_clash`/`settle` (1-based), `sandbox_week`, the web's
// `weekCloseDate`, the web hero's `+1`, the web's weeks-left `Math.ceil`, and
// `LeagueDates.currentWeek`. The same season could be week 7 on one surface and
// week 6 on another, which is L-44's exact failure and is not fixable by a
// lint: it needs a ruled producer.
//
// From here `native_home.season.week_no` IS the week. The local formula stays
// as the DECLARED FALLBACK for a payload that predates the migration — which
// is the only place either client is still allowed to count weeks.

import Testing
import Foundation
@testable import CupSeasonKit

private func season(starts: String = "2026-07-05", ends: String = "2027-01-03", status: String = "active",
                    week: Int? = nil, weeks: Int? = nil, weekEnds: String? = nil,
                    finalOpens: String? = nil) -> Me.Season {
  Me.Season(id: UUID(), number: 3, starts_on: starts, ends_on: ends, status: status, timezone: "America/Phoenix",
            grace_hours: nil, champion_squad_id: nil, champion_member_id: nil, points_king_member_id: nil,
            tiebreak_rung: nil, week_no: week, weeks_total: weeks, week_ends_on: weekEnds,
            days_to_first_tee: nil, days_left: nil, final_opens_on: finalOpens)
}

@Suite struct WeekProducerTests {

  /// The server's number wins, even when the local formula would disagree —
  /// that disagreement is the whole reason the producer exists.
  @Test func theServersWeekIsTheWeek() {
    let s = season(week: 9, weeks: 26)
    #expect(LeagueDates.week(s, today: "2026-09-08") == 9)
    #expect(LeagueDates.weeksTotal(s) == 26)
    // the local formula, for comparison — it is NOT what rendered
    #expect(LeagueDates.currentWeek(start: s.starts_on, end: s.ends_on, today: "2026-01-01") == 1)
    #expect(LeagueDates.week(s, today: "2026-01-01") == 9)
  }

  /// A payload that predates the migration falls back to the local formula, so
  /// the client renders what it renders today rather than a blank.
  @Test func theDeclaredFallbackIsTheLocalFormula() {
    let s = season()   // v2: no week_no, no weeks_total
    #expect(LeagueDates.week(s, today: "2026-09-08")
              == LeagueDates.currentWeek(start: s.starts_on, end: s.ends_on, today: "2026-09-08"))
    #expect(LeagueDates.weeksTotal(s) == LeagueDates.totalWeeks(start: s.starts_on, end: s.ends_on))
  }

  /// The two agree by construction when the server sends a figure the local
  /// arithmetic would also have produced — the migration moved the formula, it
  /// did not change it.
  @Test func theServerFormulaIsTheLocalFormulaMovedServerSide() {
    let start = "2026-07-05", end = "2027-01-03"
    for today in ["2026-07-05", "2026-07-11", "2026-07-12", "2026-09-08", "2026-12-31", "2027-01-03"] {
      let local = LeagueDates.currentWeek(start: start, end: end, today: today)
      let s = season(starts: start, ends: end, week: local)
      #expect(LeagueDates.week(s, today: today) == local)
    }
  }

  @Test func aZeroOrMissingWeekFallsBackRatherThanRenderingZero() {
    // week 0 is not a week a golfer has ever been in; it is an unset value.
    #expect(LeagueDates.week(season(week: 0), today: "2026-09-08") > 0)
    #expect(LeagueDates.weeksTotal(season(weeks: 0)) > 0)
    #expect(LeagueDates.week(nil) == 1)
  }

  @Test func theWeekClosesOnTheLeaguesOwnWeekday() {
    // The season tees off on a Sunday, so its weeks close on Saturdays.
    let s = season(weekEnds: "2026-09-12")
    #expect(LeagueDates.weekEnds(s, today: "2026-09-08") == "2026-09-12")
    // With no server value the local `weekClose` answers, keyed to starts_on
    // and never to a hardcoded Sunday.
    #expect(LeagueDates.weekEnds(season(), today: "2026-09-08")
              == LeagueDates.weekClose(start: "2026-07-05", today: "2026-09-08"))
  }

  @Test func theFinalOpensWhenTheServerSaysAndNeverOnAPointsTableSeason() {
    #expect(LeagueDates.finalOpens(season(finalOpens: "2026-12-07"), finish: "cup_final") == "2026-12-07")
    // the declared fallback: ends_on − 27
    #expect(LeagueDates.finalOpens(season(), finish: "cup_final")
              == LeagueDates.cupFinalStart(end: "2027-01-03"))
    // a points-table season has no Final to open, and the caller renders nothing
    #expect(LeagueDates.finalOpens(season(), finish: "points_table") == nil)
  }

  /// `standings_snapshots.week_no` is **0-based** (`snapshot_week`). It is
  /// RELABELLED at read time and never recomputed: the snapshot's own number is
  /// the record of which window it captured, and rewriting it would break the
  /// history it is.
  @Test func snapshotWeekIsRelabelledNeverRecomputed() {
    #expect(LeagueDates.snapshotWeekLabel(0) == 1)
    #expect(LeagueDates.snapshotWeekLabel(8) == 9)
    // and the relabel is not the season's week producer — it is a different
    // question about a different row, and the two never substitute
    let s = season(week: 9)
    #expect(LeagueDates.snapshotWeekLabel(0) != LeagueDates.week(s, today: "2026-09-08"))
  }

  /// The phase machine reads the producer, so Home and the Clubhouse cannot
  /// print two different week numbers for one season (the D213 defect, closed).
  @Test func thePhaseMachineReadsTheProducer() {
    let m = Me.Membership(league_id: UUID(), name: "Fellas", code: nil, phase: "season", sandbox: false,
                          role: "member", member_id: UUID(), marker: nil, commissioner_name: nil,
                          settings: nil, season: season(week: 9, weeks: 26), squad: nil, standing: nil, pulse: nil)
    guard case .season(let w, let of) = SeasonPhase.of(m, today: "2026-09-08") else {
      Issue.record("expected a running season"); return
    }
    #expect(w == 9 && of == 26)
  }
}
