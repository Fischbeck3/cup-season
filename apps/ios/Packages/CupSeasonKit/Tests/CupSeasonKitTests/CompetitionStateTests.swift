// F11 · ember identifies a competition in ANY state, so the state must be
// carried by a word. These hold the words, the mapping from the statuses the
// database already stores, and the one thing the widening must never do:
// make a plain booked round look like a contest.
import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct CompetitionStateTests {

  /// The three words, and none of them is new vocabulary.
  @Test func theWordsAreTheProductsOwn() {
    #expect(CompetitionState.upcoming.word == "Upcoming")
    #expect(CompetitionState.live.word == "Live")
    #expect(CompetitionState.final.word == "Final")
    // spoken first, so VoiceOver never receives the state as colour alone
    #expect(CompetitionState.live.spoken == "Live competition")
    #expect(CompetitionState.final.spoken == "Finished competition")
    #expect(CompetitionState.upcoming.spoken == "Upcoming competition")
  }

  /// A season, from `seasons.status` and the client's own phase.
  @Test func aSeasonReadsItsStatus() {
    #expect(CompetitionState.season(status: "active", phase: nil) == .live)
    #expect(CompetitionState.season(status: "cup_final", phase: nil) == .live)
    #expect(CompetitionState.season(status: "complete", phase: nil) == .final)
    #expect(CompetitionState.season(status: nil, phase: nil) == nil, "no season is no competition")
    // the phase wins where the client has derived one
    #expect(CompetitionState.season(status: "active", phase: .preseason) == .upcoming)
    #expect(CompetitionState.season(status: "active", phase: .season(week: 3, of: 13)) == .live)
    #expect(CompetitionState.season(status: "active", phase: .cupFinal(weeksLeft: 2)) == .live)
    #expect(CompetitionState.season(status: "active", phase: .wrapped) == .final)
    #expect(CompetitionState.season(status: nil, phase: .forming) == .upcoming)
  }

  /// An event, from `events.status`. A cancelled contest is gone, not finished.
  @Test func anEventReadsItsStatus() {
    #expect(CompetitionState.event(status: "setup") == .upcoming)
    #expect(CompetitionState.event(status: "live") == .live)
    #expect(CompetitionState.event(status: "complete") == .final)
    #expect(CompetitionState.event(status: "cancelled") == nil)
    #expect(CompetitionState.event(status: nil) == nil)
  }

  @Test func aClashIsLiveUntilItSettles() {
    #expect(CompetitionState.clash(settled: false) == .live)
    #expect(CompetitionState.clash(settled: true) == .final)
  }

  /// **The line the widening must not cross.** Ember marks a competition, and
  /// a booked round is not one — so a plan key is not in the competition
  /// families, however close its date is.
  @Test func aPlainBookedRoundIsNotACompetition() {
    func item(_ key: String) -> HomeDispatch.Item {
      HomeDispatch.Item(key: key, tier: .closing, eyebrow: "", headline: "", spine: .ember)
    }
    #expect(HomePage.isCompetition(item("plan:abc")) == false)
    #expect(HomePage.isCompetition(item("story:abc")) == false)
    #expect(HomePage.isCompetition(item("clash:abc:3")) == true)
    #expect(HomePage.isCompetition(item("firsttee:abc")) == true)
    // and the spine does not decide it: the server still spines a plan ember
    #expect(item("plan:abc").spine == .ember)
  }

  /// Every state a band can wear produces a word — a band with no word would
  /// be the exact ambiguity the widening introduced.
  @Test func everyStateHasAWordAndASentence() {
    for s in CompetitionState.allCases {
      #expect(!s.word.isEmpty)
      #expect(!s.spoken.isEmpty)
      #expect(s.spoken.lowercased().contains("competition"))
    }
  }
}
