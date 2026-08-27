// Cup Season — the rows the league room reads (D100 / IOS-018, parity wave 1).
//
// Every struct mirrors a PostgREST select the web client makes in
// `loadLeagueData` / `loadStandingsAndFeed` (index.html 14137–14539), plus the
// two the web never made and §16 wants: `season_adjustments` with reasons and
// `season_payouts` for the ceremony. Calendar dates are Strings (Dates.swift).
// Money is cents. Numeric columns decode as Double.

import Foundation

public enum LeagueRoom {
  public struct League: Decodable, Sendable {
    public let id: UUID
    public let name: String
    public let code: String?
    public let phase: String
    public let commissioner_id: UUID?
    public init(id: UUID, name: String, code: String?, phase: String, commissioner_id: UUID?) {
      self.id = id; self.name = name; self.code = code; self.phase = phase; self.commissioner_id = commissioner_id
    }
  }

  /// `league_settings` — the bylaws (audit 02 §3.2).
  public struct Settings: Decodable, Sendable {
    public let league_id: UUID
    public let preset: String?
    public let handicap_allowance: Int?
    public let verification: String?
    public let counting_cap: Int?
    public let participation_floor: Int?
    public let floor_penalty: String?
    public let season_format: String?
    public let buyin_cents: Int?
    public let season_months: Int?
    public let locked_at: Date?
    public let structure: String?
    public let draft_type: String?
    public let payout_champ: Int?
    public let payout_runnerup: Int?
    public let payout_king: Int?
    public let finish: String?
    public init(league_id: UUID, preset: String? = nil, handicap_allowance: Int? = nil, verification: String? = nil, counting_cap: Int? = nil,
                participation_floor: Int? = nil, floor_penalty: String? = nil, season_format: String? = nil, buyin_cents: Int? = nil,
                season_months: Int? = nil, locked_at: Date? = nil, structure: String? = nil, draft_type: String? = nil,
                payout_champ: Int? = nil, payout_runnerup: Int? = nil, payout_king: Int? = nil, finish: String? = nil) {
      self.league_id = league_id; self.preset = preset; self.handicap_allowance = handicap_allowance; self.verification = verification
      self.counting_cap = counting_cap; self.participation_floor = participation_floor; self.floor_penalty = floor_penalty
      self.season_format = season_format; self.buyin_cents = buyin_cents; self.season_months = season_months; self.locked_at = locked_at
      self.structure = structure; self.draft_type = draft_type; self.payout_champ = payout_champ; self.payout_runnerup = payout_runnerup
      self.payout_king = payout_king; self.finish = finish
    }
  }

  /// `seasons` with the D66 result columns.
  public struct Season: Decodable, Sendable {
    public let id: UUID
    public let number: Int?
    public let starts_on: String
    public let ends_on: String
    public let status: String
    public let champion_squad_id: UUID?
    public let champion_member_id: UUID?
    public let runnerup_squad_id: UUID?
    public let runnerup_member_id: UUID?
    public let points_king_member_id: UUID?
    public let champion_score: Double?
    public let runnerup_score: Double?
    public let tiebreak_rung: String?
    public init(id: UUID, number: Int? = 1, starts_on: String, ends_on: String, status: String, champion_squad_id: UUID? = nil,
                champion_member_id: UUID? = nil, runnerup_squad_id: UUID? = nil, runnerup_member_id: UUID? = nil,
                points_king_member_id: UUID? = nil, champion_score: Double? = nil, runnerup_score: Double? = nil, tiebreak_rung: String? = nil) {
      self.id = id; self.number = number; self.starts_on = starts_on; self.ends_on = ends_on; self.status = status
      self.champion_squad_id = champion_squad_id; self.champion_member_id = champion_member_id; self.runnerup_squad_id = runnerup_squad_id
      self.runnerup_member_id = runnerup_member_id; self.points_king_member_id = points_king_member_id
      self.champion_score = champion_score; self.runnerup_score = runnerup_score; self.tiebreak_rung = tiebreak_rung
    }
  }

