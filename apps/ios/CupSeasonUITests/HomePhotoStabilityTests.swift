import XCTest

/// D361 · the owner's case: two adjacent photo rounds on Home. Deterministic
/// through `-cs_dev_photo_stability` (see `HomeNoPhotoFixture`): a stub
/// fetcher that answers late and in the order asked, a re-sign button that
/// mints new URLs the way a refresh does, and a removal.
final class HomePhotoStabilityTests: XCTestCase {
  private func launch(_ extra: [String]) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_no_photo", "-cs_dev_photo_stability", "-cs_dev_look", "none", "-cs_dev_text_size", "large"] + extra
    app.launch()
    return app
  }
  /// a band, by its identifier and the golfer it belongs to. SwiftUI exposes
  /// the button and its label under one identifier, so bands are counted by
  /// name rather than by element.
  private func band(_ app: XCUIApplication, _ who: String) -> XCUIElement {
    app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@ AND label BEGINSWITH %@", "home.round.photo", "FIXTURE · " + who)).firstMatch
  }
  private func bothUp(_ app: XCUIApplication, timeout: TimeInterval) -> Bool {
    band(app, "Galen").waitForExistence(timeout: timeout) && band(app, "Jade").waitForExistence(timeout: timeout)
  }
  private func loadingFrame(_ app: XCUIApplication) -> XCUIElement {
    app.descendants(matching: .any)["home.round.photo-loading"].firstMatch
  }
  private func fetches(_ app: XCUIApplication) -> Int {
    let t = app.staticTexts["home.photo.fetches"].label
    return Int(t.split(separator: " ").last ?? "") ?? -1
  }

  @MainActor func testBothPhotographsStayUpWhenTheSecondLandsFirst() {
    let app = launch(["-cs_dev_photo_order", "reversed"])
    // while the first is out, its frame holds the score and course at the band's height
    let loading = loadingFrame(app)
    XCTAssertTrue(loading.waitForExistence(timeout: 15))
    XCTAssertEqual(loading.frame.height, 168, accuracy: 1)
    XCTAssertTrue(loading.label.contains("81 at Encanto"), "the score and course do not wait for the picture")
    // the second lands first
    XCTAssertTrue(band(app, "Jade").waitForExistence(timeout: 5))
    XCTAssertTrue(loading.exists, "the first is still loading, untouched by the second")
    // then both are up, together
    XCTAssertTrue(bothUp(app, timeout: 10))
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "two-photos-reversed-order"; shot.lifetime = .keepAlways; add(shot)
    XCTAssertEqual(fetches(app), 2)

    // scrolling away and back does not reload them
    app.swipeUp(); app.swipeUp()
    XCTAssertTrue(app.staticTexts["home.photo.end"].waitForExistence(timeout: 5))
    app.swipeDown(); app.swipeDown()
    XCTAssertTrue(bothUp(app, timeout: 5))
    XCTAssertEqual(fetches(app), 2, "returning to the bands did not fetch again")
  }

  @MainActor func testRefreshKeepsBothPicturesAndATransientMissDoesNotRemoveOne() {
    let app = launch(["-cs_dev_photo_fail", "second"])
    XCTAssertTrue(bothUp(app, timeout: 15))
    // a refresh re-signs: new URLs, new fetches — the pictures stay on screen throughout
    app.buttons["home.photo.resign"].tap()
    XCTAssertTrue(band(app, "Galen").exists && band(app, "Jade").exists, "re-signing took a picture down")
    XCTAssertFalse(loadingFrame(app).exists, "a frame replaced a picture that was already up")
    // the second's refresh misses transiently: its last good picture stays
    let settled = NSPredicate(format: "label ENDSWITH '4'")
    expectation(for: settled, evaluatedWith: app.staticTexts["home.photo.fetches"]); waitForExpectations(timeout: 8)
    XCTAssertTrue(band(app, "Galen").exists && band(app, "Jade").exists, "a transient miss removed a photograph")
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "two-photos-after-refresh-with-one-miss"; shot.lifetime = .keepAlways; add(shot)
  }

  @MainActor func testRemovalAndAGoneObjectBecomeTheRecord() {
    let app = launch(["-cs_dev_photo_gone", "second"])
    XCTAssertTrue(bothUp(app, timeout: 15))
    // the object is gone on refresh → the record, the other picture untouched
    app.buttons["home.photo.resign"].tap()
    let record = app.buttons.matching(identifier: "home.round.no-photo").firstMatch
    XCTAssertTrue(record.waitForExistence(timeout: 8))
    // "still up" is a short wait, not an instant sample: the band re-lays out
    // between its loaded and refreshing faces and the tree can be mid-snapshot
    XCTAssertTrue(band(app, "Galen").waitForExistence(timeout: 3) && !band(app, "Jade").exists, "the gone object touched the other picture")
    // an attachment removed outright (no URL to sign) → the record as well
    app.buttons["home.photo.remove"].tap()
    XCTAssertTrue(record.waitForExistence(timeout: 5))
    XCTAssertTrue(band(app, "Galen").waitForExistence(timeout: 3) && !band(app, "Jade").exists, "removing the second touched the first")
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "one-photo-one-record-after-removal"; shot.lifetime = .keepAlways; add(shot)
  }

  @MainActor func testFirstLoadMissRecoversOnAPullWithoutANewCredential() {
    let app = launch(["-cs_dev_photo_fail_first", "first"])
    // the second is up; the first missed and shows the record, not an empty panel
    XCTAssertTrue(band(app, "Jade").waitForExistence(timeout: 15))
    let record = app.buttons.matching(identifier: "home.round.no-photo").firstMatch
    XCTAssertTrue(record.waitForExistence(timeout: 10))
    let before = fetches(app)
    // a pull asks again on the SAME credential, and the picture lands
    app.buttons["home.photo.pull"].tap()
    XCTAssertTrue(band(app, "Galen").waitForExistence(timeout: 15), "the first round did not recover")
    XCTAssertEqual(fetches(app), before + 1, "recovery was more than one request")
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "first-load-miss-recovered"; shot.lifetime = .keepAlways; add(shot)
  }

  @MainActor func testACredentialThisLoadCouldNotGetKeepsThePictureUp() {
    let app = launch(["-cs_dev_photo_unsignable", "second"])
    XCTAssertTrue(bothUp(app, timeout: 15))
    // the re-sign yields no credential for the second: a temporary condition
    app.buttons["home.photo.resign"].tap()
    XCTAssertTrue(band(app, "Jade").waitForExistence(timeout: 3), "a transient signing failure took the picture down")
    XCTAssertTrue(band(app, "Galen").waitForExistence(timeout: 5))
    // only the first's refresh went out: nothing was requested for a path with no credential
    let settled = NSPredicate(format: "label ENDSWITH '3'")
    expectation(for: settled, evaluatedWith: app.staticTexts["home.photo.fetches"]); waitForExpectations(timeout: 8)
    XCTAssertTrue(band(app, "Jade").exists && band(app, "Galen").exists)
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "unsignable-keeps-picture"; shot.lifetime = .keepAlways; add(shot)
  }
}
