// Cup Season — the lead card's ladder (D176). The whole point of the ladder is
// that it is FIXED: the same state must always produce the same card, or a
// screen that changes becomes a screen you cannot learn. These tests are what
// makes that claim enforceable rather than aspirational.

import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct HomeLeadTests {

  private func clash(closesToday: Bool = false, days: Int = 4,
                     mine: HomeClash.Side? = nil, theirs: HomeClash.Side? = nil,
                     rivalry: String? = nil) -> HomeClash {
    HomeClash(weekNo: 5, endsOn: "2026-09-06", daysLeft: days, closesToday: closesToday,
              themName: "Galen Ward", themMarker: "island", mine: mine, theirs: theirs, rivalry: rivalry)
  }
  private let pulseShort = Me.Pulse(credits: 6, floor: 8, at_floor: false, partial: false)
  private let standingMoved = Me.Standing(rank: 3, of: 8, points: 41, prev_rank: 5, leader_squad_id: nil,
                                          leader_points: 50, gap_to_leader: 9, gap_to_next: 2)

  // ── the order ──────────────────────────────────────────────────────────────

  @Test("the clash outranks everything else on the ladder")
  func clashWins() {
    let lead = HomeLead.choose(clash: clash(), pulse: pulseShort, monthDaysLeft: 1,
                               standing: standingMoved,
                               milestone: ("Galen", "🔥 Personal best", UUID(), "island"))
    guard case .clash = lead else { Issue.record("expected the clash, got \(String(describing: lead))"); return }
  }

  @Test("the floor outranks a move and a buddy's milestone")
  func floorSecond() {
    let lead = HomeLead.choose(clash: nil, pulse: pulseShort, monthDaysLeft: 2,
                               standing: standingMoved,
                               milestone: ("Galen", "🔥 Personal best", nil, nil))
    guard case .floor(let d, let c, let f) = lead else { Issue.record("expected the floor"); return }
    #expect(d == 2); #expect(c == 6); #expect(f == 8)
  }

  @Test("a move outranks a buddy's milestone")
  func moveThird() {
    let lead = HomeLead.choose(clash: nil, pulse: nil, monthDaysLeft: nil, standing: standingMoved,
                               milestone: ("Galen", "🔥 Personal best", nil, nil))
    guard case .move(let r, let of, let from, _) = lead else { Issue.record("expected the move"); return }
    #expect(r == 3); #expect(of == 8); #expect(from == 5)
  }

  @Test("nothing true means NO card — the hero is the resting state")
  func nothingIsNil() {
    #expect(HomeLead.choose(clash: nil, pulse: nil, monthDaysLeft: nil, standing: nil, milestone: nil) == nil)
  }

  // ── the floor's guards ─────────────────────────────────────────────────────

  @Test("a met floor raises no card")
  func floorMet() {
    let met = Me.Pulse(credits: 9, floor: 8, at_floor: true, partial: false)
    #expect(HomeLead.choose(clash: nil, pulse: met, monthDaysLeft: 1, standing: nil, milestone: nil) == nil)
  }

  @Test("a PARTIAL month never asks for a floor — §14.0 waives them")
  func partialWaived() {
    let partial = Me.Pulse(credits: 0, floor: 8, at_floor: false, partial: true)
    #expect(HomeLead.choose(clash: nil, pulse: partial, monthDaysLeft: 0, standing: nil, milestone: nil) == nil)
  }

  @Test("the floor is silent until three days out — the chip already says it earlier")
  func floorWindow() {
    #expect(HomeLead.choose(clash: nil, pulse: pulseShort, monthDaysLeft: 4, standing: nil, milestone: nil) == nil)
    #expect(HomeLead.choose(clash: nil, pulse: pulseShort, monthDaysLeft: 3, standing: nil, milestone: nil) != nil)
  }

  @Test("a rank that did not move raises no card")
  func heldRank() {
    let held = Me.Standing(rank: 3, of: 8, points: 41, prev_rank: 3, leader_squad_id: nil,
                           leader_points: 50, gap_to_leader: 9, gap_to_next: 2)
    #expect(HomeLead.choose(clash: nil, pulse: nil, monthDaysLeft: nil, standing: held, milestone: nil) == nil)
  }

  // ── the words ──────────────────────────────────────────────────────────────

  @Test("the deadline says TODAY, never tonight — golf is played in daylight")
  func todayNotTonight() {
    let e = HomeLeadCopy.clashEyebrow(clash(closesToday: true, days: 0))
    #expect(e == "The clash · closes today")
    #expect(!e.lowercased().contains("tonight"))
    #expect(HomeLeadCopy.clashEyebrow(clash(days: 1)) == "The clash · one day left")
    #expect(HomeLeadCopy.clashEyebrow(clash(days: 4)) == "The clash · 4 days left")
  }

  @Test("a named rivalry takes the eyebrow — the one line all season where it belongs")
  func rivalryNamed() {
    #expect(HomeLeadCopy.clashEyebrow(clash(days: 2, rivalry: "The Cactus Cup")) == "The Cactus Cup · 2 days left")
    // blank is not a name
    #expect(HomeLeadCopy.clashEyebrow(clash(days: 2, rivalry: "  ")) == "The clash · 2 days left")
  }

  @Test("the line names the opponent by FIRST name only — D77")
  func firstNameOnly() {
    #expect(HomeLeadCopy.clashLine(clash()) == "You v Galen. Best round of the week takes it.")
  }

  @Test("a side with nothing posted says so; a side with a round speaks bands")
  func sideLines() {
    #expect(HomeLeadCopy.sideLine(nil) == "Nothing posted")
    let s = HomeClash.Side(playedOn: "2026-08-27", points: 9, pvi: 2.4, gross: 79)
    #expect(HomeLeadCopy.sideLine(s) == "79 · +2.4 · THU")
    let level = HomeClash.Side(playedOn: "2026-08-27", points: 6, pvi: 0.2, gross: 84)
    #expect(HomeLeadCopy.sideLine(level).contains("level"))
  }

  @Test("the action follows the state, and never dead-ends")
  func actions() {
    #expect(HomeLeadCopy.clashAction(clash()) == "Post a round")
    let ahead = clash(mine: .init(points: 9, pvi: 2.4), theirs: .init(points: 6, pvi: 0.5))
    #expect(HomeLeadCopy.clashAction(ahead) == "See the receipt")
    let behind = clash(mine: .init(points: 6, pvi: 0.5), theirs: .init(points: 9, pvi: 2.4))
    #expect(HomeLeadCopy.clashAction(behind) == "Post a better one")
  }

  @Test("the edge is decided by POINTS — the band, exactly as settle_week_clash decides it")
  func edgeIsPoints() {
    #expect(clash().edge == .level)                                                  // neither posted
    #expect(clash(mine: .init(points: 6)).edge == .me)                               // walkover
    #expect(clash(theirs: .init(points: 6)).edge == .them)
    #expect(clash(mine: .init(points: 9), theirs: .init(points: 6)).edge == .me)
    #expect(clash(mine: .init(points: 6), theirs: .init(points: 9)).edge == .them)
    // same band, different strokes: ALL SQUARE (D2 — the band decides, not gross)
    #expect(clash(mine: .init(points: 9, pvi: 3.1, gross: 78),
                  theirs: .init(points: 9, pvi: 4.9, gross: 74)).edge == .level)
  }

  @Test("the floor line states the gap, not the total")
  func floorWords() {
    #expect(HomeLeadCopy.floorEyebrow(days: 0) == "The month closes today")
    #expect(HomeLeadCopy.floorEyebrow(days: 1) == "The month closes tomorrow")
    #expect(HomeLeadCopy.floorEyebrow(days: 3) == "The month closes in 3 days")
    #expect(HomeLeadCopy.floorLine(credits: 6, floor: 8).hasPrefix("You're 2 short of the floor"))
  }

  @Test("a move up and a move down read differently, and the lead reads as news")
  func moveWords() {
    #expect(HomeLeadCopy.moveEyebrow(rank: 3, from: 5) == "Up 2")
    #expect(HomeLeadCopy.moveEyebrow(rank: 5, from: 3) == "Down 2")
    #expect(HomeLeadCopy.moveLine(rank: 1, of: 8, from: 3, gapToLead: nil) == "1st of 8. A new leader.")
    #expect(HomeLeadCopy.moveLine(rank: 3, of: 8, from: 5, gapToLead: 9) == "3rd of 8, 9 back.")
  }

  // ── the decode ─────────────────────────────────────────────────────────────

  @Test("a null RPC result is no card, not a crash")
  func decodeNull() {
    #expect(HomeClash.decode(nil) == nil)
    #expect(HomeClash.decode(.null) == nil)
  }

  @Test("the RPC's shape decodes, sides and all")
  func decodeShape() throws {
    let json = """
    {"week_no":5,"ends_on":"2026-09-06","days_left":0,"closes_today":true,
     "them_name":"Galen Ward","them_marker":"island","rivalry":null,
     "mine":null,
     "theirs":{"round_id":"11111111-1111-1111-1111-111111111111","played_on":"2026-08-27",
               "points":9,"pvi":2.4,"gross":79}}
    """
    let v = try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))
    let c = try #require(HomeClash.decode(v))
    #expect(c.weekNo == 5)
    #expect(c.closesToday)
    #expect(c.daysLeft == 0)
    #expect(c.themName == "Galen Ward")
    #expect(c.mine == nil)
    #expect(c.theirs?.gross == 79)
    #expect(c.theirs?.roundId == UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
    #expect(c.edge == .them)
  }

  // ── the chips are doors ────────────────────────────────────────────────────

  @Test("every Up Next chip names a destination — none is a dead end")
  func chipsRoute() throws {
    // ScheduledRound is a GENERATED row (Rpc.my_schedule.Row) — it decodes, it
    // is not hand-built, which is also how it arrives in the app.
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
    // 3 days from the end of August
    let chips = UpNext.chips(watch: [], invites: 0, requests: 0, hasMemberships: true, today: "2026-08-29")
    #expect(chips.first { $0.k == "Month closes" }?.go == .standings)
  }
}
