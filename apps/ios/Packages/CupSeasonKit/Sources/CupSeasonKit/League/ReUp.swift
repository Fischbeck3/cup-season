// Cup Season — season two is a re-up (D375, as built in 20261115090000): the
// covenant again, a recorded yes. `run_it_back` mints the next season with the
// terms carried, seats only the Pro, and asks every living member through the
// invitation door; a yes lands in `league_members.agreed_seasons`. The words on
// both clients come from one producer each — these are the phone's twins of
// the desk's `csRunItBackDone`, `csReUpDone`, `csAlreadyInLine`, `csAskedAgain`
// and `CS_NOT_IN_YET` (index.html), verbatim.

import Foundation

public enum ReUpCopy {
  /// The roster's mark beside a member whose yes to THIS season is not on record.
  public static let notInYet = "NOT IN YET"

  /// The Pro's sub on the run-it-back door: what the tap does, and no roster
  /// the server has not got.
  public static let proSub = "Same rules, fresh table. Everyone gets the invitation again — the table fills as they say yes."

  /// `csRunItBackDone(seasonNumber, asked)`: the season is on and N invitations
  /// are out. A Pro alone is told the true thing too; a server that did not say
  /// how many it asked gets the one clause that is true on any server.
  public static func runItBackDone(seasonNumber: Int?, asked: Int?) -> String {
    let n = seasonNumber.map { "Season \($0)" } ?? "The next season"
    guard let a = asked else { return "\(n) is on." }
    if a <= 0 { return "\(n) is on. You’re in — share the code and the rest follow." }
    if a == 1 { return "\(n) is on. One invitation is out — the table fills as they say yes." }
    return "\(n) is on. \(a) invitations are out — the table fills as they say yes."
  }

  /// `csReUpDone`: the member's own yes, said once.
  public static func reUpDone(seasonNumber: Int?) -> String {
    (seasonNumber.map { "You’re in for season \($0)." } ?? "You’re in for the new season.") + " Same rules — the table starts fresh."
  }

  /// `csAlreadyInLine`: the covenant's stop when the yes is already on record.
  public static func alreadyIn(seasonNumber: Int?) -> String {
    seasonNumber.map { "You’re already in for season \($0)." } ?? "You’re already in."
  }

  /// `csAskedAgain`: the Pro's ask-again — the same invitation, re-dated, rings again.
  public static func askedAgain(firstName: String?) -> String {
    ((firstName?.isEmpty == false) ? "\(firstName!) is" : "They’re") + " asked again — it rings on their phone."
  }

  /// The roster eyebrow's count: "5 IN FOR SEASON 2".
  public static func inForLine(count: Int, seasonNumber: Int) -> String { "\(count) IN FOR SEASON \(seasonNumber)" }

  /// The web's `inFor(m)`: season one marks nobody; an older database (no
  /// record) marks nobody either; otherwise the yes must be on record.
  public static func inFor(agreedSeasons: [Int]?, seasonNumber: Int) -> Bool {
    guard seasonNumber > 1, let agreed = agreedSeasons else { return true }
    return agreed.contains(seasonNumber)
  }

  /// `csInviteTitle` for a league row: a re-up says which season it is for.
  public static func inviteTitle(reup: Bool?, seasonNumber: Int?) -> String {
    (reup == true && (seasonNumber ?? 0) > 1) ? "Season \(seasonNumber!) invite" : "League invite"
  }
  /// The invitation card's line and the Home item's: what a re-up is, in one sentence.
  public static func reUpLine(seasonNumber: Int, name: String) -> String {
    "Season \(seasonNumber) of \(name) is on. Same rules, fresh table."
  }
}
