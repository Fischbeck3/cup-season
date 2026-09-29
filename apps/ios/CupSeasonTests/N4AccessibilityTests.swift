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

  /// N4-140 · buddy chips ran off the right edge and cut names on an SE, and
  /// at AX3 on both phones: FlowLayout measured every chip unconstrained and a
  /// chip held one unbreakable line. A chip is offered at most its row now,
  /// and a long name takes a second line inside it.
  @Test("a chip longer than its row wraps inside it, and nothing runs off the edge")
  func aLongChipStaysInsideItsRow() {
    let names = ["Maximilian Placeholder-Fixture", "Casey Placeholderfixture", "Avery"]
    for (width, size) in [(CGFloat(335), DynamicTypeSize.large), (362, .accessibility3)] {
      let h = HostedLayout(FlowLayout(spacing: 8) { ForEach(names, id: \.self) { CSChip($0, selected: false) } },
                           width: width, typeSize: size)
      defer { h.tearDown() }
      let chips = h.elements.filter { e in names.contains { e.label.caseInsensitiveCompare($0) == .orderedSame } }
      #expect(chips.count == names.count, "\(width) \(size): every chip is drawn — \(h.elements.map(\.label))")
      for c in chips {
        #expect(c.frame.minX >= -0.5 && c.frame.maxX <= width + 0.5, "\(width) \(size): '\(c.label)' stays in its row — \(c.frame)")
      }
    }
  }
}
