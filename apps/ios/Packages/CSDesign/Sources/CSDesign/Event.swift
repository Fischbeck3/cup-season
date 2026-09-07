// Cup Season — the title card's three objects (UI_SYSTEM §15.5, §15.5a).
//
// AN EVENT IS A MOMENT, NOT A DATABASE RECORD. Three devices carry it and none
// of them is a container: the **side roster** (two named groups under two
// squad rules), the **score rail** (figures sharing one metal rule), and the
// **clash row** (two faces across a middle word, on the page's own ground).
//
// §15.5a IS THE REASON THIS FILE EXISTS. All three blind reviewers filed the
// same failure and one called it a failure at the surface's one job: *"this is
// a team event and you cannot tell who is on which team."* Sides were two
// 14 × 4pt colour ticks that also collided with the dateline, over six roster
// discs coloured by PERSONAL MARKER — identity, not side. `sq0` and `sq3` are
// **1.58:1** apart, so on a bright screen, through a greyscale filter, or with
// achromatopsia the two teams became one team.
//
// The law: two named groups, each under a full-width 3pt rule in its squad
// colour with the squad's name in `agateS` beneath, and **every disc carries a
// 2.5pt outer ring in its side's colour while keeping its own pigment and
// glyph**. Identity and side are different channels and stay so — re-tinting a
// marker by side would trade one legibility failure for a worse one.

import SwiftUI

public extension CSPalette {
  /// The four squad marks on the CEREMONY ground (§2.8's pinned ramp). A title
  /// card is a physical object and does not re-print in the morning, so a
  /// squad rule on it never reaches for the page's own `sq0…sq3`.
  func ceremonySquad(_ i: Int) -> Color {
    [ceremonySq0, ceremonySq1, ceremonySq2, ceremonySq3][max(0, min(3, i))]
  }
  /// The same four on the page's own ground.
  func squadMark(_ i: Int) -> Color { [sq0, sq1, sq2, sq3][max(0, min(3, i))] }
}

// MARK: - The side roster

/// **Two named groups, never one row of six** (§15.5a).
///
/// Each group sits under a full-width 3pt rule in its squad colour with the
/// squad's name in `agateS` beneath it — leading-aligned on the left group,
/// trailing-aligned on the right — and every disc in the group carries a 2.5pt
/// ring in that colour. The count is capped at three a side: a seventh golfer
/// becomes a `+N` disc that pushes to the field list, because a rail of nine
/// discs is a crowd and not a roster.
public struct CSSideRoster: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize

  public struct Side: Identifiable, Sendable {
    public let id: String
    /// `SAGUAROS` — the squad's NAME, which is what makes the colour legal.
    public let name: String
    public let color: Color
    public let faces: [CSFace.Model]
    /// First names — `CSBands.fn1`'s output, one word each.
    public let names: [String]
    public init(id: String, name: String, color: Color, faces: [CSFace.Model], names: [String]) {
      self.id = id; self.name = name; self.color = color; self.faces = faces; self.names = names
    }
    /// **Three a side, then a `+N`.** The overflow is the field list's door.
    static let seats = 3
    var shown: Int { min(faces.count, Self.seats) }
    var overflow: Int { max(0, faces.count - Self.seats) }
  }

  let left: Side
  let right: Side
  /// The disc diameter. A title card takes `.list`; a desk takes it larger.
  let size: CSFace.Size

  public init(left: Side, right: Side, size: CSFace.Size = .list) {
    self.left = left; self.right = right; self.size = size
  }

  public var body: some View {
    // §7.5 · **at the accessibility sizes the rail SCROLLS rather than
    // shrinking the discs.** A 38pt face is already the smallest a marker
    // reads at, and an AX3 name under it is 26pt tall; squeezing six of those
    // into 362 points is how a roster becomes a smudge.
    if typeSize.isA11y {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: CSTokens.Space.s4) {
          group(left, align: .leading)
          group(right, align: .leading)
        }
      }
      .accessibilityElement(children: .contain)
    } else {
      // Two groups side by side while the names fit on one line each; the
      // moment they do not — a long first name on a narrow phone — the groups
      // stack, which is §16.3's SE clause.
      ViewThatFits(in: .horizontal) {
        HStack(alignment: .top, spacing: CSTokens.Space.s3) {
          group(left, align: .leading).frame(maxWidth: .infinity, alignment: .leading)
          group(right, align: .trailing).frame(maxWidth: .infinity, alignment: .trailing)
        }
        VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
          group(left, align: .leading)
          group(right, align: .leading)
        }
      }
    }
  }

  @ViewBuilder private func group(_ s: Side, align: HorizontalAlignment) -> some View {
    VStack(alignment: align, spacing: CSTokens.Space.s2) {
      // the rule is an OVERLAY so it never widens the group: a
      // `maxWidth: .infinity` rule inside the stack makes the whole group
      // infinitely flexible and `ViewThatFits` then always takes the first
      // candidate, which is the bug that shape invites.
      Text(s.name).csType(.agateS, caps: true).foregroundStyle(CSTokens.dark.ceremonyMut)
        .lineLimit(1).fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity, alignment: align == .leading ? .leading : .trailing)
        .padding(.top, CSTokens.Space.s2)
        .overlay(alignment: .top) { Rectangle().fill(s.color).frame(height: 3) }
      HStack(alignment: .top, spacing: CSTokens.Space.s2) {
        ForEach(Array(s.faces.prefix(Side.seats).enumerated()), id: \.offset) { i, f in
          VStack(spacing: CSTokens.Space.s2) {
            CSFace(f, size: size, sideRing: s.color)
            if i < s.names.count {
              Text(s.names[i]).csType(.agateS, caps: true)
                .foregroundStyle(f.isViewer ? CSTokens.dark.ceremonyInk : CSTokens.dark.ceremonyMut)
                .lineLimit(1).fixedSize(horizontal: true, vertical: false)
            }
          }
        }
        if s.overflow > 0 {
          VStack(spacing: CSTokens.Space.s2) {
            ZStack {
              Circle().fill(CSTokens.dark.ceremonyInk.opacity(CSTokens.Alpha.a16))
              Text("+\(s.overflow)").csType(.agateS, caps: true).foregroundStyle(CSTokens.dark.ceremonyInk)
            }
            .frame(width: size.rawValue, height: size.rawValue)
            .overlay(Circle().inset(by: -1.5).stroke(s.color, lineWidth: 2.5))
            Text("more").csType(.agateS, caps: true).foregroundStyle(CSTokens.dark.ceremonyMut)
          }
        }
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(spoken(s))
  }

  private func spoken(_ s: Side) -> String {
    let who = s.names.prefix(Side.seats).joined(separator: ", ")
    return s.overflow > 0 ? "\(s.name): \(who) and \(s.overflow) more" : "\(s.name): \(who)"
  }
}

