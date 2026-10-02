import SwiftUI
import CupSeasonKit

/// D405 · what the views of ONE round's conversation share.
///
/// A thread opens in line under its round on Home, under the same round's post on
/// the board and on the round's own page, so more than one view of one
/// conversation can be alive at once. They share one draft (the words typed, the
/// comment being replied to, the key of a send that has not been answered), as the
/// web's `csTalkDrafts` does: a comment sent from one view never leaves another
/// holding its words as if it had not gone, and a second press of Send from there
/// is the same comment on the server, not a second one.
@MainActor @Observable final class RoundTalk {
  var text = ""
  var replying: SocialComment?
  /// the key of a send that has not been answered: a retry of the same words is the same comment
  var pending: CommentIntent?
  /// what the last send was refused with, kept with the words it was refused for: a thread folded while
  /// it sent has no screen to say it on, and says it when it is opened again
  var sendError: String?
  /// an empty conversation opened to be written in puts the cursor in the composer ONCE:
  /// a thread that reloads, or scrolls back into view, does not bring the keyboard up again
  var autoFocused = false
  /// moves when a write lands from any view (a comment sent or removed, the setting changed):
  /// every other view of the conversation reads it again
  private(set) var changes = 0
  /// how many comments the conversation holds and which is newest, as any view of it last read
  /// or sent; the door under the round (on Home, on the board) follows it. `summaries` moves each time.
  private(set) var summaryCount: Int?
  private(set) var summaryNewest: SocialComment?
  private(set) var summaries = 0

  func wrote() { changes += 1 }

  /// Whether an empty conversation opened to be written in puts the cursor in its composer NOW. It does once
  /// per opening: a thread that reloads, or scrolls back into view, does not bring the keyboard up again.
  func takeAutoFocus(wanted: Bool, visible: Bool, canComment: Bool, empty: Bool) -> Bool {
    guard wanted, !autoFocused, visible, canComment, empty, text.isEmpty else { return false }
    autoFocused = true
    return true
  }
  func summarize(count: Int, newest: SocialComment?) {
    summaryCount = count; summaryNewest = newest; summaries += 1
  }
}

/// What a golfer has typed and not sent, by round, for this launch: folding a thread, or
/// opening another one, must not eat a half-written comment.
@MainActor enum CommentDrafts {
  private static var talks: [UUID: RoundTalk] = [:]
  static func talk(_ round: UUID) -> RoundTalk {
    if let known = talks[round] { return known }
    let made = RoundTalk()
    talks[round] = made
    return made
  }
  /// a sign-out or an account change: what one golfer typed is not another's
  static func reset() { talks = [:] }
}

extension View {
  /// D405 · the door under a round follows its conversation. Whichever view of the thread read or
  /// sent last (in line, on the round's own page, on the other tab), the surface that draws the
  /// door hears how many comments the thread holds and which is newest, without another read.
  func followsThread(_ round: UUID?, _ note: @escaping (UUID, Int, SocialComment?) -> Void) -> some View {
    onChange(of: round.map { CommentDrafts.talk($0).summaries } ?? 0) { _, _ in
      guard let round else { return }
      let talk = CommentDrafts.talk(round)
      if let count = talk.summaryCount { note(round, count, talk.summaryNewest) }
    }
  }
}
