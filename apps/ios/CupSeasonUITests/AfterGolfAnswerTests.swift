import XCTest

/// R1 · the after-golf card's three actions, in the placements a real golfer
/// actually gets. The controls shipped on `.empty` alone — the layout chosen
/// when a golfer has neither seasons nor rounds — so a build declared a
/// capability its ordinary Home did not implement. These tests fail if any
/// supported placement loses them again.
///
/// Every golfer here is a fixture. `-cs_dev_home_state` substitutes ONE read
/// and writes nothing to any server.
final class AfterGolfAnswerTests: XCTestCase {

  /// The hatch's payload arrives in a `.task`, so a relaunched scene can lay
  /// the scroll view out once with no content — and a scroll view with nothing
  /// in it takes its content's ideal width, which is zero. It never re-expands.
  /// The real app never sees this: Home always has a `me` before it appears.
  /// Here the launch is simply repeated until the page has a width.
  private func launch(_ extra: [String]) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_home_state", "after_golf", "-cs_dev_look", "none"] + extra
    for attempt in 1...4 {
      app.terminate(); app.launch()
      let door = app.buttons["Add my round"].firstMatch
      guard door.waitForExistence(timeout: 25) else { continue }
      if app.scrollViews.allElementsBoundByIndex.contains(where: { $0.frame.width > 100 }) { return app }
      XCTContext.runActivity(named: "relaunch \(attempt): the fixture page laid out with no width") { _ in }
    }
    XCTFail("the Home-state fixture never laid out with a width")
    return app
  }

  /// The root animates its arrival (`CSMotion.rise`), so a control can exist
  /// before it is in its final place. Hittability is waited for, never asserted
  /// on the first frame.
  private func hittable(_ e: XCUIElement, _ app: XCUIApplication, _ what: String,
                        file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(e.waitForExistence(timeout: 25), "\(what) never rendered", file: file, line: line)
    for _ in 0..<40 {
      if e.isHittable { break }
      // A tall page at accessibility sizes puts the answers below the fold.
      // Reaching them by scrolling is normal; being unreachable is not.
      app.scrollViews.firstMatch.swipeUp()
      _ = e.waitForExistence(timeout: 1)
    }
    XCTAssertTrue(e.isHittable, "\(what) rendered but cannot be tapped", file: file, line: line)
    XCTAssertGreaterThanOrEqual(e.frame.height, 44 - 1, "\(what) is under the tap target", file: file, line: line)
  }

  private func card(_ app: XCUIApplication) -> (door: XCUIElement, later: XCUIElement, didnt: XCUIElement) {
    (app.buttons["Add my round"].firstMatch,
     app.buttons["Later"].firstMatch,
     app.buttons["Didn’t play"].firstMatch)
  }

  /// The fixture has 22 rounds, so the arrangement gives it the LEAD layout —
  /// which is exactly the one that had the door and no answers.
  @MainActor func testAnEstablishedGolferGetsAllThreeActions() {
    let app = launch(["-cs_dev_text_size", "large"])
    let c = card(app)
    hittable(c.door, app, "R1: the round door on the lead layout")
    hittable(c.later, app, "R1: Later on the lead layout")
    hittable(c.didnt, app, "R1: Didn’t play on the lead layout")
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "After golf · lead · dark · large"; shot.lifetime = .keepAlways; add(shot)
  }

  /// The round door keeps its own words and stays the primary. What it OPENS
  /// is not provable here: the fixture renders Home outside the tab shell, so
  /// there is no presenter to put the composer up. The day it fills in is
  /// covered by `PlanPrefillTests` and by the browser suite; a real tap through
  /// to the composer belongs to a device pass.
  @MainActor func testTheRoundDoorIsThePrimaryAndKeepsItsWords() {
    let app = launch(["-cs_dev_text_size", "large"])
    let c = card(app)
    hittable(c.door, app, "the round door")
    XCTAssertEqual(c.door.label, "Add my round")
    XCTAssertLessThan(c.door.frame.minY, c.later.frame.minY,
                      "the round is the point — it sits above the ways out of being asked")
  }

  /// An answer is a real tap that reaches the server. The fixture has no
  /// session, so the call fails and the card must STAY — which is the
  /// behaviour that matters: nothing local is written and nothing is hidden
  /// on a failure.
  @MainActor func testAFailedAnswerKeepsTheCard() {
    let app = launch(["-cs_dev_text_size", "large"])
    let c = card(app)
    hittable(c.later, app, "Later")
    c.later.tap()
    XCTAssertTrue(c.door.waitForExistence(timeout: 10), "a failed answer threw the card away")
    XCTAssertTrue(c.later.exists, "a failed answer left no way to try again")
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "After golf · answer failed, card kept"; shot.lifetime = .keepAlways; add(shot)
  }

  @MainActor func testTheActionsSurviveAccessibilityText() {
    let app = launch(["-cs_dev_text_size", "ax3"])
    let c = card(app)
    hittable(c.door, app, "R1: the round door at AX3")
    hittable(c.later, app, "R1: Later at AX3")
    hittable(c.didnt, app, "R1: Didn’t play at AX3")
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "After golf · lead · AX3"; shot.lifetime = .keepAlways; add(shot)
  }

  @MainActor func testTheActionsSurviveLightPrinting() {
    let app = launch(["-cs_dev_text_size", "large", "-cs_dev_appearance", "light"])
    let c = card(app)
    hittable(c.door, app, "R1: the round door in light")
    hittable(c.later, app, "R1: Later in light")
    hittable(c.didnt, app, "R1: Didn’t play in light")
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "After golf · lead · light"; shot.lifetime = .keepAlways; add(shot)
  }
}

// R1 · THE THIRD PLACEMENT IS CODE-COMPLETE AND NOT PROVABLE HERE, which is
// worth saying plainly rather than leaving a green suite to imply otherwise.
//
// An after-golf item that is not the lead renders through the wire, and the
// wire is built from `HomeModel.items` — the FEED. `runFixture` clears that
// deliberately: "a fixture that invented a feed would be inventing golfers"
// (D259, and EVIDENCE_POLICY). So a Home-state fixture can put a card in the
// lead and cannot put one in the wire, and a test that seemed to do so would be
// testing a feed this repository has ruled it may not fabricate.
//
// What IS proven: `HomeStateFixtureTests` asserts the `after_golf_wire` payload
// carries an answerable card that is not the lead, and `HomeView.answers(_:)`
// is one producer called from all three placements, so a layout cannot ship the
// door without the answers again. A real displaced card belongs to a device
// pass with a real account.
