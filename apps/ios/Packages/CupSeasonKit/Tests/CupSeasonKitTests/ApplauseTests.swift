// D365 · one appreciation action. The vocabulary, the state fold, the
// activity sentence and the first-use rule — each a value a test holds.
import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct ApplauseTests {
  @Test func theVocabularyIsApplauseNeverClap() {
    let words = [Applause.noun, Applause.give, Applause.remove, Applause.sent, Applause.failed,
                 Applause.activity(["Alex"]), Applause.earlierNote(2)]
    for w in words { #expect(!w.lowercased().contains("clap"), Comment(rawValue: w)) }
    #expect(Applause.give == "Give applause" && Applause.remove == "Remove applause" && Applause.sent == "Applause sent")
    #expect(Applause.key == "applause" && Applause.key.count <= 8)   // post_kudos_emoji_len
  }

  @Test func activityGroupsDistinctPeople() {
    #expect(Applause.activity([]) == "")
    #expect(Applause.activity(["Alex"]) == "Alex applauded your round")
    #expect(Applause.activity(["Alex", "Jade"]) == "Alex and Jade applauded your round")
    #expect(Applause.activity(["Alex", "Jade", "Ed"]) == "Alex and 2 others applauded your round")
    // never a sum of taps: the same person twice is one person
    #expect(Applause.activity(["Alex", "Alex", "Jade"]) == "Alex and Jade applauded your round")
  }

  /// The fold counts applause only. Reactions from the retired menu are kept
  /// and shown apart — never summed into the count, never deleted.
  @Test func theStateCountsApplauseAndKeepsEarlierReactionsApart() {
    let rx: [String: ReactionState] = [
      "applause": ReactionState(n: 3, me: true, who: ["Alex", "Jade", "You"]),
      "azalea": ReactionState(n: 2, me: false, who: ["Ed", "Rosa"]),
      "rake": ReactionState(n: 1, me: false, who: ["Ed"]),
    ]
    let s = Applause.state(rx)
    #expect(s.n == 3 && s.me && s.who == ["Alex", "Jade", "You"])
    #expect(s.earlier == 3)
    #expect(s.spoken == "Remove applause, 3 applause, yours")
    let none = Applause.state([:])
    #expect(none.n == 0 && !none.me && none.earlier == 0 && none.spoken == "Give applause")
  }

  @Test func applauseSentIsSaidOnce() {
    let d = UserDefaults(suiteName: "cs.test.applause.\(UUID().uuidString)")!
    #expect(Applause.firstSend(defaults: d) == true)
    #expect(Applause.firstSend(defaults: d) == false)
  }

  /// The digest's line for applause is the approved activity sentence, and a
  /// mention that arrives as applause is grouped by round rather than listed.
  @Test func theDigestSaysApplauded() {
    #expect(HomeDigest.mention(HomeSocial.Mention(who: "Alex", emoji: "applause", gross: 84), gross: "84") == "Alex applauded your round")
    let rid = UUID()
    let mentions = [HomeSocial.Mention(who: "Alex", emoji: "applause", gross: 84, roundId: rid),
                    HomeSocial.Mention(who: "Jade", emoji: "applause", gross: 84, roundId: rid),
                    HomeSocial.Mention(who: "Ed", emoji: "applause", gross: 84, roundId: rid)]
    #expect(HomeDigest.applauseLines(mentions) == ["Alex and 2 others applauded your round"])
    let two = [HomeSocial.Mention(who: "Alex", emoji: "applause", gross: 84, roundId: rid),
               HomeSocial.Mention(who: "Jade", emoji: "applause", gross: 79, roundId: UUID())]
    #expect(HomeDigest.applauseLines(two) == ["Alex applauded your round", "Jade applauded your round"])
  }
}
