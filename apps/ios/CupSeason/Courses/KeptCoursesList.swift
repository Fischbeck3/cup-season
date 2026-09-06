// Cup Season — the courses this phone has kept, as a list anybody can mount.
//
// OE-1 · it used to be `private` inside `CardAndSettingsScreen`, which put it
// under `MainTabView` and therefore behind a successful boot. The one screen
// that most needs it is the one a golfer reaches when the boot FAILED — on a
// plane, holding forty kilobytes of exactly these course books and unable to
// read a word of them. It reads `CourseDisk` and needs no session, so it works
// on that screen unchanged.

import SwiftUI
import CSDesign
import CupSeasonKit

/// D261 / R-N · the courses this phone has kept, and the door onto each card.
///
/// It draws from `CourseDisk` alone — no network read, by design, because this
/// is the list a golfer opens when there is no network. An empty store is a
/// real state and says what fills it, rather than rendering nothing.
struct KeptCoursesList: View {
  @Environment(\.cs) private var cs
  @State private var books: [CourseBook] = []
  @State private var loaded = false
  @State private var open: String? = nil

  var body: some View {
    Group {
      CSSectionHead("Courses on your phone").padding(.top, 14)
      Text(CourseBookCopy.what).font(CSFont.footnote).foregroundStyle(cs.dimText)
        .fixedSize(horizontal: false, vertical: true)
      if !loaded {
        CSFine("Reading what your phone kept…")
      } else if books.isEmpty {
        CSFine("Nothing kept yet. Post a round or put one on the schedule and its course comes with you.")
      } else {
        ForEach(books) { b in
          Button { open = b.id } label: {
            HStack(alignment: .firstTextBaseline) {
              VStack(alignment: .leading, spacing: 2) {
                Text(b.label).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
                Text(b.subline).font(CSFont.monoSmall).foregroundStyle(cs.mut)
              }
              Spacer()
              Text("SEE").font(CSFont.label).foregroundStyle(cs.brand)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          CSHairline()
        }
      }
    }
    .task {
      books = await CourseBookStore().kept()
      loaded = true
    }
    .sheet(item: Binding(get: { open.map(CourseSheetId.init) }, set: { open = $0?.id })) { s in
      CourseCardSheet(courseId: s.id)
    }
  }
}

struct CourseSheetId: Identifiable { let id: String }


/// OE-1 · the same list, in its own sheet, for a screen with no tab bar under
/// it. `CourseCardSheet` rises from inside the list exactly as it does in
/// Settings, so there is one list and one card, not two of each (L-34).
struct KeptCoursesSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) { KeptCoursesList() }
          .padding(.horizontal, 18).padding(.bottom, 28)
      }
      .background(cs.bg0.ignoresSafeArea())
      .navigationTitle("On your phone")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
    }
  }
}
