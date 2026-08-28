import Testing
import Foundation
@testable import CupSeasonKit

// The visible pricing model (IOS-021 / D56, amended by D101 — the league-year):
// the bands, the per-player line, the Founding lookup, and the fail-closed
// decode — each against the D101 numbers ($59 · $89 · $109 a year).

@Suite struct PricingBandTests {
  let flags = PricingFlags.seed

  @Test func theThreeBandsAtTheirEdges() {
    #expect(flags.passFor(roster: 8).cents == 5900)
    #expect(flags.passFor(roster: 9).cents == 5900)
    #expect(flags.passFor(roster: 10).cents == 8900)
    #expect(flags.passFor(roster: 13).cents == 8900)
    #expect(flags.passFor(roster: 14).cents == 10900)
    #expect(flags.passFor(roster: 16).cents == 10900)
  }

  @Test func pastTheLastBandTheLastBandHolds() {
    #expect(flags.passFor(roster: 140).cents == 10900)
    #expect(flags.passFor(roster: 0).cents == 5900)
  }

  @Test func noBandsFallsBackToTheAnchor() {
    let f = PricingFlags(visible: true, anchorCents: 9900, bands: [], firstYearFree: true, founding: .init())
    #expect(f.passFor(roster: 12).cents == 9900)
  }

  @Test func everyBandStaysUnderNineAHeadAYear() {
    // D101: about $6.50–$7.80 a player a year at the bands' middles; the
    // bottom edge of a band is the dear end (10 → $8.90), never past $9.
    for r in 8...20 {
      let each = Double(flags.passFor(roster: r).cents) / 100 / Double(r)
      #expect(each >= 5.0 && each < 9.0, "roster \(r) → \(each)")
    }
  }

  @Test func theUnitIsTheYear() {
    #expect(flags.unit == "year")
    #expect(flags.firstYearFree)
  }
}

@Suite struct PricingFormatTests {
  @Test func dollarsStayWholeWhenTheyAre() {
    #expect(PricingFlags.dollars(8900) == "$89")
    #expect(PricingFlags.dollars(5900) == "$59")
    #expect(PricingFlags.dollars(10900) == "$109")
    #expect(PricingFlags.dollars(8950) == "$89.50")
  }

  @Test func perPlayerIsTwoDecimalsUnderTenElseRound() {
    #expect(PricingFlags.perPlayer(cents: 8900, roster: 12) == "$7.40")   // the standard band's quoted figure
    #expect(PricingFlags.perPlayer(cents: 8900, roster: 10) == "$8.90")
    #expect(PricingFlags.perPlayer(cents: 5900, roster: 8) == "$7.40")
    #expect(PricingFlags.perPlayer(cents: 10900, roster: 14) == "$7.80")
    #expect(PricingFlags.perPlayer(cents: 10900, roster: 16) == "$6.80")
    #expect(PricingFlags.perPlayer(cents: 5900, roster: 4) == "$15")
    #expect(PricingFlags.perPlayer(cents: 8900, roster: 7) == "$13")
  }

  @Test func theLineSaysAbout() {
    #expect(PricingFlags.perPlayerLine(cents: 8900, roster: 12) == "about $7.40 a player")
    #expect(PricingFlags.perPlayerLine(cents: 5900, roster: 4) == "about $15 a player")
  }

  @Test func aZeroRosterNeverDividesByZero() {
    #expect(PricingFlags.perPlayer(cents: 8900, roster: 0) == "$89")
  }
}

@Suite struct PricingFoundingTests {
  let pigl = UUID()

  @Test func theBadgeNumberByLeagueIdInEitherCase() {
    let lower = PricingFlags(visible: true, anchorCents: 8900, bands: PricingFlags.defaultBands, firstYearFree: true,
                             founding: .init(cap: 10, closed: false, ids: [pigl.uuidString.lowercased(): 1]))
    #expect(lower.foundingNumber(leagueId: pigl) == 1)
    let upper = PricingFlags(visible: true, anchorCents: 8900, bands: PricingFlags.defaultBands, firstYearFree: true,
                             founding: .init(cap: 10, closed: false, ids: [pigl.uuidString.uppercased(): 3]))
    #expect(upper.foundingNumber(leagueId: pigl) == 3)
    #expect(upper.foundingNumber(leagueId: UUID()) == nil)
  }

