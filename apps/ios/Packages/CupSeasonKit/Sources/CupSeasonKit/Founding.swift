// Cup Season — Founder and Founding Member (D102).
//
// Two earned tags on the golfer: the one founder (`profiles.is_founder`, the
// web's `✦ Founder`) and the hand-picked founding members
// (`profiles.founding_member`). One read per session through
// `founding_ids()`; a phone ahead of the migration falls back to the web's
// `founder_id()` and tags only the founder — never blank, never wrong.

import Foundation
import Supabase

public enum FoundingBadge: Sendable, Equatable {
  case founder, member

  /// `✦ FOUNDER` · `✦ FOUNDING MEMBER` — mono, uppercase, gold (earned).
  public var label: String {
    switch self {
    case .founder: "✦ Founder"
    case .member: "✦ Founding member"
    }
  }
  public var accessibilityLabel: String {
    switch self {
    case .founder: "Cup Season founder"
    case .member: "Founding member"
    }
  }
}

public struct FoundingIds: Sendable, Equatable {
  public var founder: UUID?
  public var members: Set<UUID>
  public init(founder: UUID? = nil, members: Set<UUID> = []) { self.founder = founder; self.members = members }

  /// The founder outranks a member; most golfers carry nothing.
  public func badge(for profileId: UUID?) -> FoundingBadge? {
    guard let profileId else { return nil }
    if profileId == founder { return .founder }
    if members.contains(profileId) { return .member }
    return nil
  }

  /// `founding_ids()`, then `founder_id()` on any failure (deploy skew: the
  /// client may ship before the migration). Never throws.
  public static func load(_ svc: SupabaseService = .shared) async -> FoundingIds {
    if let json = try? await svc.call(Rpc.founding_ids()) {
      let founder = json["founder"]?.string.flatMap(UUID.init)
      let members = (json["members"]?.array ?? []).compactMap { $0.string.flatMap(UUID.init) }
      return FoundingIds(founder: founder, members: Set(members))
    }
    let f = try? await svc.call(Rpc.founder_id())
    return FoundingIds(founder: f, members: [])
  }
}
