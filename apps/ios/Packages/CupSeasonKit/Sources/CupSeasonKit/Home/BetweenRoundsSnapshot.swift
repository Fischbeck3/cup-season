// App-authored, money-free facts. Compiled into Kit and the widget extension.
import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

public enum BetweenRoundsKind: String, CaseIterable, Codable, Sendable {
  // Keep the installed season widget's identity.
  case race = "CSSeasonWidget", nextTee = "CSNextTeeWidget"
  case record = "CSRecordWidget", rivalry = "CSRivalryWidget"
  /// D400 · Home's own ranked cards, carried out to the home screen
  case whatsOn = "CSWhatsOnWidget"
  public var title: String {
    switch self {
    case .race: "The Race"; case .nextTee: "Next Tee"; case .record: "The Record"; case .rivalry: "The Rivalry"
    case .whatsOn: "What’s On"
    }
  }
}

public struct WidgetSlice<Value: Codable & Sendable & Equatable>: Codable, Sendable, Equatable {
  public var value: Value?
  public let savedAt: Date
  public init(_ value: Value?, at date: Date = Date()) { self.value = value; savedAt = date }
  public func isStale(at now: Date) -> Bool {
    now.timeIntervalSince(savedAt) >= DispatchSnapshot.staleAfter || savedAt.timeIntervalSince(now) > 300
  }
}

public struct BetweenRoundsSnapshot: Codable, Sendable, Equatable {
  public static let key = "widgets.between-rounds.v1"
  public static let epochKey = "widgets.owner.epoch"
  public let owner: UUID
  public var race: WidgetSlice<Race>?
  public var nextTee: WidgetSlice<Tee>?
  public var record: WidgetSlice<Record>?
  public var rivalry: WidgetSlice<Rivalry>?
  /// D400 · Home's lead and deck, as `home_dispatch` served them
  public var whatsOn: WidgetSlice<WhatsOn>?
  /// D400 · whether the golfer holds any season at all, so an empty Race says
  /// "Start a season" only to a golfer who has none. nil in an older snapshot.
  public var hasSeason: Bool?
  public init(owner: UUID) { self.owner = owner }

  public struct Race: Codable, Sendable, Equatable {
    public struct Row: Codable, Sendable, Equatable, Identifiable {
      public let id: String, name: String, rank: String
      public let points: Int
      public let mine: Bool
      public init(id: String, name: String, rank: String, points: Int, mine: Bool) {
        self.id = id; self.name = name; self.rank = rank; self.points = points; self.mine = mine
      }
    }
    public let league: UUID
    public let name: String, context: String, standing: String, story: String
    /// N4-082 · `story` with its figure marked as a run, for the widget's serif
    /// line; absent in a snapshot an older build wrote
    public var storyMarked: String?
    public let rows: [Row]
    public init(league: UUID, name: String, context: String, standing: String, story: String, rows: [Row]) {
      self.league = league; self.name = name; self.context = context; self.standing = standing; self.story = story; self.rows = rows
    }
  }

  public struct Tee: Codable, Sendable, Equatable {
    public let id: UUID
    /// Wall-clock schedule, matching the existing plan. No invented course timezone.
    public let playOn: String, day: String, month: String, dateLine: String, time: String, course: String, company: String
    public let closesAt: Date
    public var status: String?
    public let canReply: Bool
    public var replyError: String?
    public init(id: UUID, playOn: String, day: String, month: String, dateLine: String, time: String,
                course: String, company: String, closesAt: Date, status: String?, canReply: Bool, replyError: String? = nil) {
      self.id = id; self.playOn = playOn; self.day = day; self.month = month; self.dateLine = dateLine; self.time = time
      self.course = course; self.company = company; self.closesAt = closesAt; self.status = status; self.canReply = canReply; self.replyError = replyError
    }
    public func allowsReply(at now: Date) -> Bool { canReply && now < closesAt }
    public var response: String {
      switch status { case "in": "You’re in"; case "out": "You’re out"; case "maybe": "Maybe"; default: "You’re invited" }
    }
  }

  public struct Record: Codable, Sendable, Equatable {
    public let id: UUID
    public let headline: String, course: String, date: String
    /// N4-082 · `headline` with its figure marked as a run (the serif line)
    public var headlineMarked: String?
    public let gross: Int, holes: Int
    public let out: Int?, inn: Int?
    public let earned: Bool
    public let company: String?
    public init(id: UUID, headline: String, course: String, date: String, gross: Int, holes: Int, out: Int?, inn: Int?, earned: Bool, company: String? = nil) {
      self.id = id; self.headline = headline; self.course = course; self.date = date; self.gross = gross; self.holes = holes
      // A partial card must not pretend to be a full pair of nines.
      let complete = holes == 18 && out != nil && inn != nil && out! + inn! == gross
      self.out = complete ? out : nil; self.inn = complete ? inn : nil; self.earned = earned; self.company = company
    }
  }

