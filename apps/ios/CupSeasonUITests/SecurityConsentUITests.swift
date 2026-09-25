import XCTest

final class SecurityConsentUITests: XCTestCase {
  @MainActor private func launch() -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_audit_backend", "local", "-cs_dev_security", "-cs_dev_appearance", "dark", "-cs_dev_look", "none"]
    app.launch()
    XCTAssertTrue(app.buttons["open-person"].waitForExistence(timeout: 15))
    return app
  }
  @MainActor func testEveryLinkNeedsConfirmationAndNotNowDoesNothing() {
    let app = launch()
    for kind in ["person", "plan", "claim"] {
      app.buttons["open-\(kind)"].tap()
      XCTAssertTrue(app.buttons["link-confirm"].waitForExistence(timeout: 5))
      app.buttons["link-decline"].tap()
      XCTAssertTrue(app.staticTexts["security-writes"].waitForExistence(timeout: 5))
      XCTAssertEqual(app.staticTexts["security-writes"].label, "Writes: 0")
    }
    app.buttons["open-claim"].tap()
    app.buttons["link-confirm"].tap()
    XCTAssertTrue(app.staticTexts["security-writes"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["security-writes"].label, "Writes: 1")
    XCTAssertEqual(app.staticTexts["security-result"].label, "Confirmed claim")
  }
  @MainActor func testScanDeclineDoesNotUploadAndYesEnablesScan() {
    let app = launch()
    app.buttons["open-scan"].tap()
    XCTAssertTrue(app.buttons["scan-consent-decline"].waitForExistence(timeout: 5))
    app.buttons["scan-consent-decline"].tap()
    XCTAssertTrue(app.staticTexts["security-writes"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["security-writes"].label, "Writes: 0")
    app.buttons["open-scan"].tap()
    app.buttons["scan-consent-confirm"].tap()
    XCTAssertTrue(app.staticTexts["security-writes"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["security-result"].label, "Scan permitted")
    XCTAssertEqual(app.staticTexts["security-writes"].label, "Writes: 1")
  }
  @MainActor func testCommentReportAndBlockAreReachable() {
    let app = launch()
    for label in ["open-comment", "open-plan-comment"] {
      app.buttons[label].tap()
      XCTAssertTrue(app.buttons["comment-report-send"].waitForExistence(timeout: 5))
      app.buttons["comment-report-send"].tap()
      XCTAssertTrue(app.staticTexts["comment-reported"].waitForExistence(timeout: 5))
      app.buttons["comment-block"].tap()
      XCTAssertTrue(app.staticTexts["security-result"].waitForExistence(timeout: 5))
      XCTAssertEqual(app.staticTexts["security-result"].label, "Blocked Alex")
    }
    XCTAssertEqual(app.staticTexts["security-writes"].label, "Writes: 4")
  }
  @MainActor func testPendingActionsAreClearedAtTheAccountBoundary() {
    let app = launch()
    app.buttons["open-person"].tap()
    XCTAssertTrue(app.buttons["link-confirm"].waitForExistence(timeout: 5))
    let bar = app.navigationBars["A buddy link"]
    bar.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0)).press(forDuration: 0.1,
      thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95)))
    XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: app.buttons["link-confirm"])], timeout: 5) == .completed)
    app.scrollViews.firstMatch.swipeUp()
    let clear = app.buttons["clear-actions"]
    XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: clear)], timeout: 5) == .completed)
    clear.tap()
    XCTAssertEqual(app.staticTexts["security-result"].label, "Pending actions cleared")
    XCTAssertEqual(app.staticTexts["security-writes"].label, "Writes: 0")
  }
  @MainActor func testSheetsInBothPrintingsWithLongNames() {
    for theme in ["light", "dark"] {
      let app = XCUIApplication()
      app.launchArguments = ["-cs_audit_backend", "local", "-cs_dev_security", "-cs_dev_appearance", theme, "-cs_dev_look", "none", "-cs_security_long"]
      app.launch()
      XCTAssertTrue(app.buttons["open-person"].waitForExistence(timeout: 15))
      for kind in ["person", "plan", "claim"] {
        app.buttons["open-\(kind)"].tap()
        XCTAssertTrue(app.buttons["link-confirm"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["link-confirm"].isHittable)
        XCTAssertTrue(app.buttons["link-decline"].isHittable)
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "\(theme)-\(kind)"; shot.lifetime = .keepAlways; add(shot)
        app.buttons["link-decline"].tap()
      }
      app.buttons["open-scan"].tap()
      XCTAssertTrue(app.buttons["scan-consent-confirm"].waitForExistence(timeout: 5))
      XCTAssertTrue(app.buttons["scan-consent-confirm"].isHittable)
      XCTAssertTrue(app.buttons["scan-consent-decline"].isHittable)
      let scan = XCTAttachment(screenshot: app.screenshot()); scan.name = "\(theme)-scan"; scan.lifetime = .keepAlways; add(scan)
      app.buttons["scan-consent-decline"].tap()
      app.buttons["open-comment"].tap()
      XCTAssertTrue(app.buttons["comment-report-send"].waitForExistence(timeout: 5))
      let comment = XCTAttachment(screenshot: app.screenshot()); comment.name = "\(theme)-comment"; comment.lifetime = .keepAlways; add(comment)
      app.terminate()
    }
  }
}
