import Testing
import Foundation
@testable import CupSeasonKit

// The receipt's arithmetic row, the named bands, the form row, the career
// tiles, "n of 3", the rivalry and league-record strings — each against the
// web's own output (index.html line numbers in the sources).

@Suite struct ReceiptRowTests {
  let biltmore = ReceiptSeed(id: UUID(), gross: 86, differential: 21.5, indexAtPost: 10.0, playedOn: "2026-07-25",
                             courseLabel: "Arizona Biltmore Links · Copper", holesPlayed: 18, rating: 64.9, slope: 111,
                             points: 5, monthRank: 3, countingCap: 4)

  @Test func theArithmeticRowShowsItsWork() {
    let rows = ReceiptRows.build(biltmore, capN: nil, viewerId: nil)
    #expect(rows[0] == .math(label: "The course", value: "64.9 / 111", sub: false))
    // D209 · the number rows come FIRST, then the arithmetic; D210 · "VS COURSE"
    #expect(rows[1] == .math(label: "Your number that day", value: "10.0", sub: true))
    #expect(rows[2] == .math(label: "86 − 64.9 × 113 ⁄ 111", value: "21.5 VS COURSE", sub: true))
    #expect(rows[3] == .math(label: "Against your number", value: "-11.5 — POSTED ANYWAY", sub: false))
    #expect(rows[4] == .math(label: "Points", value: "5", sub: false))
    #expect(rows[5] == .math(label: "This month", value: "COUNTING #3", sub: false))
    #expect(rows.count == 6)
  }

  @Test func nineHolesUseTheNineRatingAndSayHalfValue() {
    var r = biltmore
    r.holesPlayed = 9; r.nineRating = 32.1; r.gross = 42; r.differential = 10.1
    let rows = ReceiptRows.build(r, capN: nil, viewerId: nil)
    #expect(rows.contains(.math(label: "42 − 32.1 × 113 ⁄ 111", value: "10.1 VS COURSE", sub: true)))
    #expect(rows.contains(.math(label: "Nine holes", value: "HALF VALUE · HALF A ROUND", sub: false)))
  }

  @Test func someoneElsesRoundReadsTheir() {
    var r = biltmore
    r.isMine = false; r.pvi = 2.4
    let rows = ReceiptRows.build(r, capN: nil, viewerId: nil)
    #expect(rows.contains(.math(label: "Their number that day", value: "10.0", sub: true)))
    #expect(rows.contains(.math(label: "Against their number", value: "+2.4 — BEAT THEIR NUMBER", sub: false)))
  }

  @Test func bumpedPastTheCapAndTheHandOff() {
    var r = ReceiptSeed(gross: 90, monthRank: 5, attested: true, playedWith: ["Garrett", "Mike"], liveRoundId: UUID())
    r.countingCap = nil
    let rows = ReceiptRows.build(r, capN: 4, viewerId: nil)
    #expect(rows.contains(.math(label: "This month", value: "BUMPED", sub: false)))
    #expect(rows.contains(.math(label: "Attested", value: "PLAYED WITH THE GROUP", sub: false)))
    #expect(rows.contains(.playedWith(["Garrett", "Mike"])))
    if case .scorecard = rows.last! {} else { Issue.record("expected the scorecard hand-off last") }
    // unlimited cap: everything counts
    #expect(ReceiptRows.build(r, capN: nil, viewerId: nil).contains(.math(label: "This month", value: "COUNTING #5", sub: false)))
  }

  @Test func headerAndTheD95Alias() {
    #expect(biltmore.title == "86 gross")
    #expect(biltmore.subtitle == "ARIZONA BILTMORE LINKS · COPPER · 18 HOLES · 2026-07-25")
    let feedRow = ReceiptSeed.from(json: .object(["course": .string("Papago GC"), "gross": .number(82), "holes_played": .number(18)]))
    #expect(feedRow.courseLabel == "Papago GC")
    #expect(ReceiptSeed().title == "The round")
    #expect(ReceiptSeed().subtitle == "SOMEWHERE OUT THERE · 18 HOLES")
  }

