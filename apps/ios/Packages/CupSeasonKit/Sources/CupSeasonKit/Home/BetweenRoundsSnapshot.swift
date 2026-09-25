// App-authored, money-free facts. Compiled into Kit and the widget extension.
import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

public enum BetweenRoundsKind: String, CaseIterable, Codable, Sendable {
  // Keep the installed season widget's identity.
  case race = "CSSeasonWidget", nextTee = "CSNextTeeWidget"
  case record = "CSRecordWidget", rivalry = "CSRivalryWidget"
  public var title: String {
    switch self { case .race: "The Race"; case .nextTee: "Next Tee"; case .record: "The Record"; case .rivalry: "The Rivalry" }
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

  public func savedAt(for kind: BetweenRoundsKind) -> Date? {
    switch kind { case .race: race?.savedAt; case .nextTee: nextTee?.savedAt; case .record: record?.savedAt; case .rivalry: rivalry?.savedAt }
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
  public func link(for kind: BetweenRoundsKind) -> URL {
    let id: UUID?
    switch kind { case .race: id = race?.value?.league; case .nextTee: id = nextTee?.value?.id
    case .record: id = record?.value?.id; case .rivalry: id = rivalry?.value?.opponent }
    return WidgetDestination(kind: kind, id: id, owner: owner).url
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

/// A widget is a private read door, never a share token or an automatic write.
public struct WidgetDestination: Codable, Sendable, Equatable {
  public let kind: BetweenRoundsKind
  public let id: UUID?
  public let owner: UUID
  public init(kind: BetweenRoundsKind, id: UUID?, owner: UUID) { self.kind = kind; self.id = id; self.owner = owner }
  public var url: URL {
    var c = URLComponents(); c.scheme = "cupseason"; c.host = "widget"
    c.queryItems = [.init(name: "kind", value: kind.rawValue), .init(name: "owner", value: owner.uuidString)]
    if let id { c.queryItems?.append(.init(name: "id", value: id.uuidString)) }
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
    self.init(kind: kind, id: value("id").flatMap(UUID.init), owner: owner)
  }
}
