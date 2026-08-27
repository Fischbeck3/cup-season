// Cup Season — the tee-sheet engines against the web's vectors
// (tests/sunningdale.test.mjs ported verbatim; match / round robin / wolf /
// skins written in the same style, which the web never had), the envelope
// shapes (audit 04 §5), the strokes ladder, settlement transfers, the copy,
// and the LWW / queue semantics of D85.

import Testing
import Foundation
@testable import CupSeasonKit

// helpers: build 18-wide score arrays, exactly like the JS `S(...)`
private func S(_ vals: Int?...) -> [Int?] {
  var a: [Int?] = Array(repeating: nil, count: 18)
  for (k, v) in vals.enumerated() { a[k] = v }
  return a
}
private func S(_ vals: [Int?]) -> [Int?] {
  var a: [Int?] = Array(repeating: nil, count: 18)
  for (k, v) in vals.enumerated() where k < 18 { a[k] = v }
  return a
}
private func closed(_ w: Int, _ l: Int, _ r: Int) -> LiveEngines.Closeout { .init(winner: w, lead: l, rem: r) }

/// A round with named players, a slope and a real card, for the result builders.
private func round(_ names: [String], indices: [Double], scores: [[Int?]], game: LiveGame, stake: Double = 0, holes: Int = 18,
                   mode: LiveMode = .teams, teams: [[Int]]? = nil, wolfOrder: [Int]? = nil, wolf: [LiveWolfPick?]? = nil,
                   slope: Int = 113, si: [Int]? = nil) -> LiveRoundState {
  let players = names.enumerated().map { LivePlayer(n: $1, i: indices[$0], ci: 1, guest: false, mid: UUID(), pid: UUID()) }
  var card = LiveCourseCard(slope: slope)
  if let si { card.si = si; card.siEst = false }
  var s = LiveRoundState.fresh(players: players, course: card)
  s.stage = .live; s.active = true; s.game = game; s.stake = stake; s.holes = holes; s.mode = mode
  s.scores = scores
  s.teams = teams ?? LiveRoundState.defaultTeams(count: players.count)
  s.wolfOrder = wolfOrder
  if let wolf { s.wolf = wolf }
  s.pmap = players.map { _ in UUID() }
  s.lr = UUID()
  return s
}

// MARK: - 5.1 common

@Suite struct LiveStrokeTests {
  @Test func courseHandicapRoundsLikeJS() {
    // Math.round(12.4 × 123 / 113) = round(13.49) = 13 · a nine halves it: round(6.75) = 7
    #expect(LiveEngines.courseHandicaps(indices: [12.4], slope: 123, nine: false) == [13])
    #expect(LiveEngines.courseHandicaps(indices: [12.4], slope: 123, nine: true) == [7])
    // JS Math.round(-2.5) is −2, not −3
    #expect(LiveEngines.jsRound(-2.5) == -2)
    #expect(LiveEngines.jsRound(2.5) == 3)
  }

  @Test func strokesOffTheLowMan() {
    #expect(LiveEngines.strokesOffLow([13, 9, 20]) == [4, 0, 11])
  }

  @Test func allocationWrapsPastTheCard() {
    let si = [7, 13, 15, 1, 9, 5, 17, 11, 3, 8, 14, 2, 10, 4, 12, 18, 6, 16]
    // 4 strokes: the 4 hardest holes (SI 1..4)
    let four = (0..<18).map { LiveEngines.strokeOn(stk: 4, si: si, h: $0, holes: 18) }
    #expect(four.reduce(0, +) == 4)
    #expect(four[3] == 1 && four[11] == 1 && four[8] == 1 && four[13] == 1)
    // 28 given = 1 every hole + a 2nd on the 10 hardest
    let many = (0..<18).map { LiveEngines.strokeOn(stk: 28, si: si, h: $0, holes: 18) }
    #expect(many.reduce(0, +) == 28)
    #expect(many.allSatisfy { $0 >= 1 })
    // a nine ranks 1..9 and wraps over nine: 10 strokes = 1 each + a 2nd on SI 1
    let nineSI = LiveCourseCard.estimateSI(pars: LiveCourseCard.standardPars, holes: 9)
    let nine = (0..<9).map { LiveEngines.strokeOn(stk: 10, si: nineSI, h: $0, holes: 9) }
    #expect(nine.reduce(0, +) == 10)
  }

  @Test func estimatedIndexIsHardestParFirst() {
    let si = LiveCourseCard.estimateSI(pars: LiveCourseCard.standardPars, holes: 18)
    // the four par 5s (holes 4, 9, 13, 18) take SI 1–4 in hole order
    #expect(si[3] == 1 && si[8] == 2 && si[12] == 3 && si[17] == 4)
    #expect(Set(si) == Set(1...18))
    let nine = LiveCourseCard.estimateSI(pars: LiveCourseCard.standardPars, holes: 9)
    #expect(Set(nine.prefix(9)) == Set(1...9))
    #expect(nine.suffix(9).allSatisfy { $0 == 18 })
  }
}

// MARK: - 5.2 match play

@Suite struct LiveMatchTests {
  let noStrokes = Array(repeating: Array(repeating: 0, count: 18), count: 4)

  @Test func closesOutWhenLeadBeatsRemaining() {
    // A wins 1–5 straight: 5 up with 13 left on 18 is open; on a nine it is 5&4
    let a = S(3, 3, 3, 3, 3), b = S(4, 4, 4, 4, 4)
    let open = LiveEngines.match(scores: [a, b], strokes: noStrokes, teams: [[0], [1]], holes: 18)
    #expect(open.closed == nil && open.a == 5 && open.played == 5)
    let nine = LiveEngines.match(scores: [a, b], strokes: noStrokes, teams: [[0], [1]], holes: 9)
    #expect(nine.closed == closed(0, 5, 4))
    #expect(nine.cells == [.a, .a, .a, .a, .a])
  }

