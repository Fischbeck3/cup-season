// Cup Season — the week's clash, as the client holds it (D176, D207, D216).
//
// `HomeClash` outlived the five-rung lead ladder it was written for. The
// ladder is gone (D231 — the lead is chosen by a written desk rule on the
// server), but the clash payload is still read on the DECLARED FALLBACK path:
// when `home_dispatch` cannot be reached, `HomeFallbackItems` composes the
// clash item from `native_home.membership.clash` (v3, inlined) or from
// `home_clash(p_league)` on an older payload, and it needs both the shape and
// the sentences. D216's yield lives here, on the payload, so the fallback and
// the server ranker cannot disagree about what an idle clash is.

import Foundation

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

// MARK: - the words, on the fallback path

/// The clash's sentences, carried off the retired `HomeLeadCopy` unchanged.
/// On the served path the server writes these strings; this producer is what
/// the client says when it cannot reach the server, and the two are held to
/// the same rulings by `HomeCopyContractTests`.
public enum HomeClashCopy {
  /// "The clash · closes today" / "The clash · 4 days left".
  ///
  /// "today", never "tonight": the window closes at the end of the calendar
  /// day and hardly anyone plays golf in the dark (owner ruling, D176). The
  /// server says the same thing in `clash_last_call`.
  public static func eyebrow(_ c: HomeClash) -> String {
    let name = (c.rivalry?.trimmingCharacters(in: .whitespaces)).flatMap { $0.isEmpty ? nil : $0 } ?? "The clash"
    if c.closesToday { return "\(name) · closes today" }
    if c.daysLeft == 1 { return "\(name) · one day left" }
    return "\(name) · \(c.daysLeft) days left"
  }

  /// The sentence under it. D207's n = 2 line is kept verbatim: the first week
  /// of a two-person season says what the board says.
  ///
  /// **SA-2 · "I have posted, they have not" is its own sentence.** The
  /// shipped line was symmetric ("You v Galen") and misattributed the
  /// pressure; where one side has posted the subject becomes the OPPONENT,
  /// which is where the clock actually sits.
  public static func line(_ c: HomeClash) -> String {
    if c.isFirstWeekIdle { return "It's the two of you — every week is the clash." }
    let them = CSBands.fn1(c.themName)
    if c.mine != nil && c.theirs == nil {
      let clock = c.closesToday ? "today" : c.daysLeft == 1 ? "one day" : "\(c.daysLeft) days"
      let gross = c.mine?.gross.map(String.init) ?? "round"
      return "\(them) has \(clock) to answer your \(gross)."
    }
    if c.theirs != nil && c.mine == nil {
      let gross = c.theirs?.gross.map(String.init) ?? "a round"
      return "\(them) posted \(gross). That is the number to beat."
    }
    return "You v \(them). Best round of the week takes it."
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

  /// The one action. Which one depends on who is where — and it is never
  /// "post again" to a golfer who has already posted.
  public static func action(_ c: HomeClash) -> String {
    if c.mine == nil { return "Add my round" }
    switch c.edge {
    case .me:    return "See the receipt"
    case .them:  return "Post a better one"
    case .level: return "Post a better one"
    }
  }
}
