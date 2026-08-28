// Cup Season — what the door may offer (IOS-023).
//
// One `app_flags` row keyed `ios` (migration 20260827130100 seeds
// `{min_build}`) gains `apple_sign_in` when the owner has configured the
// Apple provider. Mirrors `PricingFlags.load()`: `.limit(1)`, decode the
// array, and FAIL CLOSED — no row, no read, a bad value, a missing key: the
// button does not render. The read never blocks the email field.
//
// Known gap, on the record: `flags_read` is granted to `authenticated` only
// (anon holds zero relation privileges — CLAUDE.md), and the door is signed
// out. Until an anon-callable read exists (a SECURITY DEFINER RPC returning
// only `{apple_sign_in}` — the owner's migration), this decodes to closed in
// prod. `-cs_dev_apple` (DEBUG) forces it open for a look.

import Foundation
import Supabase
import CupSeasonKit

struct DoorFlags: Decodable, Sendable, Equatable {
  let appleSignIn: Bool

  init(appleSignIn: Bool) { self.appleSignIn = appleSignIn }

  /// Lenient on every key, closed on the one that matters.
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    appleSignIn = try c.decodeIfPresent(Bool.self, forKey: .appleSignIn) ?? false
  }
  enum CodingKeys: String, CodingKey { case appleSignIn = "apple_sign_in" }

  /// What every failure decodes to.
  static let closed = DoorFlags(appleSignIn: false)

  private struct Row: Decodable { let value: DoorFlags? }

  /// The row's `value` jsonb as bytes → flags. Bad shape → closed.
  static func decode(_ data: Data) -> DoorFlags {
    (try? JSONDecoder().decode(DoorFlags.self, from: data)) ?? .closed
  }

  /// `door_flags()` — hand-declared (migration 20260827190000; anon-callable,
  /// returns only `apple_sign_in`). The generator picks it up on the next
  /// contract refresh.
  struct Call: RpcCall {
    static let name = "door_flags"
    static let optionalArgs: [String] = []
    typealias Returns = JSONValue
  }

  /// The door is signed out, so the RPC is the real path; the table read
  /// only works for a signed-in re-render. Never throws; closed on anything.
  static func load(_ svc: SupabaseService = .shared) async -> DoorFlags {
    if let json = try? await svc.call(Call()), let on = json["apple_sign_in"]?.bool {
      return DoorFlags(appleSignIn: on)
    }
    guard let rows: [Row] = try? await svc.client.from("app_flags").select("value").eq("key", value: "ios").limit(1).execute().value,
          let flags = rows.first?.value else { return .closed }
    return flags
  }
}
