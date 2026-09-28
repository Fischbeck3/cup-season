import XCTest

// Local-only verification of existing Door. No account request or submission.
final class ApprovedNativeVerificationTests: XCTestCase {
  @MainActor func testEmailAccessibleName() throws {
    continueAfterFailure = true
    let size = ProcessInfo.processInfo.environment["CS_CAPTURE_SIZE"] ?? "large"
    for theme in ["dark", "light"] {
      let app = XCUIApplication()
      app.launchArguments = ["-cs_dev_pending_join", "-cs_dev_appearance", theme, "-cs_dev_look", "none", "-cs_dev_text_size", size, "-cs_dev_offline_network"]
      app.launch()
      let sign = app.buttons.matching(NSPredicate(format: "label =[c] %@", "Sign in")).firstMatch
      XCTAssertTrue(sign.waitForExistence(timeout: 20))
      sign.tap()
      let field = app.textFields.firstMatch
      XCTAssertTrue(field.waitForExistence(timeout: 10))
      let visibleEmail = app.staticTexts.matching(NSPredicate(format: "label =[c] %@", "Email")).firstMatch
      XCTAssertTrue(visibleEmail.exists)
      let before = ["label": field.label, "placeholder": field.placeholderValue ?? "", "value": String(describing: field.value ?? "")]
      XCTAssertEqual(field.label, "Email", "The native field must be named before typing")
      let shot = XCTAttachment(screenshot: app.screenshot())
      shot.name = "native-door-email-after-\(theme)-\(size)"; shot.lifetime = .keepAlways; add(shot)
      field.tap()
      XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
      field.typeText("fixture@example.com")
      XCTAssertEqual(field.value as? String, "fixture@example.com")
      let after = ["label": field.label, "placeholder": field.placeholderValue ?? "", "value": String(describing: field.value ?? "")]
      let record: [String: Any] = ["theme": theme, "size": size, "visibleEmailLabel": visibleEmail.exists, "before": before, "after": after]
      let data = try JSONSerialization.data(withJSONObject: record, options: [.sortedKeys])
      print("APPROVED_NATIVE_AX " + String(decoding: data, as: UTF8.self))
      let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
      attachment.name = "native-door-ax-\(theme)-\(size)"; attachment.lifetime = .keepAlways; add(attachment)
      // Both names must persist independently of the entered value.
      XCTAssertFalse(field.label.isEmpty, "Native email field has no accessibility name")
      XCTAssertEqual(field.label, "Email", "The native field name must persist after typing")
      app.terminate()
    }
  }
}
