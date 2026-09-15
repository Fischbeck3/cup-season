import Testing
import Foundation
@testable import CupSeasonKit

/// **BUILD 905's OWN CODE, FROZEN, AGAINST THE NEW PAYLOAD** (D362).
///
/// `20261104090000` drops `round_card(uuid)` and creates `round_card(uuid,
/// uuid default null)`, and for a round counting in two leagues the scalars
/// come back null. Build 905 — the quality checkpoint on TestFlight — decodes
/// that payload with the code below, copied verbatim from `714609b`'s
/// `ReceiptSeed.merged(with:)` and `ReceiptRows.build`. The question these
/// answer is not "does the new client cope" but "what does the SHIPPED one do".
///
/// The answer, asserted here: it prints no `This month` row at all — it
/// degrades to silence, never to a wrong league's rank.
@Suite struct Build905CompatTests {

  /// Verbatim from `714609b` — the five scalar reads the shipped receipt makes.
  struct Seed905 {
    var pvi: Double?; var playingIndex: Double?; var points: Double?
    var monthRank: Int?; var countingCap: Int?
    var gross: Int?; var band: String?; var isMine: Bool?
    static func merged(_ json: JSONValue) -> Seed905 {
      guard case .object(let o) = json else { return Seed905() }
      func has(_ k: String) -> Bool { o[k] != nil }
      var r = Seed905()
      if has("gross") { r.gross = o["gross"]?.int }
      if has("pvi") { r.pvi = o["pvi"]?.double }
      if has("band") { r.band = o["band"]?.string }
      if has("playing_index") { r.playingIndex = o["playing_index"]?.double }
      if has("points") { r.points = o["points"]?.double }
      if has("month_rank") { r.monthRank = o["month_rank"]?.int }
      if has("counting_cap") { r.countingCap = o["counting_cap"]?.int }
      if has("is_mine") { r.isMine = o["is_mine"]?.bool }
      return r
    }
    /// Verbatim from `714609b`'s `ReceiptRows.build` — the month row only.
    func monthRow(capN: Int?) -> String? {
      guard let rank = monthRank else { return nil }
      let cap = countingCap ?? capN
      let counting = cap.map { rank <= $0 } ?? true
      let clause = cap.map { "COUNTING #\(rank) OF \($0)" } ?? "COUNTING #\(rank)"
      return counting ? clause : "BUMPED"
    }
  }

  private func json(_ s: String) -> JSONValue {
    try! JSONDecoder().decode(JSONValue.self, from: Data(s.utf8))
  }

  /// What `round_card(p_round)` — the one-argument call build 905 makes —
  /// returns from the NEW function for a round counting in TWO leagues: every
  /// key 905 reads is present, and the ambiguous scalars are null.
  private let twoLeagues = #"""
  {"id":"00000000-0000-4000-8000-00000000e003","gross":92,"holes_played":18,"played_on":"2026-09-12",
   "course_label":"Encanto","rating":70.1,"slope":120,"nine_rating":null,"differential":19.3,
   "index_at_post":12.0,"index_provisional":false,"provisional_round":null,
   "playing_index":null,"pvi":-7.3,"band":"A little loose",
   "points":null,"month_rank":null,"counting_cap":null,
   "league_id":null,"season_id":null,"member_id":null,
   "contributions":[{"league_name":"Fellas","month_rank":3,"counting_cap":2,"points":2},
                    {"league_name":"Sunday Cup","month_rank":3,"counting_cap":null,"points":2}],
   "source":"app","attested":false,"photo_path":null,"live_round_id":null,
   "profile_id":"00000000-0000-4000-8000-00000000a001","golfer":"Sam Fixture","is_mine":true,"played_with":[]}
  """#

  /// The same call for a round counting in ONE league: the scalars ARE that lens.
  private let oneLeague = #"""
  {"id":"00000000-0000-4000-8000-00000000e001","gross":84,"holes_played":18,"played_on":"2026-09-01",
   "course_label":"Papago","rating":70.1,"slope":120,"differential":12.5,"index_at_post":12.0,
   "index_provisional":false,"playing_index":12.0,"pvi":-0.5,"band":"Played to it",
   "points":7,"month_rank":2,"counting_cap":4,
   "league_id":"00000000-0000-4000-8000-00000000b001","season_id":"00000000-0000-4000-8000-00000000c001",
   "member_id":"00000000-0000-4000-8000-00000000d001",
   "contributions":[{"league_name":"Fellas","month_rank":2,"counting_cap":4,"points":7}],
   "source":"app","attested":false,"photo_path":null,"live_round_id":null,
   "profile_id":"00000000-0000-4000-8000-00000000a001","golfer":"Sam Fixture","is_mine":true,"played_with":[]}
  """#

  @Test("build 905 decodes the new payload: every key it reads is present, and an unknown key is ignored")
  func decodes() {
    let s = Seed905.merged(json(twoLeagues))
    #expect(s.gross == 92 && s.pvi == -7.3 && s.band == "A little loose" && s.isMine == true,
            "905 lost a fact it used to read")
    #expect(s.points == nil && s.monthRank == nil && s.countingCap == nil && s.playingIndex == nil,
            "the ambiguous scalars must be null, not another league's")
  }

  @Test("two leagues, no context: build 905 prints NO month row — silence, never a wrong league's rank")
  func twoLeaguesDegradesToSilence() {
    let s = Seed905.merged(json(twoLeagues))
    #expect(s.monthRow(capN: 4) == nil, "905 invented a month row from a null rank")
    #expect(s.monthRow(capN: nil) == nil)
  }

  @Test("one league: build 905 prints exactly what it printed before the migration")
  func oneLeagueUnchanged() {
    let s = Seed905.merged(json(oneLeague))
    #expect(s.monthRow(capN: 4) == "COUNTING #2 OF 4")
    #expect(s.points == 7 && s.playingIndex == 12.0)
  }

  @Test("the current client reads the same two payloads as lenses, and the two-league one is not silent")
  func currentClientIsNotSilent() {
    let me = UUID(uuidString: "00000000-0000-4000-8000-00000000a001")!
    var seed = ReceiptSeed(id: UUID()).merged(with: json(twoLeagues))
    seed.profileId = me
    let months = ReceiptRows.build(seed, capN: 4, viewerId: me).compactMap { r -> String? in
      if case .math(let l, let v, _) = r, l.hasPrefix("This month") { return "\(l)=\(v)" }
      return nil
    }
    #expect(months == ["This month · Fellas=BUMPED · 2 PTS", "This month · Sunday Cup=COUNTING #3 · 2 PTS"])
  }
}
