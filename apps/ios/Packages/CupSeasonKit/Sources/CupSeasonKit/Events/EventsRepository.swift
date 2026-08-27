// Cup Season — the events data layer, mirroring the web client.
//
// Reads: `loadEvent` (15833–15905) — six parallel selects, then the Major's
// board + cards, the lineage chain, and the number to beat per open session,
// each one skew-safe (a missing RPC leaves that surface empty, the board
// posts still tell the story). `loadMyEvents` (15811–15831) for the chips.
//
// Writes: every one an RPC through `SupabaseService.call`. `create_event`
// and `create_major` keep the web's OWN retry sequence — drop `p_lineage`,
// then `p_tz` — because the service's generic retry would also drop
// `p_league`, and a Ryder that silently detached from its league is a
// different event, not a skew recovery.

import Foundation
import Supabase

/// `create_event`'s args, with the optional set encoded only when present.
/// `optionalArgs` is empty on purpose: the sequence below is by hand.
struct RyderCreateCall: RpcCall {
  static let name = "create_event"
  static let optionalArgs: [String] = []
  typealias Returns = UUID
  let p_name: String
  let p_starts_on: String
  let p_sessions: Int
  let p_session_weeks: Int
  let p_draw_rule: String
  let p_team_a: String
  let p_team_b: String
  let p_league: UUID?
  let p_tz: String?
  let p_lineage: UUID?
}

/// `create_major`'s args — same discipline.
struct MajorCreateCall: RpcCall {
  static let name = "create_major"
  static let optionalArgs: [String] = []
  typealias Returns = UUID
  let p_name: String
  let p_final_on: String
  let p_days: Int
  let p_buy_in: Double
  let p_pot_split: String
  let p_league: UUID?
  let p_tz: String?
  let p_lineage: UUID?
}

/// What the Ryder setup sheet sends (openRyderSetup 15988–16000).
public struct RyderDraft: Sendable, Equatable {
  public var name: String
  public var teamA: String
  public var teamB: String
  public var sessions: Int
  public var weeks: Int
  public var startsOn: String
  public var league: UUID?
  public var lineage: UUID?
  public init(name: String, teamA: String, teamB: String, sessions: Int, weeks: Int, startsOn: String, league: UUID?, lineage: UUID?) {
    self.name = name; self.teamA = teamA; self.teamB = teamB; self.sessions = sessions; self.weeks = weeks
    self.startsOn = startsOn; self.league = league; self.lineage = lineage
  }
}

/// What the Major setup sheet sends (openMajorSetup 16110–16118).
public struct MajorDraft: Sendable, Equatable {
  public var name: String
  public var finalOn: String
  public var days: Int
  public var buyIn: Double
  public var potSplit: String
  public var league: UUID?
  public var lineage: UUID?
  public init(name: String, finalOn: String, days: Int, buyIn: Double, potSplit: String, league: UUID?, lineage: UUID?) {
    self.name = name; self.finalOn = finalOn; self.days = days; self.buyIn = buyIn; self.potSplit = potSplit
    self.league = league; self.lineage = lineage
  }
}

