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

  /// D359 follow-through · the opt-out, on a fixture round that ACTUALLY
  /// carries a photograph. Nothing here touches an account: `-cs_dev_share_photo`
  /// hands the fixture the drawn stand-in, so the three states — included,
  /// opted out, opted back in — are the same three every run.
  ///
  /// It reads the OUTPUT, not the switch: `round.share.card.withPhoto` and
  /// `round.share.card.noPhoto` are the identifier of the rendered card, and
  /// they name which composition `RecapCardView.render` was actually handed.
  @MainActor func testFixturePhotoOptOutRemovesAndRestoresIt() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_round_share_fixture", "-cs_dev_share_photo",
                           "-cs_dev_look", "none", "-cs_dev_appearance", "dark"]
    app.launch()
    let withPhoto = app.images["round.share.card.withPhoto"]
    let noPhoto = app.images["round.share.card.noPhoto"]
    XCTAssertTrue(withPhoto.waitForExistence(timeout: 35), "the fixture round carries a photograph")
    let on = XCTAttachment(screenshot: app.screenshot())
    on.name = "fixture-share-with-photo"; on.lifetime = .keepAlways; add(on)

    let toggle = app.switches["Include round photo"]
    XCTAssertTrue(toggle.waitForExistence(timeout: 10), "a round with a photograph offers the opt-out")
    for _ in 0..<4 where !toggle.isHittable { app.swipeUp() }
    toggle.tap()
    XCTAssertTrue(noPhoto.waitForExistence(timeout: 10), "opting out removes the photograph from the card")
    XCTAssertFalse(withPhoto.exists)
    let off = XCTAttachment(screenshot: app.screenshot())
    off.name = "fixture-share-opted-out"; off.lifetime = .keepAlways; add(off)

    toggle.tap()
    XCTAssertTrue(withPhoto.waitForExistence(timeout: 10), "opting back in restores it")
    XCTAssertFalse(noPhoto.exists)
    let back = XCTAttachment(screenshot: app.screenshot())
    back.name = "fixture-share-photo-restored"; back.lifetime = .keepAlways; add(back)
  }

  /// The separate no-photo case: a round with no photograph renders the card
  /// without one and offers no switch at all, so the opt-out is not a control
  /// that exists with nothing behind it.
  @MainActor func testFixtureWithoutPhotoOffersNoOptOut() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_round_share_fixture", "-cs_dev_look", "none", "-cs_dev_appearance", "dark"]
    app.launch()
    XCTAssertTrue(app.images["round.share.card.noPhoto"].waitForExistence(timeout: 35))
    XCTAssertFalse(app.images["round.share.card.withPhoto"].exists)
    XCTAssertFalse(app.switches["Include round photo"].exists, "no photograph, no opt-out")
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "fixture-share-no-photo-case"; shot.lifetime = .keepAlways; add(shot)
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
    // `-cs_dev_receipt_photo on` is what makes this deterministic: the hatch
    // stands a photograph on whichever accepted round the receipt opened, so
    // the test no longer presumes the account's newest round happens to carry
    // one. It overrides the photograph's two facts and nothing else, and it
    // writes nothing to the server.
    app.launchArguments = ["-cs_dev_open", "receipt", "-cs_dev_receipt_photo", "on",
                           "-cs_dev_look", "none", "-cs_dev_appearance", "light",
                           "-cs_dev_text_size", "large", "-cs_dev_share_export"]
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
    XCTAssertTrue(app.images["round.share.card.withPhoto"].waitForExistence(timeout: 10),
                  "the hatch stood a photograph on the round, so the card carries one")
    let toggle = app.switches["Include round photo"]
    XCTAssertTrue(toggle.exists, "a round with a photograph offers the opt-out")
    for _ in 0..<4 where !toggle.isHittable { app.swipeUp() }
    toggle.tap()
    XCTAssertTrue(app.images["round.share.card.noPhoto"].waitForExistence(timeout: 10),
                  "opting out removes the photograph from the card")
    app.swipeDown()
    let noPhoto = XCTAttachment(screenshot: app.screenshot())
    noPhoto.name = "real-round-no-photo-preview"; noPhoto.lifetime = .keepAlways; add(noPhoto)
    toggle.tap()
    XCTAssertTrue(app.images["round.share.card.withPhoto"].waitForExistence(timeout: 10),
                  "opting back in restores it")
    send.tap()
    let activity = app.otherElements["ActivityListView"]
    XCTAssertTrue(activity.waitForExistence(timeout: 10))
    app.buttons["header.closeButton"].tap()
    XCTAssertTrue(activity.waitForNonExistence(timeout: 5))
    XCTAssertTrue(send.isHittable)
  }
}

/// D360 row 8 · the receipt's brand moment on the phone, in its states: with
/// the round's photograph and without one, both appearances, and at AX3.
/// The hatch stands a photograph on the receipt or takes it away; the round,
/// the figures and the leaf are the signed-in account's own.
final class ReceiptMomentTests: XCTestCase {
  @MainActor func testMomentStatesInBothAppearances() throws {
    for (photo, appearance, size) in [("on", "dark", "large"), ("none", "light", "large"), ("on", "light", "ax3"), ("none", "dark", "large")] {
      let app = XCUIApplication()
      app.launchArguments = ["-cs_dev_open", "receipt", "-cs_dev_receipt_photo", photo,
                             "-cs_dev_look", "none", "-cs_dev_appearance", appearance, "-cs_dev_text_size", size]
      app.launch()
      let id = photo == "on" ? "receipt.moment.photo" : "receipt.moment"
      let moment = app.descendants(matching: .any)[id].firstMatch
      XCTAssertTrue(moment.waitForExistence(timeout: 35), "the moment did not render for photo=\(photo)")
      XCTAssertTrue(moment.label.localizedCaseInsensitiveContains("any time"), "the moment signs itself: \(moment.label)")
      let shot = XCTAttachment(screenshot: app.screenshot())
      shot.name = "receipt-moment-\(photo)-\(appearance)-\(size)"; shot.lifetime = .keepAlways; add(shot)
      app.terminate()
    }
  }
}
