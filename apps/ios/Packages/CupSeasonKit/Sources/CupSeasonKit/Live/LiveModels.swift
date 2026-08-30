// Cup Season — the live round, as shapes (index.html 7176–7260, 7454–7480,
// 8937–8940; audit 04 §6.1).
//
// `LiveRoundState` is the web's `state.live` + the play-view globals it leaned
// on (LIVE, MTEAMS, PAR, SI, SIEST, CRATE, CSLOPE) folded into one value, so a
// snapshot is the whole round and nothing lives in a global. Scores stay
// 18-wide with the back nine nil on a nine — the server already reads that as
// a 9-hole card; only the LOOPS shrink (D73).

import Foundation

/// `#gameSeg` — Just score · Match play · Wolf · Skins · Sunningdale Rules.
public enum LiveGame: String, Codable, Sendable, CaseIterable, Equatable {
  case score, match, wolf, skins, sunningdale

  /// `p_game` — the server spells stroke play 'none'.
  public var server: String { self == .score ? "none" : rawValue }
  public init(server: String?) {
    guard let server, server != "none" else { self = .score; return }
    self = LiveGame(rawValue: server) ?? .score
  }

  /// The seg button.
  public var segLabel: String {
    switch self {
    case .score: "Just score"
    case .match: "Match play"
    case .wolf: "Wolf"
    case .skins: "Skins"
    case .sunningdale: "Sunningdale Rules"
    }
  }

  /// `#gameNote` (8891–8896).
  public var note: String {
    switch self {
    case .score: "Stroke play — your card, your pace. One to four players; post when you’re done."
    case .match: "Singles (2) or 2v2 net best ball (4). Keep scoring; we tally the match as you go."
    case .wolf: "A round of Wolf — needs four. We run the rotation and the side tally; scores still post."
    case .skins: "Low net takes the hole’s skin; ties carry the pot. Two to four players; scores still post."
    case .sunningdale: "Match play, no handicaps — go 2 down and you get a stroke until you climb out. Singles or 2v2. Win a hole while ahead to bank a unit."
    }
  }

  /// `gl` on the resume banner (7718): Stroke play / Match play / …
  public var banner: String {
    switch self {
    case .score: "Stroke play"
    case .match: "Match play"
    case .wolf: "Wolf"
    case .skins: "Skins"
    case .sunningdale: "Sunningdale Rules"
    }
  }

  /// `GAME_LABEL` on the recap and the settlement card (9200).
  public var recapLabel: String {
    switch self {
    case .score: "THE ROUND"
    case .match: "MATCH PLAY"
    case .wolf: "WOLF"
    case .skins: "SKINS"
    case .sunningdale: "SUNNINGDALE RULES"
    }
  }

  /// Which games carry a stake (8665).
  public var money: Bool { self != .score }

  /// The stake label (8670–8673).
  public var stakeLabel: String {
    switch self {
    case .match: "Stake per side · $0 = bragging rights"
    case .wolf: "Dollars per point · $0 = bragging rights"
    case .sunningdale: "Bank unit · $0 = bragging rights"
    case .skins: "Dollars per skin · $0 = bragging rights"
    case .score: ""
    }
  }

  /// Team-capable games — the court and the mode seg (8724, 8905).
  public var teamable: Bool { self == .match || self == .sunningdale }

  /// Tee-off validation (8903–8912): the constraint, or nil when the count works.
  public func teeOffProblem(players n: Int) -> String? {
    switch self {
    case .score: n < 1 ? "Pick at least yourself" : nil
    case .match: (n != 2 && n != 4) ? "Match play takes 2 (singles) or 4 (2v2)" : nil
    case .sunningdale: (n != 2 && n != 4) ? "Sunningdale Rules takes 2 (singles) or 4 (2v2)" : nil
    case .skins: (n < 2 || n > 4) ? "Skins takes 2 to 4 players" : nil
    case .wolf: n != 4 ? "Wolf needs exactly 4" : nil
    }
  }
}

/// D75: 2v2 teams, or everyone for themselves.
public enum LiveMode: String, Codable, Sendable, Equatable { case teams, solo }

/// One seat on the sheet — a `ROSTER` / `LIVE` entry (7207, 7392–7405).
public struct LivePlayer: Codable, Sendable, Equatable, Identifiable {
  public var id: String
  /// display name
  public var n: String
  /// index (signed; negative = plus handicap)
  public var i: Double
  /// squad colour index; −1 for a guest
  public var ci: Int
  public var guest: Bool
  /// index is estimated (blank guest index, or an unestablished member)
  public var est: Bool
  /// a guest picked from the app (a known golfer) — wears B, not G
  public var buddy: Bool
  /// league_members.id
  public var mid: UUID?
  /// profiles.id
  public var pid: UUID?
  public var me: Bool
  public var locked: Bool
  public var team: String?

