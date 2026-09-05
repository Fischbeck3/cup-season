// Cup Season — Home circle reactions (index.html `fetchHomeSocial`,
// `homeRxOf`, `toggleHomeRx`).
//
// Home is profile-first and cross-league. A reaction USED to be league-scoped
// (post_kudos → posts → league), and a round fanned into one post PER league,
// so each circle round mapped to one deterministic post: the open league's if
// the viewer was in it, else the round's oldest. And the comment that sat here
// said the quiet part out loud —
//
//     "Rows with no shared-league post (friend-only circle members) get no
//      strip at all — an affordance that would fail is worse than none."
//
// — which is 14 of 39 prod profiles, plus every member between seasons, unable
// to be congratulated on a round their friends can see. **D238 is what closes
// that**: `posts.profile_id` gives a leagueless round a post, `post_kudos`
// re-keys to `profiles`, and the strip appears on rows that never had one.
//
// The choosing and the folding are PURE (`pick`, `fold`) so the whole of that
// behaviour is a table test rather than something you can only see by signing
// in as somebody with no league.

import Foundation
import Supabase

public struct HomeSocial: Sendable {
  /// The one post a circle round's strip is attached to. `leagueId` is now
  /// OPTIONAL: a profile-homed post has no league, and that is the whole point.
  public struct Target: Sendable, Equatable {
    public let postId: UUID
    public let leagueId: UUID?
    public init(postId: UUID, leagueId: UUID?) { self.postId = postId; self.leagueId = leagueId }
  }
  public struct KudoLite: Decodable, Sendable {
    public let post_id: UUID
    public let profile_id: UUID?
    public let member_id: UUID?
    public let emoji: String?
    public let created_at: Date?
    public init(post_id: UUID, profile_id: UUID? = nil, member_id: UUID? = nil, emoji: String?, created_at: Date?) {
      self.post_id = post_id; self.profile_id = profile_id; self.member_id = member_id
      self.emoji = emoji; self.created_at = created_at
    }
  }
  public struct CommentLite: Decodable, Sendable {
    public let post_id: UUID
    public let member_id: UUID?
    public let created_at: Date?
    public init(post_id: UUID, member_id: UUID?, created_at: Date?) {
      self.post_id = post_id; self.member_id = member_id; self.created_at = created_at
    }
  }
  public struct Mention: Sendable, Equatable { public let who: String; public let emoji: String?; public let gross: Int? }

  /// One `posts` row as the picker sees it. `profile_id` is optional on the
  /// client for deploy skew in the other direction: the column may not be
  /// there yet, the select retries without it, and every post is a league's.
  public struct PostLite: Decodable, Sendable {
    public let id: UUID
    public let league_id: UUID?
    public let profile_id: UUID?
    public let round_id: UUID?
    public let created_at: Date?
    public init(id: UUID, league_id: UUID?, profile_id: UUID? = nil, round_id: UUID?, created_at: Date?) {
      self.id = id; self.league_id = league_id; self.profile_id = profile_id
      self.round_id = round_id; self.created_at = created_at
    }
  }

  public struct Snapshot: Sendable {
    public var targets: [UUID: Target] = [:]                 // round_id → post
    public var rx: [UUID: [String: ReactionState]] = [:]      // post_id → emoji → state
    /// profile_id → display name. Keyed on the PERSON now, not the membership:
    /// a reactor may share no league with the viewer at all.
    public var names: [UUID: String] = [:]
    public var raw: [KudoLite] = []
    public var myComments: [CommentLite] = []
    public var myMemberIds: Set<UUID> = []
    public var me: UUID?
    public init() {}

    public func state(for roundId: UUID) -> [String: ReactionState]? {
      guard let t = targets[roundId] else { return nil }
      return rx[t.postId] ?? [:]
    }

    /// `dgMentions` — what landed on YOUR rounds since the mark. A 🔥 at 11pm
    /// is news at 7am. Rows without a created_at are skipped (no time, no claim).
    public func mentions(rounds: [HomeFeedRow], since mark: Date, memberToProfile: [UUID: UUID] = [:]) -> [Mention] {
      var mine: [UUID: HomeFeedRow] = [:]
      for r in rounds where r.is_me == true { if let id = r.round_id, let t = targets[id] { mine[t.postId] = r } }
      var out: [Mention] = []
      for k in raw {
        guard let t = k.created_at, t > mark, let r = mine[k.post_id] else { continue }
        let row = BoardKudos.Row(post_id: k.post_id, profile_id: k.profile_id, member_id: k.member_id, emoji: k.emoji)
        if BoardKudos.isMine(row, me: me, myMemberIds: myMemberIds, memberToProfile: memberToProfile) { continue }
        let who = BoardKudos.author(row, memberToProfile: memberToProfile).flatMap { names[$0] } ?? "someone"
        out.append(Mention(who: who, emoji: k.emoji ?? CSReactions.quick, gross: r.gross))
      }
      for c in myComments {
        guard let t = c.created_at, t > mark, let r = mine[c.post_id] else { continue }
        if let m = c.member_id, myMemberIds.contains(m) || memberToProfile[m] == me { continue }
        let who = c.member_id.flatMap { memberToProfile[$0] }.flatMap { names[$0] } ?? "someone"
        out.append(Mention(who: who, emoji: nil, gross: r.gross))
      }
      return out
    }
  }

