// Cup Season — synthetic reads for YOU: the credential (`tour_card`), the
// record (`career_record`, `my_league_record`, trophies, achievements), the
// rounds and their season lenses, rivals, the bag, the last-round-with line,
// and Card & settings. Contracts traced from YouScreen / YouRepository /
// TourCard / RecordPage / CardAndSettingsScreen / BagService (2026-09-28).

#if DEBUG
import Foundation
import CupSeasonKit

extension SyntheticWorld {
  func youRPC(_ name: String, _ r: SynthRequest) -> SyntheticReply? {
    switch name {
    case "my_trophies": return SynthOut.json(trophies())
    case "my_achievements": return SynthOut.json(achievements())
    case "career_record": return SynthOut.json(careerRecord())
    case "last_round_with": return SynthOut.json([Any]())
    case "my_league_record": return SynthOut.json(leagueRecord())
    case "tour_card":
      let who = r.string("p_profile").flatMap(UUID.init(uuidString:)).flatMap { person(id: $0) } ?? me
      return SynthOut.json(tourCard(who))
    case "bag_of":
      let who = r.string("p_profile").flatMap(UUID.init(uuidString:)).flatMap { person(id: $0) } ?? me
      return SynthOut.json(bag(who))
    case "save_bag":
      var out = bag(me); out["changed"] = 1
      return SynthOut.json(out)
    case "my_rivalries": return SynthOut.json(rivalries())
    case "rivalry_weeks": return SynthOut.json(rivalryWeeks())
    case "set_email_recap", "set_scan_consent": return SynthOut.json((r.params["p_on"] as? Bool) ?? true)
    case "handle_available": return SynthOut.json(true)
    case "submit_feedback", "founder_note": return SynthOut.json(fids(9_401))
    case "delete_account": return SynthOut.void
    default: return nil
    }
  }

  func youTable(_ t: String, _ r: SynthRequest) -> SyntheticReply? {
    switch t {
    case "v_rounds_ranked": return SynthOut.rows(rankedRows(r), r)
    case "v_individual_standings":
      let seasons = Set(r.filterList("season_id").map { $0.lowercased() })
      return SynthOut.rows(leagues.filter { seasons.isEmpty || seasons.contains($0.seasonIds) }.flatMap { l in
        l.members.enumerated().map { i, pn -> [String: Any] in
          ["season_id": l.seasonIds, "member_id": l.memberIds(pn), "points": l.points[i],
           "rounds_posted": entries(l)[pn, default: []].filter { $0.round != nil }.count] as [String: Any]
        }
      }, r)
    default: return nil
    }
  }

  /// `profiles` reads that are not the name lookup: extras, settings, the
  /// discoverable chip, scan consent, one avatar's path. Answered by column.
  func profileRead(_ r: SynthRequest) -> [[String: Any]]? {
    let select = r.query["select"]?.first ?? ""
    // A name lookup (`id=in.(…)`, `select=id,display_name`) is Home's; this
    // answers the single-golfer column reads.
    guard select != "id,display_name", r.query["id"]?.first?.hasPrefix("eq.") == true,
          let id = r.filter("id")?.lowercased(), let who = people.first(where: { $0.ids == id }) else { return nil }
    let created = stamp(who.n == me.n && !hasRounds ? -1 : -200, 17)
    var row: [String: Any] = [:]
    for col in select.split(separator: ",").map(String.init) {
      switch col {
      case "id": row[col] = who.ids
      case "display_name": row[col] = displayName(who)
      case "handle": row[col] = who.n == me.n ? (cardDone ? state.get("handle", me.handle) : NSNull()) : who.handle
      case "marker": row[col] = who.n == me.n ? (cardDone ? state.get("marker", me.marker) : NSNull()) : who.marker
      case "city": row[col] = who.city
      case "home_course": row[col] = courses[0].name
      case "index_current": row[col] = who.n == me.n && !hasRounds ? NSNull() as Any : who.index as Any
      case "index_source": row[col] = hasRounds ? "app" : "manual"
      case "discoverable": row[col] = "everyone"
      case "notify_chat", "notify_rounds": row[col] = true
      case "created_at": row[col] = created
      default: row[col] = NSNull()
      }
    }
    return [row]
  }

  /// The card gate is done once a handle and a marker exist (the gate's Save
  /// writes them into `SynthState`, and the next `native_home` echoes them).
  var cardDone: Bool { scenario != .cardGate || state.get("handle", "") != "" }
  func displayName(_ p: SynthPerson) -> String {
    guard p.n == me.n else { return p.name }
    // The signup trigger's own guess until the card is made (D325).
    return cardDone ? state.get("name", me.name) : me.handle
  }

  // MARK: rounds and lenses

