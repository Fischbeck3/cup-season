// Cup Season — the board's derived lines, each a port of one web function.
//
//   roundStreak      5207   "N STRAIGHT UNDER" walked off the round cache (D76)
//   counting line    5241   COUNTING #n / BUMPED / PRE-SEASON · NOT COUNTING
//   boardDigestHtml  5063   "SINCE YOU WERE HERE" on a quiet day (F13 3.3)
//   #statFinal       9422   the nearest deadline line the digest quotes
//   boardSeenKey     5029   per-device seen mark, `cs_board_seen_<league>`
//
// Nothing here is authoritative: month_rank, pvi and points arrive from
// `v_rounds_ranked`; these only phrase them.

import Foundation

public enum BoardLogic {
  // MARK: - Streak (D76)

  /// Nth straight round beating the number (pvi ≥ 1), walked off the board's
  /// own cache. Cache-only: the board window IS the history.
  public static func roundStreak(_ r: BoardRound, cache: [UUID: BoardRound]) -> Int {
    guard let pid = r.profileId, let pvi = r.pvi, pvi >= 1 else { return 0 }
    let mine = cache.values
      .filter { $0.profileId == pid && $0.pvi != nil && $0.playedOn != nil }
      .sorted { a, b in
        if a.playedOn == b.playedOn { return a.id.uuidString < b.id.uuidString }
        return (a.playedOn ?? "") < (b.playedOn ?? "")
      }
    var n = 0
    for x in mine {
      n = (x.pvi ?? 0) >= 1 ? n + 1 : 0
      if x.id == r.id { return n }
    }
    return 0
  }

  // MARK: - Counting line (5241–5246)

  public enum Counting: Equatable, Sendable {
    case preseason            // month_rank null — "PRE-SEASON · NOT COUNTING"
    case counting(Int)        // "COUNTING #n THIS MONTH"
    case bumped(Int?)         // "BUMPED — OUTSIDE THE BEST n THIS MONTH"

    public var text: String {
      switch self {
      case .preseason: "PRE-SEASON · NOT COUNTING"
      case .counting(let n): "COUNTING #\(n) THIS MONTH"
      case .bumped(let cap): "BUMPED — OUTSIDE THE BEST \(cap.map(String.init) ?? "") THIS MONTH"
      }
    }
    /// `.ok` (pos) for counting, `.dim` for the other two.
    public var ok: Bool { if case .counting = self { return true }; return false }
  }

  /// D142: marks against the league's ACTUAL `counting_cap` (nil = unlimited),
  /// so a cap the ladder does not carry still bumps at the right rank.
  public static func counting(monthRank: Int?, capN: Int?) -> Counting {
    guard let rank = monthRank else { return .preseason }
    if let capN, rank > capN { return .bumped(capN) }
    return .counting(rank)
  }

  /// `<gross> GROSS · <BAND>` — the band in third person unless it's yours.
  public static func grossLine(_ r: BoardRound, viewer: UUID?) -> String {
    var s = "\(r.gross.map(String.init) ?? "—") GROSS"
    if let pvi = r.pvi {
      let band = CSBands.bandName(pvi)
      let mine = r.profileId != nil && r.profileId == viewer
      s += " · " + (mine ? band : CSBands.theirs(band)).uppercased()
    }
    return s
  }

  /// `course · N holes · date` (5262). The label goes through `RoundCopy.course`
  /// so the board says "Palo Verde GC", not the "Palo Verde Gc" the course API
  /// title-cased upstream.
  public static func courseLine(_ r: BoardRound) -> String {
    let c = RoundCopy.course(r.courseLabel)
    return "\(c.isEmpty ? "somewhere out there" : c) · \(r.holesPlayed ?? 18) holes · \(r.playedOn ?? "")"
  }

  // MARK: - Digest (F13 3.3)

  /// `digestRoundLine` — the latest round story as one line.
  public static func digestRoundLine(_ f: BoardItem, cache: [UUID: BoardRound], names: BoardText.NameRegistry) -> String {
    if let rid = f.roundId, let r = cache[rid], r.gross != nil {
      let band = r.pvi.map(CSBands.bandName) ?? ""
      let c = RoundCopy.course(r.courseLabel)
      return "\(f.who.isEmpty ? "—" : f.who) · \(c.isEmpty ? "somewhere out there" : c)\(band.isEmpty ? "" : " · \(band)")"
    }
    return BoardText.easeCaps(f.text, names: names)
  }

