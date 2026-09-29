import Testing
import Foundation
@testable import CupSeasonKit

/// W4 · the signed-in scorecard link asks about the CLUB, and the course and
/// tee go to the facts line under it — the web's `csLinkAskClaim` and
/// `csLinkCard('claim')`, word for word (the links harness pins "Add this 91
/// at Mesquite Wash…"). The holes are a scorecard; "card" is the person (T-01).
@Suite struct LinkClaimAskTests {
  private func card(_ info: [String: JSONValue]) -> LinkConfirmation {
    LinkConfirmation(kind: .claim, token: UUID(), owner: UUID(), info: .object(info))
  }

  @Test func theQuestionNamesTheClubAndTheFactsCarryTheCourseAndTee() {
    let c = card(["guest_name": .string("Avery Fixture"), "gross": .number(91),
                  "course_label": .string("Mesquite Wash Golf Club (fixture) — Mesquite Wash · Black")])
    #expect(c.question == "Add this 91 at Mesquite Wash Golf Club (fixture) to your record?")
    // N4-045 · the sheet sets the gross as a figure run; the words are the same
    #expect(c.questionMarked == "Add this {91} at Mesquite Wash Golf Club (fixture) to your record?")
    #expect(c.facts == "Scored as Avery Fixture · Mesquite Wash · Black")
  }

  @Test func withoutAGrossItAsksForTheScorecard() {
    #expect(card(["course_label": .string("Papago")]).question == "Add this scorecard from Papago to your record?")
    // a label with no club says nothing it was not given
    #expect(card(["course_label": .string("Papago")]).facts == "")
    #expect(card([:]).question == "Add this scorecard from the course to your record?")
    #expect(card(["gross": .number(84), "course_label": .string("")]).question == "Add this 84 at the course to your record?")
  }
}
