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
  @Environment(\.dynamicTypeSize) private var typeSize
  public enum Field: Sendable { case earned, mine, none }
  let rank: Int
  let field: Field
  /// **The rail paints its field and stands its numeral down.** A surface that
  /// animates the rank (`RankFlipText`, the split-flap) draws its own numeral
  /// over the rail; without this the rail's static numeral stays underneath and
  /// the two align invisibly at the reading sizes and **stack visibly at AX3**,
  /// which is how `02 / 02` reached a screenshot.
  let hidesNumeral: Bool
  public init(_ rank: Int, field: Field, hidesNumeral: Bool = false) {
    self.rank = rank; self.field = field; self.hidesNumeral = hidesNumeral
  }

  /// Two digits with a leading zero, and **no ordinal**: the rail prints `01`,
  /// not `1ST`, so the one ordinal form in the product is never needed here.
  var text: String { rank < 10 ? "0\(rank)" : "\(rank)" }

  public var body: some View {
    Text(hidesNumeral ? "" : text)
      .csType(.figureM)
      // Unpainted is a FIELD state, not an ink state: the numeral stays `ink`
      // so a rank reads as a figure. `mut` made every row but the leader's and
      // the viewer's read as a caption beside its own name.
      .foregroundStyle(field == .none ? cs.ink : cs.panelInk)
      .frame(width: CSTokens.Space.rail)
      // WAVE 10 · **the numeral sits with the name, not in the middle of a
      // grown row.** At the reading sizes the rail and the name are the same
      // height and centring is invisible; at AX3 the row grows to hold a
      // wrapped name and a spoken facts line, and a centred numeral floats
      // half a row below the name it belongs to — which is what the first AX3
      // photograph of this board showed. The rail keeps its 44pt width
      // either way (§16.3): it is the row's HEIGHT that grows.
      .frame(maxHeight: .infinity, alignment: typeSize.isA11y ? .top : .center)
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

  // MARK: derived from the measure (WAVE 10 · §16.3's 375pt paragraph)

  /// **The two numeric columns are a FRACTION of the measure, floored and
  /// capped**, rather than two constants cut against a 402pt artboard.
  ///
  /// 58 and 50 are 14.4% and 12.4% of 402. At 375 that is 54 and 46.5, which
  /// hands **7.5pt back to the name** — the difference between `PRIYA
  /// RAGHUNA…` and `PRIYA RAGHUNATHAN` on an SE, which is the row the blind
  /// review filed as the set's most damaging defect. The floors (46 · 44) are
  /// what `+12` beside a triangle and a two-digit total actually need; the
  /// caps hold the Max's extra 38pt in the NAME column, where it belongs,
  /// rather than inflating two columns that are already wide enough.
  public static func changeWidth(at measure: CGFloat) -> CGFloat {
    min(58, max(46, (measure * 0.144).rounded()))
  }
  public static func trailingWidth(at measure: CGFloat) -> CGFloat {
    min(50, max(44, (measure * 0.124).rounded()))
  }
  /// The form board's trailing column, on the same derivation. Its floor is
  /// what `BEAT YOUR NUMBER` needs on one line.
  public static func formTrailingWidth(at measure: CGFloat) -> CGFloat {
    min(120, max(104, (measure * 0.3).rounded()))
  }
  /// **The form board's trailing column is wider than the season board's, and
  /// it has to be.** It carries a signed figure at `figureS` with a band word
  /// beneath it — `BEAT YOUR NUMBER` is the longest of the five and it sets on
  /// ONE line or it is not a fixed slot (§4). 50pt would ellipsise four of the
  /// five bands; 120 fits the longest at the default size and the name column
  /// keeps 156 at the 402 measure, which is more than the season board's own
  /// row gives a name once the gap and the movement are on it.
  public static let formTrailingWidth: CGFloat = 120
  public static let fixedColumns: CGFloat =
    CSTokens.Space.rail + CSFace.Size.slat.rawValue + railGap
    + changeWidth + trailingWidth + CSTokens.Space.gutter
  /// What is left for the name at a given screen width — **with that width's
  /// own columns**, not with the 402 artboard's.
  public static func nameWidth(at measure: CGFloat) -> CGFloat {
    measure - (CSTokens.Space.rail + CSFace.Size.slat.rawValue + railGap * 2
               + changeWidth(at: measure) + trailingWidth(at: measure) + CSTokens.Space.gutter)
  }

  /// **Does this field of names fit the column it is being read in?**
  ///
  /// `MeStripLayout`'s model, applied to the board: measure the actual
  /// characters in the actual face at the size being read, and abbreviate the
  /// whole board's given names when the longest one does not fit. `count >= 10`
  /// stays as the floor — a big field keeps one grammar whatever the phone —
  /// and this is what catches the eight-row board on an SE, where the same
  /// eight rows fit perfectly on a Max.
  public static func abbreviates(names: [String], count: Int,
                                 measure: CGFloat, size: DynamicTypeSize) -> Bool {
    if count >= 10 { return true }
    guard !names.isEmpty, !size.isA11y else { return count >= 10 }
    let column = nameWidth(at: measure)
    guard column > 0 else { return false }
    return names.contains { CSAdvance.width($0, .name, size) > column }
  }
}

