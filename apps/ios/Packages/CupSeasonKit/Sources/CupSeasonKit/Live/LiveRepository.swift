// Cup Season — the live round's data layer (audit 04 §3.1–3.2, §4.1).
//
// Every write is an RPC through `SupabaseService.call` (the skew retry drops
// `p_config` / `p_result` on ANY error, as the web did by message at 8983 and
// 9155). Three calls are hand-declared because the generator maps a nullable
// uuid / int to a non-optional: `start_live_round` (course_id/tee_id are
// always null from the client, 8977), and the two `*_set_score` (a null
// `p_strokes` DELETES the cell). Same names, same grants — preflight 17 sees
// them through `static let name`.

import Foundation
import Supabase

/// `start_live_round` with the nullable uuids encoded as explicit nulls —
/// p_league included (D107: null = a league-less round).
struct LiveStartCall: RpcCall {
  static let name = "start_live_round"
  // D150 repair · p_api_course_id is OPTIONAL so `call()`'s skew retry can drop
  // it against a database that predates D150 — the round still starts, it just
  // starts without a course identity, exactly as it did before.
  static let optionalArgs: [String] = ["p_config", "p_api_course_id"]
  typealias Returns = JSONValue
  let p_league: UUID?
  let p_course_label: String
  let p_snapshot: JSONValue
  let p_game: String
  let p_players: JSONValue
  let p_config: JSONValue?
  /// `api_courses.id` — the phone HAS this (it queries api_course_tees with it)
  /// and never sent it, so every iOS live round landed with no course identity
  /// and every card it posted fell out of the Tour Card's shared courses.
  let p_api_course_id: String?
  enum Keys: String, CodingKey { case p_league, p_course_id, p_tee_id, p_course_label, p_snapshot, p_game, p_players, p_config, p_api_course_id }
  func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: Keys.self)
    try c.encode(p_league, forKey: .p_league)
    try c.encodeNil(forKey: .p_course_id)
    try c.encodeNil(forKey: .p_tee_id)
    try c.encode(p_course_label, forKey: .p_course_label)
    try c.encode(p_snapshot, forKey: .p_snapshot)
    try c.encode(p_game, forKey: .p_game)
    try c.encode(p_players, forKey: .p_players)
    if let p_config { try c.encode(p_config, forKey: .p_config) }
    if let p_api_course_id { try c.encode(p_api_course_id, forKey: .p_api_course_id) }
  }
}

/// `live_set_score` — `p_strokes` null deletes; `p_client_ts` keeps its ms.
struct LiveSetScoreCall: RpcCall {
  static let name = "live_set_score"
  static let optionalArgs: [String] = []
  typealias Returns = RpcVoid
  let p_live_round: UUID
  let p_player: UUID
  let p_hole: Int
  let p_strokes: Int?
  let p_client_ts: String
  enum Keys: String, CodingKey { case p_live_round, p_player, p_hole, p_strokes, p_client_ts }
  func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: Keys.self)
    try c.encode(p_live_round, forKey: .p_live_round)
    try c.encode(p_player, forKey: .p_player)
    try c.encode(p_hole, forKey: .p_hole)
    try c.encode(p_strokes, forKey: .p_strokes)
    try c.encode(p_client_ts, forKey: .p_client_ts)
  }
}

struct LiveGuestSetScoreCall: RpcCall {
  static let name = "guest_live_set_score"
  static let optionalArgs: [String] = []
  typealias Returns = RpcVoid
  let p_token: UUID
  let p_player: UUID
  let p_hole: Int
  let p_strokes: Int?
  let p_client_ts: String
  enum Keys: String, CodingKey { case p_token, p_player, p_hole, p_strokes, p_client_ts }
  func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: Keys.self)
    try c.encode(p_token, forKey: .p_token)
    try c.encode(p_player, forKey: .p_player)
    try c.encode(p_hole, forKey: .p_hole)
    try c.encode(p_strokes, forKey: .p_strokes)
    try c.encode(p_client_ts, forKey: .p_client_ts)
  }
}

struct LiveSetWolfCall: RpcCall {
  static let name = "live_set_wolf"
  static let optionalArgs: [String] = []
  typealias Returns = RpcVoid
  let p_live_round: UUID
  let p_hole: Int
  let p_wolf: JSONValue
  let p_client_ts: String
}

struct LiveGuestSetWolfCall: RpcCall {
  static let name = "guest_live_set_wolf"
  static let optionalArgs: [String] = []
  typealias Returns = RpcVoid
  let p_token: UUID
  let p_hole: Int
  let p_wolf: JSONValue
  let p_client_ts: String
}

