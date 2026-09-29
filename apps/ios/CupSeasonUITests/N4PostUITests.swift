import XCTest
import UIKit

/// N4 · the composer's two P1s, measured in the picture rather than the tree.
///
/// - N4-020: a refused round said nothing. The refusal was a toast, the only
///   toast host drew at the app's root, and the composer is a full-screen
///   cover over it — so the element was in the tree and the golfer saw
///   nothing (`flow__post-failed.png`). The answer is now said above
///   `Add my round`, and this reads it off the screenshot.
/// - N4-021: at AX3 the worth sentence's scroll put the gross field above the
///   top of the screen, and the golfer typed a score they could not see
///   (`se3/composer-dark-AX3.png`). Run this on an SE as well as a 17 Pro.
final class N4PostUITests: N2UITestCase {
  override func setUp() { continueAfterFailure = true }

  /// The card the route tests fill: a gross, then the rating and slope, and
  /// (unless told not to) a course typed by hand.
  @MainActor private func fill(_ app: XCUIApplication, course named: Bool = true) {
    let gross = app.textFields["Your gross"].firstMatch
    XCTAssertTrue(gross.waitForExistence(timeout: 10))
    if !app.keyboards.firstMatch.exists { gross.tap() }
    gross.typeText("84")
    let fold = app.buttons.containing(NSPredicate(format: "label BEGINSWITH %@", "Rating not set")).firstMatch
    if fold.waitForExistence(timeout: 3) { fold.tap() }
    let rating = app.textFields["Rating"].firstMatch
    XCTAssertTrue(rating.waitForExistence(timeout: 5))
    rating.tap(); rating.typeText("70.1")
    let slope = app.textFields["Slope"].firstMatch
    slope.tap(); slope.typeText("124")
    // A2 · a round names its course (noCard, noCourse, noRating): the synthetic
    // composer inherits none, so one is typed by hand, as a golfer off the list
    // types it — last, because its results open under the field and move the
    // rating and slope
    if named {
      let course = courseField(app)
      XCTAssertTrue(course.waitForExistence(timeout: 5), "the course field")
      app.tapToType(course)   // after the slope it can sit under the bars or on the keyboard
      course.typeText("Fixture Muni")
    }
    app.swipeDown()
  }

  @MainActor private func courseField(_ app: XCUIApplication) -> XCUIElement {
    app.textFields.matching(NSPredicate(format: "identifier == %@ OR placeholderValue BEGINSWITH %@",
                                        "post.course.search", "Search a course")).firstMatch
  }

