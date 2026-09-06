// Cup Season — the bag's two calls (D262, IOS-042, R-O).
//
// `bag_of(p_profile)` reads a golfer's bag behind THE TOUR CARD'S OWN GATE —
// `can_see_profile_board`, the predicate the card states and D238 extracted —
// so a bag is never more public than the card that carries it and there is no
// second privacy switch to get out of step with the first.
//
// `save_bag(p_clubs, p_sideline, p_ball, p_ball_set)` takes the WHOLE bag,
// diffs it server-side and writes one person-homed post only when a club
// actually entered or left the bag or the ball actually changed. The client
// therefore never decides whether something is worth posting; it sends what
// the golfer typed and the database decides what moved (one producer).
//
// Both are hand-declared until the owner's push regenerates `Rpc.swift` from
// the contract (BUILD_PLAN §2's standing rule).
//
// NEITHER DECLARES AN OPTIONAL ARGUMENT, deliberately, and this is the one
// interesting line in the file. `SupabaseService.call` retries a failed call
// with the optional arguments DROPPED — which is right for a new argument on
// an old function, and wrong here twice over: dropping `p_profile` would read
// MY bag and render it under somebody else's name, and dropping `p_ball_set`
// would silently discard a ball the golfer had just typed. A function that
// does not exist yet cannot be helped by a second attempt, so there is none.

import Foundation

/// One row on the way OUT. `id` is the server's, absent for a club the golfer
/// has just typed; the server mints one and keeps the spell dates straight.
public struct BagWrite: Encodable, Sendable {
  public let id: String?
  public let slot: String?
  public let label: String
  public init(id: String?, slot: String?, label: String) {
    self.id = id; self.slot = slot; self.label = label
  }
  public init(_ item: Bag.Item) {
    self.id = item.serverId?.uuidString
    let s = (item.slot ?? "").trimmingCharacters(in: .whitespaces)
    self.slot = s.isEmpty ? nil : s
    self.label = item.label.trimmingCharacters(in: .whitespaces)
  }
}

public struct BagOfCall: RpcCall {
  public static let name = "bag_of"
  public static let optionalArgs: [String] = []
  public typealias Returns = JSONValue
  public var p_profile: UUID?
  public init(p_profile: UUID? = nil) { self.p_profile = p_profile }
}

public struct SaveBagCall: RpcCall {
  public static let name = "save_bag"
  public static let optionalArgs: [String] = []
  public typealias Returns = JSONValue
  /// A nil list means "leave that list exactly as it is" — the synthesised
  /// encoder omits a nil Optional, the argument takes its SQL default, and the
  /// server reads that as untouched. An EMPTY list means "empty it".
  public var p_clubs: [BagWrite]?
  public var p_sideline: [BagWrite]?
  public var p_ball: String?
  public var p_ball_set: Bool
  public init(p_clubs: [BagWrite]? = nil, p_sideline: [BagWrite]? = nil,
              p_ball: String? = nil, p_ball_set: Bool = false) {
    self.p_clubs = p_clubs; self.p_sideline = p_sideline
    self.p_ball = p_ball; self.p_ball_set = p_ball_set
  }
}

public struct BagService: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  /// nil is "the read did not happen" — no session, no signal, or a database
  /// this migration has not reached. It is NOT "an empty bag", and no caller
  /// may narrate it as one: the surfaces draw nothing at all on nil, which is
  /// what makes the deploy-skew window honest instead of empty (L-32).
  public func load(_ profile: UUID? = nil) async -> Bag? {
    guard let payload = try? await svc.call(BagOfCall(p_profile: profile)) else { return nil }
    return Bag.parse(payload)
  }

  /// Throws on refusal — the fifteenth club, a lost session, an unreachable
  /// database — so the editor can say what happened instead of pretending the
  /// save landed.
  @discardableResult
  public func save(clubs: [Bag.Item]?, sideline: [Bag.Item]?,
                   ball: String?, ballSet: Bool) async throws -> Bag {
    let payload = try await svc.call(SaveBagCall(
      p_clubs: clubs.map { $0.filter { !$0.label.trimmingCharacters(in: .whitespaces).isEmpty }.map(BagWrite.init) },
      p_sideline: sideline.map { $0.filter { !$0.label.trimmingCharacters(in: .whitespaces).isEmpty }.map(BagWrite.init) },
      p_ball: ball, p_ball_set: ballSet))
    return Bag.parse(payload)
  }
}
