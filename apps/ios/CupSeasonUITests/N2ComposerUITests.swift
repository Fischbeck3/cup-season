import XCTest

final class N2ComposerUITests: N2UITestCase {
  // MARK: F09 · the first round leads with the score

  @MainActor func testF09FirstRoundBandsWaitBehindHowPointsWork() {
    let app = launch("brand-new", "postround")
    _ = root(app, "composer")
    XCTAssertTrue(app.textFields["Your gross"].waitForExistence(timeout: 10))
    let how = app.buttons["How points work"]
    for _ in 0..<6 where !how.exists || !how.isHittable { app.swipeUp() }
    XCTAssertTrue(how.exists)
    XCTAssertEqual(how.value as? String, "collapsed")
    XCTAssertGreaterThanOrEqual(how.frame.height, 44)
    let before = app.staticTexts.count
    how.tap()
    XCTAssertEqual(app.buttons["How points work"].value as? String, "expanded")
    // the five bands appear only when asked for (named nowhere here: the one
    // band table is CSBands, and a test is not a second one)
    XCTAssertGreaterThanOrEqual(app.staticTexts.count, before + 5, "the band rows open under How points work")
  }
}
