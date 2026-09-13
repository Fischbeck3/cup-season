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

/// F1 · the fourth placement: another story leads AND the feed is empty, so
/// `HomePage.make` promotes the reminder to `wireEmptyItem`. That block drew
/// three lines and offered no act at all.
///
/// The regression is Codex's, brought across from its review workspace. My own
/// note here previously said a displaced card was not reachable through a
/// fixture because the wire is built from the feed. That was wrong in the one
/// way that mattered: when the feed is EMPTY the item is promoted out of the
/// wire and into this block, so `after_golf_wire` reaches it without inventing
/// a single feed row.
final class AfterGolfWirePlacementTests: XCTestCase {

  private func launch(_ extra: [String]) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_home_state", "after_golf_wire", "-cs_dev_look", "none"] + extra
    app.terminate(); app.launch()
    return app
  }

  private func reach(_ e: XCUIElement, _ app: XCUIApplication, _ what: String,
                     file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(e.waitForExistence(timeout: 25), "F1: \(what) never rendered", file: file, line: line)
    for _ in 0..<40 where !e.isHittable { app.scrollViews.firstMatch.swipeUp() }
    XCTAssertTrue(e.isHittable, "F1: \(what) rendered but cannot be tapped", file: file, line: line)
    XCTAssertGreaterThanOrEqual(e.frame.height, 43, "F1: \(what) is under the tap target", file: file, line: line)
  }

  @MainActor func testDisplacedCardWithAnEmptyFeedKeepsAllThreeActions() {
    let app = launch(["-cs_dev_text_size", "large"])
    XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "had you on the plan"))
                    .firstMatch.waitForExistence(timeout: 25), "the reminder itself is gone")
    // Something else must be leading, or this is not the arrangement under test.
    // The lead is ONE combined accessibility element (§7), so its headline is
    // inside the button's label rather than a static text of its own.
    XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "two points off the lead"))
                    .firstMatch.exists, "the lead above it was lost — this is not the displaced arrangement")
    reach(app.buttons["Add my round"].firstMatch, app, "the plan-aware round door")
    reach(app.buttons["Later"].firstMatch, app, "Later")
    reach(app.buttons["Didn’t play"].firstMatch, app, "Didn’t play")
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "After golf · displaced, empty feed"; shot.lifetime = .keepAlways; add(shot)
  }

  @MainActor func testDisplacedCardSurvivesAccessibilityText() {
    let app = launch(["-cs_dev_text_size", "ax3"])
    reach(app.buttons["Add my round"].firstMatch, app, "the round door at AX3")
    reach(app.buttons["Later"].firstMatch, app, "Later at AX3")
    reach(app.buttons["Didn’t play"].firstMatch, app, "Didn’t play at AX3")
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "After golf · displaced · AX3"; shot.lifetime = .keepAlways; add(shot)
  }

  /// A failed answer keeps the card here too — the fixture has no session, so
  /// the call fails, and nothing local may be written or hidden on a failure.
  @MainActor func testAFailedAnswerKeepsTheDisplacedCard() {
    let app = launch(["-cs_dev_text_size", "large"])
    let later = app.buttons["Later"].firstMatch
    reach(later, app, "Later")
    later.tap()
    XCTAssertTrue(app.buttons["Add my round"].firstMatch.waitForExistence(timeout: 10),
                  "F1: a failed answer threw the displaced card away")
    XCTAssertTrue(later.exists, "F1: a failed answer left no way to try again")
  }
}
