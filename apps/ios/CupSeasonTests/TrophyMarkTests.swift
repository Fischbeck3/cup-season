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
import Foundation
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

/// D291 · **the three shelves.** The case was eleven identical 50pt slats in
/// which a Cup sat at exactly the weight of *"Posted"*; the shelf is the whole
/// of the hierarchy, and its rule is shared verbatim with the desk's
/// `csTrophyShelf` (`tests/trophycase.test.mjs` holds the other half).
@Suite struct TrophyShelfTests {

  private func ach(_ kind: String, meta: JSONValue? = nil, on: String? = "2026-08-24",
                   round: UUID? = nil) -> Achievement {
    Achievement(kind: kind, label: kind, earned_on: on, meta: meta, round_id: round)
  }

  @Test func everyTrophyRowIsHardware() {
    #expect(TrophyMeta.shelf(kind: "league", isHardware: true) == .hardware)
    #expect(TrophyMeta.shelf(kind: "ryder", isHardware: true) == .hardware)
    // and the same kind arriving as an ACHIEVEMENT is not hardware — the row's
    // table decides the shelf, never its `kind` string.
    #expect(TrophyMeta.shelf(kind: "league", isHardware: false) == .along)
  }

  @Test func aNumberYouBeatIsABest() {
    for k in ["sub_100", "sub_90", "sub_80", "personal_best", "low_round", "most_improved"] {
      #expect(TrophyMeta.shelf(kind: k, isHardware: false) == .bests, "\(k)")
    }
  }

  @Test func turningUpIsAlongTheWay() {
    for k in ["first_round", "streak_4", "streak_8", "streak_12"] {
      #expect(TrophyMeta.shelf(kind: k, isHardware: false) == .along, "\(k)")
    }
  }

  /// **An unknown kind is QUIET, never loud.** A migration that mints a kind
  /// this build has never heard of must not put it above the Cup.
  @Test func anUnknownKindFallsToTheQuietShelf() {
    #expect(TrophyMeta.shelf(kind: "grand_slam_2031", isHardware: false) == .along)
    #expect(TrophyMeta.shelf(kind: nil, isHardware: false) == .along)
  }

  @Test func threeSizesAndThreeHeads() {
    #expect(TrophyShelf.hardware.mark == 44)
    #expect(TrophyShelf.bests.mark == 28)
    #expect(TrophyShelf.along.mark == 28)
    #expect(TrophyShelf.allCases.map(\.head) == ["Hardware", "Bests", "Along the way"])
    #expect(TrophyShelf.hardware.rank < TrophyShelf.bests.rank)
    #expect(TrophyShelf.bests.rank < TrophyShelf.along.rank)
  }

  /// An empty shelf is ABSENT — a head over nothing is a heading that lies
  /// about what is under it.
  @Test func anEmptyShelfDoesNotPrint() {
    let tiles = TrophyCase.tiles(trophies: [], achievements: [ach("sub_80", meta: .object(["gross": .number(79)]))])
    let shelves = TrophyCase.shelves(tiles)
    #expect(shelves.count == 1)
    #expect(shelves.first?.shelf == .bests)
  }

  /// And what does print, prints in the shelves' own order — hardware first.
  @Test func theShelvesPrintInOrder() {
    let tiles = TrophyCase.tiles(trophies: [], achievements: [ach("first_round"), ach("sub_80")])
    #expect(TrophyCase.shelves(tiles).map(\.shelf) == [.bests, .along])
  }

  // MARK: - the BESTS sub-line, verbatim with `csMilestoneSub`

  @Test func aBestNamesTheRoundItWasWonOn() {
    let rid = UUID()
    let tiles = TrophyCase.tiles(trophies: [],
      achievements: [ach("sub_80", meta: .object(["gross": .number(79)]), round: rid)],
      round: { _ in MilestoneRound(gross: 79, courseLabel: "Papago", playedOn: "2026-08-24") })
    #expect(tiles.first?.sub == "79 at Papago · Aug 24")
    #expect(tiles.first?.roundId == rid)
  }

