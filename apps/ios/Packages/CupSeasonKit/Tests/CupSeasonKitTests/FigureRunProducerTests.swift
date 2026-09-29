import Foundation
import Testing
@testable import CupSeasonKit

/// N4-082 · a number inside a sentence set in the serif is a figure run, and
/// the producer marks it (UI_SYSTEM §1.4, §1.6) — never a regex over prose.
/// Each marked form says the same words as the plain one, which stays the
/// web's verbatim; these pin the producers the checkpoint added.
struct FigureRunProducerTests {
  private func plain(_ s: String) -> String { s.filter { $0 != "{" && $0 != "}" } }

  @Test func aTagsDayIsARun() throws {
    let tag = try JSONDecoder().decode(PeopleService.OpenTag.self, from: Data("""
      {"round_id":null,"played_on":"2026-06-01","course_label":"North Grove (fixture)","gross":84,"by_name":"Blake Fixture","by_profile":null}
      """.utf8))
    #expect(tag.questionMarked == "Blake Fixture says you were out at North Grove (fixture) on June {1} — that right?")
    #expect(plain(tag.questionMarked) == tag.question)
  }

  @Test func aDatesDayIsARun() {
    #expect(LeagueDates.dowMonDay("2026-09-12", marked: true) == "Sat Sep {12}")
    #expect(LeagueDates.monDay("2026-09-12", marked: true) == "Sep {12}")
    #expect(LeagueDates.dowMonDay("2026-09-12") == "Sat Sep 12")
    #expect(RivalryCopy.monthDaySpoken("2026-06-01", marked: true) == "June {1}")
  }
}
