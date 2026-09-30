import Testing
import SwiftUI
@testable import CupSeason

@MainActor @Suite struct OwnerX38CardLinkTests {
  @Test func theFirstTapAsksAndOnlyAConfirmedRevokeSaysOff() async {
    var writes = 0
    let profile = UUID()
    let model = CardLinkOffModel { id in #expect(id == profile); writes += 1; return true }
    await model.tap(profile)
    #expect(model.armed && writes == 0 && model.status == nil)
    await model.tap(profile)
    #expect(!model.armed && !model.busy && writes == 1)
    #expect(model.status == CardLinkOffModel.done && !model.failed)
    model.sharedAgain()
    #expect(model.status == nil && !model.armed)
  }

  @Test func aRefusedRevokeKeepsTheControlAndNeverClaimsSuccess() async {
    let model = CardLinkOffModel { _ in false }
    let profile = UUID()
    await model.tap(profile); await model.tap(profile)
    #expect(model.failed && model.status != CardLinkOffModel.done)
    #expect(!model.busy && !model.armed)
  }

  @Test func theArmedWordsFitAndKeepA44PointTarget() throws {
    for width: CGFloat in [375, 402] {
      for size in [DynamicTypeSize.large, .accessibility3] {
        let model = CardLinkOffModel { _ in true }; model.armed = true
        let host = HostedLayout(CardLinkOffControl(model: model, profile: UUID()).padding(20), width: width, typeSize: size)
        defer { host.tearDown() }
        let target = try #require(host.element("cardLink.off"))
        #expect(target.label == CardLinkOffModel.armedLabel)
        #expect(target.frame.height >= 43.99 && target.frame.minX >= 19 && target.frame.maxX <= width - 19)
        #expect(host.horizontalScrollers.isEmpty)
      }
    }
  }
}
