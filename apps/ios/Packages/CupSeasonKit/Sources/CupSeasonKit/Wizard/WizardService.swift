// Cup Season — the wizard's writes (index.html, the module block):
//   createLeague   14852–14877   RPC create_league(p_name, p_code), telemetry league_create
//   lockBylaws     17194–17248   ONE call — RPC lock_league(...) (D111): the bylaws,
//                                season 1, form_squads unless solo, and the phase +
//                                name, in one server transaction. Idempotent on
//                                `locked_at`: a retap after an ambiguous failure gets
//                                `{already_locked: true}` and the standing truth
//                                instead of a second season. The next phase comes
//                                from the RPC's result (the STORED structure), never
//                                from the dials. Deploy skew does NOT ride the
//                                Kit's `call(_:)` retry: that retry sheds every
//                                droppable arg at once, so `WizardLockCall`
//                                declares none and a refusal reaches the golfer
//                                instead of locking a league on the SQL defaults.
//                                Every deployed signature since 20260829220000
//                                carries all eighteen args; the web's own skew
//                                path (17239–17248) falls back only when the
//                                FUNCTION is missing, never by dropping args.
//   the lock button 15226–15261  lock_attempt · lock_blocked · lock_ok telemetry
//   qaEvent        6097–6105     client_events INSERT, fire-and-forget, never throws
//   wizCancel      15278–15292   delete_league on step-0 Cancel
//   loadBylaws     14137–14142   league_settings select (run it back / an existing league)
//
// The reads here (`league`, `bylaws`, `season`, `memberCount`) are plain
// selects under RLS; the phone previews and renders, it never decides.

import Foundation
import Supabase

