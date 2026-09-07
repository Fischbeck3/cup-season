// Cup Season — the course page (D272 / D275, IOS-048, `surfaces/course.md`).
//
// A course is the only object in Cup Season that is **a place**. Everything
// else — a season, an event, a golfer, a round — is a record of what people
// did; a course is where they did it, and it exists whether or not anybody
// opens the app. That is why it gets the product's only image-led surface and
// its only pull quote.
//
// THE SURFACE THE BLIND REVIEW FAILED, 0/3 ON PROUD-TO-POST, FOR ONE REASON:
// there was no photograph of a golf course anywhere in five renders, and the
// page a golfer actually got was a 2×2 grid of bordered KPI tiles under a
// cache disclaimer — "the canonical SaaS dashboard pattern", scoring the two
// lowest cells in the entire audit. What replaces it, top to bottom: the plate
// (the §10.1 ladder, full-bleed, with the name reversed out of it), the facts
// as ONE LINE OF TYPE, the rating in `ink`, the pull quote, the golfers who
// have played it **named in a sentence**, the front nine printed on a leaf,
// and the rounds posted here.
//
// IT IS A PUSHED SCREEN AND NOT A SHEET (§7.3: objects are pushed). The
// `Done`-in-ember toolbar is gone; a pushed screen has no dismiss verb.
//
// AND IT STILL WORKS ON A PLANE. Every fact above the rounds list — the name,
// the place, the tees, the ratings, the slopes, the pars, the stroke indexes,
// the drawn plate and the whole leaf — comes from `CourseDisk`, exactly as
// D261 / R-N built it. The social half is one network read that degrades to
// nothing without ever taking the page down with it.

import SwiftUI
import CSDesign
import CupSeasonKit

