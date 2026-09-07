// Cup Season — the standings arithmetic the web client does in the browser,
// ported line for line so the phone can never disagree with it:
//   teams / series / priorRank / the story  (index.html 4513–4600, 14371–14380)
//   indRows / myMonth / myIndexDelta        (14494–14516)
//   the individual race trio                (11250–11275)
//   the climb window + cut line             (4273–4360)
//   the scenario line                       (14557–14600)
// Nothing here is authoritative: the points come from the views; this file
// only orders, phrases and windows them (README: "the phone previews and
// renders").

import Foundation

// MARK: - Shapes

/// One row of the race — a squad, or a player in a solo league.
public struct Team: Identifiable, Sendable, Equatable {
  public let id: UUID
  public let name: String
  /// Captain's name ("" when solo or unknown) — `memName(captain_member_id)`.
  public let cap: String
  public let pts: Double
  /// Palette index 0…3 → `sq0…sq3`.
  public let ci: Int
  public let solo: Bool
  /// Rounds posted (solo rows only).
  public let sub: Int
  public let mk: String?
  public init(id: UUID, name: String, cap: String = "", pts: Double, ci: Int, solo: Bool = false, sub: Int = 0, mk: String? = nil) {
    self.id = id; self.name = name; self.cap = cap; self.pts = pts; self.ci = ci; self.solo = solo; self.sub = sub; self.mk = mk
  }
}

public struct HistRound: Sendable, Equatable, Identifiable {
  public let round_id: UUID?
  public let played_on: String
  public let holes_played: Int?
  public let pvi: Double
  public let points: Double
  public let counting: Bool
  public let index_at_post: Double?
  public var id: String { round_id?.uuidString ?? played_on + String(pvi) }
  public init(round_id: UUID?, played_on: String, holes_played: Int?, pvi: Double, points: Double, counting: Bool, index_at_post: Double?) {
    self.round_id = round_id; self.played_on = played_on; self.holes_played = holes_played; self.pvi = pvi; self.points = points
    self.counting = counting; self.index_at_post = index_at_post
  }
}

/// `window.indRows[]` — one per member of the season.
public struct IndRow: Identifiable, Sendable, Equatable {
  public let mid: UUID
  public let profileId: UUID?
  public let n: String
  public let ci: Int
  public let sq: String
  public let r: Int
  public let avg: Double
  public let best: Double?
  public let pts: Double
  /// last `index_at_post` − first, this season; nil under two rounds.
  public let d: Double?
  public let me: Bool
  /// Newest first, `counting` = month_rank ≤ cap.
  public let hist: [HistRound]
  public var id: UUID { mid }
  public init(mid: UUID, profileId: UUID? = nil, n: String, ci: Int, sq: String, r: Int, avg: Double, best: Double?, pts: Double, d: Double?, me: Bool, hist: [HistRound]) {
    self.mid = mid; self.profileId = profileId; self.n = n; self.ci = ci; self.sq = sq; self.r = r; self.avg = avg; self.best = best
    self.pts = pts; self.d = d; self.me = me; self.hist = hist
  }
}

public struct MyMonth: Sendable, Equatable {
  public let credits: Double
  public let counting: Int
  public init(credits: Double, counting: Int) { self.credits = credits; self.counting = counting }
}

/// A-4 · THE HONEST MOVEMENT LABEL — the phone's twin of the web's
/// `csMovement`, and the producer that finally kills the bare chip.
///
/// `prev_rank` is a SUNDAY snapshot (`run_week_snapshots`, cron `'10 7 * * 0'`),
/// so a Tuesday climb read "held" and erased the only movement of the week.
/// The rule is absolute on both clients now: a movement label NAMES THE DAY IT
/// IS MEASURED FROM, or it does not render. No clock, no label — which is the
/// deploy-skew case and the week-1 case both.
///
/// `delta` is prior rank minus current rank (positive = climbed). `since` is
/// the snapshot's own `captured_at`; its calendar-date prefix is what names the
/// day, never an ISO parse of the instant (L-07).
public struct Movement: Sendable, Equatable {
  /// `held` · `up` · `up2` · `down`.
  ///
  /// **Wave 7 · `up2` KEEPS ITS MAGNITUDE AND LOSES ITS COLOUR.** The fourth
  /// case is inherited from the deleted heat axis, where a climb of two or
  /// more took a hotter tint than a climb of one. There is now one `pos` and
  /// one `cool` in the whole system, so `up2` is a *size* of movement and
  /// never a second green: `CSMovement` paints from `dir`, and the desk's
  /// `.up2` class carries no colour of its own. The case survives because the
  /// arithmetic (who moved, by how much) is still the arithmetic.
  public enum Tone: String, Sendable, Equatable { case held, up, up2, down }
  public let tone: Tone
  /// **NO GLYPH.** `UP 1 SINCE SUN` / `DOWN 2 SINCE SUN` / `HELD SINCE SUN`.
  ///
  /// It used to emit `▲1 SINCE SUN` — a typed arrow inside a produced string,
  /// which `LINT-13` fails, and which is the half of the audit's DD-02 that a
  /// renderer cannot fix: the same glyph was being emitted for **most
  /// improved** by three other producers, where it means the opposite thing.
  /// The producer now emits the PARTS — `dir`, `count`, `sinceShort` — and
  /// `CSMovement` draws the triangle, in one direction, with one meaning.
  public let text: String
  /// The magnitude, with no sign and no glyph: 1, 2, … · **0 when held**.
  public let count: Int
  /// `SUN` — the short day the movement is measured from. A movement label
  /// NAMES THE DAY IT IS MEASURED FROM or it does not render, and this is the
  /// part of that rule a drawn mark cannot carry, which is why the clock rides
  /// the section head for the whole table (D-2).
  public let sinceShort: String
  /// "up one since Sunday" — the VoiceOver grain, and the AX3 line. Unchanged.
  public let long: String
  /// 1 climbed · 0 held · -1 fell.
  public let dir: Int
  public init(tone: Tone, text: String, count: Int, sinceShort: String, long: String, dir: Int) {
    self.tone = tone; self.text = text; self.count = count
    self.sinceShort = sinceShort; self.long = long; self.dir = dir
  }
}

