import XCTest

/// F03 (native verification) · every presented sheet names itself, and its
/// dismissal lands back where it rose from.
///
/// What XCUITest can observe is checked here: the sheet's title is a
/// heading (the element VoiceOver's heading rotor and a screen change land
/// on), it is the first words of the sheet's content, the Close control is a
/// named 44pt target, the system accessibility audit's findings are
/// attached, and Close returns to the root underneath. Where VoiceOver's
/// cursor goes on presentation and on dismissal is the platform's sheet
/// presentation and is not observable from a simulator; that stays a device
/// check.
final class N2SheetsUITests: N2UITestCase {
  struct Sheet { let place: String; let root: String; let title: String; let under: String }
  private let sheets: [Sheet] = [
    .init(place: "receipt", root: "receipt", title: "Your round", under: "home"),
    .init(place: "bag", root: "bag", title: "Your bag", under: "home"),
    .init(place: "declare", root: "declare", title: "Put a round on the schedule", under: "home"),
    .init(place: "plan", root: "plan", title: "", under: "home"),
    .init(place: "intent", root: "intent", title: "What do you want to do?", under: "home"),
    .init(place: "tourcard", root: "tourcard", title: "Avery Fixture", under: "home"),
  ]
  /// every sheet is checked, even after one fails, so the report is whole
  override func setUp() { continueAfterFailure = true }

  /// UIAccessibilityTraits.header, read from the element's snapshot.
  private static let headerTrait: UInt64 = 1 << 16

  @MainActor private func traits(_ el: XCUIElement) -> UInt64? {
    guard let snap = try? el.snapshot() as AnyObject, snap.responds(to: NSSelectorFromString("traits")) else { return nil }
    return (snap.value(forKey: "traits") as? NSNumber)?.uint64Value
  }

  @MainActor func testF03EverySheetIsNamedByAHeadingAndClosesBackToItsRoot() throws {
    var report: [String] = []
    for s in sheets {
      let app = launch("season-live", s.place)
      let root = root(app, s.root)
      Thread.sleep(forTimeInterval: 2)
      // the sheet's words, top to bottom (the tab root underneath stays in
      // XCUITest's tree, so the sheet's own content is what sits in its frame)
      let texts = app.staticTexts.allElementsBoundByIndex.filter { $0.exists && $0.frame.minY > 40 && $0.frame.height > 0 }
      let headers = texts.filter { t in (traits(t) ?? 0) & Self.headerTrait != 0 }
      let names = headers.map { $0.label }
      let close = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Close")).firstMatch
      report.append("\(s.place): headers=\(names) close=\(close.exists ? "\(close.frame.size)" : "none")")
      if !s.title.isEmpty {
        // the tour card's title is the credential's name (CSCredential), a
        // heading since N4
        let named = names.contains { $0.caseInsensitiveCompare(s.title) == .orderedSame }
        XCTAssertTrue(named, "\(s.place): the title \(s.title) is the sheet's heading — headers: \(names)")
      }
      XCTAssertFalse(headers.isEmpty, "\(s.place): the sheet names itself with a heading")
      // the system audit, recorded rather than enforced here (its findings
      // cover more than F03 and are triaged in the report)
      var issues: [String] = []
      try? app.performAccessibilityAudit(for: [.sufficientElementDescription, .hitRegion, .trait, .elementDetection]) { issue in
        issues.append("\(issue.auditType.rawValue) · \(issue.compactDescription) · \(issue.element?.label ?? "?")")
        return true
      }
      report.append("  audit: \(issues.count) — " + issues.prefix(8).joined(separator: " | "))
      attach(app, "f03-\(s.place)")
      if close.exists && close.isHittable {
        // measured on screen: a fitted sheet is drawn scaled (≈0.96), so the
        // intent sheet's Close is `.fittedSheet`'s 48 in layout (N4)
        XCTAssertGreaterThanOrEqual(close.frame.height, 43.5, "\(s.place): Close is a 44pt target")
        XCTAssertGreaterThanOrEqual(close.frame.width, 43.5, "\(s.place): Close is a 44pt target, across too")
        close.tap()
        XCTAssertTrue(root.waitForNonExistence(timeout: 10), "\(s.place): Close takes the sheet down")
        XCTAssertTrue(app.descendants(matching: .any)["cs.screen.\(s.under)"].waitForExistence(timeout: 10),
                      "\(s.place): dismissal lands back on \(s.under)")
      }
      app.terminate()
    }
    let a = XCTAttachment(string: report.joined(separator: "\n"))
    a.name = "f03-sheets-report"; a.lifetime = .keepAlways; add(a)
  }
}
