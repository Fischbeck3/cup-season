import XCTest

/// D360 / D365 · a round on Home, drawn by the production `HomeWireBand`,
/// `HomeWireSlat` and `HomeWireReactions` on the `-cs_dev_no_photo` design
/// fixture (`HomeNoPhotoFixture`: labelled rows, local destinations, no reads).
///
/// **Recast 2026-10-01 for the Match Programme record** (`e8e9f84b`, then the
/// owner phone-feedback correction `1664d7cd`, `docs/home-phone-feedback-2026-09-30.md`).
/// One record per round, photograph or not: the golfer is its own control,
/// `home.round.person.<profile id>`; the round control, `home.round.<round id>`,
/// is the identity and the gross and speaks the complete record once; the
/// course, tee and story lines and any photograph sit under it, open the same
/// round, and are hidden from VoiceOver so nothing is said twice. A photograph
/// is a 16:9 insert below the facts and an absent one reserves no space. The
/// 168pt full-bleed band and its identifiers (`home.round.photo`,
/// `home.round.no-photo`) went with the design that had them, so the facts are
/// read here from the round control's label.
@MainActor final class HomeNoPhotoTests: XCTestCase {
  /// the fixture's own round (`is_me`, 89 at UNM Championship Course)
  private let yourRound = "home.round.A0000000-0000-4000-8000-000000000001"
  private let yourCard = "home.round.person.A0000000-0000-4000-8000-000000000011"

  /// The applause control directly under a round: the top of that round's
  /// supporting line.
  private func applauseBelow(_ round: XCUIElement, in app: XCUIApplication) -> CGRect? {
    let bottom = round.frame.maxY
    return app.buttons.matching(identifier: "applause.give").allElementsBoundByIndex
      .map { $0.frame }.filter { $0.minY >= bottom - 1 }.min { $0.minY < $1.minY }
  }

  @MainActor func testLoadedPhotoFaceAndRoundHaveDistinctDestinations() {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_no_photo", "-cs_dev_loaded_photo", "-cs_dev_text_size", "large", "-cs_dev_look", "none"]
    app.terminate(); app.launch()
    let round = app.buttons[yourRound]
    // the first launch on a freshly booted phone can take most of a minute:
    // 20s timed out there, the one first-launch flake (root's run and E's)
    XCTAssertTrue(round.waitForExistence(timeout: 60))
    // the loaded photograph is a 16:9 insert under the record's facts, at the
    // record's width (the fixture lays photo rounds edge to edge)
    let insert = app.frame.width * 9 / 16
    guard let applause = applauseBelow(round, in: app) else { return XCTFail("the round has no supporting line under it") }
    XCTAssertGreaterThanOrEqual(applause.minY - round.frame.maxY, insert, "the loaded photograph is not under the record")
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "Loaded photo control fixture"; shot.lifetime = .keepAlways; add(shot)
    // three doors on one record, and the photograph's fill never takes a tap
    // meant for the controls above it: the golfer opens the golfer …
    let person = app.buttons[yourCard]
    XCTAssertTrue(person.isHittable)
    XCTAssertFalse(person.frame.intersects(round.frame), "the golfer and the round share a target")
    person.tap()
    XCTAssertTrue(app.staticTexts["Golfer · You"].waitForExistence(timeout: 5))
    // … the round control opens the round …
    app.terminate(); app.launch()
    XCTAssertTrue(round.waitForExistence(timeout: 20))
    round.tap()
    XCTAssertTrue(app.staticTexts["Round · UNM Championship Course"].waitForExistence(timeout: 5))
    // … and so does the photograph: its centre sits the record's 12pt bottom
    // padding (`s3`) and half an insert above the supporting line
    app.terminate(); app.launch()
    XCTAssertTrue(round.waitForExistence(timeout: 20))
    guard let line = applauseBelow(round, in: app) else { return XCTFail("the round has no supporting line under it") }
    app.coordinate(withNormalizedOffset: .zero)
      .withOffset(CGVector(dx: app.frame.midX, dy: line.minY - 12 - insert / 2)).tap()
    XCTAssertTrue(app.staticTexts["Round · UNM Championship Course"].waitForExistence(timeout: 5))
  }