/// The ▲/▼ chip vs the last weekly snapshot (D76 heat).
///
/// **Superseded as a user-facing label by `Movement`** (A-4): `.held`'s "–" is
/// a claim about time made without a clock. The type survives because the
/// arithmetic (who moved, by how much) is still the arithmetic.
public enum RankMove: Sendable, Equatable {
  case held
  case up(Int)
  case down(Int)
  /* D276 / LINT-13 · `label` is DELETED. It emitted `▲2` — a typed triangle
     in a produced string, in the same face and size as the DOWN triangle three
     other producers put on an IMPROVING handicap index, with no colour between
     them (the audit's DD-02). `Movement` already superseded it as the
     user-facing label and nothing rendered `label` any more, so the fix is the
     deletion rather than a second parts-shaped producer. `title` survives
     because it is WORDS, which is what a producer is allowed to emit. */
  public var title: String {
    switch self {
    case .held: "held this week"
    case .up(let n): "up \(n) this week"
    case .down(let n): "down \(n) this week"
    }
  }
}

/// `#standingsStory` — the serif sentence over the table (4535–4544).
public enum StandingsStory: Sendable, Equatable {
  case none
  case outFront(Team)
  case deadHeat(Team, Team, pts: Double)
  case lead(Team, Team, margin: Double, back: String)

  /// The sentence, plain. Views colour the names.
  ///
  /// F-9 · the VERB AGREES with its subject. This was written when a `Team`
  /// was always a squad — "Reds lead by 4" — and D205 made a solo season a
  /// season at two golfers, so `a.name` is a PERSON now and the line read
  /// "Galen lead by 4". `Team.solo` is the answer the row already carries.
  ///
  /// And the two clauses are joined by a FULL STOP, not a middot: a middot
  /// between two independent clauses reads as two links rather than a
  /// sentence, and V-4 wants a sentence with a subject directly above THE
  /// TABLE.
  public var text: String { text(viewer: nil) }

  /// DEF-3 · **one screen, one name for one person.** The clash card above the
  /// table says `you`, the story line said `Jerecho Fischbeck` and the row
  /// under it said `Jerecho Fischbeck` again — three names for the golfer
  /// reading them. The viewer's own SOLO row resolves to **You** in every
  /// sentence addressed to them; the full name stays on the Tour Card, where
  /// it identifies a person to somebody else. A SQUAD keeps its name: a squad
  /// is a thing the viewer is in, not the viewer.
  ///
  /// Second person takes a second-person verb, so the elision that carries a
  /// third-person clause ("Galen out front", "Squad 2 a good weekend back")
  /// gains its copula rather than printing "You out front".
  public func text(viewer: UUID?) -> String {
    switch self {
    case .none: return ""
    case .outFront(let a):
      return "\(Self.displayName(a, viewer: viewer)) \(Self.isYou(a, viewer) ? "are " : "")out front — waiting on a challenger."
    case .deadHeat(let a, let b, let pts):
      return "Dead heat — \(Self.displayName(a, viewer: viewer)) and \(Self.displayName(b, viewer: viewer)) level at \(CSCopy.points(pts))."
    case .lead(let a, let b, let m, let back):
      return "\(Self.displayName(a, viewer: viewer)) \(Self.leads(a, viewer: viewer)) by \(CSCopy.points(m)). "
        + "\(Self.displayName(b, viewer: viewer)) \(Self.isYou(b, viewer) ? "are " : "")\(back)."
    }
  }

  /// True when this rung is the golfer reading it.
  public static func isYou(_ t: Team, _ viewer: UUID?) -> Bool {
    guard t.solo, let v = viewer else { return false }
    return t.id == v
  }

  /// The name a SENTENCE uses for a rung. See `text(viewer:)`.
  public static func displayName(_ t: Team, viewer: UUID?) -> String {
    isYou(t, viewer) ? "You" : t.name
  }

