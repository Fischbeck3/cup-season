import Testing
import Foundation
@testable import CupSeasonKit

private let L = UUID(), P = UUID(), R = UUID(), LR = UUID(), E = UUID(), PR = UUID(), SR = UUID(), RQ = UUID(), IV = UUID()

/// A contract payload's `userInfo`, as APNs hands it over.
private func userInfo(kind: String, v: Any = 1, category: String? = nil, _ ids: [String: UUID] = [:]) -> [AnyHashable: Any] {
  var cs: [String: Any] = ["v": v, "kind": kind]
  for (k, id) in ids { cs[k] = id.uuidString.lowercased() }
  var aps: [String: Any] = ["alert": ["title": "t", "body": "b"], "sound": "default"]
  if let category { aps["category"] = category }
  return ["aps": aps, "cs": cs]
}

@Suite struct PushPayloadTests {
  @Test func everyKindLandsWhereTheContractSays() {
    let cases: [(String, [String: UUID], PushRoute)] = [
      ("round", ["round_id": R, "league_id": L], .receipt(R)),
      ("settlement", ["live_round_id": LR, "league_id": L], .scorecard(LR)),
      ("chat", ["league_id": L, "post_id": P], .board(L)),
      ("announce", ["league_id": L, "post_id": P], .board(L)),
      ("moment", ["league_id": L, "post_id": P], .board(L)),
      ("system", ["league_id": L, "post_id": P], .board(L)),
      ("live_open", ["live_round_id": LR, "league_id": L], .live(LR)),
      ("nudge", ["event_id": E], .event(E)),
      ("nudge", ["live_round_id": LR], .live(LR)),
      ("event", ["event_id": E], .event(E)),
      ("invite", ["invite_id": IV, "league_id": L], .invites),
      ("request", ["request_id": RQ, "profile_id": PR], .requests),
      ("rsvp", ["scheduled_round_id": SR], .scheduledRound(SR)),
    ]
    for (kind, ids, want) in cases {
      let p = PushPayload(userInfo: userInfo(kind: kind, ids))
      #expect(p != nil, "\(kind) decodes")
      #expect(p.map(PushRoute.from) == want, "\(kind) → \(want)")
    }
    #expect(PushKind.allCases.count == 12)
  }

  @Test func missingIdsLandHome() {
    for kind in ["round", "settlement", "chat", "announce", "moment", "system", "live_open", "nudge", "event", "rsvp"] {
      #expect(PushPayload(userInfo: userInfo(kind: kind)).map(PushRoute.from) == .home, Comment(rawValue: kind))
    }
    // the two that need no id still land where they belong
    #expect(PushPayload(userInfo: userInfo(kind: "invite")).map(PushRoute.from) == .invites)
    #expect(PushPayload(userInfo: userInfo(kind: "request")).map(PushRoute.from) == .requests)
  }

  @Test func unknownVersionIsNil_unknownKindIsHome() {
    #expect(PushPayload(userInfo: userInfo(kind: "round", v: 2, ["round_id": R])) == nil)
    #expect(PushPayload(userInfo: userInfo(kind: "round", v: "9", ["round_id": R])) == nil)
    #expect(PushPayload(userInfo: ["aps": ["alert": "x"]]) == nil)          // web-shaped, no cs
    #expect(PushPayload(userInfo: userInfo(kind: "round", v: "1", ["round_id": R])) != nil)   // a string "1" still reads
    let p = PushPayload(userInfo: userInfo(kind: "parade", ["league_id": L]))
    #expect(p?.kind == nil && p.map(PushRoute.from) == .home)
    #expect(PushPayload(cs: ["v": 1, "kind": "round", "round_id": "not-a-uuid"]).map(PushRoute.from) == .home)
  }

  @Test func categoryRidesInFromAps() {
    let p = PushPayload(userInfo: userInfo(kind: "request", category: "CS_REQUEST", ["request_id": RQ]))
    #expect(p?.category == "CS_REQUEST")
    #expect(PushPayload(userInfo: userInfo(kind: "chat", ["league_id": L]))?.category == nil)
  }

