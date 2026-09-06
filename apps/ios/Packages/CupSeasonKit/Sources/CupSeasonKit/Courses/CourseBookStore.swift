// Cup Season — the one door onto the offline course store (D261, IOS-041, R-N).
//
// Every course read on the phone comes through here now, and the rule is the
// same in all three cases R-N names:
//
//   1 · LOOKING A COURSE UP — the tees, the ratings and slopes, the card. The
//       airplane case, exactly. `book(_:)` answers from disk first and says
//       when the copy is from; with a signal it refreshes underneath.
//   2 · STARTING AND SCORING A LIVE ROUND — the bigger win, because golf
//       courses are where signal is worst and the tee sheet needs pars and
//       stroke indexes to score at all. `card(courseId:tee:want:)` is what
//       `LiveRepository.courseHoles` falls back to.
//   3 · THE COMPOSER offering a course you have played, with its tee data, so
//       a round can be added in the car park and posted when the signal
//       returns. `search(_:)` is the offline half of the picker.
//
// WRITE-THROUGH, NOT A SECOND FETCHER. Every read that succeeds against the
// network is handed to `keep(...)`, so the store fills itself from ordinary
// use as well as from `my_course_books`. Nothing here invents a course, and a
// read that fails returns `.failed`, never `[]` dressed as "no courses" (L-32:
// a failed read is never an empty screen).

import Foundation

/// What a course read came back as, and where it came from. The CALLER cannot
/// draw a cached figure without knowing it is cached, because there is no
/// case that hands over a book without saying so.
public enum CourseSource: Sendable, Equatable {
  /// Straight off the server, this second.
  case live
  /// Off the phone. Carries the book so the honest line can be drawn from it.
  case saved(Date)
  /// The read failed and there was nothing kept.
  case failed
  /// The course has never been on this phone and there is no signal to get it.
  case neverKept

  public var isSaved: Bool { if case .saved = self { return true }; return false }
}

public struct CourseAnswer: Sendable, Equatable {
  public let book: CourseBook?
  public let source: CourseSource
  public init(book: CourseBook?, source: CourseSource) { self.book = book; self.source = source }

  /// The line that must appear beside anything drawn from this answer. Empty
  /// for a live read — a live read needs no caveat and must not wear one.
  public func line(now: Date = Date(), calendar: Calendar = .current) -> String {
    switch source {
    case .live: return ""
    case .saved: return book.map { CourseBookCopy.offlineBanner($0, now: now, calendar: calendar) } ?? ""
    case .failed: return CourseBookCopy.readFailed
    case .neverKept: return CourseBookCopy.neverKept
    }
  }
}

/// What a course search came back with, and whether the network was in it.
public struct CourseSearchAnswer: Sendable, Equatable {
  public let hits: [CourseHit]
  /// true when NOTHING on the network answered and these rows are the phone's
  /// own. `hits` may still be empty — an empty offline answer means this phone
  /// has never kept a course by that name, which is a different sentence from
  /// "no such course", and the note says which.
  public let offline: Bool
  public init(hits: [CourseHit], offline: Bool) { self.hits = hits; self.offline = offline }

  /// The line under the rows. Empty when the network answered — a live list
  /// must never wear an offline caveat (L-32 cuts both ways).
  public var note: String { offline ? CourseBookCopy.searchOffline : "" }
}

/// `my_course_books(p_limit)` — hand-declared until the owner's push
/// regenerates `Rpc.swift` from the contract (BUILD_PLAN §2's standing rule).
/// The argument is DEFAULTED server-side and listed as droppable here, so a
/// client that runs against a database without the function, or without the
/// argument, degrades to the store it already has rather than to an error.
public struct MyCourseBooksCall: RpcCall {
  public static let name = "my_course_books"
  public static let optionalArgs: [String] = ["p_limit"]
  public typealias Returns = JSONValue
  public var p_limit: Int?
  public init(p_limit: Int? = CourseDisk.cap) { self.p_limit = p_limit }
}

public struct CourseBookStore: Sendable {
  let svc: SupabaseService
  let disk: CourseDisk

  public init(_ svc: SupabaseService = .shared, disk: CourseDisk = .shared) {
    self.svc = svc; self.disk = disk
  }

  // MARK: - the fill

  /// The one read that fills the store. Called after a successful boot and
  /// after a round is posted or a plan is booked — the two moments the set of
  /// courses I have played or planned actually changes.
  ///
  /// Returns the number of books written, or nil when the read did not happen
  /// (no session, no function yet, no signal). nil is not zero, and the caller
  /// must not narrate it as "no courses".
  @discardableResult
  public func refresh(limit: Int = CourseDisk.cap) async -> Int? {
    guard let payload = try? await svc.call(MyCourseBooksCall(p_limit: limit)),
          let rows = payload.array else { return nil }
    let books = rows.compactMap(CourseBookStore.book(from:))
    guard !books.isEmpty else { return 0 }
    await disk.merge(books)
    return books.count
  }

