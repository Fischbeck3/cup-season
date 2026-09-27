import Foundation
import Testing
@testable import CupSeasonKit

@Suite struct ReceiptLoaderTests {
  private let id = UUID()
  private func social(course: String? = "course-7", gross: Int = 84) -> PostedRoundThread {
    PostedRoundThread(.object([
      "ok": .bool(true), "can_comment": .bool(true),
      "round": .object([
        "gross": .number(Double(gross)), "holes": .number(18),
        "course": .object(["api_course_id": course.map(JSONValue.string) ?? .null, "name": .string("Home course")]),
        "owner": .object(["id": .string(id.uuidString), "marker": .string("oak")]),
        "played_on": .string("2026-09-20"), "is_mine": .bool(false)
      ])
    ]))
  }

  private func collect(_ source: ReceiptScript, seed: ReceiptSeed? = nil, focus: UUID? = nil) async -> [ReceiptLoadUpdate] {
    var result: [ReceiptLoadUpdate] = []
    for await update in ReceiptLoader(source: source).updates(for: id, seed: seed, focusComment: focus) { result.append(update) }
    return result
  }

  private func details(_ updates: [ReceiptLoadUpdate]) throws -> ReceiptDetails {
    try #require(updates.compactMap { if case .details(let value) = $0 { value } else { nil } }.first)
  }

  @Test func scoringEnrichesWithoutErasingSocialCourseOrRefetchingConversation() async throws {
    let focus = UUID(), thread = social()
    let source = ReceiptScript(thread: thread, payload: .object(["gross": .number(82), "points": .null]))
    let answer = try details(await collect(source, seed: ReceiptSeed(id: id, points: 20, marker: "oak"), focus: focus))
    #expect(answer.courseId == "course-7")
    #expect(answer.seed?.gross == 82)
    #expect(answer.seed?.points == nil)
    #expect(answer.seed?.marker == "oak")
    #expect(answer.conversation == thread)
    #expect(!answer.failed)
    #expect(await source.focus == focus)
    #expect(await source.calls.filter { $0 == "thread" }.count == 1)
  }

  @Test func deniedRoundStopsBeforeReadingCacheScoringOrPhotos() async {
    let source = ReceiptScript(thread: PostedRoundThread(.object(["ok": .bool(false)])))
    let updates = await collect(source, seed: ReceiptSeed(id: id, gross: 80, photoPath: "private/photo"))
    #expect(updates.count == 1)
    if case .unavailable = updates.first {} else { Issue.record("A denied round must clear the receipt") }
    #expect(await source.calls == ["thread"])
  }

  @Test func friendRoundUsesSocialFactsWhenScoringIsInaccessible() async throws {
    let source = ReceiptScript(thread: social())
    let answer = try details(await collect(source, seed: ReceiptSeed(id: id, gross: 90, points: 30)))
    #expect(answer.seed?.gross == 84)
    #expect(answer.seed?.points == nil)
    #expect(answer.seed?.profileId == id)
    #expect(answer.seed?.marker == "oak")
    #expect(answer.seed?.courseLabel == "Home course")
    #expect(answer.courseId == "course-7")
    #expect(!answer.failed)
    #expect(await source.cardGross == 84)
    #expect(await source.cardHoles == 18)
  }

