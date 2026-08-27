// Cup Season — the named bands (spec §2.2's Read column), verbatim from
// index.html 5566–5600 (`pointsFor`, `bandName`, `vsPhrase`, `theirs`, `fn1`).
//
// PvI stays the engine currency; the SCREEN says "your number" (D1). This is
// display copy, never authority: the points a round is worth come from the
// server (`v_rounds_ranked` → `cup_points()`), and the phone only phrases them.
//
// ONE KNOWN SEAM, documented rather than hidden: the web's `pointsFor` says
// `vs >= -1 → 7`, but the server's `cup_points()` (baseline 247) says
// `p_pvi > -1 → 7`, so a round that lands EXACTLY −1.0 against your number is
// worth 6 on the books and 7 in this preview. `pointsFor` mirrors the client
// because it is a preview string; the receipt shows the server's figure.

import Foundation

public enum RoundCopy {
  /// The web's `pointsFor(vs)` — a preview (points, sentence) for the post
  /// composer's calc panel. See the −1.0 seam in the header.
  public static func pointsFor(_ vs: Double) -> (points: Int, line: String) {
    if vs >= 3 { return (12, "You torched your number by \(f1(vs)). Sandbagger alert.") }
    if vs >= 1 { return (9, "You beat your number by \(f1(vs)). Nice round.") }
    if vs >= -1 { return (7, "Right on your number. Steady points.") }
    if vs >= -3 { return (6, "A little loose, still cash in the bank.") }
    return (5, "Rough one, but posted rounds always score.")
  }

  /// `bandName(vs)` — the five named bands.
  public static func bandName(_ vs: Double) -> String {
    if vs >= 3 { return "Torched it" }
    if vs >= 1 { return "Beat your number" }
    if vs >= -1 { return "Played to it" }
    if vs >= -3 { return "A little loose" }
    return "Posted anyway"
  }

  /// `vsPhrase(vs)` — "beat your number by 2.4" / "played to your number" /
  /// "1.3 over your number". Empty when there is no finite number.
  public static func vsPhrase(_ vs: Double?) -> String {
    guard let vs, vs.isFinite else { return "" }
    if vs >= 1 { return "beat your number by \(f1(vs))" }
    if vs >= -1 { return "played to your number" }
    return f1(vs).replacingOccurrences(of: "-", with: "") + " over your number"
  }

  /// `theirs(s)` — third-person form for SOMEONE ELSE's round. Always
  /// they/them; never guess pronouns from a name.
  public static func theirs(_ s: String) -> String {
    s.replacingOccurrences(of: "YOUR", with: "THEIR")
      .replacingOccurrences(of: "Your", with: "Their")
      .replacingOccurrences(of: "your", with: "their")
  }

  /// `fn1(n)` — D77: first names leave the app, full names stay in it.
  /// Falls back rather than emptying.
  public static func firstName(_ n: String?) -> String {
    let first = (n ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      .split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? ""
    return first.isEmpty ? "Someone" : first
  }

  /// `sgn(v)` as the web writes it in a dozen places: `(v>=0?'+':'')+v.toFixed(1)`.
  public static func signed(_ v: Double) -> String { (v >= 0 ? "+" : "") + f1(v) }

  /// JS `Number(v).toFixed(1)`.
  public static func f1(_ v: Double) -> String { String(format: "%.1f", v) }
}
