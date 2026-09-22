import XCTest

final class LaunchSheetTests: XCTestCase {
  @MainActor func testReUpCovenantShowsSeasonAndConsent() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_launch_sheets", "-cs_dev_appearance", "dark"]
    app.launch()
    let accept = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "in for season 2")).firstMatch
    XCTAssertTrue(accept.waitForExistence(timeout: 20))
    for _ in 0..<3 where !accept.isHittable { app.swipeUp() }
    XCTAssertTrue(accept.isHittable)
    XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Last season you finished 3rd of 8 with 41 points.")).firstMatch.exists)
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "launch-reup-covenant-fixture"; shot.lifetime = .keepAlways; add(shot)
  }

  @MainActor func testRulingExplainsLedgerAndHasReachableAction() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_launch_sheets", "-cs_dev_launch_ruling", "-cs_dev_appearance", "dark"]
    app.launch()
    let record = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Record the ruling")).firstMatch
    XCTAssertTrue(record.waitForExistence(timeout: 20))
    for _ in 0..<3 where !record.isHittable { app.swipeUp() }
    XCTAssertTrue(record.isHittable)
    XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Rounds are never changed.")).firstMatch.exists)
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "launch-ruling-sheet-fixture"; shot.lifetime = .keepAlways; add(shot)
  }
}
