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
    // D322 · "theirs", not "them". `others` excludes the viewer by
    // construction and the page prints a YOUR BEST tile directly above it, so
    // the word has to carry the exclusion the arithmetic already does.
    #expect(a.friendsLine == "Galen, Tash and Jade. Galen’s {79} is the best of theirs.")
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
    #expect(CoursePageAnswer(others: [row("Dev Patel", nil)]).friendsLine == "Dev has played it.")
    // and with several, the list stands alone rather than inventing a best
    #expect(CoursePageAnswer(others: [row("Dev Patel", nil), row("Tash Bell", nil)])
              .friendsLine == "Dev and Tash.")
  }

  /// **THE BUG THE OWNER FOUND ON HIS OWN COURSE PAGE** (D322). One other
  /// golfer had played Gold Canyon, and the page printed *"Galen. Galen's 92
  /// is the best of them."* — the list clause introduces a GROUP and the
  /// second singles one out of it, so with one person both are the same name.
  /// **One round is not the best of anything**, so a lone golfer gets no
  /// superlative at all.
  @Test func oneOtherGolferIsNotAGroupAndHasNoBest() {
    let one = CoursePageAnswer(others: [row("Galen Marr", 92)]).friendsLine
    #expect(one == "Galen has played it — a {92}.")
    #expect(!one.contains("best"))
    // the name is said ONCE
    #expect(one.components(separatedBy: "Galen").count - 1 == 1)
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

  /// The read did not happen — no signal, or a database that predates a
  /// function — so the client's own state is `unavailable`, and it draws the
  /// same rail an unrated course draws. It is NOT "not rated", and only the
  /// sheet is allowed to tell them apart.
  @Test func noFunctionMeansUnavailableRatherThanZero() {
    #expect(CourseRating.none.unavailable)
    #expect(CourseRating.none.stars == nil)
  }

  /// **D289 · the sentences come back with the numbers**, and an uncredited
  /// one does not come back at all: a note with no name behind it is the thing
  /// this product does not print, so the decoder drops it rather than the view
  /// hiding it.
  @Test func theSentencesDecodeAndTheUncreditedOneIsDropped() {
    let v = JSONValue.object([
      "rated": .bool(true), "stars": .number(4.5), "count": .number(24),
      "friends": .number(4.5), "friends_count": .number(6), "mine": .number(5),
      "mine_note": .string("Best muni in the state and it isn’t close."),
      "notes": .array([
        .object(["who": .string("Galen Marr"), "stars": .number(4.5),
                 "note": .string("The 12th is the only hole that scares me.")]),
        .object(["who": .string(""), "stars": .number(3), "note": .string("no name")]),
        .object(["who": .string("Jade"), "stars": .number(4), "note": .string("")])])])
    let r = CourseRatingService.decode(v)
    #expect(r.mineNote == "Best muni in the state and it isn’t close.")
    #expect(r.notes.count == 1)
    #expect(r.notes.first?.line == "Galen Marr · 4.5")
  }

  /// A rating with no sentence is the common case, and it is nil rather than
  /// an empty string dressed as one (L-44).
  @Test func aRatingWithNoSentenceCarriesNone() {
    let v = JSONValue.object(["rated": .bool(true), "stars": .number(4), "count": .number(2),
                              "mine": .number(4), "mine_note": .null])
    let r = CourseRatingService.decode(v)
    #expect(r.mineNote == nil && r.notes.isEmpty)
  }

  /// **`p_note` is DROPPABLE, and that is what makes the default safe.** A
  /// client newer than its database still sets the star: `svc.call` retries
  /// without the argument, and the server's `null` contract leaves any
  /// sentence already stored exactly where it was.
  @Test func theNoteArgumentIsTheDroppableOne() {
    #expect(RateCourseCall.optionalArgs == ["p_note"])
    #expect(CourseRatingCall.optionalArgs.isEmpty)
    #expect(UnrateCourseCall.optionalArgs.isEmpty)
    #expect(MyCourseRatingsCall.name == "my_course_ratings")
  }

  /// The two sentences, with L-33's small numbers as words through the one
  /// producer.
  @Test func theTwoSentences() {
    let r = CourseRating(stars: 4.6, count: 24, friends: 4.9, friendsCount: 4, mine: nil)
    #expect(r.friendsLine == "Your buddies give it {4.9}.")
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
