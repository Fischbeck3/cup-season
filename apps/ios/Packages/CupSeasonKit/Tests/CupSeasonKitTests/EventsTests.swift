// Cup Season — the Ryder's and the Major's arithmetic and copy, pinned to
// the web client's phrasings (index.html line numbers in each suite).

import Testing
import Foundation
@testable import CupSeasonKit

private let evId = UUID(), teamA = UUID(), teamB = UUID()
private let p1 = UUID(), p2 = UUID(), p3 = UUID(), p4 = UUID()
private let s1 = UUID(), s2 = UUID(), s3 = UUID()
private let cal: Calendar = { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "America/Phoenix")!; return c }()

private func team(_ id: UUID, slot: Int, _ name: String) -> EventTeam { EventTeam(id: id, slot: slot, name: name, color: slot) }
private func player(_ id: UUID, _ name: String, team: UUID?, captain: Bool = false) -> EventPlayer {
  EventPlayer(id: id, profileId: UUID(), teamId: team, role: captain ? "captain" : "player", name: name)
}
private func session(_ id: UUID, _ n: Int, _ open: String, _ close: String, _ status: String) -> EventSession {
  EventSession(id: id, session_no: n, opens_on: open, closes_on: close, status: status)
}
private func room(status: String = "live", winner: UUID? = nil, sessionCount: Int = 3, sessions: [EventSession] = [],
                  duels: [EventDuel] = [], score: [UUID: Double] = [:], lineage: [EventLineageRow] = []) -> EventRoom {
  EventRoom(event: EventRow(id: evId, name: "The Grudge", created_by: nil, status: status, session_count: sessionCount, winner_team_id: winner),
            teams: [team(teamA, slot: 0, "Red"), team(teamB, slot: 1, "Blue")],
            players: [player(p1, "Jerecho", team: teamA, captain: true), player(p2, "Will", team: teamA),
                      player(p3, "Jade", team: teamB), player(p4, "Isaak", team: teamB)],
            sessions: sessions, duels: duels, scoreboard: score, lineage: lineage)
}

// MARK: `evHalf` (12196)

@Suite struct EvHalfTests {
  @Test func halves() {
    #expect(RyderMath.evHalf(9.5) == "9½")
    #expect(RyderMath.evHalf(0.5) == "½")
    #expect(RyderMath.evHalf(4) == "4")
    #expect(RyderMath.evHalf(0) == "0")
    #expect(RyderMath.evHalf(6.5) == "6½")
  }
  @Test func nthUp() {
    #expect(RyderMath.nthUp(1) == "1ST"); #expect(RyderMath.nthUp(2) == "2ND"); #expect(RyderMath.nthUp(3) == "3RD")
    #expect(RyderMath.nthUp(4) == "4TH"); #expect(RyderMath.nthUp(11) == "11TH"); #expect(RyderMath.nthUp(12) == "12TH")
    #expect(RyderMath.nthUp(13) == "13TH"); #expect(RyderMath.nthUp(21) == "21ST")
  }
}

// MARK: the clinch (§R4; 12208–12210, 12217–12219)

@Suite struct ClinchTests {
  @Test func sixASideThreeWeeks() {
    let t = RyderMath.target(rosterA: 6, rosterB: 6, sessionCount: 3, sessionRows: 3)
    #expect(t.pairings == 6 && t.points == 18 && t.clinch == 9.5)
  }
  @Test func oddRostersBenchTheSurplus() {
    let t = RyderMath.target(rosterA: 5, rosterB: 4, sessionCount: 3, sessionRows: 3)
    #expect(t.pairings == 4 && t.points == 12 && t.clinch == 6.5)
  }
  @Test func clinchLineLive() {
    let r = room(score: [teamA: 6.5, teamB: 4.5])
    #expect(RyderMath.clinchLine(r) == "FIRST TO 3½ · RED NEEDS 0 · BLUE NEEDS 0")
    let fresh = room(score: [:])
    #expect(RyderMath.clinchLine(fresh) == "FIRST TO 3½ · RED NEEDS 3½ · BLUE NEEDS 3½")
  }
  @Test func clinchLineFinal() {
    let r = room(status: "complete", winner: teamA, score: [teamA: 6.5, teamB: 4.5])
    #expect(RyderMath.clinchLine(r) == "FINAL · 6½–4½")
  }
  @Test func ruleSentence() {
    let t = RyderMath.target(rosterA: 6, rosterB: 6, sessionCount: 3, sessionRows: 3)
    #expect(RyderMath.ruleSentence(t).hasSuffix("First to 9½ of 18 takes the cup."))
    let empty = RyderMath.target(rosterA: 0, rosterB: 3, sessionCount: 3, sessionRows: 3)
    #expect(RyderMath.ruleSentence(empty).hasSuffix("Add players to both teams to set the target."))
  }
}

