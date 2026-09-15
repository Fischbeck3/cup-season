// D363 / F7 · "Play with Alex → Now" hands the live sheet a person, and the
// sheet seats them beside me — or says exactly why it could not. Every branch
// of `LiveRoundStore.seat` walked with no network: the store is driven with a
// roster the test writes itself.
import Testing
import Foundation
@testable import CupSeason
@testable import CupSeasonKit

@MainActor
struct LivePreselectTests {
  private static let alex = TagCandidate(id: UUID(uuidString: "00000000-0000-0000-0000-00000000A1EF")!, name: "Alex Rivera", marker: "azalea")

  /// A fresh store with me alone in the group, the way `primeRoster()` leaves it.
  private func store() -> LiveRoundStore {
    let s = LiveRoundStore()
    s.state = .fresh()
    s.scoreOnPhone = false
    s.roster = [LivePlayer(id: "me", n: "You", i: 12.4, ci: 1, guest: false, me: true, locked: true, team: "—")]
    s.sel = [0]
    return s
  }

  @Test func thePersonIsSeatedBesideMeAndRemovable() {
    let s = store()
    #expect(s.seat(Self.alex, index: 9.8) == .seated(estimated: false))
    #expect(s.sel.count == 2)
    let seated = s.roster[s.sel[1]]
    #expect(seated.pid == Self.alex.id)
    #expect(seated.n == "Alex Rivera")
    #expect(seated.i == 9.8 && seated.est == false)
    #expect(seated.guest && seated.buddy)          // a known golfer, not a posting member
    #expect(seated.locked == false)                // removable before tee-off, like anyone
    s.remove(s.sel[1])
    #expect(s.sel == [0])
  }

  /// No number from the picker's producer → the store's ordinary estimate,
  /// flagged EST. Never a number copied off a profile page.
  @Test func noNumberOnFileIsAnEstimateAndSaysSo() {
    let s = store()
    #expect(s.seat(Self.alex, index: nil) == .seated(estimated: true))
    let seated = s.roster[s.sel[1]]
    #expect(seated.i == 18 && seated.est)
    #expect(PlayWithCopy.seated("Alex Rivera", estimated: true).contains("estimated 18"))
  }

  @Test func anExistingRoundIsNeverOverwritten() {
    let s = store()
    s.state.active = true
    #expect(s.seat(Self.alex, index: 9.8) == .alreadyInARound)
    #expect(s.sel == [0] && s.roster.count == 1)
  }

  @Test func thePhoneOnlyPathIsMyRoundAlone() {
    let s = store()
    s.scoreOnPhone = true
    #expect(s.seat(Self.alex, index: 9.8) == .yourRoundOnly)
    #expect(s.roster.count == 1)
  }

  /// Already in the roster (a league mate, a buddy added earlier): selected,
  /// never duplicated. Already selected: nothing happens, and nothing is said.
  @Test func anAlreadyKnownGolferIsSelectedOnceAndNeverDuplicated() {
    let s = store()
    s.roster.append(LivePlayer(id: "m:1", n: "Alex Rivera", i: 9.8, ci: 1, guest: false, pid: Self.alex.id, team: "—"))
    #expect(s.seat(Self.alex, index: 9.8) == .seated(estimated: false))
    #expect(s.sel == [0, 1] && s.roster.count == 2)
    #expect(s.seat(Self.alex, index: 9.8) == .alreadySeated)
    #expect(s.sel == [0, 1] && s.roster.count == 2)
  }

  @Test func aFullGroupSaysSoRatherThanDroppingSomeone() {
    let s = store()
    for k in 1...3 { s.roster.append(LivePlayer(n: "Guest \(k)", i: 18, ci: -1, guest: true)); s.sel.append(k) }
    #expect(s.sel.count == 4)
    #expect(s.seat(Self.alex, index: 9.8) == .full)
    #expect(s.sel.count == 4 && s.roster.count == 4)
    #expect(PlayWithCopy.groupFull("Alex Rivera").contains("remove someone"))
  }

  /// The pending person is consumed by ONE apply. A second `applyPending()` —
  /// a generic Play opened later — finds nothing and seats nobody.
  @Test func thePersonNeverLeaksIntoALaterGenericPlay() async {
    let s = store()
    s.state.active = true            // refused this time
    s.preselect(Self.alex)
    await s.applyPending()
    s.state.active = false           // a later, generic Play
    await s.applyPending()
    #expect(s.roster.count == 1 && s.sel == [0])
  }
}
