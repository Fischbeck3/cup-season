// Cup Season — the season as a story (R6 `season_story`, D223, D235, R-H).
//
// A season stopped being a six-segment database record and became a page with
// a spine: one sentence about a person at the top, the table beneath it with a
// clause of WHY beside every number, and the arc that produced both.
//
// THE SERVER RETURNS FACTS; THIS FILE CHOOSES THE SENTENCE. `season_story`
// counts over `standings_snapshots`, `week_clashes`, `my_rivalries`, `posts`
// and `season_scenarios` and hands back the counts with their provenance; the
// seven-rung ladder (INFORMATION_ARCHITECTURE.md §7.2) lives HERE, because a
// ladder written in SQL is a ladder no test can walk. `SeasonStoryTests` walks
// every rung as a table, and `csSeasonStoryLine` in index.html is the same
// ladder in the web's own words — one rule, two renders (D234).
//
// R-H · THE BOTTOM RUNG REACHES INTO HISTORY, AND THE FENCE IS ABSOLUTE. When
// nothing has moved this week the ladder may look further back — an unsettled
// week, a run at a place, a best week — and it may not look one inch into
// invention. Every candidate arrives with the `source` it was counted over,
// `render` refuses any source it does not recognise (`namedReads`), and no
// rung manufactures a stake that does not exist. When even history finds
// nothing, rung 7b says nothing has moved, which is the honest sentence and
// the thing that stops an editorial layer from making a quiet week loud.
//
// L-01 · every number here traces to a receipt. The leader's run is a count of
// consecutive snapshot weeks; the gap is a subtraction of two rows; the record
// is `my_rivalries`' own W–L. Nothing is a projection, a probability or a
// prediction (D24).

import Foundation

public enum SeasonStory {

  // MARK: - The payload

  public struct Season: Decodable, Sendable, Equatable {
    public let id: UUID?
    public let league_id: UUID?
    public let league: String?
    public let number: Int?
    /// Calendar dates, as Strings (L-07).
    public let starts_on: String?
    public let ends_on: String?
    public let status: String?
    public let finish: String?
    public let structure: String?
    public let solo: Bool?
    public let today: String?
    public let my_member_id: UUID?
    /// D244 · the viewer has left this season. Their rounds and their name
    /// stay; they stop scoring from the day they left.
    public let i_left: Bool?
    public init(id: UUID? = nil, league_id: UUID? = nil, league: String? = nil, number: Int? = nil,
                starts_on: String? = nil, ends_on: String? = nil, status: String? = nil, finish: String? = nil,
                structure: String? = nil, solo: Bool? = nil, today: String? = nil,
                my_member_id: UUID? = nil, i_left: Bool? = nil) {
      self.id = id; self.league_id = league_id; self.league = league; self.number = number
      self.starts_on = starts_on; self.ends_on = ends_on; self.status = status; self.finish = finish
      self.structure = structure; self.solo = solo; self.today = today
      self.my_member_id = my_member_id; self.i_left = i_left
    }
  }

  public struct Leader: Decodable, Sendable, Equatable {
    public let id: String?
    public let name: String?
    public let points: Double?
    public let run_weeks: Int?
    public let since: String?
    public let is_me: Bool?
    public let source: String?
    public init(id: String? = nil, name: String? = nil, points: Double? = nil, run_weeks: Int? = nil,
                since: String? = nil, is_me: Bool? = nil, source: String? = "standings_snapshots") {
      self.id = id; self.name = name; self.points = points; self.run_weeks = run_weeks
      self.since = since; self.is_me = is_me; self.source = source
    }
  }

  public struct Side: Decodable, Sendable, Equatable {
    public let name: String?
    public let points: Double?
    public init(name: String? = nil, points: Double? = nil) { self.name = name; self.points = points }
  }

  /// The most recent week whose top row changed hands.
  public struct Flip: Decodable, Sendable, Equatable {
    public let week: Int?
    public let on: String?
    public let to: String?
    public let to_id: String?
    public let from: String?
    public let first_time: Bool?
    public let source: String?
    public init(week: Int? = nil, on: String? = nil, to: String? = nil, to_id: String? = nil,
                from: String? = nil, first_time: Bool? = nil, source: String? = "standings_snapshots") {
      self.week = week; self.on = on; self.to = to; self.to_id = to_id
      self.from = from; self.first_time = first_time; self.source = source
    }
  }

