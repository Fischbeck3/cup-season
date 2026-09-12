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
  @State private var stars: [String: MyCourseRating] = [:]
  @State private var loaded = false
  @State private var filter: Filter = .all
  @State private var showOfflineCourses = false

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

  /// **D289 · THE RECORD OF THE COURSES YOU LIKE.** The owner's own clause,
  /// and the whole change to this screen: the list stops being an inventory in
  /// schedule-then-recency order and becomes an OPINION, sorted. The rated
  /// come first, best first; the rest fall under `ALSO KEPT` with a rail a
  /// golfer can still tap on the page behind them.
  private var liked: [CourseBook] {
    shown.filter { stars[$0.id] != nil }
      .sorted { (stars[$0.id]?.mine ?? 0, $1.label) > (stars[$1.id]?.mine ?? 0, $0.label) }
  }
  private var rest: [CourseBook] { shown.filter { stars[$0.id] == nil } }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        Text("Courses").csType(.display).foregroundStyle(cs.ink)
        Text(sub).csType(.agate, caps: true).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
        Button("Save courses for offline") { showOfflineCourses = true }
          .buttonStyle(.csTertiary(.content))

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
                  door: .elsewhere("Save a course for offline, post a round at it, or put one on the plan."))
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
          if !liked.isEmpty {
            CSSectionHead("Courses you like", count: "\(liked.count) rated")
            group(liked)
          }
          if !rest.isEmpty {
            if !liked.isEmpty { CSSectionHead("Also kept", count: "\(rest.count)") }
            group(rest)
          }
        }
      }
      .padding(.horizontal, CSTokens.Space.gutter)
      .padding(.vertical, CSTokens.Space.s4)
    }
    .background(cs.bg0.ignoresSafeArea())
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showOfflineCourses, onDismiss: { Task { books = await CourseBookStore().kept() } }) {
      OfflineCoursesSheet().csDevTextSize(CSDevHatch.textSize)
    }
    .task {
      books = await CourseBookStore().kept()
      loaded = true
      // the phone's own store answers first and alone; the bests and the
      // ratings are one read each on top, and a failure leaves the column
      // absent rather than emptying the list (L-32)
      bests = await CoursePageRepository().myBests(me: store.me?.profile?.id)
      let mine = await CourseRatingService().mine()
      stars = Dictionary(mine.map { ($0.courseId, $0) }, uniquingKeysWith: { a, _ in a })
    }
  }

  /// One run of rows under one head. The rule is the row's own top edge, and
  /// the run closes with one — never a border and never a card (§32).
  @ViewBuilder private func group(_ list: [CourseBook]) -> some View {
    VStack(spacing: 0) {
      ForEach(list) { b in
        CSRule()
        NavigationLink(value: CourseSheetRef(id: b.id, label: b.label)) {
          CourseRow(book: b, best: bests[b.id], mine: stars[b.id]?.mine, open: {})
        }
        .buttonStyle(.plain)
      }
      CSRule()
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
  /// **Your own star** (D289), when `my_course_ratings` has answered. The
  /// rail on a ROW is a picture and not a control: a half-star target that
  /// clears WCAG 2.5.8 needs a 48pt star, which is a headline and not a row,
  /// so the control lives on the page this row opens.
  var mine: Double? = nil
  let open: () -> Void

  private var holes: [CSDrawnCard.Hole] {
    let tee = book.defaultTee
    return (tee?.holes ?? []).sorted { $0.hole < $1.hole }.compactMap { h in
      h.par.map { CSDrawnCard.Hole(number: h.hole, par: $0, si: h.si, yards: h.yards) }
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
        if let mine, !typeSize.isA11y {
          HStack(spacing: CSTokens.Space.s2) {
            CSStarRail(mine, size: 14)
            Text(CSRating.format(mine)).csType(.agateS, caps: true).foregroundStyle(cs.mut)
          }
        }
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
  /// own. The rating is a rail above this line (D289), never a word in it.
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
    let r = mine.map { ", you rate it \(CSRating.format($0))" } ?? ""
    return "\(book.label)\(b)\(r). \(sub)"
  }
}
