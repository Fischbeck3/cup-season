// Cup Season — the declared fallback (IOS-029b, UX_PRINCIPLES.md §5.4 rule 2).
//
// "Render as today" is NOT available. The wave that adds `home_dispatch` also
// retires `HomeMode`, `HomeLead`, `HomeHeroCopy` and `HomeLeagueRow`, so there
// is no "today" left to render. The declared fallback is therefore a PRODUCER,
// named here, shipped in the same push, and guarded by **preflight check 23**:
// if this file leaves the Home target the push fails.
//
// What it composes, from reads that already exist:
//
//   `native_home`  — the memberships, the standing, the inlined clash (v3),
//                    the live round, the tee sheet, the invitations
//   `home_feed`    — the circle's rounds, for the one CIRCLE item
//
// What it does NOT do:
//
//   * it does not rank. There is no lead card on this path — a client that
//     cannot reach the ranker must not invent one, because the veto is the
//     server's assertion and a guessed lead is exactly the failure D231
//     exists to prevent. `HomeRank.fallbackOrder` sorts the items by the
//     static, tier-less order **CLOSING → CHANGED → COMING → CIRCLE**, and
//     Home renders them as a list under the strip.
//   * it does not compute a score, a modifier or a `rank_reason`. Those are
//     the ranker's answers and this path does not have them.
//   * it does not draw the ME strip differently. `MeStripCopy.make` is pure
//     over `Me` + the tee sheet and needs no ranker, so the strip is the same
//     four facts either way — which is the point of putting them in a
//     producer in wave 1a.
//
// The sentences are the ones the retiring producers carried, kept: D216's
// yield (an idle clash is a COMING item, never a stake), D207's two-person
// line, D140's solo exclusion from the floor, and D129's owe line, which is
// not here at all because the strip owns it (L-34).

import Foundation

public enum HomeFallbackItems {

