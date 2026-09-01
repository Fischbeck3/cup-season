// Cup Season — the doors out of the You tab. The host decides where each one
// leads (the ⚙ hub, the buddies screen, the ⊕, the founder desk); this slice
// only opens them. Optional doors hide their button when the host has none —
// a button that cannot do anything is never rendered.

import Foundation
import CupSeasonKit

struct YouLinks {
  var openBuddies: () -> Void
  /// The ⚙ — SETTINGS, and only settings (IOS-029 call 1).
  var openSettings: () -> Void
  /// The card editor, reached by touching the card. `focusPhoto` raises the
  /// photo picker on arrival — the hero's "add your photo".
  var openCard: (_ focusPhoto: Bool) -> Void = { _ in }
  var openFeedback: () -> Void
  var openFounderDesk: () -> Void
  var postRound: () -> Void
  var openTourCard: (UUID) -> Void
  var openReceipt: (UUID) -> Void
  /// "add your GHIN" — lands on the GHIN field; falls back to `openCard`.
  var addGhin: (() -> Void)? = nil
  /// The founder's "✏️ Field note" (`founder_note`); hidden when nil.
  var founderNote: (() -> Void)? = nil
  /// D63 "Stage it" — the declare sheet for the given day, tagging one golfer;
  /// hidden when nil.
  var stageRound: ((_ playOn: String, _ tag: UUID) -> Void)? = nil

  @MainActor static let none = YouLinks(openBuddies: {}, openSettings: {}, openCard: { _ in }, openFeedback: {}, openFounderDesk: {}, postRound: {},
                             openTourCard: { _ in }, openReceipt: { _ in })
}