  @Test func dormieAndHalves() {
    // 15 played, A 3 up with 3 to play = dormie; a halve is 'h'
    var a = S(Array(repeating: 4, count: 15)), b = S(Array(repeating: 4, count: 15))
    for h in [0, 1, 2] { a[h] = 3 }
    let m = LiveEngines.match(scores: [a, b], strokes: noStrokes, teams: [[0], [1]], holes: 18)
    #expect(m.a == 3 && m.b == 0 && m.played == 15 && m.closed == nil)
    #expect(m.dormie(holes: 18))
    #expect(m.cells[3] == .h)
    // one more halve closes it 3&2
    a[15] = 4; b[15] = 4
    let m2 = LiveEngines.match(scores: [a, b], strokes: noStrokes, teams: [[0], [1]], holes: 18)
    #expect(m2.closed == closed(0, 3, 2))
  }

  @Test func netBestBallUsesStrokes() {
    // B gets a stroke on hole 1 (SI 1): gross 4 nets 3 and beats A's 4
    var strokes = noStrokes
    strokes[1][0] = 1
    let m = LiveEngines.match(scores: [S(4), S(4)], strokes: strokes, teams: [[0], [1]], holes: 18)
    #expect(m.b == 1 && m.cells == [.b])
    // 2v2: the low ball per side decides
    let t = LiveEngines.match(scores: [S(5), S(4), S(6), S(6)], strokes: noStrokes, teams: [[0, 1], [2, 3]], holes: 18)
    #expect(t.a == 1)
  }

  @Test func resultEnvelopeAndStory() {
    let a = S(3, 3, 3, 3, 3), b = S(4, 4, 4, 4, 4)
    let s = round(["Jerecho", "Ed"], indices: [0, 0], scores: [a, b], game: .match, stake: 10, holes: 9)
    let r = LiveResultBuilder.match(s)
    #expect(r.winner == "0" && r.status == "5&4")
    #expect(r.story == "Jerecho def. Ed 5&4 · $10 on the line")
    #expect(r.share == "Jerecho beat Ed 5&4 for $10")
    #expect(r.json["game"]?.string == "match")
    #expect(r.json["winner"]?.string == "0")
    #expect(r.json["side_a"]?.string == "Jerecho" && r.json["side_b"]?.string == "Ed")
    #expect(r.json["stake"]?.double == 10)
    let H = r.json["holes"]
    #expect(H?["mode"]?.string == "sides" && H?["n"]?.int == 9 && H?["played"]?.int == 5 && H?["closed"]?.int == 5)
    #expect(H?["hot"]?.string == "a" && H?["legend"]?.string == "Jerecho")
    #expect(H?["cells"]?.array?.count == 5)
    #expect(r.recapRow.money == "ED PAYS JERECHO $10 · SETTLE UP")
    #expect(r.holes?.highlights == ["WON 5 STRAIGHT · 1-5", "CLOSED OUT ON 5"])
  }

  @Test func allSquareStory() {
    let s = round(["A B", "C D"], indices: [0, 0], scores: [S(4, 4), S(4, 4)], game: .match)
    let r = LiveResultBuilder.match(s)
    #expect(r.winner == nil && r.status == "HALVED")
    #expect(r.story == "All square — A B, C D")
    #expect(r.share == "All square - A, C")
    #expect(r.json["winner"]?.isNull == true)
    #expect(r.recapRow.money == "BRAGGING RIGHTS ONLY")
    #expect(r.recapRow.line == "All square — A B, C D")
  }

  @Test func pairsTakePluralVerbs() {
    let s = round(["A", "B", "C", "D"], indices: [0, 0, 0, 0], scores: [S(3), S(3), S(4), S(4)], game: .match, stake: 5, teams: [[0, 1], [2, 3]])
    let r = LiveResultBuilder.match(s)
    #expect(r.recapRow.money == "C & D PAY A & B $5 · SETTLE UP")
  }
}

// MARK: - round robin (D75, D79)

@Suite struct LiveRoundRobinTests {
  @Test func recordsAndSettlement() {
    // A beats everyone on h1, B beats C and D, C beats D
    let s = round(["A", "B", "C", "D"], indices: [0, 0, 0, 0], scores: [S(3), S(4), S(5), S(6)], game: .match, stake: 5, mode: .solo)
    let pairs = LiveEngines.roundRobin(scores: s.scores, strokes: s.strokeTable, holes: 18)
    #expect(pairs.count == 6)
    let rec = LiveEngines.rrRecords(pairs, count: 4)
    #expect(rec.map(\.w) == [3, 2, 1, 0] && rec.map(\.l) == [0, 1, 2, 3])
    let r = LiveResultBuilder.roundRobin(s)
    #expect(r.json["mode"]?.string == "solo")
    #expect(r.story == "A won the round robin, 3-0 · A 3-0, B 2-1, C 1-2, D 0-3 · $5 a match")
    #expect(r.share == "A won the round robin, 3-0")
    // pts = w − l = [3, 1, −1, −3] × $5 → D pays A 15, C pays B 5
    #expect(r.transfers == [LiveTransferNamed(from: "D", to: "A", amt: 15), LiveTransferNamed(from: "C", to: "B", amt: 5)])
    #expect(r.recapRow.money == "D PAYS A $15 · C PAYS B $5 · SETTLE UP")
  }

  @Test func splitHeadline() {
    let s = round(["A", "B", "C", "D"], indices: [0, 0, 0, 0], scores: [S(3), S(3), S(5), S(5)], game: .match, mode: .solo)
    let r = LiveResultBuilder.roundRobin(s)
    #expect(r.share == "A and B split it, 2 wins each")
    let none = round(["A", "B", "C", "D"], indices: [0, 0, 0, 0], scores: [S(4), S(4), S(4), S(4)], game: .match, mode: .solo)
    #expect(LiveResultBuilder.roundRobin(none).share == "Nobody won a match")
  }
}

// MARK: - 5.3 wolf

@Suite struct LiveWolfTests {
  let z = Array(repeating: Array(repeating: 0, count: 18), count: 4)
  let order = [2, 0, 3, 1]

