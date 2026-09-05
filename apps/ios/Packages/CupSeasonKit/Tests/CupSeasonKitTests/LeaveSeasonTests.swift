// Cup Season — leaving a season, forward-only (D244, C-9).
//
// The three facts the copy promises, and the gate that decides whether the
// door is even offered. What the SERVER does with them is asserted in the
// migration's own self-check (`v_rounds_ranked` honours `left_at`, no round is
// mutated, the Pro cannot walk out); what this file holds is that the app
// never says anything else about it.

import Testing
import Foundation
@testable import CupSeasonKit

@Suite("D244 — a member may leave a season, forward-only")
struct LeaveSeasonTests {

  @Test("the copy says exactly what happens: the rounds, the name, the day scoring stops")
  func theThreeFacts() {
    let body = LeaveSeason.body
    #expect(body == "Your rounds stay where they are. Your name stays on the season you played. "
                  + "You stop scoring from today.")
    // forward-only, in the words a golfer reads: nothing is removed, nothing
    // is deleted, and nothing is taken off anybody's card.
    for word in ["delete", "remove", "erase", "wipe", "forfeit"] {
      #expect(body.lowercased().contains(word) == false, "the exit promises to \(word) something")
    }
  }

  @Test("it is two taps, and the armed tap restates the consequence (L-32)")
  func twoTaps() {
    #expect(LeaveSeason.armed == "Sure? You stop scoring today")
    #expect(LeaveSeason.armed != LeaveSeason.head)
  }

  @Test("the gate · a member is offered the door")
  func memberGate() {
    #expect(LeaveSeason.gate(isPro: false, hasLeft: false) == .offer)
  }

  @Test("the gate · the Pro is told why, rather than shown nothing")
  func proGate() {
    #expect(LeaveSeason.gate(isPro: true, hasLeft: false) == .proMustHandOver)
    #expect(LeaveSeason.proNote.isEmpty == false)
    #expect(LeaveSeason.proNote.contains("Pro"))
  }

  @Test("the gate · a golfer who has left is told the state once, and offered nothing twice")
  func alreadyLeft() {
    #expect(LeaveSeason.gate(isPro: false, hasLeft: true) == .alreadyLeft)
    #expect(LeaveSeason.gate(isPro: true, hasLeft: true) == .alreadyLeft)
    #expect(LeaveSeason.leftNote.contains("stay"))
  }

  @Test("the RPC is defaulted on both sides, so either deploy order renders honestly")
  func deploySkew() {
    #expect(LeaveSeasonCall.name == "leave_season")
    #expect(LeaveSeasonCall.optionalArgs == ["p_league"])
    #expect(SeasonStoryCall.name == "season_story")
    #expect(SeasonStoryCall.optionalArgs == ["p_season", "p_league"])
  }

  @Test("the result decodes, including the idempotent second call")
  func decodesResult() throws {
    let json = #"{"left_at":"2026-09-05T17:00:00+00:00","league":"Fellas","already":true}"#
    let r = try JSONDecoder().decode(LeaveResult.self, from: Data(json.utf8))
    #expect(r.already == true)
    #expect(r.league == "Fellas")
    #expect(LeaveSeason.done(r.league) == "You left Fellas. Your rounds stay on your card.")
    // a payload that names no league still produces a sentence, not a blank
    #expect(LeaveSeason.done(nil) == "You left the season. Your rounds stay on your card.")
  }

  @Test("a leaver keeps their row on the table — the table is history, not a roster")
  func rowSurvives() {
    let gone = SeasonStory.Row(id: "jade", name: "Jade", points: 9, rank: 3, left: true)
    let leader = SeasonStory.Row(id: "galen", name: "Galen", points: 31, rank: 1)
    let clause = SeasonStoryCopy.rowClause(gone, leader: leader, cap: 3)
    #expect(clause?.contains("stopped scoring") == true)
    #expect(gone.points == 9)   // the number they earned is still the number
  }
}
