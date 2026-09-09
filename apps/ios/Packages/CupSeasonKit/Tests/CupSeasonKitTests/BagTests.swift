// D262 / R-O · what's in the bag.
//
// The half a screenshot cannot prove: the payload's honesty rules (a bag that
// did not load is not an empty bag; a `beat` figure that never arrived is not
// zero), the sentence the whole feature exists for, and the two refusals —
// the fourteen and the acronym.

import Foundation
import Testing
@testable import CupSeasonKit

@Suite struct BagTests {

  private func parse(_ json: String) throws -> Bag {
    Bag.parse(try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8)))
  }

  // MARK: - the payload

  @Test("a bag_of payload becomes a bag, and a row with no label is dropped")
  func decodesThePayload() throws {
    let bag = try parse("""
    {"visible":true,"is_me":true,
     "clubs":[{"id":"4E4D2C6E-0000-0000-0000-000000000001","slot":"Driver","label":"TSR3 9° · Ventus Blue","added_on":"2026-07-01"},
              {"id":"4E4D2C6E-0000-0000-0000-000000000002","slot":null,"label":"Newport 2","added_on":"2026-01-04"},
              {"id":"4E4D2C6E-0000-0000-0000-000000000003","slot":"5-wood"}],
     "sideline":[{"id":"4E4D2C6E-0000-0000-0000-000000000004","slot":"3-iron","label":"P790","added_on":"2026-02-02","removed_on":"2026-07-01"}],
     "ball":{"id":"4E4D2C6E-0000-0000-0000-000000000005","label":"Pro V1","added_on":"2026-07-01"},
     "since":{"slot":"Driver","label":"TSR3 9° · Ventus Blue","added_on":"2026-07-01","rounds":4,"beat":2}}
    """)
    #expect(bag.visible && bag.isMe)
    #expect(bag.clubs.count == 2)                       // the label-less row is DROPPED, never defaulted
    #expect(bag.clubs.first?.line == "Driver · TSR3 9° · Ventus Blue")
    #expect(bag.clubs.last?.line == "Newport 2")        // no slot, no separator hanging off it
    #expect(bag.sideline.first?.removedOn == "2026-07-01")
    #expect(bag.ball?.label == "Pro V1")
    #expect(bag.since?.rounds == 4 && bag.since?.beat == 2)
    #expect(!bag.isEmpty)
  }

  @Test("two brand-new rows are two rows — identity is local, never the server's nil")
  func newRowsAreDistinct() {
    let a = Bag.Item(label: "")
    let b = Bag.Item(label: "")
    #expect(a.id != b.id)
    #expect(a.serverId == nil && b.serverId == nil)
  }

  @Test("an invisible card is an invisible bag, and it is not an empty one")
  func invisibleIsNotEmpty() throws {
    let bag = try parse(#"{"visible":false}"#)
    #expect(!bag.visible)
    // the surfaces branch on `visible` FIRST; nothing may read the lists of a
    // card it was not allowed to see
    #expect(bag.clubs.isEmpty && bag.sideline.isEmpty && bag.ball == nil)
  }

  @Test("a since block with no rounds behind it is not a since block")
  func sinceNeedsRounds() throws {
    let bag = try parse("""
    {"visible":true,"is_me":true,"clubs":[],"sideline":[],
     "since":{"slot":"Driver","label":"TSR3","added_on":"2026-09-01","rounds":0,"beat":null}}
    """)
    #expect(bag.since == nil)
  }

  @Test("beat is null, not zero, when no season has scored the rounds")
  func beatCanBeAbsent() throws {
    let bag = try parse("""
    {"visible":true,"is_me":true,"clubs":[],"sideline":[],
     "since":{"slot":"Driver","label":"TSR3","added_on":"2026-07-01","rounds":4,"beat":null}}
    """)
    let since = try #require(bag.since)
    #expect(since.beat == nil)
    // the sentence stops after the rounds rather than claiming a zero
    #expect(BagCopy.sinceLine(since) == "Since the new driver went in: four rounds.")
  }

  // MARK: - the sentence R-O asked for

  @Test("since the new driver went in: four rounds, two beat your playing HCP")
  func theLine() {
    let s = Bag.Since(slot: "Driver", label: "TSR3 9°", addedOn: "2026-07-01", rounds: 4, beat: 2)
    #expect(BagCopy.sinceLine(s) == "Since the new driver went in: four rounds, two beat your playing HCP.")
    // R-M · the noun is the playing HCP, and the acronym keeps its case
    #expect(BagCopy.sinceLine(s).contains("playing HCP"))
    #expect(!BagCopy.sinceLine(s).contains("playing hcp"))
    // somebody else's page turns the possessive over through the one producer
    #expect(BagCopy.sinceLine(s, isMe: false)
            == "Since the new driver went in: four rounds, two beat their playing HCP.")
  }

  @Test("one round is one round, and none of them is said plainly")
  func theLineDegrades() {
    #expect(BagCopy.sinceLine(Bag.Since(slot: nil, label: "A club", addedOn: "2026-07-01", rounds: 1, beat: 1))
            == "Since the new club went in: one round, one beat your playing HCP.")
    #expect(BagCopy.sinceLine(Bag.Since(slot: "3-wood", label: "TSi2", addedOn: "2026-07-01", rounds: 6, beat: 0))
            == "Since the new 3-wood went in: six rounds, none of them beat your playing HCP.")
  }

  @Test("the slot lower-cases like a word and never like an acronym")
  func theWord() {
    #expect(BagCopy.word("Driver") == "driver")
    #expect(BagCopy.word("3-Wood") == "3-wood")
    #expect(BagCopy.word("TSR3") == "TSR3")     // the R-M lesson, in one line
    #expect(BagCopy.word(nil) == "club")
    #expect(BagCopy.word("   ") == "club")
  }

  // MARK: - the summary on the You door

  @Test("the door says what is in the bag, or what a bag is")
  func theSummary() {
    let empty = Bag(visible: true, isMe: true)
    #expect(BagCopy.summary(empty) == BagCopy.noneYet)
    let full = Bag(visible: true, isMe: true,
                   clubs: (1...13).map { Bag.Item(label: "club \($0)") },
                   sideline: [Bag.Item(label: "P790")],
                   ball: Bag.Item(label: "Pro V1"))
    #expect(BagCopy.summary(full) == "13 clubs · 1 on the sideline · Pro V1")
    let one = Bag(visible: true, isMe: true, clubs: [Bag.Item(label: "Newport 2")])
    #expect(BagCopy.summary(one) == "1 club")
  }

  // MARK: - what goes out on the wire

  @Test("a write carries the server's id, trims what the golfer typed, and blanks an empty slot")
  func theWrite() {
    let item = Bag.Item(serverId: UUID(uuidString: "4E4D2C6E-0000-0000-0000-000000000001"),
                        slot: "  ", label: "  TSR3 9°  ")
    let w = BagWrite(item)
    #expect(w.id == "4E4D2C6E-0000-0000-0000-000000000001")
    #expect(w.slot == nil)
    #expect(w.label == "TSR3 9°")
  }

  @Test("a nil list is absent from the payload — absent means LEAVE IT ALONE, [] means empty it")
  func nilListIsAbsent() throws {
    let call = SaveBagCall(p_clubs: nil, p_sideline: [], p_ball: nil, p_ball_set: false)
    let obj = try JSONSerialization.jsonObject(with: JSONEncoder().encode(call)) as? [String: Any]
    let keys = Set((obj ?? [:]).keys)
    #expect(!keys.contains("p_clubs"))         // absent → the SQL default → untouched
    #expect(keys.contains("p_sideline"))       // present and empty → emptied
    #expect(keys.contains("p_ball_set"))
  }

  @Test("neither call drops an argument on a retry")
  func noDroppableArguments() {
    // Dropping `p_profile` would read MY bag and render it under somebody
    // else's name; dropping `p_ball_set` would silently discard a ball the
    // golfer had just typed. A missing function is not fixed by asking again.
    #expect(BagOfCall.optionalArgs.isEmpty)
    #expect(SaveBagCall.optionalArgs.isEmpty)
    #expect(BagOfCall.name == "bag_of" && SaveBagCall.name == "save_bag")
  }

  @Test("fourteen is the cap, and it is the Rules' number")
  func theCap() {
    #expect(BagCopy.cap == 14)
  }
}

