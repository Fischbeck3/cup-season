// Cup Season — the Ryder's and the Major's arithmetic and copy, ported
// VERBATIM from index.html:
//
//   evHalf          12196   6½ — the half-point voice
//   renderEvent     12197   status chip · clinch line · series line · the rule
//                           sentence · session order (S5-02) · duel rows · the
//                           number to beat · the nag line · W-L-H
//   mjVs / mjMoney  12363   "4.2 UNDER" · "$20"
//   renderMajorRoom 12374   status chip · the card lines · the annual voice ·
//                           the fine print
//   nextSundayISO   15909   the first tee default
//   isoPlus         16171   "same weekday, next year"
//   nthUp           10904   1ST / 2ND / 3RD / 11TH
//
// Everything here is display arithmetic on facts the engine already wrote.
// The clinch is derived the way the web derives it for the SCREEN; the engine
// flips `complete` on its own (resolve_session), never this file.

import Foundation

// MARK: - Dates the rooms print

public enum EventDates {
  static let MOS = BoardText.MOS
  static let DOW = BoardText.DOW
  static let DOWLong = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

  /// `nextSundayISO` — the coming Sunday; a Sunday today rolls a week ahead.
  public static func nextSundayISO(today: String = CSDate.today(), calendar: Calendar = .current) -> String {
    guard let d = CSDate.local(today, calendar: calendar) else { return today }
    let dow = (calendar.component(.weekday, from: d) - 1)      // JS getDay(): 0 = Sunday
    var add = (7 - dow) % 7
    if add == 0 { add = 7 }
    guard let n = calendar.date(byAdding: .day, value: add, to: d) else { return today }
    return CSDate.iso(n, calendar: calendar)
  }

  public static func isSunday(_ iso: String, calendar: Calendar = .current) -> Bool {
    guard let d = CSDate.local(iso, calendar: calendar) else { return false }
    return calendar.component(.weekday, from: d) == 1
  }

  /// `isoPlus(dstr, addDays)` — calendar arithmetic, never through UTC.
  public static func isoPlus(_ iso: String, _ days: Int, calendar: Calendar = .current) -> String? {
    guard let d = CSDate.local(iso, calendar: calendar), let n = calendar.date(byAdding: .day, value: days, to: d) else { return nil }
    return CSDate.iso(n, calendar: calendar)
  }

  /// "JUL 6" — `MOS[m].toUpperCase() + ' ' + date`.
  public static func monthDayUpper(_ iso: String, calendar: Calendar = .current) -> String {
    guard let d = CSDate.local(iso, calendar: calendar) else { return iso }
    let c = calendar.dateComponents([.month, .day], from: d)
    return "\(MOS[max(0, (c.month ?? 1) - 1)].uppercased()) \(c.day ?? 1)"
  }

  /// "JUL 6–JUL 12" — a session window, a Major window.
  public static func window(_ opens: String, _ closes: String, calendar: Calendar = .current) -> String {
    "\(monthDayUpper(opens, calendar: calendar))–\(monthDayUpper(closes, calendar: calendar))"
  }

  /// "Sep 6" — **case belongs to the ROLE** (§1.3), so the producer stops
  /// shouting and the `agate` role uppercases what it draws.
  public static func monthDay(_ iso: String, calendar: Calendar = .current) -> String {
    guard let d = CSDate.local(iso, calendar: calendar) else { return iso }
    let c = calendar.dateComponents([.month, .day], from: d)
    return "\(MOS[max(0, (c.month ?? 1) - 1)]) \(c.day ?? 1)"
  }

  /// "Sep 6 – Sep 12" — the SPACED en dash a dateline sets, never `→`
  /// (§5.2, `LINT-13`: an arrow inside a dateline is not a link affordance).
  public static func windowSpaced(_ opens: String, _ closes: String, calendar: Calendar = .current) -> String {
    "\(monthDay(opens, calendar: calendar)) – \(monthDay(closes, calendar: calendar))"
  }

  /// "Sun Sep 6" — the weekday form a title card's dateline takes.
  public static func dowMonthDay(_ iso: String, calendar: Calendar = .current) -> String {
    guard let d = CSDate.local(iso, calendar: calendar) else { return iso }
    let c = calendar.dateComponents([.weekday, .month, .day], from: d)
    return "\(DOW[max(0, (c.weekday ?? 1) - 1)]) \(MOS[max(0, (c.month ?? 1) - 1)]) \(c.day ?? 1)"
  }