  public struct Rivalry: Codable, Sendable, Equatable {
    public let opponent: UUID
    public let name: String, scope: String, story: String, detail: String?
    public let wins: Int, losses: Int, ties: Int
    public init(opponent: UUID, name: String, scope: String, story: String, detail: String?, wins: Int, losses: Int, ties: Int) {
      self.opponent = opponent; self.name = name; self.scope = scope; self.story = story; self.detail = detail
      self.wins = wins; self.losses = losses; self.ties = ties
    }
  }

  /// D400 · What's On. Every word is Home's: the ranker's eyebrow, headline
  /// and verb, copied, never re-derived (L-34). The route is flattened to the
  /// strings a widget URL can carry.
  public struct WhatsOn: Codable, Sendable, Equatable {
    public struct Item: Codable, Sendable, Equatable, Identifiable {
      public let key: String
      public let eyebrow: String, headline: String
      public let action: String?
      /// `ember` · `gold` · `mut` — the Home card's own spine
      public let spine: String
      /// `WhatsOnRoute` raw value, and the id and pane it carries
      public let route: String?
      public let routeId: UUID?
      public let pane: String?
      public var id: String { key }
      public init(key: String, eyebrow: String, headline: String, action: String?, spine: String,
                  route: String?, routeId: UUID?, pane: String?) {
        self.key = key; self.eyebrow = eyebrow; self.headline = headline; self.action = action; self.spine = spine
        self.route = route; self.routeId = routeId; self.pane = pane
      }
    }
    public let items: [Item]
    public init(items: [Item]) { self.items = items }

    /// The featured item for a rotation step, and the ones after it in order.
    public func rotated(_ step: Int) -> [Item] {
      guard !items.isEmpty else { return [] }
      let start = ((step % items.count) + items.count) % items.count
      return Array(items[start...] + items[..<start])
    }
  }

  /// D400 · how often the What's On feature card turns, and for how long a
  /// single timeline keeps turning before the provider is asked again
  public static let rotationStep: TimeInterval = 20 * 60
  public static let rotationSpan: TimeInterval = 6 * 60 * 60

  /// D400 · the rotation's entries: one every `rotationStep`, and the stale
  /// boundary, where the rotation stops offering doors. A snapshot with one
  /// item (or none) has nothing to turn.
  public func rotationDates(now: Date) -> [(date: Date, step: Int)] {
    let count = whatsOn?.value?.items.count ?? 0
    var out: [(date: Date, step: Int)] = [(now, 0)]
    guard count > 1 else {
      if let saved = whatsOn?.savedAt, saved.addingTimeInterval(DispatchSnapshot.staleAfter) > now {
        out.append((saved.addingTimeInterval(DispatchSnapshot.staleAfter), 0))
      }
      return out
    }
    let expiry = whatsOn?.savedAt.addingTimeInterval(DispatchSnapshot.staleAfter) ?? now
    guard expiry > now else { return out }
    var t = now.addingTimeInterval(Self.rotationStep), step = 1
    while t < now.addingTimeInterval(Self.rotationSpan) {
      if t >= expiry { out.append((expiry, 0)); break }
      out.append((t, step)); step += 1; t = t.addingTimeInterval(Self.rotationStep)
    }
    return out
  }

  public func savedAt(for kind: BetweenRoundsKind) -> Date? {
    switch kind {
    case .race: race?.savedAt; case .nextTee: nextTee?.savedAt; case .record: record?.savedAt; case .rivalry: rivalry?.savedAt
    case .whatsOn: whatsOn?.savedAt
    }
  }
  public func isStale(_ kind: BetweenRoundsKind, at now: Date) -> Bool {
    guard let saved = savedAt(for: kind) else { return true }
    return now.timeIntervalSince(saved) >= DispatchSnapshot.staleAfter || saved.timeIntervalSince(now) > 300
  }
  public func timelineDates(now: Date) -> [Date] {
    var dates = BetweenRoundsKind.allCases.compactMap { savedAt(for: $0)?.addingTimeInterval(DispatchSnapshot.staleAfter) }
    if let tee = nextTee?.value { dates.append(tee.closesAt) }
    return [now] + Set(dates.filter { $0 > now }).sorted()
  }
  public func asOf(_ kind: BetweenRoundsKind, at now: Date) -> String {
    guard let saved = savedAt(for: kind) else { return "Open to refresh" }
    return DispatchSnapshot(seasonRow: nil, facts: [], savedAt: saved).asOf(now: now)
  }

