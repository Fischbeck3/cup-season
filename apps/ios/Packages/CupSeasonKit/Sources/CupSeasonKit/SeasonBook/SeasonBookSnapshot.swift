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
    /// W5 twin (the web's `standingOf`) · the reader's own row says so: "You ·
    /// 2nd". nil when there is nothing to say.
    public var standingLine: String? {
      let parts = [mine ? "You" : nil, standing].compactMap { $0 }
      return parts.isEmpty ? nil : parts.joined(separator: " · ")
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
      return recorded_on.map { "Recorded \(LeagueDates.roundDay($0)) · outside the season weeks" } ?? "Assessment date unavailable"
    }

    /// W5 twin (csSeasonBookReceipt) · the entry's place line. A WEEK's
    /// receipt says its week once, in its head, so its entries do not repeat
    /// "Week 12"; an entry outside the season's weeks still says so.
    public func place(inWeek: Bool) -> String? {
      inWeek && week != nil ? nil : dateLine
    }
  }
  public struct Cell: Codable, Sendable {
    public let week: Int
    public let points: Int?
    public let cumulative: Int?
    public let future: Bool
  }
  public var live: Bool { status == "active" || status == "cup_final" }
  /// "Jul 6 – Oct 18, 2026" — the season's span as a golfer reads it, local,
  /// in the week columns' own "Jul 6" form. The head printed the raw
  /// 2026-07-06 – 2026-10-18. The desk's Book head reads the same (45d599f5).
  public var span: String {
    let a = BoardText.shortDate(starts_on), b = BoardText.shortDate(ends_on)
    let year = ends_on.prefix(4)
    return "\(a.isEmpty ? starts_on : a) – \(b.isEmpty ? ends_on : b)" + (year.count == 4 && Int(year) != nil ? ", \(year)" : "")
  }
  public var hasSquads: Bool { rows.contains { $0.kind == "squad" } }
  public static func prominent(fieldSize: Int, hasSquads: Bool) -> Bool { fieldSize >= 10 || hasSquads }
  /// W7-120 · the minimum names its unit ("minimum 2 rounds"): a bare
  /// "minimum 2" read as two points or two wins. The web's Book (b2bd5b1f).
  public var rules: String {
    (counting_cap.map { "Best \($0) per calendar month" } ?? "All rounds count") +
      (participation_floor.map { " · minimum \($0) round\($0 == 1 ? "" : "s")" } ?? "")
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
  /// F11 · a cell is TWO things: its figure and its status marks. Drawn as one
  /// string at one size, "33D" read as a number. The page draws `fig` in the
  /// column figure and `marks` beside it as a small record note; `label` stays
  /// their concatenation for every caller that wants the compact string.
  /// Twin: `SeasonBook.parts` / `.label` on the desk.
  public struct CellParts: Sendable, Equatable {
    /// The figure (a true minus when it is negative, `num`), or the one symbol
    /// that stands in for it (`•`, `—`, `B`, `D`).
    public let fig: String
    /// Status marks beside a figure (`*` adjustment, `D` dropped), or "".
    public let marks: String
    public init(fig: String, marks: String) { self.fig = fig; self.marks = marks }
  }
  public static func parts(row: Row, cell: Cell, cumulative: Bool) -> CellParts {
    if cell.future { return CellParts(fig: "•", marks: "") }
    let selected = selectedEntries(row, week: cell.week, cumulative: cumulative)
    guard let points = cumulative ? cell.cumulative : cell.points else { return CellParts(fig: "—", marks: "") }
    if !cumulative && !selected.isEmpty && selected.allSatisfy({ $0.count_state == "bye" }) { return CellParts(fig: "B", marks: "") }
    if !cumulative && !selected.isEmpty && selected.allSatisfy({ $0.count_state == "dropped" }) { return CellParts(fig: "D", marks: "") }
    let flags = cumulative ? "" : (selected.contains { !$0.isRound } ? "*" : "") + (selected.contains { $0.count_state == "dropped" } ? "D" : "")
    return CellParts(fig: num(points), marks: flags)
  }
  /// W5 · a signed figure as a golfer reads it: a true minus, never a hyphen
  /// ("−3 points", not "-3 points"). Cells, totals and receipts alike. Twin:
  /// `csBookNum` on the desk.
  public static func num(_ n: Int) -> String { n < 0 ? "\u{2212}\(n.magnitude)" : String(n) }
  /// W5 · the month an adjustment was assessed for, as a golfer reads it —
  /// "Aug 2026", never the raw "2026-08" — by parts, never through an ISO
  /// parser (L-07). Twin: `csBookMonth` on the desk.
  public static func month(_ iso: String) -> String {
    let parts = iso.prefix(10).split(separator: "-").prefix(2).compactMap { Int($0) }
    guard parts.count == 2, (1...12).contains(parts[1]) else { return iso }
    return "\(LeagueDates.mos[parts[1] - 1]) \(parts[0])"
  }
  public static func label(row: Row, cell: Cell, cumulative: Bool) -> String {
    let p = parts(row: row, cell: cell, cumulative: cumulative)
    return p.fig + p.marks
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

  // MARK: W5 · the race, labelled at its line ends (twin of `csSeasonBookRace`)

  /// The lines the race draws: the golfer followed, then the leaders, three at
  /// most. Equal points read in alphabetical order (D381), so the same three
  /// are drawn on every load.
  public static func racePlotted(_ rows: [Row], follow: String) -> [Row] {
    let leaders = Array(rows.sorted {
      $0.points != $1.points ? $0.points > $1.points : $0.name.localizedCompare($1.name) == .orderedAscending
    }.prefix(3))
    guard let chosen = rows.first(where: { $0.id == follow }) else { return leaders }
    return [chosen] + leaders.filter { $0.id != chosen.id }.prefix(2)
  }
  /// Where a line ends: the last week it reaches, and its points there. nil for
  /// a row with nothing plotted, which then takes no label.
  public static func raceEnd(_ row: Row) -> (week: Int, points: Int)? {
    guard let last = row.cells.last(where: { !$0.future && $0.cumulative != nil }), let points = last.cumulative else { return nil }
    return (last.week, points)
  }
  /// A line's end label — its name and where it stands today, "Name 41". The
  /// legend of box-drawing glyphs (━ ┄ ┈) it replaces had to be matched by eye
  /// to three near-identical dashes (§9.10).
  public static func raceLabel(_ row: Row) -> String { "\(row.name) \(num(raceEnd(row)?.points ?? 0))" }
  /// One label per line, in a column, never on top of another: each sits
  /// level with its line's end, pushed down to clear the one above it by
  /// `gap`, and the column lifts as a whole when it runs past `bottom`. The
  /// label centres come back in the order the ends were given.
  public static func raceSlots(_ ends: [Double], gap: Double, top: Double, bottom: Double) -> [Double] {
    let order = ends.indices.sorted { ends[$0] != ends[$1] ? ends[$0] < ends[$1] : $0 < $1 }
    var slots = ends
    var previous: Double?
    for i in order {
      let slot = max(ends[i], previous.map { $0 + gap } ?? top)
      slots[i] = slot; previous = slot
    }
    if let last = previous, last > bottom { slots = slots.map { $0 - (last - bottom) } }
    return slots
  }

  // MARK: W5 · the crown on a finished Book (twin of `csBookChampion`)

  /// The read carries no champion, so the Book names one only from the crown
  /// the SEASON stores — its champion and the `tiebreak_rung` that settled a
  /// level top — and only when that season is this Book's and complete.
  /// Without it, a level top says what §14.3's ladder (D388) does with a tie:
  /// two "1st · Tied" rows and no champion left the reader to guess, and the
  /// Book never picks one itself.
  public struct Crown: Sendable, Equatable {
    public let label: String
    public let text: String
  }
  public static let tieLadder = "A tie at the top goes to head-to-head months won, then the best single month, then the fewest rounds used, then a coin flip."
  static let rungWords = ["months won": "head-to-head months won", "best single month": "the best single month",
                          "fewest rounds used": "the fewest rounds used", "coin flip": "a coin flip"]
  public func crown(stored season: Me.Season?) -> Crown? {
    guard status == "complete", current_week > 0 else { return nil }
    let kind = hasSquads ? "squad" : "golfer"
    if let season, season.id == season_id, season.status == "complete",
       let id = hasSquads ? season.champion_squad_id : season.champion_member_id,
       let champion = rows.first(where: { $0.kind == kind && (hasSquads ? $0.squad_id : $0.member_id) == id }) {
      let rung = season.tiebreak_rung.flatMap { $0.isEmpty ? nil : $0 }
      return Crown(label: "Champion",
                   text: champion.name + (rung.map { " · level at the top, decided on \(Self.rungWords[$0] ?? $0)" } ?? ""))
    }
    return rows.filter { $0.kind == kind && $0.points_rank == 1 }.count > 1
      ? Crown(label: "Level at the top", text: Self.tieLadder) : nil
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
