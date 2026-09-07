// Cup Season — the credential's copy band (the repair pass, DF-02 / C-13).
//
// The defect this suite exists for: `CSCredential.head` laid the identity
// block `.bottomLeading` inside a plate of FIXED height while the block
// itself GROWS, so a two-line name at `display` 34 over a three-clause
// identity reached the gold slot at the plate's head and `JER` of `JERECHO`
// printed behind `FOUNDER` — on the flagship object of the design, at the
// DEFAULT reading size, on every device photographed.

import Testing
import SwiftUI
@testable import CSDesign

@Suite struct CredentialBandTests {

  private let plate: CGFloat = 312 * 0.58        // the 362pt card's plate
  private let measure: CGFloat = 362 - 20 * 2    // its inner measure

  /// The band the slot owns is reserved and nothing may enter it.
  @Test func theSlotsBandIsReserved() {
    #expect(CSCredential<EmptyView>.PlateBand.head == CGFloat(52))
    #expect(CSCredential<EmptyView>.PlateBand.room(plateHeight: plate) > 0)
  }

  /// **The photographed case.** A two-line name over a three-clause identity
  /// fits under the slot once the name drops a size — and it must, because
  /// this is the default reading size on the default device.
  @Test func aTwoLineNameOverAThreeClauseIdentityStaysUnderTheSlot() {
    let name = "Jerecho Fischbeck"
    // it genuinely does not set on one line at `display`
    #expect(CSCredential<EmptyView>.PlateBand.nameRole(name, measure: measure, size: .large) == .displayS)
    let band = CSCredential<EmptyView>.PlateBand.height(
      name: name, role: .displayS, identityClauses: 3, measure: measure, size: .large)
    #expect(band <= CSCredential<EmptyView>.PlateBand.room(plateHeight: plate),
            "the name's top reaches the slot's bottom")
    #expect(CSCredential<EmptyView>.PlateBand.ridesThePlate(
      name: name, identityClauses: 3, measure: measure, plateHeight: plate, size: .large))
  }

  /// A short name keeps `display`, which is the artboard's own setting.
  @Test func aShortNameKeepsTheDisplaySize() {
    #expect(CSCredential<EmptyView>.PlateBand.nameRole("Galen Marr", measure: measure, size: .large) == .display)
  }

  /// And when the band genuinely cannot fit, the identity leaves the
  /// photograph rather than printing through the slot — §6.7's own path.
  @Test func anImpossibleBandLeavesThePhotograph() {
    #expect(!CSCredential<EmptyView>.PlateBand.ridesThePlate(
      name: "Bartholomew Featherstonehaugh", identityClauses: 6,
      measure: measure, plateHeight: plate, size: .large))
    // the accessibility sizes always take that path (the `riding` rule)
    #expect(!CSCredential<EmptyView>.PlateBand.ridesThePlate(
      name: "Galen Marr", identityClauses: 1,
      measure: measure, plateHeight: plate, size: .accessibility3))
  }
}
