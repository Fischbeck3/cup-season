// Cup Season — the month's pulse, one row per member (`league_pulse`).
//
// D354 · hand-declared beside the generated `Rpc.league_pulse` while the
// migration that grows the row awaits its contract refresh: two more facts,
// both computed the exact way `close_month` decides money — `joined_this_month`
// (the D161 waiver) and `bye_available` (the D14 first-miss cover). Every field
// is optional: a server without the migration answers eight columns and the
// two new ones decode nil, and a fact with no read renders nothing (L-44).
// Same name, same one-argument signature, same grant.

import Foundation

public struct LeaguePulseRow: Decodable, Sendable, Equatable {
  public let profile_id: UUID?
  public let display_name: String?
  public let marker: String?
  public let credits: Double?
  public let floor: Int?
  public let at_floor: Bool?
  public let is_me: Bool?
  public let partial: Bool?
  /// D161 · this member joined during the month the pulse measures, so the
  /// floor is waived for them this month. nil = the server did not say.
  public let joined_this_month: Bool?
  /// D14 · no bye has been spent on this member this season. nil = not said.
  public let bye_available: Bool?

  public init(profile_id: UUID? = nil, display_name: String? = nil, marker: String? = nil, credits: Double? = nil,
              floor: Int? = nil, at_floor: Bool? = nil, is_me: Bool? = nil, partial: Bool? = nil,
              joined_this_month: Bool? = nil, bye_available: Bool? = nil) {
    self.profile_id = profile_id; self.display_name = display_name; self.marker = marker; self.credits = credits
    self.floor = floor; self.at_floor = at_floor; self.is_me = is_me; self.partial = partial
    self.joined_this_month = joined_this_month; self.bye_available = bye_available
  }
}

struct LeaguePulseCall: RpcCall {
  static let name = "league_pulse"
  static let optionalArgs: [String] = []
  typealias Returns = [LeaguePulseRow]
  let p_league: UUID
}
