import Testing
import Foundation
@testable import CupSeasonKit

/// D350 (built) · the ordinary post's fault paths, each one a test rather than
/// a promise: a replay that sends the frozen envelope verbatim, an accepted
/// recovery that finishes, a disk that cannot be read or written, an ambiguous
/// failure that keeps the same id, an edited card resolved by asking the
/// server, a server without the function, and an account switch.
@MainActor
@Suite struct OrdinaryPostTests {
  let owner = UUID()
  let request = UUID()

  func card(_ gross: String = "84", course: String = "Papago") -> PostCard {
    var c = PostCard(); c.whole = gross; c.rating = "71.2"; c.slope = "128"; c.course = course; c.date = "2026-09-13"; return c
  }
  func payload(_ c: PostCard) -> PostPayload { PostPayload.build(c, seasonId: nil) }
  func outcome(_ id: UUID = UUID()) -> PostService.PostOutcome { PostService.PostOutcome(roundId: id) }
  func missing() -> RpcError { RpcError(name: "post_round_once", underlying: "PGRST202: could not find the function", droppedArgs: []) }
  func network() -> RpcError { RpcError(name: "post_round_once", underlying: "The request timed out", droppedArgs: []) }

  /// An in-memory disk with switches for every fault.
  final class Disk {
    var files: [String: OfflinePost] = [:]
    var readFails = false
    var saveFails = false
    var saves = 0
    func key(_ o: UUID, _ r: UUID) -> String { o.uuidString + "/" + r.uuidString }
    func read(_ o: UUID, _ r: UUID) throws -> OfflinePost? {
      if readFails { throw OfflineRounds.Failure.invalidCard }
      return files[key(o, r)]
    }
    func save(_ p: OfflinePost) throws {
      if saveFails { throw OfflineRounds.Failure.invalidCard }
      saves += 1; files[key(p.owner, p.request)] = p
    }
  }

  final class Net {
    var posts: [OfflinePost] = []
    var uploads = 0
    var statusCalls = 0
  }

  func ports(_ disk: Disk, net: Net,
             post: @escaping @MainActor (OfflinePost) async throws -> PostService.PostOutcome,
             status: @escaping @MainActor (UUID) async throws -> UUID? = { _ in nil },
             upload: String? = "u/photo.jpg") -> OrdinaryPost.Ports {
    OrdinaryPost.Ports(read: { try disk.read($0, $1) }, save: { try disk.save($0) },
                       status: { net.statusCalls += 1; return try await status($0) },
                       post: { net.posts.append($0); return try await post($0) },
                       upload: { _ in net.uploads += 1; return upload })
  }

  // MARK: - the happy path writes before it sends

  @Test func aFreshEnvelopeIsSavedBeforeTheCallAndAcceptedAfter() async throws {
    let disk = Disk(); let net = Net()
    let id = UUID()
    let c = card()
    let r = await OrdinaryPost.run(owner: owner, request: request, card: c, payload: payload(c), playedWith: [], jpeg: Data([1]),
                                   ports: ports(disk, net: net, post: { _ in self.outcome(id) }))
    #expect(r == .accepted(outcome(id), replayed: false, photoDropped: false, receiptUnsaved: false))
    #expect(disk.saves == 2, "once before the call, once with the acceptance")
    #expect(net.posts.count == 1 && net.uploads == 1)
    #expect(net.posts[0].payload.photo_path == "u/photo.jpg", "the upload's output rides the frozen envelope")
    #expect(try disk.read(owner, request)?.accepted == id)
  }

  // MARK: - replay: the frozen envelope, verbatim, no second upload

  @Test func aRetryAfterAnAmbiguousFailureReplaysTheFrozenEnvelope() async throws {
    let disk = Disk(); let net = Net()
    let c = card()
    var flaky = true
    let p = ports(disk, net: net, post: { _ in
      if flaky { flaky = false; throw self.network() }
      return self.outcome()
    })
    let first = await OrdinaryPost.run(owner: owner, request: request, card: c, payload: payload(c), playedWith: [], jpeg: Data([1]), ports: p)
    guard case .failed(let msg) = first else { Issue.record("expected an ambiguous failure, got \(first)"); return }
    #expect(msg.hasPrefix(OrdinaryPost.ambiguousPrefix))
    #expect(try disk.read(owner, request)?.accepted == nil, "the envelope is frozen and unresolved")
    // the golfer presses Post again: same id, same envelope, no new upload
    let second = await OrdinaryPost.run(owner: owner, request: request, card: c, payload: payload(c), playedWith: [], jpeg: Data([1]), ports: p)
    guard case .accepted(_, let replayed, _, _) = second else { Issue.record("expected acceptance, got \(second)"); return }
    #expect(replayed)
    #expect(net.uploads == 1, "the photo is uploaded once; the frozen path is reused")
    #expect(net.posts.count == 2 && net.posts[0] == net.posts[1], "the SAME envelope, byte for byte")
    #expect(net.statusCalls == 0, "a matching card never needs to ask")
  }

