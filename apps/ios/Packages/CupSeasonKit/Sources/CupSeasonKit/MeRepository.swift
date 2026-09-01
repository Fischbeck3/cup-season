// Cup Season — the bootstrap read (IOS-002 §3, §4).
//
// One round trip via `native_home()` (IOS-009 batch 1, pushed 2026-08-27 —
// `Rpc.native_home` exists in Generated/Rpc.swift with a `JSONValue` return).
// This typed twin decodes straight into `Me` through the SDK's decoder; it is
// the same function and the same grant. The legacy fallback stays for a
// database that is behind this build (a store build cannot be re-pushed).

import Foundation
import Supabase

/// Typed twin of `Rpc.native_home` (jsonb → `Me` instead of `JSONValue`).
struct NativeHomeCall: RpcCall {
  static let name = "native_home"
  static let optionalArgs: [String] = []
  typealias Returns = Me
}

public protocol MeRepository: Sendable {
  func load(userId: UUID) async throws -> Me
}

public struct SupabaseMeRepository: MeRepository {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  public func load(userId: UUID) async throws -> Me {
    do {
      return try await svc.call(NativeHomeCall())
    } catch let e as RpcError where e.isMissingFunction {
      return try await legacyBootstrap(userId: userId)
    }
  }

  // MARK: - Fallback: the web client's reads, assembled into the same shape

  private struct ProfileRow: Decodable {
    let id: UUID; let display_name: String?; let handle: String?; let marker: String?
    let city: String?; let home_course: String?; let index_current: Double?; let index_source: String?
    let photo_path: String?; let created_at: Date?; let discoverable: String?
  }
  private struct LeagueRow: Decodable { let id: UUID; let name: String; let code: String?; let phase: String; let commissioner_id: UUID? }
  private struct MemberRow: Decodable { let id: UUID; let league_id: UUID; let role: String; let marker: String?; let leagues: LeagueRow? }
  private struct SeasonRow: Decodable {
    let id: UUID; let league_id: UUID; let number: Int?; let starts_on: String; let ends_on: String; let status: String
    let timezone: String?; let grace_hours: Int?; let champion_squad_id: UUID?; let champion_member_id: UUID?
    let points_king_member_id: UUID?; let tiebreak_rung: String?
  }
  private struct SquadRow: Decodable { let id: UUID; let name: String; let color: Int; let season_id: UUID }
  private struct SeatRow: Decodable { let squad_id: UUID; let member_id: UUID }
  private struct SquadStandingRow: Decodable { let season_id: UUID; let squad_id: UUID; let points: Double? }
  private struct IndivStandingRow: Decodable { let member_id: UUID; let season_id: UUID; let points: Double? }
  private struct CountRow: Decodable { let count: Int }

