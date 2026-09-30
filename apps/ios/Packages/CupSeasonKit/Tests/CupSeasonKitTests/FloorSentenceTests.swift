// Cup Season — Q-27 · the one floor sentence, and the rules page that says it.
//
// The monthly minimum was written more than one way, and the rules page's
// version left out what a miss costs ("Miss a month and your first one is
// forgiven automatically." — and then nothing). The web's `floorSentence()`
// is the producer Home and the pot use; the phone says the same words.

import Testing
import Foundation
@testable import CupSeasonKit

@Suite("Q-27 · the floor sentence")
struct FloorSentenceTests {

  @Test("the web's floorSentence, word for word, for each of its five answers")
  func webWords() {
    #expect(LeagueCopy.floorSentence(floor: 0, preset: 1, structure: "squads2")
            == "No minimum — every round counts, and nothing is owed.")
    #expect(LeagueCopy.floorSentence(floor: 2, preset: 1, structure: "solo")
            == "Post 2 rounds a month. In a solo league that is a habit, not a penalty — there's no squad to dock.")
    #expect(LeagueCopy.floorSentence(floor: 1, preset: 0, structure: "squads2")
            == "Post 1 round a month. Nothing is docked if you miss — it's a habit, not a penalty.")
    #expect(LeagueCopy.floorSentence(floor: 2, preset: 1, structure: "squads2")
            == "Post 2 rounds a month. Miss once and your season bye covers it automatically; from the second miss your squad loses 5 points for every round you're short. A partial first or last month has no minimum.")
    #expect(LeagueCopy.floorSentence(floor: 3, preset: 2, structure: "squads4")
            == "Post 3 rounds a month. Miss once and your season bye covers it automatically; from the second miss the month's rounds are struck. A partial first or last month has no minimum.")
  }

  @Test("the rules page says what a miss costs, in the same sentence; no floor, no section")
  func rulesPage() {
    let clock = RoomClock(phase: .season, startsOn: "2026-07-06", endsOn: "2026-10-18", status: "active",
                          finish: "cup_final", today: "2026-09-28")
    let owe = SeasonRules.sections(Bylaws(floor: 2, presetIdx: 1, structure: "squads2"), clock: clock, pro: nil, members: 8)
      .first { $0.head == "What you owe the season" }
    #expect(owe?.body == LeagueCopy.floorSentence(floor: 2, preset: 1, structure: "squads2"))
    #expect(owe?.body.contains("your squad loses 5 points") == true)
    let solo = SeasonRules.sections(Bylaws(floor: 2, presetIdx: 1, structure: "solo"), clock: clock, pro: nil, members: 8)
      .first { $0.head == "What you owe the season" }
    #expect(solo?.body.contains("no squad to dock") == true)
    #expect(SeasonRules.sections(Bylaws(floor: 0), clock: clock, pro: nil, members: 8)
      .contains { $0.head == "What you owe the season" } == false)
  }

  /// N4-181 · the numbers a golfer scans for are figures, set as runs on the
  /// page; the counting rule's "best four" stays a word (PAR-29), and the
  /// split is the covenant's own sentence.
  @Test("the rules page sets its figures as runs, and says the same words plain")
  func rulesPageFigures() {
    let clock = RoomClock(phase: .season, startsOn: "2026-07-06", endsOn: "2026-10-18", status: "active",
                          finish: "cup_final", today: "2026-09-28")
    let b = Bylaws(stake: 40, floor: 2, cap: 4, presetIdx: 1, structure: "squads2")
    let marked = SeasonRules.sections(b, clock: clock, pro: "Blake", members: 8, marked: true)
    let plain = SeasonRules.sections(b, clock: clock, pro: "Blake", members: 8)
    func body(_ s: [SeasonRules.Section], _ head: String) -> String { s.first { $0.head == head }?.body ?? "" }
    #expect(body(marked, "How it scores").contains("your index at {95} percent"))
    #expect(body(marked, "How it scores").contains("Your best four rounds"), "the counting rule keeps its word")
    #expect(body(marked, "What you owe the season").hasPrefix("Post {2} rounds a month."))
    #expect(body(marked, "What's on it").hasPrefix("{$40} each, {$320} in the pot. {60} percent to the champion, {25} to the runner-up, {15} to the points king."))
    #expect(body(plain, "What's on it").contains(PotMath.splitWords(champion: 60, runnerUp: 25, pointsKing: 15)! + "."))
    // one producer, two grains: the marks come off and the words are the same
    for (m, p) in zip(marked, plain) {
      #expect(m.body.filter { $0 != "{" && $0 != "}" } == p.body)
      #expect(!p.marked && !p.body.contains("{"))
    }
    // a section that prints a name is never set as marks
    #expect(marked.first { $0.head == "Who runs it" }?.marked == false)
  }

  /// N4 · the scoring guide said the minimum in its own words ("the penalty
  /// bites from the second miss"). With a league in hand it now says the
  /// league's minimum in this sentence; the league-less reader, who has no
  /// number, keeps the paragraph that describes both structures.
  @Test("the scoring guide states a league's minimum in the floor sentence")
  func scoringGuide() {
    func counts(_ s: [GuideCopy.ScoringSection]) -> String? { s.first { $0.eyebrow == "What counts" }?.paragraphs.first }
    let squads = GuideCopy.Minimum(floor: 2, preset: 1, structure: "squads2")
    let p = counts(GuideCopy.scoring(solo: false, minimum: squads))
    #expect(p?.contains(LeagueCopy.floorSentence(floor: 2, preset: 1, structure: "squads2")) == true)
    #expect(p?.contains("the penalty bites from the second miss") == false)
    #expect(p?.hasPrefix("Your best rounds each month count for your squad") == true)
    let solo = GuideCopy.Minimum(floor: 2, preset: 1, structure: "solo")
    let q = counts(GuideCopy.scoring(solo: true, minimum: solo))
    #expect(q?.contains(LeagueCopy.floorSentence(floor: 2, preset: 1, structure: "solo")) == true)
    #expect(q?.contains("for your squad") == false)
    // the league's structure decides the covenant too, whatever `solo` said
    #expect(GuideCopy.scoring(solo: nil, minimum: solo).flatMap(\.paragraphs).contains { $0.contains("hurt your standing") })
    #expect(GuideCopy.scoring(solo: nil, minimum: squads).flatMap(\.paragraphs).contains { $0.contains("hurt your squad") })
    // no minimum at all is said in the sentence, too
    let none = GuideCopy.Minimum(floor: 0, preset: 1, structure: "squads2")
    #expect(counts(GuideCopy.scoring(solo: false, minimum: none))?.contains("No minimum") == true)
    // the league-less reader: no number to state, both structures described
    let leagueless = counts(GuideCopy.scoring(solo: nil))
    #expect(leagueless?.contains("In a squad league") == true)
    #expect(leagueless?.contains("In a solo league") == true)
    #expect(leagueless?.contains("Post ") == false)
  }

  @Test("a membership's settings give the minimum the way the room's bylaws do")
  func minimumFromSettings() throws {
    let s = try JSONDecoder().decode(Me.Settings.self,
      from: Data(#"{"structure":"squads3","preset":"cutthroat","participation_floor":3}"#.utf8))
    #expect(GuideCopy.Minimum(s) == GuideCopy.Minimum(floor: 3, preset: 2, structure: "squads3"))
    let noFloor = try JSONDecoder().decode(Me.Settings.self, from: Data(#"{"structure":"solo"}"#.utf8))
    #expect(GuideCopy.Minimum(noFloor) == nil)
    #expect(GuideCopy.Minimum(nil) == nil)
    #expect(GuideCopy.Minimum(Bylaws(floor: 2, presetIdx: 0, structure: "solo"))
            == GuideCopy.Minimum(floor: 2, preset: 0, structure: "solo"))
  }
}
