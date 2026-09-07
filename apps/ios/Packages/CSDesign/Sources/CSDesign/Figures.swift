// Cup Season — the rule-and-figure, the signature (D267, UI_SYSTEM §9.2).
//
// Numbers never wear a box; boxes wear numbers. Remove the logo and this
// device plus the rank rail still say Cup Season.
//
// The finding it answers: 38 sites typed a score into a sentence in the
// sentence's own face; the board's gross was 13pt grey mono while its points
// figure got 21pt and a red pill outranked both; a golfer's finishing position
// for a whole season was 11pt tracked caps under a generic flag. Ten
// renderings of the gross across six roles from 11pt to 64pt become THREE.

import SwiftUI

// MARK: - The rule-and-figure

/// A figure, a 2pt rule the width of its column, and an agate label beneath.
///
/// **A figure at 27 or above always carries the rule and the label** — with two
/// exceptions the system states rather than leaves to taste:
///
///   · a figure INSIDE A PANEL carries neither: the panel's own edge is the
///     rule, so its label sits directly under the numeral in `panelMut`;
///   · a figure REPEATING DOWN A TABLE'S TRAILING COLUMN carries neither, because
///     column position is already the hierarchy. Six rule-and-figures down one
///     list is six 2pt rules and eleven lines of ragged caps against one right
///     edge. The rule-and-figure is reserved for **a number that matters**,
///     which cannot be every row. Pass `label: nil` and you get the bare figure.
public struct CSFigure: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  @Environment(\.csInContainer) private var inContainer

  public enum Size: Sendable {
    case xl, l, m, s
    var role: CSType.Role {
      switch self {
      case .xl: .figureXL
      case .l: .figureL
      case .m: .figureM
      case .s: .figureS
      }
    }
    /// Below 27 a figure is a value in a column, not an object on a page.
    var carriesRule: Bool { self != .s }
  }

  public enum Metal: Sendable { case ink, live, earned }

  let value: String
  let size: Size
  let metal: Metal
  let label: String?
  /// `2ND`. Board 700, UPPERCASE, 0.44–0.46 em of the figure, tracked .05 em,
  /// **on the baseline** — never raised. At the sizes this product sets
  /// ordinals a raised suffix collides with the row above and reads as a
  /// footnote marker beside a number that is not a footnote.
  let ordinal: String?
  /// A figure drawn on a leaf or a ceremony object takes that object's ink.
  let over: CSRule.Ground

  public init(_ value: String, size: Size, metal: Metal = .ink,
              label: String?, ordinal: String? = nil, over: CSRule.Ground = .page) {
    self.value = value; self.size = size; self.metal = metal
    self.label = label; self.ordinal = ordinal; self.over = over
  }

  private var showsRule: Bool { label != nil && size.carriesRule && !inContainer }

  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      numeral
      if showsRule {
        CSRule(.heavy, metal: ruleMetal, over: over)
        if let label {
          Text(label).csType(.agateS, caps: true).foregroundStyle(labelInk)
        }
      } else if let label {
        // inside a panel: the label hangs straight off the numeral
        Text(label).csType(.agateS, caps: true).foregroundStyle(labelInk)
      }
    }
    .fixedSize(horizontal: false, vertical: true)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(label.map { "\(value)\(ordinal ?? ""), \($0)" } ?? "\(value)\(ordinal ?? "")")
    // §2.4 — the metals are scarce BY CONSTRUCTION, so the figure counts itself
    .csBudget(gold: metal == .earned ? 1 : 0, ember: metal == .live ? 1 : 0)
  }

  private var numeral: some View {
    let pt = CSType.renderedSize(size.role, typeSize)
    return HStack(alignment: .firstTextBaseline, spacing: 0) {
      Text(value).csType(size.role).foregroundStyle(figureInk)
      if let ordinal {
        Text(ordinal)
          .font(.custom(CSType.boardBold, fixedSize: max(11, pt * 0.45)))
          .tracking(max(11, pt * 0.45) * CSTokens.Track.ord)
          .textCase(.uppercase)
          .foregroundStyle(figureInk)
          .padding(.leading, pt * 0.05)
      }
    }
  }

  private var ruleMetal: CSRule.Metal {
    switch metal {
    case .ink: .ink
    case .live: .live
    case .earned: .earned
    }
  }

  /// **The figure itself is ink.** The metal is the RULE's, not the numeral's —
  /// money is `ink` and the sign is a word (D273), a points total is ink and
  /// only the leader's is gold, and a course's rating is ink because an average
  /// of opinions is not earned.
  private var figureInk: Color {
    switch over {
    case .page: metal == .earned ? cs.gold : cs.ink
    case .leaf: cs.leafInk
    case .panel: metal == .earned ? CSTokens.light.gold : cs.panelInk
    case .ceremony: CSTokens.dark.ceremonyInk
    }
  }

  private var labelInk: Color {
    switch over {
    case .page: cs.mut
    case .leaf: cs.leafMut
    case .panel: cs.panelMut
    case .ceremony: CSTokens.dark.ceremonyMut
    }
  }
}