struct CourseScreen: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  @Environment(\.presenter) private var presenter
  @Environment(SessionStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  @State private var vm: CourseModel
  @State private var rating = false

  init(courseId: String?, label: String? = nil) {
    _vm = State(initialValue: CourseModel(courseId: courseId, label: label))
  }

  var body: some View {
    ScrollViewReader { proxy in
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        if let book = vm.book {
          page(book)
        } else if vm.loading {
          // **Loading is the destination's own geometry, redacted** (§13.2) —
          // never a spinner inside content. The shipped
          // `CSFine("Looking for this course on your phone…")` is deleted.
          page(CourseModel.placeholder(vm.label)).csRedacted(true)
        } else {
          neverKept
        }
      }
      .padding(.bottom, CSTokens.Space.s6)
      .csPage("course")
    }
    // **The plate runs full-bleed UNDER the status bar**, which is the whole
    // reason `CSPhotoScrim.top` exists — without this the scroll view insets
    // its content below the bar and the "full-bleed" plate starts 114pt down
    // the screen, which is what the first build of this page did.
    .csPlateBleedsInDark(cs.bg0)
    .background(cs.bg0.ignoresSafeArea())

    // §2.1 · **the system bar carries the back chevron only** — and on this
    // page it does not carry it at all. A full-bleed plate under a bar means
    // the platform's own back button arrives inside a translucent disc sitting
    // on the photograph; the design draws the chevron itself, at 1.7pt in
    // `scrimInk`, on the `.top` scrim that exists to hold it. The stack's own
    // edge-swipe is untouched.
    // **THE BAR IS EMPTIED, NOT HIDDEN** (`csBareBar`, DF-07). Hiding it left
    // nothing to hang `toolbarColorScheme` on, so in the LIGHT printing the
    // system put its DARK glyph set on this page's near-black `ceremony`
    // plate: the clock, the cellular dots and the battery, unreadable, over
    // the top 60pt of a flagship surface. The plate is dark in both
    // printings and now says so. Nothing else about the bar changes — it
    // paints no background, carries no title and shows no system back button.
    .csBareBar(overDarkPlate: true)
    .task { await vm.load(me: store.me?.profile?.id) }
    .sheet(isPresented: $rating) {
      RateCourseSheet(courseId: vm.courseId ?? "", course: vm.title, rating: vm.rating) { r in
        vm.rating = r
      }
    }
    #if DEBUG
    // `-cs_dev_open coursecard rate` raises the rating sheet, which otherwise
    // opens from a link and therefore needs a finger this Mac does not have.
    .task(id: vm.loading) {
      guard !vm.loading, ProcessInfo.processInfo.arguments.contains("-cs_dev_rate") else { return }
      try? await Task.sleep(for: .seconds(1))
      rating = true
    }
    // `-cs_dev_scroll <leaf|rounds>` — the same door the season room and the
    // You tab have. A page two screens tall cannot be judged from its top, and
    // this Mac has no way to scroll a simulator by hand.
    .task(id: vm.loading) {
      let a = ProcessInfo.processInfo.arguments
      guard !vm.loading, let i = a.firstIndex(of: "-cs_dev_scroll"), i + 1 < a.count else { return }
      try? await Task.sleep(for: .seconds(2))
      proxy.scrollTo("course-" + a[i + 1], anchor: .top)
    }
    #endif
    }
  }

  /// The one piece of chrome on the surface. `CSGlyph(.chevron)` points
  /// forward, so the back chevron is the same drawing flipped — one path in
  /// the family rather than a second one that has to match it.
  private var back: some View {
    Button { dismiss() } label: {
      CSGlyph(.chevron, size: .tab)
        .scaleEffect(x: -1)
        .foregroundStyle(CSTokens.dark.scrimInk)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .padding(.leading, CSTokens.Space.gutter - 10)
    .padding(.top, 46)
    .accessibilityLabel("Back")
  }

  // MARK: - the page

  @ViewBuilder private func page(_ book: CourseBook) -> some View {
    plate(book)
    VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
      facts(book)
      // D289 · the rail IS the control. One tap sets it, tapping the value you
      // already hold takes it off, and the write returns the aggregate so the
      // figure above re-tallies from the server's own arithmetic rather than
      // from a number this view was holding.
      CSRating(value: vm.rating.stars, count: vm.rating.count,
               sentence: vm.rating.friendsLine.isEmpty ? nil : vm.rating.friendsLine,
               mine: vm.rating.mine,
               onSet: vm.courseId == nil ? nil : { v in Task { await vm.set(v) } },
               rate: { rating = true })
      said
      quote
      friends
      CourseCardLeaf(tee: vm.tee(in: book), title: leafTitle(book)).id("course-leaf")
      // §2.6 · off the first viewport: the back nine and every rated tee,
      // pushed as a screen and not a sheet.
      if vm.book != nil {
        NavigationLink { CourseWholeCardScreen(book: book) } label: { Text("The whole card") }
          .buttonStyle(.csTertiary(.content))
      }
      rounds(book).id("course-rounds")
    }
    .padding(.horizontal, CSTokens.Space.gutter)
    .padding(.top, CSTokens.Space.s4)
  }

  /// **The plate — the §10.1 ladder, and the object does not change when the
  /// content does.** A golfer's round photo here, else the drawn card off the
  /// phone's own hole card, else the contour seeded from the course id. There
  /// is no fourth rung and no gradient wash.
  @ViewBuilder private func plate(_ book: CourseBook) -> some View {
    ZStack(alignment: .topLeading) {
      coursePlate(book)
      // the chevron rides the PLATE, so it scrolls away with the picture
      // rather than hanging over the facts line half a screen later
      back
    }
  }

  @ViewBuilder private func coursePlate(_ book: CourseBook) -> some View {
    CSCoursePlate(eyebrow: vm.eyebrow(book), name: vm.headline(book),
                  course: vm.secondLine(book), place: book.place,
                  credit: vm.page.hero?.credit,
                  reserve: vm.rung(book) == .card ? 140 : 0) {
      // D-9 · the plate spends one of the two panels, and it is **absent**
      // — not dashed — when you have not played here.
      //
      // **At AX3 it stops being a panel**, and that is the panel's own licence
      // rather than a dodge: §3.2 allows the bone tile *over a photograph*, and
      // at the accessibility sizes §4.1 takes the whole foot block OFF the
      // image and onto the page's own ground. A figure standing on the page
      // takes the page's device — the rule-and-figure — and the 44pt-grown
      // numeral gets the measure instead of a 64pt tile.
      if let best = vm.page.myBest {
        if typeSize.isA11y {
          CSFigure("\(best)", size: .m, label: "Your best")
        } else {
          CSPanel(.overPhoto, unit: "Your best", width: 64) {
            Text("\(best)").csType(.figureM)
          }
        }
      }
    } plate: {
      ladder(book)
    }
  }

  @ViewBuilder private func ladder(_ book: CourseBook) -> some View {
    if case .photo = vm.rung(book), let hero = vm.page.hero {
      // rung 1 · a golfer's own round photo at this course, credited
      AsyncImage(url: hero.url) { $0.resizable().scaledToFill() } placeholder: { cs.bg1 }
    } else if vm.rung(book) == .card, let holes = vm.drawnCard(book) {
      // rung 2 · the drawn card, from real par, stroke index and yardage
      // §13(b) · the bars are bottom-anchored ABOVE the head block rather than
      // behind it, and the tallest is clamped to the plate's height less the
      // room the copy needs — a bar running into the eyebrow is the render's
      // own known imperfection, fixed here rather than shipped.
      //
      // **A DRAWN PLATE STANDS ON THE CEREMONY GROUND IN BOTH PRINTINGS.**
      // §4 says the drawn card fills the plate with the name reversed out of
      // it *exactly as over a photograph* — and a name cannot be reversed out
      // of the light theme's paper. On `bg1` in light the scrim turned the
      // whole plate into a white-to-black ramp, which is a **gradient wash**:
      // the one image state D272 bans by name, arrived at by accident. The
      // ground is pinned the way the credential's is.
      ZStack(alignment: .top) {
        CSTokens.dark.ceremony
        VStack(spacing: 0) {
          CSDrawnCard(holes, scale: .hero)
            .frame(height: 88)
            .padding(.horizontal, CSTokens.Space.gutter)
            .padding(.top, 52)
          Spacer(minLength: 0)
        }
        .csCeremony()
      }
    } else {
      // rung 3 · the contour, seeded from the course id — hero scale only, on
      // the same pinned ground as the drawn card and for the same reason
      ZStack {
        CSTokens.dark.ceremony
        CSContour(seed: book.id, tint: CSTokens.dark.ceremonyMut.opacity(CSTokens.Alpha.a56),
                  mark: vm.hardestHole(book) != nil ? CSTokens.dark.ceremonyBrand : nil)
      }
    }
  }

  /// §2.2 · one line of type, and D-1's provenance beneath it as the object's
  /// own label rather than as the first paragraph a golfer reads about a golf
  /// course.
  @ViewBuilder private func facts(_ book: CourseBook) -> some View {
    if let tee = vm.tee(in: book) {
      CSFactsLine(vm.facts(tee), label: vm.factsLabel(book, tee: tee), spoken: vm.factsSpoken(book, tee: tee))
    }
  }

  /// **D289 · WHAT WE THOUGHT OF THE COURSE** — the owner's own clause, and
  /// the surface's serif finally has a producer. Your sentence first (it is
  /// yours and you can change it), then up to three of your golfers'. Never a
  /// stranger's, never an uncredited one, and the block is ABSENT rather than
  /// empty when nobody has written anything.
  @ViewBuilder private var said: some View {
    if vm.rateFailed {
      Text("That did not save. Your rating is as it was — try it again in a moment.")
        .csType(.bodyS).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
    }
    if let mine = vm.rating.mineNote, !mine.isEmpty {
      CSQuote(mine, attribution: "You.")
    }
    ForEach(vm.rating.notes) { n in
      CSQuote(n.note, attribution: n.line)
    }
  }

  /// §2.4 · the one serif on the surface, and it renders only when a golfer
  /// actually wrote a sentence about this place. **There is no producer for it
  /// yet** (`course.md` §7.5 — the `posts.body` attached to a round played
  /// here is a new selection), so today the block is absent and the surface's
  /// serif moves to the empty state's headline, exactly as D-7 says it does.
  @ViewBuilder private var quote: some View {
    if let q = vm.quote {
      CSQuote(q.text, attribution: q.attribution)
    }
  }

  /// §2.5 · **the line that makes a course page social rather than a database
  /// record.** Overlapping discs read as a group; the sentence names them.
  @ViewBuilder private var friends: some View {
    if !vm.page.others.isEmpty {
      let line = vm.page.friendsLine
      Group {
        if typeSize.isA11y {
          VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
            CSFaceRow(vm.faces, style: .overlapped)
            CSFigureRun(line, role: .body).foregroundStyle(cs.ink)
          }
        } else {
          HStack(alignment: .top, spacing: CSTokens.Space.s3) {
            CSFaceRow(vm.faces, style: .overlapped)
            CSFigureRun(line, role: .body).foregroundStyle(cs.ink)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(line.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: ""))
    }
  }

  /// §2.7 · the rounds posted here. **No rank rail** — these rounds are not
  /// ranked against each other, and painting a rail would assert an order the
  /// data does not have.
  @ViewBuilder private func rounds(_ book: CourseBook) -> some View {
    if !vm.page.rounds.isEmpty {
      VStack(alignment: .leading, spacing: 0) {
        HStack(spacing: CSTokens.Space.s3) {
          Text("Rounds here").csType(.agate, caps: true).foregroundStyle(cs.mut)
            .accessibilityAddTraits(.isHeader)
          CSRule()
        }
        .padding(.bottom, CSTokens.Space.s2)
        ForEach(vm.page.rounds.prefix(12)) { r in
          CSRule()
          CourseRoundSlat(row: r, open: { id in presenter.tourCard = id })
        }
      }
    } else if !vm.page.failed {
      // §4 · **nobody has played it** — a fact about the world, never the
      // golfer's omission, and the page's one primary.
      CSEmpty(glyph: .scorecard,
              eyebrow: "The first card",
              headline: "Nobody here has played it.",
              fact: vm.firstCardFact(book),
              door: .primary("Add my round") {
                presenter.postOnComposer = true
                presenter.showPost = true
              })
    }
  }

  /// §4 · the course is not on this phone and there is no signal. The name at
  /// `display`, `CourseBookCopy.neverKept` verbatim, and the one door that
  /// both works offline and makes the book arrive next time.
  private var neverKept: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      back.padding(.leading, -(CSTokens.Space.gutter - 10))
      Text(vm.title).csType(.display).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
      Text(CourseBookCopy.neverKept).csType(.body).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
      CSDoor(.primary("Put it on the plan") {
        presenter.declare = DeclarePrefill(course: vm.label, courseId: vm.courseId)
      })
    }
    .padding(.horizontal, CSTokens.Space.gutter)
    .padding(.top, CSTokens.Space.s2)
  }

  private func leafTitle(_ book: CourseBook) -> String {
    let tee = vm.tee(in: book)?.title ?? ""
    return tee.isEmpty ? "The front nine" : "The front nine · \(tee)"
  }
}

