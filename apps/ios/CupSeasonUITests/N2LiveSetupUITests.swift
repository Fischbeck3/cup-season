import XCTest

final class N2LiveSetupUITests: N2UITestCase {
  // MARK: F08 · the tee details keep their names

  @MainActor func testF08TeeRatingAndSlopeKeepTheirNamesWhenFilled() {
    for size in ["large", "AX3"] {
      let app = launch("brand-new", "live", size: size)
      _ = root(app, "live")
      for (id, name, value) in [("live.setup.tee", "Tee", "Blue"), ("live.setup.rating", "Rating", "70.1"), ("live.setup.slope", "Slope", "124")] {
        // the keyboard from the last field can cover this one: put it away first
        let close = app.buttons["Close keyboard"]
        if close.exists && close.isHittable { close.tap() }
        let f = app.textFields[id]
        XCTAssertTrue(f.waitForExistence(timeout: 10), id)
        for _ in 0..<4 where !f.isHittable { app.swipeUp() }
        XCTAssertEqual(f.label, name, "\(size): \(id) is named")
        f.tap()
        XCTAssertTrue(f.waitForKeyboardFocus(), "\(size): \(id) takes the keyboard")
        f.typeText(value)
        XCTAssertEqual(app.textFields[id].label, name, "\(size): \(id) keeps its name when filled")
        XCTAssertEqual(app.textFields[id].value as? String, value)
      }
      attach(app, "f08-setup-filled-\(size)")
      app.terminate()
    }
  }
}

private extension XCUIElement {
  /// A tap can land while the keyboard is still settling; give the field a
  /// moment to take focus rather than typing into nothing.
  func waitForKeyboardFocus(timeout: TimeInterval = 5) -> Bool {
    let end = Date().addingTimeInterval(timeout)
    while Date() < end {
      if (value(forKey: "hasKeyboardFocus") as? Bool) == true { return true }
      Thread.sleep(forTimeInterval: 0.2)
    }
    tap()
    return (value(forKey: "hasKeyboardFocus") as? Bool) == true
  }
}
