// Cup Season — the chrome and the drawn glyph family (UI_SYSTEM §5, §12).
//
// ONE DRAWN FAMILY, AT THE MARKERS' OWN STROKE WEIGHT. Every glyph the product
// draws — the fourteen markers, the five tab glyphs, the movement triangles,
// the live dot, the star, the pennant, the empty-state objects, the scorecard
// rings and boxes — is 1.7pt on a 24 × 24 box, round caps and joins, no fill,
// `currentColor`. Put a marker beside a tab glyph and they are one hand; that
// is the test, and the shipped product fails it by 40pt — a filled SF mass
// beside a 1.8pt hairline.
//
// Tints: three. `mut` at rest, `ink` when selected or primary,
// `panelInk`/`leafInk` inside a panel or a leaf. **Never a metal**, with two
// exceptions that both mean something: the ⊕ Play glyph (ember, because it IS
// the live action) and the medallion's marker (gold, because it means "this is
// theirs").

import SwiftUI

// MARK: - The glyph

public struct CSGlyph: View {
  /// **The glyph's name IS its accessibility label**, which is why the empty
  /// schedule is `scheduleSheet` and reads "schedule sheet" — "tee sheet" is a
  /// retired noun and `TERMINOLOGY` §4's scope explicitly covers
  /// `.accessibilityLabel`.
  public enum Name: String, CaseIterable, Sendable {
    // the tab band's five
    case home, pennant, play, people, card
    // furniture
    case check, cross, chevron, star, dot, share, search, more, plus
    // the empty-state objects — **two absences never share one**
    case scorecard        // you have no rounds
    case emptyRail        // a board with nobody on it
    case scheduleSheet    // nothing is scheduled
    case rack             // no trophies yet
    case bag              // nothing in the bag

    /// One 24 × 24 path, stroked. Round caps, round joins, no fill.
    var path: String {
      switch self {
      case .home: "M3 11l9-7 9 7M6 10v10h12V10"
      case .pennant: "M6 21V3M6 4.5c4-2.2 8 2 12-.2v7.4c-4 2.2-8-2-12 .2"
      case .play: "M12 3.5a8.5 8.5 0 100 17 8.5 8.5 0 000-17M12 8v8M8 12h8"
      case .people: "M9.2 11.4a3.1 3.1 0 100-6.2 3.1 3.1 0 000 6.2M3.6 20.2c0-3.4 2.5-5.7 5.6-5.7s5.6 2.3 5.6 5.7M16.4 7.6a2.4 2.4 0 010 4.8M17.4 14.8c2.1.5 3.2 2.4 3.2 5"
      case .card: "M3 6h18v12.5H3zM8.6 12.2a2 2 0 100-4 2 2 0 000 4M6 15.6h5.2M13.8 10h4.6M13.8 13.4h4.6"
      case .check: "M4.5 12.6l4.8 4.8L19.5 7"
      case .cross: "M6 6l12 12M18 6L6 18"
      case .chevron: "M9 4.5l7.5 7.5L9 19.5"
      case .star: "M12 3.8l2.5 5.2 5.7.8-4.1 4 1 5.6-5.1-2.7-5.1 2.7 1-5.6-4.1-4 5.7-.8z"
      case .dot: "M12 8.4a3.6 3.6 0 100 7.2 3.6 3.6 0 000-7.2"
      case .share: "M12 15.5V4M8 7.5L12 3.5l4 4M5 13v7.5h14V13"
      case .search: "M10.8 4.5a6.3 6.3 0 100 12.6 6.3 6.3 0 000-12.6M15.4 15.4l4.6 4.6"
      case .more: "M6 12h.01M12 12h.01M18 12h.01"
      case .plus: "M12 5v14M5 12h14"
      case .scorecard: "M4.5 3h15v18h-15zM4.5 8.4h15M4.5 13.2h15M4.5 18h15M9.5 3v18M14.5 3v18"
      case .emptyRail: "M3.5 4h5.5v16H3.5zM12 7h8.5M12 12h8.5M12 17h8.5"
      case .scheduleSheet: "M4 5.5h16V21H4zM4 10.5h16M8.5 3v4.5M15.5 3v4.5M8 14.5h3M13 14.5h3"
      case .rack: "M4 20.5h16M6.5 20.5V8.5h11v12M6.5 13h11M10 8.5V4h4v4.5"
      case .bag: "M8.5 9.5V5.6a2.6 2.6 0 015.2 0v3.9M6.5 9.5h9.5c1 0 1.8.9 1.7 1.9l-.9 8.7H5.7l-.9-8.7c-.1-1 .7-1.9 1.7-1.9M10 3.2v2.2M12 2.6v2.8M14 3.4v2"
      }
    }

