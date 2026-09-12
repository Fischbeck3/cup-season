// Cup Season — the containers, and there are only three (D266, UI_SYSTEM §3).
//
//   THE PANEL   one opaque tile, ≤96×96, ONE figure or ONE word. Radius p 3.
//   THE LEAF    a sheet of scorecard paper, and it must hold a grid.
//   THE OBJECT  a physical artefact a golfer would keep — the credential, the
//               settlement card. Radius r 16 + shadow-lift.
//
// Everything else on a screen is a **band**, a **rule**, a **rail** and
// **whitespace**. `CSCard` is deleted, the system has NO BORDER TOKEN, and no
// container may contain another container (`LINT-08`).
//
// The arithmetic that makes this a design rather than a preference: on the
// shipped ground the card fill sat **1.084:1** above the page and its border
// **1.443:1**. Those are not weak values; they are absent ones. The rule here
// is **2.66:1** and the panel **14.91:1** — real depth, spent on the two
// objects a screen is about instead of on every paragraph. And it holds in
// both printings, which is the test a tone-step design fails: the panel is
// 14.91:1 dark and **15.65:1 light**, because it inverts.

import SwiftUI

// MARK: - The band

/// A full-bleed tone or ceremony field. Radius 0, always — a band that runs
/// edge to edge can never read as a box, which is the whole point of it.
///
/// `.ceremony` is the honour room: the takeover, the finish, a settlement. It
/// is **pinned in both themes**, because a physical object does not re-print —
/// so every token inside resolves to its dark value even on the light stock.
public struct CSBand<Content: View>: View {
  @Environment(\.cs) private var cs
  public enum Kind: Sendable { case tone, ceremony }
  let kind: Kind
  let padding: CGFloat
  let content: Content

  public init(_ kind: Kind = .tone, padding: CGFloat = CSTokens.Space.s4, @ViewBuilder content: () -> Content) {
    self.kind = kind; self.padding = padding; self.content = content()
  }

  public var body: some View {
    // A `ViewBuilder` that yields more than one child is a `TupleView`, and a
    // modifier applied to a TupleView applies to EACH child — which drew one
    // band per paragraph rather than one band around them. Every container in
    // this file composes its children first for that reason.
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) { content }
      .padding(.vertical, padding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(kind == .tone ? cs.bg1 : CSTokens.dark.ceremony)
      .modifier(CSCeremonyGround(on: kind == .ceremony))
  }
}

/// On a ceremony ground every token resolves to its DARK value in both themes
/// (`UI_SYSTEM` §2.9). Stated once, here, rather than by each surface
/// remembering to flip two environment values in the right order.
struct CSCeremonyGround: ViewModifier {
  let on: Bool
  func body(content: Content) -> some View {
    if on {
      content.environment(\.colorScheme, .dark).environment(\.cs, CSTokens.dark)
    } else {
      content
    }
  }
}

public extension View {
  /// Put this view on the ceremony ground's token set without drawing a band.
  func csCeremony() -> some View { modifier(CSCeremonyGround(on: true)) }
}

// MARK: - The rule

/// **The only divider in the product.** Replaces `CSHairline` and every bare
/// `Divider()`.
///
/// `.hair` is the 1px `rule` — 2.66:1 on `bg0`, 84% more separation than the
/// shipped hairline. `.heavy` is the 2pt rule that lives under a figure or a
/// masthead, and its three metals are the two-metal law made graphic: `ink`
/// by default, `brand` when the thing above it is LIVE, `gold` when it was
/// EARNED.
public struct CSRule: View {
  @Environment(\.cs) private var cs
  public enum Weight: Sendable { case hair, heavy }
  public enum Metal: Sendable { case ink, live, earned }
  let weight: Weight
  let metal: Metal
  let inset: CGFloat
  /// A rule drawn on a leaf or a ceremony object takes that object's ink, not
  /// the page's — the two grounds do not turn over together.
  let over: Ground

  /// Which ground a rule — or a figure, or a slot — is standing on. **The
  /// grounds do not turn over together**: paper is paper in both rooms, a
  /// ceremony is a physical object in both rooms, and the panel is the
  /// opposite of the page by construction. A mark that reads the page's `ink`
  /// while sitting on one of the other three is invisible in one theme and
  /// nobody notices until the screenshot.
  public enum Ground: Sendable { case page, leaf, ceremony, panel }

