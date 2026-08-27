// Cup Season — the quiet-day frame (index.html 10488–10614; D27).
//
// "An open never reveals nothing." Home either says what changed since your
// last visit, or on a genuinely quiet day resurfaces the best recent thing.
// The seen-mark is per profile and read ONCE per load so a re-render
// mid-session cannot erase the digest you are reading.
// Mentions (reactions/comments on YOUR rounds since the mark) come from
// `HomeSocial.Snapshot.mentions` — a 🔥 at 11pm is news at 7am.

import Foundation

public struct HomeDigest: Sendable, Equatable {
  public enum Kind: Sendable, Equatable { case since, quiet }
  public let kind: Kind
  /// "Since you were here" · "Quiet since your last visit"
  public let label: String
  /// The sentence body (already joined; plain text — bold is the view's job).
  public let body: String
  /// For the quiet frame: the resurfaced round, so a thumb can open its receipt.
  public let roundId: UUID?
  public let photoURL: URL?

  private static func key(profile: UUID?) -> String { "cs.seen.\(profile?.uuidString.lowercased() ?? "anon")" }

  /// Read the mark once, then advance it — the web's `dgAsOf` + `dgMarkSeen`.
  public static func readAndMark(profile: UUID?, defaults: UserDefaults = .standard, now: Date = Date()) -> Date? {
    let k = key(profile: profile)
    let prev = defaults.double(forKey: k)
    defaults.set(now.timeIntervalSince1970, forKey: k)
    return prev > 0 ? Date(timeIntervalSince1970: prev) : nil
  }

  /// serial comma is load-bearing: "a personal best from Diego and Rosa broke 80"
  static func join(_ a: [String]) -> String {
    if a.count < 2 { return a.first ?? "" }
    if a.count == 2 { return "\(a[0]) and \(a[1])" }
    return a.dropLast().joined(separator: ", ") + ", and " + a[a.count - 1]
  }

  static func who(_ r: HomeFeedRow) -> String { r.is_me == true ? "You" : (r.golfer ?? "a golfer") }

  static func day(_ t: Date, now: Date, calendar: Calendar) -> String {
    let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: t), to: calendar.startOfDay(for: now)).day ?? 0
    if days <= 0 { return "Today" }
    if days == 1 { return "Yesterday" }
    return CSDate.short(CSDate.iso(t, calendar: calendar), calendar: calendar)
  }

  /// A milestone outranks a good score, a good score outranks a recent one.
  static func best(_ rounds: [HomeFeedRow], now: Date) -> HomeFeedRow? {
    let recent = rounds.filter { r in
      let t = r.created_at ?? CSDate.local(r.played_on ?? "") ?? .distantPast
      return now.timeIntervalSince(t) <= 14 * 86400
    }
    func rank(_ r: HomeFeedRow) -> Int { r.is_pr == true ? 4 : r.is_sub80 == true ? 3 : r.is_first == true ? 2 : 1 }
    return recent.sorted { a, b in
      if rank(a) != rank(b) { return rank(a) > rank(b) }
      if (a.pvi ?? 0) != (b.pvi ?? 0) { return (a.pvi ?? 0) > (b.pvi ?? 0) }
      return (a.created_at ?? .distantPast) > (b.created_at ?? .distantPast)
    }.first
  }

  static func line(_ r: HomeFeedRow) -> String {
    let w = who(r), course = r.course ?? "a round", g = r.gross.map(String.init) ?? "—"
    if r.is_pr == true { return "\(w) set a personal best — \(g) at \(course)" }
    if r.is_sub80 == true { return "\(w) broke 80 — \(g) at \(course)" }
    if r.is_first == true { return "\(w) posted \(r.is_me == true ? "your" : "their") first round — \(g) at \(course)" }
    return "\(w) posted \(g) at \(course)"
  }

  /// nil = nothing to frame (first visit, or truly nothing).
  public static func make(rounds: [HomeFeedRow], posts: [HomePost], photoURLs: [UUID: URL] = [:], mark: Date?,
                          mentions: [HomeSocial.Mention] = [], now: Date = Date(), calendar: Calendar = .current) -> HomeDigest? {
    guard let mark else { return nil }   // first visit — the feed IS the reveal
    let freshRounds = rounds.filter { ($0.created_at ?? CSDate.local($0.played_on ?? "") ?? .distantPast) > mark }
    let freshPosts = posts.filter { ($0.created_at ?? .distantPast) > mark }
    // mentions can RESCUE a quiet day — a reaction on your round IS something new
    if !freshRounds.isEmpty || !freshPosts.isEmpty || !mentions.isEmpty {
      var bits: [String] = []
      if !freshRounds.isEmpty { bits.append("\(freshRounds.count) round\(freshRounds.count > 1 ? "s" : "")") }
      if let pr = freshRounds.first(where: { $0.is_pr == true }) { bits.append("a personal best from \(who(pr))") }
      if let s = freshRounds.first(where: { $0.is_sub80 == true }) { bits.append("\(who(s)) broke 80") }
      if let f = freshRounds.first(where: { $0.is_first == true }) { bits.append("\(who(f))'s first round") }
      if !freshPosts.isEmpty { bits.append("\(freshPosts.count) league note\(freshPosts.count > 1 ? "s" : "")") }
      if let m = mentions.first {
        let g = m.gross.map(String.init) ?? "round"
        bits.append(m.emoji.map { "\(m.who) \($0)’d your \(g)" } ?? "\(m.who) chimed in on your \(g)")
        if mentions.count > 1 { bits.append("\(mentions.count - 1) more chimed in on your rounds") }
      }
      guard !bits.isEmpty else { return nil }
      return HomeDigest(kind: .since, label: "Since you were here", body: join(bits) + ".", roundId: nil, photoURL: nil)
    }
    guard let b = best(rounds, now: now) else { return nil }
    let t = b.created_at ?? CSDate.local(b.played_on ?? "") ?? now
    return HomeDigest(kind: .quiet, label: "Quiet since your last visit", body: "\(day(t, now: now, calendar: calendar)) — \(line(b))",
                      roundId: b.round_id, photoURL: b.round_id.flatMap { photoURLs[$0] })
  }
}
