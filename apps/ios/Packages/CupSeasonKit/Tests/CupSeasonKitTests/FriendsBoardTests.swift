// Cup Season — the board (R5, D245 / C-7).
//
// D245 rules ranking friends narrowly, and every clause of the ruling is a
// case here rather than a comment in a migration:
//
//   1 · FORM is the default lens — beats first, then rounds, then the average
//   2 · the handicap is the SECOND lens, and there are only two
//   3 · NEVER points (L-13) and NO ATTENTION METRIC OF ANY KIND (L-22) —
//       asserted against the type's own shape, not against a promise
//   4 · buddies only, and `discoverable = 'nobody'` does NOT hide a golfer
//       from the buddies who accepted them
//   5 · the display is a BAND, never a raw figure (L-14 / T-07), and the
//       round COUNT rides beside it so a two-round month never masquerades as
//       a season of form

import Testing
import Foundation
@testable import CupSeasonKit

private func rows(_ json: String) throws -> [FriendsBoard.ServerRow] {
  try JSONDecoder().decode([FriendsBoard.ServerRow].self, from: Data(json.utf8))
}

private let me = "11111111-1111-1111-1111-111111111111"
private let tash = "22222222-2222-2222-2222-222222222222"
private let marcus = "33333333-3333-3333-3333-333333333333"
private let quiet = "44444444-4444-4444-4444-444444444444"

/// IA §10.2's own worked example, plus a buddy whose `discoverable` is
/// 'nobody' — the server does not send that column at all, which is the point.
private let board = """
[
  { "profile_id": "\(tash)", "display_name": "Tash", "handle": "tash", "marker": "cactus",
    "index_current": 14.2, "rounds_30d": 4, "beats_30d": 3, "avg_vs_number_30d": 2.4,
    "best_vs_number_30d": 5.1, "last_round_on": "2026-09-01",
    "rank_by_form": 1, "rank_by_index": 3, "is_me": false },
  { "profile_id": "\(me)", "display_name": "Jerecho", "handle": "jer", "marker": "saguaro",
    "index_current": 12.4, "rounds_30d": 6, "beats_30d": 2, "avg_vs_number_30d": 0.4,
    "best_vs_number_30d": 3.0, "last_round_on": "2026-09-04",
    "rank_by_form": 2, "rank_by_index": 2, "is_me": true },
  { "profile_id": "\(marcus)", "display_name": "Marcus", "handle": "marc", "marker": "beer",
    "index_current": 9.1, "rounds_30d": 2, "beats_30d": 0, "avg_vs_number_30d": -0.2,
    "best_vs_number_30d": 0.6, "last_round_on": "2026-08-28",
    "rank_by_form": 3, "rank_by_index": 1, "is_me": false },
  { "profile_id": "\(quiet)", "display_name": "Jade", "handle": "jade", "marker": "flag",
    "index_current": 10.0, "rounds_30d": 0, "beats_30d": 0, "avg_vs_number_30d": null,
    "best_vs_number_30d": null, "last_round_on": null,
    "rank_by_form": 4, "rank_by_index": 4, "is_me": false }
]
"""

@Suite struct FriendsBoardTests {

  // MARK: clause 1 — form first

  @Test func formIsTheDefaultAndBeatsLeadIt() throws {
    let b = FriendsBoard.parse(try rows(board))
    #expect(b.ordered(.form).map(\.name) == ["Tash", "You", "Marcus", "Jade"])
    // IA §10.2's example, exactly: four rounds and three beats leads six
    // rounds and two beats, because beats are the fact and rounds are the
    // tiebreak.
    #expect(b.ordered(.form)[0].beats == 3)
    #expect(b.ordered(.form)[1].beats == 2)
  }

  // MARK: the rail follows the figure the row prints (DF-01)

