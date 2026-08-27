// Cup Season — the board's state (one league, one store).
//
// Ports the web's `feed[]` + `window.roundCache` + `fetchSocial` +
// `toggleRx` / `sendComment` / `sendChatFrom` / `reportPost` / the 📣 button,
// with the same optimistic-then-revert shape and the same toasts. Realtime
// arrives through `LeagueRealtime`: a `posts` INSERT is applied in place
// when the payload allows (chat / announce / moment / system), otherwise the
// board refetches as the web does (a round post needs the cache).

import Foundation
import Observation
import Supabase

@MainActor
@Observable
public final class BoardStore {
  public let leagueId: UUID
  public let leagueName: String
  public let memberId: UUID?
  public let profileId: UUID?
  public let isPro: Bool
  public let seasonId: UUID?
  public let capIndex: Int
  private let season: Me.Season?
  private let finish: String?
  private let phase: String

  public private(set) var items: [BoardItem] = []
  public private(set) var rounds: [UUID: BoardRound] = [:]
  public private(set) var members: [BoardMember] = []
  public private(set) var names = BoardText.NameRegistry()
  public private(set) var founderId: UUID?
  public private(set) var loading = false
  public private(set) var loaded = false
  public private(set) var loadingEarlier = false
  public private(set) var hasEarlier = false
  /// The "SINCE YOU WERE HERE" lines, or nil when the feed is the reveal.
  public private(set) var digest: [String]?
  /// A one-shot message for the toast host. Cleared by the view.
  public var toast: String?
  /// Open comment threads, keyed by item id — preserved across refreshes.
  public var openThreads: Set<String> = []
  /// Open reaction trays, exclusive — one at a time (F11 3.1).
  public var openTray: String?

  public let realtime: LeagueRealtime
  /// The D86 doorbell, exposed for the live-round slice.
  public var onLiveOpen: (@MainActor (JSONObject) -> Void)?

  private let repo: any BoardRepository
  private let pageSize = 120
  private let earlierSize = 40

  public init(leagueId: UUID, leagueName: String, membership: Me.Membership?, profileId: UUID?,
              repo: any BoardRepository = SupabaseBoardRepository(), realtime: LeagueRealtime = LeagueRealtime()) {
    self.leagueId = leagueId
    self.leagueName = leagueName
    self.memberId = membership?.member_id
    self.profileId = profileId
    self.isPro = membership?.isPro ?? false
    self.seasonId = membership?.season?.id
    self.season = membership?.season
    self.finish = membership?.settings?.finish
    self.phase = membership?.phase ?? "setup"
    self.capIndex = CountingCap.index(membership?.settings?.counting_cap)
    self.repo = repo
    self.realtime = realtime
    realtime.onPostInsert = { [weak self] record in self?.applyInsert(record) }
    realtime.onSocialChange = { [weak self] in Task { await self?.refreshSocial() } }
    realtime.onLiveOpen = { [weak self] payload in self?.onLiveOpen?(payload) }
  }

  // MARK: - Names

  /// `memName` — display name by league_members.id, "—" when unknown.
  public func memberName(_ id: UUID?) -> String { members.first { $0.id == id }?.name ?? "—" }
  public func member(_ id: UUID?) -> BoardMember? { members.first { $0.id == id } }
  /// `memberMarker(pid)` — the effective marker for a profile on this league.
  public func marker(profile: UUID?) -> String { members.first { $0.profileId == profile }?.marker ?? "saguaro" }
  public func face(profile: UUID?) -> URL? { members.first { $0.profileId == profile }?.photoURL }
  /// `myBoardName` — how my optimistic rows and reactions are labelled.
  public var myName: String { memberId.flatMap { id in members.first { $0.id == id }?.name } ?? "You" }
  public var myMember: BoardMember? { member(memberId) }
  public var pinnedIndex: Int? { items.lastIndex { $0.kind == .announce } }

  // MARK: - Load

  public func load() async {
    guard !loading else { return }
    loading = true
    defer { loading = false; loaded = true }
    do {
      async let data = repo.leagueData(league: leagueId, season: seasonId)
      async let posts = repo.posts(league: leagueId, limit: pageSize, before: nil)
      let (ld, rows) = try await (data, posts)
      members = ld.members
      names.learn(ld.members.map(\.name) + ld.squads.map(\.name))
      hasEarlier = rows.count >= pageSize
      if founderId == nil { founderId = await repo.founderId() }
      var built = rows.map(item(from:))
      try await hydrate(&built)
      items = built
      if items.isEmpty {
        items = [BoardItem(id: "synthetic-empty", postId: nil, kind: .system, dateLabel: BoardText.todayLabel(), ts: nil,
                           text: (leagueName.isEmpty ? "Your league" : leagueName) + " is live — post the first round")]
      }
      recomputeDigest()
    } catch {
      // the web keeps the feed and warns; the phone says it once
      if items.isEmpty { toast = BoardText.humanError(error, "Could not load the board.") }
    }
  }

