// Cup Season — the door's geometry (IOS-064).
//
// **THE FIRST SCREEN OF THE PRODUCT COULD NOT BE COMPLETED ON A 375pt PHONE.**
// `se-door.png`: the mark cut in half by the status bar, the email field half
// under the keyboard, and `CONTINUE WITH EMAIL` — the only action on the
// screen — entirely off the bottom of it. The door auto-focuses email on
// appearance, so the keyboard is up from the moment a new golfer arrives:
// every SE owner met the product as a screen with no way forward on it.
//
// The cause is not a constant that is 20pt wrong. The door was drawn ONCE, at
// one size, for a tall phone: a 260pt crest, a 48pt entrance pad, a four-line
// pitch and only then the field. That column is ~605pt before the action's
// bottom edge, and a 667pt phone with an email keyboard up has 417pt of
// viewport. No amount of scrolling machinery makes 605 fit in 417 with the
// mark still whole — the CEREMONY has to have a second register.
//
// So it does. The door reads its window once (a window height does not change
// when a keyboard rises, so nothing thrashes) and picks a register:
//
//   · **ceremony** — a tall phone at a reading size. The Forge at 260, the
//     entrance pad at 48, the pitch above the field. Unchanged, to the point.
//   · **working** — a phone shorter than the ceremony floor, or ANY phone at
//     an accessibility size. The crest keeps every part it has and draws them
//     smaller; the marketing paragraph moves BELOW the action, where a golfer
//     who wants it can still read it and a golfer who wants in is not made to
//     scroll past it. The invited stranger's sentence — the one that names the
//     season he is joining — never moves: it is the answer to "what am I
//     handing my email to", and it is owed before the field, not after it.
//
// Which register is a pure function of two numbers, so it is a test rather
// than a screenshot (`DoorLayoutTests`).

import SwiftUI

enum DoorLayout {

  /// `.ob-crest{width:min(64vw, 300px)}` — the phone sits at 260.
  static let crestFull: CGFloat = 260

  /// The working crest. Every part of the mark survives — cup, wordmark, fuse,
  /// tagline — at the size that leaves the field and the action above an email
  /// keyboard on a 375×667 phone. The wordmark and the tagline are type and
  /// keep their own size; what shrinks is the drawn cup and its fuse, which is
  /// the part that was spending 113pt to say what 73pt says. 132 fitted and
  /// looked wrong — a small icon over a full-size wordmark — so the number is
  /// the largest cup that still leaves the action clear of an SE keyboard.
  static let crestWorking: CGFloat = 168

  /// **THE CEREMONY FLOOR.** A window shorter than this cannot hold the full
  /// crest, the pitch, the field AND the action above a keyboard. 667pt (SE,
  /// 8, SE2/3) is below it; 844 (14/15/16/17), 852 (17 Pro) and 956 (Max) are
  /// above it. The number is the device boundary and not a measurement of any
  /// one keyboard: iOS keyboards vary by locale, by predictive row and by
  /// whether a hardware one is attached, and a layout that flips register on a
  /// keyboard's live height flickers.
  static let ceremonyFloor: CGFloat = 700

  /// The working register. An accessibility size takes it on every device —
  /// at AX3 the pitch alone is taller than an SE.
  static func working(windowHeight: CGFloat, typeSize: DynamicTypeSize) -> Bool {
    typeSize.isAccessibilitySize || windowHeight < ceremonyFloor
  }

  static func crestWidth(working: Bool) -> CGFloat { working ? crestWorking : crestFull }

  /// The entrance pad above the mark, and the air below it before the door's
  /// words start. Ceremony is the artboard's; working gives 44pt back.
  static func crestTop(working: Bool) -> CGFloat { working ? 20 : 48 }
  static func crestBottom(working: Bool) -> CGFloat { working ? 20 : 36 }

  /// **THE ANCHOR THE KEYBOARD MAY NOT COVER.** Every stage of the door tags
  /// its own primary with this, and the door scrolls it to the bottom edge
  /// whenever a field takes focus. `scrollTo(_:anchor: .bottom)` is the
  /// MINIMUM scroll that reveals a target's bottom edge and it clamps at zero,
  /// so a phone where the action already fits does not move at all — which is
  /// what keeps the mark whole in the working register rather than merely
  /// reachable.
  static let action = "door-action"

  /// The keyboard's inset has to land on the scroll view before a scroll to
  /// the action means anything; a scroll issued in the same runloop as the
  /// focus change scrolls against the pre-keyboard viewport and undershoots.
  static let settle: Duration = .milliseconds(360)

  /// The window the door is drawn in. Read the same way `CSStatusCap` reads
  /// its safe area — the window, not `UIScreen`, because on iPad the door may
  /// be in a slide-over that is nothing like the screen.
  @MainActor static var windowHeight: CGFloat {
    #if canImport(UIKit)
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let window = scenes.first?.windows.first(where: \.isKeyWindow) ?? scenes.first?.windows.first
    return window?.bounds.height ?? ceremonyFloor
    #else
    return ceremonyFloor
    #endif
  }
}
