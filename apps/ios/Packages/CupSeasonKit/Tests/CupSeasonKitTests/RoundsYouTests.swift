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
    #expect(rows[1] == .math(label: "86 − 64.9 × 113 ⁄ 111", value: "21.5 DIFFERENTIAL", sub: true))
    #expect(rows[2] == .math(label: "Your number that day", value: "10.0", sub: true))
    #expect(rows[3] == .math(label: "Against your number", value: "-11.5 — POSTED ANYWAY", sub: false))
    #expect(rows[4] == .math(label: "Points", value: "5", sub: false))
    #expect(rows[5] == .math(label: "This month", value: "COUNTING #3", sub: false))
    #expect(rows.count == 6)
  }

  @Test func nineHolesUseTheNineRatingAndSayHalfValue() {
    var r = biltmore
    r.holesPlayed = 9; r.nineRating = 32.1; r.gross = 42; r.differential = 10.1
    let rows = ReceiptRows.build(r, capN: nil, viewerId: nil)
    #expect(rows.contains(.math(label: "42 − 32.1 × 113 ⁄ 111", value: "10.1 DIFFERENTIAL", sub: true)))
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
    #expect(RoundCopy.bandName(-1.0) == "Played to it")
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
  @Test func theMinusOneSeamIsDocumentedNotHidden() {
    // the client preview says 7 at exactly −1.0; the server's cup_points() says 6 (p_pvi > −1 → 7)
    #expect(RoundCopy.pointsFor(-1.0).points == 7)
    #expect(RoundCopy.pointsFor(-1.01).points == 6)
    #expect(RoundCopy.pointsFor(3).points == 12 && RoundCopy.pointsFor(1).points == 9 && RoundCopy.pointsFor(-4).points == 5)
    #expect(RoundCopy.signed(1.25) == "+1.2" || RoundCopy.signed(1.25) == "+1.3")
    #expect(RoundCopy.signed(-0.4) == "-0.4")
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
}

@Suite struct CareerTests {
  func row(_ d: Double?, _ i: Double?, gross: Int = 85) -> RoundRow {
    RoundRow(id: UUID(), gross: gross, differential: d, index_at_post: i, played_on: "2026-06-01", course_label: "Papago GC", holes_played: 18)
  }

  @Test func tilesMirrorLoadCareerWithIOS016sBest() {
    let rows = [row(9.1, 12.4), row(11.2, 12.4), row(7.8, 12.4), row(14.6, 12.4), row(10.3, 12.4), row(nil, nil)]
    let c = Career.compute(rows: rows, memberships: 2, events: 1)
    #expect(c.rounds == 6)
    #expect(c.bestDifferential == 7.8)                    // IOS-016: the lowest differential
    #expect(c.bestText == "7.8")
    // mean pvi over the five that have both pieces: (3.3 + 1.2 + 4.6 − 2.2 + 2.1) / 5 = 1.8
    #expect(abs((c.avgVsIndex ?? 0) - 1.8) < 0.0001)
    #expect(c.avgText == "+1.8")
    #expect(c.played == 3)
    #expect(c.recent.count == 5)
    #expect(c.recent.map(\.beat) == [true, true, true, false, true])
  }

  @Test func emptyCard() {
    let c = Career.compute(rows: [], memberships: 0, events: 0)
    #expect(c.bestText == "—" && c.avgText == "—" && c.roundsText == "0")
  }

  @Test func nOfThree() {
    #expect(Career.establishing(rounds: 0) == "0 of 3")
    #expect(Career.establishing(rounds: 2) == "2 of 3")
    #expect(Career.establishing(rounds: 7) == "3 of 3")
  }
}

@Suite struct DisplayCaseTests {
  @Test func tilesAndTheirSubtitles() {
    let t = Rpc.my_trophies.Row(id: nil, kind: "ryder", title: "The Grudge", subtitle: "The Ryder", placement: "winner", season_year: 2026, earned_on: nil)
    let a = Rpc.my_achievements.Row(kind: "sub_80", label: "Broke 80", earned_on: "2026-06-14", meta: .object(["gross": .number(79)]))
    let pb = Rpc.my_achievements.Row(kind: "personal_best", label: nil, earned_on: "2026-06-14", meta: .object(["diff": .number(7.8)]))
    let tiles = TrophyCase.tiles(trophies: [t], achievements: [a, pb])
    #expect(tiles[0].icon == "⚔️" && tiles[0].title == "The Grudge" && tiles[0].sub == "The Ryder · '26")
    #expect(tiles[1].icon == "🔥" && tiles[1].title == "Broke 80" && tiles[1].sub == "79 gross · '26")
    #expect(tiles[2].icon == "📉" && tiles[2].title == "Personal best" && tiles[2].sub == "Diff 7.8 · '26")
    #expect(TrophyMeta.trophyIcon("bracket") == "🥊" && TrophyMeta.trophyIcon("league") == "🏆")
    #expect(TrophyMeta.meta(kind: "mystery", label: nil).title == "Milestone")
  }
  @Test func credentialLines() {
    let ach = (1...5).map { Rpc.my_achievements.Row(kind: "sub_90", label: nil, earned_on: "2026-0\($0)-01", meta: nil) }
    let lines = TrophyMeta.credLines(ach, max: 3, moreSuffix: " more in the case")
    #expect(lines.count == 4 && lines[0] == "🎯 Broke 90 · '26" && lines[3] == "+2 more in the case")
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
    #expect(LeagueRecord.line(phase: "setup", season: nil, standings: [], myMemberId: me) == "Forming — invites open")
    #expect(LeagueRecord.line(phase: "draft", season: season, standings: st, myMemberId: me) == "Squad formation")
    #expect(LeagueRecord.line(phase: "season", season: season, standings: st, myMemberId: me, today: "2026-06-01") == "2ND OF 2 · 41 PTS")
    var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "America/Phoenix")!
    // 2026-05-03 is a Sunday; the label derives it rather than assuming it
    #expect(LeagueRecord.line(phase: "season", season: season, standings: st, myMemberId: me, today: "2026-04-20", calendar: cal) == "FIRST TEE SUN MAY 3")
    let cup = Me.Season(id: sid, number: 2, starts_on: "2026-05-03", ends_on: "2026-09-26", status: "cup_final", timezone: nil, grace_hours: nil,
                        champion_squad_id: nil, champion_member_id: nil, points_king_member_id: nil, tiebreak_rung: nil)
    #expect(LeagueRecord.line(phase: "season", season: cup, standings: st, myMemberId: me, today: "2026-09-01") == "CUP FINAL · 2ND OF 2 · 41 PTS")
    #expect(LeagueRecord.line(phase: "complete", season: season, standings: st, myMemberId: UUID(), today: "2026-10-01") == "FINISHED —")
    #expect(LeagueRecordRow(id: UUID(), name: "PIGL", number: 2, line: "3RD OF 12 · 41 PTS").sub == "SEASON II · 3RD OF 12 · 41 PTS")
    #expect(LeagueRecord.ordUpper(1) == "1ST" && LeagueRecord.ordUpper(11) == "11TH" && LeagueRecord.ordUpper(21) == "21ST" && LeagueRecord.ordUpper(3) == "3RD")
  }

  @Test func seasonStrip() {
    let me = UUID(), sid = UUID()
    let rows = [RankedRound(member_id: me, pvi: 1.4, points: 9, month_rank: 1, floor_credit: 1, played_on: "2026-05-10", index_at_post: 12.4, holes_played: 18),
                RankedRound(member_id: me, pvi: -0.6, points: 7, month_rank: 2, floor_credit: 1, played_on: "2026-05-17", index_at_post: 12.1, holes_played: 18),
                RankedRound(member_id: UUID(), pvi: 4, points: 12, month_rank: 1, floor_credit: 1, played_on: "2026-05-17", index_at_post: 8, holes_played: 18)]
    let s = SeasonStats.compute(rows: rows, standings: [IndividualStanding(season_id: sid, member_id: me, points: 16, rounds_posted: 2)], myMemberId: me)
    #expect(s.roundsText == "2" && s.avgText == "+0.4" && s.bestText == "+1.4" && s.deltaText == "▼ 0.3")
    #expect(SeasonStats.empty.avgText == "—" && SeasonStats.empty.deltaText == "—")
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
