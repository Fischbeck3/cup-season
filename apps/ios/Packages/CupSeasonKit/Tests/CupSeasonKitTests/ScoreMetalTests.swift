import Testing
@testable import CupSeasonKit

@Suite struct ScoreMetalTests {
  @Test func matchesExistingBandEdges() {
    for value in [1.0, 2.9, 3.0, 9.0] {
      #expect(CSBands.scoreMetal(value) == .gold)
      #expect(CSBands.cupPoints(value) >= 9)
    }
    for value in [-0.999, 0.0, 0.999] {
      #expect(CSBands.scoreMetal(value) == .silver)
      #expect(CSBands.cupPoints(value) == 7)
    }
    for value in [-1.0, -3.0, -3.001, -9.0] {
      #expect(CSBands.scoreMetal(value) == .bronze)
      #expect(CSBands.cupPoints(value) <= 6)
    }
  }

  @Test func unknownPerformanceCannotEarnAMetal() {
    let values: [Double?] = [nil, .nan, .infinity, -.infinity]
    for value in values {
      #expect(CSBands.scoreMetal(value) == .neutral)
    }
  }
}
