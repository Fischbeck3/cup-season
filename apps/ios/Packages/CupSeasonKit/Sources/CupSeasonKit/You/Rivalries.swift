// Cup Season — rivalries: the lifetime weekly-clash record vs your league
// mates (index.html `renderRivalries` 13215–13242, `openRivalrySheet`
// 13244–13264, `openNameRivalry` 13268–13290).
//
// `my_rivalries()` → summary rows; `rivalry_weeks()` → the receipts (§16).
// The faceted record: clashes and Ryder duels side by side, never one blended
// number. A christened rivalry (M3/D18) wears its name in gold.

import Foundation

public enum RivalryLead: Sendable, Equatable { case up, down, even }

public struct RivalryLine: Sendable, Identifiable, Equatable {
  public let opponent: UUID
  public let name: String
  public let marker: String?
  public let facets: String
  public let record: String
  public let lead: RivalryLead
  public let rivalryName: String?
  public var id: UUID { opponent }

  public init(opponent: UUID, name: String, marker: String?, facets: String, record: String, lead: RivalryLead, rivalryName: String?) {
    self.opponent = opponent; self.name = name; self.marker = marker; self.facets = facets; self.record = record; self.lead = lead; self.rivalryName = rivalryName
  }

  /// A row from `my_rivalries`. nil when it names no opponent.
  public static func from(_ r: Rpc.my_rivalries.Row) -> RivalryLine? {
    guard let opp = r.opponent else { return nil }
    let wins = r.wins ?? 0, losses = r.losses ?? 0, ties = r.ties ?? 0
    let dw = r.duel_wins ?? 0, dl = r.duel_losses ?? 0, dh = r.duel_halves ?? 0
    let meetings = r.meetings ?? 0
    let facets = [
      meetings > 0 ? "\(meetings) week\(meetings == 1 ? "" : "s") head-to-head" : nil,
      (dw + dl + dh) > 0 ? "Ryder duels \(dw)–\(dl)\(dh > 0 ? "–\(dh)" : "")" : nil,
    ].compactMap { $0 }.joined(separator: " · ")
    let lead: RivalryLead = r.lead == "up" ? .up : r.lead == "down" ? .down : .even
    let named = (r.rivalry_name ?? "").isEmpty ? nil : r.rivalry_name
    return RivalryLine(opponent: opp, name: r.display_name ?? "—", marker: r.marker, facets: facets,
                       record: RivalryCopy.record(wins: wins, losses: losses, ties: ties), lead: lead, rivalryName: named)
  }
}

/// One head-to-head week on the rivalry sheet.
public struct RivalryWeek: Sendable, Identifiable, Equatable {
  public enum Verdict: Sendable, Equatable { case won, lost, halved }
  public let wk: String
  public let verdict: Verdict
  public let headline: String
  public var id: String { wk }

  public var verdictText: String {
    switch verdict { case .won: "WON"; case .lost: "LOST"; case .halved: "HALVED" }
  }
  /// "WK OF" over "JUL 6" (the web's two-line mono cell).
  public var wkLabel: String { "WK OF\n" + RivalryCopy.monthDay(wk) }

  /// `x.winner==='me' → WON`, `'them' → LOST`, else HALVED;
  /// "YOU +1.2 · NAME −0.4".
  public static func from(_ x: Rpc.rivalry_weeks.Row, opponentName: String) -> RivalryWeek? {
    guard let wk = x.wk else { return nil }
    let me = x.my_pvi ?? 0, th = x.opp_pvi ?? 0
    let v: Verdict = x.winner == "me" ? .won : x.winner == "them" ? .lost : .halved
    return RivalryWeek(wk: wk, verdict: v, headline: "YOU \(RoundCopy.signed(me)) · \(opponentName) \(RoundCopy.signed(th))")
  }
}

public enum RivalryCopy {
  /// `${wins}–${losses}${ties?'–'+ties:''}`
  public static func record(wins: Int, losses: Int, ties: Int) -> String {
    "\(wins)–\(losses)" + (ties > 0 ? "–\(ties)" : "")
  }
  /// `YOU LEAD` / `THEY LEAD` / `ALL SQUARE` (the Tour Card's vs chip).
  public static func leadLabel(wins: Int, losses: Int) -> String {
    wins > losses ? "YOU LEAD" : wins < losses ? "THEY LEAD" : "ALL SQUARE"
  }
  /// "JUL 6" from "2026-07-06" — by parts, never through an ISO parser.
  public static func monthDay(_ iso: String) -> String {
    let parts = iso.split(separator: "-").compactMap { Int($0) }
    let mos = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
    guard parts.count == 3, (1...12).contains(parts[1]) else { return iso.uppercased() }
    return "\(mos[parts[1] - 1]) \(parts[2])"
  }

  public static let weekSub = "BEST ROUND VS INDEX THAT WEEK"
  public static let sheetSub = "WEEKLY CLASH · BETTER ROUND VS INDEX TAKES THE WEEK"
  public static let noWeeks = "No head-to-head weeks yet. A clash counts a week you both post."
  public static let nameHelp = "Give it a name your crew would actually say — “The Grudge,” “Border War.” Either of you can change it later."
  public static let namePlaceholder = "The Grudge"
}