  private func legacyBootstrap(userId: UUID) async throws -> Me {
    let db = svc.client

    // profile — named columns (email is sealed; never select *)
    let profiles: [ProfileRow] = try await db.from("profiles")
      .select("id, display_name, handle, marker, city, home_course, index_current, index_source, photo_path, created_at, discoverable")
      .eq("id", value: userId).execute().value
    let p = profiles.first
    let roundsCount: Int = (try? await db.from("rounds").select("id", head: true, count: .exact)
      .eq("profile_id", value: userId).eq("voided", value: false).execute().count) ?? 0

    let profile = p.map { Me.Profile(id: $0.id, display_name: $0.display_name, handle: $0.handle, marker: $0.marker, city: $0.city,
                                     home_course: $0.home_course, index_current: $0.index_current, index_source: $0.index_source,
                                     photo_path: $0.photo_path, rounds_count: roundsCount, member_since: $0.created_at, is_founder: nil,
                                     discoverable: $0.discoverable) }

    // memberships with their league
    let members: [MemberRow] = try await db.from("league_members")
      .select("id, league_id, role, marker, leagues(id, name, code, phase, commissioner_id)")
      .eq("profile_id", value: userId).execute().value
    guard !members.isEmpty else { return Me(profile: profile) }
    let leagueIds = members.map(\.league_id)

    async let settingsRows: [SettingsRow] = db.from("league_settings")
      .select("league_id, structure, preset, counting_cap, participation_floor, floor_penalty, handicap_allowance, buyin_cents, payout_champ, payout_runnerup, payout_king, finish, locked_at")
      .in("league_id", values: leagueIds).execute().value
    async let seasonRows: [SeasonRow] = db.from("seasons")
      .select("id, league_id, number, starts_on, ends_on, status, timezone, grace_hours, champion_squad_id, champion_member_id, points_king_member_id, tiebreak_rung")
      .in("league_id", values: leagueIds).order("number", ascending: false).execute().value
    let (settings, seasons) = try await (settingsRows, seasonRows)

    // latest season per league
    var seasonByLeague: [UUID: SeasonRow] = [:]
    for s in seasons where seasonByLeague[s.league_id] == nil { seasonByLeague[s.league_id] = s }
    let seasonIds = Array(seasonByLeague.values.map(\.id))

    var squads: [SquadRow] = [], seats: [SeatRow] = [], squadStandings: [SquadStandingRow] = [], indiv: [IndivStandingRow] = []
    if !seasonIds.isEmpty {
      async let sq: [SquadRow] = db.from("squads").select("id, name, color, season_id").in("season_id", values: seasonIds).execute().value
      async let se: [SeatRow] = db.from("squad_members").select("squad_id, member_id").in("member_id", values: members.map(\.id)).execute().value
      async let ss: [SquadStandingRow] = db.from("v_squad_standings").select("season_id, squad_id, points").in("season_id", values: seasonIds).execute().value
      async let iv: [IndivStandingRow] = db.from("v_individual_standings").select("member_id, season_id, points").in("season_id", values: seasonIds).execute().value
      (squads, seats, squadStandings, indiv) = try await (sq, se, ss, iv)
    }

    let memberships: [Me.Membership] = members.map { m in
      let league = m.leagues
      let st = settings.first { $0.league_id == m.league_id }
      let season = seasonByLeague[m.league_id]
      let mySeat = seats.first { seat in seat.member_id == m.id && squads.contains { $0.id == seat.squad_id && $0.season_id == season?.id } }
      let mySquad = squads.first { $0.id == mySeat?.squad_id }
      var standing: Me.Standing? = nil
      if let season {
        if st?.structure == "solo" {
          let rows = indiv.filter { $0.season_id == season.id }.sorted { ($0.points ?? 0) > ($1.points ?? 0) }
          if let i = rows.firstIndex(where: { $0.member_id == m.id }) {
            let top = rows.first?.points ?? 0
            standing = Me.Standing(rank: i + 1, of: rows.count, points: rows[i].points, prev_rank: nil, leader_squad_id: nil,
                                   leader_points: top, gap_to_leader: top - (rows[i].points ?? 0),
                                   gap_to_next: i > 0 ? (rows[i - 1].points ?? 0) - (rows[i].points ?? 0) : nil)
          }
        } else if let mySquad {
          let rows = squadStandings.filter { $0.season_id == season.id }
            .sorted { a, b in
              if (a.points ?? 0) != (b.points ?? 0) { return (a.points ?? 0) > (b.points ?? 0) }
              return (squads.first { $0.id == a.squad_id }?.name ?? "") < (squads.first { $0.id == b.squad_id }?.name ?? "")
            }
          if let i = rows.firstIndex(where: { $0.squad_id == mySquad.id }) {
            let top = rows.first
            standing = Me.Standing(rank: i + 1, of: rows.count, points: rows[i].points, prev_rank: nil, leader_squad_id: top?.squad_id,
                                   leader_points: top?.points, gap_to_leader: (top?.points ?? 0) - (rows[i].points ?? 0),
                                   gap_to_next: i > 0 ? (rows[i - 1].points ?? 0) - (rows[i].points ?? 0) : nil)
          }
        }
      }
      return Me.Membership(
        league_id: m.league_id, name: league?.name ?? "League", code: league?.code, phase: league?.phase ?? "setup",
        role: m.role, member_id: m.id, marker: m.marker ?? p?.marker, commissioner_name: nil,
        settings: st.map { Me.Settings(structure: $0.structure, preset: $0.preset, counting_cap: $0.counting_cap, participation_floor: $0.participation_floor,
                                       floor_penalty: $0.floor_penalty, handicap_allowance: $0.handicap_allowance, buyin_cents: $0.buyin_cents,
                                       payout_champ: $0.payout_champ, payout_runnerup: $0.payout_runnerup, payout_king: $0.payout_king,
                                       finish: $0.finish, locked_at: $0.locked_at) },
        season: season.map { Me.Season(id: $0.id, number: $0.number, starts_on: $0.starts_on, ends_on: $0.ends_on, status: $0.status,
                                       timezone: $0.timezone, grace_hours: $0.grace_hours, champion_squad_id: $0.champion_squad_id,
                                       champion_member_id: $0.champion_member_id, points_king_member_id: $0.points_king_member_id,
                                       tiebreak_rung: $0.tiebreak_rung) },
        squad: mySquad.map { Me.Squad(id: $0.id, name: $0.name, color: $0.color) },
        standing: standing, pulse: nil)
    }
    return Me(profile: profile, memberships: memberships)
  }

  private struct SettingsRow: Decodable {
    let league_id: UUID; let structure: String?; let preset: String?; let counting_cap: Int?; let participation_floor: Int?
    let floor_penalty: String?; let handicap_allowance: Int?; let buyin_cents: Int?; let payout_champ: Int?; let payout_runnerup: Int?
    let payout_king: Int?; let finish: String?; let locked_at: Date?
  }
}
