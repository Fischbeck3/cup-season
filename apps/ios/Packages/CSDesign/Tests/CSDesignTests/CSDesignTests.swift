import Testing
import SwiftUI
@testable import CSDesign

// `CSMarkerView` and `CSFace` declare `: View`, which is `@MainActor
// @preconcurrency` — global-actor inference makes both structs (initializers
// and stored properties included) main-actor isolated, and Swift 6 language
// mode refuses to touch them from a nonisolated test. The Kit's own answer is
// the same one: `@Suite @MainActor struct LeagueRoomModelTests`.
@Suite @MainActor struct MarkerTests {
  @Test func allFourteenMarkersParseToNonEmptyPaths() {
    #expect(CSMarkers.all.count == 14)
    for m in CSMarkers.all {
      let p = SVGPath.path(m.path)
      #expect(!p.isEmpty, "\(m.key) drew nothing")
      let b = p.boundingRect
      #expect(b.width > 0 && b.height > 0, "\(m.key) has no extent")
      // every glyph lives on the 24×24 grid the web draws it on
      #expect(b.minX >= -1 && b.maxX <= 25 && b.minY >= -1 && b.maxY <= 25, "\(m.key) escapes the grid: \(b)")
    }
  }

  @Test func unknownKeyIsTheSaguaro() {
    #expect(CSMarkers.marker("nope").key == "saguaro")
    #expect(CSMarkers.marker(nil).key == "saguaro")
  }

  @Test func arcCommandDrawsTheAzaleaDot() {
    // the only glyph with arcs; a 1.2-radius circle at (12,12)
    let azalea = CSMarkers.byKey["azalea"]!
    let p = SVGPath.path("M13.2 12a1.2 1.2 0 11-2.4 0 1.2 1.2 0 012.4 0")
    let b = p.boundingRect
    #expect(abs(b.midX - 12) < 0.05 && abs(b.midY - 12) < 0.05, "circle centre off: \(b)")
    #expect(abs(b.width - 2.4) < 0.1, "circle diameter off: \(b.width)")
    #expect(azalea.path.contains("a1.2"))
  }

  // Y-33 · a marker beside a name is silent; a face speaks the person, never the marker
  @Test func aMarkerIsSilentUnlessItStandsAlone() {
    #expect(CSMarkerView(key: "azalea").labelled == false)
    #expect(CSMarkerView(key: "azalea", labelled: true).marker.name == CSMarkers.marker("azalea").name)
    #expect(CSFace(marker: "azalea").name == nil)
    #expect(CSFace(marker: "azalea", name: "Maya").name == "Maya")
  }
}

@Suite struct TokenTests {
  @Test func bothThemesCarryEveryColourToken() {
    #expect(CSTokens.tokenNames.count == 34)
    #expect(CSTokens.defaultTheme == .dark)
    #expect(CSTokens.Radius.r == 16 && CSTokens.Radius.rc == 10 && CSTokens.Radius.rs == 24)
    #expect(CSTokens.FontStack.mono.first == "IBM Plex Mono")
    #expect(CSTokens.FontStack.serif.first == "Charter")
  }

  /// D211 / Y-32 · the light ink metals and semantics clear WCAG AA (4.5:1)
  /// on BOTH light surfaces, not just the page. Gold sat at 3.53:1 on `bg2`,
  /// pos at 2.96:1, before the shades moved; this holds them there.
  @Test func lightGoldBrandPosNegClearAAOnBothSurfaces() {
    let cs = CSTokens.light
    let inks: [(String, Color)] = [("gold", cs.gold), ("brand", cs.brand), ("pos", cs.pos), ("neg", cs.neg)]
    let grounds: [(String, Color)] = [("bg1", cs.bg1), ("bg2", cs.bg2)]
    for (ink, c) in inks {
      for (ground, g) in grounds {
        let ratio = Self.contrast(c, g)
        #expect(ratio >= 4.5, "light \(ink) on \(ground) is \(ratio):1")
      }
    }
  }

  /// WCAG 2 relative luminance from the resolved LINEAR components.
  private static func luminance(_ c: Color) -> Double {
    let r = c.resolve(in: EnvironmentValues())
    return 0.2126 * Double(r.linearRed) + 0.7152 * Double(r.linearGreen) + 0.0722 * Double(r.linearBlue)
  }

  private static func contrast(_ a: Color, _ b: Color) -> Double {
    let (la, lb) = (luminance(a), luminance(b))
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
  }
}

/// D202b · copy over a photograph (`CSPhotoScrim`).
@Suite struct PhotoScrimTests {
  /// The credential's smallest line is footnote `mut` riding a photograph,
  /// and a photograph can be ANY tone — so the two subjects that fight the
  /// ink are one as bright as paper and one as dark as dusk. (Those are the
  /// palettes' own grounds, used as stand-in subjects: a photograph brighter
  /// than `light.bg1` or darker than `dark.bg0` is off the end of the app's
  /// own range, and no colour is invented to test one.) The settle and the
  /// plate together have to clear AA on either subject, in either palette.
  /// Lighten a ramp without re-measuring and this is what says so.
  ///
  /// Measured on the simulator too, not only asserted here: the same pair
  /// took the `-cs_dev_cred photo` fixture's worst patch from 3.54:1 to
  /// 4.79:1 in charcoal, and the real You hero's from 4.23:1 to 5.18:1.
  @Test func theSmallestLineOverAnyPhotographClearsAA() {
    let ground = CSPhotoScrim.groundUnderCopy
    #expect(ground > 0.9, "the two layers leave only \(ground) of the card's own ground under the copy")
    let subjects: [(String, Color)] = [("a subject as bright as paper", CSTokens.light.bg1),
                                       ("a subject as dark as dusk", CSTokens.dark.bg0)]
    for (theme, p) in [("charcoal", CSTokens.dark), ("paper", CSTokens.light)] {
      for (subject, s) in subjects {
        let ratio = Self.contrast(p.mut, on: p.bg1, over: s, ground)
        #expect(ratio >= 4.5, "\(theme) mut over \(subject) is \(ratio):1")
      }
    }
  }

  /// A ramp is read the way `LinearGradient` draws it — flat outside its own
  /// ends, linear between its stops. The plate does nearly nothing where the
  /// name is and most of its work in the last third, which is the whole
  /// reason it costs the photograph a strip and not a third.
  @Test func theRampsReadTheWayTheyAreDrawn() {
    #expect(CSPhotoScrim.alpha(CSPhotoScrim.plateRamp, at: 0) == 0)
    #expect(CSPhotoScrim.alpha(CSPhotoScrim.plateRamp, at: 1) == 0.70)
    #expect(CSPhotoScrim.alpha(CSPhotoScrim.plateRamp, at: 1.4) == 0.70)
    // the name's own band: the picture, not the plate
    #expect(CSPhotoScrim.alpha(CSPhotoScrim.plateRamp, at: 0.2) < 0.06)
    // half way down, half way between the 0.32 and 0.64 stops
    #expect(abs(CSPhotoScrim.alpha(CSPhotoScrim.plateRamp, at: 0.48) - 0.22) < 0.0001)
    // the settle never runs to full — the seam keeps a whisper of photograph
    #expect(CSPhotoScrim.alpha(CSPhotoScrim.settleRamp, at: 1) == 0.92)
  }

  /// `ink` against `ground` laid over `subject` at `alpha`. The blend is done
  /// in sRGB, which is where the compositor does it and what a screenshot
  /// measures; the luminance is then WCAG 2's, off the linearised composite.
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
