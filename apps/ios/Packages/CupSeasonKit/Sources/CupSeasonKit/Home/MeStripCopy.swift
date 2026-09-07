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
    /// **Is this a fact, or the shape where a fact will go?** `— BUILDING`,
    /// `NO ROUNDS YET` and `PLAN ONE` are doors wearing a slot's clothes. Each
    /// is right on its own; all of them at once is a row of absences dressed
    /// as a data row, which is what a brand-new golfer was handed.
    public let isPlaceholder: Bool
    public var id: String { fact.rawValue }

    public init(fact: Fact, label: String, value: String, door: Door, voiceOver: String,
                isPlaceholder: Bool = false) {
      self.fact = fact; self.label = label; self.value = value; self.door = door
      self.voiceOver = voiceOver; self.isPlaceholder = isPlaceholder
    }
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
    /// QB-09 · the month's cap, what I have posted into it, and how much of it
    /// is left. `SeasonFacts.monthRow` — one producer, and it is a FACT that
    /// stands every day, not a deadline item that fires on three of thirty.
    public let monthRow: String?
    /// QB-04 · **HOW TO PAY, UNDER THE FIGURE THAT SAYS YOU OWE.**
    ///
    /// `Me.Membership.BuyIn` carries `note` — commented in the model as "how
    /// to pay, the Pro's words" — and `due_on`. `SeasonFacts.owe` turns them
    /// into *"You still owe $75 · Venmo @casey · by Sat Sep 5"*, or the honest
    /// fallback *"…ask the Pro how to pay — money moves between you"*. A grep
    /// of the whole iOS target found it called from **one unit test and no
    /// view**: the sentence the Pro typed was fetched to the golfer's phone
    /// and printed nowhere, while the strip beside it dunned him in red.
    ///
    /// It renders for the SAME membership the money slot's door points at, so
    /// the figure and the instruction are one fact in one place (L-34).
    public let oweRow: String?
    /// L-34 as a producer rule, not a per-screen judgement.
    public var suppress: Set<Fact> { Set(slots.map(\.fact)) }
    public var isEmpty: Bool { slots.isEmpty && seasonRow == nil && monthRow == nil }

    public init(slots: [Slot], seasonRow: SeasonRow?, monthRow: String? = nil, oweRow: String? = nil) {
      self.slots = slots; self.seasonRow = seasonRow; self.monthRow = monthRow; self.oweRow = oweRow
    }
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
  /// `suppress` is **what the lead and the deck have already said**
  /// (`HomeRank.Ranked.columnFacts`). `HOME_STATE_MATRIX` §3 row 3 puts this
  /// row's never-list first: *"any fact the lead or the deck also renders"*.
  /// The precedence is one-way — lead → deck → strip — so the strip is the
  /// surface that gives way, and on a busy morning it is a shorter line.
  public static func make(_ me: Me?, upcoming: [ScheduledRound]?, today: String = CSDate.today(),
                          calendar: Calendar = .current, starter: Double? = nil,
                          suppress: Set<Fact> = [], standingSaid: Bool = false) -> Strip {
    guard let me else { return Strip(slots: [], seasonRow: nil) }
    // The order is the reading order and it never changes: my number, my last
    // round, my next round, my money.
    let slots = [numberSlot(me.profile, starter: starter),
                 lastSlot(me.profile, today: today, calendar: calendar),
                 nextSlot(upcoming, today: today, calendar: calendar),
                 moneySlot(me.memberships)]
      .compactMap { $0 }
      .filter { !suppress.contains($0.fact) }

    // **The three supporting rows stop being a paragraph.**
    //
    // The strip used to set the owe instruction, the season row and the month
    // row one under the other, unconditionally: three sentences in
    // near-identical grey, five lines of type, two of which repeated something
    // already on the screen — the `$75` directly above the first, and the
    // standing a CHANGED card was making its headline out of. Between the lead
    // card and the deck it read as debris.
    //
    // Each now earns its place instead:
    //
    //   · **the owe instruction** keeps QB-04's whole point — the Pro's terms,
    //     fetched to the phone and printed nowhere — minus the figure, which
    //     is in the slot one row up (`withoutFigure`);
    //   · **the season row** stands down when the column already said where I
    //     stand. It is NOT ranked below the owe line: a buy-in stays unpaid for
    //     weeks, and letting money outrank standing would have hidden the
    //     competition behind a chore for most of a season;
    //   · **the month row** is the weakest of the three and renders only when
    //     neither of the others did — it is a rule, not news.
    let showsMoney = slots.contains { $0.fact == .myMoney }
    let owe = oweRow(me.memberships, today: today, calendar: calendar)
      .map { showsMoney ? withoutFigure($0) : $0 }
    let season = standingSaid ? nil : seasonRow(me.memberships, today: today, calendar: calendar)
    let month = (owe == nil && season == nil)
      ? nearest(me.memberships, today: today)
          .flatMap { SeasonFacts.monthRow($0, today: today, calendar: calendar) }
      : nil
    // **A ROW OF ABSENCES IS NOT AN ANCHOR.** On a brand-new account every
    // slot is a door wearing a slot's clothes — `— BUILDING · NO ROUNDS YET ·
    // PLAN ONE` — set directly under a lead card that has just said "your
    // first round is the only thing missing". The strip's whole job is to be
    // the four facts that are about ME; with nothing yet true it is a form
    // that failed to load, and it says the lead's sentence back in mono.
    //
    // So it stands down entirely, and Home is the lead card and the four
    // doors — which is `HOME_STATE_MATRIX` §4.5's own shape for the first
    // open, *"one true thing is enough"*, applied one row higher than the
    // matrix applied it. Nothing is lost: every placeholder's door is also a
    // foot door, and the foot doors are the floor that never hides (L-32).
    //
    // One real fact is enough to bring it back: `14.2 · 86 WED · PLAN ONE` is
    // a strip with something to say, and `PLAN ONE` inside it is an invitation
    // rather than a fourth way of saying "nothing here yet".
    let allEmpty = !slots.isEmpty && slots.allSatisfy(\.isPlaceholder)
    if allEmpty && owe == nil && season == nil && month == nil {
      return Strip(slots: [], seasonRow: nil)
    }
    return Strip(slots: slots, seasonRow: season, monthRow: month, oweRow: owe)
  }

  /// The same, reading the payload's own tee sheet.
  public static func make(_ me: Me?, today: String = CSDate.today(), calendar: Calendar = .current,
                          starter: Double? = nil, suppress: Set<Fact> = [],
                          standingSaid: Bool = false) -> Strip {
    make(me, upcoming: me?.upcoming, today: today, calendar: calendar, starter: starter,
         suppress: suppress, standingSaid: standingSaid)
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
                                  : "your number, building, \(min(n, 3)) of 3 rounds posted",
                isPlaceholder: true)
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
                  voiceOver: "last round, none yet", isPlaceholder: true)
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
                  voiceOver: "next round, none booked", isPlaceholder: true)
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
    return Slot(fact: .myMoney, // **THE THREE MONEY WORDS ARE NAMED, AND THIS IS NOT ONE OF THEM.**
        // Non-negotiable 8 spells them exactly — `YOU OWE` / `YOU'RE OWED` /
        // `THE POT` — and the artboard prints `YOU OWE`. The rail printed a
        // fourth label, on the one place money appears on the product's front
        // page. The *still* rides the SENTENCE (`SeasonFacts.owe` already
        // opens with it), which is where a nuance belongs.
        label: "YOU OWE", value: value, door: .pot(nearest.league_id),
                voiceOver: "you still owe \(CSCopy.dollars(cents: cents))")
  }

  /// QB-04 · the Pro's payment words, for the season the money slot opens.
  ///
  /// The slot's door is `moneySlot`'s own choice — the season with the nearest
  /// due date — and this reads the same one, so the figure and the sentence
  /// can never describe different seasons. With more than one season owing,
  /// the strip's figure is a SUM and the instruction is the nearest season's;
  /// the sentence names its own amount, so nothing is ambiguous.
  static func oweRow(_ memberships: [Me.Membership], today: String, calendar: Calendar) -> String? {
    let owed = memberships.filter { $0.stakeCents > 0 && $0.phase != "setup" && $0.buy_in?.paid == false }
    guard !owed.isEmpty else { return nil }
    let nearest = owed.min { a, b in
      (a.buy_in?.due_on ?? "9999-12-31") < (b.buy_in?.due_on ?? "9999-12-31")
    } ?? owed[0]
    return SeasonFacts.owe(nearest, today: today, calendar: calendar)
  }

  /// **The figure is directly above this line; it is not said twice.**
  ///
  /// `SeasonFacts.owe` opens with the amount — *"You still owe $75 · ask the
  /// Pro how to pay"* — because on the pot pane it stands alone and has to.
  /// In the strip it sits one row under `$75 · YOU OWE`, so the opening
  /// clause is the same fact restated in the same words a line apart, which is
  /// the L-34 finding the audit filed and then reproduced.
  ///
  /// Only the leading clause goes. Everything the slot cannot say — the Pro's
  /// terms, the due date — is what remains, which was the point of QB-04.
  static func withoutFigure(_ line: String) -> String {
    guard line.hasPrefix("You still owe "), let cut = line.range(of: " \u{00B7} ") else { return line }
    let rest = String(line[cut.upperBound...])
    guard let f = rest.first else { return line }
    return f.uppercased() + rest.dropFirst()
  }

  // MARK: - The season context row

  /// `FELLAS · 2ND OF 8 · 4 BACK OF GALEN · 2 CLEAR OF JADE · TOP 2 INTO THE
  /// FINAL, OPENS OCT 6`, for the season with the nearest deadline.
  ///
  /// **QB-03 · THE ENDGAME CLAUSE IS NEVER DROPPED.** It used to be appended
  /// only `if st.rank < 3`, to make room for the leader's name — so the one
  /// seat that does not already know where it stands, third, was the one seat
  /// guaranteed never to be told. A golfer at 1 or 2 knows they are in; a
  /// golfer at 3 does not know they are out. That broke D126, D235 ("a clause
  /// you always see") and `UX_AUDIT` §8.3's keep list, and a blind walker in
  /// exactly that seat found the sentence three taps deep on a page called The
  /// rules: *"Nothing on Home tells me 3rd is a losing position."*
  ///
  /// So the LEADER'S NAME yields instead, at rank ≥ 3, and the clause stands:
  /// `RED MOUNTAIN · 3RD OF 8 · 4 BACK OF CAL · TOP 2 INTO THE FINAL`. The
  /// leader is twelve points and nineteen weeks away; the golfer one rung up
  /// is catchable this weekend, is named by `next_up`, and the cut line is
  /// what decides whether catching him matters. The trade is the one the
  /// walker asked for in his own words. It also shortens the longest string
  /// this row can produce, which is the AX3 gate (QB-11).
  ///
  /// **QB-05 · A SEASON THAT HAS NOT STARTED IS STILL A SEASON.** The row
  /// required a `standing`, and a preseason member has none — so a golfer who
  /// had just paid $50 to play five named golfers got a Home with no season on
  /// it at all, and a wire that told him to add some buddies. For him the
  /// ROSTER is the content, and `SeasonFacts.seasonLine` already writes the
  /// sentence: `DAWN PATROL · FIRST TEE SAT SEP 5 · 6 ON THE ROSTER`.
  ///
  /// With no season at all the row is absent — **not a row of zeroes** (L-44).
  static func seasonRow(_ memberships: [Me.Membership], today: String, calendar: Calendar) -> SeasonRow? {
    guard let m = nearest(memberships, today: today), let st = m.standing else {
      return preseasonRow(memberships, today: today, calendar: calendar)
    }
    var parts: [String] = [m.name.uppercased()]
    // Squads read the squad first, then me. `standing` is the SQUAD's row in a
    // squads league, so the squad's name goes on the rank, and "you Nth of N"
    // is a fact this payload does not have and does not invent.
    let rank = "\(CSCopy.ordinal(st.rank).uppercased()) OF \(st.of)"
    parts.append(m.isSolo ? rank : [m.squad?.name.uppercased(), rank].compactMap { $0 }.joined(separator: " "))

    // QB-03 · the leader's name is the clause that yields. It only ever
    // rendered at rank ≥ 3, which is precisely the rank at which the endgame
    // clause was being deleted to make room for it — and of the two, the cut
    // line is the one that answers "am I in or out".
    _ = st.leader_name
    // A-5 · a gap is always attached to a name.
    if let up = st.next_up, let name = up.name, let gap = gapUp(st, up), gap >= 0 {
      parts.append("\(CSCopy.points(gap)) BACK OF \(name.uppercased())")
    }
    if let down = st.next_down, let name = down.name, let gap = gapDown(st, down), gap >= 0 {
      parts.append("\(CSCopy.points(gap)) CLEAR OF \(name.uppercased())")
    }
    // The short half of D126(2)'s always-visible endgame. **At every rank.**
    if let clause = endgameClause(m, calendar: calendar) { parts.append(clause) }
    return SeasonRow(leagueId: m.league_id, text: parts.joined(separator: " · "), parts: parts)
  }

  /// QB-05 · the row for a member whose season has not teed off.
  ///
  /// The season with the nearest first tee, named, with its date and its
  /// roster — the two facts that are true about a preseason membership and
  /// interesting to the golfer who just joined it. The sentence is
  /// `SeasonFacts.seasonLine`'s own preseason branch, upper-cased into the
  /// strip's register, so Home and Compete cannot say different things about
  /// the same season. It taps to the season, where the roster is.
  static func preseasonRow(_ memberships: [Me.Membership], today: String, calendar: Calendar) -> SeasonRow? {
    let pre = memberships.filter {
      if case .preseason = SeasonPhase.of($0, today: today) { return true }
      return false
    }
    guard let m = pre.min(by: { ($0.season?.starts_on ?? "9999") < ($1.season?.starts_on ?? "9999") }) else { return nil }
    let line = SeasonFacts.seasonLine(m, today: today, calendar: calendar)
    let parts = [m.name.uppercased()] + line.split(separator: "\u{00B7}").map {
      $0.trimmingCharacters(in: .whitespaces).uppercased()
    }
    return SeasonRow(leagueId: m.league_id, text: parts.joined(separator: " \u{00B7} "), parts: parts)
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
