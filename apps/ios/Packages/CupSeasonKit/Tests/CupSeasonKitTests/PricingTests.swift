import Testing
import Foundation
@testable import CupSeasonKit

// The visible pricing model (IOS-021 / D56): the bands, the per-player line,
// the Founding lookup, and the fail-closed decode — each against the numbers
// in spec/pricing-discovery-2026-07.md §2 and the plan's copy.

@Suite struct PricingBandTests {
  let flags = PricingFlags.seed

  @Test func theThreeBandsAtTheirEdges() {
    #expect(flags.passFor(roster: 8).cents == 4900)
    #expect(flags.passFor(roster: 9).cents == 4900)
    #expect(flags.passFor(roster: 10).cents == 7900)
    #expect(flags.passFor(roster: 13).cents == 7900)
    #expect(flags.passFor(roster: 14).cents == 9900)
    #expect(flags.passFor(roster: 16).cents == 9900)
  }

  @Test func pastTheLastBandTheLastBandHolds() {
    #expect(flags.passFor(roster: 140).cents == 9900)
    #expect(flags.passFor(roster: 0).cents == 4900)
  }

  @Test func noBandsFallsBackToTheAnchor() {
    let f = PricingFlags(visible: true, anchorCents: 8900, bands: [], season1Free: true, founding: .init())
    #expect(f.passFor(roster: 12).cents == 8900)
  }
}

@Suite struct PricingFormatTests {
  @Test func dollarsStayWholeWhenTheyAre() {
    #expect(PricingFlags.dollars(7900) == "$79")
    #expect(PricingFlags.dollars(4900) == "$49")
    #expect(PricingFlags.dollars(7950) == "$79.50")
  }

  @Test func perPlayerIsTwoDecimalsUnderTenElseRound() {
    #expect(PricingFlags.perPlayer(cents: 7900, roster: 12) == "$6.60")   // the plan's quoted figure
    #expect(PricingFlags.perPlayer(cents: 7900, roster: 10) == "$7.90")
    #expect(PricingFlags.perPlayer(cents: 4900, roster: 8) == "$6.10")
    #expect(PricingFlags.perPlayer(cents: 9900, roster: 14) == "$7.10")
    #expect(PricingFlags.perPlayer(cents: 9900, roster: 16) == "$6.20")
    #expect(PricingFlags.perPlayer(cents: 4900, roster: 4) == "$12")
    #expect(PricingFlags.perPlayer(cents: 7900, roster: 7) == "$11")
  }

  @Test func theLineSaysAbout() {
    #expect(PricingFlags.perPlayerLine(cents: 7900, roster: 12) == "about $6.60 a player")
    #expect(PricingFlags.perPlayerLine(cents: 4900, roster: 4) == "about $12 a player")
  }

  @Test func aZeroRosterNeverDividesByZero() {
    #expect(PricingFlags.perPlayer(cents: 7900, roster: 0) == "$79")
  }
}

@Suite struct PricingFoundingTests {
  let pigl = UUID()

  @Test func theBadgeNumberByLeagueIdInEitherCase() {
    let lower = PricingFlags(visible: true, anchorCents: 7900, bands: PricingFlags.defaultBands, season1Free: true,
                             founding: .init(cap: 10, closed: false, ids: [pigl.uuidString.lowercased(): 1]))
    #expect(lower.foundingNumber(leagueId: pigl) == 1)
    let upper = PricingFlags(visible: true, anchorCents: 7900, bands: PricingFlags.defaultBands, season1Free: true,
                             founding: .init(cap: 10, closed: false, ids: [pigl.uuidString.uppercased(): 3]))
    #expect(upper.foundingNumber(leagueId: pigl) == 3)
    #expect(upper.foundingNumber(leagueId: UUID()) == nil)
  }

  @Test func foundingBeatsPaidBeatsFree() {
    let f = PricingFlags(visible: true, anchorCents: 7900, bands: PricingFlags.defaultBands, season1Free: true,
                         founding: .init(ids: [pigl.uuidString.lowercased(): 1]))
    let paid = PricingPaid(paidThrough: "2027-09-26", cents: 7900)
    #expect(PricingMembershipState.of(f, leagueId: pigl, seasonNumber: 2, roster: 12, paid: paid) == .founding(number: 1))
    let other = UUID()
    #expect(PricingMembershipState.of(f, leagueId: other, seasonNumber: 2, roster: 12, paid: paid) == .paid(paid))
    #expect(PricingMembershipState.of(f, leagueId: other, seasonNumber: nil, roster: nil, paid: nil)
            == .freeSeason(seasonNumber: 1, cents: 7900, roster: PricingFlags.referenceRoster))
    #expect(PricingMembershipState.of(f, leagueId: other, seasonNumber: 1, roster: 8, paid: nil) == .freeSeason(seasonNumber: 1, cents: 4900, roster: 8))
  }
}

@Suite struct PricingDecodeTests {
  func decode(_ json: String) throws -> PricingFlags { try JSONDecoder().decode(PricingFlags.self, from: Data(json.utf8)) }

  @Test func theSeedDecodesWithSnakeCaseKeys() throws {
    let f = try decode("""
    {"visible": true, "anchor_cents": 7900,
     "bands": [{"max_roster": 9, "cents": 4900}, {"max_roster": 13, "cents": 7900}, {"max_roster": 99, "cents": 9900}],
     "season1_free": true, "founding": {"cap": 10, "closed": false, "ids": {"5c1e8b2e-2a4b-4b1e-9d3f-0a1b2c3d4e5f": 1}}}
    """)
    #expect(f.visible)
    #expect(f.anchorCents == 7900)
    #expect(f.bands == PricingFlags.defaultBands)
    #expect(f.season1Free)
    #expect(f.founding.cap == 10)
    #expect(f.foundingNumber(leagueId: UUID(uuidString: "5c1e8b2e-2a4b-4b1e-9d3f-0a1b2c3d4e5f")!) == 1)
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
    #expect(f.passFor(roster: 12).cents == 7900)
    #expect(f.founding.ids.isEmpty)
  }

  @Test func theProdSeedIsHiddenUntilTheOwnerFlipsIt() throws {
    // The migration's value, verbatim but for whitespace.
    let f = try decode("""
    {"visible": false, "anchor_cents": 7900,
     "bands": [{"max_roster": 9, "cents": 4900}, {"max_roster": 13, "cents": 7900}, {"max_roster": 99, "cents": 9900}],
     "season1_free": true, "founding": {"cap": 10, "closed": false, "ids": {}}}
    """)
    #expect(f.visible == false)
  }

  @Test func jsonValueInHandAndBadShapesFailClosed() {
    #expect(PricingFlags(json: nil) == .hidden)
    #expect(PricingFlags(json: .string("nope")) == .hidden)
    #expect(PricingFlags(json: .object(["visible": .string("yes")])) == .hidden)
    let ok = PricingFlags(json: .object(["visible": .bool(true), "anchor_cents": .number(8900)]))
    #expect(ok.visible && ok.anchorCents == 8900)
  }
}
