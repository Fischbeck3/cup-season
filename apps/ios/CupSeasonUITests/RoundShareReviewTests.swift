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


/// D362 · the receipt's lenses and doors, on the signed-in account's own round
/// with the lenses stood in by the hatch (the production database predates
/// them), photographed in both appearances.
final class ReceiptLensesUITests: XCTestCase {
  @MainActor func testLensRowsAndDoors() throws {
    for (mode, appearance, expectRows, expectDoor) in [
      ("two", "dark", ["This month · Fellas", "This month · Sunday Cup"], "Your rounds that count in"),
      ("bumped", "light", ["This month"], "Your rounds that count in"),
      ("uncapped", "dark", ["This month"], "Your rounds that count in"),
    ] {
      let app = XCUIApplication()
      app.launchArguments = ["-cs_dev_open", "receipt", "-cs_dev_receipt_lenses", mode, "-cs_dev_receipt_photo", "none",
                             "-cs_dev_look", "none", "-cs_dev_appearance", appearance, "-cs_dev_text_size", "large"]
      app.launch()
      let door = app.descendants(matching: .any)["receipt.counting.door"].firstMatch
      XCTAssertTrue(door.waitForExistence(timeout: 35), "no door for \(mode)")
      for _ in 0..<6 where !door.isHittable { app.swipeUp() }
      for label in expectRows { XCTAssertTrue(app.staticTexts[label].exists, "missing row \(label) for \(mode)") }
      XCTAssertTrue(door.label.contains(expectDoor), door.label)
      if mode == "bumped" { XCTAssertTrue(app.staticTexts["BUMPED"].exists) }
      if mode == "uncapped" { XCTAssertTrue(app.staticTexts["COUNTING #3"].exists && !app.staticTexts["COUNTING #3 OF"].exists) }
      let shot = XCTAttachment(screenshot: app.screenshot())
      shot.name = "receipt-lenses-\(mode)-\(appearance)"; shot.lifetime = .keepAlways; add(shot)
      // the door opens the sheet; against the older database it says so honestly
      door.tap()
      let sheet = app.descendants(matching: .any)["counting.sheet"].firstMatch
      XCTAssertTrue(sheet.waitForExistence(timeout: 10))
      let settled = NSPredicate(format: "exists == true")
      let honest = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'latest update' OR label CONTAINS 'No rounds' OR label CONTAINS 'at '")).firstMatch
      expectation(for: settled, evaluatedWith: honest); waitForExpectations(timeout: 15)
      // **A RULE IS ONLY EVER THE LOADED PAYLOAD'S.** Against the production
      // database these functions do not exist, so the sheet fails — and it may
      // not print a counting rule it was never told. It used to read `cap` as
      // nil and say "Every round counts" over a failure.
      XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Every round counts' OR label CONTAINS 'count each month'")).firstMatch.exists,
                     "the sheet invented a counting rule from an unloaded payload")
      let shot2 = XCTAttachment(screenshot: app.screenshot())
      shot2.name = "counting-sheet-\(mode)"; shot2.lifetime = .keepAlways; add(shot2)
      app.terminate()
    }
  }
}


/// D362 · the composer says what this round can add, from the served counters
/// (stood in by `-cs_dev_worth` until the migration lands).
///
/// **VISIBLE, not merely present.** Every assertion here reads the element's
/// FRAME and compares it against the window and the keyboard: a sentence in
/// the accessibility tree that sits under the keypad or below the fold is a
/// sentence nobody reads. The keypad is up when the composer opens (IOS-030
/// puts the cursor on the number), so that is the state it is proved in first.
final class ComposerWorthUITests: XCTestCase {
  private func openComposer(_ app: XCUIApplication, _ mode: String, size: String = "large") {
    app.launchArguments = ["-cs_dev_open", "post", "-cs_dev_worth", mode,
                           "-cs_dev_look", "none", "-cs_dev_text_size", size]
    app.launch()
    let addDoor = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Add a round you played")).firstMatch
    XCTAssertTrue(addDoor.waitForExistence(timeout: 35), "the Play fork did not open for \(mode)")
    addDoor.tap()
  }
  /// The sentence's frame is inside the window AND clear of the keyboard.
  @discardableResult
  private func assertReadable(_ app: XCUIApplication, _ what: String, file: StaticString = #filePath, line: UInt = #line) -> CGRect {
    let line_ = app.staticTexts.matching(identifier: "post.worth").firstMatch
    XCTAssertTrue(line_.waitForExistence(timeout: 15), "no worth line \(what)", file: file, line: line)
    // the page scrolls the sentence into view when it arrives; give that a beat
    let onScreen = NSPredicate(format: "isHittable == true")
    let e = XCTNSPredicateExpectation(predicate: onScreen, object: line_)
    _ = XCTWaiter().wait(for: [e], timeout: 5)
    let f = line_.frame, window = app.windows.firstMatch.frame
    XCTAssertFalse(f.isEmpty, "\(what): the sentence has no size", file: file, line: line)
    XCTAssertTrue(window.contains(CGPoint(x: f.midX, y: f.minY)) && window.contains(CGPoint(x: f.midX, y: f.maxY)),
                  "\(what): the sentence is outside the window (\(f) in \(window))", file: file, line: line)
    if app.keyboards.count > 0 {
      let kb = app.keyboards.firstMatch.frame
      XCTAssertLessThanOrEqual(f.maxY, kb.minY + 1,
                               "\(what): the keypad covers the sentence (sentence \(f), keypad \(kb))", file: file, line: line)
    }
    XCTAssertTrue(line_.isHittable, "\(what): the sentence is not on screen", file: file, line: line)
    return f
  }

