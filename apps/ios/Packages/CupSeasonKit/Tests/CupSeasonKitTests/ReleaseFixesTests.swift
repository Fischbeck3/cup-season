import Testing
import Foundation
@testable import CupSeasonKit

/// D353 · the covenant says the allowance and the whole counting rule.
@Suite struct CovenantAllowanceTests {
  @Test func theAllowanceIsSaidInTheWizardsOwnWords() {
    let c = Covenant(name: "the Fellas", buyinCents: 0, preset: "standard", floor: 2, finish: nil,
                     countingCap: 3, handicapAllowance: 95)
    // D373 · the same sentence the web pins (tests/app-tests.js "D373: the allowance clause says what it does")
    #expect(c.rulesLine == "Standard rules: honest scores, best three a month count, two a month keeps you in, scored against your playing HCP — your index at 95 percent.")
  }

  @Test func unlimitedIsSaidOffTheRealBooleanNeverOffAnAbsentKey() {
    // an older server: no cap key, no boolean — nothing is claimed either way
    let old = Covenant(name: "x", buyinCents: 0, preset: nil, floor: 0, finish: nil)
    #expect(old.rulesLine == "The rules: honest scores.")
    // the new server, Unlimited
    let unl = Covenant(name: "x", buyinCents: 0, preset: "casual", floor: 0, finish: nil, countingCap: nil, everyRoundCounts: true)
    #expect(unl.rulesLine == "Casual rules: honest scores, every round counts.")
    // the new server, a cap: the boolean is false and the cap wins
    let capped = Covenant(name: "x", buyinCents: 0, preset: nil, floor: 0, finish: nil, countingCap: 2, everyRoundCounts: false)
    #expect(capped.rulesLine == "The rules: honest scores, best two a month count.")
  }

  @Test func theTwoFactsDecodeFromThePayload() throws {
    let json: JSONValue = .object(["name": .string("PIGL"), "buyin_cents": .number(0), "floor": .number(2),
                                   "counting_cap": .null, "every_round_counts": .bool(true),
                                   "handicap_allowance": .number(90), "ends_on": .string("2026-12-12")])
    let c = try #require(Covenant(json))
    #expect(c.everyRoundCounts == true && c.countingCap == nil && c.handicapAllowance == 90 && c.endsOn == "2026-12-12")
    // an older payload leaves both nil
    let old = try #require(Covenant(.object(["name": .string("PIGL")])))
    #expect(old.everyRoundCounts == nil && old.handicapAllowance == nil)
  }
}

/// D355 · the durable create record, owner-scoped, frozen until the season starts.
@Suite struct PendingCreateTests {
  @Test func theRecordRoundTripsEveryChoice() throws {
    let name = "pending-create-\(UUID())"
    let d = UserDefaults(suiteName: name)!
    defer { d.removePersistentDomain(forName: name) }
    let owner = UUID(), request = UUID()
    var dials = WizardDials(name: "The Fellas", stake: 50, durWeeks: 17, structure: "squads3")
    dials.capExact = 5; dials.cap = Bylaws.capIndex(5); dials.buyInNote = "Venmo @fixture"; dials.invitees = [UUID(), UUID()]
    dials.expectedRoster = 9
    let created = WizardService.Created(leagueId: UUID(), name: "The Fellas", code: "FELLAS26", memberId: UUID())
    try PendingCreate.write(PendingCreate(request: request, dials: dials, squadsChosen: true, created: created), owner: owner, defaults: d)
    let back = try #require(PendingCreate.read(owner: owner, defaults: d))
    #expect(back.request == request, "the SAME request id, so the replay is the same league")
    #expect(back.dials == dials, "every dial, the off-ladder exact cap and the pay note included")
    #expect(back.dials.capN == 5 && back.dials.structure == "squads3" && back.squadsChosen == true)
    #expect(back.created == created)
  }

  @Test func theRecordIsOwnerScopedAndClearsOnce() throws {
    let name = "pending-create-\(UUID())"
    let d = UserDefaults(suiteName: name)!
    defer { d.removePersistentDomain(forName: name) }
    let a = UUID(), b = UUID()
    try PendingCreate.write(PendingCreate(request: UUID(), dials: WizardDials(name: "A"), squadsChosen: nil), owner: a, defaults: d)
    #expect(PendingCreate.read(owner: b, defaults: d) == nil, "another golfer on this phone resumes nothing")
    PendingCreate.clear(owner: b, defaults: d)
    #expect(PendingCreate.read(owner: a, defaults: d) != nil, "and cannot clear somebody else's")
    PendingCreate.clear(owner: a, defaults: d)
    #expect(PendingCreate.read(owner: a, defaults: d) == nil)
  }

