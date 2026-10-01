import XCTest

final class RecipientJourneyUITests: XCTestCase {
  @MainActor func testAlreadyAgreedOpensTheSeasonInBothPrintingsAndAtAX3() {
    for theme in ["dark","light"] {
      var readingTitleHeight: CGFloat = 0
      for size in ["large","accessibility3"] {
        let app=XCUIApplication()
        app.terminate()
        app.launchArguments=["-cs_dev_launch_sheets","-cs_dev_join_agreed","-cs_dev_appearance",theme,"-cs_dev_text_size",size]
        app.launch()
        let open=app.buttons["covenant.openSeason"]
        // Existing simulator hatch: first launch after reinstall can lose its arguments.
        if !open.waitForExistence(timeout:15) {
          XCTContext.runActivity(named:"relaunch · recipient fixture absent on first launch") { _ in
            let note=XCTAttachment(string:app.debugDescription)
            note.name="recipient-fixture-absent";note.lifetime = .keepAlways;add(note)
            app.terminate();app.launch()
          }
        }
        XCTAssertTrue(open.waitForExistence(timeout:15))
        for _ in 0..<8 where !open.isHittable { app.swipeUp() }
        XCTAssertTrue(open.isHittable)
        XCTAssertEqual(open.label.lowercased(),"open the season")
        let title=app.staticTexts.matching(NSPredicate(format:"label ==[c] %@","North Grove (fixture)")).firstMatch
        XCTAssertTrue(title.exists)
        if size == "large" { readingTitleHeight=title.frame.height }
        else { XCTAssertGreaterThan(title.frame.height,readingTitleHeight * 1.1,"AX3 must actually enlarge the sheet text") }
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
