import XCTest

final class HomeNoPhotoTests: XCTestCase {
  @MainActor func testLoadedPhotoFaceAndRoundHaveDistinctDestinations() {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_no_photo", "-cs_dev_loaded_photo", "-cs_dev_text_size", "large", "-cs_dev_look", "none"]
    app.terminate(); app.launch()
    let photo = app.descendants(matching: .any)["home.round.photo"].firstMatch
    XCTAssertTrue(photo.waitForExistence(timeout: 20))
    XCTAssertEqual(photo.frame.height, 168, accuracy: 1)
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "Loaded photo control fixture"; shot.lifetime = .keepAlways; add(shot)
    // The 44pt face starts at the 20pt gutter and ends 12pt above the band bottom.
    photo.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 42, dy: 134)).tap()
    XCTAssertTrue(app.staticTexts["Golfer · You"].waitForExistence(timeout: 5))
    app.terminate(); app.launch()
    XCTAssertTrue(photo.waitForExistence(timeout: 20))
    photo.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5)).tap()
    XCTAssertTrue(app.staticTexts["Round · UNM Championship Course"].waitForExistence(timeout: 5))
  }

  @MainActor func testUnavailablePhotoKeepsReceiptPersonAndReactionDoors() {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_no_photo", "-cs_dev_failed_photo", "-cs_dev_text_size", "ax3", "-cs_dev_look", "none"]
    app.launch()
    let record = app.buttons.matching(identifier: "home.round.no-photo").firstMatch
    XCTAssertTrue(record.waitForExistence(timeout: 20))
    XCTAssertTrue(record.isHittable)
    let photoFallback = XCTAttachment(screenshot: app.screenshot())
    photoFallback.name = "Unavailable photo at AX3"; photoFallback.lifetime = .keepAlways; add(photoFallback)
    // D365 · one appreciation action: give applause, and the count appears
    let give = app.buttons["Give applause"].firstMatch
    XCTAssertTrue(give.waitForExistence(timeout: 5))
    give.tap()
    XCTAssertTrue(app.buttons["Remove applause"].firstMatch.waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["1 applause"].firstMatch.exists)
    record.tap()
    XCTAssertTrue(app.staticTexts["Round · UNM Championship Course"].waitForExistence(timeout: 5))
    app.terminate(); app.launch()
    let golfer = app.scrollViews["home.no-photo.fixture"].firstMatch.buttons["Open golfer card: You"]
    XCTAssertTrue(golfer.waitForExistence(timeout: 20))
    golfer.tap()
    XCTAssertTrue(app.staticTexts["Golfer · You"].waitForExistence(timeout: 5))
  }

  @MainActor func testReactRevealsChoicesAndKeepsOnlyTheGivenReaction() {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_no_photo", "-cs_dev_text_size", "large", "-cs_dev_look", "none"]
    app.launch()
    // D365 · no picker, no capsule, no word: one glyph, then a count, and a
    // second tap takes it back. The old menu's words never appear.
    let give = app.buttons["Give applause"].firstMatch
    XCTAssertTrue(give.waitForExistence(timeout: 20))
    XCTAssertFalse(app.descendants(matching: .any)["flowers"].exists)
    XCTAssertFalse(app.buttons["React to this round"].exists)
    XCTAssertFalse(app.buttons["More reactions"].exists)
    XCTAssertGreaterThanOrEqual(give.frame.width, 44); XCTAssertGreaterThanOrEqual(give.frame.height, 44)
    give.tap()
    let remove = app.buttons["Remove applause"].firstMatch
    XCTAssertTrue(remove.waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["1 applause"].firstMatch.exists)
    let given = XCTAttachment(screenshot: app.screenshot())
    given.name = "Home applause given"; given.lifetime = .keepAlways; add(given)
    // the count opens the people
    app.buttons["1 applause"].firstMatch.tap()
    XCTAssertTrue(app.staticTexts["Applause"].firstMatch.waitForExistence(timeout: 5))
    app.buttons["Close"].firstMatch.tap()
    remove.tap()
    XCTAssertTrue(app.buttons["Give applause"].firstMatch.waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["1 applause"].exists)
    XCTAssertTrue(app.buttons["Give applause"].firstMatch.exists)   // D365
  }

  /// D360 · the five states of the record, photographed in both appearances
  /// and at an accessibility size: the reference round, a milestone, a long
  /// course name with no handicap context, and the consequence case.
  @MainActor func testRecordStatesInBothAppearances() {
    for (appearance, size) in [("dark", "large"), ("light", "large"), ("dark", "ax3")] {
      let app = XCUIApplication()
      app.launchArguments = ["-cs_dev_no_photo", "-cs_dev_text_size", size, "-cs_dev_look", "none", "-cs_dev_appearance", appearance]
      app.launch()
      let record = app.buttons.matching(identifier: "home.round.no-photo").firstMatch
      XCTAssertTrue(record.waitForExistence(timeout: 20))
      XCTAssertTrue(app.staticTexts["UNM Championship Course"].exists, "the course is the title")
      XCTAssertTrue(app.staticTexts["89"].exists, "the gross is the figure")
      XCTAssertTrue(app.staticTexts["2.0 over your playing HCP."].exists, "the story is the handicap context")
      XCTAssertTrue(app.staticTexts["9 pts · counting #2 this month"].exists, "the consequence is the story when it is known")
      XCTAssertFalse(app.staticTexts["Beat their playing HCP by 3.1."].exists, "two stories on one round")
      let shot = XCTAttachment(screenshot: app.screenshot())
      shot.name = "record-states-\(appearance)-\(size)"; shot.lifetime = .keepAlways; add(shot)
      app.terminate()
    }
  }

  @MainActor func testRecordAndGolferHaveSeparateWorkingDoors() {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_no_photo", "-cs_dev_text_size", "large", "-cs_dev_look", "none"]
    app.launch()
    let record = app.buttons.matching(identifier: "home.round.no-photo").firstMatch
    XCTAssertTrue(record.waitForExistence(timeout: 20))
    XCTAssertTrue(record.isHittable)
    record.tap()
    XCTAssertTrue(app.staticTexts["Round · UNM Championship Course"].waitForExistence(timeout: 5))
    app.terminate()
    app.launch()
    let golfer = app.scrollViews["home.no-photo.fixture"].firstMatch.buttons["Open golfer card: You"]
    XCTAssertTrue(golfer.waitForExistence(timeout: 20))
    golfer.tap()
    XCTAssertTrue(app.staticTexts["Golfer · You"].waitForExistence(timeout: 5))
  }
}
