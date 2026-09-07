// Cup Season — the component vocabulary's own tests (Wave 0b, IOS-045).
//
// These assert the things that would otherwise only be true in a screenshot:
// the growth caps, the frozen marker pair, the slat's column arithmetic, and
// the fact that every one of the nine roles declares all six of the properties
// the shipped eighteen declared none of.

import Testing
import SwiftUI
@testable import CSDesign

@Suite struct TypeRoleTests {
  /// **Fourteen symbols, and no surface may name a size that is not one of
  /// them.** If this number moves, a role was added or lost and every budget in
  /// `UI_SYSTEM` §1.5 is counting a different set.
  @Test func thereAreFourteenRolesAndEachDeclaresEverything() {
    #expect(CSType.Role.allCases.count == 18, "fourteen public symbols across nine roles, plus the four size variants")
    for r in CSType.Role.allCases {
      #expect(r.size >= 11, "\(r) sets \(r.size)pt — nothing renders below the 11pt floor")
      #expect(r.leading >= 0.9 && r.leading <= 1.5, "\(r) declares no sane leading")
    }
  }

  /// The three capped roles are the three the identity rides on, and nothing
  /// else is capped: a golfer who asks for bigger type gets bigger PROSE.
  @Test func exactlyTheIdentityRolesAreCapped() {
    let capped = CSType.Role.allCases.filter { $0.cap != nil }.map(\.rawValue).sorted()
    #expect(capped == ["agate", "agateS", "display", "displayS", "figureL", "figureM", "figureXL"].sorted())
    #expect(CSType.Role.body.cap == nil && CSType.Role.story.cap == nil && CSType.Role.lead.cap == nil,
            "prose is never capped — that is the whole difference between a label and a sentence")
  }

  /// `agate`'s ×2.2 is the one Dynamic Type exception the system takes, and it
  /// is stated rather than discovered. Uncapped, `agate` reaches 33pt at AX3
  /// and §1.5's ten licensed lines then spend ~260pt of an 874pt frame on
  /// LABELS before a word of content.
  @Test func agateIsCappedAtTwoPointTwo() {
    let big = CSType.renderedSize(.agate, .accessibility5)
    #expect(big <= 12 * 2.2 + 0.01, "agate reached \(big)pt")
    #expect(big > CSType.renderedSize(.agate, .large), "agate still grows — a cap is not a freeze")
  }

  /// Every capped role reads the ENVIRONMENT's size, not the device's. Without
  /// this the capture hatch photographs the default size while claiming AX3.
  @Test func aCappedRoleGrowsWithTheEnvironmentsSize() {
    for r in CSType.Role.allCases where r.cap != nil {
      let small = CSType.renderedSize(r, .large)
      let large = CSType.renderedSize(r, .accessibility3)
      #expect(large > small, "\(r) did not grow between Large and AX3 — it is reading the device, not the environment")
    }
  }

  /// Tracking is a RATIO, and the nine values are the resolved set (D268).
  @Test func trackingIsARatioOfTheRenderedSize() {
    #expect(CSType.Role.agate.track == CSTokens.Track.agate)
    #expect(CSType.Role.agateS.track == CSTokens.Track.agateS)
    #expect(CSType.Role.name.track == CSTokens.Track.caps)
    #expect(CSType.Role.body.track == CSTokens.Track.flat)
    // the point of a ratio: the same role tracks WIDER at a bigger size
    let atLarge = CSType.renderedSize(.agate, .large) * CSType.Role.agate.track
    let atAX3 = CSType.renderedSize(.agate, .accessibility3) * CSType.Role.agate.track
    #expect(atAX3 > atLarge, "tracking did not scale — a caps line loses its letterspacing exactly where it needs it")
  }

  /// The four face strings are the ONLY `.custom(` names in the product
  /// (`LINT-01`), and they are the files' own, not the brief's.
  @Test func theFourFaceNamesAreTheFilesOwn() {
    #expect(CSType.boardSemi == "IBMPlexSansCond-SmBld")
    #expect(CSType.boardBold == "IBMPlexSansCond-Bold")
    #expect(CSType.monoRegular == "IBMPlexMono-Regular")
    #expect(CSType.monoMedium == "IBMPlexMono-Medium")
  }

  /// §1.4's fence, as data: the board face sets things that are NAMED and the
  /// serif sets things that are SAID.
  @Test func eachFamilySetsOnlyItsOwnKind() {
    #expect(CSType.Role.figureXL.family == .board && CSType.Role.name.family == .board)
    #expect(CSType.Role.body.family == .sans && CSType.Role.bodyS.family == .sans)
    #expect(CSType.Role.lead.family == .serif && CSType.Role.story.family == .serif)
    #expect(CSType.Role.column.family == .mono)
  }
}

