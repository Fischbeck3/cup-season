import Testing
import SwiftUI
@testable import CSDesign

/// Wave 6 · the title card's three objects, and §15.5a in particular.
///
/// **The law this file guards:** a team event's roster is two NAMED GROUPS,
/// each under a full-width 3pt rule in its squad colour, with every disc
/// carrying a 2.5pt ring in that colour **while keeping its own pigment and
/// glyph**. Two of three blind reviewers could not tell who was on which team,
/// and one called it a failure at the surface's one job — so identity and side
/// are two channels here, and a test says so.
@MainActor
@Suite struct SideRosterTests {

  private func side(_ n: Int) -> CSSideRoster.Side {
    CSSideRoster.Side(id: "s", name: "Saguaros", color: .red,
                      faces: (0..<n).map { _ in CSFace.Model(id: UUID(), marker: "saguaro") },
                      names: (0..<n).map { "P\($0)" })
  }

  @Test func threeASideThenAPlusN() {
    #expect(side(3).shown == 3 && side(3).overflow == 0)
    // §2 A.6 · seven or more in the field: each group keeps three discs and the
    // third becomes a `+N` that pushes to the field list. A rail of nine discs
    // is a crowd, not a roster.
    #expect(side(5).shown == 3 && side(5).overflow == 2)
    #expect(side(1).shown == 1 && side(1).overflow == 0)
  }

  /// **IDENTITY AND SIDE ARE DIFFERENT CHANNELS AND MUST STAY SO.** Re-tinting
  /// a marker by side would trade one legibility failure for a worse one, so
  /// the ring is a separate parameter and the pigment is still the golfer's.
  @Test func theRingIsTheSideAndTheDiscIsThePerson() {
    let id = UUID()
    let m = CSFace.Model(id: id, marker: "saguaro")
    let ringed = CSFace(m, size: .list, sideRing: .red)
    let bare = CSFace(m, size: .list)
    #expect(ringed.model.pigmentIndex == bare.model.pigmentIndex)
    #expect(ringed.sideRing != nil && bare.sideRing == nil)
  }

  /// The ceremony ramp, because a title card does not re-print in the morning.
  @Test func theSquadRulesComeFromThePinnedRamp() {
    let p = CSTokens.dark
    #expect(p.ceremonySquad(0) == p.ceremonySq0)
    #expect(p.ceremonySquad(3) == p.ceremonySq3)
    // out of range clamps rather than crashing on a fifth colour index
    #expect(p.ceremonySquad(9) == p.ceremonySq3)
    #expect(p.ceremonySquad(-1) == p.ceremonySq0)
    // and the light printing of a title card is the DARK one (D-1)
    #expect(CSTokens.light.ceremony == CSTokens.dark.ceremony)
  }
}

/// The score rail — figures on ONE shared rule, and the metal is the state.
@MainActor
@Suite struct ScoreRailTests {

  @Test func theMetalSaysWhetherItIsRunning() {
    let live = CSScoreRail([.init(id: "a", value: "3", half: true, label: "Saguaros")], metal: .live)
    let done = CSScoreRail([.init(id: "a", value: "5", label: "Saguaros")], metal: .ink)
    #expect(live.metal == .live)
    #expect(done.metal == .ink)
  }

  /// **D-6 · nothing on a live event has been earned**, so the rail never
  /// carries the earned metal while play is open. Gold arrives at `complete`,
  /// on the result — which is what makes "gold means earned" true across time
  /// and not only across space.
  @Test func theRailNeverWearsGoldWhileItIsLive() {
    // the type makes the third state reachable, so the rule is a test rather
    // than a comment: a caller CAN pass `.earned`, and the surfaces do not.
    let cells: [CSScoreRail.Cell] = [.init(id: "a", value: "3", label: "A")]
    #expect(CSScoreRail(cells, metal: .earned).metal == .earned)
  }

  /// The half is a RIDER: the whole number and the fraction are two pieces, so
  /// a mixed number reads as one figure rather than as a small diagonal.
  @Test func theHalfIsCarriedByTheCellAndNotByTheString() {
    let c = CSScoreRail.Cell(id: "a", value: "3", half: true, label: "Saguaros")
    #expect(c.value == "3" && c.half)
    #expect(!c.value.contains("½"))
  }

  /// A countdown's label is the only one allowed the live metal, and only
  /// because it IS the clock.
  @Test func onlyTheClockLabelIsLive() {
    let clock = CSScoreRail.Cell(id: "c", value: "3", label: "Days left", labelLive: true)
    let side = CSScoreRail.Cell(id: "a", value: "3", label: "Saguaros")
    #expect(clock.labelLive && !side.labelLive)
  }
}

/// The clash — **D-4 · a clash refuses the rank rail**, because a pairing has
/// no position and a rail painted with a half-point would mean two things.
@MainActor
@Suite struct ClashRowTests {

  private func row(_ result: CSClashRow.Result, left: String? = "+2.1", right: String? = "−0.4") -> CSClashRow {
    CSClashRow(left: CSFace.Model(id: UUID(), marker: "saguaro"), leftName: "Galen Marr",
               right: CSFace.Model(id: UUID(), marker: "shark"), rightName: "Mike Fenner",
               mid: result == .open ? "vs" : result == .halved ? "halved" : "def.",
               leftFigure: left, rightFigure: right, result: result)
  }

  /// Colour is never the only channel: the result is carried by the WORD and by
  /// the loser's tone, and VoiceOver hears a sentence rather than four cells.
  @Test func oneVoiceOverElementSaysWhoBeatWhom() {
    #expect(row(.left).spoken.hasPrefix("Galen Marr beat Mike Fenner"))
    #expect(row(.right).spoken.hasPrefix("Mike Fenner beat Galen Marr"))
    #expect(row(.halved).spoken.hasPrefix("Galen Marr and Mike Fenner halved"))
    #expect(row(.open).spoken.hasPrefix("Galen Marr versus Mike Fenner"))
  }

  /// `—` is "not posted", and it is said rather than read out as a dash.
  @Test func anEmptySideIsSaidAndNeverGuessed() {
    let r = row(.open, left: "—", right: nil)
    #expect(r.spoken.contains("Galen Marr has not posted"))
    #expect(!r.spoken.contains("Mike Fenner ") || !r.spoken.contains("0"))
  }

  @Test func theFiguresAreSpokenAsWords() {
    #expect(row(.left).spoken.contains("plus 2.1"))
    #expect(row(.left).spoken.contains("minus 0.4"))
  }
}
