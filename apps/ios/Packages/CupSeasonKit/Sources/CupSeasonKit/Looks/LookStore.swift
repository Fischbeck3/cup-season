// Cup Season — the looks' state (IOS-025). The person's dial (device-local),
// every league's curated look (one `league_looks()` read per session), and
// the Pro's write (`set_league_look()`, optimistic; reverts on error so the
// room never keeps a colour the server refused).
//
// Both RPCs are hand-declared: the migration (`20260827200000_league_look`)
// is not in the snapshot yet, and deploy skew is the normal state this week.
// Every read fails CLOSED — an error, a missing function, an odd payload all
// mean "no league looks", never a stale or invented one.

import Foundation
import Observation
import CSDesign

/// `league_looks()` → `{ "<league uuid>": "<key>", … }`.
struct LookLeagueLooksCall: RpcCall {
  static let name = "league_looks"
  static let optionalArgs: [String] = []
  typealias Returns = [String: String?]
}

/// `set_league_look(p_league, p_look)` — commissioner only; empty clears.
struct LookSetLeagueLookCall: RpcCall {
  static let name = "set_league_look"
  static let optionalArgs: [String] = []
  typealias Returns = RpcVoid
  let p_league: UUID
  let p_look: String
}

@MainActor
@Observable
public final class LookStore {
  /// The person's dial. Writing persists (`cs_look`).
  public var personal: PersonalLook {
    didSet { if persist { personal.save(defaults) } }
  }
  /// Every league's curated key, by league id. Empty until `load()`, and after any failure.
  public private(set) var leagueLooks: [UUID: String] = [:]
  public private(set) var loaded = false
  /// DEBUG hatch — pins the resolver's date. nil = now.
  public var pinnedDate: Date?

  @ObservationIgnored private let svc: SupabaseService
  @ObservationIgnored private let defaults: UserDefaults
  @ObservationIgnored private var persist = true
  @ObservationIgnored private var loadedFor: UUID?

  public init(service: SupabaseService = .shared, defaults: UserDefaults = .standard) {
    self.svc = service
    self.defaults = defaults
    self.personal = PersonalLook.load(defaults)
  }

  /// A dial setting that does not touch UserDefaults (the `-cs_dev_look` hatch).
  public func setPersonalTransient(_ p: PersonalLook) {
    persist = false
    personal = p
    persist = true
  }

  public var today: Date { pinnedDate ?? Date() }

  // MARK: reads

  /// One read per signed-in session; a second call for the same user is a no-op.
  public func load(userId: UUID?) async {
    guard let userId else { leagueLooks = [:]; loaded = false; loadedFor = nil; return }
    guard loadedFor != userId else { return }
    loadedFor = userId
    leagueLooks = (try? await svc.call(LookLeagueLooksCall())).map(Self.parse) ?? [:]
    loaded = true
  }

  /// Only well-formed pairs survive: a uuid key and a calendar key the catalogue knows.
  nonisolated static func parse(_ raw: [String: String?]) -> [UUID: String] {
    var out: [UUID: String] = [:]
    for (k, v) in raw {
      guard let id = UUID(uuidString: k), let v, CSLooks.spec(v)?.window != nil else { continue }
      out[id] = v
    }
    return out
  }

  /// The look for a league's room — phase ≻ the Pro's choice ≻ the person's dial.
  public func look(for m: Me.Membership?) -> CSLookSpec? {
    guard let m else { return personalLook() }
    return LookResolver.resolve(date: today, leaguePhase: SeasonPhase.of(m), leagueLook: leagueLooks[m.league_id], personal: personal)
  }

  /// The person's dial, resolved for today — Home, You, the ⊕.
  public func personalLook() -> CSLookSpec? {
    LookResolver.personalLook(personal, date: today)
  }

  /// What the calendar says today, whatever the dial — the "Follow the calendar" sub-line.
  public func calendarLook() -> CSLookSpec? {
    LookResolver.calendarLook(date: today)
  }

  // MARK: the Pro's write

  /// Optimistic: the room wears it at once; the server's refusal puts it back and is thrown for the toast.
  public func setLeagueLook(leagueId: UUID, key: String?) async throws {
    let previous = leagueLooks[leagueId]
    if let key { leagueLooks[leagueId] = key } else { leagueLooks.removeValue(forKey: leagueId) }
    do {
      _ = try await svc.call(LookSetLeagueLookCall(p_league: leagueId, p_look: key ?? ""))
    } catch {
      if let previous { leagueLooks[leagueId] = previous } else { leagueLooks.removeValue(forKey: leagueId) }
      throw error
    }
  }
}
