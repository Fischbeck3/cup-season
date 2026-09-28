import Foundation
import Testing
@testable import CupSeasonKit

@Suite struct LiveDeliveryTests {
  private func card(round: UUID, player: UUID, strokes: Int = 4, clock: Int64 = 10) -> LiveRoundState {
    var golfer = LivePlayer(n: "QA", i: 0, ci: 1, guest: false, me: true)
    golfer.pid = UUID()
    var value = LiveRoundState.fresh(players: [golfer])
    value.active = true; value.stage = .live; value.lr = round; value.code = "TEST"
    value.pmap = [player]; value.ts = clock
    value.course.save(front: Array(repeating: 4, count: 9), back: Array(repeating: 4, count: 9), nine: false)
    value.ensureClocks(); value.scores[0][0] = strokes; value.scts[0][0] = clock
    return value
  }

  @Test(.timeLimit(.minutes(1))) func newerEditSurvivesEarlierAcknowledgment() async {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let disk = LiveDisk(directory: directory), script = DeliveryScript(heldWrites: [0, 1])
    let session = LiveRoundSession(disk: disk, delivery: script), round = UUID(), player = UUID()
    await session.prepareSavedRound(round, code: "TEST")
    let first = card(round: round, player: player)
    var later = first; later.ts = 20; later.scores[0][0] = 5; later.scts[0][0] = 20
    let task = Task { await session.submit(first, message: .score(pid: player, hole0: 0, strokes: 4, cts: 10), guest: nil) }
    await script.writesReached(1)
    await session.submit(later, message: .score(pid: player, hole0: 0, strokes: 5, cts: 20), guest: nil)
    #expect(await disk.queue(round).map(\.cts) == [10, 20])
    await script.releaseWrite(0)
    await script.writesReached(2)
    #expect(await disk.queue(round).map(\.cts) == [20])
    #expect(await disk.snapshot(round)?.scores[0][0] == 5)
    await script.releaseWrite(1); await task.value
    #expect(await disk.queue(round).isEmpty)
  }

  @Test func timeoutKeepsTheWriteUntilReconnectDrainsAndReconciles() async {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let disk = LiveDisk(directory: directory), script = DeliveryScript(failures: [0: .timeout])
    let session = LiveRoundSession(disk: disk, delivery: script), round = UUID(), player = UUID()
    await session.prepareSavedRound(round, code: "TEST")
    await session.submit(card(round: round, player: player), message: .score(pid: player, hole0: 0, strokes: 4, cts: 10), guest: nil)
    #expect(await disk.queue(round).first?.tries == 1)
    #expect(await disk.snapshotUnsynced(round) == nil)
    #expect(await session.synchronize(round: round) == 0)
    #expect(await script.writes.count == 2)
    #expect(await script.reads.count == 1)
    #expect(await disk.queue(round).isEmpty)
  }