  /// The name a TABLE ROW uses. The row is a place a golfer looks to find
  /// themselves, so it keeps the full name and marks it — the same form the
  /// climb has always rendered (`ClimbView`: `You · <name>`).
  public static func rowName(_ t: Team, viewer: UUID?) -> String {
    isYou(t, viewer) ? "You · \(t.name)" : t.name
  }

  /// "lead" for you, "leads" for one other golfer, "lead" for a squad.
  /// The row knows which it is.
  public static func leads(_ t: Team, viewer: UUID? = nil) -> String {
    isYou(t, viewer) ? "lead" : (t.solo ? "leads" : "lead")
  }
}

// MARK: - The math

public enum StandingsMath {
  /// `CAPVALS` — the rounds that count as a number (nil = unlimited).
  public static func capN(_ countingCap: Int?) -> Int { countingCap ?? Int.max }

  /// `memCi` (14384): the palette index of the squad a member sits in; 1 when unsquadded.
  public static func memCi(_ memberId: UUID, squads: [LeagueRoom.Squad]) -> Int {
    guard let i = squads.firstIndex(where: { $0.seats(memberId) }) else { return 1 }
    return i % 4
  }

  /// `sqOf` (14490): the squad's first four letters, upper.
  public static func sqOf(_ memberId: UUID, squads: [LeagueRoom.Squad]) -> String {
    guard let q = squads.first(where: { $0.seats(memberId) }) else { return "" }
    return String(q.name.prefix(4)).uppercased()
  }

  /// Squads → teams, sorted by points (14371–14380). Stable, like the web's sort.
  public static func squadTeams(squads: [LeagueRoom.Squad], standings: [LeagueRoom.SquadStanding], captainName: (UUID?) -> String) -> [Team] {
    let pts = Dictionary(standings.map { ($0.squad_id, $0.points ?? 0) }, uniquingKeysWith: { a, _ in a })
    let teams = squads.enumerated().map { i, q in
      Team(id: q.id, name: q.name, cap: captainName(q.captain_member_id), pts: pts[q.id] ?? 0, ci: (q.color ?? i) % 4)
    }
    return teams.sorted { $0.pts > $1.pts }
  }

  /// Solo leagues: the race IS the individual standings (14520–14528).
  public static func soloTeams(_ rows: [IndRow], marker: (UUID) -> String?) -> [Team] {
    rows.map { Team(id: $0.mid, name: $0.n, cap: "", pts: $0.pts, ci: $0.ci, solo: true, sub: $0.r, mk: marker($0.mid)) }
      .sorted { $0.pts > $1.pts }
  }

