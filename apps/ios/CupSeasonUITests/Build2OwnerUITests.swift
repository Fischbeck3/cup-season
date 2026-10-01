import XCTest

/// Build 2 owner doors, in the actual app, on an isolated synthetic phone.
final class Build2OwnerUITests: XCTestCase {
  @MainActor private func launch(_ route: String, theme: String, size: String, extra: [String] = []) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_synthetic", "season-live", "-cs_dev_open", route,
      "-cs_dev_appearance", theme, "-cs_dev_look", "none", "-cs_dev_text_size", size] + extra
    app.launch()
    return app
  }
  @MainActor private func reveal(_ target: XCUIElement, in app: XCUIApplication) {
    XCTAssertTrue(target.waitForExistence(timeout: 30))
    for _ in 0..<12 where !target.isHittable { app.swipeUp() }
    XCTAssertTrue(target.isHittable)
  }
  @MainActor private func capture(_ name: String) {
    let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    shot.name = name; shot.lifetime = .keepAlways; add(shot)
  }
  @MainActor func testCardLinkAsksThenReportsOnlyTheConfirmedRevoke() {
    for theme in ["dark", "light"] {
      for size in ["large", "accessibility3"] {
        let app = launch("settings", theme: theme, size: size)
        let control = app.buttons["cardLink.off"]
        reveal(control, in: app)
        XCTAssertEqual(control.label, "Turn off my card link")
        capture("X38-before-tap-\(theme)-\(size)")
        control.tap()
        XCTAssertEqual(control.label, "Sure? The old link stops working")
        XCTAssertGreaterThanOrEqual(control.frame.height, 43.99)
        capture("X38-armed-\(theme)-\(size)")
        control.tap()
        let status = app.staticTexts["cardLink.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 15))
        XCTAssertEqual(status.label, "Your card link is off. Sharing your card again makes a new link.")
        reveal(status, in: app)
        capture("X38-done-\(theme)-\(size)")
        app.terminate()
      }
    }
  }
  @MainActor func testTheClinchSentenceOpensItsOwnArithmetic() {
    for theme in ["dark", "light"] {
      let app = launch("season", theme: theme, size: "large", extra: ["-cs_synth_clinch"])
      let door = app.buttons["season.clinchReceipt"]
      reveal(door, in: app)
      XCTAssertEqual(door.label, "Fixture Javelinas clinch the top seed with 351 more points.")
      capture("Q50-sentence-\(theme)")
      door.tap()
      XCTAssertTrue(app.staticTexts["351 more points"].waitForExistence(timeout: 10))
      XCTAssertTrue(app.staticTexts["Fixture Wrens can still reach"].exists)
      XCTAssertTrue(app.staticTexts["521"].exists)
      XCTAssertTrue(app.staticTexts["−171"].exists)
      XCTAssertTrue(app.staticTexts["+1"].exists)
      capture("Q50-receipt-\(theme)")
      app.terminate()
    }
  }
}