  /// A2 (B d4d7c6f0) · **a round with no course is the course field's own
  /// error.** A gross, a rating and a slope, and no course: Add my round says
  /// the sentence under the course field and puts the cursor there, and the
  /// post's own answer slot above the button stays empty — it is for the post.
  @MainActor func testARoundWithNoCourseIsTheCourseFieldsOwnError() {
    let app = launch("season-live", "postround")
    _ = root(app, "composer")
    fill(app, course: false)
    let words = "Add the course you played — its tee sets the rating and slope."
    let post = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "add my round")).allElementsBoundByIndex
      .max { $0.frame.minY < $1.frame.minY }
    XCTAssertNotNil(post, "Add my round is there")
    post?.tap()
    let said = app.staticTexts.matching(NSPredicate(format: "label == %@", words))
    XCTAssertTrue(said.firstMatch.waitForExistence(timeout: 10), "the course's own error is said")
    let course = courseField(app)
    XCTAssertTrue(course.waitForExistence(timeout: 5), "the card opened on the course field")
    // the field's element carries its own error line (CSField's family), so
    // "under" is under the 50pt input box at its top, inside what it reports
    let box = course.frame.minY + 44
    let under = said.allElementsBoundByIndex.contains { $0.frame.minY >= box && $0.frame.minY <= course.frame.maxY + 60 }
    XCTAssertTrue(under, "the sentence stands under the course field — \(course.frame) · \(said.allElementsBoundByIndex.map(\.frame))")
    let focused = NSPredicate(format: "hasKeyboardFocus == true")
    XCTAssertEqual(XCTWaiter().wait(for: [expectation(for: focused, evaluatedWith: course)], timeout: 5), .completed,
                   "the course field takes the cursor")
    XCTAssertFalse(app.staticTexts["post.refusal"].exists, "the post's answer slot is left for the post")
    attach(app, "a2-no-course")
    // naming a course answers it: the field's error goes, and the calc line
    // previews the round instead of saying what it is missing
    course.typeText("Fixture Muni")
    XCTAssertTrue(waitGone(said.firstMatch, timeout: 5), "the sentence goes once a course is named")
    app.terminate()
  }

  /// N4-022 · Start over wiped the card, the photo and the draft on one tap,
  /// directly under the primary. It is armed now: the first tap asks and
  /// keeps the card, and the second clears it.
  @MainActor func testStartOverAsksBeforeItClearsTheCard() {
    let app = launch("season-live", "postround")
    _ = root(app, "composer")
    let gross = app.textFields["Your gross"].firstMatch
    XCTAssertTrue(gross.waitForExistence(timeout: 10))
    if !app.keyboards.firstMatch.exists { gross.tap() }
    gross.typeText("84")
    app.swipeDown()
    let start = app.buttons["post.startOver"].firstMatch
    XCTAssertTrue(start.waitForExistence(timeout: 5), "Start over is there")
    for _ in 0..<6 where !start.isHittable { app.swipeUp() }
    start.tap()
    let asks = NSPredicate(format: "label ==[c] %@", "Sure? This clears the card")
    XCTAssertEqual(XCTWaiter().wait(for: [expectation(for: asks, evaluatedWith: start)], timeout: 3), .completed,
                   "the first tap asks — \(start.label)")
    XCTAssertEqual(gross.value as? String, "84", "and keeps the card")
    attach(app, "n4-022-armed")
    start.tap()
    let cleared = NSPredicate(format: "value != %@", "84")
    XCTAssertEqual(XCTWaiter().wait(for: [expectation(for: cleared, evaluatedWith: gross)], timeout: 5), .completed,
                   "the second tap clears it")
    app.terminate()
  }

  /// N4-020, finished (root): a round with a course and no rating is the
  /// rating's own error — the sentence under the rating and slope fields, the
  /// cursor in the first one missing, and the post's answer slot left empty.
  @MainActor func testARoundWithNoRatingIsTheRatingsOwnError() {
    let app = launch("season-live", "postround")
    _ = root(app, "composer")
    let gross = app.textFields["Your gross"].firstMatch
    XCTAssertTrue(gross.waitForExistence(timeout: 10))
    if !app.keyboards.firstMatch.exists { gross.tap() }
    gross.typeText("84")
    let course = courseField(app)
    XCTAssertTrue(course.waitForExistence(timeout: 5), "the course field")
    course.tap(); course.typeText("Fixture Muni")
    app.swipeDown()
    let post = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "add my round")).allElementsBoundByIndex
      .max { $0.frame.minY < $1.frame.minY }
    XCTAssertNotNil(post, "Add my round is there")
    post?.tap()
    let said = app.staticTexts["post.rating.error"]
    XCTAssertTrue(said.waitForExistence(timeout: 10), "the rating's own error is said")
    XCTAssertTrue(said.label.hasPrefix("Type the rating and slope"), said.label)
    let rating = app.textFields["Rating"].firstMatch
    XCTAssertTrue(rating.exists, "the fields are open")
    XCTAssertGreaterThanOrEqual(said.frame.minY, rating.frame.minY + 44, "the sentence stands under the fields")
    let focused = NSPredicate(format: "hasKeyboardFocus == true")
    XCTAssertEqual(XCTWaiter().wait(for: [expectation(for: focused, evaluatedWith: rating)], timeout: 5), .completed,
                   "the rating field takes the cursor")
    XCTAssertFalse(app.staticTexts["post.refusal"].exists, "the post's answer slot is left for the post")
    attach(app, "n4-020-no-rating")
    app.terminate()
  }

  @MainActor private func waitGone(_ e: XCUIElement, timeout: TimeInterval) -> Bool {
    XCTWaiter().wait(for: [expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: e)], timeout: timeout) == .completed
  }

  /// How many pixels inside `frame` differ from its own top-left corner —
  /// drawn words, rather than a frame with nothing painted in it.
  @MainActor private func inkedPixels(_ app: XCUIApplication, in frame: CGRect) -> Int {
    guard let cg = app.screenshot().image.cgImage else { return 0 }
    let w = cg.width, h = cg.height
    var buf = [UInt8](repeating: 0, count: w * h * 4)
    let ok = buf.withUnsafeMutableBytes { raw -> Bool in
      guard let ctx = CGContext(data: raw.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return false }
      ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h)); return true
    }
    guard ok else { return 0 }
    let scale = CGFloat(w) / app.windows.firstMatch.frame.width
    func px(_ x: Int, _ y: Int) -> [Int] { let i = (y * w + x) * 4; return [Int(buf[i]), Int(buf[i + 1]), Int(buf[i + 2])] }
    let x0 = max(0, Int(frame.minX * scale)), x1 = min(w - 1, Int(frame.maxX * scale))
    let y0 = max(0, Int(frame.minY * scale)), y1 = min(h - 1, Int(frame.maxY * scale))
    guard x1 > x0, y1 > y0 else { return 0 }
    let ground = px(x0, y0)
    var inked = 0
    for y in stride(from: y0, to: y1, by: 2) {
      for x in stride(from: x0, to: x1, by: 2) where zip(px(x, y), ground).contains(where: { abs($0 - $1) > 40 }) { inked += 1 }
    }
    return inked
  }

  @MainActor func testAtAX3TheGrossFieldStaysInViewAboveTheKeypad() {
    // The reads are held, so the worth sentence lands AFTER the keypad is up —
    // the order a loaded phone (and the capture matrix) produced, and the one
    // that scrolled the field away. Unheld, a fast simulator lands the
    // sentence first and the bug hides.
    let app = launch("season-live", "postround", size: "AX3", extra: ["-cs_synth_delay", "3"])
    _ = root(app, "composer", timeout: 45)
    let gross = app.textFields["Your gross"].firstMatch
    XCTAssertTrue(gross.waitForExistence(timeout: 15))
    // IOS-030 focuses the box; the keypad rises, then the sentence lands —
    // both scrolls have had their turn once this settles
    XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10), "the keypad is up")
    let sentence = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "can score up to")).firstMatch
    _ = sentence.waitForExistence(timeout: 15)
    Thread.sleep(forTimeInterval: 2)
    let post = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "add my round")).allElementsBoundByIndex
      .max { $0.frame.minY < $1.frame.minY }
    let nav = app.navigationBars.firstMatch
    func onScreen(_ when: String) {
      XCTAssertTrue(gross.isHittable, "\(when): the gross field is on screen — \(gross.frame)")
      if nav.exists { XCTAssertGreaterThanOrEqual(gross.frame.minY, nav.frame.maxY - 1, "\(when): below the bar — \(gross.frame)") }
      if let post { XCTAssertLessThanOrEqual(gross.frame.maxY, post.frame.minY, "\(when): above the pinned foot — \(gross.frame)") }
      XCTAssertLessThanOrEqual(gross.frame.maxY, app.keyboards.firstMatch.frame.minY, "\(when): above the keypad")
    }
    onScreen("focused")
    attach(app, "n4-composer-AX3-focused")
    // the golfer types, and sees the number they typed
    gross.typeText("84")
    XCTAssertEqual(gross.value as? String, "84")
    onScreen("typed")
    XCTAssertGreaterThan(inkedPixels(app, in: gross.frame), 20, "the typed score is drawn in the picture")
    attach(app, "n4-composer-AX3-typed")
    app.terminate()
  }

  @MainActor func testARefusedPostIsSaidAboveTheButtonWhereTheGolferCanSeeIt() {
    for size in ["large", "AX3"] {
      let app = launch("season-live", "postround", size: size, extra: ["-cs_synth_post_fail"])
      _ = root(app, "composer")
      fill(app)
      let post = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "add my round")).allElementsBoundByIndex
        .max { $0.frame.minY < $1.frame.minY }
      XCTAssertNotNil(post, "\(size): Add my round is there")
      post?.tap()
      let said = app.staticTexts["post.refusal"]
      XCTAssertTrue(said.waitForExistence(timeout: 10), "\(size): the refusal is said")
      Thread.sleep(forTimeInterval: 1)
      XCTAssertTrue(said.isHittable, "\(size): on screen, not under the cover — \(said.frame)")
      XCTAssertTrue(said.label.hasPrefix("Nothing was posted") || said.label.hasPrefix("The server didn’t accept"),
                    "\(size): W1's words — \(said.label)")
      XCTAssertFalse(said.label.contains("press Post"), "\(size): never a button the composer does not have")
      if let post {
        XCTAssertLessThanOrEqual(said.frame.maxY, post.frame.minY + 1, "\(size): above the button it answers")
      }
      XCTAssertGreaterThan(inkedPixels(app, in: said.frame), 20, "\(size): the words are drawn in the picture")
      attach(app, "n4-post-refused-\(size)")
      // the card is kept, and changing it is the golfer's answer to the line
      XCTAssertEqual(app.textFields["Your gross"].firstMatch.value as? String, "84", "\(size): the card is kept")
      app.terminate()
    }
  }
}
