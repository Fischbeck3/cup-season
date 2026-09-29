import XCTest

/// N4 · the event rooms, measured on screen.
///
/// - Q29 (the judges, via C) · §16.3: at AX3 the Ryder's side roster scrolled
///   sideways, so the second side was a swipe nobody knew to make. The sides
///   stack now. This reads it off the synthetic live room, which needs no
///   signed-in simulator (CompeteGameplayReviewTests' twin of it opens the
///   real route and fails on a signed-out simulator). Run it on an SE as well
///   as a 17 Pro.
final class N4EventUITests: N2UITestCase {
  override func setUp() { continueAfterFailure = true }

  @MainActor func testAtAX3TheRyderSidesStackAndNothingScrollsSideways() {
    let app = launch("event-live", "event", size: "AX3")
    _ = root(app, "event")
    let roster = app.descendants(matching: .any)["event.side-roster"].firstMatch
    XCTAssertTrue(roster.waitForExistence(timeout: 20), "the side roster is drawn")
    XCTAssertEqual(app.scrollViews.matching(identifier: "event.side-roster").count, 0,
                   "the roster does not scroll sideways")
    // each side is one element, "<Side>: <names>", and there are two of them
    let sides = roster.descendants(matching: .any)
      .matching(NSPredicate(format: "label CONTAINS %@", ": ")).allElementsBoundByIndex
    XCTAssertEqual(sides.count, 2, "two sides — \(sides.map(\.label))")
    let screen = app.windows.firstMatch.frame
    for s in sides {
      XCTAssertGreaterThanOrEqual(s.frame.minX, screen.minX, "\(s.label) starts on the screen — \(s.frame)")
      XCTAssertLessThanOrEqual(s.frame.maxX, screen.maxX, "\(s.label) ends on the screen — \(s.frame)")
    }
    if sides.count == 2 {
      XCTAssertGreaterThanOrEqual(sides[1].frame.minY, sides[0].frame.maxY - 1,
                                  "the second side is under the first — \(sides[0].frame) · \(sides[1].frame)")
    }
    attach(app, "n4-ryder-sides-AX3")
    app.terminate()
  }
}
