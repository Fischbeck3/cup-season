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
    "It leaves your rounds and any season standings it counted toward. This cannot be undone."
  /// L-32 · a failed write says so in the golfer's words, never with a code.
  public static let deleteFailed = "That didn’t delete. Check your signal and try again."

  // MARK: - D293 · a photograph on a round you already posted

  /// **The six sentences of the round photograph, and both clients read them
  /// here** (D234). The owner posted a round and could not go back to
  /// photograph it, because `post_round`'s `p_photo_path` was the only path a
  /// photograph had ever taken to a round. The act now lives on the round's
  /// own receipt — the same place D284 put the delete, and the place a golfer
  /// looking at a round he posted already is.
  public static let photoAdd = "Add a photo"
  public static let photoReplace = "Replace photo"
  public static let photoRemove = "Remove photo"
  /// The armed half of the two-tap. Never an alert (IOS-003 §4).
  public static let photoRemoveArmed = "Sure?"

  /// **The honest pre-migration sentence**, in the form `csRateCourse` set
  /// ("Rated — the line needs the latest update."). The migration that
  /// creates `set_round_photo` is written and unpushed, so this is what every
  /// attempt reads today: it names the update in the house form (`CS_SHARE_NOT_YET`),
  /// never a code and never the push — "database push" is the builder's word
  /// (D297 class 5, W-17) — and the object the client had already uploaded is
  /// taken back out before the golfer sees it.
  public static let photoNeedsPush =
    "Not attached — photos on a posted round need the latest update — try again shortly."
  /// L-32 again — a real failure (no signal, a refused upload, a round that is
  /// not yours) says so where the finger is.
  public static let photoFailed = "That photo didn’t attach. Check your signal and try again."
  public static let photoRemoveFailed = "That photo didn’t come off. Check your signal and try again."

  // MARK: - D294 · the card a round actually has

  /// **The five sentences of the round's own scorecard**, and both clients
  /// read them here (D234). The product draws a real card — the bone leaf with
  /// par and stroke index — in exactly one place, inside the course page. A
  /// ROUND, which is the object every surface opens, showed one number.
  public static let cardHead = "The card"
  /// The dateline when the round has its strokes but the cache cannot prove a
  /// par — a hand-typed course, an edited rating, a nine. It says what the
  /// card IS rather than apologising for what it is not (L-44).
  public static let cardStrokesOnly = "Hole by hole"
  /// The share. **The golfer who played the round sees the card first** — it is
  /// drawn on his own receipt, in his own theme, and this button renders the
  /// same object for everyone else. The settlement card's mistake, named in
  /// the audit as finding 9, was existing ONLY as a share PNG.
  public static let cardShare = "Share the card"
  public static let cardShareFailed = "That card didn’t render. Try again."

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