  @Test func rotationThenComeback() {
    let empty: [LiveWolfPick?] = Array(repeating: nil, count: 18)
    let blank: [[Int?]] = Array(repeating: Array(repeating: nil, count: 18), count: 4)
    #expect(LiveEngines.wolfAt(h: 0, order: order, picks: empty, scores: blank, strokes: z, holes: 18) == 2)
    #expect(LiveEngines.wolfAt(h: 5, order: order, picks: empty, scores: blank, strokes: z, holes: 18) == 0)
    #expect(LiveEngines.wolfAt(h: 6, order: order, picks: empty, scores: blank, strokes: z, holes: 18) == 3)
    // the last two holes go to last place: player 1 lost a lone wolf on h1 (−3)
    var picks = empty
    picks[0] = .partner(1)
    var scores = blank
    for p in 0..<4 { scores[p][0] = 4 }
    scores[2] = S(5); scores[1] = S(5); scores[0] = S(3); scores[3] = S(3)   // wolf 2 + partner 1 lose
    let pts = LiveEngines.wolfPoints(order: order, picks: picks, scores: scores, strokes: z, holes: 18)
    #expect(pts == [1, -1, -1, 1])
    // worst is scanned 0..3 with strict <, from ord[0]=2: pts[1] < pts[2]? equal, so 2 keeps it
    #expect(LiveEngines.wolfAt(h: 16, order: order, picks: picks, scores: scores, strokes: z, holes: 18) == 2)
    #expect(LiveEngines.wolfAt(h: 7, order: order, picks: picks, scores: scores, strokes: z, holes: 9) == 2)
    // a strictly worse player takes it: 1 loses a lone wolf on h2 (−3) → last place
    picks[1] = .lone
    scores[0][1] = 3; scores[1][1] = 5; scores[2][1] = 4; scores[3][1] = 4   // wolf on h2 is ord[1] = 0, who wins alone
    picks[2] = .lone
    scores[0][2] = 4; scores[1][2] = 4; scores[2][2] = 4; scores[3][2] = 6   // wolf on h3 is ord[2] = 3, who loses alone
    let pts2 = LiveEngines.wolfPoints(order: order, picks: picks, scores: scores, strokes: z, holes: 18)
    #expect(pts2 == [5, -1, -1, -3])
    #expect(LiveEngines.wolfAt(h: 16, order: order, picks: picks, scores: scores, strokes: z, holes: 18) == 3)
  }

  @Test func loneAndPartnerScoring() {
    var picks: [LiveWolfPick?] = Array(repeating: nil, count: 18)
    picks[0] = .lone            // wolf 2 alone, wins: +3 / −1 each
    picks[1] = .partner(0)      // wolf 0 (ord[1]) + partner 0? partner must differ — use 3
    picks[1] = .partner(3)
    picks[2] = .lone            // wolf 3 alone, loses: −3 / +1 each
    picks[3] = nil              // no pick — scores nothing
    let scores: [[Int?]] = [S(4, 4, 4, 4), S(4, 5, 4, 4), S(3, 5, 4, 4), S(4, 5, 5, 4)]
    let t = LiveEngines.wolfPointsThrough(limit: 18, order: order, picks: picks, scores: scores, strokes: z, holes: 18, cells: true)
    // h1: wolf 2 lone wins → [−1, −1, +3, −1]; h2: wolf 0 + 3 (net 4 vs 5) win → [0, −2, +2, 0]
    // h3: wolf 3 lone (5 vs 4) loses → [+1, −1, +3, −3]; h4: no pick
    #expect(t.pts == [1, -1, 3, -3])
    #expect(t.cells.prefix(4) == [.w, .w, .o, nil])
    #expect(t.cells.count == 18)
    // a halve moves nothing and is 'h'
    let halve = LiveEngines.wolfPointsThrough(limit: 1, order: order, picks: [.lone], scores: [S(4), S(4), S(4), S(4)], strokes: z, holes: 18, cells: true)
    #expect(halve.pts == [0, 0, 0, 0] && halve.cells == [.h])
  }

  @Test func teeOrderPutsTheWolfLast() {
    #expect(LiveEngines.wolfTeeOrder(wolf: 0, order: order) == [3, 1, 2, 0])
  }

  @Test func resultEnvelope() {
    var picks: [LiveWolfPick?] = Array(repeating: nil, count: 18)
    picks[0] = .lone
    let s = round(["Chuck", "Gary", "Jerecho", "Logan"], indices: [0, 0, 0, 0], scores: [S(4), S(4), S(3), S(4)], game: .wolf, stake: 2, wolfOrder: order, wolf: picks)
    let r = LiveResultBuilder.wolf(s)
    #expect(r.story == "Jerecho took Wolf, up $6 · Chuck -$2, Gary -$2, Jerecho +$6, Logan -$2 · $2/pt")
    #expect(r.share == "Jerecho took Wolf, up $6")
    #expect(r.json["holes"]?["mode"]?.string == "wolf" && r.json["holes"]?["hot"]?.string == "w")
    #expect(r.json["holes"]?["legend"]?.string == "the wolf's side")
    #expect(r.json["holes"]?["played"]?.int == 18)
    #expect(r.transfers.count == 3 && r.transfers.allSatisfy { $0.to == "Jerecho" && $0.amt == 2 })
    #expect(r.recapRow.icon == "🐺")
    let level = round(["A", "B", "C", "D"], indices: [0, 0, 0, 0], scores: [S(4), S(4), S(4), S(4)], game: .wolf, wolfOrder: order, wolf: picks)
    #expect(LiveResultBuilder.wolf(level).story == "Wolf ended level · A +0, B +0, C +0, D +0 pts")
  }
}

// MARK: - 5.4 skins

@Suite struct LiveSkinsTests {
  let z3 = Array(repeating: Array(repeating: 0, count: 18), count: 3)

  @Test func carryAndDieAtTheLastHole() {
    // h1 tie carries; h2 A takes 2; h3 tie carries into nothing on a nine? — use 9 holes with a tie on 9
    var scores: [[Int?]] = [S(4, 3, 4), S(4, 4, 4), S(4, 4, 4)]
    let sk = LiveEngines.skins(scores: scores, strokes: z3, holes: 18)
    #expect(sk.won == [2, 0, 0] && sk.carry == 2 && sk.thru == 3)
    #expect(sk.cells == [.c, .player(0), .c])
    // net-zero: pts = won × n − total → [4, −2, −2]
    #expect(sk.pts == [4, -2, -2])
    // a full nine ending in a tie: the carried skin dies
    scores = [S(Array(repeating: 4, count: 9)), S(Array(repeating: 4, count: 9)), S(Array(repeating: 4, count: 9))]
    let dead = LiveEngines.skins(scores: scores, strokes: z3, holes: 9)
    #expect(dead.thru == 9 && dead.carry == 10 && dead.won == [0, 0, 0])
  }

