// D405 · the newest comment under a round is a door, and a whole one: one line
// of what Blake said, a 44pt target at both phones' widths, the reading size and
// AX3 — read off the hosting view's accessibility tree (`HostedLayout`).

import Testing
import SwiftUI
import UIKit
import CSDesign
import CupSeasonKit
@testable import CupSeason

@MainActor
@Suite struct InlineThreadPreviewTests {
  private func door(_ count: Int, latest: Bool) -> RoundSocialDoor {
    let author = SocialPerson(.object(["id": .string(UUID().uuidString), "name": .string("Blake Hartwell")]))!
    return RoundSocialDoor(roundId: UUID(), commentCount: count,
                           latest: latest ? .init(id: UUID(), author: author, body: "Did the putt on 18 drop?", createdAt: "") : nil)
  }

  private let round = UUID()
  private var previewId: String { "round.preview.\(round.uuidString)" }

  private func hosted(_ door: RoundSocialDoor?, width: CGFloat, size: DynamicTypeSize) -> HostedLayout {
    HostedLayout(InlineRoundThread(roundId: round, door: door, isOpen: false, open: {})
                   .padding(.horizontal, CSTokens.Space.gutter),
                 width: width, typeSize: size)
  }

  @Test("the newest comment is one line under the round, and says who said it")
  func thePreviewReadsAsOneLine() {
    let h = hosted(door(3, latest: true), width: 402, size: .large)
    defer { h.tearDown() }
    let e = h.element(previewId)
    #expect(e?.label == "Latest comment. Blake: Did the putt on 18 drop?", "\(e?.label ?? "no preview")")
  }

  @Test("the preview is a whole 44pt target at the reading size and AX3, on both phones")
  func thePreviewIsAWholeTarget() {
    for width in [CGFloat(375), 402] {
      for size in [DynamicTypeSize.large, .accessibility3] {
        let h = hosted(door(3, latest: true), width: width, size: size)
        defer { h.tearDown() }
        let e = h.element(previewId)
        #expect(e != nil, "\(width) \(size): the preview is an element")
        if let f = e?.frame { #expect(f.height >= 44 - 0.01, "\(width) \(size): \(f.width) × \(f.height)") }
      }
    }
  }

  @Test("a round with no newest comment, or a server that does not send one, draws nothing extra")
  func noPreviewWithoutAComment() {
    for door in [door(0, latest: false), door(3, latest: false)] {
      let h = hosted(door, width: 402, size: .large)
      defer { h.tearDown() }
      #expect(h.element(previewId) == nil)
    }
    let none = hosted(nil, width: 402, size: .large)
    defer { none.tearDown() }
    #expect(none.element(previewId) == nil)
  }
}
