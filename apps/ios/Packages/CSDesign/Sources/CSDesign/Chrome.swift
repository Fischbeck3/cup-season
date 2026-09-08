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
    // the weather, drawn — `Weather.line` no longer embeds a literal `☀`
    // (`LINT-12`), so the mark is a path in this family at the family's own
    // stroke rather than an emoji in whatever face the sentence happens to be
    case sun, cloud
    // WAVE 8 · the four icon systems become one family (D277). SF Symbols
    // survived in nineteen places the seven surface waves never opened — a
    // camera on the composer, a calendar on the schedule, a bell on the push
    // prompt — and a system symbol beside a drawn one is two icon systems on
    // one row, at two stroke weights, in two optical sizes.
    case camera, photo, calendar, comment, bell, link, send, trash, gear, clock
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
      case .sun: "M12 8.2a3.8 3.8 0 100 7.6 3.8 3.8 0 000-7.6M12 3v2.4M12 18.6V21M3 12h2.4M18.6 12H21M5.6 5.6l1.7 1.7M16.7 16.7l1.7 1.7M18.4 5.6l-1.7 1.7M7.3 16.7l-1.7 1.7"
      case .cloud: "M7.6 18.5h9.1a3.7 3.7 0 00.4-7.4 5.3 5.3 0 00-10.1-.6 3.7 3.7 0 00.6 8"
      case .camera: "M3.5 7.8h3.6l1.5-2.3h6.8l1.5 2.3h3.6V19H3.5zM12 16.6a3.5 3.5 0 100-7 3.5 3.5 0 000 7"
      case .photo: "M3.5 5h17v14h-17zM3.5 15.4l4.8-4.4 3.5 3.2 3.6-3.9 5.1 5.1M8.2 9.4a1.5 1.5 0 100-3 1.5 1.5 0 000 3"
      case .calendar: "M4 5.5h16V21H4zM4 10.5h16M8.5 3v4.5M15.5 3v4.5"
      case .comment: "M4 5h16v11H9.5L5.5 20v-4H4z"
      case .bell: "M12 3.2a5.4 5.4 0 015.4 5.4c0 4.6 1.6 6.4 1.6 6.4H5s1.6-1.8 1.6-6.4A5.4 5.4 0 0112 3.2M10.2 18.2a2 2 0 003.6 0"
      case .link: "M10.4 13.6a3.6 3.6 0 010-5.1l2.6-2.6a3.6 3.6 0 015.1 5.1l-1.3 1.3M13.6 10.4a3.6 3.6 0 010 5.1l-2.6 2.6a3.6 3.6 0 01-5.1-5.1l1.3-1.3"
      case .send: "M20.5 3.5L3.5 10.2l6.8 2.9M20.5 3.5l-6.7 17-2.9-6.8M20.5 3.5l-9.6 10.2"
      case .trash: "M4.5 6.5h15M9.5 6.5V3.5h5v3M6.5 6.5l1 14h9l1-14M10 10v7M14 10v7"
      case .gear: "M12 8.6a3.4 3.4 0 100 6.8 3.4 3.4 0 000-6.8M12 2.8l1.3 2.6 2.9-.5.6 2.9 2.6 1.4-1.4 2.6 1.4 2.6-2.6 1.4-.6 2.9-2.9-.5-1.3 2.6-1.3-2.6-2.9.5-.6-2.9-2.6-1.4L5.8 12 4.4 9.4 7 8l.6-2.9 2.9.5z"
      case .clock: "M12 3.5a8.5 8.5 0 100 17 8.5 8.5 0 000-17M12 7v5.4l3.6 2.2"
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
      case .comment: "comment"
      case .send: "send"
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
/// rather than a screen: **the wordmark · the dateline in agate flush right ·
/// a 2pt `ink` rule beneath, full measure.** No ember tick — the masthead is
/// not live — no sky wash, no second ground, and no pennant: `LINT-28` reserves
/// the flag to the tab band and the app icon, and `surfaces/home.md` §1.1 draws
/// the wordmark alone.
///
/// **THE WORDMARK IS SET IN `display`, WHICH IS A CHANGE OF FACE.** Wave 0b cut
/// it in Plex Mono 600 at 0.32em, the setting `brand/README.md` states and the
/// two lockups and the og-image are generated from. The design decided
/// otherwise: `home.md` §1.1 and all five artboards set it in the board face,
/// tight, because a 0.32em mono lockup on the page reads as a *logo pasted onto
/// a screen* where the board cut reads as a masthead. The generated lockups are
/// untouched, so the trade is real and stated: the wordmark on Home is now set
/// differently from the wordmark in an email. That is a brand decision the
/// canon reserves to the owner, and it is recorded in IOS-046 rather than made
/// quietly.
public struct CSMasthead: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let date: Date
  let calendar: Calendar
  /// **Stale rewrites the dateline IN PLACE** (§13.3) — `AS OF FRI 6:12 PM ·
  /// OFFLINE` — and nothing else on the page changes and no action is
  /// disabled. It is the one place the product says the read did not land.
  let asOf: Date?
  public init(date: Date = Date(), calendar: Calendar = .current, asOf: Date? = nil) {
    self.date = date; self.calendar = calendar; self.asOf = asOf
  }

  /// `SUN · SEP 6`.
  public static func dateline(_ d: Date, calendar: Calendar = .current) -> String {
    let f = DateFormatter(); f.calendar = calendar; f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "EEE · MMM d"
    return f.string(from: d).uppercased()
  }

  private var line: String {
    asOf.map { CSStale.line($0, calendar: calendar) } ?? Self.dateline(date, calendar: calendar)
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      // At the default size `CUP SEASON` measures ~187pt and the dateline 65 —
      // 252 of the 362 measure. At AX3 a capped wordmark is 300pt and even a
      // capped dateline is 141, so the single row fails at AX2. From AX1 up the
      // dateline takes its own line and the wordmark WRAPS rather than
      // truncating — it is the product's name, and the tail-ellipsis policy
      // must never reach it.
      if typeSize.isA11y {
        wordmark
        Text(line).csType(.agate, caps: true).foregroundStyle(cs.mut)
      } else {
        HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s2) {
          wordmark
          Spacer(minLength: CSTokens.Space.s2)
          Text(line).csType(.agate, caps: true).foregroundStyle(cs.mut)
            .lineLimit(1).fixedSize()
        }
      }
      CSRule(.heavy)
    }
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isHeader)
  }

  private var wordmark: some View {
    Text("Cup Season")
      .csType(.display)
      .foregroundStyle(cs.ink)
      .lineLimit(2)
      .fixedSize(horizontal: false, vertical: true)
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
  @Environment(\.dynamicTypeSize) private var typeSize
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
  /// D227 · a LONG PRESS on the ⊕ opens the composer with the score focused.
  /// The system tab bar had no gesture of its own and the recogniser had to be
  /// bolted onto a live `UITabBar`; a band the product draws simply takes one.
  let onPlayHold: () -> Void
  public init(_ items: [Item], selection: Binding<T>,
              onPlay: @escaping () -> Void = {}, onPlayHold: @escaping () -> Void = {}) {
    self.items = items; _selection = selection
    self.onPlay = onPlay; self.onPlayHold = onPlayHold
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
              // §16.3 · at AX3 the glyph grows to 28 — and **the label stays**.
              //
              // It used to drop, because five capped agate labels across 402pt
              // is 72pt a slot and `COMPETE` and `GOLFERS` broke in half and
              // printed `COMP/ETE` and `GOLFE/RS` under their own glyphs. But
              // the answer to a label that will not fit on one line is not to
              // delete it: **an unlabelled tab bar is worse than a taller
              // one**, and it is unlabelled for exactly the golfers most
              // likely to need the words. The label WRAPS instead, at
              // `agateS`'s own floor, and the band grows its height — which is
              // the same rule §16.3 applies to every other row in the product.
              CSGlyph(item.glyph, points: typeSize.isA11y ? 28 : CSGlyph.Size.tab.rawValue,
                      labelled: false)
              // **THE WORD STAYS WHOLE.** Wrapping printed `COMPE/TE` and
              // `GOLFER/S`, which is the shear the label used to be deleted to
              // avoid — a broken word is not a label. It SHRINKS instead: at
              // AX3 `agateS` renders ~25pt and 0.55 of that is ~14, still
              // above the default reading size and comfortably above the 11pt
              // floor, on the one row where five slots have to share 402pt.
              Text(item.label).csType(.agateS, caps: true)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(typeSize.isA11y ? 0.55 : 1)
                .fixedSize(horizontal: !typeSize.isA11y, vertical: true)
              Rectangle()
                .fill(on && !item.isPlay ? cs.ink : Color.clear)
                .frame(width: 26, height: 2)
            }
            .foregroundStyle(item.isPlay ? cs.brand : (on ? cs.ink : cs.mut))
            .frame(maxWidth: .infinity, minHeight: typeSize.isA11y ? 84 : 74)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .modifier(CSPlayHold(on: item.isPlay, act: onPlayHold))
          .accessibilityLabel(item.label)
          .accessibilityAddTraits(on ? [.isSelected] : [])
        }
      }
    }
    .background(cs.bg0)
  }
}