  /// Every item this client can honestly compose without the ranker, in the
  /// static order. `today` is injectable so the table test can pin a date.
  /// `liveHost` is the first name of whoever STARTED the live round, when the
  /// device knows it (`LiveRoundStore.state.host`). `native_home`'s
  /// `live_round` carries `mine` but no name, so this is passed in rather than
  /// guessed — and with nothing in hand the invitation still says the true
  /// thing, just without a subject.
  public static func make(_ me: Me?, feed: [HomeFeedRow] = [], today: String = CSDate.today(),
                          calendar: Calendar = .current, liveHost: String? = nil) -> [HomeDispatch.Item] {
    guard let me else { return [] }
    var out: [HomeDispatch.Item] = []

    // ---- CLOSING · a live round --------------------------------------------
    // R-04 · TWO FACES, because `native_home.live_round` is "a live round the
    // caller is SEATED in" — which includes a round somebody else started and
    // I have never opened. One face said "You are on the card right now" and
    // "the card is open" for that state, where both sentences are false, the
    // host is unnamed and the verb JOIN is missing. `LiveCopy.resumeBanner`
    // has always produced both; nothing rendered it after the resume banner
    // came off Home.
    //
    // LV-09 · and the noun: §2.1 splits "your card" (the person) from "your
    // scorecard" (the holes). This is the holes.
    if let lr = me.live_round {
      let mine = lr.mine != false
      let who = liveHost.map { CSBands.fn1($0) }
      out.append(.init(key: "live:\(lr.id.uuidString)", tier: .closing,
                       subject: mine ? "you" : (who ?? "a golfer"), humanSubject: true,
                       eyebrow: mine
                         ? ((lr.course_label?.uppercased()).flatMap { $0.isEmpty ? nil : $0 } ?? "A ROUND IS LIVE")
                         : "JUST TEED OFF · NOTHING SCORED YET",
                       headline: mine
                         ? "You’re in a live round right now."
                         : "\(who ?? "Somebody") started a live round with you.",
                       standfirst: mine
                         ? lr.league_name.flatMap { $0.isEmpty ? nil : "\($0) — the scorecard is open." }
                         : ((lr.course_label?.isEmpty == false) ? lr.course_label : lr.league_name),
                       action: mine ? "Back to the round" : "Join",
                       route: .live(lr.id),
                       leagueId: lr.league_id, spine: .ember,
                       at: lr.started_at.map { CSDate.iso($0) }))
    }

    // ---- CLOSING · an invitation waiting ------------------------------------
    // The verb is "See the terms", never "Join": every join passes the
    // covenant, at every stake, $0 included (L-12, D136).
    // `invites` rides the payload as raw jsonb (`my_invites()` verbatim), so
    // it is read by key and a row that cannot answer is skipped, never guessed.
    for inv in me.invites {
      guard let id = inv["id"]?.string, let container = inv["container_id"]?.string.flatMap(UUID.init(uuidString:))
      else { continue }
      let who = inv["inviter"]?.string.flatMap { $0.isEmpty ? nil : CSBands.fn1($0) }
      let kind = inv["kind"]?.string
      out.append(.init(key: "invite:\(id)", tier: .closing,
                       subject: who, humanSubject: who != nil,
                       eyebrow: "AN INVITATION",
                       headline: "\(who ?? "A golfer") put you on \(inv["container_name"]?.string ?? "a season").",
                       standfirst: "See the terms before you are in.",
                       action: "See the terms",
                       route: .invite(container, kind: kind),
                       leagueId: kind == "league" ? container : nil,
                       spine: .ember, at: inv["created_at"]?.string))
    }

    // ---- per membership -----------------------------------------------------
    for m in me.memberships {
      if let item = clashItem(m, today: today) { out.append(item) }
      if let item = floorItem(m, today: today, calendar: calendar) { out.append(item) }
      if let item = movementItem(m) { out.append(item) }
      if let item = firstTeeItem(m, today: today, calendar: calendar) { out.append(item) }
      if let item = chapterItem(m) { out.append(item) }
    }

    // ---- COMING · a plan on the sheet ---------------------------------------
    // The strip owns NEXT (L-34), so this item names the COURSE and the
    // PEOPLE — never the tee time a second time on one screen.
    for p in MeStripCopy.mine(me.upcoming, today: today).prefix(2) {
      guard let on = p.play_on, let days = CSDate.days(from: today, to: on), days <= 8 else { continue }
      let mine = p.mine != false
      let who = p.display_name.flatMap { CSBands.fn1($0) } ?? "A golfer"
      // DEF-2 (L-34) · the EYEBROW carries the where-and-when, so the headline
      // carries the who-and-what. It read `MON · GOLD CANYON — DINOSAUR
      // MOUNTAIN · BLACK/BLUE` with `Galen has you down for Gold Canyon —
      // Dinosaur Mountain · Black/Blue.` immediately under it: the same fact,
      // in full, twice on one card. That is the whole reason the card grammar
      // has three slots.
      let day = MeStripCopy.dayWord(on, today: today, calendar: calendar)
      let tee = p.tee_time.flatMap(MeStripCopy.teeText).map { "\($0) tee" }
      let party = (p.rsvp_in ?? 0) > 1 ? "\(p.rsvp_in ?? 0) of you in" : nil
      let stand = [tee, party].compactMap { $0 }.joined(separator: " · ")
      out.append(.init(key: "plan:\(p.id?.uuidString ?? on)", tier: days <= 3 ? .closing : .coming,
                       subject: mine ? "you" : who, humanSubject: true,
                       eyebrow: [MeStripCopy.dayToken(on, today: today, calendar: calendar),
                                 (p.course_label?.isEmpty == false) ? p.course_label!.uppercased() : nil]
                                  .compactMap { $0 }.joined(separator: " · "),
                       headline: mine ? "You have a round on \(day)."
                                      : "\(who) has you down for \(day).",
                       standfirst: !stand.isEmpty ? stand + "."
                                   : (p.my_rsvp == nil ? "You have not said either way." : nil),
                       action: p.my_rsvp == nil ? "Say you're in" : "Open the plan",
                       route: p.id.map(HomeDispatch.Route.plan) ?? .declare,
                       spine: .ember, at: on))
    }

    // ---- CIRCLE · the freshest thing somebody I know did --------------------
    if let r = feed.first(where: { $0.is_me != true && $0.gross != nil }) {
      let who = HomeCopy.who(r)
      let mile = HomeCopy.milestone(r)
      // QB-20 · the eyebrow said `AROUND YOUR BUDDIES`, which is also the
      // SECTION HEAD one thumb-flick below it. Two readers took the repeat for
      // a rendering bug — *"for a second I think I've scrolled backwards"* —
      // and one of them read the two instances as different things. A card's
      // eyebrow names its own subject; the section keeps the name.
      let when = r.played_on.map { MeStripCopy.dayToken($0, today: today, calendar: calendar) }
      out.append(.init(key: "story:\(r.round_id?.uuidString ?? who)", tier: .circle,
                       subject: who, humanSubject: true,
                       eyebrow: [who.uppercased(), when].compactMap { $0 }.joined(separator: " · "),
                       headline: "\(who) posted \(r.gross.map(String.init) ?? "a round")"
                                   + ((r.course?.isEmpty == false) ? " at \(r.course!)." : "."),
                       standfirst: mile,
                       action: "See the round",
                       route: r.round_id.map(HomeDispatch.Route.receipt),
                       spine: mile == nil ? .mut : .gold,
                       at: r.played_on))
    }

    // ---- OPPORTUNITY · the door worth walking through today ------------------
    // Fired only on a REAL shape (L-22): no rounds at all, or rounds and
    // nobody to show them to. Never a tip, never a promotion.
    if (me.profile?.rounds_count ?? 0) == 0 {
      out.append(.init(key: "first_round", tier: .opportunity,
                       subject: "you", humanSubject: true,
                       eyebrow: "NEW HERE",
                       headline: "Your first round is the only thing missing.",
                       standfirst: "Add one you already played — course, score, done. Your number starts building at three.",
                       action: "Add my round", route: .composer, spine: .ember))
    }

    return HomeRank.fallbackOrder(out)
  }

