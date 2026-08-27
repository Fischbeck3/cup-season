import Testing
import Foundation
@testable import CupSeasonKit

// The quick post, checked against the web's own math and copy (index.html
// line numbers in the sources): recalc for 18 and for nines, the payload,
// the pars sheet, the even-par guard, the draft TTL, scan apply, the
// ceremony and epilogue lines.

@Suite struct PostRecalcTests {
  func card(f9: String = "", b9: String = "", rating: String = "71.2", slope: String = "128", side: Int = 18) -> PostCard {
    var c = PostCard(); c.f9 = f9; c.b9 = b9; c.rating = rating; c.slope = slope; c.side = side; return c
  }

  @Test func eighteenHolesAtOneHundredPercent() {
    // 84 on a 71.2/128 with a 12.4: diff = 12.8 × 113 / 128 = 11.3 → vs = +1.1 → 9 points
    let p = PostCalc.preview(card(f9: "41", b9: "43"), myIndex: 12.4)!
    #expect(p.gross == 84 && p.holes == 18)
    #expect(abs(p.vs - 1.1) < 0.05)
    #expect(p.points == 9)
    #expect(p.vsText == "+1.1")
    #expect(p.label == "84 GROSS")
    #expect(p.grossLine == "Gross 84 · 18 holes")
  }

  @Test func aNineHalvesTheRatingAndThePoints() {
    // 41 on the front of an 18-hole 71.2/128: rating9 = 35.6, diff = (5.4 × 113 / 128) × 2 = 9.5 → vs = 12.4 − 9.5 = +2.9 → 9 → ceil(9/2) = 5
    let p = PostCalc.preview(card(f9: "41"), myIndex: 12.4)!
    #expect(p.gross == 41 && p.holes == 9)
    #expect(abs(p.vs - 2.9) < 0.05)
    #expect(p.points == 5)
    #expect(p.message.hasPrefix("9-hole round, half value. "))
    #expect(p.grossLine == "Gross 41 · 9 holes · half value")
  }

  @Test func aRealNineHoleTeeIsNotHalved() {
    // D72: rating9 — the field already holds the 9-hole rating (35.6)
    var c = card(f9: "41", rating: "35.6", side: 9); c.rating9 = true
    let p = PostCalc.preview(c, myIndex: 12.4)!
    #expect(abs(p.vs - 2.9) < 0.05)
  }

  @Test func aNinePostIgnoresAStaleBackNine() {
    // D72: on the 9-hole side the back box is ignored even if it carries a value
    let c = card(f9: "41", b9: "43", side: 9)
    #expect(c.inputs.f9 == 41 && c.inputs.b9 == 0)
    #expect(PostCalc.preview(c, myIndex: 12.4)!.holes == 9)
  }

  @Test func emptyCardPreviewsNothing() {
    #expect(PostCalc.preview(card(), myIndex: 12.4) == nil)
    #expect(PostCalc.preview(card(rating: "", slope: ""), myIndex: nil) == nil)
  }

  @Test func noNumberFallsBackToEighteen() {
    // the web's `|| 18` (14872): a golfer with no number previews against 18
    let a = PostCalc.preview(card(f9: "41", b9: "43"), myIndex: nil)!
    let b = PostCalc.preview(card(f9: "41", b9: "43"), myIndex: 18)!
    #expect(a.vs == b.vs)
  }

  @Test func holesModeSumsTheGrid() {
    var c = card(); c.mode = .holes; c.scores = Array(repeating: 5, count: 18)
    #expect(c.inputs.f9 == 45 && c.inputs.b9 == 45)
    c.side = 9
    #expect(c.inputs.f9 == 45 && c.inputs.b9 == 0)
  }

  @Test func theSanityGate() {
    #expect(PostCalc.vsIsSane(2.4))
    #expect(!PostCalc.vsIsSane(-71.6))
    #expect(!PostCalc.vsIsSane(nil))
  }
}

@Suite struct PostPayloadTests {
  @Test func eighteenHolePayload() {
    var c = PostCard(); c.f9 = "41"; c.b9 = "43"; c.rating = "71.2"; c.slope = "128"; c.course = " Papago "; c.courseId = "abc"; c.date = "2026-08-22"
    let s = UUID()
    let p = PostPayload.build(c, seasonId: s)
    #expect(p.gross == 84 && p.rating == 71.2 && p.nine_rating == nil && p.slope == 128 && p.holes_played == 18)
    #expect(p.source == "quick" && p.played_on == "2026-08-22" && p.course_label == "Papago" && p.api_course_id == "abc" && p.season_id == s)
    #expect(p.photo_path == nil)
  }

