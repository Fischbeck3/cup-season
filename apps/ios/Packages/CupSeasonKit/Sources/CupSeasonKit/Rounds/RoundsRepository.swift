// Cup Season — the read side of rounds (audit 03 §1.6, §1.9, §1.11; §9).
//
// Every read here is one the web client makes today, column for column:
// `loadCareer` (16409), `renderAlbum` (16456), `loadStandingsAndFeed`'s
// `v_rounds_ranked` pass (14480), `loadLeagueRecord` (16587). The deploy-skew
// rule from CLAUDE.md is kept: a select naming `photo_path` retries WITHOUT it
// on ANY error, never on the message (42501 never names its column).

import Foundation
import Supabase

/// A `rounds` row as the You tab and the album read it.
public struct RoundRow: Decodable, Sendable, Identifiable, Equatable {
  public let id: UUID
  public let profile_id: UUID?
  public let gross: Int?
  public let differential: Double?
  public let index_at_post: Double?
  public let played_on: String?
  public let course_label: String?
  public let holes_played: Int?
  public let photo_path: String?
  public var photo_url: URL?

  public init(id: UUID, profile_id: UUID? = nil, gross: Int?, differential: Double?, index_at_post: Double?, played_on: String?,
              course_label: String?, holes_played: Int?, photo_path: String? = nil, photo_url: URL? = nil) {
    self.id = id; self.profile_id = profile_id; self.gross = gross; self.differential = differential; self.index_at_post = index_at_post
    self.played_on = played_on; self.course_label = course_label; self.holes_played = holes_played; self.photo_path = photo_path; self.photo_url = photo_url
  }

  enum CodingKeys: String, CodingKey { case id, profile_id, gross, differential, index_at_post, played_on, course_label, holes_played, photo_path }

  /// `pvi = index_at_post − differential` at 100% — the Tour Card's own
  /// figure. NOT the You tab's: D209 reads the allowance figure off
  /// `v_rounds_ranked` (`Career.figure(for:)`) and never this.
  public var pvi: Double? {
    guard let i = index_at_post, let d = differential else { return nil }
    return i - d
  }
  /// D76 FORM: beat the number = pvi ≥ 1; nines are already 18-equivalized
  /// by `score_round()`. Missing pieces stay nil (a slate dot).
  public var beat: Bool? { pvi.map { $0 >= 1 } }

  public func seed(marker: String? = nil, isMine: Bool? = nil) -> ReceiptSeed {
    ReceiptSeed(id: id, profileId: profile_id, gross: gross, differential: differential, indexAtPost: index_at_post, playedOn: played_on,
                courseLabel: course_label, holesPlayed: holes_played, photoPath: photo_path, photoURL: photo_url, isMine: isMine, marker: marker)
  }
}

/// A `v_rounds_ranked` row, the league's scoring lens on a round. `pvi` is
/// the ALLOWANCE figure — `playing_index − differential`, the number the
/// points were scored against (D209) — and it is the only "vs your playing
/// number" the You tab prints; the phone never re-derives it.
public struct RankedRound: Decodable, Sendable, Equatable {
  public let member_id: UUID
  public let pvi: Double?
  public let points: Double?
  public let month_rank: Int?
  public let floor_credit: Double?
  public let played_on: String?
  public let index_at_post: Double?
  public let holes_played: Int?
  /// the round and the season the lens is on — nil on the season-scoped
  /// reads that never asked for them
  public let round_id: UUID?
  public let season_id: UUID?
  public init(member_id: UUID, pvi: Double?, points: Double?, month_rank: Int?, floor_credit: Double?, played_on: String?, index_at_post: Double?, holes_played: Int?,
              round_id: UUID? = nil, season_id: UUID? = nil) {
    self.member_id = member_id; self.pvi = pvi; self.points = points; self.month_rank = month_rank; self.floor_credit = floor_credit
    self.played_on = played_on; self.index_at_post = index_at_post; self.holes_played = holes_played
    self.round_id = round_id; self.season_id = season_id
  }
}

public struct IndividualStanding: Decodable, Sendable, Equatable {
  public let season_id: UUID
  public let member_id: UUID
  public let points: Double?
  public let rounds_posted: Int?
  public init(season_id: UUID, member_id: UUID, points: Double?, rounds_posted: Int?) {
    self.season_id = season_id; self.member_id = member_id; self.points = points; self.rounds_posted = rounds_posted
  }
}

/// A league mate as the album and the receipt medallion need them.
public struct LeagueMate: Sendable, Equatable {
  public let profileId: UUID
  public let displayName: String?
  /// effective marker: league override → profile choice → floor
  public let marker: String?
  public let photoPath: String?
  public init(profileId: UUID, displayName: String?, marker: String?, photoPath: String?) {
    self.profileId = profileId; self.displayName = displayName; self.marker = marker; self.photoPath = photoPath
  }
}