  @Test func resultEnvelope() {
    let s = round(["Ed", "Mitch", "Blake"], indices: [0, 0, 0], scores: [S(4, 3, 4), S(4, 4, 4), S(4, 4, 4)], game: .skins, stake: 5)
    let r = LiveResultBuilder.skins(s)
    // money is pts × rate: 4 × $5 = $20
    #expect(r.story == "Ed took 2 skins and $20 · Ed 2 · $5 a skin · 1 carried died")
    #expect(r.share == "Ed took 2 skins and $20")
    #expect(r.json["carried_died"]?.int == 1 && r.json["thru"]?.int == 3)
    #expect(r.json["holes"]?["mode"]?.string == "players")
    #expect(r.json["holes"]?["hot"]?.int == 0)   // a player index travels as a NUMBER
    #expect(r.json["holes"]?["cells"]?.array?[1].int == 0)
    #expect(r.json["holes"]?["cells"]?.array?[0].string == "c")
    #expect(r.transfers == [LiveTransferNamed(from: "Mitch", to: "Ed", amt: 10), LiveTransferNamed(from: "Blake", to: "Ed", amt: 10)])
    let none = round(["A", "B"], indices: [0, 0], scores: [S(4), S(4)], game: .skins)
    #expect(LiveResultBuilder.skins(none).story == "Nobody took a skin · 1 carried died")
  }
}

// MARK: - 5.5 Sunningdale — tests/sunningdale.test.mjs, verbatim

@Suite struct LiveSunningdaleTests {
  func singles(_ a: [Int?], _ b: [Int?], _ holes: Int = 18) -> LiveEngines.Sunningdale {
    LiveEngines.sunningdale(scores: [a, b], teams: [[0], [1]], holes: holes)
  }

  @Test func t1_straightUp() {
    let r = singles(S(3, 4), S(4, 4))
    #expect(([r.a, r.b, r.played] as [Int]) == [1, 0, 2])
    #expect(r.strokes == [0, 0])
    #expect(r.bank == 1)
    #expect(r.closed == nil)
  }
  @Test func t2_twoDownGetsAStroke() {
    let r = singles(S(3, 3, 4), S(4, 4, 4))
    #expect(([r.a, r.b, r.played] as [Int]) == [2, 1, 3])
    #expect(r.strokes == [0, 0])
  }
  @Test func t3_scaling() {
    let r3 = singles(S(3, 3, 3), S(4, 4, 5))
    #expect(r3.strokes == [0, 2])
    let r4 = singles(S(3, 3, 3, 3), S(4, 4, 5, 6))
    #expect(r4.strokes == [0, 3])
  }
  @Test func t4_strokePersists() {
    let r = singles(S(3, 3, 4, 4), S(4, 4, 5, 4))
    #expect(([r.a, r.b] as [Int]) == [2, 1])
  }
  @Test func t5_teamsBestBall() {
    let r = LiveEngines.sunningdale(scores: [S(4, 4, 4), S(4, 4, 5), S(5, 5, 5), S(5, 5, 5)], teams: [[0, 1], [2, 3]], holes: 18)
    #expect(([r.a, r.b, r.played] as [Int]) == [2, 0, 3])
  }
  @Test func t6_t7_t8_closeouts() {
    #expect(singles(S(3, 3, 3, 3, 3), S(4, 4, 5, 6, 7), 9).closed == closed(0, 5, 4))
    #expect(singles(S(3, 3, 3, 3, 3), S(4, 4, 5, 6, 7), 18).closed == nil)
    let A = S(Array(repeating: 3, count: 10)), B = S(4, 4, 5, 6, 7, 8, 9, 10, 11, 12)
    #expect(singles(A, B, 18).closed == closed(0, 10, 8))
  }
  @Test func t9_theBankWalk() {
    let r = singles(S(3, 3, 4, 5, 5, 5, 6), S(4, 4, 4, 4, 4, 4, 4))
    #expect(([r.a, r.b] as [Int]) == [2, 5])
    #expect(r.bank == -1)
    #expect(r.strokes == [2, 0])
  }
  @Test func t10_halvesMoveNothing() {
    let r = singles(S(4, 4, 4), S(4, 4, 4))
    #expect(([r.a, r.b, r.played, r.bank] as [Int]) == [0, 0, 3, 0])
  }
  @Test func t11_incompleteHoleStops() {
    var a = S(4, 4); a[2] = 4
    #expect(singles(a, S(5, 5)).played == 2)
  }

  func solo(_ rows: [[Int?]], _ holes: Int = 18) -> LiveEngines.SunningdaleSolo {
    LiveEngines.sunningdaleSolo(scores: rows.map { S($0) }, holes: holes)
  }
  @Test func s1_outrightLowWins() {
    let r = solo([[3, 4], [4, 4], [4, 4], [5, 4]])
    #expect(r.wins == [1, 0, 0, 0] && r.played == 2)
  }
  @Test func s2_deficitStrokes() {
    #expect(solo([[3, 3, 3], [4, 4, 5], [4, 4, 5], [4, 4, 5]]).strokes == [0, 2, 2, 2])
  }
  @Test func s3_equalizerWinsAHole() {
    #expect(Array(solo([[3, 3, 4, 4], [4, 4, 4, 4], [5, 5, 5, 5], [5, 5, 5, 5]]).wins.prefix(2)) == [2, 1])
  }
  @Test func s4_s5_singleOwnerBank() {
    let r = solo([[3, 3, 5, 5, 5, 5], [4, 4, 4, 4, 4, 4], [7, 7, 7, 7, 7, 7], [7, 7, 7, 7, 7, 7]])
    #expect(r.wins == [2, 4, 0, 0])
    #expect(r.bankOwner == 0 && r.bankUnits == 0)
    let r2 = solo([[3, 3, 5, 5, 5, 5, 6], [4, 4, 4, 4, 4, 4, 4], [7, 7, 7, 7, 7, 7, 8], [7, 7, 7, 7, 7, 7, 8]])
    #expect(r2.bankOwner == 1 && r2.bankUnits == 1)
  }
  @Test func s6_s7_nineAndIncomplete() {
    let rows = [Array(repeating: 3, count: 10)] + Array(repeating: Array(repeating: 4, count: 10), count: 3)
    #expect(solo(rows.map { $0.map { Optional($0) } }, 9).played == 9)
    #expect(solo([[3, 3], [4, 4], [4, 4], [4, nil]]).played == 1)
  }

