// Cup Season — the lead card (D176). One slot above the hero that changes with
// what is actually true today, chosen by a FIXED ladder.
//
// The whole design rests on two rules, and both exist to keep a screen that
// changes from becoming a screen you cannot learn:
//
//   1. ONE card at a time, never a stack.
//   2. The ladder is fixed and documented, so the same state always produces
//      the same card. Nothing here is random and nothing rotates.
//
// The resting state is NO card — Home's hero is already a good one. A lead card
// appears only when there is something true and time-bound to say.
//
// Nothing here is computed authoritatively: the clash rung comes from the
// `home_clash` RPC (the same expression `settle_week_clash` uses, so the card
// and the result can never disagree), and every other rung reads figures the
// session already carries.

import Foundation

// MARK: - the clash rung's payload

/// `home_clash(p_league)` — null unless you are IN this week's open clash.
/// A clash you are not in belongs on the board, not on your Home (D176).
public struct HomeClash: Sendable, Equatable {
  public struct Side: Sendable, Equatable {
    public let roundId: UUID?
    public let playedOn: String?
    public let points: Double?
    public let pvi: Double?
    public let gross: Int?
    public init(roundId: UUID? = nil, playedOn: String? = nil, points: Double? = nil,
                pvi: Double? = nil, gross: Int? = nil) {
      self.roundId = roundId; self.playedOn = playedOn; self.points = points
      self.pvi = pvi; self.gross = gross
    }
  }
  public let weekNo: Int
  public let endsOn: String
  public let daysLeft: Int
  public let closesToday: Bool
  public let themName: String
  public let themMarker: String?
  public let mine: Side?
  public let theirs: Side?
  public let rivalry: String?
  /// The RPC returns only open clashes today (`settled_at is null`); a settled
  /// one, should a future payload carry it, is a result and never yields.
  public let settled: Bool
  /// The league's headcount, from the membership in hand
  /// (`Membership.headcount` — the server's D207 count on a v2 payload) —
  /// the clash payload does not carry it. nil on a payload that cannot say.
  public let roster: Int?

  public init(weekNo: Int, endsOn: String, daysLeft: Int, closesToday: Bool, themName: String,
              themMarker: String? = nil, mine: Side? = nil, theirs: Side? = nil, rivalry: String? = nil,
              settled: Bool = false, roster: Int? = nil) {
    self.weekNo = weekNo; self.endsOn = endsOn; self.daysLeft = daysLeft
    self.closesToday = closesToday; self.themName = themName; self.themMarker = themMarker
    self.mine = mine; self.theirs = theirs; self.rivalry = rivalry; self.settled = settled
    self.roster = roster
  }

  /// D207 · "It's the two of you" is the TWO-person league's sentence — the
  /// server writes it only `when v_wk = 1 and v_roster = 2`
  /// (`20260902170000:195`); in a bigger league the pairing rotates (D52) and
  /// week 1 is a week like any other. A payload that cannot say is not two.
  public var isTwo: Bool { roster == 2 }

  /// D216 · a clash with nothing posted on either side and more than a day
  /// still to run has nothing to say yet — "You v Marcus. Nothing posted"
  /// three mornings running is the noise the hard-look logged. The rung
  /// re-enters the moment either side posts, on the last-call day (one day or
  /// less left), or once settled.
  public var yields: Bool {
    guard !settled, mine == nil, theirs == nil else { return false }
    // The first week of a two-person season shows once even at 0–0 — that
    // card carries D207's own sentence ("It's the two of you — every week is
    // the clash.").
    guard !(weekNo <= 1 && isTwo) else { return false }
    return daysLeft > 1 && !closesToday
  }

  /// D207 · the first week of a two-person season, nothing posted yet.
  public var isFirstWeekIdle: Bool { weekNo == 1 && isTwo && mine == nil && theirs == nil && !settled }

  /// Hand-decoded from the RPC's jsonb. `try?`-free on purpose: a missing key
  /// returns nil rather than throwing, so deploy skew renders no card instead
  /// of breaking Home.
  public static func decode(_ v: JSONValue?, roster: Int? = nil) -> HomeClash? {
    guard let v, !v.isNull,
          let week = v["week_no"]?.int,
          let ends = v["ends_on"]?.string,
          let them = v["them_name"]?.string else { return nil }
    func side(_ k: String) -> Side? {
      guard let s = v[k], !s.isNull else { return nil }
      return Side(roundId: s["round_id"]?.string.flatMap(UUID.init(uuidString:)),
                  playedOn: s["played_on"]?.string,
                  points: s["points"]?.double,
                  pvi: s["pvi"]?.double,
                  gross: s["gross"]?.int)
    }
    return HomeClash(weekNo: week,
                     endsOn: ends,
                     daysLeft: v["days_left"]?.int ?? 0,
                     closesToday: v["closes_today"]?.bool ?? false,
                     themName: them,
                     themMarker: v["them_marker"]?.string,
                     mine: side("mine"),
                     theirs: side("theirs"),
                     rivalry: v["rivalry"]?.string,
                     settled: v["settled"]?.bool ?? (v["settled_at"].map { !$0.isNull } ?? false),
                     roster: roster)
  }

  /// Who is ahead right now, by the settle's own rule — POINTS, which is the
  /// band. nil means level, or nobody has posted.
  public enum Edge: Sendable, Equatable { case me, them, level }
  public var edge: Edge {
    let m = mine?.points, t = theirs?.points
    if m == nil && t == nil { return .level }
    if t == nil { return .me }
    if m == nil { return .them }
    if (m ?? 0) > (t ?? 0) { return .me }
    if (t ?? 0) > (m ?? 0) { return .them }
    return .level
  }
}

