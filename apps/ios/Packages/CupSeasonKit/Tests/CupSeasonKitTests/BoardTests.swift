import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct BandTests {
  @Test func bandsAreTheWebsVerbatim() {
    #expect(CSBands.bandName(3.0) == "Torched it")
    #expect(CSBands.bandName(1.0) == "Beat your number")
    #expect(CSBands.bandName(0.99) == "Played to it")
    #expect(CSBands.bandName(-1.0) == "Played to it")
    #expect(CSBands.bandName(-1.01) == "A little loose")
    #expect(CSBands.bandName(-3.0) == "A little loose")
    #expect(CSBands.bandName(-3.01) == "Posted anyway")
  }

  @Test func pointsFollowTheServerRuleAtMinusOne() {
    // web pointsFor: vs >= -1 → 7 · server cup_points: p_pvi > -1 → 7, else >= -3 → 6
    #expect(CSBands.cupPoints(-1.0) == 6)
    #expect(CSBands.pointsFor(-1.0).points == 6)
    #expect(CSBands.pointsFor(-1.0).line == "A little loose, still cash in the bank.")
    #expect(CSBands.pointsFor(-0.99).points == 7)
    #expect(CSBands.pointsFor(3.4) == (12, "You torched your number by 3.4. Sandbagger alert."))
    #expect(CSBands.pointsFor(2.4) == (9, "You beat your number by 2.4. Nice round."))
    #expect(CSBands.pointsFor(0.4) == (7, "Right on your number. Steady points."))
    #expect(CSBands.pointsFor(-2.2) == (6, "A little loose, still cash in the bank."))
    #expect(CSBands.pointsFor(-5) == (5, "Rough one, but posted rounds always score."))
  }

  @Test func phrasesAndPronouns() {
    #expect(CSBands.vsPhrase(2.4) == "beat your number by 2.4")
    #expect(CSBands.vsPhrase(0.2) == "played to your number")
    #expect(CSBands.vsPhrase(-2.2) == "2.2 over your number")
    #expect(CSBands.vsPhrase(nil) == "")
    #expect(CSBands.theirs("Beat your number") == "Beat their number")
    #expect(CSBands.theirs("BEAT YOUR NUMBER") == "BEAT THEIR NUMBER")
    #expect(CSBands.theirs("Your number") == "Their number")
    #expect(CSBands.fn1("Jerecho Fischbeck") == "Jerecho")
    #expect(CSBands.fn1("   ") == "Someone")
    #expect(CSBands.pviChip(1.4) == "+1.4" && CSBands.pviChip(-0.35) == "-0.4" && CSBands.pviChip(0) == "+0.0")
  }
}

@Suite struct BoardTextTests {
  @Test func easeCapsReadsLikeASentence() {
    #expect(BoardText.easeCaps("ROSTERS LOCKED — THE SEASON IS LIVE") == "Rosters locked — The season is live")
    #expect(BoardText.easeCaps("Mixed Case passes through") == "Mixed Case passes through")
    #expect(BoardText.easeCaps("JERECHO POSTED 92 AT ENCANTO GC.") == "Jerecho posted 92 at encanto gc.")
    #expect(BoardText.easeCaps("MATCH WITH ED ON SAT · 3 UP") == "Match with Ed on Sat · 3 up")
    #expect(BoardText.easeCaps("A & B") == "A & B")
    var names = BoardText.NameRegistry()
    names.learn(["Sandy Wedge", "Back Nine", "Ed"])
    #expect(names.names["sandy wedge"] == "Sandy Wedge")
    #expect(names.names["back nine"] == nil)          // a common golf phrase never enters
    #expect(names.names["ed"] == nil)                 // single names never enter
    #expect(BoardText.easeCaps("SANDY WEDGE'S BUY-IN IS IN", names: names) == "Sandy Wedge's buy-in is in")
  }