@Suite @MainActor struct FaceTests {
  static let galen = UUID(uuidString: "6F9619FF-8B86-D011-B42D-00C04FC964FF")!

  /// **The pigment must not move between launches.** `Hashable.hashValue` in
  /// Swift is seeded per PROCESS — `pig[hash(id) % 6]` written literally would
  /// reseat a golfer every time the app cold-starts, which is exactly the drift
  /// §6.2a forbids arriving through the line that looks most like the spec.
  @Test func thePigmentIsFrozenToTheId() {
    let a = CSFace.Model(id: Self.galen, marker: "lonetree")
    let b = CSFace.Model(id: Self.galen, marker: "lonetree", photoURL: URL(string: "https://x/y.jpg"))
    #expect(a.pigmentIndex == b.pigmentIndex)
    #expect(a.pigmentIndex == 0, "the seat for this id changed — every existing golfer's coin just moved")
    // and it is the same in both printings: one identity, two printings
    #expect(a.pigment(CSTokens.dark) == CSTokens.dark.pig0)
    #expect(a.pigment(CSTokens.light) == CSTokens.light.pig0)
  }

  /// Six pigments, and the seat is spread rather than clustered.
  @Test func sixPigmentsAreAllReachable() {
    var seen = Set<Int>()
    for n in 0..<400 {
      let u = UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", n))!
      seen.insert(CSFace.Model(id: u, marker: nil).pigmentIndex)
    }
    #expect(seen == Set(0..<6), "the hash does not reach all six pigments: \(seen.sorted())")
  }

  /// The `unkeyed` path is DEBT, and debt that is deterministic is debt that
  /// can be ratcheted. Two golfers with the same marker share a seat there, and
  /// that is the whole reason `LINT-31` counts its call sites.
  @Test func theUnkeyedPathIsDeterministicAndSaysWhatItCosts() {
    let a = CSFace.Model.unkeyed(marker: "jug")
    let b = CSFace.Model.unkeyed(marker: "jug")
    let c = CSFace.Model.unkeyed(marker: "thistle")
    #expect(a.pigmentIndex == b.pigmentIndex, "the unkeyed seat is not stable")
    #expect(a.id == b.id)
    #expect(a.pigmentIndex != c.pigmentIndex || a.id != c.id)
  }

  /// **There is no initials rung.** Initials draw only when a golfer chose
  /// nothing — this was already canon and was violated on five artboards.
  @Test func initialsNeverAppearBesideAMarker() {
    let chose = CSFace.Model(id: Self.galen, marker: "azalea", initials: "TB")
    let didNot = CSFace.Model(id: Self.galen, marker: nil, initials: "TB")
    #expect(chose.marker != nil, "a golfer with a marker must draw the marker, at any size, in any component")
    #expect(didNot.marker == nil && !didNot.initials.isEmpty)
  }

  /// Five sizes, tokenised, and nothing draws a person at any other diameter.
  @Test func thereAreFiveSizes() {
    #expect(CSFace.Size.inline.rawValue == 24)
    #expect(CSFace.Size.slat.rawValue == 30)
    #expect(CSFace.Size.list.rawValue == 38)
    #expect(CSFace.Size.block.rawValue == 56)
    #expect(CSFace.Size.crest.rawValue == 120)
  }

