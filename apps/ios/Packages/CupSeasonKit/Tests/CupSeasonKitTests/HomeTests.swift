import Testing
import Foundation
@testable import CupSeasonKit

private func row(_ id: UUID = UUID(), me: Bool = false, golfer: String? = "Diego", gross: Int? = 79, pvi: Double? = 2.1,
                 playedOn: String, createdAt: Date? = nil, course: String? = "Papago GC", pr: Bool = false, sub80: Bool = false, first: Bool = false) -> HomeFeedRow {
  let json: [String: Any?] = [
    "round_id": id.uuidString, "profile_id": UUID().uuidString, "golfer": golfer, "marker": "saguaro", "handle": "d",
    "gross": gross, "pvi": pvi, "played_on": playedOn,
    "created_at": createdAt.map { ISO8601DateFormatter().string(from: $0) },
    "course": course, "is_pr": pr, "is_first": first, "is_sub80": sub80, "is_me": me, "photo_path": nil,
  ]
  let data = try! JSONSerialization.data(withJSONObject: json.compactMapValues { $0 })
  let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601
  return try! d.decode(HomeFeedRow.self, from: data)
}

@Suite struct HomeBucketTests {
  @Test func bucketsByDisplayedDate() {
    let today = "2026-08-27"
    let items: [HomeItem] = [
      .round(row(playedOn: "2026-08-27"), photoURL: nil),
      .round(row(playedOn: "2026-08-22"), photoURL: nil),   // 5 days → this week
      .round(row(playedOn: "2026-08-20"), photoURL: nil),   // 7 days → earlier
    ]
    let b = HomeBuckets.bucket(items, today: today)
    #expect(b.map(\.label) == ["Today", "This week", "Earlier"])
    #expect(b[0].items.count == 1 && b[1].items.count == 1 && b[2].items.count == 1)
  }
}

@Suite struct HomeDigestTests {
  let now = ISO8601DateFormatter().date(from: "2026-08-27T15:00:00Z")!

  @Test func firstVisitHasNoDigest() {
    #expect(HomeDigest.make(rounds: [row(playedOn: "2026-08-27")], posts: [], mark: nil, now: now) == nil)
  }

  @Test func sinceYouWereHereJoinsWithTheSerialComma() {
    let mark = now.addingTimeInterval(-3600)
    let fresh = now.addingTimeInterval(-600)
    let rounds = [
      row(golfer: "Diego", playedOn: "2026-08-27", createdAt: fresh, pr: true),
      row(golfer: "Rosa", playedOn: "2026-08-27", createdAt: fresh, sub80: true),
    ]
    let d = HomeDigest.make(rounds: rounds, posts: [], mark: mark, now: now)!
    #expect(d.kind == .since)
    #expect(d.body == "2 rounds, a personal best from Diego, and Rosa broke 80.")
  }

  @Test func aMentionRescuesAQuietDay() {
    let mark = now.addingTimeInterval(-3600)
    let old = now.addingTimeInterval(-86400 * 3)
    let rounds = [row(me: true, gross: 84, playedOn: "2026-08-24", createdAt: old)]
    let d = HomeDigest.make(rounds: rounds, posts: [], mark: mark,
                            mentions: [HomeSocial.Mention(who: "Ed", emoji: "azalea", gross: 84)], now: now)!
    #expect(d.kind == .since)
    #expect(d.body == "Ed gave your 84 its flowers.")
  }

  @Test func quietDayResurfacesTheBestRecentThing() {
    let mark = now.addingTimeInterval(-3600)
    let old = now.addingTimeInterval(-86400 * 2)
    let rounds = [
      row(golfer: "Marco", gross: 90, pvi: 0.4, playedOn: "2026-08-25", createdAt: old),
      row(golfer: "Rosa", gross: 74, pvi: 3.8, playedOn: "2026-08-25", createdAt: old, sub80: true),
    ]
    let d = HomeDigest.make(rounds: rounds, posts: [], mark: mark, now: now)!
    #expect(d.kind == .quiet)
    #expect(d.body.hasSuffix("Rosa broke 80 — 74 at Papago GC"))
  }
}

@Suite struct OccasionTests {
  @Test func windowsWrapAcrossNewYear() {
    // The wrap rule itself, on a literal — `fresh` used to be the example and
    // is no longer a windowed card (see the test below).
    let dec27toJan15 = (12, 27, 1, 15)
    #expect(Occasion.inWindow(dec27toJan15, month: 12, day: 30))
    #expect(Occasion.inWindow(dec27toJan15, month: 1, day: 10))
    #expect(!Occasion.inWindow(dec27toJan15, month: 2, day: 1))
    let opener = Occasion.all.first { $0.key == "opener" }!
    #expect(Occasion.inWindow(opener.window, month: 4, day: 1))
    #expect(!Occasion.inWindow(opener.window, month: 4, day: 20))
  }

