import Testing
import Foundation
@testable import CupSeasonKit

/// D237 / R-F · "I want to beat one guy" asks the length, and every length lands
/// on an object that already exists.
///
/// Three properties, and all three are the owner's ruling rather than taste:
///   1 · ALL THREE ARE ALWAYS OFFERED. The state may order them; it may never
///       withhold one.
///   2 · THE WORDS ARE THE OWNER'S, verbatim.
///   3 · NO LENGTH INVENTS A STAKE. The stake, if any, is a forfeit or the live
///       game's own — never a fourth money noun (T-02).
@Suite struct CalloutTests {

  // MARK: - 1 · always three

  @Test func allThreeAreAlwaysOffered() {
    for live in [false, true] {
      for shared in [false, true] {
        let o = CalloutLength.offered(liveNow: live, shareASeason: shared)
        #expect(o.count == 3, Comment(rawValue: "live=\(live) shared=\(shared)"))
        #expect(Set(o) == Set(CalloutLength.allCases))
      }
    }
  }

  @Test func theStateOrdersThemAndNeverShortensThem() {
    #expect(CalloutLength.offered() == [.thisSaturday, .oneWeek, .aSeason])
    // already in a live round → This Saturday first
    #expect(CalloutLength.offered(liveNow: true).first == .thisSaturday)
    // already sharing a season → A season LAST, and still there
    #expect(CalloutLength.offered(shareASeason: true).last == .aSeason)
    #expect(CalloutLength.offered(shareASeason: true).contains(.aSeason))
    // both at once still leaves three, with live first and the season last
    let both = CalloutLength.offered(liveNow: true, shareASeason: true)
    #expect(both == [.thisSaturday, .oneWeek, .aSeason])
  }

  // MARK: - 2 · the owner's words

  @Test func theWordsAreRFsVerbatim() {
    #expect(CalloutLength.question == "How long?")
    #expect(CalloutLength.thisSaturday.title == "This Saturday")
    #expect(CalloutLength.oneWeek.title == "One week")
    #expect(CalloutLength.aSeason.title == "A season")
    #expect(CalloutLength.thisSaturday.gloss == "a live match, on one card")
    #expect(CalloutLength.oneWeek.gloss == "best round by Sunday takes it")
    #expect(CalloutLength.aSeason.gloss == "a table, and a cup at the end")
  }

  /// The golfer never meets the object's name.
  @Test func noLengthNamesItsObject() {
    for l in CalloutLength.allCases {
      let hits = StartIntent.objectNouns(in: l.title + " " + l.gloss)
      #expect(hits.isEmpty, Comment(rawValue: "\(l.title): \(hits)"))
    }
  }

  // MARK: - 3 · each lands on something that already exists

  @Test func eachLengthMapsToAnObjectTheEngineHas() {
    #expect(CalloutLength.thisSaturday.object == .liveRound)
    #expect(CalloutLength.oneWeek.object == .callout)
    #expect(CalloutLength.aSeason.object == .pairSeason)
    let objects = CalloutLength.allCases.map(\.object)
    #expect(Set(objects).count == 3)
  }

  /// A-1 · the pair's second seat is an INVITE, never `add_friend_to_league`,
  /// which inserts the membership row with no invite, no acceptance and no
  /// covenant — at a stake above $0 that seats a golfer on a pot he never
  /// agreed to (L-12).
  @Test func thePairSeasonInvitesRatherThanSeats() {
    let rpcs = CalloutLength.aSeason.rpcs
    #expect(rpcs.contains("invite_golfer"))
    #expect(!rpcs.contains("add_friend_to_league"))
  }

  @Test func onlyTheCallOutIsNew() {
    // Every RPC named here ships today except `call_out` — which is the whole
    // of D237's "no new table" claim, expressed as a list.
    let shipped: Set<String> = ["start_live_round", "create_league", "lock_league", "invite_golfer"]
    for l in CalloutLength.allCases {
      for r in l.rpcs where r != "call_out" {
        #expect(shipped.contains(r), Comment(rawValue: r))
      }
    }
    #expect(CalloutLength.oneWeek.rpcs == ["call_out"])
  }

  /// T-02 · no length invents a money noun. Not one string in the whole flow
  /// says cents, dollars, a stake amount or a pot.
  @Test func noLengthInventsAStake() {
    let banned = ["cents", "$", "dollars", "buy-in", "buyin", "pot"]
    var strings = CalloutLength.allCases.flatMap { [$0.title, $0.gloss] }
    strings += [CalloutLength.question, CalloutCopy.stakeQuestion, CalloutCopy.stakeNone,
                CalloutCopy.stakeForfeit, CalloutCopy.stakePlaceholder, CalloutCopy.send,
                CalloutCopy.allSquare, CalloutCopy.noPoints, CalloutCopy.accept, CalloutCopy.decline]
    for s in strings {
      for b in banned {
        #expect(!s.lowercased().contains(b), Comment(rawValue: "\"\(s)\" says \(b)"))
      }
    }
  }

  // MARK: - what a callout says

  /// D21 (b) and (c): a tie is "All square. Nobody buys.", and when nobody
  /// posted it is the SAME sentence — there is no "never showed" line and this
  /// producer has no way to write one (L-22).
  @Test func aTieAndAnEmptyWindowReadTheSame() {
    #expect(CalloutCopy.allSquare == "All square. Nobody buys.")
    #expect(CalloutCopy.nobodyPosted == CalloutCopy.allSquare)
    #expect(!CalloutCopy.nobodyPosted.lowercased().contains("showed"))
    #expect(!CalloutCopy.nobodyPosted.lowercased().contains("didn't"))
  }

