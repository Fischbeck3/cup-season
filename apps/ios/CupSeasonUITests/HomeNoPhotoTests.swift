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
    app.buttons["React to this round"].firstMatch.tap()
    let flowers = app.descendants(matching: .any)["flowers"]
    XCTAssertTrue(flowers.waitForExistence(timeout: 5))
    flowers.tap()
    XCTAssertTrue(app.descendants(matching: .any)["flowers, 1, yours"].exists)
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
    let react = app.buttons["React to this round"].firstMatch
    XCTAssertTrue(react.waitForExistence(timeout: 20))
    XCTAssertFalse(app.descendants(matching: .any)["flowers"].exists)
    react.tap()
    let flowers = app.descendants(matching: .any)["flowers"]
    XCTAssertTrue(flowers.waitForExistence(timeout: 5))
    let reveal = XCTAttachment(screenshot: app.screenshot())
    reveal.name = "Home reaction choices"; reveal.lifetime = .keepAlways; add(reveal)
    flowers.tap()
    XCTAssertTrue(app.descendants(matching: .any)["flowers, 1, yours"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.descendants(matching: .any)["cheers"].exists)
    XCTAssertTrue(app.buttons["More reactions"].exists)
    app.descendants(matching: .any)["flowers, 1, yours"].tap()
    XCTAssertFalse(app.descendants(matching: .any)["flowers, 1, yours"].exists)
    XCTAssertTrue(app.buttons["React to this round"].firstMatch.exists)
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