  /// N4-190 · the as-of line at the accessibility sizes, where a widget cannot
  /// grow: the time alone ("2:22 PM"), or the stale state's instruction alone
  /// ("OPEN TO REFRESH"). It truncated as "AS OF MON · OPEN T…".
  public func asOfShort(_ kind: BetweenRoundsKind, at now: Date) -> String {
    Self.shortened(asOf(kind, at: now))
  }
  static func shortened(_ full: String) -> String {
    guard full.hasPrefix("AS OF ") else { return full }
    if let dot = full.range(of: " · ") { return String(full[dot.upperBound...]) }
    return String(full.dropFirst("AS OF ".count))
  }
  public func link(for kind: BetweenRoundsKind) -> URL {
    let id: UUID?
    switch kind { case .race: id = race?.value?.league; case .nextTee: id = nextTee?.value?.id
    case .record: id = record?.value?.id; case .rivalry: id = rivalry?.value?.opponent
    case .whatsOn: return link(for: whatsOn?.value?.items.first)
    }
    return WidgetDestination(kind: kind, id: id, owner: owner).url
  }
  /// D400 · one What's On item's own door. A route the app cannot open from a
  /// widget lands on Home, where the same card sits.
  public func link(for item: WhatsOn.Item?) -> URL {
    guard let item, let route = item.route.flatMap(WhatsOnRoute.init(rawValue:)),
          !route.needsId || item.routeId != nil else {
      return WidgetDestination(kind: .whatsOn, id: nil, owner: owner).url
    }
    return WidgetDestination(kind: .whatsOn, id: item.routeId, owner: owner, route: route, pane: item.pane).url
  }

  public static func read(_ defaults: UserDefaults? = UserDefaults(suiteName: CSAppGroup.id)) -> Self? {
    guard let data = defaults?.data(forKey: key), let value = try? JSONDecoder().decode(Self.self, from: data),
          DispatchSnapshot.belongs(to: value.owner, defaults: defaults) else { return nil }
    return value
  }
  @discardableResult public func write(_ defaults: UserDefaults? = UserDefaults(suiteName: CSAppGroup.id), epoch: String?) -> Bool {
    guard DispatchSnapshot.belongs(to: owner, defaults: defaults), defaults?.string(forKey: Self.epochKey) == epoch,
          let data = try? JSONEncoder().encode(self) else { return false }
    defaults?.set(data, forKey: Self.key)
    #if canImport(WidgetKit)
    WidgetCenter.shared.reloadAllTimelines()
    #endif
    return true
  }
}

/// D400 · the doors a What's On item may open from a widget. Anything else a
/// Home card routes to (the composer, an invitation's terms) needs state the
/// URL cannot carry, and lands on Home instead.
public enum WhatsOnRoute: String, Codable, Sendable, CaseIterable {
  case receipt, plan, season, live, people, home
  /// Whether the route needs an id to mean anything
  public var needsId: Bool { self == .receipt || self == .plan || self == .season }
}

/// A widget is a private read door, never a share token or an automatic write.
public struct WidgetDestination: Codable, Sendable, Equatable {
  public let kind: BetweenRoundsKind
  public let id: UUID?
  public let owner: UUID
  /// D400 · What's On only: which door, and the season pane it names
  public let route: WhatsOnRoute?
  public let pane: String?
  public init(kind: BetweenRoundsKind, id: UUID?, owner: UUID, route: WhatsOnRoute? = nil, pane: String? = nil) {
    self.kind = kind; self.id = id; self.owner = owner
    self.route = kind == .whatsOn ? route : nil
    self.pane = kind == .whatsOn && route == .season ? pane : nil
  }
  public var url: URL {
    var c = URLComponents(); c.scheme = "cupseason"; c.host = "widget"
    c.queryItems = [.init(name: "kind", value: kind.rawValue), .init(name: "owner", value: owner.uuidString)]
    if let id { c.queryItems?.append(.init(name: "id", value: id.uuidString)) }
    if let route { c.queryItems?.append(.init(name: "route", value: route.rawValue)) }
    if let pane { c.queryItems?.append(.init(name: "pane", value: pane)) }
    return c.url!
  }
  public init?(url: URL) {
    guard url.scheme == "cupseason", url.host == "widget", let c = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
    func value(_ name: String) -> String? {
      let matches = c.queryItems?.filter { $0.name == name } ?? []
      return matches.count == 1 ? matches.first?.value : nil
    }
    guard let kind = value("kind").flatMap(BetweenRoundsKind.init(rawValue:)),
          let owner = value("owner").flatMap(UUID.init) else { return nil }
    let ids = c.queryItems?.filter { $0.name == "id" } ?? []
    guard ids.isEmpty || (ids.count == 1 && value("id").flatMap(UUID.init) != nil) else { return nil }
    // D400 · a route is What's On's alone, spelled once, and one this app knows
    let routes = c.queryItems?.filter { $0.name == "route" } ?? []
    let panes = c.queryItems?.filter { $0.name == "pane" } ?? []
    guard routes.count <= 1, panes.count <= 1 else { return nil }
    var route: WhatsOnRoute?
    if let raw = value("route") {
      guard kind == .whatsOn, let r = WhatsOnRoute(rawValue: raw) else { return nil }
      route = r
    }
    let pane = value("pane")
    if pane != nil, route != .season { return nil }
    if let pane, pane.count > 24 || !pane.allSatisfy({ $0.isLetter || $0 == "_" }) { return nil }
    self.init(kind: kind, id: value("id").flatMap(UUID.init), owner: owner, route: route, pane: pane)
  }
}