  /// `league_members` + the embedded profile (named columns — email is sealed).
  public struct Member: Decodable, Sendable, Identifiable {
    public struct Profile: Decodable, Sendable {
      public let display_name: String?
      public let marker: String?
      public let index_current: Double?
      public let handle: String?
      public let photo_path: String?
      public init(display_name: String?, marker: String? = nil, index_current: Double? = nil, handle: String? = nil, photo_path: String? = nil) {
        self.display_name = display_name; self.marker = marker; self.index_current = index_current; self.handle = handle; self.photo_path = photo_path
      }
    }
    public let id: UUID
    public let role: String
    public let profile_id: UUID
    public let joined_at: Date?
    public let marker: String?
    public let profile: Profile?
    public init(id: UUID, role: String, profile_id: UUID, joined_at: Date? = nil, marker: String? = nil, profile: Profile? = nil) {
      self.id = id; self.role = role; self.profile_id = profile_id; self.joined_at = joined_at; self.marker = marker; self.profile = profile
    }
    /// Effective marker: league override → profile choice → the floor (14300).
    public var mk: String { marker ?? profile?.marker ?? "saguaro" }
    /// `memName` (14344): the display name, "—" when unknown.
    public var name: String { profile?.display_name ?? "—" }
    public var isPro: Bool { role == "commissioner" }
  }

  public struct Squad: Decodable, Sendable, Identifiable {
    public struct Seat: Decodable, Sendable { public let member_id: UUID; public init(member_id: UUID) { self.member_id = member_id } }
    public let id: UUID
    public let name: String
    public let color: Int?
    public let captain_member_id: UUID?
    public let squad_members: [Seat]
    public init(id: UUID, name: String, color: Int?, captain_member_id: UUID? = nil, squad_members: [Seat] = []) {
      self.id = id; self.name = name; self.color = color; self.captain_member_id = captain_member_id; self.squad_members = squad_members
    }
    public func seats(_ id: UUID) -> Bool { squad_members.contains { $0.member_id == id } }
  }

  public struct BuyIn: Decodable, Sendable {
    public let member_id: UUID
    public let paid: Bool
    public let amount_cents: Int?
    public init(member_id: UUID, paid: Bool, amount_cents: Int?) { self.member_id = member_id; self.paid = paid; self.amount_cents = amount_cents }
  }

  /// `season_adjustments` — the ledger WITH its reasons (§14.2, §16).
  public struct Adjustment: Decodable, Sendable, Identifiable {
    public let id: UUID
    public let squad_id: UUID?
    public let member_id: UUID?
    public let month: String?
    public let kind: String
    public let points: Int
    public let reason: String?
    public let created_by: UUID?
    public init(id: UUID, squad_id: UUID?, member_id: UUID?, month: String?, kind: String, points: Int, reason: String?, created_by: UUID? = nil) {
      self.id = id; self.squad_id = squad_id; self.member_id = member_id; self.month = month; self.kind = kind; self.points = points
      self.reason = reason; self.created_by = created_by
    }
    /// The `month_closed` sentinel is bookkeeping, not a line on the receipt.
    public var isSentinel: Bool { kind == "month_closed" }
  }

  public struct Snapshot: Decodable, Sendable {
    public let week_no: Int
    public let standings: JSONValue
    public init(week_no: Int, standings: JSONValue) { self.week_no = week_no; self.standings = standings }
  }

  /// `v_rounds_ranked` — one row per round × league lens.
  public struct RankedRound: Decodable, Sendable {
    public let member_id: UUID
    public let round_id: UUID?
    public let pvi: Double?
    public let points: Double?
    public let month_rank: Int?
    public let floor_credit: Double?
    public let played_on: String
    public let index_at_post: Double?
    public let holes_played: Int?
    public init(member_id: UUID, round_id: UUID? = nil, pvi: Double?, points: Double?, month_rank: Int?, floor_credit: Double?,
                played_on: String, index_at_post: Double?, holes_played: Int?) {
      self.member_id = member_id; self.round_id = round_id; self.pvi = pvi; self.points = points; self.month_rank = month_rank
      self.floor_credit = floor_credit; self.played_on = played_on; self.index_at_post = index_at_post; self.holes_played = holes_played
    }
  }

  public struct IndivStanding: Decodable, Sendable {
    public let member_id: UUID
    public let points: Double?
    public let rounds_posted: Int?
    public init(member_id: UUID, points: Double?, rounds_posted: Int?) { self.member_id = member_id; self.points = points; self.rounds_posted = rounds_posted }
  }

  public struct SquadStanding: Decodable, Sendable {
    public let squad_id: UUID
    public let points: Double?
    public init(squad_id: UUID, points: Double?) { self.squad_id = squad_id; self.points = points }
  }

