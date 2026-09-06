// Cup Season — "Go head to head" (D237 / R-F / R-J; IA §9, §9.1; CORE_FLOWS §9).
//
// THE OWNER RULED THE SHAPE AND THE WORDS. After the golfer, ONE question, and
// all three lengths are always offered:
//
//     How long?
//     ▌ This Saturday   → a live match, on one card
//     ▌ One week        → best round by Sunday takes it
//     ▌ A season        → a table, and a cup at the end
//
// The person's state may ORDER the three; it may never withhold one. The golfer
// never meets the object's name, and every length lands on something that
// already exists — a live round, a one-session event at a field of two, or a
// two-golfer season (D205: a solo league IS a season at two golfers).
//
// THE STAKE, IF ANY, IS A FORFEIT or the live game's own stake (T-02, D242).
// No length invents a money noun, and that is a test, not a comment.

import Foundation

// MARK: - the length

public enum CalloutLength: String, Sendable, Equatable, CaseIterable, Identifiable {
  case thisSaturday, oneWeek, aSeason
  public var id: String { rawValue }

  /// R-F's words, verbatim. These are the owner's own and are pinned by test.
  public var title: String {
    switch self {
    case .thisSaturday: return "This Saturday"
    case .oneWeek:      return "One week"
    case .aSeason:      return "A season"
    }
  }

  /// R-F's glosses, verbatim.
  public var gloss: String {
    switch self {
    case .thisSaturday: return "a live match, on one card"
    case .oneWeek:      return "best round by Sunday takes it"
    case .aSeason:      return "a table, and a cup at the end"
    }
  }

  /// The engine object behind it. The golfer never hears any of these words.
  public enum Object: String, Sendable, Equatable {
    /// `start_live_round(p_game:'match')` — the free door (L-40).
    case liveRound
    /// `call_out` — a Ryder with a field of two and one session (D237).
    case callout
    /// `create_league` → `lock_league(p_structure:'solo')` → `invite_golfer`.
    /// NOT `add_friend_to_league`, which seats a golfer with no covenant
    /// (CORE_FLOWS §0 A-1; L-12).
    case pairSeason
  }

  public var object: Object {
    switch self {
    case .thisSaturday: return .liveRound
    case .oneWeek:      return .callout
    case .aSeason:      return .pairSeason
    }
  }

  /// The RPCs each one calls, named so a test can assert that none of them is
  /// new and none of them is a money object.
  public var rpcs: [String] {
    switch self {
    case .thisSaturday: return ["start_live_round"]
    case .oneWeek:      return ["call_out"]
    case .aSeason:      return ["create_league", "lock_league", "invite_golfer"]
    }
  }

  // MARK: the order, which the state may change and may never shorten

  /// ALL THREE, ALWAYS. A golfer already in a live round sees *This Saturday*
  /// first; two who already share a season see *A season* last. Nothing is ever
  /// withheld, and the returned array is always `allCases` in some order.
  public static func offered(liveNow: Bool = false, shareASeason: Bool = false) -> [CalloutLength] {
    var order: [CalloutLength] = [.thisSaturday, .oneWeek, .aSeason]
    if shareASeason {
      order.removeAll { $0 == .aSeason }
      order.append(.aSeason)
    }
    if liveNow {
      order.removeAll { $0 == .thisSaturday }
      order.insert(.thisSaturday, at: 0)
    }
    return order
  }

  /// The head above the three.
  public static let question = "How long?"

  /// WHEN "ONE WEEK" ENDS, and it ends on a **Sunday** — because R-F's ruled
  /// gloss says so out loud ("best round by Sunday takes it") and a sheet that
  /// then printed "by Sat Sep 12" would have two screens of one client
  /// disagreeing about the same fact. Caught by looking at the shipped sheet
  /// beside the ruled words, not by a test.
  ///
  /// The coming Sunday, unless that is fewer than three days out — a callout
  /// raised on Friday for the day after tomorrow is not a week, and the door
  /// says a week.
  public static func defaultClose(today: String = CSDate.today(), calendar: Calendar = .current) -> String {
    var d = EventDates.nextSundayISO(today: today, calendar: calendar)
    if (CSDate.days(from: today, to: d) ?? 7) < 3 { d = LeagueDates.addDays(d, 7, calendar: calendar) }
    return d
  }
}