  @Test func ninePayloadCarriesTheNineRating() {
    var c = PostCard(); c.f9 = "41"; c.rating = "71.2"; c.slope = "128"
    #expect(PostPayload.build(c, seasonId: nil).nine_rating == 35.6)
    #expect(PostPayload.build(c, seasonId: nil).holes_played == 9)
    c.rating9 = true; c.rating = "35.6"; c.side = 9
    #expect(PostPayload.build(c, seasonId: nil).nine_rating == 35.6)
  }

  @Test func emptyCourseIsAbsentNotBlank() throws {
    var c = PostCard(); c.f9 = "41"; c.b9 = "43"; c.rating = "71.2"; c.slope = "128"
    let p = PostPayload.build(c, seasonId: nil)
    #expect(p.course_label == nil && p.played_on == nil)
    let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(p)) as! [String: Any]
    #expect(json["course_label"] == nil && json["nine_rating"] == nil && json["season_id"] == nil)
    #expect(json["source"] as? String == "quick")
  }

  @Test func holeRowsOnlyInHolesMode() {
    var c = PostCard(); c.mode = .holes; c.scores = PostCard.parStd; c.scores[2] = 0
    let id = UUID()
    let rows = PostPayload.holeRows(c, roundId: id)
    #expect(rows.count == 17)
    #expect(rows.first == PostHoleRow(round_id: id, hole_number: 1, strokes: 4))
    #expect(!rows.contains { $0.hole_number == 3 })
    c.mode = .total
    #expect(PostPayload.holeRows(c, roundId: id).isEmpty)
  }
}

@Suite struct PostParsTests {
  @Test func nineDigitsASide() {
    #expect(PostPars.clean("45a3 4 5 3 5 4 3 7") == "453453543")
    #expect(PostPars.validSide("453453543"))
    #expect(!PostPars.validSide("45345354"))
    #expect(PostPars.sum("453453543") == 36)
  }

  @Test func parseBothSides() {
    let p = PostPars.parse(front: "453453543", back: "434445345", nine: false, current: PostCard.parStd)!
    #expect(p.count == 18 && p.reduce(0, +) == 72)
    #expect(PostPars.parse(front: "4534535", back: "434445345", nine: false, current: PostCard.parStd) == nil)
  }

  @Test func aNineKeepsTheBackPars() {
    var current = PostCard.parStd; current[17] = 3
    let p = PostPars.parse(front: "333333333", back: "", nine: true, current: current)!
    #expect(p.prefix(9).allSatisfy { $0 == 3 } && p[17] == 3)
  }
}

@Suite struct PostGuardAndCardTests {
  @Test func evenParGuardTracksInteraction() {
    var c = PostCard(); c.mode = .holes
    #expect(c.needsEvenParGuard && c.evenParTotal == 72)
    c.side = 9
    #expect(c.evenParTotal == 36)
    c.plus(0); c.minus(0)   // dialled back to par — still a real card
    #expect(!c.needsEvenParGuard && c.scores == PostCard.parStd)
    c.mode = .total; c.touched = false
    #expect(!c.needsEvenParGuard)
  }

  @Test func stepperBounds() {
    var c = PostCard()
    for _ in 0..<20 { c.plus(0) }
    #expect(c.scores[0] == 15)
    for _ in 0..<20 { c.minus(0) }
    #expect(c.scores[0] == 1)
    #expect(c.result(at: 0) == .eagle)
  }

  @Test func aNewCourseNeverWearsTheLastCard() {
    var c = PostCard()
    c.teePicked(courseId: "palo", label: "Palo Verde · White", rating: 30.5, slope: 95, nineHoleTee: true)
    #expect(c.side == 9 && c.rating9 && c.rating == "30.5" && c.slope == "95")
    c.loadPars([3, 3, 3, 3, 3, 3, 3, 3, 3], nineHoleTee: true)
    #expect(c.pars.prefix(9).allSatisfy { $0 == 3 } && c.pars[9] == 4)
    c.teePicked(courseId: "papago", label: "Papago · Blue", rating: 71.2, slope: 128, nineHoleTee: false)
    #expect(c.pars == PostCard.parStd && c.side == 18 && !c.rating9)
    // re-picking the same course leaves a hand-typed card alone
    c.pars[0] = 5
    c.teePicked(courseId: "papago", label: "Papago · White", rating: 69.0, slope: 120, nineHoleTee: false)
    #expect(c.pars[0] == 5)
  }

  @Test func theWaysOut() {
    var c = PostCard(); c.f9 = "41"; c.course = "Papago"; c.mode = .holes; c.touched = true; c.side = 9; c.rating9 = true
    c.scan = PostScanContext(read: [], others: [])
    c.scrapScan()
    #expect(c.mode == .total && !c.touched && c.scan == nil && c.course == "Papago")
    c.clearAfterPost()
    #expect(c.isBlank && c.side == 18 && !c.rating9 && c.pars == PostCard.parStd)
  }
}