  // MARK: - The two pure halves

  /// WHICH post a round's strip hangs on. The order is deliberate and it is
  /// the only place it is written down:
  ///
  ///   1 · the OPEN league's post — the reaction the viewer is already among
  ///   2 · any other league's, oldest first — one deterministic choice
  ///   3 · the PERSON's — D238's new rail, and the only post a leagueless
  ///       golfer's round ever has
  ///
  /// A league post outranks a profile-homed one because `round_to_board`
  /// writes one OR the other, never both; where both somehow exist the crew
  /// that shares a season is the louder room, and the tie is broken rather
  /// than left to whichever row came back first.
  public static func pick(posts: [PostLite], currentLeague: UUID?) -> [UUID: Target] {
    func rank(_ p: PostLite) -> Int {
      if let l = p.league_id { return l == currentLeague ? 0 : 1 }
      return p.profile_id != nil ? 2 : 3
    }
    var out: [UUID: Target] = [:]
    var best: [UUID: Int] = [:]
    for p in posts.sorted(by: { ($0.created_at ?? .distantPast) < ($1.created_at ?? .distantPast) }) {
      guard let rid = p.round_id else { continue }
      let r = rank(p)
      if r == 3 { continue }                       // homed on nothing — not a strip
      if let b = best[rid], b <= r { continue }    // first at this rank wins (oldest)
      best[rid] = r
      out[rid] = Target(postId: p.id, leagueId: p.league_id)
    }
    return out
  }

  /// Fold the kudos onto the posts. Pure, so "a leagueless friend's round has
  /// a strip and my own 🔥 on it reads as mine" is an assertion.
  public static func fold(kudos: [KudoLite], names: [UUID: String], me: UUID?,
                          myMemberIds: Set<UUID>, memberToProfile: [UUID: UUID]) -> [UUID: [String: ReactionState]] {
    var rx: [UUID: [String: ReactionState]] = [:]
    for k in kudos {
      let row = BoardKudos.Row(post_id: k.post_id, profile_id: k.profile_id, member_id: k.member_id, emoji: k.emoji)
      let e = BoardKudos.emoji(row)
      var st = rx[k.post_id, default: [:]][e, default: ReactionState()]
      st.n += 1
      if BoardKudos.isMine(row, me: me, myMemberIds: myMemberIds, memberToProfile: memberToProfile) { st.me = true }
      st.who.append(BoardKudos.author(row, memberToProfile: memberToProfile).flatMap { names[$0] } ?? "someone")
      rx[k.post_id, default: [:]][e] = st
    }
    return rx
  }

  // MARK: - The read

  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  private struct LegacyPost: Decodable { let id: UUID; let league_id: UUID?; let round_id: UUID?; let created_at: Date? }
  private struct MemberName: Decodable { struct P: Decodable { let id: UUID?; let display_name: String? }; let id: UUID; let profile_id: UUID?; let profile: P? }
  private struct ProfileName: Decodable { let id: UUID; let display_name: String? }

