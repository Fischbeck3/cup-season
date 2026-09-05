// Cup Season — THE COPY CONTRACT (IOS-029b).
//
// These are the assertions that used to pin `HomeHeroCopy` and `HomeLeagueRow`.
// **Both producers retired with wave 1b** — Home's hero and the D121 compact
// rows are replaced by one ranked dispatch (D228, D229, D231) — and the
// rulings they encoded moved into `SeasonFacts`, where wave 4's season page
// reads them. This file moved with them.
//
// It exists because deleting the tests alongside the producers would have
// deleted the only proof those rulings still hold. Every assertion below is
// the SAME assertion, retargeted at the producer the ruling now lives in:
//
//   D129  the owe matrix — the note, the Pro's own line, the member's ask,
//         "was due" behind today and "by" ahead of it, never in setup
//   D106  the pot's two numbers · D70  nothing at all on a $0 league
//   D140  a solo league has no floor and no floor clock, ever
//   D14   the floor sentence squads have carried since D14, word for word
//   D138  a seed is the LOCKED `cup_finalists` row, never the table's rank
//   D207  the two-person season's own sentences
//   D126  the endgame sentence, and §14.3's Cup-Final clock — "1 week left",
//         never "0 left"
//   D26 / D130  "back of" and "clear of", and the leader BY NAME
//
// What is NOT here, because the thing it tested no longer exists: the D121
// row's own `rows(_:excluding:)` ordering and `HomeMode.pool`. Home has no
// open league (D229), so there is nothing left to exclude and no pool to
// choose from. The SENTENCE those rows spoke survives as
// `SeasonFacts.seasonLine` and is asserted below, unchanged.

import Testing
import Foundation
@testable import CupSeasonKit

// MARK: - builders

/// A membership as `native_home()` would hand it over. `v2: false` drops the
/// v2 keys (deploy skew — the client must decode and speak either way).
func heroMembership(name: String = "Who's the bitch?", structure: String = "solo", stake: Int = 0, cap: Int? = 4,
                    finish: String = "cup_final", starts: String = "2026-08-03", ends: String = "2026-11-02",
                    status: String = "active", phase: String = "season", role: String = "player",
                    rank: Int = 2, of: Int = 2, points: Double? = 9, prev: Int? = nil,
                    leaderPts: Double? = 21, gapLeader: Double? = 12, gapNext: Double? = nil,
                    leader: String? = "Galen", runnerUp: String? = "Jerecho", runnerPts: Double? = 9,
                    credits: Double? = 2, floor: Int? = nil, partial: Bool? = false,
                    paid: Bool? = false, note: String? = nil, due: String? = nil, players: Int? = nil, paidCount: Int? = 0,
                    collected: Int? = 0, v2: Bool = true, buyIn: Bool = true, season: Bool = true, standing: Bool = true,
                    seed: Int? = nil, finalists: [String]? = nil, roster: Int? = nil, members: Int? = nil,
                    id: UUID = UUID()) -> Me.Membership {
  var st: [String: Any?] = ["rank": rank, "of": of, "points": points, "prev_rank": prev, "leader_squad_id": nil,
                             "leader_points": leaderPts, "gap_to_leader": gapLeader, "gap_to_next": gapNext]
  if v2 { st["leader_name"] = leader; st["runner_up_name"] = runnerUp; st["runner_up_points"] = runnerPts }
  // the Final's keys ride the standing only while the season is in its Final
  if v2 { st["seed"] = seed; st["finalists"] = finalists }
  let bi: [String: Any?] = ["paid": paid, "note": note, "due_on": due, "players": players ?? of, "paid_count": paidCount,
                            "collected_cents": collected]
  var m: [String: Any?] = [
    "league_id": id.uuidString, "name": name, "code": "ABCD", "phase": phase, "sandbox": false, "role": role,
    "member_id": UUID().uuidString, "marker": "saguaro", "commissioner_name": "Casey",
    "settings": ["structure": structure, "preset": "classic", "counting_cap": cap, "participation_floor": floor,
                 "floor_penalty": nil, "handicap_allowance": 95, "buyin_cents": stake, "payout_champ": 60,
                 "payout_runner": 25, "payout_king": 15, "finish": finish, "locked_at": nil] as [String: Any?],
    "season": season ? ["id": UUID().uuidString, "number": 1, "starts_on": starts, "ends_on": ends, "status": status,
                        "timezone": "America/Phoenix", "grace_hours": 12, "champion_squad_id": nil, "champion_member_id": nil,
                        "points_king_member_id": nil, "tiebreak_rung": nil] as [String: Any?] : nil,
    "squad": nil,
    "standing": standing ? st : nil,
    "pulse": ["credits": credits, "floor": floor, "at_floor": false, "partial": partial] as [String: Any?],
  ]
  if v2 && buyIn && stake > 0 { m["buy_in"] = bi }
  if v2 { m["roster"] = roster; m["members"] = members }
  func strip(_ v: Any?) -> Any? {
    if let d = v as? [String: Any?] { return d.compactMapValues(strip) }
    if let a = v as? [Any?] { return a.compactMap(strip) }
    return v
  }
  let data = try! JSONSerialization.data(withJSONObject: strip(m)!)
  return try! JSONDecoder().decode(Me.Membership.self, from: data)
}

// MARK: - the payload

@Suite struct NativeHomeV2DecodeTests {
  @Test("a v1 payload (no leader_name / buy_in keys) still decodes — deploy skew")
  func v1Decodes() {
    let m = heroMembership(stake: 7500, v2: false)
    #expect(m.standing?.leader_name == nil && m.standing?.runner_up_name == nil && m.standing?.runner_up_points == nil)
    #expect(m.buy_in == nil)
    #expect(m.standing?.gap_to_leader == 12 && m.stakeCents == 7500)
  }

  @Test("a v2 payload decodes every new key")
  func v2Decodes() {
    let m = heroMembership(stake: 7500, paid: false, note: "Venmo @casey", due: "2026-09-05", players: 2, paidCount: 1, collected: 7500)
    #expect(m.standing?.leader_name == "Galen" && m.standing?.runner_up_name == "Jerecho" && m.standing?.runner_up_points == 9)
    #expect(m.buy_in == Me.BuyIn(paid: false, note: "Venmo @casey", due_on: "2026-09-05", players: 2, paid_count: 1, collected_cents: 7500))
  }