  /// `forfeits` — the D64 ledger. Never dollars.
  public struct Forfeit: Decodable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let terms: String
    public let kind: String
    public let party_a: UUID
    public let party_b: UUID?
    public let hangs_on: String?
    public let status: String
    public let winner: UUID?
    public let settled_note: String?
    public let created_by: UUID
    public init(id: UUID, name: String, terms: String, kind: String = "custom", party_a: UUID, party_b: UUID? = nil, hangs_on: String? = nil,
                status: String = "open", winner: UUID? = nil, settled_note: String? = nil, created_by: UUID) {
      self.id = id; self.name = name; self.terms = terms; self.kind = kind; self.party_a = party_a; self.party_b = party_b
      self.hangs_on = hangs_on; self.status = status; self.winner = winner; self.settled_note = settled_note; self.created_by = created_by
    }
  }

  /// `season_payouts` — the settlement as the server wrote it (D67).
  public struct Payout: Decodable, Sendable {
    public let profile_id: UUID
    public let cents: Int
    public let reason: String
    public init(profile_id: UUID, cents: Int, reason: String) { self.profile_id = profile_id; self.cents = cents; self.reason = reason }
  }

  /// `rounds` with a photo — the album (16456).
  public struct AlbumRound: Decodable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let profile_id: UUID
    public let gross: Int?
    public let differential: Double?
    public let index_at_post: Double?
    public let played_on: String
    public let course_label: String?
    public let holes_played: Int?
    public let photo_path: String
    public init(id: UUID, profile_id: UUID, gross: Int?, differential: Double? = nil, index_at_post: Double? = nil, played_on: String,
                course_label: String?, holes_played: Int? = nil, photo_path: String) {
      self.id = id; self.profile_id = profile_id; self.gross = gross; self.differential = differential; self.index_at_post = index_at_post
      self.played_on = played_on; self.course_label = course_label; self.holes_played = holes_played; self.photo_path = photo_path
    }
  }
}

/// `season_scenarios` (D24) — decoded from its jsonb.
public struct SeasonScenarios: Decodable, Sendable, Equatable {
  public struct Meta: Decodable, Sendable, Equatable {
    public let finish: String?
    public let structure: String?
    public let level: String?
    public let k: Int?
    public let seed_end: String?
    public let months_left: Int?
    public let locked: Bool?
    public let cap: Int?
    public let status: String?
    public let ends_on: String?
    public init(finish: String?, structure: String?, level: String?, k: Int?, seed_end: String? = nil, months_left: Int?, locked: Bool?, cap: Int?,
                status: String? = nil, ends_on: String? = nil) {
      self.finish = finish; self.structure = structure; self.level = level; self.k = k; self.seed_end = seed_end; self.months_left = months_left
      self.locked = locked; self.cap = cap; self.status = status; self.ends_on = ends_on
    }
  }
  public struct Row: Decodable, Sendable, Equatable, Identifiable {
    public let level: String?
    public let id: UUID
    public let name: String?
    public let points: Double?
    public let max_final: Double?
    public let roster: Int?
    public let rank: Int?
    public let clinched: Bool?
    public let eliminated: Bool?
    public let needs: Double?
    public init(level: String? = nil, id: UUID, name: String?, points: Double?, max_final: Double?, roster: Int? = nil, rank: Int? = nil,
                clinched: Bool?, eliminated: Bool?, needs: Double?) {
      self.level = level; self.id = id; self.name = name; self.points = points; self.max_final = max_final; self.roster = roster
      self.rank = rank; self.clinched = clinched; self.eliminated = eliminated; self.needs = needs
    }
  }
  public let meta: Meta
  public let rows: [Row]
  public init(meta: Meta, rows: [Row]) { self.meta = meta; self.rows = rows }

  public static func decode(_ v: JSONValue) -> SeasonScenarios? {
    guard case .object = v, v["meta"] != nil else { return nil }
    guard let data = try? JSONEncoder().encode(v) else { return nil }
    return try? JSONDecoder().decode(SeasonScenarios.self, from: data)
  }
}

/// `league_cancel_status` (D71).
public struct CancelStatus: Decodable, Sendable, Equatable {
  public let open: Bool?
  public let members: Int?
  public let approved: Int?
  public let you_approved: Bool?
  public let you_refund_cents: Int?
  public let is_pro: Bool?
  public let requested_by_me: Bool?
  public init(open: Bool?, members: Int?, approved: Int?, you_approved: Bool?, you_refund_cents: Int?, is_pro: Bool?, requested_by_me: Bool? = nil) {
    self.open = open; self.members = members; self.approved = approved; self.you_approved = you_approved
    self.you_refund_cents = you_refund_cents; self.is_pro = is_pro; self.requested_by_me = requested_by_me
  }
  public static func decode(_ v: JSONValue) -> CancelStatus? {
    guard case .object = v, let data = try? JSONEncoder().encode(v) else { return nil }
    return try? JSONDecoder().decode(CancelStatus.self, from: data)
  }
}
