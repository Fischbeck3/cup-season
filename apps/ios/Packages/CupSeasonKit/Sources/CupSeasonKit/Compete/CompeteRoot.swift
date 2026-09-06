// Cup Season — COMPETE, the peer list (D222 / R-A, R-D; IA §6.1).
//
// Every season and every moment I am in, as PEERS. Not a room I am inside with
// the others hidden behind a swipe — the shape that let `HomeMode.pool` drop a
// wrapped season the moment a live one existed, which is an erasure no entry
// ever authorised.
//
// Three rules the list obeys, and each is a test:
//   1 · NEAREST CLOCK FIRST. A thing with a deadline outranks a thing without
//       one, and the sooner deadline outranks the later. A row with no clock
//       keeps its place at the back in a stable order rather than sorting by
//       name — a list that reorders itself between two loads is a list nobody
//       can point at.
//   2 · FINISHED IS FOLDED, NEVER HIDDEN, and the champion is named where the
//       payload names them.
//   3 · THE EMPTY ROOT ENDS IN A NEXT MOVE (L-32), and a FAILED READ IS NEVER
//       AN EMPTY ONE — "nothing running" over a season you are in is a lie the
//       golfer cannot tell is a lie.
//
// The sentences are not retyped here. `SeasonFacts.seasonLine` is the season
// row's own sub and `LeagueCopy.Stage` is its stage word; this file decides
// ORDER and STATE, which is what a list is for.

import Foundation

public enum CompeteRoot {

  // MARK: - the rows

  public struct Row: Sendable, Equatable, Identifiable {
    public enum Kind: String, Sendable, Equatable { case season, moment, weekend }
    /// Stable across loads: the object's own id, so SwiftUI keeps the row.
    public let id: String
    public let kind: Kind
    /// The mono line above the name — a stage, a week, a date.
    public let eyebrow: String
    public let title: String
    /// The one true sentence under it.
    public let sub: String
    /// Days until this row's next deadline; nil = no clock. Never printed —
    /// it is the sort key (L-22: a countdown nobody asked for is pressure).
    public let clock: Int?
    public let leagueId: UUID?
    public let eventId: UUID?
    public let roundId: UUID?

    public init(id: String, kind: Kind, eyebrow: String, title: String, sub: String, clock: Int?,
                leagueId: UUID? = nil, eventId: UUID? = nil, roundId: UUID? = nil) {
      self.id = id; self.kind = kind; self.eyebrow = eyebrow; self.title = title; self.sub = sub
      self.clock = clock; self.leagueId = leagueId; self.eventId = eventId; self.roundId = roundId
    }
  }

  /// The three heads, verbatim (R-D: the object keeps its name where the
  /// object is, even though the tab does not).
  ///
  /// **F-3 · CONFLICT, and the ruling wins.** `OWNER_RULINGS.md` R-D names
  /// these two heads in terms — *"the section heads still read YOUR SEASONS
  /// and YOUR MOMENTS"*. `TERMINOLOGY.md` A-4 replaced the second with
  /// `MATCHES & WEEKENDS` because `moment` is also `posts.moment`, a schema
  /// word, and preflight check 25 was then written to FAIL THE PUSH on the
  /// owner's own word. A-4's reasoning is sound and its argument is recorded
  /// in the D-entry and in the report as a question for the owner — but an
  /// artifact does not overrule a ruling, and a lint may not enforce the
  /// inversion. The owner's word ships; check 25 now guards the other way.
  public enum Head {
    public static let seasons = "YOUR SEASONS"
    public static let moments = "YOUR MOMENTS"
    public static let finished = "FINISHED"
  }

  public struct List: Sendable, Equatable {
    public let seasons: [Row]
    public let moments: [Row]
    public let finished: [Row]
    public var isEmpty: Bool { seasons.isEmpty && moments.isEmpty && finished.isEmpty }
    /// Nothing LIVE — a shelf of finished seasons is still an empty root's
    /// question ("what are you playing for now?"), so the empty root renders
    /// above them rather than instead of them.
    public var nothingRunning: Bool { seasons.isEmpty && moments.isEmpty }
  }

