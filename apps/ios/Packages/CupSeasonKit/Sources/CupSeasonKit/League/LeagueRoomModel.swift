// Cup Season — the league room's data (D100 / IOS-018, parity wave 1).
//
// One load per league, mirroring `enterLeague` → `loadLeagueData` →
// `loadStandingsAndFeed` (index.html 14187–14539): direct PostgREST reads on
// the RLS-scoped tables and views, exactly the columns the web reads, plus
// the ledger with its reasons and the settlement rows (§16). The Pro's tools
// are the same definer RPCs the web calls — identity is checked at the
// database, never by hiding a button. Nothing authoritative is computed here:
// the views are truth; this file orders and phrases.

import Foundation
import Observation
import Supabase

/// The signed-in golfer as the room needs them (from `Me`).
public struct RoomViewer: Sendable, Equatable {
  public let id: UUID
  public let displayName: String?
  public let marker: String?
  public let indexCurrent: Double?
  public let roundsCount: Int
  public init(id: UUID, displayName: String?, marker: String?, indexCurrent: Double?, roundsCount: Int) {
    self.id = id; self.displayName = displayName; self.marker = marker; self.indexCurrent = indexCurrent; self.roundsCount = roundsCount
  }
  public init?(_ me: Me) {
    guard let p = me.profile else { return nil }
    self.init(id: p.id, displayName: p.display_name, marker: p.marker, indexCurrent: p.index_current, roundsCount: p.rounds_count ?? 0)
  }
}

/// `set_league_notify_system(p_league, p_on)` — migration 20260828030000.
/// Hand-declared (the LiveRepository pattern) until the RPC snapshot is
/// refreshed and Generated/Rpc.swift names it; preflight 17 holds it to its grant.
struct SetLeagueNotifyCall: RpcCall {
  static let name = "set_league_notify_system"
  static let optionalArgs: [String] = []
  typealias Returns = RpcVoid
  let p_league: UUID
  let p_on: Bool
}

public struct AlbumItem: Sendable, Identifiable, Equatable {
  public let round: LeagueRoom.AlbumRound
  public let url: URL
  public let golfer: String
  public var id: UUID { round.id }
}

@MainActor
@Observable
public final class LeagueRoomModel {
  public let leagueId: UUID
  private let svc: SupabaseService

  public private(set) var loading = false
  public private(set) var loaded = false
  public private(set) var error: String?
  public private(set) var viewer: RoomViewer?

  // MARK: rows
  public private(set) var league: LeagueRoom.League?
  public private(set) var settings: LeagueRoom.Settings?
  public private(set) var season: LeagueRoom.Season?
  public private(set) var members: [LeagueRoom.Member] = []
  public private(set) var squads: [LeagueRoom.Squad] = []
  public private(set) var buyIns: [UUID: LeagueRoom.BuyIn] = [:]
  public private(set) var adjustments: [LeagueRoom.Adjustment] = []
  public private(set) var snapshots: [LeagueRoom.Snapshot] = []
  public private(set) var rankedRounds: [LeagueRoom.RankedRound] = []
  public private(set) var indivStandings: [LeagueRoom.IndivStanding] = []
  public private(set) var squadStandings: [LeagueRoom.SquadStanding] = []
  /// nil = the table is not there yet (deploy skew) — the block hides, like the web.
  public private(set) var forfeits: [LeagueRoom.Forfeit]? = nil
  public private(set) var payouts: [LeagueRoom.Payout] = []
  public private(set) var pulse: [Rpc.league_pulse.Row] = []
  public private(set) var scenarios: SeasonScenarios?
  /// D105: the Cup Final race from the server; nil until the window opens (or on skew).
  public private(set) var cupRace: CupFinalRace?
  public private(set) var cancel: CancelStatus?
  /// Signed avatar URLs by profile id (one batched signing per load, an hour).
  public private(set) var avatarURL: [UUID: URL] = [:]
  public private(set) var album: [AlbumItem]? = nil
  public private(set) var albumLoading = false

