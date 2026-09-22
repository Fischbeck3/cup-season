// Cup Season — where a forfeit hangs (D242 / C-5; T-02; CORE_FLOWS §6.4).
//
// A forfeit is T-02's noun: the ONE way an optional stake is expressed. It
// required a league, so "loser buys" between two buddies who share no season
// was inexpressible, and the only answer the app could offer was a thirteen-week
// season for a Saturday bet.
//
// TWO RULES, AND BOTH ARE VALUES A TEST HOLDS:
//
//   1. EXACTLY ONE HOME. At most one CONTAINER (a season, a moment, a plan) and,
//      when there is no container at all, a named opponent — the fourth home,
//      which is the callout's own stake. The database says the same thing in two
//      CHECKs (`forfeits_one_home`, `forfeits_has_home`); this is their twin, so
//      the sheet refuses before the server has to.
//
//   2. NO MONEY COLUMN, EVER. `forfeits` carries a load-bearing rule
//      (20260724120000:10-13): terms are PROSE, never an amount. Nothing here
//      formats a currency, and `moneyWords` is the assertion that nothing ever
//      will — it is the store-review posture as much as taste (D39/D64).

import Foundation

public struct ForfeitHome: Sendable, Equatable {
  public let leagueId: UUID?
  public let eventId: UUID?
  public let scheduledRoundId: UUID?
  /// The other side. Null = a standing bounty against the field, which only a
  /// container can hold.
  public let opponent: UUID?

  public init(leagueId: UUID? = nil, eventId: UUID? = nil, scheduledRoundId: UUID? = nil, opponent: UUID? = nil) {
    self.leagueId = leagueId; self.eventId = eventId
    self.scheduledRoundId = scheduledRoundId; self.opponent = opponent
  }

  /// The three containers, counted.
  public var containers: Int {
    (leagueId == nil ? 0 : 1) + (eventId == nil ? 0 : 1) + (scheduledRoundId == nil ? 0 : 1)
  }

  /// What the server's two CHECKs say, said once on the client.
  public enum Verdict: Sendable, Equatable {
    case ok
    /// Two or three containers named at once.
    case twoHomes
    /// No container and no opponent — a stake hanging on nothing.
    case noHome
    /// A bounty against the field needs a field to be against.
    case bountyNeedsAContainer
  }

  public var verdict: Verdict {
    if containers > 1 { return .twoHomes }
    if containers == 0 && opponent == nil { return .noHome }
    if containers == 0 && opponent != nil { return .ok }
    return .ok
  }

  public var isValid: Bool { verdict == .ok }

  /// The sentence a refusal reads as. A refusal a golfer can read beats a
  /// control that is missing (L-32).
  public var refusal: String? {
    switch verdict {
    case .ok: return nil
    case .twoHomes: return "A pride bet hangs on one thing."
    case .noHome: return "Say who it is with, or what it hangs on."
    case .bountyNeedsAContainer: return "A bounty needs a field. Name who it’s with."
    }
  }

  /// Which of the four this is, for a caller that renders a different head.
  public enum Kind: String, Sendable, Equatable { case season, moment, plan, buddies, none }
  public var kind: Kind {
    if leagueId != nil { return .season }
    if eventId != nil { return .moment }
    if scheduledRoundId != nil { return .plan }
    if opponent != nil { return .buddies }
    return .none
  }
}

/// The sheet's own copy (`PotPane`'s forfeit sheet, moved out of the pot pane so
/// it is reachable without a season). CORE_FLOWS §6.4.
public enum ForfeitCopy {
  /// D299 · **ONE composer, ONE title.** LV-02 ruled one set of words for the
  /// forfeit composer and the two sheets still differed — the Pot pane said
  /// *Post a forfeit* and this one asked *What’s on it?*. Both say the act now.
  public static let title = "Post a pride bet"
  public static let nameLabel = "Name it"
  public static let namePlaceholder = "The Lawn Bet"
  public static let termsLabel = "The terms"
  public static let termsPlaceholder = "Loser mows the winner’s lawn"
  public static let whoLabel = "Who"
  public static let theField = "The field"
  public static let settlesLabel = "When it settles"
  public static let settlesPlaceholder = "Sunday’s clash · first ace · the Cup Final"
  public static let put = "Put it on the record"

