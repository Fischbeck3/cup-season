// Cup Season — THE BOARD: your buddies, ranked (R5 `friends_board`; D245 /
// C-7, IA §10.2).
//
// The brief asks for "#4 among your friends" and the canon had never ruled it.
// Left unruled, the obvious implementation — a handicap ladder — is BACKWARDS
// as a competitive object: it ranks worse golfers first. D245 rules it
// narrowly and this file is the ruling as a value:
//
//   1 · the default lens is FORM — rounds and beats-your-number over 30 days,
//       shown as a BAND, never a raw figure (L-14 / T-07)
//   2 · the handicap is the SECOND lens, because it is the figure golfers
//       already trade in a parking lot
//   3 · NEVER points. Points are season-scoped and a cross-season points
//       ladder would be meaningless (L-13)
//   4 · accepted buddies only, both ways — and `discoverable = 'nobody'` does
//       NOT hide a golfer from their own buddies, because they accepted
//   5 · it is a LIST, NOT A SCORE: no badges, no movement arrows, no weekly
//       "you dropped to 5th", and NO ATTENTION METRIC OF ANY KIND (L-22)
//
// Clause 5 is why this type has the fields it has and no others. There is
// nowhere here to put a reaction count, and `FriendsBoardTests` asserts the
// shape rather than trusting the comment.
//
// THE DENOMINATOR IS PART OF THE FACT (L-01). Every row prints how many rounds
// the figure is over, so a two-round month never masquerades as a season of
// form — which is D245's own tradeoff, built rather than promised.

import Foundation

public struct FriendsBoard: Sendable, Equatable {

  /// Which lens the board is wearing. Two, and only two.
  public enum Lens: String, Sendable, CaseIterable {
    case form, handicap

    /// The segment label.
    public var label: String {
      switch self { case .form: "Form"; case .handicap: "Handicap" }
    }
    /// The section's own sub, which names the window the figures cover.
    public func caption(days: Int) -> String {
      switch self {
      case .form:     "LAST \(days) DAYS"
      case .handicap: "HANDICAP INDEX"
      }
    }
  }

  public struct Row: Sendable, Equatable, Identifiable {
    public let profileId: UUID
    public let displayName: String?
    public let handle: String?
    public let marker: String?
    public let indexCurrent: Double?
    public let rounds: Int
    public let beats: Int
    public let avgVsNumber: Double?
    public let bestVsNumber: Double?
    /// A calendar date as a String — never through an ISO parser (L-07).
    public let lastRoundOn: String?
    public let rankByForm: Int
    public let rankByIndex: Int
    public let isMe: Bool
    public var id: UUID { profileId }

    public init(profileId: UUID, displayName: String?, handle: String?, marker: String?,
                indexCurrent: Double?, rounds: Int, beats: Int,
                avgVsNumber: Double?, bestVsNumber: Double?, lastRoundOn: String?,
                rankByForm: Int, rankByIndex: Int, isMe: Bool) {
      self.profileId = profileId; self.displayName = displayName; self.handle = handle
      self.marker = marker; self.indexCurrent = indexCurrent
      self.rounds = rounds; self.beats = beats
      self.avgVsNumber = avgVsNumber; self.bestVsNumber = bestVsNumber
      self.lastRoundOn = lastRoundOn
      self.rankByForm = rankByForm; self.rankByIndex = rankByIndex; self.isMe = isMe
    }

    public var name: String { isMe ? "You" : (displayName ?? "—") }

    public func rank(_ lens: Lens) -> Int { lens == .form ? rankByForm : rankByIndex }

    /// **Ascending sort key on the figure this lens PRINTS**, or nil when the
    /// row has no figure and belongs in the tail. Form is negated because
    /// plus is better and the sort is ascending; the handicap is not, because
    /// a lower index is the better golfer.
    func sortKey(_ lens: Lens) -> Double? {
      switch lens {
      case .form:     guard rounds > 0, let a = avgVsNumber else { return nil }; return -a
      case .handicap: return indexCurrent
      }
    }

