// Cup Season — synthetic reads for ROUNDS as rows: the `rounds` table by
// every filter the app sends (a golfer's rounds, a course's rounds, the
// photographs of a season, the composer's course memory, one round's
// photo path), the Album's roster, and live rounds.

#if DEBUG
import Foundation
import CupSeasonKit

extension SyntheticWorld {
  func roundsTable(_ t: String, _ r: SynthRequest) -> SyntheticReply? {
    switch t {
    case "rounds": return SynthOut.rows(roundRows(r), r)
    case "live_rounds": return SynthOut.rows([], r)
    case "round_holes": return SynthOut.rows([], r)
    default: return nil
    }
  }

  /// The `rounds` table, filtered the way PostgREST would filter it.
  func roundRows(_ r: SynthRequest) -> [[String: Any]] {
    var rs = rounds
    if let id = r.filter("id")?.lowercased() { rs = rounds.filter { $0.ids == id } + (round(id: UUID(uuidString: id) ?? fid(0)).map { [$0] } ?? []) }
    if let v = r.query["profile_id"]?.first {
      if v.hasPrefix("in.") {
        let ids = Set(r.filterList("profile_id").map { $0.lowercased() })
        rs = rs.filter { ids.contains($0.owner.ids) }
      } else if v.hasPrefix("eq."), let owner = r.filter("profile_id")?.lowercased() {
        rs = rs.filter { $0.owner.ids == owner }
      }
    }
    if let v = r.query["api_course_id"]?.first {
      if v == "not.is.null" { rs = rs.filter { !$0.course.key.isEmpty } }
      else if let key = r.filter("api_course_id") { rs = rs.filter { $0.course.key == key } }
    }
    if r.query["photo_path"]?.first == "not.is.null" { rs = rs.filter { $0.photoPath != nil } }
    var seen = Set<String>()
    let rows = rs.filter { seen.insert($0.ids).inserted }.sorted { $0.day > $1.day }.map(roundRow)
    let limit = Int(r.query["limit"]?.first ?? "") ?? rows.count
    return Array(rows.prefix(limit))
  }

  func roundsRPC(_ name: String, _ r: SynthRequest) -> SyntheticReply? {
    let x = round(r.string("p_round"))
    switch name {
    case "round_card":
      guard let x else { return SynthOut.error("That round is not in this record.", code: "P0001", status: 400) }
      return SynthOut.json(roundCard(x))
    case "posted_round_thread":
      guard let x else { return SynthOut.json(["ok": false]) }
      return SynthOut.json(thread(x))
    case "round_tally": return SynthOut.json(["known": true, "eagles": 0, "birdies": x == nil ? 0 : 1])
    case "round_scorecard":
      guard let x, x.owner.n == me.n, x.n == 4_001 || x.n == 4_003 else { return SynthOut.json(NSNull()) }
      return SynthOut.json(scorecard(x))
    case "round_holes_of": return SynthOut.json([Any]())
    case "round_share_status":
      return SynthOut.json(["token": NSNull(), "include_photo": NSNull(), "cleanup_pending": false, "cleanup": [Any](), "preparing": false])
    case "round_post_status": return SynthOut.json(NSNull())
    case "live_round_card": return SynthOut.json(["round": NSNull(), "players": [Any]()])
    case "finish_live_round":
      return SynthOut.json(["posted": [["name": me.name, "gross": 84, "holes": 18, "round_id": fids(4_902), "profile_id": me.ids],
                                       ["name": person(2).name, "gross": 81, "holes": 18, "round_id": fids(4_903), "profile_id": person(2).ids],
                                       ["name": person(3).name, "gross": 88, "holes": 18, "round_id": fids(4_904), "profile_id": person(3).ids]],
                            "guests": [["name": cast.guest, "claim_token": Self.claimToken.uuidString.lowercased()]],
                            "skipped": [Any](), "casual": false])
    case "abandon_live_round": return SynthOut.void
    case "add_posted_round_comment":
      let body = r.string("p_body") ?? ""
      // the refusal path under test: a comment that says so is refused the way the server's rate limit refuses,
      // and one that says [slow] is refused three seconds late (a thread folded while its comment is on the way)
      if body.contains("[refuse]") {
        var refusal = SynthOut.error("Easy — try again in a minute.", code: "P0001", status: 400)
        if body.contains("[slow]") { refusal.delay = 3 }
        return refusal
      }
      let key = r.string("p_round")?.lowercased() ?? ""
      // a comment is kept for the rest of the launch, so the thread read after a send contains it
      let parent = r.string("p_parent")
      var replyTo: Any = NSNull()
      if let parent, let target = threadComments(x).first(where: { ($0["id"] as? String)?.lowercased() == parent.lowercased() }),
         let who = target["author"] as? [String: Any] { replyTo = ["id": parent, "name": who["name"] ?? ""] }
      let comment: [String: Any] = ["id": r.string("p_client_id") ?? fids(8_050 + state.next("comment")), "author": ["id": me.ids, "name": me.name, "marker": me.marker],
                                    "body": body, "parent_id": parent ?? NSNull(), "root_id": parent ?? NSNull(), "reply_to": replyTo,
                                    "created_at": isoNow(), "is_mine": true, "can_reply": true, "origin": "round"]
      var added: [[String: Any]] = state.get("comments:" + key, [])
      added.append(comment); state.set("comments:" + key, added)
      // commenting is joining the conversation (D405): a golfer with no setting, who does not own the round
      if let x, x.owner.n != me.n, state.get("thread:" + key, "none") == "none" { state.set("thread:" + key, "following") }
      return SynthOut.json(["ok": true, "replayed": false, "comment": comment, "count": threadComments(x).count])
    default: return nil
    }
  }

