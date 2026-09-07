// Cup Season — Home's five weights, as a table (IOS-046, `surfaces/home.md`).
//
// `HomeRankTests` proves the ORDER. This proves the **weight**: which form the
// lead takes, what a surviving item is drawn as, what the floor already knows
// the page is offering, and the two sentences the wire produces for itself.
//
// The wave's own sentence is *do not make every feed item visually equal*, and
// the audit's finding is that **ceremony night and a brand-new account render
// as the same card with a different eyebrow word**. Those are the first two
// tests, because they are the ones that would silently come back.

import Testing
import Foundation
@testable import CupSeasonKit

private func item(_ key: String, _ tier: HomeDispatch.Tier, rank: Int? = nil,
                  human: Bool = true, spine: HomeDispatch.Spine = .mut,
                  route: HomeDispatch.Route? = .composer, at: String? = nil) -> HomeDispatch.Item {
  .init(key: key, tier: tier, rank: rank, subject: "Galen", humanSubject: human,
        eyebrow: key.uppercased(), headline: "Galen — \(key).", standfirst: "A standfirst.",
        action: "Open it", route: route, spine: spine, at: at)
}

private func profile(rounds: Int?, index: Double? = nil, source: String? = nil,
                     home: String? = nil) -> Me.Profile {
  .init(id: UUID(), display_name: "Sam", handle: "sam", marker: "flag", city: nil,
        home_course: home, index_current: index, index_source: source,
        photo_path: nil, rounds_count: rounds, member_since: nil, is_founder: false)
}

private func me(rounds: Int?, memberships: [Me.Membership] = [], index: Double? = nil,
                source: String? = nil, home: String? = nil) -> Me {
  .init(profile: profile(rounds: rounds, index: index, source: source, home: home),
        memberships: memberships)
}

private let emptyStrip = MeStripCopy.Strip(slots: [], seasonRow: nil)

@Suite struct HomePageTests {

  // MARK: - the two Homes the audit says look identical

  @Test("H-03 · ceremony night is a TAKEOVER and a brand-new account is an EMPTY — not one card twice")
  func ceremonyIsNotTheEmpty() {
    let night = item("move:1", .changed, rank: 1, spine: .gold, route: .pot(UUID()))
    let ceremony = HomePage.make(me: me(rounds: 40), strip: emptyStrip,
                                 ranked: HomeRank.arrange([night]), buckets: [])
    guard case .ceremony = ceremony.lead else { Issue.record("ceremony night did not take the band"); return }

    let first = item("first_round", .opportunity, rank: 1, spine: .ember)
    let new = HomePage.make(me: me(rounds: 0), strip: emptyStrip,
                            ranked: HomeRank.arrange([first]), buckets: [])
    guard case .empty = new.lead else { Issue.record("the brand-new empty did not take the page"); return }
    #expect(new.firstRound)
    #expect(new.hasPrimary)
    #expect(!ceremony.firstRound)
    #expect(!ceremony.hasPrimary)
  }

  @Test("A season that ENDED A WHILE AGO is a quiet block, not a ceremony — that is the whole difference")
  func lastSeasonIsNotACeremony() {
    let last = item("lastseason:1", .chapter, rank: 1, spine: .gold, route: .pot(UUID()))
    let page = HomePage.make(me: me(rounds: 40), strip: emptyStrip,
                             ranked: HomeRank.arrange([last]), buckets: [])
    guard case .block = page.lead else { Issue.record("lastseason: took the ceremony band"); return }
    #expect(!HomePage.isCeremony(last))
  }

  @Test("A GOLD spine alone is not a ceremony, and an ember move: is not either")
  func ceremonyNeedsBothHalves() {
    #expect(!HomePage.isCeremony(item("plan:1", .coming, spine: .gold)))
    #expect(!HomePage.isCeremony(item("move:1", .changed, spine: .ember)))
    #expect(HomePage.isCeremony(item("chapter:1", .chapter, spine: .gold)))
  }

