// Cup Season — the season's own facts, in sentences (relocated 2026-09-05).
//
// These are the pure producers that used to live in `HomeHeroCopy` and
// `HomeLeagueRow`. **The two SURFACES retired with wave 1b** — Home's hero and
// the D121 compact rows are replaced by one ranked dispatch (D228, D229,
// D231) — but the RULINGS they encoded did not, and this file is where they
// now live so wave 4's season page reads them rather than retyping them.
//
// Every ruling carried across, named, with its assertions in
// `HomeCopyContractTests.swift`:
//
//   D26   "back of" — the Climb's catch-framing, the table's first noun.
//   D130  the leader BY NAME — a person is beaten by a person, not "the lead";
//         its build note (2026-09-02) owns "clear of" and "Level with Galen · 32 – 32.".
//   D70   a $0 league never sees a dollar sign.
//   D23   money addressed to a person is SELF-only ("You still owe…").
//   D47   the books = money (D131 upholds it) — "on the books" is a money line.
//   D106  the pot's two numbers — "collected" and "still owe" are its words.
//   D138  the Final is a field of two — a seed is the locked row, never the table.
//   D129  the owe line: "You still owe $50 · Venmo @casey · by Sat Sep 5".
//   D140  a solo league has no floor and no floor clock, ever.
//   D14   the floor sentence, verbatim.
//   D126  the endgame is a sentence you can always see — `LeagueCopy.endgame`
//         says it; §14.3 is the ladder it names ("Months won breaks it.").
//   D207  the two-person season's own sentences.
//
// Pure functions over (Membership, today). Nothing here reads the clock or
// the network, so a test can pin every sentence. Every name arrives from
// `native_home()` already in the board's own form — `firstname(display_name)`
// for a golfer, `squads.name` for a squad — so a sentence says "Galen" where
// the board says "Galen" and never first-names a squad called "Sunday Money".
// A payload without names falls back to the sentences that predate them.

import Foundation

public enum SeasonFacts {
  // MARK: - the standing line

  /// The sentence under the figure, in season.
  ///
  /// Two-person league (`of == 2`) — the whole race is the two of you, so the
  /// score is the sentence:
  ///   behind  "12 back of Galen · 9 – 21"
  ///   leading "You lead Jade by 22 · 31 – 9"
  ///   level   "Level with Galen · 14 – 14." (the tiebreak lives in the endgame foot)
  /// Bigger field:
  ///   leading "6 clear of Jade"
  ///   behind  "12 back of Galen" + " · 3 back of 2nd" when a rung sits between
  ///   level   "Level with Galen · 14 – 14."
  /// Skew (no `leader_name`): "12 points back of the lead." / "Level with the
  /// lead." / "You lead by 6 points." / "Top of the table." — a v1 payload
  /// never carries the leader's margin, so the top row claims no margin and
  /// never a tie.
  public static func line(_ m: Me.Membership) -> String {
    guard let st = m.standing else { return "Standings start at the first posted round." }
    let mine = CSCopy.points(st.points ?? 0)
    if st.rank == 1 {
      if st.of <= 1 { return "Only you on the table so far." }
      // A v1 payload never carries a rank-1 margin (`gap_to_next` is `lag()`,
      // null on the top row) — so "no margin known" is NOT "level"; it is
      // "top of the table", which is all the phone can honestly say.
      let gap = st.gap_to_next ?? ((st.points != nil && st.runner_up_points != nil) ? (st.points! - st.runner_up_points!) : nil)
      guard let other = clean(st.runner_up_name) else {
        if let g = gap, g > 0 { return "You lead by \(CSCopy.points(g)) points." }
        return "Top of the table."
      }
      guard let g = gap else { return "Top of the table." }
      guard g > 0 else { return level(with: other, at: mine) }
      if st.of == 2 {
        let theirs = CSCopy.points(st.runner_up_points ?? ((st.points ?? 0) - g))
        return "You lead \(other) by \(CSCopy.points(g)) · \(mine) – \(theirs)"
      }
      return "\(CSCopy.points(g)) clear of \(other)"
    }
    guard let leader = clean(st.leader_name) else {
      if let g = st.gap_to_leader { return g == 0 ? "Level with the lead." : "\(CSCopy.points(g)) points back of the lead." }
      return "In the race."
    }
    guard let g = st.gap_to_leader else { return "In the race." }
    if g <= 0 { return level(with: leader, at: mine) }
    if st.of == 2 {
      let theirs = CSCopy.points(st.leader_points ?? ((st.points ?? 0) + g))
      return "\(CSCopy.points(g)) back of \(leader) · \(mine) – \(theirs)"
    }
    var s = "\(CSCopy.points(g)) back of \(leader)"
    if st.rank > 2, let n = st.gap_to_next, n > 0 { s += " · \(CSCopy.points(n)) back of \(CSCopy.ordinal(st.rank - 1))" }
    return s
  }

