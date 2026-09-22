import Testing
import Foundation
@testable import CupSeasonKit

/// D362 · the receipt's lenses and the composer's served counters, on both
/// databases: the one that carries `contributions` and the one that does not.
@Suite struct ReceiptLensesTests {
  private let me = UUID(uuidString: "00000000-0000-4000-8000-0000000000aa")!
  private func seed(_ json: String) -> ReceiptSeed {
    let v = try! JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))
    var s = ReceiptSeed(id: UUID()).merged(with: v)
    s.profileId = me
    return s
  }
  private func lensRows(_ s: ReceiptSeed) -> [(String, String)] {
    ReceiptRows.build(s, capN: 4, viewerId: me).compactMap {
      if case .math(let l, let v, _) = $0, l.hasPrefix("This month") { return (l, v) }
      return nil
    }
  }
  private func doors(_ s: ReceiptSeed) -> [ReceiptCountingDoor] {
    ReceiptRows.build(s, capN: 4, viewerId: me).compactMap { if case .countingDoor(let d) = $0 { return d }; return nil }
  }

  @Test("the clause: no denominator without a cap, the denominator with one, BUMPED past it")
  func clause() {
    #expect(ReceiptRows.clause(rank: 2, cap: nil) == "COUNTING #2")
    #expect(ReceiptRows.clause(rank: 2, cap: 0) == "COUNTING #2")
    #expect(ReceiptRows.clause(rank: 2, cap: 4) == "COUNTING #2 OF 4")
    #expect(ReceiptRows.clause(rank: 5, cap: 4) == "BUMPED")
  }

  @Test("one lens: one unnamed row and one door to that season's month")
  func oneLens() {
    let s = seed(#"{"gross":84,"contributions":[{"league_id":"00000000-0000-4000-8000-000000000001","league_name":"Fellas","season_id":"00000000-0000-4000-8000-000000000002","member_id":"00000000-0000-4000-8000-000000000003","points":7,"month_rank":2,"counting_cap":4,"month":"2026-09"}]}"#)
    #expect(lensRows(s).map(\.0) == ["This month"] && lensRows(s).first?.1 == "COUNTING #2 OF 4")
    let d = doors(s)
    #expect(d.count == 1 && d.first?.month == "2026-09" && d.first?.label == "Your rounds that count in September")
  }

  @Test("two lenses: each row names its league and carries its points; a bumped one says so; an uncapped one has no denominator")
  func twoLenses() {
    let s = seed(#"{"gross":92,"contributions":[{"league_name":"Fellas","season_id":"00000000-0000-4000-8000-000000000002","member_id":"00000000-0000-4000-8000-000000000003","points":2,"month_rank":3,"counting_cap":2,"month":"2026-09"},{"league_name":"Sunday Cup","season_id":"00000000-0000-4000-8000-000000000004","member_id":"00000000-0000-4000-8000-000000000005","points":2,"month_rank":3,"counting_cap":null,"month":"2026-09"}]}"#)
    let rows = lensRows(s)
    #expect(rows.map(\.0) == ["This month · Fellas", "This month · Sunday Cup"])
    #expect(rows[0].1 == "BUMPED · 2 PTS" && rows[1].1 == "COUNTING #3 · 2 PTS")
    #expect(doors(s).map(\.label) == ["Your rounds that count in September · Fellas", "Your rounds that count in September · Sunday Cup"])
  }

  @Test("no contributions (the older database): the scalars' one lens, no door; nothing at all when the round has no rank")
  func olderDatabase() {
    let s = seed(#"{"gross":84,"points":7,"month_rank":2,"counting_cap":4}"#)
    #expect(lensRows(s).first?.1 == "COUNTING #2 OF 4" && doors(s).isEmpty)
    let none = seed(#"{"gross":84}"#)
    #expect(lensRows(none).isEmpty && doors(none).isEmpty)
  }

  @Test("the served counters become the composer's sentences, the season named only when there are two")
  func servedLines() {
    let one = try! JSONDecoder().decode(JSONValue.self, from: Data(#"[{"league_name":"Fellas","cap":4,"counters":{"used":2,"worst":5}}]"#.utf8))
    #expect(RoundWorth.servedLines(one) == ["This round can score up to 12, and it counts: your best 4 count and you have 2."])
    let two = try! JSONDecoder().decode(JSONValue.self, from: Data(#"[{"league_name":"Fellas","cap":2,"counters":{"used":2,"worst":6}},{"league_name":"Sunday Cup","cap":null,"counters":{"used":3,"worst":5}}]"#.utf8))
    let lines = RoundWorth.servedLines(two)
    #expect(lines.count == 2 && lines[0].contains("in Fellas") && lines[1].contains("in Sunday Cup") && lines[1].contains("Every round you post this month counts"))
    #expect(RoundWorth.servedLines(.array([])).isEmpty, "no season, nothing promised")
  }
}
