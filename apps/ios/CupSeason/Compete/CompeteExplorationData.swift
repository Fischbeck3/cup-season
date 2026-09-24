// Local proposal payloads, never a production scoring implementation.
#if DEBUG
import Foundation
import CupSeasonKit

@MainActor
enum CompeteExploration {
  static let flag = "-cs_dev_compete_exploration"
  static var on: Bool { ProcessInfo.processInfo.arguments.contains(flag) }
  static func argument(_ key: String, fallback: String) -> String {
    let a = ProcessInfo.processInfo.arguments
    guard let i = a.firstIndex(of: key), i + 1 < a.count else { return fallback }
    return a[i + 1]
  }
  static var direction: String { argument(flag, fallback: "scoreboard") }
  static var fixture: String { argument("-cs_explore_fixture", fallback: "field") }
  static var screen: String { argument("-cs_explore_screen", fallback: "root") }
  static func id(_ n: Int) -> UUID { UUID(uuidString: String(format: "C50E0000-0000-4000-8000-%012d", n))! }
}

struct SeasonBookEntry: Identifiable, Hashable {
  let id: UUID
  let member: Int?
  let squad: Int?
  let week: Int
  let points: Int
  let counted: Bool
  let kind: String
  let reason: String
  var round: Bool { kind == "round" }
  var contribution: Int { counted ? points : 0 }
}

@MainActor
final class CompeteExplorationSeason {
  let kind: String
  let model: LeagueRoomModel
  let entries: [SeasonBookEntry]
  let names: [String]
  let title: String
  let weeks = 15
  var upcoming: Bool { kind == "upcoming" }
  var finished: Bool { kind == "finished" }
  var squads: Bool { kind == "squads" }
  var currentWeek: Int { upcoming ? 0 : (finished ? 15 : 12) }
  var live: Bool { !upcoming && !finished }
  var standings: [Team] { model.teams }
  var ranks: [Int] { StandingsMath.competitionRanks(standings.map { Int($0.pts.rounded()) }) }
  var mine: Team? { standings.first { $0.id == model.myTeamId } }
  var raceTeams: [Team] {
    var result = Array(standings.prefix(1))
    if let mine, !result.contains(where: { $0.id == mine.id }) { result.append(mine) }
    for team in standings where result.count < 3 && !result.contains(where: { $0.id == team.id }) { result.append(team) }
    return result
  }
  var cap: Int { kind == "tie" ? 4 : 3 }
  var rules: String {
    let cap = model.settings?.counting_cap.map { "Best \($0)" } ?? "All rounds"
    return "\(cap) per calendar month · minimum \(model.settings?.participation_floor ?? 0)"
  }
  var bookAvailable: Bool { squads || names.count >= 10 }
  var story: String {
    if upcoming { return "The first tee is October 5." }
    if finished { return "Galen won the Summer Cup." }
    if kind == "tie" { return "Two golfers. The lead is shared." }
    guard let mine, let leader = standings.first else { return "The season is underway." }
    let gap = Int(leader.pts - mine.pts)
    if gap == 0 {
      return standings.filter { $0.pts == mine.pts }.count > 1 ? "\(mine.name) shares the lead." : "\(mine.name) leads."
    }
    return "\(mine.name) is \(gap) back from \(leader.name)."
  }
  func rank(_ team: Team) -> String {
    guard !upcoming, let i = standings.firstIndex(where: { $0.id == team.id }) else { return "Not started" }
    let r = ranks[i]
    return CSCopy.ordinal(r) + (ranks.filter { $0 == r }.count > 1 ? " · Tied" : "")
  }
  func memberEntries(_ member: Int) -> [SeasonBookEntry] { entries.filter { $0.member == member } }
  func teamEntries(_ team: Team) -> [SeasonBookEntry] {
    if !squads { return entries.filter { $0.member.map { CompeteExploration.id($0 + 1) == team.id } == true } }
    guard let index = (0..<4).first(where: { CompeteExploration.id(200 + $0) == team.id }) else { return [] }
    return entries.filter { $0.squad == index || $0.member.map { $0 / 4 == index } == true }
  }
  func total(_ entries: [SeasonBookEntry], through week: Int = 15) -> Int {
    entries.filter { $0.week <= week }.reduce(0) { $0 + $1.contribution }
  }
  func weekDate(_ week: Int) -> String {
    let base = upcoming ? "2026-10-05" : "2026-07-06"
    let date = CSDate.local(base) ?? Date(timeIntervalSince1970: 0)
    return CSDate.iso(Calendar(identifier: .gregorian).date(byAdding: .day, value: (week - 1) * 7, to: date)!)
  }
  init(_ kind: String) {
    self.kind = kind
    title = ["tie": "The Saturday Cup", "field": "The Fellas", "squads": "Four at a Time", "upcoming": "The Autumn Cup", "finished": "The Summer Cup", "multi": "The Fellas"][kind] ?? "The Fellas"
    names = kind == "tie" ? ["Galen Marr", "Jerecho"] : ["Galen Marr", "Jerecho", "Jade Okafor", "Dev Rana", "Tash Bell", "Mike Fenner", "Priya Raghunathan", "Sam Ridley", "Nora Vance", "Eli Brandt", "Ruth Salas", "Owen Pike", "Alex Park", "Cam Ellis", "Robin West", "Lee Santos"]
    let league = CompeteExploration.id(900)
    model = LeagueRoomModel(leagueId: league)
    var values: [SeasonBookEntry] = []
    var serial = 1000
    func add(_ m: Int?, _ s: Int?, _ w: Int, _ p: Int, _ counted: Bool, _ kind: String, _ reason: String) {
      serial += 1
      values.append(.init(id: CompeteExploration.id(serial), member: m, squad: s, week: w, points: p, counted: counted, kind: kind, reason: reason))
    }
    if kind == "tie" {
      for m in 0..<2 {
        for (i, p) in [7, 7, 9, 6, 7, 5].enumerated() { add(m, nil, [1, 3, 5, 7, 10, 12][i], p, true, "round", "Counting round") }
      }
    } else if kind != "upcoming" {
      // Authored scored fixture payload. These flags are facts, not a client
      // best-N calculator. A production read must return them from Postgres.
      for m in 0..<16 {
        for w in [1, 2, 3, 5, 6, 7, 10, 11, 12] {
          if m == 14 && [5, 6].contains(w) { continue }
          if m == 15 && [5, 6, 7].contains(w) { continue }
          let scores = [
            [12,9,9,7,9,12,9,12,12], [7,9,7,9,9,12,12,9,12],
            [9,12,12,9,7,9,9,7,9], [7,7,9,12,12,9,7,9,9],
            [9,7,7,9,12,7,9,9,7], [7,9,12,7,7,9,9,7,7],
            [12,7,9,7,9,7,7,9,6], [6,9,7,9,7,7,9,7,6],
            [7,6,9,7,7,9,7,6,7], [9,7,6,7,6,7,7,9,6],
            [6,7,7,9,6,7,6,7,7], [7,6,7,6,7,7,6,7,6],
            [6,6,7,7,6,7,6,6,7], [6,7,6,6,7,6,6,6,6],
            [7,6,6,6,6,7,7,6,6], [6,6,7,6,7,6,6,7,6]
          ]
          let p = scores[m][[1,2,3,5,6,7,10,11,12].firstIndex(of: w)!]
          add(m, nil, w, p, true, "round", "Counting round")
        }
        add(m, nil, 4, 5, false, "round", "Outside July's best 3; the round stays in the record.")
        if kind == "finished" { add(m, nil, 15, [7, 9, 12][m % 3], true, "round", "Counting round") }
      }
      add(14, nil, 4, 0, true, "bye", "July bye recorded August 1 by The Pro; retained even though the golfer later met the minimum.")
      add(14, nil, 9, -5, true, "floor_penalty", "August minimum: one round short; season bye already recorded in July.")
      add(15, nil, 9, 0, true, "bye", "August minimum waived: bye recorded by The Pro.")
      // Imported historical kind, deliberately visible in a FINISHED fixture
      // only. Hybrid awards are retired; this is not a new bonus mechanic.
      if kind == "finished" { add(0, nil, 9, 15, true, "matchup_bonus", "Historical matchup bonus, retained from the legacy season record.") }
    }
    // Two receipts in one week: an included round and a displaced round.
    if kind != "upcoming" && kind != "tie" { add(1, nil, 12, 5, false, "round", "Outside September's best 3; 9 points was the counting cut.") }
    entries = values
    SeasonFixture.applyExploration(self)
  }
}
// The race must include every intermediate total. A later deduction can put
// the last total below an earlier peak or below zero; neither may be clipped.
enum SeasonBookRaceScale {
  static func domain(rows: [[SeasonBookEntry]], currentWeek: Int) -> ClosedRange<Int> {
    let values = rows.flatMap { entries in
      (0...max(0, currentWeek)).map { week in
        entries.filter { $0.week <= week }.reduce(0) { $0 + $1.contribution }
      }
    }
    let low = min(0, values.min() ?? 0)
    let high = max(0, values.max() ?? 0)
    return low...max(low + 1, high)
  }
}

