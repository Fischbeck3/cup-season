// Cup Season — the league channel (`subscribeLeague`, index.html 14684–14722).
//
// ONE channel `lg-<leagueId>` per open league, torn down on switch, on the
// DEDICATED realtime client only. The landmine (CLAUDE.md): channel joins on
// the busy auth+data client fail with CHANNEL_ERROR / transport failure —
// verified with a raw socket and a fresh client on the same token. The token
// is forwarded to this client by SessionStore on every auth change.
//
//   postgres_changes INSERT on public.posts, filter league_id=eq.<id>  → onPostInsert
//   postgres_changes *      on post_kudos / post_comments               → onSocialChange, debounced 250 ms
//   broadcast        live_open (D86 doorbell)                           → onLiveOpen — a nudge, never trusted
//
// Subscribe status is logged as a breadcrumb; silence cost a full session.

import Foundation
import Supabase

@MainActor
public final class LeagueRealtime {
  public private(set) var leagueId: UUID?
  public private(set) var status: String = "idle"

  /// Fires with the inserted `posts` row when the payload carries one.
  public var onPostInsert: (@MainActor (JSONObject?) -> Void)?
  /// Fires once per 250 ms burst of reaction/comment traffic.
  public var onSocialChange: (@MainActor () -> Void)?
  /// The `live_open` broadcast payload. Consumers re-read the roster themselves.
  public var onLiveOpen: (@MainActor (JSONObject) -> Void)?
  /// Breadcrumb sink (the web's `bootTrace`). Defaults to `print`.
  public var log: @Sendable (String) -> Void = { print("[realtime] \($0)") }

  private let svc: SupabaseService
  private var channel: RealtimeChannelV2?
  private var tokens: [RealtimeSubscription] = []
  private var socialDebounce: Task<Void, Never>?

  public init(svc: SupabaseService = .shared) { self.svc = svc }

  /// Join the league's channel. Tears down any previous one first.
  public func start(leagueId: UUID) async {
    await stop()
    self.leagueId = leagueId
    let topic = "lg-" + leagueId.uuidString
    let ch = svc.realtime.realtimeV2.channel(topic)
    channel = ch
    let log = self.log

    tokens.append(ch.onPostgresChange(InsertAction.self, schema: "public", table: "posts",
                                      filter: .eq("league_id", value: leagueId.uuidString)) { [weak self] action in
      let record = action.record
      Task { @MainActor [weak self] in self?.onPostInsert?(record) }
    })
    for table in ["post_kudos", "post_comments"] {
      tokens.append(ch.onPostgresChange(AnyAction.self, schema: "public", table: table) { [weak self] _ in
        Task { @MainActor [weak self] in self?.nudgeSocial() }
      })
    }
    tokens.append(ch.onBroadcast(event: "live_open") { [weak self] payload in
      Task { @MainActor [weak self] in self?.onLiveOpen?(payload) }
    })
    tokens.append(ch.onStatusChange { [weak self] s in
      let name: String = switch s {
      case .subscribed: "SUBSCRIBED"
      case .subscribing: "SUBSCRIBING"
      case .unsubscribing: "UNSUBSCRIBING"
      case .unsubscribed: "CLOSED"
      }
      log("\(topic) \(name)")
      Task { @MainActor [weak self] in self?.status = name }
    })
    do {
      try await ch.subscribeWithError()
    } catch {
      // keep failures loud in the breadcrumbs — silence cost a full session
      let msg = "\(topic) CHANNEL_ERROR — \(error.localizedDescription)"
      log(msg)
      status = "CHANNEL_ERROR"
    }
  }

  private func nudgeSocial() {
    socialDebounce?.cancel()
    socialDebounce = Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(250))
      guard !Task.isCancelled else { return }
      self?.onSocialChange?()
    }
  }

  /// Leave the channel and drop every callback.
  public func stop() async {
    socialDebounce?.cancel()
    tokens.forEach { $0.cancel() }
    tokens.removeAll()
    if let ch = channel {
      await svc.realtime.realtimeV2.removeChannel(ch)
      channel = nil
      status = "CLOSED"
    }
    leagueId = nil
  }
}