// MARK: - The score rail

/// **Figures on ONE shared rule** — the signature object, at the size of a
/// scoreboard. Two cells for a Ryder, three for a callout, four for a plan.
///
/// The rule's metal is the state: `brand` while it is live, `ink` the moment it
/// completes, and **never gold** — nothing on a live event has been earned, and
/// the pot is the surface's gold object (D-6).
///
/// **A countdown is not a score** (§15.5a). The rail carries the two side
/// scores; a Ryder's deadline lives in the live eyebrow with the other time
/// facts. A callout's clock IS one of its three numbers, because a callout has
/// no week structure to put it in.
public struct CSScoreRail: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize

  public struct Cell: Identifiable, Sendable {
    public let id: String
    /// The whole number. `3½` is composed, never passed as one string —
    /// `RyderMath.evHalf`'s pre-composed vulgar fraction reads as a small
    /// diagonal at 40pt, which is the set's weakest typographic moment.
    public let value: String
    /// The rider: a `½` at 0.56 em on a raised baseline, so a mixed number
    /// reads as one figure exactly as the ordinal rider does on a rank hero.
    public let half: Bool
    public let label: String
    /// The 26 × 3pt squad rule above the numeral — a side's cell, and nothing
    /// else on this surface, carries one.
    public let tick: Color?
    /// `DAYS LEFT` is `brand`; a side's name is `mut`.
    public let labelLive: Bool
    /// **§6.2 · the RESULT is the earned thing, and only once it is a result.**
    /// A completed event paints the winning cell gold and sends the pot figure
    /// to `ink`, because the pot has been paid. That keeps exactly one gold
    /// object per viewport in BOTH states and makes "gold means earned" true
    /// across time, not only across space. It is never set while play is open.
    public let earned: Bool
    public let spoken: String?
    public init(id: String, value: String, half: Bool = false, label: String,
                tick: Color? = nil, labelLive: Bool = false, earned: Bool = false,
                spoken: String? = nil) {
      self.id = id; self.value = value; self.half = half; self.label = label
      self.tick = tick; self.labelLive = labelLive; self.earned = earned; self.spoken = spoken
    }
  }

  let cells: [Cell]
  let size: CSFigure.Size
  let metal: CSRule.Metal

  public init(_ cells: [Cell], size: CSFigure.Size = .l, metal: CSRule.Metal = .ink) {
    self.cells = cells; self.size = size; self.metal = metal
  }

  public var body: some View {
    if typeSize.isA11y {
      // §7.5 · a stacked list — the agate label leading, the figure trailing,
      // each on its own 2pt rule, and the rule's metal preserved per row.
      VStack(alignment: .leading, spacing: 0) {
        ForEach(cells) { c in
          HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s3) {
            Text(c.label).csType(.agateS, caps: true).foregroundStyle(labelInk(c))
            Spacer(minLength: CSTokens.Space.s3)
            numeral(c)
          }
          .frame(minHeight: 44)
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(c.spoken ?? "\(c.label), \(c.value)\(c.half ? " and a half" : "")")
          CSRule(.heavy, metal: metal)
        }
      }
      .csBudget(gold: cells.filter(\.earned).count, ember: metal == .live ? 1 : 0)
    } else {
      VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
        HStack(alignment: .bottom, spacing: CSTokens.Space.s2) {
          ForEach(cells) { c in
            VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
              if let tick = c.tick { Rectangle().fill(tick).frame(width: 26, height: 3) }
              numeral(c)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(c.spoken ?? "\(c.label), \(c.value)\(c.half ? " and a half" : "")")
          }
        }
        // ONE rule under all of them. The metal says whether it is running.
        CSRule(.heavy, metal: metal)
        HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s2) {
          ForEach(cells) { c in
            Text(c.label).csType(.agateS, caps: true).foregroundStyle(labelInk(c))
              .lineLimit(1).truncationMode(.tail)
              .frame(maxWidth: .infinity, alignment: .leading)
              .accessibilityHidden(true)
          }
        }
      }
      .csBudget(gold: cells.filter(\.earned).count, ember: metal == .live ? 1 : 0)
    }
  }

  private func labelInk(_ c: Cell) -> Color { c.labelLive ? cs.brand : cs.mut }

  /// The whole number, and the half as a rider rather than a glyph.
  private func numeral(_ c: Cell) -> some View {
    let pt = CSType.renderedSize(size.role, typeSize)
    return HStack(alignment: .firstTextBaseline, spacing: 0) {
      Text(c.value).csType(size.role).foregroundStyle(c.earned ? cs.gold : cs.ink)
      if c.half {
        Text("½")
          .font(.custom(CSType.boardBold, fixedSize: pt * 0.56))
          .baselineOffset(pt * 0.16)
          .foregroundStyle(c.earned ? cs.gold : cs.ink)
      }
    }
    .lineLimit(1)
  }
}

