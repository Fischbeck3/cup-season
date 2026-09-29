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
  public static let nineBest = "Nines aren’t compared: which nine was played isn’t recorded. They stay in each golfer’s history."
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

/// D391 · the words a course's circle says (N4-203, PAR-08). `CS_RELATION` and
/// `csCoursePeopleRender` (index.html) are the twins; the contract names the
/// relation labels ("native should match"), the best's eyebrow and the
/// unknown-tee sentence, and makes the web the copy source for the rest.
public enum CircleCopy {
  /// `me` → "You", never "Your rounds"; never "league mate" or "event".
  public static func relation(_ value: String) -> String? {
    switch value {
    case "me": "You"
    case "friend": "Friend"
    case "league": "In your seasons"
    case "event": "In your Ryders and Majors"
    default: nil
    }
  }
  public static let loading = "Loading who of yours has played it…"
  public static let readFailed = "Couldn’t load the course."
  public static let nothing = "Nothing to show for this course."
  public static let nobody = "Nobody in your circle has posted a round here yet."
  public static let head = "Who’s played here"
  public static let noScores = "No scores from your circle on these tees for this round length yet."
  public static let noTees = "No round here has a tee we can prove yet, so there is no best to compare."
  public static let sharedBest = "Shared best"
  public static let yourBest = "Your best here"
  public static let noTee = "Tee not recorded"

  /// *"Your circle best · gross"* — the scope's own label, then the measure.
  public static func bestEyebrow(_ label: String?) -> String { "\(label ?? "Your circle best") · gross" }
  /// *"3 rounds without a tee we can prove are listed but never compared."*
  public static func unknownTees(_ n: Int) -> String {
    "\(n) \(n == 1 ? "round" : "rounds") without a tee we can prove \(n == 1 ? "is" : "are") listed but never compared."
  }
  /// *"7 rounds compared · Your circle"*
  public static func compared(_ n: Int, scope: String?) -> String {
    "\(n) \(n == 1 ? "round" : "rounds") compared · \(scope ?? "Your circle")"
  }
  /// *"3 rounds on these tees"*, under Your best here
  public static func onTheseTees(_ n: Int) -> String { "\(n) \(n == 1 ? "round" : "rounds") on these tees" }
  /// *"The 30 most recent of 41."*
  public static func mostRecent(_ shown: Int, of all: Int) -> String { "The \(shown) most recent of \(all)." }
  /// *"White tees"*, or the sentence for a tee nobody can prove
  public static func tee(_ name: String?) -> String { name.map { "\($0) tees" } ?? noTee }
  /// A golfer's row: who they are to you, how many rounds, and the last one.
  /// *"Friend · 5 rounds · last Sep 20"*
  public static func golferLine(relation: String, rounds: Int, latest: String?) -> String {
    [CircleCopy.relation(relation), "\(rounds) \(rounds == 1 ? "round" : "rounds")", latest.map { "last \($0)" }]
      .compactMap { $0 }.joined(separator: " · ")
  }
}
