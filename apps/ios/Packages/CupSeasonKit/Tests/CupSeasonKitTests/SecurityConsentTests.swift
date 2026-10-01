import Foundation
import Testing
@testable import CupSeasonKit

@Suite @MainActor struct SecurityConsentTests {
  private func defaults() -> UserDefaults { UserDefaults(suiteName: "security-test-\(UUID())")! }
  private enum Failure: Error { case offline }

  @Test func signingOutClearsEveryPendingAction() {
    let d = defaults(), token = UUID()
    JoinIntent.store("TEST", defaults: d)
    ClaimIntent.store(token.uuidString, defaults: d)
    for kind in ShareIntent.allCases { kind.store(token, defaults: d) }
    SessionActionCleanup.clear(defaults: d)
    #expect(JoinIntent.pending(defaults: d) == nil)
    #expect(ClaimIntent.pending(defaults: d) == nil)
    #expect(ShareIntent.allCases.allSatisfy { $0.pending(defaults: d) == nil })
  }

  @Test func linkConsentIsForExactlyOneTokenAndOneGolfer() {
    let d = defaults(), token = UUID(), next = UUID(), owner = UUID()
    ShareIntent.person.store(token, defaults: d)
    let card = LinkConfirmation(kind: .person, token: token, owner: owner, info: .object(["name": .string("Alex")]))
    #expect(card.isCurrent(owner: owner, defaults: d))
    #expect(!card.isCurrent(owner: UUID(), defaults: d))
    ShareIntent.person.store(next, defaults: d)
    #expect(!card.isCurrent(owner: owner, defaults: d))
    card.clear(defaults: d)
    #expect(ShareIntent.person.pending(defaults: d) == next)
  }

  @Test func aLateClaimCannotClearTheNextCard() {
    let d = defaults(), old = UUID(), next = UUID()
    ClaimIntent.store(next.uuidString, defaults: d)
    ClaimIntent.clear(ifMatching: old, defaults: d)
    #expect(ClaimIntent.pending(defaults: d) == next)
    ClaimIntent.clear(ifMatching: next, defaults: d)
    #expect(ClaimIntent.pending(defaults: d) == nil)
  }

  @Test func claimsWithoutMatchingConsentNeverReachTheNetwork() async {
    let d = defaults(), token = UUID()
    ClaimIntent.store(token.uuidString, defaults: d)
    let result = await ClaimFlow.consume(confirmedToken: UUID(), defaults: d)
    #expect(result == .nothing)
    let switched = await ClaimFlow.consume(confirmedToken: token, stillAuthorized: { false }, defaults: d)
    #expect(switched == .nothing)
    #expect(ClaimIntent.pending(defaults: d) == token)
  }

  @Test func scanDoesNotAcquirePermissionFromAReadFailure() async {
    let owner = UUID(), d = defaults()
    let consent = ScanConsentStore(defaults: d, read: { _ in throw Failure.offline }, write: { _ in throw Failure.offline })
    await consent.load(owner: owner)
    #expect(!consent.permits(owner))
    #expect(!consent.pendingSync)
    let serverSaved = await consent.set(true, owner: owner)
    #expect(!serverSaved)
    // D403 (corrected) · a yes the server did not take is reported and kept
    // nowhere — not on screen, not on the phone
    #expect(!consent.allowed)
    #expect(!consent.permits(owner))
    #expect(!consent.pendingSync)
    #expect(d.object(forKey: "cs_scan_consent.\(owner.uuidString.lowercased())") == nil)
    #expect(!consent.permits(UUID()))
  }

  @Test func aFailedNoIsKeptAndResentAndRevocationWinsOnThisPhone() async {
    let d = defaults(), owner = UUID(), other = UUID()
    let offline = ScanConsentStore(defaults: d, read: { $0 == owner }, write: { _ in throw Failure.offline })
    await offline.load(owner: owner)
    #expect(offline.permits(owner))
    #expect(await offline.set(false, owner: owner) == false)
    #expect(!offline.permits(owner) && offline.pendingSync)
    offline.reset()
    await offline.load(owner: other)
    #expect(!offline.permits(other) && !offline.pendingSync)      // scoped to its golfer
    var writes: [Bool] = []
    let online = ScanConsentStore(defaults: d, read: { _ in true }, write: { writes.append($0); return $0 })
    await online.load(owner: owner)
    #expect(writes == [false])                                    // the "no" is resent, not read over
    #expect(!online.permits(owner) && !online.pendingSync)
  }

