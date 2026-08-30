// Cup Season — every line the live round speaks, ported verbatim from
// `renderPlay` / `renderScoreboard` / `renderMatchPrev` / `renderResumeBanner`
// / `finishRealLiveRound` (index.html 7710–7735, 7862–7870, 8386–8589,
// 8604–8654, 8660–8719, 9109–9177).
//
// Pure functions of `LiveRoundState`, so the words a card shows are testable
// without a view, and the scoreboard's hero line borrows the same words the
// cards speak (D85).

import Foundation

public enum LiveCopy {

  // MARK: - the match card (8445–8511)

  public struct GameCard: Sendable, Equatable {
    public let teams: String
    public let status: String
    public let meta: String
  }

  static func up(_ s: String) -> String { s.uppercased() }
  static func sideNames(_ s: LiveRoundState, _ t: Int, sep: String) -> String {
    s.teams[t].compactMap { $0 < s.players.count ? s.players[$0].n : nil }.joined(separator: sep)
  }

  /// `#matchCard` — match play, round robin, Sunningdale team + solo.
  public static func matchCard(_ s: LiveRoundState) -> GameCard? {
    let n = s.players.count
    let js = LiveFmt.js
    if s.game == .match, s.solo, n == 4 {
      let pairs = LiveEngines.roundRobin(scores: s.scores, strokes: s.strokeTable, holes: s.liveHoles)
      let rec = LiveEngines.rrRecords(pairs, count: n)
      let thru = pairs.map(\.played).min() ?? 0
      let order = rec.indices.sorted { (rec[$0].w - rec[$0].l) > (rec[$1].w - rec[$1].l) }
      let status = order.map { "\(up(s.players[$0].n)) \(rec[$0].line)" }.joined(separator: " · ")
      let meta = "THRU \(thru) · 6 MATCHES · STROKES OFF LOW MAN" + (s.stake > 0 ? " · $\(js(s.stake)) A MATCH" : "") + (s.course.siEst ? " · EST. CARD" : "")
      return GameCard(teams: "Match play · round robin · everyone for themselves", status: status, meta: meta)
    }
    if s.game == .match {
      let teamA = up(sideNames(s, 0, sep: " & ")), teamB = up(sideNames(s, 1, sep: " & "))
      let chs = s.courseHandicaps
      let li = chs.firstIndex(of: s.lowCH) ?? -1
      let lowMan = li >= 0 ? up(s.players[li].n) : ""
      let teams = n == 2
        ? "Match play · singles · \(s.players[0].n) vs \(s.players[1].n)"
        : "Match play · net best ball · \(sideNames(s, 0, sep: " + ")) vs \(sideNames(s, 1, sep: " + "))"
      let m = LiveEngines.match(scores: s.scores, strokes: s.strokeTable, teams: s.teams, holes: s.liveHoles)
      let status: String
      if let c = m.closed { status = "\(c.winner == 0 ? teamA : teamB) WIN \(c.lead)&\(c.rem)" }
      else if m.a == m.b { status = "ALL SQUARE" }
      else { status = "\(m.a > m.b ? teamA : teamB) \(abs(m.a - m.b)) UP\(m.dormie(holes: s.liveHoles) ? " · DORMIE" : "")" }
      let meta = "THRU \(m.played) · STROKES OFF LOW MAN (\(lowMan))" + (s.stake > 0 ? " · $\(js(s.stake)) A SIDE" : "") + (s.course.siEst ? " · EST. CARD" : "")
      return GameCard(teams: teams, status: status, meta: meta)
    }
    if s.game == .sunningdale, s.solo, n == 4 {
      let m = LiveEngines.sunningdaleSolo(scores: s.scores, holes: s.liveHoles)
      let unit = s.stake
      let order = m.wins.indices.sorted { m.wins[$0] > m.wins[$1] }
      let status = order.map { "\(up(s.players[$0].n)) \(m.wins[$0])" }.joined(separator: " · ")
      let sTxt = m.strokes.enumerated().compactMap { i, v in v > 0 ? "\(up(s.players[i].n)) +\(v)" : nil }.joined(separator: ", ")
      let bTxt = m.bankUnits == 0 ? "BANK EMPTY"
        : "BANK: \(up(s.players[m.bankOwner].n))\(unit > 0 ? " $\(js(Double(m.bankUnits) * unit)) · EACH OWES" : " \(m.bankUnits)U")"
      let meta = "THRU \(m.played) · NO HANDICAPS\(sTxt.isEmpty ? "" : " · \(sTxt) NEXT") · \(bTxt)"
      return GameCard(teams: "Sunningdale Rules · everyone for themselves", status: status, meta: meta)
    }
    if s.game == .sunningdale {
      let teamA = up(sideNames(s, 0, sep: " & ")), teamB = up(sideNames(s, 1, sep: " & "))
      let teams = n == 2
        ? "Sunningdale Rules · singles · \(s.players[0].n) vs \(s.players[1].n)"
        : "Sunningdale Rules · 2v2 best ball · \(sideNames(s, 0, sep: " + ")) vs \(sideNames(s, 1, sep: " + "))"
      let m = LiveEngines.sunningdale(scores: s.scores, teams: s.teams, holes: s.liveHoles)
      let status: String
      if let c = m.closed { status = "\(c.winner == 0 ? teamA : teamB) WIN \(c.lead)&\(c.rem)" }
      else if m.a == m.b { status = "ALL SQUARE" }
      else { status = "\(m.a > m.b ? teamA : teamB) \(abs(m.a - m.b)) UP" }
      let unit = s.stake
      let sTxt = m.strokes[0] > 0 ? " · \(teamA) GET \(m.strokes[0]) NEXT" : m.strokes[1] > 0 ? " · \(teamB) GET \(m.strokes[1]) NEXT" : ""
      let bTxt = m.bank == 0 ? " · BANK EMPTY"
        : " · BANK: \(m.bank > 0 ? teamA : teamB)\(unit > 0 ? " $\(js(Double(abs(m.bank)) * unit))" : " \(abs(m.bank))U")"
      return GameCard(teams: teams, status: status, meta: "THRU \(m.played) · NO HANDICAPS\(sTxt)\(bTxt)")
    }
    return nil
  }