@Suite struct PostDraftTests {
  @Test func aDraftComesBackWithinADay() {
    var c = PostCard(); c.f9 = "41"; c.course = "Papago"
    let data = PostDraft.encode(PostDraft(at: Date().addingTimeInterval(-3600), card: c))
    #expect(PostDraft.decode(data)?.card.f9 == "41")
  }

  @Test func aStaleDraftIsDropped() {
    var c = PostCard(); c.f9 = "41"
    let data = PostDraft.encode(PostDraft(at: Date().addingTimeInterval(-25 * 3600), card: c))
    #expect(PostDraft.decode(data) == nil)
    #expect(PostDraft.decode(nil) == nil)
    #expect(PostDraft.decode(Data("nope".utf8)) == nil)
  }
}

@Suite struct PostScanTests {
  func scan(players: Int = 1) -> PostScan {
    var holes = Array(repeating: 5, count: 18); holes[3] = 0; holes[16] = 0
    let me = PostScanPlayer(name: "Jerecho", holes: holes, total: 84, holes_read: 16)
    let other = PostScanPlayer(name: "Ed", holes: Array(repeating: 4, count: 18), total: 72, holes_read: 18)
    return PostScan(courseName: "Papago", date: "2026-08-22", parRow: Array(repeating: 4, count: 18), players: players == 1 ? [me] : [me, other])
  }

  @Test func applyFlipsToTheGridAndParsTheUnread() {
    var c = PostCard()
    let misses = scan(players: 2).apply(row: 0, to: &c)
    #expect(misses == 2)
    #expect(c.mode == .holes && c.side == 18 && c.touched)
    #expect(c.scores[3] == 4 && c.scores[0] == 5)
    #expect(c.course == "Papago" && c.date == "2026-08-22")
    #expect(c.scan?.others.count == 1 && c.scan?.others.first?.name == "Ed")
    #expect(PostScan.readToast(misses: 2) == "Card read — 2 holes I couldn’t make out are set to par")
    #expect(PostScan.readToast(misses: 0) == "Card read — check the grid, then post")
  }

  @Test func aFrontNineOnlyCardIsANine() {
    var c = PostCard()
    var s = scan()
    s.players[0].holes = Array(repeating: 5, count: 9) + Array(repeating: 0, count: 9)
    s.apply(row: 0, to: &c)
    #expect(c.side == 9)
  }

  @Test func aTypedCourseIsNotOverwritten() {
    var c = PostCard(); c.course = "Encanto"
    scan().apply(row: 0, to: &c)
    #expect(c.course == "Encanto")
  }

  @Test func accuracyCountsWhatTheGolferFixed() {
    var read = Array(repeating: 5, count: 18); read[3] = 0
    var scores = read; scores[3] = 4; scores[0] = 6
    let a = PostScan.accuracy(read: read, scores: scores)
    #expect(a.fixed == 1 && a.misses == 1)
  }

  @Test func decodesTheFunctionsPayload() {
    let json: JSONValue = .object(["ok": .bool(true), "scan": .object([
      "course_name": .string("Papago"), "date": .null, "par_row": .array((0..<18).map { _ in .number(4) }),
      "players": .array([.object(["name": .string("J"), "holes": .array((0..<18).map { _ in .number(5) }), "total": .number(90), "holes_read": .number(18)])]),
    ])])
    let s = PostScan(json: json)!
    #expect(s.players.count == 1 && s.players[0].holes.count == 18 && s.date == nil)
    #expect(PostScan(json: .object(["ok": .bool(true), "scan": .object(["players": .array([])])])) == nil)
  }
}

@Suite struct PostCeremonyTests {
  let season = Me.Season(id: UUID(), number: 1, starts_on: "2026-05-03", ends_on: "2026-09-26", status: "active", timezone: nil, grace_hours: nil,
                         champion_squad_id: nil, champion_member_id: nil, points_king_member_id: nil, tiebreak_rung: nil)

  @Test func countsOnlyInsideTheWindow() {
    #expect(PostSeasonRule.counts(playedOn: "2026-08-22", season: season, hasLeague: true))
    #expect(!PostSeasonRule.counts(playedOn: "2026-04-22", season: season, hasLeague: true))
    #expect(!PostSeasonRule.counts(playedOn: "2026-08-22", season: season, hasLeague: false))
    #expect(!PostSeasonRule.counts(playedOn: "2026-08-22", season: nil, hasLeague: true))
  }

