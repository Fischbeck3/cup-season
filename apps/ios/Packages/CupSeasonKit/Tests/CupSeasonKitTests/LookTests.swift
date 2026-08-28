import Testing
import Foundation
import CSDesign
@testable import CupSeasonKit

/// IOS-025 — the resolver is pure; these pin D103a's precedence and the calendar.
@Suite struct LookResolverTests {
  private let cal: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "America/Phoenix")!
    return c
  }()
  private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
    cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
  }

  // MARK: the calendar

  @Test func windowHits() {
    #expect(LookResolver.calendarLook(date: day(2026, 7, 15), calendar: cal)?.key == "oldest")    // Claret, mid-window
    #expect(LookResolver.calendarLook(date: day(2026, 7, 10), calendar: cal)?.key == "oldest")    // first day
    #expect(LookResolver.calendarLook(date: day(2026, 7, 24), calendar: cal)?.key == "oldest")    // last day
    #expect(LookResolver.calendarLook(date: day(2026, 4, 1), calendar: cal)?.key == "opener")     // Azaleas spans two months
    #expect(LookResolver.calendarLook(date: day(2026, 6, 30), calendar: cal)?.key == "fourth")
  }

  @Test func windowMisses() {
    #expect(LookResolver.calendarLook(date: day(2026, 7, 25), calendar: cal) == nil)   // the day after Claret
    #expect(LookResolver.calendarLook(date: day(2026, 8, 27), calendar: cal) == nil)   // late August: homebase
    #expect(LookResolver.calendarLook(date: day(2026, 3, 27), calendar: cal) == nil)   // the eve of the opener
  }

  @Test func decemberToJanuaryWraps() {
    #expect(LookResolver.calendarLook(date: day(2026, 12, 27), calendar: cal)?.key == "fresh")
    #expect(LookResolver.calendarLook(date: day(2026, 12, 31), calendar: cal)?.key == "fresh")
    #expect(LookResolver.calendarLook(date: day(2027, 1, 1), calendar: cal)?.key == "fresh")
    #expect(LookResolver.calendarLook(date: day(2027, 1, 15), calendar: cal)?.key == "fresh")
    #expect(LookResolver.calendarLook(date: day(2027, 1, 16), calendar: cal) == nil)
    #expect(LookResolver.calendarLook(date: day(2026, 12, 26), calendar: cal)?.key == "holidays")
  }

  @Test func theRyderIsOddYearsOnly() {
    #expect(LookResolver.calendarLook(date: day(2025, 9, 20), calendar: cal)?.key == "teams")
    #expect(LookResolver.calendarLook(date: day(2027, 10, 5), calendar: cal)?.key == "teams")
    // an even year: Two Teams yields — Sep 20 is homebase, Oct 5 is Fall (its window opens Oct 1)
    #expect(LookResolver.calendarLook(date: day(2026, 9, 20), calendar: cal) == nil)
    #expect(LookResolver.calendarLook(date: day(2026, 10, 5), calendar: cal)?.key == "fall")
  }

  // MARK: precedence

  private func membership(phase: String, status: String?, starts: String, ends: String) -> Me.Membership {
    let season: String = status.map {
      """
      "season": {"id": "\(UUID().uuidString)", "starts_on": "\(starts)", "ends_on": "\(ends)", "status": "\($0)"},
      """
    } ?? ""
    let json = """
    {"league_id": "\(UUID().uuidString)", "name": "PIGL", "code": "ABCD", "phase": "\(phase)", "role": "player",
     "member_id": "\(UUID().uuidString)", \(season) "marker": "saguaro"}
    """
    return try! JSONDecoder().decode(Me.Membership.self, from: Data(json.utf8))
  }

  @Test func phaseLookBeatsEverything() {
    let final = SeasonPhase.cupFinal(weeksLeft: 2)
    #expect(LookResolver.resolve(date: day(2026, 7, 15), calendar: cal, leaguePhase: final, leagueLook: "opener", personal: .fixed("teams"))?.key == "cupfinal")
    #expect(LookResolver.resolve(date: day(2026, 7, 15), calendar: cal, leaguePhase: .wrapped, leagueLook: "opener", personal: .none)?.key == "wrap")
  }

  @Test func leagueLookBeatsPersonalWhenInScope() {
    let live = SeasonPhase.season(week: 3, of: 12)
    #expect(LookResolver.resolve(date: day(2026, 7, 15), calendar: cal, leaguePhase: live, leagueLook: "opener", personal: .calendar)?.key == "opener")
    #expect(LookResolver.resolve(date: day(2026, 7, 15), calendar: cal, leaguePhase: live, leagueLook: "opener", personal: .none)?.key == "opener")
    #expect(LookResolver.resolve(date: day(2026, 7, 15), calendar: cal, leaguePhase: .forming, leagueLook: "may", personal: .fixed("teams"))?.key == "may")
  }

  @Test func leagueLookIgnoredOutOfScope() {
    // no league in scope (Home without a membership, You): the league key means nothing
    #expect(LookResolver.resolve(date: day(2026, 7, 15), calendar: cal, leaguePhase: nil, leagueLook: "opener", personal: .calendar)?.key == "oldest")
    #expect(LookResolver.resolve(date: day(2026, 8, 27), calendar: cal, leaguePhase: nil, leagueLook: "opener", personal: .none) == nil)
  }

  @Test func personalDialWhenTheLeagueSaysNothing() {
    let live = SeasonPhase.season(week: 3, of: 12)
    #expect(LookResolver.resolve(date: day(2026, 7, 15), calendar: cal, leaguePhase: live, leagueLook: nil, personal: .calendar)?.key == "oldest")
    #expect(LookResolver.resolve(date: day(2026, 8, 27), calendar: cal, leaguePhase: live, leagueLook: nil, personal: .calendar) == nil)
    #expect(LookResolver.resolve(date: day(2026, 8, 27), calendar: cal, leaguePhase: live, leagueLook: nil, personal: .fixed("holidays"))?.key == "holidays")
    #expect(LookResolver.resolve(date: day(2026, 7, 15), calendar: cal, leaguePhase: live, leagueLook: nil, personal: .none) == nil)
  }

  @Test func unknownKeysFailClosed() {
    let live = SeasonPhase.season(week: 3, of: 12)
    // an unknown personal key is homebase
    #expect(LookResolver.resolve(date: day(2026, 7, 15), calendar: cal, leaguePhase: nil, leagueLook: nil, personal: .fixed("bogus")) == nil)
    // an unknown league key is absent — the person's dial shows through
    #expect(LookResolver.resolve(date: day(2026, 7, 15), calendar: cal, leaguePhase: live, leagueLook: "bogus", personal: .calendar)?.key == "oldest")
    #expect(LookResolver.resolve(date: day(2026, 8, 27), calendar: cal, leaguePhase: live, leagueLook: "bogus", personal: .none) == nil)
    // a phase key cannot be curated by the Pro — it is the season's to turn on
    #expect(LookResolver.resolve(date: day(2026, 8, 27), calendar: cal, leaguePhase: live, leagueLook: "cupfinal", personal: .none) == nil)
    #expect(CSLooks.spec("bogus") == nil)
  }

  @Test func membershipPhaseFeedsTheResolver() {
    let wrapped = membership(phase: "season", status: "complete", starts: "2026-03-01", ends: "2026-05-24")
    #expect(LookResolver.resolve(date: day(2026, 7, 15), calendar: cal, leaguePhase: SeasonPhase.of(wrapped), leagueLook: nil, personal: .none)?.key == "wrap")
    let final = membership(phase: "season", status: "cup_final", starts: "2026-05-01", ends: "2026-08-30")
    #expect(LookResolver.resolve(date: day(2026, 8, 20), calendar: cal, leaguePhase: SeasonPhase.of(final, today: "2026-08-20"), leagueLook: "opener", personal: .none)?.key == "cupfinal")
  }

  // MARK: the dial's storage

  @Test func personalLookRoundTrips() {
    let d = UserDefaults(suiteName: "cs-look-tests-\(UUID().uuidString)")!
    #expect(PersonalLook.load(d) == .calendar)                       // the default
    PersonalLook.none.save(d);            #expect(PersonalLook.load(d) == .none)
    PersonalLook.fixed("oldest").save(d); #expect(PersonalLook.load(d) == .fixed("oldest"))
    PersonalLook.calendar.save(d);        #expect(PersonalLook.load(d) == .calendar)
    #expect(PersonalLook(rawValue: "") == .calendar)
  }

  @Test func leagueLooksPayloadIsParsedStrictly() {
    let a = UUID(), b = UUID()
    let parsed = LookStore.parse([a.uuidString: "oldest", b.uuidString: "bogus", "not-a-uuid": "opener", UUID().uuidString: nil, UUID().uuidString: "cupfinal"])
    #expect(parsed == [a: "oldest"])
  }

  // MARK: copy

  @Test func windowCopy() {
    #expect(LookCopy.window(CSLooks.spec("oldest")!) == "Jul 10 – 24")
    #expect(LookCopy.window(CSLooks.spec("opener")!) == "Mar 28 – Apr 13")
    #expect(LookCopy.window(CSLooks.spec("teams")!) == "odd years · Sep 18 – Oct 5")
    #expect(LookCopy.window(CSLooks.spec("fresh")!) == "Dec 27 – Jan 15")
    #expect(LookCopy.window(CSLooks.spec("cupfinal")!) == nil)
    #expect(LookCopy.calendarLine(CSLooks.spec("oldest")) == "Claret · Jul 10 – 24")
    #expect(LookCopy.calendarLine(nil) == "Fescue · no look this week")
    #expect(LookCopy.dressed(CSLooks.spec("oldest")) == "The room's wearing Claret")
    #expect(LookCopy.roomLine(nil) == "Room look · follows the calendar")
  }
}