  public init(id: String = UUID().uuidString, n: String, i: Double, ci: Int, guest: Bool, est: Bool = false, buddy: Bool = false,
              mid: UUID? = nil, pid: UUID? = nil, me: Bool = false, locked: Bool = false, team: String? = nil) {
    self.id = id; self.n = n; self.i = i; self.ci = ci; self.guest = guest; self.est = est; self.buddy = buddy
    self.mid = mid; self.pid = pid; self.me = me; self.locked = locked; self.team = team
  }

  /// `fn1` (5598): the first name, or 'Someone'.
  public var first: String { LiveFmt.fn1(n) }
}

/// A wolf's call on a hole: `{mode:'partner', partner}` or `{mode:'lone'}`.
public struct LiveWolfPick: Codable, Sendable, Equatable {
  public var mode: String
  public var partner: Int?
  public init(mode: String, partner: Int? = nil) { self.mode = mode; self.partner = partner }
  public static let lone = LiveWolfPick(mode: "lone")
  public static func partner(_ p: Int) -> LiveWolfPick { LiveWolfPick(mode: "partner", partner: p) }
  public var isLone: Bool { mode == "lone" }

  public var json: JSONValue {
    var o: [String: JSONValue] = ["mode": .string(mode)]
    if let partner { o["partner"] = .number(Double(partner)) }
    return .object(o)
  }
  public init?(_ v: JSONValue?) {
    guard let v, case .object = v, let m = v["mode"]?.string else { return nil }
    self.init(mode: m, partner: v["partner"]?.int)
  }
}

/// The course card the round plays on — PAR · SI · SIEST · CRATE · CSLOPE and
/// the picked course/tee (7176–7197; the snapshot's `course` at 7456).
public struct LiveCourseCard: Codable, Sendable, Equatable {
  public var label: String
  public var tee: String
  public var rating: Double?
  public var slope: Int?
  /// 18 pars; a nine keeps the template on the back.
  public var pars: [Int]
  /// 18 stroke indexes, ranked 1..H over the holes in play.
  public var si: [Int]
  /// The SI is estimated from pars — flagged EST everywhere strokes show.
  public var siEst: Bool
  /// The raw 18 SI from the course DB, for a 9/18 re-rank (7192).
  public var siLoaded: [Int]?
  /// Which course the pars came from (7193).
  public var parsCourse: String?
  public var courseId: String?
  /// `#cardNote` — set by the loader or "Save the card"; nil = the standard line.
  public var note: String?

  /// The template card (7176) with an estimated index — a real account never
  /// inherits the demo course's stroke index (7415).
  public static let standardPars = [4, 4, 3, 5, 4, 4, 3, 4, 5, 4, 3, 4, 5, 4, 4, 3, 4, 5]
  /// `POST_PAR_STD` (6114) — the par-72 template a NEW course starts from.
  public static let postParStd = [4, 4, 4, 3, 5, 4, 3, 4, 5, 4, 4, 3, 4, 5, 4, 3, 4, 5]
  public static let standardNote = "Standard par-72 card. The stepper opens on each hole's par — pick your course above and the real pars load."

  public init(label: String = "", tee: String = "", rating: Double? = nil, slope: Int? = nil,
              pars: [Int] = LiveCourseCard.standardPars, si: [Int]? = nil, siEst: Bool = true, siLoaded: [Int]? = nil,
              parsCourse: String? = nil, courseId: String? = nil, note: String? = nil) {
    self.label = label; self.tee = tee; self.rating = rating; self.slope = slope
    self.pars = pars.count == 18 ? pars : LiveCourseCard.standardPars
    self.si = si ?? LiveCourseCard.estimateSI(pars: self.pars, holes: 18)
    self.siEst = si == nil ? true : siEst
    self.siLoaded = siLoaded; self.parsCourse = parsCourse; self.courseId = courseId; self.note = note
  }

  /// `syncTeeInputs` (8880): blank → 72 / 113.
  public var effectiveRating: Double { rating ?? 72 }
  public var effectiveSlope: Int { slope ?? 113 }