// MARK: - A round posted here

/// 50pt, a rule on its top edge, a face, the golfer's name in title case, the
/// date, and the gross as a bare `figureM` — **no rule and no label**, because
/// a figure repeating down a trailing column already has its hierarchy from
/// the column (`CSFigure`'s stated exception).
///
/// At the accessibility sizes the gross moves UNDER the sub-line as its own
/// line and the row's height goes intrinsic (§4.1).
struct CourseRoundSlat: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let row: CourseRoundRow
  let open: (UUID) -> Void

  var body: some View {
    let content = Group {
      if typeSize.isA11y {
        HStack(alignment: .top, spacing: CSTokens.Space.s3) {
          face
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            name; sub
            if let g = row.gross { Text("\(g)").csType(.figureS).foregroundStyle(cs.ink) }
          }
        }
      } else {
        HStack(spacing: CSTokens.Space.s3) {
          face
          VStack(alignment: .leading, spacing: 2) { name; sub }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
          if let g = row.gross { Text("\(g)").csType(.figureM).foregroundStyle(cs.ink) }
        }
        .frame(minHeight: 50)
      }
    }
    .contentShape(Rectangle())
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(spoken)

    if let id = row.profileId {
      Button { open(id) } label: { content }.buttonStyle(.plain)
        .accessibilityHint("Opens their card")
    } else {
      content
    }
  }

  private var face: some View {
    CSFace(CSFace.Model(id: row.profileId ?? UUID(), marker: row.marker,
                        initials: String(row.name.prefix(1)), isViewer: row.isMine),
           size: .slat)
  }
  private var name: some View {
    // §1.3 · a person in a course row is TITLE CASE
    Text(row.name.isEmpty ? "A golfer" : row.name).csType(.social).foregroundStyle(cs.ink)
      .lineLimit(typeSize.isA11y ? 2 : 1).truncationMode(.tail)
  }
  private var sub: some View {
    Text(row.subline()).csType(.agateS, caps: true).foregroundStyle(cs.mut).lineLimit(1)
  }
  private var spoken: String {
    let who = row.name.isEmpty ? "A golfer" : row.name
    let g = row.gross.map { ", \($0)" } ?? ""
    return "\(who)\(g). \(row.subline())"
  }
}

