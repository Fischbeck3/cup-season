// N4 · Home's door to a round's conversation says one comment as one, and is
// a whole 44pt target rather than its 18pt words. Read off the hosting view's
// accessibility tree (`HostedLayout`) at both phones' widths, the reading
// size and AX3.

import Testing
import SwiftUI
import UIKit
import CSDesign
import CupSeasonKit
@testable import CupSeason

@MainActor
@Suite struct CommentsDoorTargetTests {
  private func door(_ count: Int?, width: CGFloat, size: DynamicTypeSize) -> (HostedLayout, HostedLayout.Element?) {
    let h = HostedLayout(HomeWireReactions(state: [:], day: "Sun", commentCount: count,
                                           openComments: {}, onToggle: { _ in })
                          .padding(.horizontal, CSTokens.Space.gutter),
                         width: width, typeSize: size)
    return (h, h.element("home.round.comments"))
  }

  @Test("one comment is `1 comment`, and the door says what it opens with none")
  func theDoorCountsInEnglish() {
    for (n, said) in [(1, "1 comment"), (2, "2 comments"), (0, "Comments")] {
      let (h, e) = door(n, width: 402, size: .large)
      defer { h.tearDown() }
      #expect(e?.label == said, "\(n): \(e?.label ?? "no door")")
    }
  }

  @Test("the door is a whole 44pt target at the reading size and AX3, on both phones")
  func theDoorIsAWholeTarget() {
    for width in [CGFloat(375), 402] {
      for size in [DynamicTypeSize.large, .accessibility3] {
        let (h, e) = door(1, width: width, size: size)
        defer { h.tearDown() }
        #expect(e != nil, "\(width) \(size): the door is an element")
        if let f = e?.frame {
          #expect(f.height >= 44 - 0.01 && f.width >= 44 - 0.01, "\(width) \(size): \(f.width) × \(f.height)")
        }
      }
    }
  }
}
