import Foundation

/// The enriched receipt and the conversation that established its visibility.
/// Course identity belongs to the social record when the scoring payload omits it.
public struct ReceiptDetails: Sendable {
  public let seed: ReceiptSeed?
  public let courseId: String?
  public let tally: String?
  public let conversation: PostedRoundThread?
  public let failed: Bool
}

/// A late scorecard updates only the card, so it cannot undo a photo edit made
/// after the receipt appeared. A denied social read clears even a caller's seed.
public enum ReceiptLoadUpdate: Sendable {
  case preview(ReceiptSeed)
  case details(ReceiptDetails)
  case scorecard(RoundScorecard?)
  case unavailable
}

public struct ReceiptLoader: Sendable {
  private let source: any ReceiptReading

  public init() { source = ReceiptServices() }
  init(source: any ReceiptReading) { self.source = source }

  public func updates(for roundId: UUID, seed: ReceiptSeed?, focusComment: UUID? = nil) -> AsyncStream<ReceiptLoadUpdate> {
    AsyncStream { continuation in
      let task = Task {
        await load(roundId, seed: seed, focusComment: focusComment, into: continuation)
        continuation.finish()
      }
      continuation.onTermination = { @Sendable _ in task.cancel() }
    }
  }

  private func load(_ roundId: UUID, seed initial: ReceiptSeed?, focusComment: UUID?,
                    into updates: AsyncStream<ReceiptLoadUpdate>.Continuation) async {
    let social = try? await source.thread(roundId, focus: focusComment)
    guard !Task.isCancelled else { return }
    if let social, !social.visible { updates.yield(.unavailable); return }

    var seed = initial
    var courseId = social?.courseId
    if seed == nil, let cached = await source.cached(roundId) {
      seed = cached
      guard !Task.isCancelled else { return }
      updates.yield(.preview(cached))
    }
    async let payload = source.roundCard(roundId)
    if seed?.photoURL == nil, let path = seed?.photoPath, let url = await source.signedURL(path) {
      seed?.photoURL = url
      guard !Task.isCancelled else { return }
      if let seed { updates.yield(.preview(seed)) }
    }
    let tally = try? await source.tally(roundId)
    var failed = false
    if let json = try? await payload {
      courseId = courseId ?? json["api_course_id"]?.string
      var merged = (seed ?? ReceiptSeed(id: roundId)).merged(with: json)
      if merged.photoURL == nil, let path = merged.photoPath, let url = await source.signedURL(path) {
        merged.photoURL = url
      }
      seed = merged
    } else {
      // A friend can read the social round without access to league scoring.
      if let social, social.visible, let round = social.round {
        courseId = social.courseId
        seed = ReceiptSeed(id: roundId,
          profileId: round["owner"]?["id"]?.string.flatMap(UUID.init),
          gross: round["gross"]?.int, playedOn: round["played_on"]?.string,
          courseLabel: social.courseName, holesPlayed: round["holes"]?.int,
          isMine: round["is_mine"]?.bool, marker: round["owner"]?["marker"]?.string)
      }
      failed = seed?.gross == nil
    }
    guard !Task.isCancelled else { return }
    updates.yield(.details(.init(seed: seed, courseId: courseId, tally: tally,
                                conversation: social, failed: failed)))
    let card = await source.scorecard(roundId, gross: seed?.gross, holes: seed?.holesPlayed)
    guard !Task.isCancelled else { return }
    updates.yield(.scorecard(card))
  }
}

// The real services and the scripted test reader cross the same boundary.
protocol ReceiptReading: Sendable {
  func thread(_ id: UUID, focus: UUID?) async throws -> PostedRoundThread
  func cached(_ id: UUID) async -> ReceiptSeed?
  func roundCard(_ id: UUID) async throws -> JSONValue
  func signedURL(_ path: String) async -> URL?
  func tally(_ id: UUID) async throws -> String?
  func scorecard(_ id: UUID, gross: Int?, holes: Int?) async -> RoundScorecard?
}

private struct ReceiptServices: ReceiptReading {
  func thread(_ id: UUID, focus: UUID?) async throws -> PostedRoundThread {
    try await RoundSocialService().thread(id, focus: focus)
  }
  func cached(_ id: UUID) async -> ReceiptSeed? { await ReceiptCache.shared.get(id) }
  func roundCard(_ id: UUID) async throws -> JSONValue { try await RoundsRepository().roundCard(id) }
  func signedURL(_ path: String) async -> URL? { await RoundsRepository().signedURL(path) }
  func tally(_ id: UUID) async throws -> String? { try await RoundsRepository().roundTally(id) }
  func scorecard(_ id: UUID, gross: Int?, holes: Int?) async -> RoundScorecard? {
    await RoundScorecardService().load(id, gross: gross, holesPlayed: holes)
  }
}
