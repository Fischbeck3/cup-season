// Cup Season — the push contract, phone side (docs/ios/push-contract.md §1–§3,
// D104 / IOS-026). Pure: a `userInfo` dictionary in, a destination out. The
// sender is built against the same document, so the key names here are the
// contract's, verbatim — change them there first.
//
// `v` is the contract version; a payload with a `v` this build does not know
// decodes to nil and the app lands Home. Only the ids that exist for a kind
// are present, so every id is optional and the route decides what a missing
// one means (always Home, never a blank).

import Foundation

/// `cs.kind` — one per sentence the board can say.
public enum PushKind: String, Sendable, CaseIterable {
  case round, chat, announce, moment, system, settlement
  case live_open, nudge, invite, request, rsvp, event
}

/// The `cs` object of an APNs payload, decoded.
public struct PushPayload: Sendable, Equatable {
  public static let version = 1

  public let kind: PushKind?
  public let leagueId: UUID?
  public let postId: UUID?
  public let roundId: UUID?
  public let liveRoundId: UUID?
  public let eventId: UUID?
  public let profileId: UUID?
  public let scheduledRoundId: UUID?
  public let requestId: UUID?
  public let inviteId: UUID?
  /// `aps.category` — present only when the notification is actionable (§3).
  public let category: String?

  public init(kind: PushKind?, leagueId: UUID? = nil, postId: UUID? = nil, roundId: UUID? = nil, liveRoundId: UUID? = nil,
              eventId: UUID? = nil, profileId: UUID? = nil, scheduledRoundId: UUID? = nil, requestId: UUID? = nil,
              inviteId: UUID? = nil, category: String? = nil) {
    self.kind = kind; self.leagueId = leagueId; self.postId = postId; self.roundId = roundId; self.liveRoundId = liveRoundId
    self.eventId = eventId; self.profileId = profileId; self.scheduledRoundId = scheduledRoundId; self.requestId = requestId
    self.inviteId = inviteId; self.category = category
  }

  /// The whole `userInfo` (`aps` + `cs`). Nil when `cs` is absent or its `v`
  /// is not one this build reads.
  public init?(userInfo: [AnyHashable: Any]) {
    guard let cs = userInfo["cs"] as? [String: Any] else { return nil }
    let aps = userInfo["aps"] as? [String: Any]
    self.init(cs: cs, category: aps?["category"] as? String)
  }

  /// The `cs` object alone (the dev hatch feeds this).
  public init?(cs: [String: Any], category: String? = nil) {
    guard Self.int(cs["v"]) == Self.version else { return nil }
    let id: (String) -> UUID? = { key in (cs[key] as? String).flatMap(UUID.init(uuidString:)) }
    self.init(kind: (cs["kind"] as? String).flatMap(PushKind.init(rawValue:)),
              leagueId: id("league_id"), postId: id("post_id"), roundId: id("round_id"), liveRoundId: id("live_round_id"),
              eventId: id("event_id"), profileId: id("profile_id"), scheduledRoundId: id("scheduled_round_id"),
              requestId: id("request_id"), inviteId: id("invite_id"), category: category)
  }

  /// `v` arrives as a number from APNs and as a string from some senders.
  private static func int(_ v: Any?) -> Int? {
    if let n = v as? Int { return n }
    if let n = v as? Double { return Int(n) }
    if let s = v as? String { return Int(s) }
    if let n = v as? NSNumber { return n.intValue }
    return nil
  }
}

/// Where a tap lands (§2). Every case names a Presenter field or a tab path.
public enum PushRoute: Sendable, Equatable {
  case receipt(UUID)
  case scorecard(UUID)
  case board(UUID)
  case live(UUID)
  case event(UUID)
  case invites
  case requests
  case scheduledRound(UUID)
  case home

