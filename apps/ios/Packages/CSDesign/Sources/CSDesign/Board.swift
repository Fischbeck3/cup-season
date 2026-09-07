// Cup Season — the board (D267, UI_SYSTEM §9.1). The rank rail and the slat.
//
// THE FIXED COLUMNS TOTAL 214pt AND THE NAME IS THE ONLY FLEXIBLE ONE.
//   rail 44 · face 30 · s3 12 · [name, min-width 0] · gap+movement 58 · pts 50 · gutter 20
// That leaves 188pt for a name at the 402 measure and 161pt at 375 (the SE),
// which is the arithmetic every "keeps its width" claim in the surface specs
// was standing on without saying so. Derive from the measure; never hard-code.
//
// REVISED AFTER THE BLIND REVIEW. All three reviewers, independently, filed the
// twelve-row board's four truncated surnames (`PRIYA RAGHU…`, `BARTHOLOME…`) as
// the single most damaging defect in the set, and two proposed the same remedy:
//   1 · delta and gap share ONE 58pt right-aligned cell. They are both change
//       metrics, both half-empty at any field size, and separately they ate
//       ~130pt the name column needs.
//   2 · a held row prints ONE mark. `— —` reads as a rendering error.
//   3 · at a field of ten or more, EVERY row abbreviates the given name to an
//       initial before any name is truncated — per BOARD, not per row, so the
//       column keeps one grammar.
//   4 · the header row ships at EVERY field size, including the season page's.
//       One reviewer called the unlabelled `+4 / +9 / +12` column "the single
//       most confusing element in the set".

import SwiftUI

// MARK: - The rank rail

/// The 44pt left column carrying a two-digit tabular numeral. Radius 0.
///
/// Painted `gold` when the position was **earned**, `panel` when the row is
/// **yours**, unpainted otherwise. It is half the product's signature, and it
/// is also the origin of every arrival in motion — so layout and motion are
/// one idea rather than two.
public struct CSRankRail: View {
  @Environment(\.cs) private var cs
  public enum Field: Sendable { case earned, mine, none }
  let rank: Int
  let field: Field
  public init(_ rank: Int, field: Field) { self.rank = rank; self.field = field }

  /// Two digits with a leading zero, and **no ordinal**: the rail prints `01`,
  /// not `1ST`, so the one ordinal form in the product is never needed here.
  var text: String { rank < 10 ? "0\(rank)" : "\(rank)" }

  public var body: some View {
    Text(text)
      .csType(.figureM)
      .foregroundStyle(field == .none ? cs.mut : cs.panelInk)
      .frame(width: CSTokens.Space.rail)
      .frame(maxHeight: .infinity)
      .background(background)
      .csBudget(gold: field == .earned ? 1 : 0)
      .accessibilityHidden(true)
  }

  @ViewBuilder private var background: some View {
    switch field {
    case .earned: cs.gold
    case .mine: cs.panel
    case .none: Color.clear
    }
  }
}

/// The slat's column arithmetic, lifted out of the generic so it has ONE home
/// and a test can read it. `CSSlat` is generic over its trailing view, and a
/// generic type cannot hold a static stored property — which is a good reason
/// to keep the numbers somewhere a surface can cite them without instantiating
/// a row.
///
/// **The fixed columns total 214pt.** rail 44 · face 30 · `s3` 12 · change 58 ·
/// points 50 · `gutter` 20 — leaving **188pt** for a name at the 402 measure
/// and **161pt** at 375. Derive every fixed column from the measure; never
/// hard-code one.
public enum CSSlatMetrics {
  /// Body inset = rail 44 + `s3` 12 = 56 left.
  public static let railGap = CSTokens.Space.s3
  /// The merged change cell: the gap figure, then the movement mark.
  public static let changeWidth: CGFloat = 58
  public static let trailingWidth: CGFloat = 50
  public static let fixedColumns: CGFloat =
    CSTokens.Space.rail + CSFace.Size.slat.rawValue + railGap
    + changeWidth + trailingWidth + CSTokens.Space.gutter
  /// What is left for the name at a given screen width.
  public static func nameWidth(at measure: CGFloat) -> CGFloat { measure - fixedColumns }
}