  @Test func teamResultEnvelope() {
    let s = round(["Jerecho", "Ed"], indices: [12, 20], scores: [S(3, 3, 4, 5, 5, 5, 6), S(4, 4, 4, 4, 4, 4, 4)], game: .sunningdale, stake: 5)
    let r = LiveResultBuilder.sunningdale(s)
    #expect(r.status == "3 up thru 7" && r.winner == "1" && r.bank == -1)
    #expect(r.story == "Ed def. Jerecho 3 up thru 7. Sunningdale Rules · bank: Ed $5")
    #expect(r.share == "Ed beat Jerecho 3 up thru 7 for $5")
    #expect(r.json["unit"]?.double == 5 && r.json["bank"]?.int == -1)
    #expect(r.recapRow.money == "ED TAKES THE BANK - $5")
    // no handicaps: the strokes ladder never touches Sunningdale
    #expect(LiveCopy.playerRow(s, 1).sub == "NO HCP · STRAIGHT UP")
  }

  @Test func soloResultEnvelope() {
    let s = round(["A", "B", "C", "D"], indices: [0, 0, 0, 0], scores: [S(3, 3, 5, 5, 5, 5, 6), S(4, 4, 4, 4, 4, 4, 4), S(7, 7, 7, 7, 7, 7, 8), S(7, 7, 7, 7, 7, 7, 8)],
                  game: .sunningdale, stake: 10, mode: .solo)
    let r = LiveResultBuilder.sunningdaleSolo(s)
    #expect(r.json["mode"]?.string == "solo")
    #expect(r.json["bank"]?["owner"]?.int == 1 && r.json["bank"]?["units"]?.int == 1)
    #expect(r.share == "B won the most holes and $10 from each")
    #expect(r.story == "B took it, 5 holes. Sunningdale Rules · B 5, A 2, C 0, D 0 · bank: B $10 (each owes)")
    #expect(r.recapRow.money == "B HOLDS THE BANK - $10 FROM EACH")
  }
}

// MARK: - settlement transfers (8320)

@Suite struct LiveSettleTests {
  @Test func minimizedGreedy() {
    let t = LiveEngines.settleTransfers(pts: [3, -1, -1, -1], val: 2)
    #expect(t == [.init(from: 1, to: 0, amt: 2), .init(from: 2, to: 0, amt: 2), .init(from: 3, to: 0, amt: 2)])
    #expect(LiveEngines.settleTransfers(pts: [1, -1], val: 0).isEmpty)
    // creditors and debtors pair off largest first
    let m = LiveEngines.settleTransfers(pts: [4, 1, -3, -2], val: 1)
    #expect(m == [.init(from: 2, to: 0, amt: 3), .init(from: 3, to: 0, amt: 1), .init(from: 3, to: 1, amt: 1)])
  }

  @Test func liveRows() {
    #expect(LiveCopy.settleRows(pts: [1, -1], stake: 0, names: ["A", "B"]) == [.init(label: "BRAGGING POINTS — NO MONEY ON IT", amount: "$0")])
    #expect(LiveCopy.settleRows(pts: [0, 0], stake: 5, names: ["A", "B"]) == [.init(label: "ALL SQUARE", amount: "$0")])
    #expect(LiveCopy.settleRows(pts: [1, -1], stake: 2.5, names: ["Ed", "Al"]) == [.init(label: "AL → ED", amount: "$2.5")])
  }
}

// MARK: - the router + copy

@Suite struct LiveCopyTests {
  @Test func gameResultRoutes() {
    let two = round(["A", "B"], indices: [0, 0], scores: [S(4), S(4)], game: .wolf)
    #expect(LiveResultBuilder.gameResult(two) == nil)          // wolf needs four
    let one = round(["A"], indices: [0], scores: [S(4)], game: .score)
    #expect(LiveResultBuilder.gameResult(one) == nil)
    let four = round(["A", "B", "C", "D"], indices: [0, 0, 0, 0], scores: [S(4), S(4), S(4), S(4)], game: .match, mode: .solo)
    #expect(LiveResultBuilder.gameResult(four)?.solo == true)
  }

  @Test func matchCardLines() {
    // CH 9 vs 8 on a 113 slope: Jerecho gets one stroke, on the estimated SI 1 (hole 4, a par 5) — Ed's 3 there halves it net
    var a = S(Array(repeating: 4, count: 15)), b = S(Array(repeating: 4, count: 15))
    for h in [0, 1, 2] { a[h] = 3 }
    b[3] = 3
    let s = round(["Jerecho", "Ed"], indices: [8.6, 8.1], scores: [a, b], game: .match, stake: 10)
    #expect(s.strokes == [1, 0] && s.strokeOn(0, 3) == 1)
    let c = LiveCopy.matchCard(s)!
    #expect(c.teams == "Match play · singles · Jerecho vs Ed")
    #expect(c.status == "JERECHO 3 UP · DORMIE")
    #expect(c.meta == "THRU 15 · STROKES OFF LOW MAN (ED) · $10 A SIDE · EST. CARD")
    a[15] = 4; b[15] = 4
    let s2 = round(["Jerecho", "Ed"], indices: [8.6, 8.1], scores: [a, b], game: .match)
    #expect(LiveCopy.matchCard(s2)!.status == "JERECHO WIN 3&2")
    #expect(LiveCopy.scoreboard(s2, presence: []).hero == "JERECHO WIN 3&2")
  }

