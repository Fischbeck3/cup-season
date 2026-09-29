// N4 · accessibility findings read off the hosting view's accessibility tree
// (`HostedLayout`) at both phones' widths: what VoiceOver meets, in order.

import Testing
import SwiftUI
import UIKit
import CSDesign
@testable import CupSeason

@MainActor
@Suite struct N4AccessibilityTests {
  /// N4-015 · CSFactStrip gave VoiceOver every fact three times, out of order:
  /// the drawn figure, the drawn label and the 44pt target laid over them.
  /// The target is the one element now, one per fact, left to right.
  @Test("the fact strip says each fact once, in order, at the reading size")
  func theFactStripSaysEachFactOnce() {
    let cells = [CSFactStrip.Cell(value: "2", label: "Standing", ordinal: "nd"),
                 CSFactStrip.Cell(value: "06", label: "Weeks played"),
                 CSFactStrip.Cell(value: "10.9", label: "Your number")]
    for width in [CGFloat(375), 402] {
      let h = HostedLayout(CSFactStrip(cells, standing: nil), width: width)
      defer { h.tearDown() }
      let said = h.elements.map(\.label).filter { !$0.isEmpty }
      #expect(said == ["Standing, 2", "Weeks played, 06", "Your number, 10.9"], "\(width): \(said)")
    }
  }
}