  /// A rung that has closed at least half its gap to the lead in two weeks.
  public struct Closer: Decodable, Sendable, Equatable {
    public let name: String?
    public let taken: Double?
    public let weeks: Int?
    public let source: String?
    public init(name: String? = nil, taken: Double? = nil, weeks: Int? = 2, source: String? = "standings_snapshots") {
      self.name = name; self.taken = taken; self.weeks = weeks; self.source = source
    }
  }

  public struct Final: Decodable, Sendable, Equatable {
    public let opens_on: String?
    public let in_weeks: Int?
    public let seats: Int?
    public let still_live: Int?
    public let source: String?
    public init(opens_on: String? = nil, in_weeks: Int? = nil, seats: Int? = 2, still_live: Int? = nil,
                source: String? = "season_scenarios") {
      self.opens_on = opens_on; self.in_weeks = in_weeks; self.seats = seats
      self.still_live = still_live; self.source = source
    }
  }

  public struct Facts: Decodable, Sendable, Equatable {
    public let week_no: Int?
    public let weeks_total: Int?
    public let weeks_left: Int?
    public let week_ends_on: String?
    public let field: Int?
    public let leader: Leader?
    public let runner_up: Side?
    public let top_gap: Double?
    public let lead_flip: Flip?
    public let closer: Closer?
    public let final: Final?
    public let last_snapshot_on: String?
    public init(week_no: Int? = nil, weeks_total: Int? = nil, weeks_left: Int? = nil, week_ends_on: String? = nil,
                field: Int? = nil, leader: Leader? = nil, runner_up: Side? = nil, top_gap: Double? = nil,
                lead_flip: Flip? = nil, closer: Closer? = nil, final: Final? = nil, last_snapshot_on: String? = nil) {
      self.week_no = week_no; self.weeks_total = weeks_total; self.weeks_left = weeks_left
      self.week_ends_on = week_ends_on; self.field = field; self.leader = leader; self.runner_up = runner_up
      self.top_gap = top_gap; self.lead_flip = lead_flip; self.closer = closer; self.final = final
      self.last_snapshot_on = last_snapshot_on
    }
  }

  /// One candidate for rung 7 — the reach back. Every one names its read.
  public struct History: Decodable, Sendable, Equatable {
    public let kind: String
    public let source: String?
    public let record_source: String?
    public let opponent: String?
    public let since: String?
    public let days: Int?
    public let wins: Int?
    public let losses: Int?
    public let ties: Int?
    public let rank: Int?
    public let weeks: Int?
    public let week: Int?
    public let points: Double?
    public init(kind: String, source: String? = nil, record_source: String? = nil, opponent: String? = nil,
                since: String? = nil, days: Int? = nil, wins: Int? = nil, losses: Int? = nil, ties: Int? = nil,
                rank: Int? = nil, weeks: Int? = nil, week: Int? = nil, points: Double? = nil) {
      self.kind = kind; self.source = source; self.record_source = record_source; self.opponent = opponent
      self.since = since; self.days = days; self.wins = wins; self.losses = losses; self.ties = ties
      self.rank = rank; self.weeks = weeks; self.week = week; self.points = points
    }
  }

  /// One entry in the arc — the season, week by week.
  public struct Arc: Decodable, Sendable, Equatable, Identifiable {
    public let kind: String
    public let source: String?
    public let week: Int?
    public let on: String?
    public let subject: String?
    public let other: String?
    public let text: String?
    public let post_kind: String?
    public let mine: Bool?
    public var id: String { "\(kind)-\(week ?? 0)-\(on ?? "")-\(text?.prefix(24) ?? "")" }
    public init(kind: String, source: String? = nil, week: Int? = nil, on: String? = nil, subject: String? = nil,
                other: String? = nil, text: String? = nil, post_kind: String? = nil, mine: Bool? = nil) {
      self.kind = kind; self.source = source; self.week = week; self.on = on; self.subject = subject
      self.other = other; self.text = text; self.post_kind = post_kind; self.mine = mine
    }
  }

