// Cup Season — R13 / D249: one band table, three renderers.
//
// `band_name(p_pvi)` (the server), `CSBands.bandName` (this client) and the
// web's `bandName()` all name the same five reads. That is one rule with three
// renderings — which is fine — and a THIRD BAND TABLE the moment any of them
// drifts, which is the thing D249 exists to forbid. The −1.0 edge has already
// drifted once (Q-20, 2026-08-29): the phone said "Played to it" over a round
// the engine scored 6.
//
// So the fixture is generated FROM the SQL (`tests/fixtures/bands.json`,
// re-derived by preflight check 28 on every push) and this suite holds the
// phone to it. The web's half of the same fixture is asserted in
// `tests/app-tests.js`; the SQL's half is asserted by the migration's own
// self-check. Three producers, one table, three tripwires.

import Testing
import Foundation
@testable import CupSeasonKit

struct BandParityTests {
  struct Case: Decodable { let pvi: Double; let band: String; let points: Int }
  struct Fixture: Decodable { let cases: [Case] }

  static func repoRoot() -> URL {
    var u = URL(fileURLWithPath: #filePath)
    while u.pathComponents.count > 1 {
      u.deleteLastPathComponent()
      if FileManager.default.fileExists(atPath: u.appendingPathComponent("tests/fixtures/bands.json").path) { return u }
    }
    return u
  }

  static func fixture() throws -> Fixture {
    let url = repoRoot().appendingPathComponent("tests/fixtures/bands.json")
    return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
  }

  @Test("every case in the SQL's own fixture names the same band on this client")
  func bandsAgree() throws {
    let f = try Self.fixture()
    #expect(f.cases.count >= 10, "the fixture lost cases")
    for c in f.cases {
      #expect(CSBands.bandName(c.pvi) == c.band,
              "pvi \(c.pvi): the fixture says \(c.band), CSBands says \(CSBands.bandName(c.pvi))")
    }
  }

  @Test("the band and the points come off the same boundaries — the −1.0 edge included")
  func pointsAgree() throws {
    for c in try Self.fixture().cases {
      #expect(CSBands.cupPoints(c.pvi) == c.points,
              "pvi \(c.pvi): the fixture says \(c.points) points, cupPoints says \(CSBands.cupPoints(c.pvi))")
    }
  }

  @Test("the fixture covers every band and both sides of all four edges")
  func fixtureIsWorthTrusting() throws {
    let f = try Self.fixture()
    let named = Set(f.cases.map(\.band))
    #expect(named == ["Torched it", "Beat your number", "Played to it", "A little loose", "Posted anyway"],
            "the fixture does not name all five bands")
    for edge in [3.0, 1.0, -1.0, -3.0] {
      #expect(f.cases.contains { $0.pvi == edge }, "the fixture never lands ON \(edge)")
      #expect(f.cases.contains { $0.pvi < edge && $0.pvi > edge - 0.5 },
              "the fixture never lands just under \(edge)")
    }
  }

  @Test("the receipt prefers the server's band and falls back to this client's")
  func theReceiptTakesTheServersWord() {
    // the payload carried one (R13 shipped): the receipt prints it verbatim
    let me = UUID()
    var seed = ReceiptSeed(profileId: me, gross: 84, differential: 11.3, indexAtPost: 12.4, pvi: 1.1, isMine: true, band: "Beat your number")
    var rows = ReceiptRows.build(seed, capN: 3, viewerId: me)
    #expect(rows.contains { if case let .math(_, value, _) = $0 { return value.contains("BEAT YOUR NUMBER") }; return false })

    // the payload did not (the migration is unpushed, or the row never went
    // through `round_card`): the same five words, from this client's producer
    seed.band = nil
    rows = ReceiptRows.build(seed, capN: 3, viewerId: me)
    #expect(rows.contains { if case let .math(_, value, _) = $0 { return value.contains("BEAT YOUR NUMBER") }; return false })

    // and someone else's round is still third-person
    seed.band = "Beat your number"
    seed.isMine = false
    rows = ReceiptRows.build(seed, capN: 3, viewerId: UUID())
    #expect(rows.contains { if case let .math(_, value, _) = $0 { return value.contains("BEAT THEIR NUMBER") }; return false })
  }
}