  @Test func skinsAndWolfCards() {
    let s = round(["Ed", "Mitch", "Blake"], indices: [0, 0, 0], scores: [S(4, 3, 4), S(4, 4, 4), S(4, 4, 4)], game: .skins, stake: 5)
    let k = LiveCopy.skinsCard(s)!
    #expect(k.status == "HOLE 4 WORTH 2 SKINS" && k.hot && k.meta == "THRU 3 · LOW NET TAKES IT · $5/SKIN")
    #expect(LiveCopy.scoreboard(s, presence: []).hero == "ED 2 · 2 RIDING")
    var w = round(["Chuck", "Gary", "Jerecho", "Logan"], indices: [0, 0, 0, 0], scores: [S(4), S(4), S(3), S(4)], game: .wolf, stake: 2, wolfOrder: [2, 0, 3, 1])
    w.hole = 16
    let wc = LiveCopy.wolfCard(w)!
    #expect(wc.comeback && wc.who.hasSuffix(" IS THE WOLF · COMEBACK"))
    #expect(wc.meta.hasPrefix("TEES: ") && wc.meta.hasSuffix(" · $2/PT"))
  }

  @Test func strokePlayScoreboard() {
    let s = round(["Jerecho Fischbeck", "Ed"], indices: [12.4, 8.1], scores: [S(4, 5), S(5, 5)], game: .score, slope: 123)
    let sb = LiveCopy.scoreboard(s, presence: ["Ed"])
    #expect(sb.hero.hasPrefix("JERECHO LEADS · "))
    #expect(sb.chips[1].present && !sb.chips[0].present)
    #expect(sb.chips[0].name == "Jerecho")
    let blank = round(["A", "B"], indices: [0, 0], scores: [S(), S()], game: .score)
    #expect(LiveCopy.scoreboard(blank, presence: []).hero == "ALL TO PLAY")
  }

  @Test func syncBadgeAndBanner() {
    var s = round(["A", "B"], indices: [0, 0], scores: [S(4), S()], game: .score)
    s.code = nil
    #expect(LiveCopy.syncBadge(s, presence: [], queued: 0) == "Solo pencil · scores live on this phone")
    s.code = "abc"
    #expect(LiveCopy.syncBadge(s, presence: ["A", "B"], queued: 2) == "2 on the sheet · 2 queued")
    #expect(LiveCopy.syncBadge(s, presence: [], queued: 0) == "1 on the sheet · synced")
    s.course.label = "Papago"
    s.hole = 1
    let mine = LiveCopy.resumeBanner(s)!
    #expect(mine.kicker == "Continue your round" && mine.line == "PAPAGO · STROKE PLAY" && mine.meta == "HOLE 2" && mine.go == "→")
    s.mine = false; s.host = "Marcus Webb"
    let inv = LiveCopy.resumeBanner(s)!
    #expect(inv.invite && inv.kicker == "Marcus put you on the tee sheet" && inv.meta == "JUST TEED OFF · NOTHING SCORED YET" && inv.go == "JOIN")
    s.scores[1][0] = 4
    #expect(LiveCopy.resumeBanner(s)!.meta == "HOLE 2 · THRU 1")
  }

  @Test func finishSheetNamesMissingHoles() {
    var s = round(["Jerecho", "Ed"], indices: [0, 0], scores: [S(Array(repeating: 4, count: 18)), S(Array(repeating: 4, count: 16))], game: .score)
    s.players[1].guest = true
    let f = LiveCopy.finishSheet(s)
    #expect(f.primary == "Post 1 card to the season")
    #expect(f.warning == "Ed — missing holes 17, 18. That card won’t post — go back and fill in, or finish without.")
    #expect(f.intro == "Complete cards post to the season, attested by the group; 1 guest gets a recap to claim. A partial card is skipped, not lost.")
    // a clean front nine on a nine is a complete card; a nine's back holes are never "missing"
    var nine = round(["A"], indices: [0], scores: [S(Array(repeating: 4, count: 9))], game: .score, holes: 9)
    #expect(LiveCopy.finishSheet(nine).primary == "Post 1 card to the season")
    nine.scores[0][8] = nil
    #expect(LiveCopy.finishSheet(nine).primary == "Finish — no complete member card to post")
    #expect(LiveCopy.finishSheet(nine).warning == "A — missing hole 9. That card won’t post — go back and fill in, or finish without.")
    #expect(LiveCopy.cardHoles(S(Array(repeating: 4, count: 9))) == 9)
    #expect(LiveCopy.cardHoles(S(Array(repeating: 4, count: 10))) == 0)
  }

  @Test func cardsPayload() {
    let s = round(["A"], indices: [0], scores: [S(4, nil, 5)], game: .score)
    let c = LiveCopy.cards(s).array!
    #expect(c.count == 1)
    #expect(c[0]["player_id"]?.string == s.pmap![0].uuidString.lowercased())
    let strokes = c[0]["strokes"]!.array!
    #expect(strokes.count == 18 && strokes[0].int == 4 && strokes[1].isNull && strokes[2].int == 5)
  }

  @Test func previewNamesTheHoles() {
    let si = [7, 13, 15, 1, 9, 5, 17, 11, 3, 8, 14, 2, 10, 4, 12, 18, 6, 16]
    var card = LiveCourseCard(slope: 123)
    card.si = si; card.siEst = false
    let ps = [LivePlayer(n: "Ed", i: 8.1, ci: 1, guest: false), LivePlayer(n: "Danny", i: 10.6, ci: 1, guest: false)]
    let p = LiveCopy.preview(game: .match, picked: ps, pairing: 0, course: card, holes: 18)!
    #expect(p == "**Ed** vs **Danny**\nStrokes off the low man (Ed): **Danny** gets 3: holes 4, 9, 12.")
    #expect(LiveCopy.preview(game: .wolf, picked: ps, pairing: 0, course: card, holes: 18) == "Wolf needs exactly 4 players.")
    #expect(LiveCopy.preview(game: .score, picked: ps, pairing: 0, course: card, holes: 18) == nil)
  }

