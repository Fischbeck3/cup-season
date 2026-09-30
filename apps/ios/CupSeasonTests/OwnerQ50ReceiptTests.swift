import Testing
import SwiftUI
import CupSeasonKit
@testable import CupSeason

@MainActor @Suite struct OwnerQ50ReceiptTests {
  private func fixture(_ needs: Double = 351) -> SeasonScenarios {
    .init(meta: .init(finish: "cup_final", structure: "squads2", level: "squad", k: 1, months_left: 2, locked: false, cap: 4), rows: [
      .init(id: UUID(), name: "Fixture Javelinas", points: 171, max_final: 900, clinched: false, eliminated: false, needs: needs),
      .init(id: UUID(), name: "Fixture Wrens", points: 137, max_final: 521, clinched: false, eliminated: false, needs: 0)
    ])
  }

  @Test func aProvenClinchHasA44PointDoorAndUnprovenArithmeticHasNone() throws {
    for width: CGFloat in [375, 402] {
      for size in [DynamicTypeSize.large, .accessibility3] {
        for needs in [351.0, 300.0] {
          let sc = fixture(needs)
          let host = HostedLayout(ScenarioLineView(parts: ScenarioLine.parts(sc), receipt: ScenarioLine.clinchReceipt(sc)).padding(20), width: width, typeSize: size)
          defer { host.tearDown() }
          if needs == 351 {
            let door = try #require(host.element("season.clinchReceipt"))
            #expect(door.label == "Fixture Javelinas clinch the top seed with 351 more points.")
            #expect(door.frame.height >= 43.99 && door.frame.minX >= 19 && door.frame.maxX <= width - 19)
          } else { #expect(host.element("season.clinchReceipt") == nil) }
        }
      }
    }
  }

  @Test func theReceiptPrintsTheProducersArithmeticWhole() throws {
    let receipt = try #require(ScenarioLine.clinchReceipt(fixture()))
    for width: CGFloat in [375, 402] {
      let host = HostedLayout(ClinchReceiptSheet(receipt: receipt), width: width, typeSize: .accessibility3)
      defer { host.tearDown() }
      let said = host.elements.map(\.label).joined(separator: " ")
      #expect(said.contains("521") && said.contains("171") && said.contains("351"))
      #expect(said.contains(receipt.title) && said.contains(receipt.fine))
      #expect(host.horizontalScrollers.isEmpty)
    }
  }
}
