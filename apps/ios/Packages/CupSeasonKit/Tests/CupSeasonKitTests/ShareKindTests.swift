// Cup Season — the two new share kinds (D241 the person link, D253 the plan
// link), wave 6.
//
// Both are ONE VALUE on `shares.kind` and ONE BRANCH inside `share_info`,
// which is already one of L-45's twelve anon endpoints. **The signed-out
// surface stays at twelve** — preflight check 26 enumerates the
// `grant execute … to anon` list out of the migration tree and fails the push
// at thirteen; what this file holds is the client's half:
//
//   1 · BOTH TOKENS RESOLVE. A `/?p=` and a `/?plan=` URL are recognised, land
//       in a slot that exists, and round-trip through the URL the app itself
//       mints.
//   2 · AN UNGUESSABLE TOKEN THAT DOES NOT EXIST RETURNS THE SAME NOTHING.
//       `redeem_share` answers `{kind: null}` for a made-up token, a revoked
//       one and a deleted golfer alike (D57), and the client must not be able
//       to tell those apart either — one outcome, one sentence, fail-closed.

import Testing
import Foundation
@testable import CupSeasonKit

private let tok = UUID(uuidString: "9f1d3c2a-4b5e-4f60-9a71-8c2d5e6f7a80")!

@Suite("D241 / D253 · both tokens resolve")
struct ShareKindTests {

  @Test func theTwoQueriesAreTheTwoTheAasaClaims() {
    #expect(ShareIntent.person.query == "p")
    #expect(ShareIntent.plan.query == "plan")
    #expect(ShareIntent.allCases.count == 2)
    // the CHECK's own values, so a rename cannot happen on one side only
    #expect(ShareIntent.person.shareKind == "person")
    #expect(ShareIntent.plan.shareKind == "plan")
  }

  @Test func aMintedLinkParsesBackToItsOwnToken() {
    for kind in ShareIntent.allCases {
      let url = kind.url(tok)
      #expect(url.absoluteString == "https://cupseason.app/?\(kind.query)=\(tok.uuidString.lowercased())")
      #expect(kind.token(from: url) == tok)
      let found = ShareIntent.of(url)
      #expect(found?.kind == kind)
      #expect(found?.token == tok)
    }
  }

  /// The two keys cannot collide, and neither claims the other's link — `?plan=`
  /// must not be read as a person link by a prefix match.
  @Test func neitherKindClaimsTheOthersLink() {
    #expect(ShareIntent.person.token(from: ShareIntent.plan.url(tok)) == nil)
    #expect(ShareIntent.plan.token(from: ShareIntent.person.url(tok)) == nil)
  }

  /// A truncated paste is not a token, and neither is somebody's word.
  @Test func aNonTokenIsNotAToken() {
    for s in ["https://cupseason.app/?p=",
              "https://cupseason.app/?p=hello",
              "https://cupseason.app/?plan=%20",
              "https://cupseason.app/",
              "https://cupseason.app/?join=PIGL2026"] {
      #expect(ShareIntent.of(URL(string: s)!) == nil, "\(s) should not resolve")
    }
  }

  /// Every link the app claims lands in a slot that exists. This is the same
  /// assertion `RouteMapTests` makes for the other three; adding a case to
  /// `DeepLink` without a slot would not compile, and adding one without a URL
  /// form would fail here.
  @Test func bothLinksLandInASlotThatExists() {
    #expect(DeepLink.of(ShareIntent.person.url(tok)) == .person)
    #expect(DeepLink.of(ShareIntent.plan.url(tok)) == .plan)
    #expect(NavSlot.of(DeepLink.person) == .golfers)   // it ends in a buddy request
    #expect(NavSlot.of(DeepLink.plan) == .play)        // it ends in a seat on the schedule
    for l in DeepLink.allCases { #expect(NavSlot.allCases.contains(NavSlot.of(l))) }
  }

  /// The token survives the door. A link tapped on a phone with no session has
  /// to outlive email, code and the golfer card, because a buddy request from
  /// a golfer with no name on them is not a request anybody can answer.
  @Test func aPendingTokenSurvivesAndIsSpentOnce() {
    let d = UserDefaults(suiteName: "cs.tests.sharekind")!
    for k in ShareIntent.allCases { k.clear(defaults: d) }
    #expect(ShareIntent.person.pending(defaults: d) == nil)
    ShareIntent.person.store(tok, defaults: d)
    #expect(ShareIntent.person.pending(defaults: d) == tok)
    // the two kinds do not share a key
    #expect(ShareIntent.plan.pending(defaults: d) == nil)
    ShareIntent.person.clear(defaults: d)
    #expect(ShareIntent.person.pending(defaults: d) == nil)
  }

  /// L-33 · the message a golfer sends. It says what the thing is and what
  /// happens on a tap; it never sells the app to somebody's friend, and it
  /// never states a fact it was not given.
  @Test func theShareMessageStatesOnlyWhatItWasGiven() {
    let named = ShareIntent.person.message(name: "Jerecho")
    #expect(named.hasPrefix("Jerecho wants you in their golf."))
    #expect(ShareIntent.person.message(name: nil).hasPrefix("Come and play."))
    #expect(ShareIntent.person.message(name: "  ").hasPrefix("Come and play."))

    #expect(ShareIntent.plan.message(name: nil, course: "Papago", day: "Sat Sep 12")
              == "Golf at Papago, Sat Sep 12. Tap to take the seat.")
    #expect(ShareIntent.plan.message(name: nil, course: "Papago", day: nil)
              == "Golf at Papago. Tap to take the seat.")
    #expect(ShareIntent.plan.message(name: nil, course: nil, day: nil)
              == "There’s a round on. Tap to take the seat.")
  }
}

