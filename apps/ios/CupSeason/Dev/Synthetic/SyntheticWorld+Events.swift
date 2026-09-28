// Cup Season — synthetic reads for the RYDER, the MAJOR and the callout: the
// room's six table reads (`events` single, teams, golfers, weeks, pairings,
// the scoreboard view), the Major's board and cards, the lineage, this week's
// targets, the room's posts, and the `native_home.events` rows.
// Contracts traced from EventsRepository / EventRoomScreen / RyderRoomView /
// MajorRoomView / CalloutRoomView (2026-09-28).

#if DEBUG
import Foundation
import CupSeasonKit

struct SynthEvent: Sendable {
  struct Week: Sendable { let no: Int; let opens: Int; let closes: Int; let status: String }
  struct Pairing: Sendable { let week: Int; let a: Int; let b: Int; let result: String; let aPVI: Double?; let bPVI: Double? }
  let n: Int
  let name: String
  let kind: String            // ryder | major
  let status: String          // setup | live | complete
  let league: Int?
  let organizer: Int
  let weeks: [Week]
  let teams: [(slot: Int, name: String, color: Int)]
  let golfers: [(person: Int, slot: Int?, captain: Bool, exhibition: Bool)]
  let pairings: [Pairing]
  let buyIn: Double
  let winnerSlot: Int?
  var ids: String { fids(n) }
  func teamID(_ slot: Int) -> String { fids(n * 100 + 10 + slot) }
  func golferID(_ person: Int) -> String { fids(n * 100 + 20 + person) }
  func weekID(_ no: Int) -> String { fids(n * 100 + 50 + no) }
  func pairingID(_ i: Int) -> String { fids(n * 100 + 60 + i) }
}

