import XCTest

final class CoursePrepReviewTests: XCTestCase {
  @MainActor func testSaveBajamarThenUseItWithoutNetwork() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_open", "live", "-cs_dev_look", "none", "-cs_dev_appearance", "light"]
    app.launch()
    let open = app.buttons["offline.courses.open"]
    XCTAssertTrue(open.waitForExistence(timeout: 30)); open.tap()
    let field = app.textFields["offline.course.search"]
    XCTAssertTrue(field.waitForExistence(timeout: 10)); field.tap(); field.typeText("Bajamar")
    let course = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Bajamar")).firstMatch
    XCTAssertTrue(course.waitForExistence(timeout: 30)); course.tap()
    let black = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Black")).firstMatch
    XCTAssertTrue(black.waitForExistence(timeout: 10)); black.tap()
    app.swipeUp()
    let save = app.buttons["offline.course.save"]
    XCTAssertTrue(save.waitForExistence(timeout: 10)); save.tap()
    let finished = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == true"), object: save)
    XCTAssertEqual(XCTWaiter.wait(for: [finished], timeout: 40), .completed)
    let ready = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@", "Ready offline · 18 holes")).firstMatch
    XCTAssertTrue(ready.waitForExistence(timeout: 30))
    capture(app, "course-prep-bajamar-light")
    app.terminate()

    app.launchArguments = ["-cs_dev_offline_network", "-cs_dev_look", "none", "-cs_dev_appearance", "dark"]
    app.launch()
    let door = app.buttons.matching(NSPredicate(format: "label =[c] %@", "Score on this phone")).firstMatch
    XCTAssertTrue(door.waitForExistence(timeout: 30)); door.tap()
    XCTAssertTrue(open.waitForExistence(timeout: 15)); open.tap()
    let saved = app.buttons["offline.course.100"]
    XCTAssertTrue(saved.waitForExistence(timeout: 10))
    for _ in 0..<6 where !saved.isHittable { app.swipeUp() }
    capture(app, "course-prep-saved-list-dark-offline")
    saved.tap()
    app.swipeDown()
    let use = app.buttons.matching(NSPredicate(format: "label =[c] %@", "Use Black tees")).firstMatch
    for _ in 0..<12 where !use.isHittable { app.swipeUp() }
    XCTAssertTrue(use.isHittable)
    capture(app, "course-prep-ready-dark-offline")
    use.tap()
    let loaded = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Card loaded:")).firstMatch
    XCTAssertTrue(loaded.waitForExistence(timeout: 10))
    capture(app, "course-prep-selected-offline")
    app.terminate() // No tee-off, score, round or competition writes.
  }
  @MainActor func testSavedCoursePreparationAtAccessibilitySize() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_offline_network", "-cs_dev_look", "none", "-cs_dev_appearance", "light", "-cs_dev_text_size", "AX3"]
    app.launch()
    let door = app.buttons.matching(NSPredicate(format: "label =[c] %@", "Score on this phone")).firstMatch
    XCTAssertTrue(door.waitForExistence(timeout: 30))
    for _ in 0..<8 where !door.isHittable { app.swipeUp() }
    door.tap()
    let open = app.buttons["offline.courses.open"]
    XCTAssertTrue(open.waitForExistence(timeout: 15))
    for _ in 0..<8 where !open.isHittable { app.swipeUp() }
    open.tap()
    let saved = app.buttons["offline.course.100"]
    XCTAssertTrue(saved.waitForExistence(timeout: 15))
    for _ in 0..<12 where !saved.isHittable { app.swipeUp() }
    XCTAssertTrue(saved.isHittable); saved.tap()
    let use = app.buttons.matching(NSPredicate(format: "label =[c] %@", "Use Black tees")).firstMatch
    for _ in 0..<25 where !use.isHittable { app.swipeUp() }
    XCTAssertTrue(use.isHittable)
    capture(app, "course-prep-AX3-light-offline")
    app.terminate()
  }
  @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
    let s = XCTAttachment(screenshot: app.screenshot()); s.name = name; s.lifetime = .keepAlways; add(s)
  }
}

