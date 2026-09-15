// F12 · the round I just finished: what happened to it, which one is mine,
// and whether the booking has been played BY ME.
//
// These hold the three rules the finding is about: a save status is never
// inferred from a cheerful title, a round is matched on course ID and date
// rather than a label, and two candidates are a question and not a match.
import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct RoundReconcileTests {
  private static let a = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
  private static let b = UUID(uuidString: "00000000-0000-0000-0000-0000000000B2")!

  private func round(_ id: UUID, _ course: String?, _ day: String?) -> RoundReconcile.Candidate {
    RoundReconcile.Candidate(id: id, courseId: course, playedOn: day)
  }

  // MARK: - the save status, in the product's own words

  @Test func postedSavedAndNotPostedAreThreeDifferentSentences() {
    let posted = RoundReconcile.status(posted: ["Jerecho"], skipped: [], casual: false, keptLocally: false, mine: "Jerecho")
    #expect(posted == .posted)
    #expect(posted.title == "Round posted")
    #expect(posted.detail == "It's on the books and scoring.")
    #expect(posted.hasRound)

    let local = RoundReconcile.status(posted: [], skipped: [], casual: false, keptLocally: true, mine: "Jerecho")
    #expect(local == .savedOnThisPhone)
    #expect(local.title == "Saved on this phone")
    #expect(!local.hasRound, "a local card has no receipt to open yet")

    let skipped = RoundReconcile.status(posted: [], skipped: [("Jerecho", "No holes scored")],
                                        casual: false, keptLocally: false, mine: "Jerecho")
    #expect(skipped == .notPosted(reason: "No holes scored"))
    #expect(skipped.detail == "No holes scored")
    #expect(!skipped.hasRound)
  }

  /// **The local card wins over everything.** A phone that kept the card has
  /// not posted it, whatever else the payload says.
  @Test func aKeptCardIsNeverReportedAsPosted() {
    #expect(RoundReconcile.status(posted: ["Jerecho"], skipped: [], casual: false,
                                  keptLocally: true, mine: "Jerecho") == .savedOnThisPhone)
  }

  /// A casual round posts nothing BY DESIGN, and says so rather than reading
  /// as a failure.
  @Test func aCasualRoundSaysWhatItIs() {
    let s = RoundReconcile.status(posted: [], skipped: [], casual: true, keptLocally: false, mine: "Jerecho")
    #expect(s.title == "Not posted")
    #expect(s.detail.contains("casual"))
  }

  /// The viewer is not in the posted list and there is no skip line for them:
  /// the product does not claim their round is on the books.
  @Test func somebodyElsesPostIsNotMine() {
    #expect(RoundReconcile.status(posted: ["Galen"], skipped: [], casual: false,
                                  keptLocally: false, mine: "Jerecho") == .notPosted(reason: ""))
  }

  // MARK: - which round is mine

  @Test func oneRoundOnTheCourseAndTheDayIsTheMatch() {
    let rounds = [round(Self.a, "100", "2026-09-15"), round(Self.b, "212", "2026-09-15")]
    #expect(RoundReconcile.mine(rounds, courseId: "100", playedOn: "2026-09-15") == .one(Self.a))
  }

  /// **Two candidates are a question, not a match.** Two rounds at the same
  /// course on the same day is a real day of golf, and linking the wrong one
  /// is worse than asking.
  @Test func twoRoundsThatDayAreAsked() {
    let rounds = [round(Self.a, "100", "2026-09-15"), round(Self.b, "100", "2026-09-15")]
    #expect(RoundReconcile.mine(rounds, courseId: "100", playedOn: "2026-09-15") == .ambiguous([Self.a, Self.b]))
  }

  /// A course LABEL is not evidence: with no course id there is nothing to
  /// match on, and the answer is none rather than a guess.
  @Test func withoutACourseIdThereIsNoEvidence() {
    let rounds = [round(Self.a, nil, "2026-09-15")]
    #expect(RoundReconcile.mine(rounds, courseId: nil, playedOn: "2026-09-15") == .none)
    #expect(RoundReconcile.mine(rounds, courseId: "", playedOn: "2026-09-15") == .none)
    #expect(RoundReconcile.mine(rounds, courseId: "100", playedOn: nil) == .none)
  }

  /// A round backdated to another day is not this booking's round — the date
  /// is part of the evidence, not decoration.
  @Test func anotherDaysRoundIsNotThisOne() {
    let rounds = [round(Self.a, "100", "2026-09-14")]
    #expect(RoundReconcile.mine(rounds, courseId: "100", playedOn: "2026-09-15") == .none)
  }

  // MARK: - has this booking been played, by me

  /// The owner's real case, from production evidence: one booking, one round,
  /// same course id, same day — so the booking stops prompting him.
  @Test func theOwnersBookingReconciles() {
    let mine = [round(Self.a, "100", "2026-09-15")]
    #expect(RoundReconcile.booking(courseId: "100", playOn: "2026-09-15", myRounds: mine) == .played(Self.a))
  }

  /// **Per golfer.** An invited golfer who posted nothing keeps their prompt
  /// even though the host played and posted — a host finishing does not mark
  /// everyone as having played.
  @Test func aHostFinishingDoesNotMarkTheGuests() {
    #expect(RoundReconcile.booking(courseId: "100", playOn: "2026-09-15", myRounds: []) == .open)
  }

  @Test func anAmbiguousBookingAsksRatherThanGuesses() {
    let mine = [round(Self.a, "100", "2026-09-15"), round(Self.b, "100", "2026-09-15")]
    #expect(RoundReconcile.booking(courseId: "100", playOn: "2026-09-15", myRounds: mine) == .askWhich([Self.a, Self.b]))
    #expect(RoundReconcile.askWhichRound.hasSuffix("?"), "an ambiguity is asked, not asserted")
  }
}