  /// One row of the table, with its own clause of why.
  public struct Row: Decodable, Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let points: Double
    public let rank: Int
    public let rounds: Int?
    /// Counting rounds this month, from `month_rank` against the cap — never
    /// the the monthly minimum's credit count (L-44).
    public let counted: Int?
    public let left: Bool?
    public let is_me: Bool?
    public init(id: String, name: String, points: Double, rank: Int, rounds: Int? = nil,
                counted: Int? = nil, left: Bool? = nil, is_me: Bool? = nil) {
      self.id = id; self.name = name; self.points = points; self.rank = rank
      self.rounds = rounds; self.counted = counted; self.left = left; self.is_me = is_me
    }
  }

  public struct Archive: Decodable, Sendable, Equatable, Identifiable {
    public let season_id: UUID?
    public let number: Int?
    public let starts_on: String?
    public let ends_on: String?
    public let status: String?
    public let champion: String?
    public let is_current: Bool?
    public var id: String { season_id?.uuidString ?? "s\(number ?? 0)" }
    public init(season_id: UUID? = nil, number: Int? = nil, starts_on: String? = nil, ends_on: String? = nil,
                status: String? = nil, champion: String? = nil, is_current: Bool? = nil) {
      self.season_id = season_id; self.number = number; self.starts_on = starts_on; self.ends_on = ends_on
      self.status = status; self.champion = champion; self.is_current = is_current
    }
  }

  public struct Payload: Decodable, Sendable, Equatable {
    public let season: Season?
    public let facts: Facts?
    public let history: [History]
    public let arc: [Arc]
    public let table: [Row]
    public let archive: [Archive]
    public let generated_at: String?

    public init(season: Season? = nil, facts: Facts? = nil, history: [History] = [], arc: [Arc] = [],
                table: [Row] = [], archive: [Archive] = [], generated_at: String? = nil) {
      self.season = season; self.facts = facts; self.history = history; self.arc = arc
      self.table = table; self.archive = archive; self.generated_at = generated_at
    }

    private enum K: String, CodingKey { case season, facts, history, arc, table, archive, generated_at }
    public init(from decoder: any Decoder) throws {
      let c = try decoder.container(keyedBy: K.self)
      func opt<T: Decodable>(_ t: T.Type, _ k: K) -> T? { (try? c.decodeIfPresent(t, forKey: k)) ?? nil }
      season = opt(Season.self, .season)
      facts = opt(Facts.self, .facts)
      history = opt([History].self, .history) ?? []
      arc = opt([Arc].self, .arc) ?? []
      table = opt([Row].self, .table) ?? []
      archive = opt([Archive].self, .archive) ?? []
      generated_at = opt(String.self, .generated_at)
    }
  }
}

// MARK: - The ladder

public enum SeasonStoryCopy {

  /// The reads a sentence may be counted over. R-H's fence, as a value: a
  /// candidate whose `source` is not one of these renders NOTHING, whatever
  /// else it carries. A later read joins this set in the same commit as the
  /// migration that adds it, or its sentences never reach a screen.
  public static let namedReads: Set<String> = [
    "standings_snapshots", "week_clashes", "my_rivalries", "posts", "season_scenarios",
    // wave 5 · R4 joins the fence in the same commit as its migration, which
    // is what the rule above requires. Without this line every sentence the
    // head-to-head feeds would render nothing — the fence working, not a bug.
    "head_to_head",
  ]

  /// The chosen sentence, the rung it came from, and the read that proves it.
  public struct Line: Sendable, Equatable {
    public let rung: Int
    public let text: String
    public let source: String
    public init(rung: Int, text: String, source: String) {
      self.rung = rung; self.text = text; self.source = source
    }
  }