  public init(_ weight: Weight = .hair, metal: Metal = .ink, inset: CGFloat = 0, over: Ground = .page) {
    self.weight = weight; self.metal = metal; self.inset = inset; self.over = over
  }

  public var body: some View {
    Rectangle()
      .fill(colour)
      .frame(height: weight == .hair ? CSTokens.Space.hair : 2)
      .padding(.horizontal, inset)
      .csBudget(gold: metal == .earned ? 1 : 0, ember: metal == .live ? 1 : 0)
      .accessibilityHidden(true)
  }

  private var colour: Color {
    if weight == .hair && metal == .ink {
      switch over {
      case .page: return cs.rule
      case .leaf: return cs.leafMut
      case .panel: return cs.panelMut
      case .ceremony: return CSTokens.dark.ceremonyInk.opacity(CSTokens.Alpha.a16)
      }
    }
    switch metal {
    case .ink:
      switch over {
      case .page: return cs.ink
      case .leaf: return cs.leafInk
      case .panel: return cs.panelInk
      case .ceremony: return CSTokens.dark.ceremonyInk
      }
    case .live: return over == .ceremony ? CSTokens.dark.ceremonyBrand : cs.brand
    // Gold ink on bone is 1.68:1 and forbidden (§2.4), so an earned rule on a
    // leaf reads the LIGHT gold — the bronze — in both themes. Named here so
    // no surface reaches for a literal.
    case .earned:
      switch over {
      case .page: return cs.gold
      // a bone panel is a light surface whichever room it is standing in, and
      // gold ink on bone is 1.68:1 — so both read the LIGHT gold, the bronze
      // **Gold on paper is its own token.** It reads the LIGHT theme's gold
      // in both printings, because the leaf does not invert — and it is a
      // token rather than a reach into the other palette, so preflight 15 and
      // the single-source check both cover it.
      case .leaf, .panel: return cs.leafGold
      case .ceremony: return CSTokens.dark.ceremonyGold
      }
    }
  }
}

// MARK: - The panel

/// One opaque tile holding **exactly one number or one word**. Bone on dark,
/// ink on light — always the opposite of the page, which is what makes it the
/// depth the card never had.
///
/// **The tripwire: if it ever holds a sentence, it has become a card**
/// (`LINT-19` — more than 12 characters, or a space, fails).
public struct CSPanel<Content: View>: View {
  @Environment(\.cs) private var cs
  @Environment(\.csInContainer) private var nested
  @Environment(\.dynamicTypeSize) private var typeSize
  public enum Ground: Sendable { case page, overPhoto }
  let ground: Ground
  /// The agate label under the figure, in `panelMut`. One word or one unit.
  let unit: String?
  let width: CGFloat?
  /// A panel with a STATED height, for the one place the design fixes both
  /// dimensions: Home's lead chip is 84 × 90, because the chip carries the
  /// figure, the ordinal and the movement in one block (§16A.4) and a chip
  /// that changed height between "held" and "up two" would move the headline
  /// beside it. Ignored at the accessibility sizes, where the tile grows with
  /// the numeral rather than cropping it.
  let height: CGFloat?
  let content: Content

  public init(_ ground: Ground = .page, unit: String? = nil, width: CGFloat? = nil,
              height: CGFloat? = nil, @ViewBuilder content: () -> Content) {
    self.ground = ground; self.unit = unit; self.width = width
    self.height = height; self.content = content()
  }

  /// Over a photograph the panel is ALWAYS the bone panel, in both themes: a
  /// photograph carries its own dusk and the light theme's ink panel would
  /// vanish into it. The mechanism is named so nobody reaches for a literal.
  private var fill: Color { ground == .overPhoto ? CSTokens.dark.panel : cs.panel }
  private var ink: Color { ground == .overPhoto ? CSTokens.dark.panelInk : cs.panelInk }
  private var mut: Color { ground == .overPhoto ? CSTokens.dark.panelMut : cs.panelMut }

