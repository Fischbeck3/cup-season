// Cup Season — the composer's course search (`attachCourseSearch` 6729–6862,
// bound to `#inCourse` / `#inRating` / `#inSlope` at 6863).
//
// Same two-stage dropdown as the tee sheet's `CourseSearchField` — it reuses
// that slice's `CourseSearchModel` (cache first, remote merged, 320 ms
// debounce) — but the post needs the TEE back, not just the course id: the
// tee sets rating + slope, and a 9-hole tee flips the card to a nine (D72).

import SwiftUI
import CSDesign
import CupSeasonKit

struct PostCourseSearchField: View {
  @Environment(\.cs) private var cs
  @Binding var text: String
  @Binding var courseId: String?
  let onTee: (CourseHit, CourseTee) -> Void
  @State private var vm = CourseSearchModel()

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      CSField("Search a course, or type your own", text: $text, font: CSFont.body)
        .onChange(of: text) { _, q in
          // typing again after a pick unstamps the course id (the label no longer matches the row)
          if vm.pickedLabel != q { courseId = nil; vm.pickedLabel = nil }
          vm.queue(q)
        }
      switch vm.stage {
      case .hidden: EmptyView()
      case .courses:
        dropdown {
          if vm.courses.isEmpty {
            Text("No match — type the course, rating and slope by hand.").font(CSFont.footnote).foregroundStyle(cs.mut).padding(12)
          } else {
            ForEach(vm.courses) { c in
              row(c.label, c.subline) { text = c.label; vm.pickedLabel = c.label; courseId = c.id; vm.showTees(c) }
            }
          }
        }
      case .tees(let c):
        dropdown {
          row("‹ Back to courses", nil) { vm.stage = .courses }
          if c.tees.isEmpty {
            Text("No rated tees listed — type the rating and slope by hand.").font(CSFont.footnote).foregroundStyle(cs.mut).padding(12)
          } else {
            ForEach(c.tees) { t in
              row(t.title, t.subtitle) {
                let label = c.label + (t.tee_name.map { " · \($0)" } ?? "")
                vm.pickedLabel = label
                text = label
                courseId = c.id
                vm.stage = .hidden
                onTee(c, t)
              }
            }
          }
        }
      }
    }
  }

  private func dropdown<C: View>(@ViewBuilder _ content: () -> C) -> some View {
    VStack(spacing: 0) { content() }
      .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: 1))
  }

  private func row(_ b: String, _ s: String?, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 2) {
        Text(b).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
        if let s { Text(s).font(CSFont.monoSmall).foregroundStyle(cs.mut) }
      }
      .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
      .padding(.horizontal, 12).padding(.vertical, 6)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
