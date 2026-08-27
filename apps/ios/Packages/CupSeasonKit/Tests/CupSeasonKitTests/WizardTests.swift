// Cup Season — the wizard, the lock and draft night, pinned to the web
// client's arithmetic and phrasings (index.html line numbers per suite).

import Testing
import Foundation
@testable import CupSeasonKit

// MARK: presets → dials (7157–7172, PRESET_SUMMARY 7052)

@Suite struct WizardPresetTests {
  @Test func presetsSetCapAndFloor() {
    var d = WizardDials()
    d.applyPreset(0)
    #expect(d.cap == 3 && d.floor == 0 && d.capText == "Unlimited" && d.capN == nil)
    d.applyPreset(1)
    #expect(d.cap == 1 && d.floor == 2 && d.capText == "Best 4" && d.capN == 4)
    d.applyPreset(2)
    #expect(d.cap == 1 && d.floor == 3 && d.presetToast == "Cutthroat rules locked for the season")
  }
  @Test func aRealLeagueStartsAtBraggingRights() {
    let d = WizardDials()
    #expect(d.stake == 0 && d.stakeText == "None" && d.preset == 1 && d.durWeeks == 26)
  }
  @Test func steppersWalkTheLadders() {
    var d = WizardDials()
    d.stepStake(1); #expect(d.stake == 25)
    d.stepStake(-1); d.stepStake(-1); #expect(d.stake == 0)
    d.stepLength(1); #expect(d.durWeeks == 39)
    d.stepLength(1); d.stepLength(1); #expect(d.durWeeks == 52)
    d.stepFloor(1); d.stepFloor(1); d.stepFloor(1); #expect(d.floor == 4)
    d.stepCap(-1); d.stepCap(-1); #expect(d.cap == 0 && d.capText == "Best 2")
  }
  @Test func summaryAndNotesAreTheWebs() {
    var d = WizardDials()
    #expect(d.presetSummaryText.hasPrefix("Standard: 95% handicap"))
    d.payout = [70, 20, 10]
    #expect(d.payNote == "Winner-heavy: champ 70% · runner-up 20% · Points King 10%.")
    d.finish = "points_table"
    #expect(d.finishNote.hasPrefix("Points table: whoever leads"))
    d.draftType = "assign"
    #expect(d.draftNote.hasPrefix("Assign: no draw."))
  }
}

// MARK: roster fit (11812–11835)

@Suite struct WizardRosterFitTests {
  @Test func oneGolferFitsSoloOnly() {
    #expect(WizardDials.structFitLine(roster: 1) == "1 golfer staged — solo fits. Bigger squads open up as more join, by code or invite.")
    #expect(WizardDials.structToast("squads4", roster: 1) == "4 squads plays best at 8+ — fine if more join by code")
    // the web toasts solo too (STRUCT_MIN.solo = 2): guidance, never a block
    #expect(WizardDials.structToast("solo", roster: 1) == "Individual — no squads plays best at 2+ — fine if more join by code")
  }
  @Test func sixGolfersFitUpToThree() {
    #expect(WizardDials.structFitLine(roster: 6) == "6 golfers staged — solo or up to 3 squads fit. Bigger squads open up as more join, by code or invite.")
    #expect(WizardDials.fits("squads3", roster: 6) && !WizardDials.fits("squads4", roster: 6))
    #expect(WizardDials.structToast("squads2", roster: 6) == nil)
  }
}

// MARK: the portrait (11847–11890)

@Suite struct WizardPortraitTests {
  @Test func potIsStakeTimesRoster() {
    var d = WizardDials(name: " The Big Slice ")
    d.stake = 75; d.structure = "squads4"; d.payout = [60, 25, 15]
    let p = WizardPortrait(d, roster: 3)
    #expect(p.name == "The Big Slice" && p.pot == 225 && p.squads == 4)
    #expect(p.structLine == "4 SQUADS · BLIND DRAW")
    #expect(p.potSub == "$75 / player · 3 in so far · 60/25/15")
    #expect(zip(p.bar, [81.6, 34.0, 20.4]).allSatisfy { abs($0 - $1) < 0.001 })
  }
  @Test func braggingRightsAndTheSeasonBand() {
    var d = WizardDials()
    d.structure = "solo"; d.durWeeks = 26
    let p = WizardPortrait(d, roster: 1)
    #expect(p.stake == 0 && p.structLine == "SOLO · EVERY PLAYER" && p.months == 6 && p.canCup && p.seasonTail == "6 mo")
    d.durWeeks = 4; d.finish = "points_table"
    let q = WizardPortrait(d, roster: 1)
    #expect(q.months == 1 && !q.canCup && q.seasonTail == "4 wk · POINTS TABLE")
  }
}

// MARK: season dates (7081–7099): whole weeks, the REAL weekday

