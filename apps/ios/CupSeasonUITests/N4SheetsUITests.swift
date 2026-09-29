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

  /// N4-171 · "This one was casual — post nothing" ends the whole group's
  /// round and posts nobody's card. It is a tertiary link now, and armed: the
  /// first tap says "Sure? Nobody’s round posts" and finishes nothing, and left
  /// alone it disarms. Read on the dev live round's finish sheet.
  @MainActor func testTheCasualFinishAsksBeforeItEndsTheGroupsRound() {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_synthetic", "season-live", "-cs_dev_appearance", "dark", "-cs_dev_look", "none",
                           "-cs_dev_text_size", "large", "-cs_dev_live"]
    app.launch()
    XCTAssertTrue(app.staticTexts["HOLE 15"].waitForExistence(timeout: 30), "the dev round is up")
    app.swipeUp(); app.swipeUp()
    let finish = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Finish the round")).firstMatch
    XCTAssertTrue(finish.waitForExistence(timeout: 10))
    finish.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    let casual = app.buttons["live.finish.casual"]
    XCTAssertTrue(casual.waitForExistence(timeout: 10), "the finish sheet is up")
    Thread.sleep(forTimeInterval: 1)
    XCTAssertTrue(casual.label.localizedCaseInsensitiveContains("post nothing"), casual.label)
    casual.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    let armed = NSPredicate(format: "label ==[c] %@", "Sure? Nobody’s round posts")
    XCTAssertEqual(XCTWaiter().wait(for: [expectation(for: armed, evaluatedWith: casual)], timeout: 3), .completed,
                   "the first tap asks — \(casual.label)")
    XCTAssertTrue(app.buttons["live.finish.confirm"].exists, "and finishes nothing: the sheet is still up")
    attach(app, "n4-171-armed")
    let disarmed = NSPredicate(format: "label CONTAINS[c] %@", "post nothing")
    XCTAssertEqual(XCTWaiter().wait(for: [expectation(for: disarmed, evaluatedWith: casual)], timeout: 8), .completed,
                   "left alone, it disarms")
    app.terminate()
  }

  /// N4-042 · at AX3 the pinned actions sheared the claim's deciding fact
  /// ("Scored as Quinn · Sat, Sep 26"). At the accessibility sizes they follow
  /// the facts in the scroll: the facts line is above them, whole.
  @MainActor func testAtAX3TheClaimsFactsComeBeforeItsActions() {
    let app = launch("season-live", "claim", size: "AX3")
    _ = root(app, "link")
    let facts = app.staticTexts["link-facts"]
    XCTAssertTrue(facts.waitForExistence(timeout: 20), "the claim says its facts")
    let confirm = app.buttons["link-confirm"]
    for _ in 0..<8 where !confirm.isHittable { app.swipeUp() }
    XCTAssertTrue(confirm.isHittable, "the claim's action is reachable")
    XCTAssertLessThanOrEqual(facts.frame.maxY, confirm.frame.minY + 1,
                             "the facts come before the action, never under it — \(facts.frame) · \(confirm.frame)")
    attach(app, "n4-042-claim-AX3")
    app.terminate()
  }

  /// N4-114 · at 260 points the when-fork cut its second answer on an SE at
  /// the reading size. A fitted sheet grows to its content now (the height is
  /// a floor): both answers are whole on the first screen, with no scroll.
  @MainActor func testTheWhenForksAnswersAreWholeWithoutAScroll() {
    let app = launch("season-live", "whenfork")
    let head = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Two ways")).firstMatch
    XCTAssertTrue(head.waitForExistence(timeout: 30), "the sheet is up")
    Thread.sleep(forTimeInterval: 2)
    let screen = app.windows.firstMatch.frame
    for words in ["right now", "this week"] {
      let answer = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", words)).firstMatch
      XCTAssertTrue(answer.exists, "\(words): the answer is there")
      XCTAssertTrue(answer.isHittable, "\(words): a target without a scroll")
      XCTAssertLessThanOrEqual(answer.frame.maxY, screen.maxY, "\(words): whole on the first screen — \(answer.frame)")
    }
    attach(app, "n4-114-whenfork")
    app.terminate()
  }
}