  /// D299 · **the ledger's head, and the control that opens the composer.**
  /// They live here rather than in `PotPane` because the pane draws nothing at
  /// all when a league has no pride bets on it — it is the one surface of this
  /// object a screenshot cannot prove, so a test holds the words instead. The
  /// control and the sheet it opens are ONE constant (`title`), which is what
  /// LV-02 asked for and did not get.
  public static let ledgerHead = "Pride bets · on the record"

  /// L-39 / T-02 · the one sentence that says what a forfeit is, at first
  /// contact, VERBATIM from TERMINOLOGY §1 definition 9.
  ///
  /// LV-01 · the sentence this replaces — "Cup Season keeps no money on it" —
  /// was a CUSTODY CLAIM, which is the class L-09 retired along with "never
  /// held" and "takes no cut". A promise about what the company does with
  /// money is a structural promise, and D184 keeps a future pot service open;
  /// the brand canon's rule is to say what is true now and promise nothing
  /// structural. The ledger line is the only place money's handling is
  /// described, and it is `MoneyCopy.ledger`.
  public static let definition = "A bet for pride. It settles on a tap and goes on the record — never on the books."

  /// A forfeit is a fact, not a summons: no push fires (L-20/L-22).
  public static let noPush = "Nobody gets a notification. It’s on the record and that’s the point."

  // MARK: - D366 (F6) · what this is, said before the fields

  /// The owner, 2026-09-15: the composer looked engaging but its purpose and
  /// place were unclear. A first-time golfer can now answer, from the sheet
  /// alone: what the button creates, whether the other golfer has agreed,
  /// what decides it, who confirms it, where it appears later, and whether it
  /// touches league points. **It is honest about being record-only**: it
  /// records an agreement made between you; it does not send a challenge.
  /// Acceptance and competition-backed settlement are a mechanics proposal
  /// (`docs/planning/2026-09-15-applause-and-pride-proposals.md` §3).
  public static let sub = "RECORDED HERE, MADE BETWEEN YOU"
  public static let purpose = "A bet for pride between golfers, kept on the record. It records an agreement you've already made — nobody is asked to accept here."
  public static let whereLabel = "Where it lives"
  public static let decidesLabel = "What decides it"
  public static let decidesOptional = "optional"
  public static let points = "It never touches league points."
  public static let whereItShows = "It shows under Pride bets · on the record, for the people involved."

  /// "You and Alex" · "You and the field — first to hit it"
  public static func who(_ opponentName: String?) -> String {
    opponentName.map { "You and \(CSBands.fn1($0))" } ?? "You and \(theField.lowercased()) — first to hit it"
  }

  /// The competition context the record hangs on — the one place a first-time
  /// golfer learns this is not itself a contest.
  public static func context(_ home: ForfeitHome, name: String? = nil) -> String {
    context(kind: home.kind, name: name)
  }
  public static func context(kind: ForfeitHome.Kind, name: String? = nil) -> String {
    switch kind {
    case .season:  return "On \(name ?? "this season") — the result never touches its points."
    case .moment:  return "On \(name ?? "this contest")."
    case .plan:    return "On \(name ?? "this planned round")."
    case .buddies: return "Between the two of you — no season or round attached."
    case .none:    return "Say who it is with, or what it hangs on."
    }
  }

  /// How the result is confirmed today: a tap by a party, never a scored
  /// comparison and never an acceptance the app collected.
  public static func confirm(_ opponentName: String?) -> String {
    let them = opponentName.map { CSBands.fn1($0) } ?? "the other golfer"
    return "When it's decided, either of you settles it with a tap. \(them) isn't asked to accept here — tell them yourself."
  }

