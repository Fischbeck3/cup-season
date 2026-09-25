// Cup Season — D155 · starting, updating and (above all) ENDING the activity.
//
// An activity that outlives its round is worse than no activity: it is a lie on
// the lock screen that the app cannot be tapped out of. So every exit ends it —
// finish, scrap, abandon, backing out to setup — and `clearStale()` runs on
// rehydrate to sweep anything a crash or a force-quit left behind.
//
// LiveCopy supplies the hole; LiveIsland reads the existing match engines from
// the golfer's side. No second scoring calculation lives in the extension.
//
// Concurrency shape, deliberately: main-actor state holds only the activity's
// ID — a String — and the ActivityKit calls happen in `nonisolated` functions
// that look the handle up themselves. `Activity` and `ActivityContent` are not
// Sendable, so holding one on the main actor and awaiting its async methods is
// a strict-concurrency error; the ID crosses isolation safely, the handle never
// has to.

import ActivityKit
import Foundation
import CupSeasonKit

@MainActor
enum LiveActivityHost {

  private static var currentID: String?
  private static var updates: Task<Void, Never>?

  static func facts(_ s: LiveRoundState, saveState: String? = nil) -> (CSRoundActivity, CSRoundActivity.ContentState) {
    let f = LiveCopy.activity(s)
    let island = LiveIsland.facts(s)
    var state = CSRoundActivity.ContentState(hole: f.hole, par: f.par, thru: f.thru, holes: f.holes, game: f.game, compact: island.compact)
    state.opponent = island.opponent; state.result = island.result; state.detail = island.detail
    state.resultThrough = island.through; state.score = island.score
    state.canScore = island.canScore; state.saveState = saveState ?? (s.onThisPhone ? "Saved on phone" : nil)
    let owner = s.meIndex.flatMap { s.players[$0].pid }
    return (CSRoundActivity(course: f.course, round: s.lr, owner: owner), state)
  }

  /// D178 · how long a figure on the lock screen is allowed to claim it is
  /// current. Every update to this activity is main-actor app code, so a phone
  /// left in a pocket keeps asserting HOLE 4 / THRU 3 with full confidence
  /// until the app is reopened — and abandoning is the NORM, not the edge:
  /// prod `live_rounds` is 20 abandoned to 4 final, and nothing server-side
  /// reaps them (the four cron jobs never touch that table). Past this the
  /// system greys the card out, which is the honest rendering of "nobody has
  /// touched this in a while".
  ///
  /// 45 minutes is roughly three holes at a normal pace — long enough that a
  /// slow group never sees it, short enough that a forgotten round stops
  /// lying before the next one starts.
  private static let stale: TimeInterval = 45 * 60

  /// Tee-off. Idempotent: a second call on a running round updates instead of
  /// stacking a second island.
  static func start(_ s: LiveRoundState) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled, s.active, s.stage == .live else { return }
    let previousID = currentID
    currentID = matching(s)
    if let previousID, previousID != currentID {
      let previousUpdate = updates
      Task { await previousUpdate?.value; await Self.stop(id: previousID) }
    }
    guard currentID == nil else { update(s); return }
    let (attrs, state) = facts(s)
    do {
      // a denied or unavailable activity is not something the golfer needs to
      // hear about — the round is unaffected and Home still has its banner
      currentID = try Activity.request(attributes: attrs,
                                       content: .init(state: state, staleDate: Date().addingTimeInterval(stale)),
                                       pushType: nil).id
    } catch {
      currentID = nil
    }
  }

  @discardableResult static func update(_ s: LiveRoundState, saveState: String? = nil) -> Task<Void, Never>? {
    currentID = matching(s)
    guard let id = currentID else { return nil }
    guard s.active, s.stage == .live else { Task { await end() }; return nil }
    let state = facts(s, saveState: saveState).1
    let previous = updates
    let task = Task { await previous?.value; await Self.push(id: id, state: state) }
    updates = task
    return task
  }

  /// Finish, scrap, abandon, backing out to setup — all end it.
  static func end() async {
    guard let id = currentID else { return }
    currentID = nil
    let pending = updates; updates = nil
    await pending?.value
    await Self.stop(id: id)
  }

  /// A crash or a force-quit can leave one running with no round behind it.
  /// Swept on rehydrate, before anything can tap it.
  static func clearStale(keeping state: LiveRoundState? = nil) async {
    // New activities carry both identities, so a cold intent can keep exactly
    // its own activity. Legacy, mismatched and signed-out activities end.
    let keep = state.flatMap(matching)
    currentID = keep
    let pending = updates; updates = nil
    await pending?.value
    for id in await Self.ids() where id != keep { await Self.stop(id: id) }
  }

  private static func matching(_ s: LiveRoundState) -> String? {
    guard let round = s.lr, let me = s.meIndex else { return nil }
    let owner = s.players[me].pid
    return Activity<CSRoundActivity>.activities.first { $0.attributes.round == round && $0.attributes.owner == owner }?.id
  }

  // MARK: the ActivityKit side — nonisolated, so no handle crosses an actor

  private nonisolated static func ids() async -> [String] {
    Activity<CSRoundActivity>.activities.map(\.id)
  }

  private nonisolated static func push(id: String, state: CSRoundActivity.ContentState) async {
    guard let a = Activity<CSRoundActivity>.activities.first(where: { $0.id == id }) else { return }
    await a.update(ActivityContent(state: state, staleDate: Date().addingTimeInterval(stale)))
  }

  private nonisolated static func stop(id: String) async {
    guard let a = Activity<CSRoundActivity>.activities.first(where: { $0.id == id }) else { return }
    await a.end(nil, dismissalPolicy: .immediate)
  }
}
