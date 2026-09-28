// S2/C3 · the synthetic fixture seam, driven by XCUITest.
//
// Two kinds of test live here, and the difference matters:
//
//   · `testCapturePlan` is the capture runner's engine. It launches the app on
//     `-cs_dev_synthetic <scenario> -cs_dev_open <route>`, waits for the root
//     the route promises (`cs.screen.<root>`), records what the root reported
//     (unanswered and failed requests), and attaches the screenshot. A capture
//     whose root never appeared is recorded as FAILED — it is never a shot of
//     whatever screen happened to be up. The plan comes from the runner through
//     the environment (`CS_FX_PLAN`); with no plan the test does nothing.
//
//   · The flow tests are MOCKED-FLOW checks of navigation and state handling
//     against invented data. They prove a finger can walk a path in the real
//     app; they prove nothing about a real account, a real network or scoring
//     integrity, which stay owner-run checks.
//
// Every identity these tests see is invented (see Dev/Synthetic/). Nothing here
// signs in, and nothing a synthetic launch writes leaves the simulator.

import XCTest

final class SyntheticRouteTests: XCTestCase {

  // MARK: launching

  @MainActor private func launch(_ scenario: String, _ route: String? = nil, _ detail: String? = nil,
                                 theme: String = "dark", size: String? = nil, extra: [String] = []) -> XCUIApplication {
    let app = XCUIApplication()
    var args = ["-cs_dev_synthetic", scenario]
    if let route { args += ["-cs_dev_open", route] + (detail.map { [$0] } ?? []) }
    args += ["-cs_dev_appearance", theme, "-cs_dev_look", "none"]
    if let size { args += ["-cs_dev_text_size", size] }
    app.launchArguments = args + extra
    app.launch()
    return app
  }

  @MainActor private func mark(_ app: XCUIApplication, _ root: String) -> XCUIElement {
    app.descendants(matching: .any)["cs.screen.\(root)"]
  }

  @MainActor private func reveal(_ e: XCUIElement, in app: XCUIApplication, swipes: Int = 8) {
    for _ in 0..<swipes where !e.isHittable { app.swipeUp() }
  }

  @MainActor private func attach(_ app: XCUIApplication, _ name: String) {
    let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    shot.name = name
    shot.lifetime = .keepAlways
    add(shot)
  }

  // MARK: the capture runner's engine

  /// One entry of the runner's plan.
  private struct PlanEntry: Decodable {
    let name: String
    let scenario: String
    let route: String?
    let detail: String?
    let root: String
    let extra: [String]?
    let settle: Double?
    /// An optional XCUITest step before the shot: "keyboard" focuses the first
    /// text field and waits for the keyboard.
    let step: String?
  }

  @MainActor func testCapturePlan() throws {
    let env = ProcessInfo.processInfo.environment
    guard let raw = env["CS_FX_PLAN"], let data = raw.data(using: .utf8) else {
      throw XCTSkip("no CS_FX_PLAN in the environment")
    }
    continueAfterFailure = true
    let plan = try JSONDecoder().decode([PlanEntry].self, from: data)
    let themes = (env["CS_FX_THEMES"] ?? "dark,light").split(separator: ",").map(String.init)
    let size = env["CS_FX_SIZE"] ?? "large"
    for entry in plan {
      for theme in themes {
        let app = launch(entry.scenario, entry.route, entry.detail, theme: theme, size: size, extra: entry.extra ?? [])
        let root = locate(app, entry.root)
        let found = root.waitForExistence(timeout: 30)
        if found, entry.step == "keyboard" {
          let field = app.textFields.firstMatch
          reveal(field, in: app)
          if field.exists { field.tap() }
          _ = app.keyboards.firstMatch.waitForExistence(timeout: 6)
        }
        Thread.sleep(forTimeInterval: entry.settle ?? 2.0)
        let value = found ? ((root.value as? String) ?? "") : ""
        let verdict = found ? "PASS" : "FAIL"
        let counters = value.replacingOccurrences(of: "=", with: "-").replacingOccurrences(of: " ", with: "_")
        attach(app, "fx__\(entry.name)__\(theme)__\(size)__\(verdict)__\(counters)")
        let record = XCTAttachment(string: """
        {"name":"\(entry.name)","theme":"\(theme)","size":"\(size)","root":"\(entry.root)","found":\(found),"value":"\(value)","arguments":\(argumentsJSON(app))}
        """)
        record.name = "fxrecord__\(entry.name)__\(theme)__\(size)"
        record.lifetime = .keepAlways
        add(record)
        XCTAssertTrue(found, "root cs.screen.\(entry.root) for \(entry.name)")
        app.terminate()
      }
    }
  }