  // MARK: - the wolf card (8512–8548)

  public struct WolfCard: Sendable, Equatable {
    public let wolf: Int
    public let comeback: Bool
    public let who: String
    public let meta: String
    /// the per-player tally
    public let pts: [Int]
  }

  public static func wolfCard(_ s: LiveRoundState) -> WolfCard? {
    guard s.game == .wolf, s.players.count == 4 else { return nil }
    let order = s.wolfOrder ?? [0, 1, 2, 3]
    let h = s.hole
    let w = LiveEngines.wolfAt(h: h, order: order, picks: s.wolf, scores: s.scores, strokes: s.strokeTable, holes: s.liveHoles)
    let comeback = h >= s.liveHoles - 2
    let who = up(s.players[w].n) + " IS THE WOLF" + (comeback ? " · COMEBACK" : "")
    let tees = LiveEngines.wolfTeeOrder(wolf: w, order: order).map { up(s.players[$0].n) }
    let meta = "TEES: " + tees.joined(separator: " · ") + (s.stake > 0 ? " · $\(LiveFmt.js(s.stake))/PT" : " · BRAGGING POINTS")
    let pts = LiveEngines.wolfPoints(order: order, picks: s.wolf, scores: s.scores, strokes: s.strokeTable, holes: s.liveHoles)
    return WolfCard(wolf: w, comeback: comeback, who: who, meta: meta, pts: pts)
  }

  // MARK: - the skins card (8549–8571)

  public struct SkinsCard: Sendable, Equatable {
    public let status: String
    public let meta: String
    /// D76 carry-heat: 2+ riding runs hot
    public let hot: Bool
    public let won: [Int]
    public let pts: [Int]
  }

  public static func skinsCard(_ s: LiveRoundState) -> SkinsCard? {
    guard s.game == .skins, s.players.count >= 2 else { return nil }
    let sk = LiveEngines.skins(scores: s.scores, strokes: s.strokeTable, holes: s.liveHoles)
    let H = s.liveHoles
    let status = sk.thru >= H
      ? (sk.carry > 1 ? "DONE · \(sk.carry - 1) SKIN\(sk.carry == 2 ? "" : "S") DIED CARRIED" : "DONE · EVERY SKIN CLAIMED")
      : "HOLE \(sk.thru + 1) WORTH \(sk.carry) SKIN\(sk.carry == 1 ? "" : "S")"
    let meta = "THRU \(sk.thru) · LOW NET TAKES IT" + (s.stake > 0 ? " · $\(LiveFmt.js(s.stake))/SKIN" : " · BRAGGING SKINS")
    return SkinsCard(status: status, meta: meta, hot: sk.thru < H && sk.carry >= 2, won: sk.won, pts: sk.pts)
  }

