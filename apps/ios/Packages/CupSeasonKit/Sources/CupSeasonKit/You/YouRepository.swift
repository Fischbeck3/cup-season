// Cup Season — the You tab's reads, in one place (index.html `loadProfile`
// 12840–12884, `loadTrophies` 16383–16387, `loadCareerRecord`,
// `loadLastRoundWith` 16201, `loadCareer` 16409, `loadLeagueRecord` 16587,
// `renderRivalries` 13215).
//
// Y-17 · every block loads on its own and REPORTS when it could not: a read
// that fails leaves its block empty, names itself in `YouData.failed`, and the
// screen shows one quiet Retry line instead of a record that silently reads
// as "nothing yet". The founder check and the reunion whisper stay
// best-effort — neither is a fact about the golfer's card.

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
  public var achievements: [Achievement] = []
  public var careerRecord: CareerRecord?
  public var lastRoundWith: LastRoundWith?
  public var isFounder = false
  public var career: Career?
  public var rivalries: [RivalryLine] = []
  public var leagueRecord: [LeagueRecordRow] = []
  public var seasonStats: SeasonStats?
  /// Y-17 · the blocks whose read failed, by name; empty when the tab is whole
  public var failed: [String] = []
  public var isPartial: Bool { !failed.isEmpty }
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

  /// Y-17 · one block's read, where **nil means the read FAILED**. An empty
  /// list is not a failure — it is a golfer with nothing there yet, and the
  /// whole point of this tab's loading rules is that the two never look alike.
  /// (`Result<_, any Error>` is not `Sendable`, so it cannot cross an
  /// `async let`; the optional carries the same fact and does.)
  private func attempt<T: Sendable>(_ op: @Sendable () async throws -> T) async -> T? {
    try? await op()
  }

  /// The whole tab. `leagueId` picks the season strip's league and the lens
  /// that wins when a round scored in more than one.
  public func load(me: Me, userId: UUID, leagueId: UUID?) async -> YouData {
    async let extras = profileExtras(userId)
    async let trophies = attempt { try await svc.call(Rpc.my_trophies()) }
    async let achievements = attempt { try await myAchievements() }
    async let record = attempt { CareerRecord.parse(try await svc.call(Rpc.career_record())) }
    async let lrw: LastRoundWith? = loadLastRoundWith(userId)
    async let founder: Bool = ((try? await svc.call(Rpc.founder_id())) == userId)
    async let career = attempt { try await loadCareer(userId, me: me, leagueId: leagueId) }
    async let rivalries = attempt { (try await svc.call(Rpc.my_rivalries())).compactMap(RivalryLine.from) }
    async let league = attempt { try await loadLeagueRecord(me: me) }
    async let season = attempt { try await loadSeasonStats(me: me, leagueId: leagueId) }

    var d = YouData()
    // the founder check and the reunion whisper stay best-effort: neither is a
    // fact about the card, and neither is worth a Retry line
    d.extras = await extras
    d.lastRoundWith = await lrw
    d.isFounder = await founder
    if let v = await trophies { d.trophies = v } else { d.failed.append("trophies") }
    if let v = await achievements { d.achievements = v } else { d.failed.append("achievements") }
    if let v = await record { d.careerRecord = v } else { d.failed.append("record") }
    if let v = await career {
      d.career = v.career
      if v.figuresFailed { d.failed.append("figures") }
    } else {
      d.failed.append("career")
    }
    if let v = await rivalries { d.rivalries = v } else { d.failed.append("rivalries") }
    if let v = await league { d.leagueRecord = v } else { d.failed.append("league record") }
    if let v = await season { d.seasonStats = v } else { d.failed.append("season") }
    return d
  }

  /// Y-20 · the generated `Rpc.my_achievements.Row` predates `round_id`;
  /// decoding the same call into `Achievement` keeps the key optional either
  /// way (the generated file is never hand-edited), so the tile door lights up
  /// the moment the migration lands and nothing breaks before it.
  func myAchievements() async throws -> [Achievement] {
    try await svc.client.rpc(Rpc.my_achievements.name, params: Rpc.my_achievements()).execute().value
  }

  func loadLastRoundWith(_ uid: UUID) async -> LastRoundWith? {
    if LRWQuietStore(userId: uid).isQuiet() { return nil }
    guard let rows = try? await svc.call(Rpc.last_round_with()), let first = rows.first else { return nil }
    return LastRoundWith(first)
  }

  /// The career with a flag for the one read that may fail without emptying
  /// the card: the engine's figures. Rounds without them still list.
  public struct CareerLoad: Sendable {
    public let career: Career
    public let figuresFailed: Bool
  }

  public func loadCareer(_ uid: UUID, me: Me, leagueId: UUID?) async throws -> CareerLoad {
    async let rows = rounds.myRounds(uid)
    async let ranked = attempt { try await rounds.rankedRounds(profileId: uid) }
    let r = try await rows
    let rk = await ranked
    let lens = rk ?? []
    let preferred = (me.memberships.first { $0.league_id == leagueId } ?? me.memberships.first)?.season?.id
    let leagues = me.memberships.map { m in
      Career.LeagueSeen(seasonId: m.season?.id, seasonNumber: m.season?.number, seasonStatus: m.season?.status,
                        startsOn: m.season?.starts_on, sandbox: m.sandbox == true)
    }
    let played = Career.playedIn(leagues: leagues, events: Career.onRoster(me.events),
                                 rankedSeasons: Set(lens.compactMap(\.season_id)))
    return CareerLoad(career: Career.compute(rows: r, ranked: lens, preferredSeason: preferred, played: played),
                      figuresFailed: rk == nil)
  }

  public func loadLeagueRecord(me: Me) async throws -> [LeagueRecordRow] {
    guard !me.memberships.isEmpty else { return [] }
    let seasonIds = me.memberships.compactMap { $0.season?.id }
    let standings = try await rounds.individualStandings(seasonIds: seasonIds)
    return me.memberships.map { m in
      LeagueRecordRow(id: m.league_id, name: m.name, number: m.season?.number ?? 1,
                      line: LeagueRecord.line(phase: m.phase, season: m.season, standings: standings, myMemberId: m.member_id))
    }
  }

  public func loadSeasonStats(me: Me, leagueId: UUID?) async throws -> SeasonStats? {
    guard let m = me.memberships.first(where: { $0.league_id == leagueId }) ?? me.memberships.first, let s = m.season else { return nil }
    async let rr = rounds.seasonRounds(seasonId: s.id)
    async let st = rounds.individualStandings(seasonIds: [s.id])
    let (rows, standings) = try await (rr, st)
    return SeasonStats.compute(rows: rows, standings: standings, myMemberId: m.member_id)
  }

  /// `delete_round` — no `handicap_index` chaser behind it (Y-19).
  public func deleteRound(_ id: UUID) async throws { try await rounds.deleteRound(id) }
}
