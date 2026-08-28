// Cup Season — the wizard's writes (index.html, the module block):
//   createLeague   14852–14877   RPC create_league(p_name, p_code), telemetry league_create
//   lockBylaws     14884–14973   FIVE direct writes under RLS — the one place the
//                                phone writes tables directly, because the web does:
//                                (1) league_settings UPDATE (+ the skew retry dropping `finish`)
//                                (2) seasons INSERT {number:1, starts_on, ends_on} — reuses an existing row
//                                (3) RPC form_squads(p_season) unless solo
//                                (4) leagues UPDATE {phase, name}
//                                (the vestigial `invites` INSERT is D97-dead: staging is gone)
//   the lock button 15226–15261  lock_attempt · lock_blocked · lock_ok telemetry
//   qaEvent        6097–6105     client_events INSERT, fire-and-forget, never throws
//   wizCancel      15278–15292   delete_league on step-0 Cancel
//   loadBylaws     14137–14142   league_settings select (run it back / an existing league)
//
// Audit 02 §7.21: the lock is five writes, not a transaction — a retap after a
// partial lock must find `locked_at` set, a season row and `phase` still
// `setup`, and finish the job. Every write here is idempotent on that path.

import Foundation
import Supabase

public struct WizardService: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  // MARK: telemetry (`qaEvent`)

  public enum Event: String, Sendable { case league_create, lock_attempt, lock_blocked, lock_ok, invite_open }

  /// Fire-and-forget; a breadcrumb must never break a lock. One writer since
  /// IOS-024: `CSTelemetry` (dedupes, swallows, never blocks).
  public func track(_ event: Event, _ props: [String: JSONValue] = [:]) {
    CSTelemetry.event(event.rawValue, props)
  }

  // MARK: create (`createLeague`)

  public struct Created: Sendable, Equatable {
    public let leagueId: UUID
    public let name: String
    public let code: String
    public let memberId: UUID?
  }

  public func createLeague(name rawName: String) async throws -> Created {
    let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
    let finalName = name.isEmpty ? "My Cup" : name
    let code = WizardCode.codeFor(finalName)
    let data = try await svc.call(Rpc.create_league(p_name: finalName, p_code: code))
    guard let idStr = data["league"]?["id"]?.string, let id = UUID(uuidString: idStr) else {
      throw RpcError(name: "create_league", underlying: "The league was created but its id did not come back.", droppedArgs: [])
    }
    track(.league_create, ["named": .bool(finalName != "My Cup")])
    CSTelemetry.product(.leagueCreated, leagueId: id)   // IOS-024
    return Created(leagueId: id, name: data["league"]?["name"]?.string ?? finalName,
                   code: data["league"]?["code"]?.string ?? code,
                   memberId: data["member"]?["id"]?.string.flatMap(UUID.init))
  }

  // MARK: the existing league (an in-progress setup, or run it back)

  public struct LeagueHead: Decodable, Sendable, Equatable {
    public let id: UUID
    public let name: String
    public let code: String?
    public let phase: String
  }

  public func league(_ id: UUID) async throws -> LeagueHead? {
    let rows: [LeagueHead] = try await svc.client.from("leagues").select("id, name, code, phase").eq("id", value: id).limit(1).execute().value
    return rows.first
  }

  /// `loadBylaws` — the settings row, named columns.
  public func bylaws(_ leagueId: UUID) async throws -> LeagueRoom.Settings? {
    let rows: [LeagueRoom.Settings] = try await svc.client.from("league_settings")
      .select("league_id, preset, handicap_allowance, verification, counting_cap, participation_floor, floor_penalty, season_format, buyin_cents, season_months, locked_at, structure, draft_type, payout_champ, payout_runnerup, payout_king, finish")
      .eq("league_id", value: leagueId).limit(1).execute().value
    return rows.first
  }

  /// The number-1 season, if the league already has one (a retap after a partial lock).
  public func season(_ leagueId: UUID) async throws -> LeagueRoom.Season? {
    let rows: [LeagueRoom.Season] = try await svc.client.from("seasons").select("id, number, starts_on, ends_on, status")
      .eq("league_id", value: leagueId).eq("number", value: 1).limit(1).execute().value
    return rows.first
  }

  /// `openLockShare` counts THIS league's seats fresh (S2-04).
  public func memberCount(_ leagueId: UUID) async -> Int {
    let n = try? await svc.client.from("league_members").select("id", head: true, count: .exact).eq("league_id", value: leagueId).execute().count
    return n ?? 1
  }

  // MARK: the lock (`lockBylaws`)

  public struct Locked: Sendable, Equatable {
    public let nextPhase: String
    public let seasonId: UUID
    public let startsOn: String
    public let endsOn: String
  }

  private struct SeasonInsert: Encodable { let league_id: UUID; let number: Int; let starts_on: String; let ends_on: String }
  private struct LeaguePhase: Encodable { let phase: String; let name: String }

  /// The five-write sequence, in the web's order. `today` pins the preview dates
  /// so a lock at 23:59 writes the same span the review card showed.
  public func lock(leagueId: UUID, dials: WizardDials, fallbackName: String, today: String = CSDate.today(),
                   now: Date = Date()) async throws -> Locked {
    let db = svc.client
    let lockedAt = ISO8601DateFormatter().string(from: now)
    let payload = WizardLockPayload(dials, lockedAt: lockedAt)

    // (1) the bylaws — retry WITHOUT `finish` on ANY error (never sniff the message)
    do {
      try await db.from("league_settings").update(payload).eq("league_id", value: leagueId).execute()
    } catch {
      try await db.from("league_settings").update(payload.withoutFinish).eq("league_id", value: leagueId).execute()
    }

    // (2) the season — reuse number 1 on a retap, never duplicate
    let starts = dials.startDate(today: today), ends = dials.endDate(today: today)
    let seasonRow: LeagueRoom.Season
    if let existing = try await season(leagueId) {
      seasonRow = existing
    } else {
      let created: LeagueRoom.Season = try await db.from("seasons")
        .insert(SeasonInsert(league_id: leagueId, number: 1, starts_on: starts, ends_on: ends))
        .select("id, number, starts_on, ends_on, status").single().execute().value
      seasonRow = created
    }

    // (3) squads exist from lock; members join, then draw/assign fills them
    if !dials.solo { _ = try await svc.call(Rpc.form_squads(p_season: seasonRow.id)) }

    // (4) the phase and the name
    let nextPhase = dials.solo ? "season" : "draft"
    let typed = dials.name.trimmingCharacters(in: .whitespacesAndNewlines)
    let name = typed.isEmpty ? fallbackName : typed
    try await db.from("leagues").update(LeaguePhase(phase: nextPhase, name: name)).eq("id", value: leagueId).execute()

    track(.lock_ok, ["next_phase": .string(nextPhase)])
    CSTelemetry.product(.leagueLocked, leagueId: leagueId)   // IOS-024
    return Locked(nextPhase: nextPhase, seasonId: seasonRow.id, startsOn: seasonRow.starts_on, endsOn: seasonRow.ends_on)
  }

  // MARK: discard (`wizCancel`)

  public func deleteLeague(_ id: UUID) async throws {
    _ = try await svc.call(Rpc.delete_league(p_league: id))
  }
}
