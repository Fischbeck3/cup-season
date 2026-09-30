import Foundation
import Observation
import Supabase

/// Shared league identity, independent of a season's transient phase look.
public struct LeagueIdentity: Decodable, Sendable, Identifiable, Equatable {
  public enum ImageKind: String, Codable, Sendable { case photo, logo }
  public struct Person: Decodable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let name: String?
    public let marker: String?
    public let photo_path: String?
    public init(id: UUID, name: String?, marker: String?, photo_path: String? = nil) {
      self.id = id; self.name = name; self.marker = marker; self.photo_path = photo_path
    }
  }
  public let league_id: UUID
  public let description: String?
  public let image_path: String?
  public let image_kind: ImageKind?
  public let look: String?
  public let member_count: Int
  public let people: [Person]
  public var id: UUID { league_id }
  public init(league_id: UUID, description: String? = nil, image_path: String? = nil,
              image_kind: ImageKind? = nil, look: String? = nil, member_count: Int = 0, people: [Person] = []) {
    self.league_id = league_id; self.description = description; self.image_path = image_path
    self.image_kind = image_kind; self.look = look; self.member_count = member_count; self.people = people
  }

  /// A league gets an initial mark, never a fabricated golfer's identity.
  public static func initials(_ name: String) -> String {
    var words = name.split { $0.isWhitespace || $0 == "-" }
    if words.first?.lowercased() == "the" { words.removeFirst() }
    // The board type role owns capitalization when these letters render.
    let mark = String(words.prefix(3).compactMap { $0.first(where: { $0.isLetter || $0.isNumber }) })
    return mark.isEmpty ? "CS" : mark
  }

  public func peopleLine(viewer: UUID?) -> String? {
    let named = people.prefix(2).compactMap { person -> String? in
      if person.id == viewer { return "You" }
      return person.name?.split(separator: " ").first.map(String.init)
    }
    guard !named.isEmpty else { return member_count > 0 ? "\(member_count) golfer\(member_count == 1 ? "" : "s")" : nil }
    let remaining = max(0, member_count - named.count)
    return named.joined(separator: member_count == 2 ? " and " : ", ") + (remaining > 0 ? " +\(remaining)" : "")
  }
}

struct LeagueIdentitiesCall: RpcCall {
  static let name = "league_identities"
  static let optionalArgs: [String] = []
  typealias Returns = [LeagueIdentity]
}
struct SetLeagueIdentityCall: RpcCall {
  static let name = "set_league_identity"
  static let optionalArgs: [String] = []
  typealias Returns = RpcVoid
  let p_league: UUID
  let p_description: String
  let p_image_path: String
  let p_image_kind: String
}

@MainActor @Observable public final class LeagueIdentityStore {
  public private(set) var identities: [UUID: LeagueIdentity] = [:]
  public private(set) var imageURLs: [UUID: URL] = [:]
  public private(set) var avatarURLs: [UUID: URL] = [:]
  public private(set) var available = false
  @ObservationIgnored private let svc: SupabaseService
  @ObservationIgnored private var userID: UUID?
  @ObservationIgnored private var loadedAt: Date?
  @ObservationIgnored private var generation = 0
  public init(service: SupabaseService = .shared) { svc = service }

  #if DEBUG
  /// Synthetic capture values only; never calls auth, storage or RPC.
  public func seed(_ rows: [LeagueIdentity], viewer: UUID, images: [UUID: URL] = [:]) {
    generation += 1; userID = viewer
    identities = Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0) })
    imageURLs = images; avatarURLs = [:]; available = true; loadedAt = Date()
  }
  #endif

  public func load(userID next: UUID?, force: Bool = false) async {
    guard let next else {
      generation += 1; userID = nil; identities = [:]; imageURLs = [:]; avatarURLs = [:]
      available = false; loadedAt = nil; return
    }
    if next != userID {
      generation += 1; identities = [:]; imageURLs = [:]; avatarURLs = [:]
      available = false; loadedAt = nil; userID = next
    }
    if !force, let loadedAt, Date().timeIntervalSince(loadedAt) < 300 { return }
    generation += 1
    let request = generation
    do {
      let rows = try await svc.call(LeagueIdentitiesCall())
      async let images = signed(rows.compactMap(\.image_path), bucket: "league-media")
      async let faces = signed(rows.flatMap(\.people).compactMap(\.photo_path), bucket: "media")
      let (imagePaths, facePaths) = await (images, faces)
      guard userID == next, request == generation else { return }
      identities = Dictionary(rows.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
      imageURLs = Dictionary(uniqueKeysWithValues: rows.compactMap { row in
        row.image_path.flatMap { imagePaths[$0] }.map { (row.id, $0) }
      })
      avatarURLs = Dictionary(rows.flatMap(\.people).compactMap { person in
        person.photo_path.flatMap { facePaths[$0] }.map { (person.id, $0) }
      }, uniquingKeysWith: { _, last in last })
      available = true; loadedAt = Date()
    } catch {
      // A failed optional identity read never replaces the season list.
      guard userID == next, request == generation else { return }
      loadedAt = nil
    }
  }

  private func signed(_ paths: [String], bucket: String) async -> [String: URL] {
    guard !paths.isEmpty,
          let values = try? await svc.client.storage.from(bucket).createSignedURLs(paths: Array(Set(paths)), expiresIn: 3600)
      else { return [:] }
    return Dictionary(values.filter { $0.error == nil }.compactMap { value in
      value.signedURL.map { (value.path, $0) }
    }, uniquingKeysWith: { _, last in last })
  }

  /// Upload first, atomically publish the record, then reclaim the retired object.
  /// A failed save removes only the new, unpublished upload.
  public func save(leagueID: UUID, description: String, imageKind: LeagueIdentity.ImageKind,
                   image: Data?, removeImage: Bool) async throws {
    let savingUser = userID
    let previous = identities[leagueID]?.image_path
    var path = removeImage ? nil : previous
    var uploaded: String?
    do {
      if let image {
        let ext = imageKind == .logo ? "png" : "jpg"
        let fresh = leagueID.uuidString.lowercased() + "/" + UUID().uuidString.lowercased() + "." + ext
        _ = try await svc.client.storage.from("league-media").upload(fresh, data: image,
          options: FileOptions(contentType: imageKind == .logo ? "image/png" : "image/jpeg", upsert: false))
        path = fresh; uploaded = fresh
      }
      _ = try await svc.call(SetLeagueIdentityCall(p_league: leagueID, p_description: description,
        p_image_path: path ?? "", p_image_kind: imageKind.rawValue))
    } catch {
      if let uploaded { _ = try? await svc.client.storage.from("league-media").remove(paths: [uploaded]) }
      throw error
    }
    // Reflect a confirmed write even when the subsequent optional read fails.
    guard userID == savingUser else { return }
    let old = identities[leagueID]
    identities[leagueID] = .init(league_id: leagueID,
      description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
      image_path: path, image_kind: path == nil ? nil : imageKind,
      look: old?.look, member_count: old?.member_count ?? 0, people: old?.people ?? [])
    if path != previous { imageURLs.removeValue(forKey: leagueID) }
    if let previous, previous != path {
      _ = try? await svc.client.storage.from("league-media").remove(paths: [previous])
    }
    await load(userID: userID, force: true)
  }
}
