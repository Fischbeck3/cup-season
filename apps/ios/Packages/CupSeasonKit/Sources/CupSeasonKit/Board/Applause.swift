// Cup Season — ONE appreciation action: applause (D365, owner-approved
// option A, 2026-09-15).
//
// The four-token reaction menu is retired from every surface. What remains is
// one quiet control — a two-hand applause glyph and a count — that a golfer
// taps to applaud a round and taps again to take back. Applause appreciates
// participation and connection, not necessarily a good score; comments stay
// for conversation.
//
// **The vocabulary is fixed**: applause (noun) · applaud (action) ·
// applauded (done). Never "clap", "clapped" or "Clap sent".
//
// **What is stored.** The same row the reactions used — `post_kudos
// (post_id, profile_id, emoji)` — with `emoji = 'applause'`. The primary key
// already makes it one applause per golfer per post, the RLS already keys the
// write on the person, and the column accepts the word (≤ 8 characters). No
// migration is needed for the control to work today.
//
// **What is NOT done here, on purpose.** A round fans into one post per
// league, so "one golfer's applause per ROUND across every league copy" needs
// the server to fold copies together — a migration decision, recorded as a
// proposal (`docs/planning/2026-09-15-applause-and-pride-proposals.md`). Until
// then the count is per post, exactly as the reactions were. Historical
// reactions (azalea · jug · eagle · rake) are neither deleted nor summed into
// the count: they are shown, separately, in the people list, and the
// conversion policy is the second proposal. Nothing here notifies anybody.

import Foundation

public enum Applause {
  /// What `post_kudos.emoji` stores for an applause.
  public static let key = "applause"

  // MARK: - the words

  public static let noun = "Applause"
  public static let give = "Give applause"
  public static let remove = "Remove applause"
  /// First-use feedback, once per install.
  public static let sent = "Applause sent"
  public static let failed = "Applause did not save."
  /// The people list's note for reactions left before applause existed.
  public static func earlierNote(_ n: Int) -> String {
    n == 1 ? "1 earlier reaction, from before applause" : "\(n) earlier reactions, from before applause"
  }

  /// In-app activity: "Alex applauded your round" · "Alex and Jade applauded
  /// your round" · "Alex and 2 others applauded your round". Distinct people,
  /// grouped by round; never a sum of taps.
  public static func activity(_ names: [String]) -> String {
    var seen: Set<String> = []
    let who = names.filter { seen.insert($0).inserted }
    switch who.count {
    case 0: return ""
    case 1: return "\(who[0]) applauded your round"
    case 2: return "\(who[0]) and \(who[1]) applauded your round"
    default: return "\(who[0]) and \(who.count - 1) others applauded your round"
    }
  }

  // MARK: - the state of one post

  public struct State: Equatable, Sendable {
    /// Distinct golfers who applauded this post.
    public var n: Int = 0
    public var me: Bool = false
    public var who: [String] = []
    /// Rows written by the retired reaction menu — kept, shown apart, never
    /// counted as applause (the conversion policy is a proposal).
    public var earlier: Int = 0
    public init(n: Int = 0, me: Bool = false, who: [String] = [], earlier: Int = 0) {
      self.n = n; self.me = me; self.who = who; self.earlier = earlier
    }
    /// VoiceOver: the action, the count and the state in one label.
    public var spoken: String {
      let count = n == 0 ? "" : n == 1 ? ", 1 applause" : ", \(n) applause"
      return (me ? Applause.remove : Applause.give) + count + (me ? ", yours" : "")
    }
  }

  /// From the emoji-keyed fold both clients already build.
  public static func state(_ rx: [String: ReactionState]) -> State {
    let a = rx[key] ?? ReactionState()
    let earlier = rx.filter { $0.key != key }.values.reduce(0) { $0 + $1.n }
    return State(n: a.n, me: a.me, who: a.who, earlier: earlier)
  }

  // MARK: - first use

  private static let sentKey = "cs.applause.sent"
  /// True the FIRST time a golfer applauds on this install, so "Applause
  /// sent" is said once and never again.
  public static func firstSend(defaults: UserDefaults = .standard) -> Bool {
    if defaults.bool(forKey: sentKey) { return false }
    defaults.set(true, forKey: sentKey)
    return true
  }
}
