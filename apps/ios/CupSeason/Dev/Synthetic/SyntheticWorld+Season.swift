// Cup Season — synthetic reads for the SEASON PAGE (`LeagueRoomModel.load`):
// the league, its settings and season, the roster, squads, buy-ins, the two
// standings views, the weekly snapshots, the season's lenses on every round,
// adjustments, payouts, and the page's fire-and-forget reads (pulse,
// scenarios, the Cup Final race, the clash, the story, the cancel vote,
// forfeits), plus the receipt's counting-rounds sheet.
// Contracts traced from LeagueRoomModel / SeasonPage / SeasonStoryPane /
// CupFinalRaceView / ReceiptSheets / CountingRoundsSheet (2026-09-28).

#if DEBUG
import Foundation
import CupSeasonKit

extension SyntheticWorld {
  /// The Pro of each fixture season: Blake runs the Cup League, Avery the squads.
  func pro(_ l: SynthLeague) -> Int { l.n == 1_002 ? me.n : 2 }

  func seasonTable(_ t: String, _ r: SynthRequest) -> SyntheticReply? {
    let l = league(r.filter("league_id")) ?? league(r.filter("season_id")) ?? (t == "leagues" ? league(r.filter("id")) : nil)
    switch t {
    case "leagues":
      return SynthOut.rows(l.map { l in [["id": l.ids, "name": l.name, "code": l.code, "phase": l.status == "complete" ? "complete" : "season",
                                          "commissioner_id": person(pro(l)).ids, "notify_system": true] as [String: Any]] } ?? [], r)
    case "league_settings":
      return SynthOut.rows(l.map { l in [settingsRow(l)] } ?? [], r)
    case "seasons":
      return SynthOut.rows(l.map { l in [seasonRow(l)] } ?? [], r)
    case "squads":
      guard let l, !l.solo else { return SynthOut.rows([], r) }
      return SynthOut.rows(squadNames.sorted { $0.name < $1.name }.map { s in
        let members = l.memberOrder.filter { squadOf($0, in: l) == s.n }
        return ["id": fids(s.n), "name": s.name, "color": s.color, "captain_member_id": l.memberIds(members[0]),
                "squad_members": members.map { ["member_id": l.memberIds($0)] }] as [String: Any]
      }, r)
    case "buy_ins":
      guard let l, l.buyinCents > 0 else { return SynthOut.rows([], r) }
      return SynthOut.rows(l.memberOrder.enumerated().map { i, pn in
        ["member_id": l.memberIds(pn), "paid": i < l.memberOrder.count - 2, "amount_cents": l.buyinCents] as [String: Any]
      }, r)
    case "v_squad_standings":
      guard let l, !l.solo else { return SynthOut.rows([], r) }
      return SynthOut.rows(squadTable(l).map { ["squad_id": fids($0.n), "points": $0.points, "season_id": l.seasonIds] }, r)
    case "standings_snapshots":
      guard let l else { return SynthOut.rows([], r) }
      return SynthOut.rows(snapshots(l), r)
    case "season_adjustments":
      guard let l else { return SynthOut.rows([], r) }
      return SynthOut.rows(adjustments(l), r)
    case "season_payouts":
      guard let l, l.status == "complete", l.buyinCents > 0 else { return SynthOut.rows([], r) }
      let pot = l.buyinCents * l.memberOrder.count
      return SynthOut.rows([
        ["profile_id": person(l.members[0]).ids, "cents": pot * 60 / 100, "reason": "Cup champion"],
        ["profile_id": person(l.members[1]).ids, "cents": pot * 25 / 100, "reason": "Runner-up"],
        ["profile_id": person(l.members[0]).ids, "cents": pot * 15 / 100, "reason": "Points king"],
      ], r)
    case "week_clashes":
      guard let l, l.status == "active" else { return SynthOut.rows([], r) }
      let opp = l.members.first { $0 != me.n } ?? 2
      return SynthOut.rows([["id": fids(7_600 + l.n % 10), "week_no": l.week, "a_member": l.memberIds(me.n), "b_member": l.memberIds(opp),
                             "opened_at": stamp(seasonDates(l).weekEnds - 6, 7, 12), "settled_at": NSNull(), "winner_member": NSNull(),
                             "a_best": NSNull(), "b_best": NSNull()]], r)
    case "forfeits", "invites":
      return SynthOut.rows([], r)
    default: return nil
    }
  }

