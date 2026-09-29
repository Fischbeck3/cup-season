// F03 (N1, closed by N4) · the credential names the sheet and the page it
// heads — the tour card, the person page, You — so its name is the heading
// VoiceOver lands on. Read off the hosting view's accessibility tree
// (`HostedLayout`) at both phones' widths, the reading size and AX3.

import Testing
import SwiftUI
import UIKit
import CSDesign
import CupSeasonKit
@testable import CupSeason

@MainActor
@Suite struct CredentialHeadingTests {
  /// The synthetic world's own golfer (Dev/Synthetic), never a real one.
  static let golfer = CSCredentialGolfer(
    face: .init(id: UUID(uuidString: "F1C70000-0000-4000-8000-000000000001")!, marker: "saguaro"),
    name: "Avery Fixture", identity: "@AVERYFIXTURE · FIXTUREVILLE, AZ · NORTH GROVE (FIXTURE)",
    figures: [.init("12.4", label: "Handicap index"), .init("24", label: "Rounds")],
    club: "North Grove (fixture)")

  @Test("the credential's name is its heading, at the reading size and at AX3, on both phones")
  func theNameIsTheHeading() {
    for width in [CGFloat(375), 402] {
      for size in [DynamicTypeSize.large, .accessibility3] {
        let h = HostedLayout(CSCredential(Self.golfer) { Color.gray }, width: width, typeSize: size)
        defer { h.tearDown() }
        let name = h.elements.first { $0.label == Self.golfer.name }
        #expect(name != nil, "\(width) \(size): the name is an element")
        #expect(name?.traits.contains(.header) == true, "\(width) \(size): the name is the heading")
        let heads = h.elements.filter { $0.traits.contains(.header) }.map(\.label)
        #expect(heads == [Self.golfer.name], "\(width) \(size): one heading, the name — \(heads)")
      }
    }
  }
}