  /// "Level with Galen · 14 – 14." — the tiebreak is NOT repeated here: the
  /// endgame foot two lines down ends with the verbatim "Level on points?
  /// Months won breaks it." and one card says a rule once.
  private static func level(with other: String, at pts: String) -> String {
    "Level with \(other) · \(pts) – \(pts)."
  }

  /// "3rd of 10" — the caption under the figure. nil before the first posted round.
  public static func caption(_ m: Me.Membership) -> String? {
    guard let st = m.standing else { return nil }
    return "\(CSCopy.ordinal(st.rank)) of \(st.of)"
  }

  // MARK: - the Cup Final (D138 / §14.3 — a field of two, scored fresh)

  /// The figure in the Final: a finalist's LOCKED seed (`standing.seed`,
  /// `cup_finalists` on the payload); everyone else — and every payload
  /// without the seed — their place on the table, which is still live.
  /// Never the table's rank called a seed: the table keeps moving through
  /// the Final, and only two seeds exist.
  public static func finalFigure(_ m: Me.Membership) -> String? {
    guard let st = m.standing else { return nil }
    return CSCopy.ordinal(st.seed ?? st.rank)
  }

  /// "1st seed" for a finalist; "5th of 8" (`caption`) for anyone else.
  public static func seedCaption(_ m: Me.Membership) -> String? {
    guard let st = m.standing else { return nil }
    if let seed = st.seed { return "\(CSCopy.ordinal(seed)) seed" }
    return caption(m)
  }

  /// The sentence in the Final. A finalist (or a payload that cannot say):
  ///   "Four weeks, scored fresh. Whoever's hottest takes the cup. 2 weeks left."
  /// A non-finalist is told the truth (D138) — who the cup is between, and
  /// that the table race is still theirs:
  ///   "Galen v Jade for the cup. Your place on the table is still live — 12 back of Galen. 2 weeks left."
  /// Both end on the clock, as the web's Final hero foots both of its
  /// branches with it. The race clause is `line(m)` lowered after the dash
  /// (the web pastes it capitalised — a phone ruling, recorded in D138).
  public static func finalLine(_ m: Me.Membership, weeksLeft: Int) -> String {
    let clock = finalClock(weeksLeft)
    if let st = m.standing, st.seed == nil, let f = st.finalists, f.count >= 2,
       let a = clean(f[0]), let b = clean(f[1]) {
      var race = line(m)
      if let c = race.first, c.isLetter { race = c.lowercased() + race.dropFirst() }
      if !race.hasSuffix(".") { race += "." }
      return "\(a) v \(b) for the cup. Your place on the table is still live — \(race) \(clock.prefix(1).uppercased())\(clock.dropFirst())."
    }
    return "Four weeks, scored fresh. Whoever's hottest takes the cup. \(clock.prefix(1).uppercased())\(clock.dropFirst())."
  }

  /// The Final's clock, shared by the hero and the D121 row so the two can
  /// never disagree — and the web's sentence (`index.html`, the Final hero):
  /// "2 weeks left" / "1 week left", never "0 left".
  public static func finalClock(_ weeksLeft: Int) -> String {
    let w = max(1, weeksLeft)
    return "\(w) week\(w == 1 ? "" : "s") left"
  }

  // MARK: - the foot, rung by rung