    /// What VoiceOver says. The name, in the product's words.
    public var spoken: String {
      switch self {
      case .scheduleSheet: "schedule sheet"
      case .emptyRail: "empty rail"
      case .play: "play"
      case .more: "more"
      default: rawValue
      }
    }
  }

  /// Four sizes, from a token. Empty-state objects are 56–76 and are the one
  /// exception, stated.
  public enum Size: CGFloat, Sendable { case inline = 13, row = 17, tab = 22, block = 28, empty = 64 }

  let name: Name
  let size: CGFloat
  let labelled: Bool

  public init(_ name: Name, size: Size = .row, labelled: Bool = false) {
    self.name = name; self.size = size.rawValue; self.labelled = labelled
  }
  public init(_ name: Name, points: CGFloat, labelled: Bool = false) {
    self.name = name; self.size = points; self.labelled = labelled
  }

  public var body: some View {
    let scale = size / 24
    // the live dot is the family's one filled mark; everything else is a stroke
    Group {
      if name == .dot {
        Circle().frame(width: size * 0.3, height: size * 0.3)
      } else {
        SVGPath.path(name.path)
          .applying(CGAffineTransform(scaleX: scale, y: scale))
          .stroke(style: StrokeStyle(lineWidth: 1.7 * scale, lineCap: .round, lineJoin: .round))
      }
    }
    .frame(width: size, height: size)
    .accessibilityLabel(labelled ? name.spoken : "")
    .accessibilityHidden(!labelled)
  }
}

// MARK: - The masthead

