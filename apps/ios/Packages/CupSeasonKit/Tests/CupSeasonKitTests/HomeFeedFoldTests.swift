// Cup Season — D217 · the feed folds its league notes (the Home hard-look,
// 2026-09-02). The shape under test is the real one from 2026-09-02: seven
// system lines over two leagues, one posted round, two settlement lines that
// know their live round.

import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct HomeFeedFoldTests {
  static let wtb = UUID(), fellas = UUID()
  static let names = [wtb: "Who's the bitch?", fellas: "Fellas"]
  static let booking = UUID(), liveA = UUID(), liveB = UUID(), roundX = UUID()

  static func at(_ day: String, _ hm: String = "09:00") -> Date {
    let f = DateFormatter(); f.calendar = .current; f.timeZone = .current; f.dateFormat = "yyyy-MM-dd HH:mm"
    return f.date(from: "\(day) \(hm)")!
  }

  static func post(_ league: UUID, _ kind: String, _ body: String, _ day: String, _ hm: String = "09:00",
                   live: UUID? = nil, round: UUID? = nil, scheduled: UUID? = nil, id: UUID = UUID()) -> HomeItem {
    .post(HomePost(id: id, league_id: league, kind: kind, body: body, created_at: at(day, hm),
                   live_round_id: live, round_id: round, scheduled_round_id: scheduled), leagueName: names[league])
  }

  static func round(_ day: String) -> HomeItem {
    let json: [String: Any] = ["round_id": roundX.uuidString, "profile_id": UUID().uuidString, "golfer": "Jerecho", "marker": "saguaro",
                               "handle": "j", "gross": 85, "pvi": 1.2, "played_on": day, "course": "Encanto GC",
                               "is_pr": false, "is_first": false, "is_sub80": false, "is_me": true]
    let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601
    return .round(try! d.decode(HomeFeedRow.self, from: try! JSONSerialization.data(withJSONObject: json)), photoURL: nil)
  }

  /// The feed as 2026-09-01 ended, newest first — the hard-look shape.
  static func today() -> [HomeItem] {
    [
      post(wtb, "system", "Galen put a round on the books — Mon Sep 07 · Gold Canyon — Dinosaur Mountain · Black/Blue · with Jerecho", "2026-09-01", "18:10", scheduled: booking),
      post(fellas, "system", "August is in the books. The ledger is posted. A partial month — floors waived.", "2026-09-01", "00:05"),
      post(wtb, "system", "August is in the books. The ledger is posted. A partial month — floors waived.", "2026-09-01", "00:05"),
      post(fellas, "system", "The clash this week: Jade v Jerecho.", "2026-08-31"),
      post(wtb, "system", "The clash this week: Galen v Jerecho.", "2026-08-31"),
      post(wtb, "system", "This week: Galen v Jerecho.", "2026-08-30"),
      post(fellas, "system", "This week: Jade v Jerecho.", "2026-08-30"),
      round("2026-08-28"),
      post(fellas, "moment", "Jerecho took the week — 85 at Encanto GC.", "2026-08-28", "20:00", live: liveA),
      post(wtb, "moment", "Galen took the week.", "2026-08-23", "20:00", live: liveB),
    ]
  }

  @Test("seven system lines over two leagues fold to three notes; the golf passes through")
  func todayShape() {
    let b = HomeFeedFold.fold(Self.today(), today: "2026-09-01")
    #expect(b.map(\.label) == ["Today", "This week", "Earlier"])
    // Today: the booking (WTB) and ONE month-close line carrying both leagues
    let today = b[0].items
    #expect(today.count == 2)
    guard case .notes(let booking) = today[0], case .notes(let close) = today[1] else { Issue.record("expected two notes today"); return }
    #expect(booking.leagueNames == ["Who's the bitch?"] && booking.count == 1)
    #expect(booking.line(bucket: "Today") == "Who's the bitch? · 1 league note today")
    #expect(close.leagueIds == [Self.fellas, Self.wtb] && close.leagueNames == ["Fellas", "Who's the bitch?"] && close.count == 1)
    #expect(close.line(bucket: "Today") == "Fellas & Who's the bitch? · 1 league note today")
    // This week: the round and the settlement first, then one group per league
    let week = b[1].items
    #expect(week.count == 4)
    guard case .round = week[0], case .moment = week[1], case .notes(let f) = week[2], case .notes(let w) = week[3]
    else { Issue.record("expected round · moment · notes · notes, got \(week.map(\.id))"); return }
    #expect(f.leagueNames == ["Fellas"] && f.count == 2 && f.line(bucket: "This week") == "Fellas · 2 league notes this week")
    #expect(w.leagueNames == ["Who's the bitch?"] && w.count == 2 && w.line(bucket: "This week") == "Who's the bitch? · 2 league notes this week")
    #expect(f.rows.map(\.body) == ["The clash this week: Jade v Jerecho.", "This week: Jade v Jerecho."])
    // Earlier: the WTB settlement, untouched
    guard case .moment(let p, let n) = b[2].items[0] else { Issue.record("expected the earlier moment"); return }
    #expect(p.live_round_id == Self.liveB && n == "Who's the bitch?")
    // nothing was lost: 7 system rows → 5 distinct lines in 4 groups + 1 round + 2 moments
    let notes = b.flatMap(\.items).compactMap { if case .notes(let n) = $0 { return n.count } ; return nil }.reduce(0, +)
    #expect(notes == 6)
  }

  @Test("the folded line reads as a sentence in every bucket — 'earlier' is an adjective and comes before the noun")
  func lineByBucket() {
    func notes(_ n: Int, names: [String] = ["Fellas"]) -> HomeFeedNotes {
      HomeFeedNotes(leagueIds: names.map { _ in UUID() }, leagueNames: names,
                    rows: (0..<n).map { HomePost(id: UUID(), league_id: Self.fellas, kind: "system", body: "note \($0)", created_at: nil) })
    }
    #expect(notes(2).line(bucket: "This week") == "Fellas · 2 league notes this week")
    #expect(notes(1).line(bucket: "This week") == "Fellas · 1 league note this week")
    #expect(notes(3).line(bucket: "Today") == "Fellas · 3 league notes today")
    #expect(notes(1, names: ["Fellas", "Who's the bitch?"]).line(bucket: "Today") == "Fellas & Who's the bitch? · 1 league note today")
    // "3 league notes earlier" is not a sentence anyone says
    #expect(notes(3).line(bucket: "Earlier") == "Fellas · 3 earlier league notes")
    #expect(notes(1).line(bucket: "Earlier") == "Fellas · 1 earlier league note")
    #expect(notes(2, names: ["Fellas", "Who's the bitch?"]).line(bucket: "Earlier") == "Fellas & Who's the bitch? · 2 earlier league notes")
    // a note that lost its league name still reads
    #expect(notes(2, names: []).line(bucket: "Earlier") == "League · 2 earlier league notes")
    // and through the fold: three Fellas lines from a fortnight ago land in Earlier and say so
    let old = (0..<3).map { Self.post(Self.fellas, "system", "An old note \($0).", "2026-08-1\($0 + 5)") }
    let b = HomeFeedFold.fold(old, today: "2026-09-01")
    #expect(b.map(\.label) == ["Earlier"])
    guard case .notes(let n) = b[0].items[0] else { Issue.record("expected one folded note"); return }
    #expect(n.line(bucket: b[0].label) == "Fellas · 3 earlier league notes")
  }

  @Test("a booking the Coming-up card already shows is hidden from the feed")
  func bookingHidden() {
    let b = HomeFeedFold.fold(Self.today(), upcoming: [Self.booking], today: "2026-09-01")
    #expect(b[0].items.count == 1)
    guard case .notes(let close) = b[0].items[0] else { Issue.record("expected the month-close note"); return }
    #expect(close.leagueNames == ["Fellas", "Who's the bitch?"])
    // a different upcoming set hides nothing
    #expect(HomeFeedFold.fold(Self.today(), upcoming: [UUID()], today: "2026-09-01")[0].items.count == 2)
  }

  @Test("identical bodies collapse only across leagues and only within 48 hours")
  func sameNoteWindow() {
    let sameLeague = [Self.post(Self.wtb, "system", "Same words.", "2026-09-01"), Self.post(Self.wtb, "system", "Same words.", "2026-09-01", "08:00")]
    let one = HomeFeedFold.fold(sameLeague, today: "2026-09-01")
    guard case .notes(let n) = one[0].items[0] else { Issue.record("expected notes"); return }
    #expect(n.count == 2 && n.leagueIds == [Self.wtb])
    let farApart = [Self.post(Self.wtb, "system", "Same words.", "2026-09-01"), Self.post(Self.fellas, "system", "Same words.", "2026-08-27")]
    let two = HomeFeedFold.fold(farApart, today: "2026-09-01")
    #expect(two.flatMap(\.items).count == 2)
    let close = [Self.post(Self.wtb, "system", "Same words.", "2026-09-01"), Self.post(Self.fellas, "system", "same words. ", "2026-08-30", "10:00")]
    let merged = HomeFeedFold.fold(close, today: "2026-09-01").flatMap(\.items)
    #expect(merged.count == 1)
    guard case .notes(let m) = merged[0] else { Issue.record("expected one merged note"); return }
    // the leagues read by name (canonical, see `canonicalKey`); the surviving row is still the newest
    #expect(m.leagueIds == [Self.fellas, Self.wtb] && m.leagueNames == ["Fellas", "Who's the bitch?"] && m.rows.first?.league_id == Self.wtb)
  }

  @Test("the group's key is canonical — notes that survived as {A,B} and as {B,A} fold into ONE group")
  func canonicalKey() {
    // two month-close-style pairs on one day: the WTB copy is the newest of the
    // first, the Fellas copy the newest of the second — before the sort they
    // were two groups, "Who's the bitch? & Fellas" over "Fellas & Who's the bitch?"
    let rows = [
      Self.post(Self.wtb, "system", "August is in the books.", "2026-09-01", "10:00"),
      Self.post(Self.fellas, "system", "August is in the books.", "2026-09-01", "09:00"),
      Self.post(Self.fellas, "system", "The clash this week is set.", "2026-09-01", "08:00"),
      Self.post(Self.wtb, "system", "The clash this week is set.", "2026-09-01", "07:00"),
    ]
    let b = HomeFeedFold.fold(rows, today: "2026-09-01")
    #expect(b.map(\.label) == ["Today"] && b[0].items.count == 1)
    guard case .notes(let n) = b[0].items[0] else { Issue.record("expected one folded group"); return }
    #expect(n.leagueIds == [Self.fellas, Self.wtb] && n.leagueNames == ["Fellas", "Who's the bitch?"])
    #expect(n.count == 2 && n.rows.map(\.league_id) == [Self.wtb, Self.fellas])
    #expect(n.line(bucket: "Today") == "Fellas & Who's the bitch? · 2 league notes today")
    // a lone note in one league is its own group beside the pair, in the order first seen
    let three = HomeFeedFold.fold(rows + [Self.post(Self.wtb, "system", "Only here.", "2026-09-01", "06:00")], today: "2026-09-01")
    #expect(three[0].items.count == 2)
    guard case .notes(let pair) = three[0].items[0], case .notes(let lone) = three[0].items[1] else { Issue.record("expected two groups"); return }
    #expect(pair.leagueIds == [Self.fellas, Self.wtb] && lone.leagueIds == [Self.wtb] && lone.line(bucket: "Today") == "Who's the bitch? · 1 league note today")
  }

  @Test("D219 · a door iff the row knows its round: live, then round, then the booking")
  func doors() {
    let live = HomePost(id: UUID(), league_id: Self.wtb, kind: "moment", body: "x", created_at: nil, live_round_id: Self.liveA, round_id: Self.roundX, scheduled_round_id: Self.booking)
    #expect(HomeFeedFold.door(for: live) == .live(Self.liveA))
    let posted = HomePost(id: UUID(), league_id: Self.wtb, kind: "moment", body: "x", created_at: nil, round_id: Self.roundX, scheduled_round_id: Self.booking)
    #expect(HomeFeedFold.door(for: posted) == .round(Self.roundX))
    let booked = HomePost(id: UUID(), league_id: Self.wtb, kind: "system", body: "x", created_at: nil, scheduled_round_id: Self.booking)
    #expect(HomeFeedFold.door(for: booked) == .scheduled(Self.booking))
    let plain = HomePost(id: UUID(), league_id: Self.wtb, kind: "system", body: "x", created_at: nil)
    #expect(HomeFeedFold.door(for: plain) == nil)
    // through the folded items: a lone booking note opens its round; a group of two does not
    let b = HomeFeedFold.fold(Self.today(), today: "2026-09-01")
    #expect(b[0].items[0].door == .scheduled(Self.booking))
    #expect(b[0].items[1].door == nil)
    #expect(b[1].items[0].door == .round(Self.roundX))
    #expect(b[1].items[1].door == .live(Self.liveA))
    #expect(b[1].items[2].door == nil)
  }

  @Test("HomePost decodes with and without the D219 column — deploy skew")
  func postDecodes() throws {
    let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601
    let v1 = #"{"id":"\#(UUID().uuidString)","league_id":"\#(Self.wtb.uuidString)","kind":"system","member_id":null,"body":"x","created_at":"2026-09-01T09:00:00Z","live_round_id":null}"#
    let a = try d.decode(HomePost.self, from: Data(v1.utf8))
    #expect(a.round_id == nil && a.scheduled_round_id == nil)
    let v2 = #"{"id":"\#(UUID().uuidString)","league_id":"\#(Self.wtb.uuidString)","kind":"system","member_id":null,"body":"x","created_at":"2026-09-01T09:00:00Z","live_round_id":null,"round_id":null,"scheduled_round_id":"\#(Self.booking.uuidString)"}"#
    let b = try d.decode(HomePost.self, from: Data(v2.utf8))
    #expect(b.scheduled_round_id == Self.booking)
    #expect(HomeStreamRepository.postColumns.hasSuffix("round_id") && !HomeStreamRepository.postColumns.contains("scheduled"))
  }
}