  /// The rules foot.
  ///
  /// Solo (D140 — no floor, no floor clock, whatever the pulse carries):
  ///   "Best 4 rounds a month count · 2 posted · 28 days left in September"
  ///   — `posted` is this month's counted credits (`pulse.credits`); no cap →
  ///   "Every round counts · …". Outside the season window the clock is
  ///   meaningless, so only the cap clause is spoken.
  /// Squads: the floor sentence Home has carried since D14, unchanged —
  ///   "Partial month · no minimum" / "Minimum met · 6/4" /
  ///   "4 a month · 2 to go" — then "Best 4 rounds a month count", else nil.
  public static func footRule(_ m: Me.Membership, today: String = CSDate.today(), calendar: Calendar = .current) -> String? {
    let cap = m.settings?.counting_cap.map { "Best \($0) rounds a month count" }
    // Outside the window there is no month to have a floor or a clock in —
    // the pulse still comes back (partial = true before first tee) and would
    // otherwise say "floors waived" about a month that is not in the season.
    // The Cup Final is INSIDE it: caps and floors are calendar-month machinery
    // (§14.0) and `close_month` assesses a Final's full month like any other,
    // so the foot keeps saying what the lead card's floor rung may then ask.
    switch SeasonPhase.of(m, today: today) {
    case .season, .cupFinal: break
    default: return cap
    }
    if m.isSolo {
      let posted = CSCopy.points(m.pulse?.credits ?? 0)
      let left = LeagueDates.daysInMonth(today, calendar: calendar) - (Int(today.suffix(2)) ?? 0)
      let month = LeagueDates.monthLong(today, calendar: calendar)
      let clock = left <= 0 ? "last day of \(month)" : left == 1 ? "1 day left in \(month)" : "\(left) days left in \(month)"
      return "\(cap ?? "Every round counts") · \(posted) posted · \(clock)"
    }
    if let p = m.pulse, let floor = p.floor, floor > 0 {
      let credits = p.credits ?? 0
      if p.partial == true { return "Partial month · no minimum" }
      return credits >= Double(floor) ? "Minimum met · \(CSCopy.points(credits))/\(floor)"
                                      : "\(floor) a month · \(CSCopy.points(Double(floor) - credits)) to go"
    }
    return cap
  }

  /// QB-09 · **THE MONTH LINE, ON HOME, EVERY DAY.**
  ///
  /// `00-launch-default.png` carried *"Best 4 rounds a month count · 1 posted ·
  /// 26 days left in September"* above the fold on every open. After the
  /// rebuild the only surface carrying it on Home was `floorItem`, which
  /// guards on `!isSolo` **and** `left <= 3` — so a solo season never saw it at
  /// all and a squads season saw it on three days of thirty. That was a silent
  /// deletion of a fact `UX_AUDIT` §8.2/§8.3 keep, not a decision.
  ///
  /// **A cap and a clock are facts, not alarms.** `floorItem` stays exactly as
  /// it is — it is the alarm, and an alarm should fire near the deadline. This
  /// is the fact, and it is present in every state with a live season, in both
  /// shapes, in the strip's own quiet type.
  ///
  /// L-44 · an unread credit count renders NOTHING rather than a zero: "0
  /// posted" over a payload that did not carry the pulse is a claim about the
  /// golfer's month that nobody made.
  public static func monthRow(_ m: Me.Membership, today: String = CSDate.today(),
                              calendar: Calendar = .current) -> String? {
    switch SeasonPhase.of(m, today: today) {
    case .season, .cupFinal: break
    default: return nil
    }
    guard let cap = m.settings?.counting_cap, cap > 0 else { return nil }
    let left = LeagueDates.daysInMonth(today, calendar: calendar) - (Int(today.suffix(2)) ?? 0)
    let month = LeagueDates.monthLong(today, calendar: calendar)
    let clock = left <= 0 ? "last day of \(month)"
              : left == 1 ? "1 day left in \(month)"
              : "\(left) days left in \(month)"
    let head = "Best \(cap) a month count"
    guard let credits = m.pulse?.credits else { return "\(head) · \(clock)" }
    return "\(head) · \(CSCopy.points(credits)) posted · \(clock)"
  }

  /// D126 · how the season ends — `LeagueCopy.endgame`. nil until a season exists.
  public static func footEndgame(_ m: Me.Membership, calendar: Calendar = .current) -> String? {
    guard let s = m.season else { return nil }
    return LeagueCopy.endgame(finish: m.settings?.finish, structure: m.settings?.structure,
                              startsOn: s.starts_on, endsOn: s.ends_on, calendar: calendar)
  }

