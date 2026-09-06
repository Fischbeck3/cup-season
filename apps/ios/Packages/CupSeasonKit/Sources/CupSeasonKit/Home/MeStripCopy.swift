// Cup Season — the ME strip's producer (D236, IOS-029a).
//
// Four facts that belong to me and to nothing else on the screen: my number,
// my last round, my next round, my money — plus one season context row. It is
// simultaneously the L-34 enforcement (the same fact rendered three times on
// one screen was the audit's finding) and the home for D129's owe line, which
// is relocated here and NOT demoted: it fires from state, on every open, on an
// always-present surface, in `neg`, never gold, never with a countdown, and it
// is absent entirely at $0 (D70, L-10).
//
// Two laws are load-bearing in every branch below.
//
//   L-44 · a fact with no read renders NOTHING. Not a dash, not a zero, not a
//   guess. `native_home` v2 does not carry `profile.last_round_on`, so against
//   a payload that predates the migration the LAST slot simply is not there —
//   the strip renders three facts and stays honest. The owner deploys the
//   database and the clients separately and either order has to be truthful.
//
//   A-5 · a gap is always attached to a name. v2 named the leader and rank 2
//   only, so a golfer at rank ≥ 3 was told "4 back" with nobody on the end of
//   it. Without `next_up`/`next_down` the gap clause does not render.
//
// The strip publishes `suppress` — the facts it has spent — and whatever
// renders below it drops anything in that set. That is what stops a golfer's
// next round being offered twice on one screen (HM-35) and the owe line being
// said in two places at once.

import Foundation

public enum MeStripCopy {

  // MARK: - The facts

  /// The four facts the strip OWNS. Nothing below it may say one of these
  /// again (L-34) — the set is handed down as `Strip.suppress`.
  public enum Fact: String, Sendable, Hashable, CaseIterable {
    case myNumber = "my_number"
    case myLastRound = "my_last_round"
    case myNextRound = "my_next_round"
    case myMoney = "my_money"
  }

  /// Where a slot's tap lands. Every figure taps to its receipt (L-01) — a
  /// slot with no door is a number a golfer cannot check.
  public enum Door: Sendable, Equatable {
    /// You → your card, where the number's work is shown.
    case yourCard
    /// The composer, score focused — the door under an empty LAST.
    case composer
    case receipt(UUID)
    /// The declare sheet — the door under an empty NEXT.
    case declare
    case plan(UUID)
    /// The season's pot, where the Pro's payment terms live.
    case pot(UUID)
  }

  public struct Slot: Sendable, Equatable, Identifiable {
    public let fact: Fact
    /// The mono label under the value. One word for one thing (TERMINOLOGY).
    public let label: String
    public let value: String
    public let door: Door
    /// "your number, 12.4" — each pair is ONE VoiceOver element (AX3).
    public let voiceOver: String
    public var id: String { fact.rawValue }
  }

  /// The one context row under the four facts: the season with the nearest
  /// deadline, its rank, both gaps WITH NAMES, and the endgame clause.
  public struct SeasonRow: Sendable, Equatable {
    public let leagueId: UUID
    /// The row as it renders: `FELLAS · 2ND OF 8 · 4 BACK OF GALEN · 2 CLEAR
    /// OF JADE · TOP 2 INTO THE FINAL, OPENS OCT 6`.
    public let text: String
    /// The pieces, so a test can argue with one clause rather than a string.
    public let parts: [String]
  }

  public struct Strip: Sendable, Equatable {
    public let slots: [Slot]
    public let seasonRow: SeasonRow?
    /// L-34 as a producer rule, not a per-screen judgement.
    public var suppress: Set<Fact> { Set(slots.map(\.fact)) }
    public var isEmpty: Bool { slots.isEmpty && seasonRow == nil }
  }

  // MARK: - The producer

