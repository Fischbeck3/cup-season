// Cup Season — the `game_result` envelope (D78; index.html 8017–8027,
// 8191–8318, 9015–9108) and the highlights derived from it (8076–8091).
//
// "The server branches on `game` and `story`, the share page and the D92
// scorecard read `holes`. Changing it orphans every settled round." So the
// builders here produce EXACTLY the web's shapes, key for key, and every string
// (`story` for the board, `share` for a text thread) is the web's verbatim.

import Foundation

/// `holeLedger(mode, cells, played, closedOut, hot, legend)` (8017).
public struct LiveLedger: Sendable, Equatable {
  public let n: Int
  public let played: Int
  /// 'sides' · 'players' · 'wolf'
  public let mode: String
  public let cells: [LiveCell?]
  /// the hole the match ended on
  public let closed: Int?
  /// which key is hot — a string ('a'/'b'/'w') or a player index
  public let hot: LiveCell?
  public let legend: String?

  public init(mode: String, cells: [LiveCell?], played: Int, closedOut: Bool, hot: LiveCell?, legend: String?, holes: Int) {
    let c = Array(cells.prefix(holes == 9 ? 9 : 18))
    n = holes == 9 ? 9 : 18
    self.played = played != 0 ? played : c.count
    self.mode = mode
    self.cells = c
    closed = closedOut ? (played != 0 ? played : c.count) : nil
    self.hot = hot
    self.legend = legend
  }

  public var json: JSONValue {
    var o: [String: JSONValue] = [:]
    o["n"] = .number(Double(n)); o["played"] = .number(Double(played)); o["mode"] = .string(mode)
    o["cells"] = .array(cells.map { $0?.json ?? .null })
    o["closed"] = closed.map { .number(Double($0)) } ?? .null
    o["hot"] = hot?.json ?? .null
    o["legend"] = legend.map { .string($0) } ?? .null
    return .object(o)
  }

  /// Read one back from a stored `game_result.holes` (the recap of a resumed
  /// finish, the share page).
  public init?(_ v: JSONValue?) {
    guard let v, case .object = v, let cells = v["cells"]?.array else { return nil }
    n = max(1, v["n"]?.int ?? 18)
    played = v["played"]?.int ?? cells.count
    mode = v["mode"]?.string ?? ""
    self.cells = cells.map { LiveCell($0.isNull ? nil : $0) }
    closed = v["closed"]?.int
    hot = LiveCell(v["hot"].flatMap { $0.isNull ? nil : $0 })
    legend = v["legend"]?.string
  }

  /// `holeHighlights` (8076): at most three, longest run first.
  public var highlights: [String] {
    guard !cells.isEmpty else { return [] }
    let hotKey = hot?.key
    var out: [String] = []
    var best = 0, bestEnd = -1, run = 0
    for (i, v) in cells.enumerated() {
      if let v, let hotKey, v.key == hotKey { run += 1; if run > best { best = run; bestEnd = i } } else { run = 0 }
    }
    if best >= 3 { out.append("WON \(best) STRAIGHT · \(bestEnd - best + 2)-\(bestEnd + 1)") }
    let halved = cells.filter { $0 == .h }.count
    if halved >= 4 { out.append("\(halved) HOLES HALVED") }
    if let closed { out.append("CLOSED OUT ON \(closed)") }
    return Array(out.prefix(3))
  }

  /// The strip's footer (8062): "CLOSED ON n" or "THRU n".
  public var footer: String { closed.map { "CLOSED ON \($0)" } ?? "THRU \(played)" }
}

/// A named transfer on the recap: "A PAYS B $x".
public struct LiveTransferNamed: Sendable, Equatable {
  public let from: String, to: String, amt: Double
  public init(from: String, to: String, amt: Double) { self.from = from; self.to = to; self.amt = amt }
}

/// The finished game, typed for the recap AND carried as the exact JSON.
public struct LiveResult: Sendable, Equatable {
  public let game: LiveGame
  public let solo: Bool
  public let winner: String?
  public let status: String?
  public let sideA: String?
  public let sideB: String?
  public let stake: Double
  /// team Sunningdale: signed bank
  public let bank: Int?
  /// solo Sunningdale: the bank's one owner
  public let bankOwner: Int?
  public let bankUnits: Int?
  public let playerNames: [String]
  public let transfers: [LiveTransferNamed]
  public let holes: LiveLedger?
  public let story: String
  public let share: String
  public let json: JSONValue

