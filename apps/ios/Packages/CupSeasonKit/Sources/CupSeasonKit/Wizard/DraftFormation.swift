// Cup Season — squad formation and draft night (index.html):
//   renderFormation  14607–14700   blind draw (randomize_squads) · Pro assign (assign_player)
//                                  · Start the season (start_season) — the two LIVE engines
//   renderDraft      5427–5548     the snake board's copy and clock (the web shows it only for
//                                  its demo; the server's start_draft / make_pick / undo_pick are
//                                  the same board with a database under it — audit 02 §4.2)
//   subscribeLeague  14705–14722   a posts INSERT during draft reloads the room — the draw
//                                  reveal and every pick are board posts
// The server validates everything (≥4 · nobody in the pool · no empty squad);
// `DraftCopy.startBlockers` only says the same thing BEFORE the tap.

import Foundation
import Supabase

// MARK: - Rows

/// `drafts` (baseline:1000).
public struct DraftRow: Decodable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let season_id: UUID
  public let type: String
  public let status: String
  public let rounds_count: Int
  public let order_squads: [UUID]
  public let current_pick: Int
  public init(id: UUID, season_id: UUID, type: String, status: String, rounds_count: Int, order_squads: [UUID], current_pick: Int) {
    self.id = id; self.season_id = season_id; self.type = type; self.status = status; self.rounds_count = rounds_count
    self.order_squads = order_squads; self.current_pick = current_pick
  }
  public var isLive: Bool { status == "live" }
  public var isComplete: Bool { status == "complete" }
}

/// `draft_picks` (baseline:984).
public struct DraftPickRow: Decodable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let pick_number: Int
  public let round_number: Int
  public let squad_id: UUID
  public let member_id: UUID
  public let via_override: Bool
  public init(id: UUID, pick_number: Int, round_number: Int, squad_id: UUID, member_id: UUID, via_override: Bool = false) {
    self.id = id; self.pick_number = pick_number; self.round_number = round_number; self.squad_id = squad_id
    self.member_id = member_id; self.via_override = via_override
  }
}

// MARK: - The snake (make_pick's arithmetic, verbatim)

public enum DraftSnake {
  /// The squad on the clock for pick `n` (0-based) over `order` — even rounds reverse.
  public static func squadOnClock(pick n: Int, order: [UUID]) -> UUID? {
    let nSq = order.count
    guard nSq > 0 else { return nil }
    let rd = n / nSq + 1
    var idx = n % nSq
    if rd % 2 == 0 { idx = nSq - 1 - idx }
    return order[idx]
  }
  /// "R2 · PICK 3/4"
  public static func label(pick n: Int, squads nSq: Int) -> (round: Int, pick: Int) {
    guard nSq > 0 else { return (1, 1) }
    return (n / nSq + 1, n % nSq + 1)
  }
  public static func total(squads nSq: Int, rounds: Int) -> Int { nSq * rounds }
  public static func done(_ d: DraftRow) -> Bool { d.isComplete || d.current_pick >= total(squads: d.order_squads.count, rounds: d.rounds_count) }
}

// MARK: - Copy

public enum DraftCopy {
  // eyebrows (14611–14612, 5429–5431)
  public static func eyebrow(_ draftType: String) -> String {
    switch draftType {
    case "assign": "Form squads · Pro assign"
    case "live": "Live draft · pick clock"
    case "snake": "Draft night · snake"
    default: "Form squads · blind draw"
    }
  }
  // the clock (14618–14625)
  public static let formK = "Form squads"
  public static func formN(pool: Int) -> String { pool > 0 ? "\(pool) in the pool" : "Everyone has a squad" }
  public static func formM(_ draftType: String) -> String {
    draftType == "assign" ? "Tap a player, then tap a squad" : "THE HAT SHUFFLES SERVER-SIDE — NOBODY RIGS THE DRAW"
  }
  public static let draw = "Draw squads"
  public static let start = "Start the season →"
  public static let hatSpoken = "The hat has spoken"
  public static let drawFailed = "Draw failed."
  public static let assignFailed = "Assign failed."
  public static let seasonLive = "The season is live — post a round"
  public static let poolEyebrow = "The pool"
  public static let poolEmpty = "Pool is empty. Players appear here as they join with the league code."
  public static let squadEmpty = "Empty"
  public static func players(_ k: Int) -> String { "\(k) PLAYER\(k == 1 ? "" : "S")" }
  /// `switchView('draft')` in setup (4141).
  public static let setupBounce = "Lock settings first: the draft opens after setup"
  public static let memberReadOnly = "The Pro forms the squads — you'll see them here the moment they're set."

