// Cup Season — the roster door (D180). The floor exists because five of seven
// real leagues were born with a dead code; these assertions are what stop that
// regressing, and they mirror the migration's own behavioural checks so the
// client and the server can be shown to agree.

import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct RosterDoorTests {
  private func day(_ iso: String) -> Date { CSDate.local(iso)! }

  @Test("locked before first tee: open until first tee — D161, untouched")
  func normalLeague() {
    let d = RosterDoor.of(lockedAt: day("2026-08-01"), closedAt: nil,
                          startsOn: "2026-09-05", today: "2026-08-31")
    #expect(d == .open(closesOn: "2026-09-05"))
    #expect(d.isOpen)
  }

  @Test("locked before first tee, first tee passed: closed by time")
  func normalLeagueExpired() {
    let d = RosterDoor.of(lockedAt: day("2026-08-01"), closedAt: nil,
                          startsOn: "2026-08-15", today: "2026-08-31")
    #expect(d == .closedByTime)
  }

  @Test("THE BUG: locked ON its own first tee is no longer born dead")
  func bornDead() {
    // Fellas: locked 2026-07-20, first tee 2026-07-20
    let d = RosterDoor.of(lockedAt: day("2026-07-20"), closedAt: nil,
                          startsOn: "2026-07-20", today: "2026-07-20")
    #expect(d.isOpen, "a link created by lock must not be dead at lock")
    #expect(d == .grace(closesOn: "2026-07-27"))
  }

  @Test("a backdated league gets its week, and only a week")
  func backdated() {
    let lock = day("2026-08-28")
    #expect(RosterDoor.of(lockedAt: lock, closedAt: nil, startsOn: "2026-03-22", today: "2026-08-28").isOpen)
    #expect(RosterDoor.of(lockedAt: lock, closedAt: nil, startsOn: "2026-03-22", today: "2026-09-04").isOpen)
    #expect(RosterDoor.of(lockedAt: lock, closedAt: nil, startsOn: "2026-03-22", today: "2026-09-05") == .closedByTime)
  }

  @Test("the Pro's close beats an otherwise-open window")
  func proCloses() {
    let d = RosterDoor.of(lockedAt: day("2026-08-01"), closedAt: day("2026-08-20"),
                          startsOn: "2026-12-01", today: "2026-08-31")
    #expect(!d.isOpen)
    if case .closedByPro = d {} else { Issue.record("expected closedByPro, got \(d)") }
  }

  @Test("no season yet: open, with nothing to promise")
  func preSeason() {
    #expect(RosterDoor.of(lockedAt: nil, closedAt: nil, startsOn: nil, today: "2026-08-31")
            == .open(closesOn: nil))
  }

  @Test("the lines state the door and never scold the Pro for the date")
  func copy() {
    let open = RosterDoor.open(closesOn: "2026-09-05").line()
    #expect(open.hasPrefix("Works until you close it, or until first tee"))
    let grace = RosterDoor.grace(closesOn: "2026-07-27").line()
    #expect(grace.hasPrefix("Works until you close it, or until"))
    #expect(!grace.contains("first tee"), "the floor's end is not first tee")
    for line in [open, grace,
                 RosterDoor.closedByPro(on: nil).line(),
                 RosterDoor.closedByTime.line()] {
      #expect(!line.contains("⚠"))
      #expect(!line.lowercased().contains("you'll have"))
    }
    #expect(RosterDoor.closedByPro(on: nil).line().contains("halfway turn"))
  }

  @Test("the eyebrow counts the room")
  func eyebrow() {
    #expect(RosterDoor.open(closesOn: nil).eyebrow(members: 5) == "ROSTER OPEN · 5 IN")
    #expect(RosterDoor.closedByTime.eyebrow(members: 6) == "ROSTER CLOSED · 6 IN")
  }
}
