// Cup Season — a shared Tour Card, read from the outside (D186 / D188).
//
// `share_info(token)` is the one anon window onto a shared artifact, and its
// `card` branch (D186) is the golfer as an object: face, number, trophies,
// form, career. This is the phone's reader for it — the half that makes
// `?share=` safe to claim as a Universal Link (D188), because opening the app
// to Home from a card link would be worse than opening Safari, which at least
// shows the card and takes the tap.
//
// Nothing here is authoritative. The server decides whether the card is
// visible at all and whether the NUMBER travels (discoverable='friends' seen
// by a non-buddy renders number-less); this only renders what it is handed.

import Foundation

public struct SharedCard: Sendable, Equatable {
  public var name: String
  public var handle: String?
  public var marker: String?
  public var city: String?
  public var homeCourse: String?
  /// YYYY-MM-DD
  public var memberSince: String?
  /// Absent when the server withheld it — never inferred, never a placeholder.
  public var indexCurrent: Double?
  public var rounds: Int
  public var bestDiff: Double?
  /// "🔥 Broke 80 · '26" — already resolved to display lines by `TrophyMeta`.
  public var trophies: [SharedTrophy]
  /// Newest first, as `share_info` returns it; the form row reverses.
  public var beats: [Bool?]
  /// A face published beside the token at share time (D186).
  public var photo: Bool

  public struct SharedTrophy: Sendable, Equatable {
    public let kind: String
    public let earnedOn: String?
  }

  /// The subtitle under the name: "@handle · Tempe, AZ · est. Jul 2026".
  /// `member_since` arrives as a bare YYYY-MM-DD, so it goes through `CSDate`
  /// and never through an ISO parser — `Date("2026-07-04")` is UTC midnight and
  /// renders the previous day west of Greenwich (the landmine both clients
  /// carry a helper for).
  public var metaLine: String {
    let est = memberSince
      .flatMap { CSDate.local($0, calendar: ScheduleDates.gregorian) }
      .map { "est. " + TourCard.monthYear($0) }
    return [handle.map { "@\($0)" }, city, est]
      .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
  }

  /// The engraved lines, in the credential's own vocabulary — the same
  /// `TrophyMeta` table the owner's card uses, so a card looks identical from
  /// the outside and from the inside.
  public func trophyLines(max: Int = 4, moreSuffix: String = " more") -> [String] {
    var lines = trophies.prefix(max).map { t -> String in
      let m = TrophyMeta.meta(kind: t.kind, label: nil)
      return "\(m.icon) \(m.title)\(TrophyMeta.yearTag(earnedOn: t.earnedOn))"
    }
    if trophies.count > max { lines.append("+\(trophies.count - max)\(moreSuffix)") }
    return lines
  }

  /// The public face, published beside the token at share time (D186). Absent
  /// when the golfer has no photo — the marker is the floor, as everywhere.
  public func photoURL(token: UUID) -> URL? {
    guard photo else { return nil }
    return URL(string: "\(CSConfig.supabaseURL.absoluteString)/storage/v1/object/public/shared/\(token.uuidString.lowercased()).jpg")
  }

  /// `share_info`'s card branch. Returns nil for every dead path — an unknown,
  /// revoked, deleted or since-hidden token all answer the same null (D57), and
  /// a payload of another kind is not ours to render.
  public static func parse(_ json: JSONValue?) -> SharedCard? {
    guard let json, json["kind"]?.string == "card" else { return nil }
    let career = json["career"]
    let trophies: [SharedTrophy] = (json["trophies"]?.array ?? []).compactMap {
      guard let k = $0["kind"]?.string else { return nil }
      return SharedTrophy(kind: k, earnedOn: $0["earned_on"]?.string)
    }
    // `beat` is deliberately tri-state: true beat the number, false did not,
    // null could not be scored. A null is a GAP in the form row, never a loss.
    let beats: [Bool?] = (json["recent"]?.array ?? []).map { $0["beat"]?.bool }
    return SharedCard(
      name: json["name"]?.string ?? "A golfer",
      handle: json["handle"]?.string,
      marker: json["marker"]?.string,
      city: json["city"]?.string,
      homeCourse: json["home_course"]?.string,
      memberSince: json["member_since"]?.string,
      indexCurrent: json["index_current"]?.double,
      rounds: Int(career?["rounds"]?.double ?? 0),
      bestDiff: career?["best"]?.double,
      trophies: trophies,
      beats: beats,
      photo: json["photo"]?.bool ?? false)
  }
}

/// `/?share=TOKEN`, held across the door exactly as a claim is (D188).
public enum ShareIntent {
  /// The web's `localStorage.cs_share` sibling; the app writes it on a
  /// Universal Link and consumes it once the sheet has shown the card.
  public static let key = "cs_share"

  public static func store(_ token: String, defaults: UserDefaults = .standard) {
    defaults.set(token.trimmingCharacters(in: .whitespacesAndNewlines), forKey: key)
  }
  public static func pending(defaults: UserDefaults = .standard) -> UUID? {
    defaults.string(forKey: key).flatMap { UUID(uuidString: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
  }
  public static func clear(defaults: UserDefaults = .standard) { defaults.removeObject(forKey: key) }

  public static func token(from url: URL) -> String? {
    guard let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
          let v = items.first(where: { $0.name == "share" })?.value, !v.isEmpty else { return nil }
    return v.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

/// The reader. Anon-safe by construction: `share_info` is one of the twelve
/// public endpoints, so a signed-OUT phone opening a card link still sees the
/// card — it only needs an account to press the button.
public struct SharedCardRepository: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  /// What a `?share=` token turned out to be.
  ///
  /// The AASA cannot inspect a token, so claiming `?share=` claims ALL FOUR
  /// kinds — round, settlement, recap, card. The phone renders the card; the
  /// other three already have a good web page and rendering them natively is
  /// its own piece of work. `.web` is the honest answer for those: show the
  /// page the sender meant, in-app, rather than tell a reader their live link
  /// is dead. That distinction is the whole reason this is an enum.
  public enum Shared: Sendable, Equatable {
    case card(SharedCard)
    /// A live token of a kind this build does not draw — hand it to the web.
    case web(kind: String)
    /// Unknown, revoked, deleted, or hidden since. One answer for all of them (D57).
    case dead
  }

  public func load(_ token: UUID) async -> Shared {
    guard let json = try? await svc.call(Rpc.share_info(p_token: token)),
          let kind = json["kind"]?.string else { return .dead }
    if let card = SharedCard.parse(json) { return .card(card) }
    return .web(kind: kind)
  }

  /// The public page for a token — the fallback target, and the same URL the
  /// sharer sent.
  public static func webURL(_ token: UUID) -> URL {
    URL(string: "https://cupseason.app/?share=\(token.uuidString.lowercased())")!
  }

  /// D186 call 3 · "Add me on Cup Season". Authenticated only — a signed-out
  /// reader makes a golfer card first and the token replays after. Returns
  /// "friend" (they had asked first), "requested", or "self".
  public func addBuddy(_ token: UUID) async throws -> String {
    try await svc.call(Rpc.share_buddy(p_token: token))
  }

  /// D188 · the store link, or nil while there is no listing to point at.
  public func appStoreURL() async -> URL? {
    guard let json = try? await svc.call(Rpc.door_flags()),
          let s = json["app_store_url"]?.string, !s.isEmpty else { return nil }
    return URL(string: s)
  }
}