  /// **A ranked list may not contradict its own column.** The board prints
  /// `avgVsNumber` under a note reading `VS PLAYING HCP · PLUS IS BETTER`, so
  /// a +2.8 row outranks a −2.6 row, whatever the server's `rank_by_form`
  /// says. The fixture below is the photographed board that caught it.
  @Test func theOrderFollowsThePrintedFigureAndNotTheServersRank() throws {
    let b = FriendsBoard.parse(try rows("""
    [ { "profile_id": "\(tash)",   "display_name": "Tash",   "rounds_30d": 4, "beats_30d": 3,
        "avg_vs_number_30d": -2.6, "index_current": 14.2, "rank_by_form": 1, "rank_by_index": 3 },
      { "profile_id": "\(me)",     "display_name": "Jerecho", "rounds_30d": 6, "beats_30d": 2,
        "avg_vs_number_30d": 1.0,  "index_current": 12.4, "rank_by_form": 2, "rank_by_index": 2, "is_me": true },
      { "profile_id": "\(marcus)", "display_name": "Marcus", "rounds_30d": 2, "beats_30d": 2,
        "avg_vs_number_30d": 2.8,  "index_current": 9.1,  "rank_by_form": 3, "rank_by_index": 1 },
      { "profile_id": "\(quiet)",  "display_name": "Jade",   "rounds_30d": 1, "beats_30d": 0,
        "avg_vs_number_30d": -3.8, "index_current": 10.0, "rank_by_form": 4, "rank_by_index": 4 } ]
    """))
    // plus is better, so the figures descend down the rail
    #expect(b.ordered(.form).map(\.name) == ["Marcus", "You", "Tash", "Jade"])
    let figures = b.ordered(.form).compactMap(\.avgVsNumber)
    #expect(figures == figures.sorted(by: >), "the rail contradicts its own column")
    // and BOTH directions: a plus outranks a minus, and a bigger plus outranks
    // a smaller one
    #expect(b.ranked(.form).first { $0.row.name == "Marcus" }?.rank == 1)
    #expect(b.ranked(.form).first { $0.row.name == "Jade" }?.rank == 4)
    // the handicap lens ranks on the figure IT prints, ascending
    #expect(b.ordered(.handicap).map(\.name) == ["Marcus", "Jade", "You", "Tash"])
  }

  /// A golfer with no figure has nothing to be ranked on and takes the tail —
  /// never a zero, never a guess (L-44).
  @Test func aRowWithNoFigureTakesTheTail() throws {
    let b = FriendsBoard.parse(try rows(board))
    #expect(b.ordered(.form).last?.name == "Jade")     // no rounds in the window
    #expect(b.ranked(.form).last?.rank == 4)
    // and the rail is the POSITION, so it is always 1…n with no holes
    #expect(b.ranked(.form).map(\.rank) == [1, 2, 3, 4])
  }

  @Test func theIndexIsTheSecondLensAndItReordersTheList() throws {
    let b = FriendsBoard.parse(try rows(board))
    #expect(b.ordered(.handicap).map(\.name) == ["Marcus", "Jade", "You", "Tash"])
    // and the two lenses genuinely disagree — a second lens that agrees with
    // the first is not a second lens
    #expect(b.ordered(.form).map(\.name) != b.ordered(.handicap).map(\.name))
  }

  @Test func thereAreExactlyTwoLenses() {
    #expect(FriendsBoard.Lens.allCases.count == 2)
    #expect(Set(FriendsBoard.Lens.allCases.map(\.rawValue)) == ["form", "handicap"])
    // L-13 · never points. A points lens would be a cross-season ladder over
    // season-scoped figures, which is meaningless.
    #expect(!FriendsBoard.Lens.allCases.map(\.rawValue).contains("points"))
  }

  // MARK: clause 3 — no attention metric, asserted against the shape