// MARK: - The model

@Observable
@MainActor
final class CourseModel {
  let courseId: String?
  let label: String
  var book: CourseBook?
  var page = CoursePageAnswer()
  var rating = CourseRating.none
  var loading = true
  var picked: String?
  /// §2.4's pull quote. **There is no producer for it** (`course.md` §7.5), so
  /// it is nil on every course and the block does not render — never a
  /// placeholder, never a stock line, and never a caption about the course
  /// written by us.
  var quote: (text: String, attribution: String?)?
  /// D289 · the last write did not land. Said once, under the rail, in the
  /// product's voice — never a raw code and never a silent no-op.
  var rateFailed = false

  private let store = CourseBookStore()

  init(courseId: String?, label: String?) {
    self.courseId = courseId
    self.label = label ?? ""
  }

  var title: String { book?.label ?? (label.isEmpty ? "Course" : label) }

  /// **The ladder, decided in one place** (§10.1). A surface asks which rung it
  /// is on rather than working it out twice — once to draw and once to lay out.
  enum Rung: Equatable { case photo, card, contour }
  func rung(_ book: CourseBook) -> Rung {
    if page.hero != nil { return .photo }
    if let c = drawnCard(book), !c.isEmpty { return .card }
    return .contour
  }

  func tee(in book: CourseBook) -> CourseBookTee? {
    book.tees.first { $0.id == picked } ?? book.defaultTee
  }