final class CompeteGameplayReviewTests: XCTestCase {
  @MainActor func testRealCompeteSeasonAndCreationDoors() throws {
    let app = XCUIApplication()
    for room in ["light", "dark"] {
      app.launchArguments = ["-cs_dev_open", "compete", "-cs_dev_look", "none", "-cs_dev_appearance", room]
      app.launch()
      let row = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH %@", "compete.row.")).firstMatch.buttons.firstMatch
      XCTAssertTrue(row.waitForExistence(timeout: 30)); capture(app, "compete-real-" + room)
      row.tap()
      let back = app.buttons["Back"].firstMatch
      XCTAssertTrue(back.waitForExistence(timeout: 15)); settle()
      capture(app, "season-real-" + room)
      app.swipeUp(); capture(app, "season-real-lower-" + room)
      back.tap()
      let create = app.buttons.matching(NSPredicate(format: "label =[c] %@", "Start something")).firstMatch
      for _ in 0..<6 where !create.isHittable { app.swipeUp() }
      XCTAssertTrue(create.isHittable); create.tap()
      let choice = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Run a season")).firstMatch
      XCTAssertTrue(choice.waitForExistence(timeout: 10)); capture(app, "compete-intent-" + room)
      for _ in 0..<5 where !choice.isHittable { app.swipeUp() }
      choice.tap(); settle()
      capture(app, "compete-season-setup-" + room)
      app.terminate()
    }
  }
  @MainActor func testGameplayRoomsWithLabeledFixtures() throws {
    let app = XCUIApplication()
    for room in ["light", "dark"] {
      for kind in ["ryder", "callout", "major"] {
        app.launchArguments = ["-cs_dev_open", "ryder", "-cs_dev_event_fixture", kind,
                               "-cs_dev_look", "none", "-cs_dev_appearance", room]
        app.launch()
        let back = app.buttons["Back"].firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 30)); settle()
        capture(app, "compete-" + kind + "-fixture-" + room)
        app.swipeUp(); capture(app, "compete-" + kind + "-fixture-lower-" + room)
        app.terminate()
      }
    }
  }
  @MainActor func testRulesAndHeadToHeadDoors() throws {
    let app = XCUIApplication()
    for place in ["rules", "lengths", "events", "callout_sheet"] {
      app.launchArguments = ["-cs_dev_open", place, "-cs_dev_look", "none", "-cs_dev_appearance", "dark"]
      app.launch(); settle(8)
      capture(app, "compete-" + place + "-real-dark")
      app.swipeUp(); capture(app, "compete-" + place + "-real-lower-dark")
      app.terminate()
    }
  }
  @MainActor func testLargeTextCompetitionHeaders() throws {
    let app = XCUIApplication()
    for place in ["season", "ryder", "callout", "major"] {
      app.launchArguments = ["-cs_dev_open", place == "season" ? "season" : "ryder",
                             "-cs_dev_look", "none", "-cs_dev_text_size", "AX3",
                             "-cs_dev_appearance", place == "season" ? "light" : "dark"]
      if place != "season" { app.launchArguments += ["-cs_dev_event_fixture", place] }
      app.launch()
      let back = app.buttons["Back"].firstMatch
      XCTAssertTrue(back.waitForExistence(timeout: 30)); settle(3)
      if place != "callout" {
        let title = app.staticTexts[place == "season" ? "season.title" : "event.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 15))
        XCTAssertGreaterThanOrEqual(title.frame.minX, app.frame.minX)
        XCTAssertLessThanOrEqual(title.frame.maxX, app.frame.maxX)
      }
      XCTAssertTrue(back.isHittable)
      capture(app, "compete-" + place + "-AX3")
      app.swipeUp(); capture(app, "compete-" + place + "-AX3-lower")
      app.terminate()
    }
  }
  @MainActor func testLargeTextRyderRosterReachesBothTeams() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_open", "ryder", "-cs_dev_event_fixture", "ryder",
                           "-cs_dev_look", "none", "-cs_dev_text_size", "AX3", "-cs_dev_appearance", "dark"]
    app.launch()
    let roster = app.scrollViews["event.side-roster"]
    XCTAssertTrue(roster.waitForExistence(timeout: 30)); settle()
    XCTAssertTrue(roster.isHittable)
    roster.swipeLeft()
    let right = app.otherElements.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Coyotes:")).firstMatch
    XCTAssertTrue(right.exists)
    XCTAssertGreaterThanOrEqual(right.frame.minX, app.frame.minX)
    XCTAssertLessThanOrEqual(right.frame.maxX, app.frame.maxX)
    capture(app, "compete-ryder-AX3-roster-right")
    app.terminate()
  }
  @MainActor func testSeasonSelectedLookInBothRooms() throws {
    let app = XCUIApplication()
    for room in ["light", "dark"] {
      app.launchArguments = ["-cs_dev_open", "season", "-cs_dev_look", "oldest", "-cs_dev_appearance", room]
      app.launch()
      XCTAssertTrue(app.staticTexts["season.title"].waitForExistence(timeout: 30)); settle()
      capture(app, "season-selected-look-" + room)
      app.terminate()
    }
  }
  @MainActor private func settle(_ seconds: Double = 2) {
    let ready = expectation(description: "presentation settled")
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { ready.fulfill() }
    wait(for: [ready], timeout: seconds + 3)
  }
  @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
    let s = XCTAttachment(screenshot: app.screenshot()); s.name = name; s.lifetime = .keepAlways; add(s)
  }
}
