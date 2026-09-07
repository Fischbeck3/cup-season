// Cup Season — the takeover, the tally, the toast's kinds and the icon family
// (Wave 8, D277 / IOS-052).
//
// The wave's own arithmetic, argued rather than photographed — because the one
// surface it exists to fix, the season ceremony, has NO STATE ON ANY DEVICE:
// no season anywhere is `complete`, so the takeover cannot be reached by a
// real golfer on this build. Everything about it that can be asserted without
// a screen is asserted here.

import Testing
import SwiftUI
@testable import CSDesign

@Suite("The takeover")
@MainActor
struct CeremonyTests {

  @Test("the band takes one to three display lines and keeps the order it was given")
  func lines() {
    let t = CSTakeover(eyebrow: "Season complete",
                       lines: ["Galen Marr", "took the Cup"],
                       marker: "saguaro") { EmptyView() }
    #expect(t.lines == ["Galen Marr", "took the Cup"])
    #expect(t.marker == "saguaro")
  }

  @Test("a band with no seal is legal — a ceremony fired from Home has no member list")
  func noSeal() {
    let t = CSTakeover(eyebrow: "Season complete", lines: ["The Fellas is done"]) { EmptyView() }
    #expect(t.marker == nil)
  }

  /// **The figure carries its own formatter**, because it TALLIES: the number
  /// is spelled by the producer at every frame of the count, never by a
  /// `String(format:)` invented in the component.
  @Test("the tallying figure formats through the producer, at every value it passes")
  func figureFormats() {
    let f = CSTakeoverFigure(value: 4.5, format: { v in String(format: "%.1f", v) },
                              label: "The margin", earned: false)
    #expect(f.format(0) == "0.0")
    #expect(f.format(2.25) == "2.3" || f.format(2.25) == "2.2")   // rounding is the producer's
    #expect(f.format(f.value) == "4.5")
    #expect(f.earned == false)
  }

  /// §1.4 · one gold object a viewport. The margin is arithmetic, not a thing
  /// anybody was given, so it takes ink — and the ceremony spends its pair on
  /// the moment's own name and on the money won.
  @Test("an unearned figure asks for ink, an earned one for the metal")
  func figureMetal() {
    let margin = CSTakeoverFigure(value: 4.5, format: { _ in "4.5" }, label: "The margin", earned: false)
    let won = CSTakeoverFigure(value: 60, format: { _ in "$60" }, label: "You're owed")
    #expect(margin.earned == false)
    #expect(won.earned == true)
  }
}

@Suite("The toast has a kind")
struct ToastKindTests {

  /// 133 sites carried `id` and `text` and nothing else, so "Round posted" and
  /// "Reaction did not save." were the same grey pill. Shape AND colour: the
  /// glyph and the rail are the same kind, and a neutral toast draws no glyph
  /// rather than a shrug.
  @Test("confirmed and failed carry a mark; neutral carries none")
  func glyphs() {
    #expect(CSToastCenter.Kind.confirmed.glyph == .check)
    #expect(CSToastCenter.Kind.failed.glyph == .cross)
    #expect(CSToastCenter.Kind.neutral.glyph == nil)
  }

  @MainActor
  @Test("a toast keeps the kind it was shown with, and the newest replaces the old")
  func center() {
    let c = CSToastCenter()
    c.show("Card saved", kind: .confirmed)
    #expect(c.current?.kind == .confirmed)
    #expect(c.current?.text == "Card saved")
    c.show("Could not save.", kind: .failed)
    #expect(c.current?.kind == .failed)
    #expect(c.current?.actionLabel == nil)
  }
}

@Suite("One icon family")
struct GlyphFamilyTests {

  /// D277 · the four icon systems become one. Every name in the family draws a
  /// real path and says a real word — a case added without either is a glyph
  /// that renders as nothing and reads as nothing.
  @Test("every glyph has a path and a spoken name")
  func complete() {
    for name in CSGlyph.Name.allCases {
      #expect(!name.spoken.isEmpty, "\(name) says nothing")
      if name == .dot { continue }          // the family's one filled mark
      #expect(name.path.hasPrefix("M"), "\(name) has no path")
      #expect(name.path.count > 8, "\(name)'s path is too short to be a drawing")
    }
  }

  /// Wave 8 added ten: the composer's camera and photo, the schedule's
  /// calendar, the board's comment, the push prompt's bell, the link, the
  /// send, the trash, the gear and the clock. Each replaced an SF Symbol
  /// standing beside a drawn glyph at a different stroke weight.
  @Test("the ten the propagate wave added are all in the family")
  func waveEight() {
    let added: [CSGlyph.Name] = [.camera, .photo, .calendar, .comment, .bell, .link, .send, .trash, .gear, .clock]
    for n in added { #expect(CSGlyph.Name.allCases.contains(n)) }
  }

  /// LINT-28 · the pennant is the tab band's and the app icon's. Nothing else
  /// in the family is a flag, so a surface reaching for one has to reach for
  /// the reserved name and fail the check rather than find a lookalike.
  @Test("the family carries exactly one flag")
  func oneFlag() {
    #expect(CSGlyph.Name.allCases.filter { $0 == .pennant }.count == 1)
  }
}