  @Test(arguments: [false, true]) func terminalWriteKeepsSubmittedCardWithoutSnapshottingGuests(isGuest: Bool) async {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let disk = LiveDisk(directory: directory), script = DeliveryScript(failures: [0: .terminal])
    let session = LiveRoundSession(disk: disk, delivery: script), round = UUID(), player = UUID()
    let token = isGuest ? UUID() : nil
    await session.bind(round: round, code: "TEST", guest: token)
    var value = card(round: round, player: player)
    value.scores[0][1] = 5; value.scts[0][1] = 11
    await session.submit(value, message: .score(pid: player, hole0: 1, strokes: 5, cts: 11), guest: token)
    #expect(await script.writes.first?.guest == token)
    #expect(await disk.snapshotUnsynced(round)?.strokeCount == 2)
    #expect(await disk.queue(round).isEmpty)
    if isGuest { #expect(await disk.snapshot(round) == nil) }
  }

  @Test(.timeLimit(.minutes(1)), arguments: [false, true])
  func oldRPCDoesNotBlockOrRetireANewBinding(sameRound: Bool) async {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let disk = LiveDisk(directory: directory)
    let script = DeliveryScript(heldWrites: [0, 1], failures: [0: .terminal])
    let session = LiveRoundSession(disk: disk, delivery: script), first = UUID(), player = UUID()
    let next = sameRound ? first : UUID()
    await session.prepareSavedRound(first, code: "TEST")
    let old = Task { await session.send(.score(pid: player, hole0: 0, strokes: 4, cts: 10), round: first) }
    await script.writesReached(1)
    await session.leave()
    await session.prepareSavedRound(next, code: "TEST")
    let current = Task { await session.submit(card(round: next, player: player, clock: 20),
      message: .score(pid: player, hole0: 0, strokes: 4, cts: 20), guest: nil) }
    await script.writesReached(2) // The old RPC is still held; a new flush must run.
    await script.releaseWrite(0); await old.value
    await session.send(.score(pid: player, hole0: 1, strokes: 5, cts: 30), round: next)
    #expect(await script.writes.count == 2) // Old defer did not release the new flush.
    #expect(await disk.snapshotUnsynced(next) == nil)
    await script.releaseWrite(1); await current.value
    #expect(await disk.queue(next).isEmpty)
    #expect(await session.currentRound == next)
    if !sameRound { #expect(await disk.queue(first).map(\.cts) == [10]) }
  }

  @Test(.timeLimit(.minutes(1))) func lateReconcileCannotPublishIntoAnotherRound() async {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let script = DeliveryScript(heldReads: [0])
    let session = LiveRoundSession(disk: LiveDisk(directory: directory), delivery: script)
    let oldRound = UUID(), newRound = UUID()
    await session.prepareSavedRound(oldRound, code: "TEST")
    let old = Task { await session.reconcile() }
    await script.readsReached(1)
    await session.prepareSavedRound(newRound, code: "TEST")
    await script.releaseRead(0); await old.value
    await session.reconcile()
    var states: [JSONValue] = []
    for await event in session.events {
      if case .state(let value) = event {
        states.append(value)
        if value == .string(newRound.uuidString) { break }
      }
    }
    #expect(states == [.string(newRound.uuidString)])
  }

  @Test(.timeLimit(.minutes(1))) func activitySyncDoesNotEnqueueOrReconcileTwiceDuringAFlush() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let disk = LiveDisk(directory: directory), script = DeliveryScript(heldWrites: [0])
    let session = LiveRoundSession(disk: disk, delivery: script), round = UUID(), player = UUID()
    let message = LiveMessage.score(pid: player, hole0: 0, strokes: 4, cts: 10)
    try await disk.commitActivity(card(round: round, player: player), message: message)
    let first = Task { await session.syncSavedRound(round, code: "TEST", authorization: session.captureAuthorization()) }
    await script.writesReached(1)
    #expect(await session.syncSavedRound(round, code: "TEST", authorization: session.captureAuthorization()) == nil)
    #expect(await disk.queue(round).count == 1)
    #expect(await script.writes.count == 1)
    await script.releaseWrite(0)
    #expect(await first.value == 0)
    #expect(await script.writes.count == 1)
    #expect(await script.reads.count == 1)
    #expect(await disk.queue(round).isEmpty)
  }

  @Test(.timeLimit(.minutes(1))) func signOutAndSameOwnerSignInInvalidatesAnAwaitedWrite() async {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let account = DeliveryAccount(), owner = UUID()
    defer { account.remove() }
    account.claim(owner)
    let disk = LiveDisk(directory: directory), script = DeliveryScript(heldWrites: [0])
    let session = LiveRoundSession(disk: disk, delivery: script, authorizationEpoch: { account.epoch() })
    let round = UUID(), player = UUID()
    await session.prepareSavedRound(round, code: "TEST")
    let pending = Task { await session.send(.score(pid: player, hole0: 0, strokes: 4, cts: 10), round: round) }
    await script.writesReached(1)
    // These are the same epoch operations used by SessionStore on sign-out/in.
    account.claim(nil); account.claim(owner)
    await script.releaseWrite(0); await pending.value
    #expect(await session.currentRound == nil)
    #expect(await disk.queue(round).count == 1)
    await session.reconcile()
    #expect(await script.reads.isEmpty)
    await session.prepareSavedRound(round, code: "TEST")
    #expect(await session.synchronize(round: round) == 0)
  }

  @Test func queuedActivityCannotAdoptALaterAccountsAuthorization() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let account = DeliveryAccount(); defer { account.remove() }
    account.claim(UUID())
    let disk = LiveDisk(directory: directory), script = DeliveryScript()
    let session = LiveRoundSession(disk: disk, delivery: script, authorizationEpoch: { account.epoch() })
    let round = UUID(), player = UUID(), authorization = session.captureAuthorization()
    try await disk.commitActivity(card(round: round, player: player),
      message: .score(pid: player, hole0: 0, strokes: 4, cts: 10))
    account.claim(UUID()) // The action has not entered the session actor yet.
    #expect(await session.syncSavedRound(round, code: "TEST", authorization: authorization) == nil)
    #expect(await script.writes.isEmpty)
    #expect(await disk.queue(round).count == 1)
    #expect(await session.currentRound == nil)
  }

