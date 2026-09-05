// Cup Season — D67: the record — what you've WON (index.html
// `renderCareerRecord` 11103–11133; `career_record()` 20260725190000).
//
// Titles lead; zero-count titles are omitted rather than shown as a wall of
// noughts. The money is an exact sum of recorded payouts, never a
// recomputation, and it is a record of what friends settled between
// themselves (D39) — no balance, nothing owed to or by the app.
//
// Y-02 · a record with no titles renders NOTHING — the display case under it
// carries the one empty line (`TrophyCase.emptyLine`), so a new golfer is
// not told twice that the shelf is bare. The two lines this file used to
// carry for that are retired.

import Foundation

public struct CareerRecord: Sendable, Equatable {
  public struct Item: Sendable, Equatable, Identifiable {
    public let key: String
    public let n: Int
    public let label: String
    public var id: String { key }
  }

  public let items: [Item]
  public let earningsCents: Int
  /// R12 · seasons that actually PAID this golfer. It is the money line's own
  /// denominator and NOTHING else — `season_payouts` holds zero rows for every
  /// profile in prod, so this reads 0 for everyone.
  public let seasonsDone: Int
  /// R12 · complete seasons this golfer was a member of. The different
  /// question the record was asking `seasonsDone`, and getting 0 back for
  /// golfers who have finished one. Nil on a payload that predates R12, which
  /// is how the "seasons" line knows to stay away (L-44).
  public let seasonsPlayed: Int?
  /// R12 · the earliest counting round, as a calendar String (L-07). Nil until
  /// R12 lands, and the "since" clause does not render without it —
  /// `profiles.created_at` is the ACCOUNT, not the golf.
  public let firstRoundOn: String?

  public static let moneyNote = "What your friends settled with you. " + MoneyCopy.ledger

  /// "Settled across 3 seasons" — nil when nothing was settled.
  public var moneyLine: (amount: String, sub: String)? {
    guard earningsCents > 0 else { return nil }
    return (CSCopy.dollars(cents: earningsCents), "Settled across \(seasonsDone) season\(seasonsDone == 1 ? "" : "s")")
  }

  /// "3 seasons played" — nil when the read cannot answer, so the record never
  /// prints the money denominator under a word that does not mean money.
  public var seasonsLine: String? {
    guard let n = seasonsPlayed, n > 0 else { return nil }
    return "\(n) season\(n == 1 ? "" : "s") played"
  }

  /// " · since March 2026" — the clause the design asked for, rendered ONLY
  /// when `first_round_on` is present. There is no fallback: an account's
  /// creation date is not when somebody started playing golf (L-44).
  public var sinceClause: String? {
    guard let on = firstRoundOn, let m = Self.monthYear(on) else { return nil }
    return "since \(m)"
  }

  /// "March 2026" from "2026-03-22" — by parts, never through an ISO parser (L-07).
  static func monthYear(_ iso: String) -> String? {
    let parts = iso.split(separator: "-").compactMap { Int($0) }
    let mos = ["January", "February", "March", "April", "May", "June",
               "July", "August", "September", "October", "November", "December"]
    guard parts.count >= 2, (1...12).contains(parts[1]) else { return nil }
    return "\(mos[parts[1] - 1]) \(parts[0])"
  }

  private static let order: [(String, String, String)] = [
    ("cups", "Cup", "Cups"), ("crowns", "Points crown", "Points crowns"),
    ("majors", "Major", "Majors"), ("events", "Event", "Events"),
    ("runner_ups", "Runner-up", "Runner-ups"),
  ]

  public static func parse(_ json: JSONValue) -> CareerRecord {
    let items = order.compactMap { k, one, many -> Item? in
      let n = json[k]?.int ?? 0
      return n > 0 ? Item(key: k, n: n, label: n == 1 ? one : many) : nil
    }
    return CareerRecord(items: items,
                        earningsCents: json["earnings_cents"]?.int ?? 0,
                        seasonsDone: json["seasons_done"]?.int ?? 0,
                        seasonsPlayed: json["seasons_played"]?.int,
                        firstRoundOn: json["first_round_on"]?.string)
  }
}