  @Test("A golfer with a season is never the brand-new empty, however few rounds they have")
  func aSeasonIsNeverBrandNew() {
    let m = Me.Membership(league_id: UUID(), name: "The Fellas", code: nil, phase: "active",
                          sandbox: false, role: "member", member_id: UUID(), marker: nil,
                          commissioner_name: nil, settings: nil, season: nil, squad: nil,
                          standing: nil, pulse: nil)
    let page = HomePage.make(me: me(rounds: 0, memberships: [m]), strip: emptyStrip,
                             ranked: HomeRank.arrange([item("firsttee:1", .coming, rank: 1)]), buckets: [])
    guard case .block = page.lead else { Issue.record("a golfer with a season got the brand-new page"); return }
    #expect(!page.firstRound)
  }

  // MARK: - the deck is deleted

  @Test("H-01 · ranked items 2–5 are WIRE ROWS, never four smaller copies of the lead")
  func theDeckIsDeleted() {
    let items = [item("clash:1", .closing, rank: 1), item("plan:1", .coming, rank: 2, at: "2026-09-07"),
                 item("need:1", .coming, rank: 3, at: "2026-09-05")]
    let page = HomePage.make(me: me(rounds: 9), strip: emptyStrip,
                             ranked: HomeRank.arrange(items),
                             buckets: [HomeFeedBucket(label: "Today", items: [])],
                             today: "2026-09-06")
    guard case .block = page.lead else { Issue.record("no lead"); return }
    // one of the two survivors becomes the wire's own empty block; the other
    // is a quiet line. Neither is a second serif sentence.
    #expect(page.wireEmptyItem != nil)
    for row in page.rows {
      if case .line = row.body { continue }
      Issue.record("a ranked survivor rendered as something other than a quiet line")
    }
  }

  // MARK: - the order

  @Test("The wire runs OUTWARD FROM TODAY, and what is coming leads what has gone")
  func outwardFromToday() {
    #expect(HomePage.distance(0) < HomePage.distance(1))
    #expect(HomePage.distance(1) < HomePage.distance(-1))
    #expect(HomePage.distance(-1) < HomePage.distance(2))
    // a row with no date cannot claim a place in a rundown
    #expect(HomePage.distance(nil) > HomePage.distance(-99))
  }

  // MARK: - the floor

  @Test("The floor never repeats the page's own act — declare and composer are ONE door")
  func theFloorNeverRepeats() {
    #expect(HomePage.floorKey(for: .composer) == "add_my_round")
    #expect(HomePage.floorKey(for: .declare) == "add_my_round")
    #expect(HomePage.floorKey(for: .people) == "find_golfers")
    #expect(HomePage.floorKey(for: .invite(UUID(), kind: nil)) == "join_with_a_code")
    #expect(HomePage.floorKey(for: .season(UUID(), pane: nil)) == nil)

    let page = HomePage.make(me: me(rounds: 9), strip: emptyStrip,
                             ranked: HomeRank.arrange([item("clash:1", .closing, rank: 1, route: .declare)]),
                             buckets: [])
    #expect(page.offered.contains("add_my_round"))
  }

  // MARK: - the strip's two rules

  @Test("A NUMERAL RAIL HOLDS NUMERALS — the day comes out of the value and joins the label")
  func theRailHoldsNumerals() {
    let last = MeStripCopy.Slot(fact: .myLastRound, label: "LAST", value: "84 FRI",
                                door: .composer, voiceOver: "last round, 84 on fri")
    let cell = HomeWireCopy.railCell(last)
    #expect(cell.value == "84")
    #expect(cell.label == "LAST · FRI")

    // a value with no day is left exactly as the producer wrote it
    let number = MeStripCopy.Slot(fact: .myNumber, label: "YOUR NUMBER", value: "10.6",
                                  door: .yourCard, voiceOver: "your number, 10.6")
    #expect(HomeWireCopy.railCell(number).value == "10.6")
    #expect(HomeWireCopy.railCell(number).label == "YOUR NUMBER")

    // and a placeholder is never split into a figure that is not one
    let none = MeStripCopy.Slot(fact: .myLastRound, label: "LAST", value: "NO ROUNDS YET",
                                door: .composer, voiceOver: "none", isPlaceholder: true)
    #expect(HomeWireCopy.railCell(none).value == "NO ROUNDS YET")
  }