  /// The whole strip, from the payload the app already has.
  ///
  /// `upcoming` defaults to the payload's own tee sheet
  /// (`native_home.upcoming_rounds`), so the NEXT slot costs no second read.
  /// Passing `nil` means "the plan is not known" and the slot does not render
  /// — which is different from an empty sheet, which means "no plan" and
  /// renders `PLAN ONE`.
  /// `starter` is D247's band, held on the DEVICE and nowhere else. It is
  /// spent the moment the engine has a number (`StarterIndex.current` returns
  /// nil once `index_current` exists), so the strip never shows two numbers.
  public static func make(_ me: Me?, upcoming: [ScheduledRound]?, today: String = CSDate.today(),
                          calendar: Calendar = .current, starter: Double? = nil) -> Strip {
    guard let me else { return Strip(slots: [], seasonRow: nil) }
    // The order is the reading order and it never changes: my number, my last
    // round, my next round, my money.
    let slots = [numberSlot(me.profile, starter: starter),
                 lastSlot(me.profile, today: today, calendar: calendar),
                 nextSlot(upcoming, today: today, calendar: calendar),
                 moneySlot(me.memberships)].compactMap { $0 }
    return Strip(slots: slots, seasonRow: seasonRow(me.memberships, today: today, calendar: calendar))
  }

  /// The same, reading the payload's own tee sheet.
  public static func make(_ me: Me?, today: String = CSDate.today(), calendar: Calendar = .current,
                          starter: Double? = nil) -> Strip {
    make(me, upcoming: me?.upcoming, today: today, calendar: calendar, starter: starter)
  }

  // MARK: 1 · YOUR NUMBER

  /// `12.4` · `YOUR NUMBER`, or `STARTER 13` while the onboarding band stands,
  /// or `— · BUILDING` at zero rounds and `1 OF 3 · BUILDING` under three.
  ///
  /// The `STARTER` label IS ISSUED NOW (D247, wave 8), and it is issued from
  /// TWO places for one reason. The server-side `index_source = 'starter'` is
  /// still not written — D124 is an owner ruling and it declined seeding the
  /// engine — so the band a golfer picks at onboarding lives on the DEVICE and
  /// is passed in here. The label is the same either way, because to a golfer
  /// reading their card the distinction is invisible and the honesty rule is
  /// the same: a starter is never dressed as an established index (L-14).
  static func numberSlot(_ p: Me.Profile?, starter: Double? = nil) -> Slot? {
    guard let p else { return nil }
    if let ix = p.index_current, ix.isFinite {
      let isStarter = p.index_source == "starter"
      let value = CSCopy.index(ix)
      return Slot(fact: .myNumber, label: isStarter ? "STARTER" : "YOUR NUMBER", value: value, door: .yourCard,
                  voiceOver: isStarter ? "starter number, \(value)" : "your number, \(value)")
    }
    // D247's declined form: no engine number, but this golfer answered "what do
    // you usually shoot?" and the band's figure is on this device. It renders
    // as STARTER and never as YOUR NUMBER, and it never reached `profiles`.
    if let s = starter, s.isFinite {
      // `StarterIndex.text`, not `CSCopy.index`: a band is the middle of a
      // range and `13.0` would dress it in the engine's own precision (L-14).
      let value = StarterIndex.text(s)
      return Slot(fact: .myNumber, label: "STARTER", value: value, door: .yourCard,
                  voiceOver: "starter number, \(value)")
    }
    // No index yet. `rounds_count` is what says whether the number is BUILDING
    // or simply unread — and an unread count renders nothing.
    guard let n = p.rounds_count else { return nil }
    let value = n <= 0 ? "—" : "\(min(n, 3)) OF 3"
    return Slot(fact: .myNumber, label: "BUILDING", value: value, door: .yourCard,
                voiceOver: n <= 0 ? "your number, building, no rounds yet"
                                  : "your number, building, \(min(n, 3)) of 3 rounds posted")
  }

  // MARK: 2 · LAST

  /// `78 SAT` — the gross and the day. An older round says its date instead:
  /// `88 AUG 21`. `days_since_round` is never rendered (L-22).
  static func lastSlot(_ p: Me.Profile?, today: String, calendar: Calendar) -> Slot? {
    guard let p else { return nil }
    if let on = p.last_round_on, let g = p.last_gross {
      let when = dayToken(on, today: today, calendar: calendar)
      let value = "\(g) \(when)"
      let door: Door = p.last_round_id.map(Door.receipt) ?? .composer
      return Slot(fact: .myLastRound, label: "LAST", value: value, door: door,
                  voiceOver: "last round, \(g) on \(when.lowercased())")
    }
    // No last round in the payload. Only a KNOWN zero is "no rounds yet";
    // a v2 payload knows nothing about my last round and says nothing (L-44).
    if p.rounds_count == 0 {
      return Slot(fact: .myLastRound, label: "LAST", value: "NO ROUNDS YET", door: .composer,
                  voiceOver: "last round, none yet")
    }
    return nil
  }

