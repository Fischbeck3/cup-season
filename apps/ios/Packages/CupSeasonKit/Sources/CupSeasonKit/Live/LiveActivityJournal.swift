import Foundation

extension LiveDisk {
  /// A single atomic file owns BOTH the changed card and its pending RPC write.
  /// If the process dies while copying into the existing snapshot/queue files,
  /// the next read recovers this journal. No score acknowledgement can outrun it.
  struct ActivityJournal: Codable {
    var state: LiveRoundState
    var pending: [LiveMessage]
  }
  func activityURL(_ id: UUID) -> URL { dir.appendingPathComponent("activity-\(id.uuidString.lowercased()).json") }
  func activityJournal(_ id: UUID) -> ActivityJournal? {
    try? JSONDecoder().decode(ActivityJournal.self, from: Data(contentsOf: activityURL(id)))
  }
  func rawSnapshot(_ id: UUID) -> LiveRoundState? {
    try? JSONDecoder().decode(LiveRoundState.self, from: Data(contentsOf: snapshotURL(id)))
  }
  func rawQueue(_ id: UUID) -> [LiveMessage] {
    (try? JSONDecoder().decode([LiveMessage].self, from: Data(contentsOf: queueURL(id)))) ?? []
  }
  static func union(_ a: [LiveMessage], _ b: [LiveMessage]) -> [LiveMessage] {
    var out = a
    for message in b where !out.contains(where: { $0.t == message.t && $0.pid == message.pid && $0.h == message.h && $0.cts == message.cts }) { out.append(message) }
    return Array(out.suffix(queueCap))
  }
  /// A delayed app snapshot may arrive after an intent. Preserve newer clocks
  /// and cursor, rather than letting async disk scheduling undo the tap.
  static func merging(_ incoming: LiveRoundState, with old: LiveRoundState?) -> LiveRoundState {
    guard let old, old.lr == incoming.lr, old.players == incoming.players,
          old.scores.count == incoming.scores.count else { return incoming }
    var result = incoming.ts >= old.ts ? incoming : old
    result.ensureClocks()
    for pi in result.scores.indices {
      for h in result.scores[pi].indices {
        let a = incoming.scts.indices.contains(pi) && incoming.scts[pi].indices.contains(h) ? incoming.scts[pi][h] : 0
        let b = old.scts.indices.contains(pi) && old.scts[pi].indices.contains(h) ? old.scts[pi][h] : 0
        if a != b, result.scts[pi].indices.contains(h) {
          let newer = a > b ? incoming : old
          guard newer.scores[pi].indices.contains(h) else { continue }
          result.scores[pi][h] = newer.scores[pi][h]; result.scts[pi][h] = max(a, b)
        }
      }
    }
    for h in result.wolf.indices where incoming.wcts.indices.contains(h) && old.wcts.indices.contains(h) {
      if incoming.wcts[h] != old.wcts[h] {
        let newer = incoming.wcts[h] > old.wcts[h] ? incoming : old
        result.wolf[h] = newer.wolf[h]; result.wcts[h] = max(incoming.wcts[h], old.wcts[h])
      }
    }
    return result
  }
  public func commitActivity(_ state: LiveRoundState, message: LiveMessage?) throws {
    guard state.active, let id = state.lr else { throw LiveIsland.Failure.unavailable }
    let prior = activityJournal(id)
    let latest = Self.merging(state, with: Self.merging(prior?.state ?? state, with: rawSnapshot(id)))
    let journal = ActivityJournal(state: latest, pending: Self.union(prior?.pending ?? [], message.map { [$0] } ?? []))
    try JSONEncoder().encode(journal).write(to: activityURL(id), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    // The acknowledgement is the journal write. Recovery can wait for the next
    // read if a second write fails; the only durable copy is never discarded.
    try? recoverActivity(id)
  }
  func recoverActivity(_ id: UUID) throws {
    guard let journal = activityJournal(id) else { return }
    let pending = Self.union(rawQueue(id), journal.pending)
    try JSONEncoder().encode(pending).write(to: queueURL(id), options: .atomic)
    let state = Self.merging(journal.state, with: rawSnapshot(id))
    try JSONEncoder().encode(state).write(to: snapshotURL(id), options: .atomic)
    try FileManager.default.removeItem(at: activityURL(id))
  }
}
