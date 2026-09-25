import Foundation

/// Pending choices belong to the session that opened them, never the next golfer.
public enum SessionActionCleanup {
  public static func clear(defaults: UserDefaults = .standard) {
    JoinIntent.clear(defaults: defaults)
    ClaimIntent.clear(defaults: defaults)
    for kind in ShareIntent.allCases { kind.clear(defaults: defaults) }
  }
}
