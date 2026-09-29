// Cup Season — synthetic reads for HOME: the ranked dispatch, the circle's
// rounds (`home_feed`), league and person posts, applause and comment counts,
// the round-social join and the Activity inbox. Contracts traced from
// HomeView / HomeStream / HomeSocial / SocialActivitySheet (2026-09-28).

#if DEBUG
import Foundation
import CupSeasonKit

extension SyntheticWorld {
  /// The rounds Home's 21-day window can see.
  var feedRounds: [SynthRound] { rounds.filter { $0.day >= -21 } }
  func postId(for r: SynthRound) -> String { fids(20_000 + r.n) }

  func homeRPC(_ name: String, _ r: SynthRequest) -> SyntheticReply? {
    switch name {
    case "home_dispatch": return SynthOut.json(homeDispatch(caps: r.params["p_caps"] != nil))
    case "home_feed": return SynthOut.json(feedRounds.map(feedRow))
    case "posted_rounds_social":
      let asked = Set(((r.params["p_rounds"] as? [String]) ?? []).map { $0.lowercased() })
      return SynthOut.json(["ok": true, "items": feedRounds.filter { asked.contains($0.ids) }.map(roundSocial)])
    case "my_notifications": return SynthOut.json(notifications())
    case "social_notify_prefs", "set_social_notify_prefs":
      return SynthOut.json(["own_round": true, "replies": true, "followed": true])
    case "answer_plan_followup":
      return SynthOut.json(["plan_id": r.string("p_plan") ?? fids(7_002), "answer": r.string("p_answer") ?? "later",
                            "snooze_until": day(2), "applied": true, "reason": NSNull()])
    case "my_invites": return SynthOut.json(invites())
    case "join_covenant_for_invite", "join_covenant_info": return SynthOut.json(covenant())
    case "respond_invite": return SynthOut.void
    case "my_actionable_count", "mark_actionable_seen": return SynthOut.json(hasSeasons ? 1 : 0)
    // The signed-out door and the two links a recipient can tap.
    case "door_flags": return SynthOut.json(["apple_sign_in": false])
    case "league_by_code":
      return SynthOut.json(r.string("p_code") == Self.inviteCode ? Self.inviteLeagueName as Any : NSNull() as Any)
    case "guest_live_state":
      return SynthOut.json(["round": ["status": "final", "course_label": courses[0].name]])
    case "claim_round_info":
      guard r.string("p_token")?.lowercased() == Self.claimToken.uuidString.lowercased() else { return SynthOut.json(NSNull()) }
      return SynthOut.json(["guest_name": "Quinn", "gross": 88, "course_label": "\(courses[0].name) · White", "played_on": day(-2),
                            "claimed": false, "host": person(2).name, "holes_played": 18])
    case "scan_claim_info": return SynthOut.json(NSNull())
    default: return nil
    }
  }