/// The ⊕'s long press, and only the ⊕'s.
struct CSPlayHold: ViewModifier {
  let on: Bool
  let act: () -> Void
  func body(content: Content) -> some View {
    if on {
      content.simultaneousGesture(LongPressGesture(minimumDuration: 0.35).onEnded { _ in
        CSHaptic.present(); act()
      })
    } else {
      content
    }
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

  /// **The rail holds THREE seats, and cells fill it from the left.**
  ///
  /// `justify-content: space-between` reads correctly at three and badly at
  /// two: two facts pushed to opposite screen edges look like a layout that
  /// lost its middle. So the strip is always three columns of the measure —
  /// three cells take leading · centre · trailing, and one or two take the
  /// left seats and leave the rest of the rule empty, which is what a strip
  /// with a fact missing should look like.
  public static let seats = 3

  public struct Cell: Identifiable {
    public let id: String
    public let value: String
    public let label: String
    public let ordinal: String?
    /// Every figure taps to its receipt (L-01) — a number a golfer cannot
    /// check is a number they have to take on trust.
    public let spoken: String?
    public let door: (() -> Void)?
    public init(id: String = UUID().uuidString, value: String, label: String,
                ordinal: String? = nil, spoken: String? = nil, door: (() -> Void)? = nil) {
      self.id = id; self.value = value; self.label = label
      self.ordinal = ordinal; self.spoken = spoken; self.door = door
    }
  }
  let cells: [Cell]
  /// The standing line, and it names the rival.
  let standing: String?
  /// The standing line's case: caps for `THE FELLAS · 26 WEEKS · 4 TO PLAY`,
  /// sentence for a gloss a person could read aloud (§1.3).
  let standingCaps: Bool
  public init(_ cells: [Cell], standing: String? = nil, standingCaps: Bool = true) {
    self.cells = cells; self.standing = standing; self.standingCaps = standingCaps
  }

  private func alignment(_ i: Int) -> Alignment {
    guard cells.count >= Self.seats else { return .leading }
    if i == 0 { return .leading }
    return i == cells.count - 1 ? .trailing : .center
  }

  private func textAlignment(_ i: Int) -> HorizontalAlignment {
    guard cells.count >= Self.seats else { return .leading }
    if i == 0 { return .leading }
    return i == cells.count - 1 ? .trailing : .center
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      if typeSize.isA11y {
        // §2's AX3 form: a stacked list, the label leading and the figure
        // trailing, and nothing scrolls sideways.
        VStack(alignment: .leading, spacing: 0) {
          ForEach(Array(cells.enumerated()), id: \.element.id) { _, c in
            cellButton(c) {
              HStack(alignment: .firstTextBaseline) {
                Text(c.label).csType(.agateS, caps: true).foregroundStyle(cs.mut)
                Spacer(minLength: CSTokens.Space.s3)
                CSFigure(c.value, size: .m, label: nil, ordinal: c.ordinal)
              }
              .frame(minHeight: 44)
            }
            CSRule(.heavy)
          }
        }
      } else {
        VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
          row { i, c in
            CSFigure(c.value, size: .m, label: nil, ordinal: c.ordinal)
              .frame(maxWidth: .infinity, alignment: alignment(i))
          }
          // ONE rule, the full measure, under all of them — the device the
          // whole strip is: a line of type on the page's own ground.
          CSRule(.heavy)
          row { i, c in
            Text(c.label).csType(.agateS, caps: true).foregroundStyle(cs.mut)
              .lineLimit(1).minimumScaleFactor(0.8)
              .frame(maxWidth: .infinity, alignment: alignment(i))
          }
        }
        .overlay { targets }
      }
      if let standing {
        Text(standing).csType(standingCaps ? .agate : .agateS, caps: standingCaps)
          .foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityLabel(standing)
      }
    }
  }

  @ViewBuilder private func row<V: View>(@ViewBuilder _ cell: @escaping (Int, Cell) -> V) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s2) {
      ForEach(Array(cells.enumerated()), id: \.element.id) { i, c in cell(i, c) }
      ForEach(cells.count..<max(cells.count, Self.seats), id: \.self) { _ in
        Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
      }
    }
  }

  /// The 44pt targets, laid over the two rows rather than inside them, so the
  /// figures and their labels stay on **one** rule and each pair is still one
  /// button and one VoiceOver element.
  private var targets: some View {
    HStack(spacing: CSTokens.Space.s2) {
      ForEach(Array(cells.enumerated()), id: \.element.id) { _, c in
        cellButton(c) { Color.clear.contentShape(Rectangle()) }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      ForEach(cells.count..<max(cells.count, Self.seats), id: \.self) { _ in
        Color.clear.frame(maxWidth: .infinity)
      }
    }
  }

  @ViewBuilder private func cellButton<V: View>(_ c: Cell, @ViewBuilder _ label: () -> V) -> some View {
    if let door = c.door {
      Button { CSHaptic.selection(); door() } label: { label() }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(c.spoken ?? "\(c.label), \(c.value)")
        .accessibilityAddTraits(.isButton)
    } else {
      label().accessibilityElement(children: .ignore).accessibilityLabel(c.spoken ?? "\(c.label), \(c.value)")
    }
  }
}

