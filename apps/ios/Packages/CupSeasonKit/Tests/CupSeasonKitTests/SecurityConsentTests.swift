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
    let owner = UUID()
    let consent = ScanConsentStore(defaults: defaults(), read: { _ in throw Failure.offline }, write: { _ in throw Failure.offline })
    await consent.load(owner: owner)
    #expect(!consent.permits(owner))
    #expect(!consent.pendingSync)
    let serverSaved = await consent.set(true, owner: owner)
    #expect(!serverSaved)
    // D403 · the golfer's yes is kept on this phone for a retry, but a yes
    // the server never took is not consent the scan function can see
    #expect(consent.allowed)
    #expect(!consent.permits(owner))
    #expect(consent.localYesPending(owner))
    #expect(consent.pendingSync)
    #expect(!consent.permits(UUID()))
  }

  @Test func fallbackConsentIsScopedAndRevocationWinsOnThisPhone() async {
    let d = defaults(), owner = UUID(), other = UUID()
    let consent = ScanConsentStore(defaults: d, read: { _ in false }, write: { _ in throw Failure.offline })
    await consent.load(owner: owner)
    await consent.set(true, owner: owner)
    consent.reset()
    await consent.load(owner: other)
    #expect(!consent.permits(other))
    await consent.load(owner: owner)
    #expect(consent.localYesPending(owner) && !consent.permits(owner))   // D403 · kept, never permitting
    await consent.set(false, owner: owner)
    #expect(!consent.permits(owner))
    consent.reset()
    await consent.load(owner: owner)
    #expect(!consent.permits(owner))
  }

  @Test func pendingChoiceSyncsAndThenTheServerOwnsIt() async {
    let d = defaults(), owner = UUID()
    let offline = ScanConsentStore(defaults: d, read: { _ in false }, write: { _ in throw Failure.offline })
    await offline.load(owner: owner); await offline.set(true, owner: owner)
    var writes: [Bool] = []
    let online = ScanConsentStore(defaults: d, read: { _ in false }, write: { value in writes.append(value); return value })
    await online.load(owner: owner)
    #expect(writes == [true]); #expect(online.permits(owner)); #expect(!online.pendingSync)
    await online.load(owner: owner)
    #expect(!online.permits(owner)) // A server-side revocation takes effect.
  }

  /// D403 · the scan door, as a decision. The `scan` function reads the
  /// stored consent itself, so the phone never scans without the server's yes:
  /// a yes only this phone holds is written once more, and otherwise the
  /// golfer meets the existing sheet again.
  @Test func theScanDoorNeverScansWithoutTheServersYes() {
    #expect(ScanConsentGate.before(serverYes: true, localYesPending: false, retried: false) == .scan)
    #expect(ScanConsentGate.before(serverYes: false, localYesPending: true, retried: false) == .retryYes)
    #expect(ScanConsentGate.before(serverYes: false, localYesPending: true, retried: true) == .ask)
    #expect(ScanConsentGate.before(serverYes: false, localYesPending: false, retried: false) == .ask)
    // a refusal for consent overrides what this phone believed: a yes given
    // here is written once more, and after that one retry it is "not saved"
    #expect(ScanConsentGate.after(refusal: "no_consent", saidYesHere: true, retried: false) == .retryYes)
    #expect(ScanConsentGate.after(refusal: "no_consent", saidYesHere: true, retried: true) == .ask)
    #expect(ScanConsentGate.after(refusal: "no_consent", saidYesHere: false, retried: false) == .ask)
    #expect(ScanConsentGate.after(refusal: "account_closed", saidYesHere: true, retried: false) == .closed)
    // every other refusal is the composer's ordinary toast
    #expect(ScanConsentGate.after(refusal: "daily_cap", saidYesHere: false, retried: false) == nil)
    #expect(ScanConsentGate.after(refusal: nil, saidYesHere: false, retried: false) == nil)
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

  /// D403 · on a consent refusal the device-only yes is dropped and the yes is
  /// written ONCE: it permits only if the server took it, and a failed re-save
  /// leaves no yes anywhere — not a phone-only one refused on every scan.
  @Test func aConsentRefusalHandsTheTruthToTheServer() async {
    let owner = UUID()
    var writes: [Bool] = []
    let online = ScanConsentStore(defaults: defaults(), read: { _ in true }, write: { writes.append($0); return $0 })
    await online.load(owner: owner)
    #expect(await online.reconfirm(owner: owner))
    #expect(writes == [true]); #expect(online.permits(owner))

    let d = defaults()
    let offline = ScanConsentStore(defaults: d, read: { _ in false }, write: { _ in throw Failure.offline })
    await offline.load(owner: owner); await offline.set(true, owner: owner)
    #expect(offline.localYesPending(owner))
    #expect(await offline.reconfirm(owner: owner) == false)
    #expect(!offline.permits(owner) && !offline.allowed && !offline.pendingSync)
    // nothing is left on the phone to pass for consent on the next load
    let next = ScanConsentStore(defaults: d, read: { _ in false }, write: { _ in throw Failure.offline })
    await next.load(owner: owner)
    #expect(!next.allowed && !next.permits(owner))
    // and a different golfer's store is never reconfirmed
    #expect(await offline.reconfirm(owner: UUID()) == false)
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