// MARK: - The figure run

/// A numeral set in the board face **inside a sentence**, so the number is
/// always in the number's voice: "Best: **84**, Tash."
///
/// **The producer marks the run. There is no regex.** A regex over prose also
/// restyles dates, money, ordinals and any digit inside a course name — and it
/// rewrites the `AttributedString` runs VoiceOver reads, which is the part
/// nobody notices until a golfer using VoiceOver hears a sentence in pieces.
public struct CSFigureRun: View {
  @Environment(\.dynamicTypeSize) private var typeSize
  let text: String
  let runs: [Range<String.Index>]
  let role: CSType.Role

  /// `"Galen shot {74} at Papago"` — the braces are the producer's mark and
  /// never render.
  public init(_ marked: String, role: CSType.Role = .body) {
    var body = ""
    var found: [Range<String.Index>] = []
    var open: String.Index?
    for ch in marked {
      if ch == "{" { open = body.endIndex; continue }
      if ch == "}" {
        if let o = open { found.append(o..<body.endIndex) }
        open = nil
        continue
      }
      body.append(ch)
    }
    self.text = body; self.runs = found; self.role = role
  }

  public init(_ text: String, runs: [Range<String.Index>], role: CSType.Role = .body) {
    self.text = text; self.runs = runs; self.role = role
  }

  public var body: some View {
    Text(attributed)
  }

  /// The board face at the SENTENCE's own size, so the run sits on the
  /// sentence's baseline rather than looking pasted in.
  var attributed: AttributedString {
    var s = AttributedString(text)
    let pt = CSType.renderedSize(role, typeSize)
    for r in runs {
      guard let lower = AttributedString.Index(r.lowerBound, within: s),
            let upper = AttributedString.Index(r.upperBound, within: s) else { continue }
      s[lower..<upper].font = .custom(CSType.boardBold, fixedSize: pt)
    }
    return s
  }
}

// MARK: - Movement

/// A drawn triangle and a tabular numeral, **on the page's own ground**. No
/// field, no pill, no tint behind it.
///
/// **▼ has exactly one meaning: you fell.** A falling handicap index is good
/// news and does not get this mark; the producer that emitted ▼ for it is
/// changed at the producer, not decorated here.
public struct CSMovement: View {
  @Environment(\.cs) private var cs
  public enum State: Equatable, Sendable { case up(Int), down(Int), held }
  /// **A movement mark inside a panel is on BONE, in both themes.**
  ///
  /// The panel is the opposite of the page by construction, so the page's own
  /// `ink` numeral would be near-white on bone in charcoal — invisible — and
  /// the dark theme's `pos` is a bright green cut for a dark ground. Both take
  /// the panel's own values, and the triangle takes the LIGHT green for the
  /// same reason `CSRule` gives an earned rule on a leaf the light gold: a
  /// bone tile is a light surface whichever room it is standing in.
  public enum Ground: Sendable { case page, panel }
  let state: State
  let over: Ground
  public init(_ state: State, over: Ground = .page) { self.state = state; self.over = over }

