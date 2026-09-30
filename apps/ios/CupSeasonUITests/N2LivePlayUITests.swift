import XCTest

/// F07 · at the accessibility sizes the live sheet leads with the hole and
/// the golfers' scoring; the course, tee and rating wait behind a named
/// disclosure, and the sync truth is never hidden.
///
/// The live sheet has no synthetic-world route yet, so this drives the
/// existing DEBUG review fixture (`-cs_dev_morning_review`): the real
/// `LivePlayView` over a seeded four-ball on the 15th, online (`live`) and
/// held on the phone (`offline`). It is never combined with the synthetic
/// seam, and nothing it draws leaves the simulator.
final class N2LivePlayUITests: XCTestCase {
  override func setUp() { continueAfterFailure = false }

  @MainActor private func launch(_ scene: String, size: String, theme: String = "dark") -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_morning_review", "-cs_review_scene", scene, "-cs_dev_appearance", theme,
                           "-cs_dev_look", "none", "-cs_dev_text_size", size]
    app.launch()
    return app
  }

  private func attach(_ app: XCUIApplication, _ name: String) {
    let s = XCTAttachment(screenshot: app.screenshot()); s.name = name; s.lifetime = .keepAlways; add(s)
  }

  @MainActor func testF07AtAX3TheFirstScoringControlsComeBeforeTheCourseLine() {
    for scene in ["live", "offline"] {
      let app = launch(scene, size: "AX3")
      let minus = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Minus, ")).firstMatch
      XCTAssertTrue(minus.waitForExistence(timeout: 20), "\(scene): the first golfer's scoring is drawn")
      let window = app.windows.firstMatch.frame
      // reachable without scrolling: the first − and + sit inside the first view
      XCTAssertTrue(minus.isHittable, "\(scene): the first − needs no scroll at AX3")
      XCTAssertLessThanOrEqual(minus.frame.maxY, window.maxY, "\(scene): the first − is on the first screen")
      let plus = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Plus, ")).firstMatch
      XCTAssertTrue(plus.isHittable, "\(scene): the first + needs no scroll at AX3")
      // the hole leads, the course line is disclosed
      let next = app.buttons["Next hole"]
      XCTAssertTrue(next.exists && next.frame.maxY <= minus.frame.minY + 1, "\(scene): the hole comes before the golfers")
      let details = app.descendants(matching: .any)["live.round.details"].firstMatch
      XCTAssertTrue(details.exists, "\(scene): the course and tee sit behind a named disclosure")
      XCTAssertFalse(app.staticTexts["live.round.place"].exists, "\(scene): the course line is not drawn until asked for")
      // the sync truth is never disclosed away
      if scene == "offline" {
        XCTAssertTrue(app.staticTexts["live.sync.status"].exists, "offline: the sheet says the round is held on this phone")
        XCTAssertTrue(app.staticTexts["live.sync.status"].frame.maxY <= minus.frame.minY, "offline: the sync truth leads")
      }
      attach(app, "f07-\(scene)-AX3")
      // the disclosure opens onto the course, tee and rating
      for _ in 0..<6 where !details.isHittable { app.swipeUp() }
      details.tap()
      XCTAssertTrue(app.staticTexts["live.round.place"].waitForExistence(timeout: 5), "\(scene): the disclosure shows the course line")
      XCTAssertTrue(app.staticTexts["live.round.place"].label.localizedCaseInsensitiveContains("Encanto"))
      attach(app, "f07-\(scene)-AX3-details")
      app.terminate()
    }
  }

  @MainActor func testF07AtTheDefaultSizeTheSheetIsUnchanged() {
    let app = launch("live", size: "large")
    let minus = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Minus, ")).firstMatch
    XCTAssertTrue(minus.waitForExistence(timeout: 20))
    XCTAssertFalse(app.descendants(matching: .any)["live.round.details"].exists, "no disclosure at the reading sizes")
    XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@", "Encanto")).firstMatch.exists,
                  "the course line stays in the eyebrow at the reading sizes")
    attach(app, "f07-live-large")
  }

  /// TEN / W6 (critique A2, P1) · **"Change setup" holds the round.** Three
  /// holes scored, then Change setup: the setup says the round is still on
  /// and puts the way back on the first screen, with no Tee off (a new round)
  /// and no local-scoring switch; "Back to the round" returns to the same
  /// round, on the same hole, with the same three scores. A new round would
  /// have come back blank.
  @MainActor func testChangeSetupHoldsTheRoundAndItsScores() {
    let app = launch("live", size: "large")
    let plus = app.buttons["Plus, You"]
    XCTAssertTrue(plus.waitForExistence(timeout: 20), "the live sheet is up")
    let row = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "You, hole ")).firstMatch
    var said: [String] = []
    for k in 0..<3 {
      plus.tap()
      XCTAssertTrue(row.waitForExistence(timeout: 5), "the golfer's row says the hole")
      said.append(row.label)
      if k < 2 { app.buttons["Next hole"].tap() }
    }
    XCTAssertEqual(said.filter { $0.contains("not scored") }, [], "three holes scored — \(said)")
    // the eyebrow's door is set in agate caps, and its label reads as set
    app.buttons.matching(NSPredicate(format: "label ==[c] %@", "change setup")).firstMatch.tap()
    let held = app.staticTexts["live.setup.held"]
    XCTAssertTrue(held.waitForExistence(timeout: 10), "the setup says the round is held")
    XCTAssertTrue(held.label.hasPrefix("Your round is still on, and its "), held.label)
    XCTAssertTrue(held.label.hasSuffix("To change them, scrap this round and tee off again."), held.label)
    // W7-003 · the record-bearing setup is shown locked: the finish posts on
    // the tee-off snapshot, so nothing here may be offered as an edit
    for id in ["live.setup.tee", "live.setup.rating", "live.setup.slope"] {
      let field = app.textFields[id]
      XCTAssertTrue(field.exists && !field.isEnabled, "\(id) is locked while the round is held")
    }
    // W7-003r · the card note's setup guidance stands down beside the lock
    XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "par-72")).firstMatch.exists,
                   "no card note while the round is held")
    XCTAssertFalse(app.buttons["9 holes"].firstMatch.isEnabled, "the holes are locked while held")
    XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label ==[c] %@", "enter the pars")).firstMatch.isEnabled,
                   "the pars are locked while held")
    XCTAssertFalse(app.buttons["live.setup.teeOff"].exists, "no Tee off over a held round")
    XCTAssertFalse(app.switches["live.setup.offline"].exists, "no switch to a second, local round")
    let back = app.buttons["live.setup.backToRound"]
    XCTAssertTrue(back.exists && back.isHittable, "the way back is on the first screen")
    XCTAssertLessThanOrEqual(back.frame.maxY, app.windows.firstMatch.frame.maxY, "the way back needs no scroll")
    attach(app, "w6-held-setup")
    back.tap()
    // the same round: the hole it was left on, and the three scores, back to front
    XCTAssertTrue(plus.waitForExistence(timeout: 10), "back on the live sheet")
    XCTAssertEqual(row.label, said[2], "the hole it was left on, with its score")
    for k in [1, 0] {
      app.buttons["Previous hole"].tap()
      XCTAssertEqual(row.label, said[k], "the same score on the earlier hole")
    }
    attach(app, "w6-held-back")
  }
}