  @Test func datesNeverGoThroughUTC() {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "America/Phoenix")!
    #expect(BoardText.shortDate("2026-08-22", calendar: cal) == "Aug 22")
    #expect(BoardText.firstTee("2026-05-03", calendar: cal) == "Sun May 3")
    let d = CSDate.local("2026-08-26", calendar: cal)!
    #expect(BoardText.dateLabel(d, calendar: cal) == "Wed · Aug 26")
    #expect(BoardText.todayLabel(d, calendar: cal) == "Today · Aug 26")
  }

  @Test func humanErrorsAreTheWebs() {
    struct E: LocalizedError { let m: String; var errorDescription: String? { m } }
    #expect(BoardText.humanError(E(m: "TypeError: Failed to fetch"), "Message did not send.") == "Message did not send. Connection hiccup — check your signal and try again.")
    #expect(BoardText.humanError(RpcError(name: "x", underlying: "42501 permission denied for table posts", droppedArgs: [])) == "Please sign in again.")
    #expect(BoardText.humanError(E(m: "Could not find the function public.live_round_card in the schema cache")) == "Just updated — give it a second and try again.")
    #expect(BoardText.humanError(E(m: "duplicate key value violates unique constraint")) == "That already exists.")
    #expect(BoardText.humanError(E(m: "???")) == "Something went wrong — please try again.")
    #expect(BoardText.isSchemaSkew(E(m: "function live_round_card does not exist")))
  }
}

@Suite struct BoardLogicTests {
  func round(_ id: UUID = UUID(), profile: UUID, pvi: Double?, on: String, rank: Int? = nil, gross: Int? = 84) -> BoardRound {
    BoardRound(id: id, profileId: profile, gross: gross, courseLabel: "Papago", playedOn: on, holesPlayed: 18, pvi: pvi, points: 9, monthRank: rank)
  }

  @Test func streakWalksTheCache() {
    let p = UUID()
    let a = round(profile: p, pvi: 1.2, on: "2026-08-01")
    let b = round(profile: p, pvi: 0.4, on: "2026-08-05")     // breaks it
    let c = round(profile: p, pvi: 2.0, on: "2026-08-10")
    let d = round(profile: p, pvi: 1.1, on: "2026-08-15")
    let e = round(profile: p, pvi: 3.3, on: "2026-08-20")
    let other = round(profile: UUID(), pvi: 5, on: "2026-08-21")
    let cache = Dictionary(uniqueKeysWithValues: [a, b, c, d, e, other].map { ($0.id, $0) })
    #expect(BoardLogic.roundStreak(a, cache: cache) == 1)
    #expect(BoardLogic.roundStreak(b, cache: cache) == 0)
    #expect(BoardLogic.roundStreak(d, cache: cache) == 2)
    #expect(BoardLogic.roundStreak(e, cache: cache) == 3)
    #expect(BoardLogic.roundStreak(other, cache: cache) == 1)
  }

  @Test func countingLine() {
    #expect(CountingCap.index(nil) == 3 && CountingCap.index(4) == 1 && CountingCap.index(2) == 0 && CountingCap.index(6) == 2 && CountingCap.index(5) == 1)
    #expect(BoardLogic.counting(monthRank: nil, capIndex: 1).text == "PRE-SEASON · NOT COUNTING")
    #expect(BoardLogic.counting(monthRank: 2, capIndex: 1).text == "COUNTING #2 THIS MONTH")
    #expect(BoardLogic.counting(monthRank: 5, capIndex: 1).text == "BUMPED — OUTSIDE THE BEST 4 THIS MONTH")
    #expect(BoardLogic.counting(monthRank: 9, capIndex: 3).text == "COUNTING #9 THIS MONTH")    // unlimited never bumps
    #expect(BoardLogic.counting(monthRank: 2, capIndex: 1).ok)
  }

  @Test func grossLineSpeaksBandsInTheRightPerson() {
    let me = UUID(), them = UUID()
    let mine = round(profile: me, pvi: 2.4, on: "2026-08-01")
    let theirs = round(profile: them, pvi: 2.4, on: "2026-08-01")
    #expect(BoardLogic.grossLine(mine, viewer: me) == "84 GROSS · BEAT YOUR NUMBER")
    #expect(BoardLogic.grossLine(theirs, viewer: me) == "84 GROSS · BEAT THEIR NUMBER")
    #expect(BoardLogic.grossLine(round(profile: them, pvi: nil, on: "2026-08-01"), viewer: me) == "84 GROSS")
    #expect(BoardLogic.courseLine(mine) == "Papago · 18 holes · 2026-08-01")
  }