// MARK: - The slat

/// The leaderboard row: full-bleed, one `rule` on its top edge, 50pt minimum.
public struct CSSlat<Trailing: View>: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  /// WAVE 10 · the width this row is being READ at, injected by `csPage`. The
  /// two numeric columns are a fraction of it (§16.3); nothing here is cut
  /// against 402 any more.
  @Environment(\.csMeasure) private var measure

  let rank: Int
  let field: CSRankRail.Field
  /// **nil draws no disc**, and that is not a degrade — the season slat on a
  /// profile is a LEAGUE's row, not a person's, and a face there would seat
  /// the golfer beside their own position twice. Every row about a PERSON
  /// passes one; `CSFace` is still the only legal way to draw one (§6).
  let face: CSFace.Model?
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
  let variant: Variant
  /// **The row's own facts, in WORDS, for the accessibility sizes** (§16.3's
  /// slat row, and `leaderboard.md` §7 verbatim).
  ///
  /// At AX3 the column heads are hidden — a head that describes columns which
  /// are no longer on screen is worse than no head — so `+4 ▲1 15` becomes
  /// three unlabelled numerals with nothing anywhere on the page to say which
  /// is the gap and which is the total. That is what the first AX3 photograph
  /// of this board actually showed. With `axFacts` the row says it:
  /// `UP ONE SINCE SUN · 4 BACK · 15 POINTS`, from `Movement.long` and the
  /// surface's own producers, on one `CSClauseLine` that breaks rather than
  /// truncates. Empty keeps the shipped column reflow.
  let axFacts: [String]
  /// The rank is being animated over the rail by the surface; the rail paints
  /// its field and draws no numeral of its own.
  let railHidesNumeral: Bool
  let trailing: Trailing

  /// **Three shapes, one row.** The measurements are here rather than at the
  /// call sites so that "the same table at 2, 6 and 12 golfers" is a property
  /// of the component and not of whoever wrote the surface.
  public enum Variant: Sendable {
    /// The season board's row: 50pt, a 30pt face, a 50pt trailing column.
    case table
    /// **D-5 · the board's ONE second geometry, used once per table and only
    /// on rank 1.** 74pt against 50, a 38pt face against 30, and the caller
    /// sets the total at `figure` 40. It is not a card: no radius, no border,
    /// no fill, same rail, same columns — the leader's row is a beat taller
    /// and one metal apart, which is what "the current leader should visually
    /// matter" asks for without a container.
    case leader
    /// The Golfers board's row (§4): 60pt, a 38pt face, and a trailing column
    /// wide enough for the signed figure and its band word.
    case form
    var height: CGFloat { switch self { case .table: 50; case .leader: 74; case .form: 60 } }
    var face: CSFace.Size { self == .table ? .slat : .list }
    func trailingWidth(at measure: CGFloat) -> CGFloat {
      self == .form ? CSSlatMetrics.formTrailingWidth(at: measure)
                    : CSSlatMetrics.trailingWidth(at: measure)
    }
    /// **The form board's trailing column HUGS.** A fixed 120 sized every row
    /// to the longest band in the set — `BEAT THEIR NUMBER` — and starved the
    /// name column on the five rows that do not carry it, which is the same
    /// arithmetic that cut four surnames on the twelve-row board. Everything
    /// in the cell is right-flush to the margin either way, so the figures
    /// still line up down the page; what varies is how much of the row a long
    /// band takes, and it takes it from the row that has one.
    var trailingHugs: Bool { self == .form }
  }

  public init(rank: Int, field: CSRankRail.Field, face: CSFace.Model?,
              name: String, sub: String, squad: (Color, String)? = nil,
              movement: CSMovement.State?, gap: String?, variant: Variant = .table,
              axFacts: [String] = [], railHidesNumeral: Bool = false,
              @ViewBuilder trailing: () -> Trailing) {
    self.rank = rank; self.field = field; self.face = face
    self.name = name; self.sub = sub; self.squad = squad
    self.movement = movement; self.gap = gap; self.variant = variant
    self.axFacts = axFacts.filter { !$0.isEmpty }
    self.railHidesNumeral = railHidesNumeral
    self.trailing = trailing()
  }

  public var body: some View {
    VStack(spacing: 0) {
      CSRule()
      // **WAVE 10 · THE RAIL IS A SIBLING OF THE WHOLE ROW, NOT OF ITS FIRST
      // LINE.** §16.3 says the rail keeps its 44pt width and the row grows its
      // HEIGHT — and the shipped `A11yStack` grew the row by stacking a second
      // band UNDER the rail, so at AX3 the leader's gold field stopped
      // half-way down its own row and the viewer's `02` fell out of the bottom
      // of its white panel into `panelInk` on a dark ground, where it is
      // barely a numeral at all. One rail, one row, both sizes.
      // the columns sit on the row's centre line at the reading sizes, where
      // every cell is one line; at AX3 the row is three lines tall and every
      // column reads from the top, beside the name it belongs to
      HStack(alignment: typeSize.isA11y ? .top : .center, spacing: 0) {
        CSRankRail(rank, field: field, hidesNumeral: railHidesNumeral)
        if typeSize.isA11y {
          HStack(alignment: .top, spacing: 0) { faceAndName }
            .padding(.vertical, CSTokens.Space.s2)
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
          faceAndName
          // **A cell with nothing in it is not reserved.** D245 clause 5 puts
          // no movement and no gap on the friends board at all, and holding
          // 58pt open for two absent facts took the name column to 130pt and
          // ellipsised a sub-line that fits easily without it.
          if hasChange { change }
          if variant.trailingHugs {
            trailing.fixedSize(horizontal: true, vertical: false)
              .frame(minWidth: CSSlatMetrics.trailingWidth(at: measure), alignment: .trailing)
          } else {
            trailing.frame(width: variant.trailingWidth(at: measure), alignment: .trailing)
          }
        }
      }
    }
    // **PADDING AROUND A FULL-MEASURE CHILD WIDENS THE ROW.** The slat's own
    // `CSRule` claims the whole proposed width and the gutter is then ADDED to
    // it, so the row measures screen + 20. A vertical `ScrollView` CENTRES
    // content wider than itself, which shifts every block on the page left by
    // ten and runs the widest one off the right edge — invisible at the
    // reading sizes and unmissable at AX3. The frame re-clamps to the measure.
    .padding(.trailing, CSTokens.Space.gutter)
    .frame(maxWidth: .infinity, alignment: .leading)
    .frame(minHeight: variant.height)
    .fixedSize(horizontal: false, vertical: true)
    // ONE VoiceOver element per row.
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(spoken)
  }

  /// The face and the name block — the two columns that read the same way at
  /// every size. At the reading sizes they sit between the rail and the two
  /// numeric columns; at AX3 they are the row's first line and the facts set
  /// beneath them.
  @ViewBuilder private var faceAndName: some View {
    // the leader's wider face is absorbed by the flexible name column,
    // never by the change or points columns, which stay on their grid
    if let face { CSFace(face, size: variant.face).padding(.leading, CSSlatMetrics.railGap) }
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      Text(name).csType(.name).foregroundStyle(cs.ink)
        .lineLimit(typeSize.isA11y ? 3 : 1).truncationMode(.tail)
        .fixedSize(horizontal: false, vertical: typeSize.isA11y)
      HStack(spacing: CSTokens.Space.s2) {
        if let squad {
          // **A squad's OWN row takes the 6 × 30 bar; a golfer's row in a
          // squads season takes the 4 × 14 swatch and the squad's name.**
          // An empty name is the tell: the row is already called by the
          // squad, so the bar stands alone and stands taller.
          Rectangle().fill(squad.0)
            .frame(width: squad.1.isEmpty ? 6 : 4, height: squad.1.isEmpty ? 30 : 14)
          if !squad.1.isEmpty {
            // sentence case and a middot, because `Mudsharks · held four
            // weeks` is one phrase and not a label beside a phrase — and
            // the name never shrinks to `MUDS`, which is what a flexible
            // label did the first time this shipped.
            Text(squad.1 + " \u{00B7}").csType(.agateS, caps: false).foregroundStyle(cs.mut)
              .lineLimit(1).fixedSize(horizontal: true, vertical: false)
          }
        }
        Text(sub).csType(.agateS, caps: false).foregroundStyle(cs.mut)
          .lineLimit(typeSize.isA11y ? 2 : 1).truncationMode(.tail)
          .fixedSize(horizontal: false, vertical: typeSize.isA11y)
      }
      // §16.3 · at AX3 the move, the gap and the points move **under the
      // name** — inside its own block, so they read as this golfer's three
      // facts rather than as a second row indented to the rail.
      if typeSize.isA11y {
        if !axFacts.isEmpty {
          CSClauseLine(axFacts, role: .agateS, caps: true, colour: cs.mut)
            .padding(.top, CSTokens.Space.s1)
        } else {
          HStack(spacing: CSTokens.Space.s3) {
            if hasChange { change }
            trailing
            Spacer(minLength: 0)
          }
          .padding(.top, CSTokens.Space.s1)
        }
      }
    }
    .padding(.leading, CSSlatMetrics.railGap)
    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
  }

  /// **A held row prints ONE mark.** `— —` — an em dash for the gap beside a
  /// held bar for the delta — reads as a rendering error, so a leader with no
  /// gap and no movement prints the held bar alone.
  private var hasChange: Bool { movement != nil || (gap?.isEmpty == false) }

  @ViewBuilder private var change: some View {
    // **The gap never wraps.** `+12` beside a movement mark measured 58.4 in a
    // 58pt cell and broke as `+1 / 2` — a two-digit gap printed as two numbers,
    // which is the one thing a change column may never do. The mark and the
    // figure keep their own widths; the SPACING gives way.
    HStack(spacing: CSTokens.Space.s1) {
      // the cell is right-flush in a COLUMN; at the accessibility sizes there
      // is no column and the line reads from the margin like everything else
      if !typeSize.isA11y { Spacer(minLength: 0) }
      if let gap, !gap.isEmpty {
        Text(gap).csType(.columnM).foregroundStyle(cs.ink)
          .lineLimit(1).fixedSize(horizontal: true, vertical: false)
      }
      if let movement { CSMovement(movement) }
    }
    .frame(width: typeSize.isA11y ? nil : CSSlatMetrics.changeWidth(at: measure),
           alignment: typeSize.isA11y ? .leading : .trailing)
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
  @Environment(\.dynamicTypeSize) private var typeSize
  @Environment(\.csMeasure) private var measure
  let count: Int
  let cut: String?
  let cutAfter: Int?
  /// **The field's names, so the abbreviation is MEASURED** (WAVE 10, §16.3).
  /// Optional and additive: a caller that passes none keeps the count rule.
  let names: [String]
  let rows: (Int, Bool) -> Row

  /// `abbreviate` is decided per BOARD, not per row: at a field of ten or more
  /// EVERY given name goes to an initial, including the short ones, so the
  /// column keeps one grammar.
  ///
  /// **WAVE 10 · and also whenever the longest name in THIS field does not fit
  /// the name column at the width this board is being read at.** Eight rows
  /// that set perfectly on a Max truncated two surnames on an SE, because the
  /// threshold was a count and the column is a measure.
  public var abbreviateNames: Bool { count >= 10 }
  var abbreviatesHere: Bool {
    CSSlatMetrics.abbreviates(names: names, count: count, measure: measure, size: typeSize)
  }

  public init(count: Int, cut: String? = nil, cutAfter: Int? = nil, names: [String] = [],
              @ViewBuilder rows: @escaping (Int, Bool) -> Row) {
    self.count = count; self.cut = cut; self.cutAfter = cutAfter
    self.names = names; self.rows = rows
  }

  public var body: some View {
    VStack(spacing: 0) {
      // §3.1 · the heads name COLUMNS, and at the accessibility sizes there are
      // no columns — each row speaks its own facts instead. `POS` wrapping to
      // `PO / S` over a stacked row is a head describing a layout that is no
      // longer on screen.
      if !typeSize.isA11y { head }
      ForEach(0..<count, id: \.self) { i in
        rows(i, abbreviatesHere)
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
      Text("Gap").frame(width: CSSlatMetrics.changeWidth(at: measure), alignment: .trailing)
      Text("Pts").frame(width: CSSlatMetrics.trailingWidth(at: measure), alignment: .trailing)
    }
    .csType(.agateS, caps: true)
    .foregroundStyle(cs.mut)
    .padding(.trailing, CSTokens.Space.gutter)
    .padding(.bottom, CSTokens.Space.s2)
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityHidden(true)
  }
}

/// The field's cut line inside a board: `CUT · TOP TWO PLAY THE CUP FINAL`,
/// then a **2pt `ink` heavy rule** running to the margin.
///
/// **Never gold.** The shipped board drew a gold "Cut line · top 2 advance"
/// band, which spent the surface's one earned metal on a thing nobody has won
/// yet. And **never *advance***: the line says who plays.
///
/// The label is fixed and the RULE gives way, the same way a section head
/// works — a cut whose label wraps to two lines with a rule floating beside it
/// reads as a rendering error rather than as a line drawn across a field.
public struct CSCut: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let label: String
  public init(_ label: String) { self.label = label }
  public var body: some View {
    HStack(spacing: CSTokens.Space.s3) {
      Text(label).csType(.agateS, caps: true).foregroundStyle(cs.ink)
        .fixedSize(horizontal: !typeSize.isA11y, vertical: true).layoutPriority(1)
      if !typeSize.isA11y {
        Rectangle().fill(cs.ink).frame(height: 2).frame(maxWidth: .infinity)
      }
    }
    .frame(minHeight: 26)
    .padding(.leading, CSTokens.Space.rail)
    .padding(.trailing, CSTokens.Space.gutter)
    .padding(.top, CSTokens.Space.s2).padding(.bottom, CSTokens.Space.s2 - 2)
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityAddTraits(.isHeader)
  }
}

