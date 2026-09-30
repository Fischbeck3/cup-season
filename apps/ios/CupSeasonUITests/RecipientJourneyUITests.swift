import XCTest

final class RecipientJourneyUITests: XCTestCase {
  @MainActor func testAlreadyAgreedOpensTheSeasonInBothPrintingsAndAtAX3() {
    for theme in ["dark","light"] {
      for size in ["large","accessibility3"] {
        let app=XCUIApplication()
        app.launchArguments=["-cs_dev_launch_sheets","-cs_dev_join_agreed","-cs_dev_appearance",theme,"-cs_dev_text_size",size]
        app.terminate();app.launch()
        let open=app.buttons["covenant.openSeason"]
        XCTAssertTrue(open.waitForExistence(timeout:30))
        for _ in 0..<8 where !open.isHittable { app.swipeUp() }
        XCTAssertTrue(open.isHittable)
        XCTAssertEqual(open.label.lowercased(),"open the season")
        XCTAssertGreaterThanOrEqual(open.frame.height,43.99)
        let shot=XCTAttachment(screenshot:app.screenshot())
        shot.name="agreed-season-\(theme)-\(size)";shot.lifetime = .keepAlways;add(shot)
        open.tap()
        XCTAssertTrue(app.staticTexts["recipient.opened"].waitForExistence(timeout:10))
        app.terminate()
      }
    }
  }
}
