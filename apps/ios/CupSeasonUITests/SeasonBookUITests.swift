import XCTest
final class SeasonBookUITests: XCTestCase {
  @MainActor private func launch(_ fixture: String="squads",screen:String="book",extra:[String]=[]) -> XCUIApplication {
    let app=XCUIApplication();app.launchArguments=["-cs_dev_compete_selected","-cs_selected_fixture",fixture,"-cs_selected_screen",screen,"-cs_dev_appearance","dark","-cs_dev_look","none"]+extra;app.terminate();app.launch();return app
  }
  @MainActor func testRealMatrixFreezesNamesAndOpensIncludedAndDroppedReceipts() {
    let app=launch(), id="squad:c50b0000-0000-4000-8000-000000000300"
    let name=app.buttons["seasonBook.name."+id]
    XCTAssertTrue(name.waitForExistence(timeout:15));let x=name.frame.minX
    // the grid opens on its week (W5): swipe it both ways, and the names hold
    let grid=app.scrollViews["seasonBook.grid"];XCTAssertTrue(grid.exists)
    grid.swipeRight();XCTAssertEqual(name.frame.minX,x,accuracy:1)
    grid.swipeLeft();XCTAssertEqual(name.frame.minX,x,accuracy:1);name.tap()
    XCTAssertTrue(app.staticTexts["seasonBook.receipt.total"].waitForExistence(timeout:5))
    XCTAssertTrue(app.buttons["Open the round’s receipt"].firstMatch.exists)
  }
  @MainActor func testSmallTieUsesTwoEqualPointsRanksAndTheCompactRead() {
    let app=launch("tie")
    XCTAssertTrue(app.staticTexts["seasonBook.title"].waitForExistence(timeout:15))
    XCTAssertEqual(app.staticTexts["seasonBook.title"].label.lowercased(),"rounds & points")
    XCTAssertFalse(app.segmentedControls["seasonBook.mode"].exists)
    // W5 · the reader's own row reads "You · 1st · Tied": both tied rows end the same
    XCTAssertEqual(app.staticTexts.matching(NSPredicate(format:"label ENDSWITH %@","1st · Tied")).count,2)
  }
  @MainActor func testRealRootUsesTheSameTieAndOpensTheBookDoor() {
    let app=launch("tie",screen:"root")
    XCTAssertTrue(app.staticTexts["1st · Tied"].waitForExistence(timeout:15))
    let door=app.buttons["Rounds & points"]
    for _ in 0..<3 where !door.isHittable { app.swipeUp() }
    XCTAssertTrue(door.exists);door.tap()
    XCTAssertTrue(app.staticTexts["seasonBook.title"].waitForExistence(timeout:5))
    XCTAssertEqual(app.staticTexts["seasonBook.title"].label.lowercased(),"rounds & points")
  }
  @MainActor func testAccessibilityUsesWeekPickerAndRaceCanBeSelected() {
    let app=launch(extra:["-cs_dev_text_size","ax3"])
    let picker=app.buttons["seasonBook.week"]
    for _ in 0..<3 where !picker.isHittable { app.swipeUp() }
    XCTAssertTrue(picker.waitForExistence(timeout:15))
    app.terminate()
    let race=launch(extra:["-cs_selected_mode","Race"])
    XCTAssertTrue(race.staticTexts["seasonBook.race.title"].waitForExistence(timeout:15))
  }
  @MainActor func testDelayedRefreshKeepsTheGolfersViewAndTotals() {
    let app=launch(extra:["-cs_selected_refresh_read","yes"])
    let group=app.segmentedControls["seasonBook.group"]
    XCTAssertTrue(group.waitForExistence(timeout:15))
    group.buttons["Golfers"].tap()
    let mode=app.segmentedControls["seasonBook.mode"]
    mode.buttons["Totals"].tap()
    let scroll=app.scrollViews["seasonBook.scroll"]
    XCTAssertEqual(scroll.value as? String,"Book read 1")
    scroll.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.2))
      .press(forDuration:0.05,thenDragTo:scroll.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.85)))
    let completed=NSPredicate(format:"value == %@","Book read 2")
    expectation(for:completed,evaluatedWith:scroll)
    waitForExpectations(timeout:10)
    XCTAssertTrue(group.waitForExistence(timeout:10))
    XCTAssertTrue(group.buttons["Golfers"].isSelected)
    XCTAssertTrue(mode.buttons["Totals"].isSelected)
    let shot=XCTAttachment(screenshot:app.screenshot()); shot.name="Book refreshed · Golfers and Totals"; shot.lifetime = .keepAlways; add(shot)
  }

}