// Presentation only: the contribution flags are authored server-like facts.
// A dash is absence, never a zero score. Mixed counted/dropped cells retain D.
enum SeasonBookCell {
  static func label(_ entries: [SeasonBookEntry], week: Int, currentWeek: Int, cumulative: Bool = false) -> String {
    if week > currentWeek { return "•" }
    let selected = entries.filter { cumulative ? $0.week <= week : $0.week == week }
    if selected.isEmpty { return "—" }
    if !cumulative && selected.allSatisfy({ $0.kind == "bye" }) { return "B" }
    if !cumulative && selected.allSatisfy({ !$0.counted }) { return "D" }
    let suffix = cumulative ? "" : (selected.contains { !$0.round } ? "*" : "") + (selected.contains { !$0.counted } ? "D" : "")
    return String(selected.reduce(0) { $0 + $1.contribution }) + suffix
  }
  static func spoken(_ entries: [SeasonBookEntry], week: Int, currentWeek: Int, cumulative: Bool = false) -> String {
    let label = label(entries, week: week, currentWeek: currentWeek, cumulative: cumulative)
    switch label {
    case "•": return "Future week"
    case "—": return "No round or adjustment recorded"
    case "B": return "Bye; no points added"
    case "D": return "Dropped round; no points counted"
    default:
      let selected = entries.filter { cumulative ? $0.week <= week : $0.week == week }
      return "\(selected.reduce(0) { $0 + $1.contribution }) points\(cumulative ? " through this week" : " this week")" +
        (selected.contains { !$0.counted } ? "; includes dropped rounds in receipt" : "") +
        (selected.contains { !$0.round } ? "; includes adjustments" : "")
    }
  }
}
#endif
