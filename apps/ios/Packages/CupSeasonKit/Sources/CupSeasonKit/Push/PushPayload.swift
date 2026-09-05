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

/// D23's eight emotions, and there are eight. **L-20: a nudge names one of
/// these or it does not render** — so the list is a value, not a comment, and
/// `PushKindTests` asserts its exact membership.
public enum PushEmotion: String, Sendable, CaseIterable {
  case pride, nostalgia, anticipation, belonging, rivalry, joy, reflection, achievement
}

/// What a kind IS, under the notification laws. The distinction is D248's own
/// ruling and it is the reason this is an enum rather than a boolean:
///
///   · `.nudge(emotion)` — L-20 applies and the emotion is named here.
///   · `.notice`         — a TRANSACTIONAL notice under D71/L-38, exempt from
///                         L-20's emotion requirement **by name**. Exactly one
///                         kind claims it (`season_cancel`, a vote opening on
///                         money somebody paid), and no other kind may claim it
///                         without its own entry. An earlier draft of D248
///                         labelled ten kinds with words like "consent" and
///                         "the verdict", of which only two were among the
///                         eight; that labelling is struck.
///   · `.delivery`       — the twelve shipped kinds, which carry a board row or
///                         a round to a phone. They are not nudges and never
///                         were; L-20 governs what the product INVENTS a reason
///                         to send, not the delivery of something that happened.
public enum PushPolicy: Sendable, Equatable {
  case nudge(PushEmotion)
  case notice
  case delivery
}

/// `cs.kind` — one per sentence the board can say.
public enum PushKind: String, Sendable, CaseIterable {
  case round, chat, announce, moment, system, settlement
  case live_open, nudge, invite, request, rsvp, event
  // ---- D248 · nine nudges and one notice ---------------------------------
  case rank_change, clash_pressure, callout, clash_verdict, index_live
  case tee_tomorrow, season_countdown, friend_round, seat_open
  case season_cancel

  /// The ten D248 rules, as a value, so "nine nudges and one notice" is a
  /// count a test takes rather than a sentence somebody re-reads.
  public static let d248: [PushKind] = [
    .rank_change, .clash_pressure, .callout, .clash_verdict, .index_live,
    .tee_tomorrow, .season_countdown, .friend_round, .seat_open, .season_cancel,
  ]

  /// D248's table, verbatim in the column that matters.
  public var policy: PushPolicy {
    switch self {
    case .rank_change:      .nudge(.rivalry)        // somebody passed me, and it names them
    case .clash_pressure:   .nudge(.rivalry)        // they posted, I have not
    case .callout:          .nudge(.rivalry)        // I have been called out
    case .clash_verdict:    .nudge(.achievement)    // the week settled
    case .index_live:       .nudge(.achievement)    // three rounds — the number is mine
    case .tee_tomorrow:     .nudge(.anticipation)   // 7:10 tomorrow, and who is in
    case .season_countdown: .nudge(.anticipation)   // it starts Saturday / it runs back
    case .friend_round:     .nudge(.belonging)      // a buddy posted
    case .seat_open:        .nudge(.belonging)      // a plan of theirs has room
    case .season_cancel:    .notice                 // D71/L-38, exempt by name
    default:                .delivery
    }
  }

  /// L-20 as a predicate. A nudge with no emotion cannot be constructed — the
  /// associated value is not optional — so what this really asserts is that
  /// nothing OUTSIDE the ruled set has quietly become a nudge.
  public var namesAnEmotion: Bool { if case .nudge = policy { return true }; return false }
}

/// **What D248 deliberately does not send**, kept as a value because the
/// tempting ones are tempting every time somebody opens this file. Each is a
/// standing refusal with a reason, and `PushKindTests` asserts that no shipped
/// kind is one of them.
public enum PushRefusals {
  /// A standing is not an event (D130's own line for the stake is "Push:
  /// none"), a streak is manufactured engagement (L-21), a comparison to your
  /// friends' activity is the shame line L-22 forbids, and a badge beyond
  /// `actionable_count_of` is a number with nothing behind it (L-01).
  public static let declined = [
    "points_from_second", "streak", "friends_more_active", "unread_badge",
  ]
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
  /// D248 · a callout lands on the record between the two of you, which is the
  /// only page that can say what being called out means.
  case headToHead(UUID)
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

    // ---- D248 · the nine and the notice, each landing on a page that exists.
    // The contract's own rule is unchanged: a missing id lands Home, never a
    // blank, so a producer that ships before the payload key does is honest.
    case .rank_change, .clash_verdict, .season_countdown, .season_cancel:
      return p.leagueId.map(PushRoute.board) ?? .home
    case .clash_pressure:
      if let e = p.eventId { return .event(e) }
      return p.leagueId.map(PushRoute.board) ?? .home
    case .callout:
      // the opponent's card is the subject; the event is the fallback
      if let who = p.profileId { return .headToHead(who) }
      return p.eventId.map(PushRoute.event) ?? .home
    case .index_live: return .home
    case .tee_tomorrow, .seat_open:
      return p.scheduledRoundId.map(PushRoute.scheduledRound) ?? .home
    case .friend_round:
      return p.roundId.map(PushRoute.receipt) ?? .home
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
    case .headToHead: "head_to_head"
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