  func roundRow(_ x: SynthRound) -> [String: Any] {
    let t = x.teeData
    return ["id": x.ids, "profile_id": x.owner.ids, "gross": x.gross, "differential": x.differential,
            "index_at_post": x.owner.n == me.n ? ((me.index + Double(-x.day) / 120) * 10).rounded() / 10 : x.owner.index,
            "played_on": day(x.day), "course_label": "\(x.course.name) · \(t.name)", "holes_played": x.holes,
            "api_course_id": x.course.key, "photo_path": x.photoPath ?? NSNull(), "rating": t.rating, "slope": t.slope,
            "voided": false]
  }

  /// `v_rounds_ranked`: one row per round per season the golfer is in —
  /// from the same entries the Book prints, so the two cannot disagree.
  func rankedRows(_ r: SynthRequest) -> [[String: Any]] {
    let byProfile = r.filter("profile_id")?.lowercased()
    let bySeason = r.filter("season_id")?.lowercased()
    var out: [[String: Any]] = []
    for l in leagues {
      if let bySeason, bySeason != l.seasonIds { continue }
      for (pn, list) in entries(l) {
        if let byProfile, byProfile != person(pn).ids { continue }
        let rounds = list.filter { $0.round != nil }
        let byMonth = Dictionary(grouping: rounds, by: { $0.day.map { self.monthKey($0) } ?? "" })
        for e in rounds {
          let peers = (byMonth[e.day.map { monthKey($0) } ?? ""] ?? []).sorted { $0.points > $1.points }
          let rank = (peers.firstIndex { $0.id == e.id } ?? 0) + 1
          let x = round(e.round)
          out.append(["member_id": l.memberIds(pn), "season_id": l.seasonIds, "round_id": e.round ?? NSNull(),
                      "pvi": x?.pvi ?? Double(e.points - 7) / 2, "points": e.points, "month_rank": rank,
                      "floor_credit": (x?.holes ?? 18) == 9 ? 0.5 : 1, "played_on": e.day.map { day($0) } ?? day(0),
                      "index_at_post": person(pn).index, "holes_played": x?.holes ?? 18, "profile_id": person(pn).ids])
        }
      }
    }
    return out.sorted { ($0["played_on"] as? String ?? "") > ($1["played_on"] as? String ?? "") }
  }

  // MARK: the record

  func trophies() -> [[String: Any]] {
    guard hasRounds else { return [] }
    var out: [[String: Any]] = [
      ["id": fids(7_501), "kind": "major", "title": cast.majorTrophy, "subtitle": "Major champion",
       "placement": "winner", "season_year": 2026, "earned_on": day(-57)],
      ["id": fids(7_502), "kind": "ryder", "title": cast.ryderTrophy, "subtitle": "The Ryder",
       "placement": "winner", "season_year": 2026, "earned_on": day(-106)],
    ]
    if scenario == .ceremony {
      out.insert(["id": fids(7_503), "kind": "league", "title": cast.cupLeague.name, "subtitle": "Points King",
                  "placement": "points_king", "season_year": 2026, "earned_on": day(-2)], at: 0)
    }
    return out
  }

  func achievements() -> [[String: Any]] {
    guard hasRounds else { return [] }
    let sub80 = rounds.first { $0.owner.n == me.n && $0.sub80 }
    let firstRound = myRounds.min { $0.day < $1.day }
    var out: [[String: Any]] = []
    // X39 (2) · D399: a personal best needs an EARLIER round and beats every
    // one of them strictly (round_moments' rule, which rederive_achievements
    // adopts in 20261216090000), so a lone round carries none. The harness
    // world's rederive() says the same (85356446); the web half is da806ce1.
    // Over this world's rounds the rule lands where the fixture always had it
    // (the 81 on day −9, 7.8), so no screen moves for it.
    if let pb = Self.personalBest(myRounds) {
      out.append(["kind": "personal_best", "label": "Personal best", "earned_on": day(pb.day),
                  "meta": ["diff": pb.differential], "round_id": pb.ids])
    }
    let thresholds: [[String: Any]] = [
      ["kind": "sub_80", "label": "Broke 80", "earned_on": day(sub80?.day ?? -73), "meta": ["gross": sub80?.gross ?? 79], "round_id": sub80?.ids ?? NSNull()],
      ["kind": "streak_4", "label": "Four weeks running", "earned_on": day(-115), "meta": ["weeks": 4], "round_id": NSNull()],
      ["kind": "sub_90", "label": "Broke 90", "earned_on": day(-129), "meta": ["gross": 89], "round_id": fids(4_021)],
    ]
    out += thresholds
    // X39 (2) · the first 18-hole round under 100 WAS the first round (a 95),
    // so rederive mints Broke 100 on it — and the case folds that row into
    // FIRST ROUND (`TrophyCase.tiles`), which is the state X39 is about.
    if let f = firstRound, f.holes == 18, f.gross < 100 {
      out.append(["kind": "sub_100", "label": "Broke 100", "earned_on": day(f.day), "meta": ["gross": f.gross], "round_id": f.ids])
    }
    // the server's first_round carries its gross (`round_moments`), which is
    // what the folded slat names when the round is not in hand
    var firstMeta: [String: Any] = [:]
    if let f = firstRound { firstMeta["gross"] = f.gross }
    out.append(["kind": "first_round", "label": "First round", "earned_on": day(firstRound?.day ?? -143), "meta": firstMeta,
                "round_id": firstRound?.ids ?? NSNull()])
    return out
  }