  // MARK: - the live settlement rows (8337)

  public struct SettleRow: Sendable, Equatable {
    public let label: String
    public let amount: String
  }

  /// `settleRows(pts, val)`.
  public static func settleRows(pts: [Int], stake: Double, names: [String]) -> [SettleRow] {
    guard stake > 0 else { return [SettleRow(label: "BRAGGING POINTS — NO MONEY ON IT", amount: "$0")] }
    let rows = LiveEngines.settleTransfers(pts: pts, val: stake).map {
      SettleRow(label: "\(names[$0.from].uppercased()) → \(names[$0.to].uppercased())", amount: "$\(LiveFmt.js($0.amt))")
    }
    return rows.isEmpty ? [SettleRow(label: "ALL SQUARE", amount: "$0")] : rows
  }

  /// The live `#settle` card's ledger for the game on the sheet.
  public static func liveSettle(_ s: LiveRoundState) -> [SettleRow]? {
    let names = s.players.map(\.n)
    if let w = wolfCard(s) { return settleRows(pts: w.pts, stake: s.stake, names: names) }
    if let k = skinsCard(s) { return settleRows(pts: k.pts, stake: s.stake, names: names) }
    return nil
  }

  // MARK: - the player row (8409–8432)

  public struct PlayerRow: Sendable, Equatable {
    public let name: String
    public let guest: Bool
    public let strokeDots: Int
    public let sub: String
    /// "84 THRU 9" or nil when nothing scored
    public let total: String?
    /// "+3"
    public let toPar: String?
    public let score: Int?
    public let birdie: Bool
  }

  public static func playerRow(_ s: LiveRoundState, _ pi: Int) -> PlayerRow {
    let p = s.players[pi]
    let h = s.hole
    let sc = s.scores[pi][h]
    let done = s.scores[pi].compactMap { $0 }
    let gross = done.reduce(0, +)
    let par = s.scores[pi].enumerated().reduce(0) { $1.element != nil ? $0 + s.course.pars[$1.offset] : $0 }
    let vp = gross - par
    let dots: Int
    if s.game == .sunningdale {
      dots = s.solo
        ? (LiveEngines.sunningdaleSoloStrokesAt(h: h, scores: s.scores, holes: s.liveHoles)[pi])
        : (LiveEngines.sunningdaleStrokesAt(h: h, scores: s.scores, teams: s.teams, holes: s.liveHoles)[s.teams[0].contains(pi) ? 0 : 1])
    } else { dots = s.strokeOn(pi, h) }
    let sub = s.game == .sunningdale ? "NO HCP · STRAIGHT UP"
      : "\(p.est ? "EST " : (p.guest ? "SELF " : ""))\(LiveFmt.idx(p.i)) IDX · \(s.strokes[pi]) STK"
    return PlayerRow(name: p.n, guest: p.guest, strokeDots: dots, sub: sub,
                     total: done.isEmpty ? nil : "\(gross) THRU \(done.count)",
                     toPar: done.isEmpty ? nil : (vp >= 0 ? "+\(vp)" : String(vp)),
                     score: sc, birdie: sc != nil && sc! < s.course.pars[h])
  }

  /// `HOLE n` · `PAR p · SI s`.
  public static func holeHeader(_ s: LiveRoundState) -> (num: String, meta: String) {
    ("HOLE \(s.hole + 1)", "PAR \(s.course.pars[s.hole]) · SI \(s.course.si[s.hole])")
  }

  // MARK: - the scoreboard (8604–8654)

  public struct Scoreboard: Sendable, Equatable {
    public struct Chip: Sendable, Equatable {
      public let name: String
      public let line: String
      public let lead: Bool
      public let present: Bool
    }
    public let hero: String
    public let chips: [Chip]
  }

