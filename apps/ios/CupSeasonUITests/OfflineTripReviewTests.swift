import XCTest

final class OfflineTripReviewTests: XCTestCase {
  @MainActor func testScoreRelaunchAndKeepLocalRound() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_offline_trip", "-cs_dev_offline_owner", UUID().uuidString, "-cs_dev_offline_network", "-cs_dev_look", "none", "-cs_dev_appearance", "dark"]
    app.launch()
    let teeOff = app.buttons.matching(NSPredicate(format: "label =[c] %@", "Tee off")).firstMatch
    if teeOff.waitForExistence(timeout: 5) {
      for _ in 0..<5 where !teeOff.isHittable { app.swipeUp() }
      XCTAssertTrue(teeOff.isHittable); teeOff.tap()
    }
    let plus = app.buttons["Plus, Offline QA golfer"]
    XCTAssertTrue(plus.waitForExistence(timeout: 15))
    XCTAssertTrue(plus.isHittable)
    let next = app.buttons["Next hole"]
    for hole in 0..<9 { plus.tap(); if hole < 8 { next.tap() } }
    capture(app, "offline-live-scoring-fixture")
    app.terminate(); app.launch()
    XCTAssertTrue(plus.waitForExistence(timeout: 15), "Local scorecard must resume after process death")
    capture(app, "offline-relaunched-fixture")
    next.tap()
    for hole in 9..<18 { plus.tap(); if hole < 17 { next.tap() } }
    capture(app, "offline-complete-18-fixture")
    let keep = app.buttons.matching(NSPredicate(format: "label =[c] %@", "Keep round on this phone")).firstMatch
    for _ in 0..<6 where !keep.isHittable { app.swipeUp() }
    XCTAssertTrue(keep.isHittable); keep.tap()
    let confirm = app.buttons.matching(NSPredicate(format: "label =[c] %@", "Keep round on this phone")).element(boundBy: app.buttons.matching(NSPredicate(format: "label =[c] %@", "Keep round on this phone")).count - 1)
    XCTAssertTrue(confirm.waitForExistence(timeout: 5)); confirm.tap()
    XCTAssertTrue(teeOff.waitForExistence(timeout: 10))
    let notice = app.descendants(matching: .any).matching(identifier: "cs.toast").firstMatch
    if notice.waitForExistence(timeout: 1) {
      XCTAssertLessThan(notice.frame.height, app.frame.height * 0.4, "Confirmation must not cover the scorecard")
      let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: notice)
      XCTAssertEqual(XCTWaiter.wait(for: [gone], timeout: 5), .completed)
    }
    app.swipeUp()
    capture(app, "offline-kept-round-fixture")
    app.terminate()
  }
  @MainActor func testBajamarLookupWithoutStartingRound() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_open_play", "-cs_dev_look", "none", "-cs_dev_appearance", "dark"]
    app.launch()
    let live = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Score it live")).firstMatch
    if !live.waitForExistence(timeout: 5) {
      let play = app.buttons["Play"].firstMatch
      XCTAssertTrue(play.waitForExistence(timeout: 25)); play.tap()
    }
    XCTAssertTrue(live.waitForExistence(timeout: 10)); live.tap()
    let field = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS[c] %@", "Search a course")).firstMatch
    XCTAssertTrue(field.waitForExistence(timeout: 20)); field.tap(); field.typeText("Bajamar")
    let course = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Bajamar")).firstMatch
    if course.waitForExistence(timeout: 30) {
      capture(app, "bajamar-actual-course-search")
      course.tap()
      capture(app, "bajamar-actual-tee-options")
      let black = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Black")).firstMatch
      XCTAssertTrue(black.waitForExistence(timeout: 10)); black.tap()
      // Wait for the actual course card to load, not just a selected tee label.
      let loaded = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Card loaded:")).firstMatch
      XCTAssertTrue(loaded.waitForExistence(timeout: 30))
      app.swipeUp()
      capture(app, "bajamar-prepared-course")
    } else {
      capture(app, "bajamar-course-search-unavailable")
    }
    // No Tee off, no new round, no scores, no photo or invitation writes.
    app.terminate()
  }

  @MainActor func testOfflineColdBootOffersScoringToRestoredAccount() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_offline_network", "-cs_dev_look", "none", "-cs_dev_appearance", "dark"]
    app.launch()
    let offline = app.buttons.matching(NSPredicate(format: "label =[c] %@", "Score on this phone")).firstMatch
    XCTAssertTrue(offline.waitForExistence(timeout: 30), "Previously signed-in golfer must reach the offline door without a successful bootstrap")
    capture(app, "offline-cold-boot-real-account")
    offline.tap()
    let start = app.buttons.matching(NSPredicate(format: "label =[c] %@", "Tee off")).firstMatch
    XCTAssertTrue(start.waitForExistence(timeout: 15))
    capture(app, "offline-setup-real-account")
    // No score is entered on the real account.
    app.terminate()
  }

  @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
    let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = name; shot.lifetime = .keepAlways; add(shot)
  }
}
