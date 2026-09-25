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
    #expect(consent.permits(owner))
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
    #expect(consent.permits(owner))
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
