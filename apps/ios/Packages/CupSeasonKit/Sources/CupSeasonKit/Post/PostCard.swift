// Cup Season — the quick-post card as a value (index.html `state.post` 6119,
// `postInputs` 6121, `recalc` 6163–6208, the submit payload 6350–6366, the
// pars sheet 6272–6323, the even-par guard 6325–6337, `scanApply` 6632).
//
// Everything here is a PREVIEW or a payload. The server scores the round:
// `score_round()` computes the differential, `v_rounds_ranked` applies the
// league's allowance and `cup_points()`. The phone previews at 100% with the
// golfer's own number (landmine 7.3 — the web does the same) and says so.

import Foundation

/// D32: front & back is the default; the hole-by-hole grid is the opt-in card
/// (and the scan's confirmation surface, D36).
public enum PostMode: String, Codable, Sendable { case total, holes }

/// What a scan left behind on the card: the cells the model read (0 = unread)
/// and the other rows on the same card (partner claims after the post).
public struct PostScanContext: Codable, Sendable, Equatable {
  public var read: [Int]
  public var others: [PostScanPlayer]
  public init(read: [Int], others: [PostScanPlayer]) { self.read = read; self.others = others }
}

public struct PostCard: Codable, Sendable, Equatable {
  /// `POST_PAR_STD` (6114) — the par-72 template every card starts on.
  public static let parStd: [Int] = [4, 4, 4, 3, 5, 4, 3, 4, 5, 4, 4, 3, 4, 5, 4, 3, 4, 5]

  public var mode: PostMode = .total
  public var side: Int = 18
  public var pars: [Int] = PostCard.parStd
  public var scores: [Int] = PostCard.parStd
  /// F2: interaction with the grid, not scores ≠ pars — a legit dial-to-par counts.
  public var touched = false
  /// D72: the rating field already holds a 9-hole rating (a real 9-hole tee) — recalc must NOT halve it.
  public var rating9 = false
  /// The course whose pars the grid wears; a NEW course never inherits the last one's card (6871).
  public var parsCourse: String?
  public var scan: PostScanContext?

  // the typed inputs, as typed (`#inF9` … `#inDate`)
  public var f9 = ""
  public var b9 = ""
  public var rating = ""
  public var slope = ""
  public var course = ""
  public var courseId: String?
  /// YYYY-MM-DD; nil = the server's `current_date`.
  public var date: String?

  public init() {}

  // MARK: - `postInputs()` (6121)

  /// One source for f9/b9 — from the grid in holes mode, from the two boxes in
  /// total mode — so scoring never disagrees with entry.
  public var inputs: (f9: Int, b9: Int) {
    if mode == .holes {
      func sum(_ r: Range<Int>) -> Int { r.reduce(0) { $0 + max(0, scores.indices.contains($1) ? scores[$1] : 0) } }
      return side == 9 ? (sum(0..<9), 0) : (sum(0..<9), sum(9..<18))
    }
    let f = Self.num(f9), b = Self.num(b9)
    // D72: a 9-hole post ignores the back-nine box even if it carries a stale value
    return side == 9 ? (f > 0 ? f : b, 0) : (f, b)
  }

  public var ratingValue: Double { Self.dbl(rating) }
  public var slopeValue: Int { Self.num(slope) }

  /// `parseFloat(v)||0` on an integer box.
  static func num(_ s: String) -> Int { Int(dbl(s).rounded(.towardZero)) }
  /// `parseFloat(v)||0`.
  static func dbl(_ s: String) -> Double {
    let t = s.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
    guard let v = Double(t), v.isFinite else { return 0 }
    return v
  }

