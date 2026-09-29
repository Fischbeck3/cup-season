import XCTest
import UIKit

/// N4 · the composer's two P1s, measured in the picture rather than the tree.
///
/// - N4-020: a refused round said nothing. The refusal was a toast, the only
///   toast host drew at the app's root, and the composer is a full-screen
///   cover over it — so the element was in the tree and the golfer saw
///   nothing (`flow__post-failed.png`). The answer is now said above
///   `Add my round`, and this reads it off the screenshot.
final class N4PostUITests: N2UITestCase {
  override func setUp() { continueAfterFailure = true }

  /// The card the route tests fill: a gross, then the rating and slope.
  @MainActor private func fill(_ app: XCUIApplication) {
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
    app.swipeDown()
  }

  /// How many pixels inside `frame` differ from its own top-left corner —
  /// drawn words, rather than a frame with nothing painted in it.
  @MainActor private func inkedPixels(_ app: XCUIApplication, in frame: CGRect) -> Int {
    guard let cg = app.screenshot().image.cgImage else { return 0 }
    let w = cg.width, h = cg.height
    var buf = [UInt8](repeating: 0, count: w * h * 4)
    let ok = buf.withUnsafeMutableBytes { raw -> Bool in
      guard let ctx = CGContext(data: raw.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return false }
      ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h)); return true
    }
    guard ok else { return 0 }
    let scale = CGFloat(w) / app.windows.firstMatch.frame.width
    func px(_ x: Int, _ y: Int) -> [Int] { let i = (y * w + x) * 4; return [Int(buf[i]), Int(buf[i + 1]), Int(buf[i + 2])] }
    let x0 = max(0, Int(frame.minX * scale)), x1 = min(w - 1, Int(frame.maxX * scale))
    let y0 = max(0, Int(frame.minY * scale)), y1 = min(h - 1, Int(frame.maxY * scale))
    guard x1 > x0, y1 > y0 else { return 0 }
    let ground = px(x0, y0)
    var inked = 0
    for y in stride(from: y0, to: y1, by: 2) {
      for x in stride(from: x0, to: x1, by: 2) where zip(px(x, y), ground).contains(where: { abs($0 - $1) > 40 }) { inked += 1 }
    }
    return inked
  }

  @MainActor func testARefusedPostIsSaidAboveTheButtonWhereTheGolferCanSeeIt() {
    for size in ["large", "AX3"] {
      let app = launch("season-live", "postround", size: size, extra: ["-cs_synth_post_fail"])
      _ = root(app, "composer")
      fill(app)
      let post = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "add my round")).allElementsBoundByIndex
        .max { $0.frame.minY < $1.frame.minY }
      XCTAssertNotNil(post, "\(size): Add my round is there")
      post?.tap()
      let said = app.staticTexts["post.refusal"]
      XCTAssertTrue(said.waitForExistence(timeout: 10), "\(size): the refusal is said")
      Thread.sleep(forTimeInterval: 1)
      XCTAssertTrue(said.isHittable, "\(size): on screen, not under the cover — \(said.frame)")
      XCTAssertTrue(said.label.hasPrefix("Nothing was posted") || said.label.hasPrefix("The server didn’t accept"),
                    "\(size): W1's words — \(said.label)")
      XCTAssertFalse(said.label.contains("press Post"), "\(size): never a button the composer does not have")
      if let post {
        XCTAssertLessThanOrEqual(said.frame.maxY, post.frame.minY + 1, "\(size): above the button it answers")
      }
      XCTAssertGreaterThan(inkedPixels(app, in: said.frame), 20, "\(size): the words are drawn in the picture")
      attach(app, "n4-post-refused-\(size)")
      // the card is kept, and changing it is the golfer's answer to the line
      XCTAssertEqual(app.textFields["Your gross"].firstMatch.value as? String, "84", "\(size): the card is kept")
      app.terminate()
    }
  }
}
