import XCTest
import UIKit

/// The live recap, reached through FX's finish flow on the synthetic world
/// (`-cs_dev_live` draws the dev round over the tabs; the finish runs the
/// real path, answered on the device).
///
/// FX saw the takeover's words cut at the left edge under a lighter panel on a
/// 402pt phone. The panel was the settlement card: laid out at 1080 × 1350,
/// centred in its smaller frame and then scaled toward its own top-leading
/// corner, it was drawn up and off the left edge — wholly off a 375pt phone
/// (the card simply missing) and a 23pt sliver over the words on a 402pt one.
/// Every element's frame was already in place, so the picture itself is
/// read here: the gutter beside the takeover's words is the ground, and the
/// card is drawn where its element is. The card and the hole strip are each
/// one VoiceOver element.
final class N2LiveRecapUITests: N2UITestCase {
  /// every check reports, even after one fails, so the finding is whole
  override func setUp() { continueAfterFailure = true }

  /// A screenshot's pixels, addressed in points.
  private struct Pixels {
    let bytes: [UInt8]
    let w: Int
    let h: Int
    let scale: CGFloat

    init?(_ image: UIImage, pointsWide: CGFloat) {
      guard let cg = image.cgImage, pointsWide > 0 else { return nil }
      let width = cg.width, height = cg.height
      var buf = [UInt8](repeating: 0, count: width * height * 4)
      let drawn = buf.withUnsafeMutableBytes { raw -> Bool in
        guard let ctx = CGContext(data: raw.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                  bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return false }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        return true
      }
      guard drawn else { return nil }
      bytes = buf; w = width; h = height; scale = CGFloat(width) / pointsWide
    }

    func at(_ x: CGFloat, _ y: CGFloat) -> [Int] {
      let px = min(max(Int(x * scale), 0), w - 1), py = min(max(Int(y * scale), 0), h - 1)
      let i = (py * w + px) * 4
      return [Int(bytes[i]), Int(bytes[i + 1]), Int(bytes[i + 2])]
    }

    static func near(_ a: [Int], _ b: [Int], tolerance: Int = 3) -> Bool {
      zip(a, b).allSatisfy { abs($0 - $1) <= tolerance }
    }
  }

