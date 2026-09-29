// Cup Season — the front nine, printed on a leaf (`surfaces/course.md` §2.6).
//
// A sheet of scorecard paper set into the page: the rows HOLE · YDS · PAR ·
// HCP (YDS only when every hole carries one) with a tenth **Out** column. It passes §3.3's test (*a leaf must contain a
// grid*) and it is the cheapest unmistakably-golf object in the system.
//
// IT IS ALSO THE AIRPLANE-MODE PAYOFF. This block draws entirely from
// `CourseDisk` and needs no network, which is the whole reason `CourseBook`
// exists (D261 / R-N) and the whole of the owner's own escalation: *"I wanted
// to see what the slope/rating and 1st hole was on a course I wanted to play
// but the app was dead on airplane mode."*
//
// L-44 · A TEE WHOSE CARD WAS NEVER CACHED SAYS SO. `pars(want:)` returns nil
// rather than a guess and the leaf prints `CourseBookCopy.noCard` — never
// eighteen par 4s, never a row of dashes pretending to be a card.
//
// D-5 · WHEN THE CARD DOES NOT FIT, IT SCROLLS SIDEWAYS WITH ITS ROW LABELS
// PINNED. §16.3 says column heads hide at the accessibility sizes; the HOLE row
// is not a column head, it is the key the other rows are read against, and
// hiding it makes the card unreadable.
//
// F06 (2026-09-28) · AND "DOES NOT FIT" IS MEASURED, NOT ASSUMED. The card
// used to decide by type size alone — scroll at AX, never below — with every
// row 20pt tall and every column a fixed 28, 32, 34 or 40. The rows' type
// grows and a 20pt row does not, so at AX3 the numerals overran their rows
// and printed `4…5…1…` in columns too narrow to hold them; and at the
// ordinary size a nine with yardage needed 30 + 9 × 32 + 40 = 358pt plus the
// leaf's 24 — wider than the whole card on an SE, which clipped the Out
// column off the phone's edge. Now every row is as tall as its own type,
// every column as wide as its widest figure, and `ViewThatFits` prints the
// whole card when the measure holds it and scrolls it, key pinned, when it
// does not — at every size, on every phone.

import SwiftUI
import CSDesign
import CupSeasonKit

struct CourseCardLeaf: View {
  @Environment(\.cs) private var cs
  let tee: CourseBookTee?
  let title: String
  /// The front nine by default; the whole-card screen asks for the back.
  var range: ClosedRange<Int> = 1...9
  /// `Out` / `In` — the tenth column, which is what makes this a scorecard
  /// rather than a table of numbers.
  var totalLabel: String = "Out"

  private var holes: [CourseHole] {
    (tee?.holes ?? []).filter { range.contains($0.hole) }.sorted { $0.hole < $1.hole }
  }
  private var total: Int? {
    let pars = holes.compactMap(\.par)
    return pars.count == holes.count && !pars.isEmpty ? pars.reduce(0, +) : nil
  }
  /// D364 (F1) · yardage is a row when EVERY hole in the range has one; a
  /// card with a gap says nothing rather than a row with holes in it.
  private var yards: [Int]? {
    let y = holes.compactMap(\.yards)
    return y.count == holes.count && !y.isEmpty ? y : nil
  }

  /// The printed rows, top to bottom. `par` is the only row in leaf INK — it is
  /// what the others are read toward — and the rest are in the leaf's `mut`.
  enum Row: CaseIterable {
    case hole, yards, par, hcp
    /// TERMINOLOGY §3.1 · `SI` is an engine word and the table gives the ruled
    /// replacement outright: `SI 15` → **HCP 15**.
    var key: String {
      switch self { case .hole: "Hole"; case .yards: "Yds"; case .par: "Par"; case .hcp: "HCP" }
    }
    var role: CSType.Role { self == .par ? .columnM : .columnS }
  }
  private var rows: [Row] { yards == nil ? [.hole, .par, .hcp] : Row.allCases }