  func item(_ kind: BoardKind, who: String = "", text: String, rid: UUID? = nil, at: Date) -> BoardItem {
    BoardItem(id: UUID().uuidString, postId: UUID(), kind: kind, dateLabel: "x", ts: at, who: who, text: text, roundId: rid)
  }

  @Test func digestSentence() {
    let p = UUID()
    let r = round(profile: p, pvi: 2.4, on: "2026-08-20")
    let cache = [r.id: r]
    let t0 = Date(timeIntervalSince1970: 1_700_000_000)
    let items = [
      item(.round, who: "Ed Metz", text: "ED POSTED 84 AT PAPAGO.", rid: r.id, at: t0),
      item(.system, text: "MITCH JOINED THE LEAGUE", at: t0.addingTimeInterval(60)),
      item(.chat, who: "Mitch", text: "who's in Saturday", at: t0.addingTimeInterval(120)),
    ]
    let seenAfter = (t0.timeIntervalSince1970 + 600) * 1000
    let lines = BoardLogic.digest(items: items, cache: cache, names: .init(), marker: seenAfter, next: "Week closes Sun · 3d")
    #expect(lines == ["Ed Metz · Papago · Beat your number", "◆ Mitch joined the league", "Week closes Sun · 3d"])
    // first-ever open: the feed itself is the reveal
    #expect(BoardLogic.digest(items: items, cache: cache, names: .init(), marker: 0, next: nil) == nil)
    // something new landed since the mark: the feed renders exactly as today
    let seenBefore = (t0.timeIntervalSince1970 + 30) * 1000
    #expect(BoardLogic.digest(items: items, cache: cache, names: .init(), marker: seenBefore, next: nil) == nil)
    // no cache entry: the eased post body carries the line
    #expect(BoardLogic.digest(items: items, cache: [:], names: .init(), marker: seenAfter, next: nil)?.first == "Ed posted 84 at papago.")
  }

  @Test func seasonDeadlineLine() {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "America/Phoenix")!
    func season(_ status: String, _ s: String, _ e: String) -> Me.Season {
      Me.Season(id: UUID(), number: 1, starts_on: s, ends_on: e, status: status, timezone: nil, grace_hours: nil,
                champion_squad_id: nil, champion_member_id: nil, points_king_member_id: nil, tiebreak_rung: nil)
    }
    let aug27 = CSDate.local("2026-08-27", calendar: cal)!   // a Thursday
    #expect(BoardLogic.seasonDeadline(season: season("complete", "2026-05-03", "2026-09-26"), finish: nil, phase: "complete", today: aug27, calendar: cal) == "Season complete · settled")
    #expect(BoardLogic.seasonDeadline(season: season("active", "2026-09-06", "2026-12-20"), finish: nil, phase: "season", today: aug27, calendar: cal) == "First tee Sun Sep 6")
    // Cup Final started Aug 30 → still a week-close first: Sunday Aug 30 is 3 days out
    #expect(BoardLogic.seasonDeadline(season: season("active", "2026-05-03", "2026-09-26"), finish: "cup_final", phase: "season", today: aug27, calendar: cal) == "Cup Final · Sun Aug 30 · 3d")
    let sep1 = CSDate.local("2026-09-01", calendar: cal)!
    #expect(BoardLogic.seasonDeadline(season: season("active", "2026-05-03", "2026-09-26"), finish: "cup_final", phase: "season", today: sep1, calendar: cal) == "CUP FINAL LIVE · 25 days left")
    #expect(BoardLogic.seasonDeadline(season: season("active", "2026-05-03", "2026-12-20"), finish: "points", phase: "season", today: aug27, calendar: cal) == "Week closes Sun · 3d")
    #expect(BoardLogic.seasonDeadline(season: nil, finish: nil, phase: "setup", today: aug27, calendar: cal) == nil)
  }
}

