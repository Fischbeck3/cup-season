// Cup Season — the display case's marks, held together across the two
// packages (Wave 3, `surfaces/profile.md` §9, `UI_SYSTEM` §5.2).
//
// `TrophyMeta` lives in `CupSeasonKit` and names a mark by STRING, because the
// Kit sits below `CSDesign` and cannot see its types — the same contract the
// generated marker table already uses. That leaves exactly one way for the
// case to go quietly wrong: a key the Kit emits that `CSTrophyMark` does not
// know falls to `.medal`, and every trophy in the product draws the same
// medal with no crash, no log and nothing on screen that says so. That is
// D258's failure mode on a different vocabulary.
//
// This suite is hosted by the APP, which is the one target that can see both
// packages, and it is the only place the two halves can be compared.

import Testing
import CSDesign
import CupSeasonKit

@Suite struct TrophyMarkTests {

  /// Every key the Kit can emit resolves to a REAL mark — never the fallback.
  @Test func everyKitKeyIsADrawnMark() {
    var keys = Set(TrophyMeta.ach.values.map(\.glyph))
    for kind in ["league", "major", "event", "ryder", "bracket", "points_king", "crown"] {
      for placement in ["winner", "runner_up", "points_king"] {
        keys.insert(TrophyMeta.trophyGlyph(kind: kind, placement: placement))
      }
    }
    for k in keys {
      #expect(CSTrophyMark.Mark(rawValue: k) != nil, "no drawn mark for \(k)")
      #expect(k != "medal", "\(k) should not be the fallback")
    }
  }

  /// §5.2 · two achievements may never share a glyph — the mark plus its
  /// numeral is the identity, so `sub_90` and `sub_100` are two marks even
  /// though they are one shape.
  @Test func theMarksAreDistinct() {
    let marks = TrophyMeta.ach.values.map { $0.glyph + "|" + ($0.numeral ?? "") }
    #expect(Set(marks).count == marks.count)
  }

  /// `LINT-28` · the pennant is the tab band and the app icon, and nowhere
  /// else. The first draft of the Record page put it on LOW ROUND OF THE
  /// SEASON, 400pt above the Compete tab's identical flag.
  @Test func noMarkIsThePennant() {
    #expect(CSTrophyMark.Mark(rawValue: "pennant") == nil)
    #expect(!TrophyMeta.ach.values.contains { $0.glyph == "pennant" })
  }

  /// A low round carries its GROSS inside the mark — the numeral is the
  /// achievement, and the rule under it is the product's own signature.
  @Test func aLowRoundCarriesItsGross() {
    let a = Achievement(kind: "low_round", label: "Low round of the season",
                        earned_on: "2026-09-21", meta: .object(["gross": .number(74)]))
    let tile = TrophyCase.tiles(trophies: [], achievements: [a]).first
    #expect(tile?.glyph == "lowRound")
    #expect(tile?.numeral == "74")
  }
}
