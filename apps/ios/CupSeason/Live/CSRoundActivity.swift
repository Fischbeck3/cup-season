// Cup Season — D155 · the shape the Live Activity carries.
//
// This file is compiled into BOTH the app and the widget extension (see
// `project.yml`), which is why it imports nothing but ActivityKit: the
// extension must not drag in the Supabase client to draw three facts.
//
// The facts themselves are produced by `LiveCopy.activity(_:)` — the same place
// the scoreboard and the card get their sentences — so the island can never
// disagree with the screen it is a shortcut to. Nothing is computed here.

import ActivityKit
import Foundation

public struct CSRoundActivity: ActivityAttributes {
  /// What changes as the round is played.
  public struct ContentState: Codable, Hashable, Sendable {
    /// 1-based, for display
    public var hole: Int
    public var par: Int?
    /// holes the whole group has finished
    public var thru: Int
    public var holes: Int
    /// the side game's one line ("ALL SQUARE", "2 UP"). nil for a "just score"
    /// round — nothing is won hole by hole there, and drawing a line would
    /// invent a competition nobody is playing.
    public var game: String?
    /// D178 · what the COMPACT island shows, authored by `LiveCopy.activity`
    /// rather than truncated in the widget. Optional with a default so an
    /// activity started by an older build still decodes.
    public var compact: String?
    public var opponent: String?
    public var result: String?
    public var detail: String?
    public var resultThrough: Int?
    public var score: Int?
    public var canScore: Bool?
    public var saveState: String?

    public init(hole: Int, par: Int?, thru: Int, holes: Int, game: String?, compact: String? = nil) {
      self.hole = hole; self.par = par; self.thru = thru; self.holes = holes
      self.game = game; self.compact = compact
    }
  }

  /// Fixed for the life of the round.
  public var course: String
  public var round: UUID?
  public var owner: UUID?
  public init(course: String, round: UUID? = nil, owner: UUID? = nil) {
    self.course = course; self.round = round; self.owner = owner
  }
}

public enum CSRoundActivityLink {
  /// Tapping the island or the lock-screen card lands back in the round.
  public static let url = URL(string: "cupseason://live")!
  public static let host = "live"
  public static func url(round: UUID?, owner: UUID?, review: Bool = false) -> URL {
    guard let round, let owner else { return url }
    var link = URLComponents(); link.scheme = "cupseason"; link.host = host
    link.queryItems = [.init(name: "round", value: round.uuidString), .init(name: "owner", value: owner.uuidString)]
    if review { link.queryItems?.append(.init(name: "review", value: "1")) }
    return link.url!
  }
}

public extension Notification.Name {
  /// D155 · the island was tapped. Raised by `onOpenURL`, consumed by the tab
  /// view, which already knows how to present the round.
  static let csOpenLiveRound = Notification.Name("cs.openLiveRound")
  /// D241 / D253 · a person or plan token was just stored by `onOpenURL`.
  /// The shell drains pending tokens on every session change anyway; this is
  /// what makes a link tapped while the app is ALREADY open land at once
  /// rather than on the next cold start.
  static let csShareTokenPending = Notification.Name("cs.shareTokenPending")
  /// D351 (built) · a `?join=` code was just stored by `onOpenURL`. `RootView`
  /// reads the pending code on appear and on a change of golfer; this is what
  /// makes a link tapped while the app is ALREADY open and signed in present
  /// the covenant at once, exactly once, rather than on the next cold start.
  static let csJoinCodePending = Notification.Name("cs.joinCodePending")
  /// Launch audit L-06 · a `?claim=` token was just stored by `onOpenURL`. The
  /// join's twin: signed out, the root re-reads the pending claim and shows the
  /// guest pencil; signed in, it runs `LiveClaimAfterAuth` at once rather than
  /// on the next cold start.
  static let csClaimTokenPending = Notification.Name("cs.claimTokenPending")
}
