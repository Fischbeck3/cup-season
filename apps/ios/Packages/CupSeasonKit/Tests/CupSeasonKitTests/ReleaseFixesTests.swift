import Testing
import Foundation
@testable import CupSeasonKit

/// D353 · the covenant says the allowance and the whole counting rule.
@Suite struct CovenantAllowanceTests {
  @Test func theAllowanceIsSaidInTheWizardsOwnWords() {
    let c = Covenant(name: "the Fellas", buyinCents: 0, preset: "standard", floor: 2, finish: nil,
                     countingCap: 3, handicapAllowance: 95)
    #expect(c.rulesLine == "Standard rules: honest scores, best three a month count, two a month keeps you in, 95 percent of your index.")
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
