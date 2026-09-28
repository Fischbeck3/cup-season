import Foundation

/// The variable part of live delivery: the existing RPCs in production, a
/// suspended or failing reader/writer in tests. Realtime remains on its own client.
protocol LiveDelivery: Sendable {
  func write(_ message: LiveMessage, round: UUID, guest: UUID?) async throws
  func read(round: UUID, guest: UUID?) async throws -> JSONValue
}

struct LiveRPCDelivery: LiveDelivery {
  let repo: LiveRepository
  func write(_ message: LiveMessage, round: UUID, guest: UUID?) async throws {
    if message.t == "score", let pid = message.pid, let hole = message.h {
      try await repo.setScore(lr: round, player: pid, hole: hole, strokes: message.s, cts: message.cts, guest: guest)
    } else if message.t == "wolf", let hole = message.h {
      try await repo.setWolf(lr: round, hole: hole, pick: message.w ?? .null, cts: message.cts, guest: guest)
    }
  }
  func read(round: UUID, guest: UUID?) async throws -> JSONValue {
    if let guest { return try await repo.guestState(guest) }
    return try await repo.state(round)
  }
}
