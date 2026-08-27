// Cup Season — the sheets every tab can raise (IOS-002 §2: objects push,
// actions present). One presenter, installed at the tab shell, so a Tour
// Card opened from Home and one opened from the board are the same door.

import SwiftUI
import CupSeasonKit

@MainActor
@Observable
final class Presenter {
  var tourCard: UUID?
  var receipt: UUID?
  var scorecard: UUID?
  var scheduledRound: UUID?
  var showJoin = false
  var joinCode: String?
  var showPost = false
  var showFeedback = false
  var feedbackScreen = "home"
  var showDesk = false
  var showNote = false
  var declare: DeclarePrefill?
  /// "Add golfers" for a league — the people picker in invite mode.
  var inviteTo: UUID?
  /// The wizard (wave 5): nil league = a new one; `initialStep: 2` = "Lock it in".
  var wizard: WizardTarget?
  var draft: UUID?
  var runBack: UUID?
  struct WizardTarget: Identifiable { let existingLeagueId: UUID?; var initialStep = 0; var id: String { (existingLeagueId?.uuidString ?? "new") + "·\(initialStep)" } }
  /// Events (wave 6): the picker, and a room.
  var showEventPicker = false
  var event: UUID?

  func join(code: String?) { joinCode = code; showJoin = true }
}

private struct PresenterKey: EnvironmentKey {
  static let defaultValue: Presenter = MainActor.assumeIsolated { Presenter() }
}
extension EnvironmentValues {
  var presenter: Presenter {
    get { self[PresenterKey.self] }
    set { self[PresenterKey.self] = newValue }
  }
}