  @Test func goldOnlyWhenEarned() {
    let earned = PostCeremony(course: "Papago", date: "2026-08-22", gross: 84, vs: 2.4, points: 9, squad: "The Pines", inLeague: true, name: "J", marker: "saguaro", leagueName: "PIGL")
    #expect(earned.earned && earned.pointsLine == "+9 PTS · COUNTS FOR THE PINES")
    #expect(earned.eyebrow == "PAPAGO · SAT AUG 22")
    #expect(earned.band == "beat your number by 2.4")
    let solo = PostCeremony(course: "Papago", date: "2026-08-22", gross: 84, vs: 2.4, points: 9, squad: nil, inLeague: true, name: "J", marker: "saguaro", leagueName: nil)
    #expect(solo.pointsLine == "+9 PTS · COUNTS THIS SEASON")
    let card = PostCeremony(course: "", date: "2026-08-22", gross: 84, vs: -71.6, points: nil, squad: nil, inLeague: false, name: "J", marker: "saguaro", leagueName: nil)
    #expect(!card.earned && card.pointsLine == "COUNTS ON YOUR CARD" && card.band == "" && card.eyebrow == "A ROUND · SAT AUG 22")
  }

  @Test func theRecapSpeaksInTheThirdPerson() {
    let r = PostRecap(name: "Jerecho", marker: "saguaro", gross: 84, pvi: 2.4, points: 9, course: "Papago", date: "2026-08-22", badge: nil)
    #expect(r.bandLine == "BEAT THEIR NUMBER" && r.vsLine == "beat their number by 2.4")
    #expect(r.whenLine == "SAT · AUG 22 · 9 PTS")
    #expect(r.caption == "84 at Papago — beat their number by 2.4 · 9 pts · cupseason.app")
    let bare = PostRecap(name: "", marker: "saguaro", gross: 99, pvi: -71.6, points: nil, course: "", date: "2026-08-22", badge: nil)
    #expect(bare.nameLine == "A GOLFER" && bare.bandLine == nil && bare.caption == "99 at the course · cupseason.app")
  }
}

@Suite struct PostEpilogueTests {
  @Test func rowsNameAFeeling() {
    let e = PostEpilogue(gross: 84, pvi: 2.4, points: 9, monthRank: 2,
                         earned: [.init(kind: "sub_90", label: nil), .init(kind: "weird", label: "A thing")],
                         rivals: [.init(name: "Ed", wins: 3, losses: 1, ties: 1, lead: "up", rivalryName: "The Feud")])
    let rows = e.rows(cap: 4, firstEver: false)
    #expect(rows.count == 4)
    #expect(rows[0] == .line(icon: "⛳", title: "Beat your number · 9 pts", sub: "beat your number by 2.4 · counts #2 this month"))
    #expect(rows[1] == .line(icon: "🏆", title: "You broke 90 for the first time", sub: "Pinned to your card"))
    #expect(rows[2] == .line(icon: "✦", title: "A thing", sub: "Pinned to your card"))
    #expect(rows[3] == .line(icon: "⚔️", title: "You lead Ed 3–1 all-time · 1 halved", sub: "“The Feud” · your clash this week counted"))
  }

  @Test func countingCopy() {
    #expect(PostEpilogue.counting(rank: 5, cap: 4) == " · outside your best 4 this month, for now")
    #expect(PostEpilogue.counting(rank: 5, cap: nil) == " · counts this month")
    #expect(PostEpilogue.counting(rank: nil, cap: 4) == "")
  }

  @Test func nothingToSayUnlessFirstEver() {
    let quiet = PostEpilogue(gross: 84, pvi: nil, points: nil, monthRank: nil)
    #expect(quiet.rows(cap: 4, firstEver: false).isEmpty)
    let first = quiet.rows(cap: 4, firstEver: true)
    #expect(first.count == 1 && first[0] == .line(icon: "🎉", title: "Your first round is on the board", sub: "Welcome to the season — your number and record start here"))
    #expect(PostEpilogue.title(firstEver: true) == "Welcome to the season ⛳")
    #expect(quiet.subtitle(course: "Papago") == "84 at PAPAGO" && quiet.subtitle(course: nil) == "THE ROUND, FOR YOU FIRST")
    #expect(PostEpilogue.linkText(name: "Jerecho", gross: 84, course: nil) == "Jerecho — 84 at the course")
  }

  @Test func parsesTheRpc() {
    let json: JSONValue = .object(["gross": .number(84), "pvi": .number(2.4), "points": .number(9), "month_rank": .number(1),
                                   "earned": .array([.object(["kind": .string("personal_best")])]),
                                   "rivals": .array([.object(["name": .string("Ed"), "wins": .number(1), "losses": .number(2), "ties": .number(0), "lead": .string("down")])])])
    let e = PostEpilogue(json: json)!
    #expect(e.gross == 84 && e.earned.first?.kind == "personal_best" && e.rivals.first?.lead == "down")
    #expect(e.rows(cap: nil, firstEver: false)[2] == .line(icon: "⚔️", title: "Ed leads you 2–1 all-time", sub: "Your clash this week counted"))
    #expect(PostEpilogue(json: .null) == nil)
  }
}