  /// "earlier" — the 40 posts before the oldest shown.
  public func loadEarlier() async {
    guard hasEarlier, !loadingEarlier, let oldest = items.compactMap(\.ts).min() else { return }
    loadingEarlier = true
    defer { loadingEarlier = false }
    do {
      let rows = try await repo.posts(league: leagueId, limit: earlierSize, before: oldest)
      hasEarlier = rows.count >= earlierSize
      var built = rows.map(item(from:))
      try await hydrate(&built)
      let known = Set(items.map(\.id))
      items = built.filter { !known.contains($0.id) } + items
    } catch {
      toast = BoardText.humanError(error, "Could not load earlier posts.")
    }
  }

  /// Fill the round cache for these items and fold the social layer on.
  private func hydrate(_ built: inout [BoardItem]) async throws {
    let rids = Array(Set(built.compactMap { $0.kind == .round ? $0.roundId : nil }))
    let fresh = try await repo.rounds(ids: rids, season: seasonId)
    rounds.merge(fresh) { _, new in new }
    names.learn(fresh.values.map(\.courseLabel))
    try await fold(social: &built)
  }

  private func fold(social built: inout [BoardItem]) async throws {
    let pids = built.compactMap(\.postId)
    guard !pids.isEmpty else { return }
    let (kudos, comments) = try await repo.social(postIds: pids)
    var rxBy: [UUID: [String: ReactionState]] = [:]
    for k in kudos {
      let e = k.emoji ?? CSReactions.quick
      var s = rxBy[k.post_id, default: [:]][e, default: ReactionState()]
      s.n += 1
      if k.member_id == memberId { s.me = true }
      s.who.append(member(k.member_id)?.name ?? "Someone")
      rxBy[k.post_id, default: [:]][e] = s
    }
    var cmBy: [UUID: [BoardComment]] = [:]
    for c in comments { cmBy[c.post_id, default: []].append(BoardComment(who: member(c.member_id)?.name ?? "Someone", text: c.body)) }
    for i in built.indices {
      guard let pid = built[i].postId else { continue }
      built[i].reactions = rxBy[pid] ?? [:]
      built[i].comments = cmBy[pid] ?? []
    }
  }

  /// `refreshSocial` — re-pull just the social layer, no standings refetch.
  public func refreshSocial() async {
    var copy = items
    do { try await fold(social: &copy); items = copy } catch { /* keep what we had */ }
  }

  private func item(from p: PostRow) -> BoardItem {
    let m = member(p.member_id)
    let kind: BoardKind = switch p.kind {
    case "chat": .chat
    case "announce": .announce
    case "round": p.round_id != nil ? .round : .system
    case "moment": .moment
    default: .system
    }
    return BoardItem(id: p.id.uuidString, postId: p.id, kind: kind, dateLabel: BoardText.dateLabel(p.created_at), ts: p.created_at,
                     who: kind == .chat || kind == .round ? memberName(p.member_id) : "", profileId: m?.profileId, memberId: p.member_id,
                     ci: m?.ci ?? 1, text: p.body ?? "", roundId: p.round_id, liveRoundId: p.live_round_id)
  }

  private func recomputeDigest() {
    let marker = BoardLogic.seenMarker(league: leagueId)
    let next = BoardLogic.seasonDeadline(season: season, finish: finish, phase: phase)
    digest = BoardLogic.digest(items: items, cache: rounds, names: names, marker: marker, next: next)
  }

  // MARK: - Realtime

  public func start() async { await realtime.start(leagueId: leagueId) }
  public func stop() async { await realtime.stop() }

  /// A `posts` INSERT arrived. Apply it in place when the row is enough to
  /// render; a round post needs the cache and refetches like the web.
  private func applyInsert(_ record: JSONObject?) {
    guard let record, let idStr = record["id"]?.stringValue, let id = UUID(uuidString: idStr), let kind = record["kind"]?.stringValue else {
      Task { await load() }; return
    }
    if items.contains(where: { $0.id == id.uuidString }) { return }
    if kind == "round" || (kind != "chat" && kind != "announce" && kind != "moment" && kind != "system") {
      Task { await load() }; return
    }
    let created = record["created_at"]?.stringValue.flatMap(Self.parseTimestamp) ?? Date()
    let row = PostRow(id: id, kind: kind, body: record["body"]?.stringValue, created_at: created,
                      member_id: record["member_id"]?.stringValue.flatMap(UUID.init),
                      round_id: nil, live_round_id: record["live_round_id"]?.stringValue.flatMap(UUID.init))
    let built = item(from: row)
    // the real row replaces my optimistic echo of the same text
    if let i = items.firstIndex(where: { $0.isEcho && $0.text == built.text && $0.kind == built.kind }) { items.remove(at: i) }
    items.removeAll { $0.id == "synthetic-empty" }
    items.append(built)
  }

