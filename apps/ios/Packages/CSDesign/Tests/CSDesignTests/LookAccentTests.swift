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
    #expect(la.wash == CSTokens.dark.brand)
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
    #expect(la.washStrength == 0.14)
    #expect(la.skyStrength == 0.10)
    #expect(la.tick == CSTokens.gradStops)
    #expect(la.eyebrow == nil, "no look: an eyebrow stays mut")
  }

  @Test func aLookReachesTheTickTheSkyTheWashAndTheEyebrow() {
    for spec in CSLooks.all {
      for (theme, cs) in [(CSTheme.dark, CSTokens.dark), (CSTheme.light, CSTokens.light)] {
        let la = CSLookAccent(look: spec, cs: cs, theme: theme)
        #expect(la.washStrength == 0.30, "\(spec.key) wash")
        #expect(la.skyStrength == 0.22, "\(spec.key) sky")
        #expect(la.tick == [spec.accent(theme), spec.accent2(theme)], "\(spec.key) tick")
        #expect(la.eyebrow == spec.accent(theme), "\(spec.key) eyebrow")
        #expect(la.tick.contains(cs.gold) == (spec.accent(theme) == cs.gold || spec.accent2(theme) == cs.gold),
                "\(spec.key): gold in the tick only when the catalogue put it there")
      }
    }
  }

  @Test func theCatalogueIsNinePlusTwo() {
    #expect(CSLooks.calendar.count == 9)
    #expect(CSLooks.phases.map(\.key) == ["cupfinal", "wrap"])
    #expect(CSLooks.calendar.filter(\.oddYearsOnly).map(\.key) == ["teams"])
  }
}
