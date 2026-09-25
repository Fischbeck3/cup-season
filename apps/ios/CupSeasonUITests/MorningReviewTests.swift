import XCTest

final class MorningReviewTests: XCTestCase {
  @MainActor private func launch(_ scene: String, size: String = "large") -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_morning_review", "-cs_review_scene", scene,
      "-cs_dev_look", "none", "-cs_dev_appearance", "dark", "-cs_dev_text_size", size]
    app.launch()
    return app
  }

  @MainActor func testSetupKeepsTeeOffReachableBeforeAndAfterScrolling() {
    let app = launch("setup", size: "AX3")
    let teeOff = app.buttons["live.setup.teeOff"]
    XCTAssertTrue(teeOff.waitForExistence(timeout: 15))
    XCTAssertTrue(teeOff.isHittable)
    app.swipeUp()
    app.swipeUp()
    XCTAssertTrue(teeOff.isHittable)
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "setup-AX3-sticky-action"; shot.lifetime = .keepAlways; add(shot)
  }

  @MainActor func testRatingKeyboardCanBeDismissedWithoutLeavingSetup() {
    let app = launch("setup")
    let rating = app.textFields["Rating"]
    XCTAssertTrue(rating.waitForExistence(timeout: 15))
    rating.tap()
    XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
    let done = app.buttons["Close keyboard"]
    XCTAssertTrue(done.waitForExistence(timeout: 5))
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "setup-rating-keyboard"; shot.lifetime = .keepAlways; add(shot)
    done.tap()
    XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
    XCTAssertTrue(app.buttons["live.setup.teeOff"].isHittable)
  }

  @MainActor func testShareMessageCanBeReviewedBeforeSending() {
    let app = launch("share")
    let message = app.buttons["round.share.message"]
    XCTAssertTrue(message.waitForExistence(timeout: 15))
    XCTAssertGreaterThanOrEqual(message.frame.height, 44)
    message.tap()
    XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "84 at Encanto Golf Course")).firstMatch.waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["round.share.send"].isHittable)
  }

  @MainActor func testDisconnectedLiveRoundSaysItIsWaitingToSync() {
    let app = launch("offline")
    XCTAssertTrue(app.staticTexts["SAVED ON THIS PHONE · WAITING TO SYNC"].waitForExistence(timeout: 15))
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "live-disconnected"; shot.lifetime = .keepAlways; add(shot)
  }
}
