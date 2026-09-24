import XCTest

final class CompeteExplorationUITests: XCTestCase {
  @MainActor private func launch(_ direction: String = "scoreboard", fixture: String = "field", screen: String = "book", extra: [String] = []) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_compete_exploration", direction, "-cs_explore_fixture", fixture,
      "-cs_explore_screen", screen, "-cs_explore_mode", "Weeks", "-cs_dev_appearance", "dark",
      "-cs_dev_look", "none"] + extra
    app.launch()
    return app
  }

  @MainActor func testCellOpensItsReceiptAndDroppedRoundStaysVisible() {
    let app = launch(extra: ["-cs_explore_week", "12"])
    let cell = app.buttons["explore.cell.member-1.12"]
    XCTAssertTrue(cell.waitForExistence(timeout: 15))
    cell.tap()
    XCTAssertTrue(app.staticTexts["explore.receipt.total"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["explore.receipt.total"].label, "12 points")
    XCTAssertTrue(app.staticTexts["5 points · dropped"].exists)
    let entry = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "explore.receipt.")).firstMatch
    entry.tap()
    XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label ==[c] %@", "Round receipt")).firstMatch.waitForExistence(timeout: 5))
  }

  @MainActor func testHorizontalWeeksKeepNamesFixed() {
    let app = launch()
    let name = app.buttons["explore.name.member-0"]
    XCTAssertTrue(name.waitForExistence(timeout: 15))
    let before = name.frame
    let cell = app.buttons["explore.cell.member-0.2"]
    XCTAssertTrue(cell.exists)
    cell.swipeLeft()
    XCTAssertEqual(name.frame.minX, before.minX, accuracy: 1)
    XCTAssertEqual(name.frame.width, before.width, accuracy: 1)
    XCTAssertTrue(name.isHittable)
  }

  @MainActor func testAccessibilityUsesWeekRowsAndSquadsCanSwitchToContributions() {
    let app = launch("race", fixture: "squads", extra: ["-cs_dev_text_size", "ax3"])
    XCTAssertTrue(app.buttons["explore.week.picker"].waitForExistence(timeout: 15))
    app.segmentedControls.buttons["Golfers"].tap()
    let row = app.buttons["explore.ax.row.member-0"]
    for _ in 0..<3 where !row.isHittable { app.swipeUp() }
    XCTAssertTrue(row.isHittable)
    row.tap()
    XCTAssertTrue(app.staticTexts["explore.receipt.total"].waitForExistence(timeout: 5))
  }

  @MainActor func testSquadContributionFilterAlsoScopesAdjustments() {
    let app = launch(fixture: "squads", screen: "adjustments",
                     extra: ["-cs_explore_group", "golfers", "-cs_explore_squad", "0"])
    XCTAssertTrue(app.staticTexts["No adjustments recorded for this selection."].waitForExistence(timeout: 15))
    XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "August minimum:")).firstMatch.exists)
  }

  @MainActor func testAllDirectionsOpenSmallLeagueReceiptsWithoutInventingSecondPlace() {
    for direction in ["scoreboard", "race", "broadsheet"] {
      let app = launch(direction, fixture: "tie", screen: "entry")
      let door = app.buttons["explore.book"]
      XCTAssertTrue(door.waitForExistence(timeout: 15))
      XCTAssertFalse(app.staticTexts["2nd"].exists)
      door.tap()
      XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label ==[c] %@", "Rounds & points")).firstMatch.waitForExistence(timeout: 5))
      app.terminate()
    }
  }
}