  @Test func teeOffProblems() {
    #expect(LiveGame.wolf.teeOffProblem(players: 3) == "Wolf needs exactly 4")
    #expect(LiveGame.match.teeOffProblem(players: 3) == "Match play takes 2 (singles) or 4 (2v2)")
    #expect(LiveGame.skins.teeOffProblem(players: 5) == "Skins takes 2 to 4 players")
    #expect(LiveGame.score.teeOffProblem(players: 0) == "Pick at least yourself")
    #expect(LiveGame.sunningdale.teeOffProblem(players: 4) == nil)
  }

  @Test func courtSwapRederivesThePairing() {
    #expect(LivePairings.swap(pairing: 0, 1, 2) == 1)     // 0's partner becomes 2
    #expect(LivePairings.swap(pairing: 0, 0, 3) == 1)     // 0 moves across to sit with 2: partner of 0 is now 2 → pairing 1
    #expect(LivePairings.swap(pairing: 0, 0, 1) == nil)   // same zone
    #expect(LivePairings.teams(pairing: 2) == [[0, 3], [1, 2]])
  }

  @Test func eyebrowNeverRepeatsTheTee() {
    var c = LiveCourseCard(label: "Papago · Blue", tee: "Blue", rating: 70.2, slope: 123)
    #expect(c.eyebrow == "Live round · Papago · Blue · 70.2/123")
    c.label = "Papago"
    #expect(c.eyebrow == "Live round · Papago — Blue · 70.2/123")
    c.rating = nil; c.slope = nil
    #expect(c.eyebrow == "Live round · Papago — Blue · 72/113")
  }
}

// MARK: - D85 LWW / queue

@Suite struct LiveSyncTests {
  @Test func olderEditsNeverRegressACard() {
    var s = round(["A", "B"], indices: [0, 0], scores: [S(4), S()], game: .score)
    let pid = s.pmap![1]
    s.scts[1][0] = 1000
    #expect(!LiveMerge.apply(.score(pid: pid, hole0: 0, strokes: 5, cts: 999), to: &s))
    #expect(s.scores[1][0] == nil)
    #expect(LiveMerge.apply(.score(pid: pid, hole0: 0, strokes: 5, cts: 1001), to: &s))
    #expect(s.scores[1][0] == 5 && s.scts[1][0] == 1001)
    // a cleared cell travels as null and lands as nil
    #expect(LiveMerge.apply(.score(pid: pid, hole0: 0, strokes: nil, cts: 1002), to: &s))
    #expect(s.scores[1][0] == nil)
    // wolf picks carry their own clock
    #expect(LiveMerge.apply(.wolf(hole0: 3, pick: .lone, cts: 5), to: &s))
    #expect(s.wolf[3]?.isLone == true)
    #expect(!LiveMerge.apply(.wolf(hole0: 3, pick: nil, cts: 4), to: &s))
    #expect(LiveMerge.apply(.wolf(hole0: 3, pick: nil, cts: 6), to: &s))
    #expect(s.wolf[3] == nil)
  }

  @Test func reconcileMergesAndSpotsTheEnd() {
    var s = round(["A", "B"], indices: [0, 0], scores: [S(4), S()], game: .wolf)
    let lr = s.lr!, pid = s.pmap![1]
    let d: JSONValue = .object([
      "round": .object(["id": .string(lr.uuidString.lowercased()), "status": .string("live"),
                        "game_state": .object(["h2": .object(["v": .object(["mode": .string("partner"), "partner": .number(0)]), "cts": .string("2026-08-27T18:10:00.500Z")])])]),
      "scores": .array([.object(["player_id": .string(pid.uuidString.lowercased()), "hole": .number(1), "strokes": .number(6), "cts": .number(5000)])]),
    ])
    #expect(LiveMerge.applyState(d, to: &s) == nil)
    #expect(s.scores[1][0] == 6 && s.scts[1][0] == 5000)
    #expect(s.wolf[1]?.partner == 0 && s.wcts[1] == LiveMerge.parseMs("2026-08-27T18:10:00.500Z"))
    let over: JSONValue = .object(["round": .object(["id": .string(lr.uuidString.lowercased()), "status": .string("final")])])
    #expect(LiveMerge.applyState(over, to: &s) == "final")
    // another round's pull is ignored
    let other: JSONValue = .object(["round": .object(["id": .string(UUID().uuidString), "status": .string("final")])])
    #expect(LiveMerge.applyState(other, to: &s) == nil)
  }

  @Test func wireShape() {
    let m = LiveMessage.score(pid: UUID(), hole0: 6, strokes: nil, cts: 42)
    let w = m.wire
    #expect(w["t"]?.string == "score" && w["h"]?.int == 7 && w["s"]?.isNull == true && w["cts"]?.double == 42)
    let back = LiveMessage(wire: .object(w))!
    #expect(back.t == "score" && back.h == 7 && back.s == nil && back.cts == 42 && back.pid == m.pid)
    let g = LiveMessage.gone(cts: 1).wire
    #expect(g["status"]?.string == "abandoned" && g["s"] == nil)
    let wolf = LiveMessage.wolf(hole0: 0, pick: .partner(2), cts: 1).wire
    #expect(wolf["w"]?["partner"]?.int == 2)
    #expect(LiveMessage.wolf(hole0: 0, pick: nil, cts: 1).wire["w"]?.isNull == true)
  }

  @Test func deadWritesAreDropped() {
    #expect(LiveRoundSession.isDeadWrite("Round is not live"))
    #expect(LiveRoundSession.isDeadWrite("No such player in this round"))
    #expect(LiveRoundSession.isDeadWrite("Could not find the function public.live_set_score in the schema cache"))
    #expect(!LiveRoundSession.isDeadWrite("The network connection was lost."))
    #expect(LiveRoundSession.maxTries == 40)
  }

