import Testing
import CupSeasonKit
@testable import CupSeason

@Suite @MainActor struct WizardAgreementTests {
  @Test func paceDoesNotOverwriteRulesAndReviewIsASnapshot() {
    let model = WizardModel(existingLeagueId: nil, runBack: nil, initialStep: 2)
    model.dials.name = "Regulars"; model.dials.expectedRoster = 8
    model.dials.structure = "squads4"; model.squadsChosen = true
    model.dials.cap = 3; model.dials.floor = 1
    model.playingFrequency = 1
    #expect(model.dials.cap == 3 && model.dials.floor == 1)
    model.dials.applyBusyFriendsSuggestion()
    model.playingFrequency = 3
    #expect(model.dials.capN == 2 && model.dials.floor == 0)
    model.prepareAgreement()
    #expect(model.agreement?.dials.structure == "squads4")
    model.dials.floor = 3
    #expect(model.agreement?.dials.floor == 0)
  }
  @Test func paymentAndNameBlockReviewBeforeAnyWrite() {
    let model = WizardModel(existingLeagueId: nil, runBack: nil, initialStep: 2)
    model.prepareAgreement(); #expect(model.agreement == nil)
    model.dials.name = "Regulars"; model.dials.stake = 20
    model.prepareAgreement(); #expect(model.agreement == nil)
    model.dials.buyInNote = "Pay Sam"
    model.prepareAgreement(); #expect(model.agreement != nil)
    #expect(model.createdHere == nil && !model.publishAttempted)
  }
  @Test func fixtureCannotPublish() async {
    let model = WizardModel(existingLeagueId: nil, runBack: nil, initialStep: 2)
    model.fixtureMode = true; model.dials.name = "Fixture"; model.prepareAgreement()
    if case .blocked = await model.publish() {} else { Issue.record("Fixture must block publishing") }
    #expect(model.createdHere == nil && !model.publishAttempted)
  }
}