  func seasonRPC(_ name: String, _ r: SynthRequest) -> SyntheticReply? {
    let l = league(r.string("p_league")) ?? league(r.string("p_season"))
    switch name {
    case "league_pulse":
      guard let l else { return SynthOut.json([Any]()) }
      return SynthOut.json(l.members.map { pn in
        ["profile_id": person(pn).ids, "display_name": person(pn).name, "marker": person(pn).marker, "credits": 2, "floor": 2,
         "at_floor": true, "is_me": pn == me.n, "partial": false, "joined_this_month": false, "bye_available": true] as [String: Any]
      })
    case "season_scenarios":
      guard let l else { return SynthOut.json(NSNull()) }
      return SynthOut.json(scenarios(l))
    case "cup_final_race":
      guard let l, l.status != "active" else { return SynthOut.json(NSNull()) }
      return SynthOut.json(cupRace(l))
    case "season_story":
      guard let l = l ?? leagues.first else { return SynthOut.json(NSNull()) }
      return SynthOut.json(story(l))
    case "league_cancel_status": return SynthOut.json(NSNull())
    case "counting_rounds":
      guard let member = r.string("p_member")?.lowercased(),
            let lg = leagues.first(where: { lg in lg.memberOrder.contains { lg.memberIds($0) == member } }),
            let pn = lg.memberOrder.first(where: { lg.memberIds($0) == member }) else { return SynthOut.json(NSNull()) }
      let month = r.string("p_month") ?? String(day(0).prefix(7))
      let list = entries(lg)[pn, default: []].filter { $0.round != nil && ($0.day.map { String(day($0).prefix(7)) } == month) }
      return SynthOut.json(["league_name": lg.name, "cap": 4, "rounds": list.sorted { ($0.day ?? 0) > ($1.day ?? 0) }.map { e in
        let x = round(e.round)
        return ["round_id": e.round ?? NSNull(), "played_on": e.day.map { day($0) } ?? NSNull(), "holes_played": x?.holes ?? 18,
                "gross": x?.gross ?? NSNull(), "course_label": x?.course.name ?? NSNull(), "points": e.points,
                "counting": e.state == "counting"] as [String: Any]
      }])
    case "vote_league_cancel", "withdraw_league_cancel": return SynthOut.json("pending")
    case "settle_forfeit", "scrap_forfeit", "assign_player", "remove_member", "transfer_pro", "set_member_index",
         "set_league_marker", "set_league_look", "set_league_notify_system":
      return SynthOut.void
    case "leave_season":
      let body: [String: Any] = ["left_at": stamp(0, 9), "league": l?.ids ?? NSNull(), "already": false]
      return SynthOut.json(body)
    default: return nil
    }
  }

  // MARK: rows

  func settingsRow(_ l: SynthLeague) -> [String: Any] {
    [
      "league_id": l.ids, "preset": "standard", "handicap_allowance": 100, "verification": "honor", "counting_cap": 4,
      "participation_floor": 2, "floor_penalty": l.solo ? "none" : "deduct", "season_format": "points", "buyin_cents": l.buyinCents,
      "season_months": 3, "locked_at": stamp(seasonDates(l).starts - 10, 19), "structure": l.solo ? "solo" : "squads3",
      "draft_type": "random", "payout_champ": l.buyinCents > 0 ? 60 : 0, "payout_runnerup": l.buyinCents > 0 ? 25 : 0,
      "payout_king": l.buyinCents > 0 ? 15 : 0, "finish": l.finish, "roster_closed_at": NSNull(),
    ]
  }

  func seasonRow(_ l: SynthLeague) -> [String: Any] {
    let d = seasonDates(l)
    let done = l.status == "complete"
    return [
      "id": l.seasonIds, "number": 2, "starts_on": day(d.starts), "ends_on": day(d.ends), "status": l.status,
      "champion_squad_id": done && !l.solo ? fids(squadTable(l)[0].n) as Any : NSNull() as Any,
      "champion_member_id": done ? l.memberIds(l.members[0]) as Any : NSNull() as Any,
      "runnerup_squad_id": done && !l.solo ? fids(squadTable(l)[1].n) as Any : NSNull() as Any,
      "runnerup_member_id": done ? l.memberIds(l.members[1]) as Any : NSNull() as Any,
      "points_king_member_id": done ? l.memberIds(l.members[0]) as Any : NSNull() as Any,
      "champion_score": done ? 18 as Any : NSNull() as Any, "runnerup_score": done ? 16 as Any : NSNull() as Any,
      "tiebreak_rung": NSNull(), "pot_cents": l.buyinCents * l.memberOrder.count,
      "collected_cents": l.buyinCents * (l.memberOrder.count - 2),
    ]
  }

