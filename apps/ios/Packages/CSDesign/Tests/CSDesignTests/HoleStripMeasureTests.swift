// N4 · the live page's hole strip fits the page it is on.
//
// Eighteen cells at a 20pt floor asked for 360pt; an SE's measure is 335 (375
// less two 20pt gutters). The strip was wider than the page, the live page's
// ScrollView centred the wider column, and every block on it — the hole, the
// golfers, the game — sat at a 7.5pt inset instead of the 20pt gutter, on the
// SE only. These ask the strip, hosted, how wide it wants to be at each
// phone's measure.

import Testing
import SwiftUI
import UIKit
@testable import CSDesign

@MainActor
struct HoleStripMeasureTests {
  private func width(holes n: Int, measure: CGFloat, size: DynamicTypeSize = .large) -> CGFloat {
    let holes = (1...n).map { i in
      CSHoleStrip.Hole(number: i, overPar: i > 14 ? nil : (i % 3 == 0 ? 1 : (i % 4 == 0 ? -1 : 0)))
    }
    let vc = UIHostingController(rootView: CSHoleStrip(holes: holes, current: 15, trailing: "Your card · 55 thru 14")
      .environment(\.dynamicTypeSize, size)
      .csTheme())
    return vc.sizeThatFits(in: CGSize(width: measure, height: .greatestFiniteMagnitude)).width
  }

  @Test("eighteen holes fit an SE's 335pt measure and a 17 Pro's 362, at the reading size and AX3")
  func eighteenHolesFitThePage() {
    for measure in [CGFloat(335), 362] {
      for size in [DynamicTypeSize.large, .accessibility3] {
        let w = width(holes: 18, measure: measure, size: size)
        #expect(w <= measure + 0.5, "\(measure) \(size): the strip asks for \(w)")
      }
    }
  }

  @Test("the floor still keeps a gap between the widest marks: 16pt cells around a 14.4pt ring")
  func theFloorKeepsAGap() {
    #expect(CSHoleStrip.cellFloor * 18 <= 335)
    #expect(CSHoleStrip.cellFloor > 20 * 0.72)
  }
}
