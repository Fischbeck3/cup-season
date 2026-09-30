import Testing
import SwiftUI
import CSDesign
@testable import CupSeason

@MainActor @Suite struct OwnerQ36MomentTests {
  @Test func onlyAConfirmedLiveMomentSaysLive() {
    for live in [false, true] {
      let host = HostedLayout(MomentRow(text: "Avery Fixture takes the lead", live: live), width: 375)
      defer { host.tearDown() }
      #expect(host.elements.contains { $0.identifier == "board.moment.live" } == live)
      #expect(host.elements.contains { $0.label == (live ? "Live moment: Avery Fixture takes the lead" : "A moment: Avery Fixture takes the lead") })
    }
  }
}
