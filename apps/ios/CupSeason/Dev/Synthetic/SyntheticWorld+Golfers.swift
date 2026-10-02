// Cup Season — synthetic reads for GOLFERS: buddies and requests
// (`my_friends`), the board (`friends_board`), who you play with, search, the
// head-to-head, mutes and contact matching. Contracts traced from
// GolfersScreen / PeopleParts / FriendsBoard / HeadToHeadPage (2026-09-28).

#if DEBUG
import Foundation
import CupSeasonKit

extension SyntheticWorld {
  func golfersRPC(_ name: String, _ r: SynthRequest) -> SyntheticReply? {
    switch name {
    case "my_friends": return SynthOut.json(friends())
    case "friends_board": return SynthOut.json(board())
    case "recent_partners": return SynthOut.json(partners())
    case "my_open_tags": return SynthOut.json([Any]())
    case "my_visitor_rounds": return SynthOut.json([Any]())
    case "search_golfers":
      let q = (r.string("p_q") ?? "").lowercased()
      let hits = people.filter { $0.n != me.n && ($0.name.lowercased().contains(q) || $0.handle.contains(q)) }
      return SynthOut.json(hits.map { p in
        ["profile_id": p.ids, "handle": p.handle, "display_name": p.name, "city": p.city,
         "home_course": courses[0].name, "marker": p.marker, "index_current": p.index, "rel": relation(p)] as [String: Any]
      })
    case "head_to_head":
      let who = r.string("p_opponent").flatMap(UUID.init(uuidString:)).flatMap { person(id: $0) } ?? person(2)
      return SynthOut.json(headToHead(who))
    case "my_mutes": return SynthOut.json([String]())
    case "match_contacts": return SynthOut.json([Any]())
    case "friend_request": return SynthOut.json("requested")
    case "friend_respond", "unfriend": return SynthOut.void
    case "create_share": return SynthOut.json(fids(8_201))
    case "revoke_share": return SynthOut.json(true)
    case "ask_for_a_seat": return SynthOut.json(["state": "asked"])
    case "confirm_round_partner": return SynthOut.json(["state": "confirmed"])
    default: return nil
    }
  }

  /// Buddies: Blake and Casey accepted, Devon asking you, you asking Emerson.
  func friends() -> [[String: Any]] {
    guard hasBuddies else { return [] }
    let rows: [(Int, String, Bool)] = [(2, "accepted", false), (3, "accepted", true), (9, "accepted", false),
                                       (4, "pending", true), (5, "pending", false)]
    return rows.map { pn, status, incoming in
      let p = person(pn)
      return ["friendship_id": fids(7_100 + pn), "profile_id": p.ids, "handle": p.handle, "display_name": p.name,
              "city": p.city, "marker": p.marker, "index_current": p.index, "status": status, "incoming": incoming]
    }
  }

  func relation(_ p: SynthPerson) -> String {
    guard hasBuddies else { return "none" }
    switch p.n {
    case 2, 3, 9: return "friend"
    case 4: return "incoming"
    case 5: return "requested"
    default: return "none"
    }
  }

  func board() -> [[String: Any]] {
    guard hasBuddies else { return [] }
    let rows: [(Int, Int, Int, Double, Double, Int)] = [   // person, rounds, beats, avg, best, last day
      (2, 5, 2, 0.3, 2.7, -1), (me.n, 6, 1, -1.6, 4.8, -2), (9, 3, 1, -0.4, 1.1, -4), (3, 2, 0, -3.1, -1.2, -3),
    ]
    return rows.enumerated().map { i, row in
      let p = person(row.0)
      return ["profile_id": p.ids, "display_name": p.name, "handle": p.handle, "marker": p.marker, "index_current": p.index,
              "rounds_30d": row.1, "beats_30d": row.2, "avg_vs_number_30d": row.3, "best_vs_number_30d": row.4,
              "last_round_on": day(row.5), "rank_by_form": i + 1, "rank_by_index": i + 1, "is_me": row.0 == me.n]
    }
  }

  func partners() -> [[String: Any]] {
    guard hasBuddies else { return [] }
    let rows: [(Int, Int, Int)] = [(2, -1, 6), (8, -9, 2), (11, -15, 1)]   // person, last day, rounds together
    return rows.map { pn, last, together in
      let p = person(pn)
      return ["id": p.ids, "handle": p.handle, "display_name": p.name, "city": p.city, "home_course": courses[0].name,
              "marker": p.marker, "index_current": p.index, "rel": relation(p), "last_played": stamp(last, 16, 5),
              "rounds_together": together]
    }
  }

  func headToHead(_ who: SynthPerson) -> [String: Any] {
    guard hasBuddies else {
      return ["visible": true, "opponent": ["id": who.ids, "display_name": who.name, "handle": who.handle, "marker": who.marker],
              "league": NSNull(), "record": ["wins": 0, "losses": 0, "ties": 0, "total": 0], "lead": "even", "since": NSNull(),
              "streak": NSNull(), "last_five": [Any](), "rivalry_name": NSNull(), "facets": [String: Any]()]
    }
    let m = mondayOffset
    let tape: [[String: Any]] = [
      ["on": day(m - 1), "won": false, "facet": "clashes"], ["on": day(m - 8), "won": false, "facet": "season_weeks"],
      ["on": day(m - 15), "won": true, "facet": "played_together"], ["on": day(m - 22), "won": NSNull(), "facet": "played_together"],
      ["on": day(m - 29), "won": true, "facet": "season_weeks"],
    ]
    func facet(_ w: Int, _ l: Int, _ t: Int, _ first: Int, _ last: Int, _ basis: String, _ source: String) -> [String: Any] {
      ["wins": w, "losses": l, "ties": t, "meetings": w + l + t, "unsettled": 0, "confirmed": 0, "unconfirmed": 0, "heuristic": 0,
       "first_on": day(first), "last_on": day(last), "basis": basis, "source": source]
    }
    return [
      "visible": true,
      "opponent": ["id": who.ids, "display_name": who.name, "handle": who.handle, "marker": who.marker],
      "league": leagues.first?.name ?? NSNull(),
      "record": ["wins": 4, "losses": 5, "ties": 1, "total": 11], "lead": "down", "since": day(-134),
      "streak": ["who": "them", "n": 2], "last_five": tape,
      "rivalry_name": who.n == 2 ? cast.rivalry : NSNull(),
      "facets": [
        "season_weeks": facet(2, 3, 0, -134, m - 8, "the better round against your playing HCP in a week you both posted", "v_rounds_ranked"),
        "clashes": facet(1, 2, 0, -43, m - 1, "the weekly clash the season opened and settled", "week_clashes"),
        "played_together": facet(1, 0, 1, -99, m - 15, "the better card against your playing HCP on a day you were both out", "round_players"),
      ],
    ]
  }
}
#endif