  // MARK: derived (computed once per load — `derive()`)
  public private(set) var bylaws = Bylaws()
  public private(set) var clock = RoomClock(phase: .setup, startsOn: nil, endsOn: nil, status: nil, finish: "cup_final")
  public private(set) var teams: [Team] = []
  public private(set) var indRows: [IndRow] = []
  public private(set) var myMonth: MyMonth?
  public private(set) var myIndexDelta: Double?
  public private(set) var priorRank: [UUID: Int] = [:]
  public private(set) var series: [UUID: [Double]] = [:]
  public private(set) var seasonWeeks: Int?
  /// SF-6: set on a fresh load, consumed by the table's first render.
  public var freshStandings = false
  /// D66: a finished season announces itself once per member (`cs_cer_<season>`).
  public var ceremonyDue = false

  public init(leagueId: UUID, svc: SupabaseService = .shared) {
    self.leagueId = leagueId; self.svc = svc
  }

  // MARK: - Convenience

  public var myMember: LeagueRoom.Member? { viewer.flatMap { v in members.first { $0.profile_id == v.id } } }
  public var isPro: Bool { myMember?.isPro ?? false }
  public var solo: Bool { bylaws.solo }
  public var isComplete: Bool { season?.status == "complete" }
  public var mySquad: LeagueRoom.Squad? { myMember.flatMap { m in squads.first { $0.seats(m.id) } } }
  /// The viewer's rung id: the member row when solo, else their squad.
  public var myTeamId: UUID? { solo ? myMember?.id : mySquad?.id }
  public var story: StandingsStory { StandingsMath.story(teams) }
  public var awards: StandingsMath.Awards? { StandingsMath.awards(indRows) }
  public var establishedIndex: Bool { viewer?.indexCurrent != nil }
  public var pool: [LeagueRoom.Member] { members.filter { m in !squads.contains { $0.seats(m.id) } } }
  public var proName: String {
    (members.first { $0.isPro }?.profile?.display_name) ?? (isPro ? viewer?.displayName : nil) ?? "—"
  }
  public func member(_ id: UUID?) -> LeagueRoom.Member? { id.flatMap { i in members.first { $0.id == i } } }
  public func memberByProfile(_ pid: UUID?) -> LeagueRoom.Member? { pid.flatMap { p in members.first { $0.profile_id == p } } }
  /// `memName`.
  public func memName(_ id: UUID?) -> String { member(id)?.name ?? "—" }
  /// `stakeName` (10934): by profile id.
  public func stakeName(_ pid: UUID?) -> String { memberByProfile(pid)?.profile?.display_name ?? "A golfer" }
  public func squadName(_ memberId: UUID) -> String { squads.first { $0.seats(memberId) }?.name ?? "" }
  public func indRow(_ memberId: UUID) -> IndRow? { indRows.first { $0.mid == memberId } }
  /// The ledger lines for one squad (reasons included), sentinel excluded.
  public func ledger(squad: UUID) -> [LeagueRoom.Adjustment] { adjustments.filter { $0.squad_id == squad && !$0.isSentinel } }
  public var partialMonth: Bool { pulse.first?.partial ?? false }

  /// `players` in the pot (6988): the real roster, never below one.
  public var potPlayers: Int { max(members.count, 1) }
  public var potTotal: Int { bylaws.stake * potPlayers }
  public var paidCount: Int { members.filter { buyIns[$0.id]?.paid == true }.count }
  public var collectedDollars: Double {
    members.reduce(0) { acc, m in
      guard let b = buyIns[m.id], b.paid else { return acc }
      return acc + (b.amount_cents.map { Double($0) / 100 } ?? Double(bylaws.stake))
    }
  }
  /// D106: roster members without a paid buy-in — "K still owe".
  public var stillOweCount: Int { members.filter { buyIns[$0.id]?.paid != true }.count }
  /// D106: `collectedDollars` as `fmt$` text ("$450" / "$75.50").
  public var collectedText: String {
    let c = collectedDollars
    return c == c.rounded() ? "$\(Int(c))" : String(format: "$%.2f", c)
  }
  /// D106: true when the cash on hand is short of what the roster owes.
  public var collectedShort: Bool { collectedDollars < Double(potTotal) }