public struct WizardService: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  // MARK: telemetry (`qaEvent`)

  public enum Event: String, Sendable { case league_create, lock_attempt, lock_blocked, lock_ok, invite_open }

  /// Fire-and-forget; a breadcrumb must never break a lock. One writer since
  /// IOS-024: `CSTelemetry` (dedupes, swallows, never blocks).
  public func track(_ event: Event, _ props: [String: JSONValue] = [:]) {
    CSTelemetry.event(event.rawValue, props)
  }

  // MARK: create (`createLeague`)

  public struct Created: Sendable, Equatable, Codable {
    public let leagueId: UUID
    public let name: String
    public let code: String
    public let memberId: UUID?
    public init(leagueId: UUID, name: String, code: String, memberId: UUID?) {
      self.leagueId = leagueId; self.name = name; self.code = code; self.memberId = memberId
    }
  }

  /// D355 · `create_league_once(p_request_id, p_name, p_code)` — the same
  /// league however many times Start is pressed. Hand-declared while the
  /// migration awaits its contract refresh; no droppable arguments, and NO
  /// fallback to `create_league`: a server without the function cannot
  /// deduplicate, so it is told to the golfer and nothing is minted.
  struct CreateLeagueOnceCall: RpcCall {
    static let name = "create_league_once"
    static let optionalArgs: [String] = []
    typealias Returns = JSONValue
    let p_request_id: UUID
    let p_name: String
    let p_code: String
  }
  public static let createNotAvailable = "Starting a season isn’t available on this server yet. Nothing was created — try again after the update."

  /// One request id per season being started, FROZEN across retries and
  /// relaunches (`PendingCreate`). A replay returns the original league.
  public func createLeague(name rawName: String, request: UUID) async throws -> Created {
    let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
    let finalName = name.isEmpty ? "My Cup" : name
    let code = WizardCode.codeFor(finalName)
    let data: JSONValue
    do { data = try await svc.call(CreateLeagueOnceCall(p_request_id: request, p_name: finalName, p_code: code)) }
    catch {
      if (error as? RpcError)?.isMissingFunction == true {
        throw RpcError(name: CreateLeagueOnceCall.name, underlying: Self.createNotAvailable, droppedArgs: [])
      }
      throw error
    }
    guard let idStr = data["league"]?["id"]?.string, let id = UUID(uuidString: idStr) else {
      throw RpcError(name: CreateLeagueOnceCall.name, underlying: "The league was created but its id did not come back.", droppedArgs: [])
    }
    if data["replayed"]?.bool != true {
      track(.league_create, ["named": .bool(finalName != "My Cup")])
      CSTelemetry.product(.leagueCreated, leagueId: id)   // IOS-024
    }
    return Created(leagueId: id, name: data["league"]?["name"]?.string ?? finalName,
                   code: data["league"]?["code"]?.string ?? code,
                   memberId: data["member"]?["id"]?.string.flatMap(UUID.init))
  }

  // MARK: the existing league (an in-progress setup, or run it back)

  public struct LeagueHead: Decodable, Sendable, Equatable {
    public let id: UUID
    public let name: String
    public let code: String?
    public let phase: String
  }

  public func league(_ id: UUID) async throws -> LeagueHead? {
    let rows: [LeagueHead] = try await svc.client.from("leagues").select("id, name, code, phase").eq("id", value: id).limit(1).execute().value
    return rows.first
  }

  /// `loadBylaws` — the settings row, named columns.
  public func bylaws(_ leagueId: UUID) async throws -> LeagueRoom.Settings? {
    let rows: [LeagueRoom.Settings] = try await svc.client.from("league_settings")
      .select("league_id, preset, handicap_allowance, verification, counting_cap, participation_floor, floor_penalty, season_format, buyin_cents, season_months, locked_at, structure, draft_type, payout_champ, payout_runnerup, payout_king, finish")
      .eq("league_id", value: leagueId).limit(1).execute().value
    return rows.first
  }

  /// The number-1 season, if the league already has one (a retap after a partial lock).
  public func season(_ leagueId: UUID) async throws -> LeagueRoom.Season? {
    let rows: [LeagueRoom.Season] = try await svc.client.from("seasons").select("id, number, starts_on, ends_on, status")
      .eq("league_id", value: leagueId).eq("number", value: 1).limit(1).execute().value
    return rows.first
  }

  /// `openLockShare` counts THIS league's seats fresh (S2-04).
  public func memberCount(_ leagueId: UUID) async -> Int {
    let n = try? await svc.client.from("league_members").select("id", head: true, count: .exact).eq("league_id", value: leagueId).execute().count
    return n ?? 1
  }

  // MARK: the lock (`lockBylaws` → `lock_league`)

  public struct Locked: Sendable, Equatable {
    public let nextPhase: String
    public let seasonId: UUID
    public let startsOn: String
    public let endsOn: String
    /// The RPC found `locked_at` already set — a retap; the truth above stands.
    public let alreadyLocked: Bool
    /// R18 · did the pay note land in the same transaction? False means the
    /// season is live and the Pro still has to say how to pay — which the share
    /// screen names rather than letting it go quiet.
    public let payNoteLanded: Bool
    public init(nextPhase: String, seasonId: UUID, startsOn: String, endsOn: String,
                alreadyLocked: Bool, payNoteLanded: Bool = true) {
      self.nextPhase = nextPhase; self.seasonId = seasonId; self.startsOn = startsOn
      self.endsOn = endsOn; self.alreadyLocked = alreadyLocked; self.payNoteLanded = payNoteLanded
    }
  }

  /// One RPC. `today` pins the preview dates so a lock at 23:59 sends the same
  /// span the review card showed. The phase, the season and its dates are read
  /// back from the result — the server decided them.
  public func lock(leagueId: UUID, dials: WizardDials, fallbackName: String, today: String = CSDate.today()) async throws -> Locked {
    let typed = dials.name.trimmingCharacters(in: .whitespacesAndNewlines)
    let name = typed.isEmpty ? fallbackName : typed
    let call = WizardLockCall(dials, leagueId: leagueId, name: name, today: today)
    var noteLanded = call.payNote != nil
    let data: JSONValue
    do {
      data = try await svc.call(call)
    } catch {
      // R18 · the DECLARED fallback, and it fires on one condition: the
      // twenty-argument function is not deployed yet (PGRST202 / 42883).
      // A refusal — a wrong structure, a league that is gone — reaches the
      // golfer, exactly as it does today.
      guard call.payNote != nil, PostService.fallbackFires(on: error) else { throw error }
      data = try await svc.call(call.withoutPayNote)
      noteLanded = false
    }

    // `{already_locked, phase, season: row_to_json(seasons)}` — decoded defensively:
    // the season's id/dates may arrive nested (today's shape) or flat.
    let season = data["season"]
    guard let nextPhase = data["phase"]?.string,
          let idStr = season?["id"]?.string ?? data["season_id"]?.string, let seasonId = UUID(uuidString: idStr),
          let startsOn = season?["starts_on"]?.string ?? data["starts_on"]?.string,
          let endsOn = season?["ends_on"]?.string ?? data["ends_on"]?.string else {
      throw RpcError(name: WizardLockCall.name, underlying: "The season did not come back after it started.", droppedArgs: [])
    }
    let already = data["already_locked"]?.bool ?? false
    // Honest breadcrumb: the skew retry drops every optional arg on ANY error,
    // so a lock that reached the database on its second try wears the SQL
    // defaults — the dates are the tell.
    let sentDates = call.args.p_starts_on == startsOn && call.args.p_ends_on == endsOn
    track(.lock_ok, ["next_phase": .string(nextPhase), "already_locked": .bool(already), "dates_as_sent": .bool(sentDates)])
    CSTelemetry.product(.leagueLocked, leagueId: leagueId)   // IOS-024
    return Locked(nextPhase: nextPhase, seasonId: seasonId, startsOn: startsOn, endsOn: endsOn, alreadyLocked: already,
                  payNoteLanded: noteLanded && (data["has_pay_note"]?.bool ?? true))
  }

  // MARK: - D225 · the publish, on ONE tap

  public struct Published: Sendable, Equatable {
    public let leagueId: UUID
    public let code: String
    public let name: String
    public let locked: Locked
    /// How many `invite_golfer` calls landed. Each is a COVENANT, not a seat —
    /// `add_friend_to_league` inserts the `league_members` row directly, with no
    /// invite, no acceptance and no covenant, which at a stake above $0 seats a
    /// golfer on a pot he never agreed to (L-12, CORE_FLOWS §0 A-1).
    public let invited: Int
    /// The invites that did NOT land. Named on the share screen rather than
    /// swallowed — a golfer who thinks he invited four and invited two is the
    /// defect this field exists to prevent.
    public let notInvited: Int
  }

  /// A season is minted at the START tap, never on a typed name: prod holds six
  /// founder-alone `setup` leagues because "Start the league" minted on a name
  /// (`WizardScreen.swift:70-86` → `:252-268`), so an abandoned wizard left a
  /// husk behind. Nothing here writes anything until every question is answered.
  ///
  /// L-41 wants formation to be ONE transaction. `create_league` and
  /// `lock_league` are two calls, and folding the first into the second changes
  /// a signature every build in the field calls — so the ONE half-state that
  /// survives is named on screen and `lock_league` is idempotent on `locked_at`,
  /// which is what makes the retry safe.
  public func publish(dials: WizardDials, today: String = CSDate.today(), resuming: Created? = nil,
                      request: UUID = UUID(),
                      didCreate: @Sendable (Created) async -> Void = { _ in }) async throws -> Published {
    let result = try await Self.publish(dials: dials, resuming: resuming, didCreate: didCreate,
      create: { try await createLeague(name: $0, request: request) },
      lock: { try await lock(leagueId: $0.leagueId, dials: dials, fallbackName: $0.name, today: today) },
      invite: { league, profile in
        _ = try await svc.call(InviteGolferCall(p_league: league, p_event: nil, p_profile: profile))
      })
    track(.invite_open, ["sent": .number(Double(result.invited))])
    return result
  }

  /// The same orchestration is exercised with in-memory transport failures in tests.
  static func publish(dials: WizardDials, resuming: Created?,
                      didCreate: @Sendable (Created) async -> Void,
                      create: @Sendable (String) async throws -> Created,
                      lock: @Sendable (Created) async throws -> Locked,
                      invite: @Sendable (UUID, UUID) async throws -> Void) async throws -> Published {
    let name = dials.name.trimmingCharacters(in: .whitespacesAndNewlines)
    let created: Created
    if let resuming { created = resuming } else {
      created = try await create(name)
      await didCreate(created)
    }
    let locked: Locked
    do {
      locked = try await lock(created)
    } catch {
      throw RpcError(name: WizardLockCall.name,
                     underlying: WizardCopy.publishFailedHalf + " (" + HumanError.text(error) + ")",
                     droppedArgs: [])
    }
    var ok = 0, bad = 0
    for pid in dials.invitees {
      do { try await invite(created.leagueId, pid); ok += 1 }
      catch { bad += 1 }
    }
    return Published(leagueId: created.leagueId, code: created.code, name: created.name,
                     locked: locked, invited: ok, notInvited: bad)
  }

  // MARK: discard (`wizCancel`)

  public func deleteLeague(_ id: UUID) async throws {
    _ = try await svc.call(Rpc.delete_league(p_league: id))
  }
}