  func homeTable(_ t: String, _ r: SynthRequest) -> SyntheticReply? {
    switch t {
    case "app_flags":
      switch r.filter("key") {
      case "ios": return SynthOut.rows([["key": "ios", "value": ["major": true, "min_build": 0]]], r)
      case "scan": return SynthOut.rows([["key": "scan", "value": ["enabled": false]]], r)
      default: return SynthOut.rows([], r)     // pricing and the rest: the hidden stub
      }
    case "posts":
      if r.query["event_id"] != nil { return SynthOut.rows(event(r.filter("event_id")).map(eventPosts) ?? [], r) }
      if r.query["round_id"] != nil {
        let ids = Set(r.filterList("round_id").map { $0.lowercased() })
        return SynthOut.rows(feedRounds.filter { ids.contains($0.ids) }.map(roundPost), r)
      }
      if r.query["league_id"] != nil {
        // Home asks without chat and round posts (`kind=neq.…`); the board asks for all of them.
        let excluded = Set((r.query["kind"] ?? []).filter { $0.hasPrefix("neq.") }.map { String($0.dropFirst(4)) })
        let rows = leaguePosts(Set(r.filterList("league_id").map { $0.lowercased() }))
          .filter { !excluded.contains(($0["kind"] as? String) ?? "") }
          .sorted { ($0["created_at"] as? String ?? "") > ($1["created_at"] as? String ?? "") }
        return SynthOut.rows(rows, r)
      }
      if r.query["profile_id"] != nil { return SynthOut.rows(personPosts(), r) }
      return SynthOut.rows([], r)
    case "post_kudos":
      let ids = Set(r.filterList("post_id").map { $0.lowercased() })
      return SynthOut.rows(kudos().filter { ids.contains(($0["post_id"] as? String) ?? "") }, r)
    case "post_comments" where (r.query["select"]?.first ?? "").hasPrefix("id,post_id"):
      // The board's comments: two on the week's opening post.
      let ids = Set(r.filterList("post_id").map { $0.lowercased() })
      let rows: [[String: Any]] = leagues.flatMap { l -> [[String: Any]] in
        let post = fids(21_000 + l.n)
        guard ids.contains(post) else { return [] }
        return [["id": fids(22_000 + l.n), "post_id": post, "member_id": l.memberIds(3), "body": "Two weeks to catch him.",
                 "created_at": stamp(-1, 8, 30)],
                ["id": fids(22_100 + l.n), "post_id": post, "member_id": l.memberIds(pro(l)), "body": "Post them and see.",
                 "created_at": stamp(-1, 9, 5)]]
      }
      return SynthOut.rows(rows, r)
    case "post_comments" where (r.query["select"]?.first ?? "").hasPrefix("post_id,member_id"):
      let ids = Set(r.filterList("post_id").map { $0.lowercased() })
      let mine = myRounds.filter { ids.contains(postId(for: $0)) }
      return SynthOut.rows(mine.prefix(2).enumerated().map { i, round in
        ["post_id": postId(for: round), "member_id": fids(1_001 * 100 + [2, 3][i % 2]), "created_at": stamp(round.day + 1, 8, 10 * i)]
      }, r)
    case "league_members":
      return SynthOut.rows(leagueMemberRows(r), r)
    case "profiles":
      if let rows = profileRead(r) { return SynthOut.rows(rows, r) }
      let ids = Set(r.filterList("id").map { $0.lowercased() })
      let who = ids.isEmpty ? people : people.filter { ids.contains($0.ids) }
      return SynthOut.rows(who.map(profileRow), r)
    default: return nil
    }
  }

  // MARK: the dispatch

