// F05, verified further · THE CHOSEN PANEL CARRIES ITS WORDS IN EVERY PALETTE.
//
// D313 made a look's second colour the panel — your line on a board, today on
// the calendar, a picked option, Home's rank chip — and `CSInk` flips the ink
// on it. The flip was measured for the FIGURE and never for the words under
// it: the theme's `panelMut`, cut for the theme's own bone and ink panels, read
// 1.82–4.43:1 on eighteen of the twenty-two look panels, so `OF EIGHT` under
// the rank was the least legible word on Home under almost every look. And the
// movement triangles assumed a bone panel in both rooms — true at dusk only —
// so on paper, with no look at all, the green up-mark read 2.75:1 on the ink
// panel. This file measures all of it, in every palette a golfer can wear.

import Testing
import SwiftUI
@testable import CSDesign

@Suite struct PanelInkTests {
  typealias M = ContrastMath

  @Test("the figure on a panel clears 4.5:1 in every palette")
  func theFigureReads() {
    for c in M.everyPalette {
      let r = M.ratio(c.palette.panelInk, on: c.palette.panel)
      #expect(r >= 4.5, "\(c): panelInk on the panel reads \(String(format: "%.3f", r)):1")
    }
  }

  @Test("the label under it clears 4.5:1 in every palette, Increase Contrast included")
  func theLabelReads() {
    for c in M.everyPalette {
      let r = M.ratio(c.palette.panelMut, on: c.palette.panel)
      #expect(r >= 4.5, "\(c): panelMut on the panel reads \(String(format: "%.3f", r)):1")
    }
  }

  @Test("Increase Contrast never makes the panel's label quieter than the default")
  func increasedContrastNeverSteppedDown() {
    for c in M.everyPalette where !c.increased {
      let base = M.ratio(c.palette.panelMut, on: c.palette.panel)
      let ic = c.palette.increasedContrast
      let stepped = M.ratio(ic.panelMut, on: ic.panel)
      #expect(stepped >= base - 0.01, "\(c): IC label \(stepped) against default \(base)")
    }
  }

  @Test("homebase keeps its own panel voice — the fix only reaches a look's panel")
  func homebaseIsUntouched() {
    for (theme, p) in [(CSTheme.dark, CSTokens.dark), (CSTheme.light, CSTokens.light)] {
      let worn = p.wearing(nil, theme: theme)
      #expect(worn.panelMut == p.panelMut, "\(theme): no look, no change to the panel's label")
    }
  }

  @Test("the movement marks inside a panel are visible at 3:1 in every palette")
  func theMovementMarksRead() {
    for c in M.everyPalette {
      for state in [CSMovement.State.up(2), .down(1), .held] {
        let tint = CSMovement.markColor(state, over: .panel, cs: c.palette)
        let r = M.ratio(tint, on: c.palette.panel)
        #expect(r >= 3, "\(c) \(state) on the panel: \(String(format: "%.3f", r)):1")
      }
      for state in [CSMovement.State.up(2), .down(1), .held] {
        let tint = CSMovement.markColor(state, over: .page, cs: c.palette)
        let r = M.ratio(tint, on: c.palette.bg0)
        #expect(r >= 3, "\(c) \(state) on the page: \(String(format: "%.3f", r)):1")
      }
    }
  }

  /// The dark room's bone panel keeps the paper green it always carried — the
  /// measurement agrees with the old assumption where the assumption was true.
  @Test("the dark room's bone panel keeps the paper printing of pos and cool")
  func boneKeepsThePaperPrinting() {
    let cs = CSTokens.dark
    #expect(CSMovement.markColor(.up(1), over: .panel, cs: cs) == CSTokens.light.pos)
    #expect(CSMovement.markColor(.down(1), over: .panel, cs: cs) == CSTokens.light.cool)
    #expect(CSMovement.markColor(.up(1), over: .page, cs: cs) == cs.pos)
  }
}
