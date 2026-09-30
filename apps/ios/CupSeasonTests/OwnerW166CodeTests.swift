import Testing
@testable import CupSeason

@MainActor @Suite struct OwnerW166CodeTests {
  @Test func malformedAndUnknownCodesStayBesideTheirInput() async {
    var calls = 0
    let model = LeagueCodeModel { _ in calls += 1; return nil }
    for raw in ["", "A", "NORT4K7Q9", "AB C"] {
      model.code = raw
      #expect(await model.take() == nil)
      #expect(model.error == "That does not look like a code." && model.code == raw)
    }
    #expect(calls == 0)
    model.code = "nort4k7q"
    #expect(await model.take() == nil)
    #expect(calls == 1 && model.error == "No league with that code. Check with your Pro.")
    model.edited()
    #expect(model.error == nil)
  }
  @Test func aKnownCodeKeepsItsNormalizedCodeAndCurrentLeagueName() async {
    let model = LeagueCodeModel { code in
      #expect(code == "NGFX26")
      return "North Grove (fixture)"
    }
    model.code = " ngfx26 "
    let answer = await model.take()
    #expect(answer?.code == "NGFX26" && answer?.name == "North Grove (fixture)")
    #expect(!model.busy && model.error == nil)
  }
}