  func homeDispatch(caps: Bool) -> [String: Any] {
    var items: [[String: Any]] = []
    let l = leagues.first
    if scenario == .brandNew {
      items.append(item("firstround:\(me.ids)", tier: "opportunity", rank: 1, subject: "you",
                        eyebrow: "Your first round", headline: "Post a round you already played.",
                        standfirst: "A score and a course is enough. It lands on your record the moment you post it.",
                        action: "Add my round", route: ["kind": "composer"], spine: "ember"))
    }
    if let l {
      let rankNow = (l.members.firstIndex(of: me.n) ?? 2) + 1
      let behind = Int(l.points[0] - l.points[rankNow - 1])
      if scenario == .ceremony {
        items.append(item("chapter:\(l.ids)", tier: "chapter", rank: 1, subject: person(l.members[0]).first,
                          eyebrow: "\(l.name) · Season 2", headline: "\(person(l.members[0]).first) won the Cup.",
                          standfirst: "You finished \(CSCopy.ordinal(rankNow)) of \(l.members.count). The final table is in.",
                          action: "See the final table", route: ["kind": "season", "id": l.ids, "pane": "table"],
                          league: l.ids, spine: "gold", at: day(-2)))
      } else if scenario == .seasonFinal {
        items.append(item("chapter:\(l.ids)", tier: "chapter", rank: 1, subject: "you",
                          eyebrow: "The Cup Final · \(l.name)", headline: "Four golfers, four weeks, one Cup.",
                          standfirst: "You went in as the \(CSCopy.ordinal(rankNow)) seed. Every week is scored fresh.",
                          action: "Open the season", route: ["kind": "season", "id": l.ids, "pane": "table"],
                          league: l.ids, spine: "ember", at: day(-1)))
      } else {
        items.append(item("chapter:\(l.ids)", tier: "chapter", rank: 1, subject: person(l.members[0]).first,
                          eyebrow: "Week \(l.week) of \(l.weeksTotal) · \(l.name)",
                          headline: "\(person(l.members[0]).first) has led since week two, and you are the one closing.",
                          standfirst: "You moved up a spot on \(weekday(-2)), and you are \(CSCopy.spelled(behind)) back with \(CSCopy.spelled(l.weeksTotal - l.week)) weeks left.",
                          action: "Open the season", route: ["kind": "season", "id": l.ids, "pane": "table"],
                          league: l.ids, spine: "mut", at: day(-2)))
        items.append(item("need:\(l.ids)", tier: "coming", rank: 4, subject: "you",
                          eyebrow: "This month", headline: "One more round this month holds third.",
                          standfirst: "Your best four count, and you have three.",
                          action: "Put a round on the schedule", route: ["kind": "declare"], league: l.ids, spine: "mut"))
      }
      items.append(item("invite:\(fids(9_101))", tier: "closing", rank: 2, subject: person(8).first,
                        eyebrow: "An invitation", headline: "\(person(8).first) put you on \(Self.inviteLeagueName).",
                        standfirst: "See the terms before you’re in.", action: "See the terms",
                        route: ["kind": "invite", "id": fids(1_003), "pane": "league"], league: fids(1_003), spine: "ember", at: day(-1)))
    }
    if hasRounds {
      if caps {
        var after = item("afterplan:\(fids(7_002))", tier: "changed", rank: 3, subject: "you",
                         eyebrow: "\(weekday(-3)) · \(monthDay(-3))", headline: "\(person(2).first) had you on the plan for \(weekday(-3)).",
                         standfirst: "Nothing posted yet.", action: "Add my round", route: ["kind": "composer"],
                         spine: "ember", at: day(-3))
        after["context"] = ["plan_id": fids(7_002), "play_on": day(-3), "course_label": courses[1].name,
                            "course_id": courses[1].key, "tee_time": "08:10"]
        items.append(after)
      }
      var plan = item("plan:\(fids(7_001))", tier: "coming", rank: 5, subject: "you",
                      eyebrow: "\(weekday(5)) · \(monthDay(5))", headline: "\(courses[0].name) is on your schedule.",
                      standfirst: "\(person(2).first) is in. Tee at 7:10.", action: "See the plan",
                      route: ["kind": "plan", "id": fids(7_001)], spine: "mut", at: day(5))
      plan["suppress"] = ["my_next_round"]
      plan["context"] = ["plan_id": fids(7_001), "play_on": day(5), "course_label": courses[0].name,
                         "course_id": courses[0].key, "tee_time": "07:10"]
      items.append(plan)
    }
    return ["me": nativeHome(), "items": items, "lead_suppress": [String](), "generated_at": stamp(0, 7, 30)]
  }

  private func item(_ key: String, tier: String, rank: Int, subject: String, eyebrow: String, headline: String,
                    standfirst: String?, action: String?, route: [String: Any], league: String? = nil,
                    spine: String, at: String? = nil) -> [String: Any] {
    [
      "key": key, "tier": tier, "rank": rank, "score": 1_000 - rank, "subject": subject, "human_subject": true,
      "eyebrow": eyebrow, "headline": headline, "standfirst": standfirst ?? NSNull(), "action": action ?? NSNull(),
      "route": route, "league_id": league ?? NSNull(), "suppress": [String](), "spine": spine, "at": at ?? NSNull(),
    ]
  }

  // MARK: the circle's rounds

  func feedRow(_ r: SynthRound) -> [String: Any] {
    [
      "round_id": r.ids, "profile_id": r.owner.ids, "golfer": r.owner.name, "marker": r.owner.marker,
      "handle": r.owner.handle, "gross": r.gross, "pvi": r.pvi, "played_on": day(r.day),
      "created_at": stamp(r.day, 17, 40), "course": r.course.name, "is_pr": r.pr, "is_first": r.first,
      "is_sub80": r.sub80, "is_me": r.owner.n == me.n, "photo_path": r.photoPath ?? NSNull(),
    ]
  }

