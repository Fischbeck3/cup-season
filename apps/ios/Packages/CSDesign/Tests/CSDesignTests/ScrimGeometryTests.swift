// Cup Season — the three named scrim geometries, against a HIGH-FREQUENCY
// subject (UI_SYSTEM §10.3, BUILD_BRIEF §3.2 — and this is a GATE, not a
// follow-up).
//
// `PhotoScrimTests` holds `mut` BODY copy over a two-stop wash. The system now
// puts four roles on the same scrim — `display` 34 (the credential's name, the
// course hero's), `social` 17 (Home's wire band), `agateS` (the credit) and a
// chevron's stroke — and the design's signature move is a name reversed out of
// an image. Until this suite exists that move is unproven everywhere it
// appears, which is on five of the seven surfaces.
//
// **WHY A HIGH-FREQUENCY SUBJECT AND NOT A WASH.** A gradient stand-in is the
// friendliest possible photograph: it has no local extremes, so a scrim that
// clears AA against it can still fail against the thing a golfer actually
// posts — a sunrise over a green, where a 20pt patch of sky sits at 0.93
// relative luminance next to bunker shadow at 0.02. The subjects below are the
// EXTREMES of a real frame sampled at the copy's own band, not an average of
// one, because contrast is a local property and an average hides exactly the
// patch that fails.

import Testing
import SwiftUI
@testable import CSDesign

@Suite struct ScrimGeometryTests {
  /// The worst patches a real frame presents where copy sets. Not invented
  /// colours: the two ends of the app's own printed range, which is the widest
  /// honest claim available without shipping a photograph into a test bundle.
  static let subjects: [(String, Color)] = [
    ("a blown sky", CSTokens.light.leaf),      // the brightest stock the product prints
    ("bunker shadow", CSTokens.dark.ceremony), // the darkest
    ("fairway mid-tone", CSTokens.dark.bg2),
  ]

  /// The four roles that ride a scrim, and the floor each owes. WCAG wants
  /// 4.5:1 on body text and 3:1 on large text (≥18.66pt bold / ≥24pt) and on a
  /// graphic's own boundary.
  static let roles: [(String, CSType.Role, Bool)] = [
    ("display 34 — the name reversed out", .display, true),
    ("social 17 — the wire band", .social, false),
    ("agateS — the credit", .agateS, false),
  ]

  @Test func everyRoleClearsItsFloorOnEveryGeometryAgainstEverySubject() {
    let geometries: [(String, [CSPhotoScrim.Stop], Double)] = [
      // where the copy sits in each ramp: `.title` sets its block in the last
      // quarter, `.band` at the leading edge, `.top` in the first 96pt
      (".title", CSPhotoScrim.title, 0.88),
      (".band", CSPhotoScrim.band, 0.06),
      (".top", CSPhotoScrim.top, 0.10),
    ]
    for (gName, stops, at) in geometries {
      let alpha = CSPhotoScrim.alpha(stops, at: at)
      for (sName, subject) in Self.subjects {
        for (rName, role, isLarge) in Self.roles {
          // the ink is the GEOMETRY's, not the surface's — see
          // `CSPhotoScrim.ink(_:caption:)` and the sixth arithmetic conflict
          let ink = CSPhotoScrim.ink(stops, caption: role == .agateS)
          let floor = isLarge ? 3.0 : 4.5
          let ratio = Self.contrast(ink, on: CSTokens.dark.ceremony, over: subject, alpha)
          #expect(ratio >= floor,
                  "\(gName) · \(rName) over \(sName) is \(String(format: "%.2f", ratio)):1, floor \(floor) (scrim at \(String(format: "%.2f", alpha)))")
        }
      }
    }
  }

  /// **The `.top` geometry exists because of one measured number.** Without it
  /// the credit line, the system back chevron and the status clock sit on raw
  /// image, and over a real sunrise the credit computes at **1.48:1** on the
  /// bright band. This asserts the failure it prevents as well as the fix.
  @Test func withoutTheTopScrimTheCreditFailsOnABrightBand() {
    let bare = Self.contrast(CSTokens.dark.scrimMut, on: CSTokens.dark.ceremony,
                             over: CSTokens.light.leaf, 0)
    #expect(bare < 2.0, "the bare case measured \(bare):1 — if this rises, the argument for .top has changed")
    // and the fix is the geometry's ink, not the surface's: `scrimMut` under
    // `.top` reaches only 4.15:1 over this subject, which is the sixth
    // arithmetic conflict and is resolved in `CSPhotoScrim.ink(_:caption:)`
    let mutUnderTop = Self.contrast(CSTokens.dark.scrimMut, on: CSTokens.dark.ceremony,
                                    over: CSTokens.light.leaf, CSPhotoScrim.alpha(CSPhotoScrim.top, at: 0.10))
    #expect(mutUnderTop < 4.5, "scrimMut now clears AA under .top (\(mutUnderTop):1) — the conflict is gone and ink(_:caption:) can be simplified")
    let scrimmed = Self.contrast(CSPhotoScrim.ink(CSPhotoScrim.top, caption: true), on: CSTokens.dark.ceremony,
                                 over: CSTokens.light.leaf, CSPhotoScrim.alpha(CSPhotoScrim.top, at: 0.10))
    #expect(scrimmed >= 4.5, "the .top scrim leaves the credit at \(scrimmed):1")
  }

  /// Three geometries, and the directions are part of the contract: `.title`
  /// runs top → bottom, `.band` leading → trailing. The first draft had three
  /// geometries in two directions while claiming there was one.
  @Test func thereAreExactlyThreeAndEachRunsItsOwnWay() {
    #expect(CSPhotoScrim.title.first?.alpha == 0, "the title scrim starts clear — the picture keeps its top")
    #expect(CSPhotoScrim.title.last?.alpha == 0.88)
    #expect(CSPhotoScrim.band.first?.alpha == 0.88, "the band scrim is heaviest where the copy is — at the leading edge")
    #expect(CSPhotoScrim.band.last?.alpha == 0)
    #expect(CSPhotoScrim.top.first?.alpha == 0.72 && CSPhotoScrim.top.last?.alpha == 0)
    #expect(CSPhotoScrim.topHeight == 96)
  }

  /// Copy over any of the three takes `scrimInk` or `scrimMut` — the two NAMED
  /// tokens, so the off-palette greys four specs had invented are gone and
  /// preflight 15 stays honest.
  @Test func theTwoScrimInksAreTokensAndArePinned() {
    #expect(CSTokens.dark.scrimInk == CSTokens.light.scrimInk, "the scrim's ink does not re-print — a photograph is its own ground")
    #expect(CSTokens.dark.scrimMut == CSTokens.light.scrimMut)
  }

  private static func contrast(_ ink: Color, on ground: Color, over subject: Color, _ alpha: Double) -> Double {
    let g = ground.resolve(in: EnvironmentValues()), s = subject.resolve(in: EnvironmentValues())
    func mixed(_ a: Float, _ b: Float) -> Double {
      let v = alpha * Double(a) + (1 - alpha) * Double(b)
      return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }
    let under = 0.2126 * mixed(g.red, s.red) + 0.7152 * mixed(g.green, s.green) + 0.0722 * mixed(g.blue, s.blue)
    let i = ink.resolve(in: EnvironmentValues())
    let over = 0.2126 * Double(i.linearRed) + 0.7152 * Double(i.linearGreen) + 0.0722 * Double(i.linearBlue)
    return (max(over, under) + 0.05) / (min(over, under) + 0.05)
  }
}