@Suite struct WizardSeasonDateTests {
  @Test func defaultStartIsTheNextSaturdayNeverToday() {
    #expect(WizardDials.defaultStart(today: "2026-08-27") == "2026-08-29")   // a Thursday
    #expect(WizardDials.defaultStart(today: "2026-08-29") == "2026-09-05")   // a Saturday → next week
    #expect(WizardDials.defaultStart(today: "2026-08-30") == "2026-09-05")   // a Sunday
  }
  @Test func endIsStartPlusWholeWeeksSameWeekday() {
    var d = WizardDials()
    d.startISO = "2026-09-09"; d.durWeeks = 6   // a Wednesday
    #expect(d.endDate() == "2026-10-21")
    #expect(d.spanText() == "Wed Sep 9 – Wed Oct 21")
    #expect(d.startDate(today: "2026-08-27") == "2026-09-09")
  }
  @Test func untouchedStartFollowsTheDefault() {
    let d = WizardDials()
    #expect(d.startDate(today: "2026-08-27") == "2026-08-29" && d.endDate(today: "2026-08-27") == "2027-02-27")
    #expect(d.spanText(today: "2026-08-27") == "Sat Aug 29 – Sat Feb 27")
  }
  @Test func seasonMonthsIsClampedForTheCheckConstraint() {
    #expect(WizardDials.durMonths(2) == 3 && WizardDials.durMonths(26) == 6 && WizardDials.durMonths(52) == 12)
  }
  @Test func bylawsRowsRideThePreviewDates() {
    var d = WizardDials()
    d.startISO = "2026-09-05"; d.durWeeks = 26
    let rows = d.bylawsRows(today: "2026-08-27")
    #expect(rows.first { $0.k == "SEASON" }?.v == "6 mo · Sat Sep 5 → Sat Mar 6 · 26 wks")
    #expect(rows.first { $0.k == "CUP FINAL" }?.v == "Final 4 weeks · from Sun Feb 7 · scored fresh")
    #expect(rows.first { $0.k == "BUY-IN" }?.v == "None · bragging rights")
  }
}

// MARK: the code (12815)

@Suite struct WizardCodeTests {
  @Test func fourLettersThenFourRandom() {
    #expect(WizardCode.codeFor("The Big Slice", random: { "Q7Z2" }) == "THEBQ7Z2")
    #expect(WizardCode.codeFor("Dew Sweepers '26", random: { "AAAA" }) == "DEWSAAAA")
    #expect(WizardCode.codeFor("123 !!", random: { "K9K9" }) == "CUPK9K9")
    #expect(WizardCode.codeFor("ab", random: { "XXXX" }) == "ABXXXX")
  }
  @Test func randomTailIsFourBase36() {
    let c = WizardCode.codeFor("Sunday Cup")
    #expect(c.count == 8 && c.hasPrefix("SUND") && c.allSatisfy { $0.isNumber || ($0.isLetter && $0.isUppercase) })
  }
}

// MARK: the lock payload (14888–14923)

@Suite struct WizardLockPayloadTests {
  @Test func writesEveryColumnTheWebWrites() throws {
    var d = WizardDials()
    d.applyPreset(2); d.stake = 50; d.durWeeks = 13; d.structure = "squads3"; d.draftType = "assign"; d.finish = "points_table"; d.payout = [50, 30, 20]
    let p = WizardLockPayload(d, lockedAt: "2026-08-27T12:00:00Z")
    #expect(p.preset == "cutthroat" && p.handicap_allowance == 90 && p.verification == "ghin" && p.floor_penalty == "forfeit")
    #expect(p.counting_cap == 4 && p.participation_floor == 3 && p.buyin_cents == 5000 && p.season_months == 3)
    #expect(p.season_format == "points")           // the column DEFAULT is 'hybrid' — this write turns the +15 off
    #expect(p.structure == "squads3" && p.draft_type == "assign" && p.finish == "points_table")
    #expect(p.payout_champ == 50 && p.payout_runnerup == 30 && p.payout_king == 20 && p.locked_at == "2026-08-27T12:00:00Z")
    let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(p)) as? [String: Any]
    #expect(json?["finish"] as? String == "points_table" && json?["counting_cap"] as? Int == 4)
  }
  @Test func unlimitedCapIsAnExplicitNull() throws {
    var d = WizardDials()
    d.applyPreset(0)
    let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(WizardLockPayload(d, lockedAt: "x"))) as? [String: Any]
    #expect(json?.keys.contains("counting_cap") == true && json?["counting_cap"] is NSNull)
  }
  @Test func theSkewRetryDropsFinishOnly() throws {
    let d = WizardDials()
    let p = WizardLockPayload(d, lockedAt: "x").withoutFinish
    let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(p)) as? [String: Any]
    #expect(json?["finish"] == nil && json?["draft_type"] as? String == "random" && json?["buyin_cents"] as? Int == 0)
  }
}

// MARK: applyBylaws (14144–14175) — run it back