  /// An older build kept a yes on the phone when its write failed. That yes is
  /// not a choice made for any scan now, so it is dropped unwritten.
  @Test func aCachedYesFromAnOlderBuildIsNeverWritten() async {
    let d = defaults(), owner = UUID()
    d.set(true, forKey: "cs_scan_consent.\(owner.uuidString.lowercased())")
    var writes: [Bool] = []
    let consent = ScanConsentStore(defaults: d, read: { _ in false }, write: { writes.append($0); return $0 })
    await consent.load(owner: owner)
    #expect(writes.isEmpty)
    #expect(!consent.permits(owner))
    #expect(d.object(forKey: "cs_scan_consent.\(owner.uuidString.lowercased())") == nil)
  }

  /// D403 · the scan door, as a decision. The phone never scans without the
  /// server's yes, never writes a yes the golfer did not just tap, and stops
  /// after one rescan on a fresh yes.
  @Test func theScanDoorNeverScansWithoutTheServersYes() {
    #expect(ScanConsentGate.before(serverYes: true) == .scan)
    #expect(ScanConsentGate.before(serverYes: false) == .ask)
    #expect(ScanConsentGate.after(refusal: "no_consent", freshYes: false) == .ask)
    #expect(ScanConsentGate.after(refusal: "no_consent", freshYes: true) == .notSaved)
    #expect(ScanConsentGate.after(refusal: "account_closed", freshYes: true) == .closed)
    // every other refusal is the composer's ordinary toast
    #expect(ScanConsentGate.after(refusal: "daily_cap", freshYes: false) == nil)
    #expect(ScanConsentGate.after(refusal: nil, freshYes: false) == nil)
    #expect(ScanConsentCopy.notSaved == "Your yes to scanning didn’t save — type your nines in, or try the scan again.")
  }

  /// D403 · the refusal's reason is read off the 403's body — the SDK throws
  /// on a non-2xx, so without this a missing consent read as a dropped line.
  @Test func aRefusedScanNamesItsReason() {
    #expect(PostService.scanRefusalReason(Data(#"{"unavailable":true,"reason":"no_consent"}"#.utf8)) == "no_consent")
    #expect(PostService.scanRefusalReason(Data(#"{"unavailable":true,"reason":"account_closed"}"#.utf8)) == "account_closed")
    #expect(PostService.scanRefusalReason(Data(#"{"error":"boom"}"#.utf8)) == nil)
    #expect(PostService.scanRefusalReason(Data("not json".utf8)) == nil)
  }

  /// The review's regression, end to end over one shared server: grant on
  /// device A, load device B, revoke on A, scan on B. B writes nothing and
  /// nothing is scanned until the golfer taps yes again; then exactly one
  /// write and one rescan.
  @Test func aRevocationElsewhereIsNeverUndoneByAStaleDevice() async {
    let owner = UUID()
    final class Server: @unchecked Sendable { var consent = false; var writes: [Bool] = []; var provider = 0 }
    let server = Server()
    func device() -> ScanConsentStore {
      ScanConsentStore(defaults: defaults(), read: { _ in server.consent },
                       write: { server.writes.append($0); server.consent = $0; return $0 })
    }
    /// the scan function: refuses without the stored yes, before any provider call
    func scan() -> String? { if !server.consent { return "no_consent" }; server.provider += 1; return nil }

    let a = device(), b = device()
    await a.load(owner: owner)
    #expect(await a.set(true, owner: owner))                      // granted on A
    await b.load(owner: owner)
    #expect(b.permits(owner))                                     // B opened with the yes
    #expect(await a.set(false, owner: owner))                     // revoked on A
    let writes = server.writes.count

    // B scans on what it believed: refused; the gate asks; nothing written
    let refusal = scan()
    let gate = ScanConsentGate.after(refusal: refusal, freshYes: false)
    #expect(gate == .ask)
    b.serverRefused(owner: owner)
    #expect(!b.permits(owner))
    #expect(server.writes.count == writes)
    #expect(server.provider == 0)
    #expect(server.consent == false)                              // the revocation stands

    // a fresh tap on the sheet: one write, one rescan
    #expect(await b.set(true, owner: owner))
    #expect(scan() == nil)
    #expect(server.writes.count == writes + 1)
    #expect(server.provider == 1)
  }

