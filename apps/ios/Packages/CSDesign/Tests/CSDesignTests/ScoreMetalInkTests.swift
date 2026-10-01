import Testing
@testable import CSDesign

@Suite struct ScoreMetalInkTests {
  @Test func resultObjectsStayReadableAndCannotFollowALook() {
    for context in ContrastMath.everyPalette {
      let p = context.palette
      for fill in [p.scoreGold, p.scoreSilver, p.scoreBronze] {
        #expect(ContrastMath.ratio(ContrastMath.opaque(p.scoreInk), ContrastMath.opaque(fill)) >= 4.5)
      }
      for (actual, expected) in [(p.scoreGold, CSTokens.dark.scoreGold),
                                  (p.scoreSilver, CSTokens.dark.scoreSilver),
                                  (p.scoreBronze, CSTokens.dark.scoreBronze),
                                  (p.scoreInk, CSTokens.dark.scoreInk)] {
        #expect(ContrastMath.ratio(ContrastMath.opaque(actual), ContrastMath.opaque(expected)) == 1)
      }
    }
  }
}
