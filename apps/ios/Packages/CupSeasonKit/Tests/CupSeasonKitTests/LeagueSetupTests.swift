import Foundation
import Testing
@testable import CupSeasonKit

@Suite struct LeagueSetupTests {
  @Test func suggestionOnlyChangesTheTwoOfferedRules() {
    var d = WizardDials(name: "Old teammates", preset: 2, stake: 50, durWeeks: 26,
      startISO: "2026-10-03", structure: "squads4", draftType: "assign", finish: "points_table")
    d.buyInNote = "Pay Sam"; d.expectedRoster = 12; d.invitees = [UUID()]
    var expected = d; expected.cap = 0; expected.floor = 0
    d.applyBusyFriendsSuggestion()
    #expect(d == expected)
  }

  @Test func explicitSquadsSurviveEvenWhileInvitationsArePending() {
    for structure in ["squads2", "squads3", "squads4"] {
      let d = WizardDials(structure: structure)
      #expect(d.preparedForReview(squadsChosen: true).structure == structure)
      #expect(d.preparedForReview(squadsChosen: false).solo)
      #expect(d.preparedForReview(squadsChosen: nil).solo)
    }
  }

  @Test func reviewPinsDatesAndTransmitsTheSameChoicesAfterMidnight() throws {
    var d = WizardDials(name: "  Saturday Regulars ", structure: "squads3")
    d.expectedRoster = 8; d.applyBusyFriendsSuggestion()
    let review = WizardAgreement(d.preparedForReview(squadsChosen: true, today: "2026-09-18"))
    d.stepCap(1); d.floor = 2 // editing the original cannot mutate the agreement
    let c = WizardLockCall(review.dials, leagueId: UUID(), name: review.dials.name, today: "2026-09-19")
    #expect(c.args.p_starts_on == "2026-09-19")
    #expect(c.args.p_ends_on == review.dials.endDate(today: "2026-09-18"))
    #expect(c.args.p_counting_cap == 2 && c.args.p_participation_floor == 0)
    #expect(c.args.p_structure == "squads3" && c.args.p_name == "Saturday Regulars")
    var unlimited = review.dials; unlimited.cap = 4
    let bytes = try JSONEncoder().encode(WizardLockCall(unlimited, leagueId: UUID(), name: unlimited.name))
    let json = try #require(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
    #expect(json["p_counting_cap"] is NSNull)
  }

  @Test func minimumExplainsTheActualSelectedPenalty() {
    var d = WizardDials()
    d.floor = 0
    #expect(d.setupMinimumConsequence.contains("No points lost"))
    d.floor = 2
    #expect(d.setupMinimumConsequence.contains("5 points per round short"))
    #expect(d.setupMinimumConsequence.contains("One missed minimum"))
    d.preset = 2
    #expect(d.setupMinimumConsequence.contains("removed from the team total"))
    d.preset = 0
    #expect(d.setupMinimumConsequence.contains("No points penalty"))
    d.structure = "solo"
    #expect(d.setupMinimumConsequence == "No team penalty in an individual season.")
  }

  @Test func agreementDisclosesMonthlyFinalEligibilityAndShortSeasons() throws {
    var d = WizardDials()
    let full = WizardAgreement(d).rows
    #expect(try #require(full.first { $0.label == "The finish" }).value.contains("monthly counting limit"))
    #expect(full.contains { $0.label == "Head start" })
    d.durWeeks = 4
    let short = WizardAgreement(d).rows
    #expect(try #require(short.first { $0.label == "The finish" }).value == "The points leader at season end wins.")
    #expect(!short.contains { $0.label == "Head start" })
  }

  @Test func scoreExpectationsUseTheExistingCrossClientContract() {
    for preset in 0..<3 {
      let rows = WizardAgreement(WizardDials(preset: preset)).rows
      #expect(rows.first { $0.label == "Score agreement" }?.value == Bylaws.verif[preset])
    }
  }

  @Test func partialLedgerNeverPrintsTheAdjustmentTwice() {
    let partial = SquadReceiptBreakdown(total: 12, roundContributions: [12, 8], ledgerPoints: [-5])
    #expect(partial.rounds == 20 && partial.knownAdjustments == -5 && partial.unexplained == -3)
    #expect(partial.rounds + partial.knownAdjustments + partial.unexplained == partial.total)
    let complete = SquadReceiptBreakdown(total: 7.5, roundContributions: [6, 6.5], ledgerPoints: [-5])
    #expect(complete.unexplained == 0)
    let missing = SquadReceiptBreakdown(total: 10, roundContributions: [20], ledgerPoints: [])
    #expect(missing.unexplained == -10)
  }
}

private actor PublishTransport {
  enum Failure: Error { case offline }
  var creates = 0
  var locks: [UUID] = []
  var invites: [UUID] = []
  var remembered: WizardService.Created?
  let created = WizardService.Created(leagueId: UUID(), name: "Regulars", code: "REG12345", memberId: UUID())
  func create(_ name: String) -> WizardService.Created { creates += 1; return created }
  func remember(_ c: WizardService.Created) { remembered = c }
  func lock(_ c: WizardService.Created) throws -> WizardService.Locked {
    #expect(remembered?.leagueId == c.leagueId) // checkpoint must precede the fallible lock
    locks.append(c.leagueId)
    if locks.count == 1 { throw Failure.offline }
    return .init(nextPhase: "season", seasonId: UUID(), startsOn: "2026-10-03", endsOn: "2027-01-02", alreadyLocked: true)
  }
  func invite(_ league: UUID, _ golfer: UUID) throws {
    #expect(league == created.leagueId)
    invites.append(golfer)
    if invites.count == 2 { throw Failure.offline }
  }
}

@Suite struct LeaguePublishRetryTests {
  @Test func confirmedCreateSurvivesLockFailureAndInvitesWaitForLock() async throws {
    let server = PublishTransport()
    var d = WizardDials(name: "Regulars"); d.invitees = [UUID(), UUID(), UUID()]
    do {
      _ = try await WizardService.publish(dials: d, resuming: nil,
        didCreate: { await server.remember($0) }, create: { await server.create($0) },
        lock: { try await server.lock($0) }, invite: { try await server.invite($0, $1) })
      Issue.record("First lock must fail")
    } catch { #expect(await server.invites.isEmpty) }
    let remembered = try #require(await server.remembered)
    let result = try await WizardService.publish(dials: d, resuming: remembered,
      didCreate: { await server.remember($0) }, create: { await server.create($0) },
      lock: { try await server.lock($0) }, invite: { try await server.invite($0, $1) })
    #expect(await server.creates == 1)
    #expect(await server.locks == [remembered.leagueId, remembered.leagueId])
    #expect(result.leagueId == remembered.leagueId && result.locked.alreadyLocked)
    #expect(result.invited == 2 && result.notInvited == 1)
  }
}
