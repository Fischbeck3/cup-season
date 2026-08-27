// Cup Season — the Ryder and the Major, as shapes (spec/ryder-v1.md §R5,
// the_major.sql; audit 04 §4.3). One spine: `events` + `event_teams` +
// `event_players` + `event_sessions` + `event_duels`, plus the Major's frozen
// `event_major_cards`. The room is `window.CS_EVENT` (loadEvent 15833–15905).
//
// Calendar dates are Strings (CSDate). Money is the web's numeric dollars —
// `events.buy_in` is `numeric`, never cents. Nothing here is authoritative:
// the engine resolves duels and settles the jug; the phone renders.

import Foundation

/// `events` — the container both kinds share.
public struct EventRow: Decodable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let name: String
  public let created_by: UUID?
  public let league_id: UUID?
  public let kind: String?
  public let status: String
  public let starts_on: String?
  public let session_count: Int?
  public let session_weeks: Int?
  public let draw_rule: String?
  public let winner_team_id: UUID?
  public let buy_in: Double?
  public let pot_split: String?
  public let lineage_id: UUID?
  public let tz: String?

  public init(id: UUID, name: String, created_by: UUID?, league_id: UUID? = nil, kind: String? = "ryder", status: String,
              starts_on: String? = nil, session_count: Int? = nil, session_weeks: Int? = nil, draw_rule: String? = nil,
              winner_team_id: UUID? = nil, buy_in: Double? = nil, pot_split: String? = nil, lineage_id: UUID? = nil, tz: String? = nil) {
    self.id = id; self.name = name; self.created_by = created_by; self.league_id = league_id; self.kind = kind; self.status = status
    self.starts_on = starts_on; self.session_count = session_count; self.session_weeks = session_weeks; self.draw_rule = draw_rule
    self.winner_team_id = winner_team_id; self.buy_in = buy_in; self.pot_split = pot_split; self.lineage_id = lineage_id; self.tz = tz
  }

  public var isMajor: Bool { kind == "major" }
  public var isComplete: Bool { status == "complete" }
  public var isSetup: Bool { status == "setup" }
  public var isLive: Bool { status == "live" }
}

/// `event_teams` — slot 0 is Team A, slot 1 Team B; `color` indexes the squad palette.
public struct EventTeam: Decodable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let slot: Int
  public let name: String
  public let color: Int?
  public let captain_player_id: UUID?
  public init(id: UUID, slot: Int, name: String, color: Int? = nil, captain_player_id: UUID? = nil) {
    self.id = id; self.slot = slot; self.name = name; self.color = color; self.captain_player_id = captain_player_id
  }
  /// `SQHEX[c] ?? SQHEX[0]` — the palette index, 0…3.
  public var colorIndex: Int { max(0, color ?? 0) % 4 }
}

/// `event_players` joined to `profiles(display_name, marker)` — the web's
/// flattened player (15886–15889): a missing name prints '—', a missing
/// marker is the Saguaro.
public struct EventPlayer: Sendable, Equatable, Identifiable {
  public let id: UUID
  public let profileId: UUID?
  public let teamId: UUID?
  public let role: String
  public let seed: Int
  public let benchedCount: Int
  public let notifyTarget: Bool
  public let exhibition: Bool
  public let name: String
  public let marker: String

  public init(id: UUID, profileId: UUID?, teamId: UUID?, role: String = "player", seed: Int = 0, benchedCount: Int = 0,
              notifyTarget: Bool = false, exhibition: Bool = false, name: String, marker: String = "saguaro") {
    self.id = id; self.profileId = profileId; self.teamId = teamId; self.role = role; self.seed = seed; self.benchedCount = benchedCount
    self.notifyTarget = notifyTarget; self.exhibition = exhibition; self.name = name; self.marker = marker
  }

  /// The placeholder the web renders for an unknown duel side (`pById`).
  public static let unknown = EventPlayer(id: UUID(), profileId: nil, teamId: nil, name: "—")
  public var isCaptain: Bool { role == "captain" }
}

/// `event_sessions` — Sun→Sat calendar windows (§R2.2).
public struct EventSession: Decodable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let session_no: Int
  public let opens_on: String
  public let closes_on: String
  public let status: String
  public init(id: UUID, session_no: Int, opens_on: String, closes_on: String, status: String) {
    self.id = id; self.session_no = session_no; self.opens_on = opens_on; self.closes_on = closes_on; self.status = status
  }
  public var isOpen: Bool { status == "open" }
  public var isClosed: Bool { status == "closed" }
}

