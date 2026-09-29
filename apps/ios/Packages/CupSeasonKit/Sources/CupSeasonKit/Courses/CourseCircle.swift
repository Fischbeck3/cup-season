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
  /// the web's history row: the day, *"White tees"* or "Tee not recorded", the holes
  public var detail: String {
    [day.isEmpty ? nil : LeagueDates.dowMonDay(day), CircleCopy.tee(tee), holes.map { "\($0) holes" }]
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
  public var tied: Bool { json["best"]?["tied"]?.bool == true }
  /// the selected tee as the web names it: *"Red · Women’s"*
  public var teeLabel: String? {
    guard let teeName else { return nil }
    let gender = (json["tees"]?.array ?? []).first { $0["key"]?.string == tee }?["gender"]?.string
    return teeName + (gender == "female" ? " · Women’s" : "")
  }
  /// Under the best: *"Shared best · White tees · 18 holes"* (N4-203). The web
  /// puts the holder's day first when the best is not shared; the phone's
  /// holder rows carry their own day, so it is not said twice.
  public var selectionLine: String {
    [tied ? CircleCopy.sharedBest : nil, teeLabel.map { "\($0) tees" }, "\(holes) holes"]
      .compactMap { $0 }.joined(separator: " · ")
  }
  /// *"7 rounds compared · Your circle"*
  public var comparedLine: String? {
    json["best"]?["eligible_rounds"]?.int.map { CircleCopy.compared($0, scope: json["scope"]?["label"]?.string) }
  }
  /// the scope's note, then the rounds no tee can be proved for, as one paragraph
  public var noteLine: String {
    let unknown = json["unknown_tee_rounds"]?.int ?? 0
    return [json["scope"]?["note"]?.string, unknown > 0 ? CircleCopy.unknownTees(unknown) : nil]
      .compactMap { $0 }.joined(separator: " ")
  }
  /// what the best's slot says when there is no best
  public var noBestLine: String {
    if json["best_unavailable"]?.string == "nine_side_unrecorded" { return TalkCopy.nineBest }
    return (json["tees"]?.array ?? []).isEmpty ? CircleCopy.noTees : CircleCopy.noScores
  }
}
