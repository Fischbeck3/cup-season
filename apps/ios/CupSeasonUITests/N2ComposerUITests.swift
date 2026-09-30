import XCTest

final class N2ComposerUITests: N2UITestCase {
  @MainActor func testQ48IndexHasItsOwnPreviewRail() {
    for scene in ["brand-new", "season-live"] {
      let app = launch(scene, "postround")
      _ = root(app, "composer")
      let eyebrow = app.staticTexts["post.eyebrow"]
      XCTAssertTrue(eyebrow.waitForExistence(timeout: 10))
      XCTAssertEqual(eyebrow.label.lowercased(), "add my round")
      let index = app.descendants(matching: .any)["post.index"].firstMatch
      XCTAssertTrue(index.exists)
      XCTAssertTrue(index.label.lowercased().contains("your index"))
      XCTAssertEqual(index.label.contains("Builds at 3 rounds"), scene == "brand-new")
      XCTAssertGreaterThan(index.frame.minY, eyebrow.frame.maxY)
      attach(app, "q48-index-" + scene)
      app.terminate()
    }
  }

  // MARK: F09 · the first round leads with the score

  @MainActor func testF09FirstRoundBandsWaitBehindHowPointsWork() {
    let app = launch("brand-new", "postround")
    _ = root(app, "composer")
    XCTAssertTrue(app.textFields["Your gross"].waitForExistence(timeout: 10))
    let how = app.buttons["How points work"]
    for _ in 0..<6 where !how.exists || !how.isHittable { app.swipeUp() }
    XCTAssertTrue(how.exists)
    XCTAssertEqual(how.value as? String, "collapsed")
    XCTAssertGreaterThanOrEqual(how.frame.height, 44)
    let before = app.staticTexts.count
    how.tap()
    XCTAssertEqual(app.buttons["How points work"].value as? String, "expanded")
    // the five bands appear only when asked for (named nowhere here: the one
    // band table is CSBands, and a test is not a second one)
    XCTAssertGreaterThanOrEqual(app.staticTexts.count, before + 5, "the band rows open under How points work")
  }
}