  /// Build the list from the payload the app already holds. Pure.
  public static func make(_ me: Me?, upcoming: [ScheduledRound] = [], today: String = CSDate.today(),
                          calendar: Calendar = .current) -> List {
    guard let me else { return List(seasons: [], moments: [], finished: []) }
    let myName = me.profile?.display_name
    var live: [Row] = [], done: [Row] = []

    for m in me.memberships {
      let phase = SeasonPhase.of(m, today: today)
      let row = seasonRow(m, phase: phase, today: today, calendar: calendar)
      if case .wrapped = phase { done.append(row) } else { live.append(row) }
    }

    var moments: [Row] = []
    for e in me.events {
      let clock = e.starts_on.flatMap { CSDate.days(from: today, to: $0, calendar: calendar) }
      let row = Row(id: "event:\(e.id.uuidString)", kind: .moment,
                    eyebrow: eventEyebrow(e, calendar: calendar), title: e.name,
                    sub: EventCopy.momentLine(kind: e.kind, status: e.status, mine: e.my_team_slot != nil || e.is_organizer == true),
                    clock: e.status == "complete" ? nil : clock,
                    eventId: e.id)
      if e.status == "complete" { done.append(row) } else { moments.append(row) }
    }

    // A weekend is a moment with a tee time (IA §8.4). Only the ones I am on:
    // `my_schedule` already answers that, and the phone does not re-filter it.
    for r in upcoming {
      // `isMyPlan` is the SINGLE plan predicate on both clients (D219): a
      // round I booked, or one a buddy booked WITH me. Re-filtering here would
      // be the second implementation the two clients drifted on before.
      guard r.isMyPlan, let rid = r.id, let on = r.play_on,
            let days = CSDate.days(from: today, to: on, calendar: calendar), days >= 0 else { continue }
      moments.append(Row(id: "plan:\(rid.uuidString)", kind: .weekend,
                         eyebrow: LeagueDates.dowMonDay(on, calendar: calendar).uppercased(),
                         // DEF-1's lesson: a slot sized for a short name gets the
                         // club, not `Gold Canyon — Dinosaur Mountain · Black/Blue`.
                         title: r.courseShort ?? "A round",
                         sub: planLine(r, myName: myName), clock: days, roundId: rid))
    }

    return List(seasons: sorted(live), moments: sorted(moments), finished: done)
  }

  /// Rule 1 · nearest clock first; a clockless row keeps its arrival order at
  /// the back. `enumerated()` carries that order through the sort, because
  /// Swift's sort is not stable and a list that shuffles itself is unusable.
  static func sorted(_ rows: [Row]) -> [Row] {
    rows.enumerated().sorted { a, b in
      switch (a.element.clock, b.element.clock) {
      case let (x?, y?): return x == y ? a.offset < b.offset : x < y
      case (_?, nil):    return true
      case (nil, _?):    return false
      case (nil, nil):   return a.offset < b.offset
      }
    }.map(\.element)
  }

  private static func seasonRow(_ m: Me.Membership, phase: SeasonPhase, today: String, calendar: Calendar) -> Row {
    let eyebrow: String
    switch phase {
    case .season(let w, let n): eyebrow = "WEEK \(w) OF \(n)"
    case .cupFinal:             eyebrow = LeagueCopy.Stage.final.label.uppercased()
    case .preseason:            eyebrow = LeagueCopy.Stage.preseason.label.uppercased()
    case .wrapped:              eyebrow = m.season?.number.map { "SEASON \($0)" } ?? LeagueCopy.Stage.complete.label.uppercased()
    case .forming:              eyebrow = (m.phase == "draft" ? LeagueCopy.Stage.drawing : LeagueCopy.Stage.forming).label.uppercased()
    }
    // L-34 · the EYEBROW carries the week and the stage, so the sentence under
    // it does not say them again. `week: false` is the same producer's other
    // grain, not a second producer.
    return Row(id: "league:\(m.league_id.uuidString)", kind: .season, eyebrow: eyebrow, title: m.name,
               sub: finishedSub(m, phase: phase) ?? SeasonFacts.seasonLine(m, week: false, today: today, calendar: calendar),
               clock: clock(m, phase: phase, today: today, calendar: calendar),
               leagueId: m.league_id)
  }

  /// "Mike took it" — only when the payload actually names the champion of THIS
  /// season. `season.champion_member_id` is an id, not a name, so the name comes
  /// from `last_season` and only when its number is the one that just finished.
  /// Otherwise the row says the stage word and no more (L-44).
  private static func finishedSub(_ m: Me.Membership, phase: SeasonPhase) -> String? {
    guard case .wrapped = phase else { return nil }
    guard let ls = m.last_season, let champ = ls.champion_name, !champ.isEmpty,
          ls.number != nil, ls.number == m.season?.number else { return nil }
    return "\(champ) took it"
  }

