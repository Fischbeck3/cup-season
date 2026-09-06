// Cup Season — the course card, and it works on a plane (D261, IOS-041, R-N).
//
// This is the screen the owner's escalation asked for by name: *"I wanted to
// see what the slope/rating and 1st hole was on a course I wanted to play but
// the app was dead on airplane mode."* Tees, ratings, slopes, the hole card and
// the first hole — all of it drawn from `CourseDisk`, with the server used
// only to keep the copy fresh.
//
// L-32 lives at the top of the view, not in a footnote: a card drawn from the
// phone SAYS SO, in one line, above the first figure it shows. There is no
// path through this file that renders a saved rating without that line, and no
// path that renders an empty screen — a course this phone has never kept says
// exactly that and offers the thing it can still do.

import SwiftUI
import CSDesign
import CupSeasonKit

struct CourseCardSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @State private var vm: CourseCardModel

  init(courseId: String?, label: String? = nil) {
    _vm = State(initialValue: CourseCardModel(courseId: courseId, label: label))
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          CSSheetHeader(title: vm.title, sub: vm.book?.place.isEmpty == false ? vm.book?.place : nil)

          if let book = vm.book {
            // L-32 · the provenance line, before any figure it qualifies.
            Text(CourseBookCopy.offlineBanner(book))
              .font(CSFont.footnote).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)

            // THE ESCALATION'S OWN ORDER. The owner wanted "the slope/rating
            // and 1st hole" — so the picked tee's figures and its card come
            // FIRST, and the list of every other tee sits under them. Papago
            // has twelve rated tees in production; with the picker on top, the
            // one fact the screen exists for was two screens down.
            if let tee = vm.tee(in: book) {
              ratings(tee)
              card(tee)
            }
            teePicker(book)
            why(book)
          } else if vm.loading {
            CSFine("Looking for this course on your phone…")
          } else {
            // Never an empty screen (L-32). It says what it does not have, and
            // what it will have next time.
            CSNote(CourseBookCopy.neverKept)
            if !vm.label.isEmpty {
              Text(vm.label).font(CSFont.sentenceBold).foregroundStyle(cs.ink).padding(.top, 4)
            }
          }
        }
        .padding(20)
      }
      .background(cs.bg0)
      .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.foregroundStyle(cs.brand) } }
      .task { await vm.load() }
    }
    .presentationDragIndicator(.visible)
  }

  // MARK: the tees

  @ViewBuilder private func teePicker(_ book: CourseBook) -> some View {
    if book.tees.count > 1 {
      CSSectionHead("Every tee", trailing: "\(book.tees.count)")
      ForEach(book.tees) { t in
        Button {
          vm.picked = t.id
        } label: {
          HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
              Text(t.title).font(CSFont.sentenceBold).foregroundStyle(vm.picked == t.id ? cs.ink : cs.mut)
              Text(t.subtitle).font(CSFont.monoSmall).foregroundStyle(cs.dimText)
            }
            Spacer()
            if let n = t.holesCount { Text("\(n) HOLES").font(CSFont.label).foregroundStyle(cs.dimText) }
          }
          .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        CSHairline()
      }
    }
  }

  /// DEF-1's lesson, applied before it could be filed again: four `CSStat`
  /// tiles on ONE row are ~78pt wide on a 390 phone, and `78.5` and `6882`
  /// both broke across two lines in the first screenshot. Two columns give
  /// each tile half the width, and the grid reflows to one at the AX sizes.
  @ViewBuilder private func ratings(_ tee: CourseBookTee) -> some View {
    CSSectionHead(tee.title)
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], spacing: 10) {
      CSStat("Rating", value: CSCopy.points(tee.rating))
      CSStat("Slope", value: tee.slope.map(String.init) ?? "—")
      if let p = tee.parTotal { CSStat("Par", value: String(p)) }
      if let y = tee.yards { CSStat("Yards", value: String(y)) }
    }
  }

  // MARK: the hole card

  @ViewBuilder private func card(_ tee: CourseBookTee) -> some View {
    CSSectionHead("The card")
    if tee.holes.isEmpty {
      CSFine(CourseBookCopy.noCard)
    } else {
      if let first = tee.firstHole {
        // The escalation's own question, answered first and in words.
        Text("1st: par \(first.par.map(String.init) ?? "—")\(first.si.map { " · stroke index \($0)" } ?? "")")
          .font(CSFont.sentenceBold).foregroundStyle(cs.ink)
      }
      // The nines are stacked rather than run out to eighteen columns, so an
      // 18-hole card fits a 390 phone with nothing to scroll. The horizontal
      // scroller stays under them for the AX sizes and for a card that is not
      // nine or eighteen holes long.
      VStack(alignment: .leading, spacing: 10) {
        ForEach(Array(vm.nines(tee).enumerated()), id: \.offset) { _, nine in
          ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 4) {
              row("HOLE", nine.map { String($0.hole) }, tone: cs.dimText)
              row("PAR", nine.map { $0.par.map(String.init) ?? "—" }, tone: cs.ink)
              row("SI", nine.map { $0.si.map(String.init) ?? "—" }, tone: cs.mut)
            }
          }
        }
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel(vm.cardVoiceOver(tee))
    }
  }

  private func row(_ head: String, _ cells: [String], tone: Color) -> some View {
    HStack(spacing: 0) {
      Text(head).font(CSFont.label).foregroundStyle(cs.dimText).frame(width: 44, alignment: .leading)
      ForEach(Array(cells.enumerated()), id: \.offset) { _, c in
        Text(c).font(CSFont.mono).foregroundStyle(tone).frame(width: 30, alignment: .trailing)
      }
    }
  }

  @ViewBuilder private func why(_ book: CourseBook) -> some View {
    if let next = book.nextPlayOn {
      CSFine("On your schedule \(LeagueDates.dowMonDay(next)).").padding(.top, 6)
    } else if let last = book.lastPlayedOn {
      CSFine("You last played here \(LeagueDates.dowMonDay(last)).").padding(.top, 6)
    }
  }
}

