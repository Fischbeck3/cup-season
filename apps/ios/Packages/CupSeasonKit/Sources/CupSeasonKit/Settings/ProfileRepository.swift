// Cup Season — the card & settings data (audit 01 §1.6; index.html 13513–13840).
//
// `set_profile` null semantics: null = keep for name/city/home/index/marker;
// `p_ghin` and `p_photo_path` use '' = clear. The card sends `p_index: nil`
// always — the index moves ONLY via `set_index`, which is announced on the
// boards. Save order on the EDIT sheet is card first, then handle, so a
// rate-limited handle change never discards the rest of the edits (the
// reverse of the card gate, deliberately).

import Foundation
import Supabase

public struct ProfileRow: Decodable, Sendable {
  public let id: UUID
  public let display_name: String?
  public let handle: String?
  public let marker: String?
  public let city: String?
  public let home_course: String?
  public let index_current: Double?
  public let index_source: String?
  public let ghin_number: String?
  public let discoverable: String?
  public let notify_chat: Bool?
  public let notify_rounds: Bool?
  public let photo_path: String?
  public let created_at: Date?
}

public struct ProfileRepository: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  /// Named columns — `email` is sealed and a `*` would 42501.
  public func load(userId: UUID) async throws -> ProfileRow? {
    let rows: [ProfileRow] = try await svc.client.from("profiles")
      .select("id, display_name, handle, marker, city, home_course, index_current, index_source, ghin_number, discoverable, notify_chat, notify_rounds, photo_path, created_at")
      .eq("id", value: userId).execute().value
    return rows.first
  }

  public func avatarURL(userId: UUID) async -> URL? {
    try? await svc.client.storage.from("media").createSignedURL(path: "\(userId.uuidString.lowercased())/avatar.jpg", expiresIn: 3600)
  }

  /// The card fields. `ghin` '' clears; city/home '' → nil (the RPC keeps the
  /// old value on nil — a known web bug, audit 01 Q2; mirrored for parity).
  public func saveCard(name: String, city: String, home: String, marker: String?, ghin: String) async throws {
    try await svc.call(Rpc.set_profile(
      p_name: name,
      p_city: city.isEmpty ? nil : city,
      p_home: home.isEmpty ? nil : home,
      p_index: nil,
      p_marker: marker,
      p_ghin: ghin))
  }

  public func setHandle(_ handle: String) async throws {
    try await svc.call(Rpc.set_handle(p_handle: handle))
  }

  public func setIndex(_ index: Double) async throws {
    try await svc.call(Rpc.set_index(p_index: index))
  }

  public func setDiscoverable(_ mode: String) async throws {
    try await svc.call(Rpc.set_discoverable(p_mode: mode))
  }

  public func setNotifyRounds(_ on: Bool) async throws { try await svc.call(Rpc.set_notify_rounds(p_on: on)) }
  public func setNotifyChat(_ on: Bool) async throws { try await svc.call(Rpc.set_notify_chat(p_on: on)) }

  /// D68: read with no argument, write with one. nil = the RPC is absent.
  public func emailRecap() async -> Bool? {
    try? await svc.call(Rpc.set_email_recap(p_on: nil))
  }
  public func setEmailRecap(_ on: Bool) async throws -> Bool {
    try await svc.call(Rpc.set_email_recap(p_on: on))
  }

  /// D59: square-cropped JPEG straight into {uid}/avatar.jpg; the path rides
  /// `set_profile`. Immediate, not gated on Save.
  public func uploadAvatar(userId: UUID, jpeg: Data, currentName: String) async throws -> URL? {
    let path = "\(userId.uuidString.lowercased())/avatar.jpg"
    try await svc.client.storage.from("media").upload(path, data: jpeg, options: FileOptions(contentType: "image/jpeg", upsert: true))
    try await svc.call(Rpc.set_profile(p_name: currentName, p_photo_path: path))
    return try? await svc.client.storage.from("media").createSignedURL(path: path, expiresIn: 3600)
  }

  public func removeAvatar(userId: UUID, currentName: String) async throws {
    let path = "\(userId.uuidString.lowercased())/avatar.jpg"
    try await svc.call(Rpc.set_profile(p_name: currentName, p_photo_path: ""))
    _ = try? await svc.client.storage.from("media").remove(paths: [path])
  }

  public func deleteAccount() async throws {
    try await svc.call(Rpc.delete_account())
  }

  public func submitFeedback(category: String, body: String, context: [String: JSONValue]) async throws {
    _ = try await svc.call(Rpc.submit_feedback(p_category: category, p_body: body, p_context: .object(context)))
  }

  public func founderId() async -> UUID? {
    try? await svc.call(Rpc.founder_id())
  }

  public func founderDesk() async throws -> JSONValue {
    try await svc.call(Rpc.founder_desk())
  }

  public func founderNote(_ body: String) async throws {
    _ = try await svc.call(Rpc.founder_note(p_body: body))
  }

  /// Read-only "Your leagues" rows for the card pane.
  public struct LeagueRow: Decodable, Sendable, Identifiable {
    public struct League: Decodable, Sendable { public let name: String; public let code: String? }
    public let id: UUID
    public let role: String
    public let leagues: League?
  }
  public func leagues(userId: UUID) async -> [LeagueRow] {
    (try? await svc.client.from("league_members").select("id, role, leagues(name, code)").eq("profile_id", value: userId).execute().value) ?? []
  }
}
