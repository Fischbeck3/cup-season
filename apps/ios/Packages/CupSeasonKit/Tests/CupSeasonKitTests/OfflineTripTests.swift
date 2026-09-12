import Foundation
import Testing
@testable import CupSeasonKit

@Suite @MainActor struct OfflineTripTests {
  private func directory() -> URL { FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString) }
  private func round(owner: UUID, day: String, holes: Int = 18) -> LiveRoundState {
    var player = LivePlayer(n: "Offline test golfer", i: 0, ci: 1, guest: false, me: true)
    player.pid = owner
    var state = LiveRoundState.fresh(players: [player])
    state.lr = UUID(); state.localOwner = owner; state.playedDay = day; state.holes = holes
    state.active = true; state.stage = .live; state.startedAt = 1; state.ts = 1
    return state
  }
  @Test func threeRoundsSurviveRelaunchAndCorrections() throws {
    let dir = directory(); defer { try? FileManager.default.removeItem(at: dir) }
    let owner = UUID()
    for day in ["2026-09-13", "2026-09-14", "2026-09-15"] {
      var state = round(owner: owner, day: day)
      let disk = OfflineRounds(directory: dir)
      try disk.save(state)
      for hole in 0..<18 {
        state.scores[0][hole] = 4; state.hole = hole
        try disk.save(state)
        #expect(try OfflineRounds(directory: dir).round(owner: owner, id: state.lr!)?.scores == state.scores)
      }
      state.scores[0][0] = 5; try disk.save(state)
      state.active = false; state.localCompleted = true; try disk.save(state)
    }
    let kept = try OfflineRounds(directory: dir).rounds(owner: owner)
    #expect(kept.count == 3)
    #expect(kept.allSatisfy { $0.localCompleted == true && !$0.active && $0.scores[0][0] == 5 })
    #expect(Set(KeptCards.rows(kept).compactMap(\.playedOn)).count == 3)
    #expect(KeptCards.rows(kept).allSatisfy { $0.total == 73 })
    #expect(try OfflineRounds(directory: dir).rounds(owner: UUID()).isEmpty)
  }
  @Test func nineHolesAndOriginalDayRemainNine() throws {
    var s = round(owner: UUID(), day: "2026-09-13", holes: 9)
    s.rating9 = true; s.course.rating = 35.1; s.course.slope = 123
    for i in 0..<9 { s.scores[0][i] = 4 }
    let kept = try #require(KeptCards.card(from: s))
    let c = KeptCards.compose(kept)
    #expect(kept.isComplete && kept.holes == 9 && kept.total == 36)
    #expect(c.side == 9 && c.rating9 && c.date == "2026-09-13")
    #expect(PostPayload.build(c, seasonId: nil).nine_rating == 35.1)
  }
  @Test func storageFailureIsNotSuccess() throws {
    let dir = directory(); try Data([0]).write(to: dir)
    defer { try? FileManager.default.removeItem(at: dir) }
    #expect(throws: (any Error).self) { try OfflineRounds(directory: dir).save(round(owner: UUID(), day: "2026-09-13")) }
  }
  @Test func serverCleanupCannotEraseLocalRound() async throws {
    let dir = directory(); defer { try? FileManager.default.removeItem(at: dir) }
    let owner = UUID(); let state = round(owner: owner, day: "2026-09-13")
    let local = OfflineRounds(directory: dir.appendingPathComponent("offline"))
    try local.save(state)
    await LiveDisk(directory: dir.appendingPathComponent("online")).clearSnapshots(keep: nil)
    #expect(try local.rounds(owner: owner).count == 1)
    #expect(LiveCopy.syncBadge(state, presence: [], queued: 0, now: Int64.max).contains("NOT POSTED"))
  }
  @Test func corruptCardIsReportedNotSilentlyHidden() throws {
    let dir = directory(); defer { try? FileManager.default.removeItem(at: dir) }
    let owner = UUID(); let state = round(owner: owner, day: "2026-09-13")
    let local = OfflineRounds(directory: dir); try local.save(state)
    let file = dir.appendingPathComponent(owner.uuidString).appendingPathComponent(state.lr!.uuidString + ".json")
    try Data([0]).write(to: file)
    #expect(throws: (any Error).self) { try local.rounds(owner: owner) }
  }
  @Test func frozenPostSurvivesRelaunchAndAccountSwitch() throws {
    let dir = directory(); defer { try? FileManager.default.removeItem(at: dir) }
    let owner = UUID(), request = UUID()
    var c = PostCard(); c.mode = .holes; c.side = 18; c.scores = Array(repeating: 4, count: 18)
    c.date = "2026-09-13"; c.course = "QA fixture"; c.rating = "72"; c.slope = "113"
    let pending = OfflinePost(owner: owner, request: request, card: c, payload: PostPayload.build(c, seasonId: nil), playedWith: [])
    try OfflinePostDisk(directory: dir).save(pending)
    let retry = try #require(try OfflinePostDisk(directory: dir).read(owner: owner, request: request))
    #expect(retry == pending && retry.holes.count == 18)
    #expect(try OfflinePostDisk(directory: dir).read(owner: UUID(), request: request) == nil)
    var accepted = retry; accepted.accepted = UUID()
    try OfflinePostDisk(directory: dir).save(accepted)
    #expect(try OfflinePostDisk(directory: dir).read(owner: owner, request: request)?.accepted == accepted.accepted)
    #expect(PostService.PostRoundOnceCall.optionalArgs.isEmpty)
  }

  @Test func restoredDraftKeepsItsRetryIdentityAfterAWeek() throws {
    let source = UUID()
    let old = Date(timeIntervalSinceNow: -7 * 86400)
    let draft = PostDraft(at: old, card: PostCard(), sourceLive: source)
    let restored = try #require(PostDraft.decode(PostDraft.encode(draft)))
    #expect(restored.sourceLive == source)
    #expect(PostDraft.decode(PostDraft.encode(PostDraft(at: old, card: PostCard()))) == nil)
  }

}
