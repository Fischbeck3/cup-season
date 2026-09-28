// S2/C3 · the synthetic world holds to the same decoders the screens use.
//
// A fixture that drifts from its contract fails SILENTLY on a screen — an
// empty section, a skeleton that never resolves — so the shapes the routes
// depend on most are decoded here, with the app's own types, for every
// scenario. Nothing here talks to a network; the world is built in memory.

import Testing
import Foundation
import CupSeasonKit
@testable import CupSeason

@Suite struct SyntheticWorldTests {
  /// The wire's timestamps are ISO date-times with or without a fraction.
  private func decoder() -> JSONDecoder {
    let d = JSONDecoder()
    d.dateDecodingStrategy = .custom { decoder in
      let s = try decoder.singleValueContainer().decode(String.self)
      let f = ISO8601DateFormatter()
      f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      if let date = f.date(from: s) { return date }
      f.formatOptions = [.withInternetDateTime]
      if let date = f.date(from: s) { return date }
      throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "not a timestamp: \(s)"))
    }
    return d
  }

  private let signedIn = SynthScenario.allCases.filter(\.signedIn)

  @Test func everyScenarioBootsAsTheSyntheticViewer() throws {
    for scenario in signedIn {
      let world = SyntheticWorld(scenario)
      let me = try decoder().decode(Me.self, from: SynthOut.encode(world.nativeHome()))
      #expect(me.profile?.id == fid(1), "\(scenario.rawValue)")
      #expect(me.needsCard == (scenario == .cardGate), "\(scenario.rawValue)")
      #expect(me.memberships.count == world.leagues.count, "\(scenario.rawValue)")
      #expect(Set(me.memberships.map(\.league_id)).count == me.memberships.count, "\(scenario.rawValue)")
    }
  }

  @Test func everyBookPassesItsOwnValidation() throws {
    for scenario in signedIn {
      let world = SyntheticWorld(scenario)
      for l in world.leagues {
        let book = try JSONDecoder().decode(SeasonBookSnapshot.self, from: SynthOut.encode(world.seasonBook(l)))
        try book.validate(league: l.id, season: fid(l.seasonN))
        // the Book and the table agree: every golfer row carries the table's points
        for (i, pn) in l.members.enumerated() {
          let row = book.rows.first { $0.id == "golfer:\(l.memberIds(pn))" }
          #expect(row.map { Double($0.points) } == l.points[i], "\(scenario.rawValue) \(l.name) \(pn)")
        }
      }
    }
  }

  @Test func theHomeDispatchDecodes() throws {
    for scenario in signedIn {
      let world = SyntheticWorld(scenario)
      let payload = try decoder().decode(HomeDispatch.Payload.self, from: SynthOut.encode(world.homeDispatch(caps: true)))
      #expect(payload.me?.profile?.id == fid(1), "\(scenario.rawValue)")
    }
  }

  @Test func theViewerIsInventedAndTheIdsAreFixtureIds() {
    let world = SyntheticWorld(.seasonLive)
    for p in world.people {
      #expect(p.email.hasSuffix("@example.invalid"))
      #expect(p.ids.hasPrefix("f1c70000-"))
    }
    for c in world.courses { #expect(c.name.hasSuffix("(fixture)")) }
    #expect(SyntheticSeam.supabaseURL.host?.hasSuffix(".invalid") == true)
  }

  @Test func theWorldIsDeterministic() {
    let a = SyntheticWorld(.seasonLive), b = SyntheticWorld(.seasonLive)
    #expect(SynthOut.encode(a.nativeHome()) == SynthOut.encode(b.nativeHome()))
    #expect(SynthOut.encode(a.seasonBook(a.leagues[0])) == SynthOut.encode(b.seasonBook(b.leagues[0])))
  }
}
