// Cup Season — the sheets every tab can raise (IOS-002 §2: objects push,
// actions present). One presenter, installed at the tab shell, so a Tour
// Card opened from Home and one opened from the board are the same door.
//
// D222 / IOS-028 · the shell went from four slots to five and **every sheet
// here survived it**, which is the point: a sheet is presented over whatever
// tab is on, so adding a destination changes where you LAND, never what can
// rise. `dismissAll()` and `anythingUp` are the two functions that must know
// every field — the push-ask waits on a clear stage and a routed tap clears
// one — so a new field that is not in both is a defect, and they are the first
// place to look when a prompt stops appearing.

import SwiftUI
import CupSeasonKit

@MainActor
@Observable
final class Presenter {
  var tourCard: UUID?
  /// D261 / R-N · the course card — the tees, the ratings and slopes and the
  /// hole card, drawn from the phone's own store so it opens on a plane.
  var courseCard: CourseSheetRef?
  /// D262 / R-O · the bag — fourteen clubs, the sideline and the ball, the
  /// one place any of them is edited.
  var showBag = false
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
  /// D225 · the intent sheet — five sentences, no object nouns. Every
  /// "Start something" lands here first, and nothing is minted by opening it.
  var showIntent = false
  /// Intent 1's fork: right now, or a day this week.
  var showWhenFork = false
  /// R-F · the golfer picker for "Go head to head", then the length.
  var showPickAGolfer = false
  var length: TagCandidate?
  /// D237 · the callout sheet, and the recipient's door.
  var callout: TagCandidate?
  var calloutReply: CalloutInvite?
  /// D242 · the forfeit sheet, reachable without a season.
  var forfeit: ForfeitTarget?
  struct CalloutInvite: Identifiable { let eventId: UUID; let from: String; let closesOn: String; var terms: String? = nil; var id: UUID { eventId } }
  struct ForfeitTarget: Identifiable { var home = ForfeitHome(); var opponentName: String? = nil; var id: String { String(describing: home) } }

  func join(code: String?) { joinCode = code; showJoin = true }

  /// Is any sheet or cover on stage? The push ask waits for a clear stage;
  /// a routed tap clears it first (D104).
  var anythingUp: Bool {
    tourCard != nil || receipt != nil || scorecard != nil || scheduledRound != nil || showJoin || showPost || showLive ||
      showFeedback || showDesk || showNote || declare != nil || inviteTo != nil || wizard != nil || draft != nil || runBack != nil ||
      showEventPicker || event != nil || showIntent || showWhenFork || showPickAGolfer ||
      length != nil || callout != nil || calloutReply != nil || forfeit != nil
  }

  /// Take everything down. Returns true if anything was up (the caller
  /// waits for the curtain before raising the next sheet).
  @discardableResult
  func dismissAll() -> Bool {
    let was = anythingUp
    tourCard = nil; receipt = nil; scorecard = nil; scheduledRound = nil; showJoin = false; showPost = false; showLive = false
    showFeedback = false; showDesk = false; showNote = false; declare = nil; inviteTo = nil; wizard = nil; draft = nil; runBack = nil
    showEventPicker = false; event = nil
    showIntent = false; showWhenFork = false; showPickAGolfer = false
    length = nil; callout = nil; calloutReply = nil; forfeit = nil
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
