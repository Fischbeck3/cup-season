import XCTest

final class SocialBlendTests: XCTestCase {
  @MainActor private func launch(_ scene: String = "course", appearance: String = "dark", size: String = "large") -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_social_review", "-cs_dev_appearance", appearance,
      "-cs_dev_look", "none", "-cs_dev_text_size", size]
    if scene == "activity" { app.launchArguments.append("-cs_social_activity") }
    if scene == "comments" { app.launchArguments.append("-cs_social_comments") }
    app.launch(); return app
  }
  @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
    let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = name; shot.lifetime = .keepAlways; add(shot)
  }

  @MainActor func testCourseGolferHistoryOpensSourceRound() {
    let app = launch(appearance: "light")
    let person = app.buttons["course.golfer.11111111-1111-4111-8111-111111111111"]
    XCTAssertTrue(person.waitForExistence(timeout: 15))
    capture(app, "course-light")
    person.tap()
    let round = app.buttons["course.round.22222222-2222-4222-8222-222222222222"]
    XCTAssertTrue(round.waitForExistence(timeout: 5)); round.tap()
    XCTAssertTrue(app.staticTexts["THE ROUND"].waitForExistence(timeout: 5))
    capture(app, "course-source-round")
  }

  @MainActor func testNineHoleSelectionDoesNotKeepEighteenHoleBest() {
    let app = launch()
    XCTAssertTrue(app.buttons["course.social.tee"].waitForExistence(timeout: 15))
    app.buttons["18 holes"].tap()
    app.buttons["9 holes"].tap()
    XCTAssertTrue(app.staticTexts["Nines aren't compared: which nine was played isn't recorded. They stay in each golfer's history."].waitForExistence(timeout: 5))
    XCTAssertFalse(app.staticTexts["YOUR CIRCLE BEST"].exists)
    capture(app, "course-nine-empty")
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