// MARK: - D312 · the door the bag never had

@Suite struct BagDoorTests {
  private func post(kind: String, profile: UUID? = nil, round: UUID? = nil,
                    live: UUID? = nil, scheduled: UUID? = nil) -> HomePost {
    HomePost(id: UUID(), league_id: nil, kind: kind, body: "x", created_at: Date(),
             live_round_id: live, round_id: round, scheduled_round_id: scheduled,
             profile_id: profile)
  }

  /// **THE LINE THAT COULD NOT BE TAPPED.** A wire row opened only if it knew a
  /// ROUND, and a bag change knows a PERSON — so "You made ten changes to the
  /// bag" was unclickable by construction, not by oversight.
  @Test func aBagPostOpensThatGolfersBag() {
    let me = UUID()
    #expect(HomeFeedFold.door(for: post(kind: "bag", profile: me)) == .bag(me))
  }

  /// The kind is the check, never the presence of `profile_id`. A MILESTONE
  /// homed on the same person is about a round, and a door to their bag would
  /// be a door to the wrong object.
  @Test func onlyABagPostOpensABag() {
    let me = UUID()
    #expect(HomeFeedFold.door(for: post(kind: "moment", profile: me)) == nil)
    #expect(HomeFeedFold.door(for: post(kind: "system", profile: me)) == nil)
    // and a bag post with no profile has nowhere to lead
    #expect(HomeFeedFold.door(for: post(kind: "bag")) == nil)
  }

