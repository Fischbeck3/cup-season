// Cup Season — the record between two golfers (R4, IOS-032, D239).
//
// Five rules these tests exist to hold, and every one of them is a place the
// old three implementations went wrong:
//
//   · SIX facets, in a FIXED order, from the server's own keys — a facet key
//     this build does not know is dropped, never rendered under a guess
//   · a facet with no data renders NOTHING. Never "0–0", never a dash (P-6)
//   · the same-day/same-course fallback CARRIES ITS LABEL wherever it
//     contributed — it is an inference and the row says so out loud
//   · a meeting with no verdict is NOT a tie: it counts toward "you have
//     played together eleven times" and toward nobody's W–L
//   · nothing is invented. No record, no sentence; no `since`, no clause.

import Testing
import Foundation
@testable import CupSeasonKit

private func json(_ s: String) throws -> JSONValue {
  try JSONDecoder().decode(JSONValue.self, from: Data(s.utf8))
}

private let opp = "77777777-7777-7777-7777-777777777777"

/// A payload with every facet the server can send, in the shape R4 writes it.
private let full = """
{
  "visible": true,
  "opponent": { "id": "\(opp)", "display_name": "Galen", "handle": "galen", "marker": "beer" },
  "league": "Fellas",
  "record": { "wins": 6, "losses": 5, "ties": 0, "total": 11 },
  "lead": "up",
  "since": "2026-03-14",
  "streak": { "who": "them", "n": 2 },
  "last_five": [
    { "on": "2026-08-30", "won": false, "facet": "clashes" },
    { "on": "2026-08-23", "won": false, "facet": "season_weeks" },
    { "on": "2026-08-16", "won": true,  "facet": "played_together" },
    { "on": "2026-08-09", "won": true,  "facet": "live_games" },
    { "on": "2026-08-02", "won": null,  "facet": "duels" }
  ],
  "rivalry_name": "The Grudge",
  "facets": {
    "season_weeks":    { "wins": 3, "losses": 1, "ties": 0, "meetings": 4, "unsettled": 0,
                         "confirmed": 4, "unconfirmed": 0, "heuristic": 0,
                         "basis": "the better round against your playing HCP in a week you both posted",
                         "source": "v_rounds_ranked" },
    "clashes":         { "wins": 1, "losses": 1, "ties": 0, "meetings": 2, "unsettled": 0,
                         "confirmed": 2, "unconfirmed": 0, "heuristic": 0,
                         "basis": "the weekly clash the season opened and settled",
                         "source": "week_clashes" },
    "played_together": { "wins": 1, "losses": 2, "ties": 0, "meetings": 4, "unsettled": 1,
                         "confirmed": 1, "unconfirmed": 1, "heuristic": 2,
                         "basis": "the better card against your playing HCP on a day you were both out",
                         "source": "round_players" },
    "live_games":      { "wins": 1, "losses": 0, "ties": 0, "meetings": 1, "unsettled": 0,
                         "confirmed": 1, "unconfirmed": 0, "heuristic": 0,
                         "basis": "the better card against your playing HCP in a round you both scored live",
                         "source": "live_rounds" },
    "duels":           { "wins": 0, "losses": 1, "ties": 0, "meetings": 1, "unsettled": 0,
                         "confirmed": 1, "unconfirmed": 0, "heuristic": 0,
                         "basis": "a Ryder clash, settled", "source": "event_duels" },
    "callouts":        { "wins": 0, "losses": 0, "ties": 0, "meetings": 1, "unsettled": 1,
                         "confirmed": 1, "unconfirmed": 0, "heuristic": 0,
                         "basis": "a head-to-head with a field of two", "source": "event_duels" }
  }
}
"""

@Suite struct HeadToHeadTests {

  // MARK: the six facets

  @Test func sixFacetsInAFixedOrder() throws {
    let h = HeadToHead.parse(try json(full))
    #expect(h.visible)
    #expect(h.facets.count == 6)
    // the ORDER is the enum's, not the dictionary's — a page reads the same
    // way twice or it is not a page
    #expect(h.facets.map(\.facet) == HeadToHead.Facet.allCases)
    #expect(HeadToHead.Facet.allCases.count == 6)
  }

