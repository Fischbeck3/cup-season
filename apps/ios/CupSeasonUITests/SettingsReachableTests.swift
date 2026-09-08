// Can a finger get into settings? (D301)
//
// **WHY THIS TARGET EXISTS.** The owner has said *"I cant click into settings"*
// TWICE, on two different builds. The first report was answered by widening
// `CSTertiaryStyle`'s shape and adding a full-measure `Card & settings` row at
// the foot of the You page — both correct, and both verified the only way this
// repo could verify anything: by measuring a frame in a unit test and by
// looking at a screenshot.
//
// Neither of those asks the question. `TertiaryTargetTests` says so in its own
// header — *"Proving a tap needs an XCUITest target, which this app does not
// have; that is recorded as the honest gap rather than papered over with a
// probe that cannot see."* A frame is not a target, a screenshot is not a tap,
// and `UIView.hitTest` is useless here because modern SwiftUI routes every
// touch through one `_UIHostingView`.
//
// So this is that gap, closed. It drives the real app on a real simulator and
// asks the real hit-tester three questions in order: is the control in the
// accessibility tree, does the system consider it hittable, and does tapping
// it land on the settings page. Nothing here reads a frame.
//
// It runs against the SIGNED-IN simulator (this repo's captures already depend
// on that — the session is copied into the simulator keychain). Signed out the
// tests skip rather than fail: a false red on a machine with no session
// teaches nobody anything.

import XCTest

final class SettingsReachableTests: XCTestCase {

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
  }

  private func launch() -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments += ["-cs_dev_open", "you"]
    app.launch()
    return app
  }

  /// The credential is the proof that the app came up signed in: signed out
  /// there is a door and no card, and the card carries the handle. On the
  /// receipt it is the round's own dateline instead, so this waits for either.
  private func requireSignedIn(_ app: XCUIApplication) throws {
    let handle = app.staticTexts.element(matching: NSPredicate(
      format: "label BEGINSWITH %@ OR label CONTAINS[c] %@", "@", "holes"))
    guard handle.waitForExistence(timeout: 45) else {
      throw XCTSkip("Not signed in on this simulator — copy the keychain in and re-run.")
    }
  }

  /// **Matched by PREDICATE, never by a typed string.** The first run of this
  /// target skipped both tests because it asked for `"Card and settings"` while
  /// the tree holds `'CARD AND SETTINGS'` — the design system uppercases at the
  /// role, so the accessibility label arrives uppercased too. A test that has
  /// to guess the casing of a label is a test that reports a missing control
  /// when the control is sitting right there, which is the exact mistake this
  /// whole target exists to stop being made about the product.
  private func button(containing text: String, in app: XCUIApplication) -> XCUIElement {
    app.buttons.element(matching: NSPredicate(format: "label CONTAINS[c] %@", text))
  }

  /// The settings page names its first block, and **the marker has to be
  /// unique to that page.** The first draft asserted on "notifications" — which
  /// lives on the page's SECOND pane — and both tests went red against an app
  /// that had navigated correctly. "Card & settings" is no good either: the You
  /// page's own foot door carries that exact title, and XCUITest sees
  /// off-screen elements, so it would go green without moving. This line is on
  /// the settings page's first pane and nowhere else.
  private func settingsPageIsUp(_ app: XCUIApplication) -> Bool {
    app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "what your buddies see"))
      .waitForExistence(timeout: 12)
  }

  // MARK: - the corner link

  /// §1 puts ONE tertiary link at `topBarTrailing` and on You it is `Settings`.
  /// This is the control the owner reaches for first, and the one he says does
  /// not work.
  func testTheCornerSettingsLinkIsHittableAndOpensSettings() throws {
    let app = launch()
    try requireSignedIn(app)

    let corner = button(containing: "card and settings", in: app)
    XCTAssertTrue(corner.waitForExistence(timeout: 20),
                  "the You page's corner Settings link is not in the accessibility tree at all")
    XCTAssertTrue(corner.isHittable,
                  "the corner Settings link EXISTS but the system will not deliver a touch to it — \(corner.frame)")

    corner.tap()
    XCTAssertTrue(settingsPageIsUp(app), "the corner link took a tap and nothing opened")
  }

  // MARK: - the foot door

  /// The row added after the first report: a full-measure 56pt door in the
  /// block of things that are not the golf. Asserted independently — if the
  /// corner is broken and the foot works the owner still gets in, and the
  /// reverse is worth knowing too.
  func testTheFootDoorIsHittableAndOpensSettings() throws {
    let app = launch()
    try requireSignedIn(app)

    let foot = button(containing: "your name, your marker", in: app)
    XCTAssertTrue(foot.waitForExistence(timeout: 20),
                  "the foot door is not in the accessibility tree")

    // It is three screens down; a control nobody can scroll to is a control
    // nobody has. `swipeUp` is a finger, not a `scrollTo`.
    var swipes = 0
    while !foot.isHittable && swipes < 12 {
      app.swipeUp()
      swipes += 1
    }
    XCTAssertTrue(foot.isHittable,
                  "the foot door never became hittable after \(swipes) swipes — \(foot.frame)")

    foot.tap()
    XCTAssertTrue(settingsPageIsUp(app), "the foot door took a tap and nothing opened")
  }

  // MARK: - the control experiment

  /// **THE TEST THAT TOLD US IT WAS NOT THE BUTTON.** When the corner link
  /// failed, the two candidates were the control (`CSDoor(.link)`, the shared
  /// tertiary — 63 sites, so a fault there would be an app-wide outage) and the
  /// place. This ran the same control on a different screen: the receipt's
  /// `Delete this round`, which arms a second control when it fires, so a tap
  /// has a visible consequence and needs no navigation. It fired. The control
  /// was fine and the You page's chrome row was not — which is what sent the
  /// search to the credential above it (D301).
  ///
  /// It stays as a guard: if a future change to `CSTertiaryStyle` kills the
  /// product's "go here" idiom, this goes red on a screen nobody was editing.
  func testATertiaryLinkFiresOnAnotherScreen() throws {
    let app = XCUIApplication()
    app.launchArguments += ["-cs_dev_open", "receipt"]
    app.launch()
    try requireSignedIn(app)

    let del = button(containing: "delete this round", in: app)
    guard del.waitForExistence(timeout: 25) else {
      throw XCTSkip("This account has no round to open a receipt on.")
    }
    var swipes = 0
    while !del.isHittable && swipes < 10 { app.swipeUp(); swipes += 1 }
    del.tap()

    let keep = button(containing: "keep it", in: app)
    XCTAssertTrue(keep.waitForExistence(timeout: 8),
                  "the product's shared tertiary link took a tap and did not fire — this is 63 sites, not one")
  }
}
