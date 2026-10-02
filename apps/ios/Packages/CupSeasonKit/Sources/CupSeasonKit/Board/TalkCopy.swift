import Foundation

/// D391 · the words a posted round's conversation says, in one place (N4-202,
/// PAR-07). The web's `CS_TALK` (index.html) is the twin, and the contract
/// names most of them — v1.2, `docs/planning/2026-09-25-d391-social-course-contract.md`
/// §Revisions: *"Other copy the web prints (reuse verbatim)"*. The phone had
/// its own set ("Comments", "Start the conversation.", "Follow conversation",
/// "Showing 3 of 240 comments."), so the same thread read two ways.
///
/// **D405 · the conversation lives in line and says whose round it is.** The
/// composer, the round's page and the notices name the golfer and the score
/// from the producers below (the web's twins are `csTalkPlaceholder`,
/// `csTalkRoundTitle`, `csTalkHead`, `csTalkChoice` and `CS_INBOX.line`), and
/// no control reads "Follow" or "Following": the product has no follows (D25).
public enum TalkCopy {
  /// the head when the round's owner is not known; otherwise `conversationHead`
  public static let head = "Conversation"
  public static let empty = "The conversation is yours to start."
  /// the composer's label, over the field
  public static let add = "Add a comment"
  public static let reply = "Your reply"
  public static let send = "Comment"
  public static let sendReply = "Reply"
  public static let failed = "Comment did not send."
  public static let readFailed = "Couldn’t load the conversation."
  /// the ··· menu's one setting (D405). It replaces Follow / Following and
  /// Mute / Unmute: *Every comment*, *Replies to me*, *Nothing*.
  public static let notifyHead = "Notify me about"
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
  /// D405 · a round's owner hears every comment (`own_round`) without having
  /// followed anything, so their line says so rather than "replies to you".
  public static func hint(state: String, followedOn: Bool, repliesOn: Bool,
                          isMine: Bool = false, ownRoundOn: Bool = true) -> String {
    if state == "muted" { return mutedHint }
    if state == "following" && followedOn { return followHint }
    if isMine && ownRoundOn { return followHint }
    return repliesOn ? replyHint : offHint
  }

  // MARK: - D405 · whose round it is

  /// What the composer says it is writing on — *"Comment on Theo’s 84…"*, on
  /// your own round *"Comment on your 79…"* — so a golfer commenting knows it
  /// is on the round above them, and whose. The web's `csTalkPlaceholder`.
  public static func placeholder(owner: String?, gross: Int?, mine: Bool) -> String {
    if mine { return gross.map { "Comment on your \($0)…" } ?? "Comment on your round…" }
    guard let name = named(owner) else { return "Comment on this round…" }
    return gross.map { "Comment on \(first(name))’s \($0)…" } ?? "Comment on \(first(name))’s round…"
  }

  /// The round's own page: *"Theo’s round"* (set in capitals, beside their face);
  /// the page keeps "Your round" for yours and "The round" for an owner the
  /// server did not name. The web's `csTalkRoundTitle`.
  public static func roundTitle(_ owner: String?) -> String {
    named(owner).map { "\(first($0))’s round" } ?? "The round"
  }

  /// The conversation's head on the round's own page: *"On Theo’s 84"*,
  /// *"On your 79"*, and plain "Conversation" for an owner nobody named.
  public static func conversationHead(owner: String?, gross: Int?, mine: Bool) -> String {
    if mine { return gross.map { "On your \($0)" } ?? "On your round" }
    guard let name = named(owner) else { return head }
    return gross.map { "On \(first(name))’s \($0)" } ?? "On \(first(name))’s round"
  }

  /// The button above the newest comments: *"Earlier comments (4)"*.
  public static func earlier(_ n: Int) -> String { "Earlier comments (\(n))" }

  /// The newest comment under a round before anyone taps:
  /// *"Blake: Did the putt on 18 drop?"*.
  public static func preview(author: String, body: String) -> String { "\(first(author)): \(body)" }

  /// The ··· menu's one setting. The server stores a thread state per golfer
  /// per round; this is how the three words map onto it, and the only place
  /// that is written down.
  public enum Notify: String, CaseIterable, Sendable, Identifiable {
    case every, replies, nothing
    public var id: String { rawValue }
    public var label: String {
      switch self {
      case .every: "Every comment"
      case .replies: "Replies to me"
      case .nothing: "Nothing"
      }
    }
    /// the `round_thread_states.state` it writes
    public var state: String {
      switch self {
      case .every: "following"
      case .replies: "replies"
      case .nothing: "muted"
      }
    }
  }

  /// What a golfer is told about a round, given what the server stores. No row
  /// ("none") is the baseline: replies to you, and — for the round's owner,
  /// whose `own_round` switch is on — every comment, because that is what the
  /// server does for them.
  public static func notify(state: String, isMine: Bool, ownRoundOn: Bool) -> Notify {
    switch state {
    case "muted": return .nothing
    case "following": return .every
    default: return (isMine && ownRoundOn) ? .every : .replies
    }
  }

  /// The owner (switch on) is offered two choices: "Replies to me" would say
  /// something the server does not do for them.
  public static func notifyOptions(isMine: Bool, ownRoundOn: Bool) -> [Notify] {
    (isMine && ownRoundOn) ? [.every, .nothing] : [.every, .replies, .nothing]
  }

  /// a name with something in it, or nil
  private static func named(_ name: String?) -> String? {
    guard let name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    return name
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
