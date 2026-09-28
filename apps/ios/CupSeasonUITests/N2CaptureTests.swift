import XCTest

/// N2 · the ten program's capture plan for live, post, record and share views.
///
/// Every capture is a `-cs_dev_synthetic <scenario> -cs_dev_open <place>`
/// launch whose intended root (`cs.screen.<root>`) is VERIFIED before the
/// screenshot is kept: a root that never appeared is attached as FAIL, never
/// as a picture of whatever screen was up. Beside each screenshot goes the
/// accessibility tree the capture was taken from (names, traits, frames), so
/// the review reads what VoiceOver reads and not only pixels.
///
/// The plan arrives in the TEST RUNNER's environment (`CS_N2_PLAN`, a JSON
/// array), set by `docs/design/ten-2026-09-27/launch/n2/capture.py`. Without
/// one the test skips, so an ordinary `xcodebuild test` never runs it.
final class N2CaptureTests: XCTestCase {
  struct Step: Decodable {
    /// "tap" (identifier or label), "tapText" (a button whose label contains it, any case),
    /// "tapSegment", "type", "swipeUp", "swipeDown", "wait", "dismissKeyboard"
    let op: String
    let target: String?
    let text: String?
    let count: Int?
  }
  struct Entry: Decodable {
    let name: String
    let scenario: String
    let route: String
    let detail: String?
    let root: String
    let extra: [String]?
    let steps: [Step]?
    let settle: Double?
    let themes: [String]?
  }

  @MainActor func testCapturePlan() throws {
    let env = ProcessInfo.processInfo.environment
    guard let raw = env["CS_N2_PLAN"], let data = raw.data(using: .utf8) else { throw XCTSkip("no CS_N2_PLAN") }
    let plan = try JSONDecoder().decode([Entry].self, from: data)
    let size = env["CS_N2_SIZE"] ?? "large"
    let themes = (env["CS_N2_THEMES"] ?? "dark,light").split(separator: ",").map(String.init)
    for e in plan {
      for theme in e.themes ?? themes {
        let app = XCUIApplication()
        // scenario "none" is a DEBUG review fixture launched on its own (never
        // combined with the synthetic seam); its root is an element, not a mark
        var args = e.scenario == "none" ? [] : ["-cs_dev_synthetic", e.scenario, "-cs_dev_open", e.route]
        if let d = e.detail { args.append(d) }
        args += ["-cs_dev_appearance", theme, "-cs_dev_look", "none", "-cs_dev_text_size", size == "AX3" ? "AX3" : "large"]
        args += e.extra ?? []
        app.launchArguments = args
        app.launch()
        let mark: XCUIElement = e.root.hasPrefix("button:")
          ? app.buttons[String(e.root.dropFirst("button:".count))].firstMatch
          : app.descendants(matching: .any)["cs.screen.\(e.root)"]
        var found = mark.waitForExistence(timeout: 30)
        Thread.sleep(forTimeInterval: e.settle ?? 2.5)
        var stepLog: [String] = []
        for s in e.steps ?? [] { stepLog.append(perform(s, in: app)) }
        if !(e.steps ?? []).isEmpty { Thread.sleep(forTimeInterval: 1.2) }
        // the root must STILL be up after the steps (a step may push a page
        // that carries its own mark; the plan then names that root)
        found = found && mark.exists
        let value = found ? (e.root.hasPrefix("button:") ? "misses=0 fails=0 (review fixture)" : ((mark.value as? String) ?? "")) : ""
        let verdict = found ? "PASS" : "FAIL"
        let counters = value.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "=", with: "-")
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "n2__\(e.name)__\(theme)__\(size)__\(verdict)__\(counters)"
        shot.lifetime = .keepAlways
        add(shot)
        let record: [String: Any] = ["name": e.name, "theme": theme, "size": size, "arguments": args,
                                     "found": found, "value": value, "steps": stepLog]
        let rec = XCTAttachment(data: try JSONSerialization.data(withJSONObject: record, options: [.prettyPrinted, .sortedKeys]),
                                uniformTypeIdentifier: "public.json")
        rec.name = "n2record__\(e.name)__\(theme)__\(size)"
        rec.lifetime = .keepAlways
        add(rec)
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "n2ax__\(e.name)__\(theme)__\(size)"
        tree.lifetime = .keepAlways
        add(tree)
        app.terminate()
      }
    }
  }

  @MainActor private func perform(_ s: Step, in app: XCUIApplication) -> String {
    switch s.op {
    case "tap":
      guard let t = s.target else { return "tap: no target" }
      let el = app.descendants(matching: .any)[t].firstMatch
      guard el.waitForExistence(timeout: 8) else { return "tap \(t): MISSING" }
      for _ in 0..<4 where !el.isHittable { app.swipeUp() }
      el.tap(); return "tap \(t): ok"
    case "tapText":
      guard let t = s.target else { return "tapText: no target" }
      let el = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", t)).firstMatch
      guard el.waitForExistence(timeout: 8) else { return "tapText \(t): MISSING" }
      for _ in 0..<4 where !el.isHittable { app.swipeUp() }
      el.tap(); return "tapText \(t): ok"
    case "tapSegment":
      guard let t = s.target else { return "tapSegment: no target" }
      let el = app.segmentedControls.buttons[t].firstMatch
      guard el.waitForExistence(timeout: 8) else { return "tapSegment \(t): MISSING" }
      el.tap(); return "tapSegment \(t): ok"
    case "type":
      guard let t = s.target, let text = s.text else { return "type: no target" }
      let el = app.descendants(matching: .any)[t].firstMatch
      guard el.waitForExistence(timeout: 8) else { return "type \(t): MISSING" }
      el.tap(); el.typeText(text); return "type \(t): ok"
    case "typeField":
      guard let t = s.target, let text = s.text else { return "typeField: no target" }
      let el = app.textFields[t].firstMatch
      guard el.waitForExistence(timeout: 8) else { return "typeField \(t): MISSING" }
      el.tap(); el.typeText(text); return "typeField \(t): ok"
    case "swipeUp":
      for _ in 0..<(s.count ?? 1) { app.swipeUp() }; return "swipeUp \(s.count ?? 1)"
    case "swipeDown":
      for _ in 0..<(s.count ?? 1) { app.swipeDown() }; return "swipeDown \(s.count ?? 1)"
    case "wait":
      Thread.sleep(forTimeInterval: Double(s.count ?? 1)); return "wait \(s.count ?? 1)"
    case "dismissKeyboard":
      guard app.keyboards.count > 0 else { return "dismissKeyboard: none up" }
      let close = app.buttons["Close keyboard"].firstMatch
      if close.exists && close.isHittable { close.tap(); return "dismissKeyboard: toolbar" }
      for key in ["Return", "return", "Done", "done", "Go", "go"] {
        let b = app.keyboards.buttons[key].firstMatch
        if b.exists { b.tap(); return "dismissKeyboard: \(key)" }
      }
      app.swipeDown()
      return "dismissKeyboard: swipe"
    default:
      return "unknown op \(s.op)"
    }
  }
}
