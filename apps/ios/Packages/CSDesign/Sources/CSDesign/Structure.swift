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

  public enum Ground: Sendable { case page, leaf, ceremony }

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
      case .ceremony: return CSTokens.dark.ceremonyInk.opacity(CSTokens.Alpha.a16)
      }
    }
    switch metal {
    case .ink:
      switch over {
      case .page: return cs.ink
      case .leaf: return cs.leafInk
      case .ceremony: return CSTokens.dark.ceremonyInk
      }
    case .live: return over == .ceremony ? CSTokens.dark.ceremonyBrand : cs.brand
    // Gold ink on bone is 1.68:1 and forbidden (§2.4), so an earned rule on a
    // leaf reads the LIGHT gold — the bronze — in both themes. Named here so
    // no surface reaches for a literal.
    case .earned:
      switch over {
      case .page: return cs.gold
      case .leaf: return CSTokens.light.gold
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
  let content: Content

  public init(_ ground: Ground = .page, unit: String? = nil, width: CGFloat? = nil,
              @ViewBuilder content: () -> Content) {
    self.ground = ground; self.unit = unit; self.width = width; self.content = content()
  }

  /// Over a photograph the panel is ALWAYS the bone panel, in both themes: a
  /// photograph carries its own dusk and the light theme's ink panel would
  /// vanish into it. The mechanism is named so nobody reaches for a literal.
  private var fill: Color { ground == .overPhoto ? CSTokens.dark.panel : cs.panel }
  private var ink: Color { ground == .overPhoto ? CSTokens.dark.panelInk : cs.panelInk }
  private var mut: Color { ground == .overPhoto ? CSTokens.dark.panelMut : cs.panelMut }

  public var body: some View {
    VStack(spacing: CSTokens.Space.s1) {
      VStack(spacing: CSTokens.Space.s1) { content }
        .foregroundStyle(ink)
        // a panel holds ONE word or ONE figure and never wraps it: a clipped
        // word is the tripwire firing, not a layout to live with
        .fixedSize(horizontal: true, vertical: false)
      if let unit {
        Text(unit).csType(.agateS, caps: true).foregroundStyle(mut)
      }
    }
    .padding(.horizontal, CSTokens.Space.s3)
    .padding(.vertical, CSTokens.Space.s2)
    .frame(minWidth: width, maxWidth: width, minHeight: 38)
    // ≤96×96 is the law; at the accessibility sizes the tile grows with the
    // numeral rather than clipping it, because a panel that crops its one
    // figure has stopped being a panel.
    .frame(maxWidth: typeSize.isA11y ? .infinity : 96, alignment: .center)
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

  /// The 2pt rule under an EARNED figure on a leaf. Reads `CSTokens.light.gold`
  /// — the bronze — in BOTH themes, because gold ink on bone is 1.68:1.
  public static func earnedRule() -> some View { CSRule(.heavy, metal: .earned, over: .leaf) }
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
      .shadow(color: CSTokens.shadowLift.color,
              radius: CSTokens.shadowLift.radius, x: CSTokens.shadowLift.x, y: CSTokens.shadowLift.y)
  }
}