  /// "Thu, Jul 9" — `toLocaleDateString('en-US',{weekday:'short',month:'short',day:'numeric'})`.
  public static func weekdayMonthDay(_ iso: String, calendar: Calendar = .current) -> String {
    guard let d = CSDate.local(iso, calendar: calendar) else { return iso }
    let c = calendar.dateComponents([.weekday, .month, .day], from: d)
    return "\(DOW[max(0, (c.weekday ?? 1) - 1)]), \(MOS[max(0, (c.month ?? 1) - 1)]) \(c.day ?? 1)"
  }

  /// "Sunday" — the long weekday.
  public static func weekdayLong(_ iso: String, calendar: Calendar = .current) -> String {
    guard let d = CSDate.local(iso, calendar: calendar) else { return iso }
    return DOWLong[max(0, calendar.component(.weekday, from: d) - 1)]
  }

  /// Whole days from today to `iso` (0 = today, negative = past).
  public static func daysUntil(_ iso: String, today: String = CSDate.today(), calendar: Calendar = .current) -> Int? {
    CSDate.days(from: today, to: iso, calendar: calendar)
  }
}

// MARK: - The Ryder

public enum RyderMath {
  /// `evHalf(n)` — 9.5 → "9½", 0.5 → "½", 4 → "4", 0 → "0".
  public static func evHalf(_ n: Double) -> String {
    let w = Int(n.rounded(.down))
    let h = (n - Double(w)) >= 0.5
    return ((w != 0 || !h) ? String(w) : "") + (h ? "½" : "")
  }

  /// `nthUp(n)` — 1ST 2ND 3RD 4TH … 11TH 12TH 13TH … 21ST.
  public static func nthUp(_ n: Int) -> String {
    let m = n % 100
    if m >= 11 && m <= 13 { return "\(n)TH" }
    switch n % 10 {
    case 1: return "\(n)ST"
    case 2: return "\(n)ND"
    case 3: return "\(n)RD"
    default: return "\(n)TH"
    }
  }

  /// `3rd` — the same ordinal the role does NOT uppercase, for a sentence.
  public static func nth(_ n: Int) -> String { nthUp(n).lowercased() }

  /// `3` and a half, as two pieces. **The vulgar fraction is composed, never
  /// passed as one string** (§13 (a)): `½` drawn from the condensed cut at
  /// 40pt reads as a small diagonal, and the rider — 0.56 em on a raised
  /// baseline — is what makes a mixed number read as one figure.
  public static func evHalfParts(_ n: Double) -> (whole: String, half: Bool) {
    let w = Int(n.rounded(.down))
    let h = (n - Double(w)) >= 0.5
    return ((w != 0 || !h) ? String(w) : "", h)
  }

  /// `sgn(v)` — `(v>=0?'+':'')+v.toFixed(1)`.
  public static func sgn(_ v: Double) -> String { CSBands.pviChip(v) }

  /// The clinch arithmetic (§R4; renderEvent 12208–12210):
  /// P = min(rosterA, rosterB) · M = P × sessions · clinch = M/2 + ½.
  public struct Target: Sendable, Equatable {
    public let pairings: Int      // P
    public let points: Int        // M
    public let clinch: Double
    public init(pairings: Int, points: Int, clinch: Double) { self.pairings = pairings; self.points = points; self.clinch = clinch }
  }

  public static func target(rosterA: Int, rosterB: Int, sessionCount: Int?, sessionRows: Int) -> Target {
    let p = min(rosterA, rosterB)
    let m = p * (sessionCount ?? (sessionRows > 0 ? sessionRows : 1))
    return Target(pairings: p, points: m, clinch: Double(m) / 2 + 0.5)
  }

  public static func target(_ room: EventRoom) -> Target {
    target(rosterA: room.roster(room.teamA.id).count, rosterB: room.roster(room.teamB.id).count,
           sessionCount: room.event.session_count, sessionRows: room.sessions.count)
  }

  /// `Forming` · `Live · week 2 of 3` · `Fixture Owls take the cup` ·
  /// `Shared — both names on it`.
  ///
  /// **CASE BELONGS TO THE ROLE** (§1.3, and §9's producer edit 2). This
  /// returned `"Live · wk 2/3"` — sentence case with an abbreviation — beside
  /// `"NAME TAKES THE CUP"`, which called `.uppercased()` inside the producer,
  /// so one string was shouted by the copy and the other by the view and
  /// neither client could set them the same way. Both are sentences now and
  /// the `agate` role uppercases. `wk 2/3` is likewise gone: the golfer's form
  /// is **week 2 of 3** (`TERMINOLOGY` §4 pattern 10).
  public static func statusChip(status: String, winnerTeamId: UUID?, teamA: EventTeam, teamB: EventTeam,
                                closedSessions: Int, sessionCount: Int?) -> String {
    if status == "complete" {
      if let w = winnerTeamId { return (w == teamA.id ? teamA.name : teamB.name) + " take the cup" }
      return "Shared — both names on it"
    }
    if status == "setup" { return "Forming" }
    let n = sessionCount ?? 0
    return "Live · week \(min(closedSessions + 1, n)) of \(n)"
  }