  // the snake board (5440–5548)
  public static let boardWaitingK = "Squad formation"
  public static let boardWaitingN = "Waiting on the players"
  public static let boardWaitingM = "THE BOARD SEEDS FROM YOUR ROSTER ONCE INVITES LAND"
  public static let onClockK = "On the clock"
  public static let doneK = "Squads are set"
  public static let doneN = "Good luck, everybody"
  public static let doneM = "Rosters locked · season opens W1"
  public static let lockMine = "You are on the clock: make your pick"
  public static func lockTheirs(_ captain: String) -> String { "\(captain) is picking: only their account can select" }
  public static let lockIdle = "On the clock — only the picking captain can select"
  public static func notYourPick(_ captain: String) -> String { "Not your pick: \(captain) is on the clock" }
  public static func proPicked(_ player: String, for captain: String) -> String { "Pro picked \(player) for \(captain), logged" }
  public static func drafted(_ captain: String, _ player: String, _ idx: String) -> String { "\(captain) drafts \(player) (\(idx))" }
  public static let poolDone = "Pool's empty. Every player has a squad."
  public static let draftTag = "DRAFT"
  public static let lockedTag = "LOCKED"
  public static let proEyebrow = "Pro"
  public static let randomizeOrder = "Randomize order"
  public static let pickForCaptain = "Pick for captain"
  public static let proNote = "Every pick and override is written to the league log."
  public static let orderLocked = "Order locks once the first pick is in"
  public static let orderRandomized = "Order randomized and posted to the board"
  public static let pickForToast = "You already can: as the Pro, any pool player is tappable on any clock"
  public static let undoPick = "Undo last pick"
  public static let captTag = "CAPT"
  public static func slot(_ r: Int) -> String { "R\(r) pick" }
  public static func clockM(round: Int, pick: Int, of: Int, squad: String) -> String { "R\(round) · PICK \(pick)/\(of) · \(squad.uppercased())" }
  public static func idx(_ v: Double?) -> String { "\(CSCopy.index(v)) IDX" }

  /// What `start_season` will say, said first (audit 02 §7.19). nil = clear to start.
  public static func startBlocker(members: Int, pool: Int, squads: [LeagueRoom.Squad], solo: Bool) -> String? {
    guard !solo else { return nil }
    if members < 4 { return "Minimum four to tee off — \(members) in so far. Share the invite link." }
    if pool > 0 { return "\(pool) golfer(s) still in the pool — everyone needs a squad before the first tee" }
    if let empty = squads.first(where: { $0.squad_members.isEmpty }) { return "\(empty.name) is empty — draw again or assign somebody before the season starts" }
    return nil
  }
}

// MARK: - Service

