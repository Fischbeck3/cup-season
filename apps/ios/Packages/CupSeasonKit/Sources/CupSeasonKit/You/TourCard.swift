// Cup Season — the Tour Card: any golfer's whole card (index.html
// `openTourCard` 13293–13457; `tour_card()` 20260726190000).
//
// Visibility is enforced server-side (shared league/event, accepted buddy, or
// discoverable=everyone) — `visible:false` is the whole answer. The buddy
// relationship is derived from `my_friends` (fetched alongside, not after);
// the mute set from `my_mutes`. The avatar is signed from the profile's
// `photo_path` when that row is readable; the marker is the floor.

import Foundation
import Supabase

public struct TourCard: Sendable {
  public struct Profile: Sendable, Equatable {
    public let id: UUID?
    public let displayName: String?
    public let handle: String?
    public let marker: String?
    public let city: String?
    public let homeCourse: String?
    public let indexCurrent: Double?
    public let ghin: String?
    public let memberSince: Date?
    public let isMe: Bool
  }
  public struct CareerBlock: Sendable, Equatable {
    public let rounds: Int
    public let best: Double?      // min differential
    public let avgPvi: Double?
  }
  public struct Recent: Sendable, Equatable, Identifiable {
    public let playedOn: String
    public let courseLabel: String?
    public let gross: Int?
    public let differential: Double?
    public let holesPlayed: Int?
    public let beat: Bool?
    public var id: String { "\(playedOn)|\(gross ?? 0)|\(courseLabel ?? "")" }
  }
  public struct VsYou: Sendable, Equatable {
    public let wins: Int, losses: Int, ties: Int
    public var total: Int { wins + losses + ties }
    public var record: String { RivalryCopy.record(wins: wins, losses: losses, ties: ties) }
    public var lead: String { RivalryCopy.leadLabel(wins: wins, losses: losses) }
    /// "VS YOU · 3–2 · YOU LEAD"
    public var chip: String { "VS YOU · \(record) · \(lead)" }
  }

  public let visible: Bool
  public let profile: Profile
  public let career: CareerBlock
  public let trophies: [Rpc.my_achievements.Row]
  public let recent: [Recent]
  public let vsYou: VsYou?

  public static let privateLine = "This golfer keeps their card private, or you don’t share a league yet."

  public static func parse(_ json: JSONValue) -> TourCard {
    let p = json["profile"], c = json["career"]
    let profile = Profile(
      id: p?["id"]?.string.flatMap(UUID.init), displayName: p?["display_name"]?.string, handle: p?["handle"]?.string,
      marker: p?["marker"]?.string, city: p?["city"]?.string, homeCourse: p?["home_course"]?.string,
      indexCurrent: p?["index_current"]?.double, ghin: p?["ghin"]?.string,
      memberSince: p?["member_since"]?.string.flatMap(Self.timestamp), isMe: p?["is_me"]?.bool ?? false)
    let career = CareerBlock(rounds: c?["rounds"]?.int ?? 0, best: c?["best"]?.double, avgPvi: c?["avg_pvi"]?.double)
    let trophies: [Rpc.my_achievements.Row] = (json["trophies"]?.array ?? []).compactMap { t in
      guard let data = try? JSONEncoder().encode(t) else { return nil }
      return try? JSONDecoder().decode(Rpc.my_achievements.Row.self, from: data)
    }
    let recent: [Recent] = (json["recent"]?.array ?? []).compactMap { r in
      guard let on = r["played_on"]?.string else { return nil }
      return Recent(playedOn: on, courseLabel: r["course_label"]?.string, gross: r["gross"]?.int, differential: r["differential"]?.double,
                    holesPlayed: r["holes_played"]?.int, beat: r["beat"]?.bool)
    }
    var vs: VsYou? = nil
    if let v = json["vs_you"], case .object = v {
      vs = VsYou(wins: v["wins"]?.int ?? 0, losses: v["losses"]?.int ?? 0, ties: v["ties"]?.int ?? 0)
    }
    return TourCard(visible: json["visible"]?.bool ?? false, profile: profile, career: career, trophies: trophies, recent: recent, vsYou: vs)
  }

  /// A Postgres timestamptz as jsonb writes it (with or without fractional
  /// seconds). This is an instant, not a calendar date, so ISO parsing is right.
  static func timestamp(_ s: String) -> Date? {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = f.date(from: s) { return d }
    f.formatOptions = [.withInternetDateTime]
    if let d = f.date(from: s) { return d }
    // "2026-07-06 14:03:11.12345+00" — the space form
    let g = DateFormatter(); g.locale = Locale(identifier: "en_US_POSIX"); g.timeZone = TimeZone(secondsFromGMT: 0)
    for fmt in ["yyyy-MM-dd HH:mm:ss.SSSSSSxx", "yyyy-MM-dd HH:mm:ssxx", "yyyy-MM-dd'T'HH:mm:ss.SSSSSSxx"] {
      g.dateFormat = fmt
      if let d = g.date(from: s) { return d }
    }
    return nil
  }

