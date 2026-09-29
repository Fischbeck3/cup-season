// Cup Season — Q-27 · the one floor sentence, and the rules page that says it.
//
// The monthly minimum was written more than one way, and the rules page's
// version left out what a miss costs ("Miss a month and your first one is
// forgiven automatically." — and then nothing). The web's `floorSentence()`
// is the producer Home and the pot use; the phone says the same words.

import Testing
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
            == "Post 2 rounds a month. Miss once and your season bye covers it automatically; from the second miss your squad loses 5 points for every round you're short. Short months are waived.")
    #expect(LeagueCopy.floorSentence(floor: 3, preset: 2, structure: "squads4")
            == "Post 3 rounds a month. Miss once and your season bye covers it automatically; from the second miss the month's rounds are struck. Short months are waived.")
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
}