@Suite("D241 / D253 · a token that does not exist answers the same nothing")
struct ShareRedeemTests {

  /// FAIL-CLOSED. Four different dead paths on the server — a made-up token, a
  /// revoked one, a deleted golfer, a kind this client does not know — and the
  /// client cannot tell them apart, because the server does not let it.
  @Test func everyDeadPathIsOneOutcomeAndOneSentence() {
    let dead: [JSONValue?] = [
      nil,
      JSONValue.null,
      JSONValue.object(["kind": .null]),
      JSONValue.object(["kind": .string("a_kind_from_the_future")]),
      JSONValue.object([:]),
    ]
    for v in dead {
      let r = ShareRedeem.parse(v)
      #expect(r.kind == nil)
      #expect(r.outcome == .dead)
      #expect(r.line == "That link has expired. Whoever sent it can share a fresh one.")
    }
  }

  /// D80 · two-sided consent. The person link mints a REQUEST, and the
  /// sentence says request — never "you're buddies now", which would be a
  /// promise the host has not made.
  @Test func thePersonLinkSaysRequestUnlessTheyAskedFirst() {
    let requested = ShareRedeem.parse(.object(["kind": .string("person"), "result": .string("requested")]))
    #expect(requested.outcome == .requested)
    #expect(requested.line == GolfersRoot.BuddyAsk.sent)

    // `friend_request` answers 'friend' when they had already asked — mutual
    // intent, and only THEN is it a friendship.
    let mutual = ShareRedeem.parse(.object(["kind": .string("person"), "result": .string("friend")]))
    #expect(mutual.outcome == .buddies)
    #expect(mutual.line == GolfersRoot.BuddyAsk.mutual)

    // your own link on your own phone says nothing at all
    let mine = ShareRedeem.parse(.object(["kind": .string("person"), "result": .string("self")]))
    #expect(mine.outcome == .mine)
    #expect(mine.line == nil)
  }

  /// One plan, one seat. A second open writes nothing more and says so
  /// without pretending it did something.
  @Test func thePlanLinkSeatsOnceAndSaysWhichItWas() {
    let first = ShareRedeem.parse(.object(["kind": .string("plan"), "seat": .string("in"), "result": .string("requested")]))
    #expect(first.outcome == .seated(alreadyIn: false, request: "requested"))
    #expect(first.line == "You’re in for that round. The host has your buddy request.")

    let again = ShareRedeem.parse(.object(["kind": .string("plan"), "seat": .string("already"), "result": .string("friend")]))
    #expect(again.outcome == .seated(alreadyIn: true, request: "friend"))
    #expect(again.line == "You’re already down for that round.")

    let past = ShareRedeem.parse(.object(["kind": .string("plan"), "seat": .string("past")]))
    #expect(past.outcome == .planPast)
    #expect(past.line == "That round has already been played.")

    let host = ShareRedeem.parse(.object(["kind": .string("plan"), "seat": .string("host"), "result": .string("host")]))
    #expect(host.outcome == .mine)
    #expect(host.line == nil)
  }

  /// A `seat` word this client has never heard of is not a crash and not a
  /// blank: it lands on the most conservative true thing — a seat that was
  /// already there — because the server may ship a word before the client
  /// knows it (deploy skew, the way round it actually happens).
  @Test func anUnknownSeatWordLandsOnTheConservativeTruth() {
    let odd = ShareRedeem.parse(.object(["kind": .string("plan"), "seat": .string("waitlisted")]))
    #expect(odd.outcome == .seated(alreadyIn: true, request: nil))
    #expect(odd.line == "You’re already down for that round.")
  }

  /// The mint's own three states. A CHECK that does not admit the kind yet is
  /// NOT an error the golfer caused — it means the migration has not landed,
  /// and the row simply is not drawn (L-32: never a door that cannot open).
  @Test func aKindTheCheckDoesNotAdmitYetIsNotAnError() {
    struct E: Error, CustomStringConvertible { let description: String }
    #expect(ShareLinkService.kindNotDeployed(E(description: "new row for relation \"shares\" violates check constraint \"shares_kind_check\"")))
    #expect(ShareLinkService.kindNotDeployed(E(description: "PostgrestError(code: 23514)")))
    #expect(ShareLinkService.kindNotDeployed(E(description: "Nothing to share")))
    #expect(ShareLinkService.kindNotDeployed(E(description: "The Internet connection appears to be offline.")) == false)
    #expect(ShareLinkService.kindNotDeployed(E(description: "Sign in first")) == false)
    // D234 · one sentence, both clients. `CS_SHARE_NOT_YET` is its twin and
    // `tests/app-tests.js` asserts the same literal, so a reword on one side
    // fails on the other rather than shipping two voices for one situation.
    // QB-01 · the sentence may never send a golfer to the App Store, and it
    // names the live alternative in the same breath (L-32).
    #expect(!ShareLinkService.notYetLine.lowercased().contains("update"))
    #expect(ShareLinkService.notYetLine(hasSeason: false)
              == "Person links aren\u{2019}t switched on yet \u{2014} a season\u{2019}s invite link works for anyone.")
    #expect(ShareLinkService.notYetLine(hasSeason: true).contains("send your"))
  }
}
