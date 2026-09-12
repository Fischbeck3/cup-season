// Cup Season — the course book: what the phone keeps about a course (D261,
// IOS-041, owner ruling R-N).
//
// THE ESCALATION THIS EXISTS FOR, in the owner's words: *"I was in the air on
// airplane mode the other day and wanted to see what the slope/rating and 1st
// hole was on a course I wanted to play but the app was dead on airplane mode
// essentially."* Nothing about a course was stored on the phone: tees,
// ratings, slopes, pars and stroke indexes were all live reads against
// `api_course_tees` / `api_course_holes`. On a plane, and at most golf
// courses, the app had nothing to say.
//
// A book is a few kilobytes. Played/planned courses are kept automatically;
// the owner's September 12 trip-preparation flow also allows an explicit save.
// Searching the whole catalogue offline still needs the network; the phone
// only searches books it already holds.
//
// Three honesty rules are built into the type rather than left to the drawing
// code, the way `DispatchSnapshot` builds L-44 in:
//
//   L-32 · A BOOK ALWAYS SAYS WHEN IT IS FROM. `savedAt` is stamped on the way
//     to disk and `savedLine` is the only sanctioned way to render it. There is
//     no path that draws a cached rating without the line beside it.
//
//   L-44 · NOTHING IS INVENTED. A tee with no rating or no slope never becomes
//     a book entry (the server drops it too); a tee whose hole card was never
//     cached carries `holes: []` and the card says so, rather than drawing
//     eighteen par 4s. `pars` and `strokeIndexes` return nil, never a guess.
//
//   The store is CAPPED and evicts least-recently-used (`CourseDisk`), so the
//     phone can never fill up with courses a golfer stopped playing.

import Foundation

/// One hole on one tee: the par, the stroke index and the length, as the API
/// cached them.
public struct CourseHole: Codable, Sendable, Equatable {
  public let hole: Int
  public let par: Int?
  /// The stroke index. `handicap` in `api_course_holes`; SI everywhere a
  /// golfer reads it.
  public let si: Int?
  /// **D290 · the length.** `api_course_holes.yardage` has existed since
  /// `20260714050000` and `my_course_books` never selected it, so the phone
  /// drew its card height-by-PAR while the desk drew height-by-yardage — the
  /// same course, two shapes (`Course.swift`'s D-2). Optional, and a book
  /// written before that migration decodes with nil here and falls back to
  /// par, which is a weaker picture and still a real one.
  public var yards: Int?
  public init(hole: Int, par: Int?, si: Int?, yards: Int? = nil) {
    self.hole = hole; self.par = par; self.si = si; self.yards = yards
  }
}

/// One rated tee, with its card if we have it.
public struct CourseBookTee: Codable, Sendable, Equatable, Identifiable {
  public let teeName: String?
  public let gender: String?
  public let rating: Double?
  public let slope: Int?
  public let holesCount: Int?
  public let parTotal: Int?
  public let yards: Int?
  /// The hole card. EMPTY is a real state — the tee was cached before the card
  /// was — and it is drawn as "no card saved", never as eighteen par 4s.
  public let holes: [CourseHole]

  public var id: String { "\(teeName ?? "")·\(gender ?? "")·\(holesCount ?? 0)" }

  public init(teeName: String?, gender: String?, rating: Double?, slope: Int?,
              holesCount: Int?, parTotal: Int?, yards: Int?, holes: [CourseHole]) {
    self.teeName = teeName; self.gender = gender; self.rating = rating; self.slope = slope
    self.holesCount = holesCount; self.parTotal = parTotal; self.yards = yards; self.holes = holes
  }

  /// "Blue · Women's" — the same title `CourseTee` prints, so the two lists
  /// cannot disagree about what a tee is called.
  public var title: String { (teeName ?? "Tee") + (gender == "female" ? " · Women’s" : "") }

  /// "Rating 71.2 · Slope 131". A missing figure prints an em dash rather than
  /// a zero — L-44, and the exact thing the owner could not read at 30,000ft.
  public var subtitle: String { "Rating \(CSCopy.points(rating)) · Slope \(slope.map(String.init) ?? "—")" }