  /// `estimateSI(n)` (7199): hardest-par-first over the holes in play, then hole order.
  public static func estimateSI(pars: [Int], holes: Int) -> [Int] {
    let n = holes == 9 ? 9 : 18
    let order = (0..<n).sorted { a, b in pars[b] != pars[a] ? pars[a] > pars[b] : a < b }
    var si = Array(repeating: 18, count: 18)
    for (rank, h) in order.enumerated() { si[h] = rank + 1 }
    return si
  }

  public mutating func estimate(holes: Int) {
    si = LiveCourseCard.estimateSI(pars: pars, holes: holes)
    siEst = true
  }

  /// A stroke index re-ranked 1..n over `raw` (6925, 6951).
  static func rerank(_ raw: [Int]) -> [Int] {
    let order = raw.indices.sorted { raw[$0] < raw[$1] }
    var out = Array(repeating: 18, count: 18)
    for (rank, idx) in order.enumerated() { out[idx] = rank + 1 }
    return out
  }

  /// `reindexSIForHoles` (6947): a nine re-ranks its front nine 1..9 from the
  /// loaded card; eighteen restores the full card; no card → estimate.
  public mutating func reindex(holes n: Int) {
    if n == 9 {
      let src = Array((siLoaded?.isEmpty == false ? siLoaded! : si).prefix(9))
      if src.count == 9, src.allSatisfy({ $0 >= 1 }) { si = LiveCourseCard.rerank(src); siEst = false }
      else { estimate(holes: 9) }
    } else {
      if let l = siLoaded, l.count == 18, l.allSatisfy({ $0 >= 1 && $0 <= 18 }) { si = l; siEst = false }
      else { estimate(holes: 18) }
    }
  }

  /// The tee-pick loader's card write (6918–6934): the rows from the course DB.
  /// Returns false when the card was left alone (the typed path stands).
  @discardableResult
  public mutating func load(holes rows: [(par: Int, handicap: Int)], playing: Int) -> Bool {
    guard !rows.isEmpty else { return false }
    siLoaded = rows.map(\.handicap)
    if playing == 9 {
      let nine = Array(rows.prefix(9))
      pars = nine.map { $0.par > 0 ? $0.par : 4 } + Array(pars[nine.count..<18])
      let raw = nine.map(\.handicap)
      if nine.count == 9, raw.allSatisfy({ $0 >= 1 }) { si = LiveCourseCard.rerank(raw); siEst = false }
      else { estimate(holes: 9) }
    } else {
      guard rows.count == 18 else { return false }
      pars = rows.map { $0.par > 0 ? $0.par : 4 }
      let s = rows.map(\.handicap)
      if s.allSatisfy({ $0 >= 1 && $0 <= 18 }) { si = s; siEst = false } else { estimate(holes: 18) }
    }
    note = "Card loaded: \(playing == 9 ? "9-hole" : "18-hole") pars and stroke index from the course database."
    return true
  }

  /// "Save the card" (9570–9577): pars only, estimated index, ranked over the nine or the eighteen.
  public mutating func save(front: [Int], back: [Int]?, nine: Bool) {
    pars = nine ? front + Array(pars[9..<18]) : front + (back ?? Array(pars[9..<18]))
    estimate(holes: nine ? 9 : 18)
    siLoaded = nil
    let total = front.reduce(0, +) + (nine ? 0 : (back ?? []).reduce(0, +))
    note = "Card saved: par \(total)\(nine ? " · 9 holes" : ""). The stepper opens on each hole's par."
  }

  /// The snapshot shipped at tee-off (8965–8968).
  public func snapshot(holes: Int, rating9: Bool) -> JSONValue {
    var o: [String: JSONValue] = [:]
    o["rating"] = rating.map { .number($0) } ?? .null
    o["slope"] = slope.map { .number(Double($0)) } ?? .null
    // D73: a nine carries a real nine_rating — the tee's own, or half the 18-hole rating
    if holes == 9, let r = rating { o["nine_rating"] = .number(rating9 ? r : r / 2) } else { o["nine_rating"] = .null }
    o["holes"] = .number(Double(holes))
    o["pars"] = .array(pars.map { .number(Double($0)) })
    o["si"] = .array(si.map { .number(Double($0)) })
    o["label"] = .string(label.trimmingCharacters(in: .whitespaces))
    o["tee"] = .string(tee.trimmingCharacters(in: .whitespaces))
    return .object(o)
  }