  @Test func enrichMergesLikeObjectAssign() {
    let seed = ReceiptSeed(id: UUID(), gross: 86, courseLabel: nil, photoURL: URL(string: "https://x/y.jpg"), points: 9, marker: "thistle")
    let merged = seed.merged(with: .object(["course_label": .string("Papago GC"), "points": .null, "rating": .number(70.2), "slope": .number(125)]))
    #expect(merged.courseLabel == "Papago GC")
    #expect(merged.points == nil)                      // a null in the payload overwrites, as Object.assign does
    #expect(merged.photoURL == seed.photoURL)          // keys the payload lacks survive
    #expect(merged.marker == "thistle")
    #expect(merged.rating == 70.2 && merged.slope == 125)
  }
}

@Suite struct BandTests {
  @Test func theFiveBands() {
    #expect(RoundCopy.bandName(3.0) == "Torched it")
    #expect(RoundCopy.bandName(1.0) == "Beat your number")
    #expect(RoundCopy.bandName(-0.99) == "Played to it")
    #expect(RoundCopy.bandName(-1.0) == "A little loose")     // D210/Q-20: half-open at −1.0
    #expect(RoundCopy.bandName(-1.1) == "A little loose")
    #expect(RoundCopy.bandName(-3.1) == "Posted anyway")
  }
  @Test func phrases() {
    #expect(RoundCopy.vsPhrase(2.4) == "beat your number by 2.4")
    #expect(RoundCopy.vsPhrase(0.3) == "played to your number")
    #expect(RoundCopy.vsPhrase(-1.3) == "1.3 over your number")
    #expect(RoundCopy.vsPhrase(nil) == "")
    #expect(RoundCopy.theirs("Beat your number") == "Beat their number")
    #expect(RoundCopy.theirs("BEAT YOUR NUMBER") == "BEAT THEIR NUMBER")
    #expect(RoundCopy.firstName("Jerecho Fischbeck") == "Jerecho")
    #expect(RoundCopy.firstName("  ") == "Someone")
  }
  @Test func theMinusOneSeamIsGone() {
    // D210 · `RoundCopy` used to keep the web's `>= -1` while the server's
    // `cup_points()` said `> -1`, so a round at exactly −1.0 previewed 7 and
    // scored 6. Every producer here now reads `CSBands`, and the two agree.
    #expect(RoundCopy.pointsFor(-1.0).points == CSBands.cupPoints(-1.0))
    #expect(RoundCopy.pointsFor(-1.0).points == 6)
    #expect(RoundCopy.pointsFor(-0.99).points == 7)
    #expect(RoundCopy.vsPhrase(-1.0) == "1.0 over your number")
    #expect(RoundCopy.vsPhrase(-0.99) == "played to your number")
    #expect(RoundCopy.pointsFor(3).points == 12 && RoundCopy.pointsFor(1).points == 9 && RoundCopy.pointsFor(-4).points == 5)
    #expect(RoundCopy.signed(1.25) == "+1.2" || RoundCopy.signed(1.25) == "+1.3")
    #expect(RoundCopy.signed(-0.4) == "-0.4")
  }

  /// Y-13 · the club acronym is repaired; everything else in the label is left
  /// exactly as it was stored. The first three are the labels actually sitting
  /// in `rounds.course_label`
  /// (`20260830230000_course_key_and_backfill.sql:82-84`): two title-cased
  /// upstream by GolfCourseAPI, one typed by a golfer.
  @Test func courseLabelsFixTheAcronymAndNothingElse() {
    #expect(RoundCopy.course("Arizona Biltmore Cc — Links · Copper") == "Arizona Biltmore CC — Links · Copper")
    #expect(RoundCopy.course("Palo Verde Gc · Back") == "Palo Verde GC · Back")
    #expect(RoundCopy.course("Encanto GC") == "Encanto GC")                       // already right: untouched
    #expect(RoundCopy.course("Raven Golf Club-Phoenix · Silver") == "Raven Golf Club-Phoenix · Silver")
    #expect(RoundCopy.course("Troon North Golf Course — Pinnacle Course") == "Troon North Golf Course — Pinnacle Course")
    // no re-casing of the label at large: a small word stays small, a lowercase
    // name stays lowercase, and only the acronym moves
    #expect(RoundCopy.course("lone tree at the ranch") == "lone tree at the ranch")
    #expect(RoundCopy.course("papago gc") == "papago GC")
    #expect(RoundCopy.course("Whisper Rock G&cc") == "Whisper Rock G&CC")          // punctuation splits the runs
    #expect(RoundCopy.course(nil) == "" && RoundCopy.course("") == "")
  }
}