public struct RoundsRepository: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  private var db: SupabaseClient { svc.client }

  // MARK: - the receipt

  public func roundCard(_ id: UUID) async throws -> JSONValue {
    try await svc.call(Rpc.round_card(p_round: id))
  }

  /// One signed URL for the private `media` bucket, an hour long. nil on any
  /// failure — the facts still show; a photo is never load-bearing.
  public func signedURL(_ path: String, expiresIn: Int = 3600) async -> URL? {
    try? await svc.client.storage.from("media").createSignedURL(path: path, expiresIn: expiresIn)
  }

  /// One batched signing call → path ⇒ URL. Failures leave gaps, never throw.
  public func signedURLs(_ paths: [String], expiresIn: Int = 3600) async -> [String: URL] {
    let unique = Array(Set(paths.filter { !$0.isEmpty }))
    guard !unique.isEmpty else { return [:] }
    guard let results = try? await svc.client.storage.from("media").createSignedURLs(paths: unique, expiresIn: expiresIn) else { return [:] }
    var out: [String: URL] = [:]
    for r in results { if case .success(let path, let url) = r { out[path] = url } }
    return out
  }

  // MARK: - my rounds (loadCareer 16409)

  private static let roundCols = "id, profile_id, gross, differential, index_at_post, played_on, course_label, holes_played"

  /// The 400 newest rounds on my card, newest first; the first five with a
  /// photo carry a signed URL.
  public func myRounds(_ uid: UUID) async throws -> [RoundRow] {
    var rows: [RoundRow]
    do {
      rows = try await db.from("rounds").select(Self.roundCols + ", photo_path")
        .eq("profile_id", value: uid).order("played_on", ascending: false).limit(400).execute().value
    } catch {
      rows = try await db.from("rounds").select(Self.roundCols)
        .eq("profile_id", value: uid).order("played_on", ascending: false).limit(400).execute().value
    }
    let withPhoto = rows.prefix(5).compactMap(\.photo_path)
    if !withPhoto.isEmpty {
      let urls = await signedURLs(withPhoto)
      for i in rows.indices.prefix(5) { if let p = rows[i].photo_path { rows[i].photo_url = urls[p] } }
    }
    return rows
  }

  /// `delete_round`. The standings views recompute on their own (they read the
  /// rounds), and Y-19 removed the `handicap_index(p_profile)` call that used
  /// to follow it: that function is `stable` and only RETURNS a number — the
  /// result was discarded, so it refreshed nothing and cost a round trip. The
  /// profile's stored index is refreshed server-side, inside `delete_round`
  /// (the migration is Y-19's other half); the caller reloads to read it.
  public func deleteRound(_ id: UUID) async throws {
    _ = try await svc.call(Rpc.delete_round(p_round: id))
  }

  // MARK: - league mates (loadLeagueData 14293)

  private struct MemberRow: Decodable {
    struct P: Decodable { let display_name: String?; let marker: String?; let photo_path: String? }
    let profile_id: UUID?; let marker: String?; let profile: P?
  }

  public func leagueMates(leagueId: UUID) async throws -> [LeagueMate] {
    var rows: [MemberRow]
    do {
      rows = try await db.from("league_members").select("profile_id, marker, profile:profiles(display_name, marker, photo_path)")
        .eq("league_id", value: leagueId).execute().value
    } catch {
      rows = try await db.from("league_members").select("profile_id, marker, profile:profiles(display_name, marker)")
        .eq("league_id", value: leagueId).execute().value
    }
    return rows.compactMap { m in
      guard let pid = m.profile_id else { return nil }
      return LeagueMate(profileId: pid, displayName: m.profile?.display_name, marker: m.marker ?? m.profile?.marker ?? "saguaro", photoPath: m.profile?.photo_path)
    }
  }

  // MARK: - the album (renderAlbum 16456)

  /// Every league round photo, newest first, 60 at most, each with its signed
  /// URL. Rows whose signing failed are dropped (the web skips them too).
  public func albumRounds(profileIds: [UUID]) async throws -> [RoundRow] {
    guard !profileIds.isEmpty else { return [] }
    var rows: [RoundRow] = try await db.from("rounds").select(Self.roundCols + ", photo_path")
      .in("profile_id", values: profileIds).not("photo_path", operator: .is, value: "null")
      .order("played_on", ascending: false).limit(60).execute().value
    let urls = await signedURLs(rows.compactMap(\.photo_path))
    for i in rows.indices { if let p = rows[i].photo_path { rows[i].photo_url = urls[p] } }
    return rows.filter { $0.photo_url != nil }
  }

  // MARK: - the season lens (14480) and the league record (16587)

  public func seasonRounds(seasonId: UUID) async throws -> [RankedRound] {
    try await db.from("v_rounds_ranked")
      .select("member_id, pvi, points, month_rank, floor_credit, played_on, index_at_post, holes_played")
      .eq("season_id", value: seasonId).execute().value
  }

  /// D209 · every lens the engine has on MY rounds — one row per round per
  /// league season it scored in. The You tab's figures (All time, FORM, the
  /// recent rows) read `pvi` off these; a round with no row here is card-only
  /// and shows no figure rather than a re-derived one.
  /// The limit has to clear `myRounds`' 400 times the number of league seasons
  /// a round can score in — one row per lens. At 800 a golfer in three leagues
  /// lost the figures on their oldest card rounds, and `Career.compute` then
  /// averaged over a truncated window while the sub still read "across counting
  /// rounds" — a false statement rather than a missing one.
  public func rankedRounds(profileId: UUID) async throws -> [RankedRound] {
    try await db.from("v_rounds_ranked")
      .select("member_id, season_id, round_id, pvi, points, month_rank, floor_credit, played_on, index_at_post, holes_played")
      .eq("profile_id", value: profileId).order("played_on", ascending: false).limit(400 * 4).execute().value
  }

  public func individualStandings(seasonIds: [UUID]) async throws -> [IndividualStanding] {
    guard !seasonIds.isEmpty else { return [] }
    return try await db.from("v_individual_standings").select("season_id, member_id, points, rounds_posted")
      .in("season_id", values: seasonIds).execute().value
  }
}