  /// `indRows` (14494–14508), verbatim math.
  public static func indRows(indiv: [LeagueRoom.IndivStanding], ranked: [LeagueRoom.RankedRound], members: [LeagueRoom.Member],
                             squads: [LeagueRoom.Squad], myMemberId: UUID?, capN: Int) -> [IndRow] {
    var by: [UUID: [LeagueRoom.RankedRound]] = [:]
    for r in ranked { by[r.member_id, default: []].append(r) }
    for k in by.keys { by[k]!.sort { $0.played_on < $1.played_on } }
    let memberById = Dictionary(members.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
    let rows = indiv.map { i -> IndRow in
      let rs = by[i.member_id] ?? []
      let d: Double? = rs.count > 1 ? (rs.last!.index_at_post ?? 0) - (rs.first!.index_at_post ?? 0) : nil
      let pvis = rs.map { $0.pvi ?? 0 }
      let m = memberById[i.member_id]
      return IndRow(
        mid: i.member_id, profileId: m?.profile_id, n: m?.name ?? "—", ci: memCi(i.member_id, squads: squads), sq: sqOf(i.member_id, squads: squads),
        r: i.rounds_posted ?? 0,
        avg: pvis.isEmpty ? 0 : pvis.reduce(0, +) / Double(pvis.count),
        best: pvis.max(),
        pts: i.points ?? 0, d: d, me: i.member_id == myMemberId,
        hist: rs.map { HistRound(round_id: $0.round_id, played_on: $0.played_on, holes_played: $0.holes_played, pvi: $0.pvi ?? 0,
                                 points: $0.points ?? 0, counting: ($0.month_rank ?? Int.max) <= capN, index_at_post: $0.index_at_post) }.reversed())
    }
    return rows.sorted { a, b in a.pts != b.pts ? a.pts > b.pts : a.avg > b.avg }
  }

  /// `window.myMonth` (14510–14513): the device's current month.
  public static func myMonth(mine: [LeagueRoom.RankedRound], capN: Int, monthKey: String) -> MyMonth {
    let mm = mine.filter { $0.played_on.hasPrefix(monthKey) }
    return MyMonth(credits: mm.reduce(0) { $0 + ($1.floor_credit ?? 0) },
                   counting: mm.filter { ($0.month_rank ?? Int.max) <= capN }.count)
  }

  /// **The points on the month's counting rounds**, which is the array the
  /// QB-12 closer arithmetic bumps against. `myMonth` counts them; this names
  /// them. A round with no points is not a counter.
  public static func countingPoints(mine: [LeagueRoom.RankedRound], capN: Int, monthKey: String) -> [Double] {
    mine.filter { $0.played_on.hasPrefix(monthKey) && ($0.month_rank ?? Int.max) <= capN }
        .compactMap(\.points)
  }

  /// `window.myIndexDelta` (14514–14516).
  public static func myIndexDelta(mine: [LeagueRoom.RankedRound], profileIndex: Double?) -> Double? {
    let sorted = mine.sorted { $0.played_on < $1.played_on }
    guard sorted.count > 1 else { return nil }
    let now = profileIndex ?? sorted.last!.index_at_post ?? 0
    return now - (sorted.first!.index_at_post ?? 0)
  }

  /// A-4 · the movement label, or nil. The web's `csMovement`, word for word:
  /// the same words, the same tones, the same two refusals.
  public static func movement(delta: Int?, since: String?, calendar: Calendar = .current) -> Movement? {
    guard let delta, let since, !since.isEmpty else { return nil }
    // the instant's own calendar-date prefix — never an ISO parse (L-07)
    guard let d = CSDate.local(String(since.prefix(10)), calendar: calendar) else { return nil }
    let wd = calendar.component(.weekday, from: d)
    let short = LeagueDates.dow[max(0, min(6, wd - 1))].uppercased()
    let long = LeagueDates.dow[max(0, min(6, wd - 1))]
    if delta == 0 {
      return Movement(tone: .held, text: "HELD SINCE \(short)", count: 0, sinceShort: short,
                      long: "held since \(long)", dir: 0)
    }
    let n = abs(delta)
    let word = SeasonStoryCopy.word(n)
    let up = delta > 0
    return Movement(tone: up ? (delta >= 2 ? .up2 : .up) : .down,
                    text: "\(up ? "UP" : "DOWN") \(n) SINCE \(short)",
                    count: n, sinceShort: short,
                    long: "\(up ? "up" : "down") \(word) since \(long)",
                    dir: up ? 1 : -1)
  }

  /// **`MOVED SINCE SUN` — the movement clock, named ONCE for the whole
  /// table** (D-2). The shipped board printed `HELD SINCE SUN` eleven times at
  /// 11pt beside eleven two-digit ranks; the clock is a property of the
  /// SNAPSHOT, not of a row, so it rides the section head and the rows carry a
  /// drawn mark. `StandingsMath`'s absolute rule is unchanged: no clock, no
  /// claim — this returns nil and the movement column does not render either.
  public static func movedSince(_ since: String?, calendar: Calendar = .current) -> String? {
    guard let since, !since.isEmpty,
          let d = CSDate.local(String(since.prefix(10)), calendar: calendar) else { return nil }
    let wd = calendar.component(.weekday, from: d)
    return "moved since \(LeagueDates.dow[max(0, min(6, wd - 1))])"
  }

  /// **COMPETITION RANK, WITH TIES SHARED — 04, 04, 06.**
  ///
  /// The shipped renderers index the sorted array, so two golfers on 86 points
  /// read `04` and `05`: the table showed the same figure twice and gave it
  /// two positions, which is the one thing a points table may not do. This is
  /// standard competition ranking over the column the table actually PRINTS —
  /// the points — so what a golfer sees and what the rail says can never
  /// disagree. The rows keep the server's order; only the numeral is shared.
  ///
  /// It is computed on the client because both clients hold the whole column
  /// and a rank derived from it is arithmetic over produced facts, not a new
  /// fact. `N-2` on the server would let the tiebreak ladder split a tie that
  /// the points alone cannot; until it exists, a tie on points is drawn as a
  /// tie on points.
  public static func competitionRanks(_ points: [Int]) -> [Int] {
    var out: [Int] = []
    out.reserveCapacity(points.count)
    for (i, p) in points.enumerated() {
      if i > 0, p == points[i - 1] { out.append(out[i - 1]) } else { out.append(i + 1) }
    }
    return out
  }

  /// The clock a movement label is measured from — the latest snapshot's own
  /// `captured_at`. nil on a read that did not ask for it, and then there is
  /// no label at all rather than a bare arrow.
  public static func priorSince(snapshots: [LeagueRoom.Snapshot]) -> String? {
    guard let lastWk = snapshots.map(\.week_no).max() else { return nil }
    return snapshots.first(where: { $0.week_no == lastWk })?.captured_at
  }

  /// `priorRank` (4523–4531): rank in the latest weekly snapshot, by id.
  public static func priorRank(snapshots: [LeagueRoom.Snapshot], solo: Bool) -> [UUID: Int] {
    guard let lastWk = snapshots.map(\.week_no).max(), let snap = snapshots.first(where: { $0.week_no == lastWk }) else { return [:] }
    let rows = snapshotRows(snap.standings, solo: solo).sorted { $0.pts > $1.pts }
    var out: [UUID: Int] = [:]
    for (i, r) in rows.enumerated() where out[r.id] == nil { out[r.id] = i }
    return out
  }

  /// `buildRealSeries` (4243–4262): one point per snapshot week, then now.
  public static func series(teams: [Team], snapshots: [LeagueRoom.Snapshot], weeks: Int, solo: Bool) -> [UUID: [Double]] {
    let lastWk = snapshots.map(\.week_no).max() ?? 0
    var out: [UUID: [Double]] = [:]
    for t in teams {
      var arr: [Double] = []
      var last = 0.0
      if lastWk >= 1 {
        for w in 1...min(weeks, lastWk) {
          if let snap = snapshots.first(where: { $0.week_no == w }),
             let row = snapshotRows(snap.standings, solo: solo).first(where: { $0.id == t.id }) { last = row.pts }
          arr.append(last)
        }
      }
      arr.append(t.pts)
      out[t.id] = arr
    }
    return out
  }

  private static func snapshotRows(_ v: JSONValue, solo: Bool) -> [(id: UUID, pts: Double)] {
    (v[solo ? "individuals" : "squads"]?.array ?? []).compactMap { r in
      guard let s = r[solo ? "member_id" : "squad_id"]?.string, let id = UUID(uuidString: s) else { return nil }
      return (id, r["points"]?.double ?? 0)
    }
  }

  /// The ▲/▼ chip (4559–4563): nil when there is no snapshot yet.
  public static func move(prior: Int?, now: Int) -> RankMove? {
    guard let prior else { return nil }
    let d = prior - now
    return d == 0 ? .held : d > 0 ? .up(d) : .down(-d)
  }

  /// `#standingsStory` (4535–4544).
  public static func story(_ teams: [Team]) -> StandingsStory {
    guard let a = teams.first else { return .none }
    guard let b = teams.dropFirst().first else { return a.pts > 0 ? .outFront(a) : .none }
    if a.pts == 0 && b.pts == 0 { return .none }
    let m = a.pts - b.pts
    if m == 0 { return .deadHeat(a, b, pts: a.pts) }
    return .lead(a, b, margin: m, back: m <= 15 ? "a good weekend back" : "\(CSCopy.points(m)) back")
  }

  /// The award tiles (11266–11275). First names only — the tiles are narrow.
  public struct Awards: Sendable, Equatable {
    public let king: String, kingSub: String
    public let improved: String, improvedSub: String
    public let iron: String, ironSub: String
  }
  public static func firstName(_ n: String?) -> String {
    let t = (n ?? "—").trimmingCharacters(in: .whitespaces)
    return t.split(separator: " ").first.map(String.init) ?? "—"
  }
  public static func awards(_ rows: [IndRow]) -> Awards? {
    guard let king = rows.first else { return nil }
    let iron = rows.max { a, b in a.r < b.r }!
    let movers = rows.filter { ($0.d ?? 0) < -0.04 && $0.d != nil }.sorted { $0.d! < $1.d! }
    return Awards(
      king: king.pts > 0 ? firstName(king.n) : "—",
      kingSub: "Points King" + (king.pts > 0 ? " · \(CSCopy.points(king.pts)) pts" : ""),
      improved: movers.first.map { firstName($0.n) } ?? "—",
      // **▼ MEANT TWO OPPOSITE THINGS IN ONE PRODUCT** (the audit's DD-02, a
      // P0). On the table a down-triangle means *you fell*; here it meant
      // *your index came down*, which is the best thing that can happen to a
      // golfer — the same 11pt glyph, in the same face, with no colour and no
      // label separating them. The award now says the fact in words: an index
      // that dropped 0.5 reads `0.5 OFF THE INDEX`, and **no producer in the
      // product emits an arrow character for most improved.**
      improvedSub: movers.first.map { "Most Improved · " + String(format: "%.1f", abs($0.d!)) + " off the index" } ?? "Most Improved · needs 2+ rounds",
      iron: iron.r > 0 ? firstName(iron.n) : "—",
      ironSub: "Iron Man" + (iron.r > 0 ? " · \(iron.r) rds" : ""))
  }

  /// "+1.2" / "-0.4" — `sgn`.
  public static func sgn(_ v: Double) -> String { (v >= 0 ? "+" : "") + String(format: "%.1f", v) }
}

// MARK: - The climb (D26)

public struct ClimbCut: Sendable, Equatable {
  public let K: Int
  public let line: String
  public init(K: Int, line: String) { self.K = K; self.line = line }
}

public enum ClimbItem: Sendable, Equatable, Identifiable {
  case rung(ClimbRung)
  case cut(label: String)
  case ellipsis(id: String, hidden: Int)
  public var id: String {
    switch self {
    case .rung(let r): r.team.id.uuidString
    case .cut: "cut"
    case .ellipsis(let id, _): id
    }
  }
}

public struct ClimbRung: Sendable, Equatable {
  public let index: Int
  public let team: Team
  public let isMe: Bool
  public let isLead: Bool
  /// "+12" / "-4" / "" — points relative to the viewer (or behind the leader).
  public let gap: String
  /// The spoken line the two neighbouring rungs get; nil elsewhere.
  public let voice: ClimbVoice?
  public let badge: String?
  public let accessibility: String
}

/// The line the two rungs NEIGHBOURING the viewer get.
///
/// Written from the point of view of the row it renders INSIDE — which is the
/// whole subtlety. `ClimbView` prints this caption within the neighbour's own
/// rung, so "12 back of Dot Mulligan" appeared on Dot Mulligan's line and read
/// as her being 12 back of herself. The web caught this in the season sim on
/// 2026-08-30 and says "12 ahead of you"; the phone kept the old wording for
/// two months. The gap belongs to the VIEWER, so the sentence must say "you".
public enum ClimbVoice: Sendable, Equatable {
  case levelAbove(stake: String?)                 // on the rung above: "level with you"
  case aheadOfYou(Double, stake: String?)         // on the rung above: "N ahead of you"
  case levelWithYou(String)                       // on the rung below: "NAME level with you"
  case behindYou(String, Double)                  // on the rung below: "NAME, N behind you"
  public var text: String {
    switch self {
    case .levelAbove(let s): "level with you" + (s.map { " — \($0)" } ?? "")
    case .aheadOfYou(let d, let s): "\(CSCopy.points(d)) ahead of you" + (s.map { " — \($0)" } ?? "")
    case .levelWithYou(let n): "\(n) level with you"
    // the comma is load-bearing: the web parts name from number with bold, and
    // a flat run reads "Marcus 10 behind you" as one garbled figure
    case .behindYou(let n, let d): "\(n), \(CSCopy.points(d)) behind you"
    }
  }
}

public enum ClimbMath {
  /// `climbCut(meta)` (4273–4281).
  public static func cut(_ meta: SeasonScenarios.Meta?) -> ClimbCut {
    guard let meta else { return ClimbCut(K: 2, line: "CUT LINE") }
    if meta.finish == "points_table" { return ClimbCut(K: 1, line: "CROWN LINE") }
    if meta.level == "squad" && meta.structure == "squads2" { return ClimbCut(K: 1, line: "TOP SEED · +10") }
    return ClimbCut(K: meta.k ?? 2, line: "CUT LINE")
  }