  public func load(rounds: [HomeFeedRow], memberships: [Me.Membership], currentLeague: UUID?, me: UUID? = nil) async -> Snapshot {
    var s = Snapshot()
    s.myMemberIds = Set(memberships.map(\.member_id))
    s.me = me
    let rids = Array(Set(rounds.compactMap(\.round_id)))
    guard !rids.isEmpty else { return s }
    let db = svc.client

    // deploy skew: `profile_id` may not be on `posts` yet. ANY error retries
    // the legacy shape — a 42501 never names its column (CLAUDE.md).
    var posts: [PostLite]
    do {
      posts = try await db.from("posts").select("id, league_id, profile_id, round_id, created_at")
        .in("round_id", values: rids).eq("kind", value: "round").order("created_at", ascending: true).execute().value
    } catch {
      guard let legacy: [LegacyPost] = try? await db.from("posts").select("id, league_id, round_id, created_at")
        .in("round_id", values: rids).eq("kind", value: "round").order("created_at", ascending: true).execute().value
      else { return s }
      posts = legacy.map { PostLite(id: $0.id, league_id: $0.league_id, profile_id: nil, round_id: $0.round_id, created_at: $0.created_at) }
    }
    s.targets = Self.pick(posts: posts, currentLeague: currentLeague)

    let pids = s.targets.values.map(\.postId)
    guard !pids.isEmpty else { return s }
    let myPids = rounds.filter { $0.is_me == true }.compactMap { $0.round_id.flatMap { s.targets[$0]?.postId } }

    // `select('*')` keeps this skew-safe in both directions: pre-push rows have
    // no `profile_id` key and post-push rows have both.
    async let kud: [KudoLite] = (try? db.from("post_kudos").select("*").in("post_id", values: pids).execute().value) ?? []
    async let cmt: [CommentLite] = myPids.isEmpty ? [] : ((try? db.from("post_comments").select("post_id, member_id, created_at").in("post_id", values: myPids).execute().value) ?? [])
    let (kudos, comments) = await (kud, cmt)

    // names: resolve MEMBERSHIPS to profiles first (legacy rows), then read
    // every profile in one call. A reactor may now share no league at all,
    // which is exactly the row `league_members` could never name.
    var memberToProfile: [UUID: UUID] = [:]
    let memberIds = Array(Set(kudos.compactMap(\.member_id) + comments.compactMap(\.member_id)))
    if !memberIds.isEmpty,
       let mems: [MemberName] = try? await db.from("league_members").select("id, profile_id, profile:profiles(id, display_name)").in("id", values: memberIds).execute().value {
      for m in mems {
        if let p = m.profile_id ?? m.profile?.id { memberToProfile[m.id] = p; s.names[p] = m.profile?.display_name ?? "someone" }
      }
    }
    let profileIds = Array(Set(kudos.compactMap(\.profile_id) + memberToProfile.values))
    if !profileIds.isEmpty,
       let ps: [ProfileName] = try? await db.from("profiles").select("id, display_name").in("id", values: profileIds).execute().value {
      for p in ps { s.names[p.id] = p.display_name ?? "someone" }
    }

    s.raw = kudos
    s.myComments = comments
    s.rx = Self.fold(kudos: kudos, names: s.names, me: me, myMemberIds: s.myMemberIds, memberToProfile: memberToProfile)
    return s
  }

  /// THE one write path — insert or delete exactly as chosen. The reaction is
  /// keyed on the PERSON now, so a golfer with no league can leave one; the
  /// single fallback fires only when the column is not deployed yet
  /// (`BoardKudos.skewFallbackFires`), and it identifies the same person by
  /// their membership rather than writing a different reaction.
  public func write(target: Target, memberships: [Me.Membership], me: UUID?, emoji: String, had: Bool) async throws {
    struct ProfileRow: Encodable { let post_id: UUID; let profile_id: UUID; let emoji: String }
    struct MemberRow: Encodable { let post_id: UUID; let member_id: UUID; let emoji: String }
    let member = target.leagueId.flatMap { l in memberships.first(where: { $0.league_id == l })?.member_id }

    guard let me else {
      // no profile in hand at all: the legacy path or nothing
      guard let member else { throw RpcError(name: "post_kudos", underlying: "no golfer to write for", droppedArgs: []) }
      try await legacy(target: target, member: member, emoji: emoji, had: had)
      return
    }
    do {
      if had {
        try await svc.client.from("post_kudos").delete()
          .eq("post_id", value: target.postId).eq("profile_id", value: me).eq("emoji", value: emoji).execute()
      } else {
        try await svc.client.from("post_kudos").insert(ProfileRow(post_id: target.postId, profile_id: me, emoji: emoji)).execute()
      }
    } catch {
      guard BoardKudos.skewFallbackFires(on: error), let member else { throw error }
      try await legacy(target: target, member: member, emoji: emoji, had: had)
    }
  }

  private func legacy(target: Target, member: UUID, emoji: String, had: Bool) async throws {
    struct MemberRow: Encodable { let post_id: UUID; let member_id: UUID; let emoji: String }
    if had {
      try await svc.client.from("post_kudos").delete()
        .eq("post_id", value: target.postId).eq("member_id", value: member).eq("emoji", value: emoji).execute()
    } else {
      try await svc.client.from("post_kudos").insert(MemberRow(post_id: target.postId, member_id: member, emoji: emoji)).execute()
    }
  }
}