  /// One snapshot per closed week: the table as it stood.
  func snapshots(_ l: SynthLeague) -> [[String: Any]] {
    let all = entries(l)
    let d = seasonDates(l)
    return (0..<max(0, l.week - 1)).map { w in
      let through = w + 1
      let ind: [[String: Any]] = l.memberOrder.map { pn in
        ["member_id": l.memberIds(pn), "points": all[pn, default: []].filter { ($0.week ?? 99) <= through }.reduce(0) { $0 + $1.contribution }]
      }
      let sq: [[String: Any]] = l.solo ? [] : squadNames.map { s in
        ["squad_id": fids(s.n), "points": l.memberOrder.filter { squadOf($0, in: l) == s.n }
          .flatMap { all[$0, default: []] }.filter { ($0.week ?? 99) <= through }.reduce(0) { $0 + $1.contribution }]
      }
      return ["week_no": w, "captured_at": stamp(d.starts + through * 7, 7, 10), "standings": ["individuals": ind, "squads": sq]]
    }
  }

  func adjustments(_ l: SynthLeague) -> [[String: Any]] {
    var out: [[String: Any]] = [["id": fids(7_700 + l.n % 10), "squad_id": NSNull(), "member_id": NSNull(),
                                 "month": monthKey(firstOfMonthOffset - 1), "kind": "month_closed", "points": 0,
                                 "reason": "Partial month, no minimum", "created_by": NSNull()]]
    for (pn, list) in entries(l) {
      for e in list where e.kind == "override" {
        out.append(["id": e.id.replacingOccurrences(of: "adjustment:", with: ""), "squad_id": NSNull(), "member_id": l.memberIds(pn),
                    "month": e.day.map { monthKey($0) } ?? NSNull(), "kind": "override", "points": e.points, "reason": e.reason,
                    "created_by": person(pro(l)).ids])
      }
    }
    return out
  }

  // MARK: the page's own reads

  func scenarios(_ l: SynthLeague) -> [String: Any] {
    // Q50 capture seam: the real view consumes a proven server-shaped
    // number. DEBUG-only invented rows; no network or scoring calculation.
    if ProcessInfo.processInfo.arguments.contains("-cs_synth_clinch") {
      return ["meta": ["finish": "cup_final", "structure": "squads2", "level": "squad",
                       "k": 1, "months_left": 2, "locked": false, "cap": 4],
              "rows": [["id": fids(9_101), "name": "Fixture Javelinas", "points": 171,
                        "max_final": 900, "needs": 351, "clinched": false, "eliminated": false],
                       ["id": fids(9_102), "name": "Fixture Wrens", "points": 137,
                        "max_final": 521, "needs": 0, "clinched": false, "eliminated": false]]]
    }
    let d = seasonDates(l)
    let left = max(0, l.weeksTotal - l.week)
    let rows: [[String: Any]] = l.members.enumerated().map { i, pn in
      ["level": "member", "id": l.memberIds(pn), "name": person(pn).name, "points": l.points[i],
       "max_final": l.points[i] + Double(left * 12), "roster": 1, "rank": i + 1, "clinched": false, "eliminated": false,
       "needs": max(0, Int(l.points[0] + Double(left * 12) - l.points[i]) / 2)]
    }
    return ["meta": ["finish": l.finish, "structure": l.solo ? "solo" : "squads3", "level": l.solo ? "member" : "squad", "k": 2,
                     "seed_end": day(d.ends - 27), "months_left": max(0, left / 4), "locked": l.status == "complete", "cap": 4,
                     "status": l.status, "ends_on": day(d.ends)] as [String: Any],
            "rows": rows]
  }