@Suite struct WizardApplyBylawsTests {
  @Test func aStoredRowBecomesTheDials() {
    let s = LeagueRoom.Settings(league_id: UUID(), preset: "casual", counting_cap: nil, participation_floor: 0, season_format: nil,
                                buyin_cents: 7500, season_months: 9, structure: "squads2", draft_type: "assign",
                                payout_champ: 70, payout_runnerup: 20, payout_king: 10, finish: "points_table")
    let d = WizardDials.from(s, name: "PIGL · S2")
    #expect(d.name == "PIGL · S2" && d.preset == 0 && d.cap == 3 && d.floor == 0 && d.stake == 75)
    #expect(d.durWeeks == 39 && d.structure == "squads2" && d.draftType == "assign" && d.finish == "points_table" && d.payout == [70, 20, 10])
  }
  @Test func aSeasonRowPinsTheRealSpan() {
    let s = LeagueRoom.Settings(league_id: UUID(), season_months: 6)
    let d = WizardDials.from(s, name: "X", season: LeagueRoom.Season(id: UUID(), starts_on: "2026-09-05", ends_on: "2027-03-06", status: "active"))
    #expect(d.durWeeks == 26 && d.startISO == "2026-09-05")
  }
  @Test func runBackNameStripsAnOldSuffix() {
    #expect(WizardCopy.runBackName("PIGL") == "PIGL · S2")
    #expect(WizardCopy.runBackName("PIGL · S3") == "PIGL · S2")
    #expect(WizardCopy.runBackName("") == "Your league · S2")
    #expect(WizardCopy.isUnnamed("My Cup") && WizardCopy.isUnnamed("  ") && !WizardCopy.isUnnamed("PIGL"))
  }
}

// MARK: the lock share line (13946–13951)

@Suite struct WizardLockShareTests {
  @Test func seatMathFromTheStructure() {
    #expect(WizardCopy.lockShareLine(nextPhase: "draft", members: 1, structure: "squads4", draftType: "random")
            == "1 in so far — 7 more fills 4 squads, and the draw runs when the crew is in.")
    #expect(WizardCopy.lockShareLine(nextPhase: "draft", members: 5, structure: "squads2", draftType: "assign")
            == "5 in — enough for 2 squads. Seat the squads whenever you're ready.")
    #expect(WizardCopy.lockShareLine(nextPhase: "season", members: 1, structure: "solo", draftType: "random")
            == "Season is live — every golfer you add posts from day one.")
    #expect(WizardCopy.inviteURL("ABCD1234")?.absoluteString == "https://cupseason.app/?join=ABCD1234")
  }
}

// MARK: draft night — the snake (make_pick's arithmetic) and the pre-tap blockers

@Suite struct DraftSnakeTests {
  let order = [UUID(), UUID(), UUID(), UUID()]
  @Test func evenRoundsReverse() {
    #expect(DraftSnake.squadOnClock(pick: 0, order: order) == order[0])
    #expect(DraftSnake.squadOnClock(pick: 3, order: order) == order[3])
    #expect(DraftSnake.squadOnClock(pick: 4, order: order) == order[3])
    #expect(DraftSnake.squadOnClock(pick: 7, order: order) == order[0])
    #expect(DraftSnake.squadOnClock(pick: 8, order: order) == order[0])
    #expect(DraftSnake.squadOnClock(pick: 0, order: []) == nil)
  }
  @Test func roundAndPickLabels() {
    let l = DraftSnake.label(pick: 5, squads: 4)
    #expect(l.round == 2 && l.pick == 2 && DraftCopy.clockM(round: 2, pick: 2, of: 4, squad: "Squad 3") == "R2 · PICK 2/4 · SQUAD 3")
    #expect(DraftSnake.total(squads: 4, rounds: 3) == 12)
    let d = DraftRow(id: UUID(), season_id: UUID(), type: "snake", status: "live", rounds_count: 3, order_squads: order, current_pick: 12)
    #expect(DraftSnake.done(d))
  }
  @Test func startBlockersSayWhatTheServerWillSay() {
    let empty = LeagueRoom.Squad(id: UUID(), name: "Squad 2", color: 1)
    let full = LeagueRoom.Squad(id: UUID(), name: "Squad 1", color: 0, squad_members: [.init(member_id: UUID())])
    #expect(DraftCopy.startBlocker(members: 3, pool: 0, squads: [full], solo: false) == "Minimum four to tee off — 3 in so far. Share the invite link.")
    #expect(DraftCopy.startBlocker(members: 5, pool: 2, squads: [full], solo: false) == "2 golfer(s) still in the pool — everyone needs a squad before the first tee")
    #expect(DraftCopy.startBlocker(members: 5, pool: 0, squads: [full, empty], solo: false) == "Squad 2 is empty — draw again or assign somebody before the season starts")
    #expect(DraftCopy.startBlocker(members: 5, pool: 0, squads: [full], solo: false) == nil)
    #expect(DraftCopy.startBlocker(members: 1, pool: 0, squads: [], solo: true) == nil)
  }
  @Test func formationCopy() {
    #expect(DraftCopy.eyebrow("assign") == "Form squads · Pro assign" && DraftCopy.eyebrow("random") == "Form squads · blind draw")
    #expect(DraftCopy.formN(pool: 3) == "3 in the pool" && DraftCopy.formN(pool: 0) == "Everyone has a squad")
    #expect(DraftCopy.lockTheirs("Logan") == "Logan is picking: only their account can select")
    #expect(DraftCopy.proPicked("Ed", for: "Logan") == "Pro picked Ed for Logan, logged")
  }
}
