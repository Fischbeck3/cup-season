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
            label("Hole"); label("Par"); label("HCP")
          }
          ScrollView(.horizontal, showsIndicators: false) { grid }
        }
      } else {
        HStack(alignment: .top, spacing: 0) {
          VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
            label("Hole"); label("Par"); label("HCP")   // TERMINOLOGY §3.1
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
      row(holes.map { "\($0.hole)" }, total: totalLabel, role: .columnS, ink: cs.leafMut)
      row(holes.map { $0.par.map(String.init) ?? "" }, total: total.map(String.init) ?? "",
          role: .columnM, ink: cs.leafInk)
        .overlay(alignment: .top) {
          // one 1px rule between the key and the pars — a scorecard's own line
          CSRule(over: .leaf).offset(y: -CSTokens.Space.s1 - 1)
        }
      row(holes.map { $0.si.map(String.init) ?? "" }, total: "", role: .columnS, ink: cs.leafMut)
    }
  }

  private func row(_ cells: [String], total: String, role: CSType.Role, ink: Color) -> some View {
    HStack(spacing: 0) {
      ForEach(Array(cells.enumerated()), id: \.offset) { _, c in
        Text(c).csType(role).foregroundStyle(ink)
          .frame(width: typeSize.isA11y ? 34 : 28, height: 20)
      }
      Text(total).csType(role).foregroundStyle(ink)
        .frame(width: typeSize.isA11y ? 38 : 32, height: 20, alignment: .trailing)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(spoken(cells, total: total, role: role))
  }

  /// **One VoiceOver element per ROW, not per cell.** The shipped card's single
  /// label for eighteen columns is the hole the audit names; three sentences
  /// ("Holes one through nine." / "Pars: four, five, three…") is what a golfer
  /// can actually follow.
  private func spoken(_ cells: [String], total: String, role: CSType.Role) -> String {
    let head: String
    switch role {
    case .columnM: head = "Pars"
    case .columnS where cells.first == "1" || cells.first == "10": head = "Holes"
    default: head = "Stroke indexes"
    }
    let body = cells.filter { !$0.isEmpty }.joined(separator: ", ")
    let tail = total.isEmpty ? "" : ". \(totalLabel) \(total)"
    return "\(head): \(body)\(tail)."
  }
}

// MARK: - The whole card

/// **`The whole card`** — the back nine and every rated tee, pushed as a
/// screen and not a sheet (§2.6). It is where the shipped `CourseCardSheet`'s
/// tee picker went: a course with twelve rated tees still shows all twelve,
/// but they are below the one fact the page exists for rather than on top of
/// it, which is the escalation's own order.
struct CourseWholeCardScreen: View {
  @Environment(\.cs) private var cs
  let book: CourseBook

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
        Text(book.label).csType(.display).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
        Text(book.savedLine()).csType(.agateS, caps: true).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
        ForEach(book.tees) { tee in
          VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
            CSFactsLine(facts(tee), label: tee.title)
            CourseCardLeaf(tee: tee, title: "The front nine · \(tee.title)")
            if tee.holes.contains(where: { $0.hole > 9 }) {
              CourseCardLeaf(tee: tee, title: "The back nine · \(tee.title)",
                             range: 10...18, totalLabel: "In")
            }
          }
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
