import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct AuthRulesTests {
  @Test func codesAreEightDigits() {
    #expect(AuthRules.otpLength == 8)
    #expect(AuthRules.normalizeCode("1234 5678") == "12345678")
    #expect(AuthRules.normalizeCode("12‑34‑56‑78‑90") == "12345678")   // non-breaking hyphens from a mail client, truncated to 8
    #expect(AuthRules.isCompleteCode("1234567") == false)
    #expect(AuthRules.isCompleteCode("12345678") == true)
  }

  @Test func emailShape() {
    #expect(AuthRules.looksLikeEmail("  Jerecho@Example.com ") == true)
    #expect(AuthRules.normalizeEmail("  Jerecho@Example.com ") == "jerecho@example.com")
    #expect(AuthRules.looksLikeEmail("@nope") == false)
    #expect(AuthRules.looksLikeEmail("nope@") == false)
    #expect(AuthRules.isReviewer("Reviewer@CupSeason.app"))
  }

  @Test func resendIsTheUsualCauseOfInvalid() {
    struct E: LocalizedError { var errorDescription: String? { "Token has expired or is invalid" } }
    #expect(AuthRules.human(E()).contains("newest email"))
  }
}

@Suite struct DateTests {
  @Test func calendarDatesNeverGoThroughUTC() {
    // Phoenix has no DST; a date built by parts is local midnight, so its ISO form round-trips
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "America/Phoenix")!
    let d = CSDate.local("2026-08-27", calendar: cal)!
    #expect(CSDate.iso(d, calendar: cal) == "2026-08-27")
    #expect(CSDate.days(from: "2026-08-01", to: "2026-08-27", calendar: cal) == 26)
  }
}

@Suite struct PhaseTests {
  func membership(phase: String, status: String?, starts: String, ends: String) -> Me.Membership {
    let season = status.map { Me.Season(id: UUID(), number: 1, starts_on: starts, ends_on: ends, status: $0, timezone: nil, grace_hours: nil,
                                        champion_squad_id: nil, champion_member_id: nil, points_king_member_id: nil, tiebreak_rung: nil) }
    return Me.Membership(league_id: UUID(), name: "PIGL", code: "ABC", phase: phase, sandbox: false, role: "player", member_id: UUID(), marker: "saguaro",
                         commissioner_name: nil, settings: nil, season: season, squad: nil, standing: nil, pulse: nil)
  }

  @Test func cupFinalComesFromSeasonStatusNotDates() {
    // the engine flipped status; dates alone would still say "season"
    let m = membership(phase: "season", status: "cup_final", starts: "2026-05-03", ends: "2026-09-26")
    if case .cupFinal = SeasonPhase.of(m, today: "2026-08-27") {} else { Issue.record("expected cupFinal") }
  }

  @Test func aLeagueStuckInDraftIsFormingEvenWithAnActiveSeasonRow() {
    let m = membership(phase: "draft", status: "active", starts: "2026-05-03", ends: "2026-09-26")
    #expect(SeasonPhase.of(m, today: "2026-08-27") == .forming)
  }

  @Test func weekNumbering() {
    let m = membership(phase: "season", status: "active", starts: "2026-05-03", ends: "2026-09-26")
    #expect(SeasonPhase.of(m, today: "2026-05-03") == .season(week: 1, of: 21))
    #expect(SeasonPhase.of(m, today: "2026-05-10") == .season(week: 2, of: 21))
    #expect(SeasonPhase.of(m, today: "2026-04-30") == .preseason)
  }

  @Test func indexCopy() {
    #expect(CSCopy.index(nil) == "—")
    #expect(CSCopy.index(12.4) == "12.4")
    #expect(CSCopy.index(-1.2) == "+1.2")
    #expect(CSCopy.ordinal(1) == "1st" && CSCopy.ordinal(2) == "2nd" && CSCopy.ordinal(3) == "3rd" && CSCopy.ordinal(4) == "4th")
    #expect(CSCopy.ordinal(11) == "11th" && CSCopy.ordinal(12) == "12th" && CSCopy.ordinal(21) == "21st")
    #expect(CSCopy.dollars(cents: 7500) == "$75" && CSCopy.dollars(cents: 7550) == "$75.50")
  }
}