// MARK: - the copy a field of two reads

/// Every sentence a callout ever shows, in one place. The Ryder room's grammar
/// was written for a four-week series between two SIDES — "WEEK 1 OF 1" over a
/// thing that is one week long by construction, and a series score of "1–0"
/// between two men who bet on Saturday — so a callout does not land there.
public enum CalloutCopy {
  // the sheet
  public static func sheetTitle(_ name: String) -> String { "Call \(CSBands.fn1(name)) out" }
  public static let windowRow = "This week"
  public static let windowGloss = "best round by Sunday takes it"
  public static let stakeQuestion = "What's on it?"
  public static let stakeNone = "Nothing, just the record"
  public static let stakeForfeit = "A forfeit"
  /// T-02 · the stake is a forfeit, in words, never an amount (D242, and
  /// `forfeits` has no money column by rule).
  public static let stakePlaceholder = "Loser buys the beers"
  public static let send = "Send it"

  /// The picker's empty state. L-32: it ends in a next move.
  public static let noBuddies = "Callouts are between buddies. Add one first."
  public static let noBuddiesDoor = "Find golfers"
  /// One open per pair at a time — the door says so rather than refusing.
  public static let alreadyOpen = "See the callout"

  // what it says while it is open
  /// `LeagueDates.dowMonDay` is the producer — "Sun Sep 13" — and it is the
  /// same one the covenant's clock and the season page's dateline use. A second
  /// date format here is exactly the drift §4's check 27 forbids.
  public static func openLine(closesOn: String) -> String {
    "Best round by \(LeagueDates.dowMonDay(closesOn)) takes it."
  }
  public static func openLineWithStake(closesOn: String, terms: String) -> String {
    "Best round by \(LeagueDates.dowMonDay(closesOn)) takes it. \(terms)."
  }
  /// N12, generalised: the one true anticipation push in the product. L-01 —
  /// the number shows its work, and it is MY number, never a gross target
  /// derived from his (that is not computable, and §4's lint forbids writing it).
  public static func theyPosted(_ name: String, pvi: Double, daysLeft: Int) -> String {
    "\(CSBands.fn1(name)) posted. \(RoundCopy.signed(pvi)) to beat, \(daysLeft) day\(daysLeft == 1 ? "" : "s") left."
  }

  // what it says when it settles
  /// D21 (b): a tie is `halve`.
  public static let allSquare = "All square. Nobody buys."
  public static func youTookIt(mine: Double, theirs: Double?) -> String {
    guard let theirs else { return "You took it — \(RoundCopy.signed(mine)) and he never posted." }
    return "You took it — \(RoundCopy.signed(mine)) to his \(RoundCopy.signed(theirs))."
  }
  public static func theyTookIt(_ name: String, theirs: Double, mine: Double?) -> String {
    guard let mine else { return "\(CSBands.fn1(name)) took it — \(RoundCopy.signed(theirs)), and you never posted." }
    return "\(CSBands.fn1(name)) took it — \(RoundCopy.signed(theirs)) to your \(RoundCopy.signed(mine))."
  }
  /// D21 (c) / L-22: if neither posted it halves and closes quietly. NO
  /// "never showed" line is ever written, and this producer has no way to
  /// write one — the halve sentence is `allSquare` and there is no other.
  public static let nobodyPosted = allSquare

  // the recipient's door
  public static func received(_ name: String) -> String { "\(CSBands.fn1(name)) called you out" }
  public static func receivedSub(closesOn: String, terms: String?) -> String {
    "Best round by \(LeagueDates.dowMonDay(closesOn)) takes it. "
      + (terms.map { "\($0)." } ?? "Nothing on it but the record.")
  }
  public static let accept = "I'm in"
  public static let decline = "Not this week"
  /// Saying no leaves no mark on anybody (L-22). The caller is told the truth
  /// and nobody is named as having refused.
  public static let declined = "Passed. Nothing was written down."
  public static let mutedThisWeek = "They passed this week. Try them next week."

