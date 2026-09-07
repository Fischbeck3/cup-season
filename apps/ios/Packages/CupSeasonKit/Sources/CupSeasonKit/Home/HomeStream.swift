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

public struct HomePost: Decodable, Sendable, Identifiable, Equatable {
  public let id: UUID
  public let league_id: UUID?
  public let kind: String
  public let member_id: UUID?
  public let body: String?
  public let created_at: Date?
  public let live_round_id: UUID?
  /// The posted round a round/moment line is about (`posts.round_id`).
  public let round_id: UUID?
  /// D219 · the booking a "put a round on the books" line is about
  /// (`posts.scheduled_round_id`). nil before the column lands (deploy skew).
  public let scheduled_round_id: UUID?

  public init(id: UUID, league_id: UUID?, kind: String, member_id: UUID? = nil, body: String?, created_at: Date?,
              live_round_id: UUID? = nil, round_id: UUID? = nil, scheduled_round_id: UUID? = nil) {
    self.id = id; self.league_id = league_id; self.kind = kind; self.member_id = member_id; self.body = body
    self.created_at = created_at; self.live_round_id = live_round_id; self.round_id = round_id
    self.scheduled_round_id = scheduled_round_id
  }
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
  public var time: Date {
    switch self {
    case .round(let r, _): r.created_at ?? CSDate.local(r.played_on ?? "") ?? .distantPast
    case .post(let p, _): p.created_at ?? .distantPast
    }
  }
  /// Bucket key: the displayed calendar date.
  public var day: String {
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
    /// The circle's feed could not be read at all (offline, a 5xx). Every read
    /// in here is a `try?`, so a failure and a quiet week both arrive as an
    /// empty `items` — this is the one bit that tells them apart, and Home
    /// needs it: a failed read is not an empty feed (the You screen's rule),
    /// so a pull on a bad signal keeps what is already on screen instead of
    /// painting "No rounds from your buddies yet." over the circle's rounds.
    public let failed: Bool

    public init(items: [HomeItem], rounds: [HomeFeedRow], posts: [HomePost], failed: Bool = false) {
      self.items = items; self.rounds = rounds; self.posts = posts; self.failed = failed
    }
  }

  /// D176 · the clash, on the FALLBACK path only. `native_home` v3 inlines it
  /// (`membership.clash`), so a current payload needs no call at all; this is
  /// what a v2 payload still reaches for. One RPC, `try?` on the whole read:
  /// an un-migrated database renders no card, and the 42501 lesson holds —
  /// ANY error, never a sniffed message.
  /// `roster` is the league's headcount (`Membership.headcount`) — the card's
  /// week-1 sentence is the two-person league's (D207), and the RPC does not
  /// say how many are in it.
  public func clash(league: UUID?, roster: Int? = nil) async -> HomeClash? {
    guard let league else { return nil }
    return HomeClash.decode(try? await svc.call(Rpc.home_clash(p_league: league)), roster: roster)
  }

  /// R1 · the dispatch. ONE read: `{me, items, lead_suppress, generated_at}`.
  ///
  /// Hand-declared rather than generated, because the migration that creates
  /// the function is written and unpushed — the documented shape while a
  /// migration awaits its contract refresh (preflight 17 tolerates it and
  /// still demands the grant). `p_days` is optional on both sides.
  ///
  /// nil means "the ranker could not be reached", which is a DIFFERENT answer
  /// from "the ranker returned nothing": the first renders `HomeFallbackItems`,
  /// the second renders an honest, shorter Home.
  struct DispatchCall: RpcCall {
    static let name = "home_dispatch"
    static let optionalArgs: [String] = ["p_days"]
    typealias Returns = HomeDispatch.Payload
    var p_days: Int?
  }

  public func dispatch(days: Int = 21) async -> HomeDispatch.Payload? {
    try? await svc.call(DispatchCall(p_days: days))
  }

  public func load(memberships: [Me.Membership]) async -> Result {
    let ids = memberships.map(\.league_id)
    let names = Dictionary(uniqueKeysWithValues: memberships.map { ($0.league_id, $0.name) })

    // nil, not [] — the empty feed and the feed that could not be read are
    // different stories and only this call can tell them apart.
    async let feed: [HomeFeedRow]? = try? svc.call(Rpc.home_feed(p_days: 21))
    async let posts: [HomePost] = ids.isEmpty ? [] : loadPosts(ids)
    // D262 · THE PERSON RAIL GETS ITS FIRST READER. D238 gave a post the right
    // to be homed on a golfer instead of a league — the rail a leagueless
    // golfer's milestones and a bag change ride — and nothing has ever read
    // one: both clients filtered the board by `league_id`, so every
    // profile-homed post written since has gone nowhere. The circle's own
    // rounds already arrive through `home_feed`, so `round` stays out here or
    // the same round would be told twice; `chat` stays out for the same reason
    // it does in the league read.
    async let personal: [HomePost] = loadPersonPosts()
    let (read, leaguePosts, personPosts) = await (feed, posts, personal)
    // deduped by id: nothing writes a post that is homed on a league AND a
    // person today, but a list that renders by id must not depend on that.
    var seenPosts = Set<UUID>()
    let moments = (leaguePosts + personPosts).filter { seenPosts.insert($0.id).inserted }
    let rows = read ?? []

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
    return Result(items: Array(items), rounds: rows, posts: moments, failed: read == nil)
  }

