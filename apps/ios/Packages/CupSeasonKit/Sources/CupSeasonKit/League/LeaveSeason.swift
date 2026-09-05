// Cup Season — leaving a season (C-9 `leave_season`, D244).
//
// There has never been a member exit on either client: the room hero's
// "Cancel" is the Pro's, and a member who wanted out had to ask for the whole
// season to be cancelled or quietly stop posting. A competition somebody
// cannot leave is a competition they will not join.
//
// THE COPY SAYS EXACTLY WHAT HAPPENS AND NOTHING ELSE. Three sentences, and
// each one is a fact the server can be held to:
//
//   "Your rounds stay where they are."   — L-02, no round is ever mutated
//   "Your name stays on the season you played."  — §16, the table keeps the
//                                                  history that happened
//   "You stop scoring from today."       — the forward-only cut in
//                                          `v_rounds_ranked` (`left_at`)
//
// A leaver is not announced as a defection, not shamed, and not counted
// anywhere. The Pro is told once, plainly, on the board — the server writes
// that line, so it says the same thing whichever client was used.

import Foundation

public enum LeaveSeason {

  /// What the door may be, for this viewer, right now.
  public enum Gate: Sendable, Equatable {
    /// A member who is still scoring: the door is offered.
    case offer
    /// The Pro cannot walk out of their own season — `transfer_pro` first.
    /// A refusal that says why is a door; a hidden control is a mystery.
    case proMustHandOver
    /// Already left. The state is stated once, and nothing is offered twice.
    case alreadyLeft
  }

  public static func gate(isPro: Bool, hasLeft: Bool) -> Gate {
    if hasLeft { return .alreadyLeft }
    return isPro ? .proMustHandOver : .offer
  }

  // MARK: - The words

  public static let head = "Leave the season"

  /// D244's own sentence, verbatim. It is the whole of what happens.
  public static let body =
    "Your rounds stay where they are. Your name stays on the season you played. You stop scoring from today."

  /// L-32 · two taps, never an alert. The armed label restates the consequence
  /// rather than asking "are you sure" about nothing.
  public static let armed = "Sure? You stop scoring today"

  /// The Pro's refusal, in the app's voice — the same fact the server states.
  public static let proNote = "Hand the season to somebody else first — a season needs a Pro."

  /// After the act, on the page that is still open.
  public static let leftNote = "You left this season. Your rounds and your place stay exactly where they are."

  public static func done(_ league: String?) -> String {
    let n = (league?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
    return "You left \(n ?? "the season"). Your rounds stay on your card."
  }
}

/// `leave_season(p_league)` — hand-declared, because the migration that
/// creates it is written and unpushed (the documented shape while a migration
/// awaits its contract refresh; preflight 17 still demands the grant).
/// The argument is defaulted on both sides.
struct LeaveSeasonCall: RpcCall {
  static let name = "leave_season"
  static let optionalArgs: [String] = ["p_league"]
  typealias Returns = LeaveResult
  var p_league: UUID?
}

/// What the server says came of it. `already` is true when the golfer had
/// already left — leaving twice is leaving once, and it writes no second
/// board line (L-20).
public struct LeaveResult: Decodable, Sendable, Equatable {
  public let left_at: String?
  public let league: String?
  public let already: Bool?
  public init(left_at: String? = nil, league: String? = nil, already: Bool? = nil) {
    self.left_at = left_at; self.league = league; self.already = already
  }
}

/// `season_story(p_season, p_league)` — R6, hand-declared for the same reason.
/// Both arguments are optional on both sides: the page holds a league id and
/// the epilogue holds a season id, and either one answers.
struct SeasonStoryCall: RpcCall {
  static let name = "season_story"
  static let optionalArgs: [String] = ["p_season", "p_league"]
  typealias Returns = SeasonStory.Payload
  var p_season: UUID?
  var p_league: UUID?
}
