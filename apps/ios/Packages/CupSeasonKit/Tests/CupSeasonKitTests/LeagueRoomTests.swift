// Cup Season — the league room's pure logic, pinned to the web client's
// phrasings and arithmetic (index.html line numbers in each suite).

import Testing
import Foundation
@testable import CupSeasonKit

private let a = UUID(), b = UUID(), c = UUID(), d = UUID()
private let m1 = UUID(), m2 = UUID(), m3 = UUID()
private let p1 = UUID(), p2 = UUID(), p3 = UUID()

private func team(_ id: UUID, _ name: String, _ pts: Double, ci: Int = 0) -> Team { Team(id: id, name: name, pts: pts, ci: ci) }

// MARK: `#standingsStory` (4535–4544)

@Suite struct StandingsStoryTests {
  @Test func aGoodWeekendBackWithinFifteen() {
    #expect(StandingsMath.story([team(a, "Squad 1", 30), team(b, "Squad 2", 18)]).text == "Squad 1 lead by 12 · Squad 2 a good weekend back.")
  }
  @Test func pointsBackPastFifteen() {
    #expect(StandingsMath.story([team(a, "Squad 1", 40), team(b, "Squad 2", 20)]).text == "Squad 1 lead by 20 · Squad 2 20 back.")
  }
  @Test func deadHeat() {
    #expect(StandingsMath.story([team(a, "Squad 1", 20), team(b, "Squad 2", 20)]).text == "Dead heat — Squad 1 and Squad 2 level at 20.")
  }
  @Test func quietUntilAPointIsScored() {
    #expect(StandingsMath.story([team(a, "Squad 1", 0), team(b, "Squad 2", 0)]) == .none)
    #expect(StandingsMath.story([team(a, "Squad 1", 0)]) == .none)
    #expect(StandingsMath.story([]) == .none)
  }
  @Test func outFrontAlone() {
    #expect(StandingsMath.story([team(a, "Dan", 9)]).text == "Dan out front — waiting on a challenger.")
  }
}

// MARK: rank movement vs the last snapshot (4523–4563), the series (4243)

@Suite struct RankMoveTests {
  func snap(_ wk: Int, _ rows: [(UUID, Double)]) -> LeagueRoom.Snapshot {
    LeagueRoom.Snapshot(week_no: wk, standings: .object(["squads": .array(rows.map { .object(["squad_id": .string($0.0.uuidString.lowercased()), "points": .number($0.1)]) })]))
  }
  @Test func priorRankReadsTheLatestWeek() {
    let pr = StandingsMath.priorRank(snapshots: [snap(1, [(a, 30), (b, 10)]), snap(2, [(a, 10), (b, 30)])], solo: false)
    #expect(pr[b] == 0 && pr[a] == 1)
  }
  @Test func heatChips() {
    #expect(StandingsMath.move(prior: 3, now: 1) == .up(2))
    #expect(StandingsMath.move(prior: 0, now: 2) == .down(2))
    #expect(StandingsMath.move(prior: 1, now: 1) == .held)
    #expect(StandingsMath.move(prior: nil, now: 0) == nil)
    #expect(RankMove.up(2).label == "▲2" && RankMove.down(1).title == "down 1 this week" && RankMove.held.label == "–")
  }
  @Test func seriesIsSnapshotsThenNow() {
    let teams = [team(a, "A", 30), team(b, "B", 18)]
    let s = StandingsMath.series(teams: teams, snapshots: [snap(1, [(a, 10), (b, 12)]), snap(2, [(a, 20), (b, 15)])], weeks: 18, solo: false)
    #expect(s[a] == [10, 20, 30] && s[b] == [12, 15, 18])
    let none = StandingsMath.series(teams: teams, snapshots: [], weeks: 18, solo: false)
    #expect(none[a] == [30])   // WK 1: no Δ yet
  }
  @Test func squadsSortByPointsKeepingNameOrderOnTies() {
    let squads = [LeagueRoom.Squad(id: a, name: "Squad 1", color: 0), LeagueRoom.Squad(id: b, name: "Squad 2", color: 1), LeagueRoom.Squad(id: c, name: "Squad 3", color: nil)]
    let t = StandingsMath.squadTeams(squads: squads, standings: [LeagueRoom.SquadStanding(squad_id: b, points: 30), LeagueRoom.SquadStanding(squad_id: c, points: 30)], captainName: { _ in "Dan" })
    #expect(t.map(\.id) == [b, c, a] && t[1].ci == 2 && t[2].pts == 0 && t[0].cap == "Dan")
  }
}

// MARK: `indRows` / `myMonth` / `myIndexDelta` (14494–14516) and the trio (11266–11275)