  /// Zero points, always (D21; league_id is null so nothing reaches a table).
  public static let noPoints = "It's for the record — nothing scores toward a season."
}

// MARK: - the two RPCs

/// R19 · `call_out(p_opponent, p_closes_on, p_forfeit_terms default null)`.
/// Hand-declared rather than generated: the function is unpushed, so it is not
/// in `contract.psv` yet and `Rpc.swift` cannot carry it (the contract is a
/// snapshot of prod and is refreshed after the push, never ahead of it).
public struct CallOutCall: RpcCall {
  public static let name = "call_out"
  /// Nothing is droppable. The skew retry sheds every optional at once, and a
  /// callout whose stake was silently dropped is a bet nobody agreed to.
  public static let optionalArgs: [String] = []
  public typealias Returns = UUID
  public var p_opponent: UUID
  public var p_closes_on: String?
  public var p_forfeit_terms: String?
  public init(p_opponent: UUID, p_closes_on: String? = nil, p_forfeit_terms: String? = nil) {
    self.p_opponent = p_opponent; self.p_closes_on = p_closes_on; self.p_forfeit_terms = p_forfeit_terms
  }
}

/// R20 · `respond_callout(p_event, p_accept default true)` → 'accepted' |
/// 'declined' | 'closed' | 'gone'.
public struct RespondCalloutCall: RpcCall {
  public static let name = "respond_callout"
  public static let optionalArgs: [String] = []
  public typealias Returns = String
  public var p_event: UUID
  public var p_accept: Bool
  public init(p_event: UUID, p_accept: Bool) { self.p_event = p_event; self.p_accept = p_accept }
}

public struct CalloutService: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  /// The window defaults to a week out. `closesOn` is a CALENDAR date through
  /// CSDate (L-07), never an instant.
  public func callOut(_ opponent: UUID, closesOn: String? = nil, forfeitTerms: String? = nil) async throws -> UUID {
    let terms = forfeitTerms?.trimmingCharacters(in: .whitespacesAndNewlines)
    return try await svc.call(CallOutCall(p_opponent: opponent, p_closes_on: closesOn,
                                          p_forfeit_terms: (terms?.isEmpty ?? true) ? nil : terms))
  }

  public func respond(_ event: UUID, accept: Bool) async throws -> String {
    try await svc.call(RespondCalloutCall(p_event: event, p_accept: accept))
  }

  /// The three-way state every unpushed read on this wave uses (wave 6's own
  /// lesson): `.notYet` is not `.failed`, and "the callout could not be sent"
  /// over a database that simply has not had the migration is a lie.
  public static func notYet(_ error: Error) -> Bool { PostService.fallbackFires(on: error) }
  /// QB-01 · two things were wrong with this sentence and both mattered. It
  /// sent a golfer to the App Store for an update that does not exist, and it
  /// introduced the product's private noun — "callouts" — inside the failure,
  /// to somebody who had chosen "Go head to head" and had never met the
  /// word. It now says what the golfer did, says the server is behind, and
  /// names the door that is open today: a round on the schedule, tagged.
  public static let notYetLine =
    "Calling somebody out isn\u{2019}t switched on yet \u{2014} put a round on the schedule and tag them instead."
}

// MARK: - what a callout IS, to a reader

public enum CalloutShape {
  /// The one predicate that decides whether an event is a callout, on both
  /// clients: one session, no league, a field of two. Anything else is a Ryder
  /// and lands in the Ryder room with the Ryder's own words — which is the
  /// finding the D237 gate produced, not a taste call.
  public static func isCallout(sessionCount: Int?, leagueId: UUID?, field: Int?) -> Bool {
    (sessionCount ?? 0) == 1 && leagueId == nil && (field ?? 0) == 2
  }
}
