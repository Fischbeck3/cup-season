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
  /// D319 · a kept course, opened. `(api_course_id, label)` — the same pair
  /// `CourseSheetRef` takes, so this page reaches the one course page the
  /// product has rather than a second copy of it. nil, or a course with no id,
  /// draws a plain row.
  var openCourse: ((String, String) -> Void)? = nil
  /// The founder's "✏️ Field note" (`founder_note`); hidden when nil.
  var founderNote: (() -> Void)? = nil
  /// D63 "Plan a round" — the declare sheet for the given day, tagging one golfer;
  /// hidden when nil.
  var stageRound: ((_ playOn: String, _ tag: UUID) -> Void)? = nil

  /// Wave 3 · a rival slat on the You root opens the head-to-head, which is
  /// the whole point of putting rivals on the page: a name here is a record
  /// there. nil falls back to the person page, which still holds the record.
  var openHeadToHead: ((UUID) -> Void)? = nil

  /// The bag door, added after the rest — the initialiser already takes
  /// twelve arguments and a thirteenth positional one is how a call site ends
  /// up wiring the wrong closure.
  func withBag(_ open: @escaping () -> Void) -> YouLinks {
    var copy = self
    copy.openBag = open
    return copy
  }

  /// D319 · same reason as `withBag` — a named builder rather than a
  /// fifteenth positional argument on a struct nobody can read at the call
  /// site.
  func withCourse(_ open: @escaping (String, String) -> Void) -> YouLinks {
    var copy = self
    copy.openCourse = open
    return copy
  }

  /// Same reason as `withBag`: a named builder rather than a fourteenth
  /// positional closure.
  func withHeadToHead(_ open: @escaping (UUID) -> Void) -> YouLinks {
    var copy = self
    copy.openHeadToHead = open
    return copy
  }

  /// Where a rival's row goes — the head-to-head when the host wired one,
  /// their card otherwise. A door that cannot open is never rendered, and
  /// this one always can.
  func rival(_ id: UUID) { (openHeadToHead ?? openTourCard)(id) }

  @MainActor static let none = YouLinks(openBuddies: {}, openSettings: {}, openFeedback: {}, openFounderDesk: {}, postRound: {},
                             openTourCard: { _ in }, openReceipt: { _ in })
}