// MARK: - The clash

/// A week's pairing: two faces, two names, a middle word, and the two figures
/// under their own names — **56pt, one `rule` on its top edge, full-bleed**.
///
/// **D-4 · a clash refuses the rank rail.** §0.2 says every ranked list starts
/// with it, and this is not a ranked list: a pairing has no position to put in
/// the slot, and a rail painted with a half-point would make the rail mean two
/// things. The Major's leaderboard and the event's board do take the rail;
/// only the clash does not.
///
/// Colour is never the only channel: the result is carried by the WORD (`def.`
/// / `halved`) and by the loser's tone, never by hue.
public struct CSClashRow: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize

  public enum Result: Sendable { case open, left, right, halved }

  let left: CSFace.Model
  let right: CSFace.Model
  let leftName: String
  let rightName: String
  /// `vs` · `def.` · `halved` — `RyderMath.mid`, in SENTENCE case, because it
  /// is a word in a sentence and not a label.
  let mid: String
  /// `+2.1` / `−0.4`, or `—` in `mut` for "not posted". **Never a zero and
  /// never a guess.**
  let leftFigure: String?
  let rightFigure: String?
  let result: Result
  /// The taunt landed: this row's figure CHANGED since the last load (C10).
  let risen: Bool

  public init(left: CSFace.Model, leftName: String, right: CSFace.Model, rightName: String,
              mid: String, leftFigure: String?, rightFigure: String?,
              result: Result, risen: Bool = false) {
    self.left = left; self.right = right
    self.leftName = leftName; self.rightName = rightName
    self.mid = mid; self.leftFigure = leftFigure; self.rightFigure = rightFigure
    self.result = result; self.risen = risen
  }

  private var leftInk: Color { result == .right ? cs.mut : cs.ink }
  private var rightInk: Color { result == .left ? cs.mut : cs.ink }

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      CSRule()
      if typeSize.isA11y {
        // §7.5 · the two names stack (yours first), the middle word becomes a
        // leading agate line, and each figure sits under its own name.
        VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
          side(left, leftName, leftFigure, leftInk, .leading)
          Text(mid).csType(.agateS, caps: true).foregroundStyle(cs.mut)
          side(right, rightName, rightFigure, rightInk, .leading)
        }
        .padding(.vertical, CSTokens.Space.s3)
        .csGutterRow()
      } else {
        VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
          HStack(spacing: CSTokens.Space.s2) {
            CSFace(left, size: .slat)
            Text(leftName).csType(.name).foregroundStyle(leftInk)
              .lineLimit(1).truncationMode(.tail)
              .frame(minWidth: 0, alignment: .leading)
            Spacer(minLength: CSTokens.Space.s2)
            Text(mid).csType(.agateS, caps: true).foregroundStyle(cs.mut)
              .fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: CSTokens.Space.s2)
            Text(rightName).csType(.name).foregroundStyle(rightInk)
              .lineLimit(1).truncationMode(.tail)
              .frame(minWidth: 0, alignment: .trailing)
            CSFace(right, size: .slat)
          }
          HStack(spacing: 0) {
            figure(leftFigure, leftInk).frame(maxWidth: .infinity, alignment: .leading)
            figure(rightFigure, rightInk).frame(maxWidth: .infinity, alignment: .trailing)
          }
          // the figures sit under their own face+name columns
          .padding(.horizontal, CSFace.Size.slat.rawValue + CSTokens.Space.s2)
        }
        .padding(.top, CSTokens.Space.s3)
        .padding(.bottom, CSTokens.Space.s2)
        .csGutterRow()
      }
    }
    .frame(minHeight: 56)
    .fixedSize(horizontal: false, vertical: true)
    // ONE VoiceOver element per row.
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(spoken)
  }

  @ViewBuilder private func side(_ f: CSFace.Model, _ name: String, _ fig: String?,
                                 _ ink: Color, _ align: HorizontalAlignment) -> some View {
    HStack(spacing: CSTokens.Space.s2) {
      CSFace(f, size: .slat)
      Text(name).csType(.name).foregroundStyle(ink).lineLimit(1).truncationMode(.tail)
      Spacer(minLength: CSTokens.Space.s2)
      figure(fig, ink)
    }
  }

  @ViewBuilder private func figure(_ v: String?, _ ink: Color) -> some View {
    if let v {
      Text(v).csType(.figureS).foregroundStyle(v == "—" ? cs.mut : ink)
        .eventRise(risen)
    }
  }

  /// The row's one VoiceOver sentence — internal so the tests can read it,
  /// which is how "one element per row" stays a fact rather than a comment.
  var spoken: String {
    let verb = switch result {
    case .left: "\(leftName) beat \(rightName)"
    case .right: "\(rightName) beat \(leftName)"
    case .halved: "\(leftName) and \(rightName) halved"
    case .open: "\(leftName) versus \(rightName)"
    }
    let l = leftFigure.map { $0 == "—" ? "\(leftName) has not posted" : "\(leftName) \(spokenFigure($0))" }
    let r = rightFigure.map { $0 == "—" ? "\(rightName) has not posted" : "\(rightName) \(spokenFigure($0))" }
    return ([verb] + [l, r].compactMap { $0 }).joined(separator: ". ")
  }

  func spokenFigure(_ s: String) -> String {
    s.replacingOccurrences(of: "+", with: "plus ").replacingOccurrences(of: "\u{2212}", with: "minus ")
      .replacingOccurrences(of: "-", with: "minus ")
  }
}

