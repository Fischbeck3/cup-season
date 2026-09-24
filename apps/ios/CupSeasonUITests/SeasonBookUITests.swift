import XCTest
final class SeasonBookUITests: XCTestCase {
  @MainActor private func launch(_ fixture: String="squads",screen:String="book",extra:[String]=[]) -> XCUIApplication {
    let app=XCUIApplication();app.launchArguments=["-cs_dev_compete_selected","-cs_selected_fixture",fixture,"-cs_selected_screen",screen,"-cs_dev_appearance","dark","-cs_dev_look","none"]+extra;app.launch();return app
  }
  @MainActor func testRealMatrixFreezesNamesAndOpensIncludedAndDroppedReceipts() {
    let app=launch(), id="squad:c50b0000-0000-4000-8000-000000000300"
    let name=app.buttons["seasonBook.name."+id]
    XCTAssertTrue(name.waitForExistence(timeout:15));let x=name.frame.minX
    app.buttons["seasonBook.cell."+id+".2"].swipeLeft()
    XCTAssertEqual(name.frame.minX,x,accuracy:1);name.tap()
    XCTAssertTrue(app.staticTexts["seasonBook.receipt.total"].waitForExistence(timeout:5))
    XCTAssertTrue(app.buttons["Open round receipt"].firstMatch.exists)
  }
  @MainActor func testSmallTieUsesTwoEqualPointsRanksAndTheCompactRead() {
    let app=launch("tie")
    XCTAssertTrue(app.staticTexts["seasonBook.title"].waitForExistence(timeout:15))
    XCTAssertEqual(app.staticTexts["seasonBook.title"].label.lowercased(),"rounds & points")
    XCTAssertFalse(app.segmentedControls["seasonBook.mode"].exists)
    XCTAssertEqual(app.staticTexts.matching(identifier:"1st · Tied").count,2)
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
}