  // MARK: - accepted recovery finishes; nothing is sent

  @Test func anEnvelopeTheDiskSaysLandedIsFinishedNotResent() async throws {
    let disk = Disk(); let net = Net()
    let c = card(); let landed = UUID()
    var done = OfflinePost(owner: owner, request: request, card: c, payload: payload(c), playedWith: []); done.accepted = landed
    try disk.save(done)
    let r = await OrdinaryPost.run(owner: owner, request: request, card: c, payload: payload(c), playedWith: [], jpeg: nil,
                                   ports: ports(disk, net: net, post: { _ in Issue.record("must not post"); return self.outcome() }))
    #expect(r == .alreadyPosted(landed))
    #expect(net.posts.isEmpty && net.uploads == 0)
  }

  // MARK: - storage faults stop the network

  @Test func aDiskThatCannotBeReadSendsNothing() async {
    let disk = Disk(); disk.readFails = true; let net = Net()
    let c = card()
    let r = await OrdinaryPost.run(owner: owner, request: request, card: c, payload: payload(c), playedWith: [], jpeg: Data([1]),
                                   ports: ports(disk, net: net, post: { _ in self.outcome() }))
    #expect(r == .storageFailed(OrdinaryPost.readFailed))
    #expect(net.posts.isEmpty && net.uploads == 0, "not even the upload runs")
  }

  @Test func aDiskThatCannotBeWrittenSendsNothing() async {
    let disk = Disk(); disk.saveFails = true; let net = Net()
    let c = card()
    let r = await OrdinaryPost.run(owner: owner, request: request, card: c, payload: payload(c), playedWith: [], jpeg: nil,
                                   ports: ports(disk, net: net, post: { _ in self.outcome() }))
    #expect(r == .storageFailed(OrdinaryPost.saveFailed))
    #expect(net.posts.isEmpty, "the envelope must exist before the call, or the call is not made")
  }

  @Test func anAcceptanceThatCannotBeRecordedIsStillAnAcceptanceAndSaysSo() async throws {
    let disk = Disk(); let net = Net()
    let c = card()
    // the pre-call save works; the post-call save fails
    var calls = 0
    let p = OrdinaryPost.Ports(read: { try disk.read($0, $1) },
                               save: { calls += 1; if calls == 2 { throw OfflineRounds.Failure.invalidCard }; try disk.save($0) },
                               status: { _ in nil }, post: { p in net.posts.append(p); return self.outcome() }, upload: { _ in nil })
    let r = await OrdinaryPost.run(owner: owner, request: request, card: c, payload: payload(c), playedWith: [], jpeg: nil, ports: p)
    guard case .accepted(_, _, _, let unsaved) = r else { Issue.record("expected acceptance, got \(r)"); return }
    #expect(unsaved, "the composer must warn against a re-post")
  }

  // MARK: - an edited card is resolved by asking, never by guessing

  @Test func anEditedCardWhoseEarlierRequestLandedIsANewRound() async throws {
    let disk = Disk(); let net = Net()
    let original = card("84"); let landed = UUID()
    try disk.save(OfflinePost(owner: owner, request: request, card: original, payload: payload(original), playedWith: []))
    let edited = card("48")
    let r = await OrdinaryPost.run(owner: owner, request: request, card: edited, payload: payload(edited), playedWith: [], jpeg: nil,
                                   ports: ports(disk, net: net, post: { _ in Issue.record("must not post"); return self.outcome() },
                                                status: { _ in landed }))
    #expect(r == .earlierPosted(landed))
    #expect(net.posts.isEmpty && net.statusCalls == 1)
    #expect(try disk.read(owner, request)?.accepted == landed, "the old envelope is marked landed so it can never be replayed")
  }

  @Test func anEditedCardWhoseEarlierRequestNeverLandedReleasesTheId() async throws {
    let disk = Disk(); let net = Net()
    let original = card("84")
    try disk.save(OfflinePost(owner: owner, request: request, card: original, payload: payload(original), playedWith: []))
    let edited = card("48")
    let r = await OrdinaryPost.run(owner: owner, request: request, card: edited, payload: payload(edited), playedWith: [], jpeg: nil,
                                   ports: ports(disk, net: net, post: { _ in Issue.record("must not post under the old id"); return self.outcome() },
                                                status: { _ in nil }))
    #expect(r == .staleRequest)
    #expect(net.posts.isEmpty, "the old id is never reused for a different card")
    // the composer then runs again under a fresh id, and THAT posts
    let fresh = UUID()
    let r2 = await OrdinaryPost.run(owner: owner, request: fresh, card: edited, payload: payload(edited), playedWith: [], jpeg: nil,
                                    ports: ports(disk, net: net, post: { _ in self.outcome() }))
    guard case .accepted = r2 else { Issue.record("expected acceptance under the fresh id, got \(r2)"); return }
    #expect(net.posts.count == 1 && net.posts[0].request == fresh)
  }

