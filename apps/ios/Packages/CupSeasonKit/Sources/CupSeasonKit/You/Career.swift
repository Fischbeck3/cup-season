// Cup Season — the lifetime tiles and the form row (index.html `loadCareer`
// 16409–16449, `formRowHtml` 11140–11150).
//
// This is the ONE place the phone mirrors client-side math, because the web
// does it client-side too (audit 03 §9.1: "direct rounds select, client
// math"). It is labelled as such on the tile. IOS-016: "best" means the
// LOWEST DIFFERENTIAL here (the web's You tab said max PvI and its Tour Card
// said min differential; the phone uses one definition and says which).

import Foundation

public struct Career: Sendable, Equatable {
  public let rounds: Int
  /// IOS-016 — the lowest differential on the card. nil until a round has one.
  public let bestDifferential: Double?
  /// Mean of `index_at_post − differential` over rounds that have both.
  public let avgVsIndex: Double?
  /// `memberships.length + myEvents.length` — "Cups & events · Played in".
  public let played: Int
  /// The five newest rounds, with `beat` for the form row.
  public let recent: [RoundRow]

  public init(rounds: Int, bestDifferential: Double?, avgVsIndex: Double?, played: Int, recent: [RoundRow]) {
    self.rounds = rounds; self.bestDifferential = bestDifferential; self.avgVsIndex = avgVsIndex; self.played = played; self.recent = recent
  }

  /// `rows` newest first, as `myRounds` returns them.
  public static func compute(rows: [RoundRow], memberships: Int, events: Int) -> Career {
    let pvis = rows.compactMap(\.pvi)
    let diffs = rows.compactMap(\.differential)
    return Career(
      rounds: rows.count,
      bestDifferential: diffs.min(),
      avgVsIndex: pvis.isEmpty ? nil : pvis.reduce(0, +) / Double(pvis.count),
      played: memberships + events,
      recent: Array(rows.prefix(5)))
  }

  // the tile strings, as the web writes them (`sign(v)`)
  public var roundsText: String { String(rounds) }
  public var bestText: String { bestDifferential.map(RoundCopy.f1) ?? "—" }
  public var avgText: String { avgVsIndex.map(RoundCopy.signed) ?? "—" }
  public var playedText: String { String(played) }

  /// "n of 3" — the establishing meter (D3 "building, not broken").
  public static func establishing(rounds: Int) -> String { "\(min(max(rounds, 0), 3)) of 3" }
}

/// D76 — FORM L5: the card runs a temperature. Dots read oldest→newest; ember
/// = beat your number.
public struct FormRow: Sendable, Equatable {
  /// oldest → newest; true = beat the number, false = did not, nil = no number
  public let dots: [Bool?]
  /// consecutive `beat` rounds counted from the newest
  public let streak: Int

  public var tag: String? { streak >= 2 ? "\(streak) STRAIGHT UNDER" : nil }
  /// `heathot` at 3+, `heatwarm` at 2.
  public var hot: Bool { streak >= 3 }
  public var accessibilityLabel: String {
    "Form, last \(dots.count) rounds" + (streak >= 2 ? ", \(streak) straight under" : "")
  }

  /// `beats` newest first (the order every payload arrives in). Returns nil
  /// when there is nothing to draw — no rounds, or (the skew rule) no entry
  /// carries a `beat` verdict at all: "a payload whose entries carry NO `beat`
  /// key renders nothing at all — no row, no error."
  public static func from(beats: [Bool?]) -> FormRow? {
    let last5 = Array(beats.prefix(5))
    guard !last5.isEmpty, last5.contains(where: { $0 != nil }) else { return nil }
    var stk = 0
    for b in last5 { if b == true { stk += 1 } else { break } }
    return FormRow(dots: last5.reversed(), streak: stk)
  }
}