// MARK: status chips per lifecycle (12213–12216)

@Suite struct RyderStatusChipTests {
  @Test func forming() { #expect(RyderMath.statusChip(room(status: "setup")) == "Forming") }
  @Test func liveWeek() {
    let r = room(sessions: [session(s1, 1, "2026-07-05", "2026-07-11", "closed"), session(s2, 2, "2026-07-12", "2026-07-18", "open")])
    #expect(RyderMath.statusChip(r) == "Live · wk 2/3")
  }
  @Test func liveWeekCapsAtTheCount() {
    let r = room(sessions: [session(s1, 1, "2026-07-05", "2026-07-11", "closed"), session(s2, 2, "2026-07-12", "2026-07-18", "closed"),
                            session(s3, 3, "2026-07-19", "2026-07-25", "closed")])
    #expect(RyderMath.statusChip(r) == "Live · wk 3/3")
  }
  @Test func takesTheCup() { #expect(RyderMath.statusChip(room(status: "complete", winner: teamB)) == "BLUE TAKES THE CUP") }
  @Test func shared() { #expect(RyderMath.statusChip(room(status: "complete", winner: nil)) == "SHARED — BOTH NAMES ON IT") }
}

// MARK: session order S5-02 (12283–12286) · the header · the nag line

@Suite struct SessionOrderTests {
  let sessions = [session(s1, 1, "2026-07-05", "2026-07-11", "upcoming"), session(s2, 2, "2026-07-12", "2026-07-18", "upcoming"),
                  session(s3, 3, "2026-07-19", "2026-07-25", "upcoming")]
  @Test func beforeAnythingClosesSessionOneIsTheStory() {
    #expect(RyderMath.ordered(sessions).map(\.session_no) == [1, 2, 3])
  }
  @Test func onceResultsExistNewestFirst() {
    var s = sessions
    s[0] = session(s1, 1, "2026-07-05", "2026-07-11", "closed")
    #expect(RyderMath.ordered(s).map(\.session_no) == [3, 2, 1])
  }
  @Test func header() {
    #expect(RyderMath.sessionHeader(session(s1, 1, "2026-07-06", "2026-07-12", "open"), calendar: cal) == "SESSION 1 · JUL 6–JUL 12 · OPEN")
  }
  @Test func nagLine() {
    #expect(RyderMath.nagLine(waiting: ["Will", "Jade"], closesOn: "2026-07-11", today: "2026-07-08", calendar: cal) == "Still to post: Will, Jade · 3d left.")
    #expect(RyderMath.nagLine(waiting: ["Will"], closesOn: "2026-07-11", today: "2026-07-11", calendar: cal) == "Still to post: Will · closes tonight.")
    #expect(RyderMath.nagLine(waiting: [], closesOn: "2026-07-11", today: "2026-07-08", calendar: cal) == nil)
  }
  @Test func chipAndWaiting() {
    let d = EventDuel(id: UUID(), session_id: s1, a_player: p1, b_player: p3)
    let open = RyderMath.chip(d, sessionOpen: true, target: EventTarget(a: 1.2, b: nil), aName: "Jerecho", bName: "Jade")
    #expect(open.text == "+1.2 / —" && open.waiting == ["Jade"])
    let resolved = EventDuel(id: UUID(), session_id: s1, a_player: p1, b_player: p3, a_pvi: 2.1, b_pvi: -0.4, result: "a")
    let chip = RyderMath.chip(resolved, sessionOpen: false, target: nil, aName: "Jerecho", bName: "Jade")
    #expect(chip.text == "+2.1 / -0.4" && chip.waiting.isEmpty)
    #expect(RyderMath.chip(d, sessionOpen: false, target: nil, aName: "a", bName: "b").text == nil)
  }
  @Test func record() {
    let duels = [EventDuel(id: UUID(), session_id: s1, a_player: p1, b_player: p3, result: "a"),
                 EventDuel(id: UUID(), session_id: s2, a_player: p3, b_player: p1, result: "a"),
                 EventDuel(id: UUID(), session_id: s3, a_player: p1, b_player: p4, result: "halve"),
                 EventDuel(id: UUID(), session_id: s3, a_player: p2, b_player: p3, result: "pending")]
    #expect(RyderMath.record(of: p1, duels: duels) == "1-1-1")
    #expect(RyderMath.record(of: p2, duels: duels) == "0-0-0")
  }
  @Test func mid() {
    #expect(RyderMath.mid("pending") == "vs"); #expect(RyderMath.mid("halve") == "halved"); #expect(RyderMath.mid("b") == "def.")
  }
}

// MARK: the series line, D62 (12232–12250)

@Suite struct SeriesLineTests {
  let e1 = UUID(), e2 = UUID()
  @Test func leadsTheSeriesAndDefends() {
    let chain = [EventLineageRow(eventId: e1, status: "complete", winnerSlot: 1), EventLineageRow(eventId: e2, status: "complete", winnerSlot: 0),
                 EventLineageRow(eventId: evId, status: "live")]
    #expect(RyderMath.seriesLine(lineage: chain, eventId: evId, status: "live", aName: "Red", bName: "Blue") == "THE 3RD RYDER · SERIES LEVEL 1–1 · RED DEFENDS")
  }
  @Test func sharedCountsHalfEach() {
    let chain = [EventLineageRow(eventId: e1, status: "complete", winnerShared: true), EventLineageRow(eventId: e2, status: "complete", winnerSlot: 1),
                 EventLineageRow(eventId: evId, status: "complete", winnerSlot: 1)]
    #expect(RyderMath.seriesLine(lineage: chain, eventId: evId, status: "complete", aName: "Red", bName: "Blue") == "THE 3RD RYDER · BLUE LEADS THE SERIES 1½–½")
  }
  @Test func quietUntilTheChainHasTwo() {
    #expect(RyderMath.seriesLine(lineage: [EventLineageRow(eventId: evId, status: "live")], eventId: evId, status: "live", aName: "A", bName: "B") == nil)
  }
}

// MARK: the first tee (15909) · isoPlus (16171)

@Suite struct NextSundayTests {
  @Test func aWeekdayRollsToTheComingSunday() { #expect(EventDates.nextSundayISO(today: "2026-08-27", calendar: cal) == "2026-08-30") }   // Thu
  @Test func aSundayRollsAWeek() { #expect(EventDates.nextSundayISO(today: "2026-08-30", calendar: cal) == "2026-09-06") }
  @Test func aSaturdayIsTomorrow() { #expect(EventDates.nextSundayISO(today: "2026-08-29", calendar: cal) == "2026-08-30") }
  @Test func isSunday() { #expect(EventDates.isSunday("2026-08-30", calendar: cal)); #expect(!EventDates.isSunday("2026-08-27", calendar: cal)) }
  @Test func sameWeekdayNextYear() { #expect(EventDates.isoPlus("2026-07-12", 364, calendar: cal) == "2027-07-11") }
}

// MARK: the Major (12363–12404)

@Suite struct MajorTests {
  @Test func vsInWords() {
    #expect(MajorMath.vs(4.2) == "4.2 UNDER"); #expect(MajorMath.vs(-1) == "1 OVER"); #expect(MajorMath.vs(0) == "LEVEL")
    #expect(MajorMath.vs(nil) == "—"); #expect(MajorMath.vs(4.0) == "4 UNDER"); #expect(MajorMath.vs(0.04) == "LEVEL")
  }
  @Test func money() { #expect(MajorMath.money(20) == "$20"); #expect(MajorMath.money(12.5) == "$12.50"); #expect(MajorMath.money(nil) == "$0") }
  @Test func cardLines() {
    #expect(MajorMath.cardLines(days: 4, when: "JUL 9–JUL 12", field: 8, contenders: 6, buyIn: 20, pot: 120, potSplit: "places")
            == ["A MAJOR · 4 DAYS", "JUL 9–JUL 12 · FIELD OF 8 (2 EXHIBITION)", "BUY-IN $20 · POT $120 · 60 / 25 / 15"])
    #expect(MajorMath.cardLines(days: 2, when: "JUL 11–JUL 12", field: 4, contenders: 4, buyIn: 0, pot: 0, potSplit: nil)[2] == "BRAGGING RIGHTS")
    #expect(MajorMath.cardLines(days: 3, when: "", field: 4, contenders: 4, buyIn: 10, pot: 40, potSplit: "wta")[2] == "BUY-IN $10 · POT $40 · WINNER TAKES ALL")
  }
  @Test func statusChips() {
    #expect(MajorMath.statusChip(status: "setup", complete: false, championName: nil, daysLeft: 5, opensAhead: true, opensOn: "2026-07-10", calendar: cal) == "FORMING · OPENS JUL 10")
    #expect(MajorMath.statusChip(status: "setup", complete: false, championName: nil, daysLeft: 1, opensAhead: false, opensOn: "2026-07-10", calendar: cal) == "FORMING")
    #expect(MajorMath.statusChip(status: "live", complete: false, championName: nil, daysLeft: 2, opensAhead: false, opensOn: nil) == "LIVE · 2D LEFT")
    #expect(MajorMath.statusChip(status: "live", complete: false, championName: nil, daysLeft: 0, opensAhead: false, opensOn: nil) == "THE FINAL DAY")
    #expect(MajorMath.statusChip(status: "live", complete: false, championName: nil, daysLeft: -1, opensAhead: false, opensOn: nil) == "AWAITING THE HORN")
    #expect(MajorMath.statusChip(status: "complete", complete: true, championName: "Marcus", daysLeft: -2, opensAhead: false, opensOn: nil) == "MARCUS TAKES THE JUG")
    #expect(MajorMath.statusChip(status: "complete", complete: true, championName: nil, daysLeft: -2, opensAhead: false, opensOn: nil) == "SETTLED — NO CARDS")
  }
  @Test func lineageLine() {
    let e1 = UUID()
    let chain = [EventLineageRow(eventId: e1, kind: "major", status: "complete", champion: "Marcus"), EventLineageRow(eventId: evId, kind: "major", status: "live")]
    #expect(MajorMath.lineageLine(lineage: chain, eventId: evId, complete: false) == "THE 2ND ANNUAL · MARCUS DEFENDS")
    #expect(MajorMath.lineageLine(lineage: chain, eventId: evId, complete: true) == "THE 2ND ANNUAL")
    #expect(MajorMath.lineageLine(lineage: [chain[1]], eventId: evId, complete: false) == nil)
  }
  @Test func cardsLineAndShare() {
    #expect(MajorMath.cardsLine(gross: 82, cards: 2) == "82 · 2 cards")
    #expect(MajorMath.cardsLine(gross: nil, cards: 1, prize: 60) == "1 card · $60")
    #expect(MajorMath.cardsLine(gross: 90, cards: 3, exhibition: true) == "90 · 3 cards · exhibition")
    #expect(MajorMath.shareText(name: "Marcus", jug: "The PIGL Championship", gross: 82, pvi: 4.2) == "Marcus takes The PIGL Championship — 82, 4.2 under their number · cupseason.app")
  }
  @Test func whenLine() {
    #expect(MajorMath.whenLine(finalOn: "2026-07-12", days: 4, calendar: cal) == "Thu, Jul 9 → Sun, Jul 12 · best card by Sunday night")
  }
  @Test func finePrintChoosesMoneyOnlyWhenChosen() {
    #expect(!MajorMath.finePrint(buyIn: 0, potSplit: nil).contains("Pot is a ledger"))
    #expect(MajorMath.finePrint(buyIn: 20, potSplit: "wta").hasSuffix("Pot is a ledger — winner takes it; money moves between friends."))
  }
  @Test func facts() {
    let r = EventRoom(event: EventRow(id: evId, name: "The Jug", created_by: nil, kind: "major", status: "live", buy_in: 20),
                      sessions: [session(s1, 1, "2026-07-09", "2026-07-12", "open")],
                      majorBoard: [MajorBoardRow(playerId: p1, profileId: nil, displayName: "A"), MajorBoardRow(playerId: p2, profileId: nil, displayName: "B", exhibition: true)])
    let f = MajorMath.facts(r, today: "2026-07-10", calendar: cal)
    #expect(f.days == 4 && f.daysLeft == 2 && f.when == "JUL 9–JUL 12" && f.contenders == 1 && f.field == 2 && f.pot == 20 && !f.opensAhead)
  }
}

// MARK: the chips (9668, 15481)

@Suite struct EventChipCopyTests {
  @Test func subs() {
    #expect(EventCopy.chipSub(EventSummary(id: UUID(), name: "x", kind: "ryder", status: "live", mine: true)) == "Ryder · Live")
    #expect(EventCopy.chipSub(EventSummary(id: UUID(), name: "x", kind: "major", status: "setup", mine: false)) == "Major · Enter the field")
    #expect(EventCopy.chipSub(EventSummary(id: UUID(), name: "x", kind: "ryder", status: "complete", mine: true)) == "Ryder · Final")
    #expect(EventCopy.switcherSub(EventSummary(id: UUID(), name: "x", kind: "major", status: "setup", mine: true)) == "A Major · Forming")
  }
}
