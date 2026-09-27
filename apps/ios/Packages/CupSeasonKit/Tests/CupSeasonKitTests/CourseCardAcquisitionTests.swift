import Foundation
import Testing
@testable import CupSeasonKit

@Suite struct CourseCardAcquisitionTests {
  private func book(holes: [CourseHole] = []) -> CourseBook {
    CourseBook(id: "course", clubName: "Home club", courseName: "North", city: "Mesa", state: "AZ",
      tees: [.init(teeName: "Blue", gender: "male", rating: 71, slope: 128, holesCount: 18,
                   parTotal: 72, yards: 6400, holes: holes)])
  }
  private var hit: CourseHit { .init(id: "course", label: "Home club", place: "Mesa, AZ", tees: []) }

  private func live(_ network: CourseCardNetwork, disk: CourseDisk, tee: String = "Blue", rating: Double = 71, want: Int = 18) async -> [(par: Int, handicap: Int)]? {
    await CourseBookStore.courseHoles(courseId: "course", teeName: tee, rating: rating, want: want, disk: disk,
      readTees: { try await network.liveTees($0) }, readHoles: { try await network.liveHoles($0) })
  }
  private func post(_ network: CourseCardNetwork, disk: CourseDisk, tee: String = "Blue", rating: Double = 71) async -> (pars: [Int], nine: Bool)? {
    await CourseBookStore.teePars(courseId: "course", teeName: tee, rating: rating, disk: disk,
      readTees: { try await network.postTees($0) }, readHoles: { try await network.postHoles($0) })
  }
  private func prepare(_ network: CourseCardNetwork, disk: CourseDisk) async -> CourseBook? {
    await CourseBookStore.prepare(hit, disk: disk, cacheCourse: { await network.cache($0) },
      readTees: { try await network.preparedTees($0) })
  }

  @Test(arguments: [true, false]) func onlineReadsSurviveOfflineReopenWithoutLosingStrokeIndexes(liveFirst: Bool) async throws {
    let files = CourseCardFiles(); defer { files.remove() }
    _ = try await files.disk.saveVerified(book())
    let network = CourseCardNetwork()
    if liveFirst {
      _ = await live(network, disk: files.disk)
      _ = await post(network, disk: files.disk)
    } else {
      _ = await post(network, disk: files.disk)
      _ = await live(network, disk: files.disk)
    }
    await network.goOffline()
    let reopened = CourseDisk(directory: files.directory)
    let card = try #require(await live(network, disk: reopened))
    let pars = try #require(await post(network, disk: reopened))
    #expect(card.map(\.par) == Array(repeating: 4, count: 18))
    #expect(card.map(\.handicap) == Array(1...18))
    #expect(pars.pars == card.map(\.par))
    #expect(!pars.nine)
    let kept = try #require(await reopened.book("course"))
    #expect(kept.clubName == "Home club")
    #expect(kept.tees.first?.yards == 6400)
    #expect(kept.tees.first?.rating == 71)
  }

  @Test func sameNameTeesRetainDistinctLiveAndComposerSelection() async throws {
    let files = CourseCardFiles(); defer { files.remove() }
    let network = CourseCardNetwork(duplicates: true)
    let card = try #require(await live(network, disk: files.disk, rating: 72, want: 18))
    let pars = try #require(await post(network, disk: files.disk, rating: 72))
    #expect(card.count == 18)
    #expect(card.first?.par == 4)
    #expect(pars.pars.count == 9)
    #expect(pars.pars.first == 5)
    #expect(pars.nine)
    #expect(await network.selected == [CourseCardNetwork.eighteen.uuidString, CourseCardNetwork.nine.uuidString])
    // A card alone still must not create a nameless saved course.
    #expect(await files.disk.book("course") == nil)
  }

  @Test func unmatchedNamesKeepTheExistingOnlineFallbackAndStrictOfflineRead() async throws {
    let files = CourseCardFiles(); defer { files.remove() }
    let network = CourseCardNetwork(duplicates: true)
    #expect(await live(network, disk: files.disk, tee: "Missing") == nil)
    let online = try #require(await post(network, disk: files.disk, tee: "Missing"))
    #expect(online.nine)
    _ = try await files.disk.saveVerified(book(holes: (1...18).map { .init(hole: $0, par: 4, si: $0) }))
    await network.goOffline()
    #expect(await post(network, disk: files.disk, tee: "Missing") == nil)
    #expect(await live(network, disk: files.disk, tee: "Missing") == nil)
  }

