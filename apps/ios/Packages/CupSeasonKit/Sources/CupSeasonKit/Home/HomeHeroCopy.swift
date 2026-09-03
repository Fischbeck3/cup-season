// Cup Season — the words on the Home hero (the Home hard-look, 2026-09-02).
//
// Pure functions over (Membership, today). Nothing here reads the clock or the
// network, so a test can pin every sentence; the app's `HomeHero` only lays
// them out. The rules they obey, all rulings:
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
//   D126  the endgame is a sentence you can always see — `LeagueCopy.endgame`
//         says it; §14.3 is the ladder it names ("Months won breaks it.").
//
// Every name arrives from `native_home()` v2 already in the board's own form —
// `firstname(display_name)` for a golfer, `squads.name` for a squad — so the
// hero says "Galen" where the board says "Galen" and never first-names a squad
// called "Sunday Money". A v1 payload (deploy skew) has no names; the copy then
// falls back to the sentences Home spoke before this wave.

import Foundation

public enum HomeHeroCopy {
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
  ///   "Partial month · floors waived" / "Month floor met · 6/4" /
  ///   "Month floor 2/4 · 2 more" — then "Best 4 rounds a month count", else nil.
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
      if p.partial == true { return "Partial month · floors waived" }
      return credits >= Double(floor) ? "Month floor met · \(CSCopy.points(credits))/\(floor)"
                                      : "Month floor \(CSCopy.points(credits))/\(floor) · \(CSCopy.points(Double(floor) - credits)) more"
    }
    return cap
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
}
