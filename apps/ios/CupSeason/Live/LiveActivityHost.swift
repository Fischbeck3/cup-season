// Cup Season — D155 · starting, updating and (above all) ENDING the activity.
//
// An activity that outlives its round is worse than no activity: it is a lie on
// the lock screen that the app cannot be tapped out of. So every exit ends it —
// finish, scrap, abandon, backing out to setup — and `clearStale()` runs on
// rehydrate to sweep anything a crash or a force-quit left behind.
//
// The content is `LiveCopy.activity(_:)`, the same producer the scoreboard and
// the card read, so the island cannot drift from the screen.
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

  private static func facts(_ s: LiveRoundState) -> (CSRoundActivity, CSRoundActivity.ContentState) {
    let f = LiveCopy.activity(s)
    return (CSRoundActivity(course: f.course),
            .init(hole: f.hole, par: f.par, thru: f.thru, holes: f.holes, game: f.game))
  }

  /// Tee-off. Idempotent: a second call on a running round updates instead of
  /// stacking a second island.
  static func start(_ s: LiveRoundState) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled, s.active, s.stage == .live else { return }
    guard currentID == nil else { update(s); return }
    let (attrs, state) = facts(s)
    do {
      // a denied or unavailable activity is not something the golfer needs to
      // hear about — the round is unaffected and Home still has its banner
      currentID = try Activity.request(attributes: attrs,
                                       content: .init(state: state, staleDate: nil),
                                       pushType: nil).id
    } catch {
      currentID = nil
    }
  }

  static func update(_ s: LiveRoundState) {
    guard let id = currentID else { return }
    guard s.active, s.stage == .live else { Task { await end() }; return }
    let state = facts(s).1
    Task { await Self.push(id: id, state: state) }
  }

  /// Finish, scrap, abandon, backing out to setup — all end it.
  static func end() async {
    guard let id = currentID else { return }
    currentID = nil
    await Self.stop(id: id)
  }

  /// A crash or a force-quit can leave one running with no round behind it.
  /// Swept on rehydrate, before anything can tap it.
  static func clearStale(hasLiveRound: Bool) async {
    let live = await Self.ids()
    if hasLiveRound, currentID == nil, let adopt = live.first {
      currentID = adopt                      // the island belonging to the resumed round
    }
    for id in live where id != currentID { await Self.stop(id: id) }
    if !hasLiveRound { currentID = nil }
  }

  // MARK: the ActivityKit side — nonisolated, so no handle crosses an actor

  private nonisolated static func ids() async -> [String] {
    Activity<CSRoundActivity>.activities.map(\.id)
  }

  private nonisolated static func push(id: String, state: CSRoundActivity.ContentState) async {
    guard let a = Activity<CSRoundActivity>.activities.first(where: { $0.id == id }) else { return }
    await a.update(ActivityContent(state: state, staleDate: nil))
  }

  private nonisolated static func stop(id: String) async {
    guard let a = Activity<CSRoundActivity>.activities.first(where: { $0.id == id }) else { return }
    await a.end(nil, dismissalPolicy: .immediate)
  }
}
