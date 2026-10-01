// D192 / D402 · the live-round stake takes the web's $200 ceiling on the
// phone. The store is driven directly, with no network: whatever the field
// hands `setStake`, the round's state never holds more than the cap, never
// less than nothing, and never a number that is not one.
import Testing
import Foundation
@testable import CupSeason
@testable import CupSeasonKit

@MainActor
struct LiveStakeCapTests {
  private func store() -> LiveRoundStore {
    let s = LiveRoundStore()
    s.state = .fresh()
    s.scoreOnPhone = false
    return s
  }

  @Test func theStoreClampsToTheSharedCeiling() {
    let s = store()
    s.setStake(250)
    #expect(s.state.stake == 200)
    s.setStake(10_000)
    #expect(s.state.stake == Double(MoneyLimits.maxStake))
    s.setStake(200)
    #expect(s.state.stake == 200)
  }

  @Test func anOrdinaryStakeIsUntouched() {
    let s = store()
    s.setStake(5)
    #expect(s.state.stake == 5)
    s.setStake(12.5)
    #expect(s.state.stake == 12.5)
  }

  @Test func nothingBelowZeroAndNothingThatIsNotANumber() {
    let s = store()
    s.setStake(-20)
    #expect(s.state.stake == 0)
    s.setStake(.nan)
    #expect(s.state.stake == 0)
    s.setStake(.infinity)
    #expect(s.state.stake == 0)
  }
}