  /// The seasons whose window holds the round, as the receipt's lenses.
  func lenses(_ x: SynthRound) -> [[String: Any]] {
    leagues.compactMap { l -> [String: Any]? in
      guard l.memberOrder.contains(x.owner.n), let e = entries(l)[x.owner.n]?.first(where: { $0.round == x.ids }) else { return nil }
      let peers = entries(l)[x.owner.n, default: []].filter { $0.round != nil && $0.day.map { monthKey($0) } == e.day.map { monthKey($0) } }
        .sorted { $0.points > $1.points }
      return ["league_id": l.ids, "league_name": l.name, "season_id": l.seasonIds, "season_number": 2,
              "member_id": l.memberIds(x.owner.n), "points": e.points, "month_rank": (peers.firstIndex { $0.id == e.id } ?? 0) + 1,
              "counting_cap": 4, "structure": l.solo ? "solo" : "squads3", "month": String(day(x.day).prefix(7))]
    }
  }

  func roundCard(_ x: SynthRound) -> [String: Any] {
    let t = x.teeData
    let lens = lenses(x)
    let one = lens.count == 1 ? lens.first : nil
    // The band name is the Kit's own producer (one band table, three
    // renderers); the fixture never writes a band of its own.
    let band = CSBands.bandName(x.pvi)
    return [
      "id": x.ids, "profile_id": x.owner.ids, "gross": x.gross, "holes_played": x.holes, "played_on": day(x.day),
      "course_label": "\(x.course.name) · \(t.name)", "rating": t.rating, "slope": t.slope,
      "nine_rating": x.holes == 9 ? t.rating as Any : NSNull() as Any, "differential": x.differential,
      "index_at_post": x.owner.index, "index_provisional": false, "provisional_round": NSNull(), "playing_index": x.owner.index,
      "pvi": x.pvi, "band": band, "points": one?["points"] ?? NSNull(), "month_rank": one?["month_rank"] ?? NSNull(),
      "counting_cap": one == nil ? NSNull() as Any : 4 as Any, "contributions": lens, "attested": false,
      "photo_path": x.photoPath ?? NSNull(), "live_round_id": NSNull(), "is_mine": x.owner.n == me.n,
      "played_with": x.owner.n == me.n && x.n == 4_001 ? [person(2).name] : [String](), "marker": x.owner.marker,
      "api_course_id": x.course.key,
    ]
  }