  public static func ordinal(_ n: Int) -> String { CSCopy.ordinal(n) }

  /// `renderClimb` (4362–4470): the window of rungs, the cut and the ellipses.
  public static func items(teams: [Team], meId: UUID?, scenarios: SeasonScenarios?) -> [ClimbItem] {
    guard !teams.isEmpty else { return [] }
    let cut = cut(scenarios?.meta)
    let K = max(1, cut.K)
    let n = teams.count
    let scById = Dictionary((scenarios?.rows ?? []).map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
    let meIdx = meId.flatMap { id in teams.firstIndex { $0.id == id } } ?? -1
    let me: Team? = meIdx >= 0 ? teams[meIdx] : nil
    var show = Set<Int>([0])
    if K < n { show.insert(K - 1); show.insert(K) } else { show.insert(n - 1) }
    if meIdx >= 0 { show.insert(meIdx - 1); show.insert(meIdx); show.insert(meIdx + 1) }
    let idxs = show.filter { $0 >= 0 && $0 < n }.sorted()
    // QB-16 · **THE LAST SEAT IS NOT THE TOP SEED.**
    //
    // This fell through to "the top seed" for any cut line that is neither a
    // crown line nor a cup line — which at K = 2 means the golfer on rank TWO
    // is captioned the top seed while rank one sits above him with the lead.
    // Two blind readers, a full audit apart, re-read the entire ladder to check
    // they had not misread who was leading: *"Cal isn't the top seed — Wes is.
    // Cal holds the last seat."* The rung is describing the seat the golfer is
    // trying to take, and the seat above the line is the LAST one in.
    let stakeTxt = cut.line == "CROWN LINE" ? "the crown"
                 : cut.line == "CUP LINE" ? "the last cup spot"
                 : "the last seat in the Final"
    var out: [ClimbItem] = []
    var cutDrawn = false
    var prev = -1
    func drawCut() {
      var lb = cut.line
      if let me {
        if meIdx < K {
          let cush = me.pts - (K < n ? teams[K].pts : 0)
          lb = "\(cut.line) · \(CSCopy.points(cush)) CLEAR"
        } else {
          let need = (K - 1 < n ? teams[K - 1].pts : 0) - me.pts
          lb = "\(cut.line) · \(need > 0 ? CSCopy.points(need) + " BACK" : "ON THE LINE")"
        }
      }
      out.append(.cut(label: lb))
      cutDrawn = true
    }
    for i in idxs {
      if prev >= 0 && i > prev + 1 { out.append(.ellipsis(id: "e\(prev)", hidden: i - prev - 1)) }
      if K < n && !cutDrawn && i >= K { drawCut() }
      let t = teams[i]
      let row = scById[t.id]
      let isMe = i == meIdx
      var gap = ""
      var voice: ClimbVoice? = nil
      if let me, i == meIdx - 1 {
        let d = t.pts - me.pts
        let stake = (meIdx >= K && i == K - 1) ? stakeTxt : nil
        voice = d == 0 ? .levelAbove(stake: stake) : .aheadOfYou(d, stake: stake)
      } else if let me, i == meIdx + 1 {
        let d = me.pts - t.pts
        voice = d == 0 ? .levelWithYou(t.name) : .behindYou(t.name, d)
      } else if let me, !isMe {
        let d = t.pts - me.pts
        gap = d > 0 ? "+\(CSCopy.points(d))" : CSCopy.points(d)
      } else if me == nil && i > 0 {
        gap = "-\(CSCopy.points(teams[0].pts - t.pts))"
      }
      var badge: String? = nil
      // D126/D136: "LOCKED" read as locked OUT; a clinched seat is IN.
      if row?.clinched == true { badge = "IN" } else if row?.eliminated == true { badge = "OUT" }
      var al = isMe ? "You — \(ordinal(i + 1)), \(CSCopy.points(t.pts)) points" : "\(ordinal(i + 1)) — \(t.name), \(CSCopy.points(t.pts)) points"
      if let me, !isMe {
        let d = t.pts - me.pts
        al += d == 0 ? ", level with you" : d > 0 ? ", \(CSCopy.points(d)) ahead of you" : ", \(CSCopy.points(-d)) behind you"
      } else if me == nil && i > 0 {
        al += ", \(CSCopy.points(teams[0].pts - t.pts)) behind the leader"
      }
      if row?.clinched == true { al += ", clinched" } else if row?.eliminated == true { al += ", eliminated" }
      out.append(.rung(ClimbRung(index: i, team: t, isMe: isMe, isLead: i == 0, gap: gap, voice: voice, badge: badge, accessibility: al)))
      prev = i
    }
    if prev < n - 1 { out.append(.ellipsis(id: "etail", hidden: n - 1 - prev)) }
    return out
  }

  /// QB-12 · **TURN THE GAP INTO A MOVE.**
  ///
  /// Everywhere the app says "4 back of Cal" it also holds, on the same
  /// device, the five points bands and the golfer's own counting rounds for
  /// the month — and nothing did the multiplication. A blind reader did it
  /// himself, eight taps deep, inside the round composer's HOW POINTS WORK
  /// fold: *"my worst counting round is a 6, so one 'Torched it' swaps a 6 for
  /// a 12 and that's +6 — one great round puts me past Cal. That is a
  /// genuinely motivating fact and I had to derive it."*
  ///
  /// The arithmetic, stated exactly:
  ///
  ///   · with the month's counting slots NOT yet full, a new round ADDS its
  ///     points, so a top-band round is worth the whole 12;
  ///   · with them full, a top-band round BUMPS the worst counter, so it is
  ///     worth 12 minus that round.
  ///
  /// **It renders only when ONE round genuinely closes the gap.** Two rounds
  /// would each bump a successively better counter, so "two rounds closes it"
  /// is arithmetic nobody can stand behind — and a motivating sentence that is
  /// slightly wrong is worse than no sentence (L-01: every number shows its
  /// work). Silence is the honest answer for a gap that big.
  ///
  /// R-K / D256 · THE SUM MOVED, THE SENTENCE DID NOT. The multiplication
  /// above now lives in `RoundWorth.gain` because the plan sheet and Home's
  /// dispatch say what a round is worth out of the same sum; this function
  /// keeps the decision (does ONE round close it) and the words. There is one
  /// copy of the arithmetic on this client and preflight 37 keeps it that way.
  public static func closer(gap: Double, countingPoints: [Double], capN: Int?) -> String? {
    guard gap > 0, gap.isFinite else { return nil }
    guard let gain = RoundWorth.gain(cap: capN, used: countingPoints.count, worst: countingPoints.min()) else { return nil }
    guard gain >= gap else { return nil }
    return "One round in the top band closes it."
  }

  /// `#climbNote` (4471–4475).
  public static func note(teams: [Team], scenarios: SeasonScenarios?) -> String {
    let n = teams.count
    guard n > 0 else { return "" }
    let meta = scenarios?.meta
    let K = max(1, cut(meta).K)
    // D127 · when the roster cannot fill more seats than it has contenders the
    // Final is hollow; say so rather than printing "EVERYONE ADVANCES" as if it
    // were a standing. The web took this fix; the phone announced a race with
    // one runner for two months.
    if K >= n {
      return n <= 1 ? "NOBODY TO RACE YET"
                    : "EVERYONE ADVANCES — \(n) CONTENDER\(n == 1 ? "" : "S"), \(K) SEAT\(K == 1 ? "" : "S")"
    }
    // Q-26: "PROJECTED UNDER A GENEROUS CEILING" was jargon nobody decoded, and
    // it sat over two EMPTY squads on a league that had not teed off.
    if let meta { return "TOP \(K) \(meta.finish == "points_table" ? "— THE POINTS CROWN" : "ADVANCE TO THE CUP FINAL")" }
    return "TOP \(K) ADVANCE TO THE CUP FINAL"
  }
}

// MARK: - The scenario line (D24)

public enum ScenarioPart: Sendable, Equatable {
  case clinch(String)   // "THE FINAL IS SET"
  case text(String)
  case bold(String)
  case out(String)
  public var text: String {
    switch self {
    case .clinch(let s), .text(let s), .bold(let s), .out(let s): s
    }
  }
}

public enum ScenarioLine {
  static func seedWord(_ meta: SeasonScenarios.Meta) -> String {
    if meta.finish == "points_table" { return "THE CROWN" }
    if meta.level == "squad" && meta.structure == "squads2" { return "THE TOP SEED · +10" }
    return "A CUP SEED"
  }

