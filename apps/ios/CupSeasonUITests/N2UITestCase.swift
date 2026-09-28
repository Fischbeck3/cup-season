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