  public static func statusChip(_ room: EventRoom) -> String {
    statusChip(status: room.event.status, winnerTeamId: room.event.winner_team_id, teamA: room.teamA, teamB: room.teamB,
               closedSessions: room.sessions.filter { $0.isClosed }.count, sessionCount: room.event.session_count)
  }

  /// `Final. Fixture Owls took it 5–4.` · `First to 5. Fixture Owls need 1½, Fixture Foxes need 2½.`
  ///
  /// **The sentence is the story; the figures above it are the record** (§9.9),
  /// so it is prose in `body` and not a fourth line of tracked caps. It shipped
  /// pre-uppercased with middots for punctuation, which is a label pretending
  /// to be a sentence.
  public static func clinchLine(status: String, aPoints: Double, bPoints: Double, clinch: Double,
                                aName: String, bName: String, winnerName: String? = nil) -> String {
    if status == "complete" {
      guard let w = winnerName else { return "Final. It was shared, \(evHalf(aPoints))–\(evHalf(bPoints))." }
      let hi = max(aPoints, bPoints), lo = min(aPoints, bPoints)
      return "Final. \(w) took it \(evHalf(hi))–\(evHalf(lo))."
    }
    return "First to \(evHalf(clinch)). \(aName) need \(evHalf(max(0, clinch - aPoints))), \(bName) need \(evHalf(max(0, clinch - bPoints)))."
  }

  public static func clinchLine(_ room: EventRoom) -> String {
    let t = target(room)
    let w = room.event.winner_team_id.map { $0 == room.teamA.id ? room.teamA.name : room.teamB.name }
    return clinchLine(status: room.event.status, aPoints: room.points(room.teamA.id), bPoints: room.points(room.teamB.id),
                      clinch: t.clinch, aName: room.teamA.name, bName: room.teamB.name, winnerName: w)
  }

  /// D62 — the series line: editions counted, the cup defended. nil until the
  /// chain has more than one edition, or when this event is not in it.
  public static func seriesLine(lineage: [EventLineageRow], eventId: UUID, status: String, aName: String, bName: String) -> String? {
    let chain = lineage.filter { !$0.isMajor }
    guard chain.count > 1, let idx = chain.firstIndex(where: { $0.eventId == eventId }) else { return nil }
    let pos = idx + 1
    // the record THROUGH this edition: every finished edition up to and
    // including the one on screen. Counting only the others printed "The 1st
    // Ryder · all square 0–0" beside that edition's own result, and let a
    // later edition's result leak into an earlier one. A live edition is not
    // finished, so it still reads the record coming in. (The desk's fix.)
    let priors = Array(chain.prefix(pos)).filter { $0.isComplete }
    var aW = 0.0, bW = 0.0
    for r in priors {
      if r.winnerShared { aW += 0.5; bW += 0.5 }
      else if r.winnerSlot == 0 { aW += 1 }
      else if r.winnerSlot == 1 { bW += 1 }
    }
    let rec = "\(evHalf(max(aW, bW)))–\(evHalf(min(aW, bW)))"
    let leaderSlot: Int? = aW > bW ? 0 : bW > aW ? 1 : nil
    let series = leaderSlot.map { "\($0 == 0 ? aName : bName) hold the Ryder \(rec)" } ?? "all square \(rec)"
    // W2 · THE HOLDER IS SAID ONCE (owner C, category C). "Fixture Hawks hold
    // the Ryder 1–0 · Fixture Hawks hold it" was one fact twice. The holder
    // and the record ride one clause when they agree, and both are named only
    // when they do not (a shared cup, or a series all square).
    var line = series
    if status != "complete", let last = priors.last {
      if last.winnerShared { line = "\(series) · the cup is shared" }
      else if let holder = last.winnerSlot, holder == 0 || holder == 1 {
        let name = holder == 0 ? aName : bName
        line = holder == leaderSlot ? "\(name) hold it, \(rec)" : "\(series) · \(name) hold it"
      }
    }
    return "The \(nth(pos)) Ryder · \(line)"
  }

  /// How it scores — everyone sees the rule, not just the organizer (12257).
  public static func ruleSentence(_ t: Target) -> String {
    let head = "Each week pairs everyone 1‑on‑1; the best round that week against your playing HCP wins the point, a tie splits it. "
    return t.pairings > 0
      ? head + "First to \(evHalf(t.clinch)) of \(t.points) takes the cup."
      : head + "Add golfers to both teams to set the target."
  }

