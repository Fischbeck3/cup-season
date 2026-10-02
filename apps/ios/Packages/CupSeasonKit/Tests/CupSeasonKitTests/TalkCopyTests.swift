import Foundation
import Testing
@testable import CupSeasonKit

/// N4-202 / N4-203 · D391's words come from one Kit table, and they are the
/// web's (`CS_TALK`, `CS_RELATION`, `csCoursePeopleRender`), which the
/// contract (v1.2 §Revisions) names "reuse verbatim".
struct TalkCopyTests {
  private func json(_ value: String) throws -> JSONValue { try JSONDecoder().decode(JSONValue.self, from: Data(value.utf8)) }

  @Test func theConversationSaysTheContractsWords() {
    #expect(TalkCopy.head == "Conversation")
    #expect(TalkCopy.empty == "The conversation is yours to start.")
    #expect([TalkCopy.add, TalkCopy.reply] == ["Add a comment", "Your reply"])
    #expect([TalkCopy.send, TalkCopy.sendReply] == ["Comment", "Reply"])
    // D405 · no control reads Follow or Following (D25), and Mute is the third
    // answer to "Notify me about" rather than its own button
    #expect(TalkCopy.notifyHead == "Notify me about")
    #expect(TalkCopy.Notify.allCases.map(\.label) == ["Every comment", "Replies to me", "Nothing"])
    #expect(TalkCopy.courseSub == "Who of yours has played here, and your circle’s best")
    #expect(TalkCopy.truncated(200, of: 240) == "The newest 200 of 240 comments.")
    #expect(TalkCopy.to("Theo Park") == "To Theo")
    #expect(TalkCopy.replyingTo("Theo Park") == "Replying to Theo")
    #expect(TalkCopy.replyingTo("  ") == "Replying to Someone")
  }

  /// the web's order: muted wins, then a followed thread with its switch on,
  /// then the replies switch
  @Test func theComposersLineSaysWhatYouWillHearAbout() {
    #expect(TalkCopy.hint(state: "muted", followedOn: true, repliesOn: true) == "This conversation is muted.")
    #expect(TalkCopy.hint(state: "following", followedOn: true, repliesOn: false) == "Updates from this conversation are on.")
    #expect(TalkCopy.hint(state: "following", followedOn: false, repliesOn: true) == "You’ll be notified of replies to you.")
    #expect(TalkCopy.hint(state: "none", followedOn: true, repliesOn: true) == "You’ll be notified of replies to you.")
    #expect(TalkCopy.hint(state: "none", followedOn: true, repliesOn: false) == "Reply notifications are off in settings.")
  }

  /// contract v1.3 §1: the line counts the newest page the server sent, never
  /// the rows on screen (a focus rides along outside that page)
  @Test func theTruncationLineCountsTheNewestPage() throws {
    let comment = { (id: Int) in
      "{\"id\":\"00000000-0000-4000-8000-0000000000\(String(format: "%02d", id))\",\"author\":{\"id\":\"33333333-3333-4333-8333-333333333333\",\"name\":\"Avery Fixture\"},\"body\":\"x\"}"
    }
    let paged = PostedRoundThread(try json("""
      {"ok":true,"can_comment":true,"count":240,"page":{"newest":2,"limit":200,"truncated":true},
       "notify_prefs":{"own_round":true,"replies":false,"followed":true},
       "comments":[\(comment(1)),\(comment(2)),\(comment(3))]}
      """))
    #expect(paged.truncated && paged.newest == 2)
    #expect(!paged.repliesOn && paged.followedOn)
    // a server before `page`: the rows it sent, and the count
    let old = PostedRoundThread(try json("""
      {"ok":true,"can_comment":true,"count":5,"comments":[\(comment(1)),\(comment(2))]}
      """))
    #expect(old.truncated && old.newest == 2)
    #expect(old.followedOn && old.repliesOn)
    let whole = PostedRoundThread(try json("""
      {"ok":true,"can_comment":true,"count":2,"page":{"newest":2,"limit":200,"truncated":false},"comments":[\(comment(1)),\(comment(2))]}
      """))
    #expect(!whole.truncated)
  }

  @Test func theCirclesRelationLabelsAreTheContracts() {
    #expect(CircleCopy.relation("me") == "You")
    #expect(CircleCopy.relation("friend") == "Friend")
    #expect(CircleCopy.relation("league") == "In your seasons")
    #expect(CircleCopy.relation("event") == "In your Ryders and Majors")
    #expect(CircleCopy.golferLine(relation: "me", rounds: 1, latest: "Sep 20") == "You · 1 round · last Sep 20")
    #expect(CircleCopy.golferLine(relation: "friend", rounds: 5, latest: nil) == "Friend · 5 rounds")
  }

  @Test func theCirclesLinesAreTheWebs() throws {
    #expect(CircleCopy.bestEyebrow("Your circle best") == "Your circle best · gross")
    #expect(CircleCopy.bestEyebrow(nil) == "Your circle best · gross")
    #expect(CircleCopy.unknownTees(1) == "1 round without a tee we can prove is listed but never compared.")
    #expect(CircleCopy.unknownTees(3) == "3 rounds without a tee we can prove are listed but never compared.")
    #expect(CircleCopy.mostRecent(30, of: 41) == "The 30 most recent of 41.")
    #expect(CircleCopy.tee("White") == "White tees" && CircleCopy.tee(nil) == "Tee not recorded")

    let shared = CourseCirclePage(try json("""
      {"scope":{"label":"Your circle","best_label":"Your circle best","note":"Not an official course record."},
       "selection":{"tee_key":"red:female:18@70/120","tee_name":"Red","holes":18},
       "tees":[{"key":"red:female:18@70/120","name":"Red","gender":"female"}],
       "best":{"gross":80,"tied":true,"eligible_rounds":7},"unknown_tee_rounds":2,"people":[]}
      """))
    #expect(shared.selectionLine == "Shared best · Red · Women’s tees · 18 holes")
    #expect(shared.comparedLine == "7 rounds compared · Your circle")
    #expect(shared.noteLine == "Not an official course record. 2 rounds without a tee we can prove are listed but never compared.")

    let nine = CourseCirclePage(try json("{\"best_unavailable\":\"nine_side_unrecorded\",\"tees\":[{\"key\":\"k\"}]}"))
    #expect(nine.noBestLine == "Nines aren’t compared: which nine was played isn’t recorded. They stay in each golfer’s history.")
    let none = CourseCirclePage(try json("{\"tees\":[{\"key\":\"k\"}]}"))
    #expect(none.noBestLine == "No scores from your circle on these tees for this round length yet.")
    let noTees = CourseCirclePage(try json("{\"tees\":[]}"))
    #expect(noTees.noBestLine == "No round here has a tee we can prove yet, so there is no best to compare.")
  }
}
