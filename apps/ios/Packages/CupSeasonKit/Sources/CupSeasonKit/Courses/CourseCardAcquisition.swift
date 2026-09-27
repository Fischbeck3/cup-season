import Foundation

extension CourseBookStore {
  /// Live scoring needs pars and stroke indexes; a failed network read uses
  /// the saved card. Tee selection retains the live round's existing rules.
  public func courseHoles(courseId: String, teeName: String?, rating: Double? = nil, want: Int) async -> [(par: Int, handicap: Int)]? {
    await Self.courseHoles(courseId: courseId, teeName: teeName, rating: rating, want: want, disk: disk,
      readTees: { id in
        try await svc.client.from("api_course_tees").select("id, tee_name, number_of_holes")
          .eq("course_id", value: id).execute().value
      }, readHoles: { id in
        try await svc.client.from("api_course_holes").select("hole_number, par, handicap")
          .eq("tee_id", value: id).order("hole_number", ascending: true).execute().value
      })
  }

  /// The composer's pars, with its existing name/rating fallback. Keep this
  /// separate from live scoring: they do not currently select tees alike.
  public func teePars(courseId: String, teeName: String?, rating: Double?) async -> (pars: [Int], nine: Bool)? {
    await Self.teePars(courseId: courseId, teeName: teeName, rating: rating, disk: disk,
      readTees: { id in
        try await svc.client.from("api_course_tees").select("id, tee_name, number_of_holes, course_rating")
          .eq("course_id", value: id).execute().value
      }, readHoles: { id in
        try await svc.client.from("api_course_holes").select("hole_number, par")
          .eq("tee_id", value: id).order("hole_number", ascending: true).execute().value
      })
  }

  // Typed transport seams keep these operations testable against a real disk
  // without starting Supabase auth. Decoding requirements match each caller.
  struct LiveTee: Decodable, Sendable { let id: String; let tee_name: String?; let number_of_holes: Int? }
  struct LiveHole: Decodable, Sendable { let hole_number: Int?; let par: Int?; let handicap: Int? }
  struct PostTee: Decodable, Sendable { let id: UUID; let tee_name: String?; let number_of_holes: Int?; let course_rating: Double? }
  struct PostHole: Decodable, Sendable { let hole_number: Int; let par: Int? }
  struct PreparedHole: Decodable, Sendable { let hole_number: Int; let par: Int?; let handicap: Int? }
  struct PreparedTee: Decodable, Sendable {
    let tee_name: String?; let gender: String?; let course_rating: Double?; let slope_rating: Int?
    let number_of_holes: Int?; let api_course_holes: [PreparedHole]?
  }

  static func courseHoles(courseId: String, teeName: String?, rating: Double? = nil, want: Int, disk: CourseDisk,
                          readTees: @Sendable (String) async throws -> [LiveTee],
                          readHoles: @Sendable (String) async throws -> [LiveHole]) async -> [(par: Int, handicap: Int)]? {
    if let tees = try? await readTees(courseId),
       let tee = tees.first(where: { $0.tee_name == teeName && $0.number_of_holes == want })
         ?? tees.first(where: { $0.tee_name == teeName }),
       let holes = try? await readHoles(tee.id), !holes.isEmpty,
       holes.allSatisfy({ $0.par.map { (3...6).contains($0) } ?? false }) {
      let card = holes.map { (par: $0.par!, handicap: $0.handicap ?? 0) }
      await keepCard(courseId: courseId, teeName: teeName,
        holes: card.enumerated().map { CourseHole(hole: $0.offset + 1, par: $0.element.par, si: $0.element.handicap) }, disk: disk)
      return card
    }
    return await card(courseId: courseId, teeName: teeName, rating: rating, want: want, disk: disk)
  }

  static func teePars(courseId: String, teeName: String?, rating: Double?, disk: CourseDisk,
                      readTees: @Sendable (String) async throws -> [PostTee],
                      readHoles: @Sendable (UUID) async throws -> [PostHole]) async -> (pars: [Int], nine: Bool)? {
    if let tees = try? await readTees(courseId), !tees.isEmpty {
      let tee = tees.first { $0.tee_name == teeName && $0.course_rating == rating }
        ?? tees.first { $0.tee_name == teeName } ?? tees[0]
      if let holes = try? await readHoles(tee.id), !holes.isEmpty {
        let pars = holes.map { $0.par ?? 4 }
        await keepCard(courseId: courseId, teeName: teeName,
          holes: pars.enumerated().map { CourseHole(hole: $0.offset + 1, par: $0.element, si: nil) }, disk: disk)
        return (pars, tee.number_of_holes == 9)
      }
    }
    return await pars(courseId: courseId, teeName: teeName, rating: rating, disk: disk)
  }

  static func prepare(_ hit: CourseHit, disk: CourseDisk, cacheCourse: @Sendable (String) async -> Void,
                      readTees: @Sendable (String) async throws -> [PreparedTee]) async -> CourseBook? {
    await cacheCourse(hit.id)
    guard let rows = try? await readTees(hit.id), !rows.isEmpty else { return nil }
    let old = await disk.book(hit.id)
    let tees = rows.compactMap { row -> CourseBookTee? in
      guard row.course_rating != nil, row.slope_rating != nil else { return nil }
      let prior = old?.tees.first { $0.teeName == row.tee_name && $0.gender == row.gender }
      let holes = (row.api_course_holes ?? []).sorted { $0.hole_number < $1.hole_number }
        .map { CourseHole(hole: $0.hole_number, par: $0.par, si: $0.handicap) }
      return CourseBookTee(teeName: row.tee_name, gender: row.gender, rating: row.course_rating,
                           slope: row.slope_rating, holesCount: row.number_of_holes,
                           parTotal: prior?.parTotal, yards: prior?.yards, holes: holes.isEmpty ? prior?.holes ?? [] : holes)
    }
    guard !tees.isEmpty else { return nil }
    let book = CourseBook(id: hit.id, clubName: old?.clubName ?? hit.label, courseName: old?.courseName,
                           city: old?.city, state: old?.state, tees: tees,
                           planned: old?.planned ?? false, played: old?.played ?? false,
                           nextPlayOn: old?.nextPlayOn, lastPlayedOn: old?.lastPlayedOn)
    return try? await disk.saveVerified(book)
  }
}
