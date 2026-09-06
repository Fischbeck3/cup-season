import Testing
import Foundation
@testable import CupSeasonKit

// IOS-030 · the round is posted by the server, and the direct insert survives
// as the DECLARED FALLBACK. These are the assertions that make that claim
// checkable: the RPC's arguments are the payload the insert wrote, the
// fallback fires on exactly one condition, the eleven columns survive it, the
// D72 nine-versus-eighteen branch is intact, and a hand-typed course carries
// its label — and says what is missing when it has no rating.

@Suite struct PostRoundRpcTests {
  func card(whole: String = "", f9: String = "", b9: String = "",
            rating: String = "71.2", slope: String = "128", side: Int = 18,
            course: String = "Papago Golf Course", courseId: String? = "1234") -> PostCard {
    var c = PostCard()
    c.whole = whole; c.f9 = f9; c.b9 = b9; c.rating = rating; c.slope = slope; c.side = side
    c.course = course; c.courseId = courseId; c.date = "2026-09-05"
    return c
  }

  // MARK: - the RPC's shape

  @Test func theCallIsTheElevenColumnPayloadMinusTheSeason() throws {
    let payload = PostPayload.build(card(whole: "84"), seasonId: nil)
    let call = PostService.PostRoundCall(
      p_gross: payload.gross, p_rating: payload.rating, p_slope: payload.slope,
      p_holes_played: payload.holes_played, p_nine_rating: payload.nine_rating,
      p_course_id: payload.api_course_id, p_course_label: payload.course_label,
      p_played_on: payload.played_on, p_photo_path: payload.photo_path, p_played_with: [])
    let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(call)) as! [String: Any]
    #expect(json["p_gross"] as? Int == 84)
    #expect(json["p_holes_played"] as? Int == 18)
    #expect(json["p_course_label"] as? String == "Papago Golf Course")
    #expect(json["p_played_on"] as? String == "2026-09-05")
    // D229 · no league, no season. The server derives it from the date.
    #expect(json["p_season_id"] == nil && json["p_league_id"] == nil && json["p_league"] == nil)
    // and no tee: it has no counterpart in the payload or in the insert
    #expect(json["p_tee_id"] == nil)
  }

  /// C-03 · a round sheds NOTHING on a blind retry. `SupabaseService.call(_:)`
  /// removes every droppable key at once on ANY first error, so one 500 used to
  /// re-date the round to today (changing the season window it scores in, L-13),
  /// post a nine as an eighteen, and drop the partners and the photo. The skew
  /// that matters — `post_round` not existing — is the DECLARED fallback.
  @Test func nothingIsDroppableOnARound() {
    #expect(PostService.PostRoundCall.optionalArgs.isEmpty)
    #expect(PostService.PostRoundCall.name == "post_round")
  }

  // MARK: - the declared fallback

  @Test func theFallbackFiresOnAMissingFunctionAndOnNothingElse() {
    let missing = RpcError(name: "post_round", underlying: "PGRST202 Could not find the function", droppedArgs: [])
    let older = RpcError(name: "post_round", underlying: "42883 function does not exist", droppedArgs: [])
    let cached = RpcError(name: "post_round", underlying: "searched the schema cache", droppedArgs: [])
    #expect(PostService.fallbackFires(on: missing))
    #expect(PostService.fallbackFires(on: older))
    #expect(PostService.fallbackFires(on: cached))
    // a refused round is a REAL error and must reach the golfer, not quietly
    // take the old path and post anyway
    let refused = RpcError(name: "post_round", underlying: "23514 rounds_rating_sane", droppedArgs: [])
    #expect(!PostService.fallbackFires(on: refused))
    #expect(!PostService.fallbackFires(on: URLError(.notConnectedToInternet)))
  }

  @Test func theFallbacksInsertKeepsAllElevenColumns() throws {
    var payload = PostPayload.build(card(whole: "84"), seasonId: UUID())
    payload.photo_path = "abc/def.jpg"
    let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(payload)) as! [String: Any]
    // the insert this replaces wrote eleven columns; the fallback still does.
    // (`nine_rating` encodes as ABSENT on an eighteen — that is the payload's
    // own rule and the server's default depends on it.)
    for key in ["gross", "rating", "slope", "holes_played", "source", "played_on",
                "course_label", "api_course_id", "season_id", "photo_path"] {
      #expect(json[key] != nil, "the fallback's insert dropped \(key)")
    }
    #expect(json["source"] as? String == "quick")
    let nine = try JSONSerialization.jsonObject(with: JSONEncoder().encode(PostPayload.build(card(f9: "41"), seasonId: nil))) as! [String: Any]
    #expect(nine["nine_rating"] != nil)
  }

  // MARK: - D72, through the one box

  @Test func theOneBoxIsEighteenAndOneNineIsStillANine() {
    // the composer asks one number, and on eighteen that number is the round
    let whole = PostPayload.build(card(whole: "84"), seasonId: nil)
    #expect(whole.gross == 84 && whole.holes_played == 18 && whole.nine_rating == nil)

    // the nines survive underneath it, on the rules they always had
    let both = PostPayload.build(card(f9: "41", b9: "43"), seasonId: nil)
    #expect(both.gross == 84 && both.holes_played == 18 && both.nine_rating == nil)

    let one = PostPayload.build(card(f9: "41"), seasonId: nil)
    #expect(one.gross == 41 && one.holes_played == 9)
    #expect(abs((one.nine_rating ?? 0) - 35.6) < 0.001)   // an 18-hole rating, halved

    var realNine = card(f9: "41", rating: "35.6", side: 9); realNine.rating9 = true
    let nine = PostPayload.build(realNine, seasonId: nil)
    #expect(nine.holes_played == 9 && abs((nine.nine_rating ?? 0) - 35.6) < 0.001)   // sent straight
  }

  @Test func theOneBoxStandsDownWhenTheNinesAreCarryingTheCard() {
    // both entered = THE CARD wins, so one round never has two answers (L-34),
    // and the hero shows the same number it will post
    var c = card(whole: "84", f9: "41", b9: "45")
    #expect(c.entry?.gross == 86 && c.entry?.holes == 18)
    c.mode = .holes
    c.scores = Array(repeating: 5, count: 18)
    c.touched = true
    #expect(c.entry?.gross == 90 && c.entry?.holes == 18)   // the grid
    // and with the card empty the box is the round
    let box = card(whole: "84")
    #expect(box.entry?.gross == 84 && box.entry?.holes == 18)
  }

  // MARK: - a hand-typed course

  @Test func aHandTypedCoursePostsAndCarriesItsLabel() {
    let typed = card(whole: "88", course: "Muni down the road", courseId: nil)
    let payload = PostPayload.build(typed, seasonId: nil)
    #expect(payload.course_label == "Muni down the road")
    #expect(payload.api_course_id == nil)
    #expect(PostCalc.blocked(typed) == nil)
  }

  @Test func aCourseWithNoRatingSaysWhichFieldIsMissing() {
    // PP-01 · it used to preview a differential off a rating of zero and let
    // the golfer press Post on a round the database would refuse.
    let noRating = card(whole: "88", rating: "", slope: "", course: "Muni down the road", courseId: nil)
    #expect(PostCalc.blocked(noRating) == .noRating)
    #expect(PostCalc.blocked(noRating)?.message == PostCalc.noRatingMessage)
    #expect(PostCalc.blocked(noRating)?.reason == "no_rating")
    #expect(PostCalc.preview(noRating, myIndex: 12.4) == nil)
    // an empty card is a DIFFERENT sentence
    #expect(PostCalc.blocked(card()) == .noCard)
    #expect(PostCalc.blocked(card())?.message == "Enter your gross first")
    // and a slope nobody could have read off a card is refused too
    #expect(PostCalc.blocked(card(whole: "88", slope: "9")) == .noRating)
  }

  // MARK: - what comes back

  @Test func theOutcomeReadsTheServersAnswer() throws {
    let id = UUID(), season = UUID()
    let json = JSONValue.object([
      "round": .object([
        "id": .string(id.uuidString.lowercased()),
        "season_id": .string(season.uuidString.lowercased()),
        "league_name": .string("Fellas"), "squad": .string("Mudsharks"),
        "counts": .bool(true), "tagged": .number(1),
      ]),
      "epilogue": .object(["gross": .number(84), "rank_before": .number(3), "rank_after": .number(2)]),
    ])
    let out = try #require(PostService.PostOutcome(json: json))
    #expect(out.roundId == id && out.seasonId == season)
    #expect(out.leagueName == "Fellas" && out.squad == "Mudsharks")
    #expect(out.counts && out.tagged == 1 && !out.viaFallback)
    #expect(out.epilogue?.movement?.rankAfter == 2)
  }

  @Test func anAnswerWithNoRoundIdIsNotAPostedRound() {
    // never tell a golfer their round posted when we cannot name it
    #expect(PostService.PostOutcome(json: .object(["round": .object([:])])) == nil)
    #expect(PostService.PostOutcome(json: .object([:])) == nil)
    #expect(PostService.PostOutcome(json: .string("ok")) == nil)
  }

  @Test func anOlderServerAnswersWithFewerKeysAndTheOutcomeStillHolds() throws {
    let id = UUID()
    let out = try #require(PostService.PostOutcome(json: .object([
      "round": .object(["id": .string(id.uuidString.lowercased())]),
    ])))
    #expect(out.roundId == id)
    #expect(out.seasonId == nil && !out.counts && out.epilogue == nil && out.tagged == 0)
  }

  // MARK: - D229 · the allowance the composer previews at

  @Test func theAllowanceComesFromTheDateNotFromWhatHomeWasShowing() throws {
    let a = try membership(name: "Fellas", starts: "2026-07-20", ends: "2026-12-06", status: "active", allowance: 95)
    let b = try membership(name: "The Pines", starts: "2026-01-01", ends: "2026-03-01", status: "complete", allowance: 100)
    // a round played in September belongs to the season whose window holds it,
    // whichever league the golfer happened to be looking at
    #expect(PostSeasonRule.membership(playedOn: "2026-09-05", memberships: [b, a])?.name == "Fellas")
    #expect(PostSeasonRule.membership(playedOn: "2026-02-01", memberships: [a, b])?.name == "The Pines")
    // outside every window there is no membership and no allowance — 100 %
    #expect(PostSeasonRule.membership(playedOn: "2026-06-01", memberships: [a, b]) == nil)
  }

  private func membership(name: String, starts: String, ends: String, status: String, allowance: Int) throws -> Me.Membership {
    let json = """
    {"league_id":"\(UUID().uuidString)","name":"\(name)","phase":"active","role":"member",
     "member_id":"\(UUID().uuidString)",
     "settings":{"handicap_allowance":\(allowance),"preset":"standard","verification":"honor",
                 "participation_floor":0,"floor_penalty":"none","season_format":"solo","buyin_cents":0},
     "season":{"id":"\(UUID().uuidString)","starts_on":"\(starts)","ends_on":"\(ends)","status":"\(status)"}}
    """
    return try JSONDecoder().decode(Me.Membership.self, from: Data(json.utf8))
  }
}
