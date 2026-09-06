// Cup Season — what a round is worth (R-K, D256).
//
// THIS IS NOT A NEW PRODUCER. It is the arithmetic that already lived inside
// `ClimbMath.closer`, lifted to a home three surfaces can read, because R-K
// ruled that the plan sheet and Home's dispatch must say what a round is worth
// with the SAME sum the climb has been doing since QB-12. `ClimbMath.closer`
// now calls `gain` instead of doing it again; a second copy is a drift waiting
// to happen (D201) and preflight 37 fails the push on one.
//
// THE SUM, stated exactly — and it is the server's, verbatim
// (`public.round_worth(p_cap, p_used, p_worst)`), the way `CSBands.cupPoints`
// is `cup_points` verbatim:
//
//   · with the month's counting slots NOT yet full, a new round ADDS its
//     points, so a top-band round is worth the whole 12;
//   · with them full, a top-band round BUMPS the worst counter, so it is
//     worth 12 minus that round.
//
// IT IS A CEILING, NEVER A PROBABILITY (D24). "Worth up to 12" is what a round
// can be worth if it is torched; nothing here says it will be, nothing here
// weighs a chance, and the word "up to" is load-bearing. A nine-hole round
// scores half (`v_rounds_ranked`), so the ceiling assumes eighteen — which is
// what a ceiling is for.
//
// SILENCE IS AN ANSWER. Absent a cap or a counter the sum is not knowable, and
// `line` returns nil rather than guessing; an un-migrated database therefore
// renders no worth line at all rather than a wrong one (L-44).

import Foundation

public enum RoundWorth {

  /// The top band, read from the one band table (§4.27) rather than typed.
  public static var topBand: Double { Double(CSBands.cupPoints(3)) }

  // MARK: - the sum

  /// The points a top-band round ADDS to my month, or nil when the machine
  /// does not hold the facts.
  ///
  /// - `cap` nil (or ≤ 0) is an UNCAPPED league: every round counts, so a
  ///   round is worth the whole top band.
  /// - `used` ≥ `cap` is a full month: the round bumps the worst counter, and
  ///   without that counter's points there is no honest answer.
  public static func gain(cap: Int?, used: Int?, worst: Double?) -> Double? {
    let u = used ?? 0
    guard let cap, cap > 0, u >= cap else { return topBand }
    guard let worst, worst.isFinite else { return nil }
    return topBand - worst
  }

  /// How many counting slots the month still has open, or nil when uncapped
  /// or unknown. "In hand" is R-K's fence: the dispatch item may only speak
  /// where a counting round genuinely remains.
  public static func slotsLeft(cap: Int?, used: Int?) -> Int? {
    guard let cap, cap > 0 else { return nil }
    return max(0, cap - (used ?? 0))
  }

  // MARK: - the sentences

  /// The plan sheet's two sentences, or nil.
  ///
  /// `subject` is what the surface calls the round. The plan sheet passes
  /// "This round" because its own header already carries the day and the
  /// course, and a card that prints one fact twice is the defect DEF-2 was
  /// filed for (L-34). A surface with no such context passes the day and the
  /// place — *"Tomorrow at Papago"* — which is R-K's own sentence.
  ///
  /// `season` names the season when a round counts in more than one, and is
  /// left nil when there is only one to name.
  public static func line(subject: String, cap: Int?, used: Int?, worst: Double? = nil,
                          season: String? = nil) -> String? {
    guard let g = gain(cap: cap, used: used, worst: worst) else { return nil }
    let whose = season.map { " in \($0)" } ?? ""
    let u = used ?? 0
    let full = (cap ?? 0) > 0 && u >= (cap ?? 0)
    if g <= 0 {
      // A month whose counters are already top-band rounds. The round still
      // builds the number and still earns its floor credit, and saying so is
      // truer than silence and truer than a zero.
      return "\(subject) cannot add to your points\(whose) this month — your best \(cap.map(String.init) ?? "rounds") already count. It still builds your number."
    }
    let head = "\(subject) is worth up to \(CSCopy.points(g))\(full ? " more" : "")\(whose)."
    guard let cap, cap > 0 else { return head + " Every round you post this month counts." }
    let tail = full
      ? "Your best \(cap) count this month and your worst is a \(CSCopy.points(worst))."
      : "Your best \(cap) count and you have \(u)."
    return head + " " + tail
  }

  // MARK: - the counters, as they arrive

  /// One season's cap and counters for the month a round falls in —
  /// `round_detail`'s `worth` array, and nothing this client computes.
  /// Every field is optional: a database that predates the migration sends
  /// the key not at all, and the sheet renders nothing in its place (L-44).
  public struct Counters: Sendable, Equatable, Identifiable {
    public let leagueId: UUID?
    public let leagueName: String?
    public let cap: Int?
    public let used: Int?
    public let worst: Double?
    public var id: String { leagueId?.uuidString ?? leagueName ?? "—" }

    public init(leagueId: UUID?, leagueName: String?, cap: Int?, used: Int?, worst: Double?) {
      self.leagueId = leagueId; self.leagueName = leagueName; self.cap = cap; self.used = used; self.worst = worst
    }

    public init?(_ v: JSONValue) {
      guard case .object = v else { return nil }
      self.init(leagueId: v["league_id"]?.string.flatMap(UUID.init),
                leagueName: v["league_name"]?.string,
                cap: v["cap"]?.int, used: v["used"]?.int, worst: v["worst"]?.double)
    }

    /// This row's sentence. `named` is the caller's answer to "is there more
    /// than one season on this round" — the only reason to spend words on a
    /// season's name (L-34).
    public func line(subject: String, named: Bool) -> String? {
      RoundWorth.line(subject: subject, cap: cap, used: used, worst: worst,
                      season: named ? leagueName : nil)
    }
  }

  /// The lines a plan sheet prints, in payload order, at most two. A round can
  /// count in more than one season, and three of these is a wall of arithmetic
  /// on a sheet whose job is who is in and when.
  public static func lines(_ rows: [Counters], subject: String = "This round", limit: Int = 2) -> [String] {
    let named = rows.count > 1
    return rows.prefix(limit).compactMap { $0.line(subject: subject, named: named) }
  }
}