  // MARK: - the per-membership items

  /// D216, verbatim: a clash NEITHER golfer has posted in, with more than a
  /// day to run, is a COMING item and never a stake. It re-enters CLOSING the
  /// moment either side posts, or on the last-call day.
  static func clashItem(_ m: Me.Membership, today: String) -> HomeDispatch.Item? {
    guard let c = m.clash, let them = c.them_name else { return nil }
    let who = CSBands.fn1(them)
    let left = c.days_left ?? 0
    let closes = c.closes_today ?? false
    let idle = c.mine == nil && c.theirs == nil
    let yields = idle && left > 1 && !closes
    let when = closes ? "today" : left == 1 ? "tomorrow" : "in \(left) days"
    let head: String
    let stand: String?
    let act: String
    let route: HomeDispatch.Route
    if yields {
      head = "Your clash with \(who) is open."
      stand = "Best round of the week takes it."
      act = "Add my round"; route = .composer
    } else if let theirs = c.theirs, c.mine == nil {
      head = "\(who) posted \(theirs.gross.map(String.init) ?? "a round")."
      stand = "That is the number, and the week closes \(when)."
      act = "Add my round"; route = .composer
    } else if let mine = c.mine, c.theirs == nil {
      // SA-2 · the state the shipped lead had no sentence for. The subject is
      // the OPPONENT, because that is where the clock actually sits.
      let clock = closes ? "today" : left == 1 ? "one day" : "\(left) days"
      head = "\(who) has \(clock) to answer your \(mine.gross.map(String.init) ?? "round")."
      stand = "Your round is the number to beat."
      act = "See the receipt"
      route = mine.round_id.map(HomeDispatch.Route.receipt) ?? .season(m.league_id, pane: nil)
    } else {
      head = "You and \(who) are both in."
      stand = "The week closes \(when). Best round takes it."
      act = "See the receipt"
      route = c.mine?.round_id.map(HomeDispatch.Route.receipt) ?? .season(m.league_id, pane: nil)
    }
    let name = (c.rivalry?.isEmpty == false) ? c.rivalry! : m.name
    return .init(key: "clash:\(m.league_id.uuidString):\(c.week_no ?? 0)",
                 tier: yields ? .coming : .closing,
                 subject: who, humanSubject: true,
                 eyebrow: "\(name.uppercased()) · THE CLASH · CLOSES \(when.uppercased())",
                 headline: head, standfirst: stand, action: act, route: route,
                 leagueId: m.league_id,
                 suppress: c.mine != nil ? [.myLastRound] : [],
                 spine: .ember, at: c.ends_on)
  }

  /// A-4 · a movement label carries its own clock or it does not render.
  /// `prev_rank` is a SUNDAY snapshot, so the sentence says "since Sunday" —
  /// a bare "held" is unwritable here by construction.
  /// R-05 · THE MONTH MINIMUM, the one item with a hard deadline and a real
  /// penalty (−5 a round, or a forfeited month). The server ranker composes it
  /// and NEITHER client fallback did — so on the day `home_dispatch` cannot be
  /// reached, which is every day until the migrations land, the deadline
  /// simply never appeared.
  ///
  /// The guards are the retired `HomeLead`'s, verbatim: D140's SOLO EXCLUSION
  /// (a solo season has no squads, so no floor can fire), the partial-month
  /// exclusion (a golfer who joined mid-month is not behind), a floor that is
  /// actually set, credits short of it, and the last three days of the month —
  /// a minimum named on the 4th is a nag, not a clock (L-22).
  static func floorItem(_ m: Me.Membership, today: String, calendar: Calendar) -> HomeDispatch.Item? {
    guard !m.isSolo, let pu = m.pulse, pu.partial != true,
          let floor = pu.floor, floor > 0,
          let credits = pu.credits, credits < Double(floor),
          let left = CSDate.days(from: today, to: ScheduleDates.endOfMonth(today)),
          left <= 3, left >= 0,
          let monthIdx = ScheduleDates.parts(today)?.m, (1...12).contains(monthIdx),
          let closeDay = ScheduleDates.jsDay(ScheduleDates.endOfMonth(today)) else { return nil }
    let short = Double(floor) - credits
    let shortText = short == short.rounded() ? String(Int(short)) : String(format: "%.1f", short)
    return .init(key: "floor:\(m.league_id.uuidString)", tier: .closing,
                 subject: "you", humanSubject: true,
                 eyebrow: "\(LeagueDates.monthsLong[monthIdx - 1].uppercased()) CLOSES \(LeagueDates.dow[closeDay].uppercased())",
                 headline: "You are \(shortText) short of the minimum.",
                 standfirst: m.squad.map { "The \($0.name) carry the penalty, not you." },
                 action: "Add my round", route: .composer,
                 leagueId: m.league_id, spine: .ember)
  }

