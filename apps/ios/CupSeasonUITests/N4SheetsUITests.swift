import XCTest

/// N4 · N1's sheet items, measured on screen (2026-09-28).
///
/// - The intent and when-fork sheets are FITTED: iOS 26 draws a sheet at a
///   partial detent inset and scaled (386 of 402 points, 0.960), so their
///   inline Close, a 44pt layout target, measured 42.6 × 42.2. It is
///   `.csTertiary(.fittedSheet)` now, 48 in layout, 46 on the glass.
/// - The plan sheet's figures read as their numerals alone (the `5` of
///   `5 DAYS OUT`, 14.7 × 35pt), which the system audit filed as targets too
///   small to touch. Each column is one static element now: figure, rule and
///   label.
/// - "Potentially inaccessible text" on the intent sheet is the page BEHIND a
///   fitted sheet: Home, dimmed and correctly hidden from VoiceOver while the
///   sheet is up. The same sheet at its large detent audits clean, and so does
///   Home alone, which is what this pins; the fitted count is attached, not
///   asserted, because it is the platform's modality rather than the sheet.
final class N4SheetsUITests: N2UITestCase {
  private let enforced: XCUIAccessibilityAuditType = [.sufficientElementDescription, .hitRegion, .trait]

  @MainActor private func issues(_ app: XCUIApplication, _ types: XCUIAccessibilityAuditType) -> [String] {
    var found: [String] = []
    try? app.performAccessibilityAudit(for: types) { issue in
      let el = issue.element.map { "'\($0.label)' \($0.frame)" } ?? "no element"
      found.append("\(issue.auditType.rawValue) · \(issue.compactDescription) · \(el)")
      return true
    }
    return found
  }

  @MainActor func testFittedSheetsCloseIsA44ptTargetOnScreen() {
    var report: [String] = []
    for (place, words) in [("intent", "What do you want to do?"), ("whenfork", "Two ways")] {
      let app = launch("season-live", place)
      let head = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", words)).firstMatch
      XCTAssertTrue(head.waitForExistence(timeout: 30), "\(place): the sheet is up")
      Thread.sleep(forTimeInterval: 2)
      let close = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Close")).firstMatch
      XCTAssertTrue(close.exists, "\(place): Close is there")
      XCTAssertGreaterThanOrEqual(close.frame.height, 44, "\(place): Close is 44pt tall on screen — \(close.frame)")
      XCTAssertGreaterThanOrEqual(close.frame.width, 44, "\(place): Close is 44pt wide on screen — \(close.frame)")
      let found = issues(app, enforced)
      XCTAssertEqual(found, [], "\(place): no target, trait or description issue")
      let fitted = issues(app, .elementDetection)
      report.append("\(place) fitted · close \(close.frame) · element detection \(fitted.count) (the dimmed page behind)")
      attach(app, "n4-\(place)-fitted")
      if place == "intent" {
        // the same sheet at its large detent: nothing behind it, nothing found
        app.buttons["Sheet Grabber"].firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
          .press(forDuration: 0.1, thenDragTo: app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.02)))
        Thread.sleep(forTimeInterval: 2)
        let large = issues(app, [.elementDetection, .hitRegion, .sufficientElementDescription, .trait])
        XCTAssertEqual(large, [], "intent at its large detent audits clean")
        report.append("intent large · close \(close.frame) · all four audits \(large.count)")
        attach(app, "n4-intent-large")
      }
      app.terminate()
    }
    let home = launch("season-live", "home")
    _ = root(home, "home")
    Thread.sleep(forTimeInterval: 2)
    let alone = issues(home, .elementDetection)
    XCTAssertEqual(alone, [], "Home alone: no text outside the accessibility tree")
    report.append("home alone · element detection \(alone.count)")
    home.terminate()
    let a = XCTAttachment(string: report.joined(separator: "\n")); a.name = "n4-sheets-report"; a.lifetime = .keepAlways; add(a)
  }

  @MainActor func testThePlanSheetsFiguresAreWholeColumns() {
    for size in ["large", "AX3"] {
      let app = launch("season-live", "plan", size: size)
      _ = root(app, "plan")
      Thread.sleep(forTimeInterval: 2)
      for said in ["5 days out", "2 in"] {
        let cell = app.staticTexts[said]
        XCTAssertTrue(cell.waitForExistence(timeout: 10), "\(size): \(said) is a static element")
        XCTAssertGreaterThanOrEqual(cell.frame.height, 44, "\(size): \(said) is its whole column — \(cell.frame)")
        XCTAssertGreaterThanOrEqual(cell.frame.width, 44, "\(size): \(said) is its whole column — \(cell.frame)")
      }
      let found = issues(app, enforced)
      XCTAssertEqual(found, [], "\(size): the plan sheet has no target, trait or description issue")
      attach(app, "n4-plan-\(size)")
      app.terminate()
    }
  }
}
