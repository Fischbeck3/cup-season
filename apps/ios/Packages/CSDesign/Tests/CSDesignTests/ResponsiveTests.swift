// WAVE 10 · the responsive model, the accessibility floor, and the contrast
// table COMPUTED rather than quoted (UI_SYSTEM §16, D279, IOS-054).
//
// Every claim §16 makes about a ratio was written into a markdown table by
// hand. Two of them were already wrong by the time Wave 0a finished — the
// light metals were cut against the old cool `bg2` and four of them landed
// under AA on the new warm stock — and the only reason anybody found out was
// that one test computed a number instead of reading it. This file computes
// the whole table.

import Testing
import SwiftUI
@testable import CSDesign

@Suite struct AdvanceTests {

  /// The generalisation of `MeStripLayout.unit`: a string's width is what the
  /// FACE says it is. Plex Mono could be multiplied out at 0.6 em; the board
  /// face cannot, and neither can SF Pro or New York.
  @Test func aStringMeasuresWhatItsOwnFaceSays() {
    let short = CSAdvance.width("ROUNDS", .agateS)
    let long = CSAdvance.width("HANDICAP INDEX", .agateS)
    #expect(short > 0)
    #expect(long > short, "fourteen characters are wider than six in any face")
    #expect(CSAdvance.width("", .agateS) == 0, "nothing measures nothing")
  }

  /// Tracking is a RATIO of the rendered size (§1.2), so it is part of the
  /// advance and a layout that ignores it under-measures every caps line.
  @Test func trackingIsPartOfTheAdvance() {
    // `agate` tracks; `body` does not. The tracked role costs more per
    // character at the same nominal size than the untracked one does.
    let tracked = CSAdvance.width("MMMMMMMMMM", .agate)
    #expect(CSType.Role.agate.track > 0)
    #expect(tracked > 0)
  }

  /// The widest UNBREAKABLE run is what a column has to hold — the case
  /// `MeStripLayout` was written for and the one that still decides whether a
  /// name column can hold a name.
  @Test func theWidestWordIsWhatAColumnMustHold() {
    let whole = CSAdvance.width("PRIYA RAGHUNATHAN", .name)
    let word = CSAdvance.widestWord("PRIYA RAGHUNATHAN", .name)
    #expect(word < whole, "a two-word name breaks; the longest word is the floor")
    #expect(CSAdvance.widestWord("BARTHOLOMEW", .name) == CSAdvance.width("BARTHOLOMEW", .name),
            "a single token has nowhere to break and is measured whole")
  }

  /// A role that grows with the reading size measures wider at AX3, and a
  /// CAPPED role stops growing where its cap says. Both matter: the first is
  /// why a breakpoint table is wrong, the second is why the rail still holds
  /// two digits.
  @Test func theAdvanceFollowsTheSizeBeingRead() {
    let reading = CSAdvance.width("HANDICAP INDEX", .agateS, .large)
    let ax3 = CSAdvance.width("HANDICAP INDEX", .agateS, .accessibility3)
    #expect(ax3 > reading, "the same words are wider at AX3 — that is the whole finding")
    let capped = CSType.renderedSize(.figureM, .accessibility5)
    #expect(capped <= CSType.Role.figureM.size * 1.45 + 0.01,
            "the rail's 27 is capped at ×1.45 so two digits stay inside 44pt")
  }
}

@Suite struct MeasureTests {

  /// §16.3's 375pt paragraph, made arithmetic: the slat's numeric columns are
  /// a fraction of the measure and the NAME gets the difference.
  @Test func theSlatsColumnsAreDerivedFromTheMeasure() {
    let se = CSSlatMetrics.nameWidth(at: 375)
    let pro = CSSlatMetrics.nameWidth(at: 402)
    let max = CSSlatMetrics.nameWidth(at: 440)
    #expect(se < pro && pro < max, "a wider phone gives the name more room, not the columns")
    #expect(CSSlatMetrics.changeWidth(at: 375) < CSSlatMetrics.changeWidth(at: 402))
    #expect(CSSlatMetrics.changeWidth(at: 440) == 58, "the cap holds; the Max's extra goes to the name")
    #expect(CSSlatMetrics.trailingWidth(at: 375) >= 44, "the floor is what a two-digit total needs")
  }

  /// **The abbreviation is a MEASURE, not a count.** Eight rows that set
  /// perfectly on a Max truncated two surnames on an SE, because the rule was
  /// `count >= 10` and the column is a width.
  @Test func theBoardAbbreviatesWhenTheFieldDoesNotFit() {
    let long = ["Priya Raghunathan", "Bartholomew Winterbourne", "Sam Ridley"]
    let short = ["Jade Okafor", "Dev Rana", "Tash Bell"]
    #expect(CSSlatMetrics.abbreviates(names: long, count: 3, measure: 375, size: .large),
            "the SE cannot hold the longest of these")
    #expect(!CSSlatMetrics.abbreviates(names: short, count: 3, measure: 440, size: .large),
            "the Max can, so it prints them whole")
    #expect(CSSlatMetrics.abbreviates(names: short, count: 12, measure: 440, size: .large),
            "a field of ten or more keeps ONE grammar whatever the phone")
  }

  /// The three measures the product is read at, named rather than hard-coded
  /// per surface.
  @Test func theMeasureClassesAreTheThreePhones() {
    #expect(CSMeasureClass(375) == .narrow)
    #expect(CSMeasureClass(402) == .standard)
    #expect(CSMeasureClass(440) == .wide)
  }
}

