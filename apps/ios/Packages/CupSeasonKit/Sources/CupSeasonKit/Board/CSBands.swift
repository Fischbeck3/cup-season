// Cup Season — the named bands (spec §2.2's Read column; D1/D2).
//
// Ported VERBATIM from index.html 5566–5600: `pointsFor`, `bandName`,
// `vsPhrase`, `theirs`, `fn1`. PvI stays the engine currency; the SCREEN says
// "your number". Nothing here is authoritative — the server's `cup_points`
// scores the round; this only phrases it.
//
// The −1.0 edge, RESOLVED 2026-08-29 (Q-20). This file used to follow the
// server for the number while keeping the web's `>= -1` for the NAME, so a
// round at exactly −1.0 scored 6 and was called "Played to it" — the 7-point
// band's name. The web has since been corrected to the engine's half-open
// rule, so all three (points, band name, phrase) now read `> -1` on both
// clients and in `cup_points`. db-checks 17 pins the engine.

import Foundation

public enum CSBands {
  /// `public.cup_points(p_pvi numeric)` — the server rule, verbatim.
  public static func cupPoints(_ pvi: Double) -> Int {
    if pvi >= 3 { return 12 }
    if pvi >= 1 { return 9 }
    if pvi > -1 { return 7 }
    if pvi >= -3 { return 6 }
    return 5
  }

  /// The web's `pointsFor(vs)` → [points, sentence]. Points come from the
  /// server rule (see the −1.0 note above); the sentence is the web's, chosen
  /// to agree with that number.
  public static func pointsFor(_ vs: Double) -> (points: Int, line: String) {
    let pts = cupPoints(vs)
    switch pts {
    case 12: return (12, "You torched your number by \(fixed1(vs)). Sandbagger alert.")
    case 9: return (9, "You beat your number by \(fixed1(vs)). Nice round.")
    case 7: return (7, "Right on your number. Steady points.")
    case 6: return (6, "A little loose, still cash in the bank.")
    default: return (5, "Rough one, but posted rounds always score.")
    }
  }

  /// Torched it / Beat your number / Played to it / A little loose / Posted anyway.
  public static func bandName(_ vs: Double) -> String {
    if vs >= 3 { return "Torched it" }
    if vs >= 1 { return "Beat your number" }
    if vs > -1 { return "Played to it" }   // Q-20: half-open, matching cup_points
    if vs >= -3 { return "A little loose" }
    return "Posted anyway"
  }

  public static func vsPhrase(_ v: Double?) -> String {
    guard let vs = v, vs.isFinite else { return "" }
    if vs >= 1 { return "beat your number by \(fixed1(vs))" }
    if vs > -1 { return "played to your number" }   // Q-20
    return fixed1(vs).replacingOccurrences(of: "-", with: "") + " over your number"
  }

  /// Third-person form for SOMEONE ELSE's round. Always they/them — never a
  /// pronoun guessed from a name.
  public static func theirs(_ s: String?) -> String {
    (s ?? "")
      .replacingOccurrences(of: "YOUR", with: "THEIR")
      .replacingOccurrences(of: "Your", with: "Their")
      .replacingOccurrences(of: "your", with: "their")
  }

  /// D77 · first names leave the app, full names stay in it. Never empties.
  public static func fn1(_ n: String?) -> String {
    let first = (n ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      .split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? ""
    return first.isEmpty ? "Someone" : first
  }

  /// JS `Number.toFixed(1)`: one decimal, half away from zero.
  public static func fixed1(_ v: Double) -> String {
    let r = (v * 10).rounded(.toNearestOrAwayFromZero) / 10
    let s = String(format: "%.1f", r)
    return s == "-0.0" ? "0.0" : s
  }

  /// The PvI chip: `+1.4` / `-2.2` (index.html 5266).
  public static func pviChip(_ pvi: Double) -> String {
    (pvi >= 0 ? "+" : "") + fixed1(pvi)
  }
}