  /// Nothing typed and the grid untouched — the draft has nothing to keep.
  public var isBlank: Bool {
    [f9, b9, rating, slope, course].allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty } && date == nil && !touched
  }

  // MARK: - the grid (`renderPostHoles` 6131)

  public enum HoleResult: Sendable { case eagle, birdie, par, bogey }

  /// `eag` ≤ par−2 · `bird` < par · `bog` > par.
  public func result(at i: Int) -> HoleResult {
    let par = pars[i], sc = scores[i]
    if sc <= par - 2 { return .eagle }
    if sc < par { return .birdie }
    if sc > par { return .bogey }
    return .par
  }

  /// `data-php`: +1, capped at 15; a zero cell starts from par.
  public mutating func plus(_ i: Int) {
    scores[i] = min(15, (scores[i] > 0 ? scores[i] : pars[i]) + 1); touched = true
  }
  /// `data-phm`: −1, floored at 1.
  public mutating func minus(_ i: Int) {
    scores[i] = max(1, (scores[i] > 0 ? scores[i] : pars[i]) - 1); touched = true
  }

  /// Holes the grid shows: 0..<9 always; 9..<18 for 18.
  public var holeIndices: Range<Int> { 0..<(side == 9 ? 9 : 18) }

  // MARK: - the ways out (6700–6720)

  /// `resetPostComposer`: the whole composer back to blank (pars stay).
  public mutating func startOver() {
    f9 = ""; b9 = ""; rating = ""; slope = ""; course = ""; courseId = nil; date = nil
    mode = .total; scores = pars; touched = false; scan = nil
  }

  /// `#postScanBack`: just the model's numbers go; course/date/photo stay.
  public mutating func scrapScan() {
    mode = .total; scores = pars; touched = false; scan = nil
  }

  /// After a post (6444–6458): everything fresh, 18 holes, the par-72 card.
  public mutating func clearAfterPost() {
    startOver()
    side = 18; rating9 = false; pars = Self.parStd; parsCourse = nil; scores = Self.parStd
  }

  // MARK: - the even-par guard (F2, 6325)

  /// Holes mode with an untouched grid — a rushed Post would bank an accidental even par.
  public var needsEvenParGuard: Bool { mode == .holes && !touched }
  /// "…this would post an even-par 72"
  public var evenParTotal: Int { pars.prefix(side).reduce(0, +) }

  // MARK: - a tee pick (`onTee`, 6863–6902)

  /// The synchronous half of `onTee`: the holes choice and the rating
  /// convention come straight off the picked tee; a course CHANGE resets the
  /// card to the template so the real pars overlay it when the cache answers.
  public mutating func teePicked(courseId: String, label: String, rating: Double, slope: Int, nineHoleTee: Bool) {
    course = label
    self.courseId = courseId
    self.rating = CSCopy.points(rating)   // the tee's rating as the web sets it: "71.2", "70"
    self.slope = String(slope)
    side = nineHoleTee ? 9 : 18
    rating9 = nineHoleTee
    if parsCourse != courseId {
      pars = Self.parStd; scores = Self.parStd; parsCourse = courseId
    }
  }

  /// Real pars into the grid (setup, never flips `touched`): a 9-hole tee
  /// fills the front nine, an 18-hole tee fills all eighteen (6890–6896).
  public mutating func loadPars(_ loaded: [Int], nineHoleTee: Bool) {
    let p = loaded.map { $0 > 0 ? $0 : 4 }
    if nineHoleTee {
      guard p.count >= 9 else { return }
      pars = Array(p.prefix(9)) + Array(Self.parStd[9..<18])
    } else {
      guard p.count == 18 else { return }
      pars = p
    }
    scores = pars
  }

  /// A course memory chip (`loadCourseMemory` 14106): course, rating, slope.
  public mutating func fill(memory m: PostCourseMemory) {
    course = m.label; courseId = nil
    rating = m.ratingText; slope = String(m.slope)
  }
}

// MARK: - the preview (`recalc`, 6163–6208)

public struct PostPreview: Sendable, Equatable {
  public let gross: Int
  public let holes: Int
  public let vs: Double
  public let points: Int
  public let message: String
  /// `state.lastPost.label`: "84 GROSS" / "41 GROSS · 9 HOLES"
  public let label: String
  /// `#postGrossLine`: "Gross 84 · 18 holes" / "Gross 41 · 9 holes · half value"
  public var grossLine: String { "Gross \(gross) · " + (holes == 9 ? "9 holes · half value" : "18 holes") }
  /// `#calcVs`: "+2.4" / "-1.3"
  public var vsText: String { (vs >= 0 ? "+" : "") + RoundCopy.f1(vs) }
}

