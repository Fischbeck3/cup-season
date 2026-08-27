// Cup Season — the tee-sheet engines, PURE (index.html 7221–7236, 7944–8011,
// 8095–8178, 8235–8284, 8320–8336; audit 04 §5).
//
// "The engine math in §5 exactly — including the comeback wolf rule,
// carries-off/blind-off, skins dying at the last hole, Sunningdale deficit−1
// every hole and the bank's single-owner walk, round-robin w−l settlement,
// 9-hole halved CH." These are the ONLY client-side math the product allows,
// and they must match the web to the point. Every function takes plain arrays
// (scores 18-wide, nil = unplayed) so the web's test vectors port verbatim.

import Foundation

/// One cell of the D78 hole ledger.
public enum LiveCell: Sendable, Equatable {
  case a, b, h, c, w, o
  case player(Int)

  /// `String(v)` — the form the strip compares `hot` against.
  public var key: String {
    switch self {
    case .a: "a"
    case .b: "b"
    case .h: "h"
    case .c: "c"
    case .w: "w"
    case .o: "o"
    case .player(let i): String(i)
    }
  }
  /// The JSON the envelope carries — a string, or a NUMBER for a player index.
  public var json: JSONValue {
    if case .player(let i) = self { return .number(Double(i)) }
    return .string(key)
  }
  public init?(_ v: JSONValue?) {
    guard let v else { return nil }
    if let n = v.int { self = .player(n); return }
    switch v.string {
    case "a": self = .a
    case "b": self = .b
    case "h": self = .h
    case "c": self = .c
    case "w": self = .w
    case "o": self = .o
    case let s?: if let n = Int(s) { self = .player(n) } else { return nil }
    default: return nil
    }
  }
}

public enum LiveEngines {

  // MARK: - common (5.1)

  /// `recomputeStrokes` (7221): `Math.round(i × slope ÷ 113)`, halved for a nine.
  public static func courseHandicaps(indices: [Double], slope: Int, nine: Bool) -> [Int] {
    indices.map { jsRound($0 * Double(slope) / 113 / (nine ? 2 : 1)) }
  }

  /// JS `Math.round`: halves round toward +∞ (−2.5 → −2), unlike Swift's.
  static func jsRound(_ v: Double) -> Int { Int((v + 0.5).rounded(.down)) }

  /// `STROKES = CHS − LOWCH` — off the low man.
  public static func strokesOffLow(_ chs: [Int]) -> [Int] {
    let low = chs.min() ?? 0
    return chs.map { $0 - low }
  }

  /// `strokeOn(pi,h)` (7232): `floor(stk/H) + (SI[h] ≤ stk % H ? 1 : 0)` — wraps past the card.
  public static func strokeOn(stk: Int, si: [Int], h: Int, holes: Int) -> Int {
    let H = holes == 9 ? 9 : 18
    guard h < si.count else { return stk / H }
    return stk / H + (si[h] <= stk % H ? 1 : 0)
  }

  public static func strokeTable(strokes: [Int], si: [Int], holes: Int) -> [[Int]] {
    strokes.map { stk in (0..<18).map { strokeOn(stk: stk, si: si, h: $0, holes: holes) } }
  }

  /// `holeDone(h)` (7944): every player has a score.
  public static func holeDone(_ scores: [[Int?]], _ h: Int) -> Bool {
    !scores.isEmpty && scores.allSatisfy { h < $0.count && $0[h] != nil }
  }

  /// `netOf(pi,h)` (7945).
  public static func net(_ scores: [[Int?]], _ strokes: [[Int]], _ pi: Int, _ h: Int) -> Int {
    (scores[pi][h] ?? 0) - (pi < strokes.count && h < strokes[pi].count ? strokes[pi][h] : 0)
  }

  public struct Closeout: Sendable, Equatable {
    public let winner: Int, lead: Int, rem: Int
    public init(winner: Int, lead: Int, rem: Int) { self.winner = winner; self.lead = lead; self.rem = rem }
  }

  // MARK: - match play (5.2; `matchCalc` 7947)

  public struct Match: Sendable, Equatable {
    public let a: Int, b: Int, played: Int
    public let closed: Closeout?
    public let cells: [LiveCell]
    /// `_dormie` (8468): level on the wire — the lead equals the holes left.
    public func dormie(holes: Int) -> Bool { closed == nil && a != b && abs(a - b) == holes - played }
  }

