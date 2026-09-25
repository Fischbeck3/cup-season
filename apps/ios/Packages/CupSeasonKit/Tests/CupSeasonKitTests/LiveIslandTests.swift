import Foundation
import Testing
@testable import CupSeasonKit

struct LiveIslandTests {
  let owner = UUID(), round = UUID()
  func card() -> LiveRoundState {
    var me = LivePlayer(n: "You", i: 0, ci: 1, guest: false, me: true)
    me.pid = owner
    var rival = LivePlayer(n: "Galen", i: 0, ci: 2, guest: false)
    rival.pid = UUID()
    var s = LiveRoundState.fresh(players: [me, rival])
    s.active = true; s.stage = .live; s.lr = round; s.code = "TEST"; s.pmap = [UUID(), UUID()]
    s.game = .match; s.hole = 2; s.ts = 10
    s.course.save(front: Array(repeating: 4, count: 9), back: Array(repeating: 4, count: 9), nine: false)
    s.scores[0][0] = 4; s.scores[1][0] = 5; s.scores[1][1] = 4
    s.scts[0][0] = 1; s.scts[1][0] = 1; s.scts[1][1] = 1
    return s
  }
  @Test func missedHoleCanBeScoredWithoutFillingTheNextOne() throws {
    var s = card()
    (s, _) = try LiveIsland.applying(.previous, round: round, owner: owner, hole: 3, to: s)
    #expect(s.hole == 1 && s.scores[0][1] == nil)
    var write: LiveMessage?
    (s, write) = try LiveIsland.applying(.plus, round: round, owner: owner, hole: 2, to: s)
    #expect(s.scores[0][1] == 4 && write?.h == 2 && write?.pid == s.pmap?[0])
    #expect(LiveIsland.facts(s).result == "1 up" && LiveIsland.facts(s).through == 2)
    (s, _) = try LiveIsland.applying(.next, round: round, owner: owner, hole: 2, to: s)
    #expect(s.hole == 2 && s.scores[0][2] == nil && s.scores[1][1] == 4)
  }
  @Test func matchPerspectiveFollowsTheGolferOnEitherSide() {
    var s = card()
    #expect(LiveIsland.facts(s).result == "1 up")
    s.players[0].me = false; s.players[1].me = true
    #expect(LiveIsland.facts(s).result == "1 down")
    #expect(LiveIsland.facts(s).opponent == "vs You")
    s.scores[0][0] = 5
    #expect(LiveIsland.facts(s).result == "All square")
    #expect(LiveIsland.facts(s).compact == "AS")
  }
  @Test func closeoutAndPlainScoreNeverInventAMatch() {
    var s = card()
    for h in 0..<10 { s.scores[0][h] = 3; s.scores[1][h] = 4 }
    #expect(LiveIsland.facts(s).result == "Won 10&8")
    #expect(LiveIsland.facts(s).through == nil)
    s.game = .score
    #expect(LiveIsland.facts(s).result == "30")
    #expect(LiveIsland.facts(s).detail == "Gross · 10 scored")
  }
  @Test func guardOldButtonsAnotherAccountEndedRoundsAndBounds() throws {
    let s = card()
    #expect(throws: LiveIsland.Failure.self) { try LiveIsland.applying(.plus, round: UUID(), owner: owner, hole: 3, to: s) }
    #expect(throws: LiveIsland.Failure.self) { try LiveIsland.applying(.plus, round: round, owner: UUID(), hole: 3, to: s) }
    #expect(throws: LiveIsland.Failure.self) { try LiveIsland.applying(.plus, round: round, owner: owner, hole: 2, to: s) }
    var ended = s; ended.active = false
    #expect(throws: LiveIsland.Failure.self) { try LiveIsland.applying(.plus, round: round, owner: owner, hole: 3, to: ended) }
    var nine = s; nine.holes = 9; nine.hole = 8
    let (last, write) = try LiveIsland.applying(.next, round: round, owner: owner, hole: 9, to: nine)
    #expect(last.hole == 8 && write == nil && last.scores == nine.scores)
  }
  @Test func explicitScoreRangeAndMonotonicClock() throws {
    var s = card(); s.scores[0][2] = 15; s.scts[0][2] = 100
    let (capped, _) = try LiveIsland.applying(.plus, round: round, owner: owner, hole: 3, to: s, now: 1)
    #expect(capped.scores[0][2] == 15)
    s.scores[0][2] = 1
    let (cleared, write) = try LiveIsland.applying(.minus, round: round, owner: owner, hole: 3, to: s, now: 1)
    #expect(cleared.scores[0][2] == nil && write?.s == nil && write?.cts == 101)
    let (blank, none) = try LiveIsland.applying(.minus, round: round, owner: owner, hole: 3, to: cleared)
    #expect(blank == cleared && none == nil)
  }
  @Test func journalSurvivesTerminationBeforeQueueTransfer() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let disk = LiveDisk(directory: dir)
    let (s, m) = try LiveIsland.applying(.plus, round: round, owner: owner, hole: 3, to: card())
    let journal = LiveDisk.ActivityJournal(state: s, pending: [try #require(m)])
    try JSONEncoder().encode(journal).write(to: await disk.activityURL(round), options: .atomic)
    let recovered = LiveDisk(directory: dir)
    #expect(await recovered.snapshot(round)?.scores[0][2] == 4)
    #expect(await recovered.queue(round) == [m!])
    #expect(await recovered.activityJournal(round) == nil)
  }
  @Test func journalRemainsReadableWhenTransferCannotFinish() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let disk = LiveDisk(directory: dir)
    try FileManager.default.createDirectory(at: await disk.queueURL(round), withIntermediateDirectories: true)
    let (s, m) = try LiveIsland.applying(.plus, round: round, owner: owner, hole: 3, to: card())
    try await disk.commitActivity(s, message: m)
    #expect(await disk.snapshot(round)?.scores[0][2] == 4)
    #expect(await disk.snapshots().first?.lr == round)
    #expect(await disk.queue(round).count == 1)
    #expect(await disk.activityJournal(round) != nil)
  }
  @Test func delayedAppSnapshotCannotUndoIntentAndAckKeepsNewWrites() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let disk = LiveDisk(directory: dir), old = card()
    let (edited, m) = try LiveIsland.applying(.plus, round: round, owner: owner, hole: 3, to: old, now: 100)
    let first = try #require(m)
    try await disk.commitActivity(edited, message: first)
    await disk.save(old)
    #expect(await disk.snapshot(round)?.scores[0][2] == 4)
    let (newer, second) = try LiveIsland.applying(.plus, round: round, owner: owner, hole: 3, to: edited, now: 101)
    try await disk.commitActivity(newer, message: second)
    await disk.acknowledge(first, round: round)
    #expect(await disk.queue(round) == [second!])
    #expect(await disk.snapshot(round)?.scores[0][2] == 5)
  }
}