public enum PostCalc {
  /// The empty state's copy — the markup's line, then `recalc`'s once something was typed.
  public static let emptyMessage = "Enter at least one nine to see the points."
  public static let emptyMessageAfterTyping = "Enter at least one nine."
  public static let emptyGrossLine = "Enter your card to see the score."
  /// `state.myIndex`'s fallback for a golfer with no number yet (14872).
  public static let fallbackIndex = 18.0

  /// `recalc()` at 100% allowance against `myIndex`. nil = nothing to score.
  /// Points follow the server rule (`CSBands.cupPoints`) so the preview never
  /// disagrees with what lands; the sentence is the web's.
  public static func preview(_ card: PostCard, myIndex: Double?) -> PostPreview? {
    let idx = myIndex ?? fallbackIndex
    let rating = card.ratingValue
    let slope = card.slopeValue > 0 ? Double(card.slopeValue) : 113
    let (f9, b9) = card.inputs
    if f9 > 0 && b9 > 0 {
      let gross = f9 + b9
      let diff = (Double(gross) - rating) * 113 / slope
      let vs = idx - diff
      let (pts, msg) = CSBands.pointsFor(vs)
      return PostPreview(gross: gross, holes: 18, vs: vs, points: pts, message: msg, label: "\(gross) GROSS")
    }
    if f9 > 0 || b9 > 0 {
      let g9 = f9 > 0 ? f9 : b9
      // D72: (nine gross − 9-hole rating) scaled, doubled to an 18-hole equivalent
      let rating9 = card.rating9 ? rating : rating / 2
      let diff = ((Double(g9) - rating9) * 113 / slope) * 2
      let vs = idx - diff
      let base = CSBands.pointsFor(vs)
      let pts = Int((Double(base.points) / 2).rounded(.up))
      return PostPreview(gross: g9, holes: 9, vs: vs, points: pts, message: "9-hole round, half value. " + base.line, label: "\(g9) GROSS · 9 HOLES")
    }
    return nil
  }

  /// The ceremony's display gate (6055): |vs| > 30 means we don't really have a number.
  public static func vsIsSane(_ vs: Double?) -> Bool {
    guard let vs, vs.isFinite else { return false }
    return abs(vs) <= 30
  }
}

// MARK: - the payload (6350–6366)

/// The `rounds` row the client inserts — column for column. Optionals encode
/// as ABSENT (never `null`), which is what the server defaults need
/// (`played_on` → current_date). `course_label` is NOT NULL on the table; the
/// web sends null and fails at the DB — the phone is honest about that too.
public struct PostPayload: Encodable, Sendable, Equatable {
  public var gross: Int
  public var rating: Double
  public var nine_rating: Double?
  public var slope: Int
  public var holes_played: Int
  public var source = "quick"
  public var played_on: String?
  public var course_label: String?
  public var api_course_id: String?
  public var season_id: UUID?
  public var photo_path: String?

  public static func build(_ card: PostCard, seasonId: UUID?) -> PostPayload {
    let (f9, b9) = card.inputs
    let rating = card.ratingValue
    let nine = !(f9 > 0 && b9 > 0)
    let label = card.course.trimmingCharacters(in: .whitespaces)
    return PostPayload(
      gross: nine ? (f9 > 0 ? f9 : b9) : f9 + b9,
      rating: rating,
      // D72: the ACTUAL 9-hole rating the server scores against — a real 9-hole
      // tee sends it straight; an 18-hole course played as a nine sends half
      nine_rating: nine ? (card.rating9 ? rating : rating / 2) : nil,
      slope: card.slopeValue,
      holes_played: nine ? 9 : 18,
      played_on: card.date,
      course_label: label.isEmpty ? nil : label,
      api_course_id: card.courseId,
      season_id: seasonId)
  }

  /// `round_holes` rows for a hole-by-hole card (6396–6401): the first N holes with strokes > 0.
  public static func holeRows(_ card: PostCard, roundId: UUID) -> [PostHoleRow] {
    guard card.mode == .holes else { return [] }
    let (f9, b9) = card.inputs
    let n = (f9 > 0 && b9 > 0) ? 18 : 9
    return (0..<n).compactMap { i in card.scores[i] > 0 ? PostHoleRow(round_id: roundId, hole_number: i + 1, strokes: card.scores[i]) : nil }
  }
}