  /// THE DEGRADE IS THE POINT. `Career.recent` is five rounds, so most
  /// milestones have no round in hand and keep their figure and their date.
  @Test func noRoundInHandKeepsTheFigureAndTheDate() {
    let tiles = TrophyCase.tiles(trophies: [], achievements: [ach("sub_80", meta: .object(["gross": .number(79)]))])
    #expect(tiles.first?.sub == "79 · Aug 24")
  }

  /// Never the label: the slat's own title already reads BROKE 80.
  @Test func noFigureLeavesTheDateAlone() {
    #expect(TrophyMeta.milestoneSub(kind: "sub_80", label: "Broke 80", meta: nil,
                                    earnedOn: "2026-08-24", round: nil) == "Aug 24")
    #expect(TrophyMeta.milestoneSub(kind: "sub_80", label: "Broke 80", meta: nil,
                                    earnedOn: nil, round: nil) == "")
  }

  /// **A milestone prints the figure it is ABOUT.** Taking the round's gross
  /// for both put the identical sentence under BROKE 80 and PERSONAL BEST
  /// whenever one round earned them together — the owner's own complaint,
  /// arriving inside the fix for it.
  @Test func aPersonalBestKeepsTheHouseNameForItsFigure() {
    #expect(TrophyMeta.milestoneSub(kind: "personal_best", label: nil, meta: .object(["diff": .number(4.1)]),
                                    earnedOn: "2026-08-24", round: nil) == "4.1 vs course · Aug 24")
    let round = MilestoneRound(gross: 79, courseLabel: "Papago", playedOn: "2026-08-24")
    #expect(TrophyMeta.milestoneSub(kind: "personal_best", label: nil, meta: .object(["diff": .number(4.1)]),
                                    earnedOn: "2026-08-24", round: round) == "4.1 vs course · Papago · Aug 24")
    #expect(TrophyMeta.milestoneSub(kind: "sub_80", label: nil, meta: .object(["gross": .number(79)]),
                                    earnedOn: "2026-08-24", round: round) == "79 at Papago · Aug 24")
  }

  /// The round outranks the snapshot: the meta's gross is what was written
  /// the day it fired, the round is the row as it stands.
  @Test func theRoundOutranksTheSnapshot() {
    #expect(TrophyMeta.milestoneSub(kind: "sub_80", label: nil, meta: .object(["gross": .number(79)]),
                                    earnedOn: "2026-08-24",
                                    round: MilestoneRound(gross: 78, courseLabel: nil, playedOn: "2026-08-20"))
            == "78 · Aug 20")
  }

  /// The quiet shelf keeps the dated line it has always had — `Posted · '26`
  /// is the whole of that fact, and it is not a round anybody opens.
  @Test func theQuietShelfKeepsItsDatedLine() {
    let tiles = TrophyCase.tiles(trophies: [], achievements: [ach("first_round", meta: .object(["gross": .number(101)]))])
    #expect(tiles.first?.sub == "Posted · '26")
    #expect(tiles.first?.shelf == .along)
  }

  /// D291 · the year came OUT of the hardware sub-line and into its own
  /// right-flush slot, so the line reads `Fellas · beat Galen Marr` and the
  /// year sits where §16A.2's slot always was.
  @Test func hardwareCarriesItsYearInTheTrailingSlot() {
    #expect(TrophyMeta.yearTrail(seasonYear: 2025) == "’25")
    #expect(TrophyMeta.yearTrail(seasonYear: nil) == nil)
  }

  /// §17 · the empty is four marks the case really draws, at 12% — never four
  /// placeholder boxes, and never a card with a grey sentence in it.
  @Test func theEmptyIsFourRealMarks() {
    #expect(TrophyCase.emptyMarks.count == 4)
    for m in TrophyCase.emptyMarks {
      #expect(CSTrophyMark.Mark(rawValue: m.glyph) != nil, "no drawn mark for \(m.glyph)")
      #expect(m.glyph != "medal")
    }
    #expect(!TrophyCase.emptyLead.contains("⊕"))
  }
}