// The star rail, the rating, the course plate, the facts line and the pull
// quote moved to `Course.swift` in Wave 4, where they are built out to the
// surface spec — the ladder, the head block, the AX3 forms and the states.


// MARK: - The lead

/// Home's lead, weight 1 — **not a card**: a block on the ground. An eyebrow
/// with an optional live dot, a league tag flush right on its baseline, the
/// one serif sentence the viewport allows, a standfirst, one door — and an
/// **aside**, the 84pt trailing column that carries the rank chip.
///
/// **The door sits in the LEFT column, under the standfirst**, because the
/// door belongs to the sentence and not to the figure. **The aside is
/// optional and is never invented to fill the column**: an invitation, a
/// buddy request and a first round have no figure, so the sentence takes the
/// full measure and the block is type alone.
///
/// At the accessibility sizes the aside goes **full width above the eyebrow**
/// (§2), so the chip and the headline never fight over a 362pt measure.
public struct CSStoryCard<Aside: View>: View {
  @Environment(\.cs) private var cs
  /// D302 · the live dot and its eyebrow wear the look, not a fixed ember.
  @Environment(\.csLookAccent) private var la
  @Environment(\.dynamicTypeSize) private var typeSize
  let eyebrow: String
  let live: Bool
  /// `THE FELLAS` — the league, flush right on the eyebrow's baseline. Never a
  /// second sentence and never a count (§16A.2).
  let tag: String?
  /// The gold slot and the name beside it — `CHAMPION · MIKE FENNER`. The
  /// viewport's **one** gold object when it is present.
  let credit: (slot: String, name: String)?
  let headline: String
  let standfirst: String?
  let door: CSDoor.Kind?
  let aside: Aside