  @Test func anExplicitUnlimitedSurvivesTheRecord() throws {
    let name = "pending-create-\(UUID())"
    let d = UserDefaults(suiteName: name)!
    defer { d.removePersistentDomain(forName: name) }
    var dials = WizardDials(name: "Casual crew")
    dials.applyPreset(0)   // Casual · every round counts
    #expect(dials.capN == nil)
    let owner = UUID()
    try PendingCreate.write(PendingCreate(request: UUID(), dials: dials, squadsChosen: nil), owner: owner, defaults: d)
    #expect(try #require(PendingCreate.read(owner: owner, defaults: d)).dials.capN == nil, "Unlimited means Unlimited after a relaunch")
  }
}

/// D354 · the month sentence says the waiver and the bye only off the payload.
@Suite struct MonthWaiverCopyTests {
  private func clock(_ today: String) -> RoomClock {
    RoomClock(phase: .season, startsOn: "2026-05-03", endsOn: "2026-12-26", status: "active", finish: "cup_final", today: today)
  }
  private let b = Bylaws(floor: 2, cap: 4)

  @Test func aGolferWhoJoinedThisMonthIsToldTheMinimumIsWaived() {
    let t = LeagueCopy.nextUp(clock("2026-09-13"), b: b, credits: 0, partial: false, joinedThisMonth: true, byeAvailable: true).text
    #expect(t == "You joined this month, so there's no minimum to clear until October. Your best 4 each month count.")
    #expect(!t.contains("more toward"), "no figure to chase in a month close_month will waive")
    #expect(!t.contains("bye"), "the bye is not spent in a waived month, so it is not mentioned")
  }

  @Test func theByeIsSaidOnlyWhileAMinimumIsOwedAndOnlyOffThePayload() {
    let owed = LeagueCopy.nextUp(clock("2026-09-13"), b: b, credits: 1, partial: false, joinedThisMonth: false, byeAvailable: true).text
    #expect(owed.hasSuffix(LeagueCopy.byeStillThere))
    let used = LeagueCopy.nextUp(clock("2026-09-13"), b: b, credits: 1, partial: false, joinedThisMonth: false, byeAvailable: false).text
    #expect(used.hasSuffix(LeagueCopy.byeUsed))
    // an older server: neither fact, and the sentence is exactly D352's
    let old = LeagueCopy.nextUp(clock("2026-09-13"), b: b, credits: 1, partial: false).text
    #expect(old == "1 more toward September's minimum of 2 — you're at 1. Your best 4 each month count.")
    // met: nothing about the bye either way
    let met = LeagueCopy.nextUp(clock("2026-09-13"), b: b, credits: 2, partial: false, joinedThisMonth: false, byeAvailable: false).text
    #expect(!met.contains("bye"))
  }

  @Test func noMinimumAndAShortMonthOutrankTheWaiver() {
    let free = LeagueCopy.nextUp(clock("2026-09-13"), b: Bylaws(floor: 0, cap: 4), credits: 0, partial: false, joinedThisMonth: true, byeAvailable: true).text
    #expect(!free.lowercased().contains("minimum") && !free.contains("bye"))
    let short = LeagueCopy.nextUp(clock("2026-09-13"), b: b, credits: 0, partial: true, joinedThisMonth: true, byeAvailable: true).text
    #expect(short.hasPrefix("September is a short month"))
  }

  @Test func theNextMonthRollsTheYear() {
    #expect(LeagueCopy.nextMonthLong("2026-12-13") == "January")
    #expect(LeagueCopy.nextMonthLong("2026-09-13") == "October")
  }

