import Testing
import Foundation
@testable import CupSeasonKit

/// N4-010 · the forced-update wall has a door, and prints a build as a number.
@Suite struct MustUpdateCopyTests {
  @Test func theBuildIsANumberNotAQuantity() {
    #expect(MustUpdateCopy.needs(1180) == "needs build 1180")
    #expect(MustUpdateCopy.needs(999_999) == "needs build 999999")
  }

  @Test func theDoorGoesToTheOnePlaceAStoreLinkLives() {
    #expect(MustUpdateCopy.getURL.absoluteString == "https://cupseason.app/get")
    #expect(MustUpdateCopy.door == "Get the update")
  }
}