  private var numeralInk: Color { over == .panel ? cs.panelInk : cs.ink }

  public var body: some View {
    HStack(spacing: CSTokens.Space.s1) {
      mark
      if case .up(let n) = state { Text("\(n)").csType(.figureS).foregroundStyle(numeralInk) }
      if case .down(let n) = state { Text("\(n)").csType(.figureS).foregroundStyle(numeralInk) }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(spoken)
  }

  @ViewBuilder private var mark: some View {
    switch state {
    case .up:
      CSTriangle(up: true)
        .fill(over == .panel ? CSTokens.light.pos : cs.pos).frame(width: 9, height: 7)
    case .down:
      CSTriangle(up: false)
        .fill(over == .panel ? CSTokens.light.cool : cs.cool).frame(width: 9, height: 7)
    // `mut`, never `rule`: at 2pt and 2.30:1 in light a `rule` bar is neither
    // a shape nor visible, and "held" becomes indistinguishable from "no data".
    case .held:
      Rectangle().fill(over == .panel ? cs.panelMut : cs.mut).frame(width: 9, height: 2)
    }
  }

  var spoken: String {
    switch state {
    case .up(let n): "Up \(n)"
    case .down(let n): "Down \(n)"
    case .held: "Held"
    }
  }
}

struct CSTriangle: Shape {
  let up: Bool
  func path(in r: CGRect) -> Path {
    var p = Path()
    if up {
      p.move(to: CGPoint(x: r.midX, y: r.minY))
      p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
      p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
    } else {
      p.move(to: CGPoint(x: r.midX, y: r.maxY))
      p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
      p.addLine(to: CGPoint(x: r.minX, y: r.minY))
    }
    p.closeSubpath()
    return p
  }
}

// MARK: - The score mark

/// Under and over par drawn the way they are on paper: **a ring, a double ring,
/// nothing, a box, a double box** — in ink, at the icon family's 1.7pt stroke,
/// **with no colour at all, in either theme**.
///
/// This is a paper convention no app uses; it reads identically in both
/// printings; it is archival; it is not colour-only; and it settles "three
/// scorecards, three colour languages" (birdie was `pos` green on one card and
/// GOLD on another) without spending a single token.
public struct CSScoreMark: View {
  let strokesOverPar: Int
  let numeral: String?
  let size: CGFloat

  public init(_ strokesOverPar: Int, numeral: String? = nil, size: CGFloat = 30) {
    self.strokesOverPar = strokesOverPar; self.numeral = numeral; self.size = size
  }

  public var body: some View {
    ZStack {
      if let numeral { Text(numeral).csType(.figureS) }
      shape
    }
    .frame(width: size, height: size)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(numeral.map { "\($0), \(spoken)" } ?? spoken)
  }

  @ViewBuilder private var shape: some View {
    switch strokesOverPar {
    case ...(-2):
      Circle().stroke(lineWidth: 1.7).frame(width: size * 0.72, height: size * 0.72)
      Circle().stroke(lineWidth: 1.7).frame(width: size * 0.94, height: size * 0.94)
    case -1:
      Circle().stroke(lineWidth: 1.7).frame(width: size * 0.72, height: size * 0.72)
    case 0:
      EmptyView()
    case 1:
      Rectangle().stroke(lineWidth: 1.7).frame(width: size * 0.66, height: size * 0.66)
    default:
      Rectangle().stroke(lineWidth: 1.7).frame(width: size * 0.66, height: size * 0.66)
      Rectangle().stroke(lineWidth: 1.7).frame(width: size * 0.9, height: size * 0.9)
    }
  }

  var spoken: String {
    switch strokesOverPar {
    case ...(-2): "eagle or better"
    case -1: "birdie"
    case 0: "par"
    case 1: "bogey"
    default: "double bogey or worse"
    }
  }
}
