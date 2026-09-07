// Cup Season — the repair pass, as assertions (D254 / IOS-037).
//
// Every one of these is a defect a photograph or a review found in waves 0–9
// and a rule that had nothing holding it. A fix with no test is the same
// sentence-with-no-lint D249 is about.

import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct RepairPassTests {

  // MARK: - F-2 · the deck and the wire cannot tell one round twice

  /// Fixtures come off JSON for the same reason the fallback suite's do: these
  /// are payload types with long initialisers, and a decoder is the shape the
  /// client actually meets.
  private func decode<T: Decodable>(_ t: T.Type, _ json: String) throws -> T {
    let d = JSONDecoder()
    d.dateDecodingStrategy = .iso8601
    return try d.decode(t, from: Data(json.utf8))
  }

  private func story(_ round: UUID, who: String = "Galen") -> HomeDispatch.Item {
    .init(key: "story:\(round.uuidString)", tier: .circle, subject: who, humanSubject: true,
          eyebrow: "AROUND YOUR BUDDIES", headline: "\(who) posted 79 at Lone Tree Golf Club.",
          standfirst: "A personal best.", action: "See the round", route: .receipt(round))
  }

  @Test("the arrangement publishes the ROUNDS it spent, off what the item already carries")
  func theArrangementNamesItsSpentRounds() {
    let a = UUID(), b = UUID()
    let r = HomeRank.arrange([story(a), story(b, who: "Dev")], useServerRank: false)
    #expect(r.spentRounds == [a, b])
    // and the two ways an item can name its round both work: the door…
    #expect(HomeRank.spentRound(story(a)) == a)
    // …and the `story:<round>` key both producers mint, with no door at all
    let keyed = HomeDispatch.Item(key: "story:\(b.uuidString)", tier: .circle, eyebrow: "X", headline: "Y")
    #expect(HomeRank.spentRound(keyed) == b)
    // an item that names no round names none
    #expect(HomeRank.spentRound(.init(key: "first_round", tier: .opportunity, eyebrow: "X", headline: "Y")) == nil)
  }

  @Test("A-6's own worked example: the wire drops the round the deck already told")
  func theWireYieldsToTheDeck() {
    let spent = UUID(), other = UUID()
    let rows: [HomeItem] = [
      .round(try! feedRow(spent, "Galen", 79, "2026-08-23"), photoURL: nil),
      .round(try! feedRow(other, "Dev", 84, "2026-08-24"), photoURL: nil),
    ]
    let all = HomeFeedFold.fold(rows, today: "2026-08-25").flatMap(\.items)
    #expect(all.count == 2)
    let folded = HomeFeedFold.fold(rows, spent: [spent], today: "2026-08-25").flatMap(\.items)
    #expect(folded.count == 1)
    #expect(!folded.contains { if case .round(let r, _) = $0 { return r.round_id == spent }; return false })
  }

  private func feedRow(_ id: UUID, _ who: String, _ gross: Int, _ on: String,
                       pr: Bool = false, createdAt: String? = nil) throws -> HomeFeedRow {
    try decode(HomeFeedRow.self, """
    {"round_id":"\(id.uuidString)","profile_id":"22222222-2222-2222-2222-222222222222",
     "golfer":"\(who)","gross":\(gross),"played_on":"\(on)","course":"Lone Tree Golf Club",
     \(createdAt.map { "\"created_at\":\"\($0)\"," } ?? "")
     "is_pr":\(pr),"is_first":false,"is_sub80":false,"is_me":false}
    """)
  }

  @Test("and the DIGEST yields too — the quiet day reached for the same round")
  func theDigestYieldsToTheDeck() throws {
    let spent = UUID()
    let mark = Date(timeIntervalSince1970: 1_750_000_000)
    let row = try feedRow(spent, "Galen", 79, "2026-08-23", pr: true,
                          createdAt: ISO8601DateFormatter().string(from: mark.addingTimeInterval(-86_400)))
    let now = mark.addingTimeInterval(3600)
    #expect(HomeDigest.make(rounds: [row], posts: [], mark: mark, now: now) != nil)
    #expect(HomeDigest.make(rounds: [row], posts: [], mark: mark, spent: [spent], now: now) == nil)
  }

  // MARK: - R-06 · the declared fallback renders no lead card

  @Test("allowLead is a DIFFERENT question from useServerRank")
  func theFallbackLeadsWithNothing() {
    let items = [story(UUID()), story(UUID(), who: "Dev")]
    #expect(HomeRank.arrange(items, useServerRank: false, allowLead: false).lead == nil)
    #expect(HomeRank.arrange(items, useServerRank: false, allowLead: true).lead != nil)
    // and nothing is lost: every item is still on the screen, in the deck
    #expect(HomeRank.arrange(items, useServerRank: false, allowLead: false).deck.count == 2)
  }

  // MARK: - R-04 · the live item has two faces

  private func meWithLive(_ mine: Bool, host: String? = nil) throws -> Me {
    try decode(Me.self, """
    {"profile":{"id":"33333333-3333-3333-3333-333333333333","display_name":"You"},
     "memberships":[],"invites":[],
     "upcoming_rounds":[],"events":[],"open_duels":[],
     "live_round":{"id":"44444444-4444-4444-4444-444444444444","league_name":"Fellas",
                   "status":"live","course_label":"Papago","mine":\(mine)
                   \(host.map { ",\"host\":\"\($0)\"" } ?? "")}}
    """)
  }

  @Test("a round I started, and a round somebody started WITH me, are two different sentences")
  func theLiveItemHasTwoFaces() throws {
    let a = HomeFallbackItems.make(try meWithLive(true)).first { $0.key.hasPrefix("live:") }
    #expect(a?.headline == "You’re in a live round right now.")
    #expect(a?.action == "Back to the round")
    // LV-09 · "your card" is the person; the holes are the SCORECARD
    #expect(a?.standfirst?.contains("scorecard") == true)
    #expect(a?.standfirst?.contains("the card is open") == false)

    let b = HomeFallbackItems.make(try meWithLive(false), liveHost: "Galen Marek").first { $0.key.hasPrefix("live:") }
    #expect(b?.headline == "Galen started a live round with you.")
    #expect(b?.action == "Join")
    #expect(b?.eyebrow == "JUST TEED OFF · NOTHING SCORED YET")

    // and with no name in hand it still says the TRUE thing, without a subject
    let c = HomeFallbackItems.make(try meWithLive(false)).first { $0.key.hasPrefix("live:") }
    #expect(c?.headline == "Somebody started a live round with you.")
  }

  // MARK: - R-05 · the month minimum reaches the declared fallback

  private func floorMembership(credits: Double, floor: Int, partial: Bool = false, solo: Bool = false) throws -> Me.Membership {
    try decode(Me.Membership.self, """
    {"league_id":"55555555-5555-5555-5555-555555555555","name":"Fellas","phase":"season","role":"player",
     "member_id":"66666666-6666-6666-6666-666666666666",
     "settings":{"structure":"\(solo ? "solo" : "squads2")","buyin_cents":0,"participation_floor":\(floor),
                 "floor_penalty":"deduct","handicap_allowance":95},
     "pulse":{"credits":\(credits),"floor":\(floor),"at_floor":false,"partial":\(partial)}}
    """)
  }

  @Test("the one item with a hard deadline and a real penalty is composable without the ranker")
  func theFloorItemExists() throws {
    // the last three days of September 2026 (the 30th is a Wednesday)
    let m = try floorMembership(credits: 0.5, floor: 2)
    let item = HomeFallbackItems.floorItem(m, today: "2026-09-29", calendar: .current)
    #expect(item?.headline == "You are 1.5 short of the minimum.")
    #expect(item?.action == "Add my round")
    #expect(item?.tier == .closing)
    #expect(item?.eyebrow.hasPrefix("SEPTEMBER CLOSES") == true)

    // …and every guard the retired hero rung carried, kept
    #expect(HomeFallbackItems.floorItem(m, today: "2026-09-04", calendar: .current) == nil)       // not a nag on the 4th
    #expect(HomeFallbackItems.floorItem(try floorMembership(credits: 2, floor: 2), today: "2026-09-29", calendar: .current) == nil)
    #expect(HomeFallbackItems.floorItem(try floorMembership(credits: 0, floor: 2, partial: true), today: "2026-09-29", calendar: .current) == nil)
    // D140 · a solo season has no squads, so no floor can fire
    #expect(HomeFallbackItems.floorItem(try floorMembership(credits: 0, floor: 2, solo: true), today: "2026-09-29", calendar: .current) == nil)
  }

  // MARK: - LV-11 · the champion may be me

  @Test("a golfer who WON does not read their own name in the third person")
  func theChampionMayBeMe() throws {
    func membership(_ mine: Bool) throws -> Me.Membership {
      try decode(Me.Membership.self, """
      {"league_id":"77777777-7777-7777-7777-777777777777","name":"Fellas","phase":"complete","role":"player",
       "member_id":"88888888-8888-8888-8888-888888888888",
       "last_season":{"number":1,"ended_on":"2026-06-01","champion_name":"Galen",
                      "champion_is_me":\(mine),"my_rank":1,"of":8}}
      """)
    }
    #expect(HomeFallbackItems.chapterItem(try membership(false))?.headline == "Galen took the last one.")
    #expect(HomeFallbackItems.chapterItem(try membership(true))?.headline == "You took the last one.")
    // and the rank is an ORDINAL on both paths
    #expect(HomeFallbackItems.chapterItem(try membership(true))?.standfirst == "You finished 1st of 8.")
  }

  // MARK: - F-9 · the verb agrees with its subject

  @Test("a golfer LEADS; a squad LEAD; and the clauses take a full stop")
  func theStoryLineIsASentence() {
    let a = UUID(), b = UUID()
    let solo = StandingsMath.story([Team(id: a, name: "Galen", pts: 30, ci: 0, solo: true),
                                    Team(id: b, name: "Jerecho", pts: 18, ci: 1, solo: true)])
    #expect(solo.text == "Galen leads by 12. Jerecho a good weekend back.")
    let squads = StandingsMath.story([Team(id: a, name: "Reds", pts: 30, ci: 0),
                                      Team(id: b, name: "Blues", pts: 18, ci: 1)])
    #expect(squads.text == "Reds lead by 12. Blues a good weekend back.")
    #expect(!solo.text.contains(" · ") && !squads.text.contains(" · "))
  }

  // MARK: - LV-01 · a forfeit makes no custody promise

  @Test("the forfeit's definition is TERMINOLOGY's, verbatim, and promises nothing structural")
  func theForfeitDefinitionIsRuled() {
    #expect(ForfeitCopy.definition == "A forfeit is a bet for pride. It settles on a tap and goes on the record — never on the books.")
    // L-09 retired the custody claim; no forfeit string may make one
    for s in [ForfeitCopy.definition, ForfeitCopy.noPush, ForfeitCopy.put, ForfeitCopy.title] {
      let l = s.lowercased()
      #expect(!l.contains("keeps no money") && !l.contains("never held") && !l.contains("takes no cut"))
    }
  }

  // MARK: - C-04 / C-03 / C-06 · a consequential write sheds nothing

  @Test("no write on the phone drops an argument on a blind retry")
  func nothingConsequentialIsDroppable() {
    #expect(PostService.PostRoundCall.optionalArgs.isEmpty)          // C-03 · the played date, the hole count, the partners
    #expect(CreateForfeitCall.optionalArgs.isEmpty)                  // C-06
    #expect(RunItBackCall.optionalArgs.isEmpty)                      // C-06
    #expect(DeclarePlanCall.optionalArgs.isEmpty)                    // C-06
    #expect(WizardLockCall.optionalArgs.isEmpty)
    #expect(MyScheduleCall.optionalArgs.isEmpty)
  }

  // MARK: - LV-05 · a golfer's card, named for the golfer

  @Test("the card takes the person's name, and \"Tour Card\" is nowhere in the producer")
  func theCardIsNamedForThePerson() {
    #expect(GolfersRoot.CardName.title("Galen") == "Galen’s card")
    #expect(GolfersRoot.CardName.title(nil) == "A golfer’s card")
    #expect(GolfersRoot.CardName.title("   ") == "A golfer’s card")
    #expect(GolfersRoot.CardName.mine == "Your card")
    #expect(GolfersRoot.CardName.hint("Galen") == "Opens Galen’s card")
    #expect(GolfersRoot.CardName.hint() == "Opens their card")
  }

  // MARK: - F-4 · the ruled heads come from the producer

  @Test("the Golfers tab's heads are R-D's, and none of them carries a count")
  func theGolfersHeadsAreRuled() {
    #expect(GolfersRoot.Section.buddies.head == "YOUR BUDDIES")
    #expect(GolfersRoot.Section.leagueMates.head == "IN YOUR SEASONS")
    for s in GolfersRoot.Section.allCases {
      #expect(!s.head.contains("·"))          // COMPONENT_SYSTEM §574: the rows are the count
      #expect(s.head == s.head.uppercased())
    }
  }

  // MARK: - F-3 · the owner's ruled section heads

  @Test("R-D's two heads ship, and the artifact's replacement does not")
  func theRuledSectionHeadsShip() {
    #expect(CompeteRoot.Head.seasons == "YOUR SEASONS")
    #expect(CompeteRoot.Head.moments == "YOUR MOMENTS")
  }
}

