// Cup Season — the credential and the contour (Wave 2, IOS-047).
//
// The object's arithmetic, argued in clauses rather than photographed: the
// figure cap, the rule that fits its own cells, and the contour's promise that
// one course draws one plot forever.

import Testing
import SwiftUI
@testable import CSDesign

@Suite("The credential")
struct CredentialTests {

  @Test("the strip takes at most three figures, and a fourth is dropped rather than crammed")
  func figureCap() {
    let g = CSCredentialGolfer(
      face: .init(id: UUID(), marker: "saguaro"), name: "Galen Marr", identity: "@galenm",
      figures: [.init("10.2", label: "Handicap index"), .init("31", label: "Rounds"),
                .init("1", label: "The Fellas", ordinal: "ST"), .init("74", label: "Best")],
      club: "Cup Season · The Saguaro")
    #expect(g.figures.count == 3)
    #expect(g.figures.last?.label == "The Fellas")
  }

  @Test("a slot with no figure is ABSENT — never a dash, never a zero")
  func absentSlots() {
    let g = CSCredentialGolfer(
      face: .init(id: UUID(), marker: nil), name: "Tash Bell", identity: "@tashb",
      figures: [.init("2", label: "Rounds")], club: "Cup Season · The Thistle")
    #expect(g.figures.count == 1)
    #expect(!g.figures.contains { $0.value == "—" || $0.value.isEmpty })
  }

  @Test("the serial degrades: the product owns the marker's name and not a card number")
  func serialDegrades() {
    let g = CSCredentialGolfer(face: .init(id: UUID(), marker: "saguaro"), name: "A", identity: "",
                               figures: [], club: "Cup Season")
    #expect(g.serial == nil)
  }

  @Test("the object is 7:6 landscape, and the 3:4 portrait exists only for the share PNG")
  func ratios() {
    #expect(abs(CSCredential<Color>.Presentation.hero.ratio - 362.0 / 312.0) < 0.001)
    #expect(abs(CSCredential<Color>.Presentation.sharePNG.ratio - 362.0 / 483.0) < 0.001)
    // a 3:4 object at the 362pt measure is 483pt tall, which is the whole
    // reason the hero is landscape
    #expect(362.0 / CSCredential<Color>.Presentation.sharePNG.ratio > 480)
  }
}

@Suite("The contour")
struct ContourTests {

  @Test("same seed, same plot — forever, and across processes")
  func deterministic() {
    let a = CSContour.field(seed: "papago-golf-course")
    let b = CSContour.field(seed: "papago-golf-course")
    #expect(a == b)
    // FNV-1a, not `hashValue`: Swift seeds `Hashable` PER PROCESS, so the
    // literal reading of the spec would have given one course two plots in one
    // day. This asserts the value, not merely the equality of two calls in one
    // process — a per-process seed passes the equality test and fails this one.
    #expect(abs(CSContour.hash01("papago-golf-course", 2, 3) - 0.4756) < 0.0002)
  }

  @Test("two courses draw two places")
  func distinct() {
    let a = CSContour.field(seed: "papago-golf-course")
    let b = CSContour.field(seed: "troon-north")
    let differing = zip(a, b).filter { abs($0 - $1) > 0.05 }.count
    // a noise field, not six concentric circles: most of the grid must differ
    #expect(differing > a.count / 2)
  }

  @Test("the field stays inside 0...1, so every isolevel is reachable")
  func bounded() {
    let f = CSContour.field(seed: "any-course-at-all")
    #expect(f.allSatisfy { $0 >= 0 && $0 <= 1 })
    #expect(f.count == CSContour.grid * CSContour.grid)
  }

  @Test("an isoline is drawn where the field crosses it, and nowhere else")
  func marchingSquares() {
    // a field entirely below the level has no crossing at all
    var path = Path()
    CSContour.isoline([Double](repeating: 0.1, count: CSContour.grid * CSContour.grid),
                      level: 0.5, into: &path)
    #expect(path.isEmpty)
    // the real field crosses every level the plate draws
    var drawn = Path()
    CSContour.isoline(CSContour.field(seed: "papago-golf-course"), level: 0.5, into: &drawn)
    #expect(!drawn.isEmpty)
  }

  @Test("the hardest hole lands on the plate, not off it")
  func holeInside() {
    for seed in ["papago", "troon-north", "gold-canyon", "the-boulders"] {
      let p = CSContour.hardestHole(seed: seed)
      #expect(p.x > 0.2 && p.x < 0.75)
      #expect(p.y > 0.2 && p.y < 0.72)
    }
  }
}