extension SyntheticWorld {
  var events: [SynthEvent] {
    guard hasSeasons else { return [] }
    let a = [me.n, 2, 3, 4], b = [5, 6, 7, 8]
    let team = [(slot: 0, name: "Team Placeholder", color: 0), (slot: 1, name: "Team Stub", color: 3)]
    func golfers() -> [(person: Int, slot: Int?, captain: Bool, exhibition: Bool)] {
      a.map { ($0, 0, $0 == me.n, false) } + b.map { ($0, 1, $0 == 5, false) }
    }
    typealias P = SynthEvent.Pairing
    let live = SynthEvent(
      n: 5_001, name: "Fixture Invitational", kind: "ryder", status: "live", league: 1_001, organizer: me.n,
      weeks: [.init(no: 1, opens: -15, closes: -9, status: "closed"), .init(no: 2, opens: -8, closes: -2, status: "closed"),
              .init(no: 3, opens: -1, closes: 5, status: "open"), .init(no: 4, opens: 6, closes: 12, status: "upcoming")],
      teams: team, golfers: golfers(),
      pairings: [P(week: 1, a: me.n, b: 5, result: "a", aPVI: 2.4, bPVI: -0.6), P(week: 1, a: 2, b: 6, result: "b", aPVI: 0.8, bPVI: 3.1),
                 P(week: 1, a: 3, b: 7, result: "halve", aPVI: 1.2, bPVI: 1.2), P(week: 1, a: 4, b: 8, result: "a", aPVI: 1.5, bPVI: nil),
                 P(week: 2, a: me.n, b: 6, result: "b", aPVI: 0.3, bPVI: 2.2), P(week: 2, a: 2, b: 5, result: "a", aPVI: 3.6, bPVI: 1.9),
                 P(week: 2, a: 3, b: 8, result: "b", aPVI: -1.1, bPVI: 0.4), P(week: 2, a: 4, b: 7, result: "a", aPVI: 2.0, bPVI: 1.0),
                 P(week: 3, a: me.n, b: 5, result: "pending", aPVI: nil, bPVI: nil), P(week: 3, a: 2, b: 7, result: "pending", aPVI: nil, bPVI: nil),
                 P(week: 3, a: 3, b: 6, result: "pending", aPVI: nil, bPVI: nil), P(week: 3, a: 4, b: 8, result: "pending", aPVI: nil, bPVI: nil)],
      buyIn: 0, winnerSlot: nil)
    let done = SynthEvent(
      n: 5_002, name: "Fixture Autumn Cup", kind: "ryder", status: "complete", league: 1_001, organizer: me.n,
      weeks: [.init(no: 1, opens: -29, closes: -23, status: "closed"), .init(no: 2, opens: -22, closes: -16, status: "closed"),
              .init(no: 3, opens: -15, closes: -9, status: "closed"), .init(no: 4, opens: -8, closes: -2, status: "closed")],
      teams: team, golfers: golfers(),
      pairings: [P(week: 1, a: me.n, b: 5, result: "a", aPVI: 2.4, bPVI: -0.6), P(week: 1, a: 2, b: 6, result: "b", aPVI: 0.8, bPVI: 3.1),
                 P(week: 1, a: 3, b: 7, result: "halve", aPVI: 1.2, bPVI: 1.2), P(week: 1, a: 4, b: 8, result: "a", aPVI: 1.5, bPVI: nil),
                 P(week: 2, a: me.n, b: 6, result: "b", aPVI: 0.3, bPVI: 2.2), P(week: 2, a: 2, b: 5, result: "a", aPVI: 3.6, bPVI: 1.9),
                 P(week: 2, a: 3, b: 8, result: "b", aPVI: -1.1, bPVI: 0.4), P(week: 2, a: 4, b: 7, result: "a", aPVI: 2.0, bPVI: 1.0),
                 P(week: 3, a: me.n, b: 5, result: "a", aPVI: 2.2, bPVI: 1.8), P(week: 3, a: 2, b: 7, result: "a", aPVI: 2.7, bPVI: 0.4),
                 P(week: 3, a: 3, b: 6, result: "b", aPVI: nil, bPVI: 0.9), P(week: 3, a: 4, b: 8, result: "b", aPVI: 0.9, bPVI: 1.4),
                 P(week: 4, a: me.n, b: 7, result: "a", aPVI: 1.1, bPVI: -0.3), P(week: 4, a: 2, b: 8, result: "halve", aPVI: 1.0, bPVI: 1.0),
                 P(week: 4, a: 3, b: 5, result: "a", aPVI: 0.6, bPVI: -1.2), P(week: 4, a: 4, b: 6, result: "b", aPVI: 0.2, bPVI: 2.9)],
      buyIn: 0, winnerSlot: 0)
    var out = [live, done]
    if scenario == .eventLive {
      out.append(SynthEvent(
        n: 5_003, name: "The Fixture Jug", kind: "major", status: "live", league: 1_001, organizer: 2,
        weeks: [.init(no: 1, opens: -2, closes: 1, status: "open")], teams: [],
        golfers: [(2, nil, false, false), (me.n, nil, false, false), (4, nil, false, false), (3, nil, false, true), (5, nil, false, false)],
        pairings: [], buyIn: 20, winnerSlot: nil))
      out.append(SynthEvent(
        n: 5_004, name: "Avery v Blake", kind: "ryder", status: "live", league: nil, organizer: me.n,
        weeks: [.init(no: 1, opens: -1, closes: 6, status: "open")],
        teams: [(0, "Avery", 0), (1, "Blake", 1)], golfers: [(me.n, 0, true, false), (2, 1, false, false)],
        pairings: [P(week: 1, a: me.n, b: 2, result: "pending", aPVI: nil, bPVI: nil)], buyIn: 0, winnerSlot: nil))
    }
    return out
  }

  func event(_ ids: String?) -> SynthEvent? { events.first { $0.ids == ids?.lowercased() } }

  /// `native_home.events`: setup and live only, where the viewer plays or organises.
  func eventsForMe() -> [[String: Any]] {
    events.filter { $0.status != "complete" }.map { e in
      let slot = e.golfers.first { $0.person == me.n }?.slot
      return ["id": e.ids, "name": e.name, "kind": e.kind, "status": e.status, "starts_on": day(e.weeks.first?.opens ?? 0),
              "league_id": e.league.map { fids($0) } ?? NSNull(), "my_team_slot": e.kind == "major" ? NSNull() as Any : (slot.map { $0 as Any } ?? NSNull()),
              "is_organizer": e.organizer == me.n]
    }
  }

