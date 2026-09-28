import XCTest
import SwiftUI
import Vision
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
  /// F13 · the EXPORTED share PNG (the pixels `RoundSharePreview` hands the
  /// share sheet — `publicRoundCard`, rendered by `RecapCardView.render`),
  /// read back with on-device text recognition: the band is printed once, the
  /// sentence that repeated it ("played to their playing HCP") is not on the
  /// artifact at all, and the golfer's facts stay. Photo, no-photo and the
  /// long synthetic name. The photograph is a drawn stand-in: no face, no place.
  @MainActor func testRoundShareExportSaysTheBandOnce() throws {
    // the build's one drawn stand-in photograph (greyscale, no place, no face)
    let photo = ReceiptPhotoDev.image
    let short = PostRecap(name: "Avery Fixture", marker: "saguaro", gross: 84, pvi: 0.4, points: 9,
                          course: "North Grove (fixture)", date: "2026-09-20", badge: "PERSONAL BEST")
    let long = PostRecap(name: "Maximilian Placeholder-Worthington", marker: "weebridge", gross: 79, pvi: 2.1, points: 11,
                         course: "North Grove Country Club (fixture) East", date: "2026-09-19", badge: nil)
    let cases: [(String, PostRecap, UIImage?, String)] = [
      ("played-to-nophoto", short, nil, "PLAYED TO IT"),
      ("played-to-photo", short, photo, "PLAYED TO IT"),
      ("beat-long-nophoto", long, nil, "BEAT THEIR NUMBER"),
      ("beat-long-photo", long, photo, "BEAT THEIR NUMBER"),
    ]
    for (name, recap, image, band) in cases {
      let card = recap.publicRoundCard
      let png = try XCTUnwrap(RecapCardView.render(card, photo: image))
      XCTAssertEqual(png.size, CGSize(width: 1080, height: 1350), name)
      let lines = try recognized(png)
      let joined = lines.joined(separator: " | ").uppercased()
      XCTAssertEqual(lines.filter { $0.uppercased().contains(band) }.count, 1, "\(name): the band once — \(joined)")
      XCTAssertFalse(joined.contains("PLAYING HCP"), "\(name): the band's sentence is not repeated on the artifact — \(joined)")
      XCTAssertTrue(joined.contains(String(recap.gross)) && joined.contains("GROSS"), "\(name): the gross stays — \(joined)")
      XCTAssertTrue(joined.contains("NORTH GROVE"), "\(name): the course stays — \(joined)")
      let surname = recap.name.split(separator: " ").first.map(String.init)?.uppercased() ?? ""
      XCTAssertTrue(joined.contains(surname), "\(name): the golfer's name stays — \(joined)")
      // D60a · a public card carries no points and no milestone claim
      XCTAssertFalse(joined.contains("PTS") || joined.contains("PERSONAL BEST"), "\(name): no points on a public card — \(joined)")
      // the caption that travels with the card keeps the margin (the web's recapText rule)
      if recap.pvi.map({ abs($0) >= 1 }) == true {
        XCTAssertTrue(card.caption.contains("beat their playing HCP by"), "\(name): \(card.caption)")
      }
      let attachment = XCTAttachment(image: png)
      attachment.name = "n2-share-export-\(name)"
      attachment.lifetime = .keepAlways
      add(attachment)
      let text = XCTAttachment(string: lines.joined(separator: "\n"))
      text.name = "n2-share-export-\(name)-ocr"
      text.lifetime = .keepAlways
      add(text)
    }
  }

  private func recognized(_ image: UIImage) throws -> [String] {
    let cg = try XCTUnwrap(image.cgImage)
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false
    try VNImageRequestHandler(cgImage: cg).perform([request])
    return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
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