  // MARK: - the wire's own sentences

  @Test("A wire round's line NEVER repeats the name on the face above it")
  func theRoundLineHasNoName() {
    let r = HomeFeedRow.pr(golfer: "Galen Marr", gross: 79, course: "Papago")
    let line = HomeWireCopy.roundLine(r)
    #expect(line == "79 at Papago — a personal best.")
    #expect(!line.contains("Galen"))
  }

  @Test("A round with no gross says only what it knows")
  func noGrossNoNumber() {
    let r = HomeFeedRow.plain(golfer: "Galen", gross: nil, course: "Papago")
    #expect(HomeWireCopy.roundLine(r) == "A round at Papago.")
  }

  @Test("The credit is the golfer's own, with a typographic apostrophe and the given name only")
  func theCredit() {
    #expect(HomeWireCopy.possessive("Galen Marr") == "Galen\u{2019}s")
    #expect(HomeWireCopy.possessive("Chris Ames") == "Chris\u{2019}")
    #expect(HomeWireCopy.photoCredit(HomeFeedRow.plain(golfer: "Galen Marr", gross: 79, course: "Papago",
                                                       playedOn: "2026-09-06"),
                                     today: "2026-09-06") == "Galen\u{2019}s round · Today")
  }

  @Test("A field size is a WORD under a numeral and a digit past twenty")
  func theChipUnit() {
    #expect(HomeWireCopy.chipUnit(of: 8) == "Of eight")
    #expect(HomeWireCopy.chipUnit(of: 12) == "Of twelve")
    #expect(HomeWireCopy.chipUnit(of: 24) == "Of 24")
  }

  @Test("The day marker is Today, then a weekday, then a date — never `dim`, never a raw ISO string")
  func theDayMarker() {
    #expect(HomeWireCopy.dayMarker("2026-09-06", today: "2026-09-06") == "Today")
    #expect(HomeWireCopy.dayMarker("2026-09-07", today: "2026-09-06") == "Mon")
    #expect(HomeWireCopy.dayMarker(nil, today: "2026-09-06") == nil)
    #expect(HomeWireCopy.dayMarker("", today: "2026-09-06") == nil)
    let far = HomeWireCopy.dayMarker("2026-08-01", today: "2026-09-06")
    #expect(far != nil && !(far ?? "").contains("-"))
  }

  // MARK: - what the first round turns on

  @Test("EVERY GLOSS DEGRADES TO A TRUE SENTENCE — no blank, no dash, no guessed course")
  func theFirstRoundRowsDegrade() {
    let full = HomeFirstRound.rows(starter: "12.0", homeCourse: "Papago")
    #expect(full[0].gloss == "12.0 becomes yours, not ours")
    #expect(full[1].gloss == "Papago remembers your best")

    let bare = HomeFirstRound.rows()
    #expect(bare.count == 3)
    for r in bare {
      #expect(!r.gloss.isEmpty)
      #expect(!r.gloss.contains("nil"))
      #expect(!r.gloss.contains("—"))
    }
  }
}

// MARK: - fixtures

private extension HomeFeedRow {
  static func plain(golfer: String, gross: Int?, course: String, playedOn: String = "2026-09-06") -> HomeFeedRow {
    decode(["golfer": golfer, "gross": gross as Any, "course": course, "played_on": playedOn])
  }
  static func pr(golfer: String, gross: Int, course: String) -> HomeFeedRow {
    decode(["golfer": golfer, "gross": gross, "course": course, "played_on": "2026-09-06", "is_pr": true])
  }
  /// `home_feed.Row` has no memberwise init — it is generated from the RPC —
  /// so a fixture is built the way the payload arrives.
  private static func decode(_ o: [String: Any]) -> HomeFeedRow {
    var d = o
    d["round_id"] = UUID().uuidString
    d["profile_id"] = UUID().uuidString
    let data = try! JSONSerialization.data(withJSONObject: d)
    return try! JSONDecoder().decode(HomeFeedRow.self, from: data)
  }
}