  /// L-01 · the verdict shows its work, in MY number's terms. §4's lint forbids
  /// a gross target derived from the other golfer's PvI — it is not computable.
  @Test func theVerdictShowsItsWorkAndNeverNamesHisGross() {
    let won = CalloutCopy.youTookIt(mine: 2.1, theirs: 0.4)
    #expect(won.contains("+2.1"))
    #expect(won.contains("+0.4"))
    let lost = CalloutCopy.theyTookIt("Galen Fischbeck", theirs: 1.8, mine: -0.2)
    #expect(lost.hasPrefix("Galen "))
    #expect(lost.contains("-0.2"))
    for s in [won, lost] {
      #expect(!s.lowercased().contains("needs"))
      #expect(!s.lowercased().contains("off his"))
    }
  }

  /// A golfer who never posted is named as not having posted only about
  /// THEMSELVES — never as a failure of the other man.
  @Test func anUnpostedSideIsStatedNotShamed() {
    let s = CalloutCopy.youTookIt(mine: 1.0, theirs: nil)
    #expect(s.contains("never posted"))
    #expect(!s.lowercased().contains("no-show"))
    #expect(!s.lowercased().contains("bottled"))
  }

  @Test func theRecipientsDoorSaysWhatIsOnIt() {
    let none = CalloutCopy.receivedSub(closesOn: "2026-09-13", terms: nil)
    #expect(none.hasSuffix("Nothing on it but the record."))
    let some = CalloutCopy.receivedSub(closesOn: "2026-09-13", terms: "Loser buys the beers")
    #expect(some.hasSuffix("Loser buys the beers."))
    #expect(CalloutCopy.accept == "I'm in")
    #expect(CalloutCopy.decline == "Not this week")
  }

  /// R-F's gloss says "best round by SUNDAY takes it", so the window ends on a
  /// Sunday — every day of the week, and never fewer than three days out. A
  /// sheet that printed "by Sat Sep 12" under a door that said Sunday was two
  /// screens of one client disagreeing about the same fact.
  @Test func oneWeekAlwaysEndsOnASunday() {
    // Sat 2026-09-05 → the coming Sunday is one day away, so the one after
    #expect(CalloutLength.defaultClose(today: "2026-09-05") == "2026-09-13")
    // Mon 2026-09-07 → the coming Sunday, six days out
    #expect(CalloutLength.defaultClose(today: "2026-09-07") == "2026-09-13")
    // a Sunday rolls a whole week, never "today"
    #expect(CalloutLength.defaultClose(today: "2026-09-06") == "2026-09-13")
    for iso in ["2026-09-05", "2026-09-06", "2026-09-07", "2026-09-09", "2026-09-11"] {
      let close = CalloutLength.defaultClose(today: iso)
      #expect(EventDates.weekdayLong(close) == "Sunday", Comment(rawValue: "\(iso) → \(close)"))
      #expect((CSDate.days(from: iso, to: close) ?? 0) >= 3)
    }
  }

  /// L-32 · the picker's empty state ends in a next move.
  @Test func thePickerEndsInAMove() {
    #expect(CalloutCopy.noBuddies == "Callouts are between buddies. Add one first.")
    #expect(!CalloutCopy.noBuddiesDoor.isEmpty)
  }

  // MARK: - what a callout IS

  /// The gate's own finding: a Ryder ROOM is written for a multi-week series
  /// between two SIDES and reads "WEEK 1 OF 1" over a one-week object. One
  /// predicate decides which surface an event lands on, and it is here.
  @Test func onePredicateDecidesTheSurface() {
    #expect(CalloutShape.isCallout(sessionCount: 1, leagueId: nil, field: 2))
    // a Ryder: more than one session
    #expect(!CalloutShape.isCallout(sessionCount: 4, leagueId: nil, field: 2))
    // attached to a season — a league Ryder, not a callout
    #expect(!CalloutShape.isCallout(sessionCount: 1, leagueId: UUID(), field: 2))
    // a one-session event with a real field is still a Ryder
    #expect(!CalloutShape.isCallout(sessionCount: 1, leagueId: nil, field: 6))
    // and nothing decodes into a callout by accident
    #expect(!CalloutShape.isCallout(sessionCount: nil, leagueId: nil, field: nil))
  }

  /// Wave 6's rule, kept: `.notYet` is not `.failed`. "The callout couldn't be
  /// sent" over a database that has not had the migration is a lie.
  @Test func anUndeployedFunctionIsNotAFailure() {
    let missing = RpcError(name: "call_out", underlying: "PGRST202 Could not find the function", droppedArgs: [])
    let refused = RpcError(name: "call_out", underlying: "Callouts are between buddies. Add them first", droppedArgs: [])
    #expect(CalloutService.notYet(missing))
    #expect(!CalloutService.notYet(refused))
    // QB-01 · never "the latest update", and never the private noun in the
    // failure — the golfer chose "I want to beat one guy" and has never met
    // the word "callout".
    #expect(!CalloutService.notYetLine.lowercased().contains("update"))
    #expect(!CalloutService.notYetLine.lowercased().contains("callout"))
    #expect(CalloutService.notYetLine.contains("schedule"))
  }
}
