// Cup Season — THE TROPHY MARKS (Wave 3; `surfaces/profile.md` §9,
// `UI_SYSTEM` §5.2).
//
// **Two achievements may never share a glyph.** The shipped display case
// draws 🏆 for every piece of hardware and eight emoji for the milestones —
// and 🎯 twice (broke 100, broke 90), 📈 twice (four weeks, eight weeks),
// each pair under a subtitle that differs by one word. Two different things
// wearing one mark is the defect; emoji are only how it got there.
//
// So the case is drawn, in the family every other glyph in the product is
// drawn in — **1.7pt on a 24 × 24 box, round caps, no fill, `ink` in both
// themes** — and where two achievements are the same SHAPE at different
// values, the value is set in the board face inside the mark. `80` struck
// through and `90` struck through are two glyphs, not one glyph twice.
//
// **None of them is the pennant** (`LINT-28`): the Tracer's flag is
// `CSTabBand` and the app icon and nothing else, and the first draft of the
// Record page put it on LOW ROUND OF THE SEASON with the Compete tab's
// identical flag 400pt below it in the same viewport.
//
// **And none of them is an arrow.** ▼/▲ has exactly one meaning in this
// product and it is movement on a table (§9.3, DD-02), so MOST IMPROVED takes
// ascending stepped bars — which is one stroke from the drawn card, and reads
// as a scorecard rather than as a stock ticker.

import SwiftUI

/// One drawn mark for one thing a golfer did. The KEY is the Kit's
/// (`TrophyMeta.glyph`), so both clients name the same mark for the same
/// achievement and neither invents one.
public struct CSTrophyMark: View {
  @Environment(\.cs) private var cs

  /// The marks, by the Kit's key. A key this build does not know draws
  /// `medal` — a real mark rather than a blank, because a case with a hole in
  /// it reads as a rendering fault.
  public enum Mark: String, CaseIterable, Sendable {
    /// silverware you can hold — a league Cup, a major, an event
    case cup
    /// a season won on the TABLE — the filled disc on a rail (§9), which
    /// ladders to the rank rail rather than to a second piece of hardware
    case crown
    /// the Ryder — two discs facing across one rule
    case duel
    /// a knockout — the bracket itself
    case bracket
    /// second — the open disc, one notch down the rail
    case runnerUp
    /// the low round of a season — a numeral over a 2pt rule, which is the
    /// rule-and-figure signature at 28pt
    case lowRound
    /// most improved — three ascending stepped bars, NEVER an arrow
    case improved
    /// the first card — a tee with a ball on it
    case firstCard
    /// broke 100 / 90 / 80 — the number, crossed
    case threshold
    /// a personal best — the rule, and the slot that dropped below it
    case personalBest
    /// a run of weeks — the ticks, counted
    case streak
    /// every week of the season — the run, doubled and stopped at both ends
    case ironman
    /// anything this build does not know a mark for
    case medal
  }

  let mark: Mark
  /// The value inside a parametric mark — the gross for `lowRound`, the
  /// threshold for `threshold`, the week count for `streak`. Ignored by the
  /// marks that are pure drawings.
  let numeral: String?
  let size: CGFloat
  /// The mark's own accessibility name, in the product's words.
  let spoken: String

  public init(_ key: String, numeral: String? = nil, size: CGFloat = 28, spoken: String = "") {
    self.mark = Mark(rawValue: key) ?? .medal
    self.numeral = numeral
    self.size = size
    self.spoken = spoken
  }

  public var body: some View {
    Group {
      switch mark {
      case .lowRound: lowRoundMark
      case .threshold: thresholdMark
      case .streak: streakMark(min(Int(numeral ?? "") ?? 4, 8))
      case .ironman: streakMark(6, doubled: true)
      case .improved: improvedMark
      case .crown: crownMark
      case .duel: duelMark
      case .runnerUp: runnerUpMark
      case .personalBest: bestMark
      default: stroked(path)
      }
    }
    .frame(width: size, height: size)
    .foregroundStyle(cs.ink)
    .accessibilityHidden(spoken.isEmpty)
    .accessibilityLabel(spoken)
  }

  // MARK: - the pure drawings

  /// `cup`, `bracket`, `firstCard`, `medal` — one path each, in the family.
  private var path: String {
    switch mark {
    case .bracket:  "M3.5 5.5h5v13h-5M20.5 5.5h-5v13h5M8.5 12h7"
    case .firstCard: "M12 4.4a2.6 2.6 0 100 5.2 2.6 2.6 0 000-5.2M12 10.4v6M9.6 20.4l2.4-4 2.4 4"
    case .medal:    "M12 3.4a5.2 5.2 0 100 10.4 5.2 5.2 0 000-10.4M8.6 13.2L7 21l5-2.4 5 2.4-1.6-7.8"
    default:        "M7 4h10v4.2a5 5 0 01-10 0zM7 5.6H4.4v1.8a3.4 3.4 0 003.2 3.4M17 5.6h2.6v1.8a3.4 3.4 0 01-3.2 3.4M12 13.2v4.4M8.4 20.4h7.2M9.6 17.6h4.8v2.8H9.6z"
    }
  }

