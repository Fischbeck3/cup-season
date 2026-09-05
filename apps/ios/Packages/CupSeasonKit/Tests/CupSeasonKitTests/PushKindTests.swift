// Cup Season — NINE NOTIFICATION KINDS AND ONE CONSENT NOTICE (D248).
//
// L-20 says a nudge names one of D23's eight emotions **or it does not render**.
// That is a law nobody can check by reading a table in an entry, so the mapping
// is a value (`PushKind.policy`) and these are the assertions over it:
//
//   · nine nudges, each naming one of the EIGHT — not a ninth word
//   · ONE transactional notice, `season_cancel`, exempt BY NAME under D71/L-38,
//     and it is the only kind that may claim the exemption
//   · L-21 / L-22: nothing manufactured, nothing that shames — the refusals are
//     a list, and no shipped kind is on it
//   · every kind lands on a page that EXISTS, and a missing id lands Home
//
// THE PRODUCERS ARE DARK and that is the point of shipping the vocabulary
// first: D248's gate is one production APNs token receiving one real push, and
// until it is green nothing writes a row of these kinds. The migration's own
// self-check fails if anything does.

import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct PushKindTests {

  // MARK: - the ten

  @Test func d248ShipsNineNudgesAndOneNotice() {
    #expect(PushKind.d248.count == 10)
    let nudges = PushKind.d248.filter(\.namesAnEmotion)
    let notices = PushKind.d248.filter { if case .notice = $0.policy { return true }; return false }
    #expect(nudges.count == 9)
    #expect(notices == [.season_cancel])
  }

  @Test func everyNudgeNamesOneOfD23sEight() {
    // The eight, and there are eight.
    #expect(PushEmotion.allCases.count == 8)
    #expect(Set(PushEmotion.allCases.map(\.rawValue)) ==
            ["pride", "nostalgia", "anticipation", "belonging", "rivalry", "joy", "reflection", "achievement"])
    // D248's table, column by column.
    let table: [PushKind: PushEmotion] = [
      .rank_change: .rivalry, .clash_pressure: .rivalry, .callout: .rivalry,
      .clash_verdict: .achievement, .index_live: .achievement,
      .tee_tomorrow: .anticipation, .season_countdown: .anticipation,
      .friend_round: .belonging, .seat_open: .belonging,
    ]
    for (kind, emotion) in table {
      guard case .nudge(let e) = kind.policy else {
        Issue.record("\(kind.rawValue) is not a nudge"); continue
      }
      #expect(e == emotion, Comment(rawValue: kind.rawValue))
    }
    #expect(table.count == 9)
  }

  @Test func onlyOneKindClaimsTheTransactionalExemption() {
    // "Consent" is not one of D23's eight. Labelling a vote with a word that is
    // not on the list would BREAK L-20 rather than satisfy it, so `season_cancel`
    // is ruled a notice under D71/L-38 — and it is the only one.
    for k in PushKind.allCases where k != .season_cancel {
      if case .notice = k.policy { Issue.record("\(k.rawValue) claims the exemption") }
    }
    if case .notice = PushKind.season_cancel.policy {} else {
      Issue.record("season_cancel is not the notice")
    }
    #expect(!PushKind.season_cancel.namesAnEmotion)
  }

  @Test func theTwelveShippedKindsAreDeliveriesNotNudges() {
    // L-20 governs what the product INVENTS a reason to send. A board row and a
    // posted round are things that HAPPENED; calling them nudges would either
    // force a false emotion label onto them or break the law.
    let shipped: [PushKind] = [.round, .chat, .announce, .moment, .system, .settlement,
                               .live_open, .nudge, .invite, .request, .rsvp, .event]
    #expect(shipped.count == 12)
    for k in shipped {
      #expect(k.policy == .delivery, Comment(rawValue: k.rawValue))
      #expect(!PushKind.d248.contains(k), Comment(rawValue: k.rawValue))
    }
    #expect(PushKind.allCases.count == 22)
  }

  // MARK: - L-21 / L-22 · what is deliberately not sent

  @Test func theRefusalsAreAListAndNothingShippedIsOnIt() {
    #expect(Set(PushRefusals.declined) ==
            ["points_from_second", "streak", "friends_more_active", "unread_badge"])
    for k in PushKind.allCases {
      #expect(!PushRefusals.declined.contains(k.rawValue), Comment(rawValue: k.rawValue))
    }
    // and none of the ten is a standing, a streak or a comparison by NAME —
    // the word is the tell, because that is how the tempting ones arrive.
    for k in PushKind.d248 {
      for banned in ["streak", "rank_gap", "points_from", "more_active", "behind"] {
        #expect(!k.rawValue.contains(banned), Comment(rawValue: k.rawValue))
      }
    }
  }

  @Test func nothingIsSentAboutTheStakeItself() {
    // D130's own line for the stake row is "Push: none", and D248 upholds it
    // explicitly. There is no `pot`, `buy_in` or `owe` kind and there must not be.
    for k in PushKind.allCases {
      for money in ["pot", "buy_in", "owe", "paid", "stake"] {
        #expect(!k.rawValue.contains(money), Comment(rawValue: k.rawValue))
      }
    }
  }

  // MARK: - every kind lands somewhere that exists

  private func payload(_ k: PushKind, league: UUID? = nil, round: UUID? = nil, event: UUID? = nil,
                       profile: UUID? = nil, plan: UUID? = nil) -> PushPayload {
    PushPayload(kind: k, leagueId: league, roundId: round, eventId: event,
                profileId: profile, scheduledRoundId: plan)
  }

  @Test func everyNewKindLandsOnAPageThatExists() {
    let league = UUID(), round = UUID(), plan = UUID(), who = UUID(), event = UUID()
    #expect(PushRoute.from(payload(.rank_change, league: league)) == .board(league))
    #expect(PushRoute.from(payload(.clash_verdict, league: league)) == .board(league))
    #expect(PushRoute.from(payload(.season_countdown, league: league)) == .board(league))
    #expect(PushRoute.from(payload(.season_cancel, league: league)) == .board(league))
    #expect(PushRoute.from(payload(.clash_pressure, league: league)) == .board(league))
    #expect(PushRoute.from(payload(.clash_pressure, league: league, event: event)) == .event(event))
    #expect(PushRoute.from(payload(.callout, profile: who)) == .headToHead(who))
    #expect(PushRoute.from(payload(.callout, event: event)) == .event(event))
    #expect(PushRoute.from(payload(.index_live)) == .home)
    #expect(PushRoute.from(payload(.tee_tomorrow, plan: plan)) == .scheduledRound(plan))
    #expect(PushRoute.from(payload(.seat_open, plan: plan)) == .scheduledRound(plan))
    #expect(PushRoute.from(payload(.friend_round, round: round)) == .receipt(round))
  }

  @Test func aMissingIdLandsHomeNeverABlank() {
    // The contract's own rule, unchanged, and it is what makes it safe for the
    // server to start writing a kind before the payload key ships.
    for k in PushKind.d248 {
      let r = PushRoute.from(PushPayload(kind: k))
      #expect(r == .home, Comment(rawValue: "\(k.rawValue) → \(r.name)"))
    }
    #expect(PushRoute.from(PushPayload(kind: nil)) == .home)
  }

  @Test func everyRouteHasASlotAndAName() {
    let routes: [PushRoute] = [.receipt(UUID()), .scorecard(UUID()), .board(UUID()), .live(UUID()),
                               .event(UUID()), .invites, .requests, .scheduledRound(UUID()),
                               .headToHead(UUID()), .home]
    for r in routes {
      #expect(!r.name.isEmpty)
      _ = NavSlot.of(r)                       // total — a missing case would not compile
    }
    // D248's callout lands where a person waiting on you lands.
    #expect(NavSlot.of(PushRoute.headToHead(UUID())) == .golfers)
    #expect(PushRoute.headToHead(UUID()).name == "head_to_head")
  }

  @Test func anUnknownVersionStillDecodesToNothing() {
    // A payload from a future contract is not guessed at.
    #expect(PushPayload(cs: ["v": 2, "kind": "rank_change"]) == nil)
    let ok = PushPayload(cs: ["v": 1, "kind": "index_live"])
    #expect(ok?.kind == .index_live)
    // and a kind this build has never heard of decodes to nil and lands Home
    let unknown = PushPayload(cs: ["v": 1, "kind": "a_kind_from_2027"])
    #expect(unknown?.kind == nil)
    #expect(PushRoute.from(unknown!) == .home)
  }

  // MARK: - D247 · the ask's timing moved, its mechanism did not

  @Test func thePushAskNoLongerFollowsTheCard() {
    // It used to arrive over a golfer's first Home, before they had done
    // anything. The three moments are now ones that earned it.
    #expect(Set(PushAskReason.allCases.map(\.rawValue)) ==
            ["first_round", "buddy_accepted", "league_joined"])
    #expect(!PushAskReason.allCases.map(\.rawValue).contains("card_saved"))
  }

  @Test func d104sRuleIsUntouched() {
    let now = Date()
    #expect(PushAskPolicy.snooze == 14 * 86_400)
    #expect(PushAskPolicy.shouldAsk(status: .undetermined, declinedAt: nil, now: now))
    #expect(!PushAskPolicy.shouldAsk(status: .authorized, declinedAt: nil, now: now))
    #expect(!PushAskPolicy.shouldAsk(status: .denied, declinedAt: nil, now: now))
    #expect(!PushAskPolicy.shouldAsk(status: .undetermined, declinedAt: now.addingTimeInterval(-86_400), now: now))
    #expect(PushAskPolicy.shouldAsk(status: .undetermined, declinedAt: now.addingTimeInterval(-15 * 86_400), now: now))
  }
}
