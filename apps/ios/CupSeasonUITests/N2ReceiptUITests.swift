import XCTest

/// S9 · the receipt's photo states, read from the running app on the
/// synthetic world: a photograph the owner cannot see is said once, beside
/// Replace and Remove, and nowhere else; the moment's VoiceOver element is the
/// card itself (its focus ring stays on screen), and a moment over a
/// photograph says it is one.
final class N2ReceiptUITests: N2UITestCase {
  @MainActor func testS9EachPhotoStateIsSaidHonestlyAndTheMomentStaysOnTheCard() {
    // place → (the moment carries a photo, the owner hears it is missing)
    let states: [(String, Bool, Bool)] = [
      ("receipt", true, false),            // his round, a photograph
      ("receipt-nophoto", false, false),   // his round, none
      ("receipt-broken", false, true),     // his round, the file is gone
      ("receipt-withdrawn", false, false), // his round, taken back
      ("receipt-other", true, false),      // Blake's round, a photograph
    ]
    for (place, photo, missing) in states {
      let app = launch("season-live", place)
      _ = root(app, "receipt")
      let moment = app.descendants(matching: .any)[photo ? "receipt.moment.photo" : "receipt.moment"].firstMatch
      XCTAssertTrue(moment.waitForExistence(timeout: 15), "\(place): the moment is drawn")
      XCTAssertFalse(moment.label.localizedCaseInsensitiveContains("Any time"), "Q45: the private receipt is signed by the pennant alone")
      Thread.sleep(forTimeInterval: 2)   // the picture, or its absence, settles
      let screen = app.windows.firstMatch.frame
      XCTAssertLessThanOrEqual(moment.frame.maxX, screen.maxX + 0.5, "\(place): the moment's focus ring stays on the screen — \(moment.frame)")
      if photo { XCTAssertEqual(moment.value as? String, "Round photo", "\(place): a photo moment says it is one") }
      let note = app.staticTexts["receipt.photo.unavailable"]
      if missing {
        XCTAssertTrue(note.waitForExistence(timeout: 10), "\(place): the owner hears the photo couldn't be opened")
        XCTAssertEqual(note.label, "This round\u{2019}s photo couldn\u{2019}t be opened.")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Replace photo")).firstMatch.exists)
      } else {
        XCTAssertFalse(note.exists, "\(place): nothing is said about a photo that isn't missing")
      }
      attach(app, "s9-\(place)")
      app.terminate()
    }
  }
}