  @MainActor func testWorthLinesInTheComposer() throws {
    for (mode, expect) in [("room", "worth up to 12. Your best 4 count and you have 2."),
                           ("full", "worth up to 7 more."),
                           ("capped", "cannot add to your points this month"),
                           ("open", "Every round you post this month counts."),
                           ("two", "in Sunday Cup")] {
      let app = XCUIApplication()
      openComposer(app, mode)
      assertReadable(app, "for \(mode) with the keypad up")
      XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", expect)).firstMatch.exists, "\(mode) said the wrong thing")
      let shot = XCTAttachment(screenshot: app.screenshot())
      shot.name = "composer-worth-\(mode)"; shot.lifetime = .keepAlways; add(shot)
      app.terminate()
    }
  }

  /// The normal interaction: the keypad is up, a score is typed, the keypad is
  /// dismissed. The sentence is readable throughout and does not move away.
  @MainActor func testReadableThroughTypingAndDismissal() throws {
    let app = XCUIApplication()
    openComposer(app, "two")
    // the composer opens on the number; if the cursor is not there yet, put it
    // there the way a thumb would
    if !app.keyboards.firstMatch.waitForExistence(timeout: 10) {
      let gross = app.textFields.matching(NSPredicate(format: "label CONTAINS[c] %@", "gross")).firstMatch
      if gross.waitForExistence(timeout: 5) { gross.tap() }
    }
    XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10), "the keypad never rose")
    let withKeypad = assertReadable(app, "with the keypad up")
    let shot1 = XCTAttachment(screenshot: app.screenshot())
    shot1.name = "composer-worth-keypad-up"; shot1.lifetime = .keepAlways; add(shot1)

    // **TYPING A SCORE MUST NOT RE-ASK THE COUNTERS**, and this proves it:
    // `loadWorth` clears `worthLines` before every fetch, so a refetch on a
    // keystroke would empty the sentence. It is still here, and still the same
    // sentence, after two digits.
    let before = app.staticTexts.matching(identifier: "post.worth").firstMatch.label
    let field = app.textFields.matching(NSPredicate(format: "label CONTAINS[c] %@", "gross")).firstMatch
    if field.exists { field.typeText("84") } else { app.typeText("84") }
    assertReadable(app, "while typing")
    XCTAssertEqual(app.staticTexts.matching(identifier: "post.worth").firstMatch.label, before,
                   "typing a score changed or re-asked the counters")

    // dismiss the keypad and read it again
    app.swipeDown()
    if app.keyboards.count > 0 { app.tap() }
    let after = assertReadable(app, "with the keypad dismissed")
    XCTAssertEqual(withKeypad.width, after.width, accuracy: 2, "the sentence reflowed when the keypad went")
    let shot2 = XCTAttachment(screenshot: app.screenshot())
    shot2.name = "composer-worth-keypad-dismissed"; shot2.lifetime = .keepAlways; add(shot2)
  }

  /// A small phone at an accessibility size — the case where a sentence three
  /// sections below the fold was invisible.
  @MainActor func testReadableOnASmallPhoneAtAnEnlargedSize() throws {
    let app = XCUIApplication()
    openComposer(app, "room", size: "ax3")
    assertReadable(app, "at AX3")
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "composer-worth-ax3"; shot.lifetime = .keepAlways; add(shot)
  }
}