  /// From a server `course_snapshot` (7519–7527, 7900–7906).
  public static func from(snapshot snap: JSONValue?, courseLabel: String?, siEstimated: Bool) -> LiveCourseCard {
    var c = LiveCourseCard()
    let pars = snap?["pars"]?.array?.compactMap { $0.int ?? $0.string.flatMap(Int.init) }
    if let pars, pars.count == 18 { c.pars = pars }
    let si = snap?["si"]?.array?.compactMap { $0.int ?? $0.string.flatMap(Int.init) }
    if let si, si.count == 18 { c.si = si; c.siEst = siEstimated } else { c.estimate(holes: snap?["holes"]?.int == 9 ? 9 : 18) }
    if let r = snap?["rating"]?.double ?? snap?["rating"]?.string.flatMap(Double.init), r != 0 { c.rating = r }
    if let s = snap?["slope"]?.int ?? snap?["slope"]?.string.flatMap(Int.init), s != 0 { c.slope = s }
    c.label = snap?["label"]?.string ?? courseLabel ?? ""
    c.tee = snap?["tee"]?.string ?? ""
    return c
  }

  /// The live eyebrow (8388–8391): "Live round · Papago · Blue · 70.2/123",
  /// never "BLUE — BLUE" when the label already ends in the tee (S6-04).
  public var eyebrow: String {
    let c = label.isEmpty ? "Course" : label
    let t = tee.trimmingCharacters(in: .whitespaces)
    let dup = !t.isEmpty && c.lowercased().hasSuffix(("· " + t).lowercased())
    return "Live round · \(c)\(!t.isEmpty && !dup ? " — \(t)" : "") · \(LiveFmt.js(effectiveRating))/\(effectiveSlope)"
  }
}

/// The guest pencil's identity (`state.liveGuest`, 7920).
public struct LiveGuestContext: Sendable, Equatable {
  public let token: UUID
  public let me: UUID?
  public let signedIn: Bool
  public init(token: UUID, me: UUID?, signedIn: Bool) { self.token = token; self.me = me; self.signedIn = signedIn }
}

/// `state.live` (8937) + the globals, as one value. Codable = the `cs.live.<lr>`
/// snapshot (7454–7466), so a kill resumes the round with no network.
public struct LiveRoundState: Codable, Sendable, Equatable {
  public enum Stage: String, Codable, Sendable { case setup, live }
  public var stage: Stage
  public var active: Bool
  public var game: LiveGame
  public var stake: Double
  public var wolfOrder: [Int]?
  public var holes: Int
  public var rating9: Bool
  public var pairing: Int
  public var mode: LiveMode
  public var hole: Int
  public var scores: [[Int?]]
  public var wolf: [LiveWolfPick?]
  /// per-cell write clocks, ms (D85)
  public var scts: [[Int64]]
  public var wcts: [Int64]
  /// the channel key (join_code)
  public var code: String?
  public var lr: UUID?
  public var leagueId: UUID?
  /// live_round_players.id per seat
  public var pmap: [UUID]?
  /// position → claim token, for the guests
  public var guestTokens: [String: UUID]
  /// D86: I teed it off (resume face) vs someone put me on it (invite face)
  public var mine: Bool
  public var host: String?
  /// D88: a round in a league I'm not in — I score, I don't end it
  public var visitor: Bool
  /// LIVE
  public var players: [LivePlayer]
  /// MTEAMS
  public var teams: [[Int]]
  public var course: LiveCourseCard
  public var ts: Int64

  /// `freshLive()` (7241).
  public static func fresh(players: [LivePlayer] = [], course: LiveCourseCard = LiveCourseCard()) -> LiveRoundState {
    LiveRoundState(stage: .setup, active: false, game: .score, stake: 0, wolfOrder: nil, holes: 18, rating9: false, pairing: 0, mode: .teams,
                   hole: 0, scores: players.map { _ in Array(repeating: nil, count: 18) }, wolf: Array(repeating: nil, count: 18),
                   scts: players.map { _ in Array(repeating: 0, count: 18) }, wcts: Array(repeating: 0, count: 18),
                   code: nil, lr: nil, leagueId: nil, pmap: nil, guestTokens: [:], mine: true, host: nil, visitor: false,
                   players: players, teams: LiveRoundState.defaultTeams(count: players.count), course: course, ts: 0)
  }

