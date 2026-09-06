// D262 / R-O · what's in the bag.
//
// The half a screenshot cannot prove: the payload's honesty rules (a bag that
// did not load is not an empty bag; a `beat` figure that never arrived is not
// zero), the sentence the whole feature exists for, and the two refusals —
// the fourteen and the acronym.

import Foundation
import Testing
@testable import CupSeasonKit

@Suite struct BagTests {

  private func parse(_ json: String) throws -> Bag {
    Bag.parse(try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8)))
  }

  // MARK: - the payload

  @Test("a bag_of payload becomes a bag, and a row with no label is dropped")
  func decodesThePayload() throws {
    let bag = try parse("""
    {"visible":true,"is_me":true,
     "clubs":[{"id":"4E4D2C6E-0000-0000-0000-000000000001","slot":"Driver","label":"TSR3 9° · Ventus Blue","added_on":"2026-07-01"},
              {"id":"4E4D2C6E-0000-0000-0000-000000000002","slot":null,"label":"Newport 2","added_on":"2026-01-04"},
              {"id":"4E4D2C6E-0000-0000-0000-000000000003","slot":"5-wood"}],
     "sideline":[{"id":"4E4D2C6E-0000-0000-0000-000000000004","slot":"3-iron","label":"P790","added_on":"2026-02-02","removed_on":"2026-07-01"}],
     "ball":{"id":"4E4D2C6E-0000-0000-0000-000000000005","label":"Pro V1","added_on":"2026-07-01"},
     "since":{"slot":"Driver","label":"TSR3 9° · Ventus Blue","added_on":"2026-07-01","rounds":4,"beat":2}}
    """)
    #expect(bag.visible && bag.isMe)
    #expect(bag.clubs.count == 2)                       // the label-less row is DROPPED, never defaulted
    #expect(bag.clubs.first?.line == "Driver · TSR3 9° · Ventus Blue")
    #expect(bag.clubs.last?.line == "Newport 2")        // no slot, no separator hanging off it
    #expect(bag.sideline.first?.removedOn == "2026-07-01")
    #expect(bag.ball?.label == "Pro V1")
    #expect(bag.since?.rounds == 4 && bag.since?.beat == 2)
    #expect(!bag.isEmpty)
  }

  @Test("two brand-new rows are two rows — identity is local, never the server's nil")
  func newRowsAreDistinct() {
    let a = Bag.Item(label: "")
    let b = Bag.Item(label: "")
    #expect(a.id != b.id)
    #expect(a.serverId == nil && b.serverId == nil)
  }

  @Test("an invisible card is an invisible bag, and it is not an empty one")
  func invisibleIsNotEmpty() throws {
    let bag = try parse(#"{"visible":false}"#)
    #expect(!bag.visible)
    // the surfaces branch on `visible` FIRST; nothing may read the lists of a
    // card it was not allowed to see
    #expect(bag.clubs.isEmpty && bag.sideline.isEmpty && bag.ball == nil)
  }

  @Test("a since block with no rounds behind it is not a since block")
  func sinceNeedsRounds() throws {
    let bag = try parse("""
    {"visible":true,"is_me":true,"clubs":[],"sideline":[],
     "since":{"slot":"Driver","label":"TSR3","added_on":"2026-09-01","rounds":0,"beat":null}}
    """)
    #expect(bag.since == nil)
  }

  @Test("beat is null, not zero, when no season has scored the rounds")
  func beatCanBeAbsent() throws {
    let bag = try parse("""
    {"visible":true,"is_me":true,"clubs":[],"sideline":[],
     "since":{"slot":"Driver","label":"TSR3","added_on":"2026-07-01","rounds":4,"beat":null}}
    """)
    let since = try #require(bag.since)
    #expect(since.beat == nil)
    // the sentence stops after the rounds rather than claiming a zero
    #expect(BagCopy.sinceLine(since) == "Since the new driver went in: four rounds.")
  }

  // MARK: - the sentence R-O asked for

  @Test("since the new driver went in: four rounds, two beat your playing HCP")
  func theLine() {
    let s = Bag.Since(slot: "Driver", label: "TSR3 9°", addedOn: "2026-07-01", rounds: 4, beat: 2)
    #expect(BagCopy.sinceLine(s) == "Since the new driver went in: four rounds, two beat your playing HCP.")
    // R-M · the noun is the playing HCP, and the acronym keeps its case
    #expect(BagCopy.sinceLine(s).contains("playing HCP"))
    #expect(!BagCopy.sinceLine(s).contains("playing hcp"))
    // somebody else's page turns the possessive over through the one producer
    #expect(BagCopy.sinceLine(s, isMe: false)
            == "Since the new driver went in: four rounds, two beat their playing HCP.")
  }

  @Test("one round is one round, and none of them is said plainly")
  func theLineDegrades() {
    #expect(BagCopy.sinceLine(Bag.Since(slot: nil, label: "A club", addedOn: "2026-07-01", rounds: 1, beat: 1))
            == "Since the new club went in: one round, one beat your playing HCP.")
    #expect(BagCopy.sinceLine(Bag.Since(slot: "3-wood", label: "TSi2", addedOn: "2026-07-01", rounds: 6, beat: 0))
            == "Since the new 3-wood went in: six rounds, none of them beat your playing HCP.")
  }

  @Test("the slot lower-cases like a word and never like an acronym")
  func theWord() {
    #expect(BagCopy.word("Driver") == "driver")
    #expect(BagCopy.word("3-Wood") == "3-wood")
    #expect(BagCopy.word("TSR3") == "TSR3")     // the R-M lesson, in one line
    #expect(BagCopy.word(nil) == "club")
    #expect(BagCopy.word("   ") == "club")
  }

  // MARK: - the summary on the You door

  @Test("the door says what is in the bag, or what a bag is")
  func theSummary() {
    let empty = Bag(visible: true, isMe: true)
    #expect(BagCopy.summary(empty) == BagCopy.noneYet)
    let full = Bag(visible: true, isMe: true,
                   clubs: (1...13).map { Bag.Item(label: "club \($0)") },
                   sideline: [Bag.Item(label: "P790")],
                   ball: Bag.Item(label: "Pro V1"))
    #expect(BagCopy.summary(full) == "13 clubs · 1 on the sideline · Pro V1")
    let one = Bag(visible: true, isMe: true, clubs: [Bag.Item(label: "Newport 2")])
    #expect(BagCopy.summary(one) == "1 club")
  }

  // MARK: - what goes out on the wire

  @Test("a write carries the server's id, trims what the golfer typed, and blanks an empty slot")
  func theWrite() {
    let item = Bag.Item(serverId: UUID(uuidString: "4E4D2C6E-0000-0000-0000-000000000001"),
                        slot: "  ", label: "  TSR3 9°  ")
    let w = BagWrite(item)
    #expect(w.id == "4E4D2C6E-0000-0000-0000-000000000001")
    #expect(w.slot == nil)
    #expect(w.label == "TSR3 9°")
  }

  @Test("a nil list is absent from the payload — absent means LEAVE IT ALONE, [] means empty it")
  func nilListIsAbsent() throws {
    let call = SaveBagCall(p_clubs: nil, p_sideline: [], p_ball: nil, p_ball_set: false)
    let obj = try JSONSerialization.jsonObject(with: JSONEncoder().encode(call)) as? [String: Any]
    let keys = Set((obj ?? [:]).keys)
    #expect(!keys.contains("p_clubs"))         // absent → the SQL default → untouched
    #expect(keys.contains("p_sideline"))       // present and empty → emptied
    #expect(keys.contains("p_ball_set"))
  }

  @Test("neither call drops an argument on a retry")
  func noDroppableArguments() {
    // Dropping `p_profile` would read MY bag and render it under somebody
    // else's name; dropping `p_ball_set` would silently discard a ball the
    // golfer had just typed. A missing function is not fixed by asking again.
    #expect(BagOfCall.optionalArgs.isEmpty)
    #expect(SaveBagCall.optionalArgs.isEmpty)
    #expect(BagOfCall.name == "bag_of" && SaveBagCall.name == "save_bag")
  }

  @Test("fourteen is the cap, and it is the Rules' number")
  func theCap() {
    #expect(BagCopy.cap == 14)
  }
}