  /// The taunt opt-in — the control's words and the line under it (the web's
  /// `ryderNotify` button). A standing push must be CHOSEN, and the ask names
  /// THIS WEEK'S opponent: "Tell me when he posts" assumed a gender the
  /// product has no business assuming (W2, category C, critique-B P2). With
  /// no pairing this week it asks for "my opponent".
  public struct Taunt: Sendable, Equatable {
    public let label: String
    public let gloss: String
  }

  public static func taunt(on: Bool, opponent: String?) -> Taunt {
    if on { return Taunt(label: "Mute the taunts", gloss: "You hear it the moment your opponent posts.") }
    return Taunt(label: opponent.map { "Tell me when \($0) posts" } ?? "Tell me when my opponent posts",
                 gloss: "Nothing pings you until you ask for it.")
  }

  /// This week's opponent, by first name (`oppFirst`): the other side of my
  /// duel in the OPEN week. nil with no open week, no pairing yet, or a
  /// golfer the room cannot name (`—`).
  public static func thisWeeksOpponent(_ room: EventRoom, me: EventPlayer) -> String? {
    guard let open = room.sessions.first(where: \.isOpen),
          let duel = room.duels.first(where: { $0.session_id == open.id && ($0.a_player == me.id || $0.b_player == me.id) })
    else { return nil }
    let name = room.player(duel.a_player == me.id ? duel.b_player : duel.a_player).name
      .trimmingCharacters(in: .whitespaces)
    guard !name.isEmpty, name != "—" else { return nil }
    return name.split(whereSeparator: \.isWhitespace).first.map(String.init)
  }

  /// S5-02: before anything closes, Session 1 is the story — read top-down.
  /// Once results exist, newest-first puts the live session on top.
  public static func ordered(_ sessions: [EventSession]) -> [EventSession] {
    let anyClosed = sessions.contains { $0.isClosed }
    return sessions.sorted { anyClosed ? $0.session_no > $1.session_no : $0.session_no < $1.session_no }
  }

  /// `Week 2 · Sep 6 – Sep 12` — the section head's LABEL.
  ///
  /// The status left it: a section head names its count ONCE, in the slot to
  /// the right of the rule (§16A.2), and `sessionSlot` is what goes there. The
  /// dash is a spaced EN DASH, never `→` (`LINT-13`).
  public static func sessionHeader(_ s: EventSession, calendar: Calendar = .current) -> String {
    "Week \(s.session_no) · \(EventDates.windowSpaced(s.opens_on, s.closes_on, calendar: calendar))"
  }

  /// The week head's right-hand slot: `Open` · `Closed` · `Ahead`.
  public static func sessionSlot(_ s: EventSession) -> String {
    s.isOpen ? "Open" : s.isClosed ? "Closed" : "Ahead"
  }

  /// `vs` · `def.` · `halved`.
  public static func mid(_ result: String) -> String {
    switch result {
    case "halve": "halved"
    // side A always stands on the left, so a B win read "A def. B" with only
    // the loser's tone saying otherwise: the sentence is true either way now
    // (the desk's `renderEvent`, the same fix)
    case "a": "def."
    case "b": "lost to"
    default: "vs"
    }
  }

  /// One duel row's chip and its nag entries (12300–12312): a resolved duel
  /// prints `+2.1 / –0.4`; a pending duel in an OPEN session prints the number
  /// to beat with `—` for "not posted" and lists the idle side as still to post.
  public struct DuelChip: Sendable, Equatable {
    public let text: String?
    public let waiting: [String]
    public init(text: String?, waiting: [String]) { self.text = text; self.waiting = waiting }
  }

  public static func chip(_ d: EventDuel, sessionOpen: Bool, target: EventTarget?, aName: String, bName: String) -> DuelChip {
    var text: String? = nil
    if d.a_pvi != nil || d.b_pvi != nil {
      text = "\(d.a_pvi.map(sgn) ?? "–") / \(d.b_pvi.map(sgn) ?? "–")"
    }
    var waiting: [String] = []
    if d.isPending && sessionOpen, let t = target {
      text = "\(t.a.map(sgn) ?? "—") / \(t.b.map(sgn) ?? "—")"
      if t.a == nil { waiting.append(aName) }
      if t.b == nil { waiting.append(bName) }
    }
    return DuelChip(text: text, waiting: waiting)
  }

  /// `Still to post: X, Y · 3d left.` / `… · closes tonight.`
  public static func nagLine(waiting: [String], closesOn: String, today: String = CSDate.today(), calendar: Calendar = .current) -> String? {
    guard !waiting.isEmpty else { return nil }
    let days = max(0, EventDates.daysUntil(closesOn, today: today, calendar: calendar) ?? 0)
    return "Still to post: \(waiting.joined(separator: ", ")) · \(days == 0 ? "closes tonight" : "\(days)d left")."
  }