  @Test("the memberwise inits default the v2 fields — the fallback in MeRepository keeps compiling")
  func initsDefault() {
    let st = Me.Standing(rank: 1, of: 4, points: 20, prev_rank: nil, leader_squad_id: nil, leader_points: 20, gap_to_leader: 0, gap_to_next: nil)
    #expect(st.leader_name == nil && st.runner_up_points == nil)
    let m = Me.Membership(league_id: UUID(), name: "X", code: nil, phase: "setup", sandbox: nil, role: "player", member_id: UUID(),
                          marker: nil, commissioner_name: nil, settings: nil, season: nil, squad: nil, standing: st, pulse: nil)
    #expect(m.buy_in == nil && m.stakeCents == 0 && !m.isSolo)
  }
}

// MARK: - D126 · the endgame sentence, from the fixture

@Suite struct EndgameFixtureTests {
  struct Case: Decodable { let label, finish, structure, starts_on, ends_on, cup_final_start, expected: String }
  struct Fixture: Decodable { let cases: [Case] }

  static func repoRoot() -> URL {
    var u = URL(fileURLWithPath: #filePath)
    while u.pathComponents.count > 1 {
      u.deleteLastPathComponent()
      if FileManager.default.fileExists(atPath: u.appendingPathComponent("tests/fixtures/endgame.json").path) { return u }
    }
    return u
  }

  @Test("all 24 fixture cases — tests/fixtures/endgame.json is canon")
  func fixture() throws {
    let url = Self.repoRoot().appendingPathComponent("tests/fixtures/endgame.json")
    let f = try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    #expect(f.cases.count == 24)
    for c in f.cases {
      let got = LeagueCopy.endgame(finish: c.finish, structure: c.structure, startsOn: c.starts_on, endsOn: c.ends_on)
      #expect(got == c.expected, "\(c.label) · \(c.finish) · \(c.structure)")
      #expect(LeagueDates.cupFinalStart(end: c.ends_on) == c.cup_final_start, "\(c.label) cup final start")
      #expect(got.hasSuffix("Level on points? Months won breaks it."))
      #expect(got.contains("+10") == (c.finish == "cup_final" && c.structure == "squads2"))
    }
  }

  @Test("the defaults are the web's: cup_final and squads2; no season → no date clause")
  func defaults() {
    #expect(LeagueCopy.endgame(finish: nil, structure: nil, startsOn: nil, endsOn: nil)
            == "The top 2 squads go into a four-week Cup Final — scored fresh, so the weeks before it decide who is in, not who wins. The leader carries +10 in. Level on points? Months won breaks it.")
    #expect(LeagueCopy.endgame(finish: "points_table", structure: "solo", startsOn: nil, endsOn: nil)
            == "The points table crowns it — every round counts to the last day. Level on points? Months won breaks it.")
    let m = heroMembership(structure: "squads2")
    #expect(SeasonFacts.footEndgame(m)?.contains("from Tue Oct 6") == true)
    #expect(SeasonFacts.footEndgame(heroMembership(season: false)) == nil)
  }
}

// MARK: - the hero line: the full matrix

@Suite struct SeasonLineContractTests {
  @Test("two of you, behind: the gap, the name, the score")
  func twoBehind() {
    #expect(SeasonFacts.line(heroMembership()) == "12 back of Galen · 9 – 21")
    #expect(SeasonFacts.caption(heroMembership()) == "2nd of 2")
  }

  @Test("two of you, leading: You lead X by g · mine – theirs (gap_to_next is null for rank 1 — runner_up_points carries it)")
  func twoLeading() {
    let m = heroMembership(rank: 1, points: 31, leaderPts: 31, gapLeader: 0, gapNext: nil, leader: "Jerecho", runnerUp: "Jade", runnerPts: 9)
    #expect(SeasonFacts.line(m) == "You lead Jade by 22 · 31 – 9")
    #expect(SeasonFacts.caption(m) == "1st of 2")
  }

  @Test("level: the score, from either seat — the tiebreak is the endgame foot's sentence, said once")
  func level() {
    let top = heroMembership(rank: 1, points: 14, leaderPts: 14, gapLeader: 0, leader: "Jerecho", runnerUp: "Galen", runnerPts: 14)
    #expect(SeasonFacts.line(top) == "Level with Galen · 14 – 14.")
    let second = heroMembership(rank: 2, points: 14, leaderPts: 14, gapLeader: 0, leader: "Galen", runnerUp: "Jerecho", runnerPts: 14)
    #expect(SeasonFacts.line(second) == "Level with Galen · 14 – 14.")
    let ten = heroMembership(rank: 1, of: 10, points: 14, leaderPts: 14, gapLeader: 0, leader: "Jerecho", runnerUp: "Galen", runnerPts: 14)
    #expect(SeasonFacts.line(ten) == "Level with Galen · 14 – 14.")
    // one card says a rule once (§14.3): "Months won breaks it." is the endgame
    // foot's last sentence two lines down, so the standing line never repeats it
    for m in [top, second, ten] {
      #expect(!SeasonFacts.line(m).contains("Months won"))
      #expect(SeasonFacts.footEndgame(m)?.hasSuffix("Level on points? Months won breaks it.") == true)
    }
  }