/// `event_duels` — the atom. `a_round`/`b_round` are the §16 receipts.
public struct EventDuel: Decodable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let session_id: UUID
  public let a_player: UUID
  public let b_player: UUID
  public let a_round: UUID?
  public let b_round: UUID?
  public let a_pvi: Double?
  public let b_pvi: Double?
  public let result: String
  public init(id: UUID, session_id: UUID, a_player: UUID, b_player: UUID, a_round: UUID? = nil, b_round: UUID? = nil,
              a_pvi: Double? = nil, b_pvi: Double? = nil, result: String = "pending") {
    self.id = id; self.session_id = session_id; self.a_player = a_player; self.b_player = b_player; self.a_round = a_round
    self.b_round = b_round; self.a_pvi = a_pvi; self.b_pvi = b_pvi; self.result = result
  }
  public var isPending: Bool { result == "pending" }
}

/// The number to beat — one open duel's live best per side (`event_session_targets`).
public struct EventTarget: Sendable, Equatable {
  public let a: Double?
  public let b: Double?
  public init(a: Double?, b: Double?) { self.a = a; self.b = b }
}

/// An engine post on the event board (`posts` where `event_id`, 15878–15882).
public struct EventPost: Decodable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let kind: String?
  public let body: String?
  public let created_at: Date?
  public init(id: UUID, kind: String?, body: String?, created_at: Date?) {
    self.id = id; self.kind = kind; self.body = body; self.created_at = created_at
  }
}

/// `event_major_cards` — frozen at settle; `rank` is placement among contenders.
public struct MajorCard: Decodable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let player_id: UUID
  public let round_id: UUID?
  public let gross: Int?
  public let pvi: Double?
  public let cards: Int?
  public let no_card: Bool?
  public let exhibition: Bool?
  public let rank: Int?
  public let prize: Double?
  public init(id: UUID, player_id: UUID, round_id: UUID? = nil, gross: Int? = nil, pvi: Double? = nil, cards: Int? = nil,
              no_card: Bool? = nil, exhibition: Bool? = nil, rank: Int? = nil, prize: Double? = nil) {
    self.id = id; self.player_id = player_id; self.round_id = round_id; self.gross = gross; self.pvi = pvi; self.cards = cards
    self.no_card = no_card; self.exhibition = exhibition; self.rank = rank; self.prize = prize
  }
}

/// `major_leaderboard` — the live board (a definer read; rounds RLS is owner-only).
public struct MajorBoardRow: Sendable, Equatable, Identifiable {
  public let playerId: UUID
  public let profileId: UUID?
  public let displayName: String
  public let marker: String
  public let exhibition: Bool
  public let roundId: UUID?
  public let gross: Int?
  public let pvi: Double?
  public let cards: Int
  public var id: UUID { playerId }

  public init(playerId: UUID, profileId: UUID?, displayName: String, marker: String = "saguaro", exhibition: Bool = false,
              roundId: UUID? = nil, gross: Int? = nil, pvi: Double? = nil, cards: Int = 0) {
    self.playerId = playerId; self.profileId = profileId; self.displayName = displayName; self.marker = marker
    self.exhibition = exhibition; self.roundId = roundId; self.gross = gross; self.pvi = pvi; self.cards = cards
  }

  public init?(_ r: Rpc.major_leaderboard.Row) {
    guard let pid = r.player_id else { return nil }
    self.init(playerId: pid, profileId: r.profile_id, displayName: r.display_name ?? "—", marker: r.marker ?? "saguaro",
              exhibition: r.exhibition ?? false, roundId: r.round_id, gross: r.gross, pvi: r.pvi, cards: r.cards ?? 0)
  }
}

/// `event_lineage` — one edition of the chain (D61 the annual Major, D62 the Ryder series).
public struct EventLineageRow: Sendable, Equatable, Identifiable {
  public let eventId: UUID
  public let kind: String
  public let status: String
  public let year: Int?
  public let champion: String?
  public let champGross: Int?
  public let champPvi: Double?
  public let winnerSlot: Int?
  public let winnerShared: Bool
  public var id: UUID { eventId }

