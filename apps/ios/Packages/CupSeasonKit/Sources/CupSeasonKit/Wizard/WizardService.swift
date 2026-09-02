// Cup Season — the wizard's writes (index.html, the module block):
//   createLeague   14852–14877   RPC create_league(p_name, p_code), telemetry league_create
//   lockBylaws     17194–17248   ONE call — RPC lock_league(...) (D111): the bylaws,
//                                season 1, form_squads unless solo, and the phase +
//                                name, in one server transaction. Idempotent on
//                                `locked_at`: a retap after an ambiguous failure gets
//                                `{already_locked: true}` and the standing truth
//                                instead of a second season. The next phase comes
//                                from the RPC's result (the STORED structure), never
//                                from the dials. Deploy skew does NOT ride the
//                                Kit's `call(_:)` retry: that retry sheds every
//                                droppable arg at once, so `WizardLockCall`
//                                declares none and a refusal reaches the golfer
//                                instead of locking a league on the SQL defaults.
//                                Every deployed signature since 20260829220000
//                                carries all eighteen args; the web's own skew
//                                path (17239–17248) falls back only when the
//                                FUNCTION is missing, never by dropping args.
//   the lock button 15226–15261  lock_attempt · lock_blocked · lock_ok telemetry
//   qaEvent        6097–6105     client_events INSERT, fire-and-forget, never throws
//   wizCancel      15278–15292   delete_league on step-0 Cancel
//   loadBylaws     14137–14142   league_settings select (run it back / an existing league)
//
// The reads here (`league`, `bylaws`, `season`, `memberCount`) are plain
// selects under RLS; the phone previews and renders, it never decides.

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

  // MARK: the lock (`lockBylaws` → `lock_league`)

  public struct Locked: Sendable, Equatable {
    public let nextPhase: String
    public let seasonId: UUID
    public let startsOn: String
    public let endsOn: String
    /// The RPC found `locked_at` already set — a retap; the truth above stands.
    public let alreadyLocked: Bool
  }

  /// One RPC. `today` pins the preview dates so a lock at 23:59 sends the same
  /// span the review card showed. The phase, the season and its dates are read
  /// back from the result — the server decided them.
  public func lock(leagueId: UUID, dials: WizardDials, fallbackName: String, today: String = CSDate.today()) async throws -> Locked {
    let typed = dials.name.trimmingCharacters(in: .whitespacesAndNewlines)
    let name = typed.isEmpty ? fallbackName : typed
    let call = WizardLockCall(dials, leagueId: leagueId, name: name, today: today)
    let data = try await svc.call(call)

    // `{already_locked, phase, season: row_to_json(seasons)}` — decoded defensively:
    // the season's id/dates may arrive nested (today's shape) or flat.
    let season = data["season"]
    guard let nextPhase = data["phase"]?.string,
          let idStr = season?["id"]?.string ?? data["season_id"]?.string, let seasonId = UUID(uuidString: idStr),
          let startsOn = season?["starts_on"]?.string ?? data["starts_on"]?.string,
          let endsOn = season?["ends_on"]?.string ?? data["ends_on"]?.string else {
      throw RpcError(name: WizardLockCall.name, underlying: "The bylaws locked but the season did not come back.", droppedArgs: [])
    }
    let already = data["already_locked"]?.bool ?? false
    // Honest breadcrumb: the skew retry drops every optional arg on ANY error,
    // so a lock that reached the database on its second try wears the SQL
    // defaults — the dates are the tell.
    let sentDates = call.args.p_starts_on == startsOn && call.args.p_ends_on == endsOn
    track(.lock_ok, ["next_phase": .string(nextPhase), "already_locked": .bool(already), "dates_as_sent": .bool(sentDates)])
    CSTelemetry.product(.leagueLocked, leagueId: leagueId)   // IOS-024
    return Locked(nextPhase: nextPhase, seasonId: seasonId, startsOn: startsOn, endsOn: endsOn, alreadyLocked: already)
  }

  // MARK: discard (`wizCancel`)

  public func deleteLeague(_ id: UUID) async throws {
    _ = try await svc.call(Rpc.delete_league(p_league: id))
  }
}