  /// "est. Aug 2026" / "Member since Aug 2026" — month + year of an instant.
  public static func monthYear(_ d: Date, calendar: Calendar = .current) -> String {
    let f = DateFormatter(); f.calendar = calendar; f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "MMM yyyy"
    return f.string(from: d)
  }

  // the Career block strings
  public var bestText: String { career.best.map(RoundCopy.f1) ?? "—" }
  public var avgText: String { career.avgPvi.map(RoundCopy.signed) ?? "—" }
}

/// The buddy relationship with the card's golfer, from `my_friends`.
public enum BuddyRelation: Sendable, Equatable {
  case none
  case friend
  case incoming(friendshipId: UUID)
  case requested

  public static func from(_ friends: [Rpc.my_friends.Row], profile: UUID) -> BuddyRelation {
    guard let f = friends.first(where: { $0.profile_id == profile }) else { return .none }
    if f.status == "accepted" { return .friend }
    if f.incoming == true, let fid = f.friendship_id { return .incoming(friendshipId: fid) }
    return .requested
  }

  /// The button label, when there is one to tap.
  public var actionLabel: String? {
    switch self {
    case .none: "Add buddy"
    case .incoming: "Accept buddy request"
    case .friend, .requested: nil
    }
  }
  /// The settled tag, when there is nothing to tap.
  public var tag: String? {
    switch self {
    case .friend: "Buddies"
    case .requested: "Requested"
    default: nil
    }
  }
}

public struct TourCardLoad: Sendable {
  public let card: TourCard
  public let relation: BuddyRelation
  public let muted: Bool
  public let avatarURL: URL?
}

public struct TourCardRepository: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  private struct PhotoRow: Decodable { let photo_path: String? }

  /// `tour_card` + `my_friends` + `my_mutes` in parallel; the avatar best-effort.
  public func load(_ profileId: UUID) async throws -> TourCardLoad {
    async let cardJSON = svc.call(Rpc.tour_card(p_profile: profileId))
    async let friends: [Rpc.my_friends.Row] = (try? await svc.call(Rpc.my_friends())) ?? []
    async let mutes: [UUID] = (try? await svc.call(Rpc.my_mutes())) ?? []
    async let avatar: URL? = signedAvatar(profileId)
    let card = TourCard.parse(try await cardJSON)
    return TourCardLoad(card: card, relation: BuddyRelation.from(await friends, profile: profileId),
                        muted: await mutes.contains(profileId), avatarURL: await avatar)
  }

  private func signedAvatar(_ profileId: UUID) async -> URL? {
    let rows: [PhotoRow]? = try? await svc.client.from("profiles").select("photo_path").eq("id", value: profileId).execute().value
    guard let path = rows?.first?.photo_path, !path.isEmpty else { return nil }
    return try? await svc.client.storage.from("media").createSignedURL(path: path, expiresIn: 3600)
  }

  /// `friend_request` → "friend" (they had asked first) or "requested".
  public func friendRequest(_ profileId: UUID) async throws -> BuddyRelation {
    let r = try await svc.call(Rpc.friend_request(p_profile: profileId))
    return r == "friend" ? .friend : .requested
  }

  public func acceptRequest(_ friendshipId: UUID) async throws {
    _ = try await svc.call(Rpc.friend_respond(p_id: friendshipId, p_accept: true))
  }

  public func setMute(_ profileId: UUID, on: Bool) async throws {
    _ = try await svc.call(Rpc.set_mute(p_profile: profileId, p_on: on))
  }

  /// D59 moderation: lands on the founder desk.
  public func reportPhoto(_ profileId: UUID) async throws {
    _ = try await svc.call(Rpc.report_content(p_post: nil, p_reason: "profile photo", p_kind: "profile_photo", p_profile: profileId))
  }

  public func rivalryWeeks(_ opponent: UUID) async throws -> [Rpc.rivalry_weeks.Row] {
    try await svc.call(Rpc.rivalry_weeks(p_opponent: opponent))
  }

  public func setRivalryName(_ opponent: UUID, name: String) async throws {
    _ = try await svc.call(Rpc.set_rivalry_name(p_opponent: opponent, p_name: name))
  }
}
