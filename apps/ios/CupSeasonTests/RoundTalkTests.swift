// D405 · one conversation, more than one view of it. A thread opens in line under its
// round on Home, under the same round's post on the board and on the round's own page;
// the views share one draft, hear each other's writes, and a sign-out leaves nothing behind.

import Testing
import Foundation
import CupSeasonKit
@testable import CupSeason

@MainActor
@Suite struct RoundTalkTests {
  private func comment(_ body: String) -> SocialComment {
    let json: JSONValue = .object([
      "id": .string(UUID().uuidString),
      "author": .object(["id": .string(UUID().uuidString), "name": .string("Blake Hartwell")]),
      "body": .string(body), "created_at": .string("2026-09-25T18:10:00Z"),
    ])
    return SocialComment(json)!
  }

  @Test("every view of one round holds the same draft, and another round's draft is its own")
  func oneDraftPerRound() {
    CommentDrafts.reset()
    let round = UUID()
    let inLine = CommentDrafts.talk(round), onThePage = CommentDrafts.talk(round)
    #expect(inLine === onThePage)
    inLine.text = "One draft, two places"
    inLine.replying = comment("Same ball?")
    #expect(onThePage.text == "One draft, two places" && onThePage.replying?.body == "Same ball?")
    #expect(CommentDrafts.talk(UUID()).text.isEmpty && CommentDrafts.talk(UUID()).replying == nil)
  }

  @Test("a write and a read of the thread are counted, for the views and the doors that watch the counters")
  func writesAndReadsAreCounted() {
    CommentDrafts.reset()
    let round = UUID()
    let talk = CommentDrafts.talk(round)
    #expect(talk.changes == 0 && talk.summaries == 0 && talk.summaryCount == nil)
    talk.wrote()
    #expect(talk.changes == 1)
    let newest = comment("Did the putt on 18 drop?")
    talk.summarize(count: 4, newest: newest)
    #expect(talk.summaryCount == 4 && talk.summaryNewest?.id == newest.id && talk.summaries == 1)
    talk.summarize(count: 0, newest: nil)
    #expect(talk.summaryCount == 0 && talk.summaryNewest == nil && talk.summaries == 2)
  }

  @Test("an empty conversation opened to be written in puts the cursor in once per opening")
  func theCursorComesOncePerOpening() {
    CommentDrafts.reset()
    let talk = CommentDrafts.talk(UUID())
    #expect(talk.takeAutoFocus(wanted: true, visible: true, canComment: true, empty: true), "the first read of an empty conversation")
    #expect(!talk.takeAutoFocus(wanted: true, visible: true, canComment: true, empty: true), "a reload does not bring the keyboard back")
    talk.autoFocused = false   // the door opens it again
    #expect(talk.takeAutoFocus(wanted: true, visible: true, canComment: true, empty: true))
    talk.autoFocused = false
    #expect(!talk.takeAutoFocus(wanted: false, visible: true, canComment: true, empty: true), "a thread that was not opened to write in")
    #expect(!talk.takeAutoFocus(wanted: true, visible: true, canComment: true, empty: false), "a conversation with comments in it")
    #expect(!talk.takeAutoFocus(wanted: true, visible: true, canComment: false, empty: true), "a golfer who cannot comment")
    talk.text = "half a thought"
    #expect(!talk.takeAutoFocus(wanted: true, visible: true, canComment: true, empty: true), "never over words already typed")
  }

  @Test("a sign-out or an account change leaves no draft behind")
  func resetForgetsEverything() {
    let round = UUID()
    CommentDrafts.talk(round).text = "Half a thought"
    CommentDrafts.talk(round).autoFocused = true
    CommentDrafts.talk(round).sendError = "Comment did not send. Easy — try again in a minute."
    CommentDrafts.reset()
    #expect(CommentDrafts.talk(round).text.isEmpty && CommentDrafts.talk(round).autoFocused == false)
    #expect(CommentDrafts.talk(round).sendError == nil, "a refusal goes with the words it was refused for")
  }
}