  public var settlement: PotMath.Settlement? {
    guard let season else { return nil }
    return PotMath.settlement(season: season, members: members, squads: squads, solo: solo, stakeDollars: bylaws.stake,
                              payout: bylaws.payout, payouts: payouts, myProfileId: viewer?.id,
                              owing: members.filter { buyIns[$0.id]?.paid != true }.map(\.name))
  }

  public static func ceremonyKey(_ seasonId: UUID) -> String { "cs_cer_\(seasonId.uuidString.lowercased())" }
  public func markCeremonySeen() {
    guard let s = season else { return }
    UserDefaults.standard.set(true, forKey: Self.ceremonyKey(s.id))
    ceremonyDue = false
  }

  // MARK: - Load

  public func load(viewer: RoomViewer) async {
    guard !loading else { return }
    loading = true
    defer { loading = false }
    self.viewer = viewer
    error = nil
    let db = svc.client
    do {
      // the league, its bylaws, its latest season — three independent reads
      async let leagueQ: [LeagueRoom.League] = loadLeagueRows()
      async let settingsQ: [LeagueRoom.Settings] = db.from("league_settings")
        .select("league_id, preset, handicap_allowance, verification, counting_cap, participation_floor, floor_penalty, season_format, buyin_cents, season_months, locked_at, structure, draft_type, payout_champ, payout_runnerup, payout_king, finish")
        .eq("league_id", value: leagueId).execute().value
      let (leagues, settingsRows) = try await (leagueQ, settingsQ)
      guard let lg = leagues.first else { throw RpcError(name: "leagues", underlying: "No league with that id — it may have been deleted.", droppedArgs: []) }
      league = lg
      settings = settingsRows.first
      season = try await loadSeason()
      members = try await loadMembers()

      if let s = season {
        async let sq: [LeagueRoom.Squad] = db.from("squads").select("id, name, color, captain_member_id, squad_members(member_id)")
          .eq("season_id", value: s.id).order("name").execute().value
        async let bi: [LeagueRoom.BuyIn] = db.from("buy_ins").select("member_id, paid, amount_cents").eq("season_id", value: s.id).execute().value
        async let st: [LeagueRoom.SquadStanding] = db.from("v_squad_standings").select("squad_id, points").eq("season_id", value: s.id).execute().value
        async let sn: [LeagueRoom.Snapshot] = db.from("standings_snapshots").select("week_no, standings").eq("season_id", value: s.id).order("week_no").execute().value
        async let rr: [LeagueRoom.RankedRound] = db.from("v_rounds_ranked")
          .select("member_id, round_id, pvi, points, month_rank, floor_credit, played_on, index_at_post, holes_played")
          .eq("season_id", value: s.id).execute().value
        async let iv: [LeagueRoom.IndivStanding] = db.from("v_individual_standings").select("member_id, points, rounds_posted").eq("season_id", value: s.id).execute().value
        async let adj: [LeagueRoom.Adjustment] = db.from("season_adjustments").select("id, squad_id, member_id, month, kind, points, reason, created_by")
          .eq("season_id", value: s.id).order("created_at").execute().value
        async let pay: [LeagueRoom.Payout] = db.from("season_payouts").select("profile_id, cents, reason").eq("season_id", value: s.id).execute().value
        squads = try await sq
        buyIns = Dictionary((try await bi).map { ($0.member_id, $0) }, uniquingKeysWith: { a, _ in a })
        squadStandings = try await st
        snapshots = try await sn
        rankedRounds = try await rr
        indivStandings = try await iv
        adjustments = (try? await adj) ?? []
        payouts = (try? await pay) ?? []
        let d0 = s.starts_on, d1 = s.ends_on
        seasonWeeks = max(2, Int((Double((CSDate.days(from: d0, to: d1) ?? 0) + 1) / 7).rounded()))
      } else {
        squads = []; buyIns = [:]; squadStandings = []; snapshots = []; rankedRounds = []; indivStandings = []; adjustments = []; payouts = []
        seasonWeeks = nil
      }
      derive()
      loaded = true
      freshStandings = season != nil
      if let s = season, s.status == "complete" {
        ceremonyDue = !UserDefaults.standard.bool(forKey: Self.ceremonyKey(s.id))
      } else { ceremonyDue = false }
    } catch {
      self.error = AuthRules.human(error, fallback: "Could not load the room.")
      return
    }
    // the fire-and-forget layer: pulse, scenarios, the cancel banner, the forfeit ledger, avatars
    await withTaskGroup(of: Void.self) { g in
      g.addTask { await self.loadPulse() }
      g.addTask { await self.loadScenarios() }
      g.addTask { await self.loadCupRace() }
      g.addTask { await self.refreshCancelStatus() }
      g.addTask { await self.loadForfeits() }
      g.addTask { await self.signAvatars() }
    }
  }