  /// `renderScenarioLine` (14557–14600). Empty = hide. Never invents a clinch.
  public static func parts(_ sc: SeasonScenarios?) -> [ScenarioPart] {
    guard let sc, !sc.rows.isEmpty else { return [] }
    let meta = sc.meta, rows = sc.rows
    let up = { (s: String?) in (s ?? "").uppercased() }
    if meta.locked == true {
      let seeds = rows.prefix(max(0, meta.k ?? 0)).map { up($0.name) }
      return [.clinch("THE FINAL IS SET"), .text(" — \(seeds.joined(separator: " · ")) INTO THE CUP FINAL")]
    }
    if meta.months_left == 0 { return [] }
    let sw = seedWord(meta)
    let capped = (meta.cap ?? 0) > 0 && (meta.cap ?? 999) < 999
    guard let lead = rows.first else { return [] }
    let leadHeadroom = (lead.max_final ?? 0) - (lead.points ?? 0)
    var parts: [ScenarioPart] = []
    if lead.clinched == true {
      // F-5 · §2.3 retires "locked" as this product's verb for a settled
      // fact; check 5 grepped SEEDS LOCKED and this inflection walked past it.
      // "Clinched" is the golf word for the same certainty anyway.
      parts += [.bold(up(lead.name)), .text(" IS IN \(sw)")]
    } else if capped, let needs = lead.needs, needs > 0, needs <= leadHeadroom {
      parts += [.bold(up(lead.name)), .text(" · \(CSCopy.points(needs)) MORE CLINCHES \(sw)")]
    }
    let out = rows.filter { $0.eliminated == true }.map { up($0.name) }
    if !out.isEmpty {
      if !parts.isEmpty { parts.append(.text(" · ")) }
      parts.append(.out("\(out.joined(separator: ", ")) OUT OF THE \(meta.finish == "points_table" ? "RACE" : "SEED RACE")"))
    }
    return parts
  }
}

// MARK: - D71 · the cancellation vote, as an item (IA §7.5)

/// Today a vote to end a season is visible in one place — inside the room —
/// and Home keeps saying "week 7 of 26" while the season is being ended. A
/// vote nobody sees is not consent, so the vote is an ITEM: one eyebrow, one
/// sentence, the two facts that decide it, and the act this viewer actually
/// has. The page renders it at the top; Home's ranker returns the same shape
/// in band 1 when the read reaches it.
///
/// The two facts are the ones a member needs and no others (L-10, L-02):
/// the money comes back, and the rounds stay — all of them. At $0 the Pro
/// ends it alone (D71), so the sentence is a VERDICT and not a vote.
public enum SeasonVote {

