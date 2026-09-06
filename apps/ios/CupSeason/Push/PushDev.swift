// Cup Season — push developer hatches (DEBUG only; the simulator receives
// no APNs, so a launch argument stands in for a tap):
//   -cs_dev_push '<json>'      the contract's `cs` object (or a whole
//                              `{aps, cs}` payload) routed as if tapped, two
//                              seconds after the session is ready
//   -cs_dev_push <kind>        the SHORTHAND (D259): a bare `PushKind` name —
//                              `callout`, `rank_change`, `tee_tomorrow` — whose
//                              ids are resolved from the signed-in session
//   -cs_dev_push_prompt        the explainer sheet whatever the system says
//   -cs_dev_push_autoopen      a notification arriving in the FOREGROUND
//                              (`xcrun simctl push`) is routed as if tapped
//   -cs_dev_push_ids           print real ids the router can be fed
// None of these exist in Release.
//
// D259 · WHY THE SHORTHAND EXISTS, AND WHERE THE GAP ACTUALLY WAS.
// `PushRoute.from` has been correct since D248: a `callout` lands on the
// head-to-head page when the payload carries a `profile_id`. But `payload`
// below is a PURE PARSE of a launch argument, `dumpIds` printed leagues,
// events, rounds and plans and **no profile id at all**, so there was no way
// to write a callout payload that carried one — every attempt fell through
// `PushRoute.from`'s "a kind whose id is missing lands Home" clause and the
// re-audit concluded the route was broken. It was not. The hole was between
// `payload` and `router.pending`, and this file is where it is filled: the
// kinds whose landing needs an id get one from the session that is already
// loaded, so `-cs_dev_push callout` walks the page D248 says is the only one
// that can explain what being called out means.

#if DEBUG
import Foundation
import CupSeasonKit

enum PushDev {
  private static let args = ProcessInfo.processInfo.arguments
  static let forcePrompt = args.contains("-cs_dev_push_prompt")
  static let autoOpen = args.contains("-cs_dev_push_autoopen")
  static let printIds = args.contains("-cs_dev_push_ids")

  /// Whatever followed `-cs_dev_push` — JSON, or a kind's name.
  private static var spec: String? {
    guard let i = args.firstIndex(of: "-cs_dev_push"), i + 1 < args.count else { return nil }
    return args[i + 1]
  }

  /// The payload behind `-cs_dev_push`, if any. Accepts `{ "v":1, "kind":… }`
  /// or the full `{ "aps": {…}, "cs": {…} }`.
  static var payload: PushPayload? {
    guard let s = spec, let data = s.data(using: .utf8),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
    if obj["cs"] != nil { return PushPayload(userInfo: obj) }
    return PushPayload(cs: obj, category: obj["category"] as? String)
  }

  /// The bare kind, when the argument is a word rather than JSON.
  static var shorthandKind: PushKind? {
    guard let s = spec, !s.hasPrefix("{") else { return nil }
    return PushKind(rawValue: s)
  }

  /// What the shell actually routes: the JSON payload if one was given, else
  /// the shorthand's kind — and in BOTH cases with the ids the route needs
  /// filled in from the session, so nothing silently lands Home.
  @MainActor
  static func resolved(me: Me?, preferred: UUID?) async -> PushPayload? {
    guard let base = payload ?? shorthandKind.map({ PushPayload(kind: $0) }) else {
      if spec != nil {
        NSLog("[push-dev] -cs_dev_push takes a JSON `cs` object or one of: \(PushKind.allCases.map(\.rawValue).joined(separator: ", "))")
      }
      return nil
    }
    let full = await fill(base, me: me, preferred: preferred)
    NSLog("[push-dev] \(full.kind?.rawValue ?? "unknown") → \(PushRoute.from(full).name)")
    return full
  }

  /// Fill only what THIS kind's landing needs, and only when it is absent —
  /// a hand-written payload always wins over the session. Every read here is
  /// one the app already makes; nothing is written.
  @MainActor
  private static func fill(_ p: PushPayload, me: Me?, preferred: UUID?) async -> PushPayload {
    guard let kind = p.kind else { return p }
    var profileId = p.profileId
    var eventId = p.eventId
    var leagueId = p.leagueId
    var roundId = p.roundId
    var liveRoundId = p.liveRoundId
    var scheduledRoundId = p.scheduledRoundId
    var inviteId = p.inviteId
    var requestId = p.requestId

    switch kind {
    // D248's callout lands on the record between two golfers, so it needs a
    // PERSON. The opponent of an open clash is the truest answer; a buddy is
    // the fallback, because the page renders for anyone.
    case .callout:
      if profileId == nil {
        profileId = me?.open_duels.compactMap(\.opponent?.profile_id).first
        if profileId == nil { profileId = await firstBuddy() }
      }
      if eventId == nil { eventId = me?.events.first?.id }
    case .clash_pressure, .nudge, .event:
      if eventId == nil { eventId = me?.events.first?.id }
      if leagueId == nil { leagueId = preferred ?? me?.memberships.first?.league_id }
    case .rank_change, .clash_verdict, .season_countdown, .season_cancel, .chat, .announce, .moment, .system:
      if leagueId == nil { leagueId = preferred ?? me?.memberships.first?.league_id }
    case .round, .friend_round:
      if roundId == nil { roundId = await firstRound() }
    case .live_open, .settlement:
      if liveRoundId == nil { liveRoundId = me?.live_round?.id }
    case .tee_tomorrow, .seat_open, .rsvp:
      if scheduledRoundId == nil { scheduledRoundId = await firstPlan() }
    case .invite:
      if inviteId == nil { inviteId = await firstInvite() }
    case .request:
      if requestId == nil { requestId = await firstRequest() }
    case .index_live:
      break
    }
    return PushPayload(kind: kind, leagueId: leagueId, postId: p.postId, roundId: roundId, liveRoundId: liveRoundId,
                       eventId: eventId, profileId: profileId, scheduledRoundId: scheduledRoundId,
                       requestId: requestId, inviteId: inviteId,
                       category: p.category ?? defaultCategory(kind))
  }