  /// A plan root: `cs.screen.<name>` by default; `id:<identifier>` for a
  /// review host's own identifier; `text:<label>` for a pushed page that
  /// names itself; `contains:<words>` for a sheet whose head carries a name.
  @MainActor private func locate(_ app: XCUIApplication, _ root: String) -> XCUIElement {
    if root.hasPrefix("id:") { return app.descendants(matching: .any)[String(root.dropFirst(3))] }
    if root.hasPrefix("text:") { return app.staticTexts[String(root.dropFirst(5))].firstMatch }
    if root.hasPrefix("contains:") {
      return app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", String(root.dropFirst(9)))).firstMatch
    }
    return mark(app, root)
  }

  private func argumentsJSON(_ app: XCUIApplication) -> String {
    let data = (try? JSONSerialization.data(withJSONObject: app.launchArguments)) ?? Data("[]".utf8)
    return String(decoding: data, as: UTF8.self)
  }

  /// `CS_FX_DUMP="<scenario> <route> [detail]"` · the accessibility tree of a
  /// synthetic screen, as an attachment — how a lane finds the identifier or
  /// label a new check should wait on. Skips without the variable.
  @MainActor func testDumpAccessibility() throws {
    guard let spec = ProcessInfo.processInfo.environment["CS_FX_DUMP"] else { throw XCTSkip("no CS_FX_DUMP") }
    let parts = spec.split(separator: " ").map(String.init)
    let app = launch(parts[0], parts.count > 1 ? parts[1] : nil, parts.count > 2 ? parts[2] : nil)
    Thread.sleep(forTimeInterval: 8)
    let tree = XCTAttachment(string: app.debugDescription)
    tree.name = "tree__" + parts.joined(separator: "_")
    tree.lifetime = .keepAlways
    add(tree)
    attach(app, "tree__" + parts.joined(separator: "_"))
  }

  // MARK: I03 · mocked-flow checks

  /// The one dismiss verb. The toolbar style prints it in capitals, and the
  /// label carries the capitals too, so it is matched without case.
  @MainActor private func closeButton(_ app: XCUIApplication) -> XCUIElement {
    app.buttons.matching(NSPredicate(format: "label ==[c] %@", "close")).firstMatch
  }

  /// The band's own button for a destination: the lowest button wearing the
  /// label, so a row that says "You" on the page is never the one tapped.
  @MainActor private func tab(_ app: XCUIApplication, _ label: String) -> XCUIElement {
    let all = app.buttons.matching(NSPredicate(format: "label == %@", label)).allElementsBoundByIndex
    return all.max { $0.frame.minY < $1.frame.minY } ?? app.buttons[label].firstMatch
  }

  /// The five destinations, by the band: Home, Compete, the Play cover (a
  /// verb, which presents and snaps back), Golfers and You.
  @MainActor func testFiveTabNavigation() {
    let app = launch("season-live")
    XCTAssertTrue(mark(app, "home").waitForExistence(timeout: 30))
    tab(app, "Compete").tap()
    XCTAssertTrue(mark(app, "compete").waitForExistence(timeout: 10))
    tab(app, "Golfers").tap()
    XCTAssertTrue(mark(app, "golfers").waitForExistence(timeout: 10))
    tab(app, "You").tap()
    XCTAssertTrue(mark(app, "you").waitForExistence(timeout: 10))
    tab(app, "Play").tap()
    XCTAssertTrue(mark(app, "post").waitForExistence(timeout: 10))
    let close = closeButton(app)
    XCTAssertTrue(close.waitForExistence(timeout: 5))
    close.tap()
    XCTAssertTrue(mark(app, "you").waitForExistence(timeout: 10))
    tab(app, "Home").tap()
    XCTAssertTrue(mark(app, "home").waitForExistence(timeout: 10))
  }