  /// X39 · D399's personal-best rule over one golfer's rounds, oldest first: a
  /// round strictly below EVERY earlier round's differential, the lowest such
  /// (the later on a tie). The first round is never one, so one round is none.
  static func personalBest(_ rounds: [SynthRound]) -> SynthRound? {
    let byDay = rounds.sorted { $0.day == $1.day ? $0.n < $1.n : $0.day < $1.day }
    let beats = byDay.indices.dropFirst()
      .filter { i in byDay[..<i].allSatisfy { $0.differential > byDay[i].differential } }
      .map { byDay[$0] }
    return beats.min { $0.differential == $1.differential ? $0.day > $1.day : $0.differential < $1.differential }
  }

  func careerRecord() -> [String: Any] {
    guard hasRounds else {
      return ["cups": 0, "runner_ups": 0, "crowns": 0, "majors": 0, "events": 0, "trophies": 0, "earnings_cents": 0,
              "seasons_done": 0, "seasons_played": 0, "first_round_on": NSNull(), "leagues": 0]
    }
    let done = scenario == .ceremony
    let firstDay = myRounds.map(\.day).min() ?? -143
    return ["cups": 0, "runner_ups": 0, "crowns": done ? 1 : 0, "majors": 1, "events": 0, "trophies": done ? 3 : 2,
            "earnings_cents": done ? 4_800 : 0, "seasons_done": done ? 3 : 2, "seasons_played": hasSeasons ? 4 : 0,
            "first_round_on": day(firstDay), "leagues": leagues.count]
  }

  func leagueRecord() -> [[String: Any]] {
    var out: [[String: Any]] = []
    for l in leagues {
      let rank = (l.members.firstIndex(of: me.n) ?? 2) + 1
      let d = seasonDates(l)
      out.append(["league_id": l.ids, "league_name": l.name, "phase": l.status == "complete" ? "complete" : "season",
                  "sandbox": false, "structure": l.solo ? "solo" : "squads", "season_id": l.seasonIds, "number": 2,
                  "status": l.status, "starts_on": day(d.starts), "ends_on": day(d.ends),
                  "squad_name": l.solo ? NSNull() as Any : cast.squads[1] as Any, "place": l.solo ? rank : 2, "of": l.solo ? l.members.count : 3,
                  "tied": false, "won": l.status == "complete" && rank == 1, "runner_up": false, "king": false,
                  "points": l.points[rank - 1]])
      out.append(["league_id": l.ids, "league_name": l.name, "phase": "season", "sandbox": false,
                  "structure": l.solo ? "solo" : "squads", "season_id": fids(l.seasonN + 100), "number": 1,
                  "status": "complete", "starts_on": day(d.starts - 150), "ends_on": day(d.starts - 60),
                  "squad_name": l.solo ? NSNull() as Any : cast.squads[1] as Any, "place": 3, "of": l.solo ? l.members.count : 3,
                  "tied": false, "won": false, "runner_up": false, "king": false, "points": l.solo ? 64 : 19])
    }
    return out.sorted { ($0["starts_on"] as? String ?? "") > ($1["starts_on"] as? String ?? "") }
  }

  // MARK: the credential

