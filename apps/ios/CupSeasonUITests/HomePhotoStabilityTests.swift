import XCTest

/// D361 · the owner's case: two adjacent photo rounds on Home. Deterministic
/// through `-cs_dev_photo_stability` (see `HomeNoPhotoFixture`): a stub
/// fetcher that answers late and in the order asked, a re-sign button that
/// mints new URLs the way a refresh does, and a removal.
///
/// **Recast 2026-10-01 for the Match Programme record** (`e8e9f84b`, then the
/// owner phone-feedback correction `1664d7cd`). A round is one record — the
/// golfer, the gross, the course and the story — and an available photograph
/// is a 16:9 insert BELOW those facts; when no image is available "the
/// complete record reserves no photo space" (`docs/home-phone-feedback-2026-09-30.md`;
/// `docs/design-match-programme.md`: "an image must not leave a placeholder
/// when absent or unavailable"). So the full-bleed band, its 168pt loading
/// frame and the three identifiers these tests used to wait for
/// (`home.round.photo`, `home.round.photo-loading`, `home.round.no-photo`) are
/// gone by decision. D361's `HomePhotoStore` is unchanged and `HomeWireBand`
/// still draws from it, so every case below still holds; what changed is how a
/// test SEES a photograph.
///
/// The insert is hidden from VoiceOver (the round control already speaks the
/// whole record once), so it is read from the layout: the space between a
/// round's control and that round's own applause control either holds a 16:9
/// insert at the record's width or it holds only the course lines.
@MainActor final class HomePhotoStabilityTests: XCTestCase {
  /// the fixture's two adjacent photo rounds (`HomeNoPhotoFixture.photoRows`)
  private enum Who: String {
    case blake = "B0000000-0000-4000-8000-000000000001"   // 81 at Encanto · fixture/first.png
    case emery = "B0000000-0000-4000-8000-000000000002"   // 77 at Aguila · fixture/second.png
  }

