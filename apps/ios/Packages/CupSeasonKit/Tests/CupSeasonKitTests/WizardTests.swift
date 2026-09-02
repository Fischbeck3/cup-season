// Cup Season — the wizard, the lock and draft night, pinned to the web
// client's arithmetic and phrasings (index.html line numbers per suite).

import Testing
import Foundation
@testable import CupSeasonKit

// MARK: presets → dials (PRESETS 8150–8154, PRESET_SUMMARY 7997–8001)

@Suite struct WizardPresetTests {
  /// D142: the ladder is [2, 3, 4, 6, ∞]; Standard counts the best 3, Cutthroat the best 2, Casual everything.
  @Test func presetsSetCapAndFloor() {
    var d = WizardDials()
    d.applyPreset(0)
    #expect(d.cap == 4 && d.floor == 0 && d.capText == "Unlimited" && d.capN == nil)
    d.applyPreset(1)
    #expect(d.cap == 1 && d.floor == 2 && d.capText == "Best 3" && d.capN == 3)
    d.applyPreset(2)
    #expect(d.cap == 0 && d.floor == 3 && d.capText == "Best 2" && d.capN == 2 && d.presetToast == "Cutthroat rules locked for the season")
  }
  @Test func theLadderIsTheWebs() {
    #expect(WizardDials.caps == ["Best 2", "Best 3", "Best 4", "Best 6", "Unlimited"])
    #expect(WizardDials.capVals == [2, 3, 4, 6, nil])
    #expect(WizardDials.presets.map(\.line) == [
      "100% hcp · honor scores · any course · unlimited counting · no floor",
      "95% hcp · post what you'd post to GHIN · best 3 / mo count · 2-round floor",
      "90% hcp · attested where you can · rated tees · best 2 / mo · 3-round floor",
    ])
  }
  /// D206: 13 weeks by default; D142: Standard's Best 3.
  @Test func aRealLeagueStartsAtBraggingRights() {
    let d = WizardDials()
    #expect(d.stake == 0 && d.stakeText == "None" && d.preset == 1 && d.durWeeks == 13 && d.lengthText == "3 mo")
    #expect(d.cap == 1 && d.capText == "Best 3" && d.floor == 2)
  }
  @Test func steppersWalkTheLadders() {
    var d = WizardDials()
    d.stepStake(1); #expect(d.stake == 25)
    d.stepStake(-1); d.stepStake(-1); #expect(d.stake == 0)
    d.stepLength(1); #expect(d.durWeeks == 17)
    d.stepLength(1); d.stepLength(1); #expect(d.durWeeks == 26)
    d.stepLength(1); d.stepLength(1); d.stepLength(1); #expect(d.durWeeks == 52)
    d.stepFloor(1); d.stepFloor(1); d.stepFloor(1); #expect(d.floor == 4)
    d.stepCap(-1); d.stepCap(-1); #expect(d.cap == 0 && d.capText == "Best 2")
    d.stepCap(1); d.stepCap(1); d.stepCap(1); d.stepCap(1); d.stepCap(1); #expect(d.cap == 4 && d.capText == "Unlimited")
  }
  @Test func summaryAndNotesAreTheWebs() {
    var d = WizardDials()
    #expect(d.presetSummaryText.hasPrefix("Standard: 95% handicap, post what you'd post to GHIN, your best 3 a month count"))
    d.applyPreset(2)
    #expect(d.presetSummaryText.contains("attested where you can and the Pro rules on the rest") && d.presetSummaryText.contains("best 2 a month"))
    d.applyPreset(1)
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
    let d = WizardDials()   // D206: 13 weeks
    #expect(d.startDate(today: "2026-08-27") == "2026-08-29" && d.endDate(today: "2026-08-27") == "2026-11-28")
    #expect(d.spanText(today: "2026-08-27") == "Sat Aug 29 – Sat Nov 28")
  }
  /// D143: `season_months` describes the window, 1..12 like the web — never a clamped 3.
  @Test func seasonMonthsDescribesTheWindow() {
    #expect(WizardDials.durMonths(2) == 1 && WizardDials.durMonths(13) == 3 && WizardDials.durMonths(26) == 6 && WizardDials.durMonths(52) == 12)
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

// MARK: the lock call (lockBylaws → lock_league, 17194–17248)

@Suite struct WizardLockCallTests {
  let league = UUID()
  func json(_ c: WizardLockCall) throws -> [String: Any] {
    try JSONSerialization.jsonObject(with: JSONEncoder().encode(c)) as? [String: Any] ?? [:]
  }
  @Test func sendsEveryArgTheWebSends() throws {
    var d = WizardDials()
    d.applyPreset(2); d.stake = 50; d.durWeeks = 13; d.startISO = "2026-09-05"
    d.structure = "squads3"; d.draftType = "assign"; d.finish = "points_table"; d.payout = [50, 30, 20]
    let c = WizardLockCall(d, leagueId: league, name: "PIGL", today: "2026-08-27")
    let j = try json(c)
    #expect(j["p_league"] as? String == league.uuidString.lowercased() || j["p_league"] as? String == league.uuidString)
    #expect(j["p_name"] as? String == "PIGL" && j["p_preset"] as? String == "cutthroat" && j["p_handicap_allowance"] as? Int == 90)
    #expect(j["p_verification"] as? String == "ghin" && j["p_floor_penalty"] as? String == "forfeit")
    #expect(j["p_counting_cap"] as? Int == 2 && j["p_participation_floor"] as? Int == 3 && j["p_buyin_cents"] as? Int == 5000)
    #expect(j["p_season_months"] as? Int == 3)           // 13 weeks say 3, never a clamped minimum
    #expect(j["p_season_format"] as? String == "points")  // the column DEFAULT is 'hybrid' — this turns the +15 off
    #expect(j["p_structure"] as? String == "squads3" && j["p_draft_type"] as? String == "assign" && j["p_finish"] as? String == "points_table")
    #expect(j["p_payout_champ"] as? Int == 50 && j["p_payout_runnerup"] as? Int == 30 && j["p_payout_king"] as? Int == 20)
    #expect(j["p_starts_on"] as? String == "2026-09-05" && j["p_ends_on"] as? String == "2026-12-05")
    #expect(j.count == 19)
  }
  @Test func unlimitedCapIsAnExplicitNull() throws {
    var d = WizardDials()
    d.applyPreset(0)
    let j = try json(WizardLockCall(d, leagueId: league, name: "X"))
    #expect(j.keys.contains("p_counting_cap") && j["p_counting_cap"] is NSNull)
  }
  @Test func aShortPilotSaysOneMonth() throws {
    var d = WizardDials()
    d.durWeeks = 2
    #expect(try json(WizardLockCall(d, leagueId: league, name: "X"))["p_season_months"] as? Int == 1)
  }
  /// The wrapper IS the generated binding by NAME, and drops nothing. The
  /// Kit's retry sheds every droppable arg at once, so a non-empty list here
  /// would let a skew retry lock a league on the SQL defaults and still say
  /// "Bylaws locked" (D206). Every deployed signature since `20260829220000`
  /// carries all eighteen args, so there is nothing to retry into either.
  @Test func theWrapperDropsNothingOnASkewRetry() {
    #expect(WizardLockCall.name == "lock_league" && WizardLockCall.name == Rpc.lock_league.name)
    #expect(WizardLockCall.optionalArgs.isEmpty)
    #expect(Set(WizardLockCall.optionalArgs).isSubset(of: Set(Rpc.lock_league.optionalArgs)))
    #expect(!WizardLockCall.optionalArgs.contains("p_league"))
  }
}

// MARK: applyBylaws (14144–14175) — run it back

@Suite struct WizardApplyBylawsTests {
  @Test func aStoredRowBecomesTheDials() {
    let s = LeagueRoom.Settings(league_id: UUID(), preset: "casual", counting_cap: nil, participation_floor: 0, season_format: nil,
                                buyin_cents: 7500, season_months: 9, structure: "squads2", draft_type: "assign",
                                payout_champ: 70, payout_runnerup: 20, payout_king: 10, finish: "points_table")
    let d = WizardDials.from(s, name: "PIGL · S2")
    #expect(d.name == "PIGL · S2" && d.preset == 0 && d.cap == 4 && d.capText == "Unlimited" && d.floor == 0 && d.stake == 75)
    #expect(d.durWeeks == 39 && d.structure == "squads2" && d.draftType == "assign" && d.finish == "points_table" && d.payout == [70, 20, 10])
  }
  /// D142: a stored cap the ladder does not carry still names its number; the
  /// stepper sits on the nearest rung and a legacy "hybrid" reads as points.
  @Test func aCapOffTheLadderKeepsItsNumber() {
    let s = LeagueRoom.Settings(league_id: UUID(), preset: "standard", counting_cap: 5, season_format: "hybrid")
    let b = Bylaws.from(s)
    #expect(b.cap == 5 && b.capN == 5 && b.capLabel == "Best 5" && b.capIdx == 2 && b.fmtIdx == 0)
    #expect(Bylaws.fmtNames[b.fmtIdx] == "Points Race" && Bylaws.fmtNames.count == 2)
    let d = WizardDials.from(s, name: "X")
    #expect(d.cap == 2 && d.capText == "Best 4")   // the wizard can only offer its rungs
    #expect(Bylaws.from(LeagueRoom.Settings(league_id: UUID(), counting_cap: 3)).capIdx == 1)
    #expect(Bylaws.from(nil).cap == 3 && Bylaws.from(nil).capLabel == "Best 3")
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
  /// P-11: "live" only once first tee has come; a solo league locked ahead names the tee.
  @Test func liveOnlyOnceFirstTeeHasCome() {
    #expect(WizardCopy.lockShareLine(nextPhase: "season", members: 1, structure: "solo", draftType: "random", startsOn: "2026-09-05", today: "2026-08-27")
            == "First tee Sat Sep 5 — every golfer you add posts from day one.")
    #expect(WizardCopy.lockShareLine(nextPhase: "season", members: 1, structure: "solo", draftType: "random", startsOn: "2026-08-27", today: "2026-08-27")
            == "Season is live — every golfer you add posts from day one.")
    #expect(WizardCopy.lockShareLine(nextPhase: "season", members: 3, structure: "solo", draftType: "random", startsOn: "2026-08-01", today: "2026-08-27")
            == "Season is live — every golfer you add posts from day one.")
  }
  /// D205: every minimum derives from `structMin`; a solo league forms no squads.
  @Test func theReviewStepSpeaksBothMinimums() {
    #expect(WizardCopy.inviteNote == "Lock opens the invite link — one link fills the league. The code works until first tee, or until you close the roster. Squads need four to tee off; solo tees off at two.")
    #expect(WizardCopy.lockButton(solo: true) == "Lock the bylaws" && WizardCopy.lockButton(solo: false) == "Lock the bylaws & form the squads")
    #expect(WizardDials.structNotes["solo"]?.hasPrefix("Individual · every player for himself — works at any size (2+).") == true)
    #expect(WizardCopy.verificationNote == "Verification is a norm the league holds, not a filter the engine applies.")
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
    // D205 · four is the tee-off minimum for EVERY squad count — `start_season`
    // raises on `total < 4` whatever the structure, so a 3- or 4-squad league
    // is clear at four and the phone must not invent six or eight.
    let seat = { LeagueRoom.Squad(id: UUID(), name: "Squad", color: 0, squad_members: [.init(member_id: UUID())]) }
    let three = [seat(), seat(), seat()], four = three + [seat()]
    #expect(DraftCopy.startBlocker(members: 4, pool: 0, squads: three, solo: false) == nil)
    #expect(DraftCopy.startBlocker(members: 4, pool: 0, squads: four, solo: false) == nil)
    #expect(DraftCopy.startBlocker(members: 3, pool: 0, squads: three, solo: false) == "Minimum four to tee off — 3 in so far. Share the invite link.")
  }
  @Test func formationCopy() {
    #expect(DraftCopy.eyebrow("assign") == "Form squads · Pro assign" && DraftCopy.eyebrow("random") == "Form squads · blind draw")
    #expect(DraftCopy.formN(pool: 3) == "3 in the pool" && DraftCopy.formN(pool: 0) == "Everyone has a squad")
    #expect(DraftCopy.lockTheirs("Logan") == "Logan is picking: only their account can select")
    #expect(DraftCopy.proPicked("Ed", for: "Logan") == "Pro picked Ed for Logan, logged")
  }
}