  /// D106 · the pot's numbers, to every member: "$150 on the books · $0
  /// collected", and on the hero (`stillOwe`) the third figure the Pot pane
  /// prints under the same condition — "· 2 still owe" while the cash is
  /// short. Nobody is named (D23). nil on a $0 league (D70). On a v1 payload
  /// (no `buy_in`) a solo league's books are roster × stake and nothing is
  /// claimed about cash — nobody counted it; a squads league says nothing
  /// (its `of` counts squads).
  public static func footMoney(_ m: Me.Membership, stillOwe: Bool = false) -> String? {
    let stake = m.stakeCents
    // The books open at lock (D112): in setup the Pro is still writing the
    // bylaws, the stake can change, and the roster is one — nothing is owed.
    guard stake > 0, m.phase != "setup" else { return nil }
    if let b = m.buy_in, let players = b.players, players > 0 {
      let collected = b.collected_cents ?? ((b.paid_count ?? 0) * stake)
      var s = "\(PotMath.money(players * stake)) on the books · \(PotMath.money(collected)) collected"
      let owing = players - (b.paid_count ?? 0)
      if stillOwe, collected < players * stake, owing > 0 { s += " · \(owing) still owe" }
      return s
    }
    // No roster count from the server. In a solo league `standing.of` IS the
    // roster (v_individual_standings lists every member); in a squads league it
    // is the squad count, and squads × stake is a number nobody owes — say
    // nothing rather than something false (§16).
    guard m.isSolo, let of = m.standing?.of, of > 0 else { return nil }
    return "\(PotMath.money(of * stake)) on the books"
  }

  /// D129 / D23 · self-only, and only while the caller's own buy-in is unpaid:
  /// "You still owe $75 · Venmo @casey · by Sat Sep 5". No note → D129's own
  /// clause, "ask the Pro how to pay — money moves between you". A due date
  /// already gone reads "was due Sat Aug 29". The Pro is the Pro BEFORE any
  /// note: the note and the date are their own terms and they are the one who
  /// marks, so their line is the pane's state word ("in" / "not in") joined
  /// to the pane's verb ("marks"), and nothing else — "Your own $75 isn't
  /// marked in yet". Never on a $0 league, never before lock, never on a v1
  /// payload (no `paid`).
  public static func owe(_ m: Me.Membership, today: String = CSDate.today(), calendar: Calendar = .current) -> String? {
    let stake = m.stakeCents
    guard stake > 0, m.phase != "setup", let b = m.buy_in, b.paid == false else { return nil }
    if m.isPro { return "Your own \(PotMath.money(stake)) isn't marked in yet" }
    var s: String
    if let how = clean(b.note) { s = "You still owe \(PotMath.money(stake)) · \(how)" }
    else { s = "You still owe \(PotMath.money(stake)) · ask the Pro how to pay — money moves between you" }
    if let due = b.due_on, CSDate.local(due, calendar: calendar) != nil {
      s += due < today ? " · was due \(LeagueDates.dowMonDay(due, calendar: calendar))"
                       : " · by \(LeagueDates.dowMonDay(due, calendar: calendar))"
    }
    return s
  }

