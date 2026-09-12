import XCTest

final class HomeNoPhotoTests: XCTestCase {
  @MainActor func testReactRevealsChoicesAndKeepsOnlyTheGivenReaction() {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_no_photo", "-cs_dev_text_size", "large", "-cs_dev_look", "none"]
    app.launch()
    let react = app.buttons["React to this round"].firstMatch
    XCTAssertTrue(react.waitForExistence(timeout: 20))
    XCTAssertFalse(app.descendants(matching: .any)["flowers"].exists)
    react.tap()
    let flowers = app.descendants(matching: .any)["flowers"]
    XCTAssertTrue(flowers.waitForExistence(timeout: 5))
    let reveal = XCTAttachment(screenshot: app.screenshot())
    reveal.name = "Home reaction choices"; reveal.lifetime = .keepAlways; add(reveal)
    flowers.tap()
    XCTAssertTrue(app.descendants(matching: .any)["flowers, 1, yours"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.descendants(matching: .any)["cheers"].exists)
    XCTAssertTrue(app.buttons["More reactions"].exists)
    app.descendants(matching: .any)["flowers, 1, yours"].tap()
    XCTAssertFalse(app.descendants(matching: .any)["flowers, 1, yours"].exists)
    XCTAssertTrue(app.buttons["React to this round"].firstMatch.exists)
  }

  @MainActor func testRecordAndGolferHaveSeparateWorkingDoors() {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_no_photo", "-cs_dev_text_size", "large", "-cs_dev_look", "none"]
    app.launch()
    let record = app.buttons.matching(identifier: "home.round.no-photo").firstMatch
    XCTAssertTrue(record.waitForExistence(timeout: 20))
    XCTAssertTrue(record.isHittable)
    record.tap()
    XCTAssertTrue(app.staticTexts["Round · Oak Quarry"].waitForExistence(timeout: 5))
    app.terminate()
    app.launch()
    let golfer = app.buttons["You"]
    XCTAssertTrue(golfer.waitForExistence(timeout: 20))
    golfer.tap()
    XCTAssertTrue(app.staticTexts["Golfer · You"].waitForExistence(timeout: 5))
  }
}