@Suite struct IndRowsTests {
  let members = [LeagueRoom.Member(id: m1, role: "player", profile_id: p1, profile: .init(display_name: "Dan Ryan")),
                 LeagueRoom.Member(id: m2, role: "commissioner", profile_id: p2, profile: .init(display_name: "Joe"))]
  let squads = [LeagueRoom.Squad(id: a, name: "Squad 1", color: 0, squad_members: [.init(member_id: m1)]),
                LeagueRoom.Squad(id: b, name: "Squad 2", color: 1, squad_members: [.init(member_id: m2)])]
  let ranked = [
    LeagueRoom.RankedRound(member_id: m1, round_id: c, pvi: 1.5, points: 9, month_rank: 1, floor_credit: 1, played_on: "2026-06-01", index_at_post: 12.0, holes_played: 18),
    LeagueRoom.RankedRound(member_id: m1, round_id: d, pvi: -2, points: 6, month_rank: 2, floor_credit: 0.5, played_on: "2026-06-10", index_at_post: 11.5, holes_played: 9),
    LeagueRoom.RankedRound(member_id: m2, round_id: nil, pvi: 3, points: 12, month_rank: 1, floor_credit: 1, played_on: "2026-06-05", index_at_post: 8, holes_played: 18),
  ]
  let indiv = [LeagueRoom.IndivStanding(member_id: m1, points: 21, rounds_posted: 2), LeagueRoom.IndivStanding(member_id: m2, points: 21, rounds_posted: 1)]

  var rows: [IndRow] { StandingsMath.indRows(indiv: indiv, ranked: ranked, members: members, squads: squads, myMemberId: m1, capN: 1) }

  @Test func theMathVerbatim() {
    let r = rows
    #expect(r.map(\.mid) == [m2, m1])   // pts tie → avg desc
    let dan = r[1], joe = r[0]
    #expect(abs(dan.avg - (-0.25)) < 1e-9 && dan.best == 1.5 && dan.d == -0.5 && dan.me && dan.sq == "SQUA" && dan.ci == 0 && dan.n == "Dan Ryan")
    #expect(joe.avg == 3 && joe.d == nil && joe.ci == 1 && !joe.me)
    #expect(dan.hist.map(\.played_on) == ["2026-06-10", "2026-06-01"])   // newest first
    #expect(dan.hist.map(\.counting) == [false, true])                     // the second round is BUMPED under Best 1
  }
  @Test func awardsFirstNamesOnly() {
    let aw = StandingsMath.awards(rows)!
    #expect(aw.king == "Joe" && aw.kingSub == "Points King · 21 pts")
    #expect(aw.iron == "Dan" && aw.ironSub == "Iron Man · 2 rds")
    #expect(aw.improved == "Dan" && aw.improvedSub == "Most Improved · ▼0.5")
  }
  @Test func mostImprovedNeedsTwoRounds() {
    let one = StandingsMath.indRows(indiv: [indiv[1]], ranked: [ranked[2]], members: members, squads: squads, myMemberId: nil, capN: 4)
    #expect(StandingsMath.awards(one)?.improvedSub == "Most Improved · needs 2+ rounds")
    #expect(StandingsMath.awards([]) == nil)
  }
  @Test func myMonthAndIndexDelta() {
    let mine = ranked.filter { $0.member_id == m1 }
    #expect(StandingsMath.myMonth(mine: mine, capN: 1, monthKey: "2026-06") == MyMonth(credits: 1.5, counting: 1))
    #expect(StandingsMath.myMonth(mine: mine, capN: 1, monthKey: "2026-07") == MyMonth(credits: 0, counting: 0))
    #expect(abs(StandingsMath.myIndexDelta(mine: mine, profileIndex: 11.2)! - (-0.8)) < 1e-9)
    #expect(StandingsMath.myIndexDelta(mine: [mine[0]], profileIndex: 11.2) == nil)
  }
  @Test func soloTeamsAreThePlayers() {
    let t = StandingsMath.soloTeams(rows, marker: { _ in "island" })
    #expect(t.first?.solo == true && t.first?.sub == 1 && t.first?.mk == "island")
  }
}

// MARK: the pot (6973–7050) and the settlement (11471–11508)

@Suite struct PennySplitTests {
  @Test func remainderRidesTheEarliestSeats() {
    #expect(PotMath.splitCents(1000, 3) == [334, 333, 333])
    #expect(PotMath.splitCents(100, 4) == [25, 25, 25, 25])
    #expect(PotMath.splitCents(5, 0) == [])
  }
  @Test func championAbsorbsTheRounding() {
    let s = PotMath.settlementCents(pot: 52500, payout: [60, 25, 15])
    #expect(s.runner == 13125 && s.king == 7875 && s.champ == 31500)
    let odd = PotMath.settlementCents(pot: 101, payout: [60, 25, 15])
    #expect(odd.champ + odd.runner + odd.king == 101)
  }
  @Test func thePotPaneTrioInDollars() {
    let t = PotMath.trioDollars(total: 525, payout: [60, 25, 15])
    #expect(t.champ == 315 && t.runner == 131 && t.king == 79)
    #expect(PotMath.money(7550) == "$75.50" && PotMath.money(18000) == "$180")
  }