@Suite struct FormRowTests {
  @Test func dotsReadOldestToNewestAndTheStreakCountsFromTheNewest() {
    let f = FormRow.from(beats: [true, true, true, false, true])!   // newest first, as payloads arrive
    #expect(f.dots == [true, false, true, true, true])
    #expect(f.streak == 3)
    #expect(f.tag == "3 STRAIGHT UNDER")
    #expect(f.hot)
    #expect(f.accessibilityLabel == "Form, last 5 rounds, 3 straight under")
  }
  @Test func twoIsWarmOneIsNoTag() {
    let two = FormRow.from(beats: [true, true, false])!
    #expect(two.tag == "2 STRAIGHT UNDER" && !two.hot)
    let one = FormRow.from(beats: [true, false, true, true])!
    #expect(one.tag == nil && one.streak == 1)
  }
  @Test func nothingToDrawRendersNothing() {
    #expect(FormRow.from(beats: []) == nil)
    #expect(FormRow.from(beats: [nil, nil]) == nil)      // the skew rule: no verdicts, no row
    let mixed = FormRow.from(beats: [nil, true])!
    #expect(mixed.dots == [true, nil] && mixed.streak == 0)
  }

  /// Y-08 · the dots' key. The You tab had one and the Tour Card — the
  /// surface headed "this is how your buddies see you" — did not, which is
  /// the one place the reader is least likely to know what a lit dot means.
  /// Both keys are cut from ONE sentence: the card's is short because the row
  /// beside it has already drawn the five dots, and it is in the person the
  /// card is about, because that card is usually somebody else's.
  @Test func bothFormKeysAreCutFromTheSameSentence() {
    // byte-for-byte with the web's `CS_FORM_KEY` (index.html)
    #expect(YouCopy.formKey == "Your last five rounds, oldest first — a lit dot beat your playing number.")
    #expect(YouCopy.formKeyCard(mine: false) == "Last five, oldest first — a lit dot beat their playing number.")
    #expect(YouCopy.formKeyCard(mine: true) == "Last five, oldest first — a lit dot beat your playing number.")
    // the load-bearing half — the reading order and what a lit dot IS — is
    // the SAME string on every surface, which is the point of one producer
    let tail = "oldest first — a lit dot beat"
    #expect(YouCopy.formKey.contains(tail))
    #expect(YouCopy.formKeyCard(mine: false).contains(tail))
    #expect(YouCopy.formKeyCard(mine: true).hasSuffix(YouCopy.formKey.suffix(from: YouCopy.formKey.range(of: tail)!.lowerBound)))
    // the card's key never says "your" on a card that is not yours
    #expect(!YouCopy.formKeyCard(mine: false).contains("your"))
  }
}

@Suite struct CareerTests {
  func row(_ d: Double?, _ i: Double?, gross: Int = 85) -> RoundRow {
    RoundRow(id: UUID(), gross: gross, differential: d, index_at_post: i, played_on: "2026-06-01", course_label: "Papago GC", holes_played: 18)
  }
  /// one `v_rounds_ranked` row: the ALLOWANCE figure the engine scored with
  func lens(_ round: UUID, _ season: UUID, pvi: Double, points: Double? = nil) -> RankedRound {
    RankedRound(member_id: UUID(), pvi: pvi, points: points, month_rank: 1, floor_credit: 1, played_on: "2026-06-01",
                index_at_post: 12.4, holes_played: 18, round_id: round, season_id: season)
  }

  /// D209 · every All-time figure is the engine's allowance PvI. A round the
  /// engine never scored (card-only) carries no figure and is not averaged.
  @Test func everyFigureIsTheAllowanceLensNeverAReDerivedOne() {
    let s = UUID()
    let rows = [row(9.1, 12.4), row(11.2, 12.4), row(7.8, 12.4), row(14.6, 12.4), row(10.3, 12.4), row(nil, nil)]
    // 95% allowance: the engine's numbers, NOT `index_at_post − differential`
    let ranked = [lens(rows[0].id, s, pvi: 2.7, points: 9), lens(rows[1].id, s, pvi: 0.6, points: 7),
                  lens(rows[2].id, s, pvi: 4.0, points: 12), lens(rows[3].id, s, pvi: -2.8, points: 6),
                  lens(rows[4].id, s, pvi: 1.5, points: 9)]
    let c = Career.compute(rows: rows, ranked: ranked, preferredSeason: s, played: 3)
    #expect(c.rounds == 6)
    #expect(c.counting == 5)                              // the sixth round has no lens
    #expect(c.best == 4.0 && c.bestText == "+4.0")        // best AGAINST the playing number
    #expect(abs((c.avg ?? 0) - 1.2) < 0.0001)             // (2.7 + 0.6 + 4.0 − 2.8 + 1.5) / 5
    #expect(c.avgText == "+1.2")
    #expect(c.figureScope == "across 5 counting rounds")   // Y-14 · the figures name their denominator
    #expect(c.played == 3)
    #expect(c.recent.count == 5)
    #expect(c.figure(for: rows[2]) == 4.0)
    #expect(c.figure(for: rows[5]) == nil)                // card-only: no figure, never a re-derived one
  }