  nonisolated static func parseTimestamp(_ s: String) -> Date? {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = f.date(from: s) { return d }
    f.formatOptions = [.withInternetDateTime]
    if let d = f.date(from: s) { return d }
    // Postgres' own form: 2026-08-27 14:02:11.123456+00
    let g = DateFormatter(); g.locale = Locale(identifier: "en_US_POSIX"); g.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSxx"
    if let d = g.date(from: s) { return d }
    g.dateFormat = "yyyy-MM-dd HH:mm:ssxx"
    return g.date(from: s)
  }

  // MARK: - Reactions (toggleRx 4767)

  public func toggleReaction(_ itemId: String, _ emoji: String) async {
    guard let i = items.firstIndex(where: { $0.id == itemId }) else { return }
    let me = myName
    var cur = items[i].reactions[emoji] ?? ReactionState()
    let had = cur.me
    cur.flip(me: me, on: !had)
    items[i].reactions[emoji] = cur
    guard let post = items[i].postId, let member = memberId else { return }
    do {
      try await repo.writeKudo(post: post, member: member, emoji: emoji, had: had)
    } catch {
      // revert the optimistic flip — and say so
      if let j = items.firstIndex(where: { $0.id == itemId }) {
        var back = items[j].reactions[emoji] ?? ReactionState()
        back.flip(me: me, on: had)
        items[j].reactions[emoji] = back
      }
      toast = BoardText.humanError(error, "Reaction did not save.")
    }
  }

  /// The tray pick (`data-rxpick`): already mine → no-op.
  public func pickReaction(_ itemId: String, _ emoji: String) async {
    openTray = nil
    if let it = items.first(where: { $0.id == itemId }), it.reactions[emoji]?.me == true { return }
    await toggleReaction(itemId, emoji)
  }

  // MARK: - Comments (sendComment 4785)

  public func sendComment(_ itemId: String, _ text: String) async {
    let v = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !v.isEmpty, let i = items.firstIndex(where: { $0.id == itemId }) else { return }
    let echo = BoardComment(who: myName, text: v)
    items[i].comments.append(echo)
    guard let post = items[i].postId, let member = memberId else { return }
    do {
      try await repo.insertComment(post: post, member: member, body: v)
    } catch {
      if let j = items.firstIndex(where: { $0.id == itemId }) { items[j].comments.removeAll { $0.id == echo.id } }
      toast = BoardText.humanError(error, "Comment did not send.")
    }
  }

  // MARK: - Chat (sendChatFrom 5399)

  /// Returns the text to restore in the composer on failure, else nil.
  @discardableResult
  public func sendChat(_ text: String) async -> String? {
    let v = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !v.isEmpty else { return nil }
    let me = myMember
    let echo = BoardItem(id: "echo-" + UUID().uuidString, postId: nil, kind: .chat, dateLabel: BoardText.todayLabel(), ts: Date(),
                         who: "You", profileId: me?.profileId, memberId: memberId, ci: 1, text: v, isEcho: true)
    items.removeAll { $0.id == "synthetic-empty" }
    items.append(echo)
    guard let member = memberId else { return nil }
    do {
      // optimistic echo above; the realtime INSERT swaps in the real row
      try await repo.insertChat(league: leagueId, season: seasonId, member: member, body: v)
      return nil
    } catch {
      items.removeAll { $0.id == echo.id }
      toast = BoardText.humanError(error, "Message did not send.")
      return v
    }
  }

  // MARK: - Announce (13862–13871)

  public func announce(_ text: String) async -> Bool {
    let v = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !v.isEmpty else { toast = "Type the announcement first, then 📣"; return false }
    do {
      try await repo.announce(league: leagueId, body: v)
      toast = "Announced. The league heard you."
      return true
    } catch {
      toast = BoardText.humanError(error, "Could not announce.")
      return false
    }
  }

  // MARK: - Report (reportPost 4834)

  public func report(_ itemId: String, reason: String) async -> Bool {
    guard let post = items.first(where: { $0.id == itemId })?.postId else { return false }
    do {
      try await repo.report(post: post, reason: String(reason.prefix(500)))
      toast = "Reported — thanks. We’ll take a look."
      return true
    } catch {
      toast = BoardText.humanError(error, "Could not send the report.")
      return false
    }
  }

  // MARK: - Scorecard (openScorecard 10336)

  public enum ScorecardResult { case card(Scorecard), unavailable(String) }

  public static func loadScorecard(liveRound: UUID, repo: any BoardRepository = SupabaseBoardRepository()) async -> ScorecardResult {
    do {
      let d = try await repo.scorecard(liveRound: liveRound)
      guard let card = Scorecard(d) else { return .unavailable("That card isn’t available") }
      return .card(card)
    } catch {
      // deploy skew: client shipped before the migration — say so plainly
      return .unavailable(BoardText.isSchemaSkew(error)
        ? "The scorecard needs the latest update — try again shortly"
        : BoardText.humanError(error, "Could not open that card."))
    }
  }
}
