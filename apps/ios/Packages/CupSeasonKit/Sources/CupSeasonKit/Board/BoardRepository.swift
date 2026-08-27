// Cup Season — the board's reads and writes, mirroring the web client.
//
// Reads (loadStandingsAndFeed 14365–14468, loadLeagueData 14290–14330,
// fetchSocial 4801–4822): `posts` by league, `league_members` (+profiles),
// `squads` (+squad_members), `rounds`, `v_rounds_ranked` (season-scoped),
// signed `media` URLs (1h), `post_kudos`, `post_comments`.
// Writes: `posts` INSERT (chat — the only client-writable kind), `post_kudos`
// INSERT/DELETE (ONE write path, never a different emoji), `post_comments`
// INSERT; RPCs `announce`, `report_content`, `live_round_card`, `founder_id`.
//
// Deploy-skew rule (CLAUDE.md): a select that names a newer column retries
// WITHOUT it on ANY error — a 42501 never names its column.

import Foundation
import Supabase

public struct PostRow: Decodable, Sendable, Equatable {
  public let id: UUID
  public let kind: String
  public let body: String?
  public let created_at: Date
  public let member_id: UUID?
  public let round_id: UUID?
  public let live_round_id: UUID?
  public init(id: UUID, kind: String, body: String?, created_at: Date, member_id: UUID?, round_id: UUID?, live_round_id: UUID?) {
    self.id = id; self.kind = kind; self.body = body; self.created_at = created_at
    self.member_id = member_id; self.round_id = round_id; self.live_round_id = live_round_id
  }
}

public struct KudoRow: Codable, Sendable, Equatable {
  public let post_id: UUID
  public let member_id: UUID
  public let emoji: String?
  public init(post_id: UUID, member_id: UUID, emoji: String?) { self.post_id = post_id; self.member_id = member_id; self.emoji = emoji }
}

public struct CommentRow: Decodable, Sendable, Equatable {
  public let post_id: UUID
  public let member_id: UUID?
  public let body: String
  public let created_at: Date?
}

public struct SquadRoster: Sendable, Equatable {
  public let id: UUID
  public let name: String
  public let color: Int?
  public let memberIds: [UUID]
}

public struct BoardLeagueData: Sendable {
  public var members: [BoardMember]
  public var squads: [SquadRoster]
  public init(members: [BoardMember], squads: [SquadRoster]) { self.members = members; self.squads = squads }
}

public protocol BoardRepository: Sendable {
  /// The newest `limit` posts on the league's board, ascending. `before`
  /// pages earlier ("earlier" = the 40 before the oldest shown).
  func posts(league: UUID, limit: Int, before: Date?) async throws -> [PostRow]
  func leagueData(league: UUID, season: UUID?) async throws -> BoardLeagueData
  func rounds(ids: [UUID], season: UUID?) async throws -> [UUID: BoardRound]
  func social(postIds: [UUID]) async throws -> (kudos: [KudoRow], comments: [CommentRow])
  func signedURLs(paths: [String]) async -> [String: URL]
  func insertChat(league: UUID, season: UUID?, member: UUID, body: String) async throws
  func writeKudo(post: UUID, member: UUID, emoji: String, had: Bool) async throws
  func insertComment(post: UUID, member: UUID, body: String) async throws
  func announce(league: UUID, body: String) async throws
  func report(post: UUID, reason: String) async throws
  func scorecard(liveRound: UUID) async throws -> JSONValue
  func founderId() async -> UUID?
}

