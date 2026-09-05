import Testing
import Foundation
@testable import CupSeasonKit

/// L-32, both halves, on the two destinations D222 created.
///
///   1 · every empty state ends in a NEXT MOVE
///   2 · a FAILED READ IS NEVER AN EMPTY ONE
///
/// The second is the one that keeps getting lost, and it is the expensive one:
/// "No buddies yet" over a failed `my_friends` sends a golfer off to re-add the
/// friends they already have.
@Suite struct EmptyRootTests {

  // MARK: - both roots end in a move

  @Test func everyEmptyRootEndsInANextMove() {
    for root in [CompeteRoot.empty(buddies: 0), CompeteRoot.empty(buddies: 5),
                 GolfersRoot.empty(), EmptyRoot.failedRead()] {
      #expect(!root.doors.isEmpty, Comment(rawValue: root.head))
      #expect(root.doors.allSatisfy { !$0.title.isEmpty })
      // A head that is a noun on its own is a label, not a sentence.
      #expect(root.head.hasSuffix(".") || root.head.hasSuffix("?"), Comment(rawValue: root.head))
      #expect(!root.sub.isEmpty)
    }
  }

  @Test func theDesignsWordsAreTheWords() {
    #expect(CompeteRoot.empty(buddies: 0).head == "Nothing running.")
    #expect(CompeteRoot.empty(buddies: 0).sub
            == "Your next competition starts here — a season, a weekend, or one guy you want to beat.")
    #expect(GolfersRoot.empty().head == "No buddies yet.")
    #expect(GolfersRoot.empty().doors.first == .findGolfers)
  }

  // MARK: - a failed read is its own state

  @Test func competeNeverDressesAFailedReadAsAnAbsence() {
    let nothing = CompeteRoot.List(seasons: [], moments: [], finished: [])
    let failed = CompeteRoot.state(list: nothing, loaded: true, readFailed: true, buddies: nil)
    let empty  = CompeteRoot.state(list: nothing, loaded: true, readFailed: false, buddies: nil)
    #expect(failed != empty)
    guard case .failed(let f) = failed else { Issue.record("a failed read must be .failed"); return }
    guard case .empty(let e) = empty else { Issue.record("nothing running must be .empty"); return }
    #expect(f.head != e.head)
    #expect(f.doors.contains(.retry))
    #expect(!e.doors.contains(.retry))
    // and a failed read outranks a load that has not finished
    guard case .failed = CompeteRoot.state(list: nothing, loaded: false, readFailed: true, buddies: nil) else {
      Issue.record("a failed read outranks .loading"); return
    }
  }

  @Test func golfersNeverDressesAFailedReadAsAnAbsence() {
    let failed = GolfersRoot.state(buddies: 0, requests: 0, loaded: true, readFailed: true)
    let empty  = GolfersRoot.state(buddies: 0, requests: 0, loaded: true, readFailed: false)
    #expect(failed != empty)
    guard case .failed(let f) = failed, case .empty(let e) = empty else {
      Issue.record("the two states are not the same value"); return
    }
    #expect(f.head == "Couldn’t load this.")
    #expect(e.head == "No buddies yet.")
    #expect(f.doors == [.retry])
  }

  @Test func aLoadInFlightIsNotAnAbsenceEither() {
    guard case .loading = GolfersRoot.state(buddies: 0, requests: 0, loaded: false, readFailed: false) else {
      Issue.record("an unfinished load is .loading, not .empty"); return
    }
    guard case .loading = CompeteRoot.state(list: CompeteRoot.List(seasons: [], moments: [], finished: []),
                                            loaded: false, readFailed: false, buddies: nil) else {
      Issue.record("an unfinished load is .loading, not .empty"); return
    }
  }

  // MARK: - the one true fact, and the door that changes with it

  @Test func theFactIsOmittedRatherThanGuessed() {
    // With buddies it is real and is used…
    let withBuddies = CompeteRoot.empty(buddies: 5)
    #expect(withBuddies.fact == "5 buddies, and none of you is playing for anything.")
    #expect(withBuddies.doors == [.startSomething, .joinWithCode])
    #expect(CompeteRoot.empty(buddies: 1).fact == "1 buddy, and none of you is playing for anything.")
    // …with none, it is not written at all, and the second door becomes the
    // one that is any use to somebody nobody has sent a code to.
    let alone = CompeteRoot.empty(buddies: 0)
    #expect(alone.fact == nil)
    #expect(alone.doors == [.startSomething, .findGolfers])
    // A read that could not answer is the same as no fact — never a zero.
    #expect(CompeteRoot.empty(buddies: nil).fact == nil)
  }

  /// R-G's contacts door is NOT offered before the mechanic exists. A door
  /// that does not open is the one thing not permitted (L-32/L-44) and this is
  /// the wave that un-gated the Major for exactly that reason.
  @Test func golfersDoesNotSellTheContactsDoorYet() {
    let titles = GolfersRoot.empty().doors.map(\.title)
    #expect(!titles.contains { $0.lowercased().contains("your friends") })
    #expect(titles == ["Find golfers", "Text someone a link"])
  }

  /// A pending request IS somebody in the tab, even at zero buddies — the
  /// requests section is the head of the list and it has something to show.
  @Test func aPendingRequestIsNotAnEmptyTab() {
    guard case .list = GolfersRoot.state(buddies: 0, requests: 2, loaded: true, readFailed: false) else {
      Issue.record("a request in hand is a list, not an absence"); return
    }
  }

  /// A shelf of finished seasons is still "nothing running" — the question the
  /// empty root asks is what you are playing for NOW.
  @Test func finishedSeasonsDoNotCountAsRunning() {
    let done = CompeteRoot.Row(id: "league:x", kind: .season, eyebrow: "SEASON 1",
                               title: "The Dew Sweepers", sub: "Mike took it", clock: nil)
    let list = CompeteRoot.List(seasons: [], moments: [], finished: [done])
    #expect(list.nothingRunning)
    #expect(!list.isEmpty)
    guard case .empty = CompeteRoot.state(list: list, loaded: true, readFailed: false, buddies: nil) else {
      Issue.record("finished-only is still an empty root"); return
    }
  }
}

