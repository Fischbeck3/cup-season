// D412 · a Major's buy-in takes the same $200 ceiling as every other money
// field. "Run it back" prefills from the Major it follows, and a Major set
// before the ceiling existed must not carry a bigger buy-in into next year's.
import Testing
import Foundation
@testable import CupSeason
@testable import CupSeasonKit

struct MajorBuyInCapTests {
  private func room(buyIn: Double?) -> EventRoom {
    EventRoom(event: EventRow(id: UUID(), name: "The Jug", created_by: nil, kind: "major", status: "complete", buy_in: buyIn),
              sessions: [EventSession(id: UUID(), session_no: 1, opens_on: "2026-07-09", closes_on: "2026-07-12", status: "closed")])
  }

  @Test func aRunBackTakesTheCeiling() {
    #expect(MajorPrefill(room(buyIn: 250), me: nil).buy == 200)
    #expect(MajorPrefill(room(buyIn: 100_000), me: nil).buy == Double(MoneyLimits.maxStake))
  }

  @Test func anOrdinaryRunBackIsUntouched() {
    #expect(MajorPrefill(room(buyIn: 20), me: nil).buy == 20)
    #expect(MajorPrefill(room(buyIn: 12.5), me: nil).buy == 12.5)
    #expect(MajorPrefill(room(buyIn: nil), me: nil).buy == 0)
  }
}