  @Test func everyFacetCarriesItsOwnBasisAndSource() throws {
    let h = HeadToHead.parse(try json(full))
    for f in h.facets {
      #expect(f.basis?.isEmpty == false, "\(f.facet) lost its basis (L-01)")
      #expect(f.source?.isEmpty == false, "\(f.facet) lost its source")
    }
    // and the five distinct reads are named, not blended into one number —
    // `duels` and `callouts` share `event_duels` because they ARE the same
    // rows, split by the shape of the event's field
    #expect(Set(h.facets.compactMap(\.source))
            == ["v_rounds_ranked", "week_clashes", "round_players", "live_rounds", "event_duels"])
  }

  @Test func aFacetWithNoDataRendersNothing() throws {
    let h = HeadToHead.parse(try json("""
    { "visible": true, "opponent": { "id": "\(opp)", "display_name": "Galen" },
      "record": { "wins": 1, "losses": 0, "ties": 0, "total": 1 }, "lead": "up",
      "facets": {
        "season_weeks": { "wins": 1, "losses": 0, "ties": 0, "meetings": 1 },
        "duels":        { "wins": 0, "losses": 0, "ties": 0, "meetings": 0 },
        "callouts":     { "wins": 0, "losses": 0, "ties": 0, "meetings": 0 }
      } }
    """))
    // P-6 · "does not render — never 0–0"
    #expect(h.facets.map(\.facet) == [.seasonWeeks])
    #expect(h.facets.first?.record == "1–0")
  }

  @Test func aFacetKeyThisBuildDoesNotKnowIsDropped() throws {
    let h = HeadToHead.parse(try json("""
    { "visible": true, "opponent": { "id": "\(opp)" },
      "record": { "wins": 0, "losses": 0, "ties": 0, "total": 3 }, "lead": "even",
      "facets": {
        "moon_shots":   { "wins": 2, "losses": 1, "ties": 0, "meetings": 3 },
        "season_weeks": { "wins": 0, "losses": 0, "ties": 0, "meetings": 3, "unsettled": 3 }
      } }
    """))
    #expect(h.facets.map(\.facet) == [.seasonWeeks])
  }

  // MARK: the heuristic carries its label

  @Test func theHeuristicIsLabelledWhereverItContributed() throws {
    let h = HeadToHead.parse(try json(full))
    let together = try #require(h.facets.first { $0.facet == .playedTogether })
    #expect(together.heuristic == 2)
    let sub = try #require(HeadToHeadCopy.facetSub(together))
    #expect(sub.contains(HeadToHeadCopy.heuristicNote))
    #expect(HeadToHeadCopy.heuristicNote.lowercased().contains("same day"))
    #expect(HeadToHeadCopy.heuristicNote.lowercased().contains("nobody confirmed"))
    // and the page-level flag the foot line reads
    #expect(HeadToHeadCopy.usesHeuristic(h))
  }

  /// A real screenshot caught the basis running straight into the heuristic
  /// label — "…on a day you were both out Same day, same course". Every clause
  /// in a sub is a sentence and ends like one.
  @Test func everyClauseInASubEndsLikeASentence() throws {
    let h = HeadToHead.parse(try json(full))
    for f in h.facets {
      guard let sub = HeadToHeadCopy.facetSub(f) else { continue }
      #expect(sub.hasSuffix("."), "\(f.facet) sub does not end in a full stop")
      for clause in sub.components(separatedBy: ". ") where !clause.isEmpty {
        #expect(clause.first?.isUppercase == true, "\(f.facet) has a clause that does not start a sentence")
      }
    }
    let together = try #require(h.facets.first { $0.facet == .playedTogether })
    #expect(HeadToHeadCopy.facetSub(together)?.contains("out Same day") == false)
  }

  @Test func aFacetWithNoHeuristicNeverCarriesTheLabel() throws {
    let h = HeadToHead.parse(try json(full))
    for f in h.facets where f.heuristic == 0 {
      let sub = HeadToHeadCopy.facetSub(f) ?? ""
      #expect(!sub.contains(HeadToHeadCopy.heuristicNote), "\(f.facet) claimed a heuristic it does not have")
    }
  }

  @Test func aRecordWithNoInferenceInItSaysSo() throws {
    let h = HeadToHead.parse(try json("""
    { "visible": true, "opponent": { "id": "\(opp)" },
      "record": { "wins": 3, "losses": 1, "ties": 0, "total": 4 }, "lead": "up",
      "facets": { "clashes": { "wins": 3, "losses": 1, "ties": 0, "meetings": 4, "heuristic": 0 } } }
    """))
    #expect(!HeadToHeadCopy.usesHeuristic(h))
  }

  // MARK: an unanswered tag, and an undecided meeting

  @Test func anUnconfirmedTagSaysSo() throws {
    let h = HeadToHead.parse(try json(full))
    let together = try #require(h.facets.first { $0.facet == .playedTogether })
    #expect(together.unconfirmed == 1)
    #expect(HeadToHeadCopy.facetSub(together)?.contains(HeadToHeadCopy.unconfirmedNote) == true)
  }

  @Test func aMeetingWithNoVerdictIsNotATie() throws {
    let h = HeadToHead.parse(try json(full))
    let callouts = try #require(h.facets.first { $0.facet == .callouts })
    // one meeting, nobody's win, and NOT a tie
    #expect(callouts.meetings == 1)
    #expect(callouts.ties == 0)
    #expect(callouts.unsettled == 1)
    // with nothing settled the row prints no record at all
    #expect(callouts.record == nil)
    #expect(HeadToHeadCopy.facetSub(callouts)?.contains("One with no card from one of you") == true)
  }

  // MARK: the sentences

  @Test func theHeadlineNamesWhoLeads() throws {
    let up = HeadToHead.parse(try json(full))
    #expect(HeadToHeadCopy.headline(up) == "You lead 6–5.")

    let down = HeadToHead.parse(try json("""
    { "visible": true, "opponent": { "id": "\(opp)", "display_name": "Galen" },
      "record": { "wins": 5, "losses": 6, "ties": 0, "total": 11 }, "lead": "down", "facets": {} }
    """))
    #expect(HeadToHeadCopy.headline(down) == "Galen leads 6–5.")

    let even = HeadToHead.parse(try json("""
    { "visible": true, "opponent": { "id": "\(opp)", "display_name": "Galen" },
      "record": { "wins": 5, "losses": 5, "ties": 0, "total": 10 }, "lead": "even", "facets": {} }
    """))
    #expect(HeadToHeadCopy.headline(even) == "All square, 5–5.")
  }

  @Test func nothingDecidedMeansNoHeadlineAtAll() throws {
    let h = HeadToHead.parse(try json("""
    { "visible": true, "opponent": { "id": "\(opp)", "display_name": "Galen" },
      "record": { "wins": 0, "losses": 0, "ties": 0, "total": 2 }, "lead": "even",
      "facets": { "played_together": { "wins": 0, "losses": 0, "ties": 0, "meetings": 2, "unsettled": 2 } } }
    """))
    // L-44 · a record of nought is not a sentence. The empty state is.
    #expect(HeadToHeadCopy.headline(h) == nil)
    #expect(HeadToHeadCopy.personClause(h) == nil)
    let root = HeadToHeadCopy.empty("Galen")
    #expect(!root.doors.isEmpty)
    #expect(root.sub.contains("Galen"))
  }

  @Test func theStandfirstDropsEveryClauseItCannotProve() throws {
    let whole = HeadToHead.parse(try json(full))
    let s = try #require(HeadToHeadCopy.standfirst(whole))
    #expect(s.hasPrefix("Eleven meetings where you both played"))
    #expect(s.contains("going back to March"))
    #expect(s.contains("Galen has taken the last two."))

    // no `since`, no month clause; no streak, no run clause
    let bare = HeadToHead.parse(try json("""
    { "visible": true, "opponent": { "id": "\(opp)", "display_name": "Galen" },
      "record": { "wins": 1, "losses": 0, "ties": 0, "total": 1 }, "lead": "up", "facets": {} }
    """))
    let b = try #require(HeadToHeadCopy.standfirst(bare))
    #expect(!b.contains("going back"))
    #expect(!b.contains("taken the last"))
    #expect(b == "One meeting where you both played.")
  }

  @Test func aStreakOfOneIsNotAStreak() throws {
    let h = HeadToHead.parse(try json("""
    { "visible": true, "opponent": { "id": "\(opp)", "display_name": "Galen" },
      "record": { "wins": 1, "losses": 1, "ties": 0, "total": 2 }, "lead": "even",
      "streak": { "who": "me", "n": 1 }, "facets": {} }
    """))
    #expect(h.streak == nil)
    #expect(HeadToHeadCopy.standfirst(h)?.contains("taken the last") == false)
  }

  @Test func thePersonClauseIsTheOneTheCardBorrows() throws {
    let h = HeadToHead.parse(try json(full))
    #expect(HeadToHeadCopy.personClause(h) == "Galen has beaten you five times out of eleven.")

    let clean = HeadToHead.parse(try json("""
    { "visible": true, "opponent": { "id": "\(opp)", "display_name": "Galen" },
      "record": { "wins": 3, "losses": 0, "ties": 0, "total": 3 }, "lead": "up", "facets": {} }
    """))
    #expect(HeadToHeadCopy.personClause(clean) == "You have taken all three of them.")
  }

  // MARK: the gate and the fence

  @Test func anInvisibleCardCarriesNothing() throws {
    let h = HeadToHead.parse(try json("{ \"visible\": false }"))
    #expect(!h.visible)
    #expect(h.facets.isEmpty)
    #expect(h.record.total == 0)
    #expect(h.since == nil)
  }

  /// Wave 4's own rule: a read joins `namedReads` in the SAME commit as its
  /// migration, or every sentence it feeds renders nothing.
  @Test func headToHeadIsInsideTheStoryFence() {
    #expect(SeasonStoryCopy.namedReads.contains("head_to_head"))
  }

  @Test func theLastFiveKeepsItsVerdicts() throws {
    let h = HeadToHead.parse(try json(full))
    #expect(h.lastFive.count == 5)
    #expect(h.lastFive.map(\.won) == [false, false, true, true, nil])
    #expect(h.lastFive.first?.facet == .clashes)
  }

  /// The first cut of this page printed "Galen has won one title. Galen has
  /// beaten you five times out of eleven." — the same golfer opening two
  /// consecutive clauses, which reads as two facts about two people. A real
  /// screenshot caught it; this holds the fix.
  @Test func theNarrativeNamesTheGolferOnce() throws {
    let h = HeadToHead.parse(try json(full))
    let card = TourCard.parse(try json("""
    { "visible": true,
      "profile": { "id": "\(opp)", "display_name": "Galen", "is_me": false },
      "career": { "rounds": 42 },
      "case": [ { "kind": "league", "title": "Cup", "placement": "winner", "season_year": 2026 } ] }
    """))
    let line = try #require(HeadToHeadCopy.personNarrative(card: card, h2h: h))
    #expect(line == "Galen has won one title, and has beaten you five times out of eleven.")
    #expect(line.components(separatedBy: "Galen").count - 1 == 1)
  }

  @Test func theNarrativeDropsWhicheverClauseHasNoFact() throws {
    let h = HeadToHead.parse(try json(full))
    let noCase = TourCard.parse(try json("""
    { "visible": true, "profile": { "id": "\(opp)", "display_name": "Galen" }, "career": { "rounds": 3 } }
    """))
    #expect(HeadToHeadCopy.personNarrative(card: noCase, h2h: h)
            == "Galen has beaten you five times out of eleven.")
    // and with neither fact there is no sentence at all (L-44)
    #expect(HeadToHeadCopy.personNarrative(card: noCase, h2h: nil) == nil)
  }

  @Test func aDateIsNeverParsedAsAnInstant() throws {
    // L-07 · calendar dates ride as Strings and are read by parts
    let h = HeadToHead.parse(try json(full))
    #expect(h.since == "2026-03-14")
    #expect(HeadToHeadCopy.monthYear("2026-03-14") == "March")
    #expect(HeadToHeadCopy.monthYear("nonsense") == nil)
  }
}