  @Test func missingNetworkParsFallBackForLiveAndRetainComposerCompatibility() async throws {
    let files = CourseCardFiles(); defer { files.remove() }
    _ = try await files.disk.saveVerified(book(holes: (1...18).map { .init(hole: $0, par: 5, si: $0) }))
    let network = CourseCardNetwork(missingPar: true)
    let card = try #require(await live(network, disk: files.disk))
    let pars = try #require(await post(network, disk: files.disk))
    #expect(card.first?.par == 5)
    #expect(pars.pars.first == 4)
    // A same-length pars-only read cannot replace the richer stored card.
    await network.goOffline()
    let offline = try #require(await post(network, disk: files.disk))
    #expect(offline.pars.first == 5)
  }

  @Test func preparationKeepsEveryTeeAndFailureDoesNotEraseTheSavedBook() async throws {
    let files = CourseCardFiles(); defer { files.remove() }
    let network = CourseCardNetwork(duplicates: true)
    let prepared = try #require(await prepare(network, disk: files.disk))
    #expect(prepared.tees.count == 2)
    #expect(prepared.tees.allSatisfy { $0.offlineReady })
    #expect(await network.preparationCalls == ["cache:course", "read:course"])
    let reopened = CourseDisk(directory: files.directory)
    let eighteen = try #require(await CourseBookStore.card(courseId: "course", teeName: "Blue", rating: 71, want: 18, disk: reopened))
    let nine = try #require(await CourseBookStore.pars(courseId: "course", teeName: "Blue", rating: 72, disk: reopened))
    #expect(eighteen.count == 18)
    #expect(nine.nine && nine.pars.count == 9)
    await network.goOffline()
    #expect(await prepare(network, disk: reopened) == nil)
    let retained = try #require(await CourseDisk(directory: files.directory).book("course"))
    #expect(retained.tees == prepared.tees)
  }

  @Test func preparationReportsFailedVerifiedWrite() async throws {
    let files = CourseCardFiles(); defer { files.remove() }
    // The requested destination has become a file, so it cannot keep a book.
    try? FileManager.default.removeItem(at: files.directory)
    try Data("not a directory".utf8).write(to: files.directory)
    #expect(await prepare(CourseCardNetwork(), disk: files.disk) == nil)
  }
}

private struct CourseCardFiles {
  let directory: URL
  let disk: CourseDisk
  init() {
    directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    disk = CourseDisk(directory: directory)
  }
  func remove() { try? FileManager.default.removeItem(at: directory) }
}

private actor CourseCardNetwork {
  enum Failure: Error { case offline }
  static let eighteen = UUID(uuidString: "00000000-0000-4000-8000-000000000018")!
  static let nine = UUID(uuidString: "00000000-0000-4000-8000-000000000009")!
  let duplicates: Bool
  let missingPar: Bool
  var offline = false
  var selected: [String] = []
  var preparationCalls: [String] = []
  init(duplicates: Bool = false, missingPar: Bool = false) { self.duplicates = duplicates; self.missingPar = missingPar }
  func goOffline() { offline = true }
  func liveTees(_ id: String) throws -> [CourseBookStore.LiveTee] {
    if offline { throw Failure.offline }
    let tees: [CourseBookStore.LiveTee] = [
      .init(id: Self.nine.uuidString, tee_name: "Blue", number_of_holes: 9),
      .init(id: Self.eighteen.uuidString, tee_name: "Blue", number_of_holes: 18)
    ]
    return duplicates ? tees : [tees[1]]
  }
  func liveHoles(_ id: String) throws -> [CourseBookStore.LiveHole] {
    if offline { throw Failure.offline }; selected.append(id)
    return (1...(id == Self.nine.uuidString ? 9 : 18)).map {
      .init(hole_number: $0, par: missingPar && $0 == 1 ? nil : (id == Self.nine.uuidString ? 5 : 4), handicap: $0)
    }
  }
  func postTees(_ id: String) throws -> [CourseBookStore.PostTee] {
    try liveTees(id).map { .init(id: UUID(uuidString: $0.id)!, tee_name: $0.tee_name,
                                number_of_holes: $0.number_of_holes, course_rating: $0.number_of_holes == 9 ? 72 : 71) }
  }
  func postHoles(_ id: UUID) throws -> [CourseBookStore.PostHole] {
    try liveHoles(id.uuidString).map { .init(hole_number: $0.hole_number!, par: $0.par) }
  }
  func cache(_ id: String) { preparationCalls.append("cache:" + id) }
  func preparedTees(_ id: String) throws -> [CourseBookStore.PreparedTee] {
    preparationCalls.append("read:" + id)
    return try postTees(id).map { tee in
      .init(tee_name: tee.tee_name, gender: "male", course_rating: tee.course_rating, slope_rating: 128,
        number_of_holes: tee.number_of_holes, api_course_holes: try liveHoles(tee.id.uuidString).reversed().map {
          .init(hole_number: $0.hole_number!, par: $0.par, handicap: $0.handicap)
        })
    }
  }
}