@Suite struct ScorecardTests {
  static let json = """
  {"round":{"game":"match","course_label":"Papago","course_snapshot":{"holes":18,"pars":[4,4,3,5,4,4,3,4,5,4,3,4,5,4,4,3,4,5],"si":[7,3,15,1,9,11,17,5,13,8,16,2,10,4,12,18,6,14]},
   "game_config":{"side_a":["Jerecho"],"side_b":["Ed"]},
   "game_result":{"story":"Jerecho def. Ed 3&2","holes":{"mode":"sides","cells":["a",null,"b","a",null,"a","a",null,"b","a",null,"a","a","a","b","a",null,null]}},
   "finished_at":"2026-08-22T18:10:00Z"},
   "players":[{"name":"Jerecho","guest":false,"strokes":[4,4,4,5,4,3,3,4,6,4,3,4,5,4,5,3,4,null]},
              {"name":"Ed","guest":true,"strokes":[5,4,3,6,4,4,4,4,5,5,3,5,6,5,4,4,4,null]}]}
  """

  @Test func decodesTheCard() throws {
    let card = try #require(Scorecard(try JSONDecoder().decode(JSONValue.self, from: Data(Self.json.utf8))))
    #expect(card.eyebrow == "MATCH PLAY · PAPAGO")
    #expect(card.holes == 18 && card.pars?.count == 18 && card.parOut == "36" && card.parIn == "36" && card.parTot == "72")
    let rows = card.rows
    #expect(rows.count == 2)
    #expect(rows[0].cells[0].state == .won)          // ledger cell 'a' is Jerecho's
    #expect(rows[1].cells[0].state == .plain)
    #expect(rows[1].cells[2].state == .won)          // 'b' is Ed's
    #expect(rows[0].cells[5].state == .won)          // won beats bird on the same hole
    #expect(rows[1].cells[10].state == .plain)       // Ed 3 on a par 3
    #expect(rows[0].cells[17].state == .gap && rows[0].cells[17].text == "·")
    #expect(rows[0].out == "37" && rows[0].inn == "32" && rows[0].tot == "69")
    #expect(card.gaps == ["Jerecho", "Ed"])
    let f = card.footer
    #expect(f.prefix == "Aug 22 · Gold marks the holes that decided it. ")
    #expect(f.note == "Not every hole was scored — Jerecho, Ed have gaps." && f.warning)
  }

  @Test func birdiesReadGoldWhenNoLedgerOwnsTheHole() throws {
    var card = try #require(Scorecard(try JSONDecoder().decode(JSONValue.self, from: Data(Self.json.utf8))))
    // the wolf ledger belongs to no row: only the under-par colouring remains
    let wolf = Self.json.replacingOccurrences(of: "\"mode\":\"sides\"", with: "\"mode\":\"wolf\"")
    card = try #require(Scorecard(try JSONDecoder().decode(JSONValue.self, from: Data(wolf.utf8))))
    #expect(card.rows[0].cells[5].state == .bird)
    #expect(card.rows[0].cells[0].state == .plain)
  }

  @Test func nineHolesAndNoRound() throws {
    let nine = Self.json.replacingOccurrences(of: "\"holes\":18", with: "\"holes\":9")
    let card = try #require(Scorecard(try JSONDecoder().decode(JSONValue.self, from: Data(nine.utf8))))
    #expect(card.holes == 9 && card.rows[0].cells.count == 9 && card.rows[0].tot == "37")
    #expect(Scorecard(try JSONDecoder().decode(JSONValue.self, from: Data("{\"round\":null}".utf8))) == nil)
  }
}

@Suite struct ReactionTests {
  @Test func flipIsOptimisticAndReversible() {
    var s = ReactionState(n: 2, me: false, who: ["Mitch", "Logan"])
    s.flip(me: "You", on: true)
    #expect(s == ReactionState(n: 3, me: true, who: ["Mitch", "Logan", "You"]))
    s.flip(me: "You", on: false)
    #expect(s == ReactionState(n: 2, me: false, who: ["Mitch", "Logan"]))
    #expect(CSReactions.all.map(\.emoji) == ["🔥", "🦅", "⛳", "🧊", "🐍", "🚨"])
    #expect(CSReactions.label("🚨") == "sandbagger")
  }

  @Test func timestampsFromTheRealtimePayload() {
    #expect(BoardStore.parseTimestamp("2026-08-27T14:02:11.123456+00:00") != nil)
    #expect(BoardStore.parseTimestamp("2026-08-27T14:02:11Z") != nil)
    #expect(BoardStore.parseTimestamp("2026-08-27 14:02:11.123456+00") != nil)
  }
}