  /// `recOf(pid)` — won, lost and halved, from every resolved duel the player
  /// sat in.
  public static func recordCounts(of player: UUID, duels: [EventDuel]) -> (won: Int, lost: Int, halved: Int) {
    var w = 0, l = 0, h = 0
    for d in duels where !d.isPending {
      if d.a_player == player { if d.result == "a" { w += 1 } else if d.result == "b" { l += 1 } else { h += 1 } }
      else if d.b_player == player { if d.result == "b" { w += 1 } else if d.result == "a" { l += 1 } else { h += 1 } }
    }
    return (w, l, h)
  }

  /// "w-l-h" — the roster row's figure.
  public static func record(of player: UUID, duels: [EventDuel]) -> String {
    let r = recordCounts(of: player, duels: duels)
    return "\(r.won)-\(r.lost)-\(r.halved)"
  }

  /// W2 · THE ROSTER'S LEGEND IS SAID ONCE (owner P, craft T, category Sp):
  /// every row repeated it after its own figure. The side draws it once above
  /// its rows; the row keeps the figure.
  public static let recordLegend = "Won, lost, halved"

  /// …and each row says its own record in words to VoiceOver, where a legend
  /// drawn once cannot follow it (the web's row label):
  /// `Avery Fixture, captain: 1 won, 0 lost, 1 halved`.
  public static func rosterSpoken(name: String, captain: Bool, of player: UUID, duels: [EventDuel]) -> String {
    let r = recordCounts(of: player, duels: duels)
    return "\(name)\(captain ? ", captain" : ""): \(r.won) won, \(r.lost) lost, \(r.halved) halved"
  }

  /// `ryderPair` (16317): 0 pairs used to toast "Pairings set" while the
  /// session read "Pairings not set." — say what actually happened.
  public static func pairingsToast(_ pairs: Int) -> String {
    pairs > 0 ? "Pairings set" : "Both teams need golfers first — no pairings made."
  }

  public static func tauntToast(on: Bool) -> String {
    on ? "Taunts on — you'll hear the moment your opponent posts" : "Taunts muted"
  }

  /// `Scrap "X"? …` — the two-tap arm's question, from state (16266).
  public static func scrapQuestion(_ name: String) -> String {
    "Scrap \"\(name)\"? It hasn't been scored, so this removes it, its board and its field completely."
  }

  // MARK: - the title card (UI_SYSTEM §15.5)

  /// The live eyebrow: `Live · week 2 of 3 · 2 days left`.
  ///
  /// **A COUNTDOWN IS NOT A SCORE** (§15.5a). `3½`, `2½` and `2 DAYS LEFT` sat
  /// under one rule "as if they were one class of number"; the rail is the two
  /// side scores and the deadline lives here, with the other time facts. A
  /// finished event drops the clock and the dot and reads `Final · Sat Sep 26`.
  public static func eyebrow(_ room: EventRoom, today: String = CSDate.today(), calendar: Calendar = .current) -> String {
    if room.event.isComplete {
      let last = ordered(room.sessions).map(\.closes_on).max()
      return "Final" + (last.map { " · \(EventDates.dowMonthDay($0, calendar: calendar))" } ?? "")
    }
    var s = statusChip(room)
    if let open = room.sessions.first(where: { $0.isOpen }),
       let d = EventDates.daysUntil(open.closes_on, today: today, calendar: calendar), d >= 0 {
      s += d == 0 ? " · closes tonight" : " · \(d) day\(d == 1 ? "" : "s") left"
    }
    return s
  }

  /// The dateline's second line: `Sun Sep 6 – Sat Sep 26 · six in the field`.
  ///
  /// One block by §1.5's counting rule — a dateline that wraps is still one
  /// dateline — and the field SIZE belongs to it, not to the roster, because
  /// the roster now carries two squad names instead (§15.5a, finding 4).
  public static func dateline(_ room: EventRoom, calendar: Calendar = .current) -> String {
    let opens = room.sessions.map(\.opens_on).min()
    let closes = room.sessions.map(\.closes_on).max()
    var parts: [String] = []
    if let o = opens, let c = closes {
      parts.append("\(EventDates.dowMonthDay(o, calendar: calendar)) – \(EventDates.dowMonthDay(c, calendar: calendar))")
    } else if let start = room.event.starts_on {
      parts.append("From \(EventDates.dowMonthDay(start, calendar: calendar))")
    }
    let n = room.players.count
    if n > 0 { parts.append("\(spelled(n)) playing") }
    return parts.joined(separator: " · ")
  }