  public static func scoreboard(_ s: LiveRoundState, presence: [String]) -> Scoreboard {
    let g = s.game
    let noH = g == .sunningdale
    let strokes = s.strokeTable
    func stat(_ i: Int) -> LiveEngines.NetPar {
      LiveEngines.netParThru(i, scores: s.scores, pars: s.course.pars, strokes: strokes, holes: s.liveHoles, noHandicap: noH)
    }
    var hero = ""
    if g == .match || g == .sunningdale { hero = matchCard(s)?.status ?? "" }
    else if let w = wolfCard(s) {
      hero = w.pts.indices.sorted { w.pts[$0] > w.pts[$1] }.map { "\(up(LiveFmt.fn1(s.players[$0].n))) \(LiveFmt.pm(w.pts[$0]))" }.joined(separator: " · ")
    } else if g == .skins, s.players.count >= 2 {
      let sk = LiveEngines.skins(scores: s.scores, strokes: strokes, holes: s.liveHoles)
      let won = s.players.enumerated().map { (n: up(LiveFmt.fn1($1.n)), w: sk.won[$0]) }.filter { $0.w > 0 }
        .sorted { $0.w > $1.w }.map { "\($0.n) \($0.w)" }.joined(separator: " · ")
      hero = won.isEmpty ? "NO SKINS CLAIMED YET" : won
      if sk.thru < s.liveHoles, sk.carry > 1 { hero += " · \(sk.carry) RIDING" }
    } else {
      let rows = s.players.indices.map { (i: $0, s: stat($0)) }.filter { $0.s.thru > 0 }
      if rows.isEmpty { hero = "ALL TO PLAY" }
      else {
        let sorted = rows.sorted { $0.s.net < $1.s.net }
        let tie = sorted.count > 1 && sorted[1].s.net == sorted[0].s.net
        hero = tie ? "ALL SQUARE THRU \(sorted.map(\.s.thru).min() ?? 0)"
          : "\(up(LiveFmt.fn1(s.players[sorted[0].i].n))) LEADS · \(LiveFmt.pm(sorted[0].s.net)) NET THRU \(sorted[0].s.thru)"
      }
    }
    let stats = s.players.indices.map { (p: s.players[$0], s: stat($0)) }
    let scored = stats.filter { $0.s.thru > 0 }
    let best = scored.map(\.s.net).min()
    let on = Set(presence)
    let chips = stats.map { x in
      let lead = best != nil && scored.count > 1 && x.s.thru > 0 && x.s.net == best!
      return Scoreboard.Chip(name: LiveFmt.fn1(x.p.n),
                             line: x.s.thru > 0 ? "\(LiveFmt.pm(x.s.net)) net · \(x.s.gross) thru \(x.s.thru)" : "—",
                             lead: lead, present: on.contains(x.p.n))
    }
    return Scoreboard(hero: hero.isEmpty ? "—" : hero, chips: chips)
  }

  /// `liveSyncBadge` (7862).
  public static func syncBadge(_ s: LiveRoundState, presence: [String], queued: Int) -> String {
    guard s.active else { return "" }
    guard s.code != nil else { return "Solo pencil · scores live on this phone" }
    let n = max(1, presence.count)
    return "\(n) on the sheet · \(queued > 0 ? "\(queued) queued" : "synced")"
  }

  // MARK: - the resume banner (7710–7735; D86)

  public struct ResumeBanner: Sendable, Equatable {
    public let invite: Bool
    public let kicker: String
    public let line: String
    public let meta: String
    public let go: String
  }

  public static func resumeBanner(_ s: LiveRoundState) -> ResumeBanner? {
    guard s.active, s.lr != nil, s.stage == .live else { return nil }
    let thru = s.thru
    let course = s.course.label.isEmpty ? "Your round" : s.course.label
    let invite = !s.mine
    let kicker = invite ? (s.host.map { "\(LiveFmt.fn1($0)) put you on the tee sheet" } ?? "You're on a tee sheet") : "Continue your round"
    let meta = thru > 0 ? "HOLE \(s.hole + 1) · THRU \(thru)" : (invite ? "JUST TEED OFF · NOTHING SCORED YET" : "HOLE \(s.hole + 1)")
    return ResumeBanner(invite: invite, kicker: kicker, line: "\(course.uppercased()) · \(s.game.banner.uppercased())", meta: meta, go: invite ? "JOIN" : "→")
  }