  // MARK: 3 · NEXT

  /// `SAT 7:10` — the day and the tee. With no tee time the plan names its
  /// course instead (`MON · GOLD CANYON`, SA-4): `scheduled_rounds.tee_time`
  /// is nullable and real plans in prod have none, and a guessed tee time is
  /// the one thing this slot may never print. The host is named in the tap
  /// target, not in the slot.
  static func nextSlot(_ upcoming: [ScheduledRound]?, today: String, calendar: Calendar) -> Slot? {
    guard let upcoming else { return nil }
    guard let up = mine(upcoming, today: today).first, let on = up.play_on else {
      return Slot(fact: .myNextRound, label: "NEXT", value: "PLAN ONE", door: .declare,
                  voiceOver: "next round, none booked")
    }
    let day = dayToken(on, today: today, calendar: calendar)
    let tee = up.tee_time.flatMap(teeText)
    // DEF-1 · the SHORT name. The full label is the plan card's fact.
    let course = shortCourse(up.course_label)?.uppercased()
    let value = tee.map { "\(day) \($0)" } ?? course.map { "\(day) · \($0)" } ?? day
    return Slot(fact: .myNextRound, label: "NEXT", value: value,
                door: up.id.map(Door.plan) ?? .declare,
                voiceOver: "next round, \(value.lowercased())")
  }

  /// The plans that are MINE — mine, or booked with me — and that I have not
  /// said I am out of. `ScheduleModels`' own predicate, so the strip and the
  /// chips can never disagree about whose round it is.
  static func mine(_ rows: [ScheduledRound], today: String) -> [ScheduledRound] {
    rows.filter { ($0.mine != false || $0.tagged_me == true) && $0.my_rsvp != "out"
                  && $0.play_on != nil && ($0.play_on ?? "") >= today }
      .sorted { ($0.play_on ?? "", $0.tee_time ?? "") < ($1.play_on ?? "", $1.tee_time ?? "") }
  }

  // MARK: 4 · STILL OWE

  /// `$50 YOU` — D129's line, relocated. **Self-only** (D23): it is derived
  /// from `buy_in.paid`, which is the CALLER's own row and nobody else's; the
  /// strip never prints how many others owe. Absent entirely at $0 (D70,
  /// L-10), absent when everything is paid, and absent in `setup`, where the
  /// books are not open yet (D112) and nothing is owed.
  ///
  /// With more than one season it is the SUM across memberships, and the tap
  /// lands on the season with the nearest due date. There is no tap-cycle —
  /// that is the switcher, reintroduced in the tightest row on the screen.
  static func moneySlot(_ memberships: [Me.Membership]) -> Slot? {
    let owed = memberships.filter { $0.stakeCents > 0 && $0.phase != "setup" && $0.buy_in?.paid == false }
    guard !owed.isEmpty else { return nil }
    let cents = owed.reduce(0) { $0 + $1.stakeCents }
    // The nearest due date first; a season with no due date sorts last.
    let nearest = owed.min { a, b in
      (a.buy_in?.due_on ?? "9999-12-31") < (b.buy_in?.due_on ?? "9999-12-31")
    } ?? owed[0]
    // F-17 · the strip's grammar is DATUM over NOUN — "10.6" over "YOUR
    // NUMBER". This slot put a word in the value ("$75 YOU" over "STILL OWE")
    // so the pair read as a split sentence while its three neighbours read as
    // figures. The word belongs in the label.
    let value = CSCopy.dollars(cents: cents)
    return Slot(fact: .myMoney, label: "YOU STILL OWE", value: value, door: .pot(nearest.league_id),
                voiceOver: "you still owe \(CSCopy.dollars(cents: cents))")
  }

  // MARK: - The season context row

