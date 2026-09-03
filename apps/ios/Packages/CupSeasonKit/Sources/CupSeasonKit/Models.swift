// Cup Season — the bootstrap shape (`native_home`, IOS-009) and what the app
// derives from it (IOS-002 §3).
//
// Every field the server might omit is optional; the phone tolerates an older
// or newer `native_home` and renders what it has. Calendar dates are Strings
// (see Dates.swift). Money is cents.

import Foundation

public struct Me: Decodable, Sendable {
  public struct Profile: Decodable, Sendable {
    public let id: UUID
    public let display_name: String?
    public let handle: String?
    public let marker: String?
    public let city: String?
    public let home_course: String?
    public let index_current: Double?
    public let index_source: String?
    public let photo_path: String?
    public let rounds_count: Int?
    public let member_since: Date?
    public let is_founder: Bool?
  }

  public struct Settings: Decodable, Sendable {
    public let structure: String?
    public let preset: String?
    public let counting_cap: Int?
    public let participation_floor: Int?
    public let floor_penalty: String?
    public let handicap_allowance: Int?
    public let buyin_cents: Int?
    public let payout_champ: Int?
    public let payout_runnerup: Int?
    public let payout_king: Int?
    public let finish: String?
    public let locked_at: Date?
  }

  public struct Season: Decodable, Sendable {
    public let id: UUID
    public let number: Int?
    public let starts_on: String
    public let ends_on: String
    public let status: String
    public let timezone: String?
    public let grace_hours: Int?
    public let champion_squad_id: UUID?
    public let champion_member_id: UUID?
    public let points_king_member_id: UUID?
    public let tiebreak_rung: String?
  }

  public struct Squad: Decodable, Sendable {
    public let id: UUID
    public let name: String
    public let color: Int
  }

  public struct Standing: Decodable, Sendable {
    public let rank: Int
    public let of: Int
    public let points: Double?
    public let prev_rank: Int?
    public let leader_squad_id: UUID?
    public let leader_points: Double?
    public let gap_to_leader: Double?
    public let gap_to_next: Double?
    /// D130 / `native_home()` v2 · the leader BY NAME — `firstname(display_name)`
    /// in a solo league (the board's own word: "Galen"), the squad's name
    /// otherwise. nil on a v1 payload (deploy skew): the copy then says "the lead".
    public let leader_name: String?
    /// v2 · the rank-2 name, so a leader can say "22 clear of Jade"
    /// (`gap_to_next` is nil for rank 1). nil when fewer than two.
    public let runner_up_name: String?
    /// v2 · the rank-2 total, for the "19 – 9" clause at n = 2.
    public let runner_up_points: Double?
    /// v2 · D138 / §14.3 — only while the season is in its Cup Final: the
    /// caller's LOCKED `cup_finalists.seed` (nil for a non-finalist, and on
    /// every payload outside the Final). `rank` is the live table, which keeps
    /// moving through the Final — it is never a seed.
    public let seed: Int?
    /// v2 · the finalists' names in seed order, the board's form. nil outside
    /// the Final and on a v1 payload.
    public let finalists: [String]?

    public init(rank: Int, of: Int, points: Double?, prev_rank: Int?, leader_squad_id: UUID?, leader_points: Double?,
                gap_to_leader: Double?, gap_to_next: Double?, leader_name: String? = nil, runner_up_name: String? = nil,
                runner_up_points: Double? = nil, seed: Int? = nil, finalists: [String]? = nil) {
      self.rank = rank; self.of = of; self.points = points; self.prev_rank = prev_rank; self.leader_squad_id = leader_squad_id
      self.leader_points = leader_points; self.gap_to_leader = gap_to_leader; self.gap_to_next = gap_to_next
      self.seed = seed; self.finalists = finalists
      self.leader_name = leader_name; self.runner_up_name = runner_up_name; self.runner_up_points = runner_up_points
    }
  }

  /// D106 / D129 · the pot as `native_home()` v2 carries it. Absent (nil on the
  /// membership) when the league is bragging rights (D70) — and on a v1
  /// payload, where the copy falls back to roster × stake and says nothing
  /// about cash collected.
  public struct BuyIn: Decodable, Sendable, Equatable {
    /// The CALLER's own `buy_ins.paid`; false when no row. Self-only copy (D23).
    public let paid: Bool?
    /// `league_settings.buy_in_note` — how to pay, the Pro's words (D129).
    public let note: String?
    /// `league_settings.buy_in_due_on`, a calendar date (D129).
    public let due_on: String?
    /// How many members the pot is owed by — the roster, never below one
    /// (`LeagueRoomModel.potPlayers`).
    public let players: Int?
    public let paid_count: Int?
    /// `paid_count × buyin_cents` — the cash that exists (D106 "collected").
    public let collected_cents: Int?

    public init(paid: Bool? = nil, note: String? = nil, due_on: String? = nil, players: Int? = nil, paid_count: Int? = nil,
                collected_cents: Int? = nil) {
      self.paid = paid; self.note = note; self.due_on = due_on; self.players = players; self.paid_count = paid_count
      self.collected_cents = collected_cents
    }
  }