  private func launch(_ extra: [String]) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_no_photo", "-cs_dev_photo_stability", "-cs_dev_look", "none", "-cs_dev_text_size", "large"] + extra
    app.launch()
    return app
  }

  /// the round control: identity and gross, speaking the complete record
  private func round(_ app: XCUIApplication, _ who: Who) -> XCUIElement {
    app.buttons["home.round.\(who.rawValue)"]
  }

  /// A 16:9 insert at the record's width. The fixture lays each photo round
  /// edge to edge, so that width is the window's.
  private func insert(_ app: XCUIApplication) -> CGFloat { app.frame.width * 9 / 16 }

  /// From the bottom of a round's control to the top of its own applause
  /// control: the course lines alone (about 64pt here), or the course lines
  /// and the photograph (that plus 8pt and the insert).
  private func gap(_ app: XCUIApplication, _ who: Who) -> CGFloat? {
    let control = round(app, who)
    guard control.exists else { return nil }
    let bottom = control.frame.maxY
    let applause = app.buttons.matching(identifier: "applause.give").allElementsBoundByIndex
      .map { $0.frame.minY }.filter { $0 >= bottom - 1 }.min()
    return applause.map { $0 - bottom }
  }
  private func photoUp(_ app: XCUIApplication, _ who: Who) -> Bool {
    gap(app, who).map { $0 >= insert(app) } ?? false
  }
  /// The record and nothing holding a place for a picture.
  private func photoDown(_ app: XCUIApplication, _ who: Who) -> Bool {
    gap(app, who).map { $0 < insert(app) / 2 } ?? false
  }

  /// The layout reaches its states asynchronously: poll, with a deadline.
  private func eventually(_ timeout: TimeInterval, _ condition: () -> Bool) -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if condition() { return true }
      RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    }
    return condition()
  }
  /// "Stays up THROUGHOUT": the condition holds at every sample across the
  /// window, not at one instant.
  private func throughout(_ window: TimeInterval, _ condition: () -> Bool) -> Bool {
    let deadline = Date().addingTimeInterval(window)
    repeat {
      if !condition() { return false }
      RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    } while Date() < deadline
    return condition()
  }

  private func fetches(_ app: XCUIApplication) -> Int {
    let t = app.staticTexts["home.photo.fetches"].label
    return Int(t.split(separator: " ").last ?? "") ?? -1
  }
  private func capture(_ name: String, _ app: XCUIApplication) {
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = name; shot.lifetime = .keepAlways; add(shot)
  }

  @MainActor func testBothPhotographsStayUpWhenTheSecondLandsFirst() {
    let app = launch(["-cs_dev_photo_order", "reversed"])
    // while the first is out, its record is already whole — the score and the
    // course do not wait for the picture — and nothing holds a place for it
    let blake = round(app, .blake)
    XCTAssertTrue(blake.waitForExistence(timeout: 15))
    XCTAssertTrue(blake.label.contains("81 at Encanto"), "the score and course do not wait for the picture")
    XCTAssertTrue(eventually(3) { photoDown(app, .blake) }, "a loading round held space for a picture it does not have yet")
    // the second lands first
    XCTAssertTrue(eventually(5) { photoUp(app, .emery) }, "the second photograph never landed")
    XCTAssertTrue(photoDown(app, .blake), "the first is still loading, untouched by the second")
    // then both are up, together
    XCTAssertTrue(eventually(10) { photoUp(app, .blake) && photoUp(app, .emery) }, "both photographs are not up together")
    capture("two-photos-reversed-order", app)
    XCTAssertEqual(fetches(app), 2)

    // scrolling away and back does not reload them
    app.swipeUp(); app.swipeUp()
    XCTAssertTrue(app.staticTexts["home.photo.end"].waitForExistence(timeout: 5))
    app.swipeDown(); app.swipeDown()
    XCTAssertTrue(eventually(5) { photoUp(app, .blake) && photoUp(app, .emery) })
    XCTAssertEqual(fetches(app), 2, "returning to the photographs fetched again")
  }

  @MainActor func testRefreshKeepsBothPicturesAndATransientMissDoesNotRemoveOne() {
    let app = launch(["-cs_dev_photo_fail", "second"])
    XCTAssertTrue(eventually(15) { photoUp(app, .blake) && photoUp(app, .emery) })
    // a refresh re-signs: new URLs, new fetches — the pictures stay on screen throughout
    app.buttons["home.photo.resign"].tap()
    XCTAssertTrue(throughout(1) { photoUp(app, .blake) && photoUp(app, .emery) },
                  "re-signing took a picture down while its new fetch was out")
    // the second's refresh misses transiently (it answers 1.5s after it goes
    // out): its last good picture stays
    let settled = NSPredicate(format: "label ENDSWITH '4'")
    expectation(for: settled, evaluatedWith: app.staticTexts["home.photo.fetches"]); waitForExpectations(timeout: 8)
    XCTAssertTrue(throughout(3) { photoUp(app, .blake) && photoUp(app, .emery) }, "a transient miss removed a photograph")
    capture("two-photos-after-refresh-with-one-miss", app)
  }

  @MainActor func testRemovalAndAGoneObjectBecomeTheRecord() {
    let app = launch(["-cs_dev_photo_gone", "second"])
    XCTAssertTrue(eventually(15) { photoUp(app, .blake) && photoUp(app, .emery) })
    // the object is gone on refresh → the record, the other picture untouched
    app.buttons["home.photo.resign"].tap()
    XCTAssertTrue(eventually(8) { photoDown(app, .emery) }, "a gone object kept its picture's place")
    XCTAssertTrue(round(app, .emery).label.contains("77 at Aguila"), "the record is not whole")
    XCTAssertTrue(throughout(2) { photoUp(app, .blake) }, "the gone object touched the other picture")
    // an attachment removed outright (no URL to sign) → the record as well
    app.buttons["home.photo.remove"].tap()
    XCTAssertTrue(eventually(5) { photoDown(app, .emery) })
    XCTAssertTrue(throughout(2) { photoUp(app, .blake) }, "removing the second touched the first")
    capture("one-photo-one-record-after-removal", app)
  }

  @MainActor func testFirstLoadMissRecoversOnAPullWithoutANewCredential() {
    let app = launch(["-cs_dev_photo_fail_first", "first"])
    // the second is up; the first missed and shows the record, not an empty panel
    XCTAssertTrue(eventually(15) { photoUp(app, .emery) })
    XCTAssertTrue(eventually(10) { photoDown(app, .blake) }, "a first-load miss held a place for a picture")
    XCTAssertTrue(round(app, .blake).label.contains("81 at Encanto"), "the record is not whole")
    let before = fetches(app)
    // a pull asks again on the SAME credential, and the picture lands
    app.buttons["home.photo.pull"].tap()
    XCTAssertTrue(eventually(15) { photoUp(app, .blake) }, "the first round did not recover")
    XCTAssertEqual(fetches(app), before + 1, "recovery was more than one request")
    capture("first-load-miss-recovered", app)
  }

  @MainActor func testACredentialThisLoadCouldNotGetKeepsThePictureUp() {
    let app = launch(["-cs_dev_photo_unsignable", "second"])
    XCTAssertTrue(eventually(15) { photoUp(app, .blake) && photoUp(app, .emery) })
    // the re-sign yields no credential for the second: a temporary condition
    app.buttons["home.photo.resign"].tap()
    XCTAssertTrue(throughout(2) { photoUp(app, .emery) }, "a transient signing failure took the picture down")
    XCTAssertTrue(eventually(5) { photoUp(app, .blake) })
    // only the first's refresh went out: nothing was requested for a path with no credential
    let settled = NSPredicate(format: "label ENDSWITH '3'")
    expectation(for: settled, evaluatedWith: app.staticTexts["home.photo.fetches"]); waitForExpectations(timeout: 8)
    XCTAssertTrue(throughout(1.5) { photoUp(app, .emery) && photoUp(app, .blake) })
    XCTAssertEqual(fetches(app), 3, "a fetch went out for a path with no credential")
    capture("unsignable-keeps-picture", app)
  }
}