  /// What this viewer can do about it right now.
  public enum Act: Sendable, Equatable { case vote, withdraw, wait }

  public struct Item: Sendable, Equatable {
    public let eyebrow: String
    public let headline: String
    public let standfirst: String
    public let tally: String
    public let act: Act
    public init(eyebrow: String, headline: String, standfirst: String, tally: String, act: Act) {
      self.eyebrow = eyebrow; self.headline = headline; self.standfirst = standfirst
      self.tally = tally; self.act = act
    }
  }

  public static func item(_ c: CancelStatus, league: String?, pro: String?) -> Item {
    let name = (league?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? "The season"
    let proName = (pro?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
    let approved = c.approved ?? 0
    let members = c.members ?? 0
    let refund = c.you_refund_cents ?? 0

    let head = c.is_pro == true
      ? "You have asked to end the season."
      : "\(proName ?? "The Pro") has asked to end the season."
        + (members > 0 ? " \(SeasonStoryCopy.cap(SeasonStoryCopy.word(approved))) of \(SeasonStoryCopy.word(members)) "
                       + "\(approved == 1 ? "has" : "have") agreed." : "")

    // R-17 · the CONSEQUENCE first, and unconditionally. The retired
    // `CancelBanner` carried "nobody won"; this rebuilt the standfirst out of
    // the refund and the rounds, so at a $0 stake a member voting on a
    // cancellation was never told the fact that makes the vote consequential.
    var sub = "The season won't be played and nobody won. "
    sub += refund > 0 ? "Your \(PotMath.money(refund)) comes back. " : ""
    sub += "Your rounds stay where they are — all of them."

    let act: Act = c.is_pro == true ? .withdraw : (c.you_approved == true ? .wait : .vote)
    let tally = c.you_approved == true
      ? "You agreed — waiting on the rest (\(approved) of \(members))."
      : "\(approved) of \(members) agreed"

    return Item(eyebrow: "\(name.uppercased()) · A VOTE IS OPEN", headline: head, standfirst: sub,
                tally: tally, act: act)
  }
}