  /// The posts read, in two tries. `scheduled_round_id` (D219) is the newest
  /// column on `posts`; a database the migration has not reached answers the
  /// full select with an error, and the deploy-skew rule (CLAUDE.md) says a
  /// new column needs a client-side retry that drops it — ANY error, never a
  /// sniffed message. Both tries fail → an empty feed, never a broken Home.
  static let postColumns = "id, league_id, kind, member_id, body, created_at, live_round_id, round_id"
  func loadPosts(_ ids: [UUID]) async -> [HomePost] {
    func read(_ columns: String) async throws -> [HomePost] {
      try await svc.client.from("posts").select(columns)
        .in("league_id", values: ids).neq("kind", value: "chat").neq("kind", value: "round")
        .order("created_at", ascending: false).limit(20).execute().value
    }
    if let full = try? await read(Self.postColumns + ", scheduled_round_id") { return full }
    return (try? await read(Self.postColumns)) ?? []
  }

  /// D262 · the person-homed posts this viewer may see. There is no id list to
  /// pass: `posts_profile_read` (D238) IS the filter — self, an accepted
  /// buddy, a shared league, a shared event, or a golfer discoverable to
  /// everyone, minus anyone muted — which is the Tour Card's own circle, so
  /// the client cannot widen it by asking wrong.
  ///
  /// A database that predates `posts.profile_id` answers with an error, and an
  /// error here is an empty list rather than a broken Home (deploy skew, both
  /// directions).
  func loadPersonPosts() async -> [HomePost] {
    func read(_ columns: String) async throws -> [HomePost] {
      try await svc.client.from("posts").select(columns)
        .not("profile_id", operator: .is, value: "null")
        .neq("kind", value: "chat").neq("kind", value: "round")
        .order("created_at", ascending: false).limit(20).execute().value
    }
    if let full = try? await read(Self.postColumns + ", scheduled_round_id") { return full }
    return (try? await read(Self.postColumns)) ?? []
  }
}

// MARK: - copy for a feed row (feedRow 10247–10295)

