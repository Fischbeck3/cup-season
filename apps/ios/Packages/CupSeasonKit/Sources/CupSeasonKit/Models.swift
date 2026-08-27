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
    public let role: String
    public let member_id: UUID
    public let marker: String?
    public let commissioner_name: String?
    public let settings: Settings?
    public let season: Season?
    public let squad: Squad?
    public let standing: Standing?
    public let pulse: Pulse?
    public var id: UUID { league_id }
    public var isPro: Bool { role == "commissioner" }
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
    let total = max(1, ((CSDate.days(from: s.starts_on, to: s.ends_on) ?? 0) + 1 + 6) / 7)
    let week = min(total, sinceStart / 7 + 1)
    return .season(week: week, of: total)
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

  public static func of(_ me: Me, preferredLeague: UUID?) -> HomeMode {
    let active = me.memberships.filter { if case .wrapped = SeasonPhase.of($0) { return false }; return true }
    let pool = active.isEmpty ? me.memberships : active
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
