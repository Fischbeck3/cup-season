import XCTest
import Supabase
import CupSeasonKit
@testable import CupSeason

/// S8 · a room this golfer may not read is said as that — never as a read to
/// try again — and a refresh that fails keeps an open room on screen.
@MainActor
final class EventRoomModelTests: XCTestCase {
  private let id = UUID(uuidString: "f1c70000-0000-4000-8000-000000005999")!
  private let missing = PostgrestError(code: "PGRST116", message: "JSON object requested, multiple (or no) rows returned")

  func testAnEmptyRowIsUnavailableNotAFailedRead() async {
    XCTAssertTrue(EventsRepository.isUnavailable(missing))
    XCTAssertFalse(EventsRepository.isUnavailable(PostgrestError(code: "42501", message: "permission denied for table events")))
    XCTAssertFalse(EventsRepository.isUnavailable(URLError(.notConnectedToInternet)))
    let m = EventRoomModel(eventId: id) { _ in throw self.missing }
    await m.load()
    XCTAssertTrue(m.unavailable)
    XCTAssertNil(m.error, "an unavailable room offers no retry, so it carries no failure line")
    XCTAssertNil(m.room)
    XCTAssertTrue(m.loaded)
  }

  func testATransportFailureIsARetryableFailedRead() async {
    let m = EventRoomModel(eventId: id) { _ in throw URLError(.notConnectedToInternet) }
    await m.load()
    XCTAssertFalse(m.unavailable, "a dropped signal is a read to try again, not a closed room")
    XCTAssertNotNil(m.error)
  }

  func testAFailedRefreshKeepsTheOpenRoom() async {
    let room = EventRoom(event: EventRow(id: id, name: "Fixture Cup Ryder", created_by: nil, status: "live"))
    var attempts = 0
    let m = EventRoomModel(eventId: id) { _ in
      attempts += 1
      if attempts == 1 { return room }
      throw attempts == 2 ? URLError(.networkConnectionLost) as Error : self.missing
    }
    await m.load()
    XCTAssertEqual(m.room?.event.name, "Fixture Cup Ryder")
    await m.load()
    XCTAssertEqual(m.room?.event.name, "Fixture Cup Ryder", "a failed refresh keeps the room")
    XCTAssertNil(m.error)
    await m.load()
    XCTAssertEqual(m.room?.event.name, "Fixture Cup Ryder", "even an emptied row does not blank an open room")
    XCTAssertFalse(m.unavailable)
  }

  func testTheRoomsWordsNameARoomNeverAnEvent() {
    for line in [EventRoomCopy.failedHead, EventRoomCopy.brow, EventRoomCopy.unavailableHead,
                 EventRoomCopy.unavailableSpoken, EventRoomCopy.unavailableWhy, EventRoomCopy.back] {
      XCTAssertFalse(line.lowercased().contains("event"), line)
    }
    XCTAssertEqual(EventRoomCopy.back, "Back to Compete")
  }
}