  /// A posted round's conversation, said by the cast, then anything this launch
  /// has added. Home's door (`roundSocial`) reads the SAME list, so the count, the
  /// newest comment and the thread agree.
  func threadComments(_ x: SynthRound?) -> [[String: Any]] {
    guard let x else { return [] }
    let tidy: [String: Any] = ["id": fids(8_000 + x.n % 1_000), "parent_id": NSNull(), "root_id": NSNull(),
       "author": ["id": person(2).ids, "name": person(2).name, "marker": person(2).marker],
       "body": "Tidy \(x.gross) in the wind.", "created_at": stamp(x.day, 20, 2), "reply_to": NSNull(),
       "is_mine": false, "can_reply": true, "origin": "round"]
    let tees: [String: Any] = ["id": fids(8_500 + x.n % 1_000), "parent_id": NSNull(), "root_id": NSNull(),
       "author": ["id": person(9).ids, "name": person(9).name, "marker": person(9).marker],
       "body": "Same tees next week?", "created_at": stamp(x.day + 1, 8, 15), "reply_to": NSNull(),
       "is_mine": false, "can_reply": true, "origin": "round"]
    let cast: [[String: Any]] = x.owner.n == me.n || x.n == 4_101 || x.n % 3 == 2 ? [tidy, tees] : (x.n % 3 == 1 ? [tees] : [])
    let added: [[String: Any]] = state.get("comments:" + x.ids, [])
    let gone: Set<String> = state.get("removed:" + x.ids, [])
    return (cast + added).filter { !gone.contains(($0["id"] as? String)?.lowercased() ?? "") }
  }

  func thread(_ x: SynthRound) -> [String: Any] {
    let comments = threadComments(x)
    let stored = state.get("thread:" + x.ids, "none")
    return [
      "ok": true, "can_comment": true, "thread": ["state": stored, "following": stored == "following", "muted": stored == "muted"] as [String: Any],
      "notify_prefs": ["own_round": true, "replies": true, "followed": true],
      "count": comments.count, "comments": comments,
      "round": ["id": x.ids, "owner": ["id": x.owner.ids, "name": x.owner.name, "marker": x.owner.marker], "is_mine": x.owner.n == me.n,
                "gross": x.gross, "holes": x.holes, "played_on": day(x.day),
                "course": ["api_course_id": x.course.key, "name": x.course.name]] as [String: Any],
    ]
  }

  /// The wall-clock instant a comment sent now carries.
  func isoNow() -> String { ISO8601DateFormatter().string(from: Date()) }

  /// A hole-by-hole card that adds up to the gross (for two of Avery's rounds).
  func scorecard(_ x: SynthRound) -> [String: Any] {
    let holes = holeTable(x.course, tee: x.course.tees.firstIndex { $0.name == x.tee } ?? 0)
    let par = holes.map(\.par).reduce(0, +)
    var strokes = holes.map { $0.par + 1 }
    var diff = x.gross - strokes.reduce(0, +)
    var i = 0
    while diff != 0 && i < 200 {
      let h = (i * 7) % strokes.count
      if diff > 0 { strokes[h] += 1; diff -= 1 } else if strokes[h] > holes[h].par - 1 { strokes[h] -= 1; diff += 1 }
      i += 1
    }
    let rows: [[String: Any]] = holes.enumerated().map { j, h in
      ["hole": h.hole, "par": h.par, "si": h.si, "yards": h.yards, "strokes": strokes[j]]
    }
    let out = strokes.prefix(9).reduce(0, +)
    return ["holes_played": x.holes, "tee_name": x.tee, "par_source": "tee", "holes": rows,
            "par_out": holes.prefix(9).map(\.par).reduce(0, +), "par_in": par - holes.prefix(9).map(\.par).reduce(0, +), "par_total": par,
            "out": out, "inn": x.gross - out, "total": x.gross]
  }
}
#endif
