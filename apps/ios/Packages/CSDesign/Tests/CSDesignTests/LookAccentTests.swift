import Testing
import SwiftUI
@testable import CSDesign

/// IOS-025 — the look's colours fall back to ember; gold is never a look's to take.
@Suite struct LookAccentTests {
  @Test func noLookIsEmber() {
    let la = CSLookAccent(look: nil, cs: CSTokens.dark, theme: .dark)
    #expect(!la.active)
    #expect(la.accent == CSTokens.dark.brand)
    #expect(la.accent2 == CSTokens.dark.brand)
    /* D278 · `wash` is deleted with `CSWash` — the product paints no
       atmosphere. The spine is the channel that carried the same colour to a
       MARK, and it is what survives. */
    #expect(la.spine(earned: false) == CSTokens.dark.brand)
  }

  @Test func aLookWearsItsThemeAccent() {
    let claret = CSLooks.spec("oldest")!
    #expect(CSLookAccent(look: claret, cs: CSTokens.dark, theme: .dark).accent == claret.accentDark)
    #expect(CSLookAccent(look: claret, cs: CSTokens.light, theme: .light).accent == claret.accentLight)
    #expect(CSLookAccent(look: claret, cs: CSTokens.light, theme: .light).accent2 == claret.accent2Light)
  }

  @Test func earnedStaysGoldUnderAnyLook() {
    for spec in CSLooks.all {
      let la = CSLookAccent(look: spec, cs: CSTokens.dark, theme: .dark)
      #expect(la.spine(earned: true) == CSTokens.dark.gold, "\(spec.key) took gold")
      #expect(la.spine(earned: false) == spec.accentDark)
    }
  }

  // MARK: D103b — how far a look reaches

  @Test func homebaseReachIsExactlyWhatItWas() {
    let la = CSLookAccent(look: nil, cs: CSTokens.dark, theme: .dark)
    #expect(la.tick == [CSTokens.dark.brand, CSTokens.dark.brand],
            "D270: homebase's tick is flat ember — the gradient is deleted")
    #expect(la.eyebrow == nil, "no look: an eyebrow stays mut")
    #expect(la.spine(earned: false) == CSTokens.dark.brand)
    /* D278 · `washStrength` and `skyStrength` used to be pinned here. Both are
       DELETED with `CSWash` and `CSLookSky` — the product paints no
       atmosphere, so a strength for it is a number waiting to be used. If
       either comes back, this file will not compile, which is the point. */
  }

  /// **A look reaches exactly three channels after D278: the tick, the eyebrow
  /// and the spine.** It used to reach five — the two extra were the hero wash
  /// and the sky, both fields of colour over a page, both deleted in the sweep.
  @Test func aLookReachesTheTickTheSpineAndTheEyebrow() {
    for spec in CSLooks.all {
      for (theme, cs) in [(CSTheme.dark, CSTokens.dark), (CSTheme.light, CSTokens.light)] {
        let la = CSLookAccent(look: spec, cs: cs, theme: theme)
        #expect(la.tick == [spec.accent(theme), spec.accent2(theme)], "\(spec.key) tick")
        #expect(la.eyebrow == spec.accent(theme), "\(spec.key) eyebrow")
        #expect(la.tick.contains(cs.gold) == (spec.accent(theme) == cs.gold || spec.accent2(theme) == cs.gold),
                "\(spec.key): gold in the tick only when the catalogue put it there")
      }
    }
  }

  /// The other direction, so the deletion cannot quietly come back through a
  /// different door: whatever a look colours, it colours a MARK. Every channel
  /// `CSLookAccent` exposes is a stroke, a word or a 3px tick — none of them is
  /// a fill behind content, which is what the sky and the wash were.
  @Test func aLookColoursMarksAndNeverAGround() {
    let claret = CSLooks.spec("oldest")!
    let la = CSLookAccent(look: claret, cs: CSTokens.dark, theme: .dark)
    #expect(la.accent == claret.accentDark)
    #expect(la.accent2 == claret.accent2Dark)
    #expect(la.eyebrow == claret.accentDark)
    #expect(la.tick.count == 2, "the tick is two stops and nothing wider")
    #expect(la.spine(earned: true) == CSTokens.dark.gold, "earned outranks every look")
  }

  @Test func theCatalogueIsNinePlusTwo() {
    #expect(CSLooks.calendar.count == 9)
    #expect(CSLooks.phases.map(\.key) == ["cupfinal", "wrap"])
    #expect(CSLooks.calendar.filter(\.oddYearsOnly).map(\.key) == ["teams"])
  }
}