  @Test func diskQueueCapsAndAbandons() async {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("cs-live-\(UUID().uuidString)")
    let disk = LiveDisk(directory: dir)
    let lr = UUID()
    let q = (0..<320).map { LiveMessage.score(pid: UUID(), hole0: $0 % 18, strokes: 4, cts: Int64($0)) }
    await disk.saveQueue(lr, q)
    let read = await disk.queue(lr)
    #expect(read.count == LiveDisk.queueCap && read.first?.cts == 20)
    await disk.removeQueue(lr)
    #expect(await disk.queue(lr).isEmpty)
    let a = UUID()
    await disk.queueAbandon(a); await disk.queueAbandon(a)
    #expect(await disk.pendingAbandons() == [a])
    var s = round(["A"], indices: [0], scores: [S(4)], game: .score)
    s.lr = lr
    await disk.save(s)
    let snaps = await disk.snapshots()
    #expect(snaps.count == 1 && snaps[0].lr == lr && snaps[0].scores[0][0] == 4)
    await disk.clearSnapshots(keep: nil)
    #expect(await disk.snapshots().isEmpty)
    try? FileManager.default.removeItem(at: dir)
  }

  @Test func snapshotRoundTrips() throws {
    var s = round(["A", "B"], indices: [12.4, 8.1], scores: [S(4, 5), S(4)], game: .wolf, stake: 2, wolfOrder: [1, 0, 3, 2])
    s.guestTokens = ["1": UUID()]
    s.wolf[0] = .partner(1)
    let data = try JSONEncoder().encode(s)
    let back = try JSONDecoder().decode(LiveRoundState.self, from: data)
    #expect(back == s)
  }
}

// MARK: - resume + the guest's door

@Suite struct LiveRehydrateTests {
  func row(me: UUID, starter: UUID, visitor: Bool = false) -> JSONValue {
    let mid = UUID(), mid2 = UUID()
    return .object([
      "id": .string(UUID().uuidString), "league_id": .string(UUID().uuidString), "game": .string("match"),
      "game_config": .object(["stake": .number(5), "side_a": .array([.string("Me")]), "side_b": .array([.string("Host")]), "si_estimated": .bool(true)]),
      "join_code": .string("deadbeef"), "started_by": .string(mid2.uuidString),
      "course_snapshot": .object(["holes": .number(9), "rating": .number(35.1), "slope": .number(120), "label": .string("Palo Verde"), "tee": .string("White")]),
      "course_label": .string("Palo Verde"), "started_at": .string("2026-08-27T18:10:00Z"), "visitor": .bool(visitor),
      "live_round_players": .array([
        .object(["id": .string(UUID().uuidString), "member_id": .string(mid.uuidString), "position": .number(0),
                 "member": .object(["profile_id": .string(me.uuidString), "profile": .object(["display_name": .string("Me"), "index_current": .number(12.4)])])]),
        .object(["id": .string(UUID().uuidString), "member_id": .string(mid2.uuidString), "position": .number(1),
                 "member": .object(["profile_id": .string(starter.uuidString), "profile": .object(["display_name": .string("Host"), "index_current": .null])])]),
      ]),
    ])
  }

  @Test func serverRowBecomesTheInviteFace() {
    let me = UUID(), starter = UUID()
    let s = LiveRehydrator.fromServerRow(row(me: me, starter: starter), myPid: me)!
    #expect(s.stage == .live && s.active && s.game == .match && s.holes == 9 && s.code == "deadbeef")
    #expect(!s.mine && s.host == "Host")
    #expect(s.players[0].me && s.players[0].locked && s.players[1].i == 18)
    #expect(s.teams == [[0], [1]] && s.stake == 5)
    #expect(s.course.rating == 35.1 && s.course.siEst)
    #expect(LiveCopy.resumeBanner(s)?.kicker == "Host put you on the tee sheet")
    let mine = LiveRehydrator.fromServerRow(row(me: me, starter: me), myPid: me)!
    #expect(mine.mine)
  }

  @Test func guestRoundTakesTheToken() {
    let meSeat = UUID(), token = UUID()
    let d: JSONValue = .object([
      "round": .object(["id": .string(UUID().uuidString), "status": .string("live"), "game": .string("skins"), "join_code": .string("c0de"),
                        "game_config": .object(["stake": .number(3)]), "course_snapshot": .object(["holes": .number(18)]), "course_label": .string("Encanto")]),
      "players": .array([
        .object(["id": .string(UUID().uuidString), "member_id": .string(UUID().uuidString), "position": .number(0), "display_name": .string("Jerecho"), "index_current": .number(12)]),
        .object(["id": .string(meSeat.uuidString), "guest_name": .string("Chuck"), "guest_index": .null, "index_source": .string("estimated"), "position": .number(1)]),
      ]),
      "scores": .array([]),
      "me": .string(meSeat.uuidString),
    ])
    let (s, g) = LiveRehydrator.guestRound(d, token: token, signedIn: false)!
    #expect(g.token == token && g.me == meSeat && !g.signedIn)
    #expect(!s.mine && s.game == .skins && s.stake == 3 && s.players[1].me && s.players[1].est && s.players[1].guest)
    #expect(s.meIndex == 1)
  }

  @Test func claimIntentAndDoor() {
    let d = UserDefaults(suiteName: "cs-live-claim-tests")!
    d.removePersistentDomain(forName: "cs-live-claim-tests")
    let t = UUID()
    #expect(ClaimIntent.token(from: URL(string: "https://cupseason.app/?claim=\(t.uuidString)")!) == t.uuidString)
    #expect(ClaimIntent.token(from: URL(string: "https://cupseason.app/?join=abc")!) == nil)
    ClaimIntent.store(" \(t.uuidString) ", defaults: d)
    #expect(ClaimIntent.pending(defaults: d) == t)
    ClaimIntent.clear(defaults: d)
    #expect(ClaimIntent.pending(defaults: d) == nil)
    #expect(ClaimIntent.url(t).absoluteString == "https://cupseason.app/?claim=\(t.uuidString.lowercased())")
    let info: JSONValue = .object(["guest_name": .string("Chuck"), "gross": .number(84), "course_label": .string("Papago"), "played_on": .string("2026-07-25")])
    var cal = Calendar(identifier: .gregorian)
    cal.locale = Locale(identifier: "en_US")
    #expect(ClaimDoor.line(info, calendar: cal) == "Chuck — 84 at Papago, Sat, Jul 25. Enter your email to keep it.")
  }
}