  /// The digest's lines, or nil when the feed itself is the reveal. `marker`
  /// is the seen mark (0 = first-ever open); `next` is the #statFinal line.
  public static func digest(items: [BoardItem], cache: [UUID: BoardRound], names: BoardText.NameRegistry,
                            marker: TimeInterval, next: String?, now: Date = Date()) -> [String]? {
    guard !items.isEmpty, marker > 0 else { return nil }
    let newest = items.reduce(0.0) { max($0, ($1.ts ?? now).timeIntervalSince1970 * 1000) }
    if newest > marker { return nil }   // something new landed — feed renders exactly as today
    var lines: [String] = []
    if let f = items.last(where: { $0.kind == .round }) { lines.append(digestRoundLine(f, cache: cache, names: names)) }
    if let f = items.last(where: { $0.kind == .system }) { lines.append("◆ " + BoardText.easeCaps(f.text, names: names)) }
    if let next, !next.isEmpty { lines.append(next) }
    return lines.isEmpty ? nil : lines
  }

  // MARK: - The seen mark (5029)

  /// `cs_board_seen_<league>` — read ONCE per league per session, frozen,
  /// then stamped "now". Milliseconds, like the web's `Date.now()`.
  @MainActor public static var frozenSeen: [String: TimeInterval] = [:]

  @MainActor public static func seenMarker(league: UUID, now: Date = Date(), defaults: UserDefaults = .standard) -> TimeInterval {
    let key = "cs_board_seen_" + league.uuidString
    if let m = frozenSeen[key] { return m }
    let raw = defaults.object(forKey: key) as? Double ?? 0
    frozenSeen[key] = raw
    defaults.set(now.timeIntervalSince1970 * 1000, forKey: key)
    return raw
  }

  // MARK: - #statFinal (9422–9456)

  /// The season's nearest-deadline line, as the strip renders it. `finish`
  /// is the endgame dial ("cup_final" | "points"); `phase` the league phase.
  public static func seasonDeadline(season: Me.Season?, finish: String?, phase: String, today: Date = Date(),
                                    calendar: Calendar = .current) -> String? {
    guard let s = season else { return nil }
    if s.status == "complete" { return "Season complete · settled" }
    guard let start = CSDate.local(s.starts_on, calendar: calendar), let end = CSDate.local(s.ends_on, calendar: calendar) else { return nil }
    let day = calendar.startOfDay(for: today)
    let cf = calendar.date(byAdding: .day, value: -27, to: end) ?? end
    let isCupFinal = (finish ?? "cup_final") == "cup_final" && phase == "season" && today >= cf
    if phase == "season", today < start { return "First tee \(BoardText.firstTee(s.starts_on, calendar: calendar))" }
    if isCupFinal {
      let left = max(0, Int(ceil(end.timeIntervalSince(today) / 86400)))
      return "CUP FINAL LIVE · \(left) day\(left == 1 ? "" : "s") left"
    }
    func dTo(_ d: Date) -> Int { Int((calendar.startOfDay(for: d).timeIntervalSince(day) / 86400).rounded()) }
    // M-17 / §14.0: the week closes on the season's own weekday — the last day of
    // the clash window that holds today — never a hardcoded Sunday.
    let startDay = calendar.startOfDay(for: start)
    let since = max(0, Int((day.timeIntervalSince(startDay) / 86400).rounded()))
    let close = calendar.date(byAdding: .day, value: (since / 7) * 7 + 6, to: startDay) ?? day
    let closeDow = BoardText.DOW[calendar.component(.weekday, from: close) - 1]
    var comps = calendar.dateComponents([.year, .month], from: day)
    comps.month = (comps.month ?? 1) + 1; comps.day = 1
    let first = calendar.date(from: comps) ?? day
    struct Opt { let n: Int; let pri: Int; let t: String }
    var opts = [
      Opt(n: dTo(close), pri: 0, t: dTo(close) == 0 ? "Week closes tonight" : "Week closes \(closeDow) · \(dTo(close))d"),
      Opt(n: dTo(first), pri: 1, t: "Month closes \(BoardText.MOS[(calendar.component(.month, from: first) - 1)]) 1 · floors assessed"),
    ]
    if (finish ?? "cup_final") == "cup_final" {
      if cf >= day {
        let c = calendar.dateComponents([.weekday, .month, .day], from: cf)
        // The Final tees off the morning after a week closes; that week is its
        // run-up, so the gold line wins it (ties go to the Final).
        let n = dTo(cf) == dTo(close) + 1 ? dTo(close) : dTo(cf)
        opts.append(Opt(n: n, pri: 2, t: "Cup Final · \(BoardText.DOW[(c.weekday ?? 1) - 1]) \(BoardText.MOS[(c.month ?? 1) - 1]) \(c.day ?? 1) · \(dTo(cf))d"))
      }
    } else if end >= day {
      let c = calendar.dateComponents([.month, .day], from: end)
      opts.append(Opt(n: dTo(end), pri: 2, t: "Points table crowns it · ends \(BoardText.MOS[(c.month ?? 1) - 1]) \(c.day ?? 1) · \(dTo(end))d"))
    }
    return opts.sorted { $0.n != $1.n ? $0.n < $1.n : $0.pri > $1.pri }.first?.t
  }
}