  /// **THE ACT** (D289). One tap: the value goes to the server, the server
  /// hands back the whole aggregate, and this view takes it. Tapping the value
  /// you already hold is `unrate_course` — one tap in, one tap out.
  ///
  /// **`p_note` is not sent**, so a star moved on the page can never erase a
  /// sentence written in the sheet: null leaves the note alone by the
  /// column's own contract.
  ///
  /// A failure leaves the rating exactly as it was and says so. It does not
  /// queue, and it does not pretend.
  func set(_ v: Double) async {
    guard let courseId else { return }
    let had = rating
    do {
      rating = (rating.mine.map { abs($0 - v) < 0.01 } ?? false)
        ? try await CourseRatingService().unrate(courseId)
        : try await CourseRatingService().rate(courseId, stars: v)
    } catch {
      rating = had
      rateFailed = true
    }
  }

  func load(me: UUID?) async {
    loading = true
    let answer = await store.book(courseId)
    book = answer.book
    picked = answer.book?.defaultTee?.id
    loading = false
    // the social half and the rating are both allowed to fail without taking
    // the page with them (L-32)
    async let social = CoursePageRepository().page(courseId: courseId, me: me)
    async let stars = CourseRatingService().rating(courseId)
    page = await social
    rating = await stars
  }

  // MARK: the copy

  /// `KEPT · FOUR OF YOURS HAVE PLAYED IT` · `ON YOUR SCHEDULE · SATURDAY`.
  /// Never invented: every clause is a fact the page can prove.
  func eyebrow(_ book: CourseBook) -> String? {
    var parts: [String] = []
    if let next = book.nextPlayOn {
      parts.append("On your schedule · \(LeagueDates.dowMonDay(next))")
    } else if book.played || page.myBest != nil {
      parts.append("Kept")
    } else if book.planned {
      parts.append("On your plan")
    } else {
      parts.append("Kept")
    }
    let n = page.others.count
    if n > 0 { parts.append("\(CSCopy.spelled(n)) of yours \(n == 1 ? "has" : "have") played it") }
    return parts.joined(separator: " · ")
  }

  /// The club is the headline; the course is the second line when they differ
  /// — *GOLD CANYON / DINOSAUR MOUNTAIN*, which is the long-name answer at
  /// title scale.
  func headline(_ book: CourseBook) -> String {
    guard let club = book.clubName, !club.isEmpty else { return book.label }
    return club
  }
  func secondLine(_ book: CourseBook) -> String? {
    guard let course = book.courseName, !course.isEmpty,
          let club = book.clubName, !club.isEmpty, course != club else { return nil }
    return course
  }