  static func clean(_ s: String?) -> String? {
    let t = (s ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    return t.isEmpty ? nil : t
  }

  // MARK: - the season's one line (relocated from the D121 row)

  /// The line, by stage:
  ///   season    "Week 7 of 26 · 1st of 2, 22 clear of Jade · $150 on the books · $0 collected"
  ///             "Week 5 of 13 · 3rd of 10, 12 back of Galen"
  ///             "Week 5 of 13 · 2nd of 10, level with Galen"
  ///             the money clause is `SeasonFacts.footMoney` — nothing on a
  ///             $0 league (D70), no "collected" on a v1 payload.
  ///   preseason "First tee Sat Sep 5 · 5 on the roster"
  ///   cup final "Cup Final · 2 weeks left" / "· 1 week left" — never the season's place: the
  ///             Final is scored fresh (§14.3), so the table's rank is not its rank
  ///   complete  "Season complete" (`LeagueCopy.seasonNote`)
  ///   forming   "Forming" / "Squads drawing" (`LeagueCopy.Stage.label`)
  ///
  /// **One producer, two grains** (the pattern IOS-036 names for the endgame
  /// clause). `week: false` drops the leading week clause and nothing else —
  /// for a surface whose EYEBROW already carries the week, where printing it
  /// again is the same fact in two places on one row (L-34). Compete's peer
  /// list is that surface; a second producer for it would be the drift D234
  /// exists to forbid.
  ///
  /// **`rank: false` IS THE THIRD GRAIN, AND IT EXISTS BECAUSE A RANK IS A
  /// FIGURE** (D286). Where the surface draws the standing as a rule-and-figure
  /// — Compete's season row — the sentence must stop printing it, or the
  /// golfer is told his position twice in two voices on one row. The race
  /// clause and the money stay: those are the STORY beside the record, which
  /// is the same division §9.9 makes for the gap ("the chapter line may say
  /// the gap; the column is the record").
  /// **D318 · YOUR OWN DEBT RIDES ON THE SEASON THAT IS OWED IT.** The money
  /// slot printed *"$75 · YOU OWE"* on Home, above the wire, as a sum with no
  /// creditor — and the owner moved it: *"you owe needs to go to compete."*
  ///
  /// It is the SHORT form and not `owe`'s full sentence: this is a row in a
  /// list, and the how-to-pay and the due date belong on the season page where
  /// the pot is, next to the figure they qualify. The row says who wants it;
  /// the page says how. `mine: false` is the same producer's other grain — the
  /// season page and the Compete row are the same fact at two lengths.
  static func myStake(_ m: Me.Membership) -> String? {
    guard m.stakeCents > 0, m.phase != "setup", let b = m.buy_in, b.paid == false else { return nil }
    return m.isPro ? "your own \(PotMath.money(m.stakeCents)) isn't marked in"
                   : "you owe \(PotMath.money(m.stakeCents))"
  }

  public static func seasonLine(_ m: Me.Membership, week: Bool = true, rank: Bool = true,
                                mine: Bool = false,
                                today: String = CSDate.today(), calendar: Calendar = .current) -> String {
    switch SeasonPhase.of(m, today: today) {
    case .season(let w, let n):
      var s = week ? "Week \(w) of \(n)" : ""
      if let st = m.standing {
        if rank { s += (s.isEmpty ? "" : " · ") + "\(CSCopy.ordinal(st.rank)) of \(st.of)" }
        if let race = race(st) { s += (s.isEmpty ? "" : (rank ? ", " : " · ")) + race }
      }
      if let money = SeasonFacts.footMoney(m) { s += (s.isEmpty ? "" : " · ") + money }
      // D318 · and the viewer's own, last, because it is the one clause that
      // is about THEM rather than about the league.
      if mine, let owed = SeasonFacts.myStake(m) { s += (s.isEmpty ? "" : " · ") + owed }
      // A season with no standing and no money has nothing left to say once
      // the week is taken out — the stage word is the honest sentence, not an
      // empty one (L-32).
      return s.isEmpty ? "Standings start at the first posted round." : s
    case .preseason:
      var s = "First tee \(m.season.map { LeagueDates.dowMonDay($0.starts_on, calendar: calendar) } ?? "—")"
      // "on the roster" — the row's own noun for a headcount (D207's phone
      // note); "N in" is the calendar's word for RSVPs and the pot's retired
      // word for buy-ins. The number is the ROOM's: `membership.members` is
      // every league_members row, suspended and tombstoned included — what
      // the room's "N players", the Members sheet and the Pot pane print,
      // and this row is a Home lens whose hero opens that room (D218). The
      // D207 count behind `headcount` drops both and can read one lower; it
      // is what a rule gates on, and only the fallback here (v1, or the
      // server could not count).
      if let n = m.members, n > 0 { s += " · \(n) on the roster" }
      else if let n = m.headcount { s += " · \(n) on the roster" }
      return s
    case .cupFinal(let left):
      return "\(LeagueCopy.Stage.final.label) · \(SeasonFacts.finalClock(left))"
    case .wrapped:
      return LeagueCopy.seasonNote(.complete, firstTee: nil, short: true)
    case .forming:
      return (m.phase == "draft" ? LeagueCopy.Stage.drawing : LeagueCopy.Stage.forming).label
    }
  }

  /// "22 clear of Jade" / "12 back of Galen" / "level with Galen"; the pre-v2
  /// sentences when the names have not arrived; nil with nothing to say.
  public static func race(_ st: Me.Standing) -> String? {
    if st.rank == 1 {
      let gap = st.gap_to_next ?? ((st.points != nil && st.runner_up_points != nil) ? (st.points! - st.runner_up_points!) : nil)
      guard let other = SeasonFacts.clean(st.runner_up_name) else {
        // A v1 payload never carries the top row's margin — claim none, not a tie.
        if let g = gap, g > 0 { return "\(CSCopy.points(g)) clear" }
        return nil
      }
      guard let g = gap else { return nil }
      return g > 0 ? "\(CSCopy.points(g)) clear of \(other)" : "level with \(other)"
    }
    guard let g = st.gap_to_leader else { return nil }
    guard let leader = SeasonFacts.clean(st.leader_name) else {
      return g > 0 ? "\(CSCopy.points(g)) back of the lead" : "level with the lead"
    }
    return g > 0 ? "\(CSCopy.points(g)) back of \(leader)" : "level with \(leader)"
  }
}
