// Cup Season — D85 · everyone's phone scores the round: the transport
// (`liveSync`, index.html 14727–14835).
//
// Broadcast on `live-<round>-<code>` on the DEDICATED realtime client (never
// the busy one — CLAUDE.md's CHANNEL_ERROR landmine) + a durable queue on disk
// flushed through the RPCs. Guests ride the SAME transport with the anon key:
// broadcast needs no table read, and the writes re-auth per call via the claim
// token. The channel is a rumor mill; the DB stays the record — every edit that
// arrives is applied only if newer (LWW per cell), and `reconcile` pulls truth
// on subscribe and on every return to the foreground.

import Foundation
import Supabase

public actor LiveRoundSession {
  public enum Event: Sendable {
    /// a broadcast edit (score / wolf), or a finish / gone from another phone
    case message(LiveMessage)
    /// the reconcile pull — the whole round, to merge cell by cell
    case state(JSONValue)
    /// who is on the sheet (presence names)
    case presence([String])
    /// the queue depth changed
    case queued(Int)
    /// the channel's subscribe status — a breadcrumb; silence cost a full session
    case status(String)
  }

  public nonisolated let events: AsyncStream<Event>
  private let cont: AsyncStream<Event>.Continuation

  private let svc: SupabaseService
  private let disk: LiveDisk
  private let repo: LiveRepository

  private var channel: RealtimeChannelV2?
  private var tokens: [RealtimeSubscription] = []
  private var lr: UUID?
  private var code: String?
  private var guest: UUID?
  private var flushing = false
  private var present: [String: String] = [:]
  public private(set) var subStatus: String?
  /// Drop a write after this many failed tries — a poisoned write must not dam the queue (14815).
  public static let maxTries = 40

  public init(svc: SupabaseService = .shared, disk: LiveDisk = .shared) {
    self.svc = svc; self.disk = disk; repo = LiveRepository(svc)
    var c: AsyncStream<Event>.Continuation!
    events = AsyncStream(bufferingPolicy: .unbounded) { c = $0 }
    cont = c
  }

  public var isJoined: Bool { channel != nil }
  public var currentRound: UUID? { lr }

  public func queued() async -> Int {
    guard let lr else { return 0 }
    return await disk.queue(lr).count
  }

  /// `join(lr, code, guestTok)`.
  public func join(lr: UUID, code: String, guest guestToken: UUID?, name: String, presenceKey: String) async {
    if channel != nil, self.lr == lr { return }
    await leave()
    self.lr = lr; self.code = code; guest = guestToken
    let topic = "live-\(lr.uuidString.lowercased())-\(code)"
    let ch = svc.realtime.realtimeV2.channel(topic) { cfg in
      cfg.broadcast = BroadcastJoinConfig(acknowledgeBroadcasts: false, receiveOwnBroadcasts: false)
      cfg.presence = PresenceJoinConfig(key: presenceKey)
    }
    channel = ch
    tokens.append(ch.onBroadcast(event: "live") { [weak self] json in
      guard let self else { return }
      let payload = json["payload"].flatMap(LiveRoundSession.jsonValue) ?? .null
      Task { await self.receive(payload) }
    })
    tokens.append(ch.onPresenceChange { [weak self] action in
      guard let self else { return }
      let joins = action.joins.compactMapValues { $0.state["n"]?.stringValue }
      let leaves = Array(action.leaves.keys)
      Task { await self.presence(joins: joins, leaves: leaves) }
    })
    tokens.append(ch.onStatusChange { [weak self] s in
      guard let self else { return }
      let name: String = switch s {
      case .subscribed: "SUBSCRIBED"
      case .subscribing: "SUBSCRIBING"
      case .unsubscribing: "UNSUBSCRIBING"
      case .unsubscribed: "CLOSED"
      }
      Task { await self.status(name) }
    })
    do {
      try await ch.subscribeWithError()
      await ch.track(state: ["n": .string(name)])
      await status("SUBSCRIBED")
      await flush()
      await reconcile()
    } catch {
      print("[livesync] \(topic) CHANNEL_ERROR — \(error.localizedDescription)")
      await status("CHANNEL_ERROR")
    }
  }

  private func status(_ s: String) {
    print("[livesync] \(s)")
    subStatus = s
    cont.yield(.status(s))
  }

  public func leave() async {
    tokens.forEach { $0.cancel() }
    tokens.removeAll()
    if let ch = channel {
      await ch.untrack()
      await svc.realtime.realtimeV2.removeChannel(ch)
    }
    channel = nil; lr = nil; code = nil; guest = nil; subStatus = nil
    present = [:]
    cont.yield(.presence([]))
  }

  private func receive(_ payload: JSONValue) {
    guard let m = LiveMessage(wire: payload) else { return }
    cont.yield(.message(m))
  }

  private func presence(joins: [String: String], leaves: [String]) {
    for k in leaves { present[k] = nil }
    for (k, n) in joins { present[k] = n }
    cont.yield(.presence(Array(present.values)))
  }

  /// Broadcast now; queue the durable write unless `broadcastOnly` (finish /
  /// gone — the RPC that matters already ran or is about to).
  public func send(_ m: LiveMessage, broadcastOnly: Bool = false) async {
    if let ch = channel { try? await ch.broadcast(event: "live", message: m.wire) }
    guard !broadcastOnly, let lr else { return }
    var q = await disk.queue(lr)
    q.append(m)
    await disk.saveQueue(lr, q)
    cont.yield(.queued(min(q.count, LiveDisk.queueCap)))
    await flush()
  }

  /// Drain the queue in order. A permanently un-landable write (the round
  /// closed, bad args, an old DB with no RPC yet) is dropped; a network miss
  /// keeps its entry, counts a try, and backs off until the next trigger.
  public func flush() async {
    guard !flushing, let lr else { return }
    flushing = true
    defer { flushing = false }
    var q = await disk.queue(lr)
    while let m = q.first {
      do {
        if m.t == "score", let pid = m.pid, let h = m.h {
          try await repo.setScore(lr: lr, player: pid, hole: h, strokes: m.s, cts: m.cts, guest: guest)
        } else if m.t == "wolf", let h = m.h {
          try await repo.setWolf(lr: lr, hole: h, pick: m.w ?? .null, cts: m.cts, guest: guest)
        }
        q.removeFirst()
        await disk.saveQueue(lr, q)
      } catch {
        let msg = (error as? RpcError)?.underlying ?? error.localizedDescription
        if LiveRoundSession.isDeadWrite(msg) {
          q.removeFirst()
          await disk.saveQueue(lr, q)
          continue
        }
        q[0].tries = (m.tries ?? 0) + 1
        if q[0].tries! > LiveRoundSession.maxTries { q.removeFirst() }
        await disk.saveQueue(lr, q)
        break
      }
    }
    cont.yield(.queued(q.count))
  }

  /// `/not live|final|No such|not in this|function|schema cache/i` (14812).
  public static func isDeadWrite(_ message: String) -> Bool {
    message.range(of: "not live|final|No such|not in this|function|schema cache", options: [.regularExpression, .caseInsensitive]) != nil
  }

  /// The reconcile pull — `live_state` / `guest_live_state`.
  public func reconcile() async {
    guard let lr else { return }
    do {
      let d = guest != nil ? try await repo.guestState(guest!) : try await repo.state(lr)
      cont.yield(.state(d))
    } catch {
      print("[livesync] reconcile \(error.localizedDescription)")
    }
  }

  /// D86 · tee-off's doorbell: one broadcast on the LEAGUE channel, which
  /// every open app in the league already subscribes to. Fire-and-forget.
  public func announceOpen(league: UUID, lr: UUID) async {
    let ch = svc.realtime.realtimeV2.channel("lg-" + league.uuidString)
    try? await ch.httpSend(event: "live_open", message: ["lr": .string(lr.uuidString.lowercased())])
  }

  /// The round id inside a `live_open` broadcast (`LeagueRealtime.onLiveOpen`
  /// hands the raw message; the web sends `payload:{lr}`).
  public nonisolated static func liveOpenId(_ payload: JSONObject) -> UUID? {
    let s = payload["payload"]?.objectValue?["lr"]?.stringValue ?? payload["lr"]?.stringValue
    return s.flatMap(UUID.init)
  }

  /// AnyJSON → the kit's JSONValue, through the wire form.
  static func jsonValue(_ a: AnyJSON) -> JSONValue? {
    guard let data = try? JSONEncoder().encode(a) else { return nil }
    return try? JSONDecoder().decode(JSONValue.self, from: data)
  }
}
