import Foundation

/// Account-owned scorecards, separate from the server live-round cache and its
/// expiry/abandon cleanup. Writes finish before the score tap returns. A failed
/// write throws; callers must never announce that the card was kept.
@MainActor
public final class OfflineRounds {
  public static let shared = OfflineRounds()
  private let directory: URL
  public init(directory: URL? = nil) {
    self.directory = directory ?? URL.applicationSupportDirectory.appendingPathComponent("CupSeason/offline-rounds", isDirectory: true)
  }
  private func url(owner: UUID, id: UUID) -> URL {
    directory.appendingPathComponent(owner.uuidString, isDirectory: true).appendingPathComponent(id.uuidString + ".json")
  }
  public func save(_ state: LiveRoundState) throws {
    guard let owner = state.localOwner, let id = state.lr else { throw Failure.invalidCard }
    let file = url(owner: owner, id: id)
    try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
    try JSONEncoder().encode(state).write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
  }
  public func rounds(owner: UUID) throws -> [LiveRoundState] {
    let folder = directory.appendingPathComponent(owner.uuidString, isDirectory: true)
    guard FileManager.default.fileExists(atPath: folder.path) else { return [] }
    return try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
      .filter { $0.pathExtension == "json" }
      .map { try JSONDecoder().decode(LiveRoundState.self, from: Data(contentsOf: $0)) }
      .filter { $0.localOwner == owner }
      .sorted { $0.ts > $1.ts }
  }
  public func round(owner: UUID, id: UUID) throws -> LiveRoundState? {
    let file = url(owner: owner, id: id)
    guard FileManager.default.fileExists(atPath: file.path) else { return nil }
    let state = try JSONDecoder().decode(LiveRoundState.self, from: Data(contentsOf: file))
    guard state.localOwner == owner else { throw Failure.invalidCard }
    return state
  }
  public func remove(owner: UUID, id: UUID) throws {
    let file = url(owner: owner, id: id)
    if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
  }
  public enum Failure: Error { case invalidCard }
}

/// Only the golfer's own identity, read behind the SDK's restored session.
/// No token, league roster, schedule or private competition information.
public struct OfflineGolfer: Codable, Sendable {
  public let id: UUID
  public let name: String
  public let index: Double?
  public let marker: String?
  public init(id: UUID, name: String, index: Double?, marker: String?) {
    self.id = id; self.name = name; self.index = index; self.marker = marker
  }
  public func keep(defaults: UserDefaults = .standard) {
    if let data = try? JSONEncoder().encode(self) { defaults.set(data, forKey: "cs.offline-golfer." + id.uuidString) }
  }
  public static func read(owner: UUID, defaults: UserDefaults = .standard) -> Self? {
    guard let data = defaults.data(forKey: "cs.offline-golfer." + owner.uuidString),
          let golfer = try? JSONDecoder().decode(Self.self, from: data), golfer.id == owner else { return nil }
    return golfer
  }
}