  public init(eventId: UUID, kind: String = "ryder", status: String, year: Int? = nil, champion: String? = nil,
              champGross: Int? = nil, champPvi: Double? = nil, winnerSlot: Int? = nil, winnerShared: Bool = false) {
    self.eventId = eventId; self.kind = kind; self.status = status; self.year = year; self.champion = champion
    self.champGross = champGross; self.champPvi = champPvi; self.winnerSlot = winnerSlot; self.winnerShared = winnerShared
  }

  public init?(_ r: Rpc.event_lineage.Row) {
    guard let id = r.event_id else { return nil }
    self.init(eventId: id, kind: r.kind ?? "ryder", status: r.status ?? "", year: r.year, champion: r.champion,
              champGross: r.champ_gross, champPvi: r.champ_pvi, winnerSlot: r.winner_slot, winnerShared: r.winner_shared ?? false)
  }
  public var isMajor: Bool { kind == "major" }
  public var isComplete: Bool { status == "complete" }
}

/// `window.CS_EVENT` — everything one room renders from.
public struct EventRoom: Sendable, Equatable {
  public var event: EventRow
  public var teams: [EventTeam]
  public var players: [EventPlayer]
  public var sessions: [EventSession]
  public var duels: [EventDuel]
  /// team id → points (`v_event_scoreboard`).
  public var scoreboard: [UUID: Double]
  /// duel id → the number to beat.
  public var targets: [UUID: EventTarget]
  public var posts: [EventPost]
  public var majorBoard: [MajorBoardRow]
  public var majorCards: [MajorCard]
  public var lineage: [EventLineageRow]

  public init(event: EventRow, teams: [EventTeam] = [], players: [EventPlayer] = [], sessions: [EventSession] = [],
              duels: [EventDuel] = [], scoreboard: [UUID: Double] = [:], targets: [UUID: EventTarget] = [:],
              posts: [EventPost] = [], majorBoard: [MajorBoardRow] = [], majorCards: [MajorCard] = [], lineage: [EventLineageRow] = []) {
    self.event = event; self.teams = teams; self.players = players; self.sessions = sessions; self.duels = duels
    self.scoreboard = scoreboard; self.targets = targets; self.posts = posts; self.majorBoard = majorBoard
    self.majorCards = majorCards; self.lineage = lineage
  }

  /// `A` — slot 0, else the first team, else the web's placeholder.
  public var teamA: EventTeam { teams.first { $0.slot == 0 } ?? teams.first ?? EventTeam(id: UUID(), slot: 0, name: "Team A", color: 0) }
  /// `B` — slot 1, else the second team, else the placeholder.
  public var teamB: EventTeam { teams.first { $0.slot == 1 } ?? (teams.count > 1 ? teams[1] : EventTeam(id: UUID(), slot: 1, name: "Team B", color: 1)) }

  public func player(_ id: UUID) -> EventPlayer { players.first { $0.id == id } ?? .unknown }
  public func points(_ team: UUID) -> Double { scoreboard[team] ?? 0 }
  public func roster(_ team: UUID) -> [EventPlayer] { players.filter { $0.teamId == team }.sorted { $0.seed < $1.seed } }
  public var unassigned: [EventPlayer] { players.filter { $0.teamId == nil } }
  public func duels(in session: UUID) -> [EventDuel] { duels.filter { $0.session_id == session } }
  /// "the horn" — any session closed (the Major's settle guard, the Scrap guard).
  public var anyClosed: Bool { sessions.contains { $0.isClosed } }
  public func me(_ profile: UUID?) -> EventPlayer? { profile.flatMap { p in players.first { $0.profileId == p } } }
  public func isOrganizer(_ profile: UUID?) -> Bool { profile != nil && event.created_by == profile }
}

/// One chip in the Clubhouse (`loadMyEvents` 15811–15831): mine, or an
/// attached event of a league I'm in (`mine:false` → "Enter the field").
public struct EventSummary: Sendable, Equatable, Identifiable {
  public let id: UUID
  public let name: String
  public let kind: String
  public let status: String
  public let leagueId: UUID?
  public let mine: Bool
  public init(id: UUID, name: String, kind: String, status: String, leagueId: UUID? = nil, mine: Bool) {
    self.id = id; self.name = name; self.kind = kind; self.status = status; self.leagueId = leagueId; self.mine = mine
  }
  public var isMajor: Bool { kind == "major" }
}