  public struct Pulse: Decodable, Sendable {
    public let credits: Double?
    public let floor: Int?
    public let at_floor: Bool?
    public let partial: Bool?
  }

  public struct Membership: Decodable, Sendable, Identifiable {
    public let league_id: UUID
    public let name: String
    public let code: String?
    public let phase: String
    /// D208 · `native_home()` has always returned it (20260827130400:300); the
    /// You card's league count needs it, and one decoded key beats one more read.
    public let sandbox: Bool?
    public let role: String
    public let member_id: UUID
    public let marker: String?
    public let commissioner_name: String?
    public let settings: Settings?
    public let season: Season?
    public let squad: Squad?
    public let standing: Standing?
    public let pulse: Pulse?
    /// v2 · nil when `buyin_cents` is 0/null (D70) or on a v1 payload.
    public let buy_in: BuyIn?
    /// v2 · the D207 headcount — members with a living profile and no
    /// suspension, the count `open_week_clash` writes "It's the two of you"
    /// under. nil on a v1 payload. Prefer `headcount`, which falls back.
    public let roster: Int?
    /// v2 · every league_members row — suspended and tombstoned included —
    /// the number the room's "N players", the Members sheet and the Pot pane
    /// print. The count a Home line SHOWS; `roster` is the count a rule GATES
    /// on. nil on a v1 payload.
    public let members: Int?
    public var id: UUID { league_id }
    public var isPro: Bool { role == "commissioner" }

    public init(league_id: UUID, name: String, code: String?, phase: String, sandbox: Bool?, role: String, member_id: UUID, marker: String?,
                commissioner_name: String?, settings: Settings?, season: Season?, squad: Squad?, standing: Standing?, pulse: Pulse?,
                buy_in: BuyIn? = nil, roster: Int? = nil, members: Int? = nil) {
      self.league_id = league_id; self.name = name; self.code = code; self.phase = phase; self.sandbox = sandbox; self.role = role
      self.member_id = member_id; self.marker = marker; self.commissioner_name = commissioner_name; self.settings = settings
      self.season = season; self.squad = squad; self.standing = standing; self.pulse = pulse; self.buy_in = buy_in
      self.roster = roster; self.members = members
    }

    /// The stake in cents — 0 for a bragging-rights league (D70).
    public var stakeCents: Int { settings?.buyin_cents ?? 0 }
    /// D140 · a solo league has no squads, so no floor can ever fire.
    public var isSolo: Bool { settings?.structure == "solo" }
    /// The league's headcount for a RULE (D207's "It's the two of you"): the
    /// server's own D207 count (`roster`, v2) when it sent one; else the pot's
    /// count (`buy_in.players` — every member row, suspended or not); else a
    /// solo league's `standing.of`, which IS its roster; squads' `of` counts
    /// squads, so it says nothing. nil = unknown. A line that SHOWS a headcount
    /// reads `members` first — the room's number — see `HomeLeagueRow`.
    public var headcount: Int? {
      if let n = roster, n > 0 { return n }
      if let n = buy_in?.players, n > 0 { return n }
      if isSolo, let n = standing?.of, n > 0 { return n }
      return nil
    }
  }

  public struct LiveRound: Decodable, Sendable {
    public let id: UUID
    public let league_id: UUID?
    public let league_name: String?
    public let status: String
    public let started_at: Date?
    public let course_label: String?
    public let game: String?
    public let mine: Bool?
    public let visitor: Bool?
  }

  public struct Event: Decodable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let kind: String
    public let status: String
    public let starts_on: String?
    public let league_id: UUID?
    public let my_team_slot: Int?
    public let is_organizer: Bool?
  }

  public struct Duel: Decodable, Sendable {
    public struct Opponent: Decodable, Sendable {
      public let profile_id: UUID
      public let display_name: String?
      public let marker: String?
    }
    public let event_id: UUID
    public let event_name: String?
    public let session_id: UUID?
    public let session_no: Int?
    public let opens_on: String?
    public let closes_on: String?
    public let opponent: Opponent?
    public let my_pvi: Double?
    public let their_pvi: Double?
  }

  public let profile: Profile?
  public let memberships: [Membership]
  public let invites: [JSONValue]
  public let live_round: LiveRound?
  public let upcoming_rounds: [JSONValue]
  public let events: [Event]
  public let open_duels: [Duel]
  public let flags: JSONValue?
  public let generated_at: Date?

  public init(profile: Profile?, memberships: [Membership] = [], invites: [JSONValue] = [], live_round: LiveRound? = nil,
              upcoming_rounds: [JSONValue] = [], events: [Event] = [], open_duels: [Duel] = [], flags: JSONValue? = nil, generated_at: Date? = nil) {
    self.profile = profile; self.memberships = memberships; self.invites = invites; self.live_round = live_round
    self.upcoming_rounds = upcoming_rounds; self.events = events; self.open_duels = open_duels; self.flags = flags; self.generated_at = generated_at
  }

  /// The card gate: marker AND handle, never "row exists" (the signup trigger
  /// creates the row with an email-derived name).
  public var needsCard: Bool {
    guard let p = profile else { return true }
    return (p.marker ?? "").isEmpty || (p.handle ?? "").isEmpty
  }

  /// The forced-update gate (`app_flags.ios.min_build`, IOS-009).
  public var minIOSBuild: Int? { flags?["ios"]?["min_build"]?.int }
}