  let members = [LeagueRoom.Member(id: m1, role: "player", profile_id: p1, profile: .init(display_name: "Dan")),
                 LeagueRoom.Member(id: m2, role: "player", profile_id: p2, profile: .init(display_name: "Joe")),
                 LeagueRoom.Member(id: m3, role: "commissioner", profile_id: p3, profile: .init(display_name: "Al"))]
  let squads = [LeagueRoom.Squad(id: a, name: "Squad 1", color: 0, squad_members: [.init(member_id: m1), .init(member_id: m2)]),
                LeagueRoom.Squad(id: b, name: "Squad 2", color: 1, squad_members: [.init(member_id: m3)])]
  let season = LeagueRoom.Season(id: c, starts_on: "2026-05-03", ends_on: "2026-09-26", status: "complete", champion_squad_id: a, runnerup_squad_id: b,
                                 points_king_member_id: m1, champion_score: 112, runnerup_score: 98.5, tiebreak_rung: nil)

  @Test func ledgerRowsAreSummedPerPerson() {
    let payouts = [LeagueRoom.Payout(profile_id: p1, cents: 15750, reason: "Cup champion"), LeagueRoom.Payout(profile_id: p2, cents: 15750, reason: "Cup champion"),
                   LeagueRoom.Payout(profile_id: p1, cents: 7875, reason: "Points king"), LeagueRoom.Payout(profile_id: p3, cents: 13125, reason: "Runner-up")]
    let st = PotMath.settlement(season: season, members: members, squads: squads, solo: false, stakeDollars: 175, payout: [60, 25, 15], payouts: payouts, myProfileId: p1)
    #expect(st.fromLedger && st.potCents == 52500 && st.unclaimedCents == 0)
    #expect(st.rows.map(\.name) == ["Dan", "Joe", "Al"])
    #expect(st.rows[0].cents == 23625 && st.rows[0].why == ["Cup champion", "Points king"])
    #expect(st.mine?.cents == 23625 && st.champName == "Squad 1" && st.runName == "Squad 2" && st.kingName == "Dan")
  }
  @Test func thePreviewMathMatchesTheServer() {
    let st = PotMath.settlement(season: season, members: members, squads: squads, solo: false, stakeDollars: 175, payout: [60, 25, 15], payouts: [], myProfileId: p3)
    #expect(!st.fromLedger)
    #expect(st.rows.map(\.cents) == [23625, 15750, 13125] && st.mine?.name == "Al" && st.mine?.why == ["Runner-up"])
    #expect(PotMath.score(112) == "112" && PotMath.score(98.5) == "98.5")
  }
  @Test func theCeremonyPaysFromWhatWasCollected() {
    // D106: two unpaid on a $175 × 3 roster — the server split $350 (not $525) and stamped both numbers
    let short = LeagueRoom.Season(id: c, starts_on: "2026-05-03", ends_on: "2026-09-26", status: "complete", champion_squad_id: a, runnerup_squad_id: b,
                                  points_king_member_id: m1, champion_score: 112, runnerup_score: 98.5, pot_cents: 52500, collected_cents: 35000)
    let payouts = [LeagueRoom.Payout(profile_id: p1, cents: 10500, reason: "Cup champion"), LeagueRoom.Payout(profile_id: p2, cents: 10500, reason: "Cup champion"),
                   LeagueRoom.Payout(profile_id: p1, cents: 5250, reason: "Points king"), LeagueRoom.Payout(profile_id: p3, cents: 8750, reason: "Runner-up")]
    let st = PotMath.settlement(season: short, members: members, squads: squads, solo: false, stakeDollars: 175, payout: [60, 25, 15], payouts: payouts, myProfileId: p1, owing: ["Joe", "Al"])
    #expect(st.fromLedger && st.potCents == 52500 && st.collectedCents == 35000 && st.stillOwedCents == 17500)
    #expect(st.unclaimedCents == 0 && st.owing == ["Joe", "Al"] && st.mine?.cents == 15750)
    // all paid: the two numbers collapse and nobody is named
    let full = LeagueRoom.Season(id: c, starts_on: "2026-05-03", ends_on: "2026-09-26", status: "complete", champion_squad_id: a, runnerup_squad_id: b,
                                 points_king_member_id: m1, pot_cents: 52500, collected_cents: 52500)
    let st2 = PotMath.settlement(season: full, members: members, squads: squads, solo: false, stakeDollars: 175, payout: [60, 25, 15], payouts: payouts, myProfileId: nil, owing: ["Joe"])
    #expect(st2.stillOwedCents == 0 && st2.owing.isEmpty)
  }
  @Test func anEmptySquadLeavesAnUnclaimedShare() {
    let s2 = LeagueRoom.Season(id: c, starts_on: "2026-05-03", ends_on: "2026-09-26", status: "complete", champion_squad_id: a, runnerup_squad_id: d, points_king_member_id: nil)
    let st = PotMath.settlement(season: s2, members: members, squads: squads, solo: false, stakeDollars: 175, payout: [60, 25, 15], payouts: [], myProfileId: nil)
    #expect(st.unclaimedCents == 13125 + 7875 && st.runName == "" && st.mine == nil)
  }
}