  func roundPost(_ r: SynthRound) -> [String: Any] {
    let league = leagues.first { $0.members.contains(r.owner.n) }
    return ["id": postId(for: r), "league_id": league?.ids ?? NSNull(), "profile_id": league == nil ? r.owner.ids : NSNull(),
            "round_id": r.ids, "created_at": stamp(r.day, 17, 41)]
  }

  func roundSocial(_ r: SynthRound) -> [String: Any] {
    let faces = feedRounds.filter { $0.course.key == r.course.key }.prefix(3).map {
      ["id": $0.owner.ids, "name": $0.owner.name, "marker": $0.owner.marker]
    }
    return ["round_id": r.ids, "comment_count": r.owner.n == me.n ? 2 : (r.n % 3),
            "course": ["api_course_id": r.course.key, "name": r.course.name, "faces": Array(faces)]]
  }

  func kudos() -> [[String: Any]] {
    var out: [[String: Any]] = []
    for (i, r) in feedRounds.enumerated() {
      let givers = people.filter { $0.n != r.owner.n }.prefix(1 + i % 3)
      for (j, g) in givers.enumerated() {
        out.append(["post_id": postId(for: r), "profile_id": g.ids, "member_id": NSNull(), "emoji": "applause",
                    "created_at": stamp(r.day + 1, 7, 5 * j)])
      }
    }
    return out
  }

  func leaguePosts(_ ids: Set<String>) -> [[String: Any]] {
    leagues.filter { ids.contains($0.ids) }.flatMap { l -> [[String: Any]] in
      let roundPosts: [[String: Any]] = feedRounds.filter { l.memberOrder.contains($0.owner.n) }.prefix(4).map { x in
        ["id": postId(for: x), "league_id": l.ids, "kind": "round", "member_id": l.memberIds(x.owner.n),
         "body": "\(x.owner.name) posted \(x.gross) at \(x.course.name).", "created_at": stamp(x.day, 17, 41),
         "live_round_id": NSNull(), "round_id": x.ids, "scheduled_round_id": NSNull(), "profile_id": NSNull()]
      }
      let chat: [[String: Any]] = [
        ["id": fids(21_200 + l.n), "league_id": l.ids, "kind": "chat", "member_id": l.memberIds(4), "body": "Who is in for the early tee on Saturday?",
         "created_at": stamp(-1, 12, 10), "live_round_id": NSNull(), "round_id": NSNull(), "scheduled_round_id": NSNull(), "profile_id": NSNull()],
        ["id": fids(21_300 + l.n), "league_id": l.ids, "kind": "chat", "member_id": l.memberIds(me.n), "body": "In. Blue tees this time.",
         "created_at": stamp(-1, 12, 24), "live_round_id": NSNull(), "round_id": NSNull(), "scheduled_round_id": NSNull(), "profile_id": NSNull()],
      ]
      return roundPosts + chat + [
        ["id": fids(21_000 + l.n), "league_id": l.ids, "kind": "system", "member_id": NSNull(),
         "body": "Week \(l.week) opened. \(person(l.members[0]).first) leads by \(Int(l.points[0] - l.points[1])).",
         "created_at": stamp(-1, 6), "live_round_id": NSNull(), "round_id": NSNull(), "scheduled_round_id": NSNull(), "profile_id": NSNull()],
        ["id": fids(21_100 + l.n), "league_id": l.ids, "kind": "announce", "member_id": l.memberIds(l.members[0]),
         "body": "\(weekday(5)) at \(courses[0].name). Two spots left in the 7:10.", "created_at": stamp(-1, 18, 5),
         "live_round_id": NSNull(), "round_id": NSNull(), "scheduled_round_id": fids(7_001), "profile_id": NSNull()],
      ]
    }
  }

  func personPosts() -> [[String: Any]] {
    guard hasBuddies else { return [] }
    return [["id": fids(21_500), "league_id": NSNull(), "kind": "bag", "member_id": NSNull(),
             "body": "\(person(3).first) put a new driver in the bag.", "created_at": stamp(-3, 20),
             "live_round_id": NSNull(), "round_id": NSNull(), "scheduled_round_id": NSNull(), "profile_id": person(3).ids]]
  }