  /// The optical fit normalises the drawn HEIGHT and centres the drawn mass —
  /// which is what makes fourteen independently-drawn glyphs read as one hand.
  /// The Saguaro runs the full 24 grid; the Azalea sits inside 14 of it.
  @Test func theOpticalFitNormalisesTheFourteen() {
    var extents: [CGFloat] = []
    for m in CSMarkers.all {
      let raw = SVGPath.path(m.path).boundingRect
      let t = CSMarkerView.opticalTransform(raw, into: 30)
      let fitted = SVGPath.path(m.path).applying(t).boundingRect
      extents.append(max(fitted.width, fitted.height))
      #expect(fitted.minX >= -0.5 && fitted.maxX <= 30.5, "\(m.key) escapes its box after the fit")
      #expect(fitted.minY >= -0.5 && fitted.maxY <= 30.5, "\(m.key) escapes its box after the fit")
    }
    let spread = (extents.max() ?? 0) - (extents.min() ?? 0)
    #expect(spread < 0.5, "the fourteen still differ by \(spread)pt after the optical fit — a column of them reads ragged")
  }
}

@Suite @MainActor struct BoardTests {
  /// **rail 44 · face 30 · s3 12 · change 58 · points 50 · gutter 20 = 214** —
  /// the number every "the rail keeps its width" claim in the surface specs
  /// rests on, and none of them carried the arithmetic.
  ///
  /// **WAVE 10 · AND THE ARITHMETIC WAS 12pt OPTIMISTIC.** The row pays `s3`
  /// TWICE — once before the face and once before the name block, which is
  /// what stops a disc touching a surname — so the real fixed total is 226 and
  /// the name column is 176 at 402 and 156 on an SE, not 188 and 161. Every
  /// surface spec that quoted 188 was quoting a column the product does not
  /// have. `fixedColumns` is kept at its documented 214 because it is cited by
  /// name in five places; `nameWidth(at:)` is the one a layout must trust, and
  /// it now also uses that measure's OWN change and points columns.
  @Test func theFixedColumnsSumToTwoHundredAndFourteen() {
    #expect(CSSlatMetrics.fixedColumns == 214)
    #expect(CSSlatMetrics.nameWidth(at: 402) == 176, "the name column at the 402 measure")
    #expect(CSSlatMetrics.nameWidth(at: 375) == 156, "the name column on an SE")
    #expect(CSSlatMetrics.nameWidth(at: 440) > CSSlatMetrics.nameWidth(at: 402),
            "the Max's extra 38pt goes to the name, not to the columns")
  }

  /// Two digits with a leading zero, centred, and never an ordinal: the rail
  /// prints `01`, so the product's one ordinal form is never needed here.
  @Test func theRailPrintsTwoDigitsWithALeadingZero() {
    #expect(CSRankRail(1, field: .earned).text == "01")
    #expect(CSRankRail(9, field: .none).text == "09")
    #expect(CSRankRail(12, field: .mine).text == "12")
  }

  /// **Per BOARD, not per row.** At ten or more every given name abbreviates,
  /// including the short ones, so the column keeps one grammar.
  @Test func abbreviationIsDecidedForTheWholeBoard() {
    #expect(CSStandingsBoard(count: 9) { _, _ in EmptyView() }.abbreviateNames == false)
    #expect(CSStandingsBoard(count: 10) { _, _ in EmptyView() }.abbreviateNames == true)
    #expect(CSStandingsBoard(count: 12) { _, _ in EmptyView() }.abbreviateNames == true)
  }

  /// One ordinal, product-wide, uppercase, on the baseline.
  @Test func theOrdinalHasOneForm() {
    #expect(CSOrdinal.suffix(1) == "ST" && CSOrdinal.suffix(2) == "ND" && CSOrdinal.suffix(3) == "RD")
    #expect(CSOrdinal.suffix(4) == "TH" && CSOrdinal.suffix(11) == "TH" && CSOrdinal.suffix(12) == "TH")
    #expect(CSOrdinal.suffix(13) == "TH" && CSOrdinal.suffix(21) == "ST" && CSOrdinal.suffix(102) == "ND")
  }

  /// Movement is shape AND colour, never colour alone, and it says what it
  /// means out loud.
  @Test func movementSpeaksAndIsNeverColourOnly() {
    #expect(CSMovement(.up(2)).spoken == "Up 2")
    #expect(CSMovement(.down(1)).spoken == "Down 1")
    #expect(CSMovement(.held).spoken == "Held")
  }

  /// The paper convention, drawn in ink and named for a screen reader.
  @Test func theScoreMarksAreThePaperConvention() {
    #expect(CSScoreMark(-2).spoken == "eagle or better")
    #expect(CSScoreMark(-1).spoken == "birdie")
    #expect(CSScoreMark(0).spoken == "par")
    #expect(CSScoreMark(1).spoken == "bogey")
    #expect(CSScoreMark(3).spoken == "double bogey or worse")
  }
}