  /// The round ids keep their order (D219). A post that somehow knows both is
  /// about the round, because the round is the thing that happened.
  @Test func aRoundOutranksTheBag() {
    let me = UUID(), round = UUID(), live = UUID()
    #expect(HomeFeedFold.door(for: post(kind: "bag", profile: me, round: round)) == .round(round))
    #expect(HomeFeedFold.door(for: post(kind: "bag", profile: me, round: round, live: live)) == .live(live))
  }
}

// MARK: - D315 · the strip yields to a competition lead

@Suite struct StripYieldTests {
  private func slot(_ f: MeStripCopy.Fact, _ v: String) -> MeStripCopy.Slot {
    MeStripCopy.Slot(fact: f, label: f.rawValue, value: v,
                     door: .yourCard, voiceOver: "\(f.rawValue), \(v)", isPlaceholder: false)
  }

  /// The survivor is the NEXT TEE — the only forward-looking fact, and the only
  /// one that is a plan rather than a placing.
  @Test func theNextTeeSurvives() {
    let strip = MeStripCopy.Strip(
      slots: [slot(.myNumber, "12.1"), slot(.myMoney, "+$40"),
              slot(.myNextRound, "Sat 7:40"), slot(.myLastRound, "84")],
      seasonRow: nil)
    #expect(strip.leading.slots.map(\.fact) == [.myNextRound])
    // demoted, NEVER dropped — the money slot in particular carries a debt
    #expect(Set(strip.trailing.slots.map(\.fact)) == [.myNumber, .myMoney, .myLastRound])
  }

  /// **A PREFERENCE, NOT A MANDATE.** A golfer with nothing scheduled has no
  /// next tee, and the rule falls to the next fact rather than printing none.
  @Test func withNoTeeTimeItFallsThrough() {
    let strip = MeStripCopy.Strip(
      slots: [slot(.myMoney, "+$40"), slot(.myNumber, "12.1")], seasonRow: nil)
    #expect(strip.leading.slots.map(\.fact) == [.myNumber])
    #expect(strip.trailing.slots.map(\.fact) == [.myMoney])
  }