public struct DraftService: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  /// Blind draw (D54, D58): one tap; the reveal is a board post.
  public func draw(season: UUID) async throws { _ = try await svc.call(Rpc.randomize_squads(p_season: season)) }
  /// Pro assign (D75): a player onto a squad; the server logs the actor.
  public func assign(squad: UUID, member: UUID) async throws { _ = try await svc.call(Rpc.assign_player(p_squad: squad, p_member: member)) }
  /// The server validates ≥4 · nobody loose · no empty squad; its message is the copy.
  public func startSeason(season: UUID) async throws { _ = try await svc.call(Rpc.start_season(p_season: season)) }

  // the snake board
  public func startDraft(season: UUID, shuffle: Bool = true) async throws -> UUID { try await svc.call(Rpc.start_draft(p_season: season, p_shuffle: shuffle)) }
  public func makePick(draft: UUID, member: UUID) async throws { _ = try await svc.call(Rpc.make_pick(p_draft: draft, p_member: member)) }
  public func undoPick(draft: UUID) async throws { _ = try await svc.call(Rpc.undo_pick(p_draft: draft)) }

  public func draft(season: UUID) async throws -> DraftRow? {
    let rows: [DraftRow] = try await svc.client.from("drafts").select("id, season_id, type, status, rounds_count, order_squads, current_pick")
      .eq("season_id", value: season).limit(1).execute().value
    return rows.first
  }
  public func picks(draft: UUID) async throws -> [DraftPickRow] {
    try await svc.client.from("draft_picks").select("id, pick_number, round_number, squad_id, member_id, via_override")
      .eq("draft_id", value: draft).order("pick_number").execute().value
  }
}

// MARK: - Realtime (the dedicated client — CLAUDE.md landmine)

/// ONE channel per draft night, on `SupabaseService.realtime`, never `client`:
/// a `posts` INSERT for the league (the draw reveal, every pick, ROSTERS
/// LOCKED) and any change on `drafts` / `draft_picks` → `onChange`, coalesced
/// over 250 ms. Subscribe status is a breadcrumb; silence cost a full session.
@MainActor
public final class DraftRealtime {
  public private(set) var status: String = "idle"
  public var onChange: (@MainActor () -> Void)?
  public var log: @Sendable (String) -> Void = { print("[realtime] \($0)") }

  private let svc: SupabaseService
  private var channel: RealtimeChannelV2?
  private var tokens: [RealtimeSubscription] = []
  private var debounce: Task<Void, Never>?

  public init(svc: SupabaseService = .shared) { self.svc = svc }

  public func start(leagueId: UUID, seasonId: UUID) async {
    await stop()
    let topic = "draft-" + seasonId.uuidString
    let ch = svc.realtime.realtimeV2.channel(topic)
    channel = ch
    let log = self.log
    tokens.append(ch.onPostgresChange(InsertAction.self, schema: "public", table: "posts",
                                      filter: .eq("league_id", value: leagueId.uuidString)) { [weak self] _ in
      Task { @MainActor [weak self] in self?.nudge() }
    })
    tokens.append(ch.onPostgresChange(AnyAction.self, schema: "public", table: "drafts",
                                      filter: .eq("season_id", value: seasonId.uuidString)) { [weak self] _ in
      Task { @MainActor [weak self] in self?.nudge() }
    })
    tokens.append(ch.onPostgresChange(AnyAction.self, schema: "public", table: "draft_picks") { [weak self] _ in
      Task { @MainActor [weak self] in self?.nudge() }
    })
    tokens.append(ch.onStatusChange { [weak self] s in
      let name: String = switch s {
      case .subscribed: "SUBSCRIBED"
      case .subscribing: "SUBSCRIBING"
      case .unsubscribing: "UNSUBSCRIBING"
      case .unsubscribed: "CLOSED"
      }
      log("\(topic) \(name)")
      Task { @MainActor [weak self] in self?.status = name }
    })
    do { try await ch.subscribeWithError() } catch {
      log("\(topic) CHANNEL_ERROR — \(error.localizedDescription)")
      status = "CHANNEL_ERROR"
    }
  }

  private func nudge() {
    debounce?.cancel()
    debounce = Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(250))
      guard !Task.isCancelled else { return }
      self?.onChange?()
    }
  }

  public func stop() async {
    debounce?.cancel()
    tokens.forEach { $0.cancel() }
    tokens.removeAll()
    if let ch = channel {
      await svc.realtime.realtimeV2.removeChannel(ch)
      channel = nil
      status = "CLOSED"
    }
  }
}