/// D355 · the durable create record: one request id per season being started,
/// the dials it was started with, and the league once the server has said so.
/// Owner-scoped, written BEFORE `create_league_once` is called, updated when
/// the create answers, and cleared only when the season has actually STARTED
/// (the lock landed) or the Pro discarded it. A wizard killed anywhere in
/// between comes back with the same id — so the replay returns the same
/// league — and the same choices, including an explicit Unlimited, an
/// off-ladder exact cap and a chosen squad count.
public struct PendingCreate: Codable, Sendable, Equatable {
  public static let key = "cs_create_request"
  public var request: UUID
  public var dials: WizardDials
  public var squadsChosen: Bool?
  public var created: WizardService.Created?
  public var at: Date

  public init(request: UUID, dials: WizardDials, squadsChosen: Bool?, created: WizardService.Created? = nil, at: Date = Date()) {
    self.request = request; self.dials = dials; self.squadsChosen = squadsChosen; self.created = created; self.at = at
  }

  static func name(_ owner: UUID) -> String { key + "." + owner.uuidString }

  public static func read(owner: UUID, defaults: UserDefaults = .standard) -> PendingCreate? {
    guard let data = defaults.data(forKey: name(owner)) else { return nil }
    return try? JSONDecoder().decode(PendingCreate.self, from: data)
  }
  /// Throws when the record cannot be written: a create that cannot be
  /// remembered must not be sent, or a kill mid-flight mints a second league.
  public static func write(_ p: PendingCreate, owner: UUID, defaults: UserDefaults = .standard) throws {
    defaults.set(try JSONEncoder().encode(p), forKey: name(owner))
  }
  public static func clear(owner: UUID, defaults: UserDefaults = .standard) {
    defaults.removeObject(forKey: name(owner))
  }
  public static let resumedToast = "Your unfinished season came back — review it and start."
}