    /// "4 rounds · beat their playing HCP 3 times" — the sentence IA §10.2
    /// writes, with R-M's noun,
    /// with the pronoun the row can actually justify. Nobody's gender is
    /// stored, so the possessive is "their" for a buddy and "your" for me.
    public var formLine: String {
      guard rounds > 0 else { return "No rounds in the window" }
      let r = "\(rounds) round\(rounds == 1 ? "" : "s")"
      let whose = isMe ? "your" : "their"
      switch beats {
      case 0:  return "\(r) · didn’t beat \(whose) playing HCP"
      case 1:  return "\(r) · beat \(whose) playing HCP once"
      case 2:  return "\(r) · beat \(whose) playing HCP twice"
      default: return "\(r) · beat \(whose) playing HCP \(beats) times"
      }
    }

    /// The BAND, never the float (L-14 / T-07). Nil when the window holds
    /// nothing — a band over no rounds is a band about nothing.
    ///
    /// `CSBands` is written from the golfer's OWN point of view ("Beat your
    /// number"), which is right on a receipt and wrong on a list of other
    /// people — a real screenshot caught the board telling me Tash had beaten
    /// MY number. The band table stays the one band table; only the possessive
    /// turns, and only on somebody else's row.
    public var band: String? {
      guard rounds > 0, let a = avgVsNumber else { return nil }
      let name = CSBands.bandName(a)
      return isMe ? name : name.replacingOccurrences(of: "your", with: "their")
    }

    /// **`3/4` — the beats column.** `BEATS` is named once in the section
    /// head's count, so the column needs no unit, and the denominator is part
    /// of the fact (L-01): it is the COLUMN rather than a clause in the
    /// sub-line, which is what lets the sub-line stay one line at the default
    /// size. A window with no rounds reads `—`: there is nothing to be a
    /// fraction of.
    public var beatsColumn: String { rounds > 0 ? "\(beats)/\(rounds)" : "\u{2014}" }

    /// The handicap lens's own figure. A golfer with no index reads "—", not
    /// a zero and not a guess.
    public var indexText: String { indexCurrent.map { CSCopy.index($0) } ?? "—" }
  }

  public let days: Int
  public let rows: [Row]

  public init(days: Int = 30, rows: [Row]) { self.days = days; self.rows = rows }

  /// **THE RAIL FOLLOWS THE FIGURE THE ROW PRINTS.**
  ///
  /// This read the server's `rank_by_form`, which orders on BEATS first — and
  /// the column beside it prints the AVERAGE against the golfer's own playing
  /// handicap. On a photographed board that came out −2.6 (01), +1.0 (02),
  /// +2.8 (03), −3.8 (04): a ranked list neither ascending nor descending on
  /// the only figure it shows, with the design's headline device carrying the
  /// contradiction. A rail whose numeral disagrees with the number beside it
  /// cannot be scanned at all.
  ///
  /// So the order is computed here, from the figure each lens prints:
  ///
  ///   * **form** — `avgVsNumber` DESCENDING, because `CSBands` is written so
  ///     a positive figure is the better round (`bandName(+3)` is *Torched
  ///     it*). The artboard's `LOWER IS BETTER` is the document that is wrong,
  ///     and Wave 7 already corrected the words; this corrects the sort.
  ///   * **handicap** — `indexCurrent` ASCENDING, the parking-lot convention.
  ///
  /// A golfer with no rounds in the window (form) or no index (handicap) has
  /// no figure to be ranked on and takes the TAIL, in name order — never a
  /// zero and never a guess (L-44).
  ///
  /// The server's two ranks still decode, because a payload must, and
  /// `rank_by_form` will be aligned to this when `friends_board` is pushed;
  /// until then the ORDER a golfer reads is the order the figures make.
  public func ordered(_ lens: Lens) -> [Row] {
    rows.sorted { a, b in
      let x = a.sortKey(lens), y = b.sortKey(lens)
      if let x, let y, x != y { return x < y }
      if (x == nil) != (y == nil) { return y == nil }
      return (a.displayName ?? "") < (b.displayName ?? "")
    }
  }

