// Cup Season — synthetic `native_home()` (the boot read) and the other reads a
// signed-in boot makes before any screen: `founding_ids`, `league_looks`.

#if DEBUG
import Foundation
import CupSeasonKit

/// A synthetic season, as `native_home` and the season reads both describe it.
struct SynthLeague: Sendable {
  let n: Int
  let name: String
  let code: String
  let solo: Bool
  let finish: String           // "cup_final" | "points_table"
  let buyinCents: Int
  let memberOrder: [Int]       // roster order (squads are drawn from it)
  let targets: [Int: Int]      // season totals of the golfers the table invents
  let weeksTotal: Int
  let week: Int                // current week (1-based)
  let status: String           // "active" | "cup_final" | "complete"
  /// Filled from the entries (`SyntheticWorld.buildLeagues`): table order,
  /// rank 1 first, and the matching points — so the Book, the season page and
  /// `native_home` can never disagree.
  var members: [Int] = []
  var points: [Double] = []
  var id: UUID { fid(n) }
  var ids: String { fids(n) }
  var seasonN: Int { n + 100 }
  var seasonIds: String { fids(seasonN) }
  func memberIds(_ person: Int) -> String { fids(n * 100 + person) }
}

extension SyntheticWorld {
  /// The seasons in this world, built once at init. Empty unless the
  /// scenario is about one.
  func buildLeagues() -> [SynthLeague] {
    guard hasSeasons else { return [] }
    let final = scenario == .seasonFinal, done = scenario == .ceremony
    let status = done ? "complete" : final ? "cup_final" : "active"
    var base = [
      SynthLeague(n: 1_001, name: "Fixture Cup League", code: "FIXCUP", solo: true, finish: "cup_final", buyinCents: 4_000,
                  memberOrder: [2, 1, 4, 3, 9, 6, 5, 7],
                  targets: [2: 58, 4: 47, 3: 38, 9: 33, 6: 29, 5: 22, 7: 14],
                  weeksTotal: 13, week: done ? 13 : final ? 11 : 6, status: status),
      SynthLeague(n: 1_002, name: "Placeholder Squads League", code: "FIXSQD", solo: false, finish: "points_table", buyinCents: 0,
                  memberOrder: [6, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12],
                  targets: [6: 31, 2: 27, 3: 25, 4: 22, 5: 21, 7: 19, 8: 18, 9: 16, 10: 12, 11: 10, 12: 7],
                  weeksTotal: 10, week: done ? 10 : 4, status: done ? "complete" : "active"),
    ]
    for i in base.indices {
      let all = entries(base[i])
      let table = base[i].memberOrder.map { pn in (pn, all[pn, default: []].reduce(0) { $0 + $1.contribution }) }
        .sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0 < $1.0 }
      base[i].members = table.map(\.0)
      base[i].points = table.map { Double($0.1) }
    }
    return base
  }

  func league(_ ids: String?) -> SynthLeague? { leagues.first { $0.ids == ids?.lowercased() || $0.seasonIds == ids?.lowercased() } }

  /// The season's calendar, from the league's week and length.
  func seasonDates(_ l: SynthLeague) -> (starts: Int, ends: Int, weekEnds: Int) {
    let starts = -((l.week - 1) * 7 + 3)                 // three days into this week
    return (starts, starts + l.weeksTotal * 7 - 1, starts + l.week * 7 - 1)
  }

  /// Squads for the squads league: three sides of four.
  var squadNames: [(n: Int, name: String, color: Int)] {
    [(6_001, "Team Placeholder", 0), (6_002, "Team Stub", 1), (6_003, "Team Sample", 2)]
  }
  func squadOf(_ person: Int, in l: SynthLeague) -> Int? {
    guard !l.solo, let i = l.memberOrder.firstIndex(of: person) else { return nil }
    return squadNames[i % 3].n
  }
  /// Squad points: the sum of the members' contributions.
  func squadTable(_ l: SynthLeague) -> [(n: Int, name: String, color: Int, points: Double)] {
    squadNames.map { s in
      let pts = l.memberOrder.enumerated().filter { squadOf($0.element, in: l) == s.n }
        .compactMap { pn in l.members.firstIndex(of: pn.element).map { l.points[$0] } }.reduce(0, +)
      return (s.n, s.name, s.color, pts)
    }.sorted { $0.points > $1.points }
  }

  // MARK: native_home

  func meRPC(_ name: String, _ r: SynthRequest) -> SyntheticReply? {
    switch name {
    case "native_home": return SynthOut.json(nativeHome())
    case "founding_ids": return SynthOut.json(["founder": NSNull(), "members": [String]()])
    case "founder_id": return SynthOut.json(NSNull())
    case "league_looks": return SynthOut.json([String: Any]())
    default: return nil
    }
  }

  func profileJSON() -> [String: Any] {
    let card = cardDone
    let mine = myRounds
    let last = mine.first
    return [
      "id": me.ids,
      // Until the card is made, the signup trigger's own guess (D325): the
      // email's local part, which the gate knows not to pre-fill.
      "display_name": card ? state.get("name", me.name) : "fixture_avery",
      "handle": card ? state.get("handle", me.handle) : NSNull(),
      "marker": card ? state.get("marker", me.marker) : NSNull(),
      "city": card ? me.city : NSNull(),
      "home_course": card ? courses[0].name : NSNull(),
      "index_current": hasRounds ? me.index : NSNull(),
      "index_prev": hasRounds ? 13.1 : NSNull(),
      "index_source": hasRounds ? "app" : "manual",
      "photo_path": NSNull(),
      "rounds_count": mine.count,
      "member_since": stamp(-200, 10),
      "is_founder": false,
      "last_round_on": last.map { day($0.day) } ?? NSNull(),
      "last_gross": last?.gross ?? NSNull(),
      "last_round_id": last?.ids ?? NSNull(),
      "days_since_round": last.map { -$0.day } ?? NSNull(),
      "scan_consent_at": NSNull(),
    ]
  }

  func membershipJSON(_ l: SynthLeague) -> [String: Any] {
    let d = seasonDates(l)
    let rank = (l.members.firstIndex(of: me.n) ?? 0) + 1
    let myPoints = l.points[rank - 1]
    let done = l.status == "complete"
    var season: [String: Any] = [
      "id": l.seasonIds, "number": 2, "starts_on": day(d.starts), "ends_on": day(d.ends), "status": l.status,
      "timezone": "America/Phoenix", "grace_hours": 36,
      "champion_squad_id": NSNull(), "champion_member_id": done ? l.memberIds(l.members[0]) : NSNull(),
      "points_king_member_id": done ? l.memberIds(l.members[0]) : NSNull(), "tiebreak_rung": NSNull(),
      "week_no": l.week, "weeks_total": l.weeksTotal, "week_ends_on": day(d.weekEnds),
      "days_to_first_tee": NSNull(), "days_left": max(0, d.ends),
      "final_opens_on": l.finish == "cup_final" ? day(d.ends - 27) : NSNull(),
    ]
    if done { season["days_left"] = 0 }
    let up = rank > 1 ? ["name": person(l.members[rank - 2]).first, "points": l.points[rank - 2]] as [String: Any] : nil
    let down = rank < l.members.count ? ["name": person(l.members[rank]).first, "points": l.points[rank]] as [String: Any] : nil
    var standing: [String: Any] = [
      "rank": rank, "of": l.solo ? l.members.count : 3, "points": myPoints, "prev_rank": rank + 1,
      "leader_squad_id": NSNull(), "leader_points": l.points[0], "gap_to_leader": l.points[0] - myPoints,
      "gap_to_next": rank > 1 ? l.points[rank - 2] - myPoints : NSNull(),
      "leader_name": person(l.members[0]).first, "runner_up_name": person(l.members[1]).first,
      "runner_up_points": l.points[1], "seed": NSNull(), "finalists": NSNull(),
      "next_up": up ?? NSNull(), "next_down": down ?? NSNull(),
      "points_rank": rank, "points_tied": false,
    ]
    var squad: Any = NSNull()
    if !l.solo, let sq = squadOf(me.n, in: l), let s = squadNames.first(where: { $0.n == sq }) {
      squad = ["id": fids(s.n), "name": s.name, "color": s.color]
      let t = squadTable(l)
      let at = t.firstIndex { $0.n == s.n } ?? 0
      standing["rank"] = at + 1; standing["of"] = t.count
      standing["points"] = t[at].points; standing["leader_points"] = t[0].points
      standing["leader_name"] = t[0].name; standing["leader_squad_id"] = fids(t[0].n)
      standing["gap_to_leader"] = t[0].points - t[at].points
      standing["gap_to_next"] = at > 0 ? t[at - 1].points - t[at].points : NSNull()
      standing["runner_up_name"] = t[1].name; standing["runner_up_points"] = t[1].points
      standing["next_up"] = at > 0 ? ["name": t[at - 1].name, "points": t[at - 1].points] as Any : NSNull() as Any
      standing["next_down"] = at + 1 < t.count ? ["name": t[at + 1].name, "points": t[at + 1].points] as Any : NSNull() as Any
      standing["points_rank"] = at + 1; standing["prev_rank"] = at + 1
    }
    if l.status == "cup_final" {   // the Final seats two (D138)
      standing["seed"] = rank <= 2 ? rank as Any : NSNull() as Any
      standing["finalists"] = l.members.prefix(2).map { person($0).first }
    }
    let stake = l.buyinCents > 0
    return [
      "league_id": l.ids, "name": l.name, "code": l.code, "phase": done ? "complete" : "season", "sandbox": false,
      "role": pro(l) == me.n ? "commissioner" : "player", "member_id": l.memberIds(me.n), "marker": me.marker,
      "commissioner_name": l.n == 1_002 ? me.name : person(2).name,
      "settings": [
        "structure": l.solo ? "solo" : "squads3", "preset": "standard", "counting_cap": 4, "participation_floor": 2,
        "floor_penalty": "minus_three", "handicap_allowance": 100, "buyin_cents": l.buyinCents,
        "payout_champ": stake ? 60 : 0, "payout_runnerup": stake ? 25 : 0, "payout_king": stake ? 15 : 0,
        "finish": l.finish, "locked_at": stamp(d.starts - 10, 19),
      ] as [String: Any],
      "season": season,
      "squad": squad,
      "standing": standing,
      "pulse": ["credits": 2, "floor": 2, "at_floor": true, "partial": false, "joined_this_month": false, "bye_available": true],
      "buy_in": stake ? ["paid": true, "note": "Pay the Pro before week 2.", "due_on": day(d.starts + 7),
                         "players": l.members.count, "paid_count": l.members.count - 2,
                         "collected_cents": (l.members.count - 2) * l.buyinCents] as [String: Any] : NSNull(),
      "roster": l.members.count, "members": l.members.count,
      "pro_name": l.n == 1_002 ? me.first : person(2).first,
      "renewal_status": NSNull(), "in_season": true,
      "last_season": ["number": 1, "ended_on": day(d.starts - 30), "champion_name": person(6).first,
                      "champion_is_me": false, "my_rank": 3, "of": l.members.count] as [String: Any],
      "clash": NSNull(),
    ]
  }

  func nativeHome() -> [String: Any] {
    var out: [String: Any] = [
      "profile": profileJSON(),
      "memberships": leagues.map { membershipJSON($0) },
      "invites": [Any](),
      "live_round": NSNull(),
      "upcoming_rounds": upcomingRounds(),
      "events": eventsForMe(),
      "open_duels": [Any](),
      "flags": ["ios": ["min_build": 0]],
      "generated_at": stamp(0, 7, 30),
    ]
    if scenario == .brandNew || scenario == .cardGate { out["upcoming_rounds"] = [Any]() }
    return out
  }
}
#endif
