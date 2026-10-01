import XCTest

@MainActor final class ProfilePhotoTests: XCTestCase {
  func testPhotoAndFallbackCaptureMatrix() {
    for theme in ["dark", "light"] {
      let app = XCUIApplication()
      app.launchArguments = ["-cs_dev_compete_selected", "-cs_selected_screen", "faces",
                             "-cs_face_image", "http://127.0.0.1:8798/avatar-test.png",
                             "-cs_dev_appearance", theme, "-cs_dev_text_size", "large"]
      app.launch()
      let face = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Photo 120")).firstMatch
      XCTAssertTrue(face.waitForExistence(timeout: 10))
      XCTAssertEqual(face.frame.width, 120, accuracy: 1)
      // Give the local HTTP image renderer one turn after the source resolves.
      let settle = expectation(description: "image rendering settles")
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) { settle.fulfill() }
      wait(for: [settle], timeout: 3)
      capture("profile-photos-\(theme)-first", app)
      app.swipeUp()
      let guest = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Guest without profile")).firstMatch
      XCTAssertTrue(guest.exists)
      capture("profile-photos-\(theme)-fallbacks", app)
      app.terminate()
    }
  }
  private func capture(_ name: String, _ app: XCUIApplication) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
  }
  func testRemovedPhotoOverridesAnOldProvidedURL() {
    for theme in ["dark", "light"] {
      let app = XCUIApplication()
      app.launchArguments = ["-cs_dev_compete_selected", "-cs_selected_screen", "faces", "-cs_face_removed",
                             "-cs_face_image", "http://127.0.0.1:8798/avatar-test.png",
                             "-cs_dev_appearance", theme, "-cs_dev_text_size", "large"]
      app.launch()
      XCTAssertTrue(app.staticTexts["No photo"].waitForExistence(timeout: 10))
      let settle = expectation(description: "authoritative removal renders")
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) { settle.fulfill() }
      wait(for: [settle], timeout: 3)
      capture("profile-photos-\(theme)-removed", app)
      app.terminate()
    }
  }
}
