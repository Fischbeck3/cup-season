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

  /// `Forming` · `Live · wk k/N` · `NAME TAKES THE CUP` · `SHARED — BOTH NAMES ON IT`.
  public static func statusChip(status: String, winnerTeamId: UUID?, teamA: EventTeam, teamB: EventTeam,
                                closedSessions: Int, sessionCount: Int?) -> String {
    if status == "complete" {
      if let w = winnerTeamId { return (w == teamA.id ? teamA.name : teamB.name).uppercased() + " TAKES THE CUP" }
      return "SHARED — BOTH NAMES ON IT"
    }
    if status == "setup" { return "Forming" }
    let n = sessionCount ?? 0
    return "Live · wk \(min(closedSessions + 1, n))/\(n)"
  }

  public static func statusChip(_ room: EventRoom) -> String {
    statusChip(status: room.event.status, winnerTeamId: room.event.winner_team_id, teamA: room.teamA, teamB: room.teamB,
               closedSessions: room.sessions.filter { $0.isClosed }.count, sessionCount: room.event.session_count)
  }

  /// `FINAL · 6½–4½` · `FIRST TO 9½ · RED NEEDS 3 · BLUE NEEDS 5`.
  public static func clinchLine(status: String, aPoints: Double, bPoints: Double, clinch: Double, aName: String, bName: String) -> String {
    if status == "complete" { return "FINAL · \(evHalf(aPoints))–\(evHalf(bPoints))" }
    return "FIRST TO \(evHalf(clinch)) · \(aName.uppercased()) NEEDS \(evHalf(max(0, clinch - aPoints))) · \(bName.uppercased()) NEEDS \(evHalf(max(0, clinch - bPoints)))"
  }

  public static func clinchLine(_ room: EventRoom) -> String {
    let t = target(room)
    return clinchLine(status: room.event.status, aPoints: room.points(room.teamA.id), bPoints: room.points(room.teamB.id),
                      clinch: t.clinch, aName: room.teamA.name, bName: room.teamB.name)
  }

  /// D62 — the series line: editions counted, the cup defended. nil until the
  /// chain has more than one edition, or when this event is not in it.
  public static func seriesLine(lineage: [EventLineageRow], eventId: UUID, status: String, aName: String, bName: String) -> String? {
    let chain = lineage.filter { !$0.isMajor }
    guard chain.count > 1, let idx = chain.firstIndex(where: { $0.eventId == eventId }) else { return nil }
    let pos = idx + 1
    let priors = chain.filter { $0.isComplete && $0.eventId != eventId }
    var aW = 0.0, bW = 0.0
    for r in priors {
      if r.winnerShared { aW += 0.5; bW += 0.5 }
      else if r.winnerSlot == 0 { aW += 1 }
      else if r.winnerSlot == 1 { bW += 1 }
    }
    let series: String = aW == bW ? "SERIES LEVEL \(evHalf(aW))–\(evHalf(bW))"
      : aW > bW ? "\(aName.uppercased()) LEADS THE SERIES \(evHalf(aW))–\(evHalf(bW))"
      : "\(bName.uppercased()) LEADS THE SERIES \(evHalf(bW))–\(evHalf(aW))"
    var hold = ""
    if status != "complete", let last = priors.last {
      if last.winnerShared { hold = " · THE CUP IS SHARED" }
      else if last.winnerSlot == 0 { hold = " · \(aName.uppercased()) DEFENDS" }
      else if last.winnerSlot == 1 { hold = " · \(bName.uppercased()) DEFENDS" }
    }
    return "THE \(nthUp(pos)) RYDER · \(series)\(hold)"
  }

  /// How it scores — everyone sees the rule, not just the organizer (12257).
  public static func ruleSentence(_ t: Target) -> String {
    let head = "Each session pairs everyone 1‑on‑1; best round that week vs your index wins the point, a tie splits it. "
    return t.pairings > 0
      ? head + "First to \(evHalf(t.clinch)) of \(t.points) takes the cup."
      : head + "Add players to both teams to set the target."
  }

  /// The taunt toggle's label (12266).
  public static func tauntLabel(on: Bool) -> String {
    "🔔 Duel taunts: " + (on ? "ON — mute them" : "OFF — ping me when my opponent posts")
  }

  /// S5-02: before anything closes, Session 1 is the story — read top-down.
  /// Once results exist, newest-first puts the live session on top.
  public static func ordered(_ sessions: [EventSession]) -> [EventSession] {
    let anyClosed = sessions.contains { $0.isClosed }
    return sessions.sorted { anyClosed ? $0.session_no > $1.session_no : $0.session_no < $1.session_no }
  }

  /// `SESSION 2 · JUL 6–JUL 12 · OPEN`.
  public static func sessionHeader(_ s: EventSession, calendar: Calendar = .current) -> String {
    "SESSION \(s.session_no) · \(EventDates.window(s.opens_on, s.closes_on, calendar: calendar)) · \(s.status.uppercased())"
  }

  /// `vs` · `def.` · `halved`.
  public static func mid(_ result: String) -> String {
    switch result {
    case "halve": "halved"
    case "a", "b": "def."
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

  /// `recOf(pid)` — "w-l-h" from every resolved duel the player sat in.
  public static func record(of player: UUID, duels: [EventDuel]) -> String {
    var w = 0, l = 0, h = 0
    for d in duels where !d.isPending {
      if d.a_player == player { if d.result == "a" { w += 1 } else if d.result == "b" { l += 1 } else { h += 1 } }
      else if d.b_player == player { if d.result == "b" { w += 1 } else if d.result == "a" { l += 1 } else { h += 1 } }
    }
    return "\(w)-\(l)-\(h)"
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

  /// `FORMING · OPENS JUL 10` · `FORMING` · `LIVE · 2D LEFT` · `THE FINAL DAY` ·
  /// `AWAITING THE HORN` · `NAME TAKES THE JUG` · `SETTLED — NO CARDS`.
  public static func statusChip(status: String, complete: Bool, championName: String?, daysLeft: Int?, opensAhead: Bool,
                                opensOn: String?, calendar: Calendar = .current) -> String {
    if complete { return championName.map { $0.uppercased() + " TAKES THE JUG" } ?? "SETTLED — NO CARDS" }
    if status == "setup" {
      if daysLeft != nil, opensAhead, let o = opensOn { return "FORMING · OPENS " + EventDates.monthDayUpper(o, calendar: calendar) }
      return "FORMING"
    }
    guard let d = daysLeft else { return "AWAITING THE HORN" }
    if d > 0 { return "LIVE · \(d)D LEFT" }
    if d == 0 { return "THE FINAL DAY" }
    return "AWAITING THE HORN"
  }

  public static func statusChip(_ room: EventRoom, _ f: Facts, calendar: Calendar = .current) -> String {
    statusChip(status: room.event.status, complete: f.complete, championName: f.champion?.displayName, daysLeft: f.daysLeft,
               opensAhead: f.opensAhead, opensOn: f.session?.opens_on, calendar: calendar)
  }

  /// The card's three lines (12398–12404).
  public static func cardLines(days: Int, when: String, field: Int, contenders: Int, buyIn: Double, pot: Double, potSplit: String?) -> [String] {
    let ex = field != contenders ? " (\(field - contenders) EXHIBITION)" : ""
    let stakes = buyIn > 0
      ? "BUY-IN \(money(buyIn)) · POT \(money(pot)) · \(potSplit == "wta" ? "WINNER TAKES ALL" : "60 / 25 / 15")"
      : "BRAGGING RIGHTS"
    return ["A MAJOR · \(days) DAYS", "\(when) · FIELD OF \(field)\(ex)", stakes]
  }

  /// D61 — "THE 2ND ANNUAL · MARCUS DEFENDS". nil until the chain has two editions.
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
    if exhibition { s += " · exhibition" }
    return s
  }

  /// `No cards yet — first one takes the clubhouse.`
  public static func noCardsLine(live: Bool) -> String {
    "No cards yet\(live ? " — first one takes the clubhouse" : "")."
  }

  /// `Still to card: X, Y · 2d left.` / `… · cards in by tonight.`
  public static func stillToCard(_ names: [String], daysLeft: Int) -> String {
    "Still to card: \(names.joined(separator: ", ")) · \(daysLeft == 0 ? "cards in by tonight" : "\(daysLeft)d left")."
  }

  /// The fine print — chosen, not discovered (D45).
  public static func finePrint(buyIn: Double, potSplit: String?) -> String {
    var s = "The fine print. 18-hole cards only; scored by how far you beat your own number. An established number (3 posted rounds) contends for the jug"
    s += buyIn > 0 ? " and the pot" : ""
    s += "; newer golfers play exhibition — on the board, official by the next one. Ties settle on countback: second-best card, then earliest posted, then a logged coin flip."
    if buyIn > 0 { s += " Pot is a ledger — \(potSplit == "wta" ? "winner takes it" : "60/25/15, top three"); money moves between friends." }
    return s
  }

  /// The share caption (12581).
  public static func shareText(name: String, jug: String, gross: Int?, pvi: Double?) -> String {
    "\(name) takes \(jug) — \(gross.map { String($0) } ?? "—"), \(vs(pvi).lowercased()) their number · cupseason.app"
  }

  /// The setup sheet's window line: "Thu, Jul 9 → Sun, Jul 12 · best card by Sunday night".
  public static func whenLine(finalOn: String, days: Int, calendar: Calendar = .current) -> String? {
    guard let start = EventDates.isoPlus(finalOn, -(days - 1), calendar: calendar) else { return nil }
    return "\(EventDates.weekdayMonthDay(start, calendar: calendar)) → \(EventDates.weekdayMonthDay(finalOn, calendar: calendar)) · best card by \(EventDates.weekdayLong(finalOn, calendar: calendar)) night"
  }

  /// `openMajorSetup`'s create failure (16133): the skew line, else the raw text.
  public static func createFailure(_ message: String) -> String {
    message.range(of: "create_major|function|schema cache", options: [.regularExpression, .caseInsensitive]) != nil
      ? "The Major needs the database update first — one push away"
      : "Create failed: " + message
  }
}

// MARK: - The picker and the chips

public enum EventCopy {
  /// `evStat` (9668, 15481): Final · Forming · Live.
  public static func status(_ status: String) -> String {
    status == "complete" ? "Final" : status == "setup" ? "Forming" : "Live"
  }

  /// The Clubhouse chip's sub: `Ryder · Live` · `Major · Enter the field`.
  public static func chipSub(_ e: EventSummary) -> String {
    (e.isMajor ? "Major" : "Ryder") + " · " + (e.mine ? status(e.status) : "Enter the field")
  }

  /// The switcher row's sub (15483): `A Major · Live` · `The Ryder · Forming`.
  public static func switcherSub(_ e: EventSummary) -> String {
    (e.isMajor ? "A Major" : "The Ryder") + " · " + (e.mine ? status(e.status) : "Enter the field")
  }
}
