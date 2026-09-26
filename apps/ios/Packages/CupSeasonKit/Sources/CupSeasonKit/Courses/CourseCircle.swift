import Foundation

public struct CourseCircleRound: Sendable, Equatable, Identifiable {
  public let id: UUID
  public let gross: Int?
  public let day: String
  public let holes: Int?
  public let tee: String?
  public let selected: Bool
  public init?(_ json: JSONValue) {
    guard let id = json["round_id"]?.string.flatMap(UUID.init) else { return nil }
    self.id = id; gross = json["gross"]?.int; day = json["played_on"]?.string ?? ""
    holes = json["holes"]?.int; tee = json["tee_name"]?.string; selected = json["in_selection"]?.bool == true
  }
  public var detail: String {
    [day.isEmpty ? nil : LeagueDates.dowMonDay(day), tee ?? "Tee not recorded", holes.map { "\($0) holes" }]
      .compactMap { $0 }.joined(separator: " · ")
  }
}

public struct CourseCircleGolfer: Sendable, Equatable, Identifiable {
  public let person: SocialPerson
  public let relation: String
  public let count: Int
  public let latest: String?
  public let best: Int?
  public let bestRound: UUID?
  public let rounds: [CourseCircleRound]
  public var id: UUID { person.id }
  public init?(_ json: JSONValue) {
    guard let person = SocialPerson(json["person"]) else { return nil }
    self.person = person; relation = json["relation"]?.string ?? "league"
    count = json["rounds_total"]?.int ?? 0; latest = json["latest_played_on"]?.string
    best = json["best_in_selection"]?["gross"]?.int
    bestRound = json["best_in_selection"]?["round_id"]?.string.flatMap(UUID.init)
    rounds = (json["rounds"]?.array ?? []).compactMap(CourseCircleRound.init)
  }
}

public struct CourseCirclePage: Sendable, Equatable {
  public let json: JSONValue
  public let people: [CourseCircleGolfer]
  public init(_ json: JSONValue) {
    self.json = json; people = (json["people"]?.array ?? []).compactMap(CourseCircleGolfer.init)
  }
  public var tee: String? { json["selection"]?["tee_key"]?.string }
  public var teeName: String? { json["selection"]?["tee_name"]?.string }
  public var holes: Int { json["selection"]?["holes"]?.int ?? 18 }
  public var best: Int? { json["best"]?["gross"]?.int }
  public var myBest: Int? { json["my_best"]?["gross"]?.int }
  public var selectionLine: String { [teeName, "\(holes) holes", "Gross"].compactMap { $0 }.joined(separator: " · ") }
}
