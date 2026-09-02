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
  /// D209 · ONE lens. `20260902180000_one_lens_on_the_tour_card.sql` moves
  /// `career.avg_pvi` onto the allowance number the You tab already speaks,
  /// adds `best_pvi` beside it, and preserves the old 100% average under the
  /// new name `avg_vs_index`. So the block carries BOTH shapes and says which
  /// one it is holding.
  ///
  /// The switch is the FIGURES, not the keys. A leagueless golfer has no row
  /// in `v_rounds_ranked` at all, so the new server sends the allowance keys
  /// as JSON null — four real profiles are in exactly that state — and
  /// switching on key presence alone would print a dash where a real number
  /// used to be. `playingLens` is therefore true only when an allowance
  /// figure actually arrived; otherwise the block falls back to the 100%
  /// average under the 100% label, and the phone never prints the You tab's
  /// words over a figure that is not the You tab's number.
  public struct CareerBlock: Sendable, Equatable {
    public let rounds: Int
    /// `career.best` — the OLD figure: the lowest round against the course
    /// rating. Lower is better, and it is not a delta against any number.
    /// Untouched by the migration; still the fallback's "best".
    public let best: Double?
    /// `career.avg_pvi` — the average against the PLAYING number. Nil on an
    /// old payload (where that key held the 100% figure, decoded into
    /// `avgVsIndex` instead) and nil for a golfer with no ranked rounds.
    public let avgPvi: Double?
    /// `career.best_pvi` — the best round against the PLAYING number (the max
    /// of the allowance figures, exactly as `Career.best` computes it on You).
    public let bestPvi: Double?
    /// The 100% average, `index_at_post − differential`: `avg_vs_index` on the
    /// new payload, `avg_pvi` on the old one. This is what the fallback row
    /// prints, and it is genuinely "vs your number".
    public let avgVsIndex: Double?
    /// true when an allowance figure actually arrived — see the note above
    public let playingLens: Bool

    public init(rounds: Int, best: Double?, avgPvi: Double?, bestPvi: Double? = nil,
                avgVsIndex: Double? = nil, playingLens: Bool = false) {
      self.rounds = rounds; self.best = best; self.avgPvi = avgPvi
      self.bestPvi = bestPvi; self.avgVsIndex = avgVsIndex; self.playingLens = playingLens
    }
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
    // Which SHAPE the server speaks is key presence; which LENS the card
    // wears is whether a figure actually came back. On the old payload
    // `avg_pvi` IS the 100% average, so it is decoded as `avgVsIndex` and the
    // allowance fields stay nil; on the new one the 100% figure has moved to
    // its own key and `avg_pvi` means what its name says.
    let newShape = c?["avg_vs_index"] != nil || c?["best_pvi"] != nil
    let avgPvi = newShape ? c?["avg_pvi"]?.double : nil
    let bestPvi = c?["best_pvi"]?.double
    let career = CareerBlock(rounds: c?["rounds"]?.int ?? 0, best: c?["best"]?.double, avgPvi: avgPvi,
                             bestPvi: bestPvi,
                             avgVsIndex: newShape ? c?["avg_vs_index"]?.double : c?["avg_pvi"]?.double,
                             playingLens: avgPvi != nil || bestPvi != nil)
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

  /// "est. Aug 2026" — month + year of an instant. The word is "est." on every
  /// surface (Y-26); "Member since" is retired.
  public static func monthYear(_ d: Date, calendar: Calendar = .current) -> String {
    let f = DateFormatter(); f.calendar = calendar; f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "MMM yyyy"
    // non-breaking: "Jul 2026" is one fact and never breaks across two lines
    return f.string(from: d).replacingOccurrences(of: " ", with: "\u{00A0}")
  }

  /// "est. Aug 2026" — the one form of the founding date, for the credential
  /// and for settings alike. A retyped copy is the version that will drift.
  public static func established(_ d: Date, calendar: Calendar = .current) -> String { "est.\u{00A0}" + monthYear(d, calendar: calendar) }

  // MARK: - the Career block, its figures and the words that name them

  /// D209 · true once the server sends the allowance figures.
  public var playingLens: Bool { career.playingLens }

  /// The best round. Under the allowance lens it is a delta and signs like
  /// every other figure on the card; before it, the old course score, which
  /// runs the other way and is never given a `+`.
  public var bestText: String {
    career.playingLens ? (career.bestPvi.map(RoundCopy.signed) ?? "—") : (career.best.map(RoundCopy.f1) ?? "—")
  }
  /// Under the lens, the allowance average; before it, the 100% one — which
  /// is a real number for a golfer no season has ever ranked, and the reason
  /// this row does not go to a dash the day the migration lands.
  public var avgText: String {
    (career.playingLens ? career.avgPvi : career.avgVsIndex).map(RoundCopy.signed) ?? "—"
  }

  /// D209 · the lens is named ONCE, in the section's eyebrow, instead of being
  /// buried in every row label. Before the allowance keys arrive the block
  /// holds two different measurements and there is no single lens to name, so
  /// the eyebrow stays bare and the rows keep their own words.
  public static func careerEyebrow(playingLens: Bool, isMe: Bool) -> String {
    guard playingLens else { return careerTitle }
    return careerTitle + " · " + (isMe ? YouCopy.vsPlayingNumber : RoundCopy.theirs(YouCopy.vsPlayingNumber))
  }
  public static let careerTitle = "Career"
  public static let roundsLabel = "Rounds"

  /// Under the lens this is the You tab's own row, word for word
  /// (`YouCopy.bestRound`), so the two surfaces read as one number.
  public static func bestLabel(playingLens: Bool) -> String {
    playingLens ? YouCopy.bestRound : "Best round vs course"
  }
  /// The tail of "Avg vs your playing number" lives in the eyebrow above it;
  /// the old figure keeps the whole label, because the old figure is a
  /// different number.
  public static func avgLabel(playingLens: Bool, isMe: Bool) -> String {
    playingLens ? "Avg" : "Avg vs \(isMe ? "your" : "their") number"
  }

  /// The two OLD figures run opposite ways — a course score where lower wins
  /// sits beside a delta where `+` wins — and one table cannot sign both the
  /// same way. So the table says which is which. It goes with them.
  public static func careerSignsLine(isMe: Bool) -> String {
    "Lower is better against the course; against \(isMe ? "your" : "their") number, + is better."
  }
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
