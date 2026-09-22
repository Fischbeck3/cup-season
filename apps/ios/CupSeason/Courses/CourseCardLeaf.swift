// Cup Season — the front nine, printed on a leaf (`surfaces/course.md` §2.6).
//
// A sheet of scorecard paper set into the page: three rows — HOLE · PAR · SI —
// with a tenth **Out** column. It passes §3.3's test (*a leaf must contain a
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
// D-5 · AT AX3 THE LEAF SCROLLS SIDEWAYS WITH ITS ROW LABELS PINNED. §16.3
// says column heads hide at the accessibility sizes; the HOLE row is not a
// column head, it is the key the other two rows are read against, and hiding
// it makes the card unreadable. The shipped `CourseCardSheet`'s horizontal
// scroller is the one region of that screen the audit praised, and it survives
// here for exactly that reason.

import SwiftUI
import CSDesign
import CupSeasonKit

struct CourseCardLeaf: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
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

  var body: some View {
    CSLeaf {
      Text(title).csType(.agateS, caps: true).foregroundStyle(cs.leafMut)
        .fixedSize(horizontal: false, vertical: true)
      if holes.isEmpty {
        Text(CourseBookCopy.noCard).csType(.bodyS).foregroundStyle(cs.leafMut)
          .fixedSize(horizontal: false, vertical: true)
      } else if typeSize.isA11y {
        HStack(alignment: .top, spacing: 0) {
          VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
            // TERMINOLOGY §3.1 · `SI` is an engine word and the table at :146
            // gives the ruled replacement outright: `SI 15` → **HCP 15**. The
            // column head walked past preflight 18, which greps `\bSI \d`.
            label("Hole"); if yards != nil { label("Yds") }; label("Par"); label("HCP")
          }
          ScrollView(.horizontal, showsIndicators: false) { grid }
        }
      } else {
        HStack(alignment: .top, spacing: 0) {
          VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
            label("Hole"); if yards != nil { label("Yds") }; label("Par"); label("HCP")   // TERMINOLOGY §3.1
          }
          grid
        }
      }
    }
  }

  /// The row labels sit in a fixed 26pt leading column, so the three rows line
  /// up against one edge whatever the numerals do.
  private func label(_ s: String) -> some View {
    Text(s).csType(.agateS, caps: true).foregroundStyle(cs.leafMut)
      .frame(width: 30, height: 20, alignment: .leading)
  }

  private var grid: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      row(holes.map { "\($0.hole)" }, total: totalLabel, role: .columnS, ink: cs.leafMut, head: "Holes")
      if let yards {
        // D364 (F1) · the yardage, when the card actually carries it
        row(yards.map(String.init), total: String(yards.reduce(0, +)), role: .columnS, ink: cs.leafMut, head: "Yards")
      }
      row(holes.map { $0.par.map(String.init) ?? "" }, total: total.map(String.init) ?? "",
          role: .columnM, ink: cs.leafInk, head: "Pars")
        .overlay(alignment: .top) {
          // one 1px rule between the key and the pars — a scorecard's own line
          CSRule(over: .leaf).offset(y: -CSTokens.Space.s1 - 1)
        }
      row(holes.map { $0.si.map(String.init) ?? "" }, total: "", role: .columnS, ink: cs.leafMut, head: "Stroke indexes")
    }
  }

  private func row(_ cells: [String], total: String, role: CSType.Role, ink: Color, head: String) -> some View {
    HStack(spacing: 0) {
      // every row shares one column width, wider when a yardage row (three
      // digits a hole, four in the total) is on the card
      ForEach(Array(cells.enumerated()), id: \.offset) { _, c in
        Text(c).csType(role).foregroundStyle(ink)
          .frame(width: typeSize.isA11y ? (yards != nil ? 40 : 34) : (yards != nil ? 32 : 28), height: 20)
      }
      Text(total).csType(role).foregroundStyle(ink)
        .frame(width: typeSize.isA11y ? 44 : (yards != nil ? 40 : 32), height: 20, alignment: .trailing)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(spoken(cells, total: total, head: head))
  }

  /// **One VoiceOver element per ROW, not per cell.** The shipped card's single
  /// label for eighteen columns is the hole the audit names; three sentences
  /// ("Holes one through nine." / "Pars: four, five, three…") is what a golfer
  /// can actually follow.
  private func spoken(_ cells: [String], total: String, head: String) -> String {
    let body = cells.filter { !$0.isEmpty }.joined(separator: ", ")
    let tail = total.isEmpty ? "" : ". \(totalLabel) \(total)"
    return "\(head): \(body)\(tail)."
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