  /// The counting words a dateline uses. Past ten it is a numeral: "eighteen
  /// in the field" is a sentence nobody reads and "18 in the field" is a fact.
  public static func spelled(_ n: Int) -> String {
    let words = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
    return n >= 0 && n <= 10 ? words[n] : String(n)
  }

  /// The stakes line's tail: `The pot · 60/25/15 · best round each week`.
  /// The FIGURE is drawn separately, in gold, because the pot is the surface's
  /// one gold object and it is gold ink on a numeral — never a fill, never a
  /// chip (§2 D).
  public static func stakesTail(potSplit: String?) -> String {
    "The pot · \(potSplit == "wta" ? "winner takes all" : "60/25/15") · best round each week"
  }
}

// MARK: - The Major

public enum MajorMath {
  /// A JS number printed: 4 → "4", 4.2 → "4.2".
  static func jsNum(_ v: Double) -> String {
    v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
  }

  /// `mjVs(n)` — PvI in words: +4.2 → "4.2 UNDER", −1 → "1 OVER", 0 → "LEVEL", nil → "—".
  public static func vs(_ n: Double?) -> String {
    guard let n else { return "—" }
    let r = (n * 10).rounded() / 10
    if r == 0 { return "LEVEL" }
    return jsNum(abs(r)) + (r > 0 ? " UNDER" : " OVER")
  }

  /// `mjMoney(n)` — "$20" · "$12.50".
  public static func money(_ n: Double?) -> String {
    let v = ((n ?? 0) * 100).rounded() / 100
    return "$" + (v == v.rounded(.down) ? String(Int(v)) : String(format: "%.2f", v))
  }

  /// The facts the room derives once (12377–12392).
  public struct Facts: Sendable, Equatable {
    public let session: EventSession?
    public let days: Int              // window length
    public let daysLeft: Int?         // 0 = the final day; negative = awaiting the horn
    public let when: String           // "JUL 9–JUL 12"
    public let complete: Bool
    public let horn: Bool             // any session closed
    public let contenders: Int
    public let field: Int
    public let buyIn: Double
    public let pot: Double
    public let champion: MajorBoardRow?
    public let championCard: MajorCard?
    public let opensAhead: Bool       // d0 > today

    public init(session: EventSession?, days: Int, daysLeft: Int?, when: String, complete: Bool, horn: Bool, contenders: Int,
                field: Int, buyIn: Double, pot: Double, champion: MajorBoardRow?, championCard: MajorCard?, opensAhead: Bool) {
      self.session = session; self.days = days; self.daysLeft = daysLeft; self.when = when; self.complete = complete; self.horn = horn
      self.contenders = contenders; self.field = field; self.buyIn = buyIn; self.pot = pot; self.champion = champion
      self.championCard = championCard; self.opensAhead = opensAhead
    }
  }

  public static func facts(_ room: EventRoom, today: String = CSDate.today(), calendar: Calendar = .current) -> Facts {
    let s = room.sessions.first
    let days = s.map { (CSDate.days(from: $0.opens_on, to: $0.closes_on, calendar: calendar) ?? 0) + 1 } ?? 0
    let daysLeft = s.flatMap { EventDates.daysUntil($0.closes_on, today: today, calendar: calendar) }
    let opensAhead = s.flatMap { EventDates.daysUntil($0.opens_on, today: today, calendar: calendar) }.map { $0 > 0 } ?? false
    let complete = room.event.isComplete
    let champCard = room.majorCards.first { $0.rank == 1 }
    let champ = champCard.flatMap { c in room.majorBoard.first { $0.playerId == c.player_id } }
    let contenders = room.majorBoard.filter { !$0.exhibition }.count
    let buyIn = room.event.buy_in ?? 0
    return Facts(session: s, days: days, daysLeft: daysLeft,
                 when: s.map { EventDates.window($0.opens_on, $0.closes_on, calendar: calendar) } ?? "",
                 complete: complete, horn: room.anyClosed, contenders: contenders, field: room.majorBoard.count,
                 buyIn: buyIn, pot: buyIn * Double(contenders), champion: champ, championCard: champCard, opensAhead: opensAhead)
  }

