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
    // W7-047 · the head names its window
    XCTAssertTrue(app.staticTexts["Form · last five"].waitForExistence(timeout: 15), "the record returns on the retry")
    XCTAssertFalse(failed.exists)
    attach(app, "f10-you-retried")
  }

  // MARK: the Form row (§9.7 · parity with the web at 38471687)

  /// The synthetic golfer's last five hold a 43 over nine holes among 18-hole
  /// grosses. The craft panel caught the nine taking the gold; it never does,
  /// and it says it is a nine — in the columns and in the five rows at AX3.
  @MainActor func testTheFormRowNeverGoldsANine() {
    for size in ["large", "AX3"] {
      let app = launch("season-live", "you", size: size)
      _ = root(app, "you")
      let nine = app.descendants(matching: .any)
        .matching(NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS %@", "43, ", "nine holes")).firstMatch
      XCTAssertTrue(nine.waitForExistence(timeout: 15), "\(size): the nine says it is a nine")
      for _ in 0..<8 where !nine.isHittable { app.swipeUp() }
      // W7-111 · on the golfer's own card the gold is "your best"
      XCTAssertFalse(nine.label.contains("your best"), "\(size): a nine is never the best — \(nine.label)")
      let best = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", ", your best"))
      XCTAssertEqual(best.count, 1, "\(size): one column is the best")
      XCTAssertFalse(best.firstMatch.label.contains("nine holes"), "\(size): the best is an 18 — \(best.firstMatch.label)")
      attach(app, "form-\(size)")
      app.terminate()
    }
  }

  /// W7-089 · the record holds more rounds than the form shows: "The other N"
  /// opens every round, and a round opens its receipt.
  @MainActor func testTheOtherRoundsAreOneDoorAway() {
    let app = launch("season-live", "you")
    _ = root(app, "you")
    let door = app.buttons["you.allRounds"]
    for _ in 0..<6 where !(door.exists && door.isHittable) { app.swipeUp() }
    XCTAssertTrue(door.waitForExistence(timeout: 10), "the door to the other rounds")
    XCTAssertTrue(door.label.lowercased().hasPrefix("the other "), door.label)
    door.tap()
    let row = app.buttons.matching(identifier: "you.allRounds.row").firstMatch
    XCTAssertTrue(row.waitForExistence(timeout: 15), "every round, listed")
    XCTAssertGreaterThan(app.buttons.matching(identifier: "you.allRounds.row").count, 5, "more than the form's five")
    attach(app, "w7-089-your-rounds")
    row.tap()
    XCTAssertTrue(app.buttons["round.course"].waitForExistence(timeout: 15), "a round opens its receipt")
  }
}