  /// Write-through from an ordinary online read — a tee pick, a live setup, a
  /// plan. This is what makes the store fill itself between refreshes.
  public func keep(hit: CourseHit, tee: CourseTee?, holes: [CourseHole] = []) async {
    let existing = await disk.book(hit.id)
    var tees: [CourseBookTee] = existing?.tees ?? []
    for t in hit.tees {
      let card = (t.tee_name == tee?.tee_name && !holes.isEmpty)
        ? holes
        : (tees.first { $0.teeName == t.tee_name && $0.gender == t.gender }?.holes ?? [])
      // NW-2 · a write-through must not ERASE what a `my_course_books` fill
      // knew. `api_course_tees` carries no yardage or par total, so writing
      // nil over them threw away the only figure `defaultTee` can order by.
      let had = tees.first { $0.teeName == t.tee_name && $0.gender == t.gender }
      tees.removeAll { $0.teeName == t.tee_name && $0.gender == t.gender }
      tees.append(CourseBookTee(teeName: t.tee_name, gender: t.gender,
                                rating: t.course_rating, slope: t.slope_rating,
                                holesCount: t.number_of_holes,
                                parTotal: had?.parTotal, yards: had?.yards, holes: card))
    }
    guard !tees.isEmpty else { return }
    let club = existing?.clubName, course = existing?.courseName
    await disk.save(CourseBook(id: hit.id,
                               clubName: club ?? hit.label, courseName: course,
                               city: existing?.city, state: existing?.state,
                               tees: tees.sorted { ($0.holesCount ?? 0) > ($1.holesCount ?? 0) },
                               planned: existing?.planned ?? false,
                               played: existing?.played ?? false,
                               nextPlayOn: existing?.nextPlayOn, lastPlayedOn: existing?.lastPlayedOn,
                               savedAt: Date(), usedAt: Date()))
  }

  /// Write-through for a HOLE CARD alone — the live tee sheet and the composer
  /// both read one, and both read it after the course itself is known.
  ///
  /// It attaches the card to a book that already exists and does NOTHING when
  /// none does. That is deliberate: a book minted from a card would carry no
  /// club name, no city and no other tee, and would then sit in "the courses on
  /// your phone" as a nameless row. The course arrives properly on the next
  /// `refresh()`, which brings its card with it.
  public func keepCard(courseId: String, teeName: String?, holes: [CourseHole]) async {
    guard !holes.isEmpty, let old = await disk.book(courseId) else { return }
    guard old.tees.contains(where: { $0.teeName == teeName }) else { return }
    // A longer card always wins; so does one that carries stroke indexes over
    // one that does not, because the composer's read fetches pars alone and
    // the tee sheet's fetches SI too, and whichever ran last must not be able
    // to erase what the other knew.
    let betterSI = holes.contains { $0.si != nil }
    let tees = old.tees.map { t -> CourseBookTee in
      let gainsSI = betterSI && !t.holes.contains { $0.si != nil } && t.holes.count <= holes.count
      guard t.teeName == teeName, t.holes.count < holes.count || gainsSI else { return t }
      return CourseBookTee(teeName: t.teeName, gender: t.gender, rating: t.rating, slope: t.slope,
                           holesCount: t.holesCount, parTotal: t.parTotal, yards: t.yards, holes: holes)
    }
    guard tees != old.tees else { return }
    await disk.save(CourseBook(id: old.id, clubName: old.clubName, courseName: old.courseName,
                               city: old.city, state: old.state, tees: tees,
                               planned: old.planned, played: old.played,
                               nextPlayOn: old.nextPlayOn, lastPlayedOn: old.lastPlayedOn,
                               savedAt: Date(), usedAt: old.usedAt))
  }

  // MARK: - the reads

  /// Everything on the phone, most recently used first.
  public func kept() async -> [CourseBook] { await disk.books() }

  /// One course. Disk first — which is the whole point — and the answer always
  /// carries where it came from.
  public func book(_ id: String?) async -> CourseAnswer {
    guard let id, !id.isEmpty else { return CourseAnswer(book: nil, source: .neverKept) }
    if let b = await disk.book(id) { return CourseAnswer(book: b, source: .saved(b.savedAt)) }
    return CourseAnswer(book: nil, source: .neverKept)
  }

  /// The offline half of the course picker: the books that match, as search
  /// rows. Empty is a real answer here — it means this phone has never kept a
  /// course by that name, which is what `CourseBookCopy.searchOffline` says.
  public func search(_ q: String, limit: Int = 12) async -> [CourseBook] {
    await disk.search(q, limit: limit)
  }

