import XCTest
import CupSeasonKit
@testable import CupSeason

final class RoundSharePrivacyTests: XCTestCase {
  func testPublicRoundKeepsFactsWithoutCompetitionOrAchievementClaims() {
    let source = PostRecap(name: "QA golfer", marker: "", gross: 91, pvi: nil,
      points: 12, course: "QA course", date: "2026-09-11", badge: "PERSONAL BEST")
    let exported = source.publicRoundCard
    XCTAssertNil(exported.points)
    XCTAssertNil(exported.badge)
    XCTAssertNil(exported.bandLine)
    XCTAssertEqual(exported.gross, source.gross)
    XCTAssertEqual(exported.course, source.course)
    XCTAssertEqual(exported.date, source.date)
    XCTAssertFalse(exported.caption.contains("pts"))
    XCTAssertEqual(source.points, 12, "Export must not mutate the accepted source")
  }
}
