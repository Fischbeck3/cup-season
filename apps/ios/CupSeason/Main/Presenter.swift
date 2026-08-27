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
  /// Wave 5/6 hand-offs: the league wizard and the event picker are not on
  /// the phone yet; these present the honest web hand-off.
  var handoff: Handoff?

  enum Handoff: String, Identifiable { case league, event; var id: String { rawValue } }

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
