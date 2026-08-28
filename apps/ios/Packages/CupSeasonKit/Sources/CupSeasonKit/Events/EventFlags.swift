// Cup Season — the phone's event doors, from `app_flags` (IOS-022 item 7).
//
// One `app_flags` row keyed `ios` carries the phone's own switches; `major`
// opens the Major's door in the event picker. Read the way `PricingFlags.load`
// and `PostService.scanEnabled` read: `.limit(1)`, decode the array, and on
// no row / no read / a bad shape the door stays SHUT (fail closed). The Major
// code ships either way — the flag is the v1 curtain, not a delete.

import Foundation
import Supabase

public enum EventFlags {
  private struct Row: Decodable { let value: JSONValue? }

  /// `app_flags.ios.major == true`, and nothing else. Never throws.
  public static func majorEnabled(_ svc: SupabaseService = .shared) async -> Bool {
    guard let rows: [Row] = try? await svc.client.from("app_flags").select("value").eq("key", value: "ios").limit(1).execute().value,
          let v = rows.first?.value, case .object = v else { return false }
    return v["major"]?.bool == true
  }
}
