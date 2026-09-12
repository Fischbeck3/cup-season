import XCTest

final class ReturnFlowReviewTests: XCTestCase {
  @MainActor func testSignInTopoStaysVisibleAndControlsWork() async throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_look", "none", "-cs_dev_appearance", "dark", "-cs_dev_text_size", "large"]
    app.launch()
    let signIn = app.buttons.element(matching: NSPredicate(format: "label =[c] %@", "Sign in"))
    XCTAssertTrue(signIn.waitForExistence(timeout: 20), "Use the signed-out review simulator")
    capture(app.screenshot(), name: "welcome-dark")
    signIn.tap()
    XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 10))
    capture(app.screenshot(), name: "sign-in-first")
    // Observe another settled frame: no animation is added to the contour.
    let settled = expectation(description: "settled sign-in")
    DispatchQueue.main.asyncAfter(deadline: .now() + 4) { settled.fulfill() }
    await fulfillment(of: [settled], timeout: 6)
    let lockup = app.descendants(matching: .any).matching(identifier: "door.brand.lockup").firstMatch
    XCTAssertTrue(lockup.exists)
    XCTAssertEqual(lockup.frame.midX, app.frame.midX, accuracy: 2)
    capture(app.screenshot(), name: "sign-in-settled")
    XCTAssertTrue(app.buttons.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "Continue with email")).isHittable)
    XCUIDevice.shared.press(.home)
    let homeSettled = expectation(description: "home animation settled")
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { homeSettled.fulfill() }
    await fulfillment(of: [homeSettled], timeout: 5)
    capture(XCUIScreen.main.screenshot(), name: "app-icon-home-screen")
  }

  @MainActor func testGolfTerrainPaperAndLargeText() async throws {
    for size in ["large", "AX3"] {
      let app = XCUIApplication()
      app.launchArguments = ["-cs_dev_look", "none", "-cs_dev_appearance", "light", "-cs_dev_text_size", size]
      app.launch()
      let door = app.buttons.element(matching: NSPredicate(format: "label =[c] %@", "Sign in"))
      XCTAssertTrue(door.waitForExistence(timeout: 20))
      for _ in 0..<5 where !door.isHittable { app.swipeUp() }
      XCTAssertTrue(door.isHittable)
      capture(app.screenshot(), name: "golf-welcome-light-" + size)
      door.tap()
      XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 10))
      let settled = expectation(description: "keyboard settled")
      DispatchQueue.main.asyncAfter(deadline: .now() + 4) { settled.fulfill() }
      await fulfillment(of: [settled], timeout: 6)
      let action = app.buttons.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "Continue with email"))
      for _ in 0..<5 where !action.isHittable { app.swipeUp() }
      XCTAssertTrue(action.isHittable)
      capture(app.screenshot(), name: "golf-sign-in-light-" + size)
      app.terminate()
    }
  }

  @MainActor private func capture(_ screenshot: XCUIScreenshot, name: String) {
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}

final class CompeteBoldReviewTests: XCTestCase {
  @MainActor func testAppearancesAndExistingDoors() throws {
    let app = XCUIApplication()
    for appearance in ["dark", "light"] {
      app.launchArguments = ["-cs_dev_open", "compete", "-cs_dev_look", "none", "-cs_dev_appearance", appearance, "-cs_dev_text_size", "large"]
      app.launch()
      let row = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH %@", "compete.row.")).firstMatch.buttons.firstMatch
      XCTAssertTrue(row.waitForExistence(timeout: 30), "Use the signed-in review simulator")
      let shot = XCTAttachment(screenshot: app.screenshot())
      shot.name = "compete-bold-" + appearance; shot.lifetime = .keepAlways; add(shot)
      XCTAssertTrue(row.isHittable)
      row.tap()
      let back = app.buttons["Back"].firstMatch
      XCTAssertTrue(back.waitForExistence(timeout: 15), "The existing season destination should open")
      back.tap()
      let create = app.buttons.element(matching: NSPredicate(format: "label =[c] %@", "Start something"))
      XCTAssertTrue(create.waitForExistence(timeout: 10))
      for _ in 0..<5 where !create.isHittable { app.swipeUp() }
      XCTAssertTrue(create.isHittable)
      create.tap()
      XCTAssertTrue(app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "what do you want to do")).waitForExistence(timeout: 10))
      // Stop at the existing intent chooser; do not create a competition.
      app.terminate()
    }
  }

  @MainActor func testNarrowAccessibilityLayout() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_open", "compete", "-cs_dev_look", "none", "-cs_dev_appearance", "light", "-cs_dev_text_size", "AX3"]
    app.launch()
    let row = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH %@", "compete.row.")).firstMatch.buttons.firstMatch
    XCTAssertTrue(row.waitForExistence(timeout: 30))
    let top = XCTAttachment(screenshot: app.screenshot())
    top.name = "compete-bold-narrow-AX3"; top.lifetime = .keepAlways; add(top)
    let create = app.buttons.element(matching: NSPredicate(format: "label =[c] %@", "Start something"))
    for _ in 0..<8 where !create.isHittable { app.swipeUp() }
    XCTAssertTrue(create.isHittable)
    let action = XCTAttachment(screenshot: app.screenshot())
    action.name = "compete-bold-narrow-action-AX3"; action.lifetime = .keepAlways; add(action)
  }
}
