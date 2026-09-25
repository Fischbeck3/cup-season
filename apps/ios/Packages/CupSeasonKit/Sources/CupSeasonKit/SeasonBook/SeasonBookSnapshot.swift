import Foundation
import Observation

/// D381: an authoritative read, never a client best-N scorer.
public struct SeasonBookSnapshot: Codable, Sendable {
  public let version: Int
  public let league_id: UUID
  public let season_id: UUID
  public let name: String
  public let number: Int
  public let status: String
  public let starts_on: String
  public let ends_on: String
  public let timezone: String
  public let generated_at: String
  public let current_week: Int
  public let structure: String
  public let field_size: Int
  public let counting_cap: Int?
  public let participation_floor: Int?
  public let rules_note: String?
  public let coverage_complete: Bool
  public let weeks: [Week]
  public let rows: [Row]

  public struct Week: Codable, Sendable, Identifiable {
    public let week: Int
    public let starts_on: String
    public let ends_on: String
    public var id: Int { week }
  }
  public struct Row: Codable, Sendable, Identifiable {
    public let id: String
    public let kind: String
    public let name: String
    public let member_id: UUID?
    public let squad_id: UUID?
    public let points: Int
    public let points_rank: Int?
    public let tied: Bool
    public let mine: Bool
    public let reconciled: Bool
    public let unplaced_points: Int
    public let entries: [Entry]
    public let cells: [Cell]
    public var standing: String? {
      points_rank.map { CSCopy.ordinal($0) + (tied ? " · Tied" : "") }
    }
  }
  public struct Entry: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let round_id: UUID?
    public let member_id: UUID?
    public let squad_id: UUID?
    public let week: Int?
    public let recorded_on: String?
    public let affected_month: String?
    public let kind: String
    public let points: Int
    public let contribution: Int
    public let withdrawn: Bool?
    public let count_state: String
    public let reason: String
    public var isRound: Bool { round_id != nil }
    public var dateLine: String {
      if let week { return "Week \(week)" }
      return recorded_on.map { "Recorded \(CSDate.short($0)) · outside the season weeks" } ?? "Assessment date unavailable"
    }
  }
  public struct Cell: Codable, Sendable {
    public let week: Int
    public let points: Int?
    public let cumulative: Int?
    public let future: Bool
  }
  public var live: Bool { status == "active" || status == "cup_final" }
  public var hasSquads: Bool { rows.contains { $0.kind == "squad" } }
  public static func prominent(fieldSize: Int, hasSquads: Bool) -> Bool { fieldSize >= 10 || hasSquads }
  public var rules: String {
    (counting_cap.map { "Best \($0) per calendar month" } ?? "All rounds count") +
      (participation_floor.map { " · minimum \($0)" } ?? "")
  }
  /// Contract validation catches partial/proxy-truncated and mismatched reads
  /// before a table can claim that its receipts add up. No scoring decisions.
  public func validate(league: UUID, season: UUID) throws {
    guard version == 1, league_id == league, season_id == season,
      !weeks.isEmpty, weeks.count <= 104, weeks.map(\.week) == Array(1...weeks.count),
      (0...weeks.count).contains(current_week), Set(rows.map(\.id)).count == rows.count else {
      throw SeasonBookReadError.unavailable
    }
    guard coverage_complete, rows.allSatisfy({ row in
      ["golfer","squad","contribution"].contains(row.kind) &&
      (row.kind == "squad" ? row.squad_id != nil : row.member_id != nil) &&
      (row.kind != "contribution" || row.squad_id != nil) &&
      row.reconciled && row.entries.reduce(0, { $0 + $1.contribution }) == row.points &&
      Set(row.entries.map(\.id)).count == row.entries.count &&
      row.entries.allSatisfy { $0.week.map { (1...weeks.count).contains($0) } ?? true } &&
      row.cells.map(\.week) == weeks.map(\.week) &&
      row.unplaced_points == row.entries.filter { $0.week == nil }.reduce(0, { $0 + $1.contribution }) &&
      row.cells.allSatisfy { cell in
        let weekEntries = row.entries.filter { $0.week == cell.week }
        let through = row.entries.filter { $0.week.map { $0 <= cell.week } ?? false }
        return cell.future == (cell.week > current_week) &&
          cell.points == (cell.future || weekEntries.isEmpty ? nil : weekEntries.reduce(0, { $0 + $1.contribution })) &&
          cell.cumulative == (cell.future || through.isEmpty ? nil : through.reduce(0, { $0 + $1.contribution }))
      }
    }) else { throw SeasonBookReadError.incomplete }
  }
  public static func selectedEntries(_ row: Row, week: Int, cumulative: Bool) -> [Entry] {
    row.entries.filter { entry in entry.week.map { cumulative ? $0 <= week : $0 == week } ?? false }
  }
  public static func label(row: Row, cell: Cell, cumulative: Bool) -> String {
    if cell.future { return "•" }
    let selected = selectedEntries(row, week: cell.week, cumulative: cumulative)
    guard let points = cumulative ? cell.cumulative : cell.points else { return "—" }
    if !cumulative && !selected.isEmpty && selected.allSatisfy({ $0.count_state == "bye" }) { return "B" }
    if !cumulative && !selected.isEmpty && selected.allSatisfy({ $0.count_state == "dropped" }) { return "D" }
    let flags = cumulative ? "" : (selected.contains { !$0.isRound } ? "*" : "") + (selected.contains { $0.count_state == "dropped" } ? "D" : "")
    return String(points) + flags
  }
  public static func spoken(row: Row, cell: Cell, cumulative: Bool) -> String {
    if cell.future { return "Future week" }
    guard let points = cumulative ? cell.cumulative : cell.points else { return "No round or adjustment recorded" }
    let entries = selectedEntries(row, week: cell.week, cumulative: cumulative)
    return "\(points) points \(cumulative ? "through" : "in") week \(cell.week)" +
      (entries.contains { $0.count_state == "dropped" } ? "; dropped rounds retained in receipt" : "") +
      (entries.contains { !$0.isRound } ? "; adjustment or bye recorded" : "")
  }
  public static func raceDomain(_ rows: [Row]) -> ClosedRange<Int> {
    let values = rows.flatMap { $0.cells.compactMap(\.cumulative) }
    let low = min(0, values.min() ?? 0), high = max(0, values.max() ?? 0)
    return low...max(low + 1, high)
  }
}