@Suite struct ReduceTransparencyTests {

  /// §16.5 · the composited opaque value, and the worked example the palette
  /// already carries: `folioRule` is `ceremonyInk` at `a56` over `ceremony`,
  /// computed once by hand and given a name. The run-time arithmetic has to
  /// agree with it, or the two would drift.
  @Test func theCompositeAgreesWithTheTokenItWasNamedFrom() {
    let computed = CSOpaque.composite(CSTokens.dark.ceremonyInk, CSTokens.Alpha.a56,
                                      over: CSTokens.dark.ceremony)
    let named = CSTokens.dark.folioRule
    let a = computed.resolve(in: EnvironmentValues())
    let b = named.resolve(in: EnvironmentValues())
    #expect(abs(Double(a.red) - Double(b.red)) < 0.03, "red")
    #expect(abs(Double(a.green) - Double(b.green)) < 0.03, "green")
    #expect(abs(Double(a.blue) - Double(b.blue)) < 0.03, "blue")
    #expect(Double(a.opacity) == 1, "opaque is the whole point")
  }

  /// The switch is off by default and the tint is untouched: a golfer who has
  /// not asked for this sees exactly the texture the design draws.
  @Test func theTintIsUnchangedWhenTheSwitchIsOff() {
    let plain = CSOpaque.tint(CSTokens.dark.ceremonyInk, 0.24,
                              over: CSTokens.dark.ceremony, reduce: false)
    #expect(plain.resolve(in: EnvironmentValues()).opacity < 1)
    let opaque = CSOpaque.tint(CSTokens.dark.ceremonyInk, 0.24,
                               over: CSTokens.dark.ceremony, reduce: true)
    #expect(opaque.resolve(in: EnvironmentValues()).opacity == 1)
  }

  /// **A scrim is the one texture that cannot flatten to its darkest stop**,
  /// because the thing under it is a photograph. The hard edge keeps the
  /// picture above the band and gives the copy the ramp's own maximum.
  @Test func theScrimBecomesAHardEdgeRatherThanASolidPlate() {
    let hard = CSPhotoScrim.hardEdge(CSPhotoScrim.title)
    #expect(hard.count == 4)
    #expect(hard.first?.alpha == 0, "the top of the picture survives")
    #expect(hard.last?.alpha == CSPhotoScrim.title.map(\.alpha).max())
    // the edge is where the original crossed half its darkest value, so the
    // band is shorter than the ramp it replaces and darker throughout
    let edge = hard[1].at
    #expect(edge > 0 && edge < 1)
    // and the leading-anchored ramp keeps its direction
    let band = CSPhotoScrim.hardEdge(CSPhotoScrim.band)
    #expect(band.first?.alpha == CSPhotoScrim.band.map(\.alpha).max(),
            "the `band` ramp starts dark and ends clear; the hard edge does too")
  }
}

@Suite struct ContrastTableTests {

  /// §16.1's first line, computed for every pair it names, in both printings.
  /// `ink` and `mut` are the only two text tiers and they clear AA on every
  /// ground the product sets type on.
  @Test func everyTextTierClearsAAOnEveryGround() {
    for (mode, p) in [("dark", CSTokens.dark), ("light", CSTokens.light)] {
      for (gn, g) in [("bg0", p.bg0), ("bg1", p.bg1), ("bg2", p.bg2)] {
        #expect(Self.cr(p.ink, g) >= 4.5, "\(mode) ink on \(gn)")
        #expect(Self.cr(p.mut, g) >= 4.5, "\(mode) mut on \(gn)")
      }
    }
  }

