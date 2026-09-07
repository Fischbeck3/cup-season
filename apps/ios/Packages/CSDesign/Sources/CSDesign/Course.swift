// Cup Season — the course, as an editorial object (D272 / D275, IOS-048,
// `UI_SYSTEM` §9.11, §10, §15.3, `surfaces/course.md`).
//
// THE SURFACE THE BLIND REVIEW FAILED, AND THE ONE SENTENCE THAT SAYS WHY:
// there was **no photograph of a golf course anywhere in five course
// renders**. Two of three reviewers scored it "not premium" and "does not
// belong in the category" on that alone, and the third named it twice. So the
// components here are built around the LADDER (§10.1) rather than around a
// layout: rung 1 is a golfer's own round photo, credited in agate; rung 2 is
// the drawn card, from REAL par, stroke index and yardage; rung 3 is the
// contour. **A course with none of the three shows no image at all** — the
// space collapses, which is honest and better looking than a placeholder.
//
// AND THE OTHER SENTENCE, WHICH IS THE ONE THAT GOVERNS RUNG 2:
// *fake data as ornament is less premium than a plain colour* — three blind
// reviewers, in three different sentences, about eighteen unlabelled bars
// representing nothing. `CSDrawnCard` therefore refuses to draw at all when
// it has no real card to draw FROM, and it never invents a height.
//
// There is **no gold on the course page** except the one bar the drawn card
// marks, and that is `BUILD_BRIEF` §4's own acceptance line ("gold on the #1
// stroke hole") winning over `course.md` §2.3's later sentence. The RATING is
// `ink` in every state, in a control and out of one: an average of opinions is
// not earned (D275), and gold may never touch a control (D269 / `LINT-11`).

import SwiftUI

// MARK: - Rung 2 · the drawn card