  public init(eyebrow: String, live: Bool = false, tag: String? = nil,
              credit: (slot: String, name: String)? = nil,
              headline: String, standfirst: String? = nil,
              door: CSDoor.Kind? = nil, @ViewBuilder aside: () -> Aside) {
    self.eyebrow = eyebrow; self.live = live; self.tag = tag; self.credit = credit
    self.headline = headline; self.standfirst = standfirst
    self.door = door; self.aside = aside()
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      eyebrowRow
      // §16.3, the lead block's AX3 row: **the panel goes full width, ABOVE
      // THE HEADLINE** — after the eyebrow, which is the block's own first
      // line and names what the panel is a figure about. It shipped above the
      // eyebrow, which put a rank chip on the page before anything said which
      // table it was a rank in.
      if typeSize.isA11y { aside.frame(maxWidth: .infinity, alignment: .leading) }
      if typeSize.isA11y {
        column
      } else {
        HStack(alignment: .top, spacing: CSTokens.Space.s4) {
          column
          aside
        }
      }
    }
    .accessibilityElement(children: .contain)
  }

  private var eyebrowRow: some View {
    HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s2) {
      if live {
        // §1.2 · a 7pt disc, and the glyph family's dot is 0.3 of its box —
        // so the box is 23 and the disc is 6.9. Named here rather than drawn
        // as a bare `Circle()`, which is a container shape (`LINT-10`).
        CSGlyph(.dot, points: 23).foregroundStyle(la.accent)
          .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 8 }
          .accessibilityLabel("Live")
      }
      // **WAVE 10 · THE LEAD'S EYEBROW BREAKS ON ITS MIDDOTS** (§16.3, the
      // `agate` row). On an SE at the DEFAULT reading size the shipped line
      // read `MON · GOLD CANYON — DINOSAUR MOUNTAIN ·…` — the course a golfer
      // is playing today, cut off, on the front page of the product, and it
      // got worse at every size above it. The clauses are the line; a tail
      // ellipsis on a line made of clauses throws away the last fact for the
      // sake of the shape of the first.
      CSClauseLine(eyebrow, role: .agate, caps: true, colour: live ? la.accent : cs.mut)
      if let tag {
        Spacer(minLength: CSTokens.Space.s2)
        Text(tag).csType(.agate, caps: true).foregroundStyle(cs.mut)
          .lineLimit(1).fixedSize()
      }
    }
    .csBudget(ember: live ? 1 : 0)
  }

  private var column: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      if let credit {
        HStack(spacing: CSTokens.Space.s2) {
          CSSlot(credit.slot)
          Text(credit.name).csType(.agate, caps: true).foregroundStyle(cs.mut)
            .lineLimit(1).truncationMode(.tail)
        }
        .accessibilityElement(children: .combine)
      }
      // AX3 · the serif headline WRAPS. It never truncates and never shrinks
      // below the role's own floor — it is the one sentence the screen slows
      // a golfer down for.
      Text(headline).csType(.lead).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
      if let standfirst, !standfirst.isEmpty {
        Text(standfirst).csType(.body).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
      // The tertiary's rule IS the affordance, so it must be as wide as the
      // words and no wider: a `VStack` handed a column draws a rule the whole
      // column, which reads as a divider under a paragraph rather than as an
      // underline under a link. The `Spacer` gives the door its ideal width
      // and keeps the two-line AX3 behaviour intact.
      if let door {
        HStack(spacing: 0) { CSDoor(door); Spacer(minLength: 0) }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
