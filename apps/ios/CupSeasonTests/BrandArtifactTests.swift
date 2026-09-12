import XCTest
import SwiftUI
import CSDesign
import CupSeasonKit
@testable import CupSeason

final class BrandArtifactTests: XCTestCase {
  @MainActor func testRoundExportsMissingAndLongValuesWithoutChangingCaption() throws {
    let cases = [
      PostRecap(name: "QA golfer", marker: "", gross: 91, pvi: nil, points: nil, course: "", date: "", badge: nil),
      PostRecap(name: "QA golfer with a deliberately very long display name", marker: "", gross: 108, pvi: 2.4, points: 9, course: "QA course with a deliberately long championship course name", date: "2026-08-22", badge: "PERSONAL BEST")
    ]
    for (index, recap) in cases.enumerated() {
      let image = try XCTUnwrap(RecapCardView.render(recap, photo: nil))
      XCTAssertEqual(image.size, CGSize(width: 1080, height: 1350))
      let shared = RecapCardView.shareItem(recap, photo: nil)
      XCTAssertEqual(shared.items.last as? String, recap.caption)
      let attachment = XCTAttachment(image: image)
      attachment.name = "round-fixture-\(index)"
      attachment.lifetime = .keepAlways
      add(attachment)
    }
  }
  @MainActor func testRecordExportAndNativeSharePayload() throws {
    let card = BrandRecordCard(kind: "Rivalry record", title: "QA golfer & QA rival",
      figure: "3–2", statement: "3 wins · 2 losses · 0 ties",
      rows: ["5 meetings", "QA fixture · not a real result"])
    let payload = card.shareItem()
    let image = try XCTUnwrap(payload.items.first as? UIImage)
    XCTAssertEqual(image.size, CGSize(width: 1080, height: 1350))
    XCTAssertTrue(try XCTUnwrap(payload.items.last as? String).contains("QA fixture"))
    let attachment = XCTAttachment(image: image)
    attachment.name = "rivalry-fixture"
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