  /// `FELLAS · 2ND OF 8 · 4 BACK OF GALEN · 2 CLEAR OF JADE · TOP 2 INTO THE
  /// FINAL, OPENS OCT 6`, for the season with the nearest deadline.
  ///
  /// **At rank 3 or worse the leader is named** — otherwise the man actually
  /// winning is named nowhere on Home: `DESERT DOGS · 3RD OF 8 · TOMMY LEADS
  /// BY 12 · 4 BACK OF DRE`. The endgame clause is dropped at that length
  /// rather than wrapping to a fourth line.
  ///
  /// With no season the row is absent — **not a row of zeroes** (L-44).
  static func seasonRow(_ memberships: [Me.Membership], today: String, calendar: Calendar) -> SeasonRow? {
    guard let m = nearest(memberships, today: today), let st = m.standing else { return nil }
    var parts: [String] = [m.name.uppercased()]
    // Squads read the squad first, then me. `standing` is the SQUAD's row in a
    // squads league, so the squad's name goes on the rank, and "you Nth of N"
    // is a fact this payload does not have and does not invent.
    let rank = "\(CSCopy.ordinal(st.rank).uppercased()) OF \(st.of)"
    parts.append(m.isSolo ? rank : [m.squad?.name.uppercased(), rank].compactMap { $0 }.joined(separator: " "))

    // At rank ≥ 3 the leader is named before the gap; at 1 or 2 `next_up` IS
    // the leader and the clause would say the same name twice.
    if st.rank >= 3, let leader = st.leader_name, let gap = st.gap_to_leader, gap > 0 {
      parts.append("\(leader.uppercased()) LEADS BY \(CSCopy.points(gap))")
    }
    // A-5 · a gap is always attached to a name.
    if let up = st.next_up, let name = up.name, let gap = gapUp(st, up), gap >= 0 {
      parts.append("\(CSCopy.points(gap)) BACK OF \(name.uppercased())")
    }
    if let down = st.next_down, let name = down.name, let gap = gapDown(st, down), gap >= 0 {
      parts.append("\(CSCopy.points(gap)) CLEAR OF \(name.uppercased())")
    }
    // The short half of D126(2)'s always-visible endgame. Dropped at rank ≥ 3,
    // where the leader's clause has taken its room.
    if st.rank < 3, let clause = endgameClause(m, calendar: calendar) { parts.append(clause) }
    return SeasonRow(leagueId: m.league_id, text: parts.joined(separator: " · "), parts: parts)
  }

  /// The season with the nearest deadline — the week's close where the server
  /// gave one, the season's end otherwise. Wrapped seasons never win it.
  static func nearest(_ memberships: [Me.Membership], today: String) -> Me.Membership? {
    let live = memberships.filter { m in
      switch SeasonPhase.of(m, today: today) {
      case .season, .cupFinal: m.standing != nil
      default: false
      }
    }
    return live.min { a, b in deadline(a, today: today) < deadline(b, today: today) }
  }

  private static func deadline(_ m: Me.Membership, today: String) -> String {
    LeagueDates.weekEnds(m.season, today: today) ?? m.season?.ends_on ?? "9999-12-31"
  }

  /// The gap to the row above me: their points minus mine, from `next_up`'s
  /// own figures where they are there (L-01 — the clause shows its work), and
  /// from the server's `gap_to_next`, which is the same subtraction, otherwise.
  static func gapUp(_ st: Me.Standing, _ up: Me.Standing.Neighbour) -> Double? {
    if let theirs = up.points, let mine = st.points { return theirs - mine }
    return st.gap_to_next
  }

  static func gapDown(_ st: Me.Standing, _ down: Me.Standing.Neighbour) -> Double? {
    guard let theirs = down.points, let mine = st.points else { return nil }
    return mine - theirs
  }