  /// Readiness is about a complete, real tee card, not merely a cached name.
  /// Stroke indexes are optional for solo gross scoring; missing pars are not.
  public var offlineReady: Bool {
    guard let n = holesCount, n == 9 || n == 18,
          let rating, rating.isFinite, rating > 0, let slope, slope > 0,
          holes.count == n else { return false }
    let ordered = holes.sorted { $0.hole < $1.hole }
    return ordered.map(\.hole) == Array(1...n)
      && ordered.allSatisfy { (2...7).contains($0.par ?? 0) }
  }

  public var offlineStatus: String {
    if offlineReady { return "Ready offline · \(holesCount!) holes" }
    if rating == nil || slope == nil { return "Not ready · rating or slope missing" }
    return "Not ready · complete hole pars needed"
  }

  /// The pars in hole order, or nil when the card was never cached.
  public func pars(want: Int) -> [Int]? {
    let ordered = holes.sorted { $0.hole < $1.hole }
    guard ordered.count >= want else { return nil }
    let head = ordered.prefix(want)
    guard head.allSatisfy({ $0.par != nil }) else { return nil }
    return head.map { $0.par ?? 4 }
  }

  /// `(par, stroke index)` per hole — what the live tee sheet needs to score at
  /// all. nil when the card was never cached; the typed path stands.
  public func card(want: Int) -> [(par: Int, handicap: Int)]? {
    let ordered = holes.sorted { $0.hole < $1.hole }
    guard ordered.count >= want else { return nil }
    return ordered.prefix(want).map { (par: $0.par ?? 4, handicap: $0.si ?? 0) }
  }

  /// The first hole, which is the fact the escalation actually asked for.
  public var firstHole: CourseHole? { holes.min { $0.hole < $1.hole } }
}

/// Everything the phone keeps about one course.
public struct CourseBook: Codable, Sendable, Equatable, Identifiable {
  /// `api_courses.id` — GolfCourseAPI's text id, the same key the round and
  /// the plan already carry.
  public let id: String
  public let clubName: String?
  public let courseName: String?
  public let city: String?
  public let state: String?
  public let tees: [CourseBookTee]
  /// Why this course is on the phone. Both may be true.
  public let planned: Bool
  public let played: Bool
  public let nextPlayOn: String?
  public let lastPlayedOn: String?
  /// When THIS PHONE wrote the book. Never the server's `cached_at`: the line
  /// a golfer reads has to be about the copy in their hand.
  public var savedAt: Date
  /// Touched on every read. The eviction order, and nothing else.
  public var usedAt: Date

  public init(id: String, clubName: String?, courseName: String?, city: String?, state: String?,
              tees: [CourseBookTee], planned: Bool = false, played: Bool = false,
              nextPlayOn: String? = nil, lastPlayedOn: String? = nil,
              savedAt: Date = Date(), usedAt: Date = Date()) {
    self.id = id; self.clubName = clubName; self.courseName = courseName
    self.city = city; self.state = state; self.tees = tees
    self.planned = planned; self.played = played
    self.nextPlayOn = nextPlayOn; self.lastPlayedOn = lastPlayedOn
    self.savedAt = savedAt; self.usedAt = usedAt
  }