  /// QB-19 · the one card written for a golfer with nothing running fired
  /// twenty days a year, so the state it was written for could not reach it
  /// for eleven and a half months. A state is not an occasion.
  @Test func theNothingRunningCardIsReachableEveryDay() {
    let fresh = Occasion.all.first { $0.key == "fresh" }!
    for m in 1...12 {
      #expect(Occasion.inWindow(fresh.window, month: m, day: 1))
      #expect(Occasion.inWindow(fresh.window, month: m, day: 28))
    }
    // and it is still only for a golfer with nothing running
    #expect(fresh.leaguelessOnly)
    // …which is a different question from "has no membership at all" (B-1).
    let wrapped = try! JSONDecoder().decode(Me.Membership.self, from: Data("""
    {"league_id":"\(UUID().uuidString)","member_id":"\(UUID().uuidString)","name":"The Ocotillo Cup","phase":"complete","role":"member",
     "season":{"id":"\(UUID().uuidString)","starts_on":"2026-05-25","ends_on":"2026-08-23","status":"complete"}}
    """.utf8))
    #expect(Occasion.nothingRunning([wrapped], today: "2026-09-08"))
    let live = try! JSONDecoder().decode(Me.Membership.self, from: Data("""
    {"league_id":"\(UUID().uuidString)","member_id":"\(UUID().uuidString)","name":"The Fellas","phase":"season","role":"member",
     "season":{"id":"\(UUID().uuidString)","starts_on":"2026-07-20","ends_on":"2027-01-17","status":"active"}}
    """.utf8))
    #expect(!Occasion.nothingRunning([live], today: "2026-09-08"))
    #expect(Occasion.nothingRunning([], today: "2026-09-08"))
  }

  @Test func leaguelessOnlyWindowsHideForMembers() {
    let defaults = UserDefaults(suiteName: "occasion-tests")!
    defaults.removePersistentDomain(forName: "occasion-tests")
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "America/Phoenix")!
    let jan5 = cal.date(from: DateComponents(year: 2027, month: 1, day: 5))!
    #expect(Occasion.current(leagueless: true, today: jan5, calendar: cal, defaults: defaults)?.key == "fresh")
    #expect(Occasion.current(leagueless: false, today: jan5, calendar: cal, defaults: defaults) == nil)
    Occasion.dismiss(Occasion.all.first { $0.key == "fresh" }!, today: jan5, calendar: cal, defaults: defaults)
    #expect(Occasion.current(leagueless: true, today: jan5, calendar: cal, defaults: defaults) == nil)
  }
}

// D252 — a card that sells a Major does not render until the Major's door
// opens. Four of the six windows do: `opener`, `test`, `oldest` and `fall`.
// The artifacts say three; the table holds four, and all four are gated.

@Suite struct OccasionMajorGateTests {
  private func cal() -> Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "America/Phoenix")!
    return c
  }
  private func fresh(_ name: String) -> UserDefaults {
    let d = UserDefaults(suiteName: name)!
    d.removePersistentDomain(forName: name)
    return d
  }
  private func day(_ m: Int, _ d: Int, _ c: Calendar) -> Date {
    c.date(from: DateComponents(year: 2027, month: m, day: d))!
  }

  @Test func exactlyFourWindowsSellAMajorOrAJug() {
    let gated = Occasion.all.filter(\.needsMajor).map(\.key)
    #expect(Set(gated) == ["opener", "test", "oldest", "fall"])
    #expect(gated.count == 4)
    // and the two that are not gated are the Ryder and the league
    #expect(Occasion.all.filter { !$0.needsMajor }.map(\.key) == ["teams", "fresh"])
  }

  @Test func aShutDoorIsNeverSoldAndTheFlagDefaultsToShut() {
    let c = cal(), d = fresh("occasion-major-tests")
    for (m, day) in [(4, 1), (6, 12), (7, 15), (10, 20)] {
      let t = self.day(m, day, c)
      // the window is live — with the door open the card is there
      #expect(Occasion.current(leagueless: false, majorOpen: true, today: t, calendar: c, defaults: d)?.needsMajor == true)
      // with the door shut it is not, and the DEFAULT is shut: a caller that
      // never read `app_flags.ios.major` gets the same answer as one whose
      // read failed, which is what EventPickerSheet does with the same flag
      #expect(Occasion.current(leagueless: false, majorOpen: false, today: t, calendar: c, defaults: d)?.needsMajor != true)
      #expect(Occasion.current(leagueless: false, today: t, calendar: c, defaults: d)?.needsMajor != true)
    }
  }

  @Test func aWithheldCardYieldsToTheNextWindowRatherThanBlankingHome() {
    // 1–5 Oct: `teams` (a Ryder — not gated) and `fall` (a Major — gated) are
    // both live, and `teams` is first in the table. The Ryder shows either way.
    let c = cal(), d = fresh("occasion-major-overlap")
    let oct2 = day(10, 2, c)
    #expect(Occasion.current(leagueless: false, majorOpen: true, today: oct2, calendar: c, defaults: d)?.key == "teams")
    #expect(Occasion.current(leagueless: false, majorOpen: false, today: oct2, calendar: c, defaults: d)?.key == "teams")
    // and once the Ryder is dismissed, the shut door leaves nothing rather
    // than offering a Major that cannot be started
    Occasion.dismiss(Occasion.all.first { $0.key == "teams" }!, today: oct2, calendar: c, defaults: d)
    #expect(Occasion.current(leagueless: false, majorOpen: true, today: oct2, calendar: c, defaults: d)?.key == "fall")
    #expect(Occasion.current(leagueless: false, majorOpen: false, today: oct2, calendar: c, defaults: d) == nil)
  }

  @Test func theFlagIsOnlyReadOnADayThatWouldNeedIt() {
    let c = cal(), d = fresh("occasion-major-needs")
    #expect(Occasion.needsMajorToday(leagueless: false, today: day(6, 12, c), calendar: c, defaults: d))
    // 2 Oct is the Ryder's, and the Ryder needs no flag
    #expect(!Occasion.needsMajorToday(leagueless: false, today: day(10, 2, c), calendar: c, defaults: d))
    // and an ordinary day is in no window at all
    #expect(!Occasion.needsMajorToday(leagueless: false, today: day(9, 5, c), calendar: c, defaults: d))
    #expect(Occasion.current(leagueless: false, majorOpen: true, today: day(9, 5, c), calendar: c, defaults: d) == nil)
  }
}