  /// Net best ball per side; a<b → A takes the hole; ties halve; closes when lead > remaining.
  public static func match(scores: [[Int?]], strokes: [[Int]], teams: [[Int]], holes: Int) -> Match {
    var a = 0, b = 0, played = 0
    var closed: Closeout?
    var cells: [LiveCell] = []
    let H = holes == 9 ? 9 : 18
    for h in 0..<H {
      if !holeDone(scores, h) { break }
      let na = teams[0].map { net(scores, strokes, $0, h) }.min() ?? 0
      let nb = teams[1].map { net(scores, strokes, $0, h) }.min() ?? 0
      if na < nb { a += 1; cells.append(.a) } else if nb < na { b += 1; cells.append(.b) } else { cells.append(.h) }
      played = h + 1
      let lead = abs(a - b), rem = H - played
      if lead > rem, lead > 0 { closed = Closeout(winner: a > b ? 0 : 1, lead: lead, rem: rem); break }
    }
    return Match(a: a, b: b, played: played, closed: closed, cells: cells)
  }

  // MARK: - wolf (5.3; 7973–8011)

  /// `wolfAt(h)`: the shuffled order rotates; the last TWO holes go to current
  /// last place (the comeback rule) — read through the holes before it only.
  public static func wolfAt(h: Int, order: [Int], picks: [LiveWolfPick?], scores: [[Int?]], strokes: [[Int]], holes: Int) -> Int {
    let ord = order.count == 4 ? order : [0, 1, 2, 3]
    let H = holes == 9 ? 9 : 18
    if h < H - 2 { return ord[h % 4] }
    let pts = wolfPointsThrough(limit: h, order: ord, picks: picks, scores: scores, strokes: strokes, holes: holes, cells: nil).pts
    var worst = ord[0]
    for p in 0..<4 where pts[p] < pts[worst] { worst = p }
    return worst
  }

  public struct WolfTally: Sendable, Equatable {
    public let pts: [Int]
    /// index-aligned with holes when collected; nil = no pick or unplayed
    public let cells: [LiveCell?]
  }

  /// `wolfPointsThrough(limit, cells)`: partnered win ±1 each side; lone win
  /// wolf +3 / others −1; lone loss wolf −3 / others +1; halve 0. Carries OFF.
  public static func wolfPointsThrough(limit: Int, order: [Int], picks: [LiveWolfPick?], scores: [[Int?]], strokes: [[Int]], holes: Int,
                                       cells collect: Bool?) -> WolfTally {
    var pts = [0, 0, 0, 0]
    var cells: [LiveCell?] = []
    let collecting = collect == true
    for h in 0..<limit {
      guard let pick = (h < picks.count ? picks[h] : nil), holeDone(scores, h) else {
        if collecting { cells.append(nil) }
        continue
      }
      let w = wolfAt(h: h, order: order, picks: picks, scores: scores, strokes: strokes, holes: holes)
      let side: [Int] = pick.isLone ? [w] : [w, pick.partner ?? w]
      let opp = [0, 1, 2, 3].filter { !side.contains($0) }
      let ns = side.map { net(scores, strokes, $0, h) }.min() ?? 0
      let no = opp.map { net(scores, strokes, $0, h) }.min() ?? 0
      if ns == no { if collecting { cells.append(.h) }; continue }
      let win = ns < no
      if collecting { cells.append(win ? .w : .o) }
      if pick.isLone {
        if win { pts[w] += 3; for p in opp { pts[p] -= 1 } }
        else { pts[w] -= 3; for p in opp { pts[p] += 1 } }
      } else {
        for p in side { pts[p] += win ? 1 : -1 }
        for p in opp { pts[p] += win ? -1 : 1 }
      }
    }
    return WolfTally(pts: pts, cells: cells)
  }

  /// `wolfPoints()` — through every hole in play.
  public static func wolfPoints(order: [Int], picks: [LiveWolfPick?], scores: [[Int?]], strokes: [[Int]], holes: Int) -> [Int] {
    wolfPointsThrough(limit: holes == 9 ? 9 : 18, order: order, picks: picks, scores: scores, strokes: strokes, holes: holes, cells: nil).pts
  }

  /// `wolfCells()` — the ledger-collecting run, once at finish (D78).
  public static func wolfCells(order: [Int], picks: [LiveWolfPick?], scores: [[Int?]], strokes: [[Int]], holes: Int) -> [LiveCell?] {
    wolfPointsThrough(limit: holes == 9 ? 9 : 18, order: order, picks: picks, scores: scores, strokes: strokes, holes: holes, cells: true).cells
  }

  /// `wolfMeta` tee order (8515): the rotation shifted so the wolf tees last.
  public static func wolfTeeOrder(wolf: Int, order: [Int]) -> [Int] {
    let ord = order.count == 4 ? order : [0, 1, 2, 3]
    guard let k = ord.firstIndex(of: wolf) else { return ord }
    return Array(ord[(k + 1)...]) + Array(ord[...k])
  }

  // MARK: - skins (5.4; `skinsCalc` 8095)

  public struct Skins: Sendable, Equatable {
    public let won: [Int], pts: [Int], carry: Int, thru: Int
    public let cells: [LiveCell]
  }

