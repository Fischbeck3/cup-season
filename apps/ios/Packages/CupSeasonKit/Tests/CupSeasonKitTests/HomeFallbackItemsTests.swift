// Cup Season — the declared fallback, and the clash it still speaks for
// (IOS-029b, UX_PRINCIPLES.md §5.4 rule 2).
//
// The wave that added `home_dispatch` deleted `HomeMode`, `HomeLead`,
// `HomeHeroCopy` and `HomeLeagueRow`, so "render as today" is not available
// to a client whose database is behind it. `HomeFallbackItems` is what it
// renders instead, and these are the three properties that make it safe:
//
//   1. THE STATIC ORDER — CLOSING → CHANGED → COMING → CIRCLE, then the rest.
//      No score, no modifier, no `rank_reason`: those are the ranker's answers
//      and this path does not have them.
//   2. NO LEAD CARD. A client that cannot reach the ranker must not invent a
//      lead — the veto is the server's assertion, and a guessed lead is the
//      exact failure D231 exists to prevent.
//   3. THE STRIP IS STILL DRAWN. `MeStripCopy.make` is pure over `Me` plus the
//      tee sheet and needs no ranker, so the four facts are the same four
//      facts either way.
//
// It also carries the assertions the retired `HomeLead` ladder held over the
// CLASH, because the clash payload and D216's yield outlived the ladder.

import Testing
import Foundation
@testable import CupSeasonKit

// MARK: - builders

/// A membership with a clash on it, as `native_home` v3 inlines it.
func clashedMembership(name: String = "Who's the bitch?", week: Int = 5, daysLeft: Int = 4,
                       closesToday: Bool = false, them: String = "Galen Ward",
                       mineGross: Int? = nil, theirGross: Int? = nil, rivalry: String? = nil,
                       rank: Int = 2, prev: Int? = nil, status: String = "active",
                       id: UUID = UUID()) -> Me.Membership {
  let base = heroMembership(name: name, status: status, rank: rank, prev: prev, id: id)
  var dict: [String: Any] = [
    "league_id": base.league_id.uuidString, "name": name, "phase": "season", "role": "player",
    "member_id": base.member_id.uuidString,
    "settings": ["structure": "solo", "buyin_cents": 0, "finish": "cup_final", "counting_cap": 4],
    "season": ["id": UUID().uuidString, "starts_on": "2026-08-03", "ends_on": "2026-11-02",
               "status": status, "timezone": "America/Phoenix"],
    "standing": ["rank": rank, "of": 2, "points": 9, "prev_rank": prev as Any,
                 "leader_points": 21, "gap_to_leader": 12, "leader_name": "Galen"],
    "clash": ["week_no": week, "ends_on": "2026-09-06", "days_left": daysLeft,
              "closes_today": closesToday, "them_name": them, "rivalry": rivalry as Any,
              "mine": mineGross.map { ["gross": $0, "points": 9, "round_id": UUID().uuidString] } as Any,
              "theirs": theirGross.map { ["gross": $0, "points": 6] } as Any],
  ]
  func strip(_ v: Any) -> Any? {
    if v is NSNull { return nil }
    if let d = v as? [String: Any] { return d.compactMapValues(strip) }
    return v
  }
  dict = strip(dict) as! [String: Any]
  let data = try! JSONSerialization.data(withJSONObject: dict)
  return try! JSONDecoder().decode(Me.Membership.self, from: data)
}

private func profile(rounds: Int = 9, index: Double? = 12.4) -> Me.Profile {
  Me.Profile(id: UUID(), display_name: "Jerecho", handle: "jer", marker: "saguaro", city: nil,
             home_course: nil, index_current: index, index_source: "app", photo_path: nil,
             rounds_count: rounds, member_since: nil, is_founder: nil,
             last_round_on: "2026-09-04", last_gross: 89, last_round_id: UUID(), days_since_round: 1)
}

private func feedRow(gross: Int = 79, me: Bool = false, pr: Bool = false) throws -> HomeFeedRow {
  let json = """
  {"round_id":"11111111-1111-1111-1111-111111111111","profile_id":"22222222-2222-2222-2222-222222222222",
   "golfer":"Galen Ward","gross":\(gross),"played_on":"2026-09-03","course":"Lone Tree",
   "is_pr":\(pr),"is_first":false,"is_sub80":false,"is_me":\(me)}
  """
  return try JSONDecoder().decode(HomeFeedRow.self, from: Data(json.utf8))
}

// MARK: - the fallback

@Suite struct HomeFallbackItemsTests {