  func eventsRPC(_ name: String, _ r: SynthRequest) -> SyntheticReply? {
    switch name {
    case "major_leaderboard":
      guard let e = event(r.string("p_event")) else { return SynthOut.json([Any]()) }
      return SynthOut.json(majorBoard(e))
    case "event_lineage":
      guard let e = event(r.string("p_event")) else { return SynthOut.json([Any]()) }
      var rows: [[String: Any]] = []
      if e.n == 5_001 {
        rows.append(["event_id": fids(5_005), "name": e.name, "kind": "ryder", "status": "complete", "starts_on": day(-148), "year": 2026,
                     "is_current": false, "champion": NSNull(), "champ_gross": NSNull(), "champ_pvi": NSNull(), "winner_slot": 0,
                     "winner_team": "Team Placeholder", "winner_shared": false])
      }
      rows.append(["event_id": e.ids, "name": e.name, "kind": e.kind, "status": e.status, "starts_on": day(e.weeks.first?.opens ?? 0),
                   "year": 2026, "is_current": true, "champion": NSNull(), "champ_gross": NSNull(), "champ_pvi": NSNull(),
                   "winner_slot": e.winnerSlot ?? NSNull(), "winner_team": e.winnerSlot.map { e.teams[$0].name } ?? NSNull(), "winner_shared": false])
      return SynthOut.json(rows)
    case "event_session_targets":
      let id = r.string("p_session")?.lowercased()
      guard let e = events.first(where: { ev in ev.weeks.contains { ev.weekID($0.no) == id } }),
            let wk = e.weeks.first(where: { e.weekID($0.no) == id }) else { return SynthOut.json([Any]()) }
      let targets: [Double?] = [nil, 2.7, nil, 0.9]
      let rows: [[String: Any]] = e.pairings.enumerated().filter { $0.element.week == wk.no }.enumerated().map { j, pair in
        ["duel_id": e.pairingID(pair.offset), "a_pvi": targets[j % 4] ?? NSNull(), "b_pvi": j == 0 ? 1.8 as Any : (j == 3 ? 1.4 as Any : NSNull() as Any)]
      }
      return SynthOut.json(rows)
    case "set_event_team", "resolve_session", "set_event_notify", "delete_event", "open_major", "settle_major": return SynthOut.void
    case "generate_pairings": return SynthOut.json(4)
    case "enter_major", "create_event", "create_major", "invite_golfer", "call_out", "create_forfeit": return SynthOut.json(fids(5_900))
    case "respond_callout": return SynthOut.json("accepted")
    default: return nil
    }
  }

  func eventsTable(_ t: String, _ r: SynthRequest) -> SyntheticReply? {
    let id = r.filter("event_id") ?? (t == "events" ? r.filter("id") : nil)
    let e = event(id)
    switch t {
    case "events":
      guard let e else { return SynthOut.rows([], r) }   // unknown id: PostgREST's 406 under .single()
      return SynthOut.rows([eventRow(e)], r)
    case "event_teams":
      return SynthOut.rows(e.map { e in e.teams.map { team -> [String: Any] in
        let captain: Any = e.golfers.first { $0.slot == team.slot && $0.captain }.map { e.golferID($0.person) } ?? NSNull()
        return ["id": e.teamID(team.slot), "event_id": e.ids, "slot": team.slot, "name": team.name, "color": team.color,
                "captain_player_id": captain]
      } } ?? [], r)
    case "event_players":
      return SynthOut.rows(e.map { e in e.golfers.enumerated().map { i, g in
        ["id": e.golferID(g.person), "event_id": e.ids, "profile_id": person(g.person).ids,
         "team_id": g.slot.map { e.teamID($0) } ?? NSNull(), "role": g.captain ? "captain" : "player", "seed": i + 1,
         "benched_count": 0, "notify_target": g.person == me.n, "exhibition": g.exhibition,
         "profile": ["display_name": person(g.person).name, "marker": person(g.person).marker]] as [String: Any] } } ?? [], r)
    case "event_sessions":
      return SynthOut.rows(e.map { e in e.weeks.map { ["id": e.weekID($0.no), "event_id": e.ids, "session_no": $0.no,
                                                       "opens_on": day($0.opens), "closes_on": day($0.closes), "status": $0.status, "weight": 1] as [String: Any] } } ?? [], r)
    case "event_duels":
      return SynthOut.rows(e.map { e in e.pairings.enumerated().map { i, p in
        ["id": e.pairingID(i), "event_id": e.ids, "session_id": e.weekID(p.week), "a_player": e.golferID(p.a), "b_player": e.golferID(p.b),
         "a_round": p.a == me.n && p.aPVI != nil ? fids(4_003) as Any : NSNull() as Any, "b_round": NSNull(),
         "a_pvi": p.aPVI ?? NSNull(), "b_pvi": p.bPVI ?? NSNull(), "result": p.result] as [String: Any] } } ?? [], r)
    case "v_event_scoreboard":
      guard let e else { return SynthOut.rows([], r) }
      var pts = [0.0, 0.0]
      for p in e.pairings {
        switch p.result { case "a": pts[0] += 1; case "b": pts[1] += 1; case "halve": pts[0] += 0.5; pts[1] += 0.5; default: break }
      }
      return SynthOut.rows(e.teams.isEmpty ? [] : e.teams.map { ["team_id": e.teamID($0.slot), "points": pts[$0.slot]] }, r)
    case "event_major_cards":
      return SynthOut.rows([], r)
    default: return nil
    }
  }