  /// Lowest net alone takes `carry` skins; a tie carries. Net-zero ledger:
  /// `pts = won × n − total`. Carried skins die at the last hole played.
  public static func skins(scores: [[Int?]], strokes: [[Int]], holes: Int) -> Skins {
    let n = scores.count
    var won = Array(repeating: 0, count: n)
    var carry = 1, thru = 0
    var cells: [LiveCell] = []
    let H = holes == 9 ? 9 : 18
    for h in 0..<H {
      if !holeDone(scores, h) { break }
      let nets = (0..<n).map { net(scores, strokes, $0, h) }
      let mn = nets.min() ?? 0
      let winners = nets.indices.filter { nets[$0] == mn }
      if winners.count == 1 { won[winners[0]] += carry; carry = 1; cells.append(.player(winners[0])) }
      else { carry += 1; cells.append(.c) }
      thru = h + 1
    }
    let total = won.reduce(0, +)
    return Skins(won: won, pts: won.map { $0 * n - total }, carry: carry, thru: thru, cells: cells)
  }

  // MARK: - Sunningdale Rules (5.5; `sunnEngine` 8122, `sunnSoloEngine` 8150)

  public struct Sunningdale: Sendable, Equatable {
    public let a: Int, b: Int, played: Int
    public let closed: Closeout?
    /// signed: +N = side A holds N units
    public let bank: Int
    /// strokes for the UPCOMING hole
    public let strokes: [Int]
    public let cells: [LiveCell]
  }

  /// No handicaps. Entering a hole, the trailing side gets `max(0, deficit−1)`
  /// strokes on it. Best ball per side. A hole won while strictly ahead after
  /// winning banks a unit; the other side's qualifying win pulls one back.
  public static func sunningdale(scores: [[Int?]], teams: [[Int]], holes: Int) -> Sunningdale {
    let H = holes == 9 ? 9 : 18
    func done(_ h: Int) -> Bool { teams.allSatisfy { $0.allSatisfy { p in p < scores.count && h < scores[p].count && scores[p][h] != nil } } }
    var a = 0, b = 0, played = 0, bank = 0
    var closed: Closeout?
    var cells: [LiveCell] = []
    for h in 0..<H {
      if !done(h) { break }
      let dA = max(0, (b - a) - 1), dB = max(0, (a - b) - 1)
      let na = teams[0].map { scores[$0][h]! - dA }.min() ?? 0
      let nb = teams[1].map { scores[$0][h]! - dB }.min() ?? 0
      played = h + 1
      if na < nb { a += 1; if a > b { bank += 1 }; cells.append(.a) }
      else if nb < na { b += 1; if b > a { bank -= 1 }; cells.append(.b) }
      else { cells.append(.h) }
      let lead = abs(a - b), rem = H - played
      if lead > rem, lead > 0 { closed = Closeout(winner: a > b ? 0 : 1, lead: lead, rem: rem); break }
    }
    let strokes = closed != nil ? [0, 0] : [max(0, (b - a) - 1), max(0, (a - b) - 1)]
    return Sunningdale(a: a, b: b, played: played, closed: closed, bank: bank, strokes: strokes, cells: cells)
  }

  public struct SunningdaleSolo: Sendable, Equatable {
    public let wins: [Int], played: Int, strokes: [Int]
    public let bankOwner: Int, bankUnits: Int
    public let cells: [LiveCell]
  }

  /// D75 solo: own ball, outright low net wins (ties halve to nobody);
  /// strokes = `max(0, leader − you − 1)`; the bank has one owner.
  public static func sunningdaleSolo(scores: [[Int?]], holes: Int) -> SunningdaleSolo {
    let H = holes == 9 ? 9 : 18, n = scores.count
    var wins = Array(repeating: 0, count: n)
    var played = 0, bankOwner = 0, bankUnits = 0
    var cells: [LiveCell] = []
    for h in 0..<H {
      if scores.contains(where: { h >= $0.count || $0[h] == nil }) { break }
      let lead = wins.max() ?? 0
      let str = wins.map { max(0, (lead - $0) - 1) }
      let nets = scores.indices.map { scores[$0][h]! - str[$0] }
      let mn = nets.min() ?? 0
      let winners = nets.indices.filter { nets[$0] == mn }
      played = h + 1
      if winners.count == 1 {
        let w = winners[0]
        wins[w] += 1
        cells.append(.player(w))
        let others = wins.indices.filter { $0 != w }.map { wins[$0] }.max() ?? Int.min
        if wins[w] > others {
          if bankUnits == 0 || bankOwner == w { bankOwner = w; bankUnits += 1 } else { bankUnits -= 1 }
        }
      } else { cells.append(.h) }
    }
    let lead = wins.max() ?? 0
    return SunningdaleSolo(wins: wins, played: played, strokes: wins.map { max(0, (lead - $0) - 1) }, bankOwner: bankOwner, bankUnits: bankUnits, cells: cells)
  }