  @Test func routeNamesForTelemetry() {
    #expect(PushRoute.receipt(R).name == "receipt" && PushRoute.scheduledRound(SR).name == "scheduled_round" && PushRoute.home.name == "home")
  }
}

@Suite struct PushActionTests {
  @Test func theThreeCategoriesMapToTheScreensRpcs() {
    let req = PushPayload(userInfo: userInfo(kind: "request", category: "CS_REQUEST", ["request_id": RQ]))!
    #expect(PushActionCall.resolve(category: req.category, action: "ACCEPT", payload: req) == .friendRespond(id: RQ, accept: true))
    #expect(PushActionCall.resolve(category: req.category, action: "DECLINE", payload: req) == .friendRespond(id: RQ, accept: false))

    let rsvp = PushPayload(userInfo: userInfo(kind: "rsvp", category: "CS_RSVP", ["scheduled_round_id": SR]))!
    #expect(PushActionCall.resolve(category: rsvp.category, action: "IN", payload: rsvp) == .roundRsvp(round: SR, status: "in"))
    #expect(PushActionCall.resolve(category: rsvp.category, action: "OUT", payload: rsvp) == .roundRsvp(round: SR, status: "out"))

    let inv = PushPayload(userInfo: userInfo(kind: "invite", category: "CS_INVITE", ["invite_id": IV, "league_id": L]))!
    #expect(PushActionCall.resolve(category: inv.category, action: "ACCEPT", payload: inv) == .respondInvite(id: IV, accept: true))
  }

  @Test func nothingRunsWhenThePiecesDoNotLineUp() {
    let req = PushPayload(userInfo: userInfo(kind: "request", category: "CS_REQUEST", ["request_id": RQ]))!
    #expect(PushActionCall.resolve(category: req.category, action: "IN", payload: req) == nil)          // wrong action for the category
    #expect(PushActionCall.resolve(category: nil, action: "ACCEPT", payload: req) == nil)               // no category
    #expect(PushActionCall.resolve(category: "CS_PARADE", action: "ACCEPT", payload: req) == nil)       // unknown category
    let noId = PushPayload(userInfo: userInfo(kind: "request", category: "CS_REQUEST"))!
    #expect(PushActionCall.resolve(category: noId.category, action: "ACCEPT", payload: noId) == nil)    // no id
    let inv = PushPayload(userInfo: userInfo(kind: "invite", category: "CS_INVITE", ["invite_id": IV]))!
    #expect(PushActionCall.resolve(category: inv.category, action: "DECLINE", payload: inv) == nil)     // invites have no lock-screen decline
  }

  @Test func categoriesRegisterTheContractsActions() {
    #expect(PushCategory.allCases.map(\.rawValue) == ["CS_REQUEST", "CS_RSVP", "CS_INVITE"])
    #expect(PushCategory.request.actions.map(\.id) == ["ACCEPT", "DECLINE"])
    #expect(PushCategory.rsvp.actions.map(\.id) == ["IN", "OUT"])
    #expect(PushCategory.invite.actions.map(\.id) == ["ACCEPT"])
  }
}

@Suite struct PushAskPolicyTests {
  @Test func asksOnlyWhenUndeterminedAndNotSnoozed() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    #expect(PushAskPolicy.shouldAsk(status: .undetermined, declinedAt: nil, now: now))
    #expect(!PushAskPolicy.shouldAsk(status: .authorized, declinedAt: nil, now: now))
    #expect(!PushAskPolicy.shouldAsk(status: .denied, declinedAt: nil, now: now))
    #expect(!PushAskPolicy.shouldAsk(status: .undetermined, declinedAt: now.addingTimeInterval(-13 * 86_400), now: now))
    #expect(PushAskPolicy.shouldAsk(status: .undetermined, declinedAt: now.addingTimeInterval(-15 * 86_400), now: now))
    #expect(PushAskPolicy.snooze == 14 * 86_400)
  }
}

@Suite struct PushDuelPlanTests {
  private static let me = UUID(), them = UUID()
  private static let myPlayer = EventPlayer(id: UUID(), profileId: me, teamId: nil, name: "Me")
  private static let theirPlayer = EventPlayer(id: UUID(), profileId: them, teamId: nil, name: "Galen")
  /// 2026-08-27 09:00 Phoenix (UTC−7 all year).
  private static let morning = ISO8601DateFormatter().date(from: "2026-08-27T16:00:00Z")!