// MARK: - The hole strip

/// **Chart 4 (`UI_SYSTEM` §9.10), and the live sheet's signature.** 18 cells
/// across the measure at a ≥20pt pitch, one `rule` beneath them, and one agate
/// line under that: the KEY on the left, a caller's own line on the right.
///
/// **Single ring, dot, single box — and nothing else.** At a 20pt pitch an
/// eagle's double ring and a birdie's single ring are the same mark, so the
/// strip clamps to one; the double variants live on the card and the receipt
/// where §9.4 has the room. A par is a **4pt `ink` dot** rather than the
/// scorecard's empty cell, because an empty cell and an unplayed hole would be
/// the same picture on the one screen where the difference is the whole point.
///
/// **Unplayed is a 9 × 1 `mut` dash, never `rule`.** A `rule` bar sits at
/// 2.30:1 in the light printing and states nothing (§16.1), and this screen is
/// read in sunlight.
///
/// **The hole you are on carries a 2pt `brand` rule under its own cell** — the
/// strip's one ember mark, and it is a position rather than a colour-coded
/// status, so it survives being printed in grey.
///
/// **ONE VoiceOver element for the whole strip**, in the product's voice. A
/// caller that has the sentence passes it; without one the strip counts its own
/// marks rather than reading eighteen cells aloud.
public struct CSHoleStrip: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  public struct Hole: Identifiable, Sendable {
    public let id: Int
    /// nil = not played yet. A hole with no par on the payload is also nil:
    /// the strip refuses to assert a mark it cannot compute (N-3's degrade).
    public let overPar: Int?
    public init(number: Int, overPar: Int?) { self.id = number; self.overPar = overPar }
  }
  let holes: [Hole]
  let current: Int?
  /// The key — `○ under · • level · □ over` — drawn once beside the strip.
  /// The blind review filed its absence three times: squares, circles and dots
  /// had no legend anywhere in the product.
  let key: Bool
  /// The strip's own right-hand line, e.g. `YOUR CARD · 55 THRU 14`.
  let trailing: String?
  let spoken: String?

  public init(holes: [Hole], current: Int? = nil, key: Bool = true,
              trailing: String? = nil, spoken: String? = nil) {
    self.holes = holes; self.current = current
    self.key = key; self.trailing = trailing; self.spoken = spoken
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      cells
      CSRule()
      // the current hole's 2pt brand rule sits UNDER the strip's own rule, in
      // its cell's column — a tick on the axis, not a highlight on the mark
      HStack(spacing: 0) {
        ForEach(holes) { h in
          Rectangle().fill(h.id == current ? cs.brand : Color.clear)
            .frame(height: 2)
            .frame(minWidth: 20, maxWidth: .infinity)
        }
      }
      if key || trailing != nil { legend }
    }
    .csBudget(ember: current == nil ? 0 : 1)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(spokenLine)
  }

  private var cells: some View {
    HStack(spacing: 0) {
      ForEach(holes) { h in
        mark(h.overPar).frame(minWidth: 20, maxWidth: .infinity, minHeight: 22)
      }
    }
  }

  /// The clamp is the component's, not the caller's: a surface handed a −3 and
  /// asked to draw one ring would otherwise decide for itself what "capped"
  /// means, and the two live surfaces would drift.
  @ViewBuilder private func mark(_ overPar: Int?) -> some View {
    if let o = overPar {
      if o == 0 { Circle().fill(cs.ink).frame(width: 4, height: 4) }
      else { CSScoreMark(o < 0 ? -1 : 1, numeral: nil, size: 20).foregroundStyle(cs.ink) }
    } else {
      Rectangle().fill(cs.mut).frame(width: 9, height: 1)
    }
  }

  /// **The key, once, beside the strip.** Squares, circles and dots had no
  /// legend anywhere in the product and all three blind reviewers said so.
  ///
  /// At the accessibility sizes it becomes a COLUMN: three words that each want
  /// a fifth of the measure cannot share one row, and the first build of it
  /// printed `un / der`, `le / vel`, `ov / er` broken across three lines each.
  private var legend: some View {
    A11yStack(rowAlignment: .firstTextBaseline, spacing: CSTokens.Space.s3, columnSpacing: CSTokens.Space.s1) {
      if key {
        A11yStack(spacing: CSTokens.Space.s2, columnSpacing: CSTokens.Space.s1) {
          keyItem("under") { Circle().stroke(lineWidth: 1.7).frame(width: 13, height: 13) }
          keyItem("level") { Circle().fill(cs.ink).frame(width: 4, height: 4) }
          keyItem("over") { Rectangle().stroke(lineWidth: 1.7).frame(width: 12, height: 12) }
        }
      }
      if !typeSize.isA11y { Spacer(minLength: CSTokens.Space.s2) }
      if let trailing {
        Text(trailing).csType(.agateS, caps: false).foregroundStyle(cs.mut)
          .lineLimit(typeSize.isA11y ? nil : 1).truncationMode(.tail)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func keyItem<S: View>(_ word: String, @ViewBuilder _ shape: () -> S) -> some View {
    HStack(spacing: 4) {
      ZStack { shape() }.frame(width: 14, height: 14).foregroundStyle(cs.mut)
      Text(word).csType(.agateS, caps: false).foregroundStyle(cs.mut)
        .fixedSize(horizontal: true, vertical: false)
    }
  }

  /// The count, in the product's voice, when a caller has not written one.
  var spokenLine: String {
    if let spoken { return spoken }
    let played = holes.compactMap(\.overPar)
    guard !played.isEmpty else { return "No holes played yet." }
    let under = played.filter { $0 < 0 }.count
    let level = played.filter { $0 == 0 }.count
    let over = played.filter { $0 > 0 }.count
    var parts = ["Through \(played.count)"]
    if under > 0 { parts.append("\(under) under par") }
    if level > 0 { parts.append("\(level) at par") }
    if over > 0 { parts.append("\(over) over par") }
    if let current { parts.append("You are on \(current)") }
    return parts.joined(separator: ". ") + "."
  }
}

// MARK: - The meeting tape

/// **Chart 5 (§9.10), and the head-to-head's signature.** One 2pt `ink` rule
/// across the measure; every meeting is a tick — **above the rule if the
/// viewer won it, below if the rival did** — in chronological order, oldest
/// first, **the viewer's filled `ink` and the rival's outlined 1.7pt `mut`**.
/// A halved meeting is a flat `mut` bar centred on the rule, because a half
/// belongs to neither side and drawing it above or below would be a lie in
/// the one channel the graphic uses.
///
/// **NO LEGEND.** §9.10 bans a legend on a chart in the same breath as it
/// bans an axis, so the two row labels ride the tape's own right margin as
/// part of the graphic (they name the two rows, which is what an axis label
/// is — not a key mapping colour to meaning) and the section head carries the
/// order. Under it, one line: *"One square is one win."* — four words, filed
/// by the blind review, which is what turns an original graphic into an
/// unambiguous one.
///
/// **Countable, and colour-independent**: position and fill are the channels,
/// and neither is a hue. It is a *tally*, not a chart — no axis, no gridline,
/// no library.
public struct CSTape: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize

  public struct Meeting: Identifiable, Sendable {
    public let id: Int
    /// true = the viewer won it · false = the rival did · **nil = halved**,
    /// which is neither and is drawn as neither.
    public let viewer: Bool?
    public init(id: Int, viewer: Bool?) { self.id = id; self.viewer = viewer }
  }

  let meetings: [Meeting]
  /// The one key line. `"One square is one win."` — sentence case, `agateS`.
  let key: String
  /// The two row labels, which are the graphic's own axis labels rather than
  /// a legend. Pass `nil` to draw the tape bare.
  let rows: (mine: String, theirs: String)?
  /// The first and last dates, `agateS`, under the two ends of the rule.
  let dates: (first: String, last: String)?
  /// What VoiceOver says — **one element for the whole tape**, in the
  /// product's voice.
  let spoken: String

  public init(meetings: [Meeting], key: String,
              rows: (mine: String, theirs: String)? = nil,
              dates: (first: String, last: String)? = nil,
              spoken: String = "") {
    self.meetings = meetings; self.key = key; self.rows = rows
    self.dates = dates
    self.spoken = spoken.isEmpty ? key : spoken
  }

  /// **Every meeting gets an equal slot across the whole measure**, and the
  /// tick sits centred in it. Laying the ticks out at a fixed width with a
  /// fixed gap instead packs eleven meetings into the left two thirds and
  /// leaves the rule running on alone — which reads as a tape that stopped
  /// rather than a rivalry that is still going.
  ///
  /// 17 × 16 is the design's tick; it shrinks inside a crowded slot, never
  /// below 6, so a long rivalry stays ONE row. Two rows would be two
  /// chronologies on one page.
  func tickWidth(_ slot: CGFloat) -> CGFloat {
    max(6, min(17, slot - CSTokens.Space.s1))
  }

  /// One meeting's share of the measure — the tests' window onto the two
  /// lines of arithmetic that decide whether a long rivalry stays one row.
  func slotWidth(_ measure: CGFloat) -> CGFloat {
    meetings.isEmpty ? measure : measure / CGFloat(meetings.count)
  }
  func tick(_ measure: CGFloat) -> CGFloat { tickWidth(slotWidth(measure)) }
  /// What VoiceOver hears — one element for the whole tape.
  var spokenLabel: String { spoken }

  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      HStack(alignment: .center, spacing: CSTokens.Space.s3) {
        GeometryReader { g in
          ZStack(alignment: .leading) {
            Rectangle().fill(cs.ink).frame(height: 2)
            let slot = meetings.isEmpty ? g.size.width : g.size.width / CGFloat(meetings.count)
            HStack(alignment: .center, spacing: 0) {
              ForEach(meetings) { m in
                tick(m, width: tickWidth(slot)).frame(width: slot, alignment: .leading)
              }
            }
          }
          .frame(height: 46, alignment: .center)
        }
        .frame(height: 46)
        if let rows, !typeSize.isA11y {
          VStack(alignment: .trailing, spacing: 14) {
            Text(rows.mine).csType(.agateS, caps: true).foregroundStyle(cs.mut)
            Text(rows.theirs).csType(.agateS, caps: true).foregroundStyle(cs.mut)
          }
          .fixedSize()
        }
      }
      if let dates {
        HStack {
          Text(dates.first).csType(.agateS, caps: true).foregroundStyle(cs.mut)
          Spacer(minLength: CSTokens.Space.s3)
          Text(dates.last).csType(.agateS, caps: true).foregroundStyle(cs.mut)
        }
      }
      Text(key).csType(.agateS, caps: false).foregroundStyle(cs.mut)
    }
    // ONE element. Eleven ticks read one at a time is a golfer counting
    // squares out loud; the sentence is what the graphic means.
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(spoken)
  }

  @ViewBuilder private func tick(_ m: Meeting, width: CGFloat) -> some View {
    switch m.viewer {
    case .some(true):
      Rectangle().fill(cs.ink).frame(width: width, height: 16).offset(y: -12)
    case .some(false):
      Rectangle().fill(Color.clear).frame(width: width, height: 16)
        .overlay(Rectangle().stroke(cs.mut, lineWidth: 1.7))
        .offset(y: 12)
    case .none:
      // halved — centred on the rule, and it belongs to neither row
      Rectangle().fill(cs.mut).frame(width: width, height: 2)
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
  @Environment(\.dynamicTypeSize) private var typeSize

  /// One calendar month's share of the season: its label, how many of the
  /// season's weeks it counts, and — on the live month only — the days it has
  /// left. **The note is part of the object and costs no agate budget**: it is
  /// the graphic's own axis label, not a caption beside it (§1.2).
  public struct Month: Identifiable, Sendable, Equatable {
    public let label: String
    public let weeks: Int
    public let note: String?
    public let live: Bool
    public var id: String { label }
    public init(label: String, weeks: Int, note: String? = nil, live: Bool = false) {
      self.label = label; self.weeks = weeks; self.note = note; self.live = live
    }
  }

  let weeks: Int
  let played: Int
  /// Zero-based index of the live week. **Negative means nothing is live** —
  /// a complete season's ticks are all `mut`, because nothing is running.
  let now: Int
  let months: [Month]

  public init(weeks: Int, played: Int, now: Int, months: [Month]) {
    self.weeks = weeks; self.played = played; self.now = now; self.months = months
  }

  /// The legacy call (a bare list of month names, evenly divided) — kept so the
  /// developer harness and any surface that has not been re-cut still compiles.
  public init(weeks: Int, played: Int, now: Int, months: [String]) {
    self.init(weeks: weeks, played: played, now: now,
              months: CSSeasonCalendar.spread(months, over: weeks))
  }

  /// Divide `weeks` as evenly as possible across named months, remainder to the
  /// earliest — the same shape `PotMath.splitCents` gives money.
  static func spread(_ names: [String], over weeks: Int) -> [Month] {
    guard !names.isEmpty, weeks > 0 else { return [] }
    let base = weeks / names.count
    var rem = weeks - base * names.count
    return names.map { n in
      let w = base + (rem > 0 ? 1 : 0)
      if rem > 0 { rem -= 1 }
      return Month(label: n, weeks: max(1, w))
    }
  }

  /// The first week index each month group starts at.
  var starts: [Int] {
    var out: [Int] = []; var k = 0
    for m in months { out.append(k); k += m.weeks }
    return out
  }

  public var body: some View {
    // §3.1 · at the accessibility sizes ONE GROUP PER ROW, each a slat: the
    // month label leading, its ticks trailing. Thirteen ticks and three
    // wrapped labels on one row is a graphic nobody can read.
    if typeSize.isA11y {
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        ForEach(Array(months.enumerated()), id: \.element.id) { i, m in
          HStack(alignment: .bottom, spacing: CSTokens.Space.s3) {
            // **the label WRAPS here and the ticks keep their width.** At AX3
            // `SEP · 25 DAYS` is ~300pt of agate; held to one line beside its
            // ticks the row measured screen + 34, and a vertical `ScrollView`
            // CENTRES content wider than itself — so the whole season page
            // slid twenty points left and lost its gutter. The month clock was
            // the only block wide enough to do it, and only at AX3.
            label(m, wraps: true)
            Spacer(minLength: CSTokens.Space.s2)
            ticks(from: starts[i], count: m.weeks).layoutPriority(1)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(spoken)
    } else {
      HStack(alignment: .bottom, spacing: 14) {
        ForEach(Array(months.enumerated()), id: \.element.id) { i, m in
          VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
            ticks(from: starts[i], count: m.weeks)
            label(m)
          }
        }
      }
      .csBudget(ember: now >= 0 ? 1 : 0)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(spoken)
    }
  }

  /// The ticks of one month. **Played `mut` · now `brand` and 12pt tall ·
  /// ahead `rule`** — the live cell grows UPWARD from a shared baseline, so
  /// the row reads as a clock rather than as a bar with a bite out of it.
  private func ticks(from first: Int, count: Int) -> some View {
    HStack(alignment: .bottom, spacing: CSTokens.Space.s1) {
      ForEach(0..<max(0, count), id: \.self) { k in
        let i = first + k
        Rectangle()
          .fill(i == now ? cs.brand : (i < played ? cs.mut : cs.rule))
          .frame(maxWidth: 20)
          .frame(height: i == now ? 12 : 8)
      }
    }
  }

  @ViewBuilder private func label(_ m: Month, wraps: Bool = false) -> some View {
    let text = m.note.map { "\(m.label) · \($0)" } ?? m.label
    Text(text).csType(.agateS, caps: true)
      .foregroundStyle(m.live ? cs.brand : cs.mut)
      .lineLimit(wraps ? nil : 1)
      .fixedSize(horizontal: false, vertical: true)
  }

  var spoken: String {
    guard now >= 0 else { return "\(weeks) weeks, all played" }
    return "Week \(now + 1) of \(weeks), the live week"
  }
}

// MARK: - The clash

/// Two faces facing across one rule-and-figure. **No boxes** — the clash is a
/// composition, not a pair of cards with a "vs" between them.
public struct CSClash<Figure: View>: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let left: CSFace.Model
  let right: CSFace.Model
  let leftName: String
  let rightName: String
  /// The identity clause under a name — `10.6 index · Tempe` — in SENTENCE
  /// case, because it is a phrase and not a label, and so it costs none of the
  /// viewport's ten tracked-caps agate lines.
  let leftSub: String?
  let rightSub: String?
  let figure: Figure

  public init(left: CSFace.Model, leftName: String, right: CSFace.Model, rightName: String,
              leftSub: String? = nil, rightSub: String? = nil,
              @ViewBuilder figure: () -> Figure) {
    self.left = left; self.right = right
    self.leftName = leftName; self.rightName = rightName
    self.leftSub = leftSub; self.rightSub = rightSub
    self.figure = figure()
  }

  public var body: some View {
    // §6.8 · at the accessibility sizes the pair STACKS, full measure — two
    // 56pt faces and a 40pt figure do not share a 335pt line at AX3.
    if typeSize.isA11y {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        side(left, leftName, leftSub, .leading)
        figure
        side(right, rightName, rightSub, .leading)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    } else {
      HStack(alignment: .top, spacing: CSTokens.Space.s3) {
        side(left, leftName, leftSub, .leading)
        figure.frame(maxWidth: .infinity)
        side(right, rightName, rightSub, .trailing)
      }
    }
  }

  private func side(_ f: CSFace.Model, _ name: String, _ sub: String?,
                    _ align: HorizontalAlignment) -> some View {
    VStack(alignment: align, spacing: CSTokens.Space.s2) {
      CSFace(f, size: .block)
      Text(name).csType(.name).foregroundStyle(cs.ink).lineLimit(1).truncationMode(.tail)
      if let sub {
        Text(sub).csType(.agateS, caps: false).foregroundStyle(cs.mut).lineLimit(1)
      }
    }
    .accessibilityElement(children: .combine)
  }
}
