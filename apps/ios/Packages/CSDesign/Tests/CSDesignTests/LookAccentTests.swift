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

  @Test func theCatalogueIsNinePlusTwo() {
    #expect(CSLooks.calendar.count == 9)
    #expect(CSLooks.phases.map(\.key) == ["cupfinal", "wrap"])
    #expect(CSLooks.calendar.filter(\.oddYearsOnly).map(\.key) == ["teams"])
  }
}