  /// §3's actionable categories, so a shorthand payload also exercises the
  /// lock-screen actions rather than only the tap.
  private static func defaultCategory(_ kind: PushKind) -> String? {
    switch kind {
    case .request: PushCategory.request.rawValue
    case .rsvp, .tee_tomorrow, .seat_open: PushCategory.rsvp.rawValue
    case .invite: PushCategory.invite.rawValue
    default: nil
    }
  }

  // MARK: - the session's own ids, read the way the app reads them

  private static func firstBuddy() async -> UUID? {
    let svc = SupabaseService.shared
    if let rows = try? await svc.call(Rpc.my_friends()),
       let f = rows.first(where: { $0.status == "accepted" })?.profile_id { return f }
    if let rows = try? await svc.call(Rpc.my_rivalries()) { return rows.first?.opponent }
    return nil
  }

  private static func firstRound() async -> UUID? {
    guard let feed = try? await SupabaseService.shared.call(Rpc.home_feed(p_days: 60)) else { return nil }
    return feed.compactMap(\.round_id).first
  }

  private static func firstPlan() async -> UUID? {
    let to = CSDate.iso(Calendar.current.date(byAdding: .day, value: 60, to: Date()) ?? Date())
    guard let rows = try? await SupabaseService.shared.call(Rpc.my_schedule(p_from: CSDate.today(), p_to: to)) else { return nil }
    return rows.compactMap(\.id).first
  }

  private static func firstInvite() async -> UUID? {
    guard let rows = try? await SupabaseService.shared.call(Rpc.my_invites()) else { return nil }
    return rows.compactMap(\.id).first
  }

  private static func firstRequest() async -> UUID? {
    guard let rows = try? await SupabaseService.shared.call(Rpc.my_friends()) else { return nil }
    return rows.first(where: { $0.status == "pending" })?.friendship_id
  }

  /// Real ids from the signed-in account, for the hatch above.
  @MainActor
  static func dumpIds(me: Me?, preferred: UUID?) async {
    let svc = SupabaseService.shared
    NSLog("[push-dev] preferred league: \(preferred?.uuidString.lowercased() ?? "nil")")
    for m in me?.memberships ?? [] { NSLog("[push-dev] league \(m.name): \(m.league_id.uuidString.lowercased())") }
    if let lr = me?.live_round { NSLog("[push-dev] live round: \(lr.id.uuidString.lowercased()) status=\(lr.status)") }
    for e in me?.events ?? [] { NSLog("[push-dev] event \(e.name): \(e.id.uuidString.lowercased())") }
    for d in me?.open_duels ?? [] { NSLog("[push-dev] clash: \(d.session_id?.uuidString.lowercased() ?? "nil") closes \(d.closes_on ?? "?")") }
    // D259 · THE IDS THE CALLOUT NEEDED AND THIS DUMP DID NOT PRINT. A person
    // is the subject of four of D248's ten kinds and there was no way to learn
    // one from here, which is most of why `-cs_dev_push callout` "did not work".
    if let mine = me?.profile?.id { NSLog("[push-dev] me: \(mine.uuidString.lowercased())") }
    for d in me?.open_duels ?? [] {
      if let o = d.opponent { NSLog("[push-dev] opponent \(o.display_name ?? "?"): \(o.profile_id.uuidString.lowercased())") }
    }
    if let rows = try? await svc.call(Rpc.my_friends()) {
      for f in rows.prefix(5) where f.status == "accepted" {
        NSLog("[push-dev] buddy \(f.display_name ?? "?"): \(f.profile_id?.uuidString.lowercased() ?? "nil")")
      }
    }
    if let feed = try? await svc.call(Rpc.home_feed(p_days: 60)) {
      for r in feed.prefix(3) { if let id = r.round_id { NSLog("[push-dev] round: \(id.uuidString.lowercased())") } }
    }
    let to = CSDate.iso(Calendar.current.date(byAdding: .day, value: 60, to: Date()) ?? Date())
    if let sched = try? await svc.call(Rpc.my_schedule(p_from: CSDate.today(), p_to: to)) {
      for r in sched.prefix(3) { NSLog("[push-dev] scheduled round: \(r.id?.uuidString.lowercased() ?? "nil") on \(r.play_on ?? "?")") }
    }
    if let inv = try? await svc.call(Rpc.my_invites()) {
      for i in inv.prefix(3) { NSLog("[push-dev] invite: \(i.id?.uuidString.lowercased() ?? "nil")") }
    }
  }
}
#endif