  // MARK: - the strokes preview (8660–8719)

  /// `renderMatchPrev` — the sides line + who gets strokes where, or the game's
  /// rules line, or the player-count constraint. Plain text; `**` marks bold.
  public static func preview(game: LiveGame, picked: [LivePlayer], pairing: Int, course: LiveCourseCard, holes: Int) -> String? {
    guard game.money else { return nil }
    let n = picked.count
    switch game {
    case .sunningdale:
      return (n == 2 || n == 4)
        ? "Straight up — nobody gets a shot for their index. Go 2 down and you get a stroke on each hole until you climb inside 1. Win a hole while ahead and you bank a unit; their comeback wins pull it back out."
        : "Sunningdale Rules takes 2 (singles) or 4 (2v2 best ball)."
    case .wolf:
      return n == 4
        ? "Wolf order shuffles at tee-off and locks. The wolf tees last, picks a partner after any drive — or goes lone for 3. Last two holes (\(holes == 9 ? "8–9" : "17–18")): last place is the wolf."
        : "Wolf needs exactly 4 players."
    case .skins:
      return (n >= 2 && n <= 4)
        ? "Low net wins the hole’s skin; a tie carries it — next hole is worth more. Strokes apply off the low man."
        : "Skins takes 2 to 4 players."
    case .match:
      if n != 2, n != 4 { return "Match play takes 2 (singles) or 4 (2v2 net best ball)." }
      let chs = picked.map { LiveEngines.jsRound($0.i * Double(course.effectiveSlope) / 113) }
      let low = chs.min() ?? 0
      let lowName = picked[chs.firstIndex(of: low) ?? 0].n
      let lines: [String] = picked.enumerated().compactMap { k, p in
        let stk = chs[k] - low
        if stk == 0 { return nil }
        if stk <= 6 {
          let hs = course.si.indices.filter { course.si[$0] <= stk }.map { $0 + 1 }.sorted()
          return "**\(p.n)** gets \(stk): hole\(stk == 1 ? "" : "s") \(hs.map(String.init).joined(separator: ", "))"
        }
        if stk < 18 { return "**\(p.n)** gets \(stk) — the \(stk) hardest holes" }
        if stk == 18 { return "**\(p.n)** gets a stroke on every hole" }
        return "**\(p.n)** gets \(stk) — a stroke every hole, two on the \(stk - 18) hardest"
      }
      let PP = LivePairings.all[max(0, min(2, pairing))]
      let sides = n == 2
        ? "**\(picked[0].n)** vs **\(picked[1].n)**"
        : "**\(picked[PP[0][0]].n) + \(picked[PP[0][1]].n)** vs **\(picked[PP[1][0]].n) + \(picked[PP[1][1]].n)** · net best ball"
      return sides + "\nStrokes off the low man (\(lowName))\(course.siEst ? " · estimated card — no real stroke index" : ""): "
        + (lines.isEmpty ? "everyone plays level — no strokes" : lines.joined(separator: " · ")) + "."
    case .score: return nil
    }
  }

  // MARK: - the finish sheet (9109–9150)

  public struct FinishSheet: Sendable, Equatable {
    public let intro: String
    /// "NAME — missing holes 3, 7 · …" in `neg`, or nil
    public let warning: String?
    public let primary: String
    public let secondary: String
    public let completeCards: Int
    public let guests: Int
  }

  /// `cardHoles(i)` — 18 | 9 | 0, the server's rule.
  public static func cardHoles(_ a: [Int?]) -> Int {
    let f9 = (0..<9).allSatisfy { a[$0] != nil }
    let b9 = (9..<18).allSatisfy { a[$0] != nil }
    let anyB = (9..<18).contains { a[$0] != nil }
    return (f9 && b9) ? 18 : (f9 && !anyB) ? 9 : 0
  }

  /// The seats that can post at all — a player mapped into the round.
  /// ONE definition, shared by the finish sheet and by the play view's sense of
  /// "is this round done"; two notions of finished is how a screen ends up
  /// promoting a button the sheet then refuses.
  public static func seatIndices(_ s: LiveRoundState) -> [Int] {
    s.players.indices.filter { s.pmap != nil && $0 < s.pmap!.count }
  }