  public init(stage: Stage, active: Bool, game: LiveGame, stake: Double, wolfOrder: [Int]?, holes: Int, rating9: Bool, pairing: Int, mode: LiveMode,
              hole: Int, scores: [[Int?]], wolf: [LiveWolfPick?], scts: [[Int64]], wcts: [Int64], code: String?, lr: UUID?, leagueId: UUID?,
              pmap: [UUID]?, guestTokens: [String: UUID], mine: Bool, host: String?, visitor: Bool, players: [LivePlayer], teams: [[Int]],
              course: LiveCourseCard, ts: Int64) {
    self.stage = stage; self.active = active; self.game = game; self.stake = stake; self.wolfOrder = wolfOrder; self.holes = holes
    self.rating9 = rating9; self.pairing = pairing; self.mode = mode; self.hole = hole; self.scores = scores; self.wolf = wolf
    self.scts = scts; self.wcts = wcts; self.code = code; self.lr = lr; self.leagueId = leagueId; self.pmap = pmap
    self.guestTokens = guestTokens; self.mine = mine; self.host = host; self.visitor = visitor; self.players = players
    self.teams = teams; self.course = course; self.ts = ts
  }

  /// `setMatchTeams` (7217).
  public static func defaultTeams(count: Int) -> [[Int]] { count == 2 ? [[0], [1]] : [[0, 1], [2, 3]] }

  /// `liveHoles()` (7198).
  public var liveHoles: Int { holes == 9 ? 9 : 18 }
  /// `liveSolo()` (7247).
  public var solo: Bool { mode == .solo }

  // MARK: strokes (7221–7236)

  /// `CHS` — `Math.round(i × slope ÷ 113)`, halved for a nine (D73).
  public var courseHandicaps: [Int] {
    LiveEngines.courseHandicaps(indices: players.map(\.i), slope: course.effectiveSlope, nine: liveHoles == 9)
  }
  public var lowCH: Int { courseHandicaps.min() ?? 0 }
  /// `STROKES` — off the low man.
  public var strokes: [Int] { LiveEngines.strokesOffLow(courseHandicaps) }
  /// `strokeOn(pi,h)` for every seat and hole.
  public var strokeTable: [[Int]] { LiveEngines.strokeTable(strokes: strokes, si: course.si, holes: liveHoles) }
  public func strokeOn(_ pi: Int, _ h: Int) -> Int {
    let s = strokes
    guard pi < s.count else { return 0 }
    return LiveEngines.strokeOn(stk: s[pi], si: course.si, h: h, holes: liveHoles)
  }
  public func holeDone(_ h: Int) -> Bool { LiveEngines.holeDone(scores, h) }
  /// D153 · has anyone put a single number on this card yet? Gates the
  /// first-round teaching copy, which is an explanation, not a running label.
  public var anyScored: Bool { scores.contains { $0.contains { $0 != nil } } }
  /// `thru` — holes every player has finished, counted from the first (7716).
  public var thru: Int {
    var t = 0
    for k in 0..<18 { if holeDone(k) { t = k + 1 } else { break } }
    return t
  }
  /// `firstOpen` (7934): the first hole still being played.
  public var firstOpenHole: Int {
    for k in 0..<liveHoles where !holeDone(k) { return k }
    return 0
  }

  /// `ensureSyncTs` (7742).
  public mutating func ensureClocks() {
    if scts.count != players.count { scts = players.map { _ in Array(repeating: 0, count: 18) } }
    if wcts.count != 18 { wcts = Array(repeating: 0, count: 18) }
  }

  /// A seat's own row (the guest's `me`).
  public var meIndex: Int? { players.firstIndex(where: \.me) }
}

/// Number and name helpers the copy leans on.
public enum LiveFmt {
  /// `fn1` (5598): first word, or 'Someone'.
  public static func fn1(_ n: String?) -> String {
    let w = (n ?? "").trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ", omittingEmptySubsequences: true).first
    return w.map(String.init) ?? "Someone"
  }
  /// `fmtIdx` (7181): "+1.7" for a plus handicap, "12.4" otherwise.
  public static func idx(_ v: Double) -> String {
    guard v.isFinite else { return "—" }
    return v < 0 ? "+" + String(format: "%.1f", abs(v)) : String(format: "%.1f", v)
  }
  /// A JS number in a template string: 5 → "5", 2.5 → "2.5".
  public static func js(_ v: Double) -> String {
    if v == v.rounded(), abs(v) < 1e15 { return String(Int(v)) }
    var s = String(v)
    if s.hasSuffix(".0") { s.removeLast(2) }
    return s
  }
  /// `_sbPm` (8592): a signed figure.
  public static func pm(_ v: Int) -> String { (v > 0 ? "+" : "") + String(v) }
  /// ms since the epoch — the write clock (`Date.now()`).
  public static func now() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000) }
}
