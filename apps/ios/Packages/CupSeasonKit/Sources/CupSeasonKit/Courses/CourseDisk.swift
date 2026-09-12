// Cup Season — where the course books live on the phone (D261, IOS-041, R-N).
//
// THE EXISTING PATTERN, NOT A THIRD ONE. R-N is explicit: follow `LiveDisk`
// (`Live/LiveDisk.swift`) rather than inventing another on-disk shape. So this
// is the same thing: an actor, JSON files in Application Support, atomic
// writes, every read tolerant of a file that is missing or corrupt. The only
// addition `LiveDisk` does not need is a CAP with LEAST-RECENTLY-USED
// eviction, because a live round is one object and a course book is a growing
// collection.
//
// Why files rather than the App Group defaults `DispatchSnapshot` uses: the
// widget has no business reading a hole card, a book is orders of magnitude
// bigger than eight words, and `UserDefaults` is the wrong store for a
// collection you evict from. Same house, right room.
//
// The cap is 40 courses. A book with an 18-hole card runs about 3–4 KB, so the
// whole store is well under a quarter of a megabyte — the size R-N assumed
// when it said "a course is a few kilobytes".

import Foundation

public actor CourseDisk {
  public static let shared = CourseDisk()

  /// R-N: "the store is capped and evicts least-recently-used".
  public static let cap = 40

  let dir: URL
  private let enc = JSONEncoder()
  private let dec = JSONDecoder()

  public init(directory: URL? = nil) {
    if let directory { dir = directory }
    else {
      let base = (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
        ?? FileManager.default.temporaryDirectory
      dir = base.appendingPathComponent("CupSeason/courses", isDirectory: true)
    }
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    enc.dateEncodingStrategy = .iso8601
    dec.dateDecodingStrategy = .iso8601
  }

  /// A course id is GolfCourseAPI's text id and reaches us from the network —
  /// so it is never spliced into a path raw. Anything but an unreserved
  /// character becomes `-`, which cannot climb out of the directory.
  static func fileName(_ id: String) -> String {
    let safe = String(id.map { ch in
      (ch.isLetter && ch.isASCII) || ch.isNumber || ch == "-" || ch == "_" ? ch : "-"
    }).prefix(64)
    return "course-\(safe).json"
  }

  func url(_ id: String) -> URL { dir.appendingPathComponent(CourseDisk.fileName(id)) }

  private var files: [URL] {
    ((try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? [])
      .filter { $0.lastPathComponent.hasPrefix("course-") }
  }

  // MARK: reads

  /// Every book on disk, most recently used first. A file that will not decode
  /// is skipped, never thrown — a corrupt book must not take the list down.
  public func books() -> [CourseBook] {
    files.compactMap { try? dec.decode(CourseBook.self, from: Data(contentsOf: $0)) }
      .sorted { $0.usedAt > $1.usedAt }
  }

  /// One book. Reading TOUCHES it, which is what makes the eviction order mean
  /// "least recently used" rather than "least recently written".
  public func book(_ id: String) -> CourseBook? {
    guard let b = try? dec.decode(CourseBook.self, from: Data(contentsOf: url(id))) else { return nil }
    write(b.touched())
    return b
  }

  /// The books whose label or place matches, most recently used first. This is
  /// the OFFLINE search, and its scope is deliberately the store: played,
  /// planned or explicitly saved courses, never the whole catalogue.
  public func search(_ q: String, limit: Int = 12) -> [CourseBook] {
    let needle = q.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard needle.count >= 2 else { return [] }
    return books()
      .filter { $0.label.lowercased().contains(needle) || $0.place.lowercased().contains(needle) }
      .prefix(limit)
      .map { $0 }
  }

  public func count() -> Int { files.count }

  // MARK: writes

  /// Write one book and evict down to the cap. The incoming book keeps its own
  /// `usedAt` when it has one (a refresh must not promote a course the golfer
  /// has not opened in months above one they opened this morning).
  public func save(_ book: CourseBook) {
    write(book)
    evict()
  }

  /// Explicit trip preparation must report disk failure, even if an older
  /// copy with identical tee data already exists.
  public func saveVerified(_ book: CourseBook) throws -> CourseBook {
    let data = try enc.encode(book)
    try data.write(to: url(book.id), options: .atomic)
    let saved = try dec.decode(CourseBook.self, from: Data(contentsOf: url(book.id)))
    guard saved.tees == book.tees, saved.id == book.id else {
      throw CocoaError(.fileReadCorruptFile)
    }
    evict()
    return saved
  }

  /// A whole refresh, in one pass — the `my_course_books` read.
  ///
  /// It MERGES rather than replaces: a book already on disk keeps its `usedAt`
  /// so eviction order survives the refresh, and a tee list that came back
  /// EMPTY (the course rows exist but the tee cache has not been filled) never
  /// overwrites a good card with nothing. That last rule is the L-44 one: a
  /// thinner read is not permission to forget what we know.
  public func merge(_ books: [CourseBook]) {
    for incoming in books {
      var b = incoming
      if let old = try? dec.decode(CourseBook.self, from: Data(contentsOf: url(incoming.id))) {
        b.usedAt = max(old.usedAt, incoming.usedAt)
        if incoming.tees.isEmpty && !old.tees.isEmpty {
          b = CourseBook(id: old.id, clubName: incoming.clubName ?? old.clubName,
                         courseName: incoming.courseName ?? old.courseName,
                         city: incoming.city ?? old.city, state: incoming.state ?? old.state,
                         tees: old.tees, planned: incoming.planned, played: incoming.played,
                         nextPlayOn: incoming.nextPlayOn, lastPlayedOn: incoming.lastPlayedOn,
                         savedAt: old.savedAt, usedAt: b.usedAt)
        }
      }
      write(b)
    }
    evict()
  }

  public func remove(_ id: String) { try? FileManager.default.removeItem(at: url(id)) }

  /// Sign-out. The books are not secret, but they are one golfer's schedule and
  /// one golfer's rounds, and a shared phone should not hand them to the next
  /// person who signs in.
  public func clear() { for f in files { try? FileManager.default.removeItem(at: f) } }

  // MARK: internals

  private func write(_ b: CourseBook) {
    guard let data = try? enc.encode(b) else { return }
    try? data.write(to: url(b.id), options: .atomic)
  }

  /// Least-recently-USED, which is why `book(_:)` touches on read.
  private func evict() {
    let all = books()
    guard all.count > CourseDisk.cap else { return }
    for b in all.dropFirst(CourseDisk.cap) { remove(b.id) }
  }
}