  /// The preferred league's lens wins when one round scored in two seasons.
  @Test func onePreferredLensPerRound() {
    let mine = UUID(), other = UUID()
    let rows = [row(9.1, 12.4)]
    let ranked = [lens(rows[0].id, other, pvi: 3.3, points: 12), lens(rows[0].id, mine, pvi: 2.7, points: 9)]
    #expect(Career.compute(rows: rows, ranked: ranked, preferredSeason: mine, played: 1).figure(for: rows[0]) == 2.7)
  }

  /// Y-22 · the FORM row says the figures out loud, oldest → newest.
  @Test func formSpeaksItsDots() {
    let s = UUID()
    let rows = [row(9.1, 12.4), row(11.2, 12.4), row(7.8, 12.4)]
    let ranked = [lens(rows[0].id, s, pvi: 2.7, points: 9), lens(rows[2].id, s, pvi: 4.0, points: 12)]
    let f = Career.compute(rows: rows, ranked: ranked, preferredSeason: s, played: 1).form!
    #expect(f.dots == [true, nil, true])                            // oldest → newest
    #expect(f.accessibilityLabel == "Form, last three: 12, no number, 9")
  }

  @Test func emptyCard() {
    let c = Career.compute(rows: [], ranked: [], preferredSeason: nil, played: 0)
    #expect(c.bestText == "—" && c.avgText == "—" && c.roundsText == "0")
    #expect(c.figureScope == YouCopy.noCountingRounds)              // Y-28: the dash says why
    #expect(c.form == nil)
  }

  @Test func nOfThree() {
    #expect(Career.establishing(rounds: 0) == "0 of 3")
    #expect(Career.establishing(rounds: 2) == "2 of 3")
    #expect(Career.establishing(rounds: 7) == "3 of 3")
  }

  // MARK: - D208 · "Leagues & events · Played in"

  func seen(_ status: String?, _ start: String?, number: Int? = 1, sandbox: Bool = false, season: UUID? = nil) -> Career.LeagueSeen {
    Career.LeagueSeen(seasonId: season, seasonNumber: number, seasonStatus: status, startsOn: start, sandbox: sandbox)
  }

  @Test func playedInCountsLeaguesThatStarted() {
    let today = "2026-06-01"
    // an abandoned wizard, a locked league whose first tee has not come, a sandbox
    #expect(Career.playedIn(leagues: [seen(nil, nil)], events: 0, rankedSeasons: [], today: today) == 0)
    #expect(Career.playedIn(leagues: [seen("active", "2026-09-01")], events: 0, rankedSeasons: [], today: today) == 0)
    #expect(Career.playedIn(leagues: [seen("active", "2026-05-03", sandbox: true)], events: 0, rankedSeasons: [], today: today) == 0)
    // kicked off; a second season (the first one ran); a round held in it
    #expect(Career.playedIn(leagues: [seen("active", "2026-05-03")], events: 0, rankedSeasons: [], today: today) == 1)
    #expect(Career.playedIn(leagues: [seen("setup", nil, number: 2)], events: 0, rankedSeasons: [], today: today) == 1)
    let s = UUID()
    #expect(Career.playedIn(leagues: [seen("active", "2026-09-01", season: s)], events: 0, rankedSeasons: [s], today: today) == 1)
    // a sandbox never counts, not even holding a round
    #expect(Career.playedIn(leagues: [seen("active", "2026-05-03", sandbox: true, season: s)], events: 0, rankedSeasons: [s], today: today) == 0)
    // events ride on top
    #expect(Career.playedIn(leagues: [seen("active", "2026-05-03")], events: 2, rankedSeasons: [], today: today) == 3)
  }