  @Test func terminalActivityRetiresWithoutReconciliation() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let disk = LiveDisk(directory: directory), script = DeliveryScript(failures: [0: .terminal])
    let session = LiveRoundSession(disk: disk, delivery: script), round = UUID(), player = UUID()
    try await disk.commitActivity(card(round: round, player: player),
      message: .score(pid: player, hole0: 0, strokes: 4, cts: 10))
    #expect(await session.syncSavedRound(round, code: "TEST", authorization: session.captureAuthorization()) == 0)
    #expect(await disk.snapshotUnsynced(round)?.scores[0][0] == 4)
    #expect(await disk.queue(round).isEmpty)
    #expect(await script.reads.isEmpty)
  }

  @Test func unboundHostEditKeepsSnapshotAndWrongRoundCannotSend() async {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let disk = LiveDisk(directory: directory), script = DeliveryScript()
    let session = LiveRoundSession(disk: disk, delivery: script), round = UUID(), player = UUID()
    let value = card(round: round, player: player)
    let message = LiveMessage.score(pid: player, hole0: 0, strokes: 4, cts: 10)
    await session.submit(value, message: message, guest: nil)
    #expect(await disk.snapshot(round)?.scores[0][0] == 4)
    await session.prepareSavedRound(UUID(), code: "OTHER")
    await session.send(message, round: round)
    #expect(await script.writes.isEmpty)
    #expect(await disk.queue(round).isEmpty)
  }
}

private actor DeliveryScript: LiveDelivery {
  enum Failure { case timeout, terminal }
  struct Write { let message: LiveMessage; let round: UUID; let guest: UUID? }
  private(set) var writes: [Write] = []
  private(set) var reads: [UUID] = []
  let heldWrites: Set<Int>, heldReads: Set<Int>, failures: [Int: Failure]
  private var writeGates: [Int: CheckedContinuation<Void, Never>] = [:]
  private var readGates: [Int: CheckedContinuation<Void, Never>] = [:]
  private var writeObservers: [(Int, CheckedContinuation<Void, Never>)] = []
  private var readObservers: [(Int, CheckedContinuation<Void, Never>)] = []
  init(heldWrites: Set<Int> = [], heldReads: Set<Int> = [], failures: [Int: Failure] = [:]) {
    self.heldWrites = heldWrites; self.heldReads = heldReads; self.failures = failures
  }
  func write(_ message: LiveMessage, round: UUID, guest: UUID?) async throws {
    let index = writes.count
    writes.append(.init(message: message, round: round, guest: guest))
    let ready = writeObservers.filter { $0.0 <= writes.count }
    writeObservers.removeAll { $0.0 <= writes.count }; ready.forEach { $0.1.resume() }
    if heldWrites.contains(index) { await withCheckedContinuation { writeGates[index] = $0 } }
    switch failures[index] {
    case .timeout: throw URLError(.timedOut)
    case .terminal: throw RpcError(name: "live_set_score", underlying: "Round is not live", droppedArgs: [])
    case nil: return
    }
  }
  func read(round: UUID, guest: UUID?) async throws -> JSONValue {
    let index = reads.count; reads.append(round)
    let ready = readObservers.filter { $0.0 <= reads.count }
    readObservers.removeAll { $0.0 <= reads.count }; ready.forEach { $0.1.resume() }
    if heldReads.contains(index) { await withCheckedContinuation { readGates[index] = $0 } }
    return .string(round.uuidString)
  }
  func writesReached(_ count: Int) async {
    if writes.count >= count { return }
    await withCheckedContinuation { writeObservers.append((count, $0)) }
  }
  func readsReached(_ count: Int) async {
    if reads.count >= count { return }
    await withCheckedContinuation { readObservers.append((count, $0)) }
  }
  func releaseWrite(_ index: Int) { writeGates.removeValue(forKey: index)?.resume() }
  func releaseRead(_ index: Int) { readGates.removeValue(forKey: index)?.resume() }
}

/// UserDefaults is thread safe; each test uses its own suite and account epoch.
private final class DeliveryAccount: @unchecked Sendable {
  private let name = "cs.delivery.tests." + UUID().uuidString
  private let defaults: UserDefaults
  init() { defaults = UserDefaults(suiteName: name)! }
  func claim(_ owner: UUID?) { DispatchSnapshot.claim(owner: owner, defaults: defaults) }
  func epoch() -> String? { defaults.string(forKey: BetweenRoundsSnapshot.epochKey) }
  func remove() { defaults.removePersistentDomain(forName: name) }
}