  func cupRace(_ l: SynthLeague) -> [String: Any] {
    let d = seasonDates(l)
    let done = l.status == "complete"
    let finalists: [[String: Any]] = l.members.prefix(2).enumerated().map { i, pn in
      let window = entries(l)[pn, default: []].filter { ($0.day ?? -999) >= d.ends - 27 && $0.round != nil }
      let pts = window.reduce(0) { $0 + $1.contribution }
      return ["seed": i + 1, "head_start": i == 0 ? 2 : 0, "seed_rung": NSNull(), "squad_id": NSNull(), "member_id": l.memberIds(pn),
              "name": person(pn).name, "color": NSNull(), "window_points": pts, "rounds_used": window.count,
              "last_round_on": window.last?.day.map { day($0) } ?? NSNull(), "total": pts + (i == 0 ? 2 : 0),
              "rounds": window.map { ["round_id": $0.round ?? NSNull(), "played_on": $0.day.map { day($0) } ?? day(0),
                                      "points": $0.points, "month_rank": 1, "pvi": 1.2, "holes_played": 18,
                                      "member_id": l.memberIds(pn), "golfer": person(pn).name] as [String: Any] }]
    }
    return ["status": done ? "complete" : "live", "season_status": l.status, "solo": l.solo,
            "window_start": day(d.ends - 27), "window_end": day(d.ends), "cap_n": 4,
            "cap_note": "Best 4 per calendar month still applies; a round posted before the window can hold a slot.",
            "days_left": max(0, d.ends), "seed_rung": NSNull(), "finalists": finalists]
  }

  func story(_ l: SynthLeague) -> [String: Any] {
    let d = seasonDates(l)
    let leader = person(l.members[0]), second = person(l.members[1])
    let done = l.status == "complete"
    let table: [[String: Any]] = l.members.enumerated().map { i, pn in
      let list = entries(l)[pn, default: []]
      return ["id": l.memberIds(pn), "name": person(pn).name, "points": l.points[i], "rank": i + 1,
              "rounds": list.filter { $0.round != nil }.count, "counted": list.filter { $0.state == "counting" }.count,
              "left": false, "is_me": pn == me.n]
    }
    return [
      "season": ["id": l.seasonIds, "league_id": l.ids, "league": l.name, "number": 2, "starts_on": day(d.starts),
                 "ends_on": day(d.ends), "status": l.status, "finish": l.finish, "structure": l.solo ? "solo" : "squads3",
                 "solo": l.solo, "today": anchor, "my_member_id": l.memberIds(me.n), "i_left": false] as [String: Any],
      "facts": [
        "week_no": l.week, "weeks_total": l.weeksTotal, "weeks_left": max(0, l.weeksTotal - l.week),
        "week_ends_on": day(d.weekEnds), "field": l.memberOrder.count,
        "leader": ["id": l.memberIds(l.members[0]), "name": leader.name, "points": l.points[0], "run_weeks": max(1, l.week - 2),
                   "since": day(d.starts + 14), "is_me": l.members[0] == me.n, "source": "standings_snapshots"] as [String: Any],
        "runner_up": ["name": second.name, "points": l.points[1]],
        "top_gap": l.points[0] - l.points[1], "lead_flip": NSNull(), "closer": NSNull(),
        "final": l.finish == "cup_final" && !done
          ? ["opens_on": day(d.ends - 27), "in_weeks": max(0, (d.ends - 27) / 7), "seats": 2,
             "still_live": l.memberOrder.count, "source": "season_scenarios"] as Any : NSNull() as Any,
        "last_snapshot_on": stamp(d.starts + (l.week - 1) * 7, 7, 10),
      ] as [String: Any],
      "history": [Any](),
      "arc": [
        ["kind": "lead_change", "source": "standings_snapshots", "week": 2, "on": day(d.starts + 13), "subject": leader.name,
         "other": second.name, "mine": false],
        ["kind": "clash", "source": "week_clashes", "week": max(1, l.week - 1), "on": day(d.starts + (l.week - 1) * 7 - 3),
         "subject": "you", "other": person(3).name, "mine": true],
      ],
      "table": table,
      "archive": [
        ["season_id": l.seasonIds, "number": 2, "starts_on": day(d.starts), "ends_on": day(d.ends), "status": l.status,
         "champion": done ? leader.name as Any : NSNull() as Any, "is_current": true],
        ["season_id": fids(l.seasonN + 100), "number": 1, "starts_on": day(d.starts - 150), "ends_on": day(d.starts - 60),
         "status": "complete", "champion": person(6).name, "is_current": false],
      ],
      "generated_at": stamp(0, 7, 30),
    ]
  }
}
#endif