  /// D153 · every seated card can post — i.e. the finish sheet would raise no
  /// warning. `cardHoles` is the rule (18 | 9 | 0, same as `finish_live_round`),
  /// so a clean front nine counts as done and a half-played back nine does not.
  public static func roundReadyToPost(_ s: LiveRoundState) -> Bool {
    let seats = seatIndices(s)
    return !seats.isEmpty && seats.allSatisfy { cardHoles(s.scores[$0]) > 0 }
  }

  public static func finishSheet(_ s: LiveRoundState) -> FinishSheet {
    let seats = seatIndices(s)
    // D107: league-less, an app golfer's complete card posts to their own
    // profile — count it; only account-less guests ride the claim-link path.
    let leagueless = s.leagueId == nil
    let done = seats.filter { (leagueless ? (!s.players[$0].guest || s.players[$0].pid != nil) : !s.players[$0].guest) && cardHoles(s.scores[$0]) > 0 }
    let open = seats.filter { cardHoles(s.scores[$0]) == 0 }
    let guestN = s.players.filter { $0.guest && (!leagueless || $0.pid == nil) }.count
    var warning: String?
    if !open.isEmpty {
      let parts = open.map { i -> String in
        let m = (0..<s.liveHoles).filter { s.scores[i][$0] == nil }.map { $0 + 1 }
        let shown = m.prefix(5).map(String.init).joined(separator: ", ")
        return "\(s.players[i].n.isEmpty ? "A player" : s.players[i].n) — missing hole\(m.count == 1 ? "" : "s") \(shown)\(m.count > 5 ? " +\(m.count - 5) more" : "")"
      }
      warning = parts.joined(separator: " · ") + ". \(open.count == 1 ? "That card" : "Those cards") won’t post — go back and fill in, or finish without."
    }
    let intro = "\(leagueless ? "Every complete card posts to its golfer" : "Complete cards post to the season"), attested by the group\(guestN > 0 ? "; \(guestN) guest\(guestN == 1 ? "" : "s") get\(guestN == 1 ? "s" : "") a recap to claim" : ""). A partial card is skipped, not lost."
    return FinishSheet(intro: intro, warning: warning,
                       primary: done.isEmpty ? (leagueless ? "Finish — no complete card to post" : "Finish — no complete member card to post")
                                             : "Post \(done.count) card\(done.count == 1 ? "" : "s")\(leagueless ? " — each to its golfer" : " to the season")",
                       secondary: "This one was casual — post nothing", completeCards: done.count, guests: guestN)
  }

  /// `p_cards` (9110): every seated player's 18 strokes.
  public static func cards(_ s: LiveRoundState) -> JSONValue {
    guard let pmap = s.pmap else { return .array([]) }
    return .array(s.players.indices.compactMap { i in
      guard i < pmap.count else { return nil }
      return .object(["player_id": .string(pmap[i].uuidString.lowercased()),
                      "strokes": .array(s.scores[i].map { $0.map { .number(Double($0)) } ?? .null })])
    })
  }
}

/// D75 — the three ways four players split (7252) and the court's swap rule (7255).
public enum LivePairings {
  public static let all: [[[Int]]] = [[[0, 1], [2, 3]], [[0, 2], [1, 3]], [[0, 3], [1, 2]]]

  public static func teams(pairing: Int) -> [[Int]] { all[max(0, min(2, pairing))] }

  /// `courtSwap(a,b)`: swap two positions across zones, re-derive the pairing
  /// from whoever partners position 0. Returns nil when the swap is illegal.
  public static func swap(pairing: Int, _ a: Int, _ b: Int) -> Int? {
    var T = teams(pairing: pairing)
    let za = T[0].contains(a) ? 0 : 1, zb = T[0].contains(b) ? 0 : 1
    guard za != zb, let ia = T[za].firstIndex(of: a), let ib = T[zb].firstIndex(of: b) else { return nil }
    T[za][ia] = b; T[zb][ib] = a
    let home = T[0].contains(0) ? T[0] : T[1]
    let partner = home[0] == 0 ? home[1] : home[0]
    return [1: 0, 2: 1, 3: 2][partner] ?? 0
  }
}
