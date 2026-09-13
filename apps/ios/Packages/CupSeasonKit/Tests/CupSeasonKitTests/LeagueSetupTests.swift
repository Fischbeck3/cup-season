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

// MARK: - D347 · the stored rule survives the wizard

@Suite("D347 · an off-ladder cap is not silently rewritten")
struct StoredCapFidelityTests {
  private func settings(cap: Int?) -> LeagueRoom.Settings {
    LeagueRoom.Settings(league_id: UUID(), preset: "standard", handicap_allowance: 95,
                        verification: "attested", counting_cap: cap, participation_floor: 2,
                        floor_penalty: "deduct", season_format: "points", buyin_cents: 0,
                        season_months: 3, locked_at: nil, structure: "squads2",
                        draft_type: "random", payout_champ: 60, payout_runnerup: 25,
                        payout_king: 15, finish: "cup_final")
  }

  /// Every cap the CHECK admits must come back out of the wizard unchanged.
  @Test func everyStoredCapRoundTrips() {
    for stored in [1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 20, 31] {
      let d = WizardDials.from(settings(cap: stored), name: "X")
      #expect(d.capN == stored, "stored \(stored) came back as \(String(describing: d.capN))")
    }
  }

  @Test func unlimitedStaysUnlimited() {
    #expect(WizardDials.from(settings(cap: nil), name: "X").capN == nil)
  }

  /// The snapped RUNG is still what the stepper shows — this fix does not
  /// change the display contract `Bylaws.capIndex` owns.
  @Test func theStepperStillSitsOnTheNearestRung() {
    #expect(WizardDials.from(settings(cap: 5), name: "X").cap == Bylaws.capIndex(5))
  }

  /// Moving the stepper must win: the exact value is not sticky.
  @Test func movingTheStepperTakesTheLaddersValue() {
    var d = WizardDials.from(settings(cap: 5), name: "X")
    d.cap = 0
    #expect(d.capN == 2)
    d.applyPreset(1)
    #expect(d.capN == 3)
  }

  /// And the agreement a group accepts reads the rule that will be stored.
  @Test func theAgreementQuotesTheStoredRule() {
    let d = WizardDials.from(settings(cap: 5), name: "X")
    #expect(d.setupCounting == "Each golfer’s best 5 each month")
    #expect(WizardAgreement(d).rows.contains { $0.value == "Each golfer’s best 5 each month" })
  }
}

extension StoredCapFidelityTests {
  /// One tap lands on a rung, in the direction of travel.
  @Test func steppingOffAnOffLadderCapGoesTheRightWay() {
    for (stored, down, up) in [(5, 4, 6), (7, 6, nil), (1, 2, 2)] as [(Int, Int?, Int?)] {
      var a = WizardDials.from(settingsFor(cap: stored), name: "X"); a.stepCap(-1)
      #expect(a.capN == down, "stored \(stored) down → \(String(describing: a.capN))")
      var b = WizardDials.from(settingsFor(cap: stored), name: "X"); b.stepCap(1)
      #expect(b.capN == up, "stored \(stored) up → \(String(describing: b.capN))")
    }
  }
  private func settingsFor(cap: Int?) -> LeagueRoom.Settings {
    LeagueRoom.Settings(league_id: UUID(), preset: "standard", handicap_allowance: 95,
                        verification: "attested", counting_cap: cap, participation_floor: 2,
                        floor_penalty: "deduct", season_format: "points", buyin_cents: 0,
                        season_months: 3, locked_at: nil, structure: "squads2",
                        draft_type: "random", payout_champ: 60, payout_runnerup: 25,
                        payout_king: 15, finish: "cup_final")
  }
}

/// D348 · the celebration screen counts seats, not envelopes.
@Suite struct LockShareCrewTests {
  @Test func aProAloneWithFiveInvitationsIsNotSixIn() {
    let s = WizardCopy.liveSub(weeks: 13, startsOn: "2026-09-20", invited: 5, members: 1)
    #expect(s.contains("You're in"))
    #expect(s.contains("five invited"))
    #expect(!s.contains("Six in"))
  }

  @Test func acceptedGolfersAreCountedAndPendingOnesAreNot() {
    let s = WizardCopy.liveSub(weeks: 13, startsOn: "2026-09-20", invited: 2, members: 4)
    #expect(s.contains("Four in"))
    #expect(s.contains("two invited"))
  }

  @Test func noInvitationsMeansNoInvitationClause() {
    let s = WizardCopy.liveSub(weeks: 6, startsOn: "2026-09-20", invited: 0, members: 3)
    #expect(s.contains("Three in"))
    #expect(!s.contains("invited"))
    #expect(s.hasSuffix("the link works for anyone."))
  }
}