  /// The whole card on the measure when it fits; otherwise the key stays where
  /// it is and the columns scroll past it. `ViewThatFits` asks each form for
  /// its IDEAL width — the key, every column at its widest figure, the total —
  /// so the choice is the real type at the real size against the real measure,
  /// never a breakpoint. Three forms, tried in order: the card with an s2
  /// gutter between its figures; the same card set closer, s1 between figures,
  /// which is what lets a nine with three-digit yardage print whole on an SE
  /// and a 17 Pro at the reading size; and, when neither fits, the s2 card in
  /// a scroller with the key pinned outside it.
  var body: some View {
    CSLeaf {
      Text(title).csType(.agateS, caps: true).foregroundStyle(cs.leafMut)
        .fixedSize(horizontal: false, vertical: true)
      if holes.isEmpty {
        Text(CourseBookCopy.noCard).csType(.bodyS).foregroundStyle(cs.leafMut)
          .fixedSize(horizontal: false, vertical: true)
      } else {
        ViewThatFits(in: .horizontal) {
          HStack(alignment: .top, spacing: 0) { key; columns(fill: true, gap: CSTokens.Space.s2) }
          HStack(alignment: .top, spacing: 0) { key; columns(fill: true, gap: CSTokens.Space.s1) }
          HStack(alignment: .top, spacing: 0) {
            key
            ScrollView(.horizontal) {
              HStack(alignment: .top, spacing: 0) { columns(fill: false, gap: CSTokens.Space.s2) }
            }
            .scrollIndicatorsFlash(onAppear: true)
            .accessibilityIdentifier("course.card.scroll")
          }
        }
      }
    }
  }

  // MARK: the key