// MARK: - The slat

/// The leaderboard row: full-bleed, one `rule` on its top edge, 50pt minimum.
public struct CSSlat<Trailing: View>: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize

  let rank: Int
  let field: CSRankRail.Field
  let face: CSFace.Model
  let name: String
  /// The sub-line is agate **in sentence case** and in the product's voice —
  /// "3 rounds · held", "1 of 4 counting · one short" — never *floor*, which is
  /// the schema's word.
  let sub: String
  /// A 4 × 14 swatch and the squad's NAME, rendered only when the season has
  /// squads. Colour is never the only channel, and the four squad marks are
  /// 1.58:1 apart, so the name is not decoration.
  let squad: (Color, String)?
  let movement: CSMovement.State?
  let gap: String?
  let trailing: Trailing

  public init(rank: Int, field: CSRankRail.Field, face: CSFace.Model,
              name: String, sub: String, squad: (Color, String)? = nil,
              movement: CSMovement.State?, gap: String?,
              @ViewBuilder trailing: () -> Trailing) {
    self.rank = rank; self.field = field; self.face = face
    self.name = name; self.sub = sub; self.squad = squad
    self.movement = movement; self.gap = gap; self.trailing = trailing()
  }

  public var body: some View {
    VStack(spacing: 0) {
      CSRule()
      A11yStack(spacing: 0, columnSpacing: CSTokens.Space.s2) {
        HStack(spacing: 0) {
          CSRankRail(rank, field: field)
          CSFace(face, size: .slat).padding(.leading, CSSlatMetrics.railGap)
          VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
            Text(name).csType(.name).foregroundStyle(cs.ink)
              .lineLimit(1).truncationMode(.tail)
            HStack(spacing: CSTokens.Space.s2) {
              if let squad {
                Rectangle().fill(squad.0).frame(width: 4, height: 14)
                Text(squad.1).csType(.agateS, caps: true).foregroundStyle(cs.mut)
              }
              Text(sub).csType(.agateS, caps: false).foregroundStyle(cs.mut)
                .lineLimit(1).truncationMode(.tail)
            }
          }
          .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
          .padding(.leading, CSSlatMetrics.railGap)
        }
        if !typeSize.isA11y { change }
        if !typeSize.isA11y {
          trailing.frame(width: CSSlatMetrics.trailingWidth, alignment: .trailing)
        }
      }
      // at the accessibility sizes the row becomes a column rather than
      // squeezing a two-digit figure against a name that no longer fits
      if typeSize.isA11y {
        HStack(spacing: CSTokens.Space.s3) {
          change
          Spacer(minLength: 0)
          trailing
        }
        .padding(.leading, CSTokens.Space.rail + CSSlatMetrics.railGap)
      }
    }
    .padding(.trailing, CSTokens.Space.gutter)
    .frame(minHeight: 50)
    .fixedSize(horizontal: false, vertical: true)
    // ONE VoiceOver element per row.
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(spoken)
  }

  /// **A held row prints ONE mark.** `— —` — an em dash for the gap beside a
  /// held bar for the delta — reads as a rendering error, so a leader with no
  /// gap and no movement prints the held bar alone.
  @ViewBuilder private var change: some View {
    HStack(spacing: CSTokens.Space.s2) {
      Spacer(minLength: 0)
      if let gap, !gap.isEmpty { Text(gap).csType(.columnM).foregroundStyle(cs.ink) }
      if let movement { CSMovement(movement) }
    }
    .frame(width: typeSize.isA11y ? nil : CSSlatMetrics.changeWidth, alignment: .trailing)
  }

  var spoken: String {
    var parts = ["\(CSOrdinal.spoken(rank))", name, sub]
    if let squad { parts.insert(squad.1, at: 2) }
    if let movement { parts.append(CSMovement(movement).spoken) }
    if let gap, !gap.isEmpty { parts.append("\(gap) back") }
    return parts.joined(separator: ". ")
  }
}

