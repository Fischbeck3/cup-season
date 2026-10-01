import XCTest
@testable import CupSeasonKit

final class LeagueIdentityTests: XCTestCase {
  func testInitialMarksHandleLongNamesPunctuationAndEmpty() {
    XCTAssertEqual(LeagueIdentity.initials("The Dew Sweepers"), "DS")
    XCTAssertEqual(LeagueIdentity.initials("Who's the bitch?"), "Wtb")
    XCTAssertEqual(LeagueIdentity.initials("..."), "CS")
    XCTAssertEqual(LeagueIdentity.initials("The Fellas"), "F")
  }
  func testPreviewNamesCountOnlyNamedPeopleAndPreserveRemainingRoster() {
    let me = UUID(), galen = UUID()
    let pair = LeagueIdentity(league_id: UUID(), member_count: 2,
      people: [.init(id: me, name: "QA Viewer", marker: "dunes"), .init(id: galen, name: "Galen QA", marker: "lonetree")])
    XCTAssertEqual(pair.peopleLine(viewer: me), "You and Galen")
    let many = LeagueIdentity(league_id: UUID(), member_count: 12, people: pair.people)
    XCTAssertEqual(many.peopleLine(viewer: me), "You, Galen +10")
    XCTAssertNil(LeagueIdentity(league_id: UUID()).peopleLine(viewer: me))
    XCTAssertEqual(LeagueIdentity(league_id: UUID(), member_count: 1).peopleLine(viewer: me), "1 golfer")
  }
}
