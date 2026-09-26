import XCTest

final class SocialBlendTests: XCTestCase {
  @MainActor private func launch(_ scene: String = "course", appearance: String = "dark", size: String = "large", arguments: [String] = []) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_social_review", "-cs_dev_appearance", appearance,
      "-cs_dev_look", "none", "-cs_dev_text_size", size]
    if scene == "activity" { app.launchArguments.append("-cs_social_activity") }
    if scene == "comments" { app.launchArguments.append("-cs_social_comments") }
    if scene == "receipt" { app.launchArguments.append("-cs_social_receipt") }
    app.launchArguments += arguments
    app.launch()
    if scene == "course" {
      let courses = app.buttons["home.courses"]
      XCTAssertTrue(courses.waitForExistence(timeout: 15)); courses.tap()
      let course = app.buttons["courses.open.fixture-north-grove"]
      XCTAssertTrue(course.waitForExistence(timeout: 15))
      capture(app, "courses-home-" + appearance)
      course.tap()
    }
    return app
  }
  @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
    let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = name; shot.lifetime = .keepAlways; add(shot)
  }

  @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
    for _ in 0..<8 {
      if element.isHittable { return }
      app.swipeUp()
    }
  }

  @MainActor func testReceiptKeepsCourseWhenScoringCardOmitsItsID() {
    let app = launch("receipt")
    let course = app.buttons["round.course"]
    XCTAssertTrue(course.waitForExistence(timeout: 15))
    reveal(course, in: app)
    capture(app, "receipt-course-door")
    course.tap()
    XCTAssertTrue(app.buttons["course.social.tee"].waitForExistence(timeout: 10))
    XCTAssertTrue(app.buttons["course.golfer.11111111-1111-4111-8111-111111111111"].exists)
  }

  @MainActor func testFriendReceiptOpensCourseWithoutLeagueScoringAccess() {
    let app = launch("receipt", arguments: ["-cs_social_card_unavailable"])
    let course = app.buttons["round.course"]
    XCTAssertTrue(course.waitForExistence(timeout: 15))
    reveal(course, in: app); course.tap()
    XCTAssertTrue(app.buttons["course.social.tee"].waitForExistence(timeout: 10))
  }

  @MainActor func testReceiptCourseLinkRespondsAcrossTheRow() {
    let app = launch("receipt")
    let course = app.buttons["round.course"]
    XCTAssertTrue(course.waitForExistence(timeout: 15))
    reveal(course, in: app)
    course.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.5)).tap()
    XCTAssertTrue(app.buttons["course.social.tee"].waitForExistence(timeout: 10))
  }

  @MainActor func testReceiptDoesNotInventCourseFromItsLabel() {
    let app = launch("receipt", arguments: ["-cs_social_course_missing"])
    XCTAssertTrue(app.textFields["round.comment.draft"].waitForExistence(timeout: 15))
    XCTAssertFalse(app.buttons["round.course"].exists)
  }

  @MainActor func testUnavailableRoundCannotOpenItsCourse() {
    let app = launch("receipt", arguments: ["-cs_social_round_unavailable"])
    XCTAssertTrue(app.staticTexts["Couldn’t load this round."].waitForExistence(timeout: 15))
    XCTAssertFalse(app.buttons["round.course"].exists)
    XCTAssertFalse(app.textFields["round.comment.draft"].exists)
  }

  @MainActor func testCourseSearchOpensUnsavedCoursePageAtAccessibilitySize() {
    let app = launch("search", size: "accessibility3")
    let courses = app.buttons["home.courses"]
    XCTAssertTrue(courses.waitForExistence(timeout: 15)); courses.tap()
    let search = app.textFields["courses.search"]
    XCTAssertTrue(search.waitForExistence(timeout: 10))
    search.tap(); search.typeText("North")
    let course = app.buttons["courses.search.fixture-north-grove"]
    XCTAssertTrue(course.waitForExistence(timeout: 10)); course.tap()
    let tee = app.buttons["course.social.tee"]
    XCTAssertTrue(tee.waitForExistence(timeout: 10)); reveal(tee, in: app)
    capture(app, "course-real-page-ax3")
    app.swipeUp()
    capture(app, "course-best-ax3")
    let person = app.buttons["course.golfer.11111111-1111-4111-8111-111111111111"]
    reveal(person, in: app)
    capture(app, "course-golfers-ax3")
    XCTAssertTrue(person.isHittable); person.tap()
    XCTAssertTrue(app.buttons["course.round.22222222-2222-4222-8222-222222222222"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.staticTexts["Nothing is kept on this phone yet."].exists)
  }

  @MainActor func testCourseGolferHistoryOpensSourceRound() {
    let app = launch(appearance: "light")
    let person = app.buttons["course.golfer.11111111-1111-4111-8111-111111111111"]
    XCTAssertTrue(person.waitForExistence(timeout: 15))
    capture(app, "course-light")
    reveal(person, in: app)
    person.tap()
    let round = app.buttons["course.round.22222222-2222-4222-8222-222222222222"]
    XCTAssertTrue(round.waitForExistence(timeout: 5)); round.tap()
    XCTAssertTrue(app.staticTexts["THE ROUND"].waitForExistence(timeout: 5))
    capture(app, "course-source-round")
  }

  @MainActor func testNineHoleSelectionDoesNotKeepEighteenHoleBest() {
    let app = launch()
    XCTAssertTrue(app.buttons["course.social.tee"].waitForExistence(timeout: 15))
    reveal(app.buttons["18 holes"], in: app)
    app.buttons["18 holes"].tap()
    app.buttons["9 holes"].tap()
    XCTAssertTrue(app.staticTexts["Nines aren't compared: which nine was played isn't recorded. They stay in each golfer's history."].waitForExistence(timeout: 5))
    XCTAssertFalse(app.staticTexts["YOUR CIRCLE BEST"].exists)
    capture(app, "course-nine-empty")
  }

  @MainActor func testPostedCommentReportsItsIdentityAndBlocksItsAuthor() {
    let app = launch("comments")
    let actions = app.buttons["Actions for Theo Park’s comment"]
    XCTAssertTrue(actions.waitForExistence(timeout: 15)); actions.tap()
    app.buttons["Report comment"].tap()
    let reason = app.buttons["Harassment or abuse"]
    XCTAssertTrue(reason.waitForExistence(timeout: 5)); reason.tap()
    app.buttons["SEND REPORT"].tap()
    XCTAssertTrue(actions.waitForExistence(timeout: 5)); actions.tap()
    app.buttons["Block Theo"].tap()
    XCTAssertTrue(app.staticTexts["This conversation is no longer available."].waitForExistence(timeout: 5))
    XCTAssertFalse(app.textFields["round.comment.draft"].exists)
  }

  @MainActor func testFailedCommentPreservesDraftThenReplyPosts() {
    let app = launch("comments")
    let draft = app.textFields["round.comment.draft"]
    XCTAssertTrue(draft.waitForExistence(timeout: 15))
    draft.tap(); draft.typeText("Offline check")
    app.buttons["round.comment.send"].tap()
    XCTAssertEqual(draft.value as? String, "Offline check")
    capture(app, "comment-draft-retained")
    draft.tap(); draft.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 13))
    draft.typeText("Great round!")
    app.buttons["round.comment.send"].tap()
    XCTAssertTrue(app.staticTexts["Great round!"].waitForExistence(timeout: 5))
    capture(app, "comment-posted")
  }

  @MainActor func testActivityOpensExactCommentAtLargeType() {
    let app = launch("activity", size: "AX3")
    let notice = app.buttons["activity.44444444-4444-4444-8444-444444444444"]
    XCTAssertTrue(notice.waitForExistence(timeout: 15))
    capture(app, "activity-AX3")
    notice.tap()
    let comment = app.staticTexts.matching(identifier: "round.comment.33333333-3333-4333-8333-333333333333")
      .matching(NSPredicate(format: "label == %@", "Did the putt on 18 drop?")).firstMatch
    XCTAssertTrue(comment.waitForExistence(timeout: 10))
    let visible = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: comment)
    XCTAssertEqual(XCTWaiter.wait(for: [visible], timeout: 5), .completed)
    capture(app, "notification-comment-AX3")
  }
}
