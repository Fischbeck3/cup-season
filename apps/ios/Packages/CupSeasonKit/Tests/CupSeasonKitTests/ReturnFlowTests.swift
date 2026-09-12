import Foundation
import Testing
@testable import CupSeasonKit

@Suite struct ReturnFlowTests {
  @Test func runBackDoesNotInventAZeroRosterOrNewSeason() throws {
    let missing = try JSONDecoder().decode(RunItBackResult.self, from: Data("{}".utf8))
    #expect(missing.line == "The next season is on.")
    let open = try JSONDecoder().decode(RunItBackResult.self, from: Data(#"{"already_running":true}"#.utf8))
    #expect(open.line == "This season is already open.")
  }

  @Test func invitationAcceptanceDoesNotConsumeNewerIntent() {
    let name = "return-flow-\(UUID())"
    let defaults = UserDefaults(suiteName: name)!
    defer { defaults.removePersistentDomain(forName: name) }
    JoinIntent.store("NEWCODE", defaults: defaults)
    JoinIntent.clear(ifMatching: "OLDCODE", defaults: defaults)
    #expect(JoinIntent.pending(defaults: defaults)?.code == "NEWCODE")
    JoinIntent.clear(ifMatching: " newcode ", defaults: defaults)
    #expect(JoinIntent.pending(defaults: defaults) == nil)
  }

  @Test func planHeadlineUsesLocalCalendarInsteadOfServerToday() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Phoenix")!
    let item = HomeDispatch.Item(key: "plan:fixture", tier: .coming,
      subject: "you", eyebrow: "SAT", headline: "You have a round today.", at: "2026-09-12")
    #expect(item.localHeadline(today: "2026-09-11", calendar: calendar) == "You have a round tomorrow.")
    #expect(item.localHeadline(today: "2026-09-12", calendar: calendar) == "You have a round today.")
    let friend = HomeDispatch.Item(key: "plan:friend", tier: .coming,
      subject: "Alexandra", eyebrow: "SAT", headline: "Old server day", at: "2026-09-12")
    #expect(friend.localHeadline(today: "2026-09-11", calendar: calendar) == "Alexandra has you down for tomorrow.")
    #expect(friend.localHeadline(today: "2026-09-10", calendar: calendar) == "Alexandra has you down for Saturday.")
  }

  @Test func missingPlanFactsAndOtherStoriesKeepServerCopy() {
    let missing = HomeDispatch.Item(key: "plan:missing", tier: .coming,
      eyebrow: "PLAN", headline: "Your upcoming round.")
    #expect(missing.localHeadline() == missing.headline)
    let other = HomeDispatch.Item(key: "round:fixture", tier: .coming,
      subject: "you", eyebrow: "ROUND", headline: "Your round was saved.", at: "2026-09-12")
    #expect(other.localHeadline() == other.headline)
  }
}

private actor RunBackBoard: BoardRepository {
  enum Failure: Error { case unavailable }
  var writes = 0
  func insertChat(league: UUID, season: UUID?, member: UUID, body: String) async throws {
    writes += 1
    if writes == 1 { throw Failure.unavailable }
  }
  func posts(league: UUID, limit: Int, before: Date?) async throws -> [PostRow] { throw Failure.unavailable }
  func leagueData(league: UUID, season: UUID?) async throws -> BoardLeagueData { throw Failure.unavailable }
  func rounds(ids: [UUID], season: UUID?) async throws -> [UUID: BoardRound] { throw Failure.unavailable }
  func social(postIds: [UUID]) async throws -> (kudos: [KudoRow], comments: [CommentRow]) { throw Failure.unavailable }
  func signedURLs(paths: [String]) async -> [String: URL] { [:] }
  func writeKudo(post: UUID, profile: UUID?, member: UUID?, emoji: String, had: Bool) async throws { throw Failure.unavailable }
  func insertComment(post: UUID, member: UUID, body: String) async throws { throw Failure.unavailable }
  func announce(league: UUID, body: String) async throws { throw Failure.unavailable }
  func report(post: UUID, reason: String) async throws { throw Failure.unavailable }
  func scorecard(liveRound: UUID) async throws -> JSONValue { throw Failure.unavailable }
  func founderId() async -> UUID? { nil }
}

extension ReturnFlowTests {
  @Test func failedRunBackAskCanRetryButAcceptedAskIsNotRepeated() async {
    let suite = "run-back-\(UUID())"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let league = UUID(), member = UUID(), board = RunBackBoard()
    let service = RunItBackService()
    _ = await service.ask(league: league, season: nil, member: member, myFirstName: nil, board: board, defaults: defaults)
    #expect(!defaults.bool(forKey: RunItBack.askKey(league: league)))
    let accepted = await service.ask(league: league, season: nil, member: member, myFirstName: nil, board: board, defaults: defaults)
    #expect(accepted == RunItBack.askSent)
    #expect(defaults.bool(forKey: RunItBack.askKey(league: league)))
    let repeated = await service.ask(league: league, season: nil, member: member, myFirstName: nil, board: board, defaults: defaults)
    #expect(repeated == RunItBack.askAlready)
    #expect(await board.writes == 2)
  }
}