  /// `OPENS SATURDAY` · `OPENS JUL 10` · `FORMING` · `LIVE · 2D LEFT` ·
  /// `THE FINAL DAY` · `WAITING TO SETTLE` · `NAME TAKES THE JUG` ·
  /// `SETTLED — NO CARDS`.
  ///
  /// **D252 · two of these were the room's private language and are now plain
  /// words.** `AWAITING THE HORN` said nothing to a golfer who had not been
  /// told what the horn was; the state it names is "the window has closed and
  /// nobody has settled it", so it says that. And the forming chip names the
  /// DAY when the day is inside the coming week — `OPENS SATURDAY` is the
  /// sentence the terminology table asks for, and it is only true there, so
  /// past a week the chip keeps the date it always had rather than claiming a
  /// weekday eight days out that reads as this Saturday.
  public static func statusChip(status: String, complete: Bool, championName: String?, daysLeft: Int?, opensAhead: Bool,
                                opensOn: String?, today: String = CSDate.today(), calendar: Calendar = .current) -> String {
    if complete { return championName.map { $0.uppercased() + " TAKES THE JUG" } ?? "SETTLED — NO CARDS" }
    if status == "setup" {
      if daysLeft != nil, opensAhead, let o = opensOn {
        let out = CSDate.days(from: today, to: o, calendar: calendar)
        if let n = out, n >= 0, n <= 6 { return "OPENS " + EventDates.weekdayLong(o, calendar: calendar).uppercased() }
        return "OPENS " + EventDates.monthDayUpper(o, calendar: calendar)
      }
      return "FORMING"
    }
    guard let d = daysLeft else { return "WAITING TO SETTLE" }
    if d > 0 { return "LIVE · \(d)D LEFT" }
    if d == 0 { return "THE FINAL DAY" }
    return "WAITING TO SETTLE"
  }

  public static func statusChip(_ room: EventRoom, _ f: Facts, today: String = CSDate.today(), calendar: Calendar = .current) -> String {
    statusChip(status: room.event.status, complete: f.complete, championName: f.champion?.displayName, daysLeft: f.daysLeft,
               opensAhead: f.opensAhead, opensOn: f.session?.opens_on, today: today, calendar: calendar)
  }

  /// D61 — "THE 2ND ANNUAL · CASEY DEFENDS". nil until the chain has two editions.
  public static func lineageLine(lineage: [EventLineageRow], eventId: UUID, complete: Bool) -> String? {
    let chain = lineage.filter { $0.isMajor }
    guard chain.count > 1, let idx = chain.firstIndex(where: { $0.eventId == eventId }) else { return nil }
    let priors = chain.filter { $0.isComplete && $0.eventId != eventId && $0.champion != nil }
    let last = priors.last
    var s = "THE \(RyderMath.nthUp(idx + 1)) ANNUAL"
    if let last, !complete, let c = last.champion { s += " · \(c.uppercased()) DEFENDS" }
    return s
  }

  /// The champions roll — prior settled editions with a champion.
  public static func priors(lineage: [EventLineageRow], eventId: UUID) -> [EventLineageRow] {
    lineage.filter { $0.isMajor && $0.isComplete && $0.eventId != eventId && $0.champion != nil }
  }

  /// `82 · 2 cards` (+ ` · $60` after settle).
  public static func cardsLine(gross: Int?, cards: Int, prize: Double? = nil, exhibition: Bool = false) -> String {
    var s = (gross.map { "\($0) · " } ?? "") + "\(cards) card\(cards == 1 ? "" : "s")"
    if let p = prize, p > 0 { s += " · \(money(p))" }
    if exhibition { s += " · " + unofficial }
    return s
  }

  // MARK: the room's head and sections (PAR-28 · one producer, both clients)

  /// TERMINOLOGY §2.3's words for a card that is on the board and not in the
  /// running — never "Exhibition", and never an "EX" mark in the rank slot.
  public static let unofficial = "doesn’t count this year"

  /// The section heads, in TERMINOLOGY's Major row: the leaderboard is what
  /// it is (D252), and a card that does not count says so in words.
  public enum Head {
    public static let board = "Leaderboard"
    /// the leaderboard head's count slot while the window is open
    public static let live = "Live"
    public static let final = "Final"
    public static let unofficial = "Doesn’t count this year"
    public static let noCard = "No card"
    public static let stillToPost = "Still to post"
  }

  /// The pot figure's caption (D273 — the figure carries its own caption):
  /// the stake each, then the split in bare dollars, `$20 each · 48 / 20 /
  /// 12`. The shares are the settlement's own cents (`PotMath.trioCents`: the
  /// runner-up and the points king round, the champion absorbs), so the
  /// caption says what the pot pays; winner-takes-all says so. The web's
  /// `mjPotCaption` (root's ruling on N4-212).
  public static func potCaption(buyIn: Double, pot: Double, potSplit: String?) -> String {
    if potSplit == "wta" { return money(buyIn) + " each · winner takes all" }
    let t = PotMath.trioCents(potCents: PotMath.jsRound(pot * 100), payout: [60, 25, 15])
    let bare = { (c: Int) in String(PotMath.money(c).dropFirst()) }
    return money(buyIn) + " each · " + [t.champ, t.runner, t.king].map(bare).joined(separator: " / ")
  }

