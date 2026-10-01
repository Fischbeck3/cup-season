import Foundation
import Testing
import CupSeasonKit
@testable import CupSeason

@MainActor @Suite struct SeasonBookSelectionTests {
  @Test func delayedRefreshKeepsGroupWeekAndSquadThroughFailureAndRetry() async throws {
    let book = CompeteSelectedFixture.book
    var calls = 0
    let store = SeasonBookStore(read: { _, _ in
      calls += 1
      try await Task.sleep(for: .milliseconds(10))
      if calls == 2 { throw URLError(.notConnectedToInternet) }
      return book
    })
    var selected = SeasonBookSelection()
    await store.load(league:book.league_id,season:book.season_id)
    selected.receive(try #require(store.snapshot))
    #expect(selected.group == "squad" && selected.week == max(1,book.current_week) && selected.squad == "all")
    selected.group = "golfer"
    selected.week = 1
    let squad = try #require(book.rows.first { $0.kind == "squad" }?.squad_id).uuidString
    selected.squad = squad
    await store.load(league:book.league_id,season:book.season_id)
    #expect(store.error != nil && store.snapshot == nil)
    #expect(selected.group == "golfer" && selected.week == 1 && selected.squad == squad)
    await store.load(league:book.league_id,season:book.season_id)
    selected.receive(try #require(store.snapshot))
    #expect(calls == 3 && store.error == nil)
    #expect(selected.group == "golfer" && selected.week == 1 && selected.squad == squad)
  }

  @Test func aDifferentSeasonGetsItsOwnDefaultsEvenAfterARefresh() throws {
    let book = CompeteSelectedFixture.book
    var selected = SeasonBookSelection(book:book)
    selected.group = "golfer"; selected.week = 1; selected.squad = "chosen"
    selected.receive(book)
    #expect(selected.group == "golfer" && selected.week == 1 && selected.squad == "chosen")
    var json = try JSONSerialization.jsonObject(with:JSONEncoder().encode(book)) as! [String:Any]
    json["season_id"] = UUID().uuidString
    json["current_week"] = 0
    let next = try JSONDecoder().decode(SeasonBookSnapshot.self,from:JSONSerialization.data(withJSONObject:json))
    selected.receive(next)
    #expect(selected.group == "squad" && selected.week == 1 && selected.squad == "all")
  }
}
