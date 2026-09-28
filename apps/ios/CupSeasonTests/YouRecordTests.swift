import XCTest
import CupSeasonKit
@testable import CupSeason

/// F10 · the You page knows which of four things it shows: a first load still
/// out, a failed rounds read, a record with nothing in it, or a record. A
/// failed read is never "no rounds", and the empty record says so once.
final class YouRecordTests: XCTestCase {
  private func career(_ n: Int) -> Career {
    Career(rounds: n, best: nil, avg: nil, counting: 0, played: 0, recent: [], figures: [:], points: [:])
  }

  func testTheFourStates() {
    XCTAssertEqual(YouRecord.of(loaded: false, career: nil, failed: [], cardRecent: 0), .loading)
    XCTAssertEqual(YouRecord.of(loaded: true, career: career(0), failed: [], cardRecent: 0), .empty)
    XCTAssertEqual(YouRecord.of(loaded: true, career: career(1), failed: [], cardRecent: 1), .some(1))
    XCTAssertEqual(YouRecord.of(loaded: true, career: career(23), failed: ["rivalries"], cardRecent: 5), .some(23))
  }

  func testAFailedRoundsReadIsNeverNoRounds() {
    let failed = YouRecord.of(loaded: true, career: nil, failed: ["career", "trophies"], cardRecent: 0)
    XCTAssertEqual(failed, .failed)
    XCTAssertNotEqual(failed, .empty)
    // the card's own recent rounds still prove there IS a record
    XCTAssertEqual(YouRecord.of(loaded: true, career: nil, failed: ["career"], cardRecent: 3), .some(3))
  }

  func testTheWordsSayTheReadFailedNotTheRecord() {
    XCTAssertEqual(YouCopy.roundsFailed, "Your rounds didn\u{2019}t load")
    XCTAssertTrue(YouCopy.roundsFailedLine.contains("Nothing is lost"))
    XCTAssertFalse(YouCopy.roundsFailed.lowercased().contains("no rounds"))
    XCTAssertFalse(YouCopy.roundsFailedLine.lowercased().contains("no rounds"))
  }
}
