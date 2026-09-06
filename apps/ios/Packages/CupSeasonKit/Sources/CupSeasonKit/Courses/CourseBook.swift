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
// A book is a few kilobytes. The scope is R-N's exactly — every course on my
// schedule and every course I have posted a round at, and NOTHING else.
// Searching the whole catalogue offline is not in scope and needs the network,
// which the client says out loud rather than pretending.
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

/// One hole on one tee: the par and the stroke index, as the API cached them.
public struct CourseHole: Codable, Sendable, Equatable {
  public let hole: Int
  public let par: Int?
  /// The stroke index. `handicap` in `api_course_holes`; SI everywhere a
  /// golfer reads it.
  public let si: Int?
  public init(hole: Int, par: Int?, si: Int?) { self.hole = hole; self.par = par; self.si = si }
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

  /// The tee a golfer most likely wants first: the longest 18 with a rating.
  public var defaultTee: CourseBookTee? {
    tees.first { ($0.holesCount ?? 18) == 18 } ?? tees.first
  }

  /// The book as a search row, so an offline picker draws the same component
  /// the online one does (L-34 — one fact, one place, one renderer).
  public var hit: CourseHit {
    CourseHit(id: id, label: label, place: place,
              tees: tees.map { CourseTee(tee_name: $0.teeName, gender: $0.gender,
                                         course_rating: $0.rating, slope_rating: $0.slope,
                                         number_of_holes: $0.holesCount) })
  }

  public func tee(named name: String?, holes want: Int? = nil) -> CourseBookTee? {
    if let want {
      if let exact = tees.first(where: { $0.teeName == name && $0.holesCount == want }) { return exact }
    }
    return tees.first { $0.teeName == name } ?? defaultTee
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
