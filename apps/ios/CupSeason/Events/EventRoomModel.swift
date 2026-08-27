// Cup Season — one event room's state: the loaded `EventRoom`, the busy
// keys, and C10's session memory (the number-to-beat chip that CHANGED
// between loads arcs in; first paint never animates).

import Foundation
import Observation
import CupSeasonKit

@MainActor
@Observable
final class EventRoomModel {
  let eventId: UUID
  private let repo = EventsRepository()
  var room: EventRoom?
  var loaded = false
  var error: String?
  var busy = Set<String>()
  /// Duel ids whose chip changed since the last load — the taunt landed.
  var risen = Set<UUID>()
  private var pvSeen: [UUID: String] = [:]
  /// #15: team names + the event name are proper nouns the all-caps engine
  /// posts would otherwise half-shout — learned so `easeCaps` restores them.
  var names = BoardText.NameRegistry()

  init(eventId: UUID) { self.eventId = eventId }

  func load() async {
    do {
      let r = try await repo.load(eventId)
      var rises = Set<UUID>()
      var seen: [UUID: String] = [:]
      for d in r.duels {
        let open = r.sessions.first { $0.id == d.session_id }?.isOpen ?? false
        let chip = RyderMath.chip(d, sessionOpen: open, target: r.targets[d.id],
                                  aName: r.player(d.a_player).name, bName: r.player(d.b_player).name).text ?? ""
        if !chip.isEmpty, let prev = pvSeen[d.id], prev != chip { rises.insert(d.id) }
        seen[d.id] = chip
      }
      pvSeen = seen
      risen = rises
      names.learn(r.teams.map(\.name) + [r.event.name])
      room = r
      error = nil
    } catch {
      if room == nil { self.error = BoardText.humanError(error) }
    }
    loaded = true
  }

  func isBusy(_ key: String) -> Bool { busy.contains(key) }

  /// Run one organizer/player hand, then re-read the room.
  func run(_ key: String, reload: Bool = true, _ op: @MainActor () async throws -> Void) async throws {
    busy.insert(key)
    defer { busy.remove(key) }
    try await op()
    if reload { await load() }
  }

  // MARK: the hands (each a security-definer RPC; the engine re-validates)

  func assign(player: UUID, team: UUID) async throws { try await run("assign-\(player)") { try await repo.setTeam(player: player, team: team) } }
  func pair(session: UUID) async throws -> Int {
    var n = 0
    try await run("pair-\(session)") { n = try await repo.pair(session: session) }
    return n
  }
  func resolve(session: UUID) async throws { try await run("resolve-\(session)") { try await repo.resolve(session: session) } }
  func notify(on: Bool) async throws { try await run("notify") { try await repo.notify(event: eventId, on: on) } }
  func scrap() async throws { try await run("scrap", reload: false) { try await repo.scrap(event: eventId) } }
  func enter() async throws { try await run("enter") { try await repo.enter(major: eventId) } }
  func openWindow(session: UUID) async throws { try await run("open") { try await repo.openWindow(session: session) } }
  func settle(session: UUID) async throws { try await run("settle") { try await repo.settle(session: session) } }
}
