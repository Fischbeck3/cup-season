import Testing
import Foundation
@testable import CupSeasonKit

/// Wave 6 · the title card's producers (surfaces/event.md §2, §9).
///
/// **CASE BELONGS TO THE ROLE**, which is the whole of §9's producer edit 2 and
/// the reason four of these strings changed: `statusChip` shipped
/// `"Live · wk 2/3"` beside `"NAME TAKES THE CUP"`, so one string was shouted
/// by the copy and the other by the view, and neither client could set them the
/// same way. Every producer here returns a sentence; the `agate` role does the
/// shouting.
@Suite struct EventTitleCardCopyTests {
  private var cal: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "America/Phoenix")!
    return c
  }

  private let a = UUID(), b = UUID(), s1 = UUID(), s2 = UUID()

  private func room(status: String = "live", winner: UUID? = nil,
                    sessions: [EventSession] = [], players: Int = 6,
                    aPts: Double = 3.5, bPts: Double = 2.5) -> EventRoom {
    let teamA = EventTeam(id: a, slot: 0, name: "Saguaros", color: 0)
    let teamB = EventTeam(id: b, slot: 1, name: "Coyotes", color: 3)
    let ps = (0..<players).map {
      EventPlayer(id: UUID(), profileId: nil, teamId: $0 < players / 2 ? a : b, seed: $0, name: "P\($0)")
    }
    return EventRoom(event: EventRow(id: UUID(), name: "The Dew Sweepers Cup", created_by: nil,
                                     kind: "ryder", status: status, session_count: 3,
                                     winner_team_id: winner),
                     teams: [teamA, teamB], players: ps, sessions: sessions,
                     scoreboard: [a: aPts, b: bPts])
  }

  // MARK: the eyebrow — and a COUNTDOWN IS NOT A SCORE (§15.5a)

  @Test func theEyebrowCarriesTheClock() {
    let open = EventSession(id: s2, session_no: 2, opens_on: "2026-09-06", closes_on: "2026-09-12", status: "open")
    let closed = EventSession(id: s1, session_no: 1, opens_on: "2026-08-30", closes_on: "2026-09-05", status: "closed")
    let r = room(sessions: [closed, open])
    // the deadline lives HERE, with the other time facts — never on the score rail
    #expect(RyderMath.eyebrow(r, today: "2026-09-10", calendar: cal) == "Live · week 2 of 3 · 2 days left")
    #expect(RyderMath.eyebrow(r, today: "2026-09-11", calendar: cal).hasSuffix("1 day left"))
    #expect(RyderMath.eyebrow(r, today: "2026-09-12", calendar: cal).hasSuffix("closes tonight"))
  }

  @Test func aFinishedEventDropsItsClock() {
    let closed = EventSession(id: s1, session_no: 1, opens_on: "2026-08-30", closes_on: "2026-09-26", status: "closed")
    let r = room(status: "complete", winner: a, sessions: [closed])
    let line = RyderMath.eyebrow(r, today: "2026-09-27", calendar: cal)
    #expect(line.hasPrefix("Final · "))
    #expect(!line.lowercased().contains("left"))
  }

  // MARK: the dateline — ONE block, and the field size belongs to it (finding 4)

  @Test func theDatelineNamesTheRangeAndTheField() {
    let sessions = [EventSession(id: s1, session_no: 1, opens_on: "2026-09-06", closes_on: "2026-09-12", status: "closed"),
                    EventSession(id: s2, session_no: 2, opens_on: "2026-09-13", closes_on: "2026-09-26", status: "open")]
    let line = RyderMath.dateline(room(sessions: sessions), calendar: cal)
    #expect(line == "Sun Sep 6 – Sat Sep 26 · six playing")
    // **an en dash, never an arrow** (§5.2, LINT-13)
    #expect(!line.contains("→"))
  }

  @Test func smallCountsAreWordsAndBigOnesAreNumerals() {
    #expect(RyderMath.spelled(6) == "six")
    #expect(RyderMath.spelled(10) == "ten")
    #expect(RyderMath.spelled(18) == "18")
  }

  // MARK: the score rail's half, composed rather than drawn as one glyph

  @Test func theHalfIsARiderAndNotAString() {
    #expect(RyderMath.evHalfParts(3.5).whole == "3" && RyderMath.evHalfParts(3.5).half)
    #expect(RyderMath.evHalfParts(4).whole == "4" && !RyderMath.evHalfParts(4).half)
    // half a point on its own has no whole number in front of it
    #expect(RyderMath.evHalfParts(0.5).whole.isEmpty && RyderMath.evHalfParts(0.5).half)
    #expect(RyderMath.evHalfParts(0).whole == "0" && !RyderMath.evHalfParts(0).half)
  }

  // MARK: the week head — a label, and its count in the slot beside the rule

  @Test func theWeekHeadIsALabelAndTheStatusIsItsSlot() {
    let s = EventSession(id: s1, session_no: 2, opens_on: "2026-09-06", closes_on: "2026-09-12", status: "open")
    #expect(RyderMath.sessionHeader(s, calendar: cal) == "Week 2 · Sep 6 – Sep 12")
    #expect(RyderMath.sessionSlot(s) == "Open")
    // §16A.2 · a section names its count ONCE, and the label is not where
    #expect(!RyderMath.sessionHeader(s, calendar: cal).lowercased().contains("open"))
  }

  // MARK: the stakes tail — the pot's FIGURE is drawn in gold, never a word here

  @Test func theStakesTailCarriesNoMoney() {
    let tail = RyderMath.stakesTail(potSplit: "places")
    // TERMINOLOGY §4 · the card is the CREDENTIAL, so `best card each week`
    // read as "the best credential each week". The artboard's own word is
    // ROUND, and it has no collision.
    #expect(tail == "The pot · 60/25/15 · best round each week")
    #expect(!tail.contains("$"))
    #expect(RyderMath.stakesTail(potSplit: "wta").contains("winner takes all"))
  }

  // MARK: nothing shouts in a producer any more (§1.3 / LINT-14)

  @Test func noProducerOnThisSurfaceShipsPreUppercasedProse() {
    let closed = EventSession(id: s1, session_no: 1, opens_on: "2026-08-30", closes_on: "2026-09-05", status: "closed")
    let open = EventSession(id: s2, session_no: 2, opens_on: "2026-09-06", closes_on: "2026-09-12", status: "open")
    let live = room(sessions: [closed, open])
    let done = room(status: "complete", winner: a, sessions: [closed])
    let strings = [RyderMath.statusChip(live), RyderMath.statusChip(done),
                   RyderMath.clinchLine(live), RyderMath.clinchLine(done),
                   RyderMath.sessionHeader(open, calendar: cal),
                   RyderMath.stakesTail(potSplit: "places"),
                   RyderMath.dateline(live, calendar: cal)]
    for s in strings {
      // a string is "shouted" when it has three or more consecutive capitals
      // that are not a known acronym — none of these does any more
      #expect(s.range(of: "[A-Z]{3,}", options: .regularExpression) == nil,
              "producer still ships pre-uppercased prose: \(s)")
    }
  }

  @Test func theWinnerIsNamedInTheFinalSentence() {
    let closed = EventSession(id: s1, session_no: 1, opens_on: "2026-08-30", closes_on: "2026-09-05", status: "closed")
    let done = room(status: "complete", winner: a, sessions: [closed], aPts: 5, bPts: 4)
    #expect(RyderMath.clinchLine(done) == "Final. Saguaros took it 5–4.")
    let shared = room(status: "complete", winner: nil, sessions: [closed], aPts: 4.5, bPts: 4.5)
    #expect(RyderMath.clinchLine(shared) == "Final. It was shared, 4½–4½.")
  }

  // MARK: the dates the title card sets

  @Test func theDatesAreTitleCaseAndSpaced() {
    #expect(EventDates.monthDay("2026-09-06", calendar: cal) == "Sep 6")
    #expect(EventDates.dowMonthDay("2026-09-06", calendar: cal) == "Sun Sep 6")
    #expect(EventDates.windowSpaced("2026-09-06", "2026-09-12", calendar: cal) == "Sep 6 – Sep 12")
    #expect(RyderMath.nth(3) == "3rd")
  }
}

/// §5.3's emoji ban, on the one producer that carried a glyph inside a string.
@Suite struct WeatherGlyphTests {
  @Test func theProducerReturnsWordsAndTheMarkIsDrawn() {
    let w = Weather(hi: 71, lo: 55, wind: 9, summary: "Mostly sunny", icon: "sun")
    #expect(w.line == "71° Mostly sunny · 9mph")
    #expect(w.glance == "71° · 9mph")
    for s in [w.line, w.glance] {
      #expect(!s.unicodeScalars.contains { $0.properties.isEmoji && $0.value > 0x238C },
              "the weather producer is drawing a glyph again")
    }
  }
}