  /// **A STATED WIDTH IS A WIDTH — UNTIL THE LABEL NEEDS MORE, AND THEN IT IS
  /// A FLOOR.** Pinning it absolutely is what broke `GROSS` at 60: the tile
  /// held its measure and the one word inside it broke by character. Measuring
  /// is what `CSAdvance` exists for (it is LINT-14's stated exemption for
  /// exactly this reason), and the 96 ceiling is still the law.
  private var measure: CGFloat? {
    guard let width, !typeSize.isA11y else { return nil }
    guard let unit, !unit.isEmpty else { return width }
    let need = CSAdvance.width(unit, .agateS, typeSize, caps: true) + CSTokens.Space.s3 * 2
    return min(96, max(width, need.rounded(.up)))
  }

  public var body: some View {
    VStack(spacing: CSTokens.Space.s1) {
      VStack(spacing: CSTokens.Space.s1) { content }
        .foregroundStyle(ink)
        // a panel holds ONE word or ONE figure and never wraps it: a clipped
        // word is the tripwire firing, not a layout to live with
        .fixedSize(horizontal: true, vertical: false)
      if let unit {
        // **THE LABEL NEVER WRAPS EITHER.** The `fixedSize` above is on the
        // FIGURE, and this file's own law is that *a panel holds one word and
        // never wraps it — a clipped word is the tripwire firing.* The unit had
        // no such guard, so the round band's 60pt gross tile printed
        // `90 / GROS / S`. The comment below already records this exact failure
        // once (`OF / EIG / HT`) and fixed it only for the accessibility sizes.
        Text(unit).csType(.agateS, caps: true).foregroundStyle(mut)
          .fixedSize(horizontal: true, vertical: false)
      }
    }
    .padding(.horizontal, CSTokens.Space.s3)
    .padding(.vertical, CSTokens.Space.s2)
    // **A STATED WIDTH IS NOT A CAGE AT AX3.** Pinning `minWidth`/`maxWidth`
    // here as well as below kept the CONTENT at 84 while the tile's ground
    // grew, so the chip's unit wrapped by character and printed
    // `OF / EIG / HT` under a 4TH. A panel that crops or breaks its one label
    // has stopped being a panel; at the accessibility sizes it takes the
    // measure and the label sets on one line.
    .frame(minWidth: typeSize.isA11y ? nil : measure, maxWidth: typeSize.isA11y ? nil : measure,
           minHeight: typeSize.isA11y ? 38 : (height ?? 38))
    // ≤96×96 is the law; at the accessibility sizes the tile grows with the
    // numeral rather than clipping it, because a panel that crops its one
    // figure has stopped being a panel.
    //
    // **A STATED WIDTH IS A WIDTH.** `.frame(maxWidth:)` EXPANDS into whatever
    // it is offered, so a panel asked for 84 and then handed a 96 ceiling drew
    // at 96 — the chip was 14% wider than the design in the first screenshot,
    // and nothing in the code said so.
    .frame(maxWidth: measure != nil && !typeSize.isA11y ? measure : (typeSize.isA11y ? .infinity : 96),
           alignment: .center)
    .background(fill, in: RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous))
    .environment(\.csInContainer, true)
    .csBudget(nested: nested ? 1 : 0)
  }
}

// MARK: - The leaf

/// A sheet of scorecard paper set into the page. **It does not invert** —
/// paper is paper in both rooms — and **it must contain a grid** (`LINT-20`).
/// A leaf that holds prose is a card.
///
/// In light it takes a 1px `mut` frame as well as its shade: a bright sheet on
/// paper needs an edge, and the first draft's 1px `rule` was 2.55:1 over a
/// 1.11:1 tone step — where a component's shape IS its meaning ("this is a
/// scorecard, set into the page"), WCAG 1.4.11 wants 3:1 on the boundary and a
/// hairline at 2.55 delivers neither the shape nor the meaning.
public struct CSLeaf<Content: View>: View {
  @Environment(\.cs) private var cs
  @Environment(\.colorScheme) private var scheme
  @Environment(\.csInContainer) private var nested
  let padding: CGFloat
  let content: Content

  public init(padding: CGFloat = CSTokens.Space.s3, @ViewBuilder content: () -> Content) {
    self.padding = padding; self.content = content()
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) { content }
      .foregroundStyle(cs.leafInk)
      .padding(padding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(cs.leaf, in: RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous))
      .overlay {
        if scheme == .light {
          RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous)
            .stroke(cs.leafMut, lineWidth: CSTokens.Space.hair)
        }
      }
      .shadow(color: CSTokens.leafShade.color,
              radius: CSTokens.leafShade.radius, x: CSTokens.leafShade.x, y: CSTokens.leafShade.y)
      .environment(\.csInContainer, true)
      .csBudget(nested: nested ? 1 : 0)
  }

}