  @Test("the static order is CLOSING → CHANGED → COMING → CIRCLE, and it is the SAME order every load")
  func staticOrder() throws {
    let me = Me(profile: profile(),
                memberships: [clashedMembership(daysLeft: 1, theirGross: 79, prev: 4)])
    let items = HomeFallbackItems.make(me, feed: [try feedRow()], today: "2026-09-05")
    let tiers: [HomeDispatch.Tier] = items.map(\.tier)
    #expect(tiers == tiers.sorted { $0.fallbackOrder < $1.fallbackOrder }, "\(tiers)")
    #expect(tiers.first == .closing)
    #expect(tiers.contains(.changed))
    #expect(tiers.contains(.circle))
    // deterministic: two runs of the same input are the same screen
    let again: [String] = HomeFallbackItems.make(me, feed: [try feedRow()], today: "2026-09-05").map(\.key)
    #expect(again == items.map(\.key))
  }

  @Test("NO LEAD CARD on the fallback path — the veto is the server's assertion and a guessed lead is not made")
  func noLeadCard() throws {
    let me = Me(profile: profile(), memberships: [clashedMembership(theirGross: 79)])
    let items = HomeFallbackItems.make(me, feed: [], today: "2026-09-05")
    #expect(!items.isEmpty)
    // nothing carries a server rank, so nothing claims to be rank 1
    #expect(items.allSatisfy { $0.rank == nil && $0.score == nil && $0.rankReason == nil })
    // R-06 · and the SCREEN leads with nothing. The assertion above only said
    // no item claimed a rank; the phone still picked a lead off `humanSubject`
    // and drew a card, where the web drew none. §5.4 rule 2 is about the CARD.
    let arranged = HomeRank.arrange(items, useServerRank: false, allowLead: false)
    #expect(arranged.lead == nil)
    #expect(!arranged.deck.isEmpty)
    // and with the ranker's answer in hand the veto still picks one
    #expect(HomeRank.arrange(items, useServerRank: false, allowLead: true).lead != nil)
  }

  @Test("the ME strip is drawn either way — it is pure over the payload and needs no ranker")
  func stripStands() {
    let me = Me(profile: profile(), memberships: [clashedMembership()])
    let strip = MeStripCopy.make(me, upcoming: [], today: "2026-09-05")
    #expect(!strip.isEmpty)
    #expect(strip.slots.map(\.fact).prefix(2) == [.myNumber, .myLastRound])
  }

  @Test("D216 · a clash NEITHER golfer has posted in yields to COMING and never claims a stake")
  func idleClashYields() {
    let idle = HomeFallbackItems.clashItem(clashedMembership(daysLeft: 4), today: "2026-09-05")
    #expect(idle?.tier == .coming)
    #expect(idle?.headline == "Your clash with Galen is open.")
    // the last-call day is a stake again
    #expect(HomeFallbackItems.clashItem(clashedMembership(daysLeft: 1), today: "2026-09-05")?.tier == .closing)
    #expect(HomeFallbackItems.clashItem(clashedMembership(daysLeft: 0, closesToday: true), today: "2026-09-05")?.tier == .closing)
    // and so is a clash somebody has played in
    #expect(HomeFallbackItems.clashItem(clashedMembership(daysLeft: 4, theirGross: 79), today: "2026-09-05")?.tier == .closing)
  }