  /// D403 (review of 0e463792) · a scan is the starting golfer's, end to end: once the
  /// signed-in golfer changes or signs out, nothing is sent and no answer is applied.
  @Test func aScanBelongsToTheGolferWhoStartedIt() {
    let a = UUID(), b = UUID()
    let attempt = ScanAttempt(owner: a)
    #expect(attempt.isCurrent(a))
    #expect(!attempt.isCurrent(b))      // another golfer signed in mid-scan
    #expect(!attempt.isCurrent(nil))    // signed out mid-scan
  }

  /// A refusal orphans a write or read in flight: it cannot land a yes afterwards.
  @Test func aRefusalOrphansAnInFlightRead() async {
    var answer: CheckedContinuation<Bool, Never>?
    let owner = UUID()
    let consent = ScanConsentStore(defaults: defaults(), read: { _ in
      await withCheckedContinuation { answer = $0 }
    }, write: { $0 })
    let read = Task { await consent.load(owner: owner) }
    while answer == nil { await Task.yield() }
    consent.serverRefused(owner: owner)
    answer?.resume(returning: true)
    await read.value
    #expect(!consent.permits(owner))
    // and a refusal for another golfer touches nothing
    consent.serverRefused(owner: UUID())
    #expect(consent.owner == owner)
  }

  @Test func scanReadCannotResurrectAnAccountAfterSignOut() async {
    var answer: CheckedContinuation<Bool, Never>?
    let consent = ScanConsentStore(defaults: defaults(), read: { _ in
      await withCheckedContinuation { answer = $0 }
    }, write: { $0 })
    let owner = UUID()
    let read = Task { await consent.load(owner: owner) }
    while answer == nil { await Task.yield() }
    consent.reset()
    answer?.resume(returning: true)
    await read.value
    #expect(consent.owner == nil); #expect(!consent.permits(owner))
  }

  @Test func commentsReportTheirOwnIdentityAndKind() throws {
    for kind in [CommentSafety.Kind.comment, .roundComment] {
      let id = UUID(), author = UUID()
      let call = CommentSafety(id: id, kind: kind, author: author, name: "Alex").report(reason: String(repeating: "a", count: 600))
      #expect(call.p_comment == id); #expect(call.p_kind == kind.rawValue)
      #expect(call.p_post == nil); #expect(call.p_profile == nil)
      #expect(call.p_reason?.count == 500)
    }
  }

  @Test func planCommentsDecodeStableIdentityAndTolerateOldServers() throws {
    let id = UUID(), comment = UUID(), author = UUID()
    let detail = try #require(RoundDetail(.object(["id": .string(id.uuidString), "comments": .array([
      .object(["id": .string(comment.uuidString), "profile_id": .string(author.uuidString), "name": .string("Alex"), "body": .string("See you there")]),
      .object(["name": .string("Old row"), "body": .string("No invented report id")])
    ])])))
    #expect(detail.comments[0].commentId == comment); #expect(detail.comments[0].profileId == author)
    #expect(detail.comments[1].commentId == nil)
  }
  @Test func restrictedTourCardIsNotAZeroRoundRecord() {
    let card = TourCard.parse(.object([
      "visible": .bool(true), "stranger": .bool(true),
      "profile": .object(["display_name": .string("Alex"), "city": .null, "home_course": .null, "index_current": .null]),
      "career": .object(["rounds": .number(0)]), "recent": .array([])
    ]))
    #expect(card.visible && card.stranger)
    #expect(card.profile.city == nil && card.profile.homeCourse == nil && card.profile.indexCurrent == nil)
    #expect(!TourCard.parse(.object(["visible": .bool(true)])).stranger)
  }

}
