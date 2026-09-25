import Foundation

/// The server owns consent, reuse and attempt ownership. A sheet cancellation
/// cannot revoke a previously completed share, including from another device.
public struct RoundShareAttempt: Sendable, Equatable {
  public let id: UUID
  public let token: UUID
  public let owner: UUID
  public let created: Bool
  public var url: URL { URL(string: "https://cupseason.app/?share=\(token.uuidString.lowercased())")! }
  public init(id: UUID, token: UUID, created: Bool, owner: UUID) { self.id = id; self.token = token; self.created = created; self.owner = owner }
  public init(reply: JSONValue, attempt: UUID, includePhoto: Bool, owner: UUID) throws {
    guard let token = reply["token"]?.string.flatMap(UUID.init),
          let created = reply["created"]?.bool,
          reply["include_photo"]?.bool == includePhoto else { throw ShareConsent.NotReady() }
    self.init(id: attempt, token: token, created: created, owner: owner)
  }
}

/// Completion acknowledgements survive a process exit/network miss. Preparing
/// attempts are leased server-side; a killed share sheet expires and is cleaned
/// by the server. Only actual OS completion records a completed acknowledgement.
public actor RoundShareAcknowledgements {
  public static let shared = RoundShareAcknowledgements()
  private struct Pending: Codable { let owner: UUID; let attempt: UUID; let completed: Bool }
  private let key = "cs.round-share-ack.v1"
  private var draining = false
  private func read() -> [Pending] {
    guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
    return (try? JSONDecoder().decode([Pending].self, from: data)) ?? []
  }
  private func write(_ rows: [Pending]) {
    if let data = try? JSONEncoder().encode(rows) { UserDefaults.standard.set(data, forKey: key) }
  }
  public func record(owner: UUID, attempt: UUID, completed: Bool) {
    var rows = read().filter { $0.attempt != attempt }
    rows.append(Pending(owner: owner, attempt: attempt, completed: completed)); write(rows)
  }
  public func acknowledged(_ attempt: UUID) { write(read().filter { $0.attempt != attempt }) }
  public func drain(owner: UUID, svc: SupabaseService = .shared) async {
    guard !draining else { return }
    draining = true; defer { draining = false }
    for row in read() where row.owner == owner {
      do {
        _ = try await svc.call(Rpc.finish_round_share(p_attempt: row.attempt, p_completed: row.completed))
        write(read().filter { $0.attempt != row.attempt })
      } catch { return } // remains durable; next authenticated load retries
    }
  }
}
