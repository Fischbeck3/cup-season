import Foundation
import Testing
@testable import CupSeasonKit

@Suite struct HomeProgrammeCopyTests {
  private func round(gross: Int? = 82, flag: String? = nil, pvi: Double? = nil) throws -> HomeFeedRow {
    var json: [String: Any] = ["course": "QA Papago", "golfer": "QA golfer", "is_me": false]
    if let gross { json["gross"] = gross }
    if let flag { json[flag] = true }
    if let pvi { json["pvi"] = pvi }
    return try JSONDecoder().decode(HomeFeedRow.self, from: JSONSerialization.data(withJSONObject: json))
  }

  @Test("the context removes only the score; milestones and HCP wording survive")
  func preservesStory() throws {
    for row in [try round(), try round(flag: "is_pr"), try round(gross: 78, flag: "is_sub80"),
                try round(flag: "is_first"), try round(pvi: 2.4)] {
      #expect("\(row.gross!) at " + HomeWireCopy.roundContext(row) == HomeWireCopy.roundLine(row))
      #expect(!HomeWireCopy.roundContext(row).hasPrefix("\(row.gross!) at "))
    }
  }

  @Test("an unavailable score stays unavailable instead of becoming zero")
  func missingScore() throws {
    let row = try round(gross: nil)
    #expect(HomeWireCopy.roundContext(row) == "A round at QA Papago.")
  }

  @Test("the programme preserves missing-course honesty and hole-count milestone rules")
  func currentRecordRules() throws {
    let row = try round(gross: 43, flag: "is_sub80")
    #expect(HomeWireCopy.roundContext(row, holes: 9) == "QA Papago.")
    #expect(HomeWireCopy.grossUnit(holes: 9) == "Gross · 9 holes")
    let missing = try JSONDecoder().decode(HomeFeedRow.self, from: Data(#"{"gross":82,"is_me":false}"#.utf8))
    #expect(HomeWireCopy.roundContext(missing) == "Course not recorded.")
  }
}