public enum SeasonBookReadError: Error, LocalizedError {
  case unavailable, incomplete
  public var errorDescription: String? {
    switch self {
    case .unavailable: "The Book is not available yet. Try again shortly."
    case .incomplete: "The points record is incomplete. Try again to load the whole season."
    }
  }
}

@MainActor @Observable public final class SeasonBookStore {
  public private(set) var snapshot: SeasonBookSnapshot?
  public private(set) var loading = false
  public private(set) var error: String?
  private var request = UUID()
  private let read: @MainActor (UUID,UUID) async throws -> SeasonBookSnapshot
  public init(read: (@MainActor (UUID,UUID) async throws -> SeasonBookSnapshot)? = nil) {
    self.read = read ?? { league,season in
      let raw = try await SupabaseService.shared.call(Rpc.season_book(p_league_id:league,p_season_id:season))
      return try JSONDecoder().decode(SeasonBookSnapshot.self,from:JSONEncoder().encode(raw))
    }
  }
  public func load(league: UUID, season: UUID) async {
    let token=UUID(); request=token
    loading = true; error = nil; snapshot = nil
    defer { if request == token { loading = false } }
    do {
      let value = try await read(league,season)
      try Task.checkCancellation()
      guard request == token else { return }
      try value.validate(league: league, season: season)
      snapshot = value
    } catch is CancellationError { return }
    catch { if request == token { self.error = (error as? SeasonBookReadError)?.localizedDescription ?? "The Book did not load. Try again." } }
  }
  #if DEBUG
  public func seed(_ value: SeasonBookSnapshot) {
    do { try value.validate(league: value.league_id, season: value.season_id); snapshot=value; error=nil }
    catch { self.error=error.localizedDescription }
  }
  #endif
}