/// What `start_live_round` hands back (8987–8991).
public struct LiveStartOutcome: Sendable, Equatable {
  public struct Seat: Sendable, Equatable {
    public let id: UUID
    public let position: Int
    public let guestName: String?
    public let claimToken: UUID?
  }
  public let lr: UUID
  public let code: String?
  public let seats: [Seat]

  public init?(_ v: JSONValue) {
    guard let id = v["live_round_id"]?.string.flatMap(UUID.init) else { return nil }
    lr = id
    code = v["join_code"]?.string
    seats = (v["players"]?.array ?? []).compactMap { p in
      guard let pid = p["id"]?.string.flatMap(UUID.init) else { return nil }
      return Seat(id: pid, position: p["position"]?.int ?? 0, guestName: p["guest_name"]?.string, claimToken: p["claim_token"]?.string.flatMap(UUID.init))
    }.sorted { $0.position < $1.position }
  }
}

/// What `finish_live_round` hands back (`{posted, guests, skipped, casual}` / `{already_final}`).
public struct LiveFinishOutcome: Sendable, Equatable {
  public struct Posted: Sendable, Equatable { public let name: String; public let gross: Int?; public let holes: Int? }
  public struct Guest: Sendable, Equatable { public let name: String; public let token: UUID? }
  public struct Skipped: Sendable, Equatable { public let name: String; public let reason: String }
  public let posted: [Posted]
  public let guests: [Guest]
  public let skipped: [Skipped]
  public let casual: Bool
  public let alreadyFinal: Bool

  public init(posted: [Posted] = [], guests: [Guest] = [], skipped: [Skipped] = [], casual: Bool = false, alreadyFinal: Bool = false) {
    self.posted = posted; self.guests = guests; self.skipped = skipped; self.casual = casual; self.alreadyFinal = alreadyFinal
  }

  public init(_ v: JSONValue) {
    alreadyFinal = v["already_final"]?.bool ?? false
    posted = (v["posted"]?.array ?? []).map { Posted(name: $0["name"]?.string ?? "A golfer", gross: $0["gross"]?.int, holes: $0["holes"]?.int) }
    guests = (v["guests"]?.array ?? []).map { Guest(name: $0["name"]?.string ?? "Guest", token: $0["claim_token"]?.string.flatMap(UUID.init)) }
    skipped = (v["skipped"]?.array ?? []).map { Skipped(name: $0["name"]?.string ?? "A golfer", reason: $0["reason"]?.string ?? "") }
    casual = v["casual"]?.bool ?? false
  }
}

/// A league mate on the pick list (`primeRealRoster`, 7398).
public struct LiveRosterRow: Sendable, Equatable {
  public let memberId: UUID
  public let profileId: UUID?
  public let displayName: String?
  public let indexCurrent: Double?
}

