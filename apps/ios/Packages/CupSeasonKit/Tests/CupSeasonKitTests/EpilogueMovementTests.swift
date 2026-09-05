import Testing
import Foundation
@testable import CupSeasonKit

// R7 / IOS-030 · the movement sentence is a COUNT OVER A NAMED READ and
// renders nothing when the read is absent — and the epilogue's one ranked next
// act is chosen by what is true, never by what would sound good.

@Suite struct EpilogueMovementTests {

  // MARK: - the sentence

  @Test func aClimbNamesWhoWasPassed() {
    let m = PostEpilogue.Movement(rankBefore: 4, rankAfter: 2, of: 8, passed: ["Jade", "Dre"], gapToNextAfter: 4)
    #expect(EpilogueMovement.sentence(m) == "That moved you past Jade and Dre into second.")
    // one name, three names — the list reads the way a person says it
    #expect(EpilogueMovement.sentence(PostEpilogue.Movement(rankBefore: 3, rankAfter: 2, of: 8, passed: ["Jade"]))
            == "That moved you past Jade into second.")
    #expect(EpilogueMovement.sentence(PostEpilogue.Movement(rankBefore: 5, rankAfter: 1, of: 8, passed: ["A", "B", "C"]))
            == "That moved you past A, B and C into first.")
  }

  @Test func aClimbWithNobodyNamedStillSaysWhereItLanded() {
    // the count moved but the server named nobody (a tie broken on name, a
    // squads table): say the place, never invent the person
    let m = PostEpilogue.Movement(rankBefore: 3, rankAfter: 2, of: 6, passed: [])
    #expect(EpilogueMovement.sentence(m) == "That moved you into second.")
  }

  @Test func nothingRendersWhenTheReadIsAbsent() {
    // L-44 · a fact with no read renders NOTHING
    #expect(EpilogueMovement.sentence(nil) == nil)
    #expect(EpilogueMovement.sentence(PostEpilogue.Movement(rankBefore: nil, rankAfter: 2, of: 8)) == nil)
    #expect(EpilogueMovement.sentence(PostEpilogue.Movement(rankBefore: 3, rankAfter: nil, of: 8)) == nil)
  }

  @Test func aRoundThatMovedNothingSaysNothing() {
    #expect(EpilogueMovement.sentence(PostEpilogue.Movement(rankBefore: 2, rankAfter: 2, of: 3)) == nil)
    // and a table that says a posted round LOST you a place is a table we do
    // not repeat back to the golfer
    #expect(EpilogueMovement.sentence(PostEpilogue.Movement(rankBefore: 2, rankAfter: 3, of: 8, passed: [])) == nil)
  }

  @Test func theGapClauseOnlyRendersWhenThereIsOne() {
    #expect(EpilogueMovement.gapNote(PostEpilogue.Movement(rankBefore: 3, rankAfter: 2, of: 8, gapToNextAfter: 4)) == "4 back of the row above.")
    #expect(EpilogueMovement.gapNote(PostEpilogue.Movement(rankBefore: 2, rankAfter: 1, of: 8, gapToNextAfter: nil)).isEmpty)
    #expect(EpilogueMovement.gapNote(PostEpilogue.Movement(rankBefore: 2, rankAfter: 1, of: 8, gapToNextAfter: 6)).isEmpty)  // top of the table
    #expect(EpilogueMovement.gapNote(nil).isEmpty)
  }

  // MARK: - the decode, in both deploy orders

  @Test func aPayloadFromBeforeTheMigrationHasNoMovementAtAll() throws {
    // the key is the DIFFERENCE between "nothing moved" and "we did not read
    // it": an old payload must decode to nil, not to a zeroed movement that
    // would render as "held".
    let old = try #require(PostEpilogue(json: .object([
      "gross": .number(84), "pvi": .number(1.1), "points": .number(9), "month_rank": .number(2),
      "earned": .array([]), "rivals": .array([]),
    ])))
    #expect(old.movement == nil)
    #expect(old.playedWith.isEmpty)
    #expect(old.gross == 84 && old.monthRank == 2)
    #expect(EpilogueMovement.sentence(old.movement) == nil)
  }

  @Test func theR7KeysDecodeWhenTheyAreThere() throws {
    let new = try #require(PostEpilogue(json: .object([
      "gross": .number(79), "pvi": .number(3.2), "points": .number(12), "month_rank": .number(1),
      "rank_before": .number(4), "rank_after": .number(2), "of": .number(8),
      "passed": .array([.string("Jade"), .string("Dre")]), "gap_to_next_after": .number(4),
      "played_with": .array([.object(["profile_id": .string(UUID().uuidString.lowercased()),
                                      "name": .string("Galen"), "confirmed": .bool(false),
                                      "shares_season": .bool(false)])]),
    ])))
    #expect(new.movement?.rankBefore == 4 && new.movement?.rankAfter == 2 && new.movement?.of == 8)
    #expect(new.movement?.passed == ["Jade", "Dre"])
    #expect(new.movement?.gapToNextAfter == 4)
    #expect(new.playedWith.count == 1 && new.playedWith[0].name == "Galen")
    #expect(!new.playedWith[0].confirmed && !new.playedWith[0].sharesSeason)
  }

  // MARK: - the one ranked next act (P-3)

  func epilogue(movement: PostEpilogue.Movement? = nil, partners: [PostEpilogue.Partner] = [],
                rivals: [PostEpilogue.Rival] = [], monthRank: Int? = nil, pvi: Double? = 1.1) -> PostEpilogue {
    PostEpilogue(gross: 84, pvi: pvi, points: 9, monthRank: monthRank, earned: [], rivals: rivals,
                 movement: movement, playedWith: partners)
  }

  @Test func theClashOutranksEverything() {
    let act = PostNextAct.choose(epilogue(movement: .init(rankBefore: 4, rankAfter: 2, of: 8, passed: ["Jade"])),
                                 context: .init(clashOpponent: (name: "Galen", id: UUID(), weeksRunning: 2)))
    #expect(act.key == "clash")
    #expect(act.sentence == "That takes the clash. Second week running.")
    #expect(act.label == "See the head-to-head")
  }

  @Test func theMovementIsTheSecondRungAndCarriesTheTablesDoor() {
    let season = UUID()
    let act = PostNextAct.choose(epilogue(movement: .init(rankBefore: 3, rankAfter: 2, of: 8, passed: ["Jade"])),
                                 seasonId: season, context: .init())
    #expect(act.key == "movement")
    #expect(act.sentence == "That moved you past Jade into second.")
    #expect(act.door == .table(season))
  }

  @Test func aPartnerWithNoSharedSeasonIsOfferedOne() {
    let galen = UUID()
    let p = PostEpilogue.Partner(profileId: galen, name: "Galen", confirmed: false, sharesSeason: false)
    let act = PostNextAct.choose(epilogue(partners: [p]),
                                 context: .init(roundsTogetherThisMonth: [galen: 4]))
    #expect(act.key == "partner_new")
    #expect(act.sentence == "Galen was out there too. Four rounds between you this month — four is a season.")
    #expect(act.door == .seasonWith(galen, "Galen"))
    // the count is a read: without it the sentence does not invent one
    let thin = PostNextAct.choose(epilogue(partners: [p]), context: .init())
    #expect(thin.sentence == "Galen was out there too. Make the next one count.")
  }

  @Test func makeTheNextOneCountAppearsInExactlyOneRung() {
    // P-3's own check: the phrase means one thing because it is said once
    var seen = 0
    for act in everyRung() where act.sentence.contains("Make the next one count") { seen += 1 }
    #expect(seen == 1)
  }

  @Test func eightRungsEightDistinctSentences() {
    let acts = everyRung()
    #expect(acts.count == 8)
    #expect(Set(acts.map(\.sentence)).count == 8)
    #expect(Set(acts.map(\.key)).count == 8)
    // every one of them ends in a next move (L-32) — a label, never a blank
    #expect(acts.allSatisfy { !$0.label.isEmpty })
  }

  @Test func aSharedSeasonReadsTheRecordAndAThinOneDoesNot() {
    let galen = UUID()
    let p = PostEpilogue.Partner(profileId: galen, name: "Galen", confirmed: true, sharesSeason: true)
    let r = PostEpilogue.Rival(name: "Galen", wins: 5, losses: 6, ties: 0, lead: "down", rivalryName: nil)
    let act = PostNextAct.choose(epilogue(partners: [p], rivals: [r]), context: .init())
    #expect(act.key == "partner_record")
    #expect(act.sentence == "You and Galen have played eleven together. Galen leads 6.")
    #expect(act.door == .record(galen))
    // with no rivalry read the rung says only what it knows
    let thin = PostNextAct.choose(epilogue(partners: [p]), context: .init())
    #expect(thin.key == "partner_seen" && thin.sentence == "Galen was out there too.")
  }

  @Test func theLeaguelessRungsCountRatherThanGuess() {
    let buddies = PostNextAct.choose(epilogue(), context: .init(leagueless: true, buddiesPlayedThisWeek: 3))
    #expect(buddies.key == "leagueless_buddies")
    #expect(buddies.sentence == "Three of yours played this week. Nobody is playing for anything.")
    #expect(buddies.door == .startSomething)

    let third = PostNextAct.choose(epilogue(), context: .init(leagueless: true, roundsCount: 3))
    #expect(third.sentence == "That is your third. Your number goes live now.")

    let second = PostNextAct.choose(epilogue(), context: .init(leagueless: true, roundsCount: 2))
    #expect(second.sentence == "That is your second. One more and your number goes live.")

    // no count read at all: the rung does not fire and the ladder falls through
    let none = PostNextAct.choose(epilogue(), context: .init(leagueless: true))
    #expect(none.door == .done)
  }

  @Test func theEighthRungIsAlwaysATrueSentence() {
    let counting = PostNextAct.choose(epilogue(monthRank: 2), context: .init(countingCap: 3, monthName: "September"))
    #expect(counting.sentence == "That is two of your best three in September.")
    #expect(counting.label == "Done")

    // a round the engine could score nothing for says so, and does not compute
    // a points figure from a lens nobody has (V-3)
    let noPoints = PostNextAct.choose(epilogue(pvi: nil), context: .init())
    #expect(noPoints.sentence == PostNextAct.noPointsNote)

    // and an epilogue that could not be read at all still ends in a next move
    let nothing = PostNextAct.choose(nil, context: .init())
    #expect(!nothing.sentence.isEmpty && nothing.label == "Done")
  }

  /// One case per rung, in the ladder's own order.
  private func everyRung() -> [PostNextAct] {
    let galen = UUID(), jade = UUID(), event = UUID()
    let stranger = PostEpilogue.Partner(profileId: galen, name: "Galen", confirmed: false, sharesSeason: false)
    let mate = PostEpilogue.Partner(profileId: jade, name: "Jade", confirmed: true, sharesSeason: true)
    return [
      PostNextAct.choose(epilogue(), context: .init(clashOpponent: (name: "Galen", id: galen, weeksRunning: 2))),
      PostNextAct.choose(epilogue(movement: .init(rankBefore: 3, rankAfter: 2, of: 8, passed: ["Jade"])), context: .init()),
      PostNextAct.choose(epilogue(), context: .init(calloutEvent: event, calloutSentence: "You called it. You posted 84.")),
      PostNextAct.choose(epilogue(partners: [stranger]), context: .init()),
      PostNextAct.choose(epilogue(partners: [mate]), context: .init()),
      PostNextAct.choose(epilogue(), context: .init(leagueless: true, buddiesPlayedThisWeek: 3)),
      PostNextAct.choose(epilogue(), context: .init(leagueless: true, roundsCount: 3)),
      PostNextAct.choose(epilogue(monthRank: 2), context: .init(countingCap: 3, monthName: "September")),
    ]
  }
}