  /// HOLE · YDS · PAR · HCP, one label per row, each as tall as its row's own
  /// figure so the rows line up across the pinned key and the grid. Hidden
  /// from VoiceOver: every column says its own facts, label included.
  private var key: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      ForEach(rows, id: \.self) { r in
        ZStack(alignment: .leading) {
          // every key label shares the widest label's width
          ForEach(rows, id: \.self) { t in widthOnly(Text(t.key).csType(.agateS, caps: true)) }
          heightOnly(Text("0").csType(r.role))
          Text(r.key).csType(.agateS, caps: true).foregroundStyle(cs.leafMut).fixedSize()
        }
      }
    }
    .padding(.trailing, CSTokens.Space.s2)
    .accessibilityHidden(true)
  }

  // MARK: the columns

  /// The nine hole columns and the total. `fill` lets the hole columns share
  /// the measure's spare width when the whole card fits; inside the scroller
  /// they keep their own width, which is their widest figure plus `gap`.
  @ViewBuilder private func columns(fill: Bool, gap: CGFloat) -> some View {
    ForEach(Array(holes.enumerated()), id: \.offset) { i, h in
      VStack(spacing: CSTokens.Space.s2) {
        ForEach(rows, id: \.self) { r in
          cell(value(r, h, i), r, templates: holeTemplates, alignment: .center, fill: fill, gap: gap)
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(spokenHole(h, i))
      .accessibilityIdentifier("course.card.hole.\(h.hole)")
    }
    VStack(spacing: CSTokens.Space.s2) {
      ForEach(rows, id: \.self) { r in
        cell(totalValue(r), r, templates: totalTemplates, alignment: .trailing, fill: false, gap: gap)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(spokenTotal)
    .accessibilityIdentifier("course.card.total")
  }

  /// One figure in its row's role. The hidden templates make every cell of a
  /// column exactly as wide as that column's widest figure in ANY row — so the
  /// columns are even and the par rule runs unbroken across them — and the
  /// hidden key label makes the row as tall as its label, so the pinned key
  /// and the grid share every baseline.
  private func cell(_ s: String, _ r: Row, templates: [Row: String], alignment: Alignment,
                    fill: Bool, gap: CGFloat) -> some View {
    ZStack(alignment: alignment) {
      ForEach(rows, id: \.self) { t in widthOnly(Text(templates[t] ?? "").csType(t.role)) }
      heightOnly(Text(r.key).csType(.agateS, caps: true))
      Text(s).csType(r.role).foregroundStyle(r == .par ? cs.leafInk : cs.leafMut).fixedSize()
    }
    // half the gutter each side, so two figures stand `gap` apart
    .padding(.horizontal, gap / 2)
    .frame(maxWidth: fill ? .infinity : nil, alignment: alignment)
    .overlay(alignment: .top) {
      // one 1px rule between the key rows and the pars — a scorecard's own line
      if r == .par { CSRule(over: .leaf).offset(y: -CSTokens.Space.s1 - 1) }
    }
  }

  /// The widest figure each row can print in a hole column: the digits of
  /// its largest value, in the row's own face.
  private var holeTemplates: [Row: String] {
    func digits(_ ns: [Int]) -> String { String(repeating: "8", count: max(1, ns.map { String($0).count }.max() ?? 1)) }
    return [.hole: digits(holes.map(\.hole)), .yards: digits(yards ?? []),
            .par: digits(holes.compactMap(\.par)), .hcp: digits(holes.compactMap(\.si))]
  }
  /// The total column prints the label, the yardage and the par; each row's
  /// template is its own string, so the column is as wide as its widest.
  private var totalTemplates: [Row: String] {
    Dictionary(uniqueKeysWithValues: rows.map { ($0, totalValue($0)) })
  }

  private func value(_ r: Row, _ h: CourseHole, _ i: Int) -> String {
    switch r {
    case .hole: "\(h.hole)"
    case .yards: yards.map { String($0[i]) } ?? ""
    case .par: h.par.map(String.init) ?? ""
    case .hcp: h.si.map(String.init) ?? ""
    }
  }
  private func totalValue(_ r: Row) -> String {
    switch r {
    case .hole: totalLabel
    case .yards: yards.map { String($0.reduce(0, +)) } ?? ""
    case .par: total.map(String.init) ?? ""
    case .hcp: ""
    }
  }

  // MARK: VoiceOver

  /// **One VoiceOver element per HOLE, read down its column** — the way a
  /// golfer reads a card: hole three, its length, its par, how hard it plays.
  /// It was one element per ROW ("Pars: four, five, three…"), which asks a
  /// listener to hold nine numbers and count along to the hole they wanted.
  /// Abbreviations spell themselves out (TERMINOLOGY §6): HCP is "handicap".
  private func spokenHole(_ h: CourseHole, _ i: Int) -> String {
    var facts: [String] = []
    if let y = yards?[i] { facts.append("\(y) yards") }
    if let p = h.par { facts.append("par \(p)") }
    if let si = h.si { facts.append("handicap \(si)") }
    return "Hole \(h.hole)" + (facts.isEmpty ? "" : ". " + facts.joined(separator: ", ")) + "."
  }
  private var spokenTotal: String {
    var facts: [String] = []
    if let y = yards { facts.append("\(y.reduce(0, +)) yards") }
    if let t = total { facts.append("par \(t)") }
    return totalLabel + (facts.isEmpty ? "" : ". " + facts.joined(separator: ", ")) + "."
  }

  // MARK: measuring probes

  /// A hidden copy that contributes its WIDTH to the cell and nothing else.
  private func widthOnly(_ t: some View) -> some View {
    t.fixedSize().frame(height: 0).hidden()
  }
  /// A hidden copy that contributes its HEIGHT to the cell and nothing else.
  private func heightOnly(_ t: some View) -> some View {
    t.fixedSize().frame(width: 0).hidden()
  }
}

// MARK: - The whole card

/// **`The whole card`** — every rated tee, **one card at a time** (§2.6,
/// amended by D323).
///
/// It shipped as `ForEach(book.tees)` drawing a front and a back nine for each,
/// and this file's own comment accepted the cost out loud: *"a course with
/// twelve rated tees still shows all twelve."* Gold Canyon has enough of them
/// that the owner counted: *"Do we need every scorecard rating, this is like 10
/// scrolls."* Twelve tees is twenty-four leaves and nobody reads the twelfth.
///
/// **The facts line is the summary; the card is the disclosure.** Every tee
/// keeps its one line — par, yards, rating, slope — because comparing tees is
/// the actual reason a golfer opens this screen, and four figures per tee is a
/// table you can read. Only the tee you asked for draws its holes.
///
/// **It opens on the tee you play.** The course page has already resolved one
/// (`vm.tee(in:)` — the round's, or the course's default), and it hands it over
/// so this screen opens showing the card the reader came for rather than the
/// first one alphabetically.
struct CourseWholeCardScreen: View {
  @Environment(\.cs) private var cs
  let book: CourseBook
  /// The tee to open on. nil opens the course's default (the longest rated
  /// 18) — and the screen SAYS it did, rather than presenting it as a choice.
  var openOn: CourseBookTee?
  /// D364 (F1) · true when `openOn` is a tee the round or plan actually named.
  var yours: Bool = false

  /// The tee whose card is shown — one at a time, always.
  @State private var chosen: String?
  /// The other tees, revealed behind "Change tees".
  @State private var choosing = false

  private var selected: CourseBookTee? {
    book.tees.first { $0.id == (chosen ?? openOn?.id) } ?? openOn ?? book.defaultTee ?? book.tees.first
  }
  private var others: [CourseBookTee] { book.tees.filter { $0.id != selected?.id } }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
        // 1 · the course, and the copy's provenance (F2's words)
        Text(book.label).csType(.display).foregroundStyle(cs.ink)
          .accessibilityAddTraits(.isHeader)   // N4-093 · a screen names itself as a heading
          .fixedSize(horizontal: false, vertical: true)
        Text(book.savedLine()).csType(.agateS, caps: true).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)

        // 2 · THE SELECTED TEE — one, with how it was chosen said out loud.
        // D364 (F1): the screen used to loop every rated tee and expand one
        // of them inline, so the card a golfer came for could sit under ten
        // rating variants. The selected tee leads; the others wait behind a
        // control, and changing tees changes the facts and the card together.
        if let tee = selected {
          VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
            CSFactsLine(facts(tee), label: tee.title)
              .accessibilityIdentifier("course.card.tee")
            Text(chosen == nil && !yours ? CourseBookCopy.teeIsTheLongest
                 : (chosen == nil ? CourseBookCopy.teeIsYours : tee.offlineStatus))
              .csType(.agateS).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)
            if !others.isEmpty {
              CSMini(choosing ? CourseBookCopy.keepTees : CourseBookCopy.changeTees) {
                CSHaptic.selection()
                CSMotion.run(CSMotion.tick) { choosing.toggle() }
              }
              .accessibilityIdentifier("course.card.change")
            }
          }

          // 3 · the other tees, only when asked — every rated tee, one line
          // each, and a tap makes it the card below
          if choosing {
            VStack(spacing: 0) {
              ForEach(others) { t in
                Button {
                  CSHaptic.selection()
                  CSMotion.run(CSMotion.tick) { chosen = t.id; choosing = false }
                } label: {
                  VStack(alignment: .leading, spacing: 2) {
                    Text(t.title).csType(.name).foregroundStyle(cs.ink)
                    Text(t.subtitle + (t.yards.map { " · \(CourseModel.grouped($0)) yds" } ?? "")).csType(.columnS).foregroundStyle(cs.mut)
                  }
                  .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                  .padding(.vertical, CSTokens.Space.s2)
                  .overlay(alignment: .bottom) { CSRule() }
                  .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("course.card.pick")
                .accessibilityHint("Shows this tee's facts and card")
              }
            }
          }

          // 4 · the card — front, then back, for THIS tee only
          CourseCardLeaf(tee: tee, title: "The front nine · \(tee.title)")
          if tee.holes.contains(where: { $0.hole > 9 }) {
            CourseCardLeaf(tee: tee, title: "The back nine · \(tee.title)",
                           range: 10...18, totalLabel: "In")
          }
        } else {
          Text(CourseBookCopy.noCard).csType(.bodyS).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      .padding(.horizontal, CSTokens.Space.gutter)
      .padding(.vertical, CSTokens.Space.s4)
    }
    .background(cs.bg0.ignoresSafeArea())
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func facts(_ tee: CourseBookTee) -> [CSFactsLine.Fact] {
    var out: [CSFactsLine.Fact] = []
    if let p = tee.parTotal { out.append(.init("\(p)", "par")) }
    if let y = tee.yards, y > 0 { out.append(.init(CourseModel.grouped(y), "yds")) }
    if let r = tee.rating { out.append(.init(CSCopy.points(r), "rtg")) }
    if let s = tee.slope { out.append(.init("\(s)", "slope")) }
    return out
  }
}