  /// `isTeamMatch` on the recap (9195): two sides unless it is a solo mode.
  public var isTeamMatch: Bool { !solo && (game == .match || game == .sunningdale) }
}

public enum LiveResultBuilder {
  static func names(_ s: LiveRoundState, _ t: Int) -> String {
    s.teams[t].compactMap { $0 < s.players.count ? s.players[$0].n : nil }.joined(separator: " & ")
  }
  static func fnSide(_ s: LiveRoundState, _ t: Int) -> String {
    s.teams[t].compactMap { $0 < s.players.count ? LiveFmt.fn1(s.players[$0].n) : nil }.joined(separator: " & ")
  }
  static func js(_ v: Double) -> String { LiveFmt.js(v) }

  static func transfersJSON(_ t: [LiveEngines.Transfer], _ s: LiveRoundState) -> ([LiveTransferNamed], JSONValue) {
    let named = t.map { LiveTransferNamed(from: s.players[$0.from].n, to: s.players[$0.to].n, amt: $0.amt) }
    return (named, .array(named.map { .object(["from": .string($0.from), "to": .string($0.to), "amt": .number($0.amt)]) }))
  }

  /// `gameResult()` (9100): the one router.
  public static func gameResult(_ s: LiveRoundState) -> LiveResult? {
    let n = s.players.count
    if s.game == .match, s.solo, n == 4 { return roundRobin(s) }
    if s.game == .sunningdale, s.solo, n == 4 { return sunningdaleSolo(s) }
    if s.game == .match { return match(s) }
    if s.game == .wolf, n == 4 { return wolf(s) }
    if s.game == .skins, n >= 2 { return skins(s) }
    if s.game == .sunningdale, n == 2 || n == 4 { return sunningdale(s) }
    return nil
  }

  /// `matchResult` (9015).
  public static func match(_ s: LiveRoundState) -> LiveResult {
    let m = LiveEngines.match(scores: s.scores, strokes: s.strokeTable, teams: s.teams, holes: s.liveHoles)
    var winner: Int?
    let status: String
    if let c = m.closed { winner = c.winner; status = "\(c.lead)&\(c.rem)" }
    else if m.a != m.b { winner = m.a > m.b ? 0 : 1; status = "\(abs(m.a - m.b)) UP THRU \(m.played)" }
    else { status = "HALVED" }
    let stake = s.stake
    let st = status.lowercased()
    let story = winner == nil
      ? "All square — \(names(s, 0)), \(names(s, 1))\(stake > 0 ? " · nobody pays" : "")"
      : "\(names(s, winner!)) def. \(names(s, winner! == 0 ? 1 : 0)) \(st)\(stake > 0 ? " · $\(js(stake)) on the line" : "")"
    let share = winner == nil
      ? "All square - \(fnSide(s, 0)), \(fnSide(s, 1))"
      : "\(fnSide(s, winner!)) beat \(fnSide(s, winner! == 0 ? 1 : 0)) \(st)\(stake > 0 ? " for $\(js(stake))" : "")"
    let ledger = LiveLedger(mode: "sides", cells: m.cells, played: m.played, closedOut: m.closed != nil,
                            hot: winner.map { $0 == 0 ? .a : .b }, legend: winner.map { names(s, $0) }, holes: s.liveHoles)
    var o: [String: JSONValue] = [:]
    o["game"] = .string("match"); o["winner"] = winner.map { .string(String($0)) } ?? .null; o["status"] = .string(status)
    o["a"] = .number(Double(m.a)); o["b"] = .number(Double(m.b)); o["thru"] = .number(Double(m.played)); o["stake"] = .number(stake)
    o["side_a"] = .string(names(s, 0)); o["side_b"] = .string(names(s, 1))
    o["holes"] = ledger.json; o["story"] = .string(story); o["share"] = .string(share)
    let json: JSONValue = .object(o)
    return LiveResult(game: .match, solo: false, winner: winner.map(String.init), status: status, sideA: names(s, 0), sideB: names(s, 1),
                      stake: stake, bank: nil, bankOwner: nil, bankUnits: nil, playerNames: s.players.map(\.n), transfers: [],
                      holes: ledger, story: story, share: share, json: json)
  }

