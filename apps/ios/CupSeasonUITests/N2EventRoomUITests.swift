import XCTest

final class N2EventRoomUITests: N2UITestCase {
  // MARK: S8 · the room that is not open

  @MainActor func testS8AnUnavailableRoomOffersTheWayBackNotARetry() {
    let app = launch("event-live", "event-missing")
    _ = root(app, "event")
    let unavailable = app.descendants(matching: .any)["event.unavailable"]
    XCTAssertTrue(unavailable.waitForExistence(timeout: 15))
    XCTAssertTrue(app.staticTexts["This room isn\u{2019}t open to you"].exists, "the head says it in words")
    XCTAssertTrue(app.staticTexts["It may have been removed, or you\u{2019}re not on its roster."].exists)
    XCTAssertFalse(app.buttons["Try again"].exists, "nothing a retry could change")
    XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'JSON'")).firstMatch.exists, "no raw server message")
    let back = app.buttons["Back to Compete"]
    XCTAssertTrue(back.exists && back.isHittable)
    XCTAssertGreaterThanOrEqual(back.frame.height, 44)
    attach(app, "s8-event-missing")
    back.tap()
    XCTAssertTrue(app.descendants(matching: .any)["cs.screen.compete"].waitForExistence(timeout: 10), "back lands on Compete")
  }
}
