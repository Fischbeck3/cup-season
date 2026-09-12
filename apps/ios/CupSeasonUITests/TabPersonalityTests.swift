import XCTest

final class TabPersonalityTests: XCTestCase {
  func testGolferRowOpensPlayerCard() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_open", "golfers", "-cs_dev_look", "none"]
    app.launch()
    let row = app.buttons.matching(identifier: "golfer.directory.row").firstMatch
    guard row.waitForExistence(timeout: 30) else { throw XCTSkip("Requires the signed-in review account with buddies") }
    XCTAssertTrue(row.isHittable)
    row.tap()
    XCTAssertTrue(app.staticTexts.element(matching: NSPredicate(format: "label BEGINSWITH %@", "@")).waitForExistence(timeout: 15))
  }

  func testCompeteCreationStillOpensIntent() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_open", "compete", "-cs_dev_look", "none"]
    app.launch()
    let button = app.buttons.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "Start something"))
    guard button.waitForExistence(timeout: 30) else { throw XCTSkip("Requires signed-in Compete") }
    for _ in 0..<5 where !button.isHittable { app.swipeUp() }
    XCTAssertTrue(button.isHittable)
    button.tap()
    XCTAssertTrue(app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "what do you want to do")).waitForExistence(timeout: 10))
  }
}

final class WelcomeDoorTests: XCTestCase {
  func testBothDoorsReachExistingEmailFlow() throws {
    for label in ["Get started", "Sign in"] {
      let app = XCUIApplication()
      app.launchArguments = ["-cs_dev_look", "none", "-cs_dev_text_size", "large"]
      app.launch()
      let door = app.buttons.element(matching: NSPredicate(format: "label =[c] %@", label))
      guard door.waitForExistence(timeout: 15) else { throw XCTSkip("Requires signed-out simulator") }
      XCTAssertTrue(door.isHittable)
      door.tap()
      XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 10))
      XCTAssertTrue(app.buttons.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "Continue with email")).exists)
      app.terminate()
    }
  }
}