// MARK: - the ladder

public enum HomeLead: Sendable, Equatable {
  /// You are in this week's clash and it has not settled.
  case clash(HomeClash)
  /// The month closes soon and your floor is short.
  case floor(days: Int, credits: Double, floor: Int)
  /// Your rank moved since the last week snapshot.
  case move(rank: Int, of: Int, from: Int, gapToLead: Double?)
  /// A buddy did something worth a look today.
  case milestone(who: String, line: String, roundId: UUID?, marker: String?)

  /// THE LADDER. Fixed order, first match wins, one card.
  ///
  /// - clash first because it is the only rung with a hard deadline attached to
  ///   a named opponent — the most time-bound thing on the screen.
  /// - floor second: also a deadline, but it is arithmetic, not a duel.
  /// - move third: it happened, it is worth telling, nothing is owed.
  /// - milestone last: someone else's news, and the feed carries it anyway —
  ///   this only lifts it when nothing of yours is pressing.
  ///
  /// Three guards (the Home hard-look, 2026-09-02):
  /// - D216 · a 0–0 clash mid-week YIELDS to the rungs below (`HomeClash.yields`).
  /// - D140 · a solo league has no squads, so no floor can ever fire — the
  ///   pulse still carries `participation_floor`, and the rung must not read
  ///   it. `solo` is the league's `structure == "solo"`.
  /// - The move rung reads `prev_rank`, a week-snapshot figure the server keeps
  ///   carrying after the season ends and before it starts; it fires only when
  ///   `phase` is `.season`. Pass nil (the default) and it never fires.
  public static func choose(clash: HomeClash?,
                            pulse: Me.Pulse?,
                            monthDaysLeft: Int?,
                            standing: Me.Standing?,
                            milestone: (who: String, line: String, roundId: UUID?, marker: String?)?,
                            phase: SeasonPhase? = nil,
                            solo: Bool = false) -> HomeLead? {
    if let clash, !clash.yields { return .clash(clash) }

    // The floor rung. `partial == true` means an edge month with floors waived
    // (§14.0's blanket rule) — telling someone to hit a floor that is waived is
    // the exact contradiction the audit logged elsewhere, so it is excluded.
    // A solo league is excluded outright (D140).
    if !solo, let p = pulse, p.partial != true, let floor = p.floor, floor > 0,
       let days = monthDaysLeft, days <= 3 {
      let credits = p.credits ?? 0
      if credits < Double(floor) { return .floor(days: days, credits: credits, floor: floor) }
    }

    if case .season = phase, let st = standing, let prev = st.prev_rank, prev != st.rank {
      return .move(rank: st.rank, of: st.of, from: prev, gapToLead: st.gap_to_leader)
    }

    if let m = milestone { return .milestone(who: m.who, line: m.line, roundId: m.roundId, marker: m.marker) }
    return nil
  }
}

// MARK: - the words

public enum HomeLeadCopy {
  /// "The clash · closes today" / "The clash · 4 days left".
  ///
  /// "today", never "tonight": the window closes at the end of the calendar day
  /// and hardly anyone plays golf in the dark (owner ruling, D176). The server
  /// says the same thing in `clash_last_call`.
  public static func clashEyebrow(_ c: HomeClash) -> String {
    let name = (c.rivalry?.trimmingCharacters(in: .whitespaces)).flatMap { $0.isEmpty ? nil : $0 } ?? "The clash"
    if c.closesToday { return "\(name) · closes today" }
    if c.daysLeft == 1 { return "\(name) · one day left" }
    return "\(name) · \(c.daysLeft) days left"
  }

  /// The sentence under it. Sets the scene, then the stakes. The first week
  /// of a season at 0–0 says what the board says (D207).
  public static func clashLine(_ c: HomeClash) -> String {
    if c.isFirstWeekIdle { return "It's the two of you — every week is the clash." }
    return "You v \(CSBands.fn1(c.themName)). Best round of the week takes it."
  }

  /// What a side has, in the app's own language — never raw differential.
  public static func sideLine(_ s: HomeClash.Side?) -> String {
    guard let s else { return "Nothing posted" }
    var bits: [String] = []
    if let g = s.gross { bits.append(String(g)) }
    if let p = s.pvi { bits.append(CSBands.vsShort(p)) }
    if let d = s.playedOn { bits.append(ClashMath.dowShort(d).uppercased()) }
    return bits.isEmpty ? "Posted" : bits.joined(separator: " · ")
  }

  /// The one action. Which one depends on who is where.
  public static func clashAction(_ c: HomeClash) -> String {
    if c.mine == nil { return "Post a round" }
    switch c.edge {
    case .me:    return "See the receipt"
    case .them:  return "Post a better one"
    case .level: return "Post a better one"
    }
  }

  public static func floorEyebrow(days: Int) -> String {
    days == 0 ? "The month closes today" : days == 1 ? "The month closes tomorrow" : "The month closes in \(days) days"
  }
  public static func floorLine(credits: Double, floor: Int) -> String {
    let short = Double(floor) - credits
    return "You're \(CSCopy.points(short)) short of the floor. One round covers it."
  }

  public static func moveEyebrow(rank: Int, from: Int) -> String {
    rank < from ? "Up \(from - rank)" : "Down \(rank - from)"
  }
  public static func moveLine(rank: Int, of: Int, from: Int, gapToLead: Double?) -> String {
    let where_ = "\(CSCopy.ordinal(rank)) of \(of)"
    if rank == 1 { return "\(where_). A new leader." }
    if let g = gapToLead, g > 0 { return "\(where_), \(CSCopy.points(g)) back." }
    return where_ + "."
  }
}