/// The peer list's own two rules (IA §6.1): nearest clock first, and finished
/// folded rather than dropped. The second is where `HomeMode.pool`'s erasure
/// died — it dropped a wrapped membership the moment a live one existed, a
/// client decision with no log entry behind it.
@Suite struct CompeteListTests {

  private func row(_ id: String, clock: Int?) -> CompeteRoot.Row {
    CompeteRoot.Row(id: id, kind: .season, eyebrow: "", title: id, sub: "", clock: clock)
  }

  @Test func nearestClockFirst() {
    let out = CompeteRoot.sorted([row("d", clock: 9), row("a", clock: 0), row("c", clock: 4)])
    #expect(out.map(\.id) == ["a", "c", "d"])
  }

  @Test func aRowWithNoClockGoesToTheBackInArrivalOrder() {
    let out = CompeteRoot.sorted([row("none1", clock: nil), row("soon", clock: 2),
                                  row("none2", clock: nil), row("later", clock: 30)])
    #expect(out.map(\.id) == ["soon", "later", "none1", "none2"])
  }

  /// Swift's sort is not stable, and a list that reorders itself between two
  /// identical loads is a list nobody can point at.
  @Test func equalClocksKeepTheirOrderEveryTime() {
    let input = (0..<12).map { row("r\($0)", clock: 3) }
    for _ in 0..<20 { #expect(CompeteRoot.sorted(input).map(\.id) == input.map(\.id)) }
  }

  @Test func aPlanNamesWhoIsOnItAndCountsNoSeats() {
    // IA §8.4 rule 1: no seat count, anywhere — `scheduled_rounds` has no
    // capacity column and a printed one would count nothing (L-44).
    let none = CompeteRoot.planLine(plan(tagged: [], tee: "07:10:00"))
    #expect(none == "Your tee time, 7:10.")
    #expect(CompeteRoot.planLine(plan(tagged: ["Galen"])) == "You and Galen.")
    #expect(CompeteRoot.planLine(plan(tagged: ["Galen", "Jade", "Dev"])) == "You, Galen, Jade and Dev.")
    for line in [none, CompeteRoot.planLine(plan(tagged: ["Galen"]))] {
      #expect(!line.lowercased().contains("seat"))
    }
  }

  /// Seen on a real account before it was fixed: `my_schedule.tagged_names`
  /// carries the VIEWER on a round a buddy booked with them, so the sentence
  /// read "You and Jerecho Fischbeck." — the same person, twice, one of them by
  /// name. My own name comes out, and a round I do not own names its host.
  @Test func aPlanNeverNamesTheViewerTwice() {
    #expect(CompeteRoot.planLine(plan(tagged: ["Jerecho Fischbeck", "Galen"]), myName: "Jerecho Fischbeck")
            == "You and Galen.")
    #expect(CompeteRoot.planLine(plan(tagged: ["Jerecho"]), myName: "Jerecho Fischbeck")
            == "Your tee time, 7:10." || CompeteRoot.planLine(plan(tagged: ["Jerecho"]), myName: "Jerecho Fischbeck") == "Yours, so far.")
    // Somebody else's round: the host is the fact that makes it mine at all.
    #expect(CompeteRoot.planLine(plan(tagged: ["Jerecho Fischbeck"], mine: false, host: "Galen Ross"), myName: "Jerecho Fischbeck")
            == "Galen’s round. You’re on it.")
    #expect(CompeteRoot.planLine(plan(tagged: ["Jerecho Fischbeck", "Jade", "Dev"], mine: false, host: "Galen Ross"), myName: "Jerecho Fischbeck")
            == "Galen’s round. You, Jade and Dev.")
  }

  private func plan(tagged: [String], tee: String? = "07:10:00", mine: Bool = true, host: String? = nil) -> ScheduledRound {
    let json = """
    {"id":"\(UUID().uuidString)","play_on":"2026-09-12","course_label":"Papago",
     "tee_time":\(tee.map { "\"\($0)\"" } ?? "null"),"mine":\(mine),
     "display_name":\(host.map { "\"\($0)\"" } ?? "null"),
     "tagged_names":[\(tagged.map { "\"\($0)\"" }.joined(separator: ","))]}
    """
    return try! JSONDecoder().decode(ScheduledRound.self, from: Data(json.utf8))
  }

  /// L-34 on the peer row: the eyebrow carries the week, so the sentence under
  /// it must not. One producer, two grains.
  @Test func theSeasonRowDoesNotSayTheWeekTwice() {
    let m = try! JSONDecoder().decode(Me.Membership.self, from: Data("""
    {"league_id":"\(UUID().uuidString)","name":"The Fellas","phase":"season","role":"member",
     "member_id":"\(UUID().uuidString)",
     "season":{"id":"\(UUID().uuidString)","number":1,"starts_on":"2026-07-20","ends_on":"2027-01-17",
               "status":"active","week_no":7,"weeks_total":26},
     "standing":{"rank":1,"of":2,"points":31}}
    """.utf8))
    let withWeek = SeasonFacts.seasonLine(m, today: "2026-09-05")
    let without = SeasonFacts.seasonLine(m, week: false, today: "2026-09-05")
    #expect(withWeek.hasPrefix("Week 7 of 26"))
    #expect(!without.lowercased().contains("week"))
    #expect(without.hasPrefix("1st of 2"))
    #expect(withWeek.hasSuffix(without))
  }
}