  @Test func theExtendedRowDecodesWithAndWithoutTheNewColumns() throws {
    let new = try JSONDecoder().decode(LeaguePulseRow.self, from: Data(#"{"profile_id":null,"credits":1.5,"floor":2,"at_floor":false,"is_me":true,"partial":false,"joined_this_month":true,"bye_available":false}"#.utf8))
    #expect(new.joined_this_month == true && new.bye_available == false && new.credits == 1.5)
    let old = try JSONDecoder().decode(LeaguePulseRow.self, from: Data(#"{"credits":1,"floor":2,"at_floor":false,"is_me":true,"partial":false}"#.utf8))
    #expect(old.joined_this_month == nil && old.bye_available == nil, "an older server claims neither")
  }
}

/// D356 · an event invitation says what it is and what it costs, or nothing.
@Suite struct EventInviteTermsTests {
  @Test func aMajorWithAStakeSaysTheStakeAndTheLedger() {
    let i = Invite(id: UUID(), kind: "event", containerId: UUID(), containerName: "The Bloom", inviter: "Galen",
                   startsOn: "2026-10-03", eventKind: "major", buyIn: 25)
    #expect(i.title == "Major invite" && i.isMajor)
    // D357 · a Major's window is two to four days, never a week.
    #expect(i.eventTerms == ["A Major — a short window, one card, the best round takes it.",
                             "First tee Sat Oct 3.", "$25 each.", MoneyCopy.ledger])
  }
  @Test func aFreeRyderSaysNoBuyInAndNoLedger() {
    let i = Invite(id: UUID(), kind: "event", containerId: UUID(), containerName: "Desert Ryder", inviter: "Galen",
                   startsOn: nil, eventKind: "ryder", buyIn: 0)
    #expect(i.eventTerms == ["A Ryder — two teams, one clash each week.", "No buy-in."])
    #expect(!i.eventTerms.contains(MoneyCopy.ledger), "the ledger line is above $0 only")
  }
  @Test func anOlderServerGivesNoTermsAndThereforeNoDoor() {
    let i = Invite(id: UUID(), kind: "event", containerId: UUID(), containerName: "The Bloom", inviter: "Galen", startsOn: "2026-10-03")
    #expect(i.eventTerms.isEmpty && i.stakeLine == nil && i.title == "Invite")
  }
  @Test func theExtendedRowDecodesWithAndWithoutTheNewColumns() throws {
    let new = try JSONDecoder().decode(InviteRow.self, from: Data(#"{"id":"\#(UUID().uuidString)","kind":"event","container_id":null,"container_name":"The Bloom","inviter":"Galen","starts_on":"2026-10-03","event_kind":"major","buy_in":25}"#.utf8))
    #expect(Invite(new)?.eventKind == "major" && Invite(new)?.buyIn == 25)
    let old = try JSONDecoder().decode(InviteRow.self, from: Data(#"{"id":"\#(UUID().uuidString)","kind":"event","container_name":"The Bloom","inviter":"Galen"}"#.utf8))
    #expect(Invite(old)?.eventKind == nil && Invite(old)?.eventTerms.isEmpty == true)
  }
}

/// D354 (amended) · Home's own producers read the month facts off `native_home`.
@Suite struct HomeMonthFactsTests {
  @Test func theFootAndTheMonthRowSayTheWaiverOnlyOffThePayload() {
    let joined = heroMembership(structure: "squads2", credits: 0, floor: 2, joinedThisMonth: true)
    #expect(SeasonFacts.footRule(joined, today: "2026-09-13") == "Joined this month · no minimum")
    #expect(SeasonFacts.monthRow(joined, today: "2026-09-13") == "Best 4 a month count · no minimum this month, you joined this month · 17 days left in September")
    // an older payload: no fact, and the figure toward the minimum stands as before
    let old = heroMembership(structure: "squads2", credits: 0, floor: 2)
    #expect(SeasonFacts.footRule(old, today: "2026-09-13") == "2 a month · 2 to go")
    #expect(SeasonFacts.monthRow(old, today: "2026-09-13") == "Best 4 a month count · 0/2 toward the minimum · 17 days left in September")
    // said false: the same as unsaid, no waiver invented
    let stayed = heroMembership(structure: "squads2", credits: 0, floor: 2, joinedThisMonth: false)
    #expect(SeasonFacts.footRule(stayed, today: "2026-09-13") == "2 a month · 2 to go")
  }
  @Test func theFloorAlarmDoesNotFireForAMidMonthJoiner() {
    let cal = Calendar(identifier: .gregorian)
    let joined = heroMembership(structure: "squads2", credits: 0, floor: 2, joinedThisMonth: true)
    #expect(HomeFallbackItems.floorItem(joined, today: "2026-09-29", calendar: cal) == nil)
    let old = heroMembership(structure: "squads2", credits: 0, floor: 2)
    #expect(HomeFallbackItems.floorItem(old, today: "2026-09-29", calendar: cal) != nil, "with no fact the alarm keeps its existing rule")
  }
}

/// D351 (built) · the phone's invitation-list model says "Joined ✓" only on proof.
@Suite struct InviteLandedTests {
  @Test func theRouteKeyCarriesTheInvitationId() {
    let id = UUID()
    #expect(HomeDispatch.HomeInviteKey.inviteId(from: "invite:\(id.uuidString)") == id)
    #expect(HomeDispatch.HomeInviteKey.inviteId(from: "invite:\(id.uuidString.lowercased())") == id)
    #expect(HomeDispatch.HomeInviteKey.inviteId(from: "season:\(id.uuidString)") == nil)
    #expect(HomeDispatch.HomeInviteKey.inviteId(from: "invite:not-a-uuid") == nil)
  }
}