  private static func room(sessionStatus: String = "open", closes: String = "2026-08-27", myRound: UUID? = nil, tz: String? = "America/Phoenix",
                           kind: String = "ryder") -> EventRoom {
    let s = EventSession(id: UUID(), session_no: 1, opens_on: "2026-08-21", closes_on: closes, status: sessionStatus)
    let d = EventDuel(id: UUID(), session_id: s.id, a_player: myPlayer.id, b_player: theirPlayer.id, a_round: myRound, b_round: nil)
    return EventRoom(event: EventRow(id: UUID(), name: "Desert Ryder", created_by: nil, kind: kind, status: "live", tz: tz),
                     players: [myPlayer, theirPlayer], sessions: [s], duels: [d])
  }

  @Test func schedulesSixPmLeagueTimeOnTheClosingDay() {
    let r = Self.room()
    let plan = PushDuelPlan.make(room: r, me: Self.me, now: Self.morning)
    #expect(plan.schedule.count == 1 && plan.cancel.isEmpty)
    let rem = plan.schedule[0]
    #expect(rem.identifier == "duel-\(r.sessions[0].id.uuidString.lowercased())")
    #expect(rem.fireAt == ISO8601DateFormatter().date(from: "2026-08-28T01:00:00Z"))   // 18:00 Phoenix
    #expect(rem.eventName == "Desert Ryder")
  }

  @Test func cancelsWhenPostedResolvedNotTodayOrNotMine() {
    let sid = { (r: EventRoom) in PushDuelPlan.identifier(r.sessions[0].id) }
    let posted = Self.room(myRound: UUID())
    #expect(PushDuelPlan.make(room: posted, me: Self.me, now: Self.morning) == PushDuelPlan(schedule: [], cancel: [sid(posted)]))
    let resolved = Self.room(sessionStatus: "closed")
    #expect(PushDuelPlan.make(room: resolved, me: Self.me, now: Self.morning).cancel == [sid(resolved)])
    let tomorrow = Self.room(closes: "2026-08-28")
    #expect(PushDuelPlan.make(room: tomorrow, me: Self.me, now: Self.morning).schedule.isEmpty)
    let stranger = Self.room()
    #expect(PushDuelPlan.make(room: stranger, me: UUID(), now: Self.morning).schedule.isEmpty)
    #expect(PushDuelPlan.make(room: stranger, me: nil, now: Self.morning).schedule.isEmpty)
    let major = Self.room(kind: "major")
    #expect(PushDuelPlan.make(room: major, me: Self.me, now: Self.morning).schedule.isEmpty)
  }

  @Test func neverSchedulesIntoThePast() {
    let evening = ISO8601DateFormatter().date(from: "2026-08-28T02:30:00Z")!   // 19:30 Phoenix on the 27th
    let plan = PushDuelPlan.make(room: Self.room(), me: Self.me, now: evening)
    #expect(plan.schedule.isEmpty && plan.cancel.count == 1)
  }

  @Test func usesTheEventsTimeZoneAndFallsBackToPhoenix() {
    // 09:00 Phoenix is 17:00 in London on the 27th — still the 27th there, 18:00 London = 17:00Z
    let london = PushDuelPlan.make(room: Self.room(tz: "Europe/London"), me: Self.me, now: Self.morning)
    #expect(london.schedule.first?.fireAt == ISO8601DateFormatter().date(from: "2026-08-27T17:00:00Z"))
    let none = PushDuelPlan.make(room: Self.room(tz: nil), me: Self.me, now: Self.morning)
    #expect(none.schedule.first?.fireAt == ISO8601DateFormatter().date(from: "2026-08-28T01:00:00Z"))
    let junk = PushDuelPlan.make(room: Self.room(tz: "Mars/Olympus"), me: Self.me, now: Self.morning)
    #expect(junk.schedule.first?.fireAt == ISO8601DateFormatter().date(from: "2026-08-28T01:00:00Z"))
  }
}
