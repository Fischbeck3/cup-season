import XCTest

final class RoundShareReviewTests: XCTestCase {
  @MainActor func testLargeTextPreviewKeepsShareReachable() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_round_share_fixture", "-cs_dev_look", "none", "-cs_dev_text_size", "AX3", "-cs_dev_appearance", "dark"]
    app.launch()
    let send = app.buttons["round.share.send"]
    XCTAssertTrue(send.waitForExistence(timeout: 15))
    XCTAssertTrue(send.isHittable)
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "share-preview-large-text-dark-fixture"; shot.lifetime = .keepAlways; add(shot)
  }

  @MainActor func testFixturePreviewAndNativeShareCancellation() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_round_share_fixture", "-cs_dev_look", "none", "-cs_dev_appearance", "light"]
    app.launch()
    let send = app.buttons["round.share.send"]
    XCTAssertTrue(send.waitForExistence(timeout: 35), "DEBUG fixture preview must open")
    for _ in 0..<4 where !send.isHittable { app.swipeUp() }
    XCTAssertTrue(send.isHittable)
    let preview = XCTAttachment(screenshot: app.screenshot())
    preview.name = "no-photo-fixture-share-preview"
    preview.lifetime = .keepAlways
    add(preview)
    send.tap()
    let activity = app.otherElements["ActivityListView"]
    XCTAssertTrue(activity.waitForExistence(timeout: 10), "Native share sheet should open")
    // Dismiss the native sheet without selecting a destination or changing the round.
    app.buttons["header.closeButton"].tap()
    XCTAssertTrue(activity.waitForNonExistence(timeout: 5))
    XCTAssertTrue(send.waitForExistence(timeout: 10))
  }
}

final class AcceptedRoundReviewTests: XCTestCase {
  @MainActor func testReplayedAcceptedCompletionOpensReceipt() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_open", "receipt", "-cs_dev_brand_finish", "-cs_dev_look", "none", "-cs_dev_text_size", "large"]
    app.launch()
    let door = app.buttons.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "View receipt"))
    XCTAssertTrue(door.waitForExistence(timeout: 35))
    for _ in 0..<5 where !door.isHittable { app.swipeUp() }
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "accepted-round-completion-replay"; shot.lifetime = .keepAlways; add(shot)
    door.tap()
    XCTAssertTrue(app.buttons["round.share.preview"].waitForExistence(timeout: 20))
  }

  @MainActor func testAcceptedReceiptToPreviewAndPhotoOptOut() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_open", "receipt", "-cs_dev_look", "none", "-cs_dev_appearance", "light", "-cs_dev_text_size", "large", "-cs_dev_share_export"]
    app.launch()
    let previewDoor = app.buttons["round.share.preview"]
    XCTAssertTrue(previewDoor.waitForExistence(timeout: 35))
    for _ in 0..<5 where !previewDoor.isHittable { app.swipeUp() }
    XCTAssertTrue(previewDoor.isHittable)
    let receipt = XCTAttachment(screenshot: app.screenshot())
    receipt.name = "real-accepted-receipt"; receipt.lifetime = .keepAlways; add(receipt)
    previewDoor.tap()
    let send = app.buttons["round.share.send"]
    XCTAssertTrue(send.waitForExistence(timeout: 15))
    XCTAssertTrue(send.isHittable)
    let photo = XCTAttachment(screenshot: app.screenshot())
    photo.name = "real-round-photo-preview"; photo.lifetime = .keepAlways; add(photo)
    let toggle = app.switches["Include round photo"]
    XCTAssertTrue(toggle.exists, "Review account's accepted round has an attached photo")
    for _ in 0..<4 where !toggle.isHittable { app.swipeUp() }
    toggle.tap()
    app.swipeDown()
    let noPhoto = XCTAttachment(screenshot: app.screenshot())
    noPhoto.name = "real-round-no-photo-preview"; noPhoto.lifetime = .keepAlways; add(noPhoto)
    send.tap()
    let activity = app.otherElements["ActivityListView"]
    XCTAssertTrue(activity.waitForExistence(timeout: 10))
    app.buttons["header.closeButton"].tap()
    XCTAssertTrue(activity.waitForNonExistence(timeout: 5))
    XCTAssertTrue(send.isHittable)
  }
}
