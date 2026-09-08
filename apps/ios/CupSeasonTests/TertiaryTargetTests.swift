// A tertiary link's TARGET, measured on a real hosted view.
//
// The owner could not get into settings from the You page. Every check this
// repo runs greps for `44` and every one passed, because the frame IS 44 — the
// question a grep cannot ask is whether the drawn row accepts a touch.
//
// **What this file can and cannot prove.** It hosts the control and measures
// the row, which is real. It does NOT hit-test: modern SwiftUI puts one
// `_UIHostingView` on screen and routes every touch through gesture
// recognisers on it, so `UIView.hitTest` returns that same hosting view at
// every point and can tell you nothing about which control would fire. An
// earlier version of this file asserted on `hitTest` and "failed" identically
// whether the bug was present or not, which is worse than no test. Proving a
// tap needs an XCUITest target, which this app does not have; that is recorded
// as the honest gap rather than papered over with a probe that cannot see.
//
// So: this pins the geometry, and `CSTertiaryStyle` pins the shape by putting
// `contentShape` AFTER the frame rather than before it — `a11yHitSlop` installs
// its shape at the size of the WORDS and then pads back negative, so anything
// relying on the 44pt row being the target had to say so explicitly.

import Testing
import SwiftUI
import UIKit
@testable import CSDesign

@MainActor
struct TertiaryTargetTests {

  private func height(_ label: String, width: CGFloat = 402) -> CGFloat {
    let vc = UIHostingController(rootView: CSDoor(.link(label, {})))
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 400))
    window.rootViewController = vc
    window.isHidden = false
    window.layoutIfNeeded()
    return vc.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height
  }

  @Test("a tertiary link stands at least 44pt tall")
  func rowIsAtLeastFortyFour() {
    let h = height("Settings")
    #expect(h >= 44,
            "a tertiary link is the product's idiom for 'go here'; it must be a legal target. Got \(h)")
  }

  @Test("a long link wraps rather than shrinking below the floor")
  func longLabelStaysLegal() {
    let h = height("A long tertiary link that wraps onto a second line at the default size")
    #expect(h >= 44, "a wrapped link is still a target. Got \(h)")
  }
}