public struct LiveRepository: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  /// ISO-8601 with the ms the write clock carries — PostgREST casts it to timestamptz.
  public static func iso(ms: Int64) -> String {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f.string(from: Date(timeIntervalSince1970: Double(ms) / 1000))
  }

  // MARK: the round

  public func start(league: UUID?, label: String, snapshot: JSONValue, game: LiveGame, players: JSONValue, config: JSONValue,
                    apiCourseId: String? = nil) async throws -> LiveStartOutcome {
    let v = try await svc.call(LiveStartCall(p_league: league, p_course_label: label, p_snapshot: snapshot, p_game: game.server,
                                             p_players: players, p_config: config, p_api_course_id: apiCourseId))
    guard let out = LiveStartOutcome(v) else {
      throw RpcError(name: "start_live_round", underlying: "The round did not come back with an id.", droppedArgs: [])
    }
    return out
  }

  public func finish(lr: UUID, cards: JSONValue, casual: Bool, result: JSONValue?) async throws -> LiveFinishOutcome {
    LiveFinishOutcome(try await svc.call(Rpc.finish_live_round(p_live_round: lr, p_cards: cards, p_casual: casual, p_result: result)))
  }

  public func abandon(_ lr: UUID) async throws {
    _ = try await svc.call(Rpc.abandon_live_round(p_live_round: lr))
  }

  /// `drainAbandons` (7593): retry every queued scrap; keep what still fails.
  public func drainAbandons(disk: LiveDisk = .shared) async {
    let q = await disk.pendingAbandons()
    guard !q.isEmpty else { return }
    var left: [UUID] = []
    for id in q {
      do { try await abandon(id) } catch { left.append(id) }
    }
    await disk.savePendingAbandons(left)
  }

  public func state(_ lr: UUID) async throws -> JSONValue { try await svc.call(Rpc.live_state(p_live_round: lr)) }
  public func guestState(_ token: UUID) async throws -> JSONValue { try await svc.call(Rpc.guest_live_state(p_token: token)) }

  public func setScore(lr: UUID, player: UUID, hole: Int, strokes: Int?, cts: Int64, guest: UUID?) async throws {
    let ts = LiveRepository.iso(ms: cts)
    if let guest { _ = try await svc.call(LiveGuestSetScoreCall(p_token: guest, p_player: player, p_hole: hole, p_strokes: strokes, p_client_ts: ts)) }
    else { _ = try await svc.call(LiveSetScoreCall(p_live_round: lr, p_player: player, p_hole: hole, p_strokes: strokes, p_client_ts: ts)) }
  }

  public func setWolf(lr: UUID, hole: Int, pick: JSONValue, cts: Int64, guest: UUID?) async throws {
    let ts = LiveRepository.iso(ms: cts)
    if let guest { _ = try await svc.call(LiveGuestSetWolfCall(p_token: guest, p_hole: hole, p_wolf: pick, p_client_ts: ts)) }
    else { _ = try await svc.call(LiveSetWolfCall(p_live_round: lr, p_hole: hole, p_wolf: pick, p_client_ts: ts)) }
  }

  // MARK: resume (`rehydrateLiveRound` 7620–7650)

  static func cols(joinCode: Bool, starter: Bool = true) -> String {
    "id, league_id, game, game_config, \(joinCode ? "join_code, " : "")\(starter ? "starter_profile_id, " : "")started_by, course_snapshot, course_label, started_at, live_round_players(id, member_id, guest_name, guest_index, index_source, position, guest_profile_id, member:league_members(profile_id, profile:profiles(display_name, index_current)))"
  }

  /// Open rounds I can see (member RLS, or a D107 participant), newest first.
  /// Deploy skew, two rungs — retry on ANY error (column errors never name the
  /// column): an old DB has no starter_profile_id (D107) yet, an ancient one
  /// no join_code; labeling/sync just degrade.
  public func openRounds() async throws -> [JSONValue] {
    do {
      return try await svc.client.from("live_rounds").select(LiveRepository.cols(joinCode: true, starter: true)).eq("status", value: "live")
        .order("started_at", ascending: false).execute().value
    } catch {
      do {
        return try await svc.client.from("live_rounds").select(LiveRepository.cols(joinCode: true, starter: false)).eq("status", value: "live")
          .order("started_at", ascending: false).execute().value
      } catch {
        return try await svc.client.from("live_rounds").select(LiveRepository.cols(joinCode: false, starter: false)).eq("status", value: "live")
          .order("started_at", ascending: false).execute().value
      }
    }
  }

  /// D88: rounds where I am a known guest — fail-open (an old DB has no RPC).
  public func visitorRounds() async -> [JSONValue] {
    (try? await svc.call(Rpc.my_visitor_rounds()))?.array ?? []
  }

  // MARK: the course card (6900–6934)

  private struct TeeRow: Decodable { let id: String; let tee_name: String?; let number_of_holes: Int? }
  private struct HoleRow: Decodable { let hole_number: Int?; let par: Int?; let handicap: Int? }

  /// The per-hole par + stroke index for a picked tee, wanting `holes` (18 or 9).
  /// nil when the cache has no usable card (the typed path stands).
  public func courseHoles(courseId: String, teeName: String?, want: Int) async -> [(par: Int, handicap: Int)]? {
    guard let tees: [TeeRow] = try? await svc.client.from("api_course_tees").select("id, tee_name, number_of_holes").eq("course_id", value: courseId).execute().value else { return nil }
    let row = tees.first { $0.tee_name == teeName && $0.number_of_holes == want } ?? tees.first { $0.tee_name == teeName }
    guard let row else { return nil }
    guard let holes: [HoleRow] = try? await svc.client.from("api_course_holes").select("hole_number, par, handicap").eq("tee_id", value: row.id)
      .order("hole_number", ascending: true).execute().value, !holes.isEmpty else { return nil }
    return holes.map { (par: $0.par ?? 4, handicap: $0.handicap ?? 0) }
  }

  // MARK: the pick list (7398)

  private struct MemberRow: Decodable {
    struct P: Decodable { let display_name: String?; let index_current: Double? }
    let id: UUID; let profile_id: UUID?; let profile: P?
  }

  public func leagueRoster(leagueId: UUID) async throws -> [LiveRosterRow] {
    let rows: [MemberRow] = try await svc.client.from("league_members").select("id, profile_id, profile:profiles(display_name, index_current)")
      .eq("league_id", value: leagueId).execute().value
    return rows.map { LiveRosterRow(memberId: $0.id, profileId: $0.profile_id, displayName: $0.profile?.display_name, indexCurrent: $0.profile?.index_current) }
  }

  // MARK: D154 / D156 · who you actually play with, and who is standing here

  /// A golfer the picker may offer. Both sources are held to the same
  /// disclosure envelope as `search_golfers`; the RPCs hold that line, and
  /// these rows are the generated ones mapped, never a parallel decode.
  public struct PartnerRow: Sendable, Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let handle: String?
    public let city: String?
    public let homeCourse: String?
    public let marker: String?
    public let index: Double?
    public let rel: String?
    /// nil for a nearby hit — proximity says "here", not "how often"
    public let lastPlayed: Date?
    public let roundsTogether: Int?
  }

  /// D154 · the regulars, most recent first. Never throws into the caller's
  /// face: an empty list is a fine answer, and the league chips sit underneath.
  public func recentPartners(limit: Int = 12) async -> [PartnerRow] {
    let rows = (try? await svc.call(Rpc.recent_partners(p_limit: limit))) ?? []
    return rows.compactMap { r in
      guard let id = r.id else { return nil }
      return PartnerRow(id: id, name: r.display_name ?? "Golfer", handle: r.handle,
                        city: r.city, homeCourse: r.home_course, marker: r.marker,
                        index: r.index_current, rel: r.rel,
                        lastPlayed: r.last_played, roundsTogether: r.rounds_together)
    }
  }

  /// D156 · of profile ids handed over a local Bluetooth session, only the ones
  /// already a buddy or a league mate. A stranger's phone resolves to nothing.
  public func nearbyResolve(_ ids: [UUID]) async -> [PartnerRow] {
    guard !ids.isEmpty else { return [] }
    let rows = (try? await svc.call(Rpc.nearby_resolve(p_profiles: ids))) ?? []
    return rows.compactMap { r in
      guard let id = r.id else { return nil }
      return PartnerRow(id: id, name: r.display_name ?? "Golfer", handle: r.handle,
                        city: r.city, homeCourse: r.home_course, marker: r.marker,
                        index: r.index_current, rel: r.rel,
                        lastPlayed: nil, roundsTogether: nil)
    }
  }

  // MARK: the plan bridge (8349)

  /// A round of mine on the tee sheet today, if any.
  public func todaysPlan() async -> ScheduledRound? {
    let today = CSDate.today()
    let rows = (try? await ScheduleService(svc).watch(today: today)) ?? []
    return rows.first { $0.mine != false && $0.play_on == today }
  }

  // MARK: sharing (D57; 5857–5935)

  public func mintShare(kind: String, ref: UUID) async throws -> UUID {
    try await svc.call(Rpc.create_share(p_kind: kind, p_ref: ref))
  }

  /// `csRevokeLink`: re-mint the live token, then kill it.
  public func revokeShare(kind: String, ref: UUID) async throws {
    let tok = try await mintShare(kind: kind, ref: ref)
    _ = try await svc.call(Rpc.revoke_share(p_token: tok))
  }

  /// The settlement card travels with the link (D78/OG): publish the PNG at
  /// `shared/<token>.png` unless it is already there. Best effort — the link
  /// works card-less if any step misses.
  public func publishSettlementCard(token: UUID, png: Data) async {
    let name = token.uuidString.lowercased() + ".png"
    do {
      let head = try await svc.client.storage.from("shared").list(path: "", options: SearchOptions(limit: 1, search: name))
      if head.contains(where: { $0.name == name }) { return }
      try await svc.client.storage.from("shared").upload(name, data: png, options: FileOptions(contentType: "image/png", upsert: false))
    } catch {
      // ships card-less
    }
  }

  // MARK: claims (17583–17632; boot 17664–17729)

  public func claimInfo(_ token: UUID) async -> JSONValue? {
    if let v = try? await svc.call(Rpc.claim_round_info(p_token: token)), !v.isNull { return v }
    return nil
  }
  public func scanClaimInfo(_ token: UUID) async -> JSONValue? {
    if let v = try? await svc.call(Rpc.scan_claim_info(p_token: token)), !v.isNull { return v }
    return nil
  }
  public func claimRound(_ token: UUID) async throws -> JSONValue { try await svc.call(Rpc.claim_round(p_token: token)) }
  public func claimScanRound(_ token: UUID) async throws -> JSONValue { try await svc.call(Rpc.claim_scan_round(p_token: token)) }
}
