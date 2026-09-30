import XCTest

final class N2DoorUITests: N2UITestCase {
  @MainActor func testQ5BuildIsHiddenUntilThePennantIsHeld() {
    let app = launch("signed-out", "door")
    _ = root(app, "door")
    XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "v1 · build")).firstMatch.exists)
    let pennant = app.descendants(matching: .any)["door.buildReveal"].firstMatch
    XCTAssertTrue(pennant.waitForExistence(timeout: 10))
    pennant.press(forDuration: 1)
    XCTAssertTrue(app.alerts["Build"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.alerts["Build"].staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "v1 · build")).firstMatch.exists)
    app.alerts["Build"].buttons["Close"].tap()
    XCTAssertFalse(app.alerts["Build"].exists)
  }

  // MARK: R02 · the Door

  /// The email action names what it does, one fact sits beside it, and every
  /// field keeps its name before and after typing (F01's Email check, applied
  /// to the code and league-code fields). The code stays eight digits.
  @MainActor func testR02TheDoorSendsACodeAndNamesEveryField() {
    let app = launch("signed-out", "door")
    _ = root(app, "door")
    let signIn = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Sign in")).firstMatch
    XCTAssertTrue(signIn.waitForExistence(timeout: 15))
    signIn.tap()
    let email = app.textFields["Email"]
    XCTAssertTrue(email.waitForExistence(timeout: 10), "F01 · the email field is named")
    let send = app.buttons["door.email.send"]
    XCTAssertTrue(send.exists)
    XCTAssertEqual(send.label, "Send code")
    XCTAssertFalse(app.buttons["Continue with email"].exists)
    XCTAssertTrue(app.staticTexts["No password needed."].exists)
    XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'One code'")).firstMatch.exists,
                   "the code is said once, on the button")
    email.tap(); email.typeText("avery@example.invalid")
    XCTAssertTrue(app.textFields["Email"].exists, "still named after typing")
    for _ in 0..<3 where !send.isHittable { app.swipeUp() }
    XCTAssertTrue(send.isHittable, "Send code clears the keyboard")
    attach(app, "r02-door-email-typed")
    // the league code field, named before and after typing
    let have = app.buttons["I have a code"]
    if have.exists {
      for _ in 0..<3 where !have.isHittable { app.swipeUp() }
      have.tap()
      let league = app.textFields["League code"]
      XCTAssertTrue(league.waitForExistence(timeout: 5))
      league.typeText("FIXTURE24")
      XCTAssertTrue(app.textFields["League code"].exists, "the league code keeps its name when filled")
    }
    app.terminate()

    // the code stage: the field is named, empty and typed, and takes past six digits
    let code = XCUIApplication()
    code.launchArguments = ["-cs_dev_synthetic", "signed-out", "-cs_dev_open", "door", "-cs_dev_appearance", "dark",
                            "-cs_dev_look", "none", "-cs_dev_text_size", "large",
                            "-cs_dev_email", "avery@example.invalid", "-cs_dev_code", ""]
    code.launch()
    let again = code.buttons.matching(NSPredicate(format: "label ==[c] %@", "Sign in")).firstMatch
    XCTAssertTrue(again.waitForExistence(timeout: 15))
    again.tap()
    let field = code.textFields.matching(NSPredicate(format: "label CONTAINS[c] %@", "digits")).firstMatch
    XCTAssertTrue(field.waitForExistence(timeout: 10), "the code field is named before typing")
    XCTAssertFalse(field.label.isEmpty)
    field.tap(); field.typeText("1234567")
    let typed = code.textFields.matching(NSPredicate(format: "label CONTAINS[c] %@", "digits")).firstMatch
    XCTAssertTrue(typed.exists, "and after typing")
    XCTAssertEqual((typed.value as? String)?.count, 7, "no six-digit cap: the code is eight digits")
    attach(code, "r02-door-code-typed")
  }
}