  public func refresh() async {
    guard let v = viewer else { return }
    await load(viewer: v)
  }

  /// Previews and tests: the rows without the network, derived exactly like a load.
  public func seed(viewer: RoomViewer, league: LeagueRoom.League, settings: LeagueRoom.Settings?, season: LeagueRoom.Season?,
                   members: [LeagueRoom.Member], squads: [LeagueRoom.Squad] = [], squadStandings: [LeagueRoom.SquadStanding] = [],
                   indiv: [LeagueRoom.IndivStanding] = [], ranked: [LeagueRoom.RankedRound] = [], snapshots: [LeagueRoom.Snapshot] = [],
                   adjustments: [LeagueRoom.Adjustment] = [], buyIns: [LeagueRoom.BuyIn] = [], payouts: [LeagueRoom.Payout] = [],
                   scenarios: SeasonScenarios? = nil, forfeits: [LeagueRoom.Forfeit]? = nil, pulse: [Rpc.league_pulse.Row] = [],
                   today: String? = nil) {
    self.viewer = viewer; self.league = league; self.settings = settings; self.season = season
    self.members = members; self.squads = squads; self.squadStandings = squadStandings; self.indivStandings = indiv
    self.rankedRounds = ranked; self.snapshots = snapshots; self.adjustments = adjustments
    self.buyIns = Dictionary(buyIns.map { ($0.member_id, $0) }, uniquingKeysWith: { a, _ in a })
    self.payouts = payouts; self.scenarios = scenarios; self.forfeits = forfeits; self.pulse = pulse
    self.todayOverride = today
    if let s = season { seasonWeeks = max(2, Int((Double((CSDate.days(from: s.starts_on, to: s.ends_on) ?? 0) + 1) / 7).rounded())) }
    derive()
    loaded = true
    freshStandings = season != nil
  }
  private var todayOverride: String?

  /// The league row. `notify_system` arrived in 20260827210000; ANY error drops
  /// back to the legacy column list (deploy skew — never sniff the message).
  private func loadLeagueRows() async throws -> [LeagueRoom.League] {
    let db = svc.client
    do {
      return try await db.from("leagues").select("id, name, code, phase, commissioner_id, notify_system").eq("id", value: leagueId).execute().value
    } catch {
      return try await db.from("leagues").select("id, name, code, phase, commissioner_id").eq("id", value: leagueId).execute().value
    }
  }

  private func loadSeason() async throws -> LeagueRoom.Season? {
    let db = svc.client
    let d66 = "id, number, starts_on, ends_on, status, champion_squad_id, champion_member_id, runnerup_squad_id, runnerup_member_id, points_king_member_id, champion_score, runnerup_score, tiebreak_rung"
    let cols = d66 + ", pot_cents, collected_cents"   // D106
    do {
      let rows: [LeagueRoom.Season] = try await db.from("seasons").select(cols).eq("league_id", value: leagueId)
        .order("number", ascending: false).limit(1).execute().value
      return rows.first
    } catch {
      // D106 skew: a database without the two pot columns still has the D66 result columns
      if let rows: [LeagueRoom.Season] = try? await db.from("seasons").select(d66).eq("league_id", value: leagueId)
        .order("number", ascending: false).limit(1).execute().value { return rows.first }
      // D66 skew: ANY error drops back to the legacy shape (never sniff the message)
      let rows: [LeagueRoom.Season] = try await db.from("seasons").select("id, number, starts_on, ends_on, status").eq("league_id", value: leagueId)
        .order("number", ascending: false).limit(1).execute().value
      return rows.first
    }
  }

