import XCTest

/// N4 · the shell's own findings, measured on screen.
///
/// - N4-060: with the keyboard up, the tab band rode ~74pt on top of the keys,
///   and at SE3 AX3 a golfer search had no room left for a single result
///   (`se3/golfers-search-dark-AX3.png`). The band stands down while the
///   keyboard is up, as a system tab bar sits behind the keys, and comes back
///   when it goes. Run this on an SE as well as a 17 Pro.
final class N4ShellUITests: N2UITestCase {
  override func setUp() { continueAfterFailure = true }

  /// The band's five slots, wherever they are drawn at the foot of the screen.
  @MainActor private func band(_ app: XCUIApplication) -> [XCUIElement] {
    let foot = app.windows.firstMatch.frame.height * 0.6
    return app.buttons.matching(NSPredicate(format: "label IN %@", ["Home", "Compete", "Play", "Golfers", "You"]))
      .allElementsBoundByIndex.filter { $0.exists && $0.frame.minY > foot }
  }

  @MainActor func testTheTabBandStandsDownWhileTheKeyboardIsUp() {
    for size in ["large", "AX3"] {
      let app = launch("season-live", "golfers", size: size)
      _ = root(app, "golfers")
      XCTAssertGreaterThanOrEqual(band(app).count, 4, "\(size): the band is there before the keyboard")
      let field = app.textFields["Search golfers by name or @handle"].firstMatch
      XCTAssertTrue(field.waitForExistence(timeout: 10), "\(size): the search field")
      for _ in 0..<4 where !field.isHittable { app.swipeUp() }
      field.tap()
      let keys = app.keyboards.firstMatch
      XCTAssertTrue(keys.waitForExistence(timeout: 8), "\(size): the keyboard is up")
      Thread.sleep(forTimeInterval: 1)
      let top = keys.frame.minY
      let riding = band(app).filter { $0.isHittable && $0.frame.maxY <= top + 1 }
      XCTAssertTrue(riding.isEmpty, "\(size): no tab rides on top of the keys — \(riding.map { "\($0.label) \($0.frame)" })")
      XCTAssertLessThanOrEqual(field.frame.maxY, top, "\(size): the search field is above the keys")
      attach(app, "n4-golfers-search-keyboard-\(size)")
      // the keyboard goes, and the band comes back. No key is tapped by name:
      // root's 17 Pro drew no "search" key, and on this one a "return" key
      // that existed could not be tapped (XCUI's legacy and modern attributes
      // disagreed on whether it was a button). The return goes through the
      // field instead, which works whatever the key is called.
      app.swipeDown()
      if keys.exists { field.typeText("\n") }
      let close = app.buttons["Close keyboard"].firstMatch
      if keys.exists, close.exists { close.tap() }
      XCTAssertTrue(waitGone(keys, timeout: 6), "\(size): the keyboard went")
      Thread.sleep(forTimeInterval: 1)
      XCTAssertGreaterThanOrEqual(band(app).filter(\.isHittable).count, 4, "\(size): the band is back")
      app.terminate()
    }
  }

  @MainActor private func waitGone(_ e: XCUIElement, timeout: TimeInterval) -> Bool {
    let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: e)
    return XCTWaiter().wait(for: [gone], timeout: timeout) == .completed
  }
}
