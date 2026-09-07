// Cup Season — COURSES (`surfaces/course.md` §2.8, D272).
//
// **The courses list stops being a settings pane.** It was `KeptCoursesList`,
// a `CSSectionHead` and a stack of 44pt rows with an ember `SEE` label on each
// one — a link-label on a row that is already the door (BF-16) — embedded
// inside Card & settings. It is now a screen that opens with `display` 34
// COURSES, one agate line, and one chip row.
//
// EVERY ROW CARRIES THE SAME LEFT OBJECT, which is the blind review's third
// finding on this surface: one course's missing thumbnail broke the rail
// mid-list and all three reviewers read it as a load failure rather than as
// "unplayed". At ≤64pt the drawn card renders **the front nine only** — nine
// bars at three heights by par (§10.2) — because eighteen 3pt bars in a
// 44 × 26 box are three near-identical grey combs. A course with no cached
// card at all shows **no thumbnail**: the left column collapses and the name
// sets flush to the margin. That is the ladder's own rule and it is better
// looking than a placeholder.
//
// IT READS `CourseDisk` ALONE — no network read on the way in, by design,
// because this is the list a golfer opens when there is no network, and it is
// the one screen that must work on the boot-failed path with no session at all
// (OE-1).

import SwiftUI
import CSDesign
import CupSeasonKit

struct CoursesScreen: View {
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var store
  @State private var books: [CourseBook] = []
  @State private var bests: [String: Int] = [:]
  @State private var loaded = false
  @State private var filter: Filter = .all

  enum Filter: String, CaseIterable, Hashable { case all, planned, played
    var label: String { rawValue }
  }

  private var shown: [CourseBook] {
    switch filter {
    case .all: return books
    case .planned: return books.filter { $0.planned }
    case .played: return books.filter { $0.played }
    }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        Text("Courses").csType(.display).foregroundStyle(cs.ink)
        Text(sub).csType(.agate, caps: true).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)

        HStack(spacing: CSTokens.Space.s2) {
          ForEach(Filter.allCases, id: \.self) { f in
            Button { filter = f } label: { CSChip(f.label, selected: filter == f) }
              .buttonStyle(.plain)
          }
        }
        .padding(.top, CSTokens.Space.s1)

        if !loaded {
          // the destination's own geometry, redacted — never a spinner
          VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { _ in
              CSRule()
              CourseRow(book: CourseModel.placeholder("Papago"), best: nil, open: {})
            }
          }
          .csRedacted(true)
        } else if shown.isEmpty {
          CSEmpty(glyph: .scorecard,
                  eyebrow: "On your phone",
                  headline: empty,
                  fact: CourseBookCopy.what,
                  door: .elsewhere("A course arrives the first time you post a round at it or put one on the plan."))
        } else {
          // §16A.3 · an unlabelled number column is a defect, not a minimalism
          // — and a HEAD OVER AN EMPTY COLUMN is the same defect the other way
          // round, so it appears only once a row under it carries a figure.
          if shown.contains(where: { bests[$0.id] != nil }) {
            HStack {
              Spacer()
              Text("Your best").csType(.agateS, caps: true).foregroundStyle(cs.mut)
            }
            .padding(.top, CSTokens.Space.s2)
          }
          VStack(spacing: 0) {
            ForEach(shown) { b in
              CSRule()
              NavigationLink(value: CourseSheetRef(id: b.id, label: b.label)) {
                CourseRow(book: b, best: bests[b.id], open: {})
              }
              .buttonStyle(.plain)
            }
            CSRule()
          }
        }
      }
      .padding(.horizontal, CSTokens.Space.gutter)
      .padding(.vertical, CSTokens.Space.s4)
    }
    .background(cs.bg0.ignoresSafeArea())
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      books = await CourseBookStore().kept()
      loaded = true
      // the phone's own store answers first and alone; the bests are one read
      // on top, and a failure leaves the column absent rather than the list
      bests = await CoursePageRepository().myBests(me: store.me?.profile?.id)
    }
  }

  private var sub: String {
    guard loaded, !books.isEmpty else { return "Kept on your phone" }
    return "Kept on your phone · \(CSCopy.spelled(books.count)) saved"
  }

  /// A fact about the world, never the golfer's omission.
  private var empty: String {
    switch filter {
    case .all: return "Nothing is kept on this phone yet."
    case .planned: return "None of them is on the plan."
    case .played: return "You have not posted a round at any of them."
    }
  }
}

/// One course in a list: the drawn thumbnail, the name, a sub-line, and your
/// best gross here in the trailing column.
///
/// **A course you have not played shows nothing in the trailing column** — or
/// a date when it is on the plan — and never a dash and never a zero (L-44).
/// The name wraps to **two lines** before it truncates: *"The Raven Golf Club
/// at Verrado · Founde…"* cut the tee, and in golf the tee is often the whole
/// distinction.
struct CourseRow: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let book: CourseBook
  /// Your best gross here, when the page's read has one. The list itself does
  /// no network read, so this is nil on the list and filled on the page.
  let best: Int?
  let open: () -> Void

  private var holes: [CSDrawnCard.Hole] {
    let tee = book.defaultTee
    return (tee?.holes ?? []).sorted { $0.hole < $1.hole }.compactMap { h in
      h.par.map { CSDrawnCard.Hole(number: h.hole, par: $0, si: h.si, yards: nil) }
    }
  }

  var body: some View {
    HStack(spacing: CSTokens.Space.s3) {
      // §10.2 · the drawn card IS the thumbnail; the contour is banned at this
      // scale; a course with neither shows nothing and the name sets flush.
      if !holes.isEmpty && !typeSize.isA11y {
        CSDrawnCard(holes, scale: .thumb).frame(width: 44, height: 30)
      }
      VStack(alignment: .leading, spacing: 2) {
        Text(book.label).csType(.social).foregroundStyle(cs.ink)
          .lineLimit(2).truncationMode(.tail)
          .fixedSize(horizontal: false, vertical: true)
        Text(sub).csType(.agateS, caps: false).foregroundStyle(cs.mut)
          .lineLimit(typeSize.isA11y ? 3 : 1).truncationMode(.tail)
      }
      .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
      trailing
    }
    .frame(minHeight: 62)
    .contentShape(Rectangle())
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(spoken)
  }

  @ViewBuilder private var trailing: some View {
    if let best {
      Text("\(best)").csType(.figureM).foregroundStyle(cs.ink)
    } else if let next = book.nextPlayOn {
      Text(LeagueDates.dowMonDay(next)).csType(.agateS, caps: true).foregroundStyle(cs.mut)
        .multilineTextAlignment(.trailing).frame(width: 66, alignment: .trailing)
    }
  }

  /// One casing rule: the place is sentence case, the facts are the page's
  /// own. `Not rated` until the aggregate exists (D275).
  private var sub: String {
    var parts: [String] = []
    if !book.place.isEmpty { parts.append(book.place) }
    if let last = book.lastPlayedOn {
      parts.append("you played \(LeagueDates.monDay(last))")
    } else if book.planned {
      parts.append("on your plan")
    }
    return parts.joined(separator: " · ")
  }

  private var spoken: String {
    let b = best.map { ", your best \($0)" } ?? ""
    return "\(book.label)\(b). \(sub)"
  }
}
