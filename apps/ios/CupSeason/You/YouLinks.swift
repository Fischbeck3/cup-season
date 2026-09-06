// Cup Season — the doors out of the You tab. The host decides where each one
// leads (the ⚙ hub, the buddies screen, the ⊕, the founder desk); this slice
// only opens them. Optional doors hide their button when the host has none —
// a button that cannot do anything is never rendered.

import Foundation
import CupSeasonKit

struct YouLinks {
  var openBuddies: () -> Void
  var openSettings: () -> Void
  var openFeedback: () -> Void
  var openFounderDesk: () -> Void
  var postRound: () -> Void
  var openTourCard: (UUID) -> Void
  var openReceipt: (UUID) -> Void
  /// D232 · "Your record", the second head, promoted to a destination.
  /// Optional so a slice or a preview compiles without the shell; the door
  /// falls back to Settings rather than rendering a control that does nothing.
  var openRecord: (() -> Void)? = nil
  /// "add your GHIN" — lands on the GHIN field; falls back to `openSettings`.
  var addGhin: (() -> Void)? = nil
  /// D262 · R-O · "Your bag" — the editor. Optional so a slice compiles
  /// without the shell, and the ROW IS NOT DRAWN when it is nil: a door that
  /// cannot open is never rendered.
  var openBag: (() -> Void)? = nil
  /// The founder's "✏️ Field note" (`founder_note`); hidden when nil.
  var founderNote: (() -> Void)? = nil
  /// D63 "Plan a round" — the declare sheet for the given day, tagging one golfer;
  /// hidden when nil.
  var stageRound: ((_ playOn: String, _ tag: UUID) -> Void)? = nil

  /// The bag door, added after the rest — the initialiser already takes
  /// twelve arguments and a thirteenth positional one is how a call site ends
  /// up wiring the wrong closure.
  func withBag(_ open: @escaping () -> Void) -> YouLinks {
    var copy = self
    copy.openBag = open
    return copy
  }

  @MainActor static let none = YouLinks(openBuddies: {}, openSettings: {}, openFeedback: {}, openFounderDesk: {}, postRound: {},
                             openTourCard: { _ in }, openReceipt: { _ in })
}