/// Home only, and it is the reason Home reads as an edition of something
/// rather than a screen: **the 22pt pennant · `s2` · the wordmark · the
/// dateline in agate flush right · a 2pt `ink` rule beneath, full measure.**
/// No ember tick — the masthead is not live — no sky wash, no second ground.
///
/// **The wordmark keeps the canon setting** — IBM Plex Mono 600, tracked
/// 0.32em, always caps, at 30pt. `brand/README.md` states that as a rule and
/// the two lockups plus the og-image are all GENERATED from it, so re-cutting
/// it here would ship two different wordmarks: one on Home, one in every email
/// and link preview. Re-cutting a wordmark is a brand decision the canon
/// reserves to the owner.
public struct CSMasthead: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let date: Date
  let calendar: Calendar
  public init(date: Date = Date(), calendar: Calendar = .current) {
    self.date = date; self.calendar = calendar
  }

  /// `SUN · SEP 6`.
  public static func dateline(_ d: Date, calendar: Calendar = .current) -> String {
    let f = DateFormatter(); f.calendar = calendar; f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "EEE · MMM d"
    return f.string(from: d).uppercased()
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      // At the default size `CUP SEASON` at 30pt measures 169pt and the
      // dateline 65pt — 234 of the 362 measure. At AX3 a capped wordmark is
      // 271pt and even a capped dateline is 141: 412 into 362, so the single
      // row fails at AX2. From AX1 up the dateline takes its own line and the
      // wordmark WRAPS rather than truncating — it is the product's name, and
      // the tail-ellipsis policy must never reach it.
      if typeSize.isA11y {
        wordmarkRow
        Text(Self.dateline(date, calendar: calendar)).csType(.agate, caps: true).foregroundStyle(cs.mut)
      } else {
        HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s2) {
          wordmarkRow
          Spacer(minLength: CSTokens.Space.s2)
          Text(Self.dateline(date, calendar: calendar)).csType(.agate, caps: true).foregroundStyle(cs.mut)
        }
      }
      CSRule(.heavy)
    }
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isHeader)
  }

  private var wordmarkRow: some View {
    HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s2) {
      CSGlyph(.pennant, size: .tab).foregroundStyle(cs.ink).alignmentGuide(.firstTextBaseline) { $0[.bottom] - 2 }
      Text("Cup Season")
        .font(.custom(CSType.monoMedium, size: 30, relativeTo: .largeTitle))
        .tracking(30 * 0.32)
        .textCase(.uppercase)
        .foregroundStyle(cs.ink)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

// MARK: - The tab band

/// A full-width band on the page's own ground with a 1px `rule` on top. **No
/// floating pill, no glass, no capsule, no fill.** 74pt + the safe area.
///
/// Because the band sits on the page's ground with a rule, there is nothing to
/// float over and nothing to guillotine: a card sliced through its own glyphs
/// mid-scroll stops being a mitigation and becomes a non-event.
public struct CSTabBand<T: Hashable>: View {
  @Environment(\.cs) private var cs
  public struct Item: Identifiable {
    public let id: T
    public let glyph: CSGlyph.Name
    public let label: String
    /// Play is the drawn ⊕ **in `brand`** with `PLAY` in `brand` — no fill, no
    /// disc, no square. It is the only coloured thing in the chrome, and it is
    /// a glyph, so it can no longer be the loudest object on every signed-in
    /// screen.
    public let isPlay: Bool
    public init(id: T, glyph: CSGlyph.Name, label: String, isPlay: Bool = false) {
      self.id = id; self.glyph = glyph; self.label = label; self.isPlay = isPlay
    }
  }
  let items: [Item]
  @Binding var selection: T
  let onPlay: () -> Void
  public init(_ items: [Item], selection: Binding<T>, onPlay: @escaping () -> Void = {}) {
    self.items = items; _selection = selection; self.onPlay = onPlay
  }

  public var body: some View {
    VStack(spacing: 0) {
      CSRule()
      HStack(spacing: 0) {
        ForEach(items) { item in
          let on = item.id == selection
          Button {
            if item.isPlay { CSHaptic.present(); onPlay() }
            else { selection = item.id; CSHaptic.selection() }
          } label: {
            VStack(spacing: CSTokens.Space.s1) {
              CSGlyph(item.glyph, size: .tab)
              Text(item.label).csType(.agateS, caps: true)
              Rectangle()
                .fill(on && !item.isPlay ? cs.ink : Color.clear)
                .frame(width: 26, height: 2)
            }
            .foregroundStyle(item.isPlay ? cs.brand : (on ? cs.ink : cs.mut))
            .frame(maxWidth: .infinity, minHeight: 74)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel(item.label)
          .accessibilityAddTraits(on ? [.isSelected] : [])
        }
      }
    }
    .background(cs.bg0)
  }
}

// MARK: - The money line

/// **Money is `ink`; the pot and anything won are `gold`; `pos` and `neg`
/// never touch money; the sign is a WORD in agate** — `YOU OWE` · `YOU'RE
/// OWED` · `SETTLED` · `THE POT` (D273).
///
/// A red/green P&L axis is the grammar of a brokerage, and "overly minimalist
/// fintech app" is the named thing this product is not. A negative figure takes
/// a minus sign in ink, never a red fill.
public struct CSStakeLine: View {
  public enum Sign: String, Sendable {
    case owe = "You owe", owed = "You're owed", settled = "Settled", pot = "The pot"
    var earned: Bool { self == .pot || self == .owed }
  }
  let sign: Sign
  let amount: String
  let ledger: String?
  @Environment(\.cs) private var cs

  public init(_ sign: Sign, amount: String, ledger: String? = nil) {
    self.sign = sign; self.amount = amount; self.ledger = ledger
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      CSFigure(amount, size: .l, metal: sign.earned ? .earned : .ink, label: sign.rawValue)
      if let ledger {
        // the ledger line renders VERBATIM from one constant, once per
        // scrolling surface, under the first money figure that surface shows
        Text(ledger).csType(.bodyS).foregroundStyle(cs.mut)
      }
    }
  }
}

// MARK: - The me strip

/// Two to four figures on ONE shared rule with their agate labels beneath, and
/// **the league sentence in agate under the whole block**:
/// `THE FELLAS · 2ND OF 8 · 4 BACK OF GALEN`.
///
/// One agate sentence does more competitive work than any chip, and it names
/// the rival. It is type on the page's ground: **no box, no border, no radius
/// and no `CSStat`.**
public struct CSFactStrip: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  public struct Cell: Identifiable, Sendable {
    public let id = UUID()
    public let value: String
    public let label: String
    public let ordinal: String?
    public init(value: String, label: String, ordinal: String? = nil) {
      self.value = value; self.label = label; self.ordinal = ordinal
    }
  }
  let cells: [Cell]
  /// The standing line, and it names the rival.
  let standing: String?
  public init(_ cells: [Cell], standing: String? = nil) { self.cells = cells; self.standing = standing }

  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      A11yStack(spacing: CSTokens.Space.s3, columnSpacing: CSTokens.Space.s3) {
        ForEach(cells) { c in
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            CSFigure(c.value, size: .m, label: nil, ordinal: c.ordinal)
            CSRule(.heavy)
            Text(c.label).csType(.agateS, caps: true).foregroundStyle(cs.mut)
          }
          .frame(maxWidth: typeSize.isA11y ? .infinity : nil, alignment: .leading)
        }
      }
      if let standing {
        Text(standing).csType(.agate, caps: true).foregroundStyle(cs.mut)
      }
    }
  }
}

// MARK: - The star rail and the rating