// MARK: - the gutter, for a full-bleed row

extension View {
  /// **Padding around a full-measure child WIDENS the row.** A row whose
  /// content holds a `Spacer` claims the whole proposed width and the gutter
  /// is then ADDED to it, so the row measures screen + 40, a vertical
  /// `ScrollView` centres it, and every block on the page shifts left. The
  /// frame after the padding re-clamps to the measure.
  func csGutterRow() -> some View {
    padding(.horizontal, CSTokens.Space.gutter)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: - C10, the taunt landing

/// The opponent's number arcs in, squashes at touch, settles. Banter — never
/// gold, never over 350ms, and reduced motion rests immediately.
///
/// Its tint moved off the deleted `cs.warm` and onto `ink`: the ARRIVAL is the
/// signal, and a fourth orange never was one.
struct CSRiseModifier: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let rise: Bool
  @State private var landed = false
  func body(content: Content) -> some View {
    content
      .offset(x: rise && !landed ? -10 : 0, y: rise && !landed ? -18 : 0)
      .opacity(rise && !landed ? 0 : 1)
      .onAppear {
        guard rise, !reduceMotion else { landed = true; return }
        CSMotion.run { landed = true }
      }
  }
}

public extension View {
  func eventRise(_ rise: Bool) -> some View { modifier(CSRiseModifier(rise: rise)) }
}
