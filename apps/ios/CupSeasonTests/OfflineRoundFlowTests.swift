import Foundation
import Testing
@testable import CupSeason
import CupSeasonKit

@Suite @MainActor struct OfflineRoundFlowTests {
  @Test func threeRoundsThroughActualStoreWithRelaunch() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let owner = UUID()
    let golfer = OfflineGolfer(id: owner, name: "QA fixture", index: nil, marker: nil)
    for number in 1...3 {
      let vault = OfflineRounds(directory: dir)
      let store = LiveRoundStore(offline: vault)
      store.prepareOffline(golfer)
      store.state.course.label = "QA fixture course \(number)"
      store.saveCard(front: Array(repeating: 4, count: 9), back: Array(repeating: 4, count: 9))
      await store.teeOff()
      #expect(store.state.active && store.state.onThisPhone && store.state.code == nil)
      let id = try #require(store.state.lr)
      await store.teeOff() // double tap cannot replace the local card
      #expect(store.state.lr == id)
      for hole in 0..<9 { store.state.hole = hole; store.step(0, 1) }
      let resumed = LiveRoundStore(offline: OfflineRounds(directory: dir))
      resumed.prepareOffline(golfer)
      #expect(resumed.state.lr == id && resumed.state.scores[0].prefix(9).allSatisfy { $0 == 4 })
      for hole in 9..<18 { resumed.state.hole = hole; resumed.step(0, 1) }
      #expect(await resumed.finish(casual: false))
      #expect(!resumed.state.active)
      #expect(try vault.rounds(owner: owner).count == number)
      #expect(try vault.round(owner: owner, id: id)?.localCompleted == true)
    }
    let last = LiveRoundStore(offline: OfflineRounds(directory: dir)); last.prepareOffline(golfer)
    #expect(last.localCards().count == 3)
    #expect(KeptCards.rows(last.localCards()).allSatisfy { $0.total == 72 && $0.isComplete })
  }
  @Test func missingCourseCannotStartAndStorageFailureKeepsActiveState() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let owner = UUID(); let store = LiveRoundStore(offline: OfflineRounds(directory: dir))
    store.prepareOffline(OfflineGolfer(id: owner, name: "QA fixture", index: nil, marker: nil))
    await store.teeOff(); #expect(!store.state.active)
    store.state.course.label = "QA fixture course"
    await store.teeOff(); #expect(!store.state.active) // no real pars entered
    store.saveCard(front: Array(repeating: 4, count: 9), back: Array(repeating: 4, count: 9))
    await store.teeOff(); store.step(0, 1)
    try FileManager.default.removeItem(at: dir)
    try Data([0]).write(to: dir) // deterministic disk failure
    store.step(0, 1)
    #expect(store.localSaveError != nil)
    #expect(await store.finish(casual: false) == false)
    #expect(store.state.active && store.state.scores[0][0] == 5)
  }
}