/// The 2pt rule under an EARNED figure on a leaf. Reads `CSTokens.light.gold`
/// — the bronze — in BOTH themes, because gold ink on bone is 1.68:1 and dark
/// gold on bone at 2pt is a pale smear (D-6).
///
/// **It is not a static on `CSLeaf`**, which is generic over its content: a
/// static member of a generic type cannot be named without its argument, so
/// `CSLeaf.earnedRule()` does not compile in the one place the design asks
/// for it. Same lesson as `CSCredentialGolfer` in Wave 2, one file over.
public enum CSLeafRule {
  public static func earned() -> some View { CSRule(.heavy, metal: .earned, over: .leaf) }
}

// MARK: - The record, printed

/// **The archive, as a printed table on a leaf** (§9.8, `profile.md` §7).
/// `year · competition · finish · money`, one row per season, newest first —
/// and it is the one place §3.3's leaf licence applies on the profile,
/// because a leaf must contain a grid and this is one.
///
/// **The earned mark, tightened** (§7 / D-5): **a WIN takes the gold rule; a
/// podium takes a 2pt `ink` rule.** §9.8 gave gold to both, and 2nd of 8 is
/// not silverware — the tightening keeps the viewport's gold budget honest
/// without losing the podium's mark. The gold is `CSLeaf.earnedRule`, which
/// reads the LIGHT theme's gold in both printings: the leaf does not invert,
/// and dark gold on bone at 2pt is a pale smear (D-6).
///
/// **Gold ink on a leaf stays forbidden** — 1.68:1. The finish is `leafInk`
/// whatever it was; the rule under it is what says it was won.
///
/// **The money column is optional and it is dropped when nothing produces
/// it.** `CareerRecord.earningsCents` is a career total and `season_payouts`
/// holds no rows in prod, so a per-season net does not exist — and the table
/// runs three columns rather than four zeroes (`profile.md` §14.2's own
/// degrade). A table is still a table.
public struct CSRecordLeaf: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize

  public struct Row: Identifiable, Sendable {
    public let id: String
    /// `2026`. Absent rather than guessed.
    public let year: String?
    /// `The Fellas`
    public let competition: String
    /// `Season one` — the qualifier, in agate beside the name.
    public let qualifier: String?
    /// The place, as a FIGURE: `2` with the `ND` rider. nil where the season
    /// has no ranked table, and `line` prints instead.
    public let finish: Int?
    /// The pre-formatted line the row falls back to (`FIRST TEE SAT AUG 30`,
    /// `FORMING`) — §14.1's degrade, printed in `column` rather than as a
    /// figure, so it is never mistaken for a place.
    public let line: String?
    public let won: Bool
    /// `$40` / `−$20`. nil drops the whole column.
    public let money: String?
    public let spoken: String
    public let open: (@MainActor @Sendable () -> Void)?

    public init(id: String, year: String?, competition: String, qualifier: String?,
                finish: Int?, line: String?, won: Bool, money: String? = nil,
                spoken: String = "", open: (@MainActor @Sendable () -> Void)? = nil) {
      self.id = id; self.year = year; self.competition = competition; self.qualifier = qualifier
      self.finish = finish; self.line = line; self.won = won; self.money = money
      self.spoken = spoken.isEmpty ? competition : spoken
      self.open = open
    }

    /// The podium, and it is a podium only in a field that HAS one. Third of
    /// three is last place, and an ink rule under it would read as a mark.
    var podium: Bool { !won && (finish ?? 99) <= 3 }
  }

  let rows: [Row]
  public init(_ rows: [Row]) { self.rows = rows }

  /// The money column is DROPPED when nothing produces it — three columns
  /// rather than four zeroes (`profile.md` §14.2). A table is still a table.
  static func showsMoney(_ rows: [Row]) -> Bool { rows.contains { $0.money != nil } }
  private var showsMoney: Bool { Self.showsMoney(rows) }

  public var body: some View {
    CSLeaf {
      // §16A.3 · an unlabelled number column is a defect, not a minimalism.
      // At the accessibility sizes the heads go and each row speaks its own
      // facts instead (§16.3), because a four-column head at AX3 is four
      // words stacked over one row.
      if !typeSize.isA11y {
        HStack(spacing: CSTokens.Space.s3) {
          Text("Year").csType(.columnS, caps: true).foregroundStyle(cs.leafMut)
            .frame(width: 42, alignment: .leading)
          Text("Competition").csType(.columnS, caps: true).foregroundStyle(cs.leafMut)
            .frame(maxWidth: .infinity, alignment: .leading)
          Text("Finish").csType(.columnS, caps: true).foregroundStyle(cs.leafMut)
            .frame(width: 52, alignment: .trailing)
          if showsMoney {
            Text("Money").csType(.columnS, caps: true).foregroundStyle(cs.leafMut)
              .frame(width: 56, alignment: .trailing)
          }
        }
        .accessibilityHidden(true)
      }
      ForEach(Array(rows.enumerated()), id: \.element.id) { i, r in
        if i > 0 { CSRule(over: .leaf) }
        row(r)
      }
    }
  }

  @ViewBuilder private func row(_ r: Row) -> some View {
    let content = HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s3) {
      Text(r.year ?? "").csType(.columnS).foregroundStyle(cs.leafMut)
        .frame(width: typeSize.isA11y ? nil : 42, alignment: .leading)
      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s2) {
          Text(r.competition).csType(.social).foregroundStyle(cs.leafInk)
            .lineLimit(typeSize.isA11y ? 3 : 1).truncationMode(.tail)
          if let q = r.qualifier, !typeSize.isA11y {
            Text(q).csType(.agateS, caps: true).foregroundStyle(cs.leafMut).lineLimit(1)
          }
        }
        if let q = r.qualifier, typeSize.isA11y {
          Text(q).csType(.agateS, caps: true).foregroundStyle(cs.leafMut)
        }
      }
      .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
      finishCell(r)
      if showsMoney {
        // §9.5 · money is INK on a leaf too, and the sign is a word in the
        // column head — never red and green.
        Text(r.money ?? "").csType(.column).foregroundStyle(cs.leafInk)
          .frame(width: typeSize.isA11y ? nil : 56, alignment: .trailing)
      }
    }
    .frame(minHeight: 44)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(r.spoken)

    if let open = r.open {
      Button(action: open) { content.contentShape(Rectangle()) }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the season")
    } else {
      content
    }
  }

  @ViewBuilder private func finishCell(_ r: Row) -> some View {
    VStack(alignment: .trailing, spacing: 3) {
      if r.won {
        Text("Won").csType(.nameS, caps: true).foregroundStyle(cs.leafInk)
      } else if let f = r.finish {
        // §1.7's one ordinal — uppercase, 0.46 em, ON THE BASELINE — and it is
        // the figure's own rider, so the profile cannot cut a second form.
        CSFigure(String(f), size: .s, label: nil, ordinal: CSOrdinal.suffix(f), over: .leaf)
      } else if let line = r.line, !line.isEmpty {
        Text(line).csType(.columnS, caps: true).foregroundStyle(cs.leafMut)
          .lineLimit(2).multilineTextAlignment(.trailing)
      }
      // the mark: gold for a win, ink for a podium, nothing otherwise
      if r.won {
        CSLeafRule.earned()
      } else if r.podium {
        CSRule(.heavy, over: .leaf)
      }
    }
    .frame(width: typeSize.isA11y ? nil : 52, alignment: .trailing)
  }
}

