// Cup Season — the You tab's reads, in one place (index.html `loadProfile`
// 12840–12884, `loadTrophies` 16383–16387, `loadCareerRecord`,
// `loadLastRoundWith` 16201, `loadCareer` 16409, `loadLeagueRecord` 16587,
// `renderRivalries` 13215).
//
// Everything that is not the profile is best-effort: a missing RPC (deploy
// skew) leaves that block empty and the rest of the page whole, exactly as
// each web loader catches its own error.

import Foundation
import Supabase

/// The profile fields `Me.Profile` does not carry (GHIN, the created_at the
/// card anchors on, the signed avatar).
public struct ProfileExtras: Sendable, Equatable {
  public let ghinNumber: String?
  public let createdAt: Date?
  public let avatarURL: URL?
  public init(ghinNumber: String?, createdAt: Date?, avatarURL: URL?) { self.ghinNumber = ghinNumber; self.createdAt = createdAt; self.avatarURL = avatarURL }
}

public struct YouData: Sendable {
  public var extras: ProfileExtras?
  public var trophies: [Rpc.my_trophies.Row] = []
  public var achievements: [Rpc.my_achievements.Row] = []
  public var careerRecord: CareerRecord?
  public var lastRoundWith: LastRoundWith?
  public var isFounder = false
  public var career: Career?
  public var rivalries: [RivalryLine] = []
  public var leagueRecord: [LeagueRecordRow] = []
  public var seasonStats: SeasonStats?
  public init() {}
}

public struct YouRepository: Sendable {
  let svc: SupabaseService
  let rounds: RoundsRepository
  public init(_ svc: SupabaseService = .shared) { self.svc = svc; self.rounds = RoundsRepository(svc) }

  private struct ExtrasRow: Decodable { let ghin_number: String?; let created_at: Date?; let photo_path: String? }

  /// Named columns; email is sealed, so never `*`. Retries without
  /// `photo_path` on ANY error.
  public func profileExtras(_ uid: UUID) async -> ProfileExtras? {
    var row: ExtrasRow?
    do {
      let rows: [ExtrasRow] = try await svc.client.from("profiles").select("ghin_number, created_at, photo_path").eq("id", value: uid).execute().value
      row = rows.first
    } catch {
      let rows: [ExtrasRow]? = try? await svc.client.from("profiles").select("ghin_number, created_at").eq("id", value: uid).execute().value
      row = rows?.first
    }
    guard let row else { return nil }
    var url: URL? = nil
    if let p = row.photo_path, !p.isEmpty { url = await rounds.signedURL(p) }
    return ProfileExtras(ghinNumber: row.ghin_number, createdAt: row.created_at, avatarURL: url)
  }

  /// The whole tab. `leagueId` picks the season strip's league.
  public func load(me: Me, userId: UUID, leagueId: UUID?) async -> YouData {
    async let extras = profileExtras(userId)
    async let trophies: [Rpc.my_trophies.Row] = (try? await svc.call(Rpc.my_trophies())) ?? []
    async let achievements: [Rpc.my_achievements.Row] = (try? await svc.call(Rpc.my_achievements())) ?? []
    async let record: CareerRecord? = (try? await svc.call(Rpc.career_record())).map(CareerRecord.parse)
    async let lrw: LastRoundWith? = loadLastRoundWith(userId)
    async let founder: Bool = ((try? await svc.call(Rpc.founder_id())) == userId)
    async let career: Career? = loadCareer(userId, me: me)
    async let rivalries: [RivalryLine] = ((try? await svc.call(Rpc.my_rivalries())) ?? []).compactMap(RivalryLine.from)
    async let league: [LeagueRecordRow] = loadLeagueRecord(me: me)
    async let season: SeasonStats? = loadSeasonStats(me: me, leagueId: leagueId)

    var d = YouData()
    d.extras = await extras
    d.trophies = await trophies
    d.achievements = await achievements
    d.careerRecord = await record
    d.lastRoundWith = await lrw
    d.isFounder = await founder
    d.career = await career
    d.rivalries = await rivalries
    d.leagueRecord = await league
    d.seasonStats = await season
    return d
  }

  func loadLastRoundWith(_ uid: UUID) async -> LastRoundWith? {
    if LRWQuietStore(userId: uid).isQuiet() { return nil }
    guard let rows = try? await svc.call(Rpc.last_round_with()), let first = rows.first else { return nil }
    return LastRoundWith(first)
  }

  public func loadCareer(_ uid: UUID, me: Me) async -> Career? {
    guard let rows = try? await rounds.myRounds(uid) else { return nil }
    return Career.compute(rows: rows, memberships: me.memberships.count, events: me.events.count)
  }

  public func loadLeagueRecord(me: Me) async -> [LeagueRecordRow] {
    guard !me.memberships.isEmpty else { return [] }
    let seasonIds = me.memberships.compactMap { $0.season?.id }
    let standings = (try? await rounds.individualStandings(seasonIds: seasonIds)) ?? []
    return me.memberships.map { m in
      LeagueRecordRow(id: m.league_id, name: m.name, number: m.season?.number ?? 1,
                      line: LeagueRecord.line(phase: m.phase, season: m.season, standings: standings, myMemberId: m.member_id))
    }
  }

  public func loadSeasonStats(me: Me, leagueId: UUID?) async -> SeasonStats? {
    guard let m = me.memberships.first(where: { $0.league_id == leagueId }) ?? me.memberships.first, let s = m.season else { return nil }
    async let rr = rounds.seasonRounds(seasonId: s.id)
    async let st = rounds.individualStandings(seasonIds: [s.id])
    guard let rows = try? await rr else { return .empty }
    let standings = (try? await st) ?? []
    return SeasonStats.compute(rows: rows, standings: standings, myMemberId: m.member_id)
  }

  public func deleteRound(_ id: UUID, profile: UUID) async throws { try await rounds.deleteRound(id, profile: profile) }
}