// MARK: the climb (4273–4475)

@Suite struct ClimbTests {
  let teams: [Team] = [80, 70, 60, 50, 40, 30, 20, 10].enumerated().map { i, p in Team(id: [a, b, c, d, m1, m2, m3, p1][i], name: "S\(i + 1)", pts: Double(p), ci: i % 4) }

  @Test func theWindowAroundYouAndTheCut() {
    let items = ClimbMath.items(teams: teams, meId: m2, scenarios: nil)   // me = index 5
    #expect(items.map(\.id) == [a.uuidString, b.uuidString, "cut", c.uuidString, "e2", m1.uuidString, m2.uuidString, m3.uuidString, "etail"])
    if case .cut(let label) = items[2] { #expect(label == "CUT LINE · 40 BACK") } else { Issue.record("no cut") }
    if case .ellipsis(_, let hid) = items[4] { #expect(hid == 1) } else { Issue.record("no ellipsis") }
    if case .rung(let r) = items[0] { #expect(r.isLead && r.gap == "+50" && r.voice == nil) } else { Issue.record("no leader") }
    if case .rung(let r) = items[5] { #expect(r.voice == .aheadOfYou(10, stake: nil)) } else { Issue.record("no rung above") }
    if case .rung(let r) = items[6] { #expect(r.isMe && r.accessibility == "You — 6th, 30 points") } else { Issue.record("no me") }
    if case .rung(let r) = items[7] { #expect(r.voice == .behindYou("S7", 10)) } else { Issue.record("no rung below") }
    #expect(ClimbMath.note(teams: teams, scenarios: nil) == "TOP 2 ADVANCE TO THE CUP FINAL")
  }
  @Test func aLeaderSeesClearAndTheStake() {
    let items = ClimbMath.items(teams: teams, meId: a, scenarios: nil)
    if case .cut(let label) = items.first(where: { if case .cut = $0 { return true }; return false })! { #expect(label == "CUT LINE · 20 CLEAR") }
    let on = ClimbMath.items(teams: teams, meId: c, scenarios: nil)   // 3rd, one below the line
    if case .rung(let r) = on.first(where: { if case .rung(let r) = $0 { return r.index == 1 }; return false })! {
      #expect(r.voice == .aheadOfYou(10, stake: "the top seed"))
    }
  }
  @Test func spectatorsSeeBehindTheLeader() {
    let items = ClimbMath.items(teams: Array(teams.prefix(3)), meId: nil, scenarios: nil)
    if case .cut(let label) = items[2] { #expect(label == "CUT LINE") } else { Issue.record("no cut") }
    if case .rung(let r) = items[3] { #expect(r.gap == "-20" && r.accessibility == "3rd — S3, 60 points, 20 behind the leader") } else { Issue.record("no rung") }
  }
  @Test func theCutFollowsTheDial() {
    let pt = SeasonScenarios.Meta(finish: "points_table", structure: "squads4", level: "squad", k: 2, months_left: 2, locked: false, cap: 4)
    #expect(ClimbMath.cut(pt) == ClimbCut(K: 1, line: "CROWN LINE"))
    let two = SeasonScenarios.Meta(finish: "cup_final", structure: "squads2", level: "squad", k: 2, months_left: 2, locked: false, cap: 4)
    #expect(ClimbMath.cut(two) == ClimbCut(K: 1, line: "TOP SEED · +10"))
    #expect(ClimbMath.cut(nil) == ClimbCut(K: 2, line: "CUT LINE"))
    let sc = SeasonScenarios(meta: pt, rows: [])
    #expect(ClimbMath.note(teams: teams, scenarios: sc) == "TOP 1 — THE POINTS CROWN")
    #expect(ClimbMath.note(teams: [teams[0]], scenarios: nil) == "NOBODY TO RACE YET")
    #expect(ClimbMath.items(teams: [], meId: nil, scenarios: nil).isEmpty)
  }
  @Test func badgesComeFromTheServer() {
    let meta = SeasonScenarios.Meta(finish: "cup_final", structure: "squads4", level: "squad", k: 2, months_left: 1, locked: false, cap: 4)
    let sc = SeasonScenarios(meta: meta, rows: [.init(id: a, name: "S1", points: 80, max_final: 120, clinched: true, eliminated: false, needs: 0),
                                                .init(id: p1, name: "S8", points: 10, max_final: 50, clinched: false, eliminated: true, needs: 70)])
    let items = ClimbMath.items(teams: teams, meId: p1, scenarios: sc)   // me = S8, last
    // D126/D136: a clinched seat reads IN, not LOCKED (testers read the old word as locked OUT).
    if case .rung(let r) = items[0] { #expect(r.badge == "IN" && r.accessibility.hasSuffix(", clinched")) }
    if case .rung(let r) = items.last(where: { if case .rung = $0 { return true }; return false })! { #expect(r.badge == "OUT") }
  }
}

// MARK: the scenario line (14557–14600, D24)

@Suite struct ScenarioLineTests {
  func meta(finish: String = "cup_final", structure: String = "squads4", cap: Int = 4, locked: Bool = false, monthsLeft: Int = 2) -> SeasonScenarios.Meta {
    .init(finish: finish, structure: structure, level: "squad", k: 2, months_left: monthsLeft, locked: locked, cap: cap)
  }
  func row(_ id: UUID, _ n: String, pts: Double, max: Double, clinched: Bool = false, out: Bool = false, needs: Double = 0) -> SeasonScenarios.Row {
    .init(id: id, name: n, points: pts, max_final: max, clinched: clinched, eliminated: out, needs: needs)
  }
  @Test func seedsLockedOnceTheFinalRuns() {
    let sc = SeasonScenarios(meta: meta(locked: true), rows: [row(a, "Squad 1", pts: 90, max: 90), row(b, "Squad 2", pts: 70, max: 70), row(c, "Squad 3", pts: 10, max: 10)])
    #expect(ScenarioLine.parts(sc) == [.clinch("SEEDS LOCKED"), .text(" — SQUAD 1 · SQUAD 2 INTO THE CUP FINAL")])
  }
  @Test func aMagicNumberOnlyWhenReachable() {
    let sc = SeasonScenarios(meta: meta(), rows: [row(a, "Squad 1", pts: 100, max: 160, needs: 20), row(d, "Squad 4", pts: 5, max: 30, out: true)])
    #expect(ScenarioLine.parts(sc) == [.bold("SQUAD 1"), .text(" · 20 MORE LOCKS A CUP SEED"), .text(" · "), .out("SQUAD 4 OUT OF THE SEED RACE")])
    let far = SeasonScenarios(meta: meta(), rows: [row(a, "Squad 1", pts: 100, max: 110, needs: 20)])
    #expect(ScenarioLine.parts(far).isEmpty)
  }
  @Test func neverInventsUnderAnUnlimitedCap() {
    let sc = SeasonScenarios(meta: meta(cap: 999), rows: [row(a, "Squad 1", pts: 100, max: 9999, needs: 20)])
    #expect(ScenarioLine.parts(sc).isEmpty)
  }
  @Test func theCrownAndTheRace() {
    let sc = SeasonScenarios(meta: meta(finish: "points_table"), rows: [row(a, "Dan", pts: 100, max: 160, clinched: true), row(b, "Joe", pts: 1, max: 20, out: true)])
    #expect(ScenarioLine.parts(sc) == [.bold("DAN"), .text(" HAS LOCKED THE CROWN"), .text(" · "), .out("JOE OUT OF THE RACE")])
    let two = SeasonScenarios(meta: meta(structure: "squads2"), rows: [row(a, "Squad 1", pts: 100, max: 160, clinched: true)])
    #expect(ScenarioLine.parts(two) == [.bold("SQUAD 1"), .text(" HAS LOCKED THE TOP SEED · +10")])
  }
  @Test func quietAfterTheWindowAndWithoutRows() {
    #expect(ScenarioLine.parts(SeasonScenarios(meta: meta(monthsLeft: 0), rows: [row(a, "S", pts: 1, max: 2)])).isEmpty)
    #expect(ScenarioLine.parts(nil).isEmpty)
    let decoded = SeasonScenarios.decode(.object(["meta": .object(["finish": .string("cup_final"), "k": .number(2)]), "rows": .array([])]))
    #expect(decoded?.meta.k == 2)
    #expect(SeasonScenarios.decode(.null) == nil)
  }
}

// MARK: the copy (renderBylaws 11889, renderStats 9406, renderPhase 11985)

@Suite struct LeagueCopyTests {
  let season = LeagueRoom.Settings(league_id: a, preset: "standard", counting_cap: 4, participation_floor: 2, buyin_cents: 7500, structure: "squads4",
                                   draft_type: "random", payout_champ: 60, payout_runnerup: 25, payout_king: 15, finish: "cup_final")
  func clock(_ today: String, status: String = "active", phase: RoomPhase = .season, finish: String = "cup_final") -> RoomClock {
    RoomClock(phase: phase, startsOn: "2026-05-03", endsOn: "2026-09-26", status: status, finish: finish, today: today)
  }

  @Test func applyBylaws() {
    let b = Bylaws.from(season)
    #expect(b.stake == 75 && b.capIdx == 1 && b.capN == 4 && b.presetIdx == 1 && b.floor == 2 && b.payout == [60, 25, 15] && b.draftType == "random")
    #expect(Bylaws.from(LeagueRoom.Settings(league_id: a, preset: "cutthroat", counting_cap: nil, draft_type: "snake")).capIdx == 3)
    #expect(Bylaws.from(LeagueRoom.Settings(league_id: a, preset: "custom", counting_cap: 2)).presetIdx == 1)
    #expect(Bylaws.from(nil).capN == 4)
  }
  @Test func bylawsRowsVerbatim() {
    let rows = LeagueCopy.bylawsRows(Bylaws.from(season), clock: clock("2026-06-01"))
    #expect(rows.map(\.k) == ["STRUCTURE", "Squad formation", "PRESET", "HANDICAP ALLOWANCE", "VERIFICATION", "COUNTING CAP", "PARTICIPATION FLOOR", "BUY-IN", "POT SPLIT", "SEASON", "CUP FINAL"])
    #expect(rows[0].v == "4 squads" && rows[1].v == "Blind draw" && rows[3].v == "95%" && rows[5].v == "Best 4 / mo" && rows[6].v == "2 / mo · −5 sqd pts / round short")
    #expect(rows[7].v == "$75 / player" && rows[8].v == "60 / 25 / 15 · champ / 2nd / king")
    #expect(rows[9].v == "5 mo · Sun May 3 → Sat Sep 26 · 21 wks")
    #expect(rows[10].v == "Final 4 weeks · from Sun Aug 30 · scored fresh")
    let free = LeagueCopy.bylawsRows(Bylaws(stake: 0, finish: "points_table"), clock: clock("2026-06-01", finish: "points_table"))
    #expect(free.first { $0.k == "BUY-IN" }?.v == "None · bragging rights" && free.last?.k == "FINISH" && free.last?.v == "Points table crowns it · whole season, one race")
    #expect(!free.contains { $0.k == "POT SPLIT" })
  }
  @Test func theSeasonTileDeadlines() {
    let b = Bylaws.from(season)
    #expect(LeagueCopy.deadline(clock("2026-06-04"), b: b) == .init(text: "Week closes Sun · 3d", gold: false))
    #expect(LeagueCopy.deadline(clock("2026-06-07"), b: b) == .init(text: "Week closes tonight", gold: false))
    #expect(LeagueCopy.deadline(clock("2026-06-30"), b: b) == .init(text: "Month closes Jul 1 · floors assessed", gold: false))
    #expect(LeagueCopy.deadline(clock("2026-08-27"), b: b) == .init(text: "Cup Final · Sun Aug 30 · 3d", gold: true))
    #expect(LeagueCopy.deadline(clock("2026-08-30"), b: b) == .init(text: "Cup Final · Sun Aug 30 · 0d", gold: true))
    #expect(LeagueCopy.deadline(clock("2026-08-28"), b: b) == .init(text: "Cup Final · Sun Aug 30 · 2d", gold: true))   // ties go to the Final
    #expect(LeagueCopy.deadline(clock("2026-09-24"), b: b) == .init(text: "Week closes Sun · 3d", gold: false))          // the window has opened; no Final line
    #expect(LeagueCopy.deadline(clock("2026-08-28", finish: "points_table"), b: Bylaws(finish: "points_table")) == .init(text: "Week closes Sun · 2d", gold: false))
    #expect(LeagueCopy.deadline(clock("2026-09-25", finish: "points_table"), b: Bylaws(finish: "points_table")) == .init(text: "Points table crowns it · ends Sep 26 · 1d", gold: true))
    #expect(LeagueCopy.deadline(clock("2026-09-01", status: "cup_final"), b: b) == .init(text: "CUP FINAL LIVE · 25 days left", gold: true))
    #expect(LeagueCopy.deadline(clock("2026-10-01", status: "complete"), b: b) == .init(text: "Season complete · settled", gold: true))
    #expect(LeagueCopy.deadline(clock("2026-04-30"), b: b) == .init(text: "First tee Sun May 3", gold: true))
    #expect(LeagueCopy.weekValue(clock("2026-04-30")) == "—" && LeagueCopy.weekValue(clock("2026-05-10")) == "W2" && LeagueCopy.weekValue(clock("2026-10-01", status: "complete")) == "21")
  }
  @Test func thePhaseStrings() {
    // D120: one stage vocabulary; "Setup — invites open" also contradicted D112.
    #expect(LeagueCopy.phaseHeader(clock("2026-06-01", phase: .setup)) == "Forming")
    #expect(LeagueCopy.phaseHeader(clock("2026-06-01", phase: .draft)) == "Squads drawing")
    #expect(LeagueCopy.phaseHeader(clock("2026-04-30")) == "Before first tee — Sun May 3")
    #expect(LeagueCopy.phaseHeader(clock("2026-09-01", status: "cup_final")) == "Cup Final")
    #expect(LeagueCopy.phaseHeader(clock("2026-10-01", status: "complete")) == "Season complete")
    #expect(LeagueCopy.phaseHeader(clock("2026-06-01")) == "Season live")
    let b = Bylaws.from(season)
    #expect(LeagueCopy.phaseSub(clock("2026-05-10"), b: b, code: "PIGL", members: 8) == "Wk 2 / 21 · Points Race · Standard rules")
    #expect(LeagueCopy.phaseSub(clock("2026-04-30"), b: b, code: "PIGL", members: 8) == "BEFORE FIRST TEE · SUN MAY 3 · 3 DAYS")
    #expect(LeagueCopy.phaseSub(clock("2026-05-10", phase: .setup), b: b, code: "PIGL", members: 8) == "SETUP · LOCK THE BYLAWS TO OPEN INVITES")
    #expect(LeagueCopy.kickoff(clock("2026-05-02")) == ("First tee Sun May 3", "KICKS OFF IN 1 DAY · SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON"))
    #expect(LeagueCopy.seatFill(code: "PIGL", members: 5, min: 8) == "CODE PIGL · 5 OF 8 IN — 3 SEATS OPEN")
    #expect(LeagueCopy.draftPoolSub(pool: 2, members: 8, min: 8) == "2 PLAYERS IN THE POOL")
    #expect(LeagueCopy.danger(clock("2026-06-01")).link == "Cancel this league" && LeagueCopy.danger(clock("2026-04-30")).preTee)
  }
  @Test func nextUpAndTheMeter() {
    let b = Bylaws.from(season)
    #expect(LeagueCopy.nextUp(clock("2026-04-30"), b: b, credits: 0, partial: false) == ("Next up · kickoff", "First tee Sun May 3. Practice rounds hit your card, not the season."))
    #expect(LeagueCopy.nextUp(clock("2026-08-27"), b: b, credits: 1, partial: false).text == "Post 1 more round this month — best 4 count, you've posted 1.")
    #expect(LeagueCopy.nextUp(clock("2026-08-27"), b: b, credits: 0.5, partial: false).text == "Post 1.5 more rounds this month — best 4 count, you've posted 0.5.")
    #expect(LeagueCopy.nextUp(clock("2026-08-27"), b: b, credits: 2, partial: false).text == "August is covered — 2 rounds counting. A better one always replaces your lowest.")
    #expect(LeagueCopy.nextUp(clock("2026-08-27"), b: b, credits: 0, partial: true) == ("Next up · August", "August is a short month — no floor to clear. Every round still counts."))
    let pm = LeagueCopy.pressMeter(today: "2026-08-27")
    #expect(pm.legend == "5 days left in August" && pm.hot && abs(pm.fill - 26.0 / 31.0) < 1e-9)
    #expect(LeagueCopy.indexSub(established: false, delta: -1) == "Building your number")
    #expect(LeagueCopy.indexSub(established: true, delta: -0.3) == "▼ 0.3 this season" && LeagueCopy.indexSub(established: true, delta: 0.01) == "Season to date")
    #expect(LeagueCopy.countingSub(month: "August", capN: Int.max) == "August · every round counts")
    #expect(LeagueCopy.lineSplit(total: 525, payout: [60, 25, 15]) == "CHAMPS $315 · RUNNER-UP $131 · POINTS KING $79")
    #expect(LeagueCopy.finishDial(current: "cup_final").label == "Finish: Cup Final — switch to points table")
  }
}

@Suite struct LeagueDatesTests {
  @Test func weeksAndTheFinalWindow() {
    #expect(LeagueDates.totalWeeks(start: "2026-05-03", end: "2026-09-26") == 21)
    #expect(LeagueDates.currentWeek(start: "2026-05-03", end: "2026-09-26", today: "2026-05-10") == 2)
    #expect(LeagueDates.currentWeek(start: "2026-05-03", end: "2026-09-26", today: "2027-01-01") == 21)
    #expect(LeagueDates.cupFinalStart(end: "2026-09-26") == "2026-08-30")
    #expect(LeagueDates.spanText(start: "2026-05-03", end: "2026-09-26") == "Sun May 3 → Sat Sep 26 · 21 wks")
    #expect(LeagueDates.durLabel(6) == "6 wk" && LeagueDates.durLabel(26) == "6 mo")
    #expect(LeagueDates.nextSunday("2026-08-27") == "2026-08-30" && LeagueDates.nextSunday("2026-08-30") == "2026-08-30")
    #expect(LeagueDates.firstOfNextMonth("2026-12-05") == "2027-01-01" && LeagueDates.firstOfMonth("2026-08-27") == "2026-08-01")
    #expect(LeagueDates.monthLong("2026-08-27") == "August" && LeagueDates.daysInMonth("2026-02-10") == 28)
  }
}

// MARK: the model, seeded

@Suite @MainActor struct LeagueRoomModelTests {
  @Test func aSeededRoomDerivesLikeALoad() {
    let model = LeagueRoomModel(leagueId: a)
    let members = [LeagueRoom.Member(id: m1, role: "player", profile_id: p1, profile: .init(display_name: "Dan")),
                   LeagueRoom.Member(id: m2, role: "commissioner", profile_id: p2, profile: .init(display_name: "Joe"))]
    let squads = [LeagueRoom.Squad(id: b, name: "Squad 1", color: 0, captain_member_id: m1, squad_members: [.init(member_id: m1)]),
                  LeagueRoom.Squad(id: c, name: "Squad 2", color: 1, captain_member_id: m2, squad_members: [.init(member_id: m2)])]
    model.seed(viewer: RoomViewer(id: p1, displayName: "Dan", marker: "saguaro", indexCurrent: 12.4, roundsCount: 5),
               league: .init(id: a, name: "PIGL", code: "PIGL", phase: "season", commissioner_id: p2),
               settings: .init(league_id: a, preset: "standard", counting_cap: 4, participation_floor: 2, buyin_cents: 7500, structure: "squads2", finish: "cup_final"),
               season: .init(id: d, starts_on: "2026-05-03", ends_on: "2026-09-26", status: "active"),
               members: members, squads: squads,
               squadStandings: [.init(squad_id: b, points: 18), .init(squad_id: c, points: 30)],
               indiv: [.init(member_id: m1, points: 18, rounds_posted: 2), .init(member_id: m2, points: 30, rounds_posted: 3)],
               buyIns: [.init(member_id: m2, paid: true, amount_cents: 7500)], today: "2026-06-01")
    #expect(model.loaded && model.freshStandings && !model.isPro && model.myTeamId == b)
    #expect(model.teams.map(\.id) == [c, b] && model.teams[0].cap == "Joe")
    #expect(model.story.text == "Squad 2 lead by 12 · Squad 1 a good weekend back.")
    #expect(model.potTotal == 150 && model.paidCount == 1 && model.collectedDollars == 75 && model.proName == "Joe")
    #expect(model.clock.currentWeek == 5 && model.clock.totalWeeks == 21 && !model.clock.atStarter)
    #expect(model.inviteURL?.absoluteString == "https://cupseason.app/?join=PIGL" && model.inviteText == "You're invited to PIGL on Cup Season")
    #expect(LeagueRoomModel.ceremonyKey(d) == "cs_cer_\(d.uuidString.lowercased())")
  }
}


// MARK: D105 · cup_final_race (migration 20260828170100)

@Suite struct CupFinalRaceTests {
  static let squadA = UUID(), squadB = UUID()
  static let json = """
  {"status":"live","season_status":"cup_final","solo":false,"window_start":"2026-08-09","window_end":"2026-09-05",
   "cap_n":10000,"days_left":8,"seed_rung":"months won",
   "finalists":[
     {"seed":1,"head_start":10,"seed_rung":null,"squad_id":"\(squadA.uuidString.lowercased())","member_id":null,"name":"Coyotes","color":0,
      "window_points":21,"rounds_used":3,"last_round_on":"2026-08-27","total":31,
      "rounds":[{"round_id":"\(UUID().uuidString.lowercased())","played_on":"2026-08-27","points":8,"month_rank":1,"pvi":1.2,"holes_played":18,"member_id":null,"golfer":"Galen"}]},
     {"seed":2,"head_start":0,"seed_rung":"months won","squad_id":"\(squadB.uuidString.lowercased())","member_id":null,"name":"Scorpions","color":1,
      "window_points":41,"rounds_used":7,"last_round_on":"2026-08-28","total":41,"rounds":[]}
   ]}
  """
  @Test func decodesTheServerShape() throws {
    let v = try JSONDecoder().decode(JSONValue.self, from: Data(Self.json.utf8))
    let race = try #require(CupFinalRace.decode(v))
    #expect(race.isLive)
    #expect(race.days_left == 8)
    #expect(race.seed_rung == "months won")
    #expect(race.finalists.map(\.seed) == [1, 2])
    #expect(race.finalists[0].total == 31 && race.finalists[0].head_start == 10)
    #expect(race.finalists[0].rounds.first?.golfer == "Galen")
  }
  @Test func raceOrderIsTheLeaderFirstNotTheSeed() throws {
    let v = try JSONDecoder().decode(JSONValue.self, from: Data(Self.json.utf8))
    let race = try #require(CupFinalRace.decode(v))
    #expect(race.race.map(\.seed) == [2, 1])          // the 2-seed leads the Final
    #expect(race.seed(for: Self.squadB) == 2 && race.seed(for: Self.squadA) == 1)
    #expect(race.seed(for: UUID()) == nil)
  }
  @Test func pendingIsNotARace() throws {
    let v = try JSONDecoder().decode(JSONValue.self, from: Data(#"{"status":"pending","finalists":[],"seed_rung":null}"#.utf8))
    let race = try #require(CupFinalRace.decode(v))
    #expect(!race.isLive && race.finalists.isEmpty)
  }
}
