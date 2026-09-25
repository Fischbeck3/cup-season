import Foundation
import CupSeasonKit

extension LiveRoundStore {
  /// The intent uses the app's one store. A cold process recovers only the
  /// exact owned round; it never runs general discovery or replaces another round.
  func recoverActivityRound(round: UUID, owner: UUID,
                            currentOwner: @MainActor () async -> UUID?) async throws {
    guard await currentOwner() == owner else { throw LiveIsland.Failure.signIn }
    if !state.active {
      let local = try offlineActivityRound(owner: owner, id: round)
      let saved = await disk.snapshot(round)
      let abandoned = await disk.pendingAbandons()
      guard await currentOwner() == owner, !state.active else { throw LiveIsland.Failure.unavailable }
      guard let recovered = local ?? LiveRehydrator.savedRound(saved.map { [$0] } ?? [], owner: owner, abandoned: Set(abandoned)),
            recovered.lr == round else { throw LiveIsland.Failure.unavailable }
      adoptActivityRound(recovered, owner: owner)
    }
    guard !busy, !retiredCard, guest == nil, state.lr == round,
          state.active, state.stage == .live, let me = state.meIndex,
          state.players[me].pid == owner, await currentOwner() == owner else { throw LiveIsland.Failure.unavailable }
  }

  func openActivityRound(_ destination: LiveActivityRoute.Destination,
                         currentOwner: @MainActor () async -> UUID?, sync: Bool = true) async throws {
    try await recoverActivityRound(round: destination.round, owner: destination.owner, currentOwner: currentOwner)
    if !state.onThisPhone, let code = state.code {
      await session.prepareSavedRound(destination.round, code: code)
      guard state.lr == destination.round, await currentOwner() == destination.owner else { throw LiveIsland.Failure.signIn }
      if sync { Task { await joinSync() } }
    }
    if destination.review { reviewRequested = destination.round }
  }

  func activityAction(_ action: LiveIsland.Action, round: UUID, owner: UUID, hole: Int,
                      currentOwner: @MainActor () async -> UUID?, sync: Bool = true) async throws {
    try await recoverActivityRound(round: round, owner: owner, currentOwner: currentOwner)
    let before = state
    let (changed, message) = try LiveIsland.applying(action, round: round, owner: owner, hole: hole, to: before)
    guard changed != before else { return }
    // Publish in memory before suspension; later in-app edits build on this
    // state. Disk merges clocks, and no post-await assignment replaces it.
    state = changed
    do {
      if changed.onThisPhone { try saveActivityLocal(changed) }
      else { try await disk.commitActivity(changed, message: message) }
    } catch {
      if state == changed { state = before }
      if state.lr == round, await currentOwner() == owner {
        await LiveActivityHost.update(state, saveState: "Couldn’t save · open round")?.value
      }
      throw LiveIsland.Failure.storage
    }
    guard state.lr == round, await currentOwner() == owner else { throw LiveIsland.Failure.signIn }
    queued = changed.onThisPhone ? 0 : await disk.queue(round).count
    await LiveActivityHost.update(state, saveState: changed.onThisPhone || queued > 0 ? "Saved on phone" : nil)?.value
    if sync { await syncActivity(round: round, owner: owner, currentOwner: currentOwner) }
  }

  func syncActivity(round: UUID, owner: UUID, currentOwner: @MainActor () async -> UUID?) async {
    guard state.active, state.lr == round, !state.onThisPhone, !retiredCard,
          let code = state.code, await currentOwner() == owner else { return }
    await session.prepareSavedRound(round, code: code)
    guard state.lr == round, await currentOwner() == owner else { return }
    // Already persisted by commitActivity; do not enqueue a duplicate. The
    // existing RPC flush handles network failure and terminal round statuses.
    await session.flush()
    guard state.lr == round, !retiredCard, await currentOwner() == owner else { return }
    queued = await session.queued()
    await LiveActivityHost.update(state, saveState: queued > 0 ? "Saved on phone" : nil)?.value
    if queued == 0 { await session.reconcile() }
  }
}

/// App Intents can arrive together. Serialize them, while reading the live
/// score at execution time so two plus taps remain two changes.
@MainActor enum LiveActivityActions {
  private static var pending: Task<Void, Never>?
  static func run(_ action: LiveIsland.Action, round: UUID, owner: UUID, hole: Int) async throws {
    let defaults = UserDefaults(suiteName: CSAppGroup.id)
    let epoch = defaults?.string(forKey: BetweenRoundsSnapshot.epochKey)
    let svc = SupabaseService.shared
    let authenticated = await svc.currentSession() ?? svc.client.auth.currentSession
    guard authenticated?.user.id == owner else { throw LiveIsland.Failure.signIn }
    let currentOwner: @MainActor () async -> UUID? = {
      guard let id = svc.client.auth.currentSession?.user.id,
            defaults?.string(forKey: BetweenRoundsSnapshot.epochKey) == epoch,
            DispatchSnapshot.belongs(to: id, defaults: defaults) else { return nil }
      return id
    }
    let previous = pending
    let task = Task { @MainActor in
      await previous?.value
      try await LiveRoundStore.shared.activityAction(action, round: round, owner: owner, hole: hole,
        currentOwner: currentOwner, sync: false)
    }
    pending = Task { _ = try? await task.value }
    try await task.value
    // Only durable local edits serialize. A slow connection must not hold the
    // next + tap behind a network timeout. The shared session owns one flush.
    await LiveRoundStore.shared.syncActivity(round: round, owner: owner, currentOwner: currentOwner)
  }
}
