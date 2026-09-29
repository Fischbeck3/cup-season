// Cup Season — `cs.screen.<name>`: the element a route verification reads.
//
// A capture that fell through to the door, to Home or to a blank screen is a
// FAILED capture, and the runner can only know that if the screen says which
// screen it is. This is that sentence: a 1pt, invisible, hit-transparent
// element over the screen's top-leading corner, identified `cs.screen.<name>`.
// It never changes layout or draws a pixel, and it exists only in a
// `-cs_dev_synthetic` launch — every other DEBUG run, and Release (where this
// file does not exist), is untouched.

#if DEBUG
import SwiftUI
import CupSeasonKit

struct SyntheticScreenMark: ViewModifier {
  let name: String
  @State private var stats = SyntheticStats.shared
  func body(content: Content) -> some View {
    if SyntheticSeam.on {
      content.overlay(alignment: .topLeading) {
        Color.clear
          .frame(width: 1, height: 1)
          .accessibilityElement()
          .accessibilityLabel(Text(verbatim: name))
          // What the runner records beside the shot: did any request go
          // unanswered (MISS) or fail on purpose (FAIL) before it was taken.
          .accessibilityValue(Text(verbatim: "misses=\(stats.misses) fails=\(stats.fails)"))
          .accessibilityIdentifier("cs.screen.\(name)")
          .allowsHitTesting(false)
          // X35 · the failures policy dates the route's own reads from here
          .onAppear { SyntheticBackend.screenShown(name) }
      }
    } else {
      content
    }
  }
}

/// The synthetic router's counters, observable so the screen marks carry them.
@MainActor @Observable
final class SyntheticStats {
  static let shared = SyntheticStats()
  var misses = 0
  var fails = 0
  nonisolated static func record(miss: Bool) {
    Task { @MainActor in if miss { shared.misses += 1 } else { shared.fails += 1 } }
  }
}

extension View {
  /// Marks a screen root for route verification in a synthetic launch.
  func csScreenMark(_ name: String) -> some View { modifier(SyntheticScreenMark(name: name)) }
}
#endif
