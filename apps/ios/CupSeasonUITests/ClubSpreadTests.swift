import XCTest

@MainActor final class ClubSpreadTests: XCTestCase {
  private let dew = "compete.row.league:C50F0000-0000-4000-8000-000000000030"
  private let duel = "compete.row.league:C50F0000-0000-4000-8000-000000000010"
  private let fellas = "compete.row.league:C50F0000-0000-4000-8000-000000000020"

  private func launch(_ mode: String = "mixed", appearance: String = "dark",
                      size: String = "large", screen: String = "root") -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_league_identity", "-cs_identity_mode", mode,
      "-cs_identity_screen", screen, "-cs_dev_appearance", appearance,
      "-cs_dev_text_size", size, "-cs_dev_look", "none",
      "-cs_identity_photo", ProcessInfo.processInfo.environment["CS_IDENTITY_QA_PHOTO"] ?? "/private/tmp/club-spread-qa-photo.png",
      "-cs_identity_logo", ProcessInfo.processInfo.environment["CS_IDENTITY_QA_LOGO"] ?? "/private/tmp/club-spread-qa-logo.png"]
    app.launch()
    return app
  }
  private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
    // A tall accessible row can be hittable with only its bottom edge visible.
    // Put its opening inside the viewport before capturing its identity/standing.
    for _ in 0..<16 {
      let frame = element.frame
      if frame.width == 0 || frame.height == 0 { app.swipeUp(); continue }
      let top = frame.minY
      if top >= 70 && top <= app.frame.height * 0.4 { return }
      let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: top < 70 ? 0.35 : 0.65))
      let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: top < 70 ? 0.65 : 0.35))
      start.press(forDuration: 0.05, thenDragTo: end,
                  withVelocity: .slow, thenHoldForDuration: 0.3)
    }
  }
  private func capture(_ name: String, in app: XCUIApplication) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
  }
  private func revealInput(_ field: XCUIElement, in app: XCUIApplication) {
    for _ in 0..<8 {
      if field.isHittable && field.frame.maxY < app.buttons["league.identity.save"].frame.minY { return }
      let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
      let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
      start.press(forDuration: 0.05, thenDragTo: end,
                  withVelocity: .slow, thenHoldForDuration: 0.3)
    }
  }
  func testLayoutMatrix() {
    for appearance in ["dark", "light"] {
      for size in ["large", "AX3"] {
        let app = launch(appearance: appearance, size: size)
        let first = app.buttons[dew]
        XCTAssertTrue(first.waitForExistence(timeout: 15))
        XCTAssertTrue(first.label.contains("Early tee times. Long friendships."))
        XCTAssertTrue(first.label.contains("You, Tash +10"))
        XCTAssertFalse(first.label.contains("points"), "Preseason must not invent a standing")
        XCTAssertGreaterThanOrEqual(first.frame.height, 44)
        XCTAssertGreaterThanOrEqual(first.frame.minX, 19)
        XCTAssertLessThanOrEqual(first.frame.maxX, app.frame.maxX - 19)
        capture("club-spread-\(appearance)-\(size)-first", in: app)
        reveal(app.buttons[duel], in: app)
        XCTAssertTrue(app.buttons[duel].isHittable)
        XCTAssertTrue(app.buttons[duel].label.contains("You and Galen"))
        XCTAssertTrue(app.buttons[duel].label.contains("15 points"))
        XCTAssertTrue(app.buttons[duel].label.contains("Out of 2"))
        capture("club-spread-\(appearance)-\(size)-standing", in: app)
        reveal(app.buttons[fellas], in: app)
        XCTAssertTrue(app.buttons[fellas].isHittable)
        capture("club-spread-\(appearance)-\(size)-logo", in: app)
        app.terminate()
      }
    }
  }
  func testFailedAndAbsentImagesKeepTheirLeagueDoor() {
    for mode in ["failed", "none", "long"] {
      let app = launch(mode)
      let first = app.buttons[dew]
      XCTAssertTrue(first.waitForExistence(timeout: 15))
      XCTAssertTrue(first.isHittable)
      capture("club-spread-\(mode)-first", in: app)
      app.terminate()
    }
  }
  func testLeagueDoorCarriesIdentityInside() {
    let app = launch()
    let row = app.buttons[duel]
    XCTAssertTrue(row.waitForExistence(timeout: 15))
    reveal(row, in: app); row.tap()
    let title = app.descendants(matching: .any)["season.title"].firstMatch
    XCTAssertTrue(title.waitForExistence(timeout: 15))
    XCTAssertTrue(app.staticTexts["Two golfers. A season to settle it."].exists)
    capture("club-spread-season-header", in: app)
  }
  func testEditorBoundsAndPreservesFailedSave() {
    for appearance in ["dark", "light"] {
      let app = launch(appearance: appearance, screen: "editor")
      XCTAssertTrue(app.buttons["league.identity.close"].waitForExistence(timeout: 15))
      capture("club-spread-editor-\(appearance)", in: app)
      // CSField owns the native input inside its label/caption wrapper.
      // This editor has one prose input; scroll it clear of the fixed foot.
      for _ in 0..<8 where !app.textFields.firstMatch.exists &&
        !app.textViews.firstMatch.exists { app.swipeUp() }
      let field = app.textFields.firstMatch.exists ? app.textFields.firstMatch : app.textViews.firstMatch
      XCTAssertTrue(field.waitForExistence(timeout: 15))
      revealInput(field, in: app)
      field.tap(); field.typeText(" Our group.")
      app.buttons["league.identity.save"].tap()
      XCTAssertTrue(app.staticTexts["league.identity.error"].waitForExistence(timeout: 5))
      XCTAssertTrue((field.value as? String)?.contains("Our group.") == true)
      capture("club-spread-editor-\(appearance)-failed-save", in: app)
      revealInput(field, in: app)
      field.tap(); field.typeText(String(repeating: "a", count: 161))
      XCTAssertFalse(app.buttons["league.identity.save"].isEnabled,
                     "Descriptions beyond the server's limit cannot be submitted")
      app.terminate()
    }
  }
}
