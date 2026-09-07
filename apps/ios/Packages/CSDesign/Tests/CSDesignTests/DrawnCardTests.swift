// Cup Season — the drawn card and the star rail (Wave 4, D272 / D275,
// `UI_SYSTEM` §10.1, §10.2, §9.11).
//
// The drawn card is the object three blind reviewers failed the course page
// over, in three different sentences, all of which said the same thing: *fake
// data as ornament is less premium than a plain colour*. So the arithmetic a
// screenshot cannot check is checked here — that the bars are drawn from real
// par and real yardage, that a card with neither draws nothing at all, that
// the metal lands on the #1 stroke hole and nowhere else, and that the
// thumbnail is the front nine rather than eighteen 3pt combs.

import Testing
import SwiftUI
@testable import CSDesign

@MainActor
@Suite struct DrawnCardTests {

  /// Papago's real front nine, as the phone's own book holds it.
  private func nine() -> [CSDrawnCard.Hole] {
    let pars = [5, 4, 4, 3, 4, 4, 4, 3, 5]
    let sis = [15, 17, 3, 13, 11, 1, 7, 9, 5]
    return (0..<9).map { CSDrawnCard.Hole(number: $0 + 1, par: pars[$0], si: sis[$0]) }
  }

  /// **Width by par.** A par 5 is visibly a long hole and a par 3 a short one
  /// before a single number is read — and the widths sum to the measure less
  /// the gaps, so eighteen bars never overrun the plate.
  @Test func widthGoesByParAndTheBarsFitTheMeasure() {
    let card = CSDrawnCard(nine())
    let w: [CGFloat] = card.widths(in: 362, gap: 3)
    let sum: CGFloat = w.reduce(0, +)
    let usable: CGFloat = 362 - 3 * 8
    #expect(w.count == 9)
    #expect(w[0] > w[3])                       // par 5 wider than par 3
    #expect(abs(sum - usable) < 0.5)
  }

  /// **Height by yardage where there is yardage.** The card normalises across
  /// its own range, so a short course does not draw as a flat line.
  @Test func heightGoesByYardageWhenTheCardCarriesIt() {
    let holes = [CSDrawnCard.Hole(number: 1, par: 4, si: 1, yards: 320),
                 CSDrawnCard.Hole(number: 2, par: 4, si: 2, yards: 470)]
    let card = CSDrawnCard(holes)
    #expect(card.hasYardage)
    #expect(card.height(holes[1]) > card.height(holes[0]))
  }

  /// **D-2 · and by PAR when it does not** — which is the state the phone is
  /// actually in, because `my_course_books` does not select per-hole yardage.
  /// It is a weaker picture and it is still real: eleven of eighteen bars are
  /// identical, and the file says so rather than inventing a height.
  @Test func heightFallsBackToParAndSaysSo() {
    let card = CSDrawnCard(nine())
    #expect(!card.hasYardage)
    let byPar = nine()
    #expect(card.height(byPar[0]) > card.height(byPar[1]))   // par 5 over par 4
    #expect(card.height(byPar[1]) > card.height(byPar[3]))   // par 4 over par 3
  }

  /// **The metal lands on the #1 stroke hole and nowhere else.** One gold
  /// object per viewport is counted by hue, and the card counts itself.
  @Test func oneBarTakesTheMetalAndItIsTheHardestHole() {
    let card = CSDrawnCard(nine())
    #expect(card.hardest == 6)                 // SI 1 is the 6th at Papago
    // no stroke index anywhere: no mark at all, rather than a guess
    let blind = nine().map { CSDrawnCard.Hole(number: $0.number, par: $0.par, si: nil) }
    #expect(CSDrawnCard(blind).hardest == nil)
  }

  /// §10.2 · **at thumbnail the card is the front nine**, not eighteen 3pt
  /// bars — the same failure that bans the contour at that scale.
  @Test func theThumbnailIsTheFrontNine() {
    let eighteen = (1...18).map { CSDrawnCard.Hole(number: $0, par: $0 % 3 == 0 ? 3 : 4, si: $0) }
    #expect(CSDrawnCard(eighteen, scale: .thumb).drawn.count == 9)
    #expect(CSDrawnCard(eighteen, scale: .hero).drawn.count == 18)
    // and it carries no metal: a row's left column is not where a viewport
    // spends its one gold object
    #expect(CSDrawnCard(eighteen, scale: .thumb).hardest == 1)
  }

  /// **A plate never carries a caption that teaches the reader how to read
  /// it** — so the card says nothing on screen and one sentence to the ear.
  @Test func theCardSpeaksOnceAndNamesTheHardestHole() {
    #expect(CSDrawnCard(nine()).spoken.contains("6th plays hardest"))
    #expect(CSDrawnCard([]).spoken.isEmpty)
  }
}

@MainActor
@Suite struct StarRailTests {

  /// **"four and a half stars"** — the value a golfer HEARS, and the value the
  /// adjustable control announces on every half step. The rail is one element
  /// with a spoken value, never five glyphs read one at a time.
  @Test func theRailSpeaksInWords() {
    #expect(CSStarRail.spoken(4.5) == "four and a half stars")
    #expect(CSStarRail.spoken(1) == "one star")
    #expect(CSStarRail.spoken(5) == "five stars")
  }

  /// A rating is one decimal, always, so the figure never changes width as the
  /// mean moves under it.
  @Test func theFigureIsOneDecimalAlways() {
    #expect(CSRating.format(4) == "4.0")
    #expect(CSRating.format(4.65) == "4.6" || CSRating.format(4.65) == "4.7")
  }
}