  /// §16.1 · `dim` and `rule` are DECLARED NON-TEXT, and the declaration is
  /// only worth anything if the numbers back it.
  ///
  /// **AND ONE CLAUSE OF §16.1 IS WRONG, MEASURED.** It says `dim` is "below
  /// 3:1 even as large text"; the shipped dark value is **3.15:1 on `bg0`**,
  /// which clears WCAG's 3:1 large-text floor by 0.15. The RULING is
  /// untouched — `dim` may never carry a word, at any size, and `LINT-29`
  /// fails it inside a `Text(` — but it is a ruling now rather than an
  /// arithmetic consequence, and this test says so instead of repeating a
  /// number that is not true. `rule` genuinely is under 3 in both printings.
  @Test func dimAndRuleAreBelowThreeAndMayNeverCarryAWord() {
    for (mode, p) in [("dark", CSTokens.dark), ("light", CSTokens.light)] {
      #expect(Self.cr(p.dim, p.bg0) < 4.5, "\(mode) dim is not a text colour")
      #expect(Self.cr(p.rule, p.bg0) < 3, "\(mode) rule separates; it never states")
    }
    #expect(Self.cr(CSTokens.dark.dim, CSTokens.dark.bg0) > 3,
            "the dark dim is 3.15, not the sub-3 §16.1 prints — the fence is the ruling")
    #expect(Self.cr(CSTokens.light.dim, CSTokens.light.bg0) < 3, "the light one is 2.89")
  }

  /// **THE `bg2` COLUMN, COMPUTED — AND §16.1's OWN LIST OF WHO FAILS IT IS
  /// OUT OF DATE IN BOTH DIRECTIONS.** §16.1 names `brand`, `cool`, `gold`
  /// (light) and `pos` (light). Measured at the shipped values: in LIGHT all
  /// six clear it, because Wave 0a darkened four of them 1–6% to fix a
  /// different failure; in DARK it is `brand` and `cool` that do not. So the
  /// rule stands — a token under 4.5 on `bg2` may sit there only as a fill, a
  /// rule or a glyph with a label — and this test is what keeps the LIST
  /// honest rather than the prose.
  @Test func theBg2ColumnIsExactlyBrandAndCoolInTheDarkPrinting() {
    let d = CSTokens.dark
    #expect(Self.cr(d.brand, d.bg2) < 4.5)
    #expect(Self.cr(d.cool, d.bg2) < 4.5)
    #expect(Self.cr(d.gold, d.bg2) >= 4.5)
    #expect(Self.cr(d.pos, d.bg2) >= 4.5)
    #expect(Self.cr(d.neg, d.bg2) >= 4.5)
    let l = CSTokens.light
    for (n, c) in [("gold", l.gold), ("brand", l.brand), ("pos", l.pos),
                   ("neg", l.neg), ("cool", l.cool)] {
      #expect(Self.cr(c, l.bg2) >= 4.5, "light \(n) on bg2 — Wave 0a's darkening holds")
    }
  }

  /// §16.1's four named ceremony objects. On the pinned ground every token
  /// resolves to its DARK value in both printings, and these are the four the
  /// review checks by name.
  @Test func theFourCeremonyObjectsClearTheirOwnGround() {
    let g = CSTokens.dark.ceremony
    #expect(Self.cr(CSTokens.dark.ceremonyInk, g) >= 4.5, "the credential's shared rule")
    #expect(Self.cr(CSTokens.dark.ceremonyGold, g) >= 4.5, "the medallion's ring")
    #expect(Self.cr(CSTokens.dark.ceremonyMut, g) >= 4.5, "the event's dateline")
    #expect(Self.cr(CSTokens.dark.folioRule, g) >= 4.5, "the folio")
  }

  /// §6.2a · a marker's glyph is `ink` on a pigment disc, and all six discs
  /// have to carry it. A pigment that fails here is a golfer whose own mark is
  /// unreadable, which is the one thing the frozen pair exists to prevent.
  @Test func everyPigmentCarriesTheGlyph() {
    for (mode, p) in [("dark", CSTokens.dark), ("light", CSTokens.light)] {
      for (n, c) in [("pig0", p.pig0), ("pig1", p.pig1), ("pig2", p.pig2),
                     ("pig3", p.pig3), ("pig4", p.pig4), ("pig5", p.pig5)] {
        #expect(Self.cr(p.ink, c) >= 4.5, "\(mode) \(n)")
      }
    }
  }

  /// **§16.4's hardest number, and the reason a squad is always named.** The
  /// four squad marks are barely more than 1.5:1 apart from each other, so
  /// hue cannot carry a side. This asserts the failure, because a later
  /// palette change that made them separable would make the NAME look
  /// optional — and it is not: it is mandatory by ruling, not by arithmetic.
  @Test func theSquadMarksAreNotSeparableByHueAlone() {
    for (mode, p) in [("dark", CSTokens.dark), ("light", CSTokens.light)] {
      let sq = [p.sq0, p.sq1, p.sq2, p.sq3]
      var worst = Double.infinity
      for i in 0..<4 { for j in (i + 1)..<4 { worst = min(worst, Self.cr(sq[i], sq[j])) } }
      #expect(worst < 3, "\(mode): the four marks are \(worst):1 apart — the name is the channel")
    }
  }

  /// §16.5's Increase Contrast substitution, measured: `mut` steps to `ink` at
  /// `a88` and `rule` steps to `mut`, so the metadata voice and the one
  /// hairline both land well clear of AA.
  @Test func increaseContrastLiftsBothQuietTiers() {
    for (mode, p) in [("dark", CSTokens.dark), ("light", CSTokens.light)] {
      let ic = p.increasedContrast
      #expect(Self.cr(ic.mut, ic.bg0) > Self.cr(p.mut, p.bg0), "\(mode) mut steps up")
      #expect(Self.cr(ic.rule, ic.bg0) >= 4.5, "\(mode) rule becomes the metadata voice")
    }
  }

  private static func luminance(_ c: Color) -> Double {
    let r = c.resolve(in: EnvironmentValues())
    return 0.2126 * Double(r.linearRed) + 0.7152 * Double(r.linearGreen) + 0.0722 * Double(r.linearBlue)
  }
  private static func cr(_ a: Color, _ b: Color) -> Double {
    let (la, lb) = (luminance(a), luminance(b))
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
  }
}