  func tourCard(_ p: SynthPerson) -> [String: Any] {
    let theirs = rounds.filter { $0.owner.n == p.n }.sorted { $0.day > $1.day }
    let isMe = p.n == me.n
    let best = theirs.filter { $0.holes == 18 }.min { $0.gross < $1.gross }
    let byCourse = Dictionary(grouping: theirs, by: { $0.course.key })
    let courseRows: [[String: Any]] = courses.compactMap { c in
      guard let rs = byCourse[c.key], let last = rs.first else { return nil }
      return ["name": c.name, "rounds": rs.count, "last_played": day(last.day), "api_course_id": c.key]
    }
    let career: [String: Any]
    if let best, !theirs.isEmpty {
      career = ["rounds": theirs.count, "best": theirs.map(\.differential).min() ?? 0, "avg_vs_index": -1.8, "avg_pvi": -1.3,
                "best_pvi": theirs.map(\.pvi).max() ?? 0,
                "best_round": ["gross": best.gross, "course_label": best.course.name, "played_on": day(best.day), "differential": best.differential]]
    } else {
      career = ["rounds": 0, "best": NSNull(), "avg_vs_index": NSNull(), "avg_pvi": NSNull(), "best_pvi": NSNull()]
    }
    return [
      "visible": true, "stranger": false,
      "profile": ["id": p.ids, "display_name": displayName(p), "handle": isMe ? state.get("handle", p.handle) : p.handle,
                  "marker": p.marker, "city": p.city, "home_course": courses[0].name,
                  "index_current": theirs.isEmpty && isMe ? NSNull() as Any : p.index as Any,
                  "member_since": stamp(isMe && !hasRounds ? -1 : -200, 17), "is_me": isMe],
      "career": career,
      "trophies": [Any](), "case": [Any](),
      "recent": theirs.prefix(5).map { ["played_on": day($0.day), "course_label": $0.course.name, "gross": $0.gross,
                                        "differential": $0.differential, "holes_played": $0.holes, "beat": $0.pvi >= 1] },
      "vs_you": isMe ? NSNull() as Any : ["wins": 2, "losses": 3, "ties": 0] as Any,
      "courses": courseRows,
      "shared_courses": sharedCourses(isMe ? [] : courseRows),
    ]
  }

  private func sharedCourses(_ rows: [[String: Any]]) -> [[String: Any]] {
    rows.map { row -> [String: Any] in
      ["name": row["name"] as? String ?? "", "mine": 3, "theirs": row["rounds"] as? Int ?? 0]
    }
  }

  // MARK: the bag

  func bag(_ p: SynthPerson) -> [String: Any] {
    guard hasRounds else {
      return ["visible": true, "is_me": p.n == me.n, "clubs": [Any](), "sideline": [Any](), "ball": NSNull(), "since": NSNull()]
    }
    let base = 7_200_000 + p.n * 100
    let slots = ["Driver", "3-wood", "Hybrid", "5-iron", "7-iron", "9-iron", "PW", "54°", "Putter"]
    let clubs = Array(zip(slots, cast.bag.clubs))
    return [
      "visible": true, "is_me": p.n == me.n,
      "clubs": clubs.enumerated().map { i, c in ["id": fids(base + i), "slot": c.0, "label": c.1, "added_on": day(i == 0 ? -45 : -143)] },
      "sideline": [["id": fids(base + 50), "slot": "Driver", "label": cast.bag.sidelinedDriver, "added_on": day(-143), "removed_on": day(-45)]],
      "ball": ["id": fids(base + 60), "label": cast.bag.ball, "added_on": day(-143)],
      "since": ["id": fids(base), "slot": "Driver", "label": cast.bag.clubs[0], "added_on": day(-45), "rounds": 8, "beat": 2],
    ]
  }

  // MARK: rivals

  func rivalries() -> [[String: Any]] {
    guard hasBuddies else { return [] }
    return [
      ["opponent": person(2).ids, "display_name": person(2).name, "handle": person(2).handle, "marker": person(2).marker,
       "wins": 2, "losses": 3, "ties": 0, "meetings": 5, "lead": "down", "duel_wins": 0, "duel_losses": 0, "duel_halves": 0,
       "rivalry_name": cast.rivalry],
      ["opponent": person(3).ids, "display_name": person(3).name, "handle": person(3).handle, "marker": person(3).marker,
       "wins": 4, "losses": 1, "ties": 1, "meetings": 6, "lead": "up", "duel_wins": 1, "duel_losses": 1, "duel_halves": 0,
       "rivalry_name": NSNull()],
      ["opponent": person(9).ids, "display_name": person(9).name, "handle": person(9).handle, "marker": person(9).marker,
       "wins": 1, "losses": 1, "ties": 0, "meetings": 2, "lead": "even", "duel_wins": 0, "duel_losses": 0, "duel_halves": 0,
       "rivalry_name": NSNull()],
    ]
  }

  func rivalryWeeks() -> [[String: Any]] {
    guard hasBuddies else { return [] }
    let monday = mondayOffset
    let weeks: [(Int, Double, Double, String)] = [(0, -0.3, 0.0, "them"), (-7, 4.8, 2.7, "me"), (-14, -5.4, -0.9, "them"),
                                                  (-21, -2.7, 1.4, "them"), (-28, 1.1, -0.6, "me")]
    return weeks.map { ["wk": day(monday + $0.0), "my_pvi": $0.1, "opp_pvi": $0.2, "winner": $0.3] }
  }

  /// Offset of this week's Monday from the anchor.
  var mondayOffset: Int {
    guard let d = CSDate.local(anchor) else { return 0 }
    let wd = Calendar(identifier: .gregorian).component(.weekday, from: d)   // 1 = Sunday
    return -((wd + 5) % 7)
  }
}
#endif