public enum HomeCopy {
  public static func milestone(_ r: HomeFeedRow) -> String? {
    if r.is_pr == true { return "🔥 Personal best" }
    if r.is_sub80 == true { return "⛳ Broke 80 — first time" }
    // TERMINOLOGY §4 row 7 · the card is the CREDENTIAL; a round POSTS.
    if r.is_first == true { return "🎉 First round posted" }
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
///
/// D252 · FOUR of the six sell a Major or a jug, and the Major's door is gated
/// on `app_flags.ios.major`. A card that offers a door that will not open is
/// the one dishonesty the design does not permit (L-32, L-44), so `needsMajor`
/// marks them and `current(leagueless:majorOpen:)` withholds them until the
/// flag is read TRUE.
///
/// **R-E opened the flag** —
/// `supabase/migrations/20260912090000_the_major_opens.sql`, wave 3, in the
/// same wave that made the Major's surfaces good enough to receive the traffic.
/// **Nothing here changed to un-darken them, deliberately:** the gate is a READ
/// of prod, not a constant, so the four cards come back the moment the owner
/// pushes that migration and stay dark until then, on a build that is already
/// in TestFlight. That is the whole reason the sequencing clause was written as
/// a flag rather than as a promise to remember.
///
/// The flag still defaults to `false` here for the same reason
/// `EventPickerSheet` reads it fail-closed: an unreadable flag hides a door
/// rather than advertising one, and the curtain has to keep working in both
/// directions.
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
  /// This card's act is a Major or a jug — it renders only once the Major's
  /// flag is on. `teams` (a Ryder) and `fresh` (a league) are not gated.
  public let needsMajor: Bool
  public var id: String { key }

  public static let all: [Occasion] = [
    Occasion(key: "opener", window: (3, 28, 4, 13), earned: true, k: "The first one of the year", h: "Azaleas are blooming somewhere.",
             p: "One window, every card on one board, one name on the jug.", act: "Put a jug up", go: .event, marker: "azalea", leaguelessOnly: false, needsMajor: true),
    Occasion(key: "test", window: (6, 8, 6, 22), earned: true, k: "The hardest test", h: "Somewhere out there, par is winning.",
             p: "A championship window — two to four days, best round takes it.", act: "Set the Major", go: .event, marker: "no2", leaguelessOnly: false, needsMajor: true),
    Occasion(key: "oldest", window: (7, 10, 7, 24), earned: true, k: "The oldest one", h: "Links weather is a state of mind.",
             p: "One window, every card on one board, one name on the jug.", act: "Name the jug", go: .event, marker: "jug", leaguelessOnly: false, needsMajor: true),
    Occasion(key: "teams", window: (9, 18, 10, 5), earned: false, k: "The big team match", h: "Two teams. One cup. You know the one.",
             p: "One opponent a week, first past half the points. Yours can start the same weekend.", act: "Run your own", go: .event, marker: nil, leaguelessOnly: false, needsMajor: false),
    Occasion(key: "fall", window: (10, 1, 11, 20), earned: true, k: "The season's turning", h: "Cool mornings, empty fairways.",
             p: "A fall Major — two to four days, best round takes it.", act: "Name the jug", go: .event, marker: nil, leaguelessOnly: false, needsMajor: true),
    // QB-19 · **THE ONE CARD WRITTEN FOR A GOLFER WITH NOTHING RUNNING FIRED
    // TWENTY DAYS A YEAR.**
    //
    // Its window was Dec 27 – Jan 15, so it was unreachable for eleven and a
    // half months: *"the app has a card designed for exactly my state and its
    // window is Dec 27 to Jan 15. It is September."* Every other row here is a
    // genuine calendar occasion — a Major has a date and the card belongs to
    // it. This one is not an occasion at all. It is a STATE, and boxing a
    // state inside a calendar window was the error.
    //
    // So its window is the year. It is still last in the list, so any real
    // occasion in season takes the slot ahead of it; it still only reaches a
    // golfer with nothing running; and `Occasion.dismiss` still retires it for
    // the year on one tap. What it stops being is unreachable.
    Occasion(key: "fresh", window: (1, 1, 12, 31), earned: false, k: "A fresh table", h: "Nobody's ahead yet.",
             p: "A season scores the rounds you’re already playing. Nothing changes about how you post.", act: "Start a season", go: .league, marker: nil, leaguelessOnly: true, needsMajor: false),
  ]

  /// B-1 / QB-19 · the predicate `leagueless` actually wants. A membership
  /// whose season is wrapped, or which has no season at all, is not a season
  /// running — and a golfer with six buddies and a finished season is exactly
  /// who "Nobody's ahead yet." was written for.
  ///
  /// One producer, so Home and anything else that asks the question cannot
  /// answer it two different ways.
  public static func nothingRunning(_ memberships: [Me.Membership], today: String = CSDate.today()) -> Bool {
    !memberships.contains { m in
      switch SeasonPhase.of(m, today: today) {
      case .preseason, .season, .cupFinal: return true
      case .forming, .wrapped:             return false
      }
    }
  }

  public static func inWindow(_ w: (Int, Int, Int, Int), month m: Int, day: Int) -> Bool {
    let after = m > w.0 || (m == w.0 && day >= w.1)
    let before = m < w.2 || (m == w.2 && day <= w.3)
    return w.0 <= w.2 ? (after && before) : (after || before)   // Dec→Jan wraps
  }

  /// The one to show today, honouring per-year dismissals.
  ///
  /// `majorOpen` defaults to **false** (D252): a caller that has not read
  /// `app_flags.ios.major` shows no card that sells a Major, which is the same
  /// answer `EventPickerSheet` gives when the flag will not read. A withheld
  /// card does not blank Home — the next window that is not gated takes its
  /// place, exactly as a dismissed one does.
  /// `leagueless` · **B-1 / QB-19 · IT MEANS "NOTHING RUNNING", NOT "NO
  /// LEAGUE".** Both callers used to compute it as `memberships.isEmpty`, so a
  /// golfer whose season finished a fortnight ago — who is in exactly the
  /// state this card is written for — was excluded by a membership row that
  /// points at a season nobody is playing. *"Between seasons is a state, not
  /// the absence of one."* The parameter keeps its name because it is the
  /// producer's public shape; the RULE is in this sentence and in the callers.
  public static func current(leagueless: Bool, majorOpen: Bool = false, today: Date = Date(),
                             calendar: Calendar = .current, defaults: UserDefaults = .standard) -> Occasion? {
    let c = calendar.dateComponents([.year, .month, .day], from: today)
    guard let y = c.year, let m = c.month, let d = c.day else { return nil }
    return all.first { o in
      inWindow(o.window, month: m, day: d) && !(o.leaguelessOnly && !leagueless)
        && !(o.needsMajor && !majorOpen)
        && !defaults.bool(forKey: "cs_occ_\(o.key)_\(y)")
    }
  }

  /// Is any card in today's windows gated on the Major? The caller asks this
  /// FIRST so a Home outside every gated window never spends a round trip on
  /// the flag — which is every day of the year but the four windows below.
  public static func needsMajorToday(leagueless: Bool, today: Date = Date(),
                                     calendar: Calendar = .current, defaults: UserDefaults = .standard) -> Bool {
    current(leagueless: leagueless, majorOpen: true, today: today, calendar: calendar, defaults: defaults)?.needsMajor == true
  }

  public static func dismiss(_ o: Occasion, today: Date = Date(), calendar: Calendar = .current, defaults: UserDefaults = .standard) {
    let y = calendar.component(.year, from: today)
    defaults.set(true, forKey: "cs_occ_\(o.key)_\(y)")
  }
}
