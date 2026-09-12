import Foundation

/// A frozen retry envelope. Local scorecard ID is the request key; it is never
/// regenerated after a timeout. Pending requests do not inherit the draft TTL.
public struct OfflinePost: Codable, Sendable, Equatable {
  public let owner: UUID
  public let request: UUID
  public let card: PostCard
  public var payload: PostPayload
  public let playedWith: [UUID]
  public var accepted: UUID?
  public init(owner: UUID, request: UUID, card: PostCard, payload: PostPayload, playedWith: [UUID]) {
    self.owner = owner; self.request = request; self.card = card; self.payload = payload; self.playedWith = playedWith
  }
  public var holes: [Int] { card.mode == .holes ? Array(card.scores.prefix(payload.holes_played)) : [] }
}

@MainActor public final class OfflinePostDisk {
  public static let shared = OfflinePostDisk()
  private let directory: URL
  public init(directory: URL? = nil) {
    self.directory = directory ?? URL.applicationSupportDirectory.appendingPathComponent("CupSeason/offline-posts", isDirectory: true)
  }
  private func file(_ owner: UUID, _ request: UUID) -> URL {
    directory.appendingPathComponent(owner.uuidString).appendingPathComponent(request.uuidString + ".json")
  }
  public func read(owner: UUID, request: UUID) throws -> OfflinePost? {
    let url = file(owner, request)
    guard FileManager.default.fileExists(atPath: url.path) else { return nil }
    let value = try JSONDecoder().decode(OfflinePost.self, from: Data(contentsOf: url))
    guard value.owner == owner, value.request == request else { throw OfflineRounds.Failure.invalidCard }
    return value
  }
  public func save(_ value: OfflinePost) throws {
    let url = file(value.owner, value.request)
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try JSONEncoder().encode(value).write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
  }
}

extension PostService {
  /// Hand-declared while the migration awaits an approved deployment/contract
  /// refresh. No droppable arguments and absolutely no unkeyed fallback.
  struct PostRoundOnceCall: RpcCall {
    static let name = "post_round_once"
    static let optionalArgs: [String] = []
    typealias Returns = JSONValue
    let p_request_id: UUID
    let p_payload: PostPayload
    let p_hole_scores: [Int]
    let p_played_with: [UUID]
  }
  public func postOnce(_ pending: OfflinePost) async throws -> PostOutcome {
    let json = try await svc.call(PostRoundOnceCall(p_request_id: pending.request, p_payload: pending.payload,
                                                   p_hole_scores: pending.holes, p_played_with: pending.playedWith))
    guard let out = PostOutcome(json: json) else {
      throw RpcError(name: PostRoundOnceCall.name, underlying: "No accepted round identifier returned. Keep the scorecard and try the same request again.", droppedArgs: [])
    }
    return out
  }
}