@Suite @MainActor struct FigureRunTests {
  /// **The producer marks the run; there is no regex.** A regex over prose also
  /// restyles dates, money, ordinals and any digit inside a course name — and
  /// it rewrites the `AttributedString` runs VoiceOver reads.
  @Test func theBracesMarkTheRunAndNeverRender() {
    let run = CSFigureRun("Galen shot {74} at Papago")
    #expect(run.text == "Galen shot 74 at Papago")
    #expect(run.runs.count == 1)
    #expect(String(run.text[run.runs[0]]) == "74")
  }

  @Test func aSentenceWithNoMarkKeepsItsOwnFace() {
    let run = CSFigureRun("Nobody here has played it.")
    #expect(run.runs.isEmpty)
    #expect(run.text == "Nobody here has played it.")
  }

  @Test func twoRunsInOneSentenceBothLand() {
    let run = CSFigureRun("{74} at Papago, {9} points")
    #expect(run.text == "74 at Papago, 9 points")
    #expect(run.runs.count == 2)
  }
}

@Suite @MainActor struct StateTests {
  /// **`LINT-21` is the Swift compiler**: the door is a non-optional enum with
  /// three cases, and `.elsewhere` is what makes the requirement survivable —
  /// Home's quiet wire-empty genuinely has no door of its own.
  @Test func theDoorHasThreeCasesAndNoneOfThemIsNil() {
    let doors: [CSEmpty.Door] = [.primary("Add my round", {}), .link("Post one here", {}),
                                 .elsewhere("The four doors are at the foot of this page.")]
    #expect(doors.count == 3)
    for d in doors {
      switch d {
      case .primary(let t, _), .link(let t, _), .elsewhere(let t): #expect(!t.isEmpty)
      }
    }
  }

  /// **Two absences never share an object.** A blank scorecard means "you have
  /// no rounds"; an empty rail means "a board with nobody on it".
  @Test func everyGlyphNameIsDistinctAndSpeaks() {
    let names = CSGlyph.Name.allCases
    #expect(Set(names.map(\.spoken)).count == names.count, "two glyphs share an accessibility label")
    // and no glyph's spoken name is a retired term (TERMINOLOGY §4, LINT-27)
    for n in names {
      #expect(!n.spoken.lowercased().contains("tee sheet"), "\(n) speaks a retired noun")
      #expect(!n.spoken.lowercased().contains("tour card"), "\(n) speaks a retired noun")
    }
  }

  /// `schedule-sheet`, not "tee sheet". §4's scope explicitly covers
  /// `.accessibilityLabel`, and the glyph's name IS its label.
  @Test func theScheduleSheetIsNotATeeSheet() {
    #expect(CSGlyph.Name.scheduleSheet.spoken == "schedule sheet")
  }

  @Test func theStaleLineSaysWhenAndThatItIsOffline() {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "America/Phoenix")!
    let d = cal.date(from: DateComponents(year: 2026, month: 9, day: 4, hour: 18, minute: 12))!
    let line = CSStale.line(d, calendar: cal)
    #expect(line.contains("6:12"))
    #expect(line.lowercased().contains("offline"))
  }
}