  /// The seven-rung ladder, in order, with rung 7 reaching into history (R-H)
  /// and 7b saying nothing has moved. Returns nil only when there is no season
  /// to describe — a page with no story line renders no story line rather than
  /// an empty one (L-32/L-44).
  public static func line(_ p: SeasonStory.Payload, calendar: Calendar = .current) -> Line? {
    guard let f = p.facts else { return nil }
    let solo = p.season?.solo ?? true

    // Rung 0 · a wrapped season leads with how it ended, not with a ladder
    // about a race that is over. The champion is `seasons.champion_*` through
    // the archive; a payload that cannot name one falls through.
    if p.season?.status == "complete",
       let champ = clean(p.archive.first(where: { $0.is_current == true })?.champion) {
      let mine = p.table.first(where: { $0.is_me == true })?.name
      return Line(rung: 0,
                  text: champ == mine ? "You took it." : "\(champ) took it.",
                  source: "standings_snapshots")
    }

    // Rung 1 · the lead changed hands this week.
    if let flip = f.lead_flip, ok(flip.source), let to = clean(flip.to),
       let week = flip.week, week >= (f.week_no ?? 0) - 1 {
      let day = flip.on.map(dayName) ?? nil
      let when = day.map { " on \($0)" } ?? ""
      if flip.to_id != nil, let me = p.table.first(where: { $0.is_me == true }), me.id == flip.to_id {
        return Line(rung: 1, text: "You took the lead\(when)." + (flip.first_time == true ? " For the first time." : ""),
                    source: flip.source ?? "standings_snapshots")
      }
      return Line(rung: 1,
                  text: "The lead changed hands\(when). \(to) has it \(flip.first_time == true ? "for the first time" : "back").",
                  source: flip.source ?? "standings_snapshots")
    }

    // Rung 2 · somebody has led three weeks or more. A squad is a THEY —
    // "Mudsharks has led" is the engine talking, not a golfer.
    if let lead = f.leader, ok(lead.source), let run = lead.run_weeks, run >= 3, let name = clean(lead.name) {
      let who = lead.is_me == true ? "You have" : (solo ? "\(name) has" : "\(name) have")
      return Line(rung: 2, text: "\(who) led for \(word(run)) straight weeks.",
                  source: lead.source ?? "standings_snapshots")
    }

    // Rung 3 · the top two are inside two points.
    if let gap = f.top_gap, gap <= 2, (f.field ?? 0) >= 2, f.runner_up != nil {
      let left = f.weeks_left ?? 0
      let clock = left > 0 ? " with \(word(left)) week\(left == 1 ? "" : "s") to play" : ""
      if gap <= 0 { return Line(rung: 3, text: "The top two are level\(clock).", source: "standings_snapshots") }
      // A whole number is said out loud; a half is printed, because "one and a
      // half points" is not how anybody reads a table.
      let head = gap == 1 ? "One point separates"
               : gap == gap.rounded() ? "\(cap(word(Int(gap)))) points separate"
               : "\(CSCopy.points(gap)) points separate"
      return Line(rung: 3, text: "\(head) the top two\(clock).", source: "standings_snapshots")
    }

    // Rung 4 · somebody has closed half the gap in a fortnight.
    if let c = f.closer, ok(c.source), let name = clean(c.name), let taken = c.taken, taken > 0 {
      let mine = p.table.first(where: { $0.is_me == true })?.name == name
      let verb = mine ? "You have" : (solo ? "\(name) has" : "\(name) have")
      return Line(rung: 4, text: "\(verb) taken \(word(Int(taken.rounded()))) off the lead in a fortnight.",
                  source: c.source ?? "standings_snapshots")
    }

    // Rung 5 · the Final opens inside three weeks.
    if let fin = f.final, ok(fin.source), let inW = fin.in_weeks, inW <= 3, inW >= 0,
       p.season?.status != "cup_final" {
      let head = inW == 0 ? "The Final opens this week."
                          : "\(cap(word(inW))) week\(inW == 1 ? "" : "s") until the Final."
      let seats = fin.seats ?? 2
      var tail = "\(cap(word(seats))) seat\(seats == 1 ? "" : "s")"
      if let live = fin.still_live, live > 0 { tail += ", \(word(live)) still live" }
      return Line(rung: 5, text: "\(head) \(tail).", source: fin.source ?? "season_scenarios")
    }

    // Rung 6 · week one.
    if (f.week_no ?? 1) == 1, let total = f.weeks_total {
      return Line(rung: 6, text: "\(cap(word(total))) weeks. Clean cards, fragile egos.",
                  source: "standings_snapshots")
    }

    // Rung 7 · the reach back (R-H).
    for h in p.history {
      if let text = history(h, calendar: calendar), let src = h.source, ok(src) {
        return Line(rung: 7, text: text, source: src)
      }
    }

    // Rung 7b · even history found nothing.
    let w = f.week_no ?? 1, t = f.weeks_total ?? 1
    let since = f.last_snapshot_on.map(dayName) ?? nil
    return Line(rung: 7, text: "Week \(word(w)) of \(word(t)). Nothing has moved\(since.map { " since \($0)" } ?? " yet").",
                source: "standings_snapshots")
  }

