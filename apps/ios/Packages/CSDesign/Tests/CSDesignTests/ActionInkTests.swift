// F05 · THE ORDINARY ACTION IS READABLE IN EVERY PALETTE A GOLFER CAN WEAR.
//
// The audit measured one pair by hand — the Fall ("Autumn") look in the light
// printing, where the cream label on the primary's fill read 4.31:1 — and said
// the other twenty-one resting pairs cleared. A hand measurement of one state
// is how that pair shipped: nobody had multiplied the looks by the printings by
// the states. This file does, off the style's own resolved paint
// (`CSPrimaryStyle.paint`, which is what the body draws), for homebase and all
// eleven looks, dark and light, with and without Increase Contrast, at rest,
// pressed, busy and disabled — and on both grounds a primary actually stands
// on, the page and the band.
//
// The floors are WCAG's: 4.5:1 for the words (the label is `name` 17 semibold,
// under the large-text line), 3:1 for a mark that is not a word (the busy
// tally, the fill's own edge against the page, a focus ring, a lit rule), and
// the 3:1 the program set as the disabled label's target — which the disabled
// primary clears at better than AA anyway.

import Testing
import SwiftUI
@testable import CSDesign

@Suite struct ActionInkTests {
  typealias M = ContrastMath

  /// The two grounds a primary is drawn on: the page, and a `bg1` band.
  private static func grounds(_ p: CSPalette) -> [(String, Color)] { [("bg0", p.bg0), ("bg1", p.bg1)] }

  /// The words, at the opacity the state draws them, over the fill as it lands
  /// on the ground.
  private static func label(_ p: CSPalette, enabled: Bool, pressed: Bool, on ground: Color) -> Double {
    let paint = CSPrimaryStyle.paint(p, enabled: enabled, pressed: pressed, busy: false)
    let fill = M.flat(paint.fill, over: M.opaque(ground))
    return M.ratio(M.flat(paint.ink, opacity: paint.inkOpacity, over: fill), fill)
  }

  @Test("the primary's label clears 4.5:1 at rest, in every palette, on the page and the band")
  func restingLabelClearsAA() {
    for c in M.everyPalette {
      for (gn, g) in Self.grounds(c.palette) {
        let r = Self.label(c.palette, enabled: true, pressed: false, on: g)
        #expect(r >= 4.5, "\(c) on \(gn): the resting primary reads \(String(format: "%.3f", r)):1")
      }
    }
  }

  /// §7.1 gives the press a16 of movement and the words 92%. What it may not
  /// do is move the fill TOWARD its own words: the label is `bg0`, so a fill
  /// that thins toward the page thins toward the label, and the one state a
  /// golfer is certainly looking at becomes the least legible one.
  @Test("a pressed primary still reads at 4.5:1, in every palette, on the page and the band")
  func pressedLabelClearsAA() {
    for c in M.everyPalette {
      for (gn, g) in Self.grounds(c.palette) {
        let r = Self.label(c.palette, enabled: true, pressed: true, on: g)
        #expect(r >= 4.5, "\(c) on \(gn): the pressed primary reads \(String(format: "%.3f", r)):1")
      }
    }
  }

  @Test("the busy tally is a mark at 3:1 or better, at rest and pressed")
  func busyTallyIsVisible() {
    for c in M.everyPalette {
      for pressed in [false, true] {
        let paint = CSPrimaryStyle.paint(c.palette, enabled: true, pressed: pressed, busy: true)
        #expect(paint.inkOpacity == 0, "\(c): the tally replaces the words, it does not sit on them")
        let fill = M.flat(paint.fill, over: M.opaque(c.palette.bg0))
        let r = M.ratio(M.flat(paint.ink, over: fill), fill)
        #expect(r >= 3, "\(c)\(pressed ? " pressed" : ""): the busy tally reads \(String(format: "%.3f", r)):1")
      }
    }
  }

  @Test("a disabled primary is uncoloured and its label clears the 3:1 target")
  func disabledLabelIsReadable() {
    for c in M.everyPalette {
      let paint = CSPrimaryStyle.paint(c.palette, enabled: false, pressed: false, busy: false)
      #expect(paint.fill == c.palette.bg1, "\(c): a disabled primary never wears the action colour")
      let r = M.ratio(paint.ink, opacity: paint.inkOpacity, on: paint.fill)
      #expect(r >= 3, "\(c): the disabled label reads \(String(format: "%.3f", r)):1")
    }
  }

  /// The fill's own edge is the button's shape. At rest it is the label's
  /// ratio (the label IS the page colour); pressed, it must not fade into the
  /// page it sits on.
  @Test("the primary's fill keeps a 3:1 edge against the page, at rest and pressed")
  func fillEdgeHoldsAgainstThePage() {
    for c in M.everyPalette {
      for pressed in [false, true] {
        let paint = CSPrimaryStyle.paint(c.palette, enabled: true, pressed: pressed, busy: false)
        let page = M.opaque(c.palette.bg0)
        let r = M.ratio(M.flat(paint.fill, over: page), page)
        #expect(r >= 3, "\(c)\(pressed ? " pressed" : ""): the fill's edge is \(String(format: "%.3f", r)):1")
      }
    }
  }

  /// `act` is also a WORD and a MARK elsewhere in the system: the tab band's
  /// Play label, an ordinary selected verb, the field's focus ring, the door
  /// row's lit rule. The word needs AA on the page; the marks need 3:1 on the
  /// grounds they are drawn on (a focus ring sits on `bg2`).
  @Test("act as a word on the page, and as a mark on the page and the field")
  func actAsWordAndMark() {
    for c in M.everyPalette {
      let p = c.palette
      let word = M.ratio(p.act, on: p.bg0)
      #expect(word >= 4.5, "\(c): act as a word on the page reads \(String(format: "%.3f", word)):1")
      for (gn, g) in [("bg0", p.bg0), ("bg2", p.bg2)] {
        let mark = M.ratio(p.act, on: g)
        #expect(mark >= 3, "\(c): act as a mark on \(gn) is \(String(format: "%.3f", mark)):1")
      }
    }
  }
}
