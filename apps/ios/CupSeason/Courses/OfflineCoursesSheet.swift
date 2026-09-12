// Trip preparation uses the existing course book store and live course picker.
// No round is created here. Only a verified local tee card can say Ready offline.
import SwiftUI
import CSDesign
import CupSeasonKit

@MainActor @Observable
final class OfflineCoursesModel {
  var books: [CourseBook] = []
  var selected: CourseHit?
  var downloading = false
  var loaded = false
  var message: String?
  private let read: () async -> [CourseBook]
  private let download: (CourseHit) async -> CourseBook?

  init(read: @escaping () async -> [CourseBook] = { await CourseBookStore().kept() },
       download: @escaping (CourseHit) async -> CourseBook? = { await CourseBookStore().prepare($0) }) {
    self.read = read; self.download = download
  }
  var book: CourseBook? { books.first { $0.id == selected?.id } }
  func load() async { books = await read(); loaded = true }
  func select(_ hit: CourseHit) { guard !downloading else { return }; selected = hit; message = nil }
  func save() async {
    guard !downloading, let hit = selected else { return }
    downloading = true; message = nil
    defer { downloading = false }
    guard let saved = await download(hit) else {
      message = "Couldn’t save the course. Check your connection and try again. Any previously saved tees are still listed below."
      return
    }
    books = await read()
    // The preparation write was verified; the list must also resolve that copy.
    guard let kept = books.first(where: { $0.id == saved.id }), kept.tees == saved.tees else {
      message = "Couldn’t verify the saved course. Try again before leaving service."
      return
    }
    let ready = kept.tees.filter(\.offlineReady).count
    if ready < kept.tees.count {
      message = "Some tees are missing scorecard data. Only tees marked Ready offline can be used from this list."
    }
  }
}

struct OfflineCoursesSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @State private var vm = OfflineCoursesModel()
  @State private var query = ""
  var useTee: ((CourseHit, CourseTee) -> Void)? = nil

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: CSTokens.Space.s3) {
        Text("Offline courses").csType(.social).foregroundStyle(cs.ink)
          .accessibilityAddTraits(.isHeader)
        Spacer(minLength: CSTokens.Space.s2)
        Button("Close") { dismiss() }.buttonStyle(.csTertiary(.toolbar))
      }
      .padding(.horizontal, CSTokens.Space.gutter)
      .padding(.vertical, CSTokens.Space.s3)
      .background(cs.bg0)
      ScrollView {
        VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
          if vm.selected?.id == nil {
          Text("Before you lose signal").csType(.story).foregroundStyle(cs.ink)
          CSFine("Save a course while online. Check each tee below before you leave. Saving a course does not start a round.")
          LiveCourseField(fieldIdentifier: "offline.course.search", text: $query) { hit, _ in vm.select(hit) }
            .disabled(vm.downloading)
          } else {
            Button("Saved courses") { vm.selected = nil; vm.message = nil; query = "" }
              .buttonStyle(.csTertiary(.content))
              .disabled(vm.downloading)
          }
          if let hit = vm.selected {
            CSRule().id("selected-course")
            Text(hit.label).csType(.name).fixedSize(horizontal: false, vertical: true)
            Button(vm.downloading ? "Downloading…" : vm.book == nil ? "Save for offline" : "Update saved course") {
              Task { await vm.save() }
            }
            .buttonStyle(.csPrimary(busy: vm.downloading))
            .disabled(vm.downloading)
            .accessibilityIdentifier("offline.course.save")
            if vm.downloading { CSFine("Downloading tee ratings and hole pars…") }
            if let message = vm.message {
              Text(message).csType(.bodyS).foregroundStyle(cs.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("offline.course.message")
            }
            if let book = vm.book {
              Text(book.savedLine()).csType(.agateS).foregroundStyle(cs.mut)
              ForEach(book.tees) { tee in teeRow(tee, book: book) }
            }
          }
          if vm.selected?.id == nil {
          CSSectionHead("Saved courses", count: "\(vm.books.count)")
          if !vm.loaded { CSFine("Reading courses on this phone…") }
          else if vm.books.isEmpty { CSFine("No courses saved yet. Search above while you’re online.") }
          ForEach(vm.books) { book in
            Button {
              vm.select(book.hit)
              query = ""
            } label: {
              VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
                Text(book.label).csType(.social)
                let ready = book.tees.filter(\.offlineReady).count
                Text("\(ready) of \(book.tees.count) tee\(book.tees.count == 1 ? "" : "s") ready offline").csType(.agateS).foregroundStyle(cs.mut)
              }
              .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain).disabled(vm.downloading)
            .accessibilityIdentifier("offline.course.\(book.id)")
            CSRule()
          }
          }
          CSFine("Course data stays on this phone. Signing out removes it. Up to \(CourseDisk.cap) recently used courses are kept; check this list before a trip.")
        }
        .padding(CSTokens.Space.gutter)
      }
      .id(vm.selected?.id ?? "saved-course-list")
      .background(cs.bg0.ignoresSafeArea())
    }
    .background(cs.bg0.ignoresSafeArea())
    .task { await vm.load() }
  }

  @ViewBuilder private func teeRow(_ tee: CourseBookTee, book: CourseBook) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      Text(tee.title).csType(.name)
      Text(tee.subtitle).csType(.bodyS).foregroundStyle(cs.mut)
      Label(tee.offlineStatus, systemImage: tee.offlineReady ? "checkmark.circle" : "exclamationmark.circle")
        .csType(.agateS).foregroundStyle(cs.ink)
        .accessibilityIdentifier("offline.tee.\(tee.id)")
      if tee.offlineReady, let useTee,
         let option = book.hit.tees.first(where: { $0.tee_name == tee.teeName && $0.gender == tee.gender }) {
        Button("Use \(tee.title) tees") { useTee(book.hit, option); dismiss() }
          .buttonStyle(.csTertiary(.content))
          .accessibilityIdentifier("offline.tee.use.\(tee.id)")
      }
    }
    .fixedSize(horizontal: false, vertical: true)
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, CSTokens.Space.s2)
    CSRule()
  }
}