/// **The drawn card** — the plate a course generates from its own scorecard.
/// Eighteen bars, **height by yardage, width by par**, one bar in `gold` on
/// the #1 stroke hole, numbered 1–18 in `columnS` beneath.
///
/// **At ≤64pt it renders the front nine only** — nine bars at three heights by
/// par, one tone, no numerals (`UI_SYSTEM` §10.2). Eighteen 3pt bars in a
/// 44 × 26 box are three near-identical grey combs, which is the same failure
/// that bans the contour at thumbnail scale.
///
/// **D-2 · the yardage fallback, stated rather than hidden.** `my_course_books`
/// does not carry per-hole yardage (`api_course_holes.yardage` exists
/// server-side and is not selected), so a card with pars and no yardages draws
/// **height by par**, which makes 11 of 18 bars identical. That is a weaker
/// picture and it is still real. `hasYardage` says which one you are looking
/// at, so a surface can tell the truth about it.
public struct CSDrawnCard: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize

  /// One hole, as the phone's own course book holds it. **`par` is required**:
  /// a hole with no par is not a hole the card can draw, and a defaulted 4
  /// would be the invention this component exists to refuse.
  public struct Hole: Sendable, Equatable, Identifiable {
    public let number: Int
    public let par: Int
    public let si: Int?
    public let yards: Int?
    public var id: Int { number }
    public init(number: Int, par: Int, si: Int? = nil, yards: Int? = nil) {
      self.number = number; self.par = par; self.si = si; self.yards = yards
    }
  }

  public enum Scale: Sendable {
    /// Full-bleed, on a plate or a hero. Eighteen bars, numbered.
    case hero
    /// ≤64pt, in a row. The front nine, three heights by par, no numerals.
    case thumb
  }

  let holes: [Hole]
  let scale: Scale
  /// The tallest bar never runs into the copy above it. The plate clamps it to
  /// its own height less the head block; `course.md` §13(b) asked for exactly
  /// this after the render's tallest bar ended 7pt under the eyebrow.
  let ceiling: CGFloat

  public init(_ holes: [Hole], scale: Scale = .hero, ceiling: CGFloat = 1) {
    self.holes = holes.sorted { $0.number < $1.number }
    self.scale = scale
    self.ceiling = min(1, max(0.2, ceiling))
  }

  /// Whether the bars are drawn from real per-hole yardage or from par (D-2).
  public var hasYardage: Bool { holes.contains { ($0.yards ?? 0) > 0 } }

  /// The bars actually drawn: eighteen at hero, the front nine at thumbnail.
  var drawn: [Hole] { scale == .thumb ? Array(holes.prefix(9)) : Array(holes.prefix(18)) }

  /// The hardest hole by stroke index — the one bar that takes the metal.
  /// nil when no hole carries an SI, and then no bar is marked.
  var hardest: Int? { drawn.filter { $0.si != nil }.min { ($0.si ?? 99) < ($1.si ?? 99) }.map(\.number) }

  public var body: some View {
    GeometryReader { geo in
      let gap: CGFloat = scale == .thumb ? 1.5 : 3
      // §16.3 · at the accessibility sizes eighteen numerals at 25pt across a
      // 362pt measure are eighteen ellipses. The bars keep their shape and the
      // page's own facts line still says which hole plays hardest.
      let numerals = scale == .hero && !typeSize.isA11y
      let numeralRoom: CGFloat = numerals ? 15 : 0
      let field = max(1, geo.size.height - numeralRoom)
      let widths = self.widths(in: geo.size.width, gap: gap)
      HStack(alignment: .bottom, spacing: gap) {
        ForEach(Array(drawn.enumerated()), id: \.element.id) { i, h in
          VStack(spacing: 2) {
            Rectangle()
              // **THE BARS ARE THE COURSE, NOT A CHART.** Eighteen neutral grey
              // bars on near-black read as a bar chart — the "generic SaaS
              // dashboard" §1 warns about, arriving through the one image rung
              // most courses can actually render. `course-page-noimage.png`
              // draws them at **#4A6155**, which is `ground.rule`'s own dark
              // value: sampled off the artboard, not chosen here, and 2.7:1 on
              // the pinned `ceremony` ground against the 1.3:1 the neutral was
              // giving. The gold #1-stroke bar is unchanged and is still the
              // surface's one earned object.
              .fill(h.number == hardest && scale == .hero ? cs.gold : barGreen)
              .frame(height: max(3, field * height(h)))
            if numerals {
              Text("\(h.number)")
                .csType(.columnS)
                .foregroundStyle(cs.mut.opacity(CSTokens.Alpha.a56))
                .lineLimit(1).minimumScaleFactor(0.7)
            }
          }
          .frame(width: widths[min(i, widths.count - 1)], alignment: .bottom)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
      .padding(scale == .thumb ? CSTokens.Space.s1 : 0)
    }
    // At thumbnail scale the card carries its own ground, because a row's left
    // column is an OBJECT — a little printed card — and because a container
    // shape is CSDesign's to draw, never a surface's (`LINT-10`).
    .background(thumbGround)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(spoken)
    // the one bar that takes the metal — counted, like every other gold object
    .csBudget(gold: hardest != nil && scale == .hero ? 1 : 0)
  }

  /// The bars' own green. On a **hero** plate it is the pinned dark value,
  /// because that plate is pinned `ceremony` in both printings; on a
  /// **thumbnail** the card sits on `bg1` in the reader's own theme, so the
  /// bars take the theme's rule.
  private var barGreen: Color {
    scale == .hero ? CSTokens.dark.rule : cs.rule
  }

  @ViewBuilder private var thumbGround: some View {
    if scale == .thumb {
      RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous).fill(cs.bg1)
    }
  }

  /// **Width by par.** Three widths, in proportion, so a par 5 is visibly a
  /// long hole and a par 3 a short one before a single number is read.
  func widths(in measure: CGFloat, gap: CGFloat) -> [CGFloat] {
    let weights = drawn.map { w($0.par) }
    let total = weights.reduce(0, +)
    let usable = max(1, measure - gap * CGFloat(max(0, drawn.count - 1)))
    guard total > 0 else { return drawn.map { _ in usable / CGFloat(max(1, drawn.count)) } }
    return weights.map { usable * $0 / total }
  }

  private func w(_ par: Int) -> CGFloat {
    switch par {
    case ...3: 0.78
    case 5...: 1.30
    default: 1.0
    }
  }

  /// **Height by yardage where there is yardage, by par where there is not.**
  /// Normalised across the card's own range rather than against an absolute
  /// scale, so a short course does not draw as a flat line and a long one does
  /// not clip. Returned as a fraction of the field, capped by `ceiling`.
  func height(_ h: Hole) -> CGFloat {
    if hasYardage {
      let ys = drawn.compactMap { $0.yards }.filter { $0 > 0 }
      let lo = CGFloat(ys.min() ?? 0), hi = CGFloat(ys.max() ?? 1)
      guard hi > lo, let y = h.yards, y > 0 else { return 0.5 * ceiling }
      return (0.32 + 0.68 * (CGFloat(y) - lo) / (hi - lo)) * ceiling
    }
    switch h.par {
    case ...3: return 0.38 * ceiling
    case 5...: return 1.00 * ceiling
    default: return 0.68 * ceiling
    }
  }

  /// §10.2 · **a plate never carries a caption that teaches the reader how to
  /// read it**, so the drawn card says nothing on screen. It says this to the
  /// ear, once, because a graphic with no alternative is a graphic a blind
  /// golfer does not get.
  var spoken: String {
    let n = drawn.count
    guard n > 0 else { return "" }
    let base = "The card, drawn: \(n) hole\(n == 1 ? "" : "s")"
    guard let hard = hardest, let h = drawn.first(where: { $0.number == hard }) else { return base + "." }
    return base + ". The \(CSOrdinal.spoken(h.number)) plays hardest."
  }
}