// MARK: - The plate

/// An image field, and it is one of exactly three things (D272): a golfer's own
/// round photo, the drawn card, or the contour. **Never** stock, never a
/// licensed image the product does not have, never a fabricated face, and
/// **never a gradient wash**. A course with none of the three shows no
/// thumbnail at all — the space collapses.
public struct CSPlate<Content: View>: View {
  @Environment(\.cs) private var cs
  @Environment(\.csInContainer) private var nested
  public enum Fit: Sendable {
    case bleed      // full width, radius 0
    case inset32    // the 3:2 inset plate, radius p 3
    case thumb      // a row's thumbnail, radius p 3

    var radius: CGFloat { self == .bleed ? 0 : CSTokens.Radius.p }
    var ratio: CGFloat? {
      switch self {
      case .bleed: nil
      case .inset32: 3.0 / 2.0
      case .thumb: 1
      }
    }
  }
  let fit: Fit
  /// A golfer's photograph is CREDITED, in agate, always. It is the difference
  /// between an image the product borrowed and an image somebody took.
  let credit: String?
  let content: Content

  public init(_ fit: Fit, credit: String? = nil, @ViewBuilder content: () -> Content) {
    self.fit = fit; self.credit = credit; self.content = content()
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      ZStack { content }
        .frame(maxWidth: .infinity)
        .aspectRatio(fit.ratio, contentMode: .fill)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: fit.radius, style: .continuous))
      if let credit {
        Text(credit).csType(.agateS, caps: false).foregroundStyle(cs.mut)
      }
    }
    .environment(\.csInContainer, true)
    .csBudget(nested: nested ? 1 : 0)
  }
}

