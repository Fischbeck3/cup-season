// Cup Season — the door's two registers (IOS-064).
//
// The bug this guards is not cosmetic: on a 375×667 phone with the keyboard
// up, `CONTINUE WITH EMAIL` — the only action on the first screen of the
// product — was entirely behind the keyboard, so an SE owner could not get in
// at all. The register is a pure function of the window and the reader's size,
// so it is asserted here rather than looked at in a screenshot.

import Testing
import SwiftUI
@testable import CupSeason

@Suite struct DoorLayoutTests {

  /// The devices this product actually meets, by window height in points.
  static let se: CGFloat = 667        // SE, SE2, SE3, 8
  static let standard: CGFloat = 844  // 14, 15, 16, 17
  static let pro: CGFloat = 852       // 17 Pro
  static let max: CGFloat = 956       // Max

  @Test("a short phone works and a tall one keeps its ceremony")
  func theRegisterSplitsOnTheDevice() {
    #expect(DoorLayout.working(windowHeight: Self.se, typeSize: .large))
    #expect(!DoorLayout.working(windowHeight: Self.standard, typeSize: .large))
    #expect(!DoorLayout.working(windowHeight: Self.pro, typeSize: .large))
    #expect(!DoorLayout.working(windowHeight: Self.max, typeSize: .large))
  }

  @Test("an accessibility size takes the working register on every device")
  func accessibilitySizesWorkEverywhere() {
    for h in [Self.se, Self.standard, Self.pro, Self.max] {
      #expect(DoorLayout.working(windowHeight: h, typeSize: .accessibility1))
      #expect(DoorLayout.working(windowHeight: h, typeSize: .accessibility3))
      #expect(DoorLayout.working(windowHeight: h, typeSize: .accessibility5))
    }
  }

  @Test("every reading size below the floor still ceremonies on a tall phone")
  func readingSizesDoNotFlipATallPhone() {
    for size in [DynamicTypeSize.xSmall, .small, .medium, .large, .xLarge, .xxLarge, .xxxLarge] {
      #expect(!DoorLayout.working(windowHeight: Self.pro, typeSize: size),
              "a tall phone at \(size) is the artboard's door and must not compress")
    }
  }

  /// **THE ARITHMETIC THE FIX IS.** The door's column above its own primary
  /// has to end above an email keyboard on the smallest phone the product
  /// meets, or the golfer never sees the action. The parts are measured off
  /// the built layout; the assertion is that they ADD UP.
  @Test("the working column puts the action above an SE's keyboard")
  func theActionClearsTheKeyboardOnAnSE() {
    // 375×667, 20pt status bar, and an email keyboard measured off `se-door.png`
    // at 229.5pt — so 417pt of viewport above it.
    let viewport: CGFloat = 667 - 20 - 229.5

    let crest = DoorLayout.crestWidth(working: true)
    // `ForgeFrame`: the canvas is the viewBox's visible band scaled by width;
    // the wordmark, the fuse gap, the fuse and the tagline are type and pads.
    let canvas = ForgeGeometry.visibleHeight * (crest / ForgeGeometry.viewBox.width)
    let wordmarkAndFuseAndTagline: CGFloat = 2 + 34 + 12 + 8 + 14 + 44
    let column = DoorLayout.crestTop(working: true)
      + canvas + wordmarkAndFuseAndTagline
      + DoorLayout.crestBottom(working: true)
      + 16 + 10          // EMAIL agate label and the stage's own spacing
      + 48               // CSField
      + 8 + 50           // the s2 pad and the primary

    #expect(column < viewport,
            "the working door is \(column)pt to the bottom of its action; an SE gives \(viewport)pt. The action is behind the keyboard again.")
  }

  @Test("the ceremony column does NOT fit an SE, which is why there are two")
  func theCeremonyColumnIsWhyTheRegisterExists() {
    let viewport: CGFloat = 667 - 20 - 229.5
    let crest = DoorLayout.crestWidth(working: false)
    let canvas = ForgeGeometry.visibleHeight * (crest / ForgeGeometry.viewBox.width)
    let column = DoorLayout.crestTop(working: false)
      + canvas + 2 + 34 + 12 + 8 + 14 + 44
      + DoorLayout.crestBottom(working: false)
      + 124 + 18         // the pitch, four lines and its pad
      + 16 + 10 + 48 + 8 + 50
    #expect(column > viewport,
            "if the ceremony column ever fits an SE the second register is dead weight — delete it.")
  }

  @Test("the working crest is smaller than the ceremony one and still drawn")
  func theCrestShrinksRatherThanDisappearing() {
    #expect(DoorLayout.crestWidth(working: true) < DoorLayout.crestWidth(working: false))
    #expect(DoorLayout.crestWidth(working: true) > 0)
    #expect(DoorLayout.crestTop(working: true) < DoorLayout.crestTop(working: false))
    #expect(DoorLayout.crestBottom(working: true) < DoorLayout.crestBottom(working: false))
  }

  @Test("the ceremony floor sits between the phones it separates")
  func theFloorIsADeviceBoundaryAndNotAGuess() {
    #expect(DoorLayout.ceremonyFloor > Self.se)
    #expect(DoorLayout.ceremonyFloor < Self.standard)
  }

  @Test("the scroll settles after the keyboard rather than with it")
  func theScrollWaitsForTheKeyboard() {
    // A UIKit keyboard animates in over 0.25–0.3s; a scroll issued before its
    // inset lands measures the pre-keyboard viewport and undershoots by the
    // keyboard's whole height.
    #expect(DoorLayout.settle >= .milliseconds(300))
    #expect(DoorLayout.settle <= .milliseconds(600))
  }
}
