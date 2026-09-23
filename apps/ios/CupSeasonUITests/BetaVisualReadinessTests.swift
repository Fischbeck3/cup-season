import XCTest

/// The real competition renderer with its existing, server-free payload.
/// This checks layout and action reachability; recipient and navigation proof
/// on an authenticated phone remains part of the Owner beta checklist.
final class BetaVisualReadinessTests: XCTestCase {
  @MainActor func testCompetitionRowsAndPrimaryStayReachableInBothRooms() {
    for (room, size) in [("dark", "large"), ("light", "large"), ("dark", "AX3"), ("light", "AX3")] {
      let app = XCUIApplication()
      app.launchArguments = ["-cs_dev_compete_fixture", "-cs_dev_look", "none",
                             "-cs_dev_appearance", room, "-cs_dev_text_size", size]
      app.launch()
      let row = app.descendants(matching: .any)
        .matching(NSPredicate(format: "identifier BEGINSWITH %@", "compete.row.")).firstMatch
      XCTAssertTrue(row.waitForExistence(timeout: 20))
      XCTAssertGreaterThanOrEqual(row.frame.minX, app.frame.minX)
      XCTAssertLessThanOrEqual(row.frame.maxX, app.frame.maxX)
      XCTAssertGreaterThanOrEqual(row.frame.height, 44)
      capture(app, "competition-top-\(room)-\(size)")
      let start = app.buttons.matching(NSPredicate(format: "label =[c] %@", "Start something")).firstMatch
      XCTAssertTrue(start.exists)
      for _ in 0..<8 where !start.isHittable { app.swipeUp() }
      XCTAssertTrue(start.isHittable)
      // A partially exposed button can be hittable. Bring the complete label
      // into view before capturing it, including on the short AX3 phone.
      let top = app.frame.minY + 80
      let bottom = app.frame.maxY - 44
      for _ in 0..<8 {
        if start.frame.minY < top {
          app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55)))
        } else if start.frame.maxY > bottom {
          app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)))
        } else { break }
      }
      XCTAssertGreaterThanOrEqual(start.frame.minY, top)
      XCTAssertLessThanOrEqual(start.frame.maxY, bottom)
      XCTAssertLessThanOrEqual(start.frame.maxX, app.frame.maxX)
      capture(app, "competition-action-\(room)-\(size)")
      app.terminate()
    }
  }

  @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = name; shot.lifetime = .keepAlways; add(shot)
  }
}