  /// One rung-7 candidate as a sentence, or nil when this build does not know
  /// how to say it (a kind from a newer server renders nothing rather than a
  /// guess). Nothing here is inflated: a rivalry with no settled week says
  /// nothing at all, and a run of one week is not a run.
  public static func history(_ h: SeasonStory.History, calendar: Calendar = .current) -> String? {
    switch h.kind {
    case "unsettled_week":
      // A week settled days ago is not a story; a fortnight is.
      guard let name = clean(h.opponent), let since = h.since, (h.days ?? 0) >= 14,
            CSDate.local(since, calendar: calendar) != nil else { return nil }
      var s = "You and \(name) have not settled a week since \(theDayOf(since, calendar: calendar))."
      if let w = h.wins, let l = h.losses, w + l + (h.ties ?? 0) > 0 {
        if w > l { s += " You are \(w)–\(l) up all-time." }
        else if l > w { s += " \(name) is \(l)–\(w) up all-time." }
        else { s += " You are level at \(w)–\(l) all-time." }
      }
      return s
    case "my_run":
      guard let rank = h.rank, let weeks = h.weeks, weeks >= 2 else { return nil }
      return "You have held \(CSCopy.ordinal(rank)) for \(word(weeks)) straight weeks."
    case "my_best_week":
      guard let week = h.week, let pts = h.points, pts > 0 else { return nil }
      return "Your best week of the season is still week \(word(week)) — \(CSCopy.points(pts)) points."
    default:
      return nil
    }
  }

  /// One arc entry as a line. `post` carries the server's own sentence; the
  /// other kinds are facts this producer phrases, so the two clients say the
  /// same thing about the same week.
  public static func arc(_ a: SeasonStory.Arc) -> String? {
    guard ok(a.source) else { return nil }
    switch a.kind {
    case "post": return clean(a.text).map { ease($0) }
    case "lead_change":
      guard let to = clean(a.subject) else { return nil }
      if let from = clean(a.other) { return "\(to) took the lead from \(from)." }
      return "\(to) took the lead."
    case "clash":
      let other = clean(a.other) ?? "someone in the season"
      guard let who = clean(a.subject) else { return "You and \(other) halved the week." }
      return who == "you" ? "You took the week from \(other)." : "\(who) took the week."
    default: return nil
    }
  }

  /// "WEEK 7" — the arc's own eyebrow.
  public static func arcWeek(_ a: SeasonStory.Arc) -> String? {
    a.week.map { "WEEK \($0)" }
  }

  /// The dateline over the page: `FELLAS · WEEK 7 OF 26 · SEASON LIVE`. One
  /// stage vocabulary (D120), one week producer (D246), one row — so nothing
  /// below it prints the week a second time (L-34).
  public static func dateline(name: String?, stage: LeagueCopy.Stage, week: Int?, weeks: Int?) -> String {
    var parts: [String] = []
    if let n = clean(name) { parts.append(n.uppercased()) }
    if let w = week, let t = weeks, stage == .season || stage == .final { parts.append("WEEK \(w) OF \(t)") }
    parts.append(stage.label.uppercased())
    return parts.joined(separator: " · ")
  }

  /// The archive row: "SEASON 1 · JUL 20 – JAN 18 · GALEN TOOK IT".
  public static func archiveLine(_ a: SeasonStory.Archive, calendar: Calendar = .current) -> String {
    var parts: [String] = []
    if let s = a.starts_on, let e = a.ends_on,
       CSDate.local(s, calendar: calendar) != nil, CSDate.local(e, calendar: calendar) != nil {
      parts.append("\(LeagueDates.monDay(s, calendar: calendar)) – \(LeagueDates.monDay(e, calendar: calendar))")
    }
    if let champ = clean(a.champion) { parts.append("\(champ) took it") }
    else if a.status == "complete" { parts.append("Season complete") }
    else if a.is_current == true { parts.append("Running now") }
    return parts.joined(separator: " · ").uppercased()
  }

  // MARK: - The table's clause of why (§7.3)

