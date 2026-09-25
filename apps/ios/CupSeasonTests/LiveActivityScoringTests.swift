import Foundation
import Testing
@testable import CupSeason
import CupSeasonKit

@Suite @MainActor struct LiveActivityScoringTests {
  func savedCard(owner: UUID, round: UUID) -> LiveRoundState {
    var me = LivePlayer(n: "QA", i: 0, ci: 1, guest: false, me: true); me.pid = owner
    var s = LiveRoundState.fresh(players: [me]); s.active = true; s.stage = .live
    s.lr = round; s.code = "TEST"; s.pmap = [UUID()]; s.hole = 2; s.ts = LiveFmt.now()
    s.course.save(front: Array(repeating: 4, count: 9), back: Array(repeating: 4, count: 9), nine: false)
    return s
  }
  @Test func coldAppScoresOriginalRoundAndResumesMissedHole() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let owner = UUID(), round = UUID(), disk = LiveDisk(directory: dir)
    await disk.save(savedCard(owner: owner, round: round))
    let store = LiveRoundStore(offline: OfflineRounds(directory: dir.appendingPathComponent("local")), disk: disk)
    try await store.activityAction(.previous, round: round, owner: owner, hole: 3, currentOwner: { owner }, sync: false)
    try await store.activityAction(.plus, round: round, owner: owner, hole: 2, currentOwner: { owner }, sync: false)
    try await store.activityAction(.plus, round: round, owner: owner, hole: 2, currentOwner: { owner }, sync: false)
    try await store.activityAction(.next, round: round, owner: owner, hole: 2, currentOwner: { owner }, sync: false)
    #expect(store.state.lr == round && store.state.hole == 2)
    #expect(store.state.scores[0][1] == 5 && store.state.scores[0][2] == nil)
    let reopened = LiveRoundStore(disk: LiveDisk(directory: dir))
    try await reopened.activityAction(.previous, round: round, owner: owner, hole: 3, currentOwner: { owner }, sync: false)
    #expect(reopened.state.scores[0][1] == 5)
    #expect(await disk.queue(round).map(\.s) == [4,5])
  }
  @Test func anotherActiveRoundAndSignedOutUserCannotChangeIt() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let owner = UUID(), round = UUID(), store = LiveRoundStore(disk: LiveDisk(directory: dir))
    store.adoptActivityRound(savedCard(owner: owner, round: round), owner: owner)
    let before = store.state
    for actualOwner in [UUID(), nil] as [UUID?] {
      do { try await store.activityAction(.plus, round: round, owner: owner, hole: 3, currentOwner: { actualOwner }, sync: false); Issue.record("Wrong account scored") }
      catch {}
    }
    do { try await store.activityAction(.plus, round: UUID(), owner: owner, hole: 3, currentOwner: { owner }, sync: false); Issue.record("Different round scored") }
    catch {}
    #expect(store.state == before)
  }
  @Test func diskFailureDoesNotConfirmOrChangeTheScore() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try Data([0]).write(to: dir)
    defer { try? FileManager.default.removeItem(at: dir) }
    let owner = UUID(), round = UUID(), store = LiveRoundStore(disk: LiveDisk(directory: dir))
    store.adoptActivityRound(savedCard(owner: owner, round: round), owner: owner)
    do { try await store.activityAction(.plus, round: round, owner: owner, hole: 3, currentOwner: { owner }, sync: false); Issue.record("Disk failure acknowledged") }
    catch {}
    #expect(store.state.scores[0][2] == nil)
  }
  @Test func localCardUsesItsExistingVaultAndNeverQueuesAnRPC() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let owner = UUID(), round = UUID(), vault = OfflineRounds(directory: dir.appendingPathComponent("local")), disk = LiveDisk(directory: dir)
    var saved = savedCard(owner: owner, round: round); saved.localOwner = owner; saved.code = nil; saved.pmap = nil
    try vault.save(saved)
    let store = LiveRoundStore(offline: vault, disk: disk)
    try await store.activityAction(.plus, round: round, owner: owner, hole: 3, currentOwner: { owner }, sync: false)
    #expect(try vault.round(owner: owner, id: round)?.scores[0][2] == 4)
    #expect(await disk.queue(round).isEmpty)
  }
  @Test func oldAttributesDecodeWithoutInteractiveAuthority() throws {
    let data = Data("{\"course\":\"Papago\"}".utf8)
    let attrs = try JSONDecoder().decode(CSRoundActivity.self, from: data)
    #expect(attrs.round == nil && attrs.owner == nil)
    let state = try JSONDecoder().decode(CSRoundActivity.ContentState.self, from: Data("{\"hole\":3,\"thru\":1,\"holes\":18}".utf8))
    #expect(state.canScore == nil && state.score == nil)
  }
  @Test func reviewRecoversExactOwnedCardWithoutChangingTheHoleOrScores() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let owner = UUID(), round = UUID(), disk = LiveDisk(directory: dir)
    let saved = savedCard(owner: owner, round: round)
    await disk.save(saved)
    let store = LiveRoundStore(offline: OfflineRounds(directory: dir.appendingPathComponent("local")), disk: disk)
    do {
      try await store.openActivityRound(.init(round: round, owner: owner, review: true), currentOwner: { UUID() }, sync: false)
      Issue.record("Another account opened the card")
    } catch {}
    #expect(!store.state.active)
    try await store.openActivityRound(.init(round: round, owner: owner, review: true), currentOwner: { owner }, sync: false)
    #expect(store.state == saved && store.reviewRequested == round)
    #expect(await disk.queue(round).isEmpty)
  }
  @Test func reviewLinkCarriesRoundAndOwner() {
    let owner = UUID(), round = UUID(), router = LiveActivityRoute()
    #expect(router.receive(CSRoundActivityLink.url(round: round, owner: owner, review: true)))
    #expect(router.pending == .init(round: round, owner: owner, review: true))
    #expect(!router.receive(URL(string: "cupseason://live?round=wrong")!))
  }
}
