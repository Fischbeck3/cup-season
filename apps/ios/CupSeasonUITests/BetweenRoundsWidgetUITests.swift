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
    for (i, (kind, state, appearance)) in cases.enumerated() {
      app.launchArguments = ["-cs_dev_widgets", "-cs_widget_kind", kind, "-cs_widget_state", state, "-cs_dev_appearance", appearance]
      if state == "long" { app.launchArguments += ["-cs_dev_text_size", "AX3"] }
      app.launch()
      // the first launch on a freshly booted phone can take most of a minute
      XCTAssertTrue(app.scrollViews["widgetReview"].waitForExistence(timeout: i == 0 ? 60 : 10))
      if state == "stale" { XCTAssertEqual(app.buttons.count, 0, "Expired tee time still has a reply") }
      if state == "error" { XCTAssertTrue(app.staticTexts["Couldn’t confirm. Open the plan."].firstMatch.exists) }
      let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "\(kind)-\(appearance)-\(state)"; shot.lifetime = .keepAlways; add(shot)
      app.terminate()
    }
  }

  func testNativeWidgetGallery() {
    let app = XCUIApplication()
    for (i, (kind, word)) in [("CSSeasonWidget", "The Race"), ("CSNextTeeWidget", "Next Tee"), ("CSRecordWidget", "The Record"), ("CSRivalryWidget", "The Rivalry")].enumerated() {
      app.launchArguments = ["-cs_dev_widgets", "-cs_widget_kind", kind, "-cs_dev_appearance", "dark"]
      app.launch()
      XCTAssertTrue(app.scrollViews["widgetReview"].waitForExistence(timeout: i == 0 ? 60 : 10))
      XCTAssertTrue(app.staticTexts[word].firstMatch.exists)
      let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = kind; shot.lifetime = .keepAlways; add(shot)
      app.terminate()
    }
  }
  @MainActor func testWhatsOnSurvivesIntegrationInBothPrintings() {
    let app=XCUIApplication()
    for appearance in ["dark","light"] {
      app.launchArguments=["-cs_dev_widgets","-cs_widget_kind","CSWhatsOnWidget","-cs_widget_state","full","-cs_dev_appearance",appearance]
      app.terminate()
      app.launch()
      XCTAssertTrue(app.scrollViews["widgetReview"].waitForExistence(timeout:60))
      XCTAssertTrue(app.staticTexts["What’s On"].firstMatch.exists)
      XCTAssertTrue(app.staticTexts["You and Blake, two days left."].firstMatch.exists)
      let shot=XCTAttachment(screenshot:app.screenshot()); shot.name="WhatsOn-"+appearance; shot.lifetime = .keepAlways; add(shot)
      app.swipeUp()
      let lower=XCTAttachment(screenshot:app.screenshot()); lower.name="WhatsOn-families-"+appearance; lower.lifetime = .keepAlways; add(lower)
      app.terminate()
    }
  }

}
