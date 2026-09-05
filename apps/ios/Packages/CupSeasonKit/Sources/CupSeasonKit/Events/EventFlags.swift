// Cup Season — the phone's event doors, from `app_flags` (IOS-022 item 7).
//
// One `app_flags` row keyed `ios` carries the phone's own switches; `major`
// opens the Major's door in the event picker and un-darkens the four Home
// occasion cards that sell a jug. Read the way `PricingFlags.load` and
// `PostService.scanEnabled` read: `.limit(1)`, decode the array, and on no row
// / no read / a bad shape the door stays SHUT (fail closed).
//
// **D252 / R-E — the flag is being opened**, by
// `supabase/migrations/20260912090000_the_major_opens.sql`. The read does not
// change and must not: the Major's code has always shipped, the flag is the
// curtain, and the curtain has to keep working in both directions — an owner
// who wants the door shut again does it from the SQL editor with no submission.
//
// **One answer per launch.** Two surfaces ask this question (the picker, and
// Home on a day a gated occasion would show), and before this they asked the
// server twice for a boolean that cannot change while the app is open. A
// SUCCESSFUL read is remembered for the life of the process; a FAILED one is
// not, so a dead network on the first ask does not shut the door for the rest
// of the session — it fails closed once and tries again next time.

import Foundation

public actor EventFlagCache {
  public static let shared = EventFlagCache()
  private var major: Bool?
  func majorEnabled(_ svc: SupabaseService) async -> Bool {
    if let major { return major }
    guard let v = await EventFlags.read(svc) else { return false }
    major = v
    return v
  }
  /// The tests' hatch, and the one an owner-facing "refresh flags" would use.
  public func forget() { major = nil }
}

public enum EventFlags {
  private struct Row: Decodable { let value: JSONValue? }

  /// `app_flags.ios.major == true`, and nothing else. Never throws.
  public static func majorEnabled(_ svc: SupabaseService = .shared) async -> Bool {
    await EventFlagCache.shared.majorEnabled(svc)
  }

  /// The read itself. `nil` = it did not answer (no row, no network, a shape
  /// this build does not know) — which the caller turns into a shut door, but
  /// does NOT remember.
  static func read(_ svc: SupabaseService) async -> Bool? {
    guard let rows: [Row] = try? await svc.client.from("app_flags").select("value").eq("key", value: "ios").limit(1).execute().value,
          let v = rows.first?.value, case .object = v else { return nil }
    return v["major"]?.bool == true
  }
}
