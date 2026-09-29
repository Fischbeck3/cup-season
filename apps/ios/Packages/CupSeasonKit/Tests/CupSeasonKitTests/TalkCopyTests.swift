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
    #expect([TalkCopy.follow, TalkCopy.following, TalkCopy.mute, TalkCopy.unmute]
            == ["Follow", "Following", "Mute conversation", "Unmute conversation"])
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
}