  /// ONE course search, for all three pickers (the composer, the tee sheet and
  /// the live setup). D249's rule applied to a behaviour rather than a string:
  /// three copies of "book, then cache, then the API" is three chances for one
  /// of them to stop falling back.
  public func searchCourses(_ q: String) async -> CourseSearchAnswer {
    let sched = ScheduleService(svc)
    let saved = await search(q).map(\.hit)
    let cached = await sched.searchCacheResult(q)          // nil = the read FAILED
    let onPhone = ScheduleService.merge(local: saved, remote: cached ?? [])
    do {
      let remote = try await sched.searchRemote(q)
      return CourseSearchAnswer(hits: ScheduleService.merge(local: onPhone, remote: remote), offline: false)
    } catch {
      // The API is down or there is no signal. If our own cache answered, the
      // network is alive and this is just an upstream miss; if it did not, the
      // rows below are the phone's own and the golfer is told so.
      return CourseSearchAnswer(hits: onPhone, offline: cached == nil)
    }
  }

  /// `(par, stroke index)` per hole for a picked tee, from the phone. This is
  /// the read the live tee sheet needs to score at all with no signal.
  ///
  /// NW-3 · STRICT. A tee name that does not resolve returns nil and the typed
  /// path stands; it never substitutes another tee's card. `rating` is passed
  /// through so two tees sharing a name can be told apart.
  public func card(courseId: String?, teeName: String?, rating: Double? = nil, want: Int) async -> [(par: Int, handicap: Int)]? {
    guard let id = courseId, let b = await disk.book(id) else { return nil }
    return b.tee(named: teeName, holes: want, rating: rating)?.card(want: want)
  }

  /// The pars alone — the composer's `teePars`, from the phone.
  public func pars(courseId: String?, teeName: String?, rating: Double?) async -> (pars: [Int], nine: Bool)? {
    guard let id = courseId, let b = await disk.book(id) else { return nil }
    // NW-3 · strict on the NAME, narrowed by the rating. No `?? defaultTee`.
    guard let tee = b.tee(named: teeName, rating: rating) else { return nil }
    let want = (tee.holesCount ?? 18) == 9 ? 9 : 18
    guard let pars = tee.pars(want: want) else { return nil }
    return (pars, want == 9)
  }

  public func forget() async { await disk.clear() }

  /// Whose books these are. See `claim(_:)`.
  static let ownerKey = "cs_course_books_owner"

  /// OE-2 · **THE BOOKS ARE FORGOTTEN WHEN A DIFFERENT GOLFER ARRIVES, NOT
  /// WHEN ONE LEAVES.**
  ///
  /// D261 deletes the store on sign-out, because a shared phone must not hand
  /// one golfer's schedule and rounds to whoever signs in next. That reason is
  /// sound; the TRIGGER was not. `Boot stalled` offers `Sign out` as one of two
  /// buttons, supabase-swift removes the local session BEFORE its network call,
  /// and the store is deleted locally either way — so a mis-tap on a dead
  /// screen, on a plane, signed the golfer out AND destroyed the forty
  /// kilobytes of course books that were the only thing the app could still
  /// show them, with an emailed code the only way back in.
  ///
  /// The event D261 actually cares about is a DIFFERENT golfer holding the
  /// phone, and that event is a sign-IN. Until one happens the books stay put,
  /// unreachable by anyone without a session (every door onto them sits behind
  /// one), and the same golfer signing back in keeps everything.
  public func claim(_ profileId: UUID?) async {
    guard let id = profileId?.uuidString else { return }
    let d = UserDefaults.standard
    let was = d.string(forKey: CourseBookStore.ownerKey)
    if let was, was != id { await forget() }
    if was != id { d.set(id, forKey: CourseBookStore.ownerKey) }
  }

  // MARK: - decoding

  /// One `my_course_books` row → a book. Every field is optional on the way in
  /// (the payload is a jsonb object and the owner deploys the two halves
  /// separately); a row with no id is dropped rather than defaulted.
  static func book(from v: JSONValue) -> CourseBook? {
    guard let id = v["id"]?.string, !id.isEmpty else { return nil }
    let tees: [CourseBookTee] = (v["tees"]?.array ?? []).compactMap { t in
      let holes: [CourseHole] = (t["holes"]?.array ?? []).compactMap { h in
        guard let n = h["hole"]?.int else { return nil }
        return CourseHole(hole: n, par: h["par"]?.int, si: h["si"]?.int)
      }
      return CourseBookTee(teeName: t["tee_name"]?.string, gender: t["gender"]?.string,
                           rating: t["course_rating"]?.double, slope: t["slope_rating"]?.int,
                           holesCount: t["number_of_holes"]?.int, parTotal: t["par_total"]?.int,
                           yards: t["total_yards"]?.int, holes: holes.sorted { $0.hole < $1.hole })
    }
    return CourseBook(id: id,
                      clubName: v["club_name"]?.string, courseName: v["course_name"]?.string,
                      city: v["city"]?.string, state: v["state"]?.string,
                      tees: tees,
                      planned: v["planned"]?.bool ?? false,
                      played: v["played"]?.bool ?? false,
                      nextPlayOn: v["next_play_on"]?.string,
                      lastPlayedOn: v["last_played_on"]?.string)
  }
}