  @Test func foundingBeatsPaidBeatsFree() {
    let f = PricingFlags(visible: true, anchorCents: 8900, bands: PricingFlags.defaultBands, firstYearFree: true,
                         founding: .init(ids: [pigl.uuidString.lowercased(): 1]))
    let paid = PricingPaid(paidThrough: "2027-09-26", cents: 8900)
    #expect(PricingMembershipState.of(f, leagueId: pigl, roster: 12, paid: paid) == .founding(number: 1))
    let other = UUID()
    #expect(PricingMembershipState.of(f, leagueId: other, roster: 12, paid: paid) == .paid(paid))
    #expect(PricingMembershipState.of(f, leagueId: other, roster: nil, paid: nil)
            == .freeYear(cents: 8900, roster: PricingFlags.referenceRoster))
    #expect(PricingMembershipState.of(f, leagueId: other, roster: 8, paid: nil) == .freeYear(cents: 5900, roster: 8))
  }
}

@Suite struct PricingDecodeTests {
  func decode(_ json: String) throws -> PricingFlags { try JSONDecoder().decode(PricingFlags.self, from: Data(json.utf8)) }

  @Test func theSeedDecodesWithSnakeCaseKeys() throws {
    let f = try decode("""
    {"visible": true, "unit": "year", "anchor_cents": 8900,
     "bands": [{"max_roster": 9, "cents": 5900}, {"max_roster": 13, "cents": 8900}, {"max_roster": 99, "cents": 10900}],
     "first_year_free": true, "founding": {"cap": 10, "closed": false, "ids": {"5c1e8b2e-2a4b-4b1e-9d3f-0a1b2c3d4e5f": 1}}}
    """)
    #expect(f.visible)
    #expect(f.unit == "year")
    #expect(f.anchorCents == 8900)
    #expect(f.bands == PricingFlags.defaultBands)
    #expect(f.firstYearFree)
    #expect(f.founding.cap == 10)
    #expect(f.foundingNumber(leagueId: UUID(uuidString: "5c1e8b2e-2a4b-4b1e-9d3f-0a1b2c3d4e5f")!) == 1)
  }

  @Test func theD56KeyStillReads() throws {
    // a hand-written row from before D101: `season1_free` feeds `firstYearFree`
    let f = try decode(#"{"visible": true, "season1_free": false}"#)
    #expect(f.firstYearFree == false)
    #expect(f.unit == "year")
  }

  @Test func aMissingVisibleKeyIsHidden() throws {
    let f = try decode("{}")
    #expect(f.visible == false)
    #expect(f == .hidden)
    #expect(f.bands == PricingFlags.defaultBands)
  }

  @Test func aPartialRowKeepsTheDefaultsAroundIt() throws {
    let f = try decode(#"{"visible": true}"#)
    #expect(f.visible)
    #expect(f.passFor(roster: 12).cents == 8900)
    #expect(f.founding.ids.isEmpty)
  }

  @Test func theProdSeedIsHiddenUntilTheOwnerFlipsIt() throws {
    // The 20260827170000 migration's value, verbatim but for whitespace.
    let f = try decode("""
    {"visible": false, "unit": "year", "anchor_cents": 8900,
     "bands": [{"max_roster": 9, "cents": 5900}, {"max_roster": 13, "cents": 8900}, {"max_roster": 99, "cents": 10900}],
     "first_year_free": true, "founding": {"cap": 10, "closed": false, "ids": {}}}
    """)
    #expect(f.visible == false)
  }

  @Test func jsonValueInHandAndBadShapesFailClosed() {
    #expect(PricingFlags(json: nil) == .hidden)
    #expect(PricingFlags(json: .string("nope")) == .hidden)
    #expect(PricingFlags(json: .object(["visible": .string("yes")])) == .hidden)
    let ok = PricingFlags(json: .object(["visible": .bool(true), "anchor_cents": .number(9900)]))
    #expect(ok.visible && ok.anchorCents == 9900)
  }
}