public struct EventsRepository: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }
  var db: SupabaseClient { svc.client }

  /// R12.2: standalone events run on the creator's clock — the device IANA tz.
  public static var deviceTimeZone: String? { TimeZone.current.identifier }

  // MARK: - reads

  private struct PlayerRaw: Decodable {
    struct Prof: Decodable { let display_name: String?; let marker: String? }
    let id: UUID
    let profile_id: UUID?
    let team_id: UUID?
    let role: String?
    let seed: Int?
    let benched_count: Int?
    let notify_target: Bool?
    let exhibition: Bool?
    let profile: Prof?
    var player: EventPlayer {
      EventPlayer(id: id, profileId: profile_id, teamId: team_id, role: role ?? "player", seed: seed ?? 0,
                  benchedCount: benched_count ?? 0, notifyTarget: notify_target ?? false, exhibition: exhibition ?? false,
                  name: profile?.display_name ?? "—", marker: profile?.marker ?? "saguaro")
    }
  }
  private struct ScoreRaw: Decodable { let team_id: UUID?; let points: Double? }

  /// `loadEvent(id)` — the room, or a throw (the web logs and leaves "No event loaded.").
  public func load(_ id: UUID) async throws -> EventRoom {
    async let ev: EventRow = db.from("events").select("*").eq("id", value: id).single().execute().value
    async let tm: [EventTeam] = db.from("event_teams").select("*").eq("event_id", value: id).order("slot").execute().value
    async let pl: [PlayerRaw] = db.from("event_players").select("*, profile:profiles(display_name, marker)").eq("event_id", value: id).execute().value
    async let ss: [EventSession] = db.from("event_sessions").select("*").eq("event_id", value: id).order("session_no").execute().value
    async let du: [EventDuel] = db.from("event_duels").select("*").eq("event_id", value: id).execute().value
    async let sc: [ScoreRaw] = db.from("v_event_scoreboard").select("team_id, points").eq("event_id", value: id).execute().value
    var room = try await EventRoom(event: ev, teams: tm, players: pl.map(\.player), sessions: ss, duels: du)
    for r in try await sc { if let t = r.team_id { room.scoreboard[t] = r.points ?? 0 } }

    if room.event.isMajor {
      // the live board (definer read) and the frozen cards — skew-safe
      if let mb = try? await svc.call(Rpc.major_leaderboard(p_event: id)) { room.majorBoard = mb.compactMap(MajorBoardRow.init) }
      if let mc: [MajorCard] = try? await db.from("event_major_cards").select("*").eq("event_id", value: id).execute().value { room.majorCards = mc }
    }
    // the lineage chain (D61/D62) — a missing RPC just means no chain UI
    if let lg = try? await svc.call(Rpc.event_lineage(p_event: id)) { room.lineage = lg.compactMap(EventLineageRow.init) }
    // the number to beat — live targets for every OPEN session's pending duels
    if !room.event.isMajor {
      for s in room.sessions where s.isOpen {
        if let tg = try? await svc.call(Rpc.event_session_targets(p_session: s.id)) {
          for t in tg { if let d = t.duel_id { room.targets[d] = EventTarget(a: t.a_pvi, b: t.b_pvi) } }
        }
      }
    }
    // the event board: engine posts (pairings, results, the cup) — newest first, 30
    if let ps: [EventPost] = try? await db.from("posts").select("id, kind, body, created_at").eq("event_id", value: id)
      .order("created_at", ascending: false).limit(30).execute().value { room.posts = ps }
    return room
  }

  private struct MineRaw: Decodable {
    struct Ev: Decodable { let id: UUID; let name: String; let status: String; let kind: String? }
    let event: Ev?
  }
  private struct AttachedRaw: Decodable { let id: UUID; let name: String; let status: String; let kind: String?; let league_id: UUID? }

  /// `loadMyEvents` — mine (every status), then the crew's attached events I
  /// have not joined (`mine:false`, never complete). Old DB: attached stay invite-only.
  public func myEvents(profile: UUID, leagueIds: [UUID]) async -> [EventSummary] {
    var out: [EventSummary] = []
    if let rows: [MineRaw] = try? await db.from("event_players").select("event:events(id, name, status, kind)").eq("profile_id", value: profile).execute().value {
      out = rows.compactMap(\.event).map { EventSummary(id: $0.id, name: $0.name, kind: $0.kind ?? "ryder", status: $0.status, mine: true) }
    }
    if !leagueIds.isEmpty,
       let att: [AttachedRaw] = try? await db.from("events").select("id, name, status, kind, league_id").in("league_id", values: leagueIds)
        .neq("status", value: "complete").execute().value {
      let seen = Set(out.map(\.id))
      for e in att where !seen.contains(e.id) {
        out.append(EventSummary(id: e.id, name: e.name, kind: e.kind ?? "ryder", status: e.status, leagueId: e.league_id, mine: false))
      }
    }
    return out
  }

  // MARK: - creates, with the web's own skew sequence

  private func isSkew(_ e: Error) -> Bool { (e as? RpcError)?.isMissingFunction ?? false }

  /// `create_event` — drop `p_lineage`, then `p_tz`, and retry (16002–16010).
  public func createRyder(_ d: RyderDraft) async throws -> UUID {
    let tz = Self.deviceTimeZone
    var call = RyderCreateCall(p_name: d.name, p_starts_on: d.startsOn, p_sessions: d.sessions, p_session_weeks: d.weeks,
                               p_draw_rule: "team_pvi", p_team_a: d.teamA, p_team_b: d.teamB, p_league: d.league, p_tz: tz, p_lineage: d.lineage)
    do { return try await svc.call(call) } catch {
      guard isSkew(error) else { throw error }
      if call.p_lineage != nil {
        call = RyderCreateCall(p_name: d.name, p_starts_on: d.startsOn, p_sessions: d.sessions, p_session_weeks: d.weeks,
                               p_draw_rule: "team_pvi", p_team_a: d.teamA, p_team_b: d.teamB, p_league: d.league, p_tz: tz, p_lineage: nil)
        do { return try await svc.call(call) } catch { guard isSkew(error) else { throw error } }
      }
      call = RyderCreateCall(p_name: d.name, p_starts_on: d.startsOn, p_sessions: d.sessions, p_session_weeks: d.weeks,
                             p_draw_rule: "team_pvi", p_team_a: d.teamA, p_team_b: d.teamB, p_league: d.league, p_tz: nil, p_lineage: nil)
      return try await svc.call(call)
    }
  }

  /// `create_major` — drop `p_lineage` and retry (16121–16125).
  public func createMajor(_ d: MajorDraft) async throws -> UUID {
    let tz = Self.deviceTimeZone
    let full = MajorCreateCall(p_name: d.name, p_final_on: d.finalOn, p_days: d.days, p_buy_in: d.buyIn, p_pot_split: d.potSplit,
                               p_league: d.league, p_tz: tz, p_lineage: d.lineage)
    do { return try await svc.call(full) } catch {
      guard isSkew(error), d.lineage != nil else { throw error }
      let slim = MajorCreateCall(p_name: d.name, p_final_on: d.finalOn, p_days: d.days, p_buy_in: d.buyIn, p_pot_split: d.potSplit,
                                 p_league: d.league, p_tz: tz, p_lineage: nil)
      return try await svc.call(slim)
    }
  }

  /// The staged invites, fired once the event has an id — errors swallowed, as on the web.
  public func invite(_ profiles: [UUID], to event: UUID) async {
    let people = PeopleService(svc)
    for p in profiles { try? await people.invite(p, to: .event(event)) }
  }

  // MARK: - the Ryder's organizer hands

  public func setTeam(player: UUID, team: UUID) async throws { _ = try await svc.call(Rpc.set_event_team(p_player: player, p_team: team)) }
  public func pair(session: UUID) async throws -> Int { try await svc.call(Rpc.generate_pairings(p_session: session)) }
  public func resolve(session: UUID) async throws { _ = try await svc.call(Rpc.resolve_session(p_session: session)) }
  public func notify(event: UUID, on: Bool) async throws { _ = try await svc.call(Rpc.set_event_notify(p_event: event, p_on: on)) }
  public func scrap(event: UUID) async throws { _ = try await svc.call(Rpc.delete_event(p_event: event)) }

  // MARK: - the Major's

  public func enter(major: UUID) async throws { _ = try await svc.call(Rpc.enter_major(p_event: major)) }
  public func openWindow(session: UUID) async throws { _ = try await svc.call(Rpc.open_major(p_session: session)) }
  public func settle(session: UUID) async throws { _ = try await svc.call(Rpc.settle_major(p_session: session)) }
}