  /// `rrResult` (8251).
  public static func roundRobin(_ s: LiveRoundState) -> LiveResult {
    let pairs = LiveEngines.roundRobin(scores: s.scores, strokes: s.strokeTable, holes: s.liveHoles)
    let rec = LiveEngines.rrRecords(pairs, count: s.players.count)
    let stake = s.stake
    let line = s.players.enumerated().map { i, p in "\(p.n) \(rec[i].line)" }.joined(separator: ", ")
    let rank = s.players.enumerated().map { (n: $1.n, w: rec[$0].w, l: rec[$0].l) }.sorted { $0.w > $1.w }
    let co = rank.filter { $0.w == rank[0].w }
    func hd(_ f: (String) -> String) -> String {
      if rank[0].w == 0 { return "Nobody won a match" }
      if co.count > 1 { return "\(co.map { f($0.n) }.joined(separator: " and ")) split it, \(rank[0].w) win\(rank[0].w == 1 ? "" : "s") each" }
      return "\(f(rank[0].n)) won the round robin, \(rank[0].w)-\(rank[0].l)"
    }
    let pts = rec.map { $0.w - $0.l }
    let (named, tj) = transfersJSON(LiveEngines.settleTransfers(pts: pts, val: stake), s)
    let story = "\(hd { $0 }) · \(line)\(stake > 0 ? " · $\(js(stake)) a match" : "")"
    let share = hd { LiveFmt.fn1($0) }
    let playersJSON: [JSONValue] = s.players.enumerated().map { i, p in
      var q: [String: JSONValue] = [:]
      q["name"] = .string(p.n); q["w"] = .number(Double(rec[i].w)); q["l"] = .number(Double(rec[i].l)); q["h"] = .number(Double(rec[i].h))
      return .object(q)
    }
    let pairsJSON: [JSONValue] = pairs.map { p in
      var q: [String: JSONValue] = [:]
      q["a"] = .string(s.players[p.i].n); q["b"] = .string(s.players[p.j].n); q["up"] = .number(Double(p.a - p.b)); q["thru"] = .number(Double(p.played))
      return .object(q)
    }
    var o: [String: JSONValue] = [:]
    o["game"] = .string("match"); o["mode"] = .string("solo"); o["stake"] = .number(stake)
    o["transfers"] = tj; o["players"] = .array(playersJSON); o["pairs"] = .array(pairsJSON)
    o["story"] = .string(story); o["share"] = .string(share)
    let json: JSONValue = .object(o)
    return LiveResult(game: .match, solo: true, winner: nil, status: nil, sideA: nil, sideB: nil, stake: stake, bank: nil, bankOwner: nil, bankUnits: nil,
                      playerNames: s.players.map(\.n), transfers: named, holes: nil, story: story, share: share, json: json)
  }

