// Cup Season — Home's one feed (IA P1; index.html `loadHome` 16510–16562,
// `feedRow` 10247–10295, `postRow` 10297–10324, `feedBuckets` 10458–10486).
//
// Circle rounds come from `home_feed` (self ∪ buddies ∪ league-mates ∪
// event-mates, 21 days); league moments (announce · system · moment — never
// chat, never round) come from `posts` across every membership. Sorted by
// actual post time, bucketed by the DISPLAYED date, newest first, 30 max.

import Foundation
import Supabase

public typealias HomeFeedRow = Rpc.home_feed.Row

public struct HomePost: Decodable, Sendable, Identifiable {
  public let id: UUID
  public let league_id: UUID?
  public let kind: String
  public let member_id: UUID?
  public let body: String?
  public let created_at: Date?
  public let live_round_id: UUID?
}

public enum HomeItem: Sendable, Identifiable {
  case round(HomeFeedRow, photoURL: URL?)
  case post(HomePost, leagueName: String?)

  public var id: String {
    switch self {
    case .round(let r, _): "r-\(r.round_id?.uuidString ?? UUID().uuidString)"
    case .post(let p, _): "p-\(p.id.uuidString)"
    }
  }
  /// Sort key: actual post time.
  var time: Date {
    switch self {
    case .round(let r, _): r.created_at ?? CSDate.local(r.played_on ?? "") ?? .distantPast
    case .post(let p, _): p.created_at ?? .distantPast
    }
  }
  /// Bucket key: the displayed calendar date.
  var day: String {
    switch self {
    case .round(let r, _): r.played_on ?? (r.created_at.map { CSDate.iso($0) } ?? "")
    case .post(let p, _): p.created_at.map { CSDate.iso($0) } ?? ""
    }
  }
}

public struct HomeBucket: Identifiable, Sendable {
  public let label: String     // "Today" · "This week" · "Earlier"
  public let items: [HomeItem]
  public var id: String { label }
}

public enum HomeBuckets {
  public static let cap = 8
  /// today / this week (≤6 days) / earlier — by displayed date, via CSDate.
  public static func bucket(_ items: [HomeItem], today: String = CSDate.today()) -> [HomeBucket] {
    var g: [[HomeItem]] = [[], [], []]
    for i in items {
      let d = i.day
      var b = 2
      if !d.isEmpty, let days = CSDate.days(from: d, to: today) { b = days <= 0 ? 0 : days <= 6 ? 1 : 2 }
      g[b].append(i)
    }
    var out: [HomeBucket] = []
    if !g[0].isEmpty { out.append(HomeBucket(label: "Today", items: g[0])) }
    if !g[1].isEmpty { out.append(HomeBucket(label: "This week", items: g[1])) }
    if !g[2].isEmpty { out.append(HomeBucket(label: "Earlier", items: g[2])) }
    return out
  }
}

public struct HomeStreamRepository: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  public struct Result: Sendable {
    public let items: [HomeItem]
    public let rounds: [HomeFeedRow]
    public let posts: [HomePost]
  }

  public func load(memberships: [Me.Membership]) async -> Result {
    let ids = memberships.map(\.league_id)
    let names = Dictionary(uniqueKeysWithValues: memberships.map { ($0.league_id, $0.name) })

    async let feed: [HomeFeedRow] = (try? svc.call(Rpc.home_feed(p_days: 21))) ?? []
    async let posts: [HomePost] = ids.isEmpty ? [] : ((try? svc.client.from("posts")
      .select("id, league_id, kind, member_id, body, created_at, live_round_id")
      .in("league_id", values: ids).neq("kind", value: "chat").neq("kind", value: "round")
      .order("created_at", ascending: false).limit(20).execute().value) ?? [])
    let (rows, moments) = await (feed, posts)

    // one batched signing per load: the circle's photo paths → hour URLs
    var urls: [String: URL] = [:]
    let paths = rows.compactMap(\.photo_path).prefix(14)
    if !paths.isEmpty, let signed = try? await svc.client.storage.from("media").createSignedURLs(paths: Array(paths), expiresIn: 3600) {
      for s in signed where s.error == nil { urls[s.path] = s.signedURL }
    }

    let items = (rows.map { HomeItem.round($0, photoURL: $0.photo_path.flatMap { urls[$0] }) }
      + moments.map { HomeItem.post($0, leagueName: $0.league_id.flatMap { names[$0] }) })
      .sorted { $0.time > $1.time }
      .prefix(30)
    return Result(items: Array(items), rounds: rows, posts: moments)
  }
}