  @Test("rank 1: the margin is gap_to_next, else points − runner-up; an unknown margin is TOP, never level")
  func topOfTable() {
    // a table of one — the sandbox before anyone else joins
    #expect(SeasonFacts.line(heroMembership(rank: 1, of: 1, points: 32, leaderPts: 32, gapLeader: 0, leader: "Jerecho", runnerUp: nil, runnerPts: nil))
            == "Only you on the table so far.")
    // v1 (no names): `gap_to_next` is `lag()`, null on the top row — a payload
    // that carries one gets the margin, one that does not gets the honest line
    #expect(SeasonFacts.line(heroMembership(rank: 1, points: 32, leaderPts: 32, gapLeader: 0, gapNext: 22, v2: false)) == "You lead by 22 points.")
    #expect(SeasonFacts.line(heroMembership(rank: 1, points: 32, leaderPts: 32, gapLeader: 0, gapNext: nil, v2: false)) == "Top of the table.")
    // a name with no margin either way is still "top" — a tie is a claim
    #expect(SeasonFacts.line(heroMembership(rank: 1, points: 32, leaderPts: 32, gapLeader: 0, gapNext: nil, leader: "Jerecho", runnerUp: "Jade", runnerPts: nil))
            == "Top of the table.")
    // a blank name is no name (D130 needs a person to beat)
    #expect(SeasonFacts.line(heroMembership(rank: 1, points: 32, leaderPts: 32, gapLeader: 0, gapNext: 22, leader: "Jerecho", runnerUp: "  ", runnerPts: nil))
            == "You lead by 22 points.")
    // two of you: the margin from the runner-up's points, or from gap_to_next when that is all there is
    #expect(SeasonFacts.line(heroMembership(rank: 1, points: 32, leaderPts: 32, gapLeader: 0, gapNext: nil, leader: "Jerecho", runnerUp: "Jade", runnerPts: 10))
            == "You lead Jade by 22 · 32 – 10")
    #expect(SeasonFacts.line(heroMembership(rank: 1, points: 32, leaderPts: 32, gapLeader: 0, gapNext: 22, leader: "Jerecho", runnerUp: "Jade", runnerPts: nil))
            == "You lead Jade by 22 · 32 – 10")
    // level is the score alone; a wider field drops the score
    #expect(SeasonFacts.line(heroMembership(rank: 1, points: 32, leaderPts: 32, gapLeader: 0, leader: "Jerecho", runnerUp: "Jade", runnerPts: 32))
            == "Level with Jade · 32 – 32.")
    #expect(SeasonFacts.line(heroMembership(rank: 1, of: 10, points: 32, leaderPts: 32, gapLeader: 0, leader: "Jerecho", runnerUp: "Jade", runnerPts: 10))
            == "22 clear of Jade")
  }

  @Test("a field of ten: clear of / back of, and the rung above when one sits between")
  func tenWide() {
    let lead = heroMembership(rank: 1, of: 10, points: 40, leaderPts: 40, gapLeader: 0, leader: "Jerecho", runnerUp: "Jade", runnerPts: 34)
    #expect(SeasonFacts.line(lead) == "6 clear of Jade")
    let second = heroMembership(rank: 2, of: 10, points: 34, leaderPts: 40, gapLeader: 6, gapNext: 6, leader: "Galen", runnerUp: "Jerecho")
    #expect(SeasonFacts.line(second) == "6 back of Galen")   // rank 2: the rung above IS the leader
    let mid = heroMembership(rank: 5, of: 10, points: 22, leaderPts: 40, gapLeader: 18, gapNext: 3, leader: "Galen", runnerUp: "Jade")
    #expect(SeasonFacts.line(mid) == "18 back of Galen · 3 back of 4th")
    #expect(SeasonFacts.caption(mid) == "5th of 10")
    let last = heroMembership(rank: 10, of: 10, points: 2, leaderPts: 40, gapLeader: 38, gapNext: nil, leader: "Galen", runnerUp: "Jade")
    #expect(SeasonFacts.line(last) == "38 back of Galen")
    #expect(SeasonFacts.caption(last) == "10th of 10")
    let half = heroMembership(rank: 3, of: 10, points: 20.5, leaderPts: 40, gapLeader: 19.5, gapNext: 0.5, leader: "Galen", runnerUp: "Jade")
    #expect(SeasonFacts.line(half) == "19.5 back of Galen · 0.5 back of 2nd")
  }

  @Test("skew (no names): the sentences Home spoke before v2, unchanged")
  func skew() {
    #expect(SeasonFacts.line(heroMembership(v2: false)) == "12 points back of the lead.")
    #expect(SeasonFacts.line(heroMembership(gapLeader: 0, v2: false)) == "Level with the lead.")
    #expect(SeasonFacts.line(heroMembership(rank: 1, gapLeader: 0, gapNext: 6, v2: false)) == "You lead by 6 points.")
    // no margin on the top row is not a tie — v1 never carries one (see `topOfTable`)
    #expect(SeasonFacts.line(heroMembership(rank: 1, gapLeader: 0, gapNext: nil, v2: false)) == "Top of the table.")
    #expect(SeasonFacts.line(heroMembership(gapLeader: nil, v2: false)) == "In the race.")
    #expect(SeasonFacts.line(heroMembership(standing: false)) == "Standings start at the first posted round.")
    #expect(SeasonFacts.caption(heroMembership(standing: false)) == nil)
  }

  @Test("the whole matrix speaks — n × rank × structure × stake × skew, no crash, no empty line, D70 on every $0 cell")
  func matrix() {
    for n in [2, 10] {
      for rank in [1, (n + 1) / 2, n] {
        for structure in ["solo", "squads2"] {
          for stake in [0, 7500] {
            for v2 in [true, false] {
              let m = heroMembership(structure: structure, stake: stake, rank: rank, of: n, points: 20, leaderPts: rank == 1 ? 20 : 30,
                                     gapLeader: rank == 1 ? 0 : 10, gapNext: rank > 1 ? 4 : nil,
                                     leader: rank == 1 ? "Jerecho" : "Galen", runnerUp: rank == 1 ? "Jade" : "Jerecho",
                                     runnerPts: rank == 1 ? 14 : 20, v2: v2)
              let line = SeasonFacts.line(m)
              #expect(!line.isEmpty)
              #expect(SeasonFacts.caption(m) == "\(CSCopy.ordinal(rank)) of \(n)")
              let money = SeasonFacts.footMoney(m), owe = SeasonFacts.owe(m)
              if stake == 0 { #expect(money == nil && owe == nil) }
              else if v2 {
                #expect(money == "\(PotMath.money(n * 7500)) on the books · $0 collected")
                #expect(owe == "You still owe $75 · ask the Pro how to pay — money moves between you")
              } else if structure == "solo" {
                #expect(money == "\(PotMath.money(n * 7500)) on the books")   // `of` IS the roster; nobody counted the cash
                #expect(owe == nil)                                             // no `paid` → no claim
              } else {
                #expect(money == nil && owe == nil)                             // `of` counts squads — no number to claim (§16)
              }
              // D47 nouns only; "gap" is not a word Home says
              #expect(!line.lowercased().contains("gap"))
              if v2 && rank != 1 { #expect(line.hasPrefix("10 back of Galen")) }
              if v2 && rank == 1 { #expect(line == (n == 2 ? "You lead Jade by 6 · 20 – 14" : "6 clear of Jade")) }
            }
          }
        }
      }
    }
  }
}

// MARK: - the foot

@Suite struct SeasonFootContractTests {
  @Test("solo: the cap, what is posted, and the month's clock — never a floor (D140)")
  func soloRule() {
    let m = heroMembership(credits: 0, floor: 4)   // a floor the server should never send; solo ignores it
    #expect(SeasonFacts.footRule(m, today: "2026-09-02") == "Best 4 rounds a month count · 0 posted · 28 days left in September")
    #expect(SeasonFacts.footRule(heroMembership(credits: 2), today: "2026-09-29") == "Best 4 rounds a month count · 2 posted · 1 day left in September")
    #expect(SeasonFacts.footRule(heroMembership(credits: 3), today: "2026-09-30") == "Best 4 rounds a month count · 3 posted · last day of September")
    #expect(SeasonFacts.footRule(heroMembership(cap: nil, credits: 1), today: "2026-10-01") == "Every round counts · 1 posted · 30 days left in October")
    // before first tee the clock means nothing — the cap alone
    #expect(SeasonFacts.footRule(heroMembership(), today: "2026-07-01") == "Best 4 rounds a month count")
    #expect(SeasonFacts.footRule(heroMembership(cap: nil), today: "2026-07-01") == nil)
  }

  @Test("squads: the floor sentence Home has carried since D14, word for word")
  func squadRule() {
    #expect(SeasonFacts.footRule(heroMembership(structure: "squads2", credits: 2, floor: 4), today: "2026-09-02") == "4 a month · 2 to go")
    #expect(SeasonFacts.footRule(heroMembership(structure: "squads2", credits: 6, floor: 4), today: "2026-09-02") == "Minimum met · 6/4")
    #expect(SeasonFacts.footRule(heroMembership(structure: "squads2", credits: 0, floor: 4, partial: true), today: "2026-09-02") == "Partial month · no minimum")
    #expect(SeasonFacts.footRule(heroMembership(structure: "squads2", floor: nil), today: "2026-09-02") == "Best 4 rounds a month count")
    #expect(SeasonFacts.footRule(heroMembership(structure: "squads2", cap: nil, floor: nil), today: "2026-09-02") == nil)
  }

  @Test("D106 · the pot's two numbers to everyone; D70 · nothing on a $0 league")
  func money() {
    #expect(SeasonFacts.footMoney(heroMembership(stake: 0)) == nil)
    #expect(SeasonFacts.footMoney(heroMembership(stake: 7500, players: 2, paidCount: 0, collected: 0)) == "$150 on the books · $0 collected")
    #expect(SeasonFacts.footMoney(heroMembership(stake: 7500, players: 2, paidCount: 1, collected: 7500)) == "$150 on the books · $75 collected")
    #expect(SeasonFacts.footMoney(heroMembership(stake: 5000, of: 10, players: 8, paidCount: 3, collected: 15000)) == "$400 on the books · $150 collected")
    // D106 · the hero carries the Pot pane's third figure under the pane's own
    // condition — the cash is short AND someone is unpaid; nobody is named (D23)
    #expect(SeasonFacts.footMoney(heroMembership(stake: 7500, players: 2, paidCount: 0, collected: 0), stillOwe: true) == "$150 on the books · $0 collected · 2 still owe")
    #expect(SeasonFacts.footMoney(heroMembership(stake: 7500, players: 2, paidCount: 1, collected: 7500), stillOwe: true) == "$150 on the books · $75 collected · 1 still owe")
    #expect(SeasonFacts.footMoney(heroMembership(stake: 5000, of: 10, players: 8, paidCount: 3, collected: 15000), stillOwe: true) == "$400 on the books · $150 collected · 5 still owe")
    #expect(SeasonFacts.footMoney(heroMembership(stake: 7500, players: 2, paidCount: 2, collected: 15000), stillOwe: true) == "$150 on the books · $150 collected")
    // a v1 payload has no count to owe from; the row never asks
    #expect(SeasonFacts.footMoney(heroMembership(stake: 7500, v2: false), stillOwe: true) == "$150 on the books")
    #expect(SeasonFacts.seasonLine(heroMembership(stake: 7500, players: 2), today: "2026-09-02").hasSuffix("$150 on the books · $0 collected"))
    // skew: a solo league's `of` is its roster — roster × stake, and no claim about cash
    #expect(SeasonFacts.footMoney(heroMembership(stake: 7500, v2: false)) == "$150 on the books")
    #expect(SeasonFacts.footMoney(heroMembership(stake: 7500, buyIn: false)) == "$150 on the books")
    // a squads league's `of` counts squads, and squads × stake is a number nobody
    // owes — say nothing rather than something false (§16)
    #expect(SeasonFacts.footMoney(heroMembership(structure: "squads2", stake: 7500, v2: false)) == nil)
    #expect(SeasonFacts.footMoney(heroMembership(structure: "squads2", stake: 7500, buyIn: false)) == nil)
    // …until the server counts the roster: then squads speak like solo
    #expect(SeasonFacts.footMoney(heroMembership(structure: "squads2", stake: 7500, of: 2, players: 8, paidCount: 2, collected: 15000)) == "$600 on the books · $150 collected")
  }

  @Test("outside the season — before first tee, in the Final, after the wrap — the foot is the cap alone, solo AND squads (D140 / §14.0)")
  func footRuleOutsideSeason() {
    // the pulse still comes back (partial = true before first tee) and a floor
    // that would say "floors waived" about a month that is not in the season
    let stages: [(String, String, String)] = [("preseason", "2026-07-01", "active"), ("wrapped", "2026-11-03", "complete")]
    for (label, today, status) in stages {
      #expect(SeasonFacts.footRule(heroMembership(status: status, credits: 2, floor: 4, partial: true), today: today) == "Best 4 rounds a month count", "\(label)")
      #expect(SeasonFacts.footRule(heroMembership(structure: "squads2", status: status, credits: 2, floor: 4, partial: true), today: today) == "Best 4 rounds a month count", "\(label)")
      #expect(SeasonFacts.footRule(heroMembership(structure: "squads2", status: status, credits: 6, floor: 4), today: today) == "Best 4 rounds a month count", "\(label)")
      #expect(SeasonFacts.footRule(heroMembership(cap: nil, status: status, credits: 2, floor: 4), today: today) == nil, "\(label)")
      #expect(SeasonFacts.footRule(heroMembership(structure: "squads2", cap: nil, status: status, credits: 2, floor: 4), today: today) == nil, "\(label)")
    }
    // and a league still forming has no month at all
    #expect(SeasonFacts.footRule(heroMembership(structure: "squads2", phase: "setup", floor: 4, season: false), today: "2026-09-02") == "Best 4 rounds a month count")
  }

  @Test("§14.0 · the Cup Final is still a calendar month: the floor and the cap speak inside it, as close_month assesses them — the foot and the lead card's floor rung agree")
  func footRuleInTheFinal() {
    // Oct 10 is inside the Final (ends Nov 2); a full October has a floor
    #expect(SeasonFacts.footRule(heroMembership(structure: "squads2", status: "cup_final", credits: 2, floor: 4), today: "2026-10-10") == "4 a month · 2 to go")
    #expect(SeasonFacts.footRule(heroMembership(structure: "squads2", status: "cup_final", credits: 6, floor: 4), today: "2026-10-10") == "Minimum met · 6/4")
    // the edge month is partial and says so, in the Final as in the season
    #expect(SeasonFacts.footRule(heroMembership(structure: "squads2", status: "cup_final", credits: 2, floor: 4, partial: true), today: "2026-11-01") == "Partial month · no minimum")
    // solo: never a floor (D140), still the cap and the clock
    #expect(SeasonFacts.footRule(heroMembership(status: "cup_final", credits: 2, floor: 4), today: "2026-10-10") == "Best 4 rounds a month count · 2 posted · 21 days left in October")
    // and the FLOOR item fires on the same month — no contradiction on one
    // screen. The rung moved off the retired lead ladder and onto the ranker
    // (`home_dispatch`), which fires it on exactly this shape: squads, a real
    // floor, credits short of it, three days or fewer to the month's end.
  }

  @Test("D112 · the books open at lock — in setup a stake is a draft, and the foot says nothing")
  func footMoneySetup() {
    #expect(SeasonFacts.footMoney(heroMembership(stake: 7500, phase: "setup", players: 2, season: false)) == nil)
    #expect(SeasonFacts.footMoney(heroMembership(stake: 7500, phase: "setup", players: 2)) == nil)
    // the same payload one phase later speaks
    #expect(SeasonFacts.footMoney(heroMembership(stake: 7500, phase: "draft", players: 2)) == "$150 on the books · $0 collected")
    #expect(SeasonFacts.footMoney(heroMembership(stake: 7500, phase: "season", players: 2)) == "$150 on the books · $0 collected")
  }

  @Test("D129 · the owe matrix: the note, the Pro's own line (the sheet's word, no date — their own terms), the member's ask; 'was due' behind today, 'by' ahead of it; never in setup")
  func oweMatrix() {
    let today = "2026-09-02"
    // a note is how to pay — for a member; the Pro wrote it and has nobody to pay
    #expect(SeasonFacts.owe(heroMembership(stake: 7500, paid: false, note: "Venmo @casey"), today: today) == "You still owe $75 · Venmo @casey")
    #expect(SeasonFacts.owe(heroMembership(stake: 7500, role: "commissioner", paid: false, note: "Venmo @casey"), today: today) == "Your own $75 isn't marked in yet")
    // no note: the Pro has nobody to ask; a member is told who to ask
    #expect(SeasonFacts.owe(heroMembership(stake: 7500, role: "commissioner", paid: false), today: today) == "Your own $75 isn't marked in yet")
    #expect(SeasonFacts.owe(heroMembership(stake: 7500, role: "player", paid: false), today: today) == "You still owe $75 · ask the Pro how to pay — money moves between you")
    // the day: behind today is "was due", today and ahead is "by"
    #expect(SeasonFacts.owe(heroMembership(stake: 7500, paid: false, due: "2026-08-29"), today: today) == "You still owe $75 · ask the Pro how to pay — money moves between you · was due Sat Aug 29")
    #expect(SeasonFacts.owe(heroMembership(stake: 7500, paid: false, due: "2026-09-02"), today: today) == "You still owe $75 · ask the Pro how to pay — money moves between you · by Wed Sep 2")
    #expect(SeasonFacts.owe(heroMembership(stake: 7500, paid: false, due: "2026-09-05"), today: today) == "You still owe $75 · ask the Pro how to pay — money moves between you · by Sat Sep 5")
    // the Pro set the date — it is not a deadline on them, so their line carries none
    #expect(SeasonFacts.owe(heroMembership(stake: 7500, role: "commissioner", paid: false, due: "2026-08-29"), today: today) == "Your own $75 isn't marked in yet")
    #expect(SeasonFacts.owe(heroMembership(stake: 7500, role: "commissioner", paid: false, due: "2026-09-05"), today: today) == "Your own $75 isn't marked in yet")
    #expect(SeasonFacts.owe(heroMembership(stake: 5000, paid: false, note: "Venmo @casey", due: "2026-09-05"), today: today) == "You still owe $50 · Venmo @casey · by Sat Sep 5")
    // a day that does not parse is no day
    #expect(SeasonFacts.owe(heroMembership(stake: 7500, paid: false, due: "soon"), today: today) == "You still owe $75 · ask the Pro how to pay — money moves between you")
    // D112 · nothing is owed before lock, whatever the payload says
    #expect(SeasonFacts.owe(heroMembership(stake: 7500, phase: "setup", paid: false, note: "Venmo @casey", due: "2026-09-05", season: false), today: today) == nil)
    #expect(SeasonFacts.owe(heroMembership(stake: 7500, phase: "setup", role: "commissioner", paid: false), today: today) == nil)
    // paid, or unknown, is no claim (D23 — only a debt of yours is spoken)
    #expect(SeasonFacts.owe(heroMembership(stake: 7500, paid: true, note: "Venmo @casey", due: "2026-08-29"), today: today) == nil)
    #expect(SeasonFacts.owe(heroMembership(stake: 7500, paid: nil, due: "2026-08-29"), today: today) == nil)
    #expect(SeasonFacts.owe(heroMembership(stake: 0, paid: false, note: "Venmo @casey"), today: today) == nil)
  }

  @Test("D129 · self-only, unpaid only: the stake, the Pro's note, the day")
  func owe() {
    #expect(SeasonFacts.owe(heroMembership(stake: 7500, paid: false)) == "You still owe $75 · ask the Pro how to pay — money moves between you")
    #expect(SeasonFacts.owe(heroMembership(stake: 5000, paid: false, note: "Venmo @casey", due: "2026-09-05"), today: "2026-09-02") == "You still owe $50 · Venmo @casey · by Sat Sep 5")
    #expect(SeasonFacts.owe(heroMembership(stake: 5000, paid: false, note: "  ")) == "You still owe $50 · ask the Pro how to pay — money moves between you")
    #expect(SeasonFacts.owe(heroMembership(stake: 7500, paid: true)) == nil)
    #expect(SeasonFacts.owe(heroMembership(stake: 7500, paid: nil)) == nil)
    #expect(SeasonFacts.owe(heroMembership(stake: 0, paid: false)) == nil)        // D70
    #expect(SeasonFacts.owe(heroMembership(stake: 7500, v2: false)) == nil)      // skew: no `paid`, no claim
  }
}

// MARK: - D121 · the row per other league

@Suite struct SeasonRowContractTests {
  @Test("in season: week, place, the race, the money — the hard-look's own line")
  func inSeason() {
    let fellas = heroMembership(name: "Fellas", stake: 7500, starts: "2026-07-20", ends: "2027-01-18", rank: 1, points: 31,
                                leaderPts: 31, gapLeader: 0, leader: "Jerecho", runnerUp: "Jade", runnerPts: 9, players: 2)
    #expect(SeasonFacts.seasonLine(fellas, today: "2026-09-02")
              == "Week 7 of 26 · 1st of 2, 22 clear of Jade · $150 on the books · $0 collected")
    #expect(SeasonFacts.seasonLine(heroMembership(), today: "2026-09-02") == "Week 5 of 13 · 2nd of 2, 12 back of Galen")
    #expect(SeasonFacts.seasonLine(heroMembership(gapLeader: 0), today: "2026-09-02") == "Week 5 of 13 · 2nd of 2, level with Galen")
    #expect(SeasonFacts.seasonLine(heroMembership(rank: 1, gapLeader: 0, runnerUp: "Galen", runnerPts: 9), today: "2026-09-02") == "Week 5 of 13 · 1st of 2, level with Galen")
    // skew
    #expect(SeasonFacts.seasonLine(heroMembership(v2: false), today: "2026-09-02") == "Week 5 of 13 · 2nd of 2, 12 back of the lead")
    #expect(SeasonFacts.seasonLine(heroMembership(stake: 7500, v2: false), today: "2026-09-02") == "Week 5 of 13 · 2nd of 2, 12 back of the lead · $150 on the books")
    #expect(SeasonFacts.seasonLine(heroMembership(standing: false), today: "2026-09-02") == "Week 5 of 13")
  }

  @Test("before first tee, the final, the wrap, forming")
  func otherStages() {
    #expect(SeasonFacts.seasonLine(heroMembership(stake: 100, starts: "2026-09-05", ends: "2026-12-05", players: 5), today: "2026-09-02") == "First tee Sat Sep 5 · 5 on the roster")
    #expect(SeasonFacts.seasonLine(heroMembership(starts: "2026-09-05", ends: "2026-12-05", standing: false), today: "2026-09-02") == "First tee Sat Sep 5")
    // §14.3 · the Final is scored fresh — 23 days to Nov 2 is 4 weeks on the clock, and no rank
    #expect(SeasonFacts.seasonLine(heroMembership(status: "cup_final", rank: 1), today: "2026-10-10")
              == "Cup Final · 4 weeks left")
    #expect(SeasonFacts.seasonLine(heroMembership(status: "complete"), today: "2026-11-03") == "Season complete")
    #expect(SeasonFacts.seasonLine(heroMembership(phase: "setup", season: false), today: "2026-09-02") == "Forming")
    #expect(SeasonFacts.seasonLine(heroMembership(phase: "draft", season: false), today: "2026-09-02") == "Squads drawing")
  }

  @Test("§14.3 · the Cup Final row is a clock, never the table's rank — '1 week left' at one week or less, the web's sentence")
  func cupFinalClock() {
    // ends Nov 2: Oct 22 is 11 days out (2 weeks), Oct 30 is 3 (the last week), Nov 2 is the day
    let final = heroMembership(status: "cup_final", rank: 1, points: 40, leaderPts: 40, gapLeader: 0, leader: "Jerecho", runnerUp: "Jade", runnerPts: 30)
    #expect(SeasonFacts.seasonLine(final, today: "2026-10-22") == "Cup Final · 2 weeks left")
    #expect(SeasonFacts.seasonLine(final, today: "2026-10-30") == "Cup Final · 1 week left")
    #expect(SeasonFacts.seasonLine(final, today: "2026-11-02") == "Cup Final · 1 week left")
    // the clock never runs negative — a Final the engine has not wrapped yet is still its last week
    #expect(SeasonFacts.seasonLine(final, today: "2026-11-05") == "Cup Final · 1 week left")
    // the season's place is not the Final's place — no ordinal, no margin, no money
    for d in ["2026-10-10", "2026-10-22", "2026-10-30"] {
      let s = SeasonFacts.seasonLine(heroMembership(stake: 7500, status: "cup_final", rank: 1, gapLeader: 0, gapNext: 22, players: 2), today: d)
      #expect(!s.contains("1st") && !s.contains("clear") && !s.contains("$"), "\(s)")
    }
    // one clock for the row and the hero — the web's words, never "0 left"
    #expect(SeasonFacts.finalClock(0) == "1 week left" && SeasonFacts.finalClock(1) == "1 week left" && SeasonFacts.finalClock(2) == "2 weeks left")
    #expect(SeasonFacts.finalClock(-1) == "1 week left" && SeasonFacts.finalClock(4) == "4 weeks left")
    // the hero's caption: a payload that carries no seed keeps the table's place
    #expect(SeasonFacts.seedCaption(final) == "1st of 2")
    #expect(SeasonFacts.seedCaption(heroMembership(status: "cup_final", standing: false)) == nil)
  }

  @Test("D138 · the Final is a field of two: a seed is the LOCKED `cup_finalists` row, never the table's rank; a non-finalist keeps their place and is told whose cup it is")
  func finalIsAFieldOfTwo() {
    // the top of the table at lock, still top: seed 1, and gold
    let top = heroMembership(status: "cup_final", rank: 1, of: 8, points: 40, leaderPts: 40, gapLeader: 0, gapNext: 6,
                             leader: "Jerecho", runnerUp: "Jade", runnerPts: 34, seed: 1, finalists: ["Jerecho", "Jade"])
    #expect(SeasonFacts.finalFigure(top) == "1st" && SeasonFacts.seedCaption(top) == "1st seed")
    #expect(SeasonFacts.finalLine(top, weeksLeft: 2) == "Four weeks, scored fresh. Whoever's hottest takes the cup. 2 weeks left.")
    #expect(SeasonFacts.finalLine(top, weeksLeft: 1) == "Four weeks, scored fresh. Whoever's hottest takes the cup. 1 week left.")
    // the 2 seed has since passed the 1 seed on the table — the figure is STILL the seed
    let two = heroMembership(status: "cup_final", rank: 1, of: 8, points: 41, leaderPts: 41, gapLeader: 0, gapNext: 1,
                             leader: "Jade", runnerUp: "Jerecho", runnerPts: 40, seed: 2, finalists: ["Jerecho", "Jade"])
    #expect(SeasonFacts.finalFigure(two) == "2nd" && SeasonFacts.seedCaption(two) == "2nd seed")
    // a non-finalist: their place, whose cup it is, and the race that is still theirs
    let out = heroMembership(status: "cup_final", rank: 5, of: 8, points: 28, leaderPts: 40, gapLeader: 12, gapNext: 3,
                             leader: "Galen", runnerUp: nil, runnerPts: nil, finalists: ["Galen", "Jade"])
    #expect(SeasonFacts.finalFigure(out) == "5th" && SeasonFacts.seedCaption(out) == "5th of 8")
    // …and the clock ends the sentence on BOTH branches, as the web foots both of its branches with it
    #expect(SeasonFacts.finalLine(out, weeksLeft: 3) == "Galen v Jade for the cup. Your place on the table is still live — 12 back of Galen · 3 back of 4th. 3 weeks left.")
    #expect(SeasonFacts.finalLine(out, weeksLeft: 1) == "Galen v Jade for the cup. Your place on the table is still live — 12 back of Galen · 3 back of 4th. 1 week left.")
    // level with the leader on the table and out of the Final: the race clause keeps its full stop, once,
    // and is lowered after the dash (the phone's rule — the web pastes it capitalised)
    let lvl = heroMembership(status: "cup_final", rank: 2, of: 8, points: 40, leaderPts: 40, gapLeader: 0,
                             leader: "Galen", finalists: ["Galen", "Jade"])
    #expect(SeasonFacts.finalLine(lvl, weeksLeft: 3) == "Galen v Jade for the cup. Your place on the table is still live — level with Galen · 40 – 40. 3 weeks left.")
    // a non-finalist who has since climbed to the top of the table: the figure says 1st, the caption never says seed
    let climbed = heroMembership(status: "cup_final", rank: 1, of: 8, points: 41, leaderPts: 41, gapLeader: 0, gapNext: 6,
                                 leader: "Jerecho", runnerUp: "Jade", runnerPts: 35, finalists: ["Galen", "Jade"])
    #expect(SeasonFacts.finalFigure(climbed) == "1st" && SeasonFacts.seedCaption(climbed) == "1st of 8")
    #expect(SeasonFacts.finalLine(climbed, weeksLeft: 2) == "Galen v Jade for the cup. Your place on the table is still live — 6 clear of Jade. 2 weeks left.")
    // squads: the names are the squads' own (never first-named)
    let sq = heroMembership(structure: "squads2", status: "cup_final", rank: 3, of: 4, points: 30, leaderPts: 44, gapLeader: 14, gapNext: 2,
                            leader: "Sunday Money", finalists: ["Sunday Money", "The Regulars"])
    #expect(SeasonFacts.finalLine(sq, weeksLeft: 4) == "Sunday Money v The Regulars for the cup. Your place on the table is still live — 14 back of Sunday Money · 2 back of 2nd. 4 weeks left.")
    // a payload that cannot say (v1, or no finalists yet): the Final's own sentence, and the table's place
    let v1 = heroMembership(status: "cup_final", rank: 5, of: 8, v2: false)
    #expect(SeasonFacts.finalFigure(v1) == "5th" && SeasonFacts.seedCaption(v1) == "5th of 8")
    #expect(SeasonFacts.finalLine(v1, weeksLeft: 4) == "Four weeks, scored fresh. Whoever's hottest takes the cup. 4 weeks left.")
    #expect(SeasonFacts.finalLine(heroMembership(status: "cup_final", rank: 5, of: 8, finalists: ["Galen"]), weeksLeft: 4).hasPrefix("Four weeks, scored fresh."))
    #expect(SeasonFacts.finalFigure(heroMembership(status: "cup_final", standing: false)) == nil)
    // a seed never reads on the season's own captions or on the D121 row
    #expect(SeasonFacts.caption(top) == "1st of 8")
    #expect(!SeasonFacts.seasonLine(top, today: "2026-10-22").contains("seed"))
  }
  @Test("the race at the top with no name: 'N clear' when the margin is known, nothing when it is not — never 'level with' nobody")
  func raceTopNoName() {
    // v1 carries no runner-up; a v2 payload can carry a blank one (D130 needs a person)
    #expect(SeasonFacts.race(heroMembership(rank: 1, points: 32, leaderPts: 32, gapLeader: 0, gapNext: 22, v2: false).standing!) == "22 clear")
    #expect(SeasonFacts.race(heroMembership(rank: 1, points: 32, leaderPts: 32, gapLeader: 0, gapNext: 0.5, v2: false).standing!) == "0.5 clear")
    #expect(SeasonFacts.race(heroMembership(rank: 1, points: 32, leaderPts: 32, gapLeader: 0, gapNext: nil, leader: "Jerecho", runnerUp: "  ", runnerPts: 10).standing!) == "22 clear")
    // level, with nobody to be level with, is nothing
    #expect(SeasonFacts.race(heroMembership(rank: 1, points: 32, leaderPts: 32, gapLeader: 0, gapNext: nil, leader: "Jerecho", runnerUp: nil, runnerPts: 32).standing!) == nil)
    #expect(SeasonFacts.race(heroMembership(rank: 1, points: 32, leaderPts: 32, gapLeader: 0, gapNext: 0, leader: "Jerecho", runnerUp: "", runnerPts: nil).standing!) == nil)
    #expect(SeasonFacts.race(heroMembership(rank: 1, points: nil, leaderPts: nil, gapLeader: 0, gapNext: nil, v2: false).standing!) == nil)
    // on the row itself
    #expect(SeasonFacts.seasonLine(heroMembership(rank: 1, points: 32, leaderPts: 32, gapLeader: 0, gapNext: nil, leader: "Jerecho", runnerUp: nil, runnerPts: 32), today: "2026-09-02")
            == "Week 5 of 13 · 1st of 2")
  }

  @Test("`Membership.headcount` is the one headcount: the server's D207 count (`roster`, v2), else the pot's players, else a solo league's `of`; squads' `of` counts squads and says nothing")
  func rosterProducer() {
    // the server's own count wins — it excludes the suspended and the deleted, which `players` does not
    #expect(heroMembership(stake: 7500, players: 8, roster: 7).headcount == 7)
    #expect(heroMembership(structure: "squads2", of: 2, roster: 6).headcount == 6)
    #expect(heroMembership(of: 5, roster: 0).headcount == 5)   // a zero is no count
    #expect(heroMembership(stake: 7500, players: 8).headcount == 8)
    #expect(heroMembership(structure: "squads2", stake: 7500, players: 8).headcount == 8)
    // a $0 league carries no buy_in — the solo table's `of` is the count
    #expect(heroMembership(of: 5).headcount == 5)
    #expect(heroMembership(structure: "squads2", of: 2).headcount == nil)
    #expect(heroMembership(of: 0, players: 0).headcount == nil)
    #expect(heroMembership(stake: 7500, players: 8, roster: 7).roster == 7 && heroMembership(of: 5).roster == nil)
  }

  @Test("before first tee: 'on the roster' (D47's headcount noun) counts buy_in.players, else a solo league's `of`; squads say nothing")
  func preseasonRoster() {
    // the server counted the roster — squads or solo, the count is the count
    #expect(SeasonFacts.seasonLine(heroMembership(structure: "squads2", stake: 100, starts: "2026-09-05", ends: "2026-12-05", of: 2, players: 8), today: "2026-09-02")
            == "First tee Sat Sep 5 · 8 on the roster")
    // a suspended (or tombstoned) member: the room counts them and the D207 count does not — the row says
    // the room's number (`members`) on every league, whatever the stake, and falls to the D207 count only
    // when the server did not count (a v1 payload, or the count block raised)
    #expect(SeasonFacts.seasonLine(heroMembership(structure: "squads2", stake: 100, starts: "2026-09-05", ends: "2026-12-05", of: 2, players: 8, roster: 7, members: 8), today: "2026-09-02")
            == "First tee Sat Sep 5 · 8 on the roster")
    #expect(SeasonFacts.seasonLine(heroMembership(structure: "squads2", stake: 0, starts: "2026-09-05", ends: "2026-12-05", of: 2, roster: 7, members: 8), today: "2026-09-02")
            == "First tee Sat Sep 5 · 8 on the roster")
    #expect(SeasonFacts.seasonLine(heroMembership(structure: "squads2", stake: 0, starts: "2026-09-05", ends: "2026-12-05", of: 2, roster: 7), today: "2026-09-02")
            == "First tee Sat Sep 5 · 7 on the roster")
    #expect(SeasonFacts.seasonLine(heroMembership(structure: "squads2", stake: 100, starts: "2026-09-05", ends: "2026-12-05", of: 2, players: 8, roster: 7), today: "2026-09-02")
            == "First tee Sat Sep 5 · 7 on the roster")
    // no buy_in (a $0 league, or v1): a solo league's `standing.of` IS the roster…
    #expect(SeasonFacts.seasonLine(heroMembership(stake: 0, starts: "2026-09-05", ends: "2026-12-05", of: 5), today: "2026-09-02")
            == "First tee Sat Sep 5 · 5 on the roster")
    #expect(SeasonFacts.seasonLine(heroMembership(stake: 100, starts: "2026-09-05", ends: "2026-12-05", of: 5, v2: false), today: "2026-09-02")
            == "First tee Sat Sep 5 · 5 on the roster")
    // …and a squads league's `of` counts squads, which is not a headcount
    #expect(SeasonFacts.seasonLine(heroMembership(structure: "squads2", stake: 0, starts: "2026-09-05", ends: "2026-12-05", of: 2), today: "2026-09-02")
            == "First tee Sat Sep 5")
    #expect(SeasonFacts.seasonLine(heroMembership(structure: "squads2", stake: 100, starts: "2026-09-05", ends: "2026-12-05", of: 2, v2: false), today: "2026-09-02")
            == "First tee Sat Sep 5")
    // a count of nobody is no count
    #expect(SeasonFacts.seasonLine(heroMembership(stake: 100, starts: "2026-09-05", ends: "2026-12-05", of: 0, players: 0), today: "2026-09-02") == "First tee Sat Sep 5")
    // "N in" is the calendar's word for RSVPs — never the roster's
    #expect(!SeasonFacts.seasonLine(heroMembership(stake: 100, starts: "2026-09-05", ends: "2026-12-05", players: 5), today: "2026-09-02").hasSuffix(" in"))
  }

  @Test("the race clause at the top: a margin when one is known, nothing when it is not — never 'level' by default")
  func raceAtTheTop() {
    // v1 (no runner-up name): the margin alone, or no clause at all
    #expect(SeasonFacts.seasonLine(heroMembership(rank: 1, points: 32, leaderPts: 32, gapLeader: 0, gapNext: 22, v2: false), today: "2026-09-02")
            == "Week 5 of 13 · 1st of 2, 22 clear")
    #expect(SeasonFacts.seasonLine(heroMembership(rank: 1, points: 32, leaderPts: 32, gapLeader: 0, gapNext: nil, v2: false), today: "2026-09-02")
            == "Week 5 of 13 · 1st of 2")
    // a name with no margin: no clause; a margin of nothing: level, by name
    #expect(SeasonFacts.seasonLine(heroMembership(rank: 1, points: 32, leaderPts: 32, gapLeader: 0, gapNext: nil, leader: "Jerecho", runnerUp: "Jade", runnerPts: nil), today: "2026-09-02")
            == "Week 5 of 13 · 1st of 2")
    #expect(SeasonFacts.seasonLine(heroMembership(rank: 1, points: 32, leaderPts: 32, gapLeader: 0, gapNext: nil, leader: "Jerecho", runnerUp: "Jade", runnerPts: 32), today: "2026-09-02")
            == "Week 5 of 13 · 1st of 2, level with Jade")
    // the clause itself, off the standing
    let st = heroMembership(rank: 1, points: 32, leaderPts: 32, gapLeader: 0, gapNext: 22, v2: false).standing!
    #expect(SeasonFacts.race(st) == "22 clear")
    #expect(SeasonFacts.race(heroMembership(rank: 1, gapLeader: 0, gapNext: nil, v2: false).standing!) == nil)
    #expect(SeasonFacts.race(heroMembership(rank: 1, gapLeader: 0, gapNext: 0, v2: false).standing!) == nil)
    #expect(SeasonFacts.race(heroMembership(rank: 2, gapLeader: 0, v2: false).standing!) == "level with the lead")
    #expect(SeasonFacts.race(heroMembership(rank: 2, gapLeader: nil, v2: false).standing!) == nil)
  }
}

