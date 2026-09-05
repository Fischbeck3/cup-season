import Testing
import Foundation
@testable import CupSeasonKit

/// D225 / R9 · the covenant names the crew, the clock and what the money buys.
///
/// L-12 says every join passes the covenant. It did not: the gate fired only
/// above $0, so a golfer joining a FREE season never met the Pro, the length,
/// the rules or the ending. And even above $0 the screen could only say five
/// things, because the payload only carried five.
///
/// Two properties, and the second is the one that keeps a client shipping ahead
/// of a migration honest: **an absent fact renders NOTHING** (L-44).
@Suite struct CovenantFactsTests {

  /// Everything R9 returns, for a real $50 season.
  private static let full = Covenant(
    name: "the Fellas", buyinCents: 5000, preset: "standard", floor: 2, finish: "cup_final",
    proName: "Casey Nguyen", rosterCount: 8,
    rosterNames: ["Marcus Webb", "Dev Patel", "Tash Boyle", "Ravi Shah", "Jules Kerr"],
    startsOn: "2026-09-12", weeks: 13, countingCap: 3,
    split: .init(champion: 60, runnerUp: 25, pointsKing: 15),
    hasPayNote: true, buyInDueOn: nil, phase: "setup")

  /// Exactly what the SHIPPED `join_covenant_info` returns — no R9 at all.
  private static let today = Covenant(name: "the Fellas", buyinCents: 5000,
                                      preset: "standard", floor: 2, finish: "cup_final")

  // MARK: - the six added facts render

  @Test func whoComesBeforeTheMoney() {
    let facts = Self.full.facts()
    #expect(facts.first?.0 == .who)
    let who = try? #require(Self.full.whoLine)
    #expect(who?.hasPrefix("Casey Nguyen runs the season (the Pro).") == true)
    // five named, eight in, so two more beyond me and the five
    #expect(who?.contains("Marcus, Dev, Tash, Ravi, Jules and 2 more are in.") == true)
    // D132's noun, DEFINED at first contact rather than merely used
    #expect(who?.contains("(the Pro)") == true)
    // the money is after it
    let order = facts.map(\.0)
    #expect(order.firstIndex(of: .who)! < order.firstIndex(of: .stake)!)
  }

  @Test func theClockAndTheLength() {
    #expect(Self.full.lengthLine == "Thirteen weeks from Sat Sep 12.")
  }

  /// The payload's `floor` is the OTHER number; "best three a month count" was
  /// unsayable until R9 returned the counting cap.
  @Test func theRuleSaysBestThreeAndTheMinimum() {
    let r = try? #require(Self.full.rulesLine)
    #expect(r == "Standard rules: honest scores, best three a month count, two a month keeps you in.")
  }

  @Test func theEndingIsD126sSentenceNotADialName() {
    #expect(Self.full.endingLine == "It ends with a four-week Cup Final between the top two.")
    let table = Covenant(name: "x", buyinCents: 0, preset: nil, floor: 0, finish: "points_table")
    #expect(table.endingLine == "The season's points decide it. No reset.")
    for s in [Self.full.endingLine, table.endingLine] {
      #expect(!s.lowercased().contains("cup_final"))
      #expect(!s.lowercased().contains("points_table"))
    }
  }

  /// L-10 · the split renders ABOVE $0 only, and the trio is the Pro's own,
  /// printed rather than assumed.
  @Test func theSplitAnswersWhatFiftyDollarsBuys() {
    let s = try? #require(Self.full.splitLine)
    #expect(s == "If you take it: 60 percent to the champion, 25 to the runner-up, 15 to the points king.")
    let free = Covenant(name: "x", buyinCents: 0, preset: nil, floor: 0, finish: nil,
                        split: .init(champion: 60, runnerUp: 25, pointsKing: 15))
    #expect(free.splitLine == nil)
  }

  /// D129, unweakened: a BOOLEAN and a DATE, never the note itself.
  @Test func thePayFactIsABooleanAndADate() {
    #expect(Self.full.payLine?.hasPrefix("The Pro has said how to pay") == true)
    let noNote = Covenant(name: "x", buyinCents: 5000, preset: nil, floor: 0, finish: nil, hasPayNote: false)
    #expect(noNote.payLine == "The Pro hasn't said how to pay yet. It'll be on the pot when they do.")
    let due = Covenant(name: "x", buyinCents: 5000, preset: nil, floor: 0, finish: nil,
                       hasPayNote: true, buyInDueOn: "2026-09-19")
    #expect(due.payLine?.contains("by Sat Sep 19") == true)
    // never the note itself: there is nowhere on the value to put one
    #expect(!(due.payLine ?? "").contains("Venmo"))
  }

  @Test func allSixAreThereWhenTheReadIs() {
    let facts = Self.full.facts(postedRounds: 0).map(\.0)
    for f in [Covenant.Fact.who, .length, .rules, .ending, .stake, .ledger, .split, .pay, .starter] {
      #expect(facts.contains(f), Comment(rawValue: String(describing: f)))
    }
  }

  // MARK: - absent facts render nothing (L-44)

  @Test func theShippedPayloadRendersOnlyWhatItKnows() {
    let facts = Self.today.facts()
    let kinds = Set(facts.map(\.0))
    // no read → no line. Never "—", never a guess.
    #expect(Self.today.whoLine == nil)
    #expect(Self.today.lengthLine == nil)
    #expect(Self.today.splitLine == nil)
    #expect(Self.today.payLine == nil)
    #expect(!kinds.contains(.who))
    #expect(!kinds.contains(.length))
    #expect(!kinds.contains(.split))
    #expect(!kinds.contains(.pay))
    // and it still says the true things it can: the ending, the stake, the ledger
    #expect(kinds.contains(.ending))
    #expect(kinds.contains(.stake))
    #expect(kinds.contains(.ledger))
  }