  @Test("SA-2 · I posted and they have not: the subject is the OPPONENT, and the verb is never 'post again'")
  func iPostedTheyHaveNot() {
    let it = HomeFallbackItems.clashItem(clashedMembership(daysLeft: 2, mineGross: 89), today: "2026-09-05")
    #expect(it?.headline == "Galen has 2 days to answer your 89.")
    #expect(it?.subject == "Galen")
    #expect(it?.action == "See the receipt")
    #expect(it?.suppress.contains(.myLastRound) == true)   // L-34 · the lead spent my round
    // one day left reads as a day, not "1 days"
    #expect(HomeFallbackItems.clashItem(clashedMembership(daysLeft: 1, mineGross: 89), today: "2026-09-05")?.headline
              == "Galen has one day to answer your 89.")
  }

  @Test("A-4 · a movement label carries its own clock — 'since Sunday', never a bare 'held'")
  func movementCarriesItsClock() {
    let up = HomeFallbackItems.movementItem(clashedMembership(rank: 2, prev: 4))
    #expect(up?.headline == "You moved up 2 since Sunday.")
    #expect(up?.tier == .changed)
    // a rank that did not move raises nothing at all
    #expect(HomeFallbackItems.movementItem(clashedMembership(rank: 2, prev: 2)) == nil)
    // and it never fires outside a live season, where prev_rank is a stale snapshot
    #expect(HomeFallbackItems.movementItem(clashedMembership(rank: 2, prev: 4, status: "complete")) == nil)
  }

  @Test("G7 · the shame gate — no fallback sentence names my absence")
  func noShame() throws {
    let me = Me(profile: profile(rounds: 0, index: nil),
                memberships: [clashedMembership(theirGross: 79, prev: 4)])
    let all = HomeFallbackItems.make(me, feed: [try feedRow()], today: "2026-09-05")
      .flatMap { [$0.eyebrow, $0.headline, $0.standfirst ?? "", $0.action ?? ""] }
      .joined(separator: " ").lowercased()
    for banned in ["you haven't", "days since", "streak at risk", "more active than you"] {
      #expect(!all.contains(banned), "the fallback said “\(banned)”")
    }
  }

  @Test("G1 · every fallback item has a door — nothing renders as a dead sentence")
  func everyItemHasADoor() throws {
    let me = Me(profile: profile(rounds: 0, index: nil), memberships: [clashedMembership(mineGross: 89)])
    for item in HomeFallbackItems.make(me, feed: [try feedRow(pr: true)], today: "2026-09-05") {
      #expect(item.route != nil, "\(item.key) has no door")
      #expect(!item.headline.isEmpty, "\(item.key) has no sentence")
    }
  }

  @Test("R-H · a quiet league reaches BACK for an older true fact rather than stopping at nothing")
  func historyRung() throws {
    let json = """
    {"league_id":"33333333-3333-3333-3333-333333333333","name":"The Dew Sweepers","phase":"season",
     "role":"player","member_id":"44444444-4444-4444-4444-444444444444",
     "season":{"id":"55555555-5555-5555-5555-555555555555","starts_on":"2026-01-05","ends_on":"2026-06-05","status":"complete"},
     "last_season":{"number":1,"ended_on":"2026-06-05","champion_name":"Mike","my_rank":4,"of":8}}
    """
    let m = try JSONDecoder().decode(Me.Membership.self, from: Data(json.utf8))
    let it = try #require(HomeFallbackItems.chapterItem(m))
    #expect(it.headline == "Mike took the last one.")
    #expect(it.standfirst == "You finished 4th of 8.")
    #expect(it.subject == "Mike" && it.humanSubject)
    #expect(it.action == "See how it ended")
  }

  @Test("the first-round opportunity fires only on a REAL shape — a golfer with rounds never sees it")
  func opportunityFiresOnShape() {
    let none = Me(profile: profile(rounds: 0, index: nil))
    #expect(HomeFallbackItems.make(none, today: "2026-09-05").contains { $0.key == "first_round" })
    let some = Me(profile: profile(rounds: 9))
    #expect(!HomeFallbackItems.make(some, today: "2026-09-05").contains { $0.key == "first_round" })
  }
}

// MARK: - the clash payload, which outlived the ladder

@Suite struct HomeClashContractTests {

  private func clash(week: Int = 5, days: Int = 4, closesToday: Bool = false,
                     mine: HomeClash.Side? = nil, theirs: HomeClash.Side? = nil,
                     rivalry: String? = nil, settled: Bool = false, roster: Int? = 2) -> HomeClash {
    HomeClash(weekNo: week, endsOn: "2026-09-06", daysLeft: days, closesToday: closesToday,
              themName: "Galen Ward", themMarker: "island", mine: mine, theirs: theirs, rivalry: rivalry,
              settled: settled, roster: roster)
  }

  @Test("D216 · 0–0 mid-week yields; the last-call day, a posted side and a settled clash do not")
  func yields() {
    #expect(clash(days: 4).yields)
    #expect(clash(week: 13, days: 3).yields)
    #expect(!clash(days: 1).yields)
    #expect(!clash(days: 0, closesToday: true).yields)
    #expect(!clash(days: 4, mine: .init(points: 9)).yields)
    #expect(!clash(days: 4, theirs: .init(points: 9)).yields)
    #expect(!clash(days: 4, settled: true).yields)
  }

  @Test("D207 · the first week at 0–0 shows once, and only in a TWO-person league")
  func firstWeek() {
    #expect(!clash(week: 1, days: 4).yields)
    #expect(clash(week: 1, days: 4).isFirstWeekIdle)
    #expect(HomeClashCopy.line(clash(week: 1, days: 4)) == "It's the two of you — every week is the clash.")
    // a bigger league's week 1 is a week like any other, and a payload that cannot count is not two
    #expect(clash(week: 1, days: 4, roster: 8).yields)
    #expect(clash(week: 1, days: 4, roster: nil).yields)
  }

  @Test("the deadline says TODAY, never tonight — golf is played in daylight (D176)")
  func todayNotTonight() {
    let e = HomeClashCopy.eyebrow(clash(days: 0, closesToday: true))
    #expect(e == "The clash · closes today")
    #expect(!e.lowercased().contains("tonight"))
    #expect(HomeClashCopy.eyebrow(clash(days: 1)) == "The clash · one day left")
    #expect(HomeClashCopy.eyebrow(clash(days: 4)) == "The clash · 4 days left")
  }