  /// Every sentence the composer shows, for the sweeps: no money word, no
  /// "forfeit", and the honesty lines present.
  public static var all: [String] {
    [title, sub, purpose, nameLabel, namePlaceholder, termsLabel, termsPlaceholder, whoLabel, theField,
     whereLabel, decidesLabel, decidesOptional, settlesLabel, settlesPlaceholder, put, definition, noPush,
     points, whereItShows, ledgerHead, who("Alex"), who(nil), confirm("Alex"), confirm(nil),
     context(ForfeitHome(leagueId: UUID()), name: "the Fellas"), context(ForfeitHome(opponent: UUID()))]
  }

  /// The words a money AMOUNT would be written in. Nothing in this product may
  /// print one on a forfeit, and `ForfeitHomeTests` asserts that none of the
  /// strings above contains any of them.
  public static let moneyWords: Set<String> = ["$", "cents", "dollars", "usd", "amount", "stake"]
}

/// C-5 · `create_forfeit`, widened past the league. Hand-declared: the eight-
/// argument overload is unpushed, so `contract.psv` (a snapshot of prod) cannot
/// carry it yet.
///
/// C-06 · NOTHING is droppable, and nothing needs to be. `p_event` and
/// `p_round` are optionals, so a forfeit homed on a season already sends the
/// six keys the deployed function has — no shed required. Keeping them on the
/// droppable list meant a blind retry on ANY error re-homed a MOMENT's or a
/// PLAN's forfeit onto the league (a different bet), or posted a second one
/// after a lost response. A moment- or plan-homed forfeit against a database
/// that has not had the migration takes PGRST202 and says so.
public struct CreateForfeitCall: RpcCall {
  public static let name = "create_forfeit"
  public static let optionalArgs: [String] = []
  public typealias Returns = UUID
  public var p_league: UUID?
  public var p_name: String
  public var p_terms: String
  public var p_kind: String
  public var p_other: UUID?
  public var p_hangs: String?
  public var p_event: UUID?
  public var p_round: UUID?

  enum Keys: String, CodingKey { case p_league, p_name, p_terms, p_kind, p_other, p_hangs, p_event, p_round }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: Keys.self)
    try c.encode(p_league, forKey: .p_league)     // an explicit null, never an omitted key
    try c.encode(p_name, forKey: .p_name)
    try c.encode(p_terms, forKey: .p_terms)
    try c.encode(p_kind, forKey: .p_kind)
    try c.encode(p_other, forKey: .p_other)
    try c.encodeIfPresent(p_hangs, forKey: .p_hangs)
    try c.encodeIfPresent(p_event, forKey: .p_event)
    try c.encodeIfPresent(p_round, forKey: .p_round)
  }

  public init(home: ForfeitHome, name: String, terms: String, kind: String = "custom", hangs: String? = nil) {
    p_league = home.leagueId; p_event = home.eventId; p_round = home.scheduledRoundId
    p_other = home.opponent
    p_name = name; p_terms = terms; p_kind = kind
    p_hangs = (hangs?.isEmpty ?? true) ? nil : hangs
  }
}

public struct ForfeitService: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  /// A forfeit is a FACT, not a summons: nothing here writes a push (L-20/L-22).
  @discardableResult
  public func post(_ home: ForfeitHome, name: String, terms: String, kind: String = "custom", hangs: String? = nil) async throws -> UUID {
    guard home.isValid else {
      throw RpcError(name: Self.name, underlying: home.refusal ?? "A pride bet hangs on one thing", droppedArgs: [])
    }
    return try await svc.call(CreateForfeitCall(home: home, name: name, terms: terms, kind: kind, hangs: hangs))
  }
  static let name = "create_forfeit"

  /// The season two golfers share, if there is one. `league_members` is
  /// readable by fellow members, so this answers only for a golfer I really do
  /// share a season with — and a read that fails answers nil rather than
  /// guessing (L-44), which orders the three lengths as though we share none.
  public func sharedLeague(with pid: UUID, mine: [UUID]) async -> UUID? {
    guard !mine.isEmpty else { return nil }
    struct Row: Decodable { let league_id: UUID? }
    let rows: [Row]? = try? await svc.client.from("league_members")
      .select("league_id").eq("profile_id", value: pid).in("league_id", values: mine).limit(1).execute().value
    return rows?.first?.league_id
  }
}
