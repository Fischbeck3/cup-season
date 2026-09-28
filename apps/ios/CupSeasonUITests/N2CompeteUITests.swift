import XCTest

final class N2CompeteUITests: N2UITestCase {
  // MARK: F12 · Compete's one start

  @MainActor func testF12CompeteOffersOneStartEmptyOrNot() {
    for scenario in ["brand-new", "season-live"] {
      let app = launch(scenario, "compete")
      _ = root(app, "compete")
      let starts = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Start something"))
      XCTAssertTrue(starts.firstMatch.waitForExistence(timeout: 15))
      if scenario == "season-live" {
        for _ in 0..<4 where !starts.firstMatch.isHittable { app.swipeUp() }
      }
      XCTAssertEqual(starts.count, 1, "\(scenario): one Start something, one accessible action")
      XCTAssertGreaterThanOrEqual(starts.firstMatch.frame.height, 44, "\(scenario): a 44pt target")
      attach(app, "f12-compete-\(scenario)")
      app.terminate()
    }
  }
}