  /// One slot is already one voice — nothing to yield, and nothing sinks.
  @Test func aSingleSlotIsUntouched() {
    let strip = MeStripCopy.Strip(slots: [slot(.myNumber, "12.1")], seasonRow: nil)
    #expect(strip.leading.slots.count == 1)
    #expect(strip.trailing.isEmpty)
  }

  /// The keys are read from the item KEY and never from the prose — reading a
  /// claim out of a headline is a guess (L-44).
  @Test func theCompetitionKeysAreTheRankersOwn() {
    func item(_ key: String) -> HomeDispatch.Item {
      HomeDispatch.Item(key: key, tier: .closing, eyebrow: "e", headline: "x")
    }
    #expect(HomePage.isCompetition(item("clash:abc")))
    #expect(HomePage.isCompetition(item("live:abc")))
    #expect(HomePage.isCompetition(item("firsttee:abc")))
    // a ceremony and the circle are NOT the strip's competition
    #expect(!HomePage.isCompetition(item("chapter:abc")))
    #expect(!HomePage.isCompetition(item("story:abc")))
    #expect(!HomePage.isCompetition(item("runitback:abc")))
    #expect(!HomePage.isCompetition(nil))
  }
}

// MARK: - D311 · a reaction is a word, not a verb

@Suite struct ReactionSentenceTests {
  private func mention(_ key: String?) -> HomeSocial.Mention {
    HomeSocial.Mention(who: "Jade", emoji: key, gross: 90)
  }

  @Test func everyTokenHasItsOwnSentence() {
    #expect(HomeDigest.mention(mention("azalea"), gross: "90") == "Jade gave your 90 its flowers")
    #expect(HomeDigest.mention(mention("jug"), gross: "90") == "Jade raised a glass to your 90")
    #expect(HomeDigest.mention(mention("eagle"), gross: "90") == "Jade circled your 90 twice")
    #expect(HomeDigest.mention(mention("rake"), gross: "90") == "Jade called you a sandbagger on your 90")
  }

  /// A comment is not a reaction, and a token this build cannot read is
  /// neither — it falls to a neutral sentence rather than naming one it guessed.
  @Test func whatIsNotATokenIsNotNamed() {
    #expect(HomeDigest.mention(mention(nil), gross: "90") == "Jade chimed in on your 90")
    #expect(HomeDigest.mention(mention("🔥"), gross: "90") == "Jade reacted to your 90")
  }

  /// **NO GLYPH IS EVER A VERB.** The shape of the old line, asserted against
  /// so it cannot come back through a template.
  @Test func noSentenceInterpolatesAToken() {
    for k in CSReactions.all.map(\.key) + ["🔥", nil].compactMap({ $0 }) {
      let s = HomeDigest.mention(mention(k), gross: "90")
      #expect(!s.contains(k), "the sentence for \(k) printed the token itself")
      #expect(!s.contains("’d your"))
    }
  }
}

// MARK: - D321 · Home is too much

@Suite struct HomeQuietTests {
  private func item(_ key: String, subject: String? = nil, league: UUID? = nil) -> HomeDispatch.Item {
    HomeDispatch.Item(key: key, tier: .closing, subject: subject,
                      eyebrow: "e", headline: "h", leagueId: league)
  }
  private func row(_ p: HomeWirePeriod?) -> HomeWireRow {
    HomeWireRow(id: UUID().uuidString, body: .line(marker: nil, text: "x", door: nil), period: p)
  }

  /// **THE OWNER'S OWN HOME.** The lead was the clash with Galen in Who's the
  /// bitch?, carrying a `2ND OF TWO` chip; the very next row said "You are 4
  /// back of Galen with 7 weeks left" — the standing the chip had just drawn.
  @Test func anItemThatRepeatsTheLeadsSubjectAndLeagueIsAnEcho() {
    let league = UUID()
    let lead = item("clash:1", subject: "Galen", league: league)
    #expect(HomePage.echoesLead(item("need:1", subject: "Galen", league: league), lead: lead))
  }