// MARK: - The star rail

/// Five drawn stars, **filled `ink` / unfilled `rule`**, halves by CLIPPING —
/// so there is one star shape in the product rather than a second half-star
/// glyph that has to be drawn to match.
///
/// `unrated` is **not a smaller control**: it is the full-size rail, unfilled,
/// stroked in `mut`, because a shrunken control is how "nobody has rated this"
/// becomes indistinguishable from "there is nothing here" (§9.11).
public struct CSStarRail: View {
  @Environment(\.cs) private var cs
  let value: Double
  let size: CGFloat
  /// The unfilled outline's tone. `mut` when the whole rail is empty — an
  /// unrated course still shows a rail a golfer can see.
  let unrated: Bool
  public init(_ value: Double, size: CGFloat = 22, unrated: Bool = false) {
    self.value = value; self.size = size; self.unrated = unrated
  }
  public var body: some View {
    HStack(spacing: CSTokens.Space.s1) {
      ForEach(0..<5, id: \.self) { i in
        ZStack(alignment: .leading) {
          // **A filled star is FILLED.** The glyph family strokes every mark,
          // and a stroked star masked at 50% reads as five outlines in two
          // greys — "not rated" and "four and a half" drew the same picture.
          // The star is the one mark in the family with a filled state,
          // because filling it is what the rating MEANS.
          CSStarShape().stroke(lineWidth: 1.4)
            .foregroundStyle(unrated ? cs.mut : cs.rule)
            .frame(width: size, height: size)
          CSStarShape().fill(cs.ink)
            .frame(width: size, height: size)
            .mask(alignment: .leading) {
              Rectangle().frame(width: size * CGFloat(min(1, max(0, value - Double(i)))))
            }
        }
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(unrated && value == 0 ? "Not rated" : CSStarRail.spoken(value))
  }

  /// *"four and a half stars"* — the value a golfer HEARS, and the value the
  /// adjustable control in the rating sheet announces on every half step.
  public static func spoken(_ v: Double) -> String {
    let whole = Int(v)
    let half = v - Double(whole) >= 0.5
    let words = ["zero", "one", "two", "three", "four", "five"]
    let w = words[min(5, max(0, whole))]
    if half { return "\(w) and a half stars" }
    return whole == 1 ? "one star" : "\(w) stars"
  }
}

/// The star, as a `Shape` rather than as a stroked glyph, so it can be filled.
/// It is the SAME path `CSGlyph.Name.star` draws — one star in the product, at
/// two weights — and it is closed, which is what makes a fill legal.
struct CSStarShape: Shape {
  func path(in r: CGRect) -> Path {
    let scale = min(r.width, r.height) / 24
    var p = SVGPath.path(CSGlyph.Name.star.path)
      .applying(CGAffineTransform(scaleX: scale, y: scale))
    p.closeSubpath()
    return p
  }
}

// MARK: - The rating (D275)

/// The rating block: the community's number as a rule-and-figure **in `ink`**,
/// the drawn rail beside it, one sentence naming your golfers' number, and one
/// tertiary link. Two columns, `s4` apart; stacked at the accessibility sizes.
///
/// **There is no gold on this object in any state.** An average of opinions is
/// not earned, and its weight comes from size and the rule (D275).
public struct CSRating: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize

  /// nil = **not rated**, which is a state and not an error: the rail draws
  /// full size and unfilled, and the link still says `Rate it`.
  let value: Double?
  let count: Int
  /// *"Your golfers give it {4.9}."* — braces mark the figure run; nil when
  /// none of your golfers has rated it.
  let sentence: String?
  let rate: (() -> Void)?

  public init(value: Double?, count: Int, sentence: String?, rate: (() -> Void)? = nil) {
    self.value = value; self.count = count; self.sentence = sentence; self.rate = rate
  }

  public var body: some View {
    if typeSize.isA11y {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) { figure; rail; line; door }
    } else {
      HStack(alignment: .top, spacing: CSTokens.Space.s4) {
        figure.frame(width: 132, alignment: .leading)
        VStack(alignment: .leading, spacing: CSTokens.Space.s3) { rail; line; door }
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  @ViewBuilder private var figure: some View {
    if let value {
      CSFigure(CSRating.format(value), size: .l, metal: .ink,
               label: "Cup Season · \(count) rating\(count == 1 ? "" : "s")")
    }
  }

  @ViewBuilder private var rail: some View {
    CSStarRail(value ?? 0, unrated: value == nil)
  }

  @ViewBuilder private var line: some View {
    if let sentence, !sentence.isEmpty {
      CSFigureRun(sentence, role: .body).foregroundStyle(cs.mut)
    } else if value == nil {
      // §9.11 verbatim, and "rating" rather than "card": T-01 collapsed that
      // noun to the person, and the mockup's `THE FIRST CARD SETS THE NUMBER`
      // aims it at a third object.
      Text("Not rated · the first rating sets the number")
        .csType(.agateS, caps: true).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  @ViewBuilder private var door: some View {
    if let rate {
      // `.content`, never `.live`: the rating is not this screen's live
      // action, so the link keeps the shape and loses the metal (D269).
      Button("Rate it", action: rate).buttonStyle(.csTertiary(.content))
    }
  }

  /// `4.6` — one decimal, always, so the figure never changes width as the
  /// mean moves.
  public static func format(_ v: Double) -> String { String(format: "%.1f", v) }
}

// MARK: - The plate

/// The course hero: the ladder's image, the product's only scrim, and the head
/// block reversed out of it — an eyebrow, the name in `display`, an optional
/// second title line when the club and the course differ, the place, and one
/// bone panel carrying your best here.
///
/// **Type on the scrim is never a palette token**: `ink` over a photograph is a
/// coincidence, not a contrast ratio. The four text elements take `scrimInk`
/// and `scrimMut`, and the credit under `.top` takes `scrimInk` too, because
/// `.top` only reaches `a72` and a `scrimMut` caption computes at 4.15:1 over
/// the brightest subject the product prints (`CSPhotoScrim.ink`).
///
/// **At AX3 the foot block leaves the image** (§4.1): the plate becomes a
/// 200pt band carrying only the credit, and the eyebrow, name, place and panel
/// set below it on the page's own ground. Reversing 34pt-grown type out of a
/// photograph is not a contrast claim anyone can make.
public struct CSCoursePlate<Plate: View, Panel: View>: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize

  let eyebrow: String?
  let name: String
  /// `DINOSAUR MOUNTAIN` — the course, when the club is the headline.
  let course: String?
  let place: String?
  /// `GALEN'S ROUND · AUG 24`. **A drawn plate has no photographer**, so this
  /// is nil on rungs 2 and 3 — §10.2 forbids a caption that teaches the reader
  /// how to read the graphic.
  let credit: String?
  let height: CGFloat
  /// Room the head block leaves ABOVE itself, for a plate whose content is a
  /// GRAPHIC rather than a photograph. Copy reversed out of a photograph sits
  /// on the picture — that is the whole move — but copy over the drawn card's
  /// bars sits on a bar chart, so the drawn state reserves the band its bars
  /// occupy and the plate grows by exactly that much.
  let reserve: CGFloat
  let panel: Panel
  let plate: Plate

  public init(eyebrow: String? = nil, name: String, course: String? = nil, place: String? = nil,
              credit: String? = nil, height: CGFloat = 252, reserve: CGFloat = 0,
              @ViewBuilder panel: () -> Panel = { EmptyView() },
              @ViewBuilder plate: () -> Plate) {
    self.eyebrow = eyebrow; self.name = name; self.course = course; self.place = place
    self.credit = credit; self.height = height; self.reserve = reserve
    self.panel = panel(); self.plate = plate()
  }

  public var body: some View {
    if typeSize.isA11y {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        band(height: 200, copy: false)
        head(over: false).padding(.horizontal, CSTokens.Space.gutter)
      }
    } else {
      band(height: height, copy: true)
    }
  }

  private func band(height: CGFloat, copy: Bool) -> some View {
    ZStack(alignment: .bottomLeading) {
      plate.frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
      if copy { CSPhotoScrim.layer(CSPhotoScrim.title) }
      // the status-bar band: without it the credit, the back chevron and the
      // clock sit on raw image, and over a real sunrise the credit is 1.48:1
      VStack(spacing: 0) {
        CSPhotoScrim.layer(CSPhotoScrim.top).frame(height: CSPhotoScrim.topHeight)
        Spacer(minLength: 0)
      }
      if let credit {
        VStack(spacing: 0) {
          HStack {
            Spacer(minLength: 0)
            Text(credit).csType(.agateS, caps: true)
              .foregroundStyle(CSPhotoScrim.ink(CSPhotoScrim.top, caption: true))
          }
          .padding(.horizontal, CSTokens.Space.gutter)
          .padding(.top, 58)
          Spacer(minLength: 0)
        }
      }
      if copy {
        // D-8 fixes the plate at 252 — 29% of the frame — and that is a
        // MINIMUM here: `PAPAGO GOLF COURSE` sets on two lines at `display` 34,
        // and a fixed height would put a headline through the picture or the
        // drawn card's bars through the eyebrow.
        head(over: true).padding(CSTokens.Space.gutter).padding(.top, reserve)
      }
    }
    .frame(minHeight: height)
    .frame(maxWidth: .infinity)
    .clipped()
  }

  @ViewBuilder private func head(over scrim: Bool) -> some View {
    // **At the accessibility sizes the panel leaves the row.** `display` grows
    // to 54 and the panel grows with its own numeral, and the two cannot share
    // a 362pt measure: the first build's AX3 shot broke `PAPAGO GOLF COURSE`
    // mid-word into `PAPAG / O GOLF / COURS / E`, because a headline squeezed
    // into 150pt wraps by character. The panel goes under the name instead.
    if typeSize.isA11y {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        headText(over: scrim)
        panel
      }
    } else {
      HStack(alignment: .bottom, spacing: CSTokens.Space.s3) {
        headText(over: scrim)
          .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        panel
      }
    }
  }

  @ViewBuilder private func headText(over scrim: Bool) -> some View {
    let ink = scrim ? CSTokens.dark.scrimInk : cs.ink
    let mut = scrim ? CSTokens.dark.scrimMut : cs.mut
    Group {
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        if let eyebrow {
          Text(eyebrow).csType(.agate, caps: true).foregroundStyle(mut)
            .fixedSize(horizontal: false, vertical: true)
        }
        VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
          // a course headline WRAPS; the tail-ellipsis policy is for rows
          Text(name).csType(.display).foregroundStyle(ink)
            .fixedSize(horizontal: false, vertical: true)
          if let course, !course.isEmpty {
            Text(course).csType(.displayS).foregroundStyle(mut)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        if let place, !place.isEmpty {
          Text(place).csType(.agate, caps: true).foregroundStyle(mut)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }
}

// MARK: - The facts, as one line of type

/// `72 PAR · 7,068 YDS · 72.5 RTG · 130 SLOPE` — **one line of type**, and the
/// audit's single most-named defect on this surface is what it replaces: four
/// bordered KPI tiles in a 2×2 grid, "the canonical SaaS dashboard pattern",
/// scoring the lowest brand and emotion cells on the whole board.
///
/// The figures are `figureS` 20 tabular in `ink`; the units are `agateS` in
/// `mut`; the separator is a GLYPH at `a56`, not a word. At the accessibility
/// sizes it becomes a stacked list — label leading, figure trailing (§16.3).
public struct CSFactsLine: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize

  public struct Fact: Identifiable, Sendable, Equatable {
    public let value: String
    public let unit: String
    public var id: String { unit + value }
    public init(_ value: String, _ unit: String) { self.value = value; self.unit = unit }
  }

  let facts: [Fact]
  /// **The object's own label** (D-1): the tee it describes, the difficulty
  /// fact the cached card can prove, and L-32's provenance verbatim — sitting
  /// UNDER the figures it qualifies rather than as the first paragraph a
  /// golfer reads about a golf course.
  let label: String?
  let spoken: String?

  public init(_ facts: [Fact], label: String? = nil, spoken: String? = nil) {
    self.facts = facts; self.label = label; self.spoken = spoken
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      if typeSize.isA11y { stacked } else { line }
      if let label, !label.isEmpty {
        Text(label).csType(.agateS, caps: true).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(spoken ?? plain)
  }

  private var line: some View {
    HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s2) {
      ForEach(Array(facts.enumerated()), id: \.element.id) { i, f in
        if i > 0 {
          Text("·").csType(.agateS).foregroundStyle(cs.mut.opacity(CSTokens.Alpha.a56))
        }
        HStack(alignment: .firstTextBaseline, spacing: 3) {
          Text(f.value).csType(.figureS).foregroundStyle(cs.ink)
          Text(f.unit).csType(.agateS, caps: true).foregroundStyle(cs.mut)
        }
      }
    }
    .lineLimit(1)
    .minimumScaleFactor(0.8)
  }

  private var stacked: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      ForEach(facts) { f in
        HStack(alignment: .firstTextBaseline) {
          Text(f.unit).csType(.agate, caps: true).foregroundStyle(cs.mut)
          Spacer(minLength: CSTokens.Space.s3)
          Text(f.value).csType(.figureS).foregroundStyle(cs.ink)
        }
      }
    }
  }

  var plain: String { facts.map { "\($0.value) \($0.unit)" }.joined(separator: ", ") }
}

// MARK: - The pull quote

/// The course page's **one serif appearance** — and it is a pull QUOTE rather
/// than a headline, which is what keeps this surface from reading like Home
/// (§15.3). `story` 20, sentence case, the opening quote **hung 9pt into the
/// margin**, the attribution beneath with the gross as a figure run.
///
/// **The block does not render at all when there is no such post.** It is
/// never a placeholder, never a stock line, and never a caption about the
/// course written by us.
public struct CSQuote: View {
  @Environment(\.cs) private var cs
  let text: String
  /// *"Jade, after an {82} here on Aug 30."* — braces mark the figure run.
  let attribution: String?

  public init(_ text: String, attribution: String? = nil) {
    self.text = text; self.attribution = attribution
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      Text("\u{201C}\(text)\u{201D}")
        .csType(.story).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
        // the opening quote hangs into the margin: a quote mark set flush is
        // an indent nobody asked for
        .padding(.leading, -9)
      if let attribution, !attribution.isEmpty {
        CSFigureRun(attribution, role: .body).foregroundStyle(cs.mut)
      }
    }
    .accessibilityElement(children: .combine)
  }
}
