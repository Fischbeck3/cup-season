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

    public init(hole: Int, par: Int?, thru: Int, holes: Int, game: String?) {
      self.hole = hole; self.par = par; self.thru = thru; self.holes = holes; self.game = game
    }
  }

  /// Fixed for the life of the round.
  public var course: String
  public init(course: String) { self.course = course }
}

public enum CSRoundActivityLink {
  /// Tapping the island or the lock-screen card lands back in the round.
  public static let url = URL(string: "cupseason://live")!
  public static let host = "live"
}

public extension Notification.Name {
  /// D155 · the island was tapped. Raised by `onOpenURL`, consumed by the tab
  /// view, which already knows how to present the round.
  static let csOpenLiveRound = Notification.Name("cs.openLiveRound")
}