  @Test func anEventCountsOnceYouAreOnItsRoster() {
    func ev(slot: Int?, organizer: Bool?) -> Me.Event {
      Me.Event(id: UUID(), name: "The Ryder", kind: "ryder", status: "setup", starts_on: nil, league_id: nil,
               my_team_slot: slot, is_organizer: organizer)
    }
    #expect(Career.onRoster([ev(slot: 1, organizer: false)]) == 1)   // on a team
    #expect(Career.onRoster([ev(slot: nil, organizer: false)]) == 1) // a player with no team yet
    #expect(Career.onRoster([ev(slot: nil, organizer: true)]) == 0)  // organising one you do not play in
    #expect(Career.onRoster([ev(slot: 2, organizer: true)]) == 1)    // organising one you do
  }
}

@Suite struct DisplayCaseTests {
  @Test func tilesAndTheirSubtitles() {
    let t = Rpc.my_trophies.Row(id: nil, kind: "ryder", title: "The Grudge", subtitle: "The Ryder", placement: "winner", season_year: 2026, earned_on: nil)
    let a = Achievement(kind: "sub_80", label: "Broke 80", earned_on: "2026-06-14", meta: .object(["gross": .number(79)]))
    let pb = Achievement(kind: "personal_best", label: nil, earned_on: "2026-06-14", meta: .object(["diff": .number(7.8)]))
    let tiles = TrophyCase.tiles(trophies: [t], achievements: [a, pb])
    #expect(tiles[0].icon == "⚔️" && tiles[0].title == "The Grudge" && tiles[0].sub == "The Ryder · '26")
    #expect(tiles[1].icon == "🔥" && tiles[1].title == "Broke 80" && tiles[1].sub == "79 gross · '26")
    // D210 · the banned word is off the tile; the figure is named for what it is
    #expect(tiles[2].icon == "📉" && tiles[2].title == "Personal best" && tiles[2].sub == "7.8 vs course · '26")
    #expect(TrophyMeta.trophyIcon("bracket") == "🥊" && TrophyMeta.trophyIcon("league") == "🏆")
    #expect(TrophyMeta.meta(kind: "mystery", label: nil).title == "Milestone")
  }