@Observable
@MainActor
final class CourseCardModel {
  let courseId: String?
  let label: String
  var book: CourseBook?
  var loading = true
  var picked: String?

  private let store = CourseBookStore()

  init(courseId: String?, label: String?) {
    self.courseId = courseId
    self.label = label ?? ""
  }

  var title: String { book?.label ?? (label.isEmpty ? "Course" : label) }

  func tee(in book: CourseBook) -> CourseBookTee? {
    book.tees.first { $0.id == picked } ?? book.defaultTee
  }

  func load() async {
    loading = true
    let answer = await store.book(courseId)
    book = answer.book
    picked = answer.book?.defaultTee?.id
    loading = false
  }

  /// The card in nines. Eighteen holes come back as two rows of nine — the way
  /// a scorecard reads, and the way an 18-hole card fits a phone without being
  /// dragged sideways. Any other length is one block.
  func nines(_ tee: CourseBookTee) -> [[CourseHole]] {
    let holes = tee.holes.sorted { $0.hole < $1.hole }
    guard holes.count > 9 else { return holes.isEmpty ? [] : [holes] }
    return stride(from: 0, to: holes.count, by: 9).map { Array(holes[$0..<min($0 + 9, holes.count)]) }
  }

  /// The card as ONE VoiceOver sentence — eighteen separate numbers read aloud
  /// in three rows is a puzzle, not a card (L-29's rule for the ear).
  func cardVoiceOver(_ tee: CourseBookTee) -> String {
    let holes = tee.holes.sorted { $0.hole < $1.hole }.prefix(18).map { h in
      "hole \(h.hole), par \(h.par.map(String.init) ?? "unknown")\(h.si.map { ", stroke index \($0)" } ?? "")"
    }
    return "\(tee.title). " + holes.joined(separator: ". ")
  }
}
