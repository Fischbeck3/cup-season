import Testing
import Foundation
@testable import CupSeasonKit

/// **D237's GATE, walked.** The entry's own condition, and the owner's:
///
///   > Nobody has ever seen the Ryder room in LIVE or COMPLETE, which is the
///   > entire life of a callout. Walk the reviewer seed's "The Grudge" through
///   > a live and a completed session before committing.
///
/// The walk was done three ways: the room opened on a simulator against prod
/// (it refuses — The Grudge belongs to the reviewer's crew and `events` RLS is
/// working, which is the right answer and not the finding); the seed's real
/// rows were read out of prod (`complete`, three closed sessions, nine duels,
/// **Red 5 – Blue 4**); and those numbers are walked through the room's OWN
/// producers here, in both states, beside a field of two.
///
/// **What the walk found, and it changed the build.** The Ryder room's grammar
/// is written for a multi-week series between two SIDES. At a field of two and
/// one session it says *"Live · wk 1/1"* — a countdown over a thing that is one
/// week long by construction — and, at the end, *"FINAL · 1–0"* between two
/// TEAMS that happen to be two men's first names. Both are true and neither is
/// what two golfers who bet on Saturday are owed. So a callout does not land
/// there: `CalloutCopy` owns every sentence a field of two ever reads, and
/// `CalloutShape.isCallout` is the one predicate that routes it.
@Suite struct CalloutGateTests {

  // MARK: - the fixture: The Grudge's real numbers, out of prod

  private static func room(sessions: Int, closed: Int, status: String,
                           aName: String, bName: String, aPts: Double, bPts: Double,
                           perSide: Int, winner: Int? = nil) -> EventRoom {
    let ev = UUID()
    let ta = EventTeam(id: UUID(), slot: 0, name: aName, color: 0)
    let tb = EventTeam(id: UUID(), slot: 1, name: bName, color: 1)
    var players: [EventPlayer] = []
    for side in [ta, tb] {
      for i in 0..<perSide {
        players.append(EventPlayer(id: UUID(), profileId: UUID(), teamId: side.id,
                                   role: i == 0 ? "captain" : "player", seed: i, name: "G\(i)"))
      }
    }
    var rows: [EventSession] = []
    for n in 1...sessions {
      let st: String = n <= closed ? "closed" : (n == closed + 1 ? "open" : "upcoming")
      rows.append(EventSession(id: UUID(), session_no: n, opens_on: "2026-08-09",
                               closes_on: "2026-08-15", status: st))
    }
    let win: UUID? = winner == nil ? nil : (winner! == 0 ? ta.id : tb.id)
    let row = EventRow(id: ev, name: "The Grudge", created_by: UUID(), league_id: nil,
                       kind: "ryder", status: status, starts_on: "2026-08-09",
                       session_count: sessions, session_weeks: 1, draw_rule: "team_pvi",
                       winner_team_id: win)
    var r = EventRoom(event: row, teams: [ta, tb], players: players, sessions: rows, duels: [])
    r.scoreboard[ta.id] = aPts
    r.scoreboard[tb.id] = bPts
    return r
  }

  /// COMPLETE — the seed's own figures, read from prod 2026-09-05.
  private static var grudgeComplete: EventRoom {
    room(sessions: 3, closed: 3, status: "complete", aName: "Red", bName: "Blue",
         aPts: 5, bPts: 4, perSide: 3, winner: 0)
  }
  /// LIVE — the same event, one week in.
  private static var grudgeLive: EventRoom {
    room(sessions: 3, closed: 1, status: "live", aName: "Red", bName: "Blue",
         aPts: 2, bPts: 1, perSide: 3)
  }

  // MARK: - the walk: what the room says in both states

  @Test func theGrudgeReadsHonestlyInBothStates() {
    let live = Self.grudgeLive, done = Self.grudgeComplete
    // LIVE · a real countdown over a real three-week series
    #expect(RyderMath.statusChip(live) == "Live · week 2 of 3")
    #expect(RyderMath.clinchLine(live) == "First to 5. Red need 3, Blue need 4.")
    // COMPLETE · the cup, and the final score
    #expect(RyderMath.statusChip(done) == "Red take the cup")
    #expect(RyderMath.clinchLine(done) == "Final. Red took it 5–4.")
    // and the clinch arithmetic is the seed's own: 3 a side × 3 weeks = 9, first to 5
    let t = RyderMath.target(live)
    #expect(t.pairings == 3 && t.points == 9 && t.clinch == 5)
  }

  // MARK: - the finding: the same room over a FIELD OF TWO

  /// The whole life of a callout, run through the Ryder room's producers. Every
  /// sentence is TRUE. Not one of them is what two buddies who bet on Saturday
  /// are owed — which is why the callout has its own copy.
  @Test func theRyderRoomIsWrongForAFieldOfTwo() {
    let open = Self.room(sessions: 1, closed: 0, status: "live", aName: "Jerecho", bName: "Galen",
                         aPts: 0, bPts: 0, perSide: 1)
    let settled = Self.room(sessions: 1, closed: 1, status: "complete", aName: "Jerecho", bName: "Galen",
                            aPts: 1, bPts: 0, perSide: 1, winner: 0)

    // 1 · a countdown over a thing that is one week long by construction
    #expect(RyderMath.statusChip(open) == "Live · week 1 of 1")
    // 2 · a "first to" over a single point
    #expect(RyderMath.clinchLine(open) == "First to 1. Jerecho need 1, Galen need 1.")
    // 3 · a CUP, and a series score, between two men
    #expect(RyderMath.statusChip(settled) == "Jerecho take the cup")
    #expect(RyderMath.clinchLine(settled) == "Final. Jerecho took it 1–0.")
    // 4 · and the rule sentence talks about pairing "everyone"
    #expect(RyderMath.ruleSentence(RyderMath.target(open)).contains("pairs everyone"))
  }

  /// So the routing predicate is load-bearing, and it is the gate's own output.
  @Test func aCalloutIsRoutedAwayFromTheRyderRoom() {
    #expect(CalloutShape.isCallout(sessionCount: 1, leagueId: nil, field: 2))
    #expect(!CalloutShape.isCallout(sessionCount: 3, leagueId: nil, field: 6))   // The Grudge
  }

  /// And what a callout says instead — the same two moments, in its own words.
  @Test func theCalloutSaysItsOwnSentencesInBothStates() {
    #expect(CalloutCopy.openLine(closesOn: "2026-09-13") == "Best round by Sun Sep 13 takes it.")
    #expect(CalloutCopy.youTookIt(mine: 2.1, theirs: 0.4) == "You took it — +2.1 to his +0.4.")
    #expect(CalloutCopy.allSquare == "All square. Nobody buys.")
    // no cup, no series, no week count — not one of them exists here
    for s in [CalloutCopy.openLine(closesOn: "2026-09-13"),
              CalloutCopy.youTookIt(mine: 2.1, theirs: 0.4), CalloutCopy.allSquare] {
      #expect(!s.lowercased().contains("cup"))
      #expect(!s.lowercased().contains("wk "))
      #expect(!s.lowercased().contains("series"))
    }
  }
}