  @Test func theRowCarriesNoAttentionMetric() throws {
    let b = FriendsBoard.parse(try rows(board))
    let r = try #require(b.rows.first)
    // Encoding the row's own facts and reading the keys back is the only way
    // to assert an ABSENCE. If somebody adds `kudos` or `reactions` to the
    // server row, this fails (L-22).
    let mirror = Mirror(reflecting: FriendsBoard.ServerRow.self)
    _ = mirror
    let banned = ["points", "kudos", "reactions", "followers", "streak", "views", "likes"]
    let fields = Mirror(reflecting: r).children.compactMap(\.label)
    for b in banned {
      #expect(!fields.contains { $0.lowercased().contains(b) }, "an attention metric got onto the board: \(b)")
    }
    // and the row's whole vocabulary is the ranking one
    #expect(Set(fields) == ["profileId", "displayName", "handle", "marker", "indexCurrent",
                            "rounds", "beats", "avgVsNumber", "bestVsNumber", "lastRoundOn",
                            "rankByForm", "rankByIndex", "isMe"])
  }

  // MARK: clause 4 — buddies, and the privacy setting that does not apply

  @Test func discoverableNobodyDoesNotHideMeFromMyBuddies() throws {
    let b = FriendsBoard.parse(try rows(board))
    // Jade's `discoverable` is 'nobody'. The server does not filter on it and
    // the payload does not carry it, because it is the SEARCH gate (L-37) and
    // a golfer who accepted you is not hidden from you by it.
    #expect(b.rows.contains { $0.name == "Jade" })
    let fields = Mirror(reflecting: try #require(b.rows.first)).children.compactMap(\.label)
    #expect(!fields.contains("discoverable"))
  }

  @Test func meIsOnTheBoardAndIsNamedYou() throws {
    let b = FriendsBoard.parse(try rows(board))
    let mine = try #require(b.rows.first { $0.isMe })
    #expect(mine.name == "You")
    #expect(mine.formLine == "6 rounds · beat your playing HCP twice")
  }

  // MARK: clause 5 — a band, and the denominator

  @Test func theFigureIsABandAndNeverTheFloat() throws {
    let b = FriendsBoard.parse(try rows(board))
    let tashRow = try #require(b.rows.first { $0.name == "Tash" })
    // a real screenshot caught the board telling me Tash had beaten MY number
    #expect(tashRow.band == "Beat their number")
    #expect(try #require(b.rows.first { $0.isMe }).band == "Played to it")
    // T-07 · the raw figure never reaches the row's own display
    #expect(tashRow.band?.contains("2.4") == false)
    // and it is still `CSBands`' own table — one band table, one possessive turn
    #expect(CSBands.bandName(2.4) == "Beat your number")
  }

  @Test func aWindowWithNoRoundsInvitesNoBand() throws {
    let b = FriendsBoard.parse(try rows(board))
    let jade = try #require(b.rows.first { $0.name == "Jade" })
    #expect(jade.rounds == 0)
    // L-44 · a band over no rounds is a band about nothing
    #expect(jade.band == nil)
    #expect(jade.formLine == "No rounds in the window")
    // she is still ON the board, with the count said out loud
    #expect(jade.rankByForm == 4)
  }

  @Test func everyFormLineNamesItsDenominator() throws {
    let b = FriendsBoard.parse(try rows(board))
    for r in b.rows where r.rounds > 0 {
      #expect(r.formLine.contains("round"), "\(r.name) printed a figure with no denominator (L-01)")
    }
  }

  @Test func theFormLineCountsInWordsBelowThree() throws {
    let b = FriendsBoard.parse(try rows(board))
    #expect(try #require(b.rows.first { $0.name == "Tash" }).formLine == "4 rounds · beat their playing HCP 3 times")
    #expect(try #require(b.rows.first { $0.name == "Marcus" }).formLine == "2 rounds · didn’t beat their playing HCP")
  }

  // MARK: shape and decoding

  @Test func aRowWithNoProfileIsDropped() throws {
    let b = FriendsBoard.parse(try rows("""
    [ { "display_name": "Ghost", "rounds_30d": 3, "beats_30d": 3, "rank_by_form": 1, "rank_by_index": 1 },
      { "profile_id": "\(tash)", "display_name": "Tash", "rounds_30d": 1, "beats_30d": 0,
        "rank_by_form": 2, "rank_by_index": 2 } ]
    """))
    // P-7 · a row that opens nothing is not a row
    #expect(b.rows.map(\.name) == ["Tash"])
  }

  @Test func aPayloadThatPredatesAColumnStillDecodes() throws {
    // deploy-skew: every field is optional, and a missing figure is a missing
    // figure rather than a zero
    let b = FriendsBoard.parse(try rows("""
    [ { "profile_id": "\(tash)", "display_name": "Tash" } ]
    """))
    let r = try #require(b.rows.first)
    #expect(r.rounds == 0)
    #expect(r.avgVsNumber == nil)
    #expect(r.indexText == "—")
    #expect(r.band == nil)
  }

  @Test func theEmptyRootEndsInANextMove() {
    let root = FriendsBoard.empty()
    #expect(!root.doors.isEmpty)          // L-32, first half
    #expect(root.doors.first == .findGolfers)
    #expect(root.fact == nil)             // L-44 · no consolation fact
  }

  /// A simulator screenshot against prod showed "The board didn't load." over
  /// an account whose board is simply not deployed yet. The read that is not
  /// there and the read that failed are different states and get different
  /// screens: the first renders nothing, the second says so.
  @Test func anUndeployedBoardIsNotAFailedRead() {
    let missing = RpcError(name: "friends_board",
                           underlying: "PGRST202: Could not find the function public.friends_board in the schema cache",
                           droppedArgs: [])
    #expect(PostService.fallbackFires(on: missing))
    let dead = RpcError(name: "friends_board", underlying: "Failed to fetch", droppedArgs: [])
    #expect(!PostService.fallbackFires(on: dead))
  }

  @Test func theSectionSaysThisIsAListNotAScore() {
    // L-22, said where a golfer can read it
    #expect(FriendsBoard.note.contains("No badges"))
    #expect(FriendsBoard.note.contains("no streaks"))
  }

  @Test func theCaptionNamesTheWindow() {
    #expect(FriendsBoard.Lens.form.caption(days: 30) == "LAST 30 DAYS")
    #expect(FriendsBoard.Lens.handicap.caption(days: 30) == "HANDICAP INDEX")
  }
}