/// The one ordinal in the product, in the one place a screen reader needs words
/// rather than a suffix.
public enum CSOrdinal {
  /// `1` → `1ST`. Board 700, UPPERCASE, on the baseline — never raised.
  public static func suffix(_ n: Int) -> String {
    let t = n % 100
    if (11...13).contains(t) { return "TH" }
    switch n % 10 {
    case 1: return "ST"
    case 2: return "ND"
    case 3: return "RD"
    default: return "TH"
    }
  }
  static func spoken(_ n: Int) -> String { "\(n)\(suffix(n).lowercased())" }
}

// MARK: - The board

/// A column-head row + N slats + an optional cut.
public struct CSStandingsBoard<Row: View>: View {
  @Environment(\.cs) private var cs
  let count: Int
  let cut: String?
  let cutAfter: Int?
  let rows: (Int, Bool) -> Row

  /// `abbreviate` is decided per BOARD, not per row: at a field of ten or more
  /// EVERY given name goes to an initial, including the short ones, so the
  /// column keeps one grammar.
  public var abbreviateNames: Bool { count >= 10 }

  public init(count: Int, cut: String? = nil, cutAfter: Int? = nil,
              @ViewBuilder rows: @escaping (Int, Bool) -> Row) {
    self.count = count; self.cut = cut; self.cutAfter = cutAfter; self.rows = rows
  }

  public var body: some View {
    VStack(spacing: 0) {
      head
      ForEach(0..<count, id: \.self) { i in
        rows(i, abbreviateNames)
        if let cut, let cutAfter, i == cutAfter - 1 { CSCut(cut) }
      }
    }
  }

  /// `POS · GOLFER · GAP · PTS`, drawn on every table in the product — the
  /// season page's two-row board included.
  private var head: some View {
    HStack(spacing: 0) {
      Text("Pos").frame(width: CSTokens.Space.rail)
      Text("Golfer").frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, CSFace.Size.slat.rawValue + CSSlatMetrics.railGap * 2)
      Text("Gap").frame(width: CSSlatMetrics.changeWidth, alignment: .trailing)
      Text("Pts").frame(width: CSSlatMetrics.trailingWidth, alignment: .trailing)
    }
    .csType(.agateS, caps: true)
    .foregroundStyle(cs.mut)
    .padding(.trailing, CSTokens.Space.gutter)
    .padding(.bottom, CSTokens.Space.s2)
    .accessibilityHidden(true)
  }
}

/// The field's cut line inside a board: `CUT · TOP TWO PLAY THE CUP FINAL`.
public struct CSCut: View {
  @Environment(\.cs) private var cs
  let label: String
  public init(_ label: String) { self.label = label }
  public var body: some View {
    HStack(spacing: CSTokens.Space.s2) {
      Text(label).csType(.agateS, caps: true).foregroundStyle(cs.mut)
      Rectangle().fill(cs.rule).frame(height: CSTokens.Space.hair)
    }
    .padding(.leading, CSTokens.Space.rail)
    .padding(.vertical, CSTokens.Space.s2)
  }
}

// MARK: - The hole strip

/// 18 cells on one rule, marks only, each ≥20pt. A single ring or box per
/// cell — the strip states the shape of a round, it does not re-draw the card.
public struct CSHoleStrip: View {
  @Environment(\.cs) private var cs
  public struct Hole: Identifiable, Sendable {
    public let id: Int
    public let overPar: Int?
    public init(number: Int, overPar: Int?) { self.id = number; self.overPar = overPar }
  }
  let holes: [Hole]
  let current: Int?
  public init(holes: [Hole], current: Int? = nil) { self.holes = holes; self.current = current }

  public var body: some View {
    VStack(spacing: CSTokens.Space.s1) {
      HStack(spacing: 0) {
        ForEach(holes) { h in
          ZStack {
            if let o = h.overPar {
              CSScoreMark(o, numeral: nil, size: 20).foregroundStyle(cs.ink)
            }
            if h.id == current { Circle().fill(cs.brand).frame(width: 5, height: 5) }
          }
          .frame(minWidth: 20, maxWidth: .infinity, minHeight: 20)
        }
      }
      CSRule()
      HStack(spacing: 0) {
        ForEach(holes) { h in
          Text("\(h.id)").csType(.agateS, caps: true).foregroundStyle(cs.mut)
            .frame(minWidth: 20, maxWidth: .infinity)
        }
      }
    }
    .csBudget(ember: current == nil ? 0 : 1)
  }
}

