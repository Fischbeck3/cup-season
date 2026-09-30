import Testing
import SwiftUI
import CSDesign
@testable import CupSeason

@MainActor @Suite struct OwnerQ34LayoutTests {
  @Test func eachStarIsA44PointTargetOnBothPhones() throws {
    for width: CGFloat in [375, 402] {
      for size in [DynamicTypeSize.large, .accessibility3] {
        let host = HostedLayout(CSStarRail(3.5, size: 40, onSet: { _ in }).padding(20), width: width, typeSize: size)
        defer { host.tearDown() }
        let stars = host.elements(prefix: "rating.star.")
        #expect(stars.count == 5)
        for star in stars {
          // layout lands on fractional points (43.99999999999997 at 375)
          #expect(star.frame.width >= 43.99 && star.frame.height >= 43.99)
          #expect(star.frame.minX >= 19 && star.frame.maxX <= width - 19)
        }
      }
    }
  }

  @Test func aLongSlatNameGrowsTheRowInsteadOfClipping() throws {
    func slat(_ name: String) -> some View {
      CSSlat(rank: 2, field: .none, face: nil, name: name, sub: "3 rounds",
             movement: nil, gap: nil) { Text("18").csType(.figureS) }
        .accessibilityIdentifier("q34.row")
    }
    for width: CGFloat in [375, 402] {
      let short = HostedLayout(slat("Avery Fixture"), width: width)
      let long = HostedLayout(slat("Indigo Longname-Fixturington Placeholder-Worthington"), width: width)
      defer { short.tearDown(); long.tearDown() }
      let a = try #require(short.element("q34.row"))
      let b = try #require(long.element("q34.row"))
      #expect(b.label.contains("Indigo Longname-Fixturington Placeholder-Worthington"))
      #expect(b.frame.height > a.frame.height)
      #expect(b.frame.maxX <= width + 1)
    }
  }
}