  static func movementItem(_ m: Me.Membership) -> HomeDispatch.Item? {
    guard let st = m.standing, let prev = st.prev_rank, prev != st.rank,
          m.season?.status == "active" else { return nil }
    let up = prev > st.rank
    return .init(key: "move:\(m.league_id.uuidString)", tier: .changed,
                 subject: "you", humanSubject: true,
                 eyebrow: "\(m.name.uppercased()) · WEEK \(LeagueDates.week(m.season))",
                 headline: up ? "You moved up \(prev - st.rank) since Sunday."
                              : "You were passed since Sunday.",
                 standfirst: st.next_up?.name.map { "\($0) is the next one up." },
                 action: "See the table",
                 route: .season(m.league_id, pane: "table"),
                 leagueId: m.league_id, spine: .gold)
  }

  /// L-13 in words, once: rounds posted before the first tee build your
  /// number and do not score. Six of six audit posters were promised points a
  /// week before their season opened.
  static func firstTeeItem(_ m: Me.Membership, today: String, calendar: Calendar) -> HomeDispatch.Item? {
    guard let s = m.season, let days = CSDate.days(from: today, to: s.starts_on), days > 0 else { return nil }
    return .init(key: "firsttee:\(m.league_id.uuidString)", tier: days <= 3 ? .closing : .coming,
                 subject: m.pro_name ?? "you", humanSubject: true,
                 eyebrow: "FIRST TEE \(LeagueDates.dowMonDay(s.starts_on, calendar: calendar).uppercased())",
                 headline: "\(m.name) starts in \(days) day\(days == 1 ? "" : "s").",
                 standfirst: "Rounds you post before then still build your number — they just do not score yet.",
                 action: "Open the season", route: .season(m.league_id, pane: nil),
                 leagueId: m.league_id, spine: .ember, at: s.starts_on)
  }

  /// The season's slow truth, told by a PERSON — never a bare standing, which
  /// is the ME strip's business and can never lead (D231's veto).
  static func chapterItem(_ m: Me.Membership) -> HomeDispatch.Item? {
    guard let st = m.standing, let status = m.season?.status,
          status == "active" || status == "cup_final" else {
      // R-H · a quiet day reaches BACK for an older true fact rather than
      // stopping at "nothing has moved". The last completed season is that
      // fact, it is on the payload, and it needs no new read.
      guard let last = m.last_season, let champ = last.champion_name, !champ.isEmpty else { return nil }
      // LV-11 · the champion may be ME. Without the branch a golfer who WON
      // read their own name in the third person, beside "You finished 1st of
      // 8." The season's live item branches this way one case down.
      let iWon = last.champion_is_me == true
      return .init(key: "lastseason:\(m.league_id.uuidString)", tier: .chapter,
                   subject: iWon ? "you" : champ, humanSubject: true,
                   eyebrow: "\(m.name.uppercased()) · SEASON COMPLETE",
                   headline: iWon ? "You took the last one." : "\(champ) took the last one.",
                   standfirst: (last.my_rank).flatMap { r in last.of.map { "You finished \(CSCopy.ordinal(r)) of \($0)." } },
                   action: "See how it ended", route: .season(m.league_id, pane: nil),
                   leagueId: m.league_id, spine: .gold, at: last.ended_on)
    }
    guard let leader = SeasonFacts.clean(st.leader_name) else { return nil }
    let week = LeagueDates.week(m.season)
    let of = LeagueDates.weeksTotal(m.season)
    return .init(key: "chapter:\(m.league_id.uuidString)", tier: .chapter,
                 subject: leader, humanSubject: true,
                 eyebrow: "\(m.name.uppercased()) · WEEK \(week) OF \(of)",
                 headline: st.rank == 1 ? "You are the one to catch." : "\(leader) is the one to catch.",
                 standfirst: SeasonFacts.race(st).map { "\($0.prefix(1).uppercased())\($0.dropFirst())." },
                 action: "Open the season", route: .season(m.league_id, pane: nil),
                 leagueId: m.league_id, spine: .mut)
  }
}