  /// `sunnStrokesAt(h)` (8188): the engine on the card truncated before h.
  public static func sunningdaleStrokesAt(h: Int, scores: [[Int?]], teams: [[Int]], holes: Int) -> [Int] {
    let cut = scores.map { row in row.indices.map { $0 < h ? row[$0] : nil } }
    return sunningdale(scores: cut, teams: teams, holes: holes).strokes
  }
  public static func sunningdaleSoloStrokesAt(h: Int, scores: [[Int?]], holes: Int) -> [Int] {
    let cut = scores.map { row in row.indices.map { $0 < h ? row[$0] : nil } }
    return sunningdaleSolo(scores: cut, holes: holes).strokes
  }

  // MARK: - round robin (D75; 8235–8250)

  public struct RRPair: Sendable, Equatable {
    public let i: Int, j: Int, a: Int, b: Int, played: Int
  }
  public struct RRRecord: Sendable, Equatable {
    public var w: Int, l: Int, h: Int
    /// "2-1" / "2-1-1"
    public var line: String { "\(w)-\(l)" + (h > 0 ? "-\(h)" : "") }
  }

  /// Every pairing its own singles, net, none close out early.
  public static func roundRobin(scores: [[Int?]], strokes: [[Int]], holes: Int) -> [RRPair] {
    let H = holes == 9 ? 9 : 18, n = scores.count
    var pairs: [RRPair] = []
    for i in 0..<n { for j in (i + 1)..<max(i + 1, n) {
      var a = 0, b = 0, played = 0
      for h in 0..<H {
        if scores[i][h] == nil || scores[j][h] == nil { break }
        let ni = net(scores, strokes, i, h), nj = net(scores, strokes, j, h)
        if ni < nj { a += 1 } else if nj < ni { b += 1 }
        played = h + 1
      }
      pairs.append(RRPair(i: i, j: j, a: a, b: b, played: played))
    } }
    return pairs
  }

  public static func rrRecords(_ pairs: [RRPair], count: Int) -> [RRRecord] {
    var rec = Array(repeating: RRRecord(w: 0, l: 0, h: 0), count: count)
    for p in pairs {
      if p.a > p.b { rec[p.i].w += 1; rec[p.j].l += 1 }
      else if p.b > p.a { rec[p.j].w += 1; rec[p.i].l += 1 }
      else { rec[p.i].h += 1; rec[p.j].h += 1 }
    }
    return rec
  }

  // MARK: - settlement (`settleTransfers` 8320)

  public struct Transfer: Sendable, Equatable {
    public let from: Int, to: Int, amt: Double
    public init(from: Int, to: Int, amt: Double) { self.from = from; self.to = to; self.amt = amt }
  }

  /// Minimized transfers from a net-zero points ledger: creditors and debtors
  /// sorted desc, paired off greedily. Empty when nothing is on it.
  public static func settleTransfers(pts: [Int], val: Double) -> [Transfer] {
    guard val > 0 else { return [] }
    var cr: [(i: Int, amt: Double)] = [], db: [(i: Int, amt: Double)] = []
    for (i, p) in pts.enumerated() {
      let amt = Double(p) * val
      if amt > 0 { cr.append((i, amt)) } else if amt < 0 { db.append((i, -amt)) }
    }
    cr.sort { $0.amt > $1.amt }; db.sort { $0.amt > $1.amt }
    var out: [Transfer] = []
    var ci = 0, di = 0
    while ci < cr.count, di < db.count {
      let x = min(cr[ci].amt, db[di].amt)
      out.append(Transfer(from: db[di].i, to: cr[ci].i, amt: x))
      cr[ci].amt -= x; db[di].amt -= x
      if cr[ci].amt == 0 { ci += 1 }
      if db[di].amt == 0 { di += 1 }
    }
    return out
  }

  // MARK: - `netParThru` (8594)

  public struct NetPar: Sendable, Equatable {
    public let gross: Int, par: Int, net: Int, thru: Int
    public var toPar: Int { gross - par }
  }

  /// gross, par and net-to-par through the holes a player has scored.
  public static func netParThru(_ pi: Int, scores: [[Int?]], pars: [Int], strokes: [[Int]], holes: Int, noHandicap: Bool) -> NetPar {
    var gross = 0, par = 0, net = 0, thru = 0
    for h in 0..<(holes == 9 ? 9 : 18) {
      guard let s = scores[pi][h] else { continue }
      thru += 1; gross += s; par += pars[h]
      net += s - pars[h] - (noHandicap ? 0 : strokes[pi][h])
    }
    return NetPar(gross: gross, par: par, net: net, thru: thru)
  }
}