  private func loadMembers() async throws -> [LeagueRoom.Member] {
    let db = svc.client
    do {
      return try await db.from("league_members")
        .select("id, role, profile_id, joined_at, marker, profile:profiles(display_name, marker, index_current, handle, photo_path)")
        .eq("league_id", value: leagueId).execute().value
    } catch {
      return try await db.from("league_members")
        .select("id, role, profile_id, joined_at, profile:profiles(display_name, marker, index_current, handle)")
        .eq("league_id", value: leagueId).execute().value
    }
  }

  private func derive() {
    bylaws = Bylaws.from(settings)
    let phase: RoomPhase = league?.phase == "setup" ? .setup : league?.phase == "draft" ? .draft : .season
    clock = RoomClock(phase: phase, startsOn: season?.starts_on, endsOn: season?.ends_on, status: season?.status, finish: bylaws.finish,
                      today: todayOverride ?? CSDate.today())
    let capN = bylaws.capN
    let myId = myMember?.id
    indRows = StandingsMath.indRows(indiv: indivStandings, ranked: rankedRounds, members: members, squads: squads, myMemberId: myId, capN: capN)
    let mine = rankedRounds.filter { $0.member_id == myId }
    myMonth = season == nil ? nil : StandingsMath.myMonth(mine: mine, capN: capN, monthKey: LeagueDates.monthKey(clock.today))
    myIndexDelta = StandingsMath.myIndexDelta(mine: mine, profileIndex: viewer?.indexCurrent)
    if season != nil, !squads.isEmpty {
      teams = StandingsMath.squadTeams(squads: squads, standings: squadStandings, captainName: { [self] in memName($0) })
    } else if season != nil, !indRows.isEmpty {
      teams = StandingsMath.soloTeams(indRows, marker: { [self] id in member(id)?.mk })
    } else { teams = [] }
    let solo = teams.first?.solo ?? false
    priorRank = StandingsMath.priorRank(snapshots: snapshots, solo: solo)
    series = StandingsMath.series(teams: teams, snapshots: snapshots, weeks: max(2, seasonWeeks ?? 18), solo: solo)
  }

  // MARK: - The fire-and-forget layer

  private func loadPulse() async {
    pulse = (try? await svc.call(Rpc.league_pulse(p_league: leagueId))) ?? []
  }

  private func loadCupRace() async {
    guard let s = season, s.status == "cup_final" || s.status == "complete" else { cupRace = nil; return }
    let r = await CupFinalRace.fetch(season: s.id, svc: svc)
    cupRace = (r?.status == "pending") ? nil : r
  }
  /// The seed a standings row carries once the Final's seeds are locked (nil otherwise).
  public func seedOf(_ teamId: UUID) -> Int? { cupRace?.seed(for: teamId) }
  /// Tests and previews: the race without the network.
  public func seedCupRace(_ r: CupFinalRace?) { cupRace = r }

  private func loadScenarios() async {
    guard let s = season else { scenarios = nil; return }
    if let v = try? await svc.call(Rpc.season_scenarios(p_season: s.id)) { scenarios = SeasonScenarios.decode(v) } else { scenarios = nil }
  }

  public func refreshCancelStatus() async {
    if let v = try? await svc.call(Rpc.league_cancel_status(p_league: leagueId)) { cancel = CancelStatus.decode(v) }
    // skew-safe: a missing RPC leaves whatever was there (no request surface until deployed)
  }

  public func loadForfeits() async {
    do {
      let rows: [LeagueRoom.Forfeit] = try await svc.client.from("forfeits")
        .select("id, name, terms, kind, party_a, party_b, hangs_on, status, winner, settled_note, created_by")
        .eq("league_id", value: leagueId).order("created_at", ascending: false).limit(60).execute().value
      forfeits = rows
    } catch { forfeits = nil }
  }

