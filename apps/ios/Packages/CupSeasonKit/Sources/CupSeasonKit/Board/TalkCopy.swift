import Foundation

/// D391 · the words a posted round's conversation says, in one place (N4-202,
/// PAR-07). The web's `CS_TALK` (index.html) is the twin, and the contract
/// names most of them — v1.2, `docs/planning/2026-09-25-d391-social-course-contract.md`
/// §Revisions: *"Other copy the web prints (reuse verbatim)"*. The phone had
/// its own set ("Comments", "Start the conversation.", "Follow conversation",
/// "Showing 3 of 240 comments."), so the same thread read two ways.
public enum TalkCopy {
  public static let head = "Conversation"
  public static let empty = "The conversation is yours to start."
  /// the composer's label, over the field
  public static let add = "Add a comment"
  public static let reply = "Your reply"
  public static let placeholder = "Something for the crew…"
  public static let send = "Comment"
  public static let sendReply = "Reply"
  public static let failed = "Comment did not send."
  public static let readFailed = "Couldn’t load the conversation."
  public static let follow = "Follow"
  public static let following = "Following"
  public static let mute = "Mute conversation"
  public static let unmute = "Unmute conversation"
  public static let mutedHint = "This conversation is muted."
  public static let followHint = "Updates from this conversation are on."
  public static let replyHint = "You’ll be notified of replies to you."
  public static let offHint = "Reply notifications are off in settings."
  public static let courseSub = "Who of yours has played here, and your circle’s best"
  /// a thread the server no longer shows this golfer: the round is gone for them
  public static let gone = "That round isn’t available any more."
  /// a comment's own actions (the web's row buttons)
  public static let remove = "Remove"
  public static let report = "Report"
  public static let stateFailed = "That setting did not save."
  public static let removeFailed = "Could not remove that comment."

  /// *"The newest 200 of 240 comments."* — `newest` is the page the server
  /// sent (contract §1, `page.newest`), never the rows on screen: a comment
  /// opened from a notice rides along outside that page.
  public static func truncated(_ newest: Int, of all: Int) -> String {
    "The newest \(newest) of \(all) comments."
  }
  /// over the composer while a reply is being written
  public static func replyingTo(_ name: String) -> String { "Replying to \(first(name))" }
  /// on a reply, who it answers
  public static func to(_ name: String) -> String { "To \(first(name))" }

  /// The line under the composer: what this golfer will hear about. The web's
  /// order, exactly: muted wins, then a followed thread with that switch on,
  /// then the replies switch.
  public static func hint(state: String, followedOn: Bool, repliesOn: Bool) -> String {
    if state == "muted" { return mutedHint }
    if state == "following" && followedOn { return followHint }
    return repliesOn ? replyHint : offHint
  }

  /// `csTalkFirst`: the first word of a name, or "Someone".
  static func first(_ name: String) -> String {
    name.split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? "Someone"
  }
}