  /// §16's path, on the squads season (whose Book is the full grid): the
  /// season, its Book, a week's cell, the rounds and corrections behind it,
  /// and through one of them to the round's own receipt.
  @MainActor func testSeasonBookCellToRoundReceipt() {
    let app = launch("season-live", "season", "squads")
    XCTAssertTrue(mark(app, "season").waitForExistence(timeout: 30))
    let door = app.buttons["seasonBook.door"]
    XCTAssertTrue(door.waitForExistence(timeout: 15))
    reveal(door, in: app)
    door.tap()
    XCTAssertTrue(app.staticTexts["seasonBook.title"].waitForExistence(timeout: 15))
    let cells = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND isEnabled == true", "seasonBook.cell."))
    XCTAssertTrue(cells.firstMatch.waitForExistence(timeout: 10))
    cells.firstMatch.tap()
    XCTAssertTrue(app.staticTexts["seasonBook.receipt.total"].waitForExistence(timeout: 10))
    attach(app, "flow__book-cell-receipts")
    let round = app.buttons["Open round receipt"].firstMatch
    reveal(round, in: app)
    XCTAssertTrue(round.waitForExistence(timeout: 5))
    round.tap()
    XCTAssertTrue(mark(app, "receipt").waitForExistence(timeout: 15))
    attach(app, "flow__book-round-receipt")
  }

  /// The other half of §16: a correction is in the Book with its reason.
  @MainActor func testSeasonBookShowsAdjustmentReason() {
    let app = launch("season-live", "book")
    XCTAssertTrue(mark(app, "book").waitForExistence(timeout: 30))
    let row = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Gray Dummyton")).firstMatch
    reveal(row, in: app)
    XCTAssertTrue(row.waitForExistence(timeout: 10))
    row.tap()
    XCTAssertTrue(app.staticTexts["seasonBook.receipt.total"].waitForExistence(timeout: 10))
    let reason = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "corrected by the Pro")).firstMatch
    reveal(reason, in: app)
    XCTAssertTrue(reason.waitForExistence(timeout: 5))
    attach(app, "flow__book-adjustment")
  }

  /// The composer opens, takes the keyboard, and lets go without posting.
  @MainActor func testComposerKeyboardAndCancel() {
    let app = launch("season-live", "postround")
    XCTAssertTrue(mark(app, "composer").waitForExistence(timeout: 30))
    let gross = app.textFields["Your gross"].firstMatch
    XCTAssertTrue(gross.waitForExistence(timeout: 10))
    if !app.keyboards.firstMatch.exists { gross.tap() }
    XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 6))
    attach(app, "flow__composer-keyboard")
    app.buttons["Back"].firstMatch.tap()
    let close = closeButton(app)
    XCTAssertTrue(close.waitForExistence(timeout: 8))
    close.tap()
    XCTAssertTrue(mark(app, "home").waitForExistence(timeout: 10))
    XCTAssertFalse(mark(app, "composer").exists)
  }

  /// The share preview opens from the receipt and closes without sharing.
  @MainActor func testSharePreviewCancel() {
    let app = launch("season-live", "receipt")
    XCTAssertTrue(mark(app, "receipt").waitForExistence(timeout: 30))
    let share = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] %@", "Share round")).firstMatch
    reveal(share, in: app)
    XCTAssertTrue(share.waitForExistence(timeout: 10))
    share.tap()
    let send = app.buttons["round.share.send"]
    XCTAssertTrue(send.waitForExistence(timeout: 10))
    attach(app, "flow__share-preview")
    closeButton(app).tap()
    XCTAssertTrue(send.waitForNonExistence(timeout: 10))
    XCTAssertTrue(mark(app, "receipt").exists)
  }

  /// The Album's read fails once and its retry lands. Until F16 ships the
  /// Album renders its EMPTY state for a failed read, with no retry — that
  /// known gap is recorded here rather than hidden.
  @MainActor func testAlbumFailureThenRetry() {
    let app = launch("failures", "album")
    XCTAssertTrue(mark(app, "album").waitForExistence(timeout: 30))
    Thread.sleep(forTimeInterval: 2)
    attach(app, "flow__album-failed")
    let retry = app.buttons["Try again"].firstMatch
    guard retry.waitForExistence(timeout: 5) else {
      XCTExpectFailure("F16 · a failed Album read renders the empty state with no retry", options: .nonStrict())
      XCTFail("album failed read offers no retry")
      return
    }
    Thread.sleep(forTimeInterval: 1.2)
    retry.tap()
    XCTAssertTrue(retry.waitForNonExistence(timeout: 10))
    attach(app, "flow__album-retried")
  }

  /// The season page's failed read, and its retry.
  @MainActor func testSeasonFailureThenRetry() {
    let app = launch("failures", "season")
    XCTAssertTrue(mark(app, "season").waitForExistence(timeout: 30))
    let retry = app.buttons["Try again"].firstMatch
    XCTAssertTrue(retry.waitForExistence(timeout: 15))
    attach(app, "flow__season-failed")
    Thread.sleep(forTimeInterval: 1.2)
    retry.tap()
    XCTAssertTrue(retry.waitForNonExistence(timeout: 15))
    attach(app, "flow__season-retried")
  }
}
