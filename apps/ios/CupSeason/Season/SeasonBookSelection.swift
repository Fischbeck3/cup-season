import Foundation
import CupSeasonKit

/// Defaults belong to the first successful read of this season. A refresh
/// updates the record without changing the golfer's deliberate selections.
struct SeasonBookSelection {
  var group = "golfer"
  var squad = "all"
  var week = 1
  private var leagueID: UUID?
  private var seasonID: UUID?

  init() {}
  init(book: SeasonBookSnapshot, group: String? = nil) {
    receive(book)
    if let group { self.group = group }
  }
  mutating func receive(_ book: SeasonBookSnapshot) {
    guard leagueID != book.league_id || seasonID != book.season_id else { return }
    leagueID = book.league_id
    seasonID = book.season_id
    group = book.hasSquads ? "squad" : "golfer"
    week = max(1, book.current_week)
    squad = "all"
  }
}
