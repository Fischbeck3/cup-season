// Cup Season — a course search answers ABOVE the keyboard (D363 / F8).
//
// The owner's finding, 2026-09-15: in live setup, typing a course left the
// field just above the keyboard and the matching courses under it, so the
// golfer had to scroll to find out whether search found anything at all. The
// field was visible; the ANSWER was not — and a hidden answer looks exactly
// like a missing course.
//
// Every course search (live setup, the plan composer, the post composer, the
// offline-courses sheet) now shares one rule: when its answer ARRIVES — rows,
// a no-match, an offline list, the tee list after a pick — the field is
// brought to the top of the visible scroll so the answer sits under it, above
// the keyboard. Only then. Not on a keystroke (the stage does not change while
// you type), not against a scroll the golfer made on purpose (only a
// transition asks), and not when the field is already at the top. Reduced
// motion rests on the frame (`CSMotion.run`, L-30). Focus is never touched.

import SwiftUI
import CSDesign

@MainActor
enum CourseSearchReveal {
  /// The one anchor id every host puts on its search field.
  static let id = "course.search"

  /// Bring the field to the top of the visible scroll, unless it is already
  /// there. `top` is the field's `minY` in the scroll view's own space, as
  /// measured by `.onGeometryChange` — `nan` before the first layout, which
  /// counts as "not at the top" so the first answer always reveals.
  static func run(_ proxy: ScrollViewProxy, top: CGFloat) {
    if top.isFinite, top >= 0, top <= 16 { return }
    CSMotion.run(CSMotion.rise) { proxy.scrollTo(id, anchor: .top) }
  }
}
