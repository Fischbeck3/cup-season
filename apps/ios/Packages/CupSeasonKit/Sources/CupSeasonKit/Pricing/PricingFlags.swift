// Cup Season — the visible pricing model (IOS-021 executing D56).
//
// D101 (2026-08-27): the unit is the LEAGUE-YEAR — one pass covers every
// season a league runs in twelve months, first year free — and the numbers
// sit 25% under the per-league comps (Golf League Tracker $119, Fantrax
// $130, MyFantasyLeague ~$110, LeagueLobster $228/yr): $59 · $89 · $109.
//
// One `app_flags` row keyed `pricing` (migration 20260827170000) drives the
// three launch surfaces: the wizard's pass card, the You-tab membership card,
// the pot pane's Pro card. This file is the whole contract — the bands, the
// per-player line, the Founding lookup, and the read. NO checkout, no Stripe,
// no IAP: the phone shows the model; the money side stays on the web at
// season 2 (plan §2e/§3, IOS-018/D99).
//
// Fail closed, always: a missing row, a failed read, a malformed value — each
// decodes to `.hidden` (visible:false), and every surface renders today's
// copy. Nothing here throws to a screen (plan §1 "never block boot on it").
//
// Voice rules the helpers encode (plan §0): numbers speak per-head ("about
// $6.60 a player"), never % of pot; the app quotes ONE number for THIS
// league's roster, never the band table (discovery §2).

import Foundation
import Supabase

public struct PricingFlags: Decodable, Sendable, Equatable {
  /// One rung of the banded flat: the first band whose `maxRoster` holds the
  /// roster wins. Bands are pricing machinery, not a surface.
  public struct Band: Decodable, Sendable, Equatable {
    public let maxRoster: Int
    public let cents: Int
    public init(maxRoster: Int, cents: Int) { self.maxRoster = maxRoster; self.cents = cents }
    enum CodingKeys: String, CodingKey { case maxRoster = "max_roster", cents }
  }

  /// Founding Leagues — free forever, numbered, capped (the cap is the
  /// marketing). `ids` maps a league uuid (lowercase, as Postgres writes it)
  /// to its badge number.
  public struct Founding: Decodable, Sendable, Equatable {
    public let cap: Int
    public let closed: Bool
    public let ids: [String: Int]
    public init(cap: Int = 10, closed: Bool = false, ids: [String: Int] = [:]) { self.cap = cap; self.closed = closed; self.ids = ids }
    public init(from decoder: Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      cap = try c.decodeIfPresent(Int.self, forKey: .cap) ?? 10
      closed = try c.decodeIfPresent(Bool.self, forKey: .closed) ?? false
      ids = try c.decodeIfPresent([String: Int].self, forKey: .ids) ?? [:]
    }
    enum CodingKeys: String, CodingKey { case cap, closed, ids }
  }

  public let visible: Bool
  public let anchorCents: Int
  public let bands: [Band]
  /// Every league's first YEAR is on us (D101; was `season1_free` under D56).
  public let firstYearFree: Bool
  public let founding: Founding
  /// What the pass covers: "year" (D101). Carried so a future unit change is
  /// a flag write, not a build.
  public let unit: String

  public init(visible: Bool, anchorCents: Int, bands: [Band], firstYearFree: Bool, founding: Founding, unit: String = "year") {
    self.visible = visible; self.anchorCents = anchorCents; self.bands = bands; self.firstYearFree = firstYearFree; self.founding = founding; self.unit = unit
  }

