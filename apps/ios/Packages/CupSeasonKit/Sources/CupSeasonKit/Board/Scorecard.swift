// Cup Season — the scorecard behind a settlement row (D92, index.html 10336–10450).
//
// Rules it keeps, verbatim from the web:
//   · an unscored hole is a FACT — it renders as a gap, never a zero, never hidden
//   · the match ledger is drawn from the ROUND'S OWN result (game_result.holes),
//     never recomputed here
//   · par and SI come from the course snapshot taken at tee-off

import Foundation

public struct Scorecard: Sendable, Equatable {
  public struct Player: Sendable, Equatable {
    public let name: String
    public let guest: Bool
    public let strokes: [Int?]      // 18 slots, nil = gap
    public init(name: String, guest: Bool, strokes: [Int?]) { self.name = name; self.guest = guest; self.strokes = strokes }
  }
  public struct Ledger: Sendable, Equatable {
    public let mode: String         // 'sides' | 'players' | 'wolf'
    public let cells: [String?]     // per hole: 'a'/'b', a player index, or the wolf side
  }

  public let game: String?
  public let courseLabel: String
  public let holes: Int             // 9 or 18
  public let pars: [Int]?           // 18 when the snapshot has them
  public let sis: [Int]?
  public let ledger: Ledger?
  public let sideA: [String]
  public let sideB: [String]
  public let story: String
  public let when: String           // YYYY-MM-DD of finished_at, else started_at, else ""
  public let players: [Player]

  /// `gl` — the game label (10412).
  public var gameLabel: String {
    ["none": "Stroke play", "match": "Match play", "wolf": "Wolf", "skins": "Skins", "sunningdale": "Sunningdale Rules"][game ?? ""] ?? "The round"
  }
  /// The sheet eyebrow: `MATCH PLAY · PAPAGO`.
  public var eyebrow: String { "\(gameLabel.uppercased()) · \(courseLabel.uppercased())" }

  /// Decode the `live_round_card` payload. nil when `round` is missing.
  public init?(_ d: JSONValue) {
    guard let R = d["round"], !R.isNull else { return nil }
    game = R["game"]?.string
    courseLabel = R["course_label"]?.string ?? ""
    let snap = R["course_snapshot"]
    let parsArr = snap?["pars"]?.array?.compactMap { $0.double.map { Int($0) } ?? $0.string.flatMap(Int.init) }
    pars = (parsArr?.count == 18) ? parsArr : nil
    let siArr = snap?["si"]?.array?.compactMap { $0.double.map { Int($0) } ?? $0.string.flatMap(Int.init) }
    sis = (siArr?.count == 18) ? siArr : nil
    holes = snap?["holes"]?.int == 9 ? 9 : 18
    let led = R["game_result"]?["holes"]
    if let led, let cells = led["cells"]?.array {
      ledger = Ledger(mode: led["mode"]?.string ?? "", cells: cells.map { c in
        if let s = c.string { return s }
        if let n = c.double { return String(Int(n)) }
        return nil
      })
    } else { ledger = nil }
    let cfg = R["game_config"]
    sideA = cfg?["side_a"]?.array?.map { $0.string ?? $0.double.map { String(Int($0)) } ?? "" } ?? []
    sideB = cfg?["side_b"]?.array?.map { $0.string ?? $0.double.map { String(Int($0)) } ?? "" } ?? []
    story = R["game_result"]?["story"]?.string ?? ""
    when = String((R["finished_at"]?.string ?? R["started_at"]?.string ?? "").prefix(10))
    players = (d["players"]?.array ?? []).map { p in
      let raw = p["strokes"]?.array ?? []
      var s: [Int?] = raw.prefix(18).map { $0.double.map { Int($0) } }
      while s.count < 18 { s.append(nil) }
      return Player(name: p["name"]?.string ?? "A golfer", guest: p["guest"]?.bool ?? false, strokes: s)
    }
  }

  // MARK: - Layout (the table the sheet draws)

  public enum CellState: Sendable, Equatable { case plain, gap, bird, won }

  public struct Cell: Sendable, Equatable {
    public let text: String
    public let state: CellState
  }

  public struct Row: Sendable, Equatable {
    public let name: String
    public let guest: Bool
    public let cells: [Cell]
    public let out: String
    public let inn: String
    public let tot: String
  }

  static func sum(_ a: [Int?], _ from: Int, _ to: Int) -> Int? {
    var t = 0, any = false
    for i in from..<min(to, a.count) { if let v = a[i] { t += v; any = true } }
    return any ? t : nil
  }
  static func dot(_ v: Int?) -> String { v.map(String.init) ?? "·" }

  /// `sideOf` / `keyFor` (10366–10380): which ledger key belongs to this row.
  func key(for player: Player, index: Int) -> String? {
    guard let ledger else { return nil }
    switch ledger.mode {
    case "sides":
      if sideA.contains(player.name) { return "a" }
      if sideB.contains(player.name) { return "b" }
      return nil
    case "players": return String(index)
    default: return nil       // wolf: the side rotates — no row owns it
    }
  }

  public var rows: [Row] {
    players.enumerated().map { i, pl in
      let myKey = key(for: pl, index: i)
      let cells: [Cell] = (0..<holes).map { h in
        let v = pl.strokes[h]
        let mine = ledger != nil && myKey != nil && ledger!.cells.indices.contains(h) && ledger!.cells[h] != nil && ledger!.cells[h] == myKey
        let bird = pars != nil && v != nil && v! < pars![h]
        let state: CellState = v == nil ? .gap : (mine ? .won : (bird ? .bird : .plain))
        return Cell(text: Self.dot(v), state: state)
      }
      return Row(name: pl.name, guest: pl.guest, cells: cells,
                 out: Self.dot(Self.sum(pl.strokes, 0, 9)), inn: Self.dot(Self.sum(pl.strokes, 9, 18)), tot: Self.dot(Self.sum(pl.strokes, 0, holes)))
    }
  }

  public var parOut: String { pars.map { Self.dot(Self.sum($0, 0, 9)) } ?? "·" }
  public var parIn: String { pars.map { Self.dot(Self.sum($0, 9, 18)) } ?? "·" }
  public var parTot: String { pars.map { Self.dot(Self.sum($0, 0, holes)) } ?? "·" }
  public func par(_ h: Int) -> String { pars.map { String($0[h]) } ?? "·" }
  public func si(_ h: Int) -> String { sis.map { String($0[h]) } ?? "·" }

  /// Players with an unscored hole — said out loud once, under the card.
  public var gaps: [String] {
    players.filter { pl in (0..<holes).contains { pl.strokes[$0] == nil } }.map(\.name)
  }

  /// The fine print (10445–10447): a quiet prefix, then either "Every hole
  /// scored." or the gaps line, which reads in `neg`.
  public var footer: (prefix: String, note: String, warning: Bool) {
    var s = when.isEmpty ? "" : BoardText.shortDate(when) + " · "
    if ledger != nil { s += "Gold marks the holes that decided it. " }
    let g = gaps
    if g.isEmpty { return (s, "Every hole scored.", false) }
    return (s, "Not every hole was scored — \(g.joined(separator: ", ")) \(g.count == 1 ? "has" : "have") gaps.", true)
  }
}