  /// `72 PAR · 7,068 YDS · 72.5 RTG · 130 SLOPE`. A figure with no producer is
  /// **absent**, never a dash and never a zero (L-44).
  func facts(_ tee: CourseBookTee) -> [CSFactsLine.Fact] {
    var out: [CSFactsLine.Fact] = []
    if let p = tee.parTotal { out.append(.init("\(p)", "par")) }
    if let y = tee.yards, y > 0 { out.append(.init(CourseModel.grouped(y), "yds")) }
    if let r = tee.rating { out.append(.init(CSCopy.points(r), "rtg")) }
    if let s = tee.slope { out.append(.init("\(s)", "slope")) }
    return out
  }

  /// D-1 · the tee it describes, the difficulty fact the cached card can
  /// prove, and L-32's provenance verbatim from `CourseBook.savedLine`.
  func factsLabel(_ book: CourseBook, tee: CourseBookTee) -> String {
    var parts = [tee.title]
    if let h = hardestHole(book) { parts.append("the \(h)\(CSOrdinal.suffix(h)) plays hardest") }
    parts.append(book.savedLine())
    return parts.joined(separator: " · ")
  }

  func factsSpoken(_ book: CourseBook, tee: CourseBookTee) -> String {
    let figures = facts(tee).map { "\($0.value) \($0.unit)" }.joined(separator: ", ")
    return "\(figures), from the \(tee.title). \(factsLabel(book, tee: tee))."
  }

  /// The hardest hole by stroke index, or nil when no card is cached. It is
  /// the sentence that explains the drawn card's one gold bar — a fact the
  /// page was already printing, not a caption teaching the reader how to read
  /// a graphic (§10.1).
  func hardestHole(_ book: CourseBook) -> Int? {
    guard let tee = tee(in: book) else { return nil }
    return tee.holes.filter { $0.si != nil }.min { ($0.si ?? 99) < ($1.si ?? 99) }?.hole
  }

  /// Rung 2's holes, or nil when this phone has no card for the tee — and then
  /// the plate falls to the contour rather than drawing eighteen invented
  /// bars. *Fake data as ornament is less premium than a plain colour.*
  func drawnCard(_ book: CourseBook) -> [CSDrawnCard.Hole]? {
    guard let tee = tee(in: book) else { return nil }
    let holes = tee.holes.sorted { $0.hole < $1.hole }.compactMap { h -> CSDrawnCard.Hole? in
      guard let par = h.par else { return nil }
      return CSDrawnCard.Hole(number: h.hole, par: par, si: h.si, yards: nil)
    }
    return holes.isEmpty ? nil : holes
  }

  /// The faces above the sentence. Capped at six: a group is a group, and
  /// seven overlapping discs is a crowd (§6.3).
  var faces: [CSFace.Model] {
    page.others.prefix(CoursePageAnswer.namedCap).map { r in
      CSFace.Model(id: r.profileId ?? UUID(), marker: r.marker,
                   initials: String(r.name.prefix(1)), isViewer: r.isMine)
    }
  }

  /// The empty state's one true fact. §7.7 refuses "Galen keeps it" — there is
  /// no `home_course_id` behind `profiles.home_course` and a string match
  /// dressed as a fact is exactly what this product does not do. The schedule
  /// is real, so the schedule is what it says.
  func firstCardFact(_ book: CourseBook) -> String? {
    if let next = book.nextPlayOn { return "It is on your schedule for \(LeagueDates.dowMonDay(next))." }
    if let last = book.lastPlayedOn { return "You last played here \(LeagueDates.dowMonDay(last))." }
    return "One posted round puts a number on this page."
  }

  /// `7,068` — a yardage is grouped, because four digits with no separator is
  /// a part number.
  static func grouped(_ n: Int) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.groupingSeparator = ","
    return f.string(from: NSNumber(value: n)) ?? "\(n)"
  }

  /// The redacted skeleton: the destination's own geometry with real-length
  /// placeholder widths. It is never written to disk and never drawn
  /// unredacted — `csRedacted(true)` is applied at the one call site.
  static func placeholder(_ label: String) -> CourseBook {
    CourseBook(id: "", clubName: label.isEmpty ? "Course" : label, courseName: nil,
               city: "Phoenix", state: "AZ",
               tees: [CourseBookTee(teeName: "Blue", gender: nil, rating: 72.0, slope: 130,
                                    holesCount: 18, parTotal: 72, yards: 6800, holes: [])],
               planned: false, played: false)
  }
}
