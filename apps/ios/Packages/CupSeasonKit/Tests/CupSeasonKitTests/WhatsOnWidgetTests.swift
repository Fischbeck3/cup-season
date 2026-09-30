import Foundation
import Testing
@testable import CupSeasonKit

/// D400 · the Race finds a season being played; What's On carries Home's own
/// cards, never money; its doors are exact; the turn is a rotation, not a
/// reshuffle; stale stops the turning.
struct WhatsOnWidgetTests {
  let owner = UUID(), league = UUID(), round = UUID()
  let now = Date(timeIntervalSince1970: 1_790_323_200)

  private func item(_ key: String, tier: String = "circle", eyebrow: String = "Your circle",
                    headline: String = "Galen posted 78 at Papago.", action: String? = "See the round",
                    route: [String: Any]? = nil, spine: String = "mut") throws -> HomeDispatch.Item {
    var o: [String: Any] = ["key": key, "tier": tier, "eyebrow": eyebrow, "headline": headline, "spine": spine]
    if let action { o["action"] = action }
    o["route"] = route ?? ["kind": "receipt", "id": round.uuidString]
    return try JSONDecoder().decode(HomeDispatch.Item.self, from: JSONSerialization.data(withJSONObject: o))
  }

  private func book(_ fixture: String, _ edit: (inout [String: Any]) -> Void = { _ in }) throws -> SeasonBookSnapshot {
    let data = try Data(contentsOf: Bundle.module.url(forResource: fixture, withExtension: "json")!)
    var o = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    edit(&o)
    return try JSONDecoder().decode(SeasonBookSnapshot.self, from: JSONSerialization.data(withJSONObject: o))
  }

  // MARK: the Race

