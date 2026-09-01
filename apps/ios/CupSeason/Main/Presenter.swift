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
  /// D110 addendum: true = jump straight to the composer (a "post a round" CTA);
  /// false = the ⊕ shows the three-door cover.
  var postOnComposer = false
  /// The tee sheet (wave 4): setup → live → recap, over whichever tab.
  var showLive = false
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

  /// Is any sheet or cover on stage? The push ask waits for a clear stage;
  /// a routed tap clears it first (D104).
  var anythingUp: Bool {
    tourCard != nil || receipt != nil || scorecard != nil || scheduledRound != nil || showJoin || showPost || showLive ||
      showFeedback || showDesk || showNote || declare != nil || inviteTo != nil || wizard != nil || draft != nil || runBack != nil ||
      showEventPicker || event != nil
  }

  /// Take everything down. Returns true if anything was up (the caller
  /// waits for the curtain before raising the next sheet).
  @discardableResult
  func dismissAll() -> Bool {
    let was = anythingUp
    tourCard = nil; receipt = nil; scorecard = nil; scheduledRound = nil; showJoin = false; showPost = false; showLive = false
    showFeedback = false; showDesk = false; showNote = false; declare = nil; inviteTo = nil; wizard = nil; draft = nil; runBack = nil
    showEventPicker = false; event = nil
    return was
  }
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