  private func signAvatars() async {
    let wp = members.filter { $0.profile?.photo_path != nil }
    guard !wp.isEmpty else { avatarURL = [:]; return }
    guard let signed = try? await svc.client.storage.from("media").createSignedURLs(paths: wp.map { $0.profile!.photo_path! }, expiresIn: 3600) else { return }
    var out: [UUID: URL] = [:]
    for s in signed {
      if case .success(let path, let url) = s, let m = wp.first(where: { $0.profile?.photo_path == path }) { out[m.profile_id] = url }
    }
    avatarURL = out
  }

  /// `renderAlbum` (16456–16505): the league's round photos, newest first.
  public func loadAlbum() async {
    guard !albumLoading else { return }
    albumLoading = true
    defer { albumLoading = false }
    let pids = members.map(\.profile_id)
    guard !pids.isEmpty else { album = []; return }
    do {
      let rows: [LeagueRoom.AlbumRound] = try await svc.client.from("rounds")
        .select("id, profile_id, gross, differential, index_at_post, played_on, course_label, holes_played, photo_path")
        .in("profile_id", values: pids).not("photo_path", operator: .is, value: "null")
        .order("played_on", ascending: false).limit(60).execute().value
      guard !rows.isEmpty else { album = []; return }
      let signed = try await svc.client.storage.from("media").createSignedURLs(paths: rows.map(\.photo_path), expiresIn: 3600)
      var url: [String: URL] = [:]
      for s in signed { if case .success(let path, let u) = s { url[path] = u } }
      album = rows.compactMap { r in
        guard let u = url[r.photo_path] else { return nil }
        return AlbumItem(round: r, url: u, golfer: memberByProfile(r.profile_id)?.profile?.display_name ?? "A golfer")
      }
    } catch { album = [] }
  }

  /// The legacy email invites still waiting (`invites`, readable by the Pro only — 16896).
  public func pendingInviteEmails() async -> [String] {
    struct Row: Decodable, Sendable { let email: String; let status: String }
    guard isPro else { return [] }
    let rows: [Row] = (try? await svc.client.from("invites").select("email, status").eq("league_id", value: leagueId).order("created_at").execute().value) ?? []
    return rows.filter { $0.status == "sent" }.map(\.email)
  }

  // MARK: - The Pro's tools (definer RPCs; the server re-validates every one)

  public func markBuyIn(member: UUID, paid: Bool) async throws {
    guard let s = season else { throw RpcError(name: "mark_buy_in", underlying: "Buy-ins open once the bylaws lock", droppedArgs: []) }
    _ = try await svc.call(Rpc.mark_buy_in(p_season: s.id, p_member: member, p_paid: paid))
    buyIns[member] = LeagueRoom.BuyIn(member_id: member, paid: paid, amount_cents: bylaws.stake * 100)
  }

  public func setFinish(_ next: String) async throws {
    _ = try await svc.call(Rpc.set_league_finish(p_league: leagueId, p_finish: next))
    let rows: [LeagueRoom.Settings] = try await svc.client.from("league_settings")
      .select("league_id, preset, handicap_allowance, verification, counting_cap, participation_floor, floor_penalty, season_format, buyin_cents, season_months, locked_at, structure, draft_type, payout_champ, payout_runnerup, payout_king, finish")
      .eq("league_id", value: leagueId).execute().value
    settings = rows.first
    derive()
  }

  public func setMemberIndex(member: UUID, index: Double) async throws {
    _ = try await svc.call(Rpc.set_member_index(p_member: member, p_index: index))
    await refresh()
  }

  public func setMemberBye(member: UUID, month: String) async throws {
    _ = try await svc.call(Rpc.set_member_bye(p_member: member, p_month: month, p_on: true))
  }

  public func removeMember(_ member: UUID) async throws {
    _ = try await svc.call(Rpc.remove_member(p_member: member))
    await refresh()
  }