// MARK: - Derived season phase (IOS-002 §3)

/// Derived, not read from one column: the web routes on `leagues.phase`, the
/// engine on `seasons.status`, and nothing keeps them in step (audit 02 §5).
public enum SeasonPhase: Sendable, Equatable {
  case forming            // setup / draft — no season, or one not started
  case preseason          // started, first tee still ahead
  case season(week: Int, of: Int)
  case cupFinal(weeksLeft: Int)
  case wrapped

  public static func of(_ m: Me.Membership, today: String = CSDate.today()) -> SeasonPhase {
    guard let s = m.season else { return .forming }
    if s.status == "complete" || m.phase == "complete" { return .wrapped }
    if s.status == "cup_final" {
      let left = max(0, ((CSDate.days(from: today, to: s.ends_on) ?? 0) + 6) / 7)
      return .cupFinal(weeksLeft: left)
    }
    guard m.phase == "season" else { return .forming }
    guard let sinceStart = CSDate.days(from: s.starts_on, to: today) else { return .forming }
    if sinceStart < 0 { return .preseason }
    // ONE week producer (D213 / §14.0 v1.1): the season runs N whole weeks and
    // ends on the same weekday N weeks out, so N = (ends_on − starts_on) / 7 —
    // `LeagueDates.totalWeeks`, the Clubhouse's number. Home once added a day
    // before dividing and said "week 5 of 14" over a Clubhouse saying 13.
    return .season(week: LeagueDates.currentWeek(start: s.starts_on, end: s.ends_on, today: today),
                   of: LeagueDates.totalWeeks(start: s.starts_on, end: s.ends_on))
  }
}

/// What Home leads with (audit 08 §3; D81 "the standing is a verb").
public enum HomeMode: Sendable {
  case leagueless(rung: Int)      // 7: no rounds · 6: no buddies · 5: buddies, no league
  case forming(Me.Membership)
  case preseason(Me.Membership)
  case season(Me.Membership)
  case cupFinal(Me.Membership)
  case wrapped(Me.Membership)

  /// The leagues Home will render around: every one that has NOT wrapped
  /// (forming, preseason, in season, in its Final), or — only when all have
  /// wrapped — every one. One producer for the hero, the lead card and the
  /// D121 rows, so a row's door (D218) can always land: a wrapped league
  /// beside a live one is the Clubhouse's, not Home's. A preseason league
  /// stays in — its row ("First tee Sat Sep 5") is a real door.
  public static func pool(_ memberships: [Me.Membership], today: String = CSDate.today()) -> [Me.Membership] {
    let active = memberships.filter { if case .wrapped = SeasonPhase.of($0, today: today) { return false }; return true }
    return active.isEmpty ? memberships : active
  }

  public static func of(_ me: Me, preferredLeague: UUID?) -> HomeMode {
    let pool = pool(me.memberships)
    guard let m = pool.first(where: { $0.league_id == preferredLeague }) ?? pool.first else {
      let rounds = me.profile?.rounds_count ?? 0
      return .leagueless(rung: rounds < 3 ? 7 : 6)
    }
    switch SeasonPhase.of(m) {
    case .forming: return .forming(m)
    case .preseason: return .preseason(m)
    case .season: return .season(m)
    case .cupFinal: return .cupFinal(m)
    case .wrapped: return .wrapped(m)
    }
  }

  public var membership: Me.Membership? {
    switch self {
    case .leagueless: nil
    case .forming(let m), .preseason(let m), .season(let m), .cupFinal(let m), .wrapped(let m): m
    }
  }
}

// MARK: - Copy producers (D1/D2: bands, never PvI)

public enum CSCopy {
  /// "12.4", "+1.2" for plus handicaps, "—" when not established.
  public static func index(_ v: Double?) -> String {
    guard let v, v.isFinite else { return "—" }
    return v < 0 ? String(format: "+%.1f", -v) : String(format: "%.1f", v)
  }

  public static func ordinal(_ n: Int) -> String {
    let s = n % 100
    let suffix = (s >= 11 && s <= 13) ? "th" : ["th", "st", "nd", "rd"][min(n % 10, 3) == n % 10 ? (n % 10 < 4 ? n % 10 : 0) : 0]
    return "\(n)\(suffix)"
  }

  public static func points(_ v: Double?) -> String {
    guard let v else { return "—" }
    return v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
  }

  public static func dollars(cents: Int) -> String {
    cents % 100 == 0 ? "$\(cents / 100)" : String(format: "$%.2f", Double(cents) / 100)
  }
}