  /// `CourseHit.label`'s rule, so the book and the search row read identically.
  public var label: String { CourseHit.label(club: clubName, course: courseName) }
  public var place: String { [city, state].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ") }

  /// "Papago · 3 tees" — `CourseHit.subline`'s shape.
  public var subline: String { (place.isEmpty ? "" : place + " · ") + "\(tees.count) tee\(tees.count == 1 ? "" : "s")" }

  /// The tee a golfer most likely wants first: the LONGEST 18.
  ///
  /// OE-3 / NW-2 · this was `tees.first { holesCount == 18 }` — the first
  /// 18-hole tee in whatever order the fill happened to leave. Both fill paths
  /// sort by `course_rating desc` (`my_course_books` orders
  /// `number_of_holes desc, course_rating desc, tee_name`), and a women's
  /// rating off the same tee is HIGHER than a men's, so "the first 18" was
  /// systematically a women's tee: **seven of seven** books on the owner's own
  /// phone opened on one, on the screen R-N exists for. Nothing on the golfer
  /// card carries a gender, so there is nothing to match a golfer against —
  /// the book therefore does what this comment always claimed and takes the
  /// longest, which is a fact about the COURSE rather than a guess about the
  /// person reading it.
  public var defaultTee: CourseBookTee? {
    let full = tees.filter { ($0.holesCount ?? 18) == 18 }
    return CourseBook.longest(full.isEmpty ? tees : full)
  }

  /// The longest tee in a pool.
  ///
  /// `keep()`'s write-through has no yardage to carry (`api_course_tees` does
  /// not return one), so a book filled only that way can have none at all. In
  /// that case the pool keeps its order minus the ONE bias we know is in it:
  /// a women's row is not preferred over a men's one by a sort that only ever
  /// ranked them by rating. It is not a claim about the golfer; it is the
  /// removal of a claim the ordering was making on its own.
  static func longest(_ pool: [CourseBookTee]) -> CourseBookTee? {
    if let byYards = pool.filter({ ($0.yards ?? 0) > 0 }).max(by: { ($0.yards ?? 0) < ($1.yards ?? 0) }) {
      return byYards
    }
    return pool.first { $0.gender != "female" } ?? pool.first
  }

  /// The book as a search row, so an offline picker draws the same component
  /// the online one does (L-34 — one fact, one place, one renderer).
  public var hit: CourseHit {
    CourseHit(id: id, label: label, place: place,
              tees: tees.map { CourseTee(tee_name: $0.teeName, gender: $0.gender,
                                         course_rating: $0.rating, slope_rating: $0.slope,
                                         number_of_holes: $0.holesCount) })
  }

  /// The tee that was PICKED, and nothing else. A miss returns nil.
  ///
  /// NW-3 · this ended `?? defaultTee`, so a tee renamed on the server, typed
  /// by hand, or simply nil handed back the DEFAULT tee's pars and stroke
  /// indexes as though they were the picked tee's — silently, with
  /// `CourseBookCopy.noCard` never firing because a card *was* found. Stroke
  /// indexes allocate strokes in Match Play, Skins and Wolf, so a card off the
  /// wrong tee is worse than no card at all; and this file's own law at the
  /// top already says pars and stroke indexes "return nil, never a guess".
  ///
  /// `rating` separates two tees that share a name — Palo Verde carries a
  /// men's `Back` and a women's `Back` — which a name alone cannot do.
  public func tee(named name: String?, holes want: Int? = nil, rating: Double? = nil) -> CourseBookTee? {
    guard let name, !name.isEmpty else { return nil }
    var pool = tees.filter { $0.teeName == name }
    guard !pool.isEmpty else { return nil }
    if let want, pool.contains(where: { $0.holesCount == want }) {
      pool = pool.filter { $0.holesCount == want }
    }
    if let rating, let exact = pool.first(where: { $0.rating == rating }) { return exact }
    // Same name, no rating to separate them: the longest, never the sort's
    // own first (see `longest`). Still the PICKED name — never another tee.
    return CourseBook.longest(pool)
  }

  public func touched(_ now: Date = Date()) -> CourseBook {
    var c = self; c.usedAt = now; return c
  }

  // MARK: - the honest line (L-32)

  /// "Saved on your phone Sat Sep 5" — the ONLY sanctioned rendering of a
  /// cached course's provenance. It is never omitted, and it never says
  /// "updated" or "live", because it is neither.
  public func savedLine(now: Date = Date(), calendar: Calendar = .current) -> String {
    "Saved on your phone \(CourseBookCopy.when(savedAt, now: now, calendar: calendar))"
  }
}

/// The sentences a PLANNED round is allowed to say about its course (D290).
/// One home, and the desk's `csPlanCourseHtml` prints the same three — a
/// producer written twice in two idioms with no witness is how two clients
/// come to disagree about the same course (D201/D234).
public enum PlanCourseCopy {
  /// `OUT 36 · IN 36  ·  7,068 YDS  ·  73.3 / 137`.
  ///
  /// **OUT and IN here are the COURSE'S PARS and never a score**, which is why
  /// the block above them is labelled with the tee it is drawn from. nil when
  /// the card is too thin to total — never a half-line with one figure in it.
  public static func turn(holes: [CourseHole], tee: CourseBookTee?) -> String? {
    var parts: [String] = []
    let ordered = holes.sorted { $0.hole < $1.hole }
    let out = ordered.prefix(9).compactMap(\.par).reduce(0, +)
    let inn = ordered.dropFirst(9).prefix(9).compactMap(\.par).reduce(0, +)
    if out > 0 && inn > 0 { parts.append("OUT \(out) · IN \(inn)") }
    if let y = tee?.yards, y > 0 { parts.append("\(PlanCourseCopy.grouped(y)) YDS") }
    if let r = tee?.rating, let sl = tee?.slope { parts.append("\(CSCopy.points(r)) / \(sl)") }
    return parts.isEmpty ? nil : parts.joined(separator: "  ·  ")
  }