  @Test func offlineReceiptKeepsCachedFactsWithoutInventingCourseIdentity() async throws {
    let cached = ReceiptSeed(id: id, gross: 85, courseLabel: "Named course", holesPlayed: 18)
    let source = ReceiptScript(cached: cached)
    let updates = await collect(source)
    if case .preview(let shown) = updates.first { #expect(shown == cached) }
    else { Issue.record("The saved receipt should appear before enrichment") }
    let answer = try details(updates)
    #expect(answer.seed == cached)
    #expect(answer.courseId == nil)
    #expect(answer.conversation == nil)
    #expect(!answer.failed)
  }

  @Test func unavailableOptionalServicesDoNotHideReceiptAndCardComesLast() async throws {
    let source = ReceiptScript(payload: .object(["gross": .number(81), "holes_played": .number(18)]))
    let updates = await collect(source, seed: ReceiptSeed(id: id, photoPath: "missing/photo"))
    let answer = try details(updates)
    #expect(answer.seed?.gross == 81)
    #expect(answer.seed?.photoURL == nil)
    #expect(answer.tally == nil)
    #expect(!answer.failed)
    if case .scorecard(nil) = updates.last {} else { Issue.record("An absent scorecard should be independent of receipt facts") }
    #expect(await source.cardGross == 81)
  }

  @Test func scoringCourseIsUsedOnlyWhenSocialRecordHasNone() async throws {
    let payload: JSONValue = .object(["gross": .number(82), "api_course_id": .string("scoring-course")])
    let withSocial = try details(await collect(ReceiptScript(thread: social(), payload: payload)))
    let withoutSocialID = try details(await collect(ReceiptScript(thread: social(course: nil), payload: payload)))
    #expect(withSocial.courseId == "course-7")
    #expect(withoutSocialID.courseId == "scoring-course")
  }

  @Test func failedReadsWithoutFactsOfferRetry() async throws {
    let answer = try details(await collect(ReceiptScript()))
    #expect(answer.failed)
    #expect(answer.seed == nil)
    #expect(answer.courseId == nil)
  }

  @Test(.timeLimit(.minutes(1))) func receiptArrivesBeforeSlowCardAndDismissalCancelsTheRead() async throws {
    let gate = AsyncStream<Void>.makeStream()
    let started = AsyncStream<Void>.makeStream()
    let ended = AsyncStream<Void>.makeStream()
    let shown = AsyncStream<Void>.makeStream()
    defer {
      gate.continuation.finish(); started.continuation.finish(); ended.continuation.finish(); shown.continuation.finish()
    }
    let source = ReceiptScript(payload: .object(["gross": .number(81)]),
      cardGate: gate.stream, cardStarted: started.continuation, cardEnded: ended.continuation)
    let consumer = Task {
      var updates: [ReceiptLoadUpdate] = []
      for await update in ReceiptLoader(source: source).updates(for: id, seed: nil) {
        updates.append(update)
        if case .details = update { shown.continuation.yield(()) }
      }
      return updates
    }
    var visible = shown.stream.makeAsyncIterator()
    _ = await visible.next()
    var start = started.stream.makeAsyncIterator()
    _ = await start.next()
    consumer.cancel()
    var end = ended.stream.makeAsyncIterator()
    _ = await end.next()
    let updates = await consumer.value
    #expect(try details(updates).seed?.gross == 81)
    #expect(!updates.contains { if case .scorecard = $0 { true } else { false } })
    #expect(await source.cardWasCancelled)
  }
}

private actor ReceiptScript: ReceiptReading {
  enum Failure: Error { case offline }
  let social: PostedRoundThread?
  let payload: JSONValue?
  let saved: ReceiptSeed?
  let cardGate: AsyncStream<Void>?
  let cardStarted: AsyncStream<Void>.Continuation?
  let cardEnded: AsyncStream<Void>.Continuation?
  var calls: [String] = []
  var focus: UUID?
  var cardGross: Int?
  var cardHoles: Int?
  var cardWasCancelled = false
  init(thread: PostedRoundThread? = nil, payload: JSONValue? = nil, cached: ReceiptSeed? = nil,
       cardGate: AsyncStream<Void>? = nil, cardStarted: AsyncStream<Void>.Continuation? = nil,
       cardEnded: AsyncStream<Void>.Continuation? = nil) {
    social = thread; self.payload = payload; saved = cached
    self.cardGate = cardGate; self.cardStarted = cardStarted; self.cardEnded = cardEnded
  }
  func thread(_ id: UUID, focus: UUID?) throws -> PostedRoundThread {
    calls.append("thread"); self.focus = focus
    guard let social else { throw Failure.offline }; return social
  }
  func cached(_ id: UUID) -> ReceiptSeed? { calls.append("cache"); return saved }
  func roundCard(_ id: UUID) throws -> JSONValue {
    calls.append("scoring")
    guard let payload else { throw Failure.offline }; return payload
  }
  func signedURL(_ path: String) -> URL? { calls.append("photo"); return nil }
  func tally(_ id: UUID) throws -> String? { calls.append("tally"); throw Failure.offline }
  func scorecard(_ id: UUID, gross: Int?, holes: Int?) async -> RoundScorecard? {
    calls.append("scorecard"); cardGross = gross; cardHoles = holes
    if let cardGate {
      cardStarted?.yield(())
      for await _ in cardGate { }
    }
    cardWasCancelled = Task.isCancelled
    cardEnded?.yield(())
    return nil
  }
}