// MARK: - a moment fanned to two leagues is one moment (DF-04)

@Suite struct HomeFeedMomentFoldTests {
  private func moment(_ body: String, round: UUID?, league: UUID, at: Date) -> HomeItem {
    .post(HomePost(id: UUID(), league_id: league, kind: "moment", body: body,
                   created_at: at, round_id: round), leagueName: "A league")
  }

  /// `round_to_board()` fans one round's moment into every league the golfer
  /// belongs to. The wire printed one row per league — the same personal best,
  /// about the same round, told to the same golfer, twice, one row apart.
  @Test func onePersonalBestInTwoLeaguesIsOneWireRow() {
    let round = UUID(), a = UUID(), b = UUID()
    let now = Date()
    let out = HomeFeedFold.fold([moment("Jerecho set a personal best.", round: round, league: a, at: now),
                                 moment("Jerecho set a personal best.", round: round, league: b, at: now)],
                                today: CSDate.today())
    let moments = out.flatMap(\.items).filter { if case .moment = $0 { return true }; return false }
    #expect(moments.count == 1)
  }

  /// Two DIFFERENT rounds are two moments, whatever they say.
  @Test func twoRoundsAreTwoRows() {
    let a = UUID(), b = UUID()
    let now = Date()
    let out = HomeFeedFold.fold([moment("Jerecho set a personal best.", round: UUID(), league: a, at: now),
                                 moment("Jerecho set a personal best.", round: UUID(), league: b, at: now)],
                                today: CSDate.today())
    let moments = out.flatMap(\.items).filter { if case .moment = $0 { return true }; return false }
    #expect(moments.count == 2)
  }
}
