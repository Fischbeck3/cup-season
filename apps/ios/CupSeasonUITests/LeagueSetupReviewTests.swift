import XCTest

final class LeagueSetupReviewTests: XCTestCase {
  @MainActor private func reach(_ element: XCUIElement, app: XCUIApplication, attempts: Int = 30) {
    for _ in 0..<attempts {
      if element.exists && element.isHittable { return }
      app.swipeUp()
    }
    XCTAssertTrue(element.isHittable)
  }
  @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
    let image = XCTAttachment(screenshot: app.screenshot()); image.name = name
    image.lifetime = .keepAlways; add(image)
  }
  @MainActor func testSuggestionReviewEditAndSafeStart() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_wizard_fixture", "-cs_dev_look", "none", "-cs_dev_appearance", "light"]
    app.launch()
    let suggestion = app.buttons["wizard-busy-suggestion"]
    XCTAssertTrue(suggestion.waitForExistence(timeout: 25))
    let pace = app.buttons["wizard-frequency"]
    pace.tap(); app.buttons["Most weeks"].tap()
    XCTAssertFalse(suggestion.exists)
    pace.tap(); app.buttons["About once a month"].tap()
    XCTAssertTrue(suggestion.exists); suggestion.tap()
    capture(app, "setup-busy-friends-light")
    let review = app.buttons["wizard-review"]; reach(review, app: app); review.tap()
    XCTAssertTrue(app.staticTexts["wizard-agreement"].waitForExistence(timeout: 10))
    capture(app, "agreement-top-light")
    let change = app.buttons["wizard-change"]; reach(change, app: app)
    capture(app, "agreement-confirm-light"); change.tap()
    reach(review, app: app); review.tap()
    let start = app.buttons["wizard-start"]; reach(start, app: app); start.tap()
    XCTAssertTrue(app.staticTexts["Design fixture only. No season created or invitations sent."].waitForExistence(timeout: 5))
    XCTAssertTrue(start.exists)
  }
  @MainActor func testAccessibilitySizeReachesReviewAndConfirmation() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_wizard_fixture", "-cs_dev_look", "none", "-cs_dev_appearance", "dark", "-cs_dev_text_size", "AX3"]
    app.launch()
    let suggestion = app.buttons["wizard-busy-suggestion"]
    XCTAssertTrue(suggestion.waitForExistence(timeout: 25)); reach(suggestion, app: app); suggestion.tap()
    capture(app, "setup-busy-friends-AX3-dark")
    let review = app.buttons["wizard-review"]; reach(review, app: app); review.tap()
    XCTAssertTrue(app.staticTexts["wizard-agreement"].waitForExistence(timeout: 10))
    capture(app, "agreement-top-AX3-dark")
    let start = app.buttons["wizard-start"]; reach(start, app: app)
    capture(app, "agreement-confirm-AX3-dark")
    XCTAssertTrue(start.isHittable)
  }
}