  /// Y-20 · `round_id` is the door to the receipt, and it is skew-safe: the
  /// migration that adds it has not shipped, so today's payload has no key.
  @Test func aMilestoneWithARoundIsADoorAndOneWithoutIsInert() throws {
    let json = #"""
      [{"kind":"sub_80","label":"Broke 80","earned_on":"2026-06-14","meta":{"gross":79},"round_id":"5ED6E3F8-0B1E-4E1D-9E8B-0C4B6C4C3E11"},
       {"kind":"first_round","label":"First round","earned_on":"2026-05-03"}]
      """#
    let rows = try JSONDecoder().decode([Achievement].self, from: Data(json.utf8))
    #expect(rows[0].round_id != nil)
    #expect(rows[1].round_id == nil)                       // absent key → nil, not a decode failure
    let tiles = TrophyCase.tiles(trophies: [], achievements: rows)
    #expect(tiles[0].roundId == rows[0].round_id && tiles[1].roundId == nil)
  }

  /// Y-02 · one empty state. The record strip has nothing to draw, so the
  /// case's line is the only sentence a new golfer reads.
  @Test func anEmptyCaseSaysItOnce() {
    #expect(TrophyCase.tiles(trophies: [], achievements: []).isEmpty)
    #expect(TrophyCase.emptyLine.hasPrefix("No hardware yet."))
    #expect(CareerRecord.parse(.object([:])).items.isEmpty)
  }

  @Test func credentialLines() {
    let ach = (1...5).map { Achievement(kind: "sub_90", label: nil, earned_on: "2026-0\($0)-01", meta: nil) }
    // P3 · one constant for both credentials (the hero and the Tour Card)
    let lines = TrophyMeta.credLines(ach)
    #expect(TrophyMeta.credentialChips == 3)
    #expect(lines.count == 4 && lines[0] == "🎯 Broke 90 · '26" && lines[3] == "+2 more in the case")
    // the hero engraves them all and expands to the rest in place
    #expect(TrophyMeta.credChips(ach).count == 5)
    #expect(TrophyMeta.moreLine(2, suffix: TrophyMeta.moreInCase) == "+2 more in the case")
  }
  @Test func onlyArrivalsEngrave() {
    let tiles = [TrophyTile(id: "a1", icon: "⛳", title: "First round", sub: "Posted"), TrophyTile(id: "t2", icon: "🏆", title: "Cup", sub: "")]
    #expect(TrophySeenStore.fresh(tiles, seen: nil).isEmpty)           // first paint is a boot render
    #expect(TrophySeenStore.fresh(tiles, seen: ["a1"]) == ["t2"])
  }
}

@Suite struct RecordTests {
  @Test func careerRecordOmitsNoughtsAndSumsSettled() {
    let r = CareerRecord.parse(.object(["cups": .number(2), "runner_ups": .number(1), "crowns": .number(0), "majors": .number(0),
                                        "events": .number(1), "earnings_cents": .number(36000), "seasons_done": .number(3)]))
    #expect(r.items.map(\.label) == ["Cups", "Event", "Runner-up"])
    #expect(r.moneyLine?.amount == "$360" && r.moneyLine?.sub == "Settled across 3 seasons")
    let none = CareerRecord.parse(.object([:]))
    #expect(none.items.isEmpty && none.moneyLine == nil)
  }

  @Test func leagueRecordLines() {
    let sid = UUID(), me = UUID(), other = UUID()
    let season = Me.Season(id: sid, number: 2, starts_on: "2026-05-03", ends_on: "2026-09-26", status: "active", timezone: nil, grace_hours: nil,
                           champion_squad_id: nil, champion_member_id: nil, points_king_member_id: nil, tiebreak_rung: nil)
    let st = [IndividualStanding(season_id: sid, member_id: other, points: 50, rounds_posted: 5), IndividualStanding(season_id: sid, member_id: me, points: 41, rounds_posted: 4)]
    // Y-09 · the stage words are `LeagueCopy.Stage`'s, never retyped here; the
    // case is the line's, so one mono row never mixes "Forming" with "41 PTS".
    #expect(LeagueRecord.line(phase: "setup", season: nil, standings: [], myMemberId: me) == LeagueCopy.Stage.forming.label.uppercased())
    #expect(LeagueRecord.line(phase: "draft", season: season, standings: st, myMemberId: me) == LeagueCopy.Stage.drawing.label.uppercased())
    #expect(LeagueRecord.line(phase: "season", season: season, standings: st, myMemberId: me, today: "2026-06-01") == "2ND OF 2 · 41 PTS")
    var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "America/Phoenix")!
    // 2026-05-03 is a Sunday; the label derives it rather than assuming it
    #expect(LeagueRecord.line(phase: "season", season: season, standings: st, myMemberId: me, today: "2026-04-20", calendar: cal) == "FIRST TEE SUN MAY 3")
    let cup = Me.Season(id: sid, number: 2, starts_on: "2026-05-03", ends_on: "2026-09-26", status: "cup_final", timezone: nil, grace_hours: nil,
                        champion_squad_id: nil, champion_member_id: nil, points_king_member_id: nil, tiebreak_rung: nil)
    #expect(LeagueRecord.line(phase: "season", season: cup, standings: st, myMemberId: me, today: "2026-09-01") == "CUP FINAL · 2ND OF 2 · 41 PTS")
    #expect(LeagueRecord.line(phase: "complete", season: season, standings: st, myMemberId: UUID(), today: "2026-10-01") == "FINISHED —")
    let r2 = LeagueRecordRow(id: UUID(), name: "PIGL", number: 2, line: "3RD OF 12 · 41 PTS")
    #expect(r2.sub == "SEASON II · 3RD OF 12 · 41 PTS")
    #expect(r2.spoken == "Season 2, 3rd of 12 · 41 pts")   // Y-33 · not "S E A S O N I I", and not "P T S" either
    #expect(LeagueRecord.ordUpper(1) == "1ST" && LeagueRecord.ordUpper(11) == "11TH" && LeagueRecord.ordUpper(21) == "21ST" && LeagueRecord.ordUpper(3) == "3RD")
  }

  @Test func seasonStrip() {
    let me = UUID(), sid = UUID()
    let rows = [RankedRound(member_id: me, pvi: 1.4, points: 9, month_rank: 1, floor_credit: 1, played_on: "2026-05-10", index_at_post: 12.4, holes_played: 18),
                RankedRound(member_id: me, pvi: -0.6, points: 7, month_rank: 2, floor_credit: 1, played_on: "2026-05-17", index_at_post: 12.1, holes_played: 18),
                RankedRound(member_id: UUID(), pvi: 4, points: 12, month_rank: 1, floor_credit: 1, played_on: "2026-05-17", index_at_post: 8, holes_played: 18)]
    let s = SeasonStats.compute(rows: rows, standings: [IndividualStanding(season_id: sid, member_id: me, points: 16, rounds_posted: 2)], myMemberId: me)
    #expect(s.roundsText == "2" && s.avgText == "+0.4" && s.bestText == "+1.4" && s.deltaText == "▼ 0.3")
    #expect(s.counting == 2 && s.figureScope == "across 2 counting rounds" && s.deltaSub == YouCopy.seasonToDate)
    // Y-28 · two rounds and the number did not move is "Held", not a dash;
    // a dash is only "there is no second round yet", and the sub says so.
    let held = SeasonStats(rounds: 2, counting: 2, avg: 0.4, best: 1.4, delta: 0.0)
    #expect(held.deltaText == YouCopy.held && held.deltaSub == YouCopy.seasonToDate)
    #expect(SeasonStats.empty.avgText == "—" && SeasonStats.empty.deltaText == "—")
    #expect(SeasonStats.empty.deltaSub == YouCopy.needsTwoRounds && SeasonStats.empty.figureScope == YouCopy.noCountingRounds)
    // Y-14 · "Needs 2 rounds" beside "17 rounds posted" read as nonsense; it
    // means two rounds in THIS season, and now says so.
    #expect(YouCopy.needsTwoRounds == "Needs 2 rounds this season")
    // Y-14 · the singular is the whole point of the line: one counting round
    // makes the best and the average the same number.
    #expect(YouCopy.acrossCounting(1) == "across 1 counting round")
  }
}

@Suite struct RivalryTests {
  @Test func theFacetedRecord() {
    let r = Rpc.my_rivalries.Row(opponent: UUID(), display_name: "Garrett", handle: "g", marker: "thistle", wins: 4, losses: 2, ties: 1, meetings: 7,
                                 lead: "up", duel_wins: 3, duel_losses: 2, duel_halves: 0, rivalry_name: "The Grudge")
    let line = RivalryLine.from(r)!
    #expect(line.record == "4–2–1" && line.lead == .up)
    #expect(line.facets == "7 weeks head-to-head · Ryder duels 3–2")
    #expect(line.rivalryName == "The Grudge")
    let quiet = RivalryLine.from(Rpc.my_rivalries.Row(opponent: UUID(), display_name: nil, handle: nil, marker: nil, wins: 0, losses: 1, ties: 0, meetings: 1,
                                                      lead: "down", duel_wins: 0, duel_losses: 0, duel_halves: 0, rivalry_name: ""))!
    #expect(quiet.record == "0–1" && quiet.facets == "1 week head-to-head" && quiet.rivalryName == nil && quiet.name == "—")
  }
  @Test func weekRows() {
    let w = RivalryWeek.from(Rpc.rivalry_weeks.Row(wk: "2026-07-06", my_pvi: 1.2, opp_pvi: -0.4, winner: "me"), opponentName: "Garrett")!
    #expect(w.wkLabel == "WK OF\nJUL 6" && w.verdictText == "WON" && w.headline == "YOU +1.2 · Garrett -0.4")
    #expect(RivalryCopy.leadLabel(wins: 3, losses: 2) == "YOU LEAD" && RivalryCopy.leadLabel(wins: 2, losses: 2) == "ALL SQUARE")
  }
}

@Suite struct TourCardParseTests {
  @Test func parsesTheRpcShape() {
    let json: JSONValue = .object([
      "visible": .bool(true),
      "profile": .object(["id": .string(UUID().uuidString), "display_name": .string("Garrett"), "handle": .string("garrett"), "marker": .string("thistle"),
                          "city": .string("Mesa"), "index_current": .number(14.2), "ghin": .string("123"), "member_since": .string("2026-05-03T14:03:11.123456+00:00"), "is_me": .bool(false)]),
      "career": .object(["rounds": .number(12), "best": .number(7.8), "avg_pvi": .number(-0.4)]),
      "trophies": .array([.object(["kind": .string("sub_90"), "label": .string("Broke 90"), "earned_on": .string("2026-06-01"), "meta": .null])]),
      "recent": .array([.object(["played_on": .string("2026-08-03"), "course_label": .string("Papago GC"), "gross": .number(82), "differential": .number(9.1), "holes_played": .number(18), "beat": .bool(true)])]),
      "vs_you": .object(["wins": .number(3), "losses": .number(2), "ties": .number(0)]),
    ])
    let c = TourCard.parse(json)
    #expect(c.visible && c.profile.displayName == "Garrett" && c.profile.ghin == "123")
    #expect(c.profile.memberSince != nil)
    #expect(c.bestText == "7.8" && c.avgText == "-0.4")
    #expect(c.trophies.first?.kind == "sub_90")
    #expect(c.recent.first?.beat == true)
    #expect(c.vsYou?.chip == "VS YOU · 3–2 · YOU LEAD")
    #expect(TourCard.parse(.object(["visible": .bool(false)])).visible == false)
    // the OLD payload has no allowance keys at all: the lens stays off and the
    // 100% average is decoded into the field whose name says what it is.
    #expect(c.playingLens == false && c.career.avgVsIndex == -0.4 && c.career.avgPvi == nil)
    #expect(TourCard.bestLabel(playingLens: false) == "Best round vs course")
    #expect(TourCard.avgLabel(playingLens: false, isMe: true) == "Avg vs your number")
    #expect(TourCard.careerEyebrow(playingLens: false, isMe: true) == "Career")
  }

  /// D209 · migration 20260902180000 corrects `avg_pvi` to the allowance mean,
  /// adds `best_pvi`, and preserves the 100% average as `avg_vs_index`.
  @Test func theAllowanceLens() {
    func card(_ career: JSONValue) -> TourCard {
      TourCard.parse(.object(["visible": .bool(true), "profile": .object(["is_me": .bool(true)]), "career": career]))
    }
    let on = card(.object(["rounds": .number(12), "best": .number(7.8), "avg_pvi": .number(2.6),
                           "best_pvi": .number(4.0), "avg_vs_index": .number(-0.4)]))
    #expect(on.playingLens && on.bestText == "+4.0" && on.avgText == "+2.6")
    #expect(TourCard.bestLabel(playingLens: true) == "Best round")
    #expect(TourCard.avgLabel(playingLens: true, isMe: true) == "Avg")
    #expect(TourCard.careerEyebrow(playingLens: true, isMe: true) == "Career · vs your playing number")
    #expect(TourCard.careerEyebrow(playingLens: true, isMe: false) == "Career · vs their playing number")

    // A golfer no season has ever ranked: the new server sends the allowance
    // keys as null. Key presence alone would print a dash over a real number,
    // so the lens is off and the 100% figure keeps its own honest label.
    let leagueless = card(.object(["rounds": .number(2), "best": .number(21.5), "avg_pvi": .null,
                                   "best_pvi": .null, "avg_vs_index": .number(-13.3)]))
    #expect(leagueless.playingLens == false)
    #expect(leagueless.bestText == "21.5" && leagueless.avgText == "-13.3")
  }
  @Test func relation() {
    let pid = UUID(), fid = UUID()
    let rows = [Rpc.my_friends.Row(friendship_id: fid, profile_id: pid, handle: nil, display_name: nil, city: nil, marker: nil, index_current: nil, status: "pending", incoming: true)]
    #expect(BuddyRelation.from(rows, profile: pid) == .incoming(friendshipId: fid))
    #expect(BuddyRelation.from(rows, profile: UUID()) == .none)
    #expect(BuddyRelation.none.actionLabel == "Add buddy" && BuddyRelation.friend.tag == "Buddies" && BuddyRelation.requested.tag == "Requested")
  }
}

@Suite struct LastRoundWithTests {
  @Test func monthsFloorAtTwelveAndNextSaturday() {
    var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "America/Phoenix")!
    let w = LastRoundWith(Rpc.last_round_with.Row(profile_id: UUID(), display_name: "Mike", marker: "saguaro", last_on: "2025-01-10", shared_cards: 4))!
    let now = CSDate.local("2026-08-27", calendar: cal)!
    #expect(w.months(now: now, calendar: cal) == 20)
    #expect(w.months(now: CSDate.local("2025-03-01", calendar: cal)!, calendar: cal) == 12)
    #expect(w.sub == "4 rounds shared · one tap stages a Saturday")
    #expect(LastRoundWith.nextSaturday(from: CSDate.local("2026-08-27", calendar: cal)!, calendar: cal) == "2026-08-29")   // Thu → Sat
    #expect(LastRoundWith.nextSaturday(from: CSDate.local("2026-08-29", calendar: cal)!, calendar: cal) == "2026-09-05")   // Sat → next Sat
  }
}
