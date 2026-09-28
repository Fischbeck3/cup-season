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
    /// the round can no longer be written to, and its card has been KEPT on
    /// disk rather than deleted. The host stops pretending it is live.
    case retired(UUID)
  }

  public nonisolated let events: AsyncStream<Event>
  private let cont: AsyncStream<Event>.Continuation

  private let svc: SupabaseService?
  private let disk: LiveDisk
  private let delivery: any LiveDelivery
  private let authorizationEpoch: @Sendable () -> String?

  /// Capture before an authorized action suspends. A queued action cannot
  /// silently adopt the credentials of a later sign-in, even for the same owner.
  public struct Authorization: Sendable { fileprivate let epoch: String? }
  public nonisolated func captureAuthorization() -> Authorization {
    Authorization(epoch: authorizationEpoch())
  }

  struct Binding: Equatable, Sendable {
    let round: UUID
    let code: String
    let guest: UUID?
    let generation: UUID
    let epoch: String?
  }
  private var binding: Binding?
  private var channel: RealtimeChannelV2?
  private var tokens: [RealtimeSubscription] = []
  private var flushing: UUID?
  private var submittedCard: LiveRoundState?
  private var present: [String: String] = [:]
  public private(set) var subStatus: String?
  /// Drop a write after this many failed tries — a poisoned write must not dam the queue (14815).
  public static let maxTries = 40

  public init(svc: SupabaseService = .shared, disk: LiveDisk = .shared) {
    self.svc = svc; self.disk = disk
    delivery = LiveRPCDelivery(repo: LiveRepository(svc))
    authorizationEpoch = { UserDefaults(suiteName: CSAppGroup.id)?.string(forKey: BetweenRoundsSnapshot.epochKey) }
    let stream = AsyncStream<Event>.makeStream(bufferingPolicy: .unbounded)
    events = stream.stream; cont = stream.continuation
  }

  /// Tests exercise delivery through the real session without auth or a socket.
  init(disk: LiveDisk, delivery: any LiveDelivery,
       authorizationEpoch: @escaping @Sendable () -> String? = { nil }) {
    svc = nil; self.disk = disk; self.delivery = delivery; self.authorizationEpoch = authorizationEpoch
    let stream = AsyncStream<Event>.makeStream(bufferingPolicy: .unbounded)
    events = stream.stream; cont = stream.continuation
  }

  private func isCurrent(_ value: Binding) -> Bool {
    binding == value && authorizationEpoch() == value.epoch
  }
  public var isJoined: Bool { channel != nil && binding.map(isCurrent) == true }
  public var currentRound: UUID? { binding.flatMap { isCurrent($0) ? $0.round : nil } }

  public func queued() async -> Int {
    guard let value = binding, isCurrent(value) else { return 0 }
    let count = await disk.queue(value.round).count
    return isCurrent(value) ? count : 0
  }

  /// Bind before the first suspension. Disposing an old socket cannot erase a
  /// newer binding, even when the same round is reopened under a new account epoch.
  @discardableResult
  func bind(round: UUID, code: String, guest: UUID?) async -> Binding? {
    let previous = detach()
    let value = Binding(round: round, code: code, guest: guest, generation: UUID(), epoch: authorizationEpoch())
    binding = value
    await disconnect(previous)
    return isCurrent(value) ? value : nil
  }

  private func savedBinding(_ round: UUID, code: String) async -> Binding? {
    if let value = binding, isCurrent(value), value.round == round, value.code == code, value.guest == nil { return value }
    return await bind(round: round, code: code, guest: nil)
  }

  /// Bind disk writes before opening the offline card. No network required.
  public func prepareSavedRound(_ round: UUID, code: String) async {
    guard let value = await savedBinding(round, code: code) else { return }
    await publishQueued(value)
  }

  /// `join(lr, code, guestTok)`; production keeps the dedicated Realtime client.
  public func join(lr: UUID, code: String, guest guestToken: UUID?, name: String, presenceKey: String) async {
    if channel != nil, let value = binding, isCurrent(value), value.round == lr,
       value.code == code, value.guest == guestToken { return }
    guard let svc, let value = await bind(round: lr, code: code, guest: guestToken) else { return }
    let topic = "live-\(lr.uuidString.lowercased())-\(code)"
    let ch = svc.realtime.realtimeV2.channel(topic) { cfg in
      cfg.broadcast = BroadcastJoinConfig(acknowledgeBroadcasts: false, receiveOwnBroadcasts: false)
      cfg.presence = PresenceJoinConfig(key: presenceKey)
    }
    channel = ch
    tokens.append(ch.onBroadcast(event: "live") { [weak self] json in
      guard let self else { return }
      let payload = json["payload"].flatMap(LiveRoundSession.jsonValue) ?? .null
      Task { await self.receive(payload, in: value) }
    })
    tokens.append(ch.onPresenceChange { [weak self] action in
      guard let self else { return }
      let joins = action.joins.compactMapValues { $0.state["n"]?.stringValue }
      let leaves = Array(action.leaves.keys)
      Task { await self.presence(joins: joins, leaves: leaves, in: value) }
    })
    tokens.append(ch.onStatusChange { [weak self] s in
      guard let self else { return }
      let name: String = switch s {
      case .subscribed: "SUBSCRIBED"
      case .subscribing: "SUBSCRIBING"
      case .unsubscribing: "UNSUBSCRIBING"
      case .unsubscribed: "CLOSED"
      }
      Task { await self.status(name, in: value) }
    })
    do {
      try await ch.subscribeWithError()
      guard isCurrent(value) else { return }
      await ch.track(state: ["n": .string(name)])
      guard isCurrent(value) else { return }
      status("SUBSCRIBED", in: value)
      _ = await synchronize(value, onlyWhenEmpty: false)
    } catch {
      guard isCurrent(value) else { return }
      print("[livesync] \(topic) CHANNEL_ERROR — \(error.localizedDescription)")
      status("CHANNEL_ERROR", in: value)
    }
  }

  private func status(_ s: String, in value: Binding) {
    guard isCurrent(value) else { return }
    print("[livesync] \(s)")
    subStatus = s
    cont.yield(.status(s))
  }

  private func detach() -> RealtimeChannelV2? {
    let previous = channel
    tokens.forEach { $0.cancel() }; tokens.removeAll()
    channel = nil; binding = nil; submittedCard = nil; subStatus = nil
    present = [:]
    cont.yield(.presence([]))
    return previous
  }
  private func disconnect(_ previous: RealtimeChannelV2?) async {
    guard let previous, let svc else { return }
    await previous.untrack()
    await svc.realtime.realtimeV2.removeChannel(previous)
  }
  public func leave() async { await disconnect(detach()) }

  private func receive(_ payload: JSONValue, in value: Binding) {
    guard isCurrent(value), let m = LiveMessage(wire: payload) else { return }
    cont.yield(.message(m))
  }
  private func presence(joins: [String: String], leaves: [String], in value: Binding) {
    guard isCurrent(value) else { return }
    for k in leaves { present[k] = nil }
    for (k, n) in joins { present[k] = n }
    cont.yield(.presence(Array(present.values)))
  }

  /// App edits stay optimistic. Snapshot preservation and delivery now travel
  /// together; guest cards are retained in memory only, never normal snapshots.
  public func submit(_ card: LiveRoundState, message: LiveMessage, guest: UUID?) async {
    guard card.active, let round = card.lr else { return }
    let value = binding
    if let value, isCurrent(value), value.round == round, value.guest == guest {
      submittedCard = LiveDisk.merging(card, with: submittedCard)
    }
    // An edit before the channel is bound still keeps its host snapshot, as
    // persistLive always did. The explicit round prevents cross-round delivery.
    if guest == nil { await disk.save(card) }
    guard let value, isCurrent(value), value.round == round, value.guest == guest else { return }
    await transmit(message, in: value, broadcastOnly: false)
  }

  public func send(_ message: LiveMessage, round: UUID, broadcastOnly: Bool = false) async {
    guard let value = binding, isCurrent(value), value.round == round else { return }
    await transmit(message, in: value, broadcastOnly: broadcastOnly)
  }
  private func transmit(_ message: LiveMessage, in value: Binding, broadcastOnly: Bool) async {
    guard isCurrent(value) else { return }
    if let ch = channel { try? await ch.broadcast(event: "live", message: message.wire) }
    guard !broadcastOnly, isCurrent(value) else { return }
    await disk.enqueue(message, round: value.round)
    guard isCurrent(value) else { return }
    await publishQueued(value)
    _ = await flush(value)
  }

  /// A flush belongs to one binding. A suspended old RPC cannot block a new
  /// round's flush, nor clear its ownership when the old request returns.
  public func flush() async {
    guard let value = binding, isCurrent(value) else { return }
    _ = await flush(value)
  }
  private struct FlushOutcome { var retired = false }
  private func flush(_ value: Binding) async -> FlushOutcome? {
    guard isCurrent(value), flushing != value.generation else { return nil }
    var outcome = FlushOutcome()
    flushing = value.generation
    defer { if flushing == value.generation { flushing = nil } }
    while isCurrent(value) {
      let next = await disk.queue(value.round).first
      guard isCurrent(value) else { return nil }
      guard let message = next else { break }
      do {
        try await delivery.write(message, round: value.round, guest: value.guest)
        guard isCurrent(value) else { return nil }
        guard await disk.acknowledge(message, round: value.round) else { break }
      } catch {
        guard isCurrent(value) else { return nil }
        let text = (error as? RpcError)?.underlying ?? error.localizedDescription
        if Self.isDeadWrite(text) {
          // Keep the card before dropping an un-landable stroke. Preserve the
          // existing fullest-card retirement policy and app-store fallback.
          let saved = await disk.snapshot(value.round)
          guard isCurrent(value) else { return nil }
          if let latest = submittedCard.map({ LiveDisk.merging($0, with: saved) }) ?? saved {
            await disk.retire(latest, lr: value.round)
          }
          guard isCurrent(value) else { return nil }
          outcome.retired = true
          cont.yield(.retired(value.round))
          guard await disk.acknowledge(message, round: value.round) else { break }
          continue
        }
        await disk.retry(message, round: value.round, limit: Self.maxTries)
        break
      }
    }
    await publishQueued(value)
    return isCurrent(value) ? outcome : nil
  }

  private func publishQueued(_ value: Binding) async {
    let count = await disk.queue(value.round).count
    guard isCurrent(value) else { return }
    cont.yield(.queued(count))
  }

  /// Reconnect/foreground keeps the existing unconditional reconcile policy.
  @discardableResult
  public func synchronize(round: UUID) async -> Int? {
    guard let value = binding, isCurrent(value), value.round == round else { return nil }
    return await synchronize(value, onlyWhenEmpty: false)
  }

  /// Activity edits are already in the atomic journal. This path never enqueues
  /// them again, and reconciles only once their queue has drained.
  @discardableResult
  public func syncSavedRound(_ round: UUID, code: String, authorization: Authorization) async -> Int? {
    guard authorization.epoch == authorizationEpoch(),
          let value = await savedBinding(round, code: code),
          value.epoch == authorization.epoch, isCurrent(value) else { return nil }
    return await synchronize(value, onlyWhenEmpty: true)
  }
  private func synchronize(_ value: Binding, onlyWhenEmpty: Bool) async -> Int? {
    guard let outcome = await flush(value), isCurrent(value) else { return nil }
    let count = await disk.queue(value.round).count
    guard isCurrent(value) else { return nil }
    if !onlyWhenEmpty || (count == 0 && !outcome.retired) { await reconcile(value) }
    return isCurrent(value) ? count : nil
  }

  /// `/not live|final|No such|not in this|function|schema cache/i` (14812).
  public static func isDeadWrite(_ message: String) -> Bool {
    message.range(of: "not live|final|No such|not in this|function|schema cache", options: [.regularExpression, .caseInsensitive]) != nil
  }

  public func reconcile() async {
    guard let value = binding, isCurrent(value) else { return }
    await reconcile(value)
  }
  private func reconcile(_ value: Binding) async {
    do {
      let state = try await delivery.read(round: value.round, guest: value.guest)
      guard isCurrent(value) else { return }
      cont.yield(.state(state))
    } catch {
      if isCurrent(value) { print("[livesync] reconcile \(error.localizedDescription)") }
    }
  }

  /// D86 · tee-off's doorbell: one broadcast on the LEAGUE channel, which
  /// every open app in the league already subscribes to. Fire-and-forget.
  public func announceOpen(league: UUID, lr: UUID) async {
    guard let svc else { return }
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