  /// The clause beside a row's number: the movement with its own clock (A-4),
  /// then the gap, then what is counting. Never a bare arrow, never a figure
  /// without its unit.
  public static func rowClause(_ r: SeasonStory.Row, leader: SeasonStory.Row?, cap: Int?) -> String? {
    var parts: [String] = []
    if let lead = leader, lead.id != r.id {
      let gap = lead.points - r.points
      if gap > 0 { parts.append("\(CSCopy.points(gap)) back") }
    }
    if r.is_me == true, let counted = r.counted, let cap, cap > 0 {
      parts.append("\(counted) of \(cap) counting this month")
    }
    if r.left == true { parts.append("stopped scoring") }
    return parts.isEmpty ? nil : parts.joined(separator: " · ")
  }

  // MARK: - Small parts

  static func ok(_ source: String?) -> Bool {
    guard let s = source else { return false }
    return namedReads.contains(s)
  }

  static func clean(_ s: String?) -> String? {
    let t = (s ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    return t.isEmpty ? nil : t
  }

  /// The weekday of an instant, from its own calendar-date prefix — never an
  /// ISO parse of the whole timestamp (L-07). `"2026-08-30T07:10:00+00"` is a
  /// Sunday, and a Sunday is what the sentence says.
  static func dayName(_ instant: String) -> String? {
    let iso = String(instant.prefix(10))
    guard let d = CSDate.local(iso) else { return nil }
    let wd = Calendar.current.component(.weekday, from: d)
    return LeagueDates.dowLong[max(0, min(6, wd - 1))]
  }

  /// "the 12th of August" — R-H's own form.
  static func theDayOf(_ iso: String, calendar: Calendar = .current) -> String {
    guard let d = CSDate.local(iso, calendar: calendar) else { return iso }
    let day = calendar.component(.day, from: d)
    let month = calendar.component(.month, from: d)
    return "the \(CSCopy.ordinal(day)) of \(LeagueDates.monthsLong[max(0, min(11, month - 1))])"
  }

  /// Numbers as words, the way the design's own sentences say them — "Week
  /// seven of twenty-six", "Thirteen weeks", "four straight weeks". A season
  /// can run fifty-two weeks, so the table goes to ninety-nine and anything
  /// past that is a figure, which is the honest thing to do with a number
  /// nobody says out loud.
  static let words = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
                      "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen",
                      "eighteen", "nineteen", "twenty"]
  static let tens = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
  public static func word(_ n: Int) -> String {
    if n >= 0 && n < words.count { return words[n] }
    if n > 20 && n < 100 {
      let t = tens[n / 10], u = n % 10
      return u == 0 ? t : "\(t)-\(words[u])"
    }
    return String(n)
  }
  public static func cap(_ s: String) -> String {
    guard let c = s.first else { return s }
    return c.uppercased() + s.dropFirst()
  }

  /// Server bodies arrive in the scoreboard voice (ALL CAPS). In the story
  /// they read like code, so the arc eases them into sentences — through
  /// `BoardText.easeCaps`, which is the producer the board already uses and
  /// the twin of the web's `easeCaps`. A second easer here would be exactly
  /// the drift D234 forbids; mixed-case bodies pass through untouched.
  static func ease(_ s: String, names: BoardText.NameRegistry = BoardText.NameRegistry()) -> String {
    BoardText.easeCaps(s, names: names)
  }
}

// MARK: - The rules, in plain sentences (§7.4)

/// The rules page. One page of sentences, not ten all-caps rows: it retires
/// "COUNTING CAP", "PARTICIPATION FLOOR", "HANDICAP ALLOWANCE 95%",
/// "VERIFICATION", "STRUCTURE" and "PRESET" from every user surface (T-01 —
/// the engine's nouns are not the golfer's).
///
/// Two phrases survive because they are RULED, not leaked: *"scored fresh"* is
/// D126's own wording, and the allowance row's sentence is D128(2)'s.
public enum SeasonRules {

  public struct Section: Sendable, Equatable, Identifiable {
    public let head: String
    public let body: String
    public var id: String { head }
    public init(head: String, body: String) { self.head = head; self.body = body }
  }

