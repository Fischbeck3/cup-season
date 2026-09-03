// Cup Season — the lead card's ladder (D176). The whole point of the ladder is
// that it is FIXED: the same state must always produce the same card, or a
// screen that changes becomes a screen you cannot learn. These tests are what
// makes that claim enforceable rather than aspirational.

import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct HomeLeadTests {

  private func clash(week: Int = 5, closesToday: Bool = false, days: Int = 4,
                     mine: HomeClash.Side? = nil, theirs: HomeClash.Side? = nil,
                     rivalry: String? = nil, settled: Bool = false, roster: Int? = 2) -> HomeClash {
    HomeClash(weekNo: week, endsOn: "2026-09-06", daysLeft: days, closesToday: closesToday,
              themName: "Galen Ward", themMarker: "island", mine: mine, theirs: theirs, rivalry: rivalry, settled: settled,
              roster: roster)
  }
  private let pulseShort = Me.Pulse(credits: 6, floor: 8, at_floor: false, partial: false)
  private let standingMoved = Me.Standing(rank: 3, of: 8, points: 41, prev_rank: 5, leader_squad_id: nil,
                                          leader_points: 50, gap_to_leader: 9, gap_to_next: 2)

  // ── the order ──────────────────────────────────────────────────────────────

  @Test("the clash outranks everything else on the ladder")
  func clashWins() {
    let lead = HomeLead.choose(clash: clash(mine: .init(points: 9, pvi: 2.4)), pulse: pulseShort, monthDaysLeft: 1,
                               standing: standingMoved,
                               milestone: ("Galen", "🔥 Personal best", UUID(), "island"), phase: .season(week: 5, of: 13))
    guard case .clash = lead else { Issue.record("expected the clash, got \(String(describing: lead))"); return }
  }

  // ── D216 · a clash with nothing to say yields ──────────────────────────────

  @Test("D216 · 0–0 mid-week YIELDS — the rungs below get the slot")
  func emptyClashYieldsMidWeek() {
    let quiet = clash(days: 4)
    #expect(quiet.yields)
    let lead = HomeLead.choose(clash: quiet, pulse: pulseShort, monthDaysLeft: 2, standing: nil, milestone: nil)
    guard case .floor = lead else { Issue.record("expected the floor to take the slot, got \(String(describing: lead))"); return }
    // and with nothing below it, NO card — never "Nothing posted" three mornings running
    #expect(HomeLead.choose(clash: quiet, pulse: nil, monthDaysLeft: nil, standing: nil, milestone: nil) == nil)
  }

  @Test("D216 · the yield is any idle week AFTER the first — week 2, week 3, week 13 alike")
  func emptyClashYieldsFromWeekTwo() {
    for w in [2, 3, 13] {
      let quiet = clash(week: w, days: 4)
      #expect(quiet.yields, "week \(w)")
      #expect(!quiet.isFirstWeekIdle)
      #expect(HomeLead.choose(clash: quiet, pulse: nil, monthDaysLeft: nil, standing: nil, milestone: nil) == nil, "week \(w)")
    }
  }

  @Test("D207 · the first week at 0–0 SHOWS once, and says the board's sentence")
  func firstWeekIdleShows() {
    let opener = clash(week: 1, days: 6)
    #expect(!opener.yields && opener.isFirstWeekIdle)
    guard case .clash(let c) = HomeLead.choose(clash: opener, pulse: pulseShort, monthDaysLeft: 1, standing: standingMoved,
                                              milestone: ("Galen", "🔥 Personal best", nil, nil), phase: .season(week: 1, of: 13))
    else { Issue.record("expected the opener to hold the slot"); return }
    #expect(HomeLeadCopy.clashLine(c) == "It's the two of you — every week is the clash.")
    // the ordinary sentence the moment either side posts — the opener is no longer idle
    #expect(!clash(week: 1, mine: .init(points: 9, pvi: 2.4)).isFirstWeekIdle)
    #expect(HomeLeadCopy.clashLine(clash(week: 1, mine: .init(points: 9, pvi: 2.4))) == "You v Galen. Best round of the week takes it.")
    #expect(HomeLeadCopy.clashLine(clash(week: 1, theirs: .init(points: 6, pvi: 0.5))) == "You v Galen. Best round of the week takes it.")
    // a settled week 1 is a result, not the opener
    #expect(!clash(week: 1, settled: true).isFirstWeekIdle)
    // and week 5 idle never borrows the opener's line
    #expect(!clash(days: 1).isFirstWeekIdle)
    #expect(HomeLeadCopy.clashLine(clash(days: 1)) == "You v Galen. Best round of the week takes it.")
  }

  @Test("D207 · 'It's the two of you' is the TWO-person league's sentence: in a bigger league week 1 is a week like any other, and a payload that cannot count is not two")
  func openerIsTheTwoPersonLeagues() {
    // the server writes the sentence only `when v_wk = 1 and v_roster = 2`
    for n in [3, 8] {
      let opener = clash(week: 1, days: 6, roster: n)
      #expect(!opener.isTwo && !opener.isFirstWeekIdle, "roster \(n)")
      #expect(opener.yields, "roster \(n) · an idle week 1 yields like week 2")
      #expect(HomeLeadCopy.clashLine(opener) == "You v Galen. Best round of the week takes it.", "roster \(n)")
      #expect(HomeLead.choose(clash: opener, pulse: nil, monthDaysLeft: nil, standing: nil, milestone: nil) == nil, "roster \(n)")
      // …and re-enters on the last-call day, saying the ordinary sentence
      let lastCall = clash(week: 1, days: 1, roster: n)
      #expect(!lastCall.yields && HomeLeadCopy.clashLine(lastCall) == "You v Galen. Best round of the week takes it.", "roster \(n)")
    }
    // a v1 payload (no `buy_in.players`, squads' `of` counts squads) cannot say — never the opener
    let unknown = clash(week: 1, days: 6, roster: nil)
    #expect(!unknown.isTwo && !unknown.isFirstWeekIdle && unknown.yields)
    // the RPC does not carry the count; the client hands it over on decode
    let v = JSONValue.object(["week_no": .number(1), "ends_on": .string("2026-09-06"), "days_left": .number(6), "them_name": .string("Galen Ward")])
    #expect(HomeClash.decode(v, roster: 2)?.isFirstWeekIdle == true)
    #expect(HomeClash.decode(v, roster: 3)?.isFirstWeekIdle == false)
    #expect(HomeClash.decode(v)?.isFirstWeekIdle == false)
  }

  @Test("D207 / D216 · the opener never yields, whatever the clock says — `weekNo <= 1`, so a week 0 the RPC should never send is the opener too")
  func openerNeverYields() {
    for w in [0, 1] {
      for d in [0, 1, 4, 6] {
        let c = clash(week: w, closesToday: d == 0, days: d)
        #expect(!c.yields && c.isFirstWeekIdle == (w == 1), "week \(w) · \(d) days")
        guard case .clash(let got) = HomeLead.choose(clash: c, pulse: pulseShort, monthDaysLeft: 1, standing: standingMoved,
                                                     milestone: nil, phase: .season(week: 1, of: 13), solo: true)
        else { Issue.record("expected the clash at week \(w), \(d) days"); continue }
        #expect(HomeLeadCopy.clashLine(got) == (w == 1 ? "It's the two of you — every week is the clash."
                                                       : "You v Galen. Best round of the week takes it."))
      }
    }
    // the four guards of the second fix batch, side by side, on one state:
    // solo → no floor; not .season → no move; nothing else → NO card
    let idle = clash(week: 2, days: 4)
    #expect(HomeLead.choose(clash: idle, pulse: pulseShort, monthDaysLeft: 1, standing: standingMoved, milestone: nil, phase: .cupFinal(weeksLeft: 2), solo: true) == nil)
    #expect(HomeLead.choose(clash: idle, pulse: pulseShort, monthDaysLeft: 1, standing: standingMoved, milestone: nil, phase: .preseason, solo: true) == nil)
    guard case .move = HomeLead.choose(clash: idle, pulse: pulseShort, monthDaysLeft: 1, standing: standingMoved, milestone: nil, phase: .season(week: 2, of: 13), solo: true)
    else { Issue.record("expected the move once the season is on"); return }
    guard case .floor = HomeLead.choose(clash: idle, pulse: pulseShort, monthDaysLeft: 1, standing: standingMoved, milestone: nil, phase: .season(week: 2, of: 13), solo: false)
    else { Issue.record("expected the floor in a squads league"); return }
  }

  @Test("D216 · 0–0 on the last-call day SHOWS")
  func emptyClashShowsLastDay() {
    for c in [clash(closesToday: true, days: 0), clash(days: 1)] {
      #expect(!c.yields)
      guard case .clash = HomeLead.choose(clash: c, pulse: nil, monthDaysLeft: nil, standing: nil, milestone: nil)
      else { Issue.record("expected the clash on the last day"); return }
    }
  }

  @Test("D216 · one side posted SHOWS, whichever side")
  func oneSidePostedShows() {
    let mine = clash(days: 4, mine: .init(points: 9, pvi: 2.4))
    let theirs = clash(days: 4, theirs: .init(points: 6, pvi: 0.5))
    #expect(!mine.yields && !theirs.yields)
    guard case .clash = HomeLead.choose(clash: mine, pulse: pulseShort, monthDaysLeft: 1, standing: nil, milestone: nil),
          case .clash = HomeLead.choose(clash: theirs, pulse: pulseShort, monthDaysLeft: 1, standing: nil, milestone: nil)
    else { Issue.record("expected the clash once a round is on it"); return }
  }

  @Test("D216 · a settled clash SHOWS — it is a result, not a nag")
  func settledShows() {
    let done = HomeClash(weekNo: 5, endsOn: "2026-09-06", daysLeft: 4, closesToday: false, themName: "Galen Ward", settled: true)
    #expect(!done.yields)
    guard case .clash = HomeLead.choose(clash: done, pulse: nil, monthDaysLeft: nil, standing: nil, milestone: nil)
    else { Issue.record("expected the settled clash"); return }
  }

  @Test("the move rung never fires outside the season — prev_rank is a stale snapshot there")
  func moveSuppressedOutsideSeason() {
    for phase in [SeasonPhase.preseason, .forming, .wrapped, .cupFinal(weeksLeft: 2)] {
      let lead = HomeLead.choose(clash: nil, pulse: nil, monthDaysLeft: nil, standing: standingMoved,
                                 milestone: ("Galen", "🔥 Personal best", nil, nil), phase: phase)
      guard case .milestone = lead else { Issue.record("expected the milestone under \(phase), got \(String(describing: lead))"); return }
    }
    // no phase handed over at all → no move, ever
    #expect(HomeLead.choose(clash: nil, pulse: nil, monthDaysLeft: nil, standing: standingMoved, milestone: nil) == nil)
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
                               milestone: ("Galen", "🔥 Personal best", nil, nil), phase: .season(week: 5, of: 13))
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

  @Test("D140 · a solo league has no floor — the rung never fires, whatever the pulse carries")
  func soloHasNoFloor() {
    // the exact state that fires the floor in a squads league…
    guard case .floor = HomeLead.choose(clash: nil, pulse: pulseShort, monthDaysLeft: 1, standing: nil, milestone: nil, solo: false)
    else { Issue.record("expected the floor in a squads league"); return }
    // …is no card at all in a solo one, and the rungs below get the slot
    #expect(HomeLead.choose(clash: nil, pulse: pulseShort, monthDaysLeft: 1, standing: nil, milestone: nil, solo: true) == nil)
    let lead = HomeLead.choose(clash: nil, pulse: pulseShort, monthDaysLeft: 1, standing: standingMoved,
                               milestone: ("Galen", "🔥 Personal best", nil, nil), phase: .season(week: 5, of: 13), solo: true)
    guard case .move = lead else { Issue.record("expected the move under the solo guard, got \(String(describing: lead))"); return }
    // a yielding clash above it changes nothing
    #expect(HomeLead.choose(clash: clash(days: 4), pulse: pulseShort, monthDaysLeft: 0, standing: nil, milestone: nil, solo: true) == nil)
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
    #expect(HomeLead.choose(clash: nil, pulse: nil, monthDaysLeft: nil, standing: held, milestone: nil, phase: .season(week: 5, of: 13)) == nil)
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