  /// The row's deadline in days: the clash's if one is closing, else the
  /// season's own end, else the first tee. Every one of these is a figure the
  /// payload already carries — nothing is counted here.
  private static func clock(_ m: Me.Membership, phase: SeasonPhase, today: String, calendar: Calendar) -> Int? {
    if case .wrapped = phase { return nil }
    if let d = m.clash?.days_left, d >= 0 { return d }
    if let d = m.season?.days_to_first_tee, d > 0 { return d }
    if let d = m.season?.days_left, d >= 0 { return d }
    if let ends = m.season?.ends_on { return CSDate.days(from: today, to: ends, calendar: calendar) }
    return nil
  }

  private static func eventEyebrow(_ e: Me.Event, calendar: Calendar) -> String {
    if e.status == "complete" { return "FINAL" }
    guard let s = e.starts_on else { return EventCopy.status(e.status).uppercased() }
    return LeagueDates.dowMonDay(s, calendar: calendar).uppercased()
  }

  /// A plan's own sentence: who is on it, or the fact that it is only you yet.
  ///
  /// Two rules, and the first cost a real screenshot to find. **`tagged_names`
  /// includes ME** on a round a buddy booked with me, so the naive sentence
  /// read *"You and Jerecho Fischbeck."* — the viewer, twice. My own name comes
  /// out, and a round I do not own names its HOST, which is the fact that makes
  /// it mine at all. Second: nothing is invented from a count nobody sent
  /// (L-44) and **no seat count is printed** (IA §8.4 rule 1) — `scheduled_rounds`
  /// has no capacity column and a printed one counts nothing.
  static func planLine(_ r: ScheduledRound, myName: String? = nil) -> String {
    var names = (r.tagged_names ?? []).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    if let mine = myName?.trimmingCharacters(in: .whitespaces), !mine.isEmpty {
      names.removeAll { $0.caseInsensitiveCompare(mine) == .orderedSame || $0.caseInsensitiveCompare(CSBands.fn1(mine)) == .orderedSame }
    }
    guard r.isMine else {
      let host = r.hostFirstName
      return names.isEmpty ? "\(host)’s round. You’re on it."
                           : "\(host)’s round. You, " + list(names) + "."
    }
    guard !names.isEmpty else {
      return r.tee_time.flatMap(MeStripCopy.teeText).map { "Your tee time, \($0)." } ?? "Yours, so far."
    }
    return names.count == 1 ? "You and \(names[0])." : "You, " + list(names) + "."
  }

  private static func list(_ names: [String]) -> String {
    guard names.count > 1 else { return names.first ?? "" }
    return names.dropLast().joined(separator: ", ") + " and " + (names.last ?? "")
  }

  // MARK: - the root's state (L-32)

  /// What the tab shows when there is no list. The three are DIFFERENT values
  /// on purpose: a spinner is not an absence and a failed read is not an
  /// absence either.
  public enum State: Sendable, Equatable {
    case list
    case loading
    case failed(EmptyRoot)
    case empty(EmptyRoot)
  }

  /// `readFailed` wins over everything: an error is the one fact the screen
  /// knows for certain, and dressing it as "nothing running" is the failure
  /// L-32 names.
  public static func state(list: List, loaded: Bool, readFailed: Bool, buddies: Int?) -> State {
    if readFailed { return .failed(EmptyRoot.failedRead(retry: "Try again")) }
    if !loaded { return .loading }
    guard list.nothingRunning else { return .list }
    return .empty(empty(buddies: buddies))
  }

  /// IA §6.1's empty root, verbatim, with its one conditional true fact.
  ///
  /// With buddies and nothing running the fact is real and is used; with no
  /// buddies it is OMITTED rather than guessed at, and the second door becomes
  /// Find golfers — because "I have a code" is no use to somebody nobody has
  /// sent one to.
  public static func empty(buddies: Int?) -> EmptyRoot {
    let hasBuddies = (buddies ?? 0) > 0
    let fact: String? = hasBuddies
      ? "\(CSCopy.count(buddies ?? 0, "buddy", plural: "buddies")), and none of you is playing for anything."
      : nil
    return EmptyRoot(
      head: "Nothing running.",
      fact: fact,
      sub: "Your next competition starts here — a season, a weekend, or one guy you want to beat.",
      doors: [.startSomething, hasBuddies ? .joinWithCode : .findGolfers])
  }
}