  public func transferPro(to member: UUID) async throws {
    _ = try await svc.call(Rpc.transfer_pro(p_member: member))
    await refresh()
  }

  /// The Pro's "League notices" switch (push wave 7): `system` board posts —
  /// floors, closes, season notices — reach the crew's phones only while on.
  /// The server re-checks is_commissioner; the row is re-read so the pane
  /// shows what the database holds, not what was asked for.
  public func setNotifySystem(_ on: Bool) async throws {
    _ = try await svc.call(SetLeagueNotifyCall(p_league: leagueId, p_on: on))
    if let lg = try? await loadLeagueRows().first { league = lg }
  }

  /// nil = back to the profile marker (the server takes '' as null).
  public func setLeagueMarker(_ key: String?) async throws {
    _ = try await svc.call(Rpc.set_league_marker(p_league: leagueId, p_marker: key ?? ""))
    members = try await loadMembers()
    derive()
  }

  // MARK: forfeits (D64)

  public func createForfeit(name: String, terms: String, kind: String, other: UUID?, hangs: String?) async throws {
    _ = try await svc.call(Rpc.create_forfeit(p_league: leagueId, p_name: name, p_terms: terms, p_kind: kind, p_other: other, p_hangs: hangs))
    await loadForfeits()
  }
  public func settleForfeit(_ id: UUID, winner: UUID?, note: String?) async throws {
    _ = try await svc.call(Rpc.settle_forfeit(p_id: id, p_winner: winner, p_note: note))
    await loadForfeits()
  }
  public func scrapForfeit(_ id: UUID) async throws {
    _ = try await svc.call(Rpc.scrap_forfeit(p_id: id))
    await loadForfeits()
  }

  // MARK: cancellation (D71) and deletion

  /// 'done' | 'open'
  public func requestCancel() async throws -> String {
    let r = try await svc.call(Rpc.request_league_cancel(p_league: leagueId))
    if r != "done" { await refreshCancelStatus() }
    return r
  }
  /// 'done' | 'declined' | 'pending'
  public func voteCancel(approve: Bool) async throws -> String {
    let r = try await svc.call(Rpc.vote_league_cancel(p_league: leagueId, p_approve: approve))
    if r == "done" || r == "declined" { cancel = nil } else { await refreshCancelStatus() }
    return r
  }
  public func withdrawCancel() async throws {
    _ = try await svc.call(Rpc.withdraw_league_cancel(p_league: leagueId))
    cancel = nil
  }
  /// How many OTHER golfers are in — the typed-name gate keys on it (15648).
  public func othersCount() async -> Int {
    guard let v = viewer else { return 1 }
    let n = try? await svc.client.from("league_members").select("id", head: true, count: .exact)
      .eq("league_id", value: leagueId).neq("profile_id", value: v.id).execute().count
    return n ?? 1
  }
  public func deleteLeague() async throws {
    _ = try await svc.call(Rpc.delete_league(p_league: leagueId))
  }

  // MARK: share the season (D57)

  public func seasonShareURL() async throws -> URL {
    guard let s = season else { throw RpcError(name: "create_share", underlying: "The season page opens at first tee", droppedArgs: []) }
    let token = try await svc.call(Rpc.create_share(p_kind: "recap", p_ref: s.id))
    CSGrowth.log(.artifactShared, kind: "recap", token: token.uuidString.lowercased(), league: league?.id)
    return URL(string: "\(CSConfig.webOrigin.absoluteString)/?share=\(token.uuidString.lowercased())")!
  }
  public func revokeSeasonShare() async throws {
    guard let s = season else { return }
    let token = try await svc.call(Rpc.create_share(p_kind: "recap", p_ref: s.id))
    _ = try await svc.call(Rpc.revoke_share(p_token: token))
  }

  /// `shareInvite` (13911–13925).
  public var inviteURL: URL? {
    guard let code = league?.code, let enc = code.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
    return URL(string: "\(CSConfig.webOrigin.absoluteString)/?join=\(enc)")
  }
  public var inviteText: String { "You're invited to \(league?.name ?? "the league") on Cup Season" }
}
