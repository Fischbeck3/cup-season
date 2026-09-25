import XCTest

final class LiveIslandUITests: XCTestCase {
  @MainActor func testMissedHoleFlowOnProductionControls() throws {
    let app = XCUIApplication(); app.launchArguments = ["-cs_dev_island"]
    app.launch()
    XCTAssertTrue(app.scrollViews["islandReview"].waitForExistence(timeout: 15))
    app.buttons["Previous · 2"].tap()
    app.buttons["Increase your score for hole 2"].tap()
    XCTAssertTrue(app.staticTexts["Hole 2 · 4"].waitForExistence(timeout: 5))
    app.buttons["Increase your score for hole 2"].tap()
    XCTAssertTrue(app.staticTexts["Hole 2 · 5"].waitForExistence(timeout: 5))
    app.buttons["Next · 3"].tap()
    XCTAssertTrue(app.buttons["Increase your score for hole 3"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Hole 2 · 5"].exists)
    XCTAssertLessThanOrEqual(app.otherElements["islandControls"].frame.height, 160)
    let a = XCTAttachment(screenshot: app.screenshot()); a.name = "match-first-caught-up"; a.lifetime = .keepAlways; add(a)
  }
  @MainActor func testMatchStatesAndLargeText() throws {
    let variants = ["missed", "square", "down", "closed", "nine", "solo", "stale"].map { ($0, false) }
      + ["long", "square", "closed", "nine"].map { ($0, true) }
    for (state, large) in variants {
      let app = XCUIApplication()
      app.launchArguments = ["-cs_dev_island", "-cs_island_state", state]
      if large { app.launchArguments += ["-cs_dev_text_size", "AX3"] }
      app.launch()
      XCTAssertTrue(app.scrollViews["islandReview"].waitForExistence(timeout: 15))
      let controls = app.otherElements["islandControls"]
      XCTAssertTrue(controls.waitForExistence(timeout: 5))
      XCTAssertLessThanOrEqual(controls.frame.height, 160)
      if state == "stale" { XCTAssertTrue(app.buttons["Open to refresh"].exists) }
      let a = XCTAttachment(screenshot: app.screenshot()); a.name = "match-first-\(state)\(large ? "-AX3" : "")"; a.lifetime = .keepAlways; add(a)
      app.terminate()
    }
  }
}