  /// **The endgame, short.** D235 splits D126(2) in two: this clause, present
  /// on every Home open in every state with a season, and the full sentence
  /// permanently under the season page's table. It is produced from
  /// `LeagueCopy.endgame`'s own inputs — the same finish, the same structure,
  /// the same dates — so the two grains can never say different things.
  ///
  /// **At a field of two it never says "the top two seed"** (SA-3): at n = 2
  /// that is a tautology, and the shipped long string prints it.
  public static func endgameClause(_ m: Me.Membership, calendar: Calendar = .current) -> String? {
    guard let s = m.season else { return nil }
    let finish = (m.settings?.finish?.isEmpty == false) ? m.settings!.finish! : "cup_final"
    if finish == "points_table" {
      guard CSDate.local(s.ends_on, calendar: calendar) != nil else { return nil }
      return "POINTS TABLE CROWNS IT \(LeagueDates.monDay(s.ends_on, calendar: calendar).uppercased())"
    }
    guard let opens = LeagueDates.finalOpens(s, finish: finish, calendar: calendar),
          CSDate.local(opens, calendar: calendar) != nil else { return nil }
    let when = LeagueDates.monDay(opens, calendar: calendar).uppercased()
    if m.isSolo, m.standing?.of == 2 { return "A FINAL BETWEEN THE TWO OF YOU, OPENS \(when)" }
    return "TOP 2 INTO THE FINAL, OPENS \(when)"
  }

  // MARK: - Tokens

  /// `TODAY` · `SAT` · `AUG 21`. Inside a week either way the weekday is the
  /// thing a golfer recognises; past that it is the date.
  static func dayToken(_ iso: String, today: String, calendar: Calendar = .current) -> String {
    guard let days = CSDate.days(from: today, to: iso) else { return iso.uppercased() }
    if days == 0 { return "TODAY" }
    if abs(days) <= 6, let d = CSDate.local(iso, calendar: calendar) {
      let wd = calendar.component(.weekday, from: d)
      return LeagueDates.dow[max(0, min(6, wd - 1))].uppercased()
    }
    return LeagueDates.monDay(iso, calendar: calendar).uppercased()
  }

  /// THE SHORT NAME OF A COURSE (BUILD_PLAN §2.z, DEF-1). A slot sized for a
  /// short string that interpolates a name from the database looks correct in
  /// a test and wrong on a phone: prod's longest label today is
  /// `Gold Canyon — Dinosaur Mountain · Black/Blue`, and in the strip's NEXT
  /// slot it wrapped to three lines, pushed its own label out of the row and
  /// still ended in an ellipsis — at the DEFAULT type size, on the widest
  /// phone, against AX3's "nothing truncates".
  ///
  /// The rule the strip follows is the one the rest of the app already
  /// follows for a glance: the club, never the layout and never the tee
  /// variant. Both are facts the PLAN CARD carries, and one fact has one
  /// place (L-34).
  static func shortCourse(_ raw: String?) -> String? {
    guard let raw, !raw.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
    // the API's own separators: an em-dash for the layout, a middot for the tee
    let club = raw.components(separatedBy: " — ").first ?? raw
    let out = (club.components(separatedBy: " · ").first ?? club).trimmingCharacters(in: .whitespaces)
    return out.isEmpty ? nil : out
  }

  /// The day as a WORD, for a sentence rather than a slot: `today`,
  /// `tomorrow`, or the weekday (`Monday`). `dayToken` is the mono form the
  /// strip and the eyebrows wear; this is the one a headline can end on.
  static func dayWord(_ iso: String, today: String, calendar: Calendar = .current) -> String {
    guard let days = CSDate.days(from: today, to: iso) else { return "a round" }
    if days == 0 { return "today" }
    if days == 1 { return "tomorrow" }
    if days > 1, days <= 6, let d = CSDate.local(iso, calendar: calendar) {
      let wd = calendar.component(.weekday, from: d)
      let short = LeagueDates.dow[max(0, min(6, wd - 1))]
      let full = ["Sun": "Sunday", "Mon": "Monday", "Tue": "Tuesday", "Wed": "Wednesday",
                  "Thu": "Thursday", "Fri": "Friday", "Sat": "Saturday"]
      return full[short] ?? short
    }
    return LeagueDates.monDay(iso, calendar: calendar)
  }

  /// `"07:10:00"` → `"7:10"`. A tee time is printed exactly as the plan holds
  /// it; nothing is rounded and nothing is invented.
  static func teeText(_ raw: String) -> String? {
    let bits = raw.split(separator: ":")
    guard bits.count >= 2, let h = Int(bits[0]), let mm = Int(bits[1]), (0...23).contains(h), (0...59).contains(mm) else { return nil }
    return String(format: "%d:%02d", h, mm)
  }
}