// MARK: - The plate with nothing in it yet

/// **THE INVITATION, AT THE SIZE AND SHAPE OF THE PICTURE IT WANTS** (IOS-066).
///
/// A `CSPlate` shows a photograph a golfer took. This is what the same field
/// looks like BEFORE there is one, and it is not a button with a word on it:
/// it is the picture's own boundary, drawn, with the family's `.photo` glyph
/// and one agate line inside. §17 asks empty states to be invitations rather
/// than apologies, and a frame the exact size of the result is the most
/// literal invitation an image field can make.
///
/// The edge is `rule` — the system's ONE hairline, bent into the plate's own
/// radius. It is not a fifth border style: it is `CSRule` following a corner,
/// and it exists only while the field is empty. Put a picture in and the line
/// goes, because the picture has its own edge.
///
/// It lives here rather than at the call site because the shape does: a
/// rounded rectangle drawn outside `CSDesign` is what LINT-10 counts, and the
/// answer to a lint is the component it is asking for.
public struct CSPlateWell: View {
  @Environment(\.cs) private var cs
  let glyph: CSGlyph.Name
  let label: String
  public init(glyph: CSGlyph.Name = .photo, label: String) {
    self.glyph = glyph; self.label = label
  }
  public var body: some View {
    ZStack {
      VStack(spacing: CSTokens.Space.s1) {
        CSGlyph(glyph, size: .block)
        Text(label).csType(.agateS, caps: true).multilineTextAlignment(.center)
      }
      .foregroundStyle(cs.mut)
      .padding(.horizontal, CSTokens.Space.s1)
      RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous)
        .strokeBorder(cs.rule, lineWidth: CSTokens.Space.hair)
    }
  }
}

// MARK: - The object

/// A thing a golfer would keep: the credential, the settlement card, the
/// trophy plate. Radius `r` 16 and `shadow-lift` — the only elevation in the
/// system, spent on the one artefact a screen is about.
public struct CSObject<Content: View>: View {
  let content: Content
  public init(@ViewBuilder content: () -> Content) { self.content = content() }
  public var body: some View {
    VStack(spacing: 0) { content }
      .clipShape(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
      // **THE OBJECT'S OWN EDGE, BECAUSE A SHADOW ON NEAR-BLACK IS NOT ONE.**
      //
      // Both objects stand on the pinned `ceremony` ground. In the LIGHT
      // printing that is a 15:1 step off `bg0` and the card reads as a card
      // for free; in the DARK printing `ceremony` #0A0E0C against `bg0`
      // #0F1A15 is a ~1.05:1 step and `shadow-lift` is invisible over it — so
      // a golfer with no photograph (which is most golfers, for some time)
      // saw type and a contour floating on a flat screen rather than
      // something they would keep.
      //
      // This is the edge of a physical artefact drawn as a 1px rule at the
      // SAME alpha and the same ink the folio inside it already uses — not a
      // border token, not a container chrome, and not a second radius: the
      // one shape the object already has, made visible.
      .overlay(
        RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous)
          .strokeBorder(CSOpaque.tint(CSTokens.dark.ceremonyInk, CSTokens.Alpha.a16,
                                      over: CSTokens.dark.ceremony, reduce: true),
                        lineWidth: CSTokens.Space.hair)
          .allowsHitTesting(false)
      )
      .shadow(color: CSTokens.shadowLift.color,
              radius: CSTokens.shadowLift.radius, x: CSTokens.shadowLift.x, y: CSTokens.shadowLift.y)
  }
}