  /// The contract's table. A kind whose id is missing lands Home.
  public static func from(_ p: PushPayload) -> PushRoute {
    guard let kind = p.kind else { return .home }
    switch kind {
    case .round: return p.roundId.map(PushRoute.receipt) ?? .home
    case .settlement: return p.liveRoundId.map(PushRoute.scorecard) ?? .home
    case .chat, .announce, .moment, .system: return p.leagueId.map(PushRoute.board) ?? .home
    case .live_open: return p.liveRoundId.map(PushRoute.live) ?? .home
    case .nudge:
      if let e = p.eventId { return .event(e) }
      if let lr = p.liveRoundId { return .live(lr) }
      return .home
    case .event: return p.eventId.map(PushRoute.event) ?? .home
    case .invite: return .invites
    case .request: return .requests
    case .rsvp: return p.scheduledRoundId.map(PushRoute.scheduledRound) ?? .home
    }
  }

  /// The word telemetry keeps (`push_opened {route}`).
  public var name: String {
    switch self {
    case .receipt: "receipt"
    case .scorecard: "scorecard"
    case .board: "board"
    case .live: "live"
    case .event: "event"
    case .invites: "invites"
    case .requests: "requests"
    case .scheduledRound: "scheduled_round"
    case .home: "home"
    }
  }
}

// MARK: - §3 categories and actions

/// The three actionable categories and their action identifiers — the
/// strings the sender puts in `aps.category`, verbatim.
public enum PushCategory: String, Sendable, CaseIterable {
  case request = "CS_REQUEST"
  case rsvp = "CS_RSVP"
  case invite = "CS_INVITE"

  public enum Action {
    public static let accept = "ACCEPT"
    public static let decline = "DECLINE"
    public static let rsvpIn = "IN"
    public static let rsvpOut = "OUT"
  }

  /// The action ids this category registers, in lock-screen order, with the
  /// word each button wears.
  public var actions: [(id: String, title: String)] {
    switch self {
    case .request: [(Action.accept, "Accept"), (Action.decline, "Decline")]
    case .rsvp: [(Action.rsvpIn, "I’m in"), (Action.rsvpOut, "Can’t")]
    case .invite: [(Action.accept, "Accept")]
    }
  }
}

/// What a lock-screen action does — the SAME RPCs the screens call, as a
/// value so the mapping is testable without a notification center.
public enum PushActionCall: Sendable, Equatable {
  /// `friend_respond(p_id, p_accept)` — the Requests screen's hand.
  case friendRespond(id: UUID, accept: Bool)
  /// `set_round_rsvp(p_round, p_status)` — the scheduled round sheet's `in` / `out`.
  case roundRsvp(round: UUID, status: String)
  /// `respond_invite(p_id, p_accept)` — the invites banner's Accept.
  case respondInvite(id: UUID, accept: Bool)

  /// Nil when the category, action or id does not line up — nothing runs.
  public static func resolve(category: String?, action: String, payload: PushPayload) -> PushActionCall? {
    guard let cat = category.flatMap(PushCategory.init(rawValue:)) else { return nil }
    switch (cat, action) {
    case (.request, PushCategory.Action.accept): return payload.requestId.map { .friendRespond(id: $0, accept: true) }
    case (.request, PushCategory.Action.decline): return payload.requestId.map { .friendRespond(id: $0, accept: false) }
    case (.rsvp, PushCategory.Action.rsvpIn): return payload.scheduledRoundId.map { .roundRsvp(round: $0, status: "in") }
    case (.rsvp, PushCategory.Action.rsvpOut): return payload.scheduledRoundId.map { .roundRsvp(round: $0, status: "out") }
    case (.invite, PushCategory.Action.accept): return payload.inviteId.map { .respondInvite(id: $0, accept: true) }
    default: return nil
    }
  }

  /// Run it through the app's own data layer. Throws exactly what the screen would.
  public func run(_ svc: SupabaseService = .shared) async throws {
    switch self {
    case .friendRespond(let id, let accept): try await PeopleService(svc).respond(id, accept: accept)
    case .roundRsvp(let round, let status): try await ScheduleService(svc).rsvp(round, status: status)
    case .respondInvite(let id, let accept): try await PeopleService(svc).respondInvite(id, accept: accept)
    }
  }
}
