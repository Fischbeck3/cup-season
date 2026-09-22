import XCTest

final class VisualEntranceTests: XCTestCase {
  @MainActor func testInvitedWelcomeKeepsContextAndEmailDoorReachable() {
    for (theme, size) in [("dark", "large"), ("light", "AX3")] {
      let app = XCUIApplication()
      app.launchArguments = ["-cs_dev_pending_join", "-cs_dev_look", "none",
                             "-cs_dev_appearance", theme, "-cs_dev_text_size", size]
      app.launch()
      let context = app.staticTexts["door.context"]
      XCTAssertTrue(context.waitForExistence(timeout: 20))
      XCTAssertEqual(context.label, "You're joining QA season. Sign in to review and join.")
      XCTAssertLessThanOrEqual(context.frame.maxX, app.frame.maxX)
      let signIn = app.buttons.matching(NSPredicate(format: "label =[c] %@", "Sign in")).firstMatch
      for _ in 0..<5 where !signIn.isHittable { app.swipeUp() }
      XCTAssertTrue(signIn.isHittable)
      capture(app, "invited-welcome-\(theme)-\(size)")
      signIn.tap()
      XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 10))
      // Showing context must not consume the invitation or replace the auth flow.
      XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "You're joining QA season.")).firstMatch.exists)
      let continueButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Continue with email")).firstMatch
      for _ in 0..<5 where !continueButton.isHittable { app.swipeUp() }
      XCTAssertTrue(continueButton.isHittable)
      capture(app, "invited-email-\(theme)-\(size)")
      app.terminate()
    }
  }

  @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
  }
}
