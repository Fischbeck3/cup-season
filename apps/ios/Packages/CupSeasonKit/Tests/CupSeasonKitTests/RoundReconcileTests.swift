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

  // MARK: - the save status, decided by identity

  private static let me = UUID(uuidString: "00000000-0000-0000-0000-0000000000E1")!
  private static let alex = UUID(uuidString: "00000000-0000-0000-0000-000000000A1E")!
  private func card(_ name: String, _ pid: UUID?, round: UUID? = nil, reason: String? = nil) -> RoundReconcile.Card {
    RoundReconcile.Card(name: name, profileId: pid, roundId: round, reason: reason)
  }

  @Test func postedSavedAndNotPostedAreThreeDifferentSentences() {
    let posted = RoundReconcile.status(posted: [card("Jerecho", Self.me, round: Self.a)], skipped: [], casual: false, keptLocally: false, me: Self.me)
    #expect(posted == .posted)
    #expect(posted.title == "Round posted")
    #expect(posted.hasRound)

    let local = RoundReconcile.status(posted: [], skipped: [], casual: false, keptLocally: true, me: Self.me)
    #expect(local == .savedOnThisPhone)
    #expect(!local.hasRound, "a local card has no receipt to open yet")

    let skipped = RoundReconcile.status(posted: [], skipped: [card("Jerecho", Self.me, reason: "No holes scored")],
                                        casual: false, keptLocally: false, me: Self.me)
    #expect(skipped == .notPosted(reason: "No holes scored"))
    #expect(!skipped.hasRound)
  }

  /// **Codex R3 · a name is not an identity.** Another Alex posted and this
  /// Alex was skipped: the viewer is NOT told their round posted.
  @Test func aSharedNameDoesNotBorrowSomeoneElsesPost() {
    let s = RoundReconcile.status(posted: [card("Alex", Self.alex, round: Self.b)],
                                  skipped: [card("Alex", Self.me, reason: "incomplete card")],
                                  casual: false, keptLocally: false, me: Self.me)
    #expect(s == .notPosted(reason: "incomplete card"))
  }

  /// Identities were reported and mine is not among them: not posted, and
  /// never inferred from a posted card that belongs to someone else.
  @Test func somebodyElsesPostIsNotMine() {
    #expect(RoundReconcile.status(posted: [card("Galen", Self.alex, round: Self.b)], skipped: [], casual: false,
                                  keptLocally: false, me: Self.me) == .notPosted(reason: ""))
  }

  /// An OLD payload names nobody. That is uncertainty, and it is said as such
  /// until authoritative evidence confirms — one matching round of mine.
  @Test func aPayloadWithoutIdentitiesIsUnconfirmedUntilEvidence() {
    let s = RoundReconcile.status(posted: [card("Jerecho", nil)], skipped: [], casual: false, keptLocally: false, me: Self.me)
    #expect(s == .unconfirmed)
    #expect(s.title == "Not confirmed yet")
    #expect(!s.hasRound)
    #expect(RoundReconcile.confirm(s, match: .one(Self.a)) == .posted)
    #expect(RoundReconcile.confirm(s, match: .ambiguous([Self.a, Self.b])) == .unconfirmed)
    #expect(RoundReconcile.confirm(s, match: .none) == .unconfirmed)
    // and a posted status is never demoted by the confirm step
    #expect(RoundReconcile.confirm(.posted, match: .none) == .posted)
  }

  /// The kept card wins over everything.
  @Test func aKeptCardIsNeverReportedAsPosted() {
    #expect(RoundReconcile.status(posted: [card("Jerecho", Self.me, round: Self.a)], skipped: [], casual: false,
                                  keptLocally: true, me: Self.me) == .savedOnThisPhone)
  }

  @Test func aCasualRoundSaysWhatItIs() {
    let s = RoundReconcile.status(posted: [], skipped: [], casual: true, keptLocally: false, me: Self.me)
    #expect(s.title == "Not posted")
    #expect(s.detail.contains("casual"))
  }

  /// The server named my round: no matching, no ambiguity.
  @Test func theServerNamesMyRound() {
    #expect(RoundReconcile.namedRound(posted: [card("Alex", Self.alex, round: Self.b), card("Jerecho", Self.me, round: Self.a)], me: Self.me) == Self.a)
    #expect(RoundReconcile.namedRound(posted: [card("Jerecho", nil, round: Self.a)], me: Self.me) == nil, "a round without an identity is not claimed")
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

@Suite struct PlayedPlanOnHomeTests {
  private static let a = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
  private static let b = UUID(uuidString: "00000000-0000-0000-0000-0000000000B2")!
  private static let plan = UUID(uuidString: "00000000-0000-0000-0000-0000000000C3")!

  private func planItem(course: String?, day: String) -> HomeDispatch.Item {
    HomeDispatch.Item(key: "plan:\(Self.plan)", tier: .closing, eyebrow: "", headline: "", spine: .ember,
                      plan: PlanContext(planId: Self.plan, playOn: day, courseLabel: "Bajamar", courseId: course, teeTime: "06:30"))
  }
  private func round(_ id: UUID, _ course: String?, _ day: String) -> RoundReconcile.Candidate {
    RoundReconcile.Candidate(id: id, courseId: course, playedOn: day)
  }

  /// The owner's case: a booking for today on course 100, one round today on
  /// course 100 — Home stops telling him a round is scheduled.
  @Test func aPlayedBookingLeavesHome() {
    let items = [planItem(course: "100", day: "2026-09-15")]
    let out = RoundReconcile.droppingPlayedPlans(items, myRounds: [round(Self.a, "100", "2026-09-15")])
    #expect(out.isEmpty)
  }

  /// No round yet: the booking keeps prompting, which is what it is for.
  @Test func anUnplayedBookingStays() {
    let items = [planItem(course: "100", day: "2026-09-15")]
    #expect(RoundReconcile.droppingPlayedPlans(items, myRounds: []).count == 1)
    #expect(RoundReconcile.droppingPlayedPlans(items, myRounds: [round(Self.a, "212", "2026-09-15")]).count == 1,
            "a round somewhere else is not this booking")
  }

  /// A booking with no course id has no evidence to match on, so it is left
  /// alone rather than guessed off a label.
  @Test func aBookingWithoutACourseIdIsNotGuessed() {
    let items = [planItem(course: nil, day: "2026-09-15")]
    #expect(RoundReconcile.droppingPlayedPlans(items, myRounds: [round(Self.a, "100", "2026-09-15")]).count == 1)
  }

  /// Two rounds on that course that day is a question, and a question does
  /// not silently remove the booking.
  @Test func anAmbiguousDayIsNotDropped() {
    let items = [planItem(course: "100", day: "2026-09-15")]
    let out = RoundReconcile.droppingPlayedPlans(items, myRounds: [round(Self.a, "100", "2026-09-15"), round(Self.b, "100", "2026-09-15")])
    #expect(out.count == 1)
  }

  /// **Codex R5 · two bookings, one round.** One round at course 100 today and
  /// TWO bookings there today: the round cannot be assigned to either, so
  /// neither is dropped and the golfer keeps both reminders.
  @Test func twoBookingsOnOneCourseAndDayAreBothKept() {
    let p2 = UUID(uuidString: "00000000-0000-0000-0000-0000000000D4")!
    var second = planItem(course: "100", day: "2026-09-15")
    second = HomeDispatch.Item(key: "plan:\(p2)", tier: .closing, eyebrow: "", headline: "", spine: .ember,
                               plan: PlanContext(planId: p2, playOn: "2026-09-15", courseLabel: "Bajamar", courseId: "100", teeTime: "13:10"))
    let items = [planItem(course: "100", day: "2026-09-15"), second]
    let out = RoundReconcile.droppingPlayedPlans(items, myRounds: [round(Self.a, "100", "2026-09-15")])
    #expect(out.count == 2)
  }

  /// Only `plan:` items are touched — a clash or a story passes through even
  /// when it happens to carry a plan context.
  @Test func onlyPlanItemsAreReconciled() {
    var other = planItem(course: "100", day: "2026-09-15")
    other = HomeDispatch.Item(key: "clash:x", tier: other.tier, eyebrow: "", headline: "", spine: .ember, plan: other.plan)
    let out = RoundReconcile.droppingPlayedPlans([other], myRounds: [round(Self.a, "100", "2026-09-15")])
    #expect(out.count == 1)
  }
}