// MARK: - copy for a feed row (feedRow 10247–10295)

public enum HomeCopy {
  public static func milestone(_ r: HomeFeedRow) -> String? {
    if r.is_pr == true { return "🔥 Personal best" }
    if r.is_sub80 == true { return "⛳ Broke 80 — first time" }
    if r.is_first == true { return "🎉 First round on the card" }
    return nil
  }
  public static func who(_ r: HomeFeedRow) -> String { r.is_me == true ? "You" : (r.golfer ?? "A golfer") }

  /// `easeCaps` — the server's SHOUTING bodies read as sentences on Home.
  public static func easeCaps(_ s: String) -> String {
    let letters = s.filter(\.isLetter)
    guard letters.count >= 12, letters == letters.uppercased() else { return s }
    var out = s.lowercased()
    if let f = out.first { out.replaceSubrange(out.startIndex...out.startIndex, with: String(f).uppercased()) }
    return out
  }
}

// MARK: - the occasion engine (D81 R3; index.html 10032–10131)

/// Six calendar windows, all copy OBLIQUE — the marker art carries the nod,
/// never a name. Dismiss is per-window-per-year, so next spring the azaleas
/// come back. Weekend CLUSTERING preempts the calendar.
public struct Occasion: Sendable, Identifiable {
  public enum Go: Sendable { case event, league }
  public let key: String
  public let window: (Int, Int, Int, Int)   // m1, d1, m2, d2
  public let earned: Bool
  public let k: String
  public let h: String
  public let p: String
  public let act: String
  public let go: Go
  public let marker: String?
  public let leaguelessOnly: Bool
  public var id: String { key }

  public static let all: [Occasion] = [
    Occasion(key: "opener", window: (3, 28, 4, 13), earned: true, k: "The first one of the year", h: "Azaleas are blooming somewhere.",
             p: "One window, every card on one board, one name on the jug.", act: "Put a jug up", go: .event, marker: "azalea", leaguelessOnly: false),
    Occasion(key: "test", window: (6, 8, 6, 22), earned: true, k: "The hardest test", h: "Somewhere out there, par is winning.",
             p: "A championship window — two to four days, best card takes it.", act: "Set the Major", go: .event, marker: "no2", leaguelessOnly: false),
    Occasion(key: "oldest", window: (7, 10, 7, 24), earned: true, k: "The oldest one", h: "Links weather is a state of mind.",
             p: "One window, every card on one board, one name on the jug.", act: "Name the jug", go: .event, marker: "jug", leaguelessOnly: false),
    Occasion(key: "teams", window: (9, 18, 10, 5), earned: false, k: "The big team match", h: "Two teams. One cup. You know the one.",
             p: "Weekly duels, first past half the points. Yours can start the same weekend.", act: "Run your own", go: .event, marker: nil, leaguelessOnly: false),
    Occasion(key: "fall", window: (10, 1, 11, 20), earned: true, k: "The season's turning", h: "Cool mornings, empty tee sheets.",
             p: "A fall Major — two to four days, best card takes it.", act: "Name the jug", go: .event, marker: nil, leaguelessOnly: false),
    Occasion(key: "fresh", window: (12, 27, 1, 15), earned: false, k: "A fresh table", h: "Nobody's ahead yet.",
             p: "A season scores the rounds you’re already playing. Nothing changes about how you post.", act: "Start a league", go: .league, marker: nil, leaguelessOnly: true),
  ]

  public static func inWindow(_ w: (Int, Int, Int, Int), month m: Int, day: Int) -> Bool {
    let after = m > w.0 || (m == w.0 && day >= w.1)
    let before = m < w.2 || (m == w.2 && day <= w.3)
    return w.0 <= w.2 ? (after && before) : (after || before)   // Dec→Jan wraps
  }

  /// The one to show today, honouring per-year dismissals.
  public static func current(leagueless: Bool, today: Date = Date(), calendar: Calendar = .current, defaults: UserDefaults = .standard) -> Occasion? {
    let c = calendar.dateComponents([.year, .month, .day], from: today)
    guard let y = c.year, let m = c.month, let d = c.day else { return nil }
    return all.first { o in
      inWindow(o.window, month: m, day: d) && !(o.leaguelessOnly && !leagueless) && !defaults.bool(forKey: "cs_occ_\(o.key)_\(y)")
    }
  }

  public static func dismiss(_ o: Occasion, today: Date = Date(), calendar: Calendar = .current, defaults: UserDefaults = .standard) {
    let y = calendar.component(.year, from: today)
    defaults.set(true, forKey: "cs_occ_\(o.key)_\(y)")
  }
}
