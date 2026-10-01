import Testing
import Foundation
@testable import CupSeasonKit

/// D403 · the word filter speaks ONE sentence, and both of the phone's error
/// mappers hand it to the golfer exactly as the database wrote it — never the
/// shrug, never "Please sign in again", never the SQLSTATE in front of it.
@Suite struct ModerationCopyTests {
  struct E: LocalizedError { let m: String; var errorDescription: String? { m } }

  @Test func theSentenceIsTheServersOwn() {
    #expect(ModerationCopy.refusal == "Cup Season can't take that wording — no slurs, sexual content or threats. Edit it and try again.")
  }

  /// The RPC path: `SupabaseService.describe` joins PostgREST's code and
  /// message, so the raw text is "P0001 <sentence>".
  @Test func theRpcRefusalReachesTheGolferVerbatim() {
    let raw = RpcError(name: "set_profile", underlying: "P0001 " + ModerationCopy.refusal, droppedArgs: [])
    #expect(BoardText.humanError(raw) == ModerationCopy.refusal)
    #expect(AuthRules.human(raw, fallback: "Could not save.") == ModerationCopy.refusal)
    #expect(BoardText.ourSentence("P0001 " + ModerationCopy.refusal) == ModerationCopy.refusal)
  }

  /// The direct-insert path: a `PostgrestError` describes itself by its
  /// message alone, with no code in front.
  @Test func theDirectWriteRefusalReachesTheGolferVerbatim() {
    #expect(BoardText.humanError(E(m: ModerationCopy.refusal)) == ModerationCopy.refusal)
    #expect(AuthRules.human(E(m: ModerationCopy.refusal)) == ModerationCopy.refusal)
  }

  /// It is on the allowlist by name, so it does not lean on the shape gate.
  @Test func itIsAllowlistedRatherThanShapeGated() {
    #expect(ModerationCopy.refusal.range(of: BoardText.ourRaises, options: [.regularExpression, .caseInsensitive]) != nil)
    // and the escape holds: the allowlist does not suddenly pass a near-miss
    // because a metacharacter in the sentence went unescaped
    #expect("Cup Season can't take that wording — no slurs, sexual content or threatsX Edit it and try again"
              .range(of: NSRegularExpression.escapedPattern(for: ModerationCopy.refusal), options: .regularExpression) == nil)
  }

  /// The prefix a mapper puts in front stays in front; the sentence is whole.
  @Test func aPrefixedToastKeepsTheWholeSentence() {
    let raw = RpcError(name: "create_forfeit", underlying: "P0001 " + ModerationCopy.refusal, droppedArgs: [])
    #expect(BoardText.humanError(raw, "Couldn't post.") == "Couldn't post. " + ModerationCopy.refusal)
  }
}

/// D192 / D402 · one ceiling for every dollar field: the wizard's buy-in and
/// the live-round stake read the same number, and the fine line under both is
/// the same sentence.
@Suite struct MoneyLimitsTests {
  @Test func oneCeilingForBothFields() {
    #expect(MoneyLimits.maxStake == 200)
    #expect(WizardDials.maxStake == MoneyLimits.maxStake)            // the wizard's behaviour is unchanged
    #expect(WizardDials.stakes.max() == MoneyLimits.maxStake)         // the ladder's top rung is the ceiling
    #expect(MoneyLimits.upTo == "Up to $200 a golfer.")
  }

  @Test func theClampBoundsWhatIsTyped() {
    #expect(MoneyLimits.clampStake(250) == 200)
    #expect(MoneyLimits.clampStake(200) == 200)
    #expect(MoneyLimits.clampStake(7.5) == 7.5)
    #expect(MoneyLimits.clampStake(0) == 0)
    #expect(MoneyLimits.clampStake(-1) == 0)
    #expect(MoneyLimits.clampStake(.nan) == 0)
    #expect(MoneyLimits.clampStake(-.infinity) == 0)
  }
}