/// Five drawn stars, filled `ink` / unfilled `rule`, **halves by CLIPPING** —
/// so there is one star shape in the product rather than a second half-star
/// glyph that has to be drawn to match.
public struct CSStarRail: View {
  @Environment(\.cs) private var cs
  let value: Double
  let size: CGFloat
  public init(_ value: Double, size: CGFloat = 22) { self.value = value; self.size = size }
  public var body: some View {
    HStack(spacing: CSTokens.Space.s1) {
      ForEach(0..<5, id: \.self) { i in
        ZStack(alignment: .leading) {
          CSGlyph(.star, points: size).foregroundStyle(cs.rule)
          CSGlyph(.star, points: size).foregroundStyle(cs.ink)
            .mask(alignment: .leading) {
              Rectangle().frame(width: size * CGFloat(min(1, max(0, value - Double(i)))))
            }
        }
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(String(format: "%.1f of five", value))
  }
}

/// The rule-and-figure at 40 **in `ink`** + the star rail + one sentence + a
/// link. A course's rating is ink and never gold: **an average of opinions is
/// not earned.**
public struct CSRating: View {
  @Environment(\.cs) private var cs
  let value: Double
  let count: Int
  let sentence: String
  public init(value: Double, count: Int, sentence: String) {
    self.value = value; self.count = count; self.sentence = sentence
  }
  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      CSFigure(String(format: "%.1f", value), size: .l, metal: .ink, label: "\(count) ratings")
      CSStarRail(value)
      Text(sentence).csType(.bodyS).foregroundStyle(cs.mut)
    }
  }
}

// MARK: - The course

/// The course hero: a plate, `CSPhotoScrim.title`, the name reversed out, and
/// the credit.
public struct CSCoursePlate<Plate: View>: View {
  let name: String
  let credit: String?
  let plate: Plate
  public init(name: String, credit: String? = nil, @ViewBuilder plate: () -> Plate) {
    self.name = name; self.credit = credit; self.plate = plate()
  }
  public var body: some View {
    ZStack(alignment: .bottomLeading) {
      plate
      CSPhotoScrim.layer(CSPhotoScrim.title)
      VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
        Text(name).csType(.display).foregroundStyle(CSTokens.dark.scrimInk)
        if let credit {
          Text(credit).csType(.agateS, caps: false).foregroundStyle(CSTokens.dark.scrimMut)
        }
      }
      .padding(CSTokens.Space.gutter)
    }
    .clipped()
  }
}

/// `72 PAR · 7,068 YDS · 72.5 RTG · 130 SLOPE` — **one line of type**, and it
/// stays one line even at desk width. Four facts as four boxed tiles is the
/// lowest-scoring cell in the whole audit.
public struct CSFactsLine: View {
  @Environment(\.cs) private var cs
  let facts: [String]
  public init(_ facts: [String]) { self.facts = facts }
  public var body: some View {
    Text(facts.joined(separator: " · "))
      .csType(.agate, caps: true)
      .foregroundStyle(cs.mut)
      .lineLimit(2)
      .minimumScaleFactor(0.85)
  }
}

/// The course page's **one serif appearance**. New York never repeats on a
/// screen: it is the sentence a reader is meant to slow down for.
public struct CSQuote: View {
  @Environment(\.cs) private var cs
  let text: String
  let attribution: String?
  public init(_ text: String, attribution: String? = nil) {
    self.text = text; self.attribution = attribution
  }
  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      Text(text).csType(.story).foregroundStyle(cs.ink)
      if let attribution {
        Text(attribution).csType(.agateS, caps: true).foregroundStyle(cs.mut)
      }
    }
  }
}

// MARK: - The lead

/// Home's lead — **not a card**: a block on the ground. A plate, an eyebrow, a
/// headline, a standfirst and one door, with nothing drawn around them.
public struct CSStoryCard<Plate: View>: View {
  @Environment(\.cs) private var cs
  let eyebrow: String
  let live: Bool
  let headline: String
  let standfirst: String?
  let door: CSDoor.Kind?
  let plate: Plate

  public init(eyebrow: String, live: Bool = false, headline: String, standfirst: String? = nil,
              door: CSDoor.Kind? = nil, @ViewBuilder plate: () -> Plate) {
    self.eyebrow = eyebrow; self.live = live; self.headline = headline
    self.standfirst = standfirst; self.door = door; self.plate = plate()
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      plate
      HStack(spacing: CSTokens.Space.s2) {
        if live {
          CSGlyph(.dot, size: .inline).foregroundStyle(cs.brand)
        }
        Text(eyebrow).csType(.agate, caps: true).foregroundStyle(live ? cs.brand : cs.mut)
      }
      .csBudget(ember: live ? 1 : 0)
      Text(headline).csType(.lead).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
      if let standfirst {
        Text(standfirst).csType(.body).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
      if let door { CSDoor(door) }
    }
  }
}
