import XCTest

@MainActor final class MatchProgrammeTests: XCTestCase {
  private let roundID = "home.round.C5000000-0000-4000-8000-000000000001"
  private let personID = "home.round.person.C5000000-0000-4000-8000-000000000011"

  private func launch(_ mode: String, size: String = "large", appearance: String = "dark") -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_programme_fixture", mode, "-cs_dev_text_size", size,
                           "-cs_dev_appearance", appearance, "-cs_dev_look", "none"]
    if let photo = ProcessInfo.processInfo.environment["CS_PROGRAMME_QA_PHOTO"] {
      app.launchArguments += ["-cs_dev_programme_photo", photo]
    }
    app.launch()
    return app
  }

  private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
    for _ in 0..<8 where !element.isHittable { app.swipeUp() }
  }

  private func capture(_ name: String, app: XCUIApplication) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  func testHomeRecordsAndPhotoFallback() throws {
    for mode in ["photo", "no_photo", "failed", "missing"] {
      let app = launch(mode)
      let round = app.buttons[roundID]
      XCTAssertTrue(app.buttons["home.lead.action"].waitForExistence(timeout: 15))
      reveal(round, in: app)
      XCTAssertTrue(round.exists)
      XCTAssertTrue(round.isHittable)
      XCTAssertGreaterThanOrEqual(round.frame.height, 44)
      XCTAssertTrue(app.buttons[personID].isHittable)
      XCTAssertGreaterThanOrEqual(app.buttons[personID].frame.width, 44)
      XCTAssertFalse(round.frame.intersects(app.buttons[personID].frame))
      XCTAssertTrue(round.label.contains(mode == "missing" ? "A round at" : "82 at"))
      capture("home-\(mode)-records", app: app)
      round.tap()
      XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label ==[c] %@ OR label ==[c] %@", "The round", "Your round")).firstMatch.waitForExistence(timeout: 10))
      app.terminate()
    }
  }

  func testLongRecordsAtAccessibilitySize() {
    let app = launch("long", size: "AX3")
    let round = app.buttons[roundID]
    XCTAssertTrue(app.buttons["home.lead.action"].waitForExistence(timeout: 15))
    reveal(round, in: app)
    XCTAssertTrue(round.isHittable)
    XCTAssertLessThanOrEqual(round.frame.maxX, app.frame.maxX - 20)
    capture("home-long-AX3-record", app: app)
    app.buttons["Compete"].firstMatch.tap()
    XCTAssertTrue(app.buttons["compete.start"].waitForExistence(timeout: 15))
    capture("compete-AX3-first-viewport", app: app)
    reveal(app.buttons["compete.start"], in: app)
    XCTAssertTrue(app.buttons["compete.start"].isHittable)
    capture("compete-AX3-creation", app: app)
  }

  func testPhotoAtAccessibilitySize() {
    let app = launch("photo", size: "AX3")
    XCTAssertTrue(app.buttons["home.lead.action"].waitForExistence(timeout: 15))
    capture("home-live-AX3-first-viewport", app: app)
    reveal(app.buttons[roundID], in: app)
    XCTAssertTrue(app.buttons[roundID].isHittable)
    capture("home-photo-AX3-record", app: app)
    let scroll = app.scrollViews.firstMatch
    scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.72))
      .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.58)))
    capture("home-photo-AX3-insert", app: app)
  }

  func testCompeteCreationAndFinishedDisclosure() {
    let app = launch("no_photo")
    app.buttons["Compete"].firstMatch.tap()
    let start = app.buttons["compete.start"]
    XCTAssertTrue(start.waitForExistence(timeout: 15))
    capture("compete-first-viewport", app: app)
    reveal(start, in: app)
    XCTAssertTrue(start.isHittable)
    start.tap()
    XCTAssertTrue(app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "what do you want to do")).waitForExistence(timeout: 10))
    app.terminate()
    let second = launch("no_photo")
    second.buttons["Compete"].firstMatch.tap()
    let finished = second.buttons["compete.finished"]
    reveal(finished, in: second)
    XCTAssertTrue(finished.isHittable)
    finished.tap()
    let wrapped = second.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Sunningdale")).firstMatch
    XCTAssertTrue(wrapped.waitForExistence(timeout: 10))
    reveal(wrapped, in: second)
    XCTAssertTrue(wrapped.isHittable)
    capture("compete-finished-expanded", app: second)
  }

  func testThemeAndEmptyCaptures() {
    for appearance in ["dark", "light"] {
      let app = launch("no_photo", appearance: appearance)
      XCTAssertTrue(app.buttons["home.lead.action"].waitForExistence(timeout: 15))
      capture("home-\(appearance)-first-viewport", app: app)
      app.buttons["Compete"].firstMatch.tap()
      XCTAssertTrue(app.buttons["compete.start"].waitForExistence(timeout: 15))
      capture("compete-\(appearance)-first-viewport", app: app)
      app.terminate()
    }
    let empty = launch("empty")
    XCTAssertFalse(empty.buttons[roundID].exists)
    capture("home-brand-new", app: empty)
  }
}