  func eventRow(_ e: SynthEvent) -> [String: Any] {
    [
      "id": e.ids, "name": e.name, "created_by": person(e.organizer).ids, "league_id": e.league.map { fids($0) } ?? NSNull(),
      "kind": e.kind, "status": e.status, "starts_on": day(e.weeks.first?.opens ?? 0), "session_count": e.weeks.count,
      "session_weeks": 1, "draw_rule": "team_pvi", "winner_team_id": e.winnerSlot.map { e.teamID($0) } ?? NSNull(),
      "buy_in": e.buyIn, "pot_split": "places", "lineage_id": e.n == 5_001 ? fids(5_005) : NSNull(), "tz": "America/Phoenix",
      "course_id": NSNull(), "course_label": NSNull(),
    ]
  }

  func majorBoard(_ e: SynthEvent) -> [[String: Any]] {
    let cards: [Int: (gross: Int, pvi: Double, cards: Int)] = [2: (79, 3.4, 2), me.n: (84, 1.2, 1), 3: (88, 0.4, 1), 4: (86, -0.6, 1)]
    return e.golfers.map { g in
      let c = cards[g.person]
      return ["player_id": e.golferID(g.person), "profile_id": person(g.person).ids, "display_name": person(g.person).name,
              "marker": person(g.person).marker, "exhibition": g.exhibition,
              "round_id": c == nil ? NSNull() as Any : (g.person == me.n ? fids(4_001) : fids(4_101)) as Any,
              "gross": c?.gross ?? NSNull(), "pvi": c?.pvi ?? NSNull(), "cards": c?.cards ?? 0,
              "best_posted_at": c == nil ? NSNull() as Any : stamp(-1, 21, 40) as Any]
    }.sorted { (($0["pvi"] as? Double) ?? -99) > (($1["pvi"] as? Double) ?? -99) }
  }

  func eventPosts(_ e: SynthEvent) -> [[String: Any]] {
    switch e.n {
    case 5_001:
      return [["id": fids(e.n * 100 + 90), "kind": "system", "body": "Week three is open: Avery against Emerson, Blake against Gray, Casey against Finley, Devon against Harper.", "created_at": stamp(-1, 6)],
              ["id": fids(e.n * 100 + 91), "kind": "system", "body": "Week two is in. Team Placeholder lead four and a half to three and a half.", "created_at": stamp(-2, 7, 5)]]
    case 5_002:
      return [["id": fids(e.n * 100 + 90), "kind": "system", "body": "Team Placeholder take the cup, nine to seven.", "created_at": stamp(-1, 7, 6)]]
    case 5_003:
      return [["id": fids(e.n * 100 + 90), "kind": "system", "body": "The window is open. The best card takes the jug.", "created_at": stamp(-2, 6)]]
    default:
      return [["id": fids(e.n * 100 + 90), "kind": "system", "body": "Blake is in. The best round by \(weekday(6)) takes it. \u{201C}Loser buys the first round.\u{201D}", "created_at": stamp(-1, 18, 2)]]
    }
  }
}
#endif
