import XCTest

final class N2BookUITests: N2UITestCase {
  // MARK: F11 · the Book

  /// A Book cell is a figure with its status marks beside it, says the
  /// status in words, keeps the key above the grid beside the Display
  /// control, and still opens receipts that add up to the cell (§16).
  @MainActor func testF11BookCellsSayTheirStatusAndTheKeyLeadsTheGrid() {
    let app = launch("season-live", "book", "squads")
    _ = root(app, "book")
    let golfers = app.segmentedControls.buttons["Golfers"]
    XCTAssertTrue(golfers.waitForExistence(timeout: 10))
    golfers.tap()
    let key = app.staticTexts["seasonBook.key"]
    XCTAssertTrue(key.waitForExistence(timeout: 10), "the key is on screen with the grid")
    let cells = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'seasonBook.cell.'"))
    XCTAssertGreaterThan(cells.count, 0)
    XCTAssertLessThanOrEqual(key.frame.maxY, cells.element(boundBy: 0).frame.minY + 1, "the key sits above the grid")
    let mode = app.segmentedControls["seasonBook.mode"]
    XCTAssertTrue(mode.exists)
    XCTAssertGreaterThan(key.frame.minY, mode.frame.maxY - 1, "the key follows the Display control")
    // a marked cell says its status in words, after the golfer's name
    let marked = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'seasonBook.cell.' AND (label CONTAINS 'dropped rounds retained in receipt' OR label CONTAINS 'adjustment or bye recorded')")).firstMatch
    XCTAssertTrue(marked.exists, "some cell carries a status mark")
    let label = marked.label
    XCTAssertTrue(label.range(of: #"^.+, \d+ points in week \d+"#, options: .regularExpression) != nil, label)
    attach(app, "f11-book-golfers")
    // §16 · its receipt adds up to the cell
    let points = Int(label.components(separatedBy: ", ").dropFirst().first?.components(separatedBy: " ").first ?? "")
    for _ in 0..<3 where !marked.isHittable { marked.swipeLeft() }
    marked.tap()
    let total = app.staticTexts["seasonBook.receipt.total"]
    XCTAssertTrue(total.waitForExistence(timeout: 5))
    XCTAssertEqual(Int(total.label.components(separatedBy: " ").first ?? ""), points, "the receipt adds up to the cell")
  }
}
