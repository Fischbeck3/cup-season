import Foundation

/// Presentation over the existing engines, never a second match calculation.
public struct LiveIslandFacts: Sendable, Equatable {
  public let opponent: String, result: String, detail: String, compact: String
  public let through: Int?
  public let score: Int?
  public let canScore: Bool
}

public enum LiveIsland {
  public static func facts(_ s: LiveRoundState) -> LiveIslandFacts {
    let me = s.meIndex
    let h = min(max(0, s.hole), s.liveHoles - 1)
    let score = me.flatMap { s.scores.indices.contains($0) && s.scores[$0].indices.contains(h) ? s.scores[$0][h] : nil }
    let canScore = me.flatMap { s.players[$0].pid } != nil && s.active && s.stage == .live
    if (s.game == .match || s.game == .sunningdale), !(s.solo && s.players.count == 4),
       s.teams.count == 2, let me, let side = s.teams.firstIndex(where: { $0.contains(me) }),
       s.teams.allSatisfy({ !$0.isEmpty && $0.allSatisfy(s.players.indices.contains) }) {
      let a: Int, b: Int, played: Int, closed: LiveEngines.Closeout?
      if s.game == .match {
        let match = LiveEngines.match(scores: s.scores, strokes: s.strokeTable, teams: s.teams, holes: s.liveHoles)
        a = match.a; b = match.b; played = match.played; closed = match.closed
      } else {
        let match = LiveEngines.sunningdale(scores: s.scores, teams: s.teams, holes: s.liveHoles)
        a = match.a; b = match.b; played = match.played; closed = match.closed
      }
      let names = s.teams[1 - side].map { LiveFmt.fn1(s.players[$0].n) }.joined(separator: " & ")
      let result: String, compact: String
      if let closed {
        result = "\(closed.winner == side ? "Won" : "Lost") \(closed.lead)&\(closed.rem)"
        compact = result
      } else if a == b { result = "All square"; compact = "AS" }
      else {
        let ahead = side == 0 ? a > b : b > a
        result = "\(abs(a - b)) \(ahead ? "up" : "down")"; compact = result
      }
      return .init(opponent: "vs \(names)", result: result,
                   detail: s.game == .match ? "Match play" : "Sunningdale", compact: compact,
                   through: closed == nil ? played : nil, score: score, canScore: canScore)
    }
    if s.game == .score, let me, s.scores.indices.contains(me) {
      let entered = s.scores[me].prefix(s.liveHoles).compactMap { $0 }
      return .init(opponent: s.course.label, result: entered.isEmpty ? "—" : String(entered.reduce(0, +)),
                   detail: "Gross · \(entered.count) scored", compact: "\(entered.count)/\(s.liveHoles)",
                   through: nil, score: score, canScore: canScore)
    }
    let original = LiveCopy.activity(s)
    return .init(opponent: s.course.label, result: original.game ?? "Your round", detail: "Live round",
                 compact: original.compact ?? "\(s.thru)/\(s.liveHoles)", through: s.thru, score: score, canScore: canScore)
  }

  public enum Action: String, Sendable { case previous, next, minus, plus }
  public enum Failure: LocalizedError {
    case unavailable, moved, signIn, storage
    public var errorDescription: String? {
      switch self {
      case .unavailable: "Open your round to continue scoring."
      case .moved: "The round moved to another hole. Try the updated controls."
      case .signIn: "Open Cup Season and sign in to score your round."
      case .storage: "Couldn’t save that change. Open the round and try again."
      }
    }
  }

  /// Mutates only the signed-in golfer's row. The hole carried by the button
  /// prevents a delayed tap from scoring a different hole after navigation.
  public static func applying(_ action: Action, round: UUID, owner: UUID, hole: Int,
                              to original: LiveRoundState, now: Int64 = LiveFmt.now()) throws -> (LiveRoundState, LiveMessage?) {
    guard original.active, original.stage == .live, original.lr == round,
          let me = original.meIndex, original.players[me].pid == owner,
          original.localOwner == nil || original.localOwner == owner,
          original.scores.indices.contains(me), original.scores[me].count >= original.liveHoles else { throw Failure.unavailable }
    guard hole == original.hole + 1, (1...original.liveHoles).contains(hole) else { throw Failure.moved }
    var s = original; s.ts = max(now, s.ts + 1)
    switch action {
    case .previous: s.hole = max(0, s.hole - 1)
    case .next: s.hole = min(s.liveHoles - 1, s.hole + 1)
    case .plus, .minus:
      let h = hole - 1, current = s.scores[me][h]
      guard current != nil || action == .plus else { return (original, nil) }
      guard s.course.pars.indices.contains(h) else { throw Failure.unavailable }
      let next = current.map { $0 + (action == .plus ? 1 : -1) } ?? s.course.pars[h]
      // Same valid stroke range as the server. One further minus clears a 1.
      guard next <= 15 else { return (original, nil) }
      s.ensureClocks()
      s.scores[me][h] = next < 1 ? nil : next
      s.scts[me][h] = max(now, s.scts[me][h] + 1)
      if !s.onThisPhone {
        guard let players = s.pmap, players.indices.contains(me), s.code != nil else { throw Failure.unavailable }
        return (s, .score(pid: players[me], hole0: h, strokes: s.scores[me][h], cts: s.scts[me][h]))
      }
    }
    return (s, nil)
  }
}