// MARK: - The meeting tape

/// Ticks above and below one rule — **the viewer filled, the rival outlined**,
/// and one key line rather than a legend.
public struct CSTape: View {
  @Environment(\.cs) private var cs
  public struct Meeting: Identifiable, Sendable {
    public let id: Int
    /// true when the viewer won it.
    public let viewer: Bool
    public init(id: Int, viewer: Bool) { self.id = id; self.viewer = viewer }
  }
  let meetings: [Meeting]
  let key: String
  public init(meetings: [Meeting], key: String) { self.meetings = meetings; self.key = key }

  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      ZStack {
        Rectangle().fill(cs.rule).frame(height: CSTokens.Space.hair)
        HStack(spacing: CSTokens.Space.s1) {
          ForEach(meetings) { m in
            Rectangle()
              .fill(m.viewer ? cs.ink : Color.clear)
              .frame(width: 6, height: 14)
              .overlay(Rectangle().stroke(cs.ink, lineWidth: m.viewer ? 0 : 1.2))
              .offset(y: m.viewer ? -8 : 8)
          }
        }
      }
      .frame(height: 34)
      Text(key).csType(.agateS, caps: false).foregroundStyle(cs.mut)
    }
  }
}

// MARK: - The season calendar

/// The season's month/week clock: N week ticks with their month labels.
/// **Played `ink` · now `brand` · ahead `mut`** — countable, and unmistakably a
/// scorecard rather than a health bar. (`mut` played over `rule` ahead was
/// 2.66:1 dark and 2.30:1 light against each other in two bars of identical
/// size: the row's whole meaning rode one tone step below the threshold of
/// sight.) Supersedes `CSTickRow`.
public struct CSSeasonCalendar: View {
  @Environment(\.cs) private var cs
  let weeks: Int
  let played: Int
  let now: Int
  let months: [String]
  public init(weeks: Int, played: Int, now: Int, months: [String]) {
    self.weeks = weeks; self.played = played; self.now = now; self.months = months
  }
  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      HStack(spacing: 3) {
        ForEach(0..<weeks, id: \.self) { i in
          Rectangle()
            .fill(i == now ? cs.brand : (i < played ? cs.ink : cs.mut))
            .frame(maxWidth: .infinity, minHeight: 8)
        }
      }
      HStack(spacing: 0) {
        ForEach(Array(months.enumerated()), id: \.offset) { _, m in
          Text(m).csType(.agateS, caps: true).foregroundStyle(cs.mut)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
    .csBudget(ember: 1)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Week \(now + 1) of \(weeks)")
  }
}

// MARK: - The clash

/// Two faces facing across one rule-and-figure. **No boxes** — the clash is a
/// composition, not a pair of cards with a "vs" between them.
public struct CSClash<Figure: View>: View {
  @Environment(\.cs) private var cs
  let left: CSFace.Model
  let right: CSFace.Model
  let leftName: String
  let rightName: String
  let figure: Figure
  public init(left: CSFace.Model, leftName: String, right: CSFace.Model, rightName: String,
              @ViewBuilder figure: () -> Figure) {
    self.left = left; self.right = right
    self.leftName = leftName; self.rightName = rightName; self.figure = figure()
  }
  public var body: some View {
    HStack(alignment: .center, spacing: CSTokens.Space.s3) {
      VStack(spacing: CSTokens.Space.s2) {
        CSFace(left, size: .list)
        Text(leftName).csType(.agateS, caps: true).foregroundStyle(cs.mut).lineLimit(1)
      }
      figure.frame(maxWidth: .infinity)
      VStack(spacing: CSTokens.Space.s2) {
        CSFace(right, size: .list)
        Text(rightName).csType(.agateS, caps: true).foregroundStyle(cs.mut).lineLimit(1)
      }
    }
  }
}