  /// `wolfResult` (9049).
  public static func wolf(_ s: LiveRoundState) -> LiveResult {
    let val = s.stake
    let order = s.wolfOrder ?? [0, 1, 2, 3]
    let pts = LiveEngines.wolfPoints(order: order, picks: s.wolf, scores: s.scores, strokes: s.strokeTable, holes: s.liveHoles)
    let line = s.players.enumerated().map { i, p in
      val > 0 ? "\(p.n) \(pts[i] >= 0 ? "+" : "-")$\(js(abs(Double(pts[i]) * val)))" : "\(p.n) \(pts[i] >= 0 ? "+" : "")\(pts[i])"
    }.joined(separator: ", ")
    let rank = pts.enumerated().map { (v: $1, i: $0) }.sorted { $0.v > $1.v }
    let tied = rank.count > 1 && rank[1].v == rank[0].v
    let lead: (v: Int, i: Int)? = (tied || !(rank[0].v > 0)) ? nil : rank[0]
    let (named, tj) = transfersJSON(LiveEngines.settleTransfers(pts: pts, val: val), s)
    let cells = LiveEngines.wolfCells(order: order, picks: s.wolf, scores: s.scores, strokes: s.strokeTable, holes: s.liveHoles)
    let ledger = LiveLedger(mode: "wolf", cells: cells, played: 0, closedOut: false, hot: .w, legend: "the wolf's side", holes: s.liveHoles)
    let story = lead == nil
      ? "Wolf ended level · \(line)\(val > 0 ? " · $\(js(val))/pt" : " pts")"
      : "\(s.players[lead!.i].n) took Wolf\(val > 0 ? ", up $\(js(Double(lead!.v) * val))" : ", \(lead!.v) pts") · \(line)\(val > 0 ? " · $\(js(val))/pt" : "")"
    let share = lead == nil ? "Wolf ended level" : "\(LiveFmt.fn1(s.players[lead!.i].n)) took Wolf\(val > 0 ? ", up $\(js(Double(lead!.v) * val))" : "")"
    let playersJSON: [JSONValue] = s.players.enumerated().map { i, p in
      .object(["name": .string(p.n), "pts": .number(Double(pts[i]))])
    }
    var o: [String: JSONValue] = [:]
    o["game"] = .string("wolf"); o["stake"] = .number(val); o["players"] = .array(playersJSON)
    o["transfers"] = tj; o["holes"] = ledger.json; o["story"] = .string(story); o["share"] = .string(share)
    let json: JSONValue = .object(o)
    return LiveResult(game: .wolf, solo: false, winner: nil, status: nil, sideA: nil, sideB: nil, stake: val, bank: nil, bankOwner: nil, bankUnits: nil,
                      playerNames: s.players.map(\.n), transfers: named, holes: ledger, story: story, share: share, json: json)
  }

  /// `skinsResult` (9076).
  public static func skins(_ s: LiveRoundState) -> LiveResult {
    let val = s.stake
    let sk = LiveEngines.skins(scores: s.scores, strokes: s.strokeTable, holes: s.liveHoles)
    struct SkinsP { let name: String; let skins: Int; let pts: Int; let idx: Int }
    let ps: [SkinsP] = s.players.enumerated().map { SkinsP(name: $1.n, skins: sk.won[$0], pts: sk.pts[$0], idx: $0) }
    let winners = ps.filter { $0.skins > 0 }
    let line = winners.isEmpty ? "nobody took a skin" : winners.map { "\($0.name) \($0.skins)" }.joined(separator: ", ")
    let died = sk.carry > 1 ? " · \(sk.carry - 1) carried died" : ""
    let rank = winners.sorted { $0.skins > $1.skins }
    let lead: SkinsP? = (!rank.isEmpty && !(rank.count > 1 && rank[1].skins == rank[0].skins)) ? rank[0] : nil
    func took(_ f: (String) -> String, _ t: SkinsP) -> String {
      let money = (val > 0 && t.pts > 0) ? " and $\(js(Double(t.pts) * val))" : ""
      return "\(f(t.name)) took \(t.skins) skin\(t.skins == 1 ? "" : "s")\(money)"
    }
    let (named, tj) = transfersJSON(LiveEngines.settleTransfers(pts: sk.pts, val: val), s)
    let ledger = LiveLedger(mode: "players", cells: sk.cells, played: sk.thru, closedOut: false,
                            hot: lead.map { .player($0.idx) }, legend: lead?.name, holes: s.liveHoles)
    let rate = val > 0 ? " · $\(js(val)) a skin" : ""
    let story: String
    if let lead { story = "\(took({ $0 }, lead)) · \(line)\(rate)\(died)" }
    else if !winners.isEmpty { story = "The skins split — \(line)\(rate)\(died)" }
    else { story = "Nobody took a skin\(died)" }
    let share = lead.map { took({ LiveFmt.fn1($0) }, $0) } ?? (winners.isEmpty ? "Nobody took a skin" : "The skins split")
    let playersJSON: [JSONValue] = ps.map { p in
      .object(["name": .string(p.name), "skins": .number(Double(p.skins)), "pts": .number(Double(p.pts))])
    }
    var o: [String: JSONValue] = [:]
    o["game"] = .string("skins"); o["stake"] = .number(val); o["thru"] = .number(Double(sk.thru))
    o["carried_died"] = .number(Double(max(0, sk.carry - 1)))
    o["players"] = .array(playersJSON); o["transfers"] = tj; o["holes"] = ledger.json
    o["story"] = .string(story); o["share"] = .string(share)
    let json: JSONValue = .object(o)
    return LiveResult(game: .skins, solo: false, winner: nil, status: nil, sideA: nil, sideB: nil, stake: val, bank: nil, bankOwner: nil, bankUnits: nil,
                      playerNames: s.players.map(\.n), transfers: named, holes: ledger, story: story, share: share, json: json)
  }

