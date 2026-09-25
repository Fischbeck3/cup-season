import Foundation
import Testing
@testable import CupSeasonKit

@Suite("Native audit repairs preserve the season and the saved card")
struct NativeAuditRepairTests {
  @Test func finalCrownDoesNotFollowThePointsLeaderAndRemainingTiesSurvive() {
    let a = Team(id: UUID(), name: "Points leader", pts: 150, ci: 0)
    let b = Team(id: UUID(), name: "Champion", pts: 95, ci: 1)
    let c = Team(id: UUID(), name: "Runner-up", pts: 100, ci: 2)
    let d = Team(id: UUID(), name: "Also 150", pts: 150, ci: 3)
    let order = FinalTable.ordered([a, d, c, b], champion: b.id, runnerUp: c.id)
    #expect(order.map(\.id) == [b.id, c.id, a.id, d.id])
    #expect(FinalTable.ranks(order, champion: b.id, runnerUp: c.id) == [1, 2, 3, 3])
    #expect(order.map(\.pts) == [95, 100, 150, 150])
    #expect(FinalTable.ranks([], champion: nil, runnerUp: nil).isEmpty)
  }

  private func saved(owner: UUID, now: Int64) -> LiveRoundState {
    var s = LiveRoundState.fresh(players: [LivePlayer(n: "Owner", i: 12, ci: 0, guest: false, pid: owner, me: true)])
    s.active = true; s.stage = .live; s.lr = UUID(); s.code = "SAVED"; s.ts = now
    s.scores[0][0] = 5; s.scts[0][0] = now
    return s
  }

  @Test func savedCardRequiresTheSameAccountAndKeepsOriginalIdentity() {
    let owner = UUID(), now: Int64 = 1_800_000_000_000
    let s = saved(owner: owner, now: now)
    let restored = LiveRehydrator.savedRound([s], owner: owner, now: now)
    #expect(restored?.lr == s.lr)
    #expect(restored?.scores[0][0] == 5)
    #expect(restored?.scts[0][0] == now)
    #expect(LiveRehydrator.savedRound([s], owner: UUID(), now: now) == nil)
    #expect(LiveRehydrator.savedRound([s], owner: owner, abandoned: [s.lr!], now: now) == nil)
    #expect(LiveRehydrator.savedRound([s], owner: owner, now: now + 172_800_000) == nil)
    var inactive = s; inactive.active = false
    #expect(LiveRehydrator.savedRound([inactive], owner: owner, now: now) == nil)
  }

  @Test func preparingSavedRoundPreservesItsDurableQueue() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let disk = LiveDisk(directory: dir), round = UUID(), player = UUID()
    let msg = LiveMessage.score(pid: player, hole0: 0, strokes: 6, cts: 100)
    await disk.saveQueue(round, [msg])
    let session = LiveRoundSession(disk: disk)
    await session.prepareSavedRound(round, code: "SAVED")
    #expect(await session.currentRound == round)
    #expect(await session.isJoined == false)
    #expect(await session.queued() == 1)
    #expect(await disk.queue(round) == [msg])
  }

  @Test func sharePreparationMustConfirmTheChosenConsent() throws {
    let id = UUID(), token = UUID()
    let reply: JSONValue = .object(["token": .string(token.uuidString), "created": .bool(false), "include_photo": .bool(false)])
    let attempt = try RoundShareAttempt(reply: reply, attempt: id, includePhoto: false, owner: id)
    #expect(!attempt.created && attempt.token == token && attempt.id == id)
    #expect(throws: (any Error).self) { try RoundShareAttempt(reply: reply, attempt: id, includePhoto: true, owner: id) }
    #expect(throws: (any Error).self) { try RoundShareAttempt(reply: .object([:]), attempt: id, includePhoto: false, owner: id) }
  }

  @Test func covenantUsesActualStructureAndOmitsZeroAwards() {
    let solo = Covenant(name: "Solo", buyinCents: 0, preset: "standard", floor: 2, finish: "points_table", structure: "solo")
    #expect(solo.rulesLine?.contains("keeps you in") == false)
    #expect(solo.splitLine == nil && solo.potLine == nil)
    #expect(solo.endingLine.contains("No reset"))
    let squads = Covenant(name: "Sides", buyinCents: 5000, preset: "standard", floor: 2, finish: "cup_final",
                          split: .init(champion: 75, runnerUp: 25, pointsKing: 0), structure: "squads2")
    #expect(squads.endingLine.contains("Both squads") && squads.endingLine.contains("10-point"))
    #expect(squads.splitLine?.contains("Points King") == false)
    #expect(squads.potLine == MoneyCopy.ledger)
  }

  private func membership(accepted: Bool, status: String? = nil) throws -> Me.Membership {
    let json = """
    {"league_id":"00000000-0000-0000-0000-000000000001","member_id":"00000000-0000-0000-0000-000000000002", "name":"The next season", "code":"RETURN", "phase":"season", "role":"player", "in_season":\(accepted), "renewal_status":\(status.map { "\"\($0)\"" } ?? "null"),
    "season":{"id":"00000000-0000-0000-0000-000000000003", "number":2,"starts_on":"2026-10-01","ends_on":"2026-12-31","status":"active"}}
    """
    return try JSONDecoder().decode(Me.Membership.self, from: Data(json.utf8))
  }

  @Test func nextSeasonInvitationOpensTermsOnlyWhilePending() throws {
    let pending = try membership(accepted: false, status: "pending")
    let row = CompeteRoot.make(Me(profile: nil, memberships: [pending]), today: "2026-09-24").seasons.first
    #expect(row?.invitationCode == "RETURN" && row?.leagueId == nil && row?.rank == nil)
    #expect(CompeteRoot.make(Me(profile: nil, memberships: [pending]), today: "2026-10-01").seasons.isEmpty)
    let declined = try membership(accepted: false, status: "declined")
    #expect(CompeteRoot.make(Me(profile: nil, memberships: [declined]), today: "2026-09-24").seasons.isEmpty)
    let accepted = try membership(accepted: true, status: "accepted")
    let live = CompeteRoot.make(Me(profile: nil, memberships: [accepted]), today: "2026-10-02").seasons.first
    #expect(live?.leagueId == accepted.league_id && live?.invitationCode == nil)
  }
  actor WithdrawalProbe {
    enum Failure: Error { case unavailable }
    var events: [String] = []
    let failRevoke: Bool
    init(failRevoke: Bool) { self.failRevoke = failRevoke }
    func revoke() throws -> [String] {
      events.append("revoke")
      if failRevoke { throw Failure.unavailable }
      return ["token"]
    }
    func remove(_ paths: [String]) throws {
      events.append(contentsOf: paths)
      throw Failure.unavailable
    }
  }

  @Test func withdrawalNeverCallsFailedCleanupSuccessAndRetriesBothCopies() async {
    let denied = WithdrawalProbe(failRevoke: true)
    do {
      try await ShareWithdrawal.perform(revoke: { try await denied.revoke() }, remove: { try await denied.remove($0) })
      Issue.record("Revocation failure was swallowed")
    } catch { #expect(error is WithdrawalProbe.Failure) }
    #expect(await denied.events == ["revoke"])
    let offline = WithdrawalProbe(failRevoke: false)
    for _ in 0..<2 {
      do {
        try await ShareWithdrawal.perform(revoke: { try await offline.revoke() }, remove: { try await offline.remove($0) })
        Issue.record("Storage failure was swallowed")
      } catch { #expect(error is ShareWithdrawal.CleanupPending) }
    }
    #expect(await offline.events == ["revoke", "token.jpg", "token.png", "revoke", "token.jpg", "token.png"])
  }

}
