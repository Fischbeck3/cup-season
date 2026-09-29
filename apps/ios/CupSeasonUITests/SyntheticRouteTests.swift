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

  /// The reading size is PINNED, never inherited (as `N2UITestCase` pins
  /// it): a simulator left at an accessibility size by a capture pass ran
  /// the default-size flows at AX3, where the live page's Finish sits three
  /// swipes lower and the recap never came up (N4, 2026-09-28).
  @MainActor private func launch(_ scenario: String, _ route: String? = nil, _ detail: String? = nil,
                                 theme: String = "dark", size: String? = "large", extra: [String] = []) -> XCUIApplication {
    let app = XCUIApplication()
    var args = ["-cs_dev_synthetic", scenario]
    if let route { args += ["-cs_dev_open", route] + (detail.map { [$0] } ?? []) }
    args += ["-cs_dev_appearance", theme] + (extra.contains("-cs_dev_look") ? [] : ["-cs_dev_look", "none"])
    // an explicit `-cs_dev_text_size` in `extra` (a dump at AX3) wins over the pin
    if let size, !extra.contains("-cs_dev_text_size") { args += ["-cs_dev_text_size", size] }
    app.launchArguments = args + extra
    app.launch()
    // Every synthetic launch draws at least one `cs.screen.*` mark (the boot's
    // own states are marked). The first launch straight after xcodebuild
    // reinstalls the app has been seen to come up WITHOUT its launch arguments:
    // a plain DEBUG boot on the local default backend, no seam, the door. That
    // is the harness failing, not the screen: relaunch once, and say so in the
    // results. A second miss is left to fail the test.
    if !anyMark(app).waitForExistence(timeout: 15) {
      XCTContext.runActivity(named: "relaunch · the synthetic seam did not engage on the first launch") { _ in
        attach(app, "relaunch__seam-absent")
        app.terminate()
        app.launch()
      }
    }
    return app
  }

  @MainActor private func anyMark(_ app: XCUIApplication) -> XCUIElement {
    app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "cs.screen.")).firstMatch
  }

  @MainActor private func mark(_ app: XCUIApplication, _ root: String) -> XCUIElement {
    app.descendants(matching: .any)["cs.screen.\(root)"]
  }

  @MainActor private func reveal(_ e: XCUIElement, in app: XCUIApplication, swipes: Int = 8) {
    for _ in 0..<swipes where !e.isHittable { app.swipeUp() }
  }

  /// Waits until an element stops moving (a sheet or pager still sliding in
  /// would otherwise be photographed mid-flight), for at most `limit` seconds.
  @MainActor private func settle(_ e: XCUIElement, limit: Double = 6) {
    var last = e.frame
    let end = Date().addingTimeInterval(limit)
    while Date() < end {
      Thread.sleep(forTimeInterval: 0.6)
      let now = e.frame
      if now == last { return }
      last = now
    }
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
    /// text field and waits for the keyboard; `reveal:<identifier>` (or
    /// `reveal:~<words in a label>`) scrolls an element outside the fold into
    /// the shot once the root is up, down the page or back up it.
    let step: String?
    /// The same reveal, for a row whose `step` is already a tap.
    let reveal: String?
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
        // `tap:<identifier>` walks one push first and the root is checked
        // after it; `keyboard` focuses the first field once the root is up.
        if let step = entry.step, step.hasPrefix("tap:") {
          let target = app.descendants(matching: .any)[String(step.dropFirst(4))]
          if target.waitForExistence(timeout: 30) { reveal(target, in: app); target.tap() }
        }
        let root = locate(app, entry.root)
        let found = root.waitForExistence(timeout: 30)
        if found, entry.step == "keyboard" {
          let field = app.textFields.firstMatch
          reveal(field, in: app)
          if field.exists { field.tap() }
          _ = app.keyboards.firstMatch.waitForExistence(timeout: 6)
        }
        let revealKey = entry.reveal ?? entry.step.flatMap { $0.hasPrefix("reveal:") ? String($0.dropFirst(7)) : nil }
        if found, let key = revealKey {
          let target = key.hasPrefix("~")
            ? app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@", String(key.dropFirst()))).firstMatch
            : app.descendants(matching: .any)[key]
          if target.waitForExistence(timeout: 10) {
            // a board opens on its newest line, so what it pins sits ABOVE the fold
            for _ in 0..<8 where !target.isHittable {
              if target.frame.maxY < app.windows.firstMatch.frame.midY { app.swipeDown() } else { app.swipeUp() }
            }
          }
        }
        Thread.sleep(forTimeInterval: entry.settle ?? 2.0)
        // The counters are the router's, not the screen's: every mark carries
        // the same pair, so a root located by text reads them off any mark.
        let anyOne = anyMark(app)
        let value = found ? ((root.value as? String) ?? (anyOne.exists ? (anyOne.value as? String) : nil) ?? "") : ""
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
    // "<scenario> <route|-> [detail|-] [extra launch arguments…]"
    let parts = spec.split(separator: " ").map(String.init)
    let route = parts.count > 1 && parts[1] != "-" ? parts[1] : nil
    let detail = parts.count > 2 && parts[2] != "-" ? parts[2] : nil
    let app = launch(parts[0], route, detail, extra: Array(parts.dropFirst(3)))
    Thread.sleep(forTimeInterval: 8)
    for _ in 0..<(Int(ProcessInfo.processInfo.environment["CS_FX_DUMP_SWIPES"] ?? "") ?? 0) { app.swipeUp() }
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
    // the grid opens on its week (W5): a cell already on screen, else the first
    let cell = cells.allElementsBoundByIndex.first(where: \.isHittable) ?? cells.firstMatch
    app.revealBookCell(cell)
    cell.tap()
    XCTAssertTrue(app.staticTexts["seasonBook.receipt.total"].waitForExistence(timeout: 10))
    attach(app, "flow__book-cell-receipts")
    let round = app.buttons["Open the round’s receipt"].firstMatch
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

  /// The Album's read fails once, F16's failed state says so with Try again,
  /// and the retry lands on the photographs. X35 · twice: with the route
  /// opened at the usual 1.5s, and late (6s), the way a loaded machine opens
  /// it — the Album's first read then comes more than four seconds after boot
  /// and more than a second after Home's read of the same table, which the
  /// seam used to count as the golfer's retry, so the Album opened on its
  /// photographs and the failed state was never drawn.
  @MainActor func testAlbumFailureThenRetry() {
    for late in [false, true] {
      let tag = late ? "-late" : ""
      let app = launch("failures", "album", extra: late ? ["-cs_synth_open_after", "6"] : [])
      XCTAssertTrue(mark(app, "album").waitForExistence(timeout: 30))
      Thread.sleep(forTimeInterval: 2)
      attach(app, "flow__album-failed\(tag)")
      let failed = app.descendants(matching: .any)["album.failed"]
      XCTAssertTrue(failed.waitForExistence(timeout: 5), "F16 · the failed read draws the failed state\(tag)")
      let retry = app.buttons["Try again"].firstMatch
      XCTAssertTrue(retry.waitForExistence(timeout: 5), "F16 · the failed state offers Try again\(tag)")
      Thread.sleep(forTimeInterval: 1.2)
      retry.tap()
      XCTAssertTrue(failed.waitForNonExistence(timeout: 10), "the retry lands\(tag)")
      let photo = app.buttons.matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", " — ", " at ")).firstMatch
      XCTAssertTrue(photo.waitForExistence(timeout: 10), "the retried Album shows its photographs\(tag)")
      attach(app, "flow__album-retried\(tag)")
      app.terminate()
    }
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

  @MainActor private func button(_ app: XCUIApplication, _ label: String) -> XCUIElement {
    app.buttons.matching(NSPredicate(format: "label ==[c] %@", label)).firstMatch
  }

  /// A card the composer can post: a gross, and the rating and slope.
  @MainActor private func fillCard(_ app: XCUIApplication) {
    let gross = app.textFields["Your gross"].firstMatch
    XCTAssertTrue(gross.waitForExistence(timeout: 10))
    if !app.keyboards.firstMatch.exists { gross.tap() }
    gross.typeText("84")
    let fold = app.buttons.containing(NSPredicate(format: "label BEGINSWITH %@", "Rating not set")).firstMatch
    if fold.waitForExistence(timeout: 3) { fold.tap() }
    let rating = app.textFields["Rating"].firstMatch
    XCTAssertTrue(rating.waitForExistence(timeout: 5))
    rating.tap(); rating.typeText("70.1")
    let slope = app.textFields["Slope"].firstMatch
    slope.tap(); slope.typeText("124")
    // A2 · a round names its course (noCard, noCourse, noRating): the synthetic
    // composer inherits none, so one is typed by hand, as a golfer off the list
    // types it — last, because its results open under the field and move the
    // rating and slope
    let course = app.textFields.matching(NSPredicate(format: "identifier == %@ OR placeholderValue BEGINSWITH %@",
                                                      "post.course.search", "Search a course")).firstMatch
    XCTAssertTrue(course.waitForExistence(timeout: 5), "the course field")
    app.tapToType(course)   // after the slope it can sit under the bars or on the keyboard
    course.typeText("Fixture Muni")
    app.swipeDown()
  }

  /// Posting fails at the server: the composer keeps the card and says why.
  @MainActor func testPostingFailureKeepsTheCard() {
    let app = launch("season-live", "postround", extra: ["-cs_synth_post_fail"])
    XCTAssertTrue(mark(app, "composer").waitForExistence(timeout: 30))
    fillCard(app)
    let post = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "add my round")).allElementsBoundByIndex
      .max { $0.frame.minY < $1.frame.minY }
    XCTAssertNotNil(post)
    post?.tap()
    // W1 / N4-020 · the refusal is said above the button, in the picture —
    // it was a toast drawn under the composer's cover
    let why = app.staticTexts["post.refusal"]
    XCTAssertTrue(why.waitForExistence(timeout: 10))
    XCTAssertTrue(why.isHittable, "the refusal is on screen, not under the cover")
    attach(app, "flow__post-failed")
    XCTAssertTrue(mark(app, "composer").exists)
    XCTAssertEqual(app.textFields["Your gross"].firstMatch.value as? String, "84")
  }

  /// Posting lands: the finish ceremony rises with the round's receipt door.
  @MainActor func testPostingLandsOnTheCeremony() {
    let app = launch("season-live", "postround")
    XCTAssertTrue(mark(app, "composer").waitForExistence(timeout: 30))
    fillCard(app)
    let post = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "add my round")).allElementsBoundByIndex
      .max { $0.frame.minY < $1.frame.minY }
    post?.tap()
    XCTAssertTrue(button(app, "View receipt").waitForExistence(timeout: 15))
    attach(app, "flow__finish-ceremony")
  }

  /// No signal at boot, then the signal comes back and one retry lands.
  @MainActor func testOfflineThenReconnect() {
    let app = launch("offline", "home", extra: ["-cs_synth_reconnect_after", "6"])
    XCTAssertTrue(mark(app, "bootfailed").waitForExistence(timeout: 30))
    attach(app, "flow__offline")
    Thread.sleep(forTimeInterval: 6)
    button(app, "Try again").tap()
    XCTAssertTrue(mark(app, "home").waitForExistence(timeout: 20))
    attach(app, "flow__reconnected")
  }

  /// A live round finishes for the whole group and lands on the recap. The
  /// round is the dev round (`-cs_dev_live`) drawn over the tabs; controls in
  /// that host report "not hittable" to the runner even when they are drawn
  /// in the open, so its taps go to the element's centre.
  @MainActor func testLiveFinishToRecap() {
    let app = launch("season-live", nil, extra: ["-cs_dev_live"])
    let finish = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Finish the round")).firstMatch
    XCTAssertTrue(app.staticTexts["HOLE 15"].waitForExistence(timeout: 30))
    app.swipeUp(); app.swipeUp()
    XCTAssertTrue(finish.waitForExistence(timeout: 10))
    finish.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    let casual = app.buttons["live.finish.casual"]
    XCTAssertTrue(casual.waitForExistence(timeout: 10))
    Thread.sleep(forTimeInterval: 1)
    attach(app, "flow__live-finish-sheet")
    // X34 · the sheet's own primary, by its identifier. The live page behind
    // the sheet has a "Finish the round" of its own, so picking the primary by
    // label and position could take that one; walking every button to pick
    // also spent 25s between the sheet's shot and the tap.
    let primary = app.buttons["live.finish.confirm"]
    XCTAssertTrue(primary.waitForExistence(timeout: 5))
    primary.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    // The takeover's own count line ("3 cards to the season"), which nothing
    // before the finish draws.
    let recap = app.staticTexts.matching(NSPredicate(format: "label MATCHES[c] %@", "[0-9]+ cards? (to the season|posted)")).firstMatch
    XCTAssertTrue(recap.waitForExistence(timeout: 15))
    settle(recap)
    attach(app, "flow__live-recap")
  }
}