  private func stroked(_ d: String) -> some View {
    let scale = size / 24
    return SVGPath.path(d)
      .applying(CGAffineTransform(scaleX: scale, y: scale))
      .stroke(style: StrokeStyle(lineWidth: 1.7 * scale, lineCap: .round, lineJoin: .round))
  }

  // MARK: - the marks that carry a value

  /// **A rule under a numeral** — the product's own signature at 28pt, which
  /// is why a low round takes it. The second hairline under the heavy rule is
  /// what tells it apart from a figure that happens to be small.
  private var lowRoundMark: some View {
    VStack(spacing: size * 0.09) {
      Text(numeral ?? "—").csType(.figureS).csTabular()
        .minimumScaleFactor(0.5).lineLimit(1)
      Rectangle().frame(height: max(1.6, size * 0.07))
      Rectangle().frame(height: 1).opacity(CSTokens.Alpha.a56)
    }
    .frame(width: size)
  }

  /// **The number, crossed** — a threshold a golfer went under. The rule runs
  /// through the numeral rather than beneath it, so it can never be mistaken
  /// for the rule-and-figure above.
  private var thresholdMark: some View {
    Text(numeral ?? "—").csType(.figureS).csTabular()
      .minimumScaleFactor(0.5).lineLimit(1)
      .overlay { Rectangle().frame(height: max(1.6, size * 0.06)) }
      .frame(width: size)
  }

  /// **The ticks, counted.** Four weeks and eight weeks are two marks because
  /// they are four ticks and eight ticks — the count IS the difference, which
  /// is the one thing 📈 twice could never say.
  private func streakMark(_ n: Int, doubled: Bool = false) -> some View {
    let count = max(2, n)
    return VStack(spacing: size * 0.16) {
      run(count)
      if doubled { run(count) }
    }
    .frame(width: size, height: size)
  }

  private func run(_ n: Int) -> some View {
    GeometryReader { g in
      let gap = max(1, g.size.width * 0.055)
      let w = (g.size.width - gap * CGFloat(n - 1)) / CGFloat(n)
      HStack(spacing: gap) {
        ForEach(0..<n, id: \.self) { _ in
          Rectangle().frame(width: w)
        }
      }
    }
    .frame(height: size * 0.3)
  }

  /// **Ascending stepped bars, never an arrow** (§9.3, DD-02). One stroke from
  /// the drawn card, which is the point: improvement is a scorecard fact.
  private var improvedMark: some View {
    GeometryReader { g in
      let w = g.size.width * 0.24
      let gap = g.size.width * 0.14
      HStack(alignment: .bottom, spacing: gap) {
        Rectangle().frame(width: w, height: g.size.height * 0.32)
        Rectangle().frame(width: w, height: g.size.height * 0.62)
        Rectangle().frame(width: w, height: g.size.height * 0.94)
      }
      .frame(width: g.size.width, height: g.size.height, alignment: .bottom)
    }
  }

  /// **A filled disc on a rail** — a season won on the table. It ladders to
  /// `CSRankRail`, so the mark for finishing first is made of the same two
  /// shapes the board draws first place with.
  private var crownMark: some View {
    VStack(spacing: size * 0.14) {
      Circle().frame(width: size * 0.42, height: size * 0.42)
      Rectangle().frame(height: max(1.6, size * 0.07))
      Rectangle().frame(height: 1).opacity(CSTokens.Alpha.a56)
    }
    .frame(width: size)
  }

  /// Second — the same rail, the open disc, one notch down.
  private var runnerUpMark: some View {
    VStack(spacing: size * 0.14) {
      Circle().stroke(lineWidth: max(1.4, size * 0.06))
        .frame(width: size * 0.42, height: size * 0.42)
      Rectangle().frame(height: 1).opacity(CSTokens.Alpha.a56)
      Rectangle().frame(height: max(1.6, size * 0.07))
    }
    .frame(width: size)
  }

  /// The Ryder — two discs facing across one rule.
  private var duelMark: some View {
    HStack(spacing: 0) {
      Circle().frame(width: size * 0.34, height: size * 0.34)
      Rectangle().frame(height: max(1.4, size * 0.06))
      Circle().stroke(lineWidth: max(1.4, size * 0.06))
        .frame(width: size * 0.34, height: size * 0.34)
    }
    .frame(width: size)
  }

  /// A personal best — the rule, and the slot that dropped below it. No
  /// arrow, and no second numeral: the row's own sub-line carries the figure.
  private var bestMark: some View {
    VStack(alignment: .trailing, spacing: size * 0.16) {
      Rectangle().frame(height: max(1.6, size * 0.07))
      Rectangle().frame(width: size * 0.3, height: size * 0.3)
    }
    .frame(width: size, alignment: .trailing)
  }
}