  /// `sunnResult` (8191).
  public static func sunningdale(_ s: LiveRoundState) -> LiveResult {
    let m = LiveEngines.sunningdale(scores: s.scores, teams: s.teams, holes: s.liveHoles)
    var winner: Int?
    let status: String
    if let c = m.closed { winner = c.winner; status = "\(c.lead)&\(c.rem)" }
    else if m.a != m.b { winner = m.a > m.b ? 0 : 1; status = "\(abs(m.a - m.b)) up thru \(m.played)" }
    else { status = "halved" }
    let unit = s.stake
    let bankTxt = m.bank == 0 ? "bank empty"
      : "bank: \(names(s, m.bank > 0 ? 0 : 1))\(unit > 0 ? " $\(js(Double(abs(m.bank)) * unit))" : " \(abs(m.bank)) unit\(abs(m.bank) == 1 ? "" : "s")")"
    let pot = Double(abs(m.bank)) * unit
    let story = winner == nil
      ? "All square — \(names(s, 0)), \(names(s, 1)). Sunningdale Rules · \(bankTxt)"
      : "\(names(s, winner!)) def. \(names(s, winner! == 0 ? 1 : 0)) \(status). Sunningdale Rules · \(bankTxt)"
    let share = winner == nil
      ? "All square - \(fnSide(s, 0)), \(fnSide(s, 1))"
      : "\(fnSide(s, winner!)) beat \(fnSide(s, winner! == 0 ? 1 : 0)) \(status)\(pot > 0 ? " for $\(js(pot))" : "")"
    let ledger = LiveLedger(mode: "sides", cells: m.cells, played: m.played, closedOut: m.closed != nil,
                            hot: winner.map { $0 == 0 ? .a : .b }, legend: winner.map { names(s, $0) }, holes: s.liveHoles)
    var o: [String: JSONValue] = [:]
    o["game"] = .string("sunningdale"); o["winner"] = winner.map { .string(String($0)) } ?? .null; o["status"] = .string(status)
    o["a"] = .number(Double(m.a)); o["b"] = .number(Double(m.b)); o["thru"] = .number(Double(m.played))
    o["bank"] = .number(Double(m.bank)); o["unit"] = .number(unit)
    o["side_a"] = .string(names(s, 0)); o["side_b"] = .string(names(s, 1))
    o["story"] = .string(story); o["share"] = .string(share); o["holes"] = ledger.json
    let json: JSONValue = .object(o)
    return LiveResult(game: .sunningdale, solo: false, winner: winner.map(String.init), status: status, sideA: names(s, 0), sideB: names(s, 1),
                      stake: unit, bank: m.bank, bankOwner: nil, bankUnits: nil, playerNames: s.players.map(\.n), transfers: [],
                      holes: ledger, story: story, share: share, json: json)
  }