  /// The board with each row's POSITION in it — the numeral the rail prints.
  /// It is the position, not a server column, so the rail and the figure can
  /// never disagree again.
  /// **D324 · A GOLFER WITH NO ROUNDS IS NOT RANKED.**
  ///
  /// This numbered every row, so a board of six showed `01 02 03` for people
  /// who had played and `04 05 06` beside *"No rounds in the window · nothing
  /// yet"* — three ordinals over nothing. Blake is not fourth at anything; that
  /// is an absence dressed as a standing, and it quietly names who has not
  /// played, which is the L-22 line the board's own note promises not to cross
  /// (*"No badges, no streaks — just rounds"*).
  ///
  /// They stay ON the board — they are your buddies and the tab is a roster —
  /// and their rank is nil, so the rail draws nothing where a number would be.
  /// The ordinal counts only the ranked, so removing one does not leave a hole
  /// in the sequence.
  public func ranked(_ lens: Lens) -> [(rank: Int?, row: Row)] {
    var n = 0
    return ordered(lens).map { row in
      guard row.sortKey(lens) != nil else { return (rank: nil, row: row) }
      n += 1
      return (rank: n, row: row)
    }
  }

  // MARK: - The copy

  public static let head = "THE BOARD"
  /// L-22, said where a golfer can read it: this is a list, not a score.
  public static let note = "Your buddies, by how they are playing. No badges, no streaks — just rounds."
  /// The empty root, which still ends in a next move (L-32).
  public static func empty() -> EmptyRoot {
    EmptyRoot(head: "Nobody on the board yet.",
              fact: nil,
              sub: "Add the people you actually play with and the board fills itself in from the rounds you all post.",
              doors: [.findGolfers, .personLink])
  }
  /// The board is not the whole tab, so a FAILED read says so in one line
  /// rather than replacing the tab with an error (P-11's error column).
  public static let didNotLoad = "The board didn’t load."

  // MARK: - Decoding

  /// The server's row, hand-declared rather than generated: the migration that
  /// creates `friends_board` is written and unpushed, and this is the shape
  /// preflight 17 tolerates while a contract refresh waits on the owner's
  /// push. Every field is optional, because a payload that predates a column
  /// must still decode (deploy-skew).
  public struct ServerRow: Decodable, Sendable {
    public let profile_id: UUID?
    public let display_name: String?
    public let handle: String?
    public let marker: String?
    public let index_current: Double?
    public let rounds_30d: Int?
    public let beats_30d: Int?
    public let avg_vs_number_30d: Double?
    public let best_vs_number_30d: Double?
    public let last_round_on: String?
    public let rank_by_form: Int?
    public let rank_by_index: Int?
    public let is_me: Bool?
  }

  /// `friends_board()` rows. A row with no profile id is dropped — it cannot
  /// be a door, and a row that opens nothing is what P-7 forbids.
  public static func parse(_ rows: [ServerRow], days: Int = 30) -> FriendsBoard {
    FriendsBoard(days: days, rows: rows.compactMap { r in
      guard let id = r.profile_id else { return nil }
      return Row(profileId: id, displayName: r.display_name, handle: r.handle, marker: r.marker,
                 indexCurrent: r.index_current, rounds: r.rounds_30d ?? 0, beats: r.beats_30d ?? 0,
                 avgVsNumber: r.avg_vs_number_30d, bestVsNumber: r.best_vs_number_30d,
                 lastRoundOn: r.last_round_on,
                 rankByForm: r.rank_by_form ?? 0, rankByIndex: r.rank_by_index ?? 0,
                 isMe: r.is_me ?? false)
    })
  }
}
