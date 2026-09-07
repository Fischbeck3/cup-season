// Cup Season — the course page's producers (Wave 4, D272 / D275,
// `surfaces/course.md` §2.5, §2.7, §7).
//
// Two sentences and one payload, and all three are places this surface could
// quietly start lying: the sentence that NAMES the golfers who have played a
// course, the line that compares your golfers' rating with everyone's, and the
// aggregate that must return null rather than zero when nobody has rated a
// course at all.

import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct CourseFriendsLineTests {

  private func row(_ name: String, _ gross: Int?, mine: Bool = false) -> CourseRoundRow {
    CourseRoundRow(id: UUID(), profileId: UUID(), name: name, marker: "saguaro",
                   gross: gross, playedOn: "2026-08-30", holesPlayed: 18, isMine: mine)
  }

  /// §2.5 · **the line that makes a course page social rather than a database
  /// record.** It names them, and the best gross is a marked figure run —
  /// braces from the producer, never a regex over prose.
  @Test func itNamesThemAndMarksTheFigure() {
    let a = CoursePageAnswer(others: [row("Galen Marr", 79), row("Tash Bell", 84),
                                      row("Jade Okafor", 88)])
    #expect(a.friendsLine == "Galen, Tash and Jade. Galen’s {79} is the best of them.")
  }

  /// **Nobody else has played it: the block does not render**, rather than a
  /// sentence about an absence.
  @Test func nobodyElseMeansNoSentence() {
    #expect(CoursePageAnswer().friendsLine.isEmpty)
  }

  /// A group is a group. Past six names it is a roster, which is the event's
  /// device and not this one.
  @Test func theSentenceStopsNamingAtSix() {
    let eight = (1...8).map { row("Golfer\($0) Surname", 80 + $0) }
    let line = CoursePageAnswer(others: eight).friendsLine
    #expect(line.contains("Golfer6"))
    #expect(!line.contains("Golfer7"))
  }

  /// L-44 · a golfer with no gross still gets named; the page does not invent
  /// a number to finish its own sentence.
  @Test func noGrossMeansNoClaimAboutABest() {
    #expect(CoursePageAnswer(others: [row("Dev Patel", nil)]).friendsLine == "Dev.")
  }

  /// **No tee name, because `rounds` does not carry one.** The design asks for
  /// *"Aug 30 · blue tees"*; the payload holds the date and the hole count and
  /// nothing else, so the row prints what is true.
  @Test func theSublineIsTheDateAndTheHoleCount() {
    let cal = Calendar(identifier: .gregorian)
    #expect(row("Tash Bell", 84).subline(calendar: cal).contains("Aug 30"))
    let nine = CourseRoundRow(id: UUID(), profileId: UUID(), name: "Tash", marker: nil,
                              gross: 41, playedOn: "2026-08-30", holesPlayed: 9)
    #expect(nine.subline(calendar: cal).hasSuffix("nine holes"))
  }
}

@Suite struct CourseRatingTests {

  /// The write returns the read, so the client re-tallies from the server's
  /// own arithmetic rather than adding one to a number it was holding.
  @Test func theAggregateDecodesAsThreeNumbersAndTwoCounts() {
    let v = JSONValue.object([
      "rated": .bool(true), "stars": .number(4.6), "count": .number(24),
      "friends": .number(4.9), "friends_count": .number(4), "mine": .number(4.5)])
    let r = CourseRatingService.decode(v)
    #expect(r.stars == 4.6 && r.count == 24)
    #expect(r.friends == 4.9 && r.friendsCount == 4)
    #expect(r.mine == 4.5 && !r.unavailable)
  }

  /// **Null, never zero** (L-44). A course nobody has rated has no figure, and
  /// the client draws the full-size unfilled rail rather than a `0.0`.
  @Test func nothingRatedIsNullAndNotZero() {
    let v = JSONValue.object(["rated": .bool(false), "stars": .null, "count": .number(0),
                              "friends": .null, "friends_count": .number(0), "mine": .null])
    let r = CourseRatingService.decode(v)
    #expect(r.stars == nil && r.mine == nil && r.count == 0)
    #expect(r.friendsLine.isEmpty)
    #expect(r.countLine.isEmpty)
  }

  /// The function does not exist on this database yet — the migration is
  /// written and not pushed — so the client's own state is `unavailable`, and
  /// it draws the same rail an unrated course draws.
  @Test func noFunctionMeansUnavailableRatherThanZero() {
    #expect(CourseRating.none.unavailable)
    #expect(CourseRating.none.stars == nil)
  }

  /// The two sentences, with L-33's small numbers as words through the one
  /// producer.
  @Test func theTwoSentences() {
    let r = CourseRating(stars: 4.6, count: 24, friends: 4.9, friendsCount: 4, mine: nil)
    #expect(r.friendsLine == "Your golfers give it {4.9}.")
    #expect(r.countLine == "Rated by 24 golfers, four of them yours.")
    let alone = CourseRating(stars: 5, count: 1, friends: nil, friendsCount: 0, mine: 5)
    #expect(alone.countLine == "Rated by one golfer.")
    #expect(alone.friendsLine.isEmpty)
  }
}

@Suite struct CourseNamesTests {

  /// A course row is a first-name room.
  @Test func firstNames() {
    #expect(CourseNames.first("Galen Marr") == "Galen")
    #expect(CourseNames.first("Dev") == "Dev")
  }

  @Test func theList() {
    #expect(CourseNames.list([]) == "")
    #expect(CourseNames.list(["Galen"]) == "Galen")
    #expect(CourseNames.list(["Galen", "Tash"]) == "Galen and Tash")
    #expect(CourseNames.list(["Galen", "Tash", "Jade"]) == "Galen, Tash and Jade")
  }
}
