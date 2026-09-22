// Cup Season — the Pro's pen (D376): one RPC (`adjust_points`), one producer
// for the words on both clients. The desk's twins are `CS_RULING_WHAT`,
// `CS_RULING_NOT_YET` and `csRulingDone` in index.html; the sentences here are
// verbatim with them (D297: one producer per client, the same words on both).
// Scoring stays in the database: the phone sends a member, a delta and a
// reason, and reads the total the server answers with.

import Foundation

public enum RulingCopy {
  /// The sheet's opening sentence — what a ruling is and is not.
  public static let what = "A ruling moves points in the ledger with a reason. It posts to the board and every golfer can open it. Rounds are never changed. Once the Final window opens the ledger is closed — the crew settles it."
  /// Deploy skew: the RPC is not on the server this build talks to.
  public static let notYet = "Rulings need the latest update — try again shortly."
  /// The sheet's eyebrow and title, as the desk says them.
  public static let title = "A ruling"
  public static let eyebrow = "THE PRO RULES · LOGGED, ON THE BOARD"
  public static let button = "Record the ruling"
  public static let reasonHint = "Wrong card on the 7th"

  /// The server's own bounds, said once here and checked before the call.
  public static let maxDelta = 50
  public static let reasonRange = 3...240

  /// The two refusals the desk toasts before it calls the server.
  public static let deltaRefused = "A ruling moves between 1 and 50 points, up or down."
  public static let reasonRefused = "Say why — a ruling carries its reason."

  /// nil when the ruling may be sent; otherwise the sentence to show.
  public static func refusal(delta: Int?, reason: String) -> String? {
    guard let delta, delta != 0, abs(delta) <= maxDelta else { return deltaRefused }
    guard reasonRange.contains(reason.trimmingCharacters(in: .whitespacesAndNewlines).count) else { return reasonRefused }
    return nil
  }

  /// `csRulingDone(name, delta, total)`: "Ruled — Danny +3 points. Now 41. It’s on the board."
  public static func done(_ name: String, delta: Int, total: Int?) -> String {
    let sign = delta > 0 ? "+" : "−"
    let pts = abs(delta) == 1 ? " point" : " points"
    let now = total.map { ". Now \($0)." } ?? "."
    return "Ruled — \(name) \(sign)\(abs(delta))\(pts)\(now) It’s on the board."
  }

  /// A ruling's line on a receipt — month · who ruled · why (§16: the path
  /// behind the figure). The desk prints the same three parts.
  public static func ledgerLine(month: String?, reason: String?) -> String {
    [month.map { LeagueDates.monDay($0).split(separator: " ").first.map(String.init) ?? $0 },
     "The Pro ruled",
     reason ?? "a ruling"].compactMap { $0 }.joined(separator: " · ")
  }
}
