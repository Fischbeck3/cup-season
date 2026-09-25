import XCTest

final class BetweenRoundsWidgetUITests: XCTestCase {

  func testLightAndEdgeStates() {
    let app = XCUIApplication()
    let cases: [(String, String, String)] = [
      ("CSSeasonWidget", "full", "light"), ("CSNextTeeWidget", "full", "light"),
      ("CSRecordWidget", "full", "light"), ("CSRivalryWidget", "full", "light"),
      ("CSNextTeeWidget", "confirmed", "dark"), ("CSNextTeeWidget", "error", "dark"),
      ("CSNextTeeWidget", "stale", "dark"), ("CSSeasonWidget", "empty", "light"),
      ("CSRecordWidget", "nine", "dark"), ("CSRivalryWidget", "long", "light"),
      ("CSNextTeeWidget", "long", "light"),
      ("CSSeasonWidget", "long", "dark"), ("CSRecordWidget", "long", "dark")
    ]
    for (kind, state, appearance) in cases {
      app.launchArguments = ["-cs_dev_widgets", "-cs_widget_kind", kind, "-cs_widget_state", state, "-cs_dev_appearance", appearance]
      if state == "long" { app.launchArguments += ["-cs_dev_text_size", "AX3"] }
      app.launch()
      XCTAssertTrue(app.scrollViews["widgetReview"].waitForExistence(timeout: 10))
      if state == "stale" { XCTAssertEqual(app.buttons.count, 0, "Expired tee time still has a reply") }
      if state == "error" { XCTAssertTrue(app.staticTexts["Couldn’t confirm. Open the plan."].firstMatch.exists) }
      let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "\(kind)-\(appearance)-\(state)"; shot.lifetime = .keepAlways; add(shot)
      app.terminate()
    }
  }

  func testNativeWidgetGallery() {
    let app = XCUIApplication()
    for (kind, word) in [("CSSeasonWidget", "The Race"), ("CSNextTeeWidget", "Next Tee"), ("CSRecordWidget", "The Record"), ("CSRivalryWidget", "The Rivalry")] {
      app.launchArguments = ["-cs_dev_widgets", "-cs_widget_kind", kind, "-cs_dev_appearance", "dark"]
      app.launch()
      XCTAssertTrue(app.scrollViews["widgetReview"].waitForExistence(timeout: 10))
      XCTAssertTrue(app.staticTexts[word].firstMatch.exists)
      let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = kind; shot.lifetime = .keepAlways; add(shot)
      app.terminate()
    }
  }
}