  @Test("a named rivalry takes the eyebrow; a blank one is not a name")
  func rivalryNamed() {
    #expect(HomeClashCopy.eyebrow(clash(days: 2, rivalry: "The Cactus Cup")) == "The Cactus Cup · 2 days left")
    #expect(HomeClashCopy.eyebrow(clash(days: 2, rivalry: "  ")) == "The clash · 2 days left")
  }

  @Test("D77 · the line names the opponent by FIRST name only, and SA-2 moves the subject onto whoever owes a round")
  func lines() {
    #expect(HomeClashCopy.line(clash()) == "You v Galen. Best round of the week takes it.")
    #expect(HomeClashCopy.line(clash(days: 2, mine: .init(gross: 89))) == "Galen has 2 days to answer your 89.")
    #expect(HomeClashCopy.line(clash(days: 2, theirs: .init(gross: 79))) == "Galen posted 79. That is the number to beat.")
  }

  @Test("a side with nothing posted says so; a side with a round speaks bands, never a differential")
  func sideLines() {
    #expect(HomeClashCopy.sideLine(nil) == "Nothing posted")
    let s = HomeClash.Side(playedOn: "2026-08-27", points: 9, pvi: 2.4, gross: 79)
    #expect(HomeClashCopy.sideLine(s) == "79 · +2.4 · THU")
    let level = HomeClash.Side(playedOn: "2026-08-27", points: 6, pvi: 0.2, gross: 84)
    #expect(HomeClashCopy.sideLine(level).contains("level"))
  }

  @Test("the action follows the state and never dead-ends — and never tells a golfer who has posted to post again")
  func actions() {
    #expect(HomeClashCopy.action(clash()) == "Add my round")
    #expect(HomeClashCopy.action(clash(mine: .init(points: 9, pvi: 2.4), theirs: .init(points: 6, pvi: 0.5))) == "See the receipt")
    #expect(HomeClashCopy.action(clash(mine: .init(points: 6, pvi: 0.5), theirs: .init(points: 9, pvi: 2.4))) == "Post a better one")
  }

  @Test("the edge is decided by POINTS — the band, exactly as settle_week_clash decides it")
  func edgeIsPoints() {
    #expect(clash().edge == .level)
    #expect(clash(mine: .init(points: 6)).edge == .me)
    #expect(clash(theirs: .init(points: 6)).edge == .them)
    #expect(clash(mine: .init(points: 9), theirs: .init(points: 6)).edge == .me)
    #expect(clash(mine: .init(points: 6), theirs: .init(points: 9)).edge == .them)
    #expect(clash(mine: .init(points: 9, pvi: 3.1, gross: 78),
                  theirs: .init(points: 9, pvi: 4.9, gross: 74)).edge == .level)
  }

  @Test("a null RPC result is no card, not a crash; the RPC's shape decodes, sides and all")
  func decode() throws {
    #expect(HomeClash.decode(nil) == nil)
    #expect(HomeClash.decode(.null) == nil)
    let json = """
    {"week_no":5,"ends_on":"2026-09-06","days_left":0,"closes_today":true,
     "them_name":"Galen Ward","them_marker":"island","rivalry":null,
     "mine":null,
     "theirs":{"round_id":"11111111-1111-1111-1111-111111111111","played_on":"2026-08-27",
               "points":9,"pvi":2.4,"gross":79}}
    """
    let v = try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))
    let c = try #require(HomeClash.decode(v))
    #expect(c.weekNo == 5 && c.closesToday && c.daysLeft == 0)
    #expect(c.themName == "Galen Ward")
    #expect(c.mine == nil && c.theirs?.gross == 79)
    #expect(c.theirs?.roundId == UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
    #expect(c.edge == .them)
  }
}

// MARK: - the chips are doors (carried off the retired ladder's suite)

@Suite struct UpNextChipDoorTests {
  @Test("every Up Next chip names a destination — none is a dead end")
  func chipsRoute() throws {
    let rid = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    let json = """
    [{"id":"22222222-2222-2222-2222-222222222222","play_on":"2026-08-30",
      "course_label":"Papago","mine":true}]
    """
    let watch = try JSONDecoder().decode([ScheduledRound].self, from: Data(json.utf8))
    let chips = UpNext.chips(watch: watch, invites: 2, requests: 0, hasMemberships: true, today: "2026-08-28")
    #expect(!chips.isEmpty)
    for c in chips { #expect(c.go != nil, "a chip goes nowhere") }
    #expect(chips.first { $0.k == "Next round" }?.go == .round(rid))
    #expect(chips.first { $0.k == "Needs you" }?.go == .people)
  }

  @Test("the month clock is a door to the league, where the arithmetic lives")
  func monthChipRoutes() {
    let chips = UpNext.chips(watch: [], invites: 0, requests: 0, hasMemberships: true, today: "2026-08-29")
    #expect(chips.first { $0.k == "Month closes" }?.go == .standings)
  }
}
