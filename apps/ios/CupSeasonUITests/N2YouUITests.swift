import XCTest

final class N2YouUITests: N2UITestCase {
  // MARK: F10 · You

  @MainActor func testF10AnEmptyRecordSaysSoOnceWithOneNextStep() {
    let app = launch("brand-new", "you")
    _ = root(app, "you")
    let post = app.buttons["Post your first round"]
    XCTAssertTrue(post.waitForExistence(timeout: 15))
    XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Post your first round")).count, 1)
    XCTAssertGreaterThanOrEqual(post.frame.height, 44, "the next step is a real control")
    XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'No rounds yet'")).firstMatch.exists,
                   "the record's absence is not said again under its own headline")
    XCTAssertFalse(app.staticTexts["Nobody yet"].exists, "no rivals section on an empty record")
    attach(app, "f10-you-empty")
  }

  @MainActor func testF10AFailedReadIsNeverNoRoundsAndItsRetryLands() {
    let app = launch("failures", "you")
    _ = root(app, "you")
    let failed = app.descendants(matching: .any)["you.record.failed"]
    XCTAssertTrue(failed.waitForExistence(timeout: 15))
    XCTAssertTrue(app.staticTexts["Your rounds didn\u{2019}t load"].exists)
    XCTAssertFalse(app.staticTexts["Nobody yet"].exists, "a failed rivalries read is not 'nobody yet'")
    XCTAssertFalse(app.buttons["Post your first round"].exists, "a failed read never offers the first round")
    XCTAssertFalse(app.buttons["Retry loading your card"].exists, "one retry, not two")
    let retry = app.buttons["Try again"]
    XCTAssertTrue(retry.exists)
    XCTAssertGreaterThanOrEqual(retry.frame.height, 44)
    attach(app, "f10-you-failed")
    Thread.sleep(forTimeInterval: 1.5)   // the synthetic read fails once, then the retry lands
    for _ in 0..<3 where !retry.isHittable { app.swipeUp() }
    retry.tap()
    XCTAssertTrue(app.staticTexts["Form"].waitForExistence(timeout: 15), "the record returns on the retry")
    XCTAssertFalse(failed.exists)
    attach(app, "f10-you-retried")
  }
}
