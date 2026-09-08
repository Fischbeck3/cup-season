// Cup Season — `-cs_dev_round_card <full|nopar|noindex|nine>`: the four
// printings of the round's own card (D294 / IOS-067), over whatever round the
// receipt opened.
//
// WHY A HATCH RATHER THAN A REAL ROUND. Both halves of this card are, today,
// out of reach of a screenshot on this machine:
//
//   * `round_scorecard()` is WRITTEN AND UNPUSHED, so the par and the stroke
//     index — the whole reason the card is beautiful — cannot come back from
//     prod at all until the owner ships the migration.
//   * `round_holes` holds strokes for **6 of 214** rounds in prod, and none of
//     the owner's three are the round he was looking at when he said *"our
//     scorecard looks good."* The composer only writes them in holes mode.
//
// A change to a printed grid has to be LOOKED AT before it ships, so the four
// states are drawn. It overrides exactly one thing — the card — and nothing
// else on the receipt; the round, the figures, the photograph and the leaf
// stay the account's own. It writes nothing and does not exist in Release.
//
// **THE PARS AND THE STROKE INDEX ARE REAL.** They are Gold Canyon Dinosaur
// Mountain's Black tee, read out of `api_course_holes` in prod — the tee the
// owner's 2026-09-07 round pins to by rating and slope, which is the round he
// was holding when he asked for this. Par 70, 18 holes. The STROKES are a
// fixture: they add to 90, which is what that round posted, because the gross
// seal in `RoundScorecard` refuses a card whose columns do not sum to the
// number printed above them, and a hatch that walked past the seal would be
// photographing a state the product cannot reach.

#if DEBUG
import Foundation
import CupSeasonKit

enum RoundCardDev {
  /// `full`    · a pinned tee: par, the index and the round. Everything.
  /// `nopar`   · the migration is unpushed and `round_holes_of` answered —
  ///             the golfer's own numbers with a hole key over them.
  /// `noindex` · par agreed across the course's tees; the index did not
  ///             (31 of 87 courses agree on it, against 56 on par).
  /// `nine`    · nine holes and NO par, ever — nothing records which nine.
  static var mode: String? {
    let a = ProcessInfo.processInfo.arguments
    guard let i = a.firstIndex(of: "-cs_dev_round_card"), i + 1 < a.count else { return nil }
    return a[i + 1]
  }

  /// `-cs_dev_card_artifact` renders the SHARE PNG full-screen instead of
  /// handing it to `UIActivityViewController`, which `simctl` cannot open and
  /// cannot photograph. An artifact that leaves the app has to be looked at.
  static var artifact: Bool {
    ProcessInfo.processInfo.arguments.contains("-cs_dev_card_artifact")
  }

  /// Gold Canyon — Dinosaur Mountain, Black. 70.1 / 137, par 70.
  static let pars = [4, 3, 5, 4, 3, 4, 4, 3, 5, 3, 5, 4, 4, 3, 4, 5, 3, 4]
  static let sis  = [5, 15, 3, 1, 9, 11, 7, 13, 17, 16, 18, 12, 2, 6, 4, 14, 8, 10]
  /// 42 out, 48 in, 90 — the gross that round posted.
  static let strokes = [5, 4, 4, 6, 4, 5, 5, 3, 6, 5, 6, 5, 7, 4, 7, 4, 4, 6]

  static var card: RoundScorecard? {
    guard let mode else { return nil }
    switch mode {
    case "full":    return build(n: 18, par: true, index: true)
    case "noindex": return build(n: 18, par: true, index: false)
    case "nopar":   return build(n: 18, par: false, index: false)
    case "nine":    return build(n: 9, par: false, index: false)
    default:        return nil
    }
  }

  private static func build(n: Int, par: Bool, index: Bool) -> RoundScorecard {
    let holes = (1...n).map { h in
      RoundScorecardHole(hole: h,
                         par: par ? pars[h - 1] : nil,
                         si: index ? sis[h - 1] : nil,
                         strokes: strokes[h - 1])
    }
    let out = strokes[0..<min(9, n)].reduce(0, +)
    let inn = n == 18 ? strokes[9..<18].reduce(0, +) : nil
    return RoundScorecard(
      holesPlayed: n, holes: holes,
      teeName: par && index ? "Black" : nil,
      parSource: par ? (index ? .tee : .course) : nil,
      out: out, inn: inn, total: out + (inn ?? 0),
      parOut: par ? pars[0..<9].reduce(0, +) : nil,
      parIn: par && n == 18 ? pars[9..<18].reduce(0, +) : nil,
      parTotal: par ? pars[0..<n].reduce(0, +) : nil)
  }
}
#endif