  func profileRow(_ p: SynthPerson) -> [String: Any] {
    ["id": p.ids, "display_name": p.name, "handle": p.handle, "marker": p.marker, "city": p.city,
     "home_course": courses[0].name, "index_current": p.index, "photo_path": NSNull()]
  }

  /// `league_members` by member id (applause names) or by league (rosters).
  func leagueMemberRows(_ r: SynthRequest) -> [[String: Any]] {
    let ids = Set(r.filterList("id").map { $0.lowercased() })
    let leagueIDs = Set(r.filterList("league_id").map { $0.lowercased() })
    let byProfile = r.filter("profile_id")?.lowercased()
    var out: [[String: Any]] = []
    for l in leagues {
      if !leagueIDs.isEmpty && !leagueIDs.contains(l.ids) { continue }
      for pn in l.memberOrder {
        let mid = l.memberIds(pn)
        let p = person(pn)
        if !ids.isEmpty && !ids.contains(mid) { continue }
        if let byProfile, byProfile != p.ids { continue }
        out.append(["id": mid, "league_id": l.ids, "profile_id": p.ids,
                    "role": pn == pro(l) ? "commissioner" : "player", "agreed_seasons": [1, 2],
                    "suspended_at": NSNull(), "left_at": NSNull(),
                    "marker": p.marker, "display_name": p.name, "joined_at": stamp(-60, 12),
                    "leagues": ["name": l.name, "code": l.code],
                    "profile": ["id": p.ids, "display_name": p.name, "marker": p.marker, "handle": p.handle,
                                "index_current": p.index, "photo_path": NSNull()] as [String: Any]])
      }
    }
    let limit = Int(r.query["limit"]?.first ?? "") ?? out.count
    return Array(out.prefix(limit))
  }

  // MARK: the inbox

  func notifications() -> [String: Any] {
    guard hasRounds, let mine = myRounds.first else {
      return ["ok": true, "unread": 0, "next_before": NSNull(), "next_before_id": NSNull(), "items": [Any]()]
    }
    let items: [[String: Any]] = [
      ["id": fids(9_201), "kind": "own_round", "actor": ["id": person(2).ids, "name": person(2).name, "marker": person(2).marker],
       "round_id": mine.ids, "comment_id": fids(9_301), "created_at": stamp(mine.day + 1, 8, 12), "read": false,
       "excerpt": "That \(mine.gross) in the wind counts double.", "course_name": mine.course.name],
      ["id": fids(9_202), "kind": "reply", "actor": ["id": person(9).ids, "name": person(9).name, "marker": person(9).marker],
       "round_id": mine.ids, "comment_id": fids(9_302), "created_at": stamp(mine.day + 1, 9, 40), "read": true,
       "excerpt": "Rematch at the same tees next week.", "course_name": mine.course.name],
    ]
    return ["ok": true, "unread": 1, "next_before": NSNull(), "next_before_id": NSNull(), "items": items]
  }

  // MARK: invitations

  func invites() -> [[String: Any]] {
    guard hasSeasons else { return [] }
    return [["id": fids(9_101), "kind": "league", "container_id": fids(1_003), "container_name": Self.inviteLeagueName,
             "inviter": person(8).name, "starts_on": day(12), "created_at": stamp(-1, 19), "buy_in": 25,
             "season_number": 1, "reup": false]]
  }

  /// The join covenant: what joining a season agrees to, in the season's terms.
  func covenant() -> [String: Any] {
    [
      "name": Self.inviteLeagueName, "buyin_cents": 2_500, "preset": "standard", "floor": 1, "finish": "cup_final",
      "roster": ["pro_name": person(8).first, "count": 6,
                 "names": [person(8).name, person(2).name, person(3).name, person(4).name, person(10).name, person(11).name]],
      "starts_on": day(12), "weeks": 10, "counting_cap": 4,
      "split": ["champion": 60, "runner_up": 25, "points_king": 15],
      "pay": ["has_note": true, "due_on": day(19)],
      "phase": "setup", "handicap_allowance": 100, "every_round_counts": false, "ends_on": day(12 + 69),
      "season_number": 1, "reup": false, "agreed": false, "structure": "solo",
    ]
  }
}
#endif