public struct PostHoleRow: Encodable, Sendable, Equatable {
  public let round_id: UUID
  public let hole_number: Int
  public let strokes: Int
}

// MARK: - the pars sheet (`openPostParsSheet`, 6272–6323)

public enum PostPars {
  /// Keystroke filter: digits 3–6 only, nine at most.
  public static func clean(_ s: String) -> String { String(s.filter { ("3"..."6").contains($0) }.prefix(9)) }
  /// `validSide`: exactly nine digits, each 3–6.
  public static func validSide(_ s: String) -> Bool { s.count == 9 && s.allSatisfy { ("3"..."6").contains($0) } }
  /// `sumStr`
  public static func sum(_ s: String) -> Int { s.compactMap { Int(String($0)) }.reduce(0, +) }

  public static let rejectToast = "Nine digits a side, 3 through 6"
  public static let setToast = "Pars set — adjust the holes you didn’t par"

  /// The 18 pars a valid entry produces; on a nine, the back keeps the card's pars.
  public static func parse(front: String, back: String, nine: Bool, current: [Int]) -> [Int]? {
    guard validSide(front), nine || validSide(back) else { return nil }
    let f = front.compactMap { Int(String($0)) }
    let b = nine ? Array(current[9..<18]) : back.compactMap { Int(String($0)) }
    return f + b
  }
}

// MARK: - course memory (`loadCourseMemory`, 14092)

public struct PostCourseMemory: Sendable, Equatable, Identifiable {
  public let label: String
  public let rating: Double
  public let slope: Int
  public var id: String { label }
  public init(label: String, rating: Double, slope: Int) { self.label = label; self.rating = rating; self.slope = slope }
  /// The chip: "Papago · 71.2/128"
  public var chip: String { "\(label) · \(ratingText)/\(slope)" }
  /// A numeric as the web prints it raw: "71.2", "70".
  public var ratingText: String { CSCopy.points(rating) }
  public static let filledToast = "Course filled: just the gross and the date"
}

// MARK: - the draft (`savePostDraft` / `restorePostDraft`, 6217–6270)

/// The typed card, mirrored so an app kill mid-entry never loses a round.
/// 24-hour TTL. The photo does not survive — the numbers are the point.
public struct PostDraft: Codable, Sendable, Equatable {
  public static let key = "cs_post_draft"
  public static let ttl: TimeInterval = 24 * 3600
  public static let restoredToast = "Your unposted round came back — it’s waiting in Post a round"

  public var at: Date
  public var card: PostCard

  public init(at: Date = Date(), card: PostCard) { self.at = at; self.card = card }

  public func isFresh(now: Date = Date()) -> Bool { now.timeIntervalSince(at) <= Self.ttl }

  public static func encode(_ d: PostDraft) -> Data? { try? JSONEncoder().encode(d) }
  /// nil when absent, unreadable, or older than the TTL.
  public static func decode(_ data: Data?, now: Date = Date()) -> PostDraft? {
    guard let data, let d = try? JSONDecoder().decode(PostDraft.self, from: data), d.isFresh(now: now) else { return nil }
    guard d.card.pars.count == 18, d.card.scores.count == 18 else { return nil }
    return d
  }
}

// MARK: - the scan (`scanPickRow` / `scanApply`, 6620–6657)

public struct PostScanPlayer: Codable, Sendable, Equatable {
  public var name: String?
  public var holes: [Int]      // 18 cells; 0 = unread
  public var total: Int?
  public var holes_read: Int
  public init(name: String?, holes: [Int], total: Int?, holes_read: Int) {
    self.name = name; self.holes = holes; self.total = total; self.holes_read = holes_read
  }
  /// "Player 2" when the model read no name.
  public func label(_ i: Int) -> String { (name ?? "").isEmpty ? "Player \(i + 1)" : name! }
  /// A partner row worth a claim (6659): something read, or a plausible total.
  public var claimable: Bool { holes_read > 0 || (total ?? 0) >= 18 }
}

