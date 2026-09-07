// Cup Season — the named bands (spec §2.2's Read column), verbatim from
// index.html 5566–5600 (`pointsFor`, `bandName`, `vsPhrase`, `theirs`, `fn1`).
//
// PvI stays the engine currency; the SCREEN says "your playing HCP" (R-M,
// D260 — amending D1's noun for the COMPARISON only; the five bands stand).
// This is
// display copy, never authority: the points a round is worth come from the
// server (`v_rounds_ranked` → `cup_points()`), and the phone only phrases them.
//
// D210 · the band EDGES live in one place, `CSBands` (Q-20: half-open at −1.0,
// matching `cup_points`). This file used to carry its own `>= -1`, so a round
// at exactly −1.0 read "Played to it" here and scored 6 on the books; every
// producer below now reads through `CSBands`, and the seam is gone.

import Foundation

public enum RoundCopy {
  /// **Deleting a round, and what it costs** — one sentence, both clients.
  ///
  /// The desk has confirmed with these words since D57; the phone had no
  /// delete at all, so the sentence lived in a `confirm()` in `index.html` and
  /// nowhere a producer could hold it. It is here now, so the two clients
  /// cannot tell a golfer two different things about the same irreversible act.
  public static let deleteConsequence =
    "It leaves your card and any league standings it counted toward. This cannot be undone."
  /// L-32 · a failed write says so in the golfer's words, never with a code.
  public static let deleteFailed = "That didn’t delete. Check your signal and try again."

  /// The web's `pointsFor(vs)` — a preview (points, sentence) for the post
  /// composer's calc panel. The edges are `CSBands`' (D210).
  public static func pointsFor(_ vs: Double) -> (points: Int, line: String) { CSBands.pointsFor(vs) }

  /// `bandName(vs)` — the five named bands, edges from `CSBands`.
  public static func bandName(_ vs: Double) -> String { CSBands.bandName(vs) }

  /// `vsPhrase(vs)` — "beat your playing HCP by 2.4" / "played to your playing
  /// HCP" / "1.3 over your playing HCP". Empty when there is no finite figure.
  public static func vsPhrase(_ vs: Double?) -> String { CSBands.vsPhrase(vs) }

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

  // MARK: - Y-13 · the course label arrives already mangled

  /// Club acronyms. Every one is unpronounceable as a word, so a letter run
  /// that matches one case-insensitively can only be the acronym — which is
  /// what makes this list safe to apply without a dictionary behind it.
  private static let courseAcronyms: Set<String> = ["GC", "CC", "CG", "GCC", "TPC", "PGA", "USGA"]

  /// A course label as it should be READ — the acronyms in their own case,
  /// and every other character exactly as it was stored.
  ///
  /// The label is not ours and it is not consistent: GolfCourseAPI title-cases
  /// its club names upstream, so a picked course lands in `rounds.course_label`
  /// as "Arizona Biltmore Cc — Links · Copper" / "Palo Verde Gc · Back" while a
  /// hand-typed one keeps "Encanto GC" (all three verified in
  /// `20260830230000_course_key_and_backfill.sql:82-84`). There is no
  /// title-caser on the phone to turn off — the mangling is in the DATA — so
  /// the repair is the narrowest one that reads right: fix the acronyms, touch
  /// nothing else. Re-casing the whole string would break the hand-typed
  /// labels and every real name with a small word in it ("Lone Tree at the
  /// Ranch"), which is the bug one level up.
  public static func course(_ label: String?) -> String {
    guard let label, !label.isEmpty else { return "" }
    var out = "", run = ""
    func flush() {
      guard !run.isEmpty else { return }
      out += courseAcronyms.contains(run.uppercased()) ? run.uppercased() : run
      run = ""
    }
    for ch in label {
      if ch.isLetter { run.append(ch) } else { flush(); out.append(ch) }
    }
    flush()
    return out
  }
}
