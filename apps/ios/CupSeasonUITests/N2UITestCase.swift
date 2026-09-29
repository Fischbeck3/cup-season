import XCTest

/// N2 · the shared launcher for the ten program's regression checks on the
/// live, post, record and share views, over the DEBUG-only synthetic world
/// (`-cs_dev_synthetic`). Every launch names its scenario and place; nothing
/// signs in to anything and nothing leaves the simulator.
class N2UITestCase: XCTestCase {
  override func setUp() { continueAfterFailure = false }

  @MainActor func launch(_ scenario: String, _ place: String, _ detail: String? = nil,
                         size: String? = nil, theme: String = "dark", extra: [String] = []) -> XCUIApplication {
    let app = XCUIApplication()
    var args = ["-cs_dev_synthetic", scenario, "-cs_dev_open", place]
    if let detail { args.append(detail) }
    args += ["-cs_dev_appearance", theme, "-cs_dev_look", "none"]
    // the reading size is pinned, never inherited: a simulator left at an
    // accessibility size would otherwise run a default-size test at AX3
    args += ["-cs_dev_text_size", size ?? "large"]
    app.launchArguments = args + extra
    app.launch()
    return app
  }

  @MainActor func root(_ app: XCUIApplication, _ name: String, timeout: TimeInterval = 30) -> XCUIElement {
    let mark = app.descendants(matching: .any)["cs.screen.\(name)"]
    XCTAssertTrue(mark.waitForExistence(timeout: timeout), "the \(name) root never appeared")
    return mark
  }

  @MainActor func attach(_ app: XCUIApplication, _ name: String) {
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = name; shot.lifetime = .keepAlways; add(shot)
  }
}

extension XCUIApplication {
  /// W5 · the Book's grid opens on its current week, so a cell can sit on
  /// either side of the view. Swipe the GRID toward the cell — never the cell:
  /// an offscreen cell has no visible frame to swipe on — until it can be
  /// tapped.
  @MainActor func revealBookCell(_ cell: XCUIElement, tries: Int = 8) {
    let grid = scrollViews["seasonBook.grid"]
    guard grid.exists else { return }
    for _ in 0..<tries where cell.exists && !cell.isHittable {
      if cell.frame.midX < grid.frame.midX { grid.swipeRight() } else { grid.swipeLeft() }
    }
  }

  /// **A field to type into must be clear of the bars and of the keyboard.**
  /// XCUITest scrolls an element into view only when something in the app's
  /// own tree covers its centre, and neither the status bar's strip nor the
  /// keyboard is in that tree: a centre in the strip (the composer's course
  /// field after the rating and slope, E's 17 Pro) or on the keyboard's top
  /// edge (root's 17 Pro, software keyboard up) reads as hittable, and the tap
  /// lands on the bar or on a key. Drag the page until the field sits between
  /// the two, tap it, and assert the cursor is in it before anything is typed.
  @MainActor func tapToType(_ field: XCUIElement, tries: Int = 4) {
    for _ in 0..<tries where field.exists {
      let bar = navigationBars.firstMatch
      let top = bar.exists ? bar.frame.maxY : windows.firstMatch.frame.minY + 62
      let keyboard = keyboards.firstMatch
      let bottom = keyboard.exists ? keyboard.frame.minY : windows.firstMatch.frame.maxY
      let f = field.frame
      if f.minY >= top, f.maxY <= bottom - 8 { break }
      if f.midY < top { swipeDown(velocity: .slow) } else { swipeUp(velocity: .slow) }
    }
    field.tap()
    let focused = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasKeyboardFocus == true"), object: field)
    if XCTWaiter().wait(for: [focused], timeout: 3) != .completed { field.tap() }
    XCTAssertEqual(XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasKeyboardFocus == true"),
                                                                    object: field)], timeout: 3), .completed,
                   "the field took the cursor before anything was typed")
  }
}