  /// Lenient on purpose: every key defaults, so a partial row (an owner who
  /// wrote `{"visible": true}` by hand) still decodes. `visible` defaults to
  /// FALSE — the one default that matters.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    visible = try c.decodeIfPresent(Bool.self, forKey: .visible) ?? false
    anchorCents = try c.decodeIfPresent(Int.self, forKey: .anchorCents) ?? Self.defaultAnchorCents
    let decoded = try c.decodeIfPresent([Band].self, forKey: .bands) ?? []
    bands = decoded.isEmpty ? Self.defaultBands : decoded
    firstYearFree = try c.decodeIfPresent(Bool.self, forKey: .firstYearFree) ?? c.decodeIfPresent(Bool.self, forKey: .season1Free) ?? true
    founding = try c.decodeIfPresent(Founding.self, forKey: .founding) ?? Founding()
    unit = try c.decodeIfPresent(String.self, forKey: .unit) ?? "year"
  }
  enum CodingKeys: String, CodingKey {
    case visible, bands, founding, unit
    case anchorCents = "anchor_cents"
    case firstYearFree = "first_year_free"
    case season1Free = "season1_free"   // the D56 key; read for compatibility, never written
  }

  // MARK: - The constants (discovery §2, IOS-021)

  public static let defaultAnchorCents = 8900
  /// $59 ≤9 · $89 10–13 · $109 14+ — a year, every season included (D101).
  public static let defaultBands: [Band] = [Band(maxRoster: 9, cents: 5900), Band(maxRoster: 13, cents: 8900), Band(maxRoster: 99, cents: 10900)]
  /// The roster the anchor is quoted against when a surface has no roster
  /// of its own (a membership row with no count): the standard band's middle.
  public static let referenceRoster = 12

  /// What every failure decodes to. Surfaces render today's copy.
  public static let hidden = PricingFlags(visible: false, anchorCents: defaultAnchorCents, bands: defaultBands, firstYearFree: true, founding: Founding())
  /// The plan's seed with the switch ON — previews and tests, never prod
  /// (prod's row is seeded `visible:false`; the owner flips it).
  public static let seed = PricingFlags(visible: true, anchorCents: defaultAnchorCents, bands: defaultBands, firstYearFree: true, founding: Founding())

  // MARK: - Bands and formatting

  /// `passFor(roster)` — the first band with roster ≤ max_roster; past the
  /// last band, the last band. Fixes at roster lock (discovery §2).
  public func passFor(roster: Int) -> Band {
    let r = max(1, roster)
    if let b = bands.first(where: { r <= $0.maxRoster }) { return b }
    return bands.last ?? Band(maxRoster: Int.max, cents: anchorCents)
  }

  /// "$89" — whole dollars stay whole; anything else shows cents ("$89.50").
  public static func dollars(_ cents: Int) -> String {
    cents % 100 == 0 ? "$\(cents / 100)" : String(format: "$%.2f", Double(cents) / 100)
  }

  /// The per-head figure: 2 decimals under $10, else round (plan §1). Under
  /// $10 it rounds to the DIME — the standard band reads "$7.40" a year
  /// (8900 / 12 = 7.416), and the figure wears "about" / "≈" wherever it
  /// appears, so a dime is the honest precision.
  public static func perPlayer(cents: Int, roster: Int) -> String {
    let each = Double(cents) / 100 / Double(max(1, roster))
    if each < 10 { return String(format: "$%.2f", (each * 10).rounded() / 10) }
    return "$\(Int(each.rounded()))"
  }

  /// "about $7.40 a player" / "about $10 a player".
  public static func perPlayerLine(cents: Int, roster: Int) -> String {
    "about \(perPlayer(cents: cents, roster: roster)) a player"
  }

  // MARK: - Founding

  /// The badge number for a league, if it is one of the ten.
  public func foundingNumber(leagueId: UUID) -> Int? {
    founding.ids[leagueId.uuidString.lowercased()] ?? founding.ids[leagueId.uuidString.uppercased()]
  }

  // MARK: - The read

  private struct Row: Decodable { let value: PricingFlags? }

  /// `app_flags.pricing`, through `flags_read` (authenticated, using(true)).
  /// Mirrors `PostService.scanEnabled` — `.limit(1)`, decode the array. No
  /// row, no read, a bad value: `.hidden`. Never throws.
  public static func load(_ svc: SupabaseService = .shared) async -> PricingFlags {
    guard let rows: [Row] = try? await svc.client.from("app_flags").select("value").eq("key", value: "pricing").limit(1).execute().value,
          let flags = rows.first?.value else { return .hidden }
    return flags
  }

  /// The same value arriving as jsonb already in hand (a future
  /// `native_home().flags.pricing` fold-in is this one line). Bad shape → hidden.
  public init(json: JSONValue?) {
    guard let json, case .object = json, let data = try? JSONEncoder().encode(json),
          let flags = try? JSONDecoder().decode(PricingFlags.self, from: data) else { self = .hidden; return }
    self = flags
  }
}

// MARK: - What the You-tab membership card renders, per league (plan §2b)

/// A pass that has been paid — FUTURE. Nothing on the phone mints one; the
/// Stripe phase on the web does (plan §3). Carried so State C's markup exists.
public struct PricingPaid: Sendable, Equatable {
  /// "YYYY-MM-DD" — a calendar date, by parts (Dates.swift).
  public let paidThrough: String
  public let cents: Int
  public init(paidThrough: String, cents: Int) { self.paidThrough = paidThrough; self.cents = cents }
}

public enum PricingMembershipState: Sendable, Equatable {
  /// State A — gold badge, free forever.
  case founding(number: Int)
  /// State B — this year is free; the chips carry next year's number.
  case freeYear(cents: Int, roster: Int)
  /// State C — paid through a date (future).
  case paid(PricingPaid)

  /// Founding beats paid beats free — a Founding league never renders a
  /// price, whatever else is on file.
  public static func of(_ flags: PricingFlags, leagueId: UUID, roster: Int?, paid: PricingPaid?) -> PricingMembershipState {
    if let n = flags.foundingNumber(leagueId: leagueId) { return .founding(number: n) }
    if let paid { return .paid(paid) }
    let r = roster ?? PricingFlags.referenceRoster
    return .freeYear(cents: flags.passFor(roster: r).cents, roster: r)
  }
}
