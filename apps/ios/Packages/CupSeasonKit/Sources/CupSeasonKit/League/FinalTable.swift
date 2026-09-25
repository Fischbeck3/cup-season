import Foundation

public enum FinalTable {
  /// Mirrors the server's display placement: stored podium, then tied points
  /// ranks for the remaining field. It never decides who won the Cup.
  public static func ranks(_ ordered: [Team], champion: UUID?, runnerUp: UUID?) -> [Int] {
    let podium = Set([champion, runnerUp].compactMap { $0 })
    let n = ordered.filter { podium.contains($0.id) }.count
    return (n > 0 ? Array(1...n) : []) + StandingsMath.competitionRanks(ordered.dropFirst(n).map { Int($0.pts.rounded()) }).map { $0 + n }
  }
  public static func ordered(_ teams: [Team], champion: UUID?, runnerUp: UUID?) -> [Team] {
    let podium = [champion, runnerUp].compactMap { $0 }
    return podium.compactMap { id in teams.first { $0.id == id } }
      + teams.filter { !podium.contains($0.id) }
  }
}
