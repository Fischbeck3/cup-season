// Cup Season — the dispatch decodes, in every state and in both deploy orders
// (IOS-029b, R1).
//
// The owner pushes the DATABASE and the CLIENTS separately, so both orders
// have to render an honest screen: a client ahead of the database must not
// crash or invent, and a database ahead of the client must not be able to
// break a build that predates it. Every key on `HomeDispatch.Item` is
// therefore optional in BOTH senses — absent, and present-and-null — and this
// suite drives a checked-in fixture (`tests/fixtures/dispatch.json`) with one
// case per Home state to prove it.
//
// The fixture is shared with the web: `csRankDispatch` is asserted against the
// same cases in `tests/app-tests.js`, so the two clients cannot disagree about
// what a payload means.

import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct HomeDispatchDecodeTests {

  struct Case: Decodable {
    let state: String
    let payload: HomeDispatch.Payload
    let lead: String?
    let leadTier: String?
    let deck: Int
    let cut: Int?
    let leadHuman: Bool?
    let leadHasDoor: Bool?
    let leadRoute: String?
    let suppress: [String]?
  }
  struct Fixture: Decodable { let cases: [Case] }

  static func repoRoot() -> URL {
    var u = URL(fileURLWithPath: #filePath)
    while u.pathComponents.count > 1 {
      u.deleteLastPathComponent()
      if FileManager.default.fileExists(atPath: u.appendingPathComponent("tests/fixtures/dispatch.json").path) { return u }
    }
    return u
  }

  @Test("every fixture case decodes and arranges to the screen the state matrix names")
  func fixture() throws {
    let url = Self.repoRoot().appendingPathComponent("tests/fixtures/dispatch.json")
    let f = try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    #expect(f.cases.count >= 8, "the fixture lost cases")
    for c in f.cases {
      let r = HomeRank.arrange(c.payload.items, leadSuppress: c.payload.leadSuppress)
      #expect(r.lead?.key == c.lead, "\(c.state): expected \(c.lead ?? "no lead"), got \(r.lead?.key ?? "none")")
      #expect(r.lead?.tier.rawValue == c.leadTier, "\(c.state): wrong tier")
      #expect(r.deck.count == c.deck, "\(c.state): deck of \(r.deck.count), expected \(c.deck)")
      if let cut = c.cut { #expect(r.cut == cut, "\(c.state): \(r.cut) cut, expected \(cut)") }
      if c.leadHuman == true { #expect(r.lead?.humanSubject == true, "\(c.state): the veto let a bare fact lead") }
      if c.leadHasDoor == true { #expect(r.lead?.route != nil, "\(c.state): the lead has no door") }
      if let want = c.suppress {
        #expect(r.suppress == Set(want.compactMap(MeStripCopy.Fact.init(rawValue:))), "\(c.state): wrong suppress set")
      }
      if c.leadRoute == "live" {
        guard case .live = r.lead?.route else { Issue.record("\(c.state): the live route did not resolve"); return }
      }
    }
  }

  // MARK: - the skew, both ways

  @Test("a payload with EVERY optional key absent decodes, and nothing is left holding a value the server never sent")
  func everythingAbsent() throws {
    let json = """
    {"items":[{"key":"bare","tier":"coming","eyebrow":"SAT","headline":"Galen has Saturday on the sheet.",
               "route":{"kind":"composer"}}]}
    """
    let p = try JSONDecoder().decode(HomeDispatch.Payload.self, from: Data(json.utf8))
    let i = try #require(p.items.first)
    #expect(i.rank == nil && i.score == nil && i.rankReason == nil && i.subject == nil)
    #expect(i.standfirst == nil && i.action == nil && i.leagueId == nil && i.at == nil)
    #expect(i.humanSubject == false)          // a payload that cannot say is not a person
    #expect(i.suppress.isEmpty)
    #expect(i.spine == .mut)                  // the quiet default, never ember by accident
    #expect(i.weight == 600)                  // the band stands in for the score
    #expect(p.me == nil && p.generatedAt == nil && p.leadSuppress.isEmpty)
  }

  @Test("a payload with every optional key present and NULL decodes to the same nothing")
  func everythingNull() throws {
    let json = """
    {"me":null,"generated_at":null,"lead_suppress":null,
     "items":[{"key":"bare","tier":"coming","rank":null,"score":null,"rank_reason":null,"subject":null,
               "human_subject":null,"eyebrow":"SAT","headline":"Galen has Saturday on the sheet.",
               "standfirst":null,"action":null,"league_id":null,"suppress":null,"spine":null,"at":null,
               "route":{"kind":"composer","id":null,"pane":null}}]}
    """
    let p = try JSONDecoder().decode(HomeDispatch.Payload.self, from: Data(json.utf8))
    let i = try #require(p.items.first)
    #expect(i.rank == nil && i.humanSubject == false && i.spine == .mut && i.suppress.isEmpty)
    #expect(i.route == .composer)
  }

  @Test("a key this build has never heard of is IGNORED — a database ahead of the client cannot break it")
  func unknownKeysIgnored() throws {
    let json = """
    {"items":[{"key":"future","tier":"circle","eyebrow":"E","headline":"Jade broke 90.",
               "human_subject":true,"route":{"kind":"composer"},
               "weather":"windy","confidence":0.9,"nested":{"a":[1,2,3]}}],
     "something_new":{"x":1}}
    """
    let p = try JSONDecoder().decode(HomeDispatch.Payload.self, from: Data(json.utf8))
    #expect(p.items.count == 1 && p.items[0].headline == "Jade broke 90.")
  }

  @Test("every route kind the ranker writes resolves, and one it does not write resolves to NOTHING")
  func routesResolve() throws {
    let id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    func route(_ kind: String, id: String? = nil, pane: String? = nil) throws -> HomeDispatch.Route? {
      let json = """
      {"items":[{"key":"k","tier":"circle","eyebrow":"E","headline":"H",
                 "route":{"kind":"\(kind)"\(id.map { ",\"id\":\"\($0)\"" } ?? "")\(pane.map { ",\"pane\":\"\($0)\"" } ?? "")}}]}
      """
      return try JSONDecoder().decode(HomeDispatch.Payload.self, from: Data(json.utf8)).items.first?.route
    }
    #expect(try route("composer") == .composer)
    #expect(try route("people") == .people)
    #expect(try route("declare") == .declare)
    #expect(try route("live", id: id) == .live(UUID(uuidString: id)!))
    #expect(try route("receipt", id: id) == .receipt(UUID(uuidString: id)!))
    #expect(try route("plan", id: id) == .plan(UUID(uuidString: id)!))
    #expect(try route("season", id: id, pane: "table") == .season(UUID(uuidString: id)!, pane: "table"))
    #expect(try route("pot", id: id) == .pot(UUID(uuidString: id)!))
    #expect(try route("invite", id: id, pane: "league") == .invite(UUID(uuidString: id)!, kind: "league"))
    // an id-bearing route with no id, and a kind this build does not know, both
    // resolve to nil — and the FENCE then drops the item rather than rendering
    // a sentence nobody can act on.
    #expect(try route("season") == nil)
    #expect(try route("teleport", id: id) == nil)
  }

  @Test("the dispatch carries `me`, so Home makes ONE read and the strip and the cards describe one instant")
  func mePayloadRides() throws {
    let json = """
    {"me":{"profile":{"id":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","display_name":"Jerecho",
                      "handle":"jer","marker":"saguaro","rounds_count":9,"index_current":12.4,
                      "last_round_on":"2026-09-04","last_gross":89},
           "memberships":[],"invites":[],"upcoming_rounds":[],"events":[],"open_duels":[]},
     "items":[],"generated_at":null}
    """
    let p = try JSONDecoder().decode(HomeDispatch.Payload.self, from: Data(json.utf8))
    let me = try #require(p.me)
    #expect(me.profile?.index_current == 12.4)
    // and the strip draws from it, unchanged — the same producer as the fallback path
    let strip = MeStripCopy.make(me, upcoming: [], today: "2026-09-05")
    #expect(strip.slots.first?.value == "12.4")
    #expect(strip.slots.contains { $0.value == "89 FRI" })
  }
}