  @MainActor func testTheRecapCardIsDrawnInItsFrameAndTheGutterStaysClear() {
    for size in ["large", "AX3"] {
      // FX's finish flow (SyntheticRouteTests.testLiveFinishToRecap)
      let app = XCUIApplication()
      app.launchArguments = ["-cs_dev_synthetic", "season-live", "-cs_dev_appearance", "dark", "-cs_dev_look", "none",
                             "-cs_dev_text_size", size, "-cs_dev_live"]
      app.launch()
      let finish = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Finish the round")).firstMatch
      XCTAssertTrue(app.staticTexts["HOLE 15"].waitForExistence(timeout: 30), "\(size): the dev round is up")
      app.swipeUp(); app.swipeUp()
      if size == "AX3" { app.swipeUp(); app.swipeUp(); app.swipeUp() }
      XCTAssertTrue(finish.waitForExistence(timeout: 10))
      finish.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
      XCTAssertTrue(app.buttons["live.finish.casual"].waitForExistence(timeout: 10))
      Thread.sleep(forTimeInterval: 1)
      // the sheet's own primary, by its identifier (X34): the live page
      // behind the sheet has a "Finish the round" of its own
      let primary = app.buttons["live.finish.confirm"]
      XCTAssertTrue(primary.waitForExistence(timeout: 5))
      primary.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
      let count = app.staticTexts.matching(NSPredicate(format: "label MATCHES[c] %@", "[0-9]+ cards? (to the season|posted)")).firstMatch
      XCTAssertTrue(count.waitForExistence(timeout: 15), "\(size): the recap's takeover is up")
      Thread.sleep(forTimeInterval: 3)   // the takeover's lines land and seal
      let screen = app.windows.firstMatch.frame
      // the takeover's eyebrow is the one above its count line: the save
      // status says the same words again under Your round, further down
      let eyebrow = app.staticTexts.matching(NSPredicate(format: "label ==[c] %@ OR label ==[c] %@ OR label ==[c] %@",
                                                          "Round posted", "Saved on this phone", "Not posted"))
        .allElementsBoundByIndex.filter { $0.frame.maxY <= count.frame.minY }
        .min { $0.frame.minY < $1.frame.minY }
      guard let eyebrow else {
        XCTFail("\(size): the takeover's eyebrow is drawn above its count line"); app.terminate(); continue
      }
      for el in [count, eyebrow] {
        XCTAssertGreaterThanOrEqual(el.frame.minX, screen.minX + 8, "\(size): \(el.label) starts inside the gutter — \(el.frame)")
        XCTAssertLessThanOrEqual(el.frame.maxX, screen.maxX, "\(size): \(el.label) ends on the screen — \(el.frame)")
      }

      let shot = app.screenshot()
      guard let px = Pixels(shot.image, pointsWide: screen.width) else {
        XCTFail("\(size): the screenshot could not be read"); app.terminate(); continue
      }
      // the sheet's ground, read beside the eyebrow at the far edge
      let ground = px.at(screen.maxX - 6, eyebrow.frame.midY)
      // 1 · the gutter beside the takeover's words is the ground: nothing is
      // drawn over the words' left edge
      var covered: [String] = []
      var sampled = 0
      var y = eyebrow.frame.minY
      while y <= count.frame.maxY {
        for x in stride(from: CGFloat(3), through: max(3, eyebrow.frame.minX - 3), by: 4) {
          let c = px.at(x, y)
          sampled += 1
          if !Pixels.near(c, ground) { covered.append("(\(Int(x)), \(Int(y))) \(c)") }
        }
        y += 4
      }
      XCTAssertGreaterThan(sampled, 40, "\(size): the gutter was sampled from the eyebrow to the count line")
      XCTAssertTrue(covered.isEmpty,
                    "\(size): the gutter beside the takeover is the ground \(ground) — \(covered.count) points are not, e.g. \(covered.prefix(3))")

      // 2 · the card is one element, on the screen, and drawn where it is
      let card = app.descendants(matching: .any)["live.recap.card"].firstMatch
      XCTAssertTrue(card.exists, "\(size): the settlement card is one named element")
      let cardLabels = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH[c] %@", "The settlement card"))
      XCTAssertEqual(cardLabels.count, 1, "\(size): VoiceOver reads the card once")
      // W4 · the strip speaks one summary in the web's words ("… won 3 holes,
      // … won 2, 1 halved, closed on 16."), so it is found by its name
      let strips = app.descendants(matching: .any).matching(identifier: "live.recap.strip")
      XCTAssertEqual(strips.count, 0, "\(size): Q1 removes the second strip under the card")
      XCTAssertTrue(card.label.contains(" won "), "\(size): the one card says who won how many — \(card.label)")
      XCTAssertTrue(card.label.localizedCaseInsensitiveContains("closed on") || card.label.localizedCaseInsensitiveContains("through"),
                    "\(size): the card speaks its footer — \(card.label)")
      if card.exists {
        let f = card.frame
        XCTAssertGreaterThanOrEqual(f.minX, screen.minX + 8, "\(size): the card starts inside the gutter — \(f)")
        XCTAssertLessThanOrEqual(f.maxX, screen.maxX - 8, "\(size): the card ends inside the gutter — \(f)")
        if f.minX >= 0, f.minY >= 0, f.minY + 8 < screen.maxY {
          // just inside its top-leading corner the card's own ground shows,
          // not the sheet's: the card is drawn in its frame
          let inside = px.at(f.minX + 6, f.minY + 6)
          XCTAssertFalse(Pixels.near(inside, ground),
                         "\(size): the card is drawn in its frame — \(inside) inside its corner is the sheet's ground")
        }
      }

      let tree = XCTAttachment(string: app.debugDescription)
      tree.name = "recap-tree-\(size)"; tree.lifetime = .keepAlways; add(tree)
      let a = XCTAttachment(screenshot: shot); a.name = "recap-\(size)"; a.lifetime = .keepAlways; add(a)
      app.terminate()
    }
  }
}