@Suite @MainActor struct ContrastSubstitutionTests {
  /// Increase Contrast is resolved once, in the theme, not at 400 call sites.
  /// The two substitutions are the two that matter: the metadata voice steps up
  /// to ink, and the one hairline steps up to the metadata voice.
  @Test func increasedContrastLiftsTheRuleAndTheMutedVoice() {
    for base in [CSTokens.dark, CSTokens.light] {
      let hi = base.increasedContrast
      #expect(hi.rule == base.mut, "the rule did not step up")
      #expect(hi.bg0 == base.bg0 && hi.bg1 == base.bg1, "the ground must not move — a printing is not a repaint")
      #expect(hi.gold == base.gold && hi.brand == base.brand, "the metals do not move")
    }
  }
}

@Suite @MainActor struct BudgetProbeTests {
  /// The probe counts a viewport, and it names its breaches in the lint's own
  /// words so a console line is greppable against `UI_SYSTEM` §17.
  @Test func theBudgetNamesEveryLineItBreaks() {
    var b = CSBudget()
    #expect(b.breaches.isEmpty)
    b.agateCapsLines = 11; b.display = 2; b.goldObjects = 2; b.emberMarks = 3; b.nestedContainers = 1
    let lines = b.breaches.joined(separator: " ")
    for id in ["LINT-15", "LINT-16", "LINT-17", "LINT-18", "LINT-08"] {
      #expect(lines.contains(id), "the probe does not report \(id)")
    }
  }

  @Test func theBudgetsAreTheNumbersTheSystemStates() {
    var b = CSBudget()
    b.agateCapsLines = 10; b.display = 1; b.goldObjects = 1; b.emberMarks = 2
    #expect(b.breaches.isEmpty, "ten agate lines, one display, one gold object and two ember marks are the budgets, not the breaches")
  }
}

// MARK: - The season board (Wave 5, `surfaces/season.md` §1.2, §1.4)

/// **`@MainActor`, and it is load-bearing.** `CSSeasonCalendar` is a `View`, so
/// its nested `Month` and its static `spread` inherit main-actor isolation, and
/// reaching them from a non-isolated test hits `_swift_task_checkIsolatedSwift`
/// and SIGTRAPs — which in the log reads as the whole bundle crashing with
/// "signal trap" and names two unrelated suites as the failures. Wave 3 met
/// this on `CSRecordLeaf` and left the note; this is the same trap.
@MainActor
@Suite struct SeasonBoardComponentTests {
  /// The legacy call spreads bare month names as evenly as it can, remainder
  /// to the earliest — the same shape `PotMath.splitCents` gives money — and
  /// the weeks always sum to the season.
  @Test func theCalendarSpreadsWeeksAndNeverLosesOne() {
    let m = CSSeasonCalendar.spread(["Aug", "Sep", "Oct"], over: 13)
    #expect(m.map(\.weeks) == [5, 4, 4])
    #expect(m.reduce(0) { $0 + $1.weeks } == 13)
    #expect(CSSeasonCalendar.spread([], over: 13).isEmpty)
  }

  /// The ticks are laid out from each group's own first week, so the live cell
  /// lands on the week the season says it is — the bug this replaces drew
  /// every month at an equal share of the row.
  @Test func eachMonthGroupStartsWhereTheLastOneEnded() {
    let c = CSSeasonCalendar(weeks: 13, played: 4, now: 4,
                             months: [.init(label: "Aug", weeks: 4),
                                      .init(label: "Sep", weeks: 5, note: "25 days", live: true),
                                      .init(label: "Oct", weeks: 4)])
    #expect(c.starts == [0, 4, 9])
  }

  /// A complete season passes `now: -1`: **nothing is live, so nothing is
  /// ember**, and the calendar says so rather than pointing at a week.
  @Test func aCompleteSeasonHasNoLiveCell() {
    let c = CSSeasonCalendar(weeks: 13, played: 13, now: -1, months: [.init(label: "Aug", weeks: 13)])
    #expect(c.spoken == "13 weeks, all played")
    let live = CSSeasonCalendar(weeks: 13, played: 4, now: 4, months: [.init(label: "Aug", weeks: 13)])
    #expect(live.spoken == "Week 5 of 13, the live week")
  }
}
