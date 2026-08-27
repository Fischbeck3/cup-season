// Cup Season — Home circle reactions (index.html `fetchHomeSocial`
// 10135–10180, `homeRxOf` 10125–10131, `toggleHomeRx` 10181–10200).
//
// Home is profile-first and cross-league; a reaction is league-scoped
// (post_kudos → posts → league), and a round fans into one post PER league.
// So each circle round maps to ONE deterministic post: the currently-open
// league's if the viewer is in it, else the round's OLDEST post. Rows with no
// shared-league post (friend-only circle members) get no strip at all — an
// affordance that would fail is worse than none. The write carries MY member
// id in the POST's league, which may not be the open league's.

import Foundation
import Supabase

public struct HomeSocial: Sendable {
  public struct Target: Sendable, Equatable { public let postId: UUID; public let leagueId: UUID }
  public struct KudoLite: Decodable, Sendable { public let post_id: UUID; public let member_id: UUID; public let emoji: String?; public let created_at: Date? }
  public struct CommentLite: Decodable, Sendable { public let post_id: UUID; public let member_id: UUID; public let created_at: Date? }
  public struct Mention: Sendable, Equatable { public let who: String; public let emoji: String?; public let gross: Int? }

  public struct Snapshot: Sendable {
    public var targets: [UUID: Target] = [:]                 // round_id → post
    public var rx: [UUID: [String: ReactionState]] = [:]      // post_id → emoji → state
    public var names: [UUID: String] = [:]                    // member_id → display name
    public var raw: [KudoLite] = []
    public var myComments: [CommentLite] = []
    public var myMemberIds: Set<UUID> = []
    public init() {}

    public func state(for roundId: UUID) -> [String: ReactionState]? {
      guard let t = targets[roundId] else { return nil }
      return rx[t.postId] ?? [:]
    }

    /// `dgMentions` — what landed on YOUR rounds since the mark. A 🔥 at 11pm
    /// is news at 7am. Rows without a created_at are skipped (no time, no claim).
    public func mentions(rounds: [HomeFeedRow], since mark: Date) -> [Mention] {
      var mine: [UUID: HomeFeedRow] = [:]
      for r in rounds where r.is_me == true { if let id = r.round_id, let t = targets[id] { mine[t.postId] = r } }
      var out: [Mention] = []
      for k in raw {
        guard let t = k.created_at, t > mark, let r = mine[k.post_id], !myMemberIds.contains(k.member_id) else { continue }
        out.append(Mention(who: names[k.member_id] ?? "someone", emoji: k.emoji ?? "🔥", gross: r.gross))
      }
      for c in myComments {
        guard let t = c.created_at, t > mark, let r = mine[c.post_id], !myMemberIds.contains(c.member_id) else { continue }
        out.append(Mention(who: names[c.member_id] ?? "someone", emoji: nil, gross: r.gross))
      }
      return out
    }
  }

  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  private struct PostLite: Decodable { let id: UUID; let league_id: UUID?; let round_id: UUID?; let created_at: Date? }
  private struct MemberName: Decodable { struct P: Decodable { let display_name: String? }; let id: UUID; let profile: P? }

  public func load(rounds: [HomeFeedRow], memberships: [Me.Membership], currentLeague: UUID?) async -> Snapshot {
    var s = Snapshot()
    s.myMemberIds = Set(memberships.map(\.member_id))
    let rids = Array(Set(rounds.compactMap(\.round_id)))
    guard !rids.isEmpty else { return s }
    let db = svc.client
    guard let posts: [PostLite] = try? await db.from("posts").select("id, league_id, round_id, created_at")
      .in("round_id", values: rids).eq("kind", value: "round").order("created_at", ascending: true).execute().value else { return s }
    for p in posts {
      guard let rid = p.round_id, let lid = p.league_id else { continue }
      let t = s.targets[rid]
      if t == nil || (lid == currentLeague && t?.leagueId != currentLeague) { s.targets[rid] = Target(postId: p.id, leagueId: lid) }
    }
    let pids = s.targets.values.map(\.postId)
    guard !pids.isEmpty else { return s }
    let myPids = rounds.filter { $0.is_me == true }.compactMap { $0.round_id.flatMap { s.targets[$0]?.postId } }

    async let kud: [KudoLite] = (try? db.from("post_kudos").select("post_id, member_id, emoji, created_at").in("post_id", values: pids).execute().value) ?? []
    async let cmt: [CommentLite] = myPids.isEmpty ? [] : ((try? db.from("post_comments").select("post_id, member_id, created_at").in("post_id", values: myPids).execute().value) ?? [])
    let (kudos, comments) = await (kud, cmt)

    let memberIds = Array(Set(kudos.map(\.member_id) + comments.map(\.member_id)))
    if !memberIds.isEmpty, let mems: [MemberName] = try? await db.from("league_members").select("id, profile:profiles(display_name)").in("id", values: memberIds).execute().value {
      for m in mems { s.names[m.id] = m.profile?.display_name ?? "someone" }
    }
    s.raw = kudos
    s.myComments = comments
    for k in kudos {
      let e = k.emoji ?? "🔥"
      var st = s.rx[k.post_id, default: [:]][e, default: ReactionState()]
      st.n += 1
      if s.myMemberIds.contains(k.member_id) { st.me = true }
      st.who.append(s.names[k.member_id] ?? "someone")
      s.rx[k.post_id, default: [:]][e] = st
    }
    return s
  }

  /// THE one write path — insert or delete exactly as chosen, no fallback.
  public func write(target: Target, memberships: [Me.Membership], emoji: String, had: Bool) async throws {
    guard let mem = memberships.first(where: { $0.league_id == target.leagueId }) else {
      throw RpcError(name: "post_kudos", underlying: "not a member of that league", droppedArgs: [])
    }
    struct Row: Encodable { let post_id: UUID; let member_id: UUID; let emoji: String }
    if had {
      try await svc.client.from("post_kudos").delete()
        .eq("post_id", value: target.postId).eq("member_id", value: mem.member_id).eq("emoji", value: emoji).execute()
    } else {
      try await svc.client.from("post_kudos").insert(Row(post_id: target.postId, member_id: mem.member_id, emoji: emoji)).execute()
    }
  }
}
