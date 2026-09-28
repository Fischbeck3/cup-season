#if DEBUG
// Cup Season — the N1 review route (the before-launch ten program, 2026-09-28).
//
// `-cs_dev_n1 <route>` puts ONE real surface over the root, on synthetic data,
// so the three repairs this lane owns can be photographed on a simulator that
// has never signed in:
//
//   actions         the ordinary primary in its four states (rest, pressed,
//                   busy, disabled) and a panel, under whatever `-cs_dev_look`
//                   and `-cs_dev_appearance` the launch names (F05)
//   course18        the whole card, an 18-hole tee with yardage (F06)
//   course9         a nine-hole tee (F06)
//   course-noyards  an 18-hole tee whose card carries no yardage (F06)
//   course-longtee  a tee whose name runs long (F06)
//   calendar        the real schedule screen (F15) — pair it with
//                   `-cs_dev_offline_network`, so its reads fail at once and
//                   the month draws empty instead of asking a server
//
// Nothing here writes, and every name is invented: the club, the tees and the
// yardages belong to no course. The course and action routes read nothing; the
// calendar is the real screen and makes the real screen's reads, which is why
// it is photographed offline. The whole file is DEBUG, so Release has no such
// door.

import SwiftUI
import CSDesign
import CupSeasonKit

enum N1Review {
  enum Route: String, CaseIterable {
    case actions, course18, course9
    case courseNoYards = "course-noyards"
    case courseLongTee = "course-longtee"
    case calendar
  }

  static var route: Route? {
    let a = ProcessInfo.processInfo.arguments
    guard let i = a.firstIndex(of: "-cs_dev_n1"), i + 1 < a.count else { return nil }
    return Route(rawValue: a[i + 1])
  }

  // MARK: the invented course

  /// Par and stroke index for eighteen holes of a course that does not exist.
  static let pars = [4, 5, 3, 4, 4, 3, 5, 4, 4, 4, 3, 5, 4, 4, 3, 4, 5, 4]
  static let hcps = [7, 3, 17, 11, 1, 15, 5, 13, 9, 8, 18, 4, 12, 2, 16, 10, 6, 14]
  static let yards = [412, 538, 176, 395, 441, 158, 547, 382, 426, 404, 167, 529, 377, 449, 184, 391, 556, 418]

  static func holes(_ n: Int, yards withYards: Bool) -> [CourseHole] {
    (1...n).map { h in
      CourseHole(hole: h, par: pars[h - 1], si: hcps[h - 1], yards: withYards ? yards[h - 1] : nil)
    }
  }

  static func tee(_ name: String, gender: String? = "male", holes n: Int, yards withYards: Bool) -> CourseBookTee {
    let hs = holes(n, yards: withYards)
    return CourseBookTee(teeName: name, gender: gender, rating: n == 18 ? 71.8 : 35.9,
                         slope: n == 18 ? 128 : 124, holesCount: n,
                         parTotal: hs.compactMap(\.par).reduce(0, +),
                         yards: withYards ? hs.compactMap(\.yards).reduce(0, +) : nil, holes: hs)
  }

  static func book(_ tees: [CourseBookTee]) -> CourseBook {
    CourseBook(id: "n1-review-fixture", clubName: "Fixture Links", courseName: "North",
               city: nil, state: nil, tees: tees)
  }
}

struct N1ReviewView: View {
  @Environment(\.cs) private var cs
  let route: N1Review.Route

  var body: some View {
    Group {
      switch route {
      case .actions: actions
      case .course18:
        let t = N1Review.tee("Blue", holes: 18, yards: true)
        wholeCard(N1Review.book([t]), t)
      case .course9:
        let t = N1Review.tee("White", holes: 9, yards: true)
        wholeCard(N1Review.book([t]), t)
      case .courseNoYards:
        let t = N1Review.tee("Red", holes: 18, yards: false)
        wholeCard(N1Review.book([t]), t)
      case .courseLongTee:
        let t = N1Review.tee("Championship Tips Extended Back", gender: "female", holes: 18, yards: true)
        wholeCard(N1Review.book([t]), t)
      case .calendar:
        NavigationStack { ScheduleScreen() }
      }
    }
    .background(cs.bg0.ignoresSafeArea())
    .csDevTextSize(CSDevHatch.textSize)
  }

  private func wholeCard(_ book: CourseBook, _ tee: CourseBookTee) -> some View {
    NavigationStack { CourseWholeCardScreen(book: book, openOn: tee, yours: true) }
  }

  /// The ordinary primary, drawn by the real style in every state it names.
  /// `held` is the style's own window onto the pressed state (a simulator has
  /// no finger); nothing here hand-copies a fill.
  private var actions: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        state("Rest") { Button("Post the round") {}.buttonStyle(.csPrimary()) }
        state("Pressed") { Button("Post the round") {}.buttonStyle(.csPrimary(held: true)) }
        state("Busy") { Button("Post the round") {}.buttonStyle(.csPrimary(busy: true)) }
        state("Disabled") { Button("Post the round") {}.buttonStyle(.csPrimary()).disabled(true) }
        state("A chosen panel") {
          CSPanel(unit: "of eight") { Text("4").csType(.figureM) }
        }
      }
      .padding(.horizontal, CSTokens.Space.gutter)
      .padding(.vertical, CSTokens.Space.s4)
    }
  }

  private func state<C: View>(_ name: String, @ViewBuilder _ c: () -> C) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      Text(name).csType(.agateS, caps: true).foregroundStyle(cs.mut)
      c()
    }
  }
}
#endif