  @Test func aStatusReadThatFailsKeepsTheRequestAndSendsNothing() async throws {
    let disk = Disk(); let net = Net()
    let original = card("84")
    try disk.save(OfflinePost(owner: owner, request: request, card: original, payload: payload(original), playedWith: []))
    let edited = card("48")
    let r = await OrdinaryPost.run(owner: owner, request: request, card: edited, payload: payload(edited), playedWith: [], jpeg: nil,
                                   ports: ports(disk, net: net, post: { _ in self.outcome() }, status: { _ in throw self.network() }))
    guard case .failed = r else { Issue.record("expected a failure, got \(r)"); return }
    #expect(net.posts.isEmpty)
    #expect(try disk.read(owner, request)?.accepted == nil, "still frozen, still unresolved")
  }

  @Test func aChangedPartnerListIsADifferentCard() async throws {
    let disk = Disk(); let net = Net()
    let c = card(); let mate = UUID()
    try disk.save(OfflinePost(owner: owner, request: request, card: c, payload: payload(c), playedWith: []))
    let r = await OrdinaryPost.run(owner: owner, request: request, card: c, payload: payload(c), playedWith: [mate], jpeg: nil,
                                   ports: ports(disk, net: net, post: { _ in self.outcome() }, status: { _ in nil }))
    #expect(r == .staleRequest, "who was out there is part of the envelope; it is not silently replayed")
  }

  // MARK: - an older server is fail-closed, with nothing else tried

  @Test func aServerWithoutTheFunctionIsToldNotRoutedAround() async throws {
    let disk = Disk(); let net = Net()
    let c = card()
    let r = await OrdinaryPost.run(owner: owner, request: request, card: c, payload: payload(c), playedWith: [], jpeg: nil,
                                   ports: ports(disk, net: net, post: { _ in throw self.missing() }))
    #expect(r == .notAvailable)
    #expect(net.posts.count == 1, "one attempt, and it was the deduplicating one")
    #expect(try disk.read(owner, request) != nil, "the frozen envelope stays for after the update")
    #expect(try disk.read(owner, request)?.accepted == nil)
  }

  @Test func aServerWithoutTheStatusFunctionIsAlsoFailClosed() async throws {
    let disk = Disk(); let net = Net()
    let original = card("84")
    try disk.save(OfflinePost(owner: owner, request: request, card: original, payload: payload(original), playedWith: []))
    let edited = card("48")
    let r = await OrdinaryPost.run(owner: owner, request: request, card: edited, payload: payload(edited), playedWith: [], jpeg: nil,
                                   ports: ports(disk, net: net, post: { _ in self.outcome() }, status: { _ in throw self.missing() }))
    #expect(r == .notAvailable)
    #expect(net.posts.isEmpty)
  }

  // MARK: - the identity outlives the draft and belongs to one golfer

  @Test func theRequestStoreIsOwnerScoped() {
    let name = "ordinary-post-\(UUID())"
    let d = UserDefaults(suiteName: name)!
    defer { d.removePersistentDomain(forName: name) }
    let a = UUID(), b = UUID(), id = UUID()
    PostRequestStore.set(id, owner: a, defaults: d)
    #expect(PostRequestStore.pending(owner: a, defaults: d) == id)
    #expect(PostRequestStore.pending(owner: b, defaults: d) == nil, "another account on this phone sees no pending request")
    PostRequestStore.clear(owner: b, defaults: d)
    #expect(PostRequestStore.pending(owner: a, defaults: d) == id, "and cannot clear somebody else's")
    PostRequestStore.clear(owner: a, defaults: d)
    #expect(PostRequestStore.pending(owner: a, defaults: d) == nil)
  }

  @Test func aSentDraftDoesNotExpire() throws {
    var c = card()
    c.whole = "84"
    let stale = Date().addingTimeInterval(-(PostDraft.ttl + 86400))
    let sent = try #require(PostDraft.encode(PostDraft(at: stale, card: c, request: UUID())))
    let unsent = try #require(PostDraft.encode(PostDraft(at: stale, card: c)))
    #expect(PostDraft.decode(sent)?.request != nil, "a draft that was sent carries an id the server may hold")
    #expect(PostDraft.decode(unsent) == nil, "a draft that was never sent still ages out")
  }

  @Test func theDiskRefusesAnotherOwnersEnvelope() throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("ordinary-\(UUID())")
    defer { try? FileManager.default.removeItem(at: dir) }
    let disk = OfflinePostDisk(directory: dir)
    let c = card()
    try disk.save(OfflinePost(owner: owner, request: request, card: c, payload: payload(c), playedWith: []))
    #expect(try disk.read(owner: UUID(), request: request) == nil, "an account switch finds nothing to replay")
    #expect(try disk.read(owner: owner, request: request) != nil)
  }
}