  /// `sunnSoloResult` (8288).
  public static func sunningdaleSolo(_ s: LiveRoundState) -> LiveResult {
    let m = LiveEngines.sunningdaleSolo(scores: s.scores, holes: s.liveHoles)
    let unit = s.stake
    let order = m.wins.indices.sorted { m.wins[$0] > m.wins[$1] }
    let line = order.map { "\(s.players[$0].n) \(m.wins[$0])" }.joined(separator: ", ")
    let bankTxt = m.bankUnits == 0 ? "bank empty"
      : "bank: \(s.players[m.bankOwner].n)\(unit > 0 ? " $\(js(Double(m.bankUnits) * unit)) (each owes)" : " \(m.bankUnits) unit\(m.bankUnits == 1 ? "" : "s")")"
    let top = order[0]
    let tied = order.count > 1 && m.wins[order[1]] == m.wins[top]
    let lead: Int? = (tied || !(m.wins[top] > 0)) ? nil : top
    let pot = Double(m.bankUnits) * unit
    let ledger = LiveLedger(mode: "players", cells: m.cells, played: m.played, closedOut: false,
                            hot: lead.map { .player($0) }, legend: lead.map { s.players[$0].n }, holes: s.liveHoles)
    let story = lead == nil
      ? "Nobody broke away — \(line). Sunningdale Rules · \(bankTxt)"
      : "\(s.players[lead!].n) took it, \(m.wins[lead!]) holes. Sunningdale Rules · \(line) · \(bankTxt)"
    let share = lead == nil ? "Nobody broke away"
      : (pot > 0 ? "\(LiveFmt.fn1(s.players[lead!].n)) won the most holes and $\(js(pot)) from each"
                 : "\(LiveFmt.fn1(s.players[lead!].n)) won the most holes, \(m.wins[lead!])")
    let playersJSON: [JSONValue] = s.players.enumerated().map { i, p in
      .object(["name": .string(p.n), "wins": .number(Double(m.wins[i]))])
    }
    var o: [String: JSONValue] = [:]
    o["game"] = .string("sunningdale"); o["mode"] = .string("solo"); o["unit"] = .number(unit); o["thru"] = .number(Double(m.played))
    o["players"] = .array(playersJSON)
    o["bank"] = .object(["owner": .number(Double(m.bankOwner)), "units": .number(Double(m.bankUnits))])
    o["holes"] = ledger.json; o["story"] = .string(story); o["share"] = .string(share)
    let json: JSONValue = .object(o)
    return LiveResult(game: .sunningdale, solo: true, winner: nil, status: nil, sideA: nil, sideB: nil, stake: unit, bank: nil,
                      bankOwner: m.bankOwner, bankUnits: m.bankUnits, playerNames: s.players.map(\.n), transfers: [],
                      holes: ledger, story: story, share: share, json: json)
  }
}

// MARK: - the recap's money line (9205–9256)

public extension LiveResult {
  static func isPair(_ s: String?) -> Bool { (s ?? "").range(of: #"\s&\s"#, options: .regularExpression) != nil }
  static func payVerb(_ s: String?) -> String { isPair(s) ? "PAY" : "PAYS" }
  static func takeVerb(_ s: String?) -> String { isPair(s) ? "TAKE" : "TAKES" }

  /// The settlement headline (the `<b>` line) and its money sub-line.
  var recapRow: (icon: String, line: String, money: String) {
    let js = LiveFmt.js
    if isTeamMatch {
      let won = winner != nil
      let wSide = winner == "0" ? sideA : sideB, lSide = winner == "0" ? sideB : sideA
      let line = won ? "\(wSide ?? "") def. \(lSide ?? "") \(status ?? "")" : "All square — \(sideA ?? ""), \(sideB ?? "")"
      let money: String
      if game == .sunningdale {
        let sunnBank = Double(abs(bank ?? 0)) * stake
        if sunnBank > 0 {
          let bankSide = (bank ?? 0) > 0 ? (sideA ?? "") : (sideB ?? "")
          money = "\(bankSide.uppercased()) \(LiveResult.takeVerb(bankSide)) THE BANK - $\(js(sunnBank))"
        } else { money = "BRAGGING RIGHTS ONLY" }
      } else if stake > 0 {
        money = won ? "\((lSide ?? "").uppercased()) \(LiveResult.payVerb(lSide)) \((wSide ?? "").uppercased()) $\(js(stake)) · SETTLE UP" : "ALL SQUARE — NO MONEY MOVES"
      } else { money = "BRAGGING RIGHTS ONLY" }
      return ("⚔️", line, money)
    }
    let icon = game == .wolf ? "🐺" : game == .skins ? "💰" : "⚔️"
    let money: String
    if game == .sunningdale {
      let soloBank = Double(bankUnits ?? 0) * stake
      if soloBank > 0, let o = bankOwner, o < playerNames.count {
        money = "\(playerNames[o].uppercased()) HOLDS THE BANK - $\(js(soloBank)) FROM EACH"
      } else { money = "BRAGGING RIGHTS ONLY" }
    } else if stake > 0 {
      money = transfers.isEmpty ? "ALL SQUARE — NO MONEY MOVES"
        : transfers.map { "\($0.from.uppercased()) PAYS \($0.to.uppercased()) $\(js($0.amt))" }.joined(separator: " · ") + " · SETTLE UP"
    } else { money = "BRAGGING RIGHTS ONLY" }
    return (icon, share.isEmpty ? story : share, money)
  }
}
