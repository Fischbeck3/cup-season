import XCTest

final class DesignV1NavigationTests: XCTestCase {
  func testBoardPreviewStillOpensTheFullSeason() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_open", "compete", "-cs_dev_appearance", "light"]
    app.launch()
    let door = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "view full board")).firstMatch
    guard door.waitForExistence(timeout: 30) else {
      throw XCTSkip("Requires a signed-in simulator with an existing season.")
    }
    for _ in 0..<6 where !door.isHittable { app.swipeUp() }
    XCTAssertTrue(door.isHittable)
    door.tap()
    let table = app.staticTexts.matching(NSPredicate(
      format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@", "the table", "the squads")).firstMatch
    XCTAssertTrue(table.waitForExistence(timeout: 30), "The preview must retain the complete season/receipt destination.")
    XCUIDevice.shared.press(.home)
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    XCTAssertTrue(springboard.icons.firstMatch.waitForExistence(timeout: 10))
    let icon = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    icon.name = "DesignV1-app-icon"
    icon.lifetime = .keepAlways
    add(icon)
  }
}
