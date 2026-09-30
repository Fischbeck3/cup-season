import Testing
import Foundation
@testable import CupSeason
@testable import CupSeasonKit

@MainActor @Suite struct OwnerW119MomentTests {
  @Test func eitherNavigationCommitsTheHoleAndAnotherNavigationClearsIt() {
    for reverse in [true, false] {
      let store = LiveRoundStore()
      store.state = .fresh(players: [.init(n: "Avery Fixture", i: 12, ci: 0, guest: false, me: true)])
      store.state.active = true; store.state.hole = 1
      store.state.course.parsVerified = true; store.state.course.pars[1] = 4
      store.state.scores[0][1] = 3; store.state.ensureClocks(); store.state.scts[0][1] = 10
      if reverse { store.prevHole() } else { store.nextHole() }
      #expect(store.moment?.hole == 2)
      // Its life is navigation-owned; an unscored next hole contributes no moment.
      if reverse { store.nextHole() } else { store.nextHole() }
      #expect(store.moment == nil)
    }
  }
}
