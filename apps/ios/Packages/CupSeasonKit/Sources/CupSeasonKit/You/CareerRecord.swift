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
  public let seasonsDone: Int

  public static let moneyNote = "What your friends settled with you. " + MoneyCopy.ledger

  /// "Settled across 3 seasons" — nil when nothing was settled.
  public var moneyLine: (amount: String, sub: String)? {
    guard earningsCents > 0 else { return nil }
    return (CSCopy.dollars(cents: earningsCents), "Settled across \(seasonsDone) season\(seasonsDone == 1 ? "" : "s")")
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
    return CareerRecord(items: items, earningsCents: json["earnings_cents"]?.int ?? 0, seasonsDone: json["seasons_done"]?.int ?? 0)
  }
}