public struct SupabaseBoardRepository: BoardRepository {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }
  var db: SupabaseClient { svc.client }

  // MARK: reads

  public func posts(league: UUID, limit: Int, before: Date?) async throws -> [PostRow] {
    // D92: live_round_id is what makes a settlement row openable. Retry
    // without it on ANY error — an un-migrated DB must still render a board.
    struct Legacy: Decodable { let id: UUID; let kind: String; let body: String?; let created_at: Date; let member_id: UUID?; let round_id: UUID? }
    func query(_ cols: String) -> PostgrestTransformBuilder {
      var q = db.from("posts").select(cols).eq("league_id", value: league)
      if let before { q = q.lt("created_at", value: SupabaseService.encoder.dateString(before)) }
      return q.order("created_at", ascending: false).limit(limit)
    }
    do {
      let rows: [PostRow] = try await query("id, kind, body, created_at, member_id, round_id, live_round_id").execute().value
      return rows.reversed()
    } catch {
      let rows: [Legacy] = try await query("id, kind, body, created_at, member_id, round_id").execute().value
      return rows.reversed().map { PostRow(id: $0.id, kind: $0.kind, body: $0.body, created_at: $0.created_at, member_id: $0.member_id, round_id: $0.round_id, live_round_id: nil) }
    }
  }

  private struct ProfileBit: Decodable { let display_name: String?; let marker: String?; let photo_path: String? }
  private struct MemberRow: Decodable { let id: UUID; let role: String; let profile_id: UUID?; let marker: String?; let profile: ProfileBit? }
  private struct SeatRow: Decodable { let member_id: UUID }
  private struct SquadRow: Decodable { let id: UUID; let name: String; let color: Int?; let squad_members: [SeatRow]? }

  public func leagueData(league: UUID, season: UUID?) async throws -> BoardLeagueData {
    var mq: [MemberRow]
    do {
      mq = try await db.from("league_members")
        .select("id, role, profile_id, marker, profile:profiles(display_name, marker, photo_path)")
        .eq("league_id", value: league).execute().value
    } catch {
      // ANY error retries the legacy shape — a sealed column never names itself
      struct LegacyProfile: Decodable { let display_name: String?; let marker: String? }
      struct LegacyMember: Decodable { let id: UUID; let role: String; let profile_id: UUID?; let profile: LegacyProfile? }
      let rows: [LegacyMember] = try await db.from("league_members")
        .select("id, role, profile_id, profile:profiles(display_name, marker)")
        .eq("league_id", value: league).execute().value
      mq = rows.map { MemberRow(id: $0.id, role: $0.role, profile_id: $0.profile_id, marker: nil,
                                profile: ProfileBit(display_name: $0.profile?.display_name, marker: $0.profile?.marker, photo_path: nil)) }
    }
    var squads: [SquadRoster] = []
    if let season {
      let sq: [SquadRow] = try await db.from("squads")
        .select("id, name, color, squad_members(member_id)")
        .eq("season_id", value: season).order("name").execute().value
      squads = sq.map { SquadRoster(id: $0.id, name: $0.name, color: $0.color, memberIds: ($0.squad_members ?? []).map(\.member_id)) }
    }
    // one batched signing per league load: every member avatar for the hour
    let paths = mq.compactMap { $0.profile?.photo_path }
    let urls = paths.isEmpty ? [:] : await signedURLs(paths: paths)
    let members = mq.map { m in
      BoardMember(id: m.id, profileId: m.profile_id, name: m.profile?.display_name ?? "—",
                  marker: m.marker ?? m.profile?.marker ?? "saguaro", role: m.role,
                  squadIndex: squads.firstIndex { $0.memberIds.contains(m.id) },
                  photoURL: m.profile?.photo_path.flatMap { urls[$0] })
    }
    return BoardLeagueData(members: members, squads: squads)
  }

  private struct RoundRow: Decodable {
    let id: UUID; let profile_id: UUID?; let gross: Int?; let differential: Double?; let course_label: String?
    let played_on: String?; let holes_played: Int?; let index_at_post: Double?; let photo_path: String?
  }
  private struct RankRow: Decodable { let round_id: UUID; let pvi: Double?; let points: Double?; let month_rank: Int? }

  public func rounds(ids: [UUID], season: UUID?) async throws -> [UUID: BoardRound] {
    guard !ids.isEmpty else { return [:] }
    var rows: [RoundRow]
    do {
      rows = try await db.from("rounds")
        .select("id, profile_id, gross, differential, course_label, played_on, holes_played, index_at_post, photo_path")
        .in("id", values: ids).execute().value
    } catch {
      struct Legacy: Decodable { let id: UUID; let profile_id: UUID?; let gross: Int?; let differential: Double?; let course_label: String?; let played_on: String?; let holes_played: Int?; let index_at_post: Double? }
      let l: [Legacy] = try await db.from("rounds")
        .select("id, profile_id, gross, differential, course_label, played_on, holes_played, index_at_post")
        .in("id", values: ids).execute().value
      rows = l.map { RoundRow(id: $0.id, profile_id: $0.profile_id, gross: $0.gross, differential: $0.differential, course_label: $0.course_label,
                              played_on: $0.played_on, holes_played: $0.holes_played, index_at_post: $0.index_at_post, photo_path: nil) }
    }
    var cache: [UUID: BoardRound] = [:]
    for r in rows {
      cache[r.id] = BoardRound(id: r.id, profileId: r.profile_id, gross: r.gross, differential: r.differential, courseLabel: r.course_label,
                               playedOn: r.played_on, holesPlayed: r.holes_played, indexAtPost: r.index_at_post, photoPath: r.photo_path)
    }
    if let season {
      let rank: [RankRow] = (try? await db.from("v_rounds_ranked")
        .select("round_id, pvi, points, month_rank")
        .eq("season_id", value: season).in("round_id", values: ids).execute().value) ?? []
      for k in rank {
        if var r = cache[k.round_id] { r.pvi = k.pvi; r.points = k.points; r.monthRank = k.month_rank; cache[k.round_id] = r }
      }
    }
    // private bucket: one batched signing call — a storage hiccup means text-only cards
    let paths = cache.values.compactMap(\.photoPath)
    if !paths.isEmpty {
      let urls = await signedURLs(paths: paths)
      for (id, r) in cache { if let p = r.photoPath, let u = urls[p] { var x = r; x.photoURL = u; cache[id] = x } }
    }
    return cache
  }

  public func social(postIds: [UUID]) async throws -> (kudos: [KudoRow], comments: [CommentRow]) {
    guard !postIds.isEmpty else { return ([], []) }
    // select('*') on post_kudos keeps it deploy-skew safe — a pre-migration
    // table (no emoji column) just defaults every row to 🔥
    async let k: [KudoRow] = db.from("post_kudos").select("*").in("post_id", values: postIds).execute().value
    async let c: [CommentRow] = db.from("post_comments").select("post_id, member_id, body, created_at")
      .in("post_id", values: postIds).order("created_at", ascending: true).execute().value
    return try await (k, c)
  }

  public func signedURLs(paths: [String]) async -> [String: URL] {
    guard !paths.isEmpty else { return [:] }
    guard let signed = try? await db.storage.from("media").createSignedURLs(paths: Array(Set(paths)), expiresIn: 3600) else { return [:] }
    var out: [String: URL] = [:]
    for s in signed where s.error == nil { out[s.path] = s.signedURL }
    return out
  }

  // MARK: writes

  public func insertChat(league: UUID, season: UUID?, member: UUID, body: String) async throws {
    struct Row: Encodable { let league_id: UUID; let season_id: UUID?; let kind: String; let member_id: UUID; let body: String }
    try await db.from("posts").insert(Row(league_id: league, season_id: season, kind: "chat", member_id: member, body: body)).execute()
  }

  /// THE one write path for a reaction row — insert or delete, exactly as
  /// chosen. NO skew fallback here, deliberately (the original guard retried
  /// without emoji and the column default stamped 🔥 — a 🦅 became fire).
  public func writeKudo(post: UUID, member: UUID, emoji: String, had: Bool) async throws {
    if had {
      try await db.from("post_kudos").delete()
        .eq("post_id", value: post).eq("member_id", value: member).eq("emoji", value: emoji).execute()
    } else {
      try await db.from("post_kudos").insert(KudoRow(post_id: post, member_id: member, emoji: emoji)).execute()
    }
  }

  public func insertComment(post: UUID, member: UUID, body: String) async throws {
    struct Row: Encodable { let post_id: UUID; let member_id: UUID; let body: String }
    try await db.from("post_comments").insert(Row(post_id: post, member_id: member, body: body)).execute()
  }

  public func announce(league: UUID, body: String) async throws {
    _ = try await svc.call(Rpc.announce(p_league: league, p_body: body))
  }

  public func report(post: UUID, reason: String) async throws {
    _ = try await svc.call(Rpc.report_content(p_post: post, p_reason: reason))
  }

  public func scorecard(liveRound: UUID) async throws -> JSONValue {
    try await svc.call(Rpc.live_round_card(p_live_round: liveRound))
  }

  public func founderId() async -> UUID? {
    try? await svc.call(Rpc.founder_id())
  }
}

extension JSONEncoder {
  /// ISO-8601 with fractional seconds, the form PostgREST compares against.
  func dateString(_ d: Date) -> String {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f.string(from: d)
  }
}
