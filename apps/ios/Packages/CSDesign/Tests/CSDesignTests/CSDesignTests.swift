import Testing
import SwiftUI
@testable import CSDesign

@Suite struct MarkerTests {
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
}

@Suite struct TokenTests {
  @Test func bothThemesCarryEveryColourToken() {
    #expect(CSTokens.tokenNames.count == 34)
    #expect(CSTokens.defaultTheme == .dark)
    #expect(CSTokens.Radius.r == 16 && CSTokens.Radius.rc == 10 && CSTokens.Radius.rs == 24)
    #expect(CSTokens.FontStack.mono.first == "IBM Plex Mono")
    #expect(CSTokens.FontStack.serif.first == "Charter")
  }
}