  /// "The Fellas, season one." — the page's own title.
  public static func title(league: String?, number: Int?) -> String {
    let name = (league?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? "The season"
    guard let n = number, n > 0 else { return name }
    return "\(name), season \(SeasonStoryCopy.word(n))."
  }

  /// "Thirteen weeks from Saturday, Sep 12 to Saturday, Dec 12."
  public static func span(startsOn: String?, endsOn: String?, calendar: Calendar = .current) -> String? {
    guard let s = startsOn, let e = endsOn,
          CSDate.local(s, calendar: calendar) != nil, CSDate.local(e, calendar: calendar) != nil else { return nil }
    let weeks = LeagueDates.totalWeeks(start: s, end: e, calendar: calendar)
    return "\(SeasonStoryCopy.cap(SeasonStoryCopy.word(weeks))) weeks from "
         + "\(LeagueDates.dowMonDay(s, calendar: calendar)) to \(LeagueDates.dowMonDay(e, calendar: calendar))."
  }

  /// The five sections, in order. Each one is a sentence a golfer would say,
  /// and every number in them is the league's own.
  public static func sections(_ b: Bylaws, clock: RoomClock, pro: String?, members: Int,
                              calendar: Calendar = .current) -> [Section] {
    var out: [Section] = []

    // HOW IT SCORES — the allowance and the cap, as one sentence each.
    let allowance = Bylaws.allow[max(0, min(Bylaws.allow.count - 1, b.presetIdx))]
    let counted = b.cap.map { "Your best \(SeasonStoryCopy.word($0)) round\($0 == 1 ? "" : "s") each calendar month count." }
                ?? "Every round you post counts."
    out.append(Section(head: "How it scores",
                       body: "Every round you post is scored against your own number at \(percent(allowance)). \(counted)"))

    // WHAT YOU OWE THE SEASON — D14's floor, D140's solo truth, the auto-bye.
    if b.floor > 0 {
      let rounds = "\(SeasonStoryCopy.cap(SeasonStoryCopy.word(b.floor))) round\(b.floor == 1 ? "" : "s") a month."
      out.append(Section(head: "What you owe the season",
                         body: b.solo
                           ? "\(rounds) In a season with no squads that is a habit, not a penalty — there is no squad to dock."
                           : "\(rounds) Miss a month and your first one is forgiven automatically."))
    }

    // HOW IT ENDS — D126's sentence, whole, in the one place the mechanic is.
    out.append(Section(head: "How it ends",
                       body: LeagueCopy.endgame(finish: b.finish, structure: b.structure,
                                                startsOn: clock.startsOn, endsOn: clock.endsOn, calendar: calendar)))

    // WHAT'S ON IT — the pot's two numbers and the ledger line, verbatim
    // (L-09). A $0 season has no money surface at all (L-10, D70).
    if b.stake > 0 {
      let players = max(members, 1)
      let split = "\(SeasonStoryCopy.cap(SeasonStoryCopy.word(b.payout[0]))) percent to the champion, "
                + "\(SeasonStoryCopy.word(b.payout.count > 1 ? b.payout[1] : 0)) to the runner-up, "
                + "\(SeasonStoryCopy.word(b.payout.count > 2 ? b.payout[2] : 0)) to the points king."
      out.append(Section(head: "What's on it",
                         body: "\(PotMath.dollars(b.stake)) each, \(PotMath.dollars(b.stake * players)) in the pot. "
                             + "\(split) \(MoneyCopy.ledger)"))
    }

    // SCORES — M-15's own wording: the norm, not a filter.
    out.append(Section(head: "Scores",
                       body: Bylaws.verif[max(0, min(Bylaws.verif.count - 1, b.presetIdx))] + "."))

    // and the two facts that close the page
    var close = ""
    if let p = (pro?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap({ $0.isEmpty ? nil : $0 }) {
      close = "\(p) runs the season (the Pro)."
    }
    if clock.phase == .season, !clock.atStarter {
      close += close.isEmpty ? "Rules froze at the first tee." : " Rules froze at the first tee."
    }
    if !close.isEmpty { out.append(Section(head: "Who runs it", body: close)) }
    return out
  }

  /// "ninety-five percent" — the allowance said, never printed as a dial.
  static func percent(_ n: Int) -> String {
    switch n {
    case 100: return "the full number"
    case 95:  return "ninety-five percent"
    case 90:  return "ninety percent"
    default:  return "\(n) percent"
    }
  }
}