  @MainActor func testUnavailablePhotoKeepsReceiptPersonAndReactionDoors() {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_no_photo", "-cs_dev_failed_photo", "-cs_dev_text_size", "ax3", "-cs_dev_look", "none"]
    app.launch()
    let record = app.buttons[yourRound]
    XCTAssertTrue(record.waitForExistence(timeout: 20))
    XCTAssertTrue(record.isHittable)
    // the picture failed; the record did not — the score and the course are all there
    XCTAssertTrue(record.label.contains("89 at UNM Championship Course"), "an unavailable photo took facts with it")
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
    let golfer = app.scrollViews["home.no-photo.fixture"].firstMatch.buttons[yourCard]
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
    // `app.buttons["Close"]` matches the IDENTIFIER, and a toolbar
    // `Button("Close")` carries the word as its LABEL with no identifier — so
    // the subscript never found it. Match either, and say what the sheet
    // actually had if it is missing.
    // `app.buttons["Close"]` matches the IDENTIFIER, and the toolbar tertiary
    // carries the word as an UPPERCASED label with no identifier — so both the
    // subscript and a case-sensitive label match missed a control that was
    // there. Match the label case-insensitively.
    let close = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Close")).firstMatch
    XCTAssertTrue(close.waitForExistence(timeout: 5), "the applause people sheet has no Close")
    close.tap()
    remove.tap()
    XCTAssertTrue(app.buttons["Give applause"].firstMatch.waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["1 applause"].exists)
    XCTAssertTrue(app.buttons["Give applause"].firstMatch.exists)   // D365
  }

  /// D360 · the record's states, photographed in both appearances and at an
  /// accessibility size: the reference round, a milestone, a long course name
  /// with no handicap context, and the consequence case. The round control
  /// speaks what the visible lines print, from the same producers
  /// (`HomeWireCopy.roundLine` / `roundStory`): course and gross, then ONE
  /// supported story or none.
  @MainActor func testRecordStatesInBothAppearances() {
    for (appearance, size) in [("dark", "large"), ("light", "large"), ("dark", "ax3")] {
      let app = XCUIApplication()
      app.launchArguments = ["-cs_dev_no_photo", "-cs_dev_text_size", size, "-cs_dev_look", "none", "-cs_dev_appearance", appearance]
      app.launch()
      let reference = app.buttons[yourRound]
      XCTAssertTrue(reference.waitForExistence(timeout: 20))
      XCTAssertTrue(reference.label.contains("89 at UNM Championship Course"), "the course and the gross")
      XCTAssertTrue(reference.label.contains("2.0 over your playing HCP"), "the story is the handicap context")
      let milestone = app.buttons["home.round.A0000000-0000-4000-8000-000000000002"]
      XCTAssertTrue(milestone.label.contains("79 at Saguaro Flats"))
      XCTAssertTrue(milestone.label.contains("a personal best"), "a milestone says the milestone")
      let long = app.buttons["home.round.A0000000-0000-4000-8000-000000000003"]
      XCTAssertTrue(long.label.contains("108 at Gold Canyon — Dinosaur Mountain · Championship tees"), "a long course name, whole")
      XCTAssertFalse(long.label.contains("playing HCP"), "a story was invented for a round with no context")
      // TEN / W6 · the month's count, not a rank: the cap is its denominator
      let consequence = app.buttons["home.round.A0000000-0000-4000-8000-000000000004"]
      XCTAssertTrue(consequence.label.contains("9 pts · counting #2 of 4 this month"), "the consequence is the story when it is known")
      // the handicap story this round would otherwise carry, in its story form
      XCTAssertFalse(consequence.label.contains("Beat their playing HCP by 3.1"), "two stories on one round")
      let shot = XCTAttachment(screenshot: app.screenshot())
      shot.name = "record-states-\(appearance)-\(size)"; shot.lifetime = .keepAlways; add(shot)
      app.terminate()
    }
  }

  @MainActor func testRecordAndGolferHaveSeparateWorkingDoors() {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_no_photo", "-cs_dev_text_size", "large", "-cs_dev_look", "none"]
    app.launch()
    let record = app.buttons[yourRound]
    XCTAssertTrue(record.waitForExistence(timeout: 20))
    XCTAssertTrue(record.isHittable)
    let golfer = app.scrollViews["home.no-photo.fixture"].firstMatch.buttons[yourCard]
    XCTAssertTrue(golfer.isHittable)
    XCTAssertGreaterThanOrEqual(golfer.frame.width, 44 - 0.5, "the golfer is under the tap target")
    XCTAssertGreaterThanOrEqual(golfer.frame.height, 44 - 0.5, "the golfer is under the tap target")
    XCTAssertFalse(record.frame.intersects(golfer.frame), "the golfer and the round share a target")
    record.tap()
    XCTAssertTrue(app.staticTexts["Round · UNM Championship Course"].waitForExistence(timeout: 5))
    app.terminate()
    app.launch()
    XCTAssertTrue(golfer.waitForExistence(timeout: 20))
    golfer.tap()
    XCTAssertTrue(app.staticTexts["Golfer · You"].waitForExistence(timeout: 5))
  }
}