  /// Half a read is still honest: weeks with no first tee, and a first tee with
  /// no weeks, each say the half they know.
  @Test func halfAClockSaysHalfASentence() {
    let onlyWeeks = Covenant(name: "x", buyinCents: 0, preset: nil, floor: 0, finish: nil, weeks: 13)
    #expect(onlyWeeks.lengthLine == "Thirteen weeks.")
    let onlyDate = Covenant(name: "x", buyinCents: 0, preset: nil, floor: 0, finish: nil, startsOn: "2026-09-12")
    #expect(onlyDate.lengthLine == "First tee Sat Sep 12.")
  }

  /// The Pro alone. True, and not a lie about a crew.
  @Test func aSeasonOfOneSaysSo() {
    let solo = Covenant(name: "x", buyinCents: 0, preset: nil, floor: 0, finish: nil,
                        proName: "Galen", rosterCount: 1)
    #expect(solo.whoLine == "Galen runs the season (the Pro). Nobody else yet.")
  }

  // MARK: - $0 renders, and it renders differently

  /// The defect this entry exists to close: at $0 the same screen renders,
  /// without the money lines, without the split, and the button names the season.
  @Test func aFreeSeasonStillPassesTheCovenant() {
    let free = Covenant(name: "the Fellas", buyinCents: 0, preset: "standard", floor: 2, finish: "cup_final",
                        proName: "Casey Nguyen", rosterCount: 3, rosterNames: ["Dev Patel", "Tash Boyle"],
                        startsOn: "2026-09-12", weeks: 13, countingCap: 3)
    let kinds = free.facts().map(\.0)
    #expect(kinds.contains(.who))
    #expect(kinds.contains(.length))
    #expect(kinds.contains(.rules))
    #expect(kinds.contains(.ending))
    // L-10 · a $0 season shows NO pot surface anywhere
    #expect(!kinds.contains(.stake))
    #expect(!kinds.contains(.ledger))
    #expect(!kinds.contains(.split))
    #expect(!kinds.contains(.pay))
    #expect(free.joinLabel == "Join the Fellas")
    #expect(Self.full.joinLabel == "Join — I’m in for $50")
  }

  /// L-09 · the ledger line is the constant, never retyped.
  @Test func theLedgerLineIsTheConstant() {
    #expect(Self.full.potLine == MoneyCopy.ledger)
  }

  /// D124's provisional starter, said BEFORE the tap rather than discovered
  /// after it — above $0 and below it.
  @Test func theStarterClauseRendersOnFewerThanThreeRounds() {
    for stake in [0, 5000] {
      let c = Covenant(name: "x", buyinCents: stake, preset: nil, floor: 0, finish: nil)
      #expect(c.facts(postedRounds: 0).map(\.0).contains(.starter))
      #expect(c.facts(postedRounds: 2).map(\.0).contains(.starter))
      #expect(!c.facts(postedRounds: 3).map(\.0).contains(.starter))
      // not READ is not the same as three posted: it is omitted, not guessed
      #expect(!c.facts(postedRounds: nil).map(\.0).contains(.starter))
    }
  }

  // MARK: - the decode keeps every fact, and drops none

  @Test func theDecodeReadsR9sShapeAndTheOldOne() throws {
    func json(_ s: String) throws -> JSONValue {
      try JSONDecoder().decode(JSONValue.self, from: Data(s.utf8))
    }
    let c = try #require(Covenant(try json("""
      {"name":"the Fellas","buyin_cents":5000,"preset":"standard","floor":2,
       "finish":"cup_final","phase":"setup",
       "roster":{"count":8,"pro_name":"Casey Nguyen","names":["Marcus Webb","Dev Patel"],"markers":["azalea","island"]},
       "starts_on":"2026-09-12","weeks":13,"counting_cap":3,
       "split":{"champion":60,"runner_up":25,"points_king":15},
       "pay":{"has_note":true,"due_on":null}}
      """)))
    #expect(c.proName == "Casey Nguyen")
    #expect(c.rosterCount == 8)
    #expect(c.rosterNames == ["Marcus Webb", "Dev Patel"])
    #expect(c.weeks == 13)
    #expect(c.countingCap == 3)
    #expect(c.split?.champion == 60)
    #expect(c.hasPayNote == true)
    #expect(c.phase == "setup")

    // The SHIPPED payload, which carries `has_pay_note` and `buy_in_due_on`
    // flat — the two facts `Covenant.init` used to drop on the floor — and none
    // of R9's six. Every one of them decodes to nil and renders nothing.
    let o = try #require(Covenant(try json("""
      {"name":"x","buyin_cents":5000,"preset":"standard","floor":2,"finish":"cup_final",
       "has_pay_note":true,"buy_in_due_on":"2026-09-19","phase":"season"}
      """)))
    #expect(o.hasPayNote == true)
    #expect(o.buyInDueOn == "2026-09-19")
    #expect(o.weeks == nil)
    #expect(o.whoLine == nil)
    #expect(o.splitLine == nil)

    // A key the client does not know decodes to nothing rather than throwing —
    // the server may add a seventh fact before this build knows it.
    let future = try #require(Covenant(try json("""
      {"name":"x","buyin_cents":0,"floor":0,"an_unknown_fact":{"deep":[1,2]}}
      """)))
    #expect(future.name == "x")
    #expect(future.whoLine == nil)
  }
}