/// D403 · on the board, a refused message or comment gives the golfer's words
/// back and says the server's sentence — the echo goes, the draft does not.
@MainActor @Suite struct BoardRefusalKeepsTheDraftTests {
  /// A board whose every write is refused by the word filter.
  private struct RefusingBoard: BoardRepository {
    let post: UUID
    struct Refused: LocalizedError { var errorDescription: String? { ModerationCopy.refusal } }
    func posts(league: UUID, limit: Int, before: Date?) async throws -> [PostRow] {
      [PostRow(id: post, kind: "chat", body: "Fixture line", created_at: Date(), member_id: nil, round_id: nil, live_round_id: nil)]
    }
    func leagueData(league: UUID, season: UUID?) async throws -> BoardLeagueData { BoardLeagueData(members: [], squads: []) }
    func rounds(ids: [UUID], season: UUID?) async throws -> [UUID: BoardRound] { [:] }
    func social(postIds: [UUID]) async throws -> (kudos: [KudoRow], comments: [CommentRow]) { ([], []) }
    func signedURLs(paths: [String]) async -> [String: URL] { [:] }
    func founderId() async -> UUID? { nil }
    func insertChat(league: UUID, season: UUID?, member: UUID, body: String) async throws { throw Refused() }
    func writeKudo(post: UUID, profile: UUID?, member: UUID?, emoji: String, had: Bool) async throws {}
    func insertComment(post: UUID, member: UUID, body: String) async throws { throw Refused() }
    func announce(league: UUID, body: String) async throws { throw Refused() }
    func report(post: UUID, reason: String) async throws {}
    func scorecard(liveRound: UUID) async throws -> JSONValue { .null }
  }

  private func member(_ league: UUID) -> Me.Membership {
    Me.Membership(league_id: league, name: "North Grove (fixture)", code: nil, phase: "season", sandbox: false, role: "player",
                  member_id: UUID(), marker: "saguaro", commissioner_name: nil, settings: nil, season: nil, squad: nil,
                  standing: nil, pulse: nil)
  }

  @Test func aRefusedChatComesBackToTheComposer() async {
    let league = UUID()
    let store = BoardStore(leagueId: league, leagueName: "North Grove (fixture)", membership: member(league),
                           profileId: UUID(), repo: RefusingBoard(post: UUID()))
    await store.load()
    let before = store.items.count
    #expect(await store.sendChat("  the words  ") == "the words")
    #expect(store.toast == "Message did not send. " + ModerationCopy.refusal)
    #expect(store.items.count == before)                         // the echo is withdrawn
  }

  @Test func aRefusedCommentComesBackToTheField() async throws {
    let league = UUID()
    let store = BoardStore(leagueId: league, leagueName: "North Grove (fixture)", membership: member(league),
                           profileId: UUID(), repo: RefusingBoard(post: UUID()))
    await store.load()
    let item = try #require(store.items.first { $0.postId != nil })
    #expect(await store.sendComment(item.id, "the words") == "the words")
    #expect(store.toast == "Comment did not send. " + ModerationCopy.refusal)
    #expect(store.items.first { $0.id == item.id }?.comments.isEmpty == true)
  }

  /// No member row: nothing can be written, so nothing may look sent.
  @Test func anEchoWithNothingToWriteIsWithdrawn() async {
    let store = BoardStore(leagueId: UUID(), leagueName: "North Grove (fixture)", membership: nil,
                           profileId: UUID(), repo: RefusingBoard(post: UUID()))
    await store.load()
    let before = store.items.count
    #expect(await store.sendChat("hello") == "hello")
    #expect(store.items.count == before)
    #expect(store.toast?.hasPrefix("Message did not send.") == true)
    if let item = store.items.first(where: { $0.postId != nil }) {
      #expect(await store.sendComment(item.id, "hi") == "hi")
      #expect(store.items.first { $0.id == item.id }?.comments.isEmpty == true)
    }
  }

  @Test func aRefusedAnnouncementStaysInTheSheet() async {
    let league = UUID()
    let store = BoardStore(leagueId: league, leagueName: "North Grove (fixture)", membership: member(league),
                           profileId: UUID(), repo: RefusingBoard(post: UUID()))
    #expect(await store.announce("the words") == false)
    #expect(store.toast == "Could not announce. " + ModerationCopy.refusal)
  }
}
