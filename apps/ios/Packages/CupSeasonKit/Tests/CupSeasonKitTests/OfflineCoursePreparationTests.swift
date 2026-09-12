import Foundation
import Testing
@testable import CupSeasonKit

@Suite struct OfflineCoursePreparationTests {
  func tee(holes: [CourseHole], count: Int = 18, rating: Double? = 71.2) -> CourseBookTee {
    .init(teeName: "Blue", gender: "male", rating: rating, slope: 128, holesCount: count, parTotal: nil, yards: nil, holes: holes)
  }
  var card: [CourseHole] { (1...18).map { .init(hole: $0, par: 4, si: nil) } }
  @Test func readinessRequiresRealCompleteNumberedHoles() {
    #expect(tee(holes: card).offlineReady)
    #expect(tee(holes: Array(card.prefix(9)), count: 9).offlineStatus == "Ready offline · 9 holes")
    #expect(!tee(holes: Array(card.prefix(9))).offlineReady)
    #expect(!tee(holes: card, rating: nil).offlineReady)
    #expect(!tee(holes: card, rating: .nan).offlineReady)
    var malformed = card
    malformed[17] = .init(hole: 17, par: 4, si: nil)
    #expect(!tee(holes: malformed).offlineReady)
    malformed[17] = .init(hole: 18, par: nil, si: nil)
    #expect(!tee(holes: malformed).offlineReady)
    malformed[17] = .init(hole: 18, par: 0, si: nil)
    #expect(!tee(holes: malformed).offlineReady)
  }
  @Test func explicitSaveSurvivesReopenAndReportsStorageFailure() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let disk = CourseDisk(directory: dir)
    let book = CourseBook(id: "offline-test", clubName: "QA course", courseName: nil, city: nil, state: nil, tees: [tee(holes: card)])
    _ = try await disk.saveVerified(book)
    let reopened = await CourseDisk(directory: dir).book(book.id)
    #expect(reopened?.tees.first?.offlineReady == true)
    try FileManager.default.removeItem(at: dir)
    try Data("file instead of directory".utf8).write(to: dir)
    do { _ = try await disk.saveVerified(book); Issue.record("Storage failure must throw") }
    catch { }
  }
}