  /// `PAR 5 · 604 · SI 1` — the label under one of the three that decide it.
  /// A hole with no yardage cached says par and stroke index and stops; it
  /// does not guess a length (L-44).
  public static func hole(par: Int?, yards: Int?, si: Int?) -> String {
    var parts: [String] = []
    if let par { parts.append("par \(par)") }
    if let yards, yards > 0 { parts.append("\(yards)") }
    if let si { parts.append("si \(si)") }
    return parts.joined(separator: " · ")
  }

  /// *"You have played here four times · best 78."* — L-33's small numbers as
  /// words, through the one producer. nil when you have never played it: the
  /// line is ABSENT rather than saying you have not.
  public static func history(_ course: String, played: [Int]) -> String? {
    guard !played.isEmpty else { return nil }
    let n = played.count
    let head = "You have played here \(CSCopy.spelled(n)) time\(n == 1 ? "" : "s")"
    guard let best = played.min() else { return head + "." }
    return head + " · best \(best)."
  }

  /// `7,068` — a yardage is grouped, because four digits with no separator is
  /// a part number.
  public static func grouped(_ n: Int) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.groupingSeparator = ","
    return f.string(from: NSNumber(value: n)) ?? "\(n)"
  }
}

/// The words the offline store is allowed to say. One home, because these are
/// the sentences that keep a cached read from reading as a live one, and a
/// second copy of them is how one of them drifts (D201/D249).
public enum CourseBookCopy {
  /// "today" · "Sat Sep 5" — a day, never a fake precision.
  public static func when(_ at: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
    let a = CSDate.iso(at, calendar: calendar), b = CSDate.iso(now, calendar: calendar)
    if a == b { return "today" }
    if let d = CSDate.days(from: a, to: b, calendar: calendar), d == 1 { return "yesterday" }
    return LeagueDates.dowMonDay(a, calendar: calendar)
  }

  /// The banner over a course drawn from the phone rather than the server.
  public static func offlineBanner(_ book: CourseBook, now: Date = Date(), calendar: Calendar = .current) -> String {
    book.savedLine(now: now, calendar: calendar) + ". Ratings and cards change; this is the copy you have."
  }

  /// A course the phone has never kept. It says so and offers what it can —
  /// never a blank screen, never an invented tee (L-32, L-44).
  public static let neverKept =
    "This course is not on your phone. Cup Season keeps the courses you have played or planned; open this one with a signal and it will be here next time."

  /// A read that failed with nothing cached behind it.
  public static let readFailed =
    "Could not reach the course list. What your phone has kept is below."

  /// The search dropdown's own line when the network is not answering.
  public static let searchOffline =
    "No signal — searching the courses on your phone. The full list needs a connection."

  /// The tee card, when the tee was kept but its holes never were.
  public static let noCard =
    "No hole card saved for this tee. Pars and stroke indexes come down the first time you play it with a signal."

  /// The one-line explanation of what the store IS, for the You tab's row.
  public static let what =
    "Courses you have played or planned are kept on your phone, so the tees, ratings and cards are there with no signal."
}
