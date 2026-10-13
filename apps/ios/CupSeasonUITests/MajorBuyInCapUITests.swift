import XCTest

/// D412 · a Major's buy-in takes the same $200 ceiling as every other money
/// field. The setup sheet is reached the way a golfer reaches it (the event
/// picker's "A Major" row) over the synthetic world, and a typed 250 must read
/// back as 200 with the shared ceiling line under the field.
final class MajorBuyInCapUITests: N2UITestCase {
  @MainActor func testTheBuyInFieldHoldsTheCeiling() {
    let app = launch("season-live", "eventpicker")
    let major = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "A Major")).firstMatch
    XCTAssertTrue(major.waitForExistence(timeout: 30), "the picker offers a Major")
    major.tap()

    let field = app.textFields["Buy-in per golfer, dollars"].firstMatch
    XCTAssertTrue(field.waitForExistence(timeout: 15), "the Major's setup sheet opens on its buy-in field")
    let ceiling = app.staticTexts["Up to $200 a golfer."].firstMatch
    XCTAssertTrue(ceiling.waitForExistence(timeout: 5), "the ceiling line sits under the buy-in")
    attach(app, "major-setup-buy-in-line")

    app.tapToType(field)
    // the field opens on "0": clear it, then type past the ceiling
    field.typeText(XCUIKeyboardKey.delete.rawValue)
    field.typeText("250")
    let held = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "200"), object: field)
    XCTAssertEqual(XCTWaiter().wait(for: [held], timeout: 5), .completed,
                   "a typed 250 reads back as the $200 ceiling, not \(field.value as? String ?? "nothing")")
    attach(app, "major-setup-buy-in-ceiling")
  }
}
