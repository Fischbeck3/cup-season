import Foundation

/// IOS-009 · the forced-update wall (`app_flags.ios.min_build`), and N4-010:
/// it had no door, clipped its instruction at SE3 AX3 and printed the build
/// as "999,999".
public enum MustUpdateCopy {
  public static let title = "Update Cup Season"
  public static let line = "This build is behind the season. Grab the newest one from TestFlight or the App Store, then come back."

  /// The wall's one door. A wall with no door is a dead end.
  public static let door = "Get the update"

  /// **The one place a store link lives** is the site's /get page
  /// (`get.html`): it carries the public TestFlight invitation now and the
  /// App Store listing on approval day, so the phone never holds a store
  /// link or an App Store ID of its own, and never goes stale when the
  /// listing changes.
  public static let getURL = URL(string: "https://cupseason.app/get")!

  /// A build is a NUMBER, not a quantity: "needs build 1180", never "1,180".
  /// Set it as a plain `String` — a `LocalizedStringKey` interpolation would
  /// group the digits by locale.
  public static func needs(_ minBuild: Int) -> String { "needs build " + String(minBuild) }
}