  /// **BOTH HALVES ARE REQUIRED.** Two leagues can each be about Galen and
  /// those are two facts; a clash and a buddy's round in one league are two
  /// facts too. Only the pair makes them one story.
  @Test func neitherHalfAloneIsAnEcho() {
    let a = UUID(), b = UUID()
    let lead = item("clash:1", subject: "Galen", league: a)
    #expect(!HomePage.echoesLead(item("need:1", subject: "Galen", league: b), lead: lead))
    #expect(!HomePage.echoesLead(item("need:1", subject: "Jade", league: a), lead: lead))
    // half a pair is a guess (L-44)
    #expect(!HomePage.echoesLead(item("need:1", subject: "Galen"), lead: lead))
    #expect(!HomePage.echoesLead(item("need:1", league: a), lead: lead))
    // and with no lead at all nothing echoes
    #expect(!HomePage.echoesLead(item("need:1", subject: "Galen", league: a), lead: nil))
  }

  /// The lead can never suppress itself out of the deck.
  @Test func theLeadIsNotItsOwnEcho() {
    let league = UUID()
    let lead = item("clash:1", subject: "Galen", league: league)
    #expect(!HomePage.echoesLead(lead, lead: lead))
  }

  /// **A HEAD IS FOR A BUCKET, NOT FOR A SENTENCE.** `UP NEXT` and `TODAY`
  /// each held one row on the owner's Home and each got a 24pt head.
  @Test func aPeriodHoldingOneRowGetsNoHead() {
    let rows = [row(.ahead), row(.today), row(.week), row(.week), row(.earlier), row(.earlier), row(.earlier)]
    let headed = HomePage.headedPeriods(rows)
    #expect(!headed.contains(.ahead))
    #expect(!headed.contains(.today))
    #expect(headed.contains(.week))
    #expect(headed.contains(.earlier))
  }

  /// A row filed under no period is not a bucket and cannot summon a head.
  @Test func aLooseRowIsNotABucket() {
    #expect(HomePage.headedPeriods([row(nil), row(nil)]).isEmpty)
    #expect(HomePage.headedPeriods([]).isEmpty)
  }
}

// MARK: - D325 · the signup trigger's guess is not a name

@Suite struct DerivedNameTests {
  /// The m001 trigger writes `display_name` from the email localpart, so the
  /// card gate would arrive pre-filled with a machine value wearing the shape
  /// of an answer. **Eight of thirty-nine production profiles carry one.**
  @Test func aNameThatIsTheEmailIsTheTriggersGuess() {
    #expect(OnboardingGate.isDerivedName("a.golfer", email: "a.golfer@x.com"))
    #expect(OnboardingGate.isDerivedName("agolfer12", email: "agolfer12@x.com"))
    // **THE CASE THE TWO CLIENTS DISAGREED ON.** The desk normalised away every
    // non-alphanumeric; the phone stripped spaces only, so a derived name that
    // lost a dot the email carried pre-filled on the phone and not on the desk.
    #expect(OnboardingGate.isDerivedName("jsmith", email: "j.smith@x.com"))
    #expect(OnboardingGate.isDerivedName("Jerecho Fischbeck", email: "jerechofischbeck@x.com"))
  }

  /// A typed name survives — that is the whole point of the guard being narrow.
  @Test func aRealNameIsNotTheGuess() {
    #expect(!OnboardingGate.isDerivedName("Galen Marr", email: "galen@x.com"))
    #expect(!OnboardingGate.isDerivedName("Tash", email: "natasha.bell@x.com"))
  }

  /// **Nothing to compare is NOT a match.** With no email on the payload a
  /// guess would clear a name somebody typed, which is the worse failure.
  @Test func withNothingToCompareItIsNotDerived() {
    #expect(!OnboardingGate.isDerivedName("Drew", email: nil))
    #expect(!OnboardingGate.isDerivedName("Drew", email: ""))
    #expect(!OnboardingGate.isDerivedName(nil, email: "drew@x.com"))
    #expect(!OnboardingGate.isDerivedName("", email: "drew@x.com"))
    // punctuation-only normalises to nothing and must not match a real localpart
    #expect(!OnboardingGate.isDerivedName("...", email: "drew@x.com"))
  }
}
