// Cup Season — R10 · `run_it_back(p_league)` (D243).
//
// The copy is `RunItBack` in `LeagueCopy.swift`; this is the hand. Two seats,
// two verbs, and the difference is not cosmetic: the Pro's tap MINTS a season
// under the same league (nobody re-types a code), and a member's tap writes one
// line on the board and nothing else.
//
// WHY THE MEMBER'S ASK IS A BOARD LINE AND NOT A NUDGE. D248's own conflict
// clause rules that three kinds "ship with a recipient's Home item or they do
// not ship at all", and the run-back ask is one of the three. That Home item is
// not built and the push channel is gated off behind D248's APNs gate, so a
// `push_nudges` row would be a request that disappears. The board is a surface
// the Pro already reads, today, with no new mechanic and no producer.

import Foundation

/// Hand-declared: `run_it_back` is unpushed, so it is not in `contract.psv`
/// and `Rpc.swift` cannot carry it. Every argument but the league DEFAULTS
/// server-side, so a client that ships first still calls it.
public struct RunItBackCall: RpcCall {
  public static let name = "run_it_back"
  /// The four terms may all be dropped on a skew retry — dropping them means
  /// "carry last season's forward", which is exactly what the RPC does with a
  /// null. Dropping the LEAGUE would run back a different season, so it is not
  /// on this list.
  public static let optionalArgs = ["p_starts_on", "p_ends_on", "p_buyin_cents", "p_season_months", "p_pay_note"]
  public typealias Returns = RunItBackResult
  public var p_league: UUID
  public var p_starts_on: String?
  public var p_ends_on: String?
  public var p_buyin_cents: Int?
  public var p_season_months: Int?
  public var p_pay_note: String?
  public init(p_league: UUID, p_starts_on: String? = nil, p_ends_on: String? = nil,
              p_buyin_cents: Int? = nil, p_season_months: Int? = nil, p_pay_note: String? = nil) {
    self.p_league = p_league; self.p_starts_on = p_starts_on; self.p_ends_on = p_ends_on
    self.p_buyin_cents = p_buyin_cents; self.p_season_months = p_season_months; self.p_pay_note = p_pay_note
  }
}

/// R10's answer. Every field is optional but the flags, so a server that grows
/// a field the client does not know decodes fine and one that has not grown it
/// yet renders nothing rather than a zero (L-44).
public struct RunItBackResult: Decodable, Sendable, Equatable {
  public struct Season: Decodable, Sendable, Equatable {
    public let id: UUID?
    public let number: Int?
    public let starts_on: String?
    public let ends_on: String?
  }
  public let already_running: Bool?
  public let league_id: UUID?
  public let season: Season?
  public let seated: Int?
  public let invited: Int?
  public let covenant_refires: Bool?
  public let stake_moved: Bool?
  public let length_moved: Bool?

  /// The sentence the golfer reads, produced once.
  public var line: String {
    RunItBack.done(seasonNumber: season?.number, seated: seated ?? 0,
                   covenantRefires: covenant_refires ?? false)
  }
}

public struct RunItBackService: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  public enum Outcome: Sendable, Equatable {
    case ran(RunItBackResult)
    /// The migration is not pushed. Not a failure, and never narrated as one.
    case notYet
    case refused(String)
  }

  public func run(_ league: UUID, startsOn: String? = nil, endsOn: String? = nil,
                  buyInCents: Int? = nil, months: Int? = nil, payNote: String? = nil) async -> Outcome {
    do {
      let r = try await svc.call(RunItBackCall(p_league: league, p_starts_on: startsOn, p_ends_on: endsOn,
                                               p_buyin_cents: buyInCents, p_season_months: months,
                                               p_pay_note: payNote))
      return .ran(r)
    } catch {
      if PostService.fallbackFires(on: error) { return .notYet }
      return .refused(AuthRules.human(error, fallback: "Couldn't start the next season."))
    }
  }

  /// The member's ask: one board line, once per league. The spend is local
  /// because L-20's "once" is about not pestering the Pro, and the board row
  /// itself is the durable record.
  public func ask(league: UUID, season: UUID?, member: UUID, myFirstName: String?,
                  board: BoardRepository = SupabaseBoardRepository(),
                  defaults: UserDefaults = .standard) async -> String {
    let key = RunItBack.askKey(league: league)
    if defaults.bool(forKey: key) { return RunItBack.askAlready }
    do {
      try await board.insertChat(league: league, season: season, member: member,
                                 body: RunItBack.askLine(myFirstName))
      defaults.set(true, forKey: key)
      return RunItBack.askSent
    } catch {
      return AuthRules.human(error, fallback: "Couldn't send that.")
    }
  }
}