  /// The dateline's second line: the window, then the field in words —
  /// `Sep 26 – Sep 29 · five playing`. nil when there is neither.
  public static func windowLine(window: String?, field: Int) -> String? {
    let parts = [window, field > 0 ? "\(RyderMath.spelled(field)) playing" : nil].compactMap { $0 }
    return parts.isEmpty ? nil : parts.joined(separator: " · ")
  }

  /// `No cards yet — first one leads.` (D252: "the clubhouse" was the room's
  /// private name for the leaderboard, and the leaderboard is what it is.)
  public static func noCardsLine(live: Bool) -> String {
    "No cards yet\(live ? " — first one leads" : "")."
  }

  /// `Still to post: X, Y · 2d left.` / `… · cards in by tonight.`
  /// D252 / A-5: "card" is the noun on the board; "post" is the verb and the
  /// state everywhere else in the product, and one act has one word.
  public static func stillToPost(_ names: [String], daysLeft: Int) -> String {
    "Still to post: \(names.joined(separator: ", ")) · \(daysLeft == 0 ? "cards in by tonight" : "\(daysLeft)d left")."
  }

  /// The fine print — chosen, not discovered (D45).
  public static func finePrint(buyIn: Double, potSplit: String?) -> String {
    var s = "The fine print. 18-hole cards only; scored by how far you beat your playing HCP. An established number (3 posted rounds) contends for the jug"
    s += buyIn > 0 ? " and the pot" : ""
    s += "; newer golfers don't count this year — on the board, official by the next one. Ties settle on countback: second-best card, then earliest posted, then a logged coin flip."
    // D297 · the ledger line is `MoneyCopy.ledger`, never retyped (LINT-23);
    // twin of `renderMajorRoom()`'s fine print.
    if buyIn > 0 { s += " \(potSplit == "wta" ? "Winner takes it" : "60/25/15, top three"). \(MoneyCopy.ledger)" }
    return s
  }

  /// The share caption (12581).
  public static func shareText(name: String, jug: String, gross: Int?, pvi: Double?) -> String {
    "\(name) takes \(jug) — \(gross.map { String($0) } ?? "—"), \(vs(pvi).lowercased()) their playing HCP · cupseason.app"
  }

  /// The setup sheet's window line: "Thu, Jul 9 – Sun, Jul 12 · best round by Sunday night".
  public static func whenLine(finalOn: String, days: Int, calendar: Calendar = .current) -> String? {
    guard let start = EventDates.isoPlus(finalOn, -(days - 1), calendar: calendar) else { return nil }
    return "\(EventDates.weekdayMonthDay(start, calendar: calendar)) \u{2013} \(EventDates.weekdayMonthDay(finalOn, calendar: calendar)) · best round by \(EventDates.weekdayLong(finalOn, calendar: calendar)) night"
  }

  /// `openMajorSetup`'s create failure (16133): the skew line in the house
  /// form, else `BoardText.humanError` — never "Create failed: " + the raw
  /// text (D297 class 5: the machine's voice at the source).
  public static func createFailure(_ error: Error) -> String {
    let raw = (error as? RpcError)?.underlying ?? String(describing: error)
    return raw.range(of: "create_major|function|schema cache", options: [.regularExpression, .caseInsensitive]) != nil
      ? "The Major needs the latest update — try again shortly."
      : BoardText.humanError(error, "Could not set the Major.")
  }
}

// MARK: - The picker and the chips

public enum EventCopy {
  /// `evStat` (9668, 15481): Final · Forming · Live.
  public static func status(_ status: String) -> String {
    status == "complete" ? "Final" : status == "setup" ? "Forming" : "Live"
  }

  /// The chip's sub: `Ryder · Live` · `Major · I’m in`.
  /// D252 · "Enter the field" is the room's word for joining; the control the
  /// golfer taps says **I’m in**, here and in the Major's room, and nowhere
  /// are there two verbs for one act.
  public static let joinVerb = "I’m in"

  public static func chipSub(_ e: EventSummary) -> String {
    (e.isMajor ? "Major" : "Ryder") + " · " + (e.mine ? status(e.status) : joinVerb)
  }

  /// The switcher row's sub (15483): `A Major · Live` · `The Ryder · Forming`.
  public static func switcherSub(_ e: EventSummary) -> String {
    (e.isMajor ? "A Major" : "The Ryder") + " · " + (e.mine ? status(e.status) : joinVerb)
  }

  /// Compete's moment row (IA §6.1). The noun, then the state — or, for a
  /// moment I have not joined, the fact that the door is open. Never a
  /// countdown: the row's clock is a sort key, not a sentence (L-22).
  public static func momentLine(kind: String, status s: String, mine: Bool) -> String {
    let noun = kind == "major" ? "A Major" : "The Ryder"
    return noun + " · " + (mine ? status(s) : "open to you")
  }
}