public struct PostScan: Sendable, Equatable, Identifiable {
  /// One sheet per read: the card's rows, joined.
  public var id: String { players.map { "\($0.name ?? "")·\($0.total ?? 0)·\($0.holes_read)" }.joined(separator: "|") }
  public var courseName: String?
  public var date: String?
  public var parRow: [Int]
  public var players: [PostScanPlayer]
  public init(courseName: String?, date: String?, parRow: [Int], players: [PostScanPlayer]) {
    self.courseName = courseName; self.date = date; self.parRow = parRow; self.players = players
  }

  /// The function's `{ok, scan}` payload → a scan; nil when there is nothing to apply.
  public init?(json: JSONValue) {
    guard let s = json["scan"] else { return nil }
    func ints(_ v: JSONValue?, count: Int) -> [Int] {
      var out = (v?.array ?? []).map { $0.int ?? 0 }
      if out.count < count { out += Array(repeating: 0, count: count - out.count) }
      return Array(out.prefix(count))
    }
    let players = (s["players"]?.array ?? []).map { p in
      PostScanPlayer(name: p["name"]?.string, holes: ints(p["holes"], count: 18), total: p["total"]?.int, holes_read: p["holes_read"]?.int ?? 0)
    }
    guard !players.isEmpty else { return nil }
    self.init(courseName: s["course_name"]?.string, date: s["date"]?.string, parRow: ints(s["par_row"], count: 18), players: players)
  }

  /// `scanApply(scan, idx)`: the grid comes back as the confirm surface.
  /// Returns the holes the model could not make out (they sit on par).
  @discardableResult
  public func apply(row idx: Int, to card: inout PostCard) -> Int {
    let me = players[idx]
    card.side = me.holes.dropFirst(9).contains { $0 > 0 } ? 18 : 9
    if parRow.filter({ (3...6).contains($0) }).count >= 9 {
      card.pars = parRow.enumerated().map { i, v in (3...6).contains(v) ? v : (card.pars[i] > 0 ? card.pars[i] : 4) }
    }
    card.mode = .holes
    card.scores = me.holes.enumerated().map { i, v in v > 0 ? v : card.pars[i] }
    card.touched = true
    card.scan = PostScanContext(read: me.holes, others: players.enumerated().filter { $0.offset != idx }.map(\.element))
    if let c = courseName, !c.isEmpty, card.course.trimmingCharacters(in: .whitespaces).isEmpty { card.course = c }
    // the date WRITTEN ON THE CARD beats the composer's "today" default
    if let d = date, d.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil { card.date = d }
    return me.holes.filter { !($0 > 0) }.count
  }

  public static func readToast(misses: Int) -> String {
    misses > 0 ? "Card read — \(misses) hole\(misses == 1 ? "" : "s") I couldn’t make out are set to par" : "Card read — check the grid, then post"
  }

  /// D36 accuracy breadcrumb (`scan_post`): cells the golfer changed from what the model read.
  public static func accuracy(read: [Int], scores: [Int]) -> (fixed: Int, misses: Int) {
    var fixed = 0
    for (i, v) in read.enumerated() where v > 0 && i < scores.count && scores[i] != v { fixed += 1 }
    return (fixed, read.filter { !($0 > 0) }.count)
  }

  // the soft-failure vocabulary (6598–6608)
  public static let capToast = "Scan limit for today — type your nines in"
  public static let restingToast = "Scan’s resting — type your nines in"
  public static let unreadableToast = "Couldn’t read the card — type your nines in"
  public static let readingLabel = "Reading the card…"
}

// MARK: - the season window (6428–6440)

public enum PostSeasonRule {
  /// A round only "counts this season" if it lands INSIDE the window —
  /// `played_on between starts_on and ends_on`, the rule `v_rounds_ranked` enforces.
  public static func counts(playedOn: String?, season: Me.Season?, hasLeague: Bool, today: String = CSDate.today()) -> Bool {
    guard hasLeague, let s = season, !s.starts_on.isEmpty, !s.ends_on.isEmpty else { return false }
    let played = playedOn ?? today
    return played >= s.starts_on && played <= s.ends_on
  }
}
