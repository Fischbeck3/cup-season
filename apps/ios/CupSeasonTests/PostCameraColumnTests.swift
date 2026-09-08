// Cup Season — the composer's camera column (IOS-066).
//
// The claim this file guards is a claim about ARITHMETIC, not about taste:
// the plate is the gross figure's twin — the same width, and 3:2 of it, so
// the two columns of the hero end on the same line — and it therefore costs
// no vertical space that was not already blank beside a 150pt figure. If
// somebody widens the figure column and not the plate, or picks a ratio that
// makes the plate taller than the number, the composition the whole change
// rests on is gone and nothing in a screenshot review would necessarily
// catch it on the phone that was photographed that day.

import Testing
import SwiftUI
import CSDesign
import CupSeasonKit
@testable import CupSeason

@Suite struct PostCameraColumnTests {

  /// The measure — the page's own gutter is 20pt a side (`CSTokens.Space.gutter`).
  static func measure(_ screenWidth: CGFloat) -> CGFloat {
    screenWidth - CSTokens.Space.gutter * 2
  }
  static let seWidth: CGFloat = 375     // SE, SE2, SE3, 8
  static let proWidth: CGFloat = 402    // 17 Pro

  @Test("the plate is 3:2 in both registers, so a photograph is never two shapes")
  func theRatioHolds() {
    #expect(PostCameraColumn.plateWidth / PostCameraColumn.plateHeight == 1.5)
    #expect(PostCameraColumn.plateWidthA11y / PostCameraColumn.plateHeightA11y == 1.5)
  }

  /// The twin: the plate is exactly as wide as the figure column the hero
  /// draws the gross in, and 3:2 puts its foot within a few points of the
  /// agate label under the rule. Both columns are pinned to their own margin,
  /// so the pair has to FIT on the narrowest phone with the gutters on.
  @Test("the number and the picture fit side by side on a 375pt phone")
  func theTwoColumnsFitTheNarrowestPhone() {
    let needed = PostCameraColumn.plateWidth * 2 + CSTokens.Space.s3
    #expect(needed <= Self.measure(Self.seWidth))
    #expect(needed <= Self.measure(Self.proWidth))
  }

  /// **THE WHOLE POINT, AS A SUM.** On an SE the composer opens focused on the
  /// gross, so the keypad is up from the first frame: ~216pt of viewport is
  /// left between the navigation bar and the pinned foot. The camera column is
  /// the plate, the 8pt gap and a 44pt scan target, and it starts one eyebrow
  /// (~20pt) down. If that total ever exceeds the slot, the camera is behind a
  /// scroll again and this change has quietly undone itself.
  @Test("the whole camera column clears an SE keypad")
  func theCameraIsAboveTheFoldWithTheKeypadUp() {
    let eyebrow: CGFloat = 20
    let column = PostCameraColumn.plateHeight + CSTokens.Space.s2 + CSTokens.Space.rail
    #expect(eyebrow + column <= 216)
  }

  /// The accessibility cap has to actually cap something — 3:2 of the
  /// narrowest accessibility measure is 223pt — and it must never make the
  /// picture SMALLER than it is at a reading size, which would be backwards.
  @Test("the accessibility plate is bigger than the reading one and still capped")
  func theAccessibilityCapIsRealAndPointsTheRightWay() {
    #expect(PostCameraColumn.plateHeightA11y > PostCameraColumn.plateHeight)
    #expect(PostCameraColumn.plateHeightA11y < Self.measure(Self.seWidth) / 1.5)
    #expect(PostCameraColumn.plateWidthA11y <= Self.measure(Self.seWidth))
  }

  /// D234 · the word in the frame is the same word the receipt's control uses,
  /// and both read it from `RoundCopy`. A second literal here would be the
  /// beginning of two products saying the same thing two ways.
  @Test("the plate's invitation is the one producer's word")
  func theInvitationHasOneProducer() {
    #expect(RoundCopy.photoAdd == "Add a photo")
    #expect(RoundCopy.photoAdd != RoundCopy.photoReplace)
  }
}