  @Test func aSquadsLeagueBeforeTheDrawRacesTheGolfers() throws {
    // the owner's Test1: squads on the table, no squad row his, his golfer row his
    let b = try book("squads") { o in
      var rows = o["rows"] as! [[String: Any]]
      let golfer = rows.firstIndex { ($0["kind"] as? String) == "golfer" }
      for i in rows.indices where (rows[i]["kind"] as? String) == "squad" { rows[i]["mine"] = false }
      for i in rows.indices where (rows[i]["kind"] as? String) == "golfer" { rows[i]["mine"] = i == golfer }
      o["rows"] = rows
    }
    #expect(b.hasSquads)
    let race = try #require(BetweenRoundsCopy.race(b))
    #expect(race.rows.contains { $0.mine })
    for row in race.rows { #expect(b.rows.first { $0.id == row.id }?.kind == "golfer") }
    #expect(race.story != "Your squad leads.")
  }

  @Test func aSquadOfYourOwnIsStillTheRace() throws {
    let b = try book("squads")
    let race = try #require(BetweenRoundsCopy.race(b))
    for row in race.rows { #expect(b.rows.first { $0.id == row.id }?.kind == "squad") }
  }

  @Test func theRaceWithPointsBeatsAWeekOneTableAtZeros() {
    func race(_ name: String, _ points: [Int]) -> BetweenRoundsSnapshot.Race {
      .init(league: UUID(), name: name, context: "Week 1 · Cup points", standing: "1st of 2", story: "You lead.",
            rows: points.enumerated().map { .init(id: "\($0.offset)", name: "G\($0.offset)", rank: "01", points: $0.element, mine: $0.offset == 0) })
    }
    // the last-opened league leads the order, but it is at zeros
    #expect(BetweenRoundsCopy.pick([race("Test1", [0, 0]), nil, race("Fellas", [64, 10])])?.name == "Fellas")
    // among races in play, the last-opened league wins
    #expect(BetweenRoundsCopy.pick([race("Fellas", [64, 10]), race("Bitch", [41, 50])])?.name == "Fellas")
    // nothing in play anywhere: the first race still beats the empty state
    #expect(BetweenRoundsCopy.pick([nil, race("Test1", [0, 0])])?.name == "Test1")
    #expect(BetweenRoundsCopy.pick([nil, nil]) == nil)
  }

  // MARK: What's On

  @Test func whatsOnIsHomesLeadThenDeckCopiedWordForWord() throws {
    let lead = try item("clash:1", tier: "closing", eyebrow: "Clash week", headline: "You and Galen, two days left.",
                        action: "See the clash", route: ["kind": "season", "id": league.uuidString, "pane": "table"], spine: "ember")
    let deck = [try item("circle:1"), try item("clash:1"), try item("plan:1", headline: "Saturday 7:40 at Papago.",
                route: ["kind": "plan", "id": round.uuidString])]
    let w = try #require(BetweenRoundsCopy.whatsOn(lead: lead, deck: deck))
    #expect(w.items.map(\.key) == ["clash:1", "circle:1", "plan:1"], "the lead first, a repeat once")
    #expect(w.items[0].headline == "You and Galen, two days left.")
    #expect(w.items[0].eyebrow == "Clash week" && w.items[0].action == "See the clash" && w.items[0].spine == "ember")
    #expect(w.items[0].route == "season" && w.items[0].routeId == league && w.items[0].pane == "table")
    #expect(w.items[2].route == "plan")
  }

  @Test func moneyNeverReachesTheHomeScreen() throws {
    let deck = [
      try item("pot:1", headline: "The pot is settled.", route: ["kind": "pot", "id": league.uuidString]),
      try item("owe:1", headline: "Settle up with the Pro.", route: ["kind": "season", "id": league.uuidString]),
      try item("circle:2", headline: "Jade won $20 in skins.", route: ["kind": "receipt", "id": round.uuidString]),
      try item("circle:3", headline: "Jade posted 81."),
    ]
    let w = try #require(BetweenRoundsCopy.whatsOn(lead: nil, deck: deck))
    #expect(w.items.map(\.key) == ["circle:3"])
    #expect(BetweenRoundsCopy.whatsOn(lead: nil, deck: Array(deck.prefix(3))) == nil)
  }

  @Test func whatsOnStopsAtFive() throws {
    let deck = try (0..<8).map { try item("circle:\($0)") }
    #expect(BetweenRoundsCopy.whatsOn(lead: nil, deck: deck)?.items.count == BetweenRoundsCopy.whatsOnLimit)
  }

  @Test func aDoorTheWidgetCannotNameOpensHome() throws {
    let composer = try item("afterplan:1", route: ["kind": "composer"])
    let invite = try item("invite:\(UUID())", route: ["kind": "invite", "id": league.uuidString, "pane": "season"])
    let w = try #require(BetweenRoundsCopy.whatsOn(lead: composer, deck: [invite]))
    #expect(w.items.allSatisfy { $0.route == "home" && $0.routeId == nil })
    var s = BetweenRoundsSnapshot(owner: owner)
    s.whatsOn = .init(w, at: now)
    let d = try #require(WidgetDestination(url: s.link(for: w.items[0])))
    #expect(d.kind == .whatsOn && d.route == .home && d.id == nil)
  }

  @Test func whatsOnLinksRoundTripAndRejectForgedRoutes() {
    for route in WhatsOnRoute.allCases {
      let d = WidgetDestination(kind: .whatsOn, id: route.needsId ? league : nil, owner: owner,
                                route: route, pane: route == .season ? "board" : nil)
      #expect(WidgetDestination(url: d.url) == d)
    }
    let base = "cupseason://widget?kind=CSWhatsOnWidget&owner=\(owner)"
    #expect(WidgetDestination(url: URL(string: base + "&route=pot&id=\(league)")!) == nil, "not a route this app opens")
    #expect(WidgetDestination(url: URL(string: base + "&route=receipt&route=plan&id=\(league)")!) == nil)
    #expect(WidgetDestination(url: URL(string: base + "&route=receipt&pane=board&id=\(league)")!) == nil, "a pane is a season's")
    #expect(WidgetDestination(url: URL(string: "cupseason://widget?kind=CSSeasonWidget&owner=\(owner)&route=receipt")!) == nil,
            "a route is What's On's alone")
    // an item whose route needs an id and has none lands Home
    var s = BetweenRoundsSnapshot(owner: owner)
    let orphan = BetweenRoundsSnapshot.WhatsOn.Item(key: "k", eyebrow: "e", headline: "h", action: nil, spine: "mut",
                                                    route: "receipt", routeId: nil, pane: nil)
    s.whatsOn = .init(.init(items: [orphan]), at: now)
    #expect(WidgetDestination(url: s.link(for: .whatsOn))?.route == nil)
  }

  @Test func theTurnIsARotationAndStaleStopsIt() throws {
    let items = (0..<3).map { BetweenRoundsSnapshot.WhatsOn.Item(key: "k\($0)", eyebrow: "", headline: "h\($0)",
                                                                action: nil, spine: "mut", route: nil, routeId: nil, pane: nil) }
    let w = BetweenRoundsSnapshot.WhatsOn(items: items)
    #expect(w.rotated(0).map(\.key) == ["k0", "k1", "k2"])
    #expect(w.rotated(1).map(\.key) == ["k1", "k2", "k0"])
    #expect(w.rotated(4).map(\.key) == ["k1", "k2", "k0"])

    var s = BetweenRoundsSnapshot(owner: owner)
    s.whatsOn = .init(w, at: now)
    let turns = s.rotationDates(now: now)
    #expect(turns.first?.date == now && turns.first?.step == 0)
    #expect(turns.count == Int(BetweenRoundsSnapshot.rotationSpan / BetweenRoundsSnapshot.rotationStep))
    #expect(zip(turns, turns.dropFirst()).allSatisfy { $0.date < $1.date && $1.step == $0.step + 1 })

    // written 23 h 50 m ago: the turning ends at the stale line
    s.whatsOn = .init(w, at: now.addingTimeInterval(-(DispatchSnapshot.staleAfter - 600)))
    let late = s.rotationDates(now: now)
    #expect(late.last?.date == now.addingTimeInterval(600))
    // already stale: one entry, no turns
    s.whatsOn = .init(w, at: now.addingTimeInterval(-DispatchSnapshot.staleAfter - 1))
    #expect(s.rotationDates(now: now).count == 1)
    #expect(s.isStale(.whatsOn, at: now))
  }

  @Test func anOlderSnapshotStillDecodes() throws {
    // written by a build without What's On or hasSeason
    let old = #"{"owner":"\#(owner.uuidString)"}"#
    let s = try JSONDecoder().decode(BetweenRoundsSnapshot.self, from: Data(old.utf8))
    #expect(s.whatsOn == nil && s.hasSeason == nil)
  }
}
