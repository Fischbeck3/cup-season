// Cup Season — the buddies + invites data layer (audit 05 §2F, §2H, §8).
//
// Every write is an RPC through `SupabaseService.call`; the one direct read is
// `profiles.discoverable` (a column the D37 seal grants by name).

import Foundation
import Supabase

/// Where an invite lands: `invite_golfer(p_league|p_event)` (16365).
public enum InviteTarget: Sendable, Equatable {
  case league(UUID)
  case event(UUID)
}

/// `invite_golfer` takes BOTH container args and expects the other to be
/// null — the generator maps non-defaulted uuids to `UUID`, which cannot say
/// null. This call encodes the absent one as an explicit JSON null (an omitted
/// key would fail PostgREST's signature match). Same name, same grant.
struct InviteGolferCall: RpcCall {
  static let name = "invite_golfer"
  static let optionalArgs: [String] = []
  typealias Returns = UUID
  let p_league: UUID?
  let p_event: UUID?
  let p_profile: UUID
  enum Keys: String, CodingKey { case p_league, p_event, p_profile }
  func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: Keys.self)
    try c.encode(p_league, forKey: .p_league)
    try c.encode(p_event, forKey: .p_event)
    try c.encode(p_profile, forKey: .p_profile)
  }
}

public struct PeopleService: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  // MARK: buddies

  /// `psSearch` (13161): one letter is enough (pilot: "M" must find @mm…).
  public func search(_ q: String) async throws -> [Person] {
    try await svc.call(Rpc.search_golfers(p_q: q)).compactMap(Person.init)
  }

  public func friends() async throws -> BuddyLists {
    BuddyLists.partition(try await svc.call(Rpc.my_friends()))
  }

  /// `friend_request` — 'friend' when the intent was mutual, else 'requested'.
  public func request(_ profile: UUID) async throws -> Rel {
    Rel(try await svc.call(Rpc.friend_request(p_profile: profile)))
  }

  public func respond(_ friendship: UUID, accept: Bool) async throws {
    _ = try await svc.call(Rpc.friend_respond(p_id: friendship, p_accept: accept))
  }

  // MARK: discoverability

  private struct DiscRow: Decodable { let discoverable: String? }

  public func discoverable() async throws -> Discoverable {
    guard let uid = await svc.currentSession()?.user.id else { return .everyone }
    let rows: [DiscRow] = try await svc.client.from("profiles").select("discoverable").eq("id", value: uid).execute().value
    return Discoverable(rawValue: rows.first?.discoverable ?? "") ?? .everyone
  }

  public func setDiscoverable(_ mode: Discoverable) async throws {
    _ = try await svc.call(Rpc.set_discoverable(p_mode: mode.rawValue))
  }

  // MARK: invites (decision B: consent-based add)

  public func invites() async throws -> [Invite] {
    try await svc.call(Rpc.my_invites()).compactMap(Invite.init)
  }

  public func respondInvite(_ id: UUID, accept: Bool) async throws {
    _ = try await svc.call(Rpc.respond_invite(p_id: id, p_accept: accept))
  }

  public func invite(_ profile: UUID, to target: InviteTarget) async throws {
    switch target {
    case .league(let l): _ = try await svc.call(InviteGolferCall(p_league: l, p_event: nil, p_profile: profile))
    case .event(let e): _ = try await svc.call(InviteGolferCall(p_league: nil, p_event: e, p_profile: profile))
    }
  }

  public func addFriendToLeague(_ profile: UUID, league: UUID) async throws {
    _ = try await svc.call(Rpc.add_friend_to_league(p_league: league, p_profile: profile))
  }
}

/// `founderTag` (10115): "✦ Founder" beside the founder's name. One read,
/// cached for the session — `founder_id` is a public endpoint.
public actor FounderBadge {
  public static let shared = FounderBadge()
  private var cached: UUID?
  private var tried = false

  public func id(_ svc: SupabaseService = .shared) async -> UUID? {
    if tried { return cached }
    tried = true
    cached = try? await svc.call(Rpc.founder_id())
    return cached
  }

  public static let tag = "✦ Founder"
}
