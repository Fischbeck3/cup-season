// Cup Season — the season's story ladder (D223, R-H).
//
// Four rules these tests exist to hold:
//   · the seven rungs fire IN ORDER, and each one only on its own condition
//   · rung 7 REACHES BACK (R-H) and every sentence it produces is computable
//     from a named read — the `source` fence, asserted rather than promised
//   · rung 7b says nothing has moved when even history finds nothing, and it
//     is still an honest sentence
//   · nothing is invented, nothing is inflated, and no rung manufactures a
//     stake: a run of one week is not a run, a week settled on Tuesday is not
//     an unsettled rivalry, and a payload with no facts renders no line

import Testing
import Foundation
@testable import CupSeasonKit

// MARK: - Fixtures

private func row(_ name: String, _ pts: Double, rank: Int, me: Bool = false, id: String? = nil,
                 counted: Int? = nil, left: Bool? = nil) -> SeasonStory.Row {
  SeasonStory.Row(id: id ?? name.lowercased(), name: name, points: pts, rank: rank,
                  rounds: nil, counted: counted, left: left, is_me: me)
}

private func payload(facts: SeasonStory.Facts,
                     table: [SeasonStory.Row] = [row("Galen", 31, rank: 1), row("You", 27, rank: 2, me: true)],
                     history: [SeasonStory.History] = [],
                     status: String = "active",
                     solo: Bool = true,
                     archive: [SeasonStory.Archive] = []) -> SeasonStory.Payload {
  SeasonStory.Payload(
    season: SeasonStory.Season(id: UUID(), league: "Fellas", number: 1, starts_on: "2026-07-20",
                               ends_on: "2027-01-18", status: status, finish: "cup_final",
                               structure: solo ? "solo" : "squads2", solo: solo, today: "2026-09-05"),
    facts: facts, history: history, table: table, archive: archive)
}

/// A Sunday, so a weekday in a sentence is a real weekday.
private let sunday = "2026-08-30T07:10:00.228+00:00"

// MARK: - The ladder, rung by rung

@Suite("The season's story — the seven-rung ladder")
struct SeasonStoryLadderTests {

  @Test("rung 1 · the lead changed hands this week, and it names the day")
  func rungOne() {
    let p = payload(facts: SeasonStory.Facts(
      week_no: 7, weeks_total: 26, weeks_left: 19, field: 2,
      leader: SeasonStory.Leader(name: "Jade", run_weeks: 1),
      runner_up: SeasonStory.Side(name: "You", points: 27), top_gap: 4,
      lead_flip: SeasonStory.Flip(week: 7, on: sunday, to: "Jade", to_id: "jade", first_time: true)))
    let line = SeasonStoryCopy.line(p)
    #expect(line?.rung == 1)
    #expect(line?.text == "The lead changed hands on Sunday. Jade has it for the first time.")
    #expect(line?.source == "standings_snapshots")
  }

  @Test("rung 1 · a leader who has had it before takes it BACK, not for the first time")
  func rungOneAgain() {
    let p = payload(facts: SeasonStory.Facts(
      week_no: 7, weeks_total: 26, field: 2,
      lead_flip: SeasonStory.Flip(week: 7, on: sunday, to: "Jade", to_id: "jade", first_time: false)))
    #expect(SeasonStoryCopy.line(p)?.text == "The lead changed hands on Sunday. Jade has it back.")
  }

  @Test("rung 1 · when the lead came to ME the sentence is mine")
  func rungOneMine() {
    let p = payload(facts: SeasonStory.Facts(
      week_no: 7, weeks_total: 26, field: 2,
      lead_flip: SeasonStory.Flip(week: 7, on: sunday, to: "You", to_id: "you", first_time: true)),
                    table: [row("You", 31, rank: 1, me: true, id: "you"), row("Galen", 27, rank: 2, id: "galen")])
    #expect(SeasonStoryCopy.line(p)?.text == "You took the lead on Sunday. For the first time.")
  }

  @Test("rung 1 · a flip six weeks ago is NOT this week's news — the ladder falls through")
  func rungOneStale() {
    let p = payload(facts: SeasonStory.Facts(
      week_no: 7, weeks_total: 26, weeks_left: 19, field: 2,
      leader: SeasonStory.Leader(name: "Galen", run_weeks: 4),
      runner_up: SeasonStory.Side(name: "You", points: 27), top_gap: 4,
      lead_flip: SeasonStory.Flip(week: 1, on: sunday, to: "Galen", to_id: "galen", first_time: true)))
    #expect(SeasonStoryCopy.line(p)?.rung == 2)
  }

  @Test("rung 2 · a run of four weeks, said out loud")
  func rungTwo() {
    let p = payload(facts: SeasonStory.Facts(
      week_no: 7, weeks_total: 26, weeks_left: 19, field: 2,
      leader: SeasonStory.Leader(name: "Galen", run_weeks: 4),
      runner_up: SeasonStory.Side(name: "You", points: 27), top_gap: 4))
    let line = SeasonStoryCopy.line(p)
    #expect(line?.rung == 2)
    #expect(line?.text == "Galen has led for four straight weeks.")
  }

  @Test("rung 2 · a run of two weeks is not a run — the ladder falls through")
  func rungTwoTooShort() {
    let p = payload(facts: SeasonStory.Facts(
      week_no: 7, weeks_total: 26, weeks_left: 19, field: 2,
      leader: SeasonStory.Leader(name: "Galen", run_weeks: 2),
      runner_up: SeasonStory.Side(name: "You", points: 27), top_gap: 9))
    #expect(SeasonStoryCopy.line(p)?.rung != 2)
  }

  @Test("rung 2 · a squad is a THEY, a golfer a she or a he")
  func rungTwoSquad() {
    let p = payload(facts: SeasonStory.Facts(
      week_no: 7, weeks_total: 26, weeks_left: 19, field: 4,
      leader: SeasonStory.Leader(name: "Mudsharks", run_weeks: 4),
      runner_up: SeasonStory.Side(name: "The Frost", points: 27), top_gap: 4), solo: false)
    #expect(SeasonStoryCopy.line(p)?.text == "Mudsharks have led for four straight weeks.")
  }

  @Test("rung 2 · my own run is mine")
  func rungTwoMine() {
    let p = payload(facts: SeasonStory.Facts(
      week_no: 7, weeks_total: 26, weeks_left: 19, field: 2,
      leader: SeasonStory.Leader(name: "You", run_weeks: 5, is_me: true),
      runner_up: SeasonStory.Side(name: "Jade", points: 10), top_gap: 28))
    #expect(SeasonStoryCopy.line(p)?.text == "You have led for five straight weeks.")
  }

  @Test("rung 3 · two points at the top, with the clock")
  func rungThree() {
    let p = payload(facts: SeasonStory.Facts(
      week_no: 7, weeks_total: 26, weeks_left: 6, field: 4,
      leader: SeasonStory.Leader(name: "Galen", run_weeks: 1),
      runner_up: SeasonStory.Side(name: "You", points: 29), top_gap: 2))
    let line = SeasonStoryCopy.line(p)
    #expect(line?.rung == 3)
    #expect(line?.text == "Two points separate the top two with six weeks to play.")
  }

  @Test("rung 3 · level at the top is level, never 'zero points separate'")
  func rungThreeLevel() {
    let p = payload(facts: SeasonStory.Facts(
      week_no: 7, weeks_total: 26, weeks_left: 6, field: 4,
      leader: SeasonStory.Leader(name: "Galen", run_weeks: 1),
      runner_up: SeasonStory.Side(name: "You", points: 31), top_gap: 0))
    #expect(SeasonStoryCopy.line(p)?.text == "The top two are level with six weeks to play.")
  }

  @Test("rung 4 · a squad closing half the gap has a plural verb; a golfer has a singular one")
  func rungFour() {
    let squads = payload(facts: SeasonStory.Facts(
      week_no: 7, weeks_total: 26, weeks_left: 9, field: 4,
      leader: SeasonStory.Leader(name: "Galen", run_weeks: 1),
      runner_up: SeasonStory.Side(name: "The Frost", points: 25), top_gap: 6,
      closer: SeasonStory.Closer(name: "The Frost", taken: 6)), solo: false)
    #expect(SeasonStoryCopy.line(squads)?.rung == 4)
    #expect(SeasonStoryCopy.line(squads)?.text == "The Frost have taken six off the lead in a fortnight.")

    let solo = payload(facts: SeasonStory.Facts(
      week_no: 7, weeks_total: 26, weeks_left: 9, field: 4,
      leader: SeasonStory.Leader(name: "Galen", run_weeks: 1),
      runner_up: SeasonStory.Side(name: "Jade", points: 25), top_gap: 6,
      closer: SeasonStory.Closer(name: "Jade", taken: 6)), solo: true)
    #expect(SeasonStoryCopy.line(solo)?.text == "Jade has taken six off the lead in a fortnight.")
  }

  @Test("rung 5 · the Final's clock, its seats and who is still live")
  func rungFive() {
    let p = payload(facts: SeasonStory.Facts(
      week_no: 20, weeks_total: 26, weeks_left: 6, field: 4,
      leader: SeasonStory.Leader(name: "Galen", run_weeks: 1),
      runner_up: SeasonStory.Side(name: "You", points: 25), top_gap: 6,
      final: SeasonStory.Final(opens_on: "2026-12-22", in_weeks: 3, seats: 2, still_live: 4)))
    let line = SeasonStoryCopy.line(p)
    #expect(line?.rung == 5)
    #expect(line?.text == "Three weeks until the Final. Two seats, four still live.")
    #expect(line?.source == "season_scenarios")
  }

  @Test("rung 5 · a Final sixteen weeks out is not news")
  func rungFiveFar() {
    let p = payload(facts: SeasonStory.Facts(
      week_no: 7, weeks_total: 26, weeks_left: 19, field: 2,
      leader: SeasonStory.Leader(name: "Galen", run_weeks: 1),
      runner_up: SeasonStory.Side(name: "You", points: 25), top_gap: 6,
      final: SeasonStory.Final(opens_on: "2026-12-22", in_weeks: 16, seats: 2, still_live: 2)))
    #expect(SeasonStoryCopy.line(p)?.rung != 5)
  }

  @Test("rung 6 · week one")
  func rungSix() {
    let p = payload(facts: SeasonStory.Facts(week_no: 1, weeks_total: 13, weeks_left: 12, field: 6))
    let line = SeasonStoryCopy.line(p)
    #expect(line?.rung == 6)
    #expect(line?.text == "Thirteen weeks. Clean cards, fragile egos.")
  }

  @Test("rung 0 · a wrapped season leads with how it ended")
  func wrapped() {
    let p = payload(facts: SeasonStory.Facts(week_no: 26, weeks_total: 26, weeks_left: 0, field: 2),
                    status: "complete",
                    archive: [SeasonStory.Archive(number: 1, champion: "Galen", is_current: true)])
    #expect(SeasonStoryCopy.line(p)?.text == "Galen took it.")
  }

  @Test("no facts at all · no line, rather than an empty one (L-44)")
  func noFacts() {
    #expect(SeasonStoryCopy.line(SeasonStory.Payload()) == nil)
  }
}

// MARK: - Rung 7 · the reach back, and its fence

@Suite("Rung 7 — reaching into history under an absolute fence (R-H)")
struct SeasonStoryHistoryTests {

  /// The quiet week: nothing this week, so the ladder looks further back.
  private var quiet: SeasonStory.Facts {
    SeasonStory.Facts(week_no: 7, weeks_total: 26, weeks_left: 19, field: 2,
                      leader: SeasonStory.Leader(name: "Galen", run_weeks: 1),
                      runner_up: SeasonStory.Side(name: "You", points: 27), top_gap: 9,
                      last_snapshot_on: sunday)
  }

  @Test("the unsettled week — computable from week_clashes and my_rivalries, and it names them")
  func unsettled() {
    let p = payload(facts: quiet, history: [
      SeasonStory.History(kind: "unsettled_week", source: "week_clashes", record_source: "my_rivalries",
                          opponent: "Galen", since: "2026-08-12", days: 24, wins: 5, losses: 6, ties: 0),
    ])
    let line = SeasonStoryCopy.line(p)
    #expect(line?.rung == 7)
    #expect(line?.text == "You and Galen have not settled a week since the 12th of August. Galen is 6–5 up all-time.")
    #expect(line?.source == "week_clashes")
    #expect(SeasonStoryCopy.namedReads.contains(line!.source))
  }

  @Test("the record is read from MY side, and level is level")
  func recordVoices() {
    func text(_ w: Int, _ l: Int) -> String? {
      SeasonStoryCopy.history(SeasonStory.History(kind: "unsettled_week", source: "week_clashes",
                                                  opponent: "Galen", since: "2026-08-12", days: 24,
                                                  wins: w, losses: l, ties: 0))
    }
    #expect(text(6, 5)?.hasSuffix("You are 6–5 up all-time.") == true)
    #expect(text(5, 6)?.hasSuffix("Galen is 6–5 up all-time.") == true)
    #expect(text(5, 5)?.hasSuffix("You are level at 5–5 all-time.") == true)
  }

  @Test("a week settled five days ago is not an unsettled rivalry — no manufactured stake")
  func tooRecent() {
    let p = payload(facts: quiet, history: [
      SeasonStory.History(kind: "unsettled_week", source: "week_clashes", opponent: "Jade",
                          since: "2026-08-31", days: 5, wins: 2, losses: 0, ties: 0),
    ])
    // The candidate is refused, so the ladder falls to 7b rather than
    // inventing drama out of last Sunday.
    #expect(SeasonStoryCopy.line(p)?.text == "Week seven of twenty-six. Nothing has moved since Sunday.")
  }

  @Test("my own run at my own place, from the snapshots")
  func myRun() {
    let p = payload(facts: quiet, history: [
      SeasonStory.History(kind: "my_run", source: "standings_snapshots", rank: 2, weeks: 4),
    ])
    #expect(SeasonStoryCopy.line(p)?.text == "Through Aug 30, you held 2nd for four straight weeks.")
  }

  @Test("a historical rank differing from the live table carries its own date")
  func myRunAfterMovement() {
    let p = payload(facts: quiet,
                    table: [row("You", 40, rank: 1, me: true), row("Galen", 31, rank: 2)],
                    history: [.init(kind: "my_run", source: "standings_snapshots", rank: 2, weeks: 4)])
    let line = SeasonStoryCopy.line(p)
    #expect(line?.rung == 7)
    #expect(line?.text == "Through Aug 30, you held 2nd for four straight weeks.")
    #expect(line?.source == "standings_snapshots")
  }

  @Test("a missing snapshot date stays explicitly historical, without inventing a date")
  func myRunWithoutDate() {
    let h = SeasonStory.History(kind: "my_run", source: "standings_snapshots", rank: 3, weeks: 2)
    for stamp: String? in [nil, "", "not-a-date", "2026-02-30", "2026-13-01"] {
      #expect(SeasonStoryCopy.history(h, lastSnapshotOn: stamp)
              == "Your weekly record includes two straight weeks in 3rd.")
    }
    #expect(SeasonStoryCopy.history(.init(kind: "my_run", source: "standings_snapshots", rank: 0, weeks: 3)) == nil)
  }

  @Test("the weekly record uses its calendar date across time zones and year boundaries")
  func myRunCalendarDate() {
    let h = SeasonStory.History(kind: "my_run", source: "standings_snapshots", rank: 2, weeks: 4)
    for zone in ["America/Phoenix", "Pacific/Honolulu", "Pacific/Auckland"] {
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = TimeZone(identifier: zone)!
      #expect(SeasonStoryCopy.history(h, lastSnapshotOn: "2026-12-31T23:59:00+00:00", calendar: calendar)
              == "Through Dec 31, you held 2nd for four straight weeks.")
    }
  }

  @Test("my best week, as a difference between two rows that exist")
  func bestWeek() {
    let p = payload(facts: quiet, history: [
      SeasonStory.History(kind: "my_best_week", source: "standings_snapshots", week: 5, points: 10),
    ])
    #expect(SeasonStoryCopy.line(p)?.text == "Your best week of the season is still week five — 10 points.")
  }

  @Test("THE FENCE · a candidate whose source is not a named read renders NOTHING")
  func theFence() {
    let invented = payload(facts: quiet, history: [
      SeasonStory.History(kind: "unsettled_week", source: "a_hunch", opponent: "Galen",
                          since: "2026-08-12", days: 24, wins: 5, losses: 6, ties: 0),
    ])
    #expect(SeasonStoryCopy.line(invented)?.rung == 7)
    #expect(SeasonStoryCopy.line(invented)?.text.contains("Galen") == false)
    #expect(SeasonStoryCopy.line(invented)?.source == "standings_snapshots")
    // and the whitelist is the whole of what may be counted over
    // wave 5 · R4 joined the fence in the same commit as its migration, which
    // is the rule this assertion enforces: a read that feeds a sentence is
    // named here or its sentences never reach a screen.
    #expect(SeasonStoryCopy.namedReads == ["standings_snapshots", "week_clashes", "my_rivalries",
                                           "posts", "season_scenarios", "head_to_head"])
  }

  @Test("a kind this build does not know renders nothing rather than a guess")
  func unknownKind() {
    #expect(SeasonStoryCopy.history(SeasonStory.History(kind: "vibes", source: "standings_snapshots")) == nil)
  }

  @Test("a run of one week is not a run, and a best week of zero is not a best week")
  func notInflated() {
    #expect(SeasonStoryCopy.history(SeasonStory.History(kind: "my_run", source: "standings_snapshots",
                                                        rank: 2, weeks: 1)) == nil)
    #expect(SeasonStoryCopy.history(SeasonStory.History(kind: "my_best_week", source: "standings_snapshots",
                                                        week: 5, points: 0)) == nil)
  }

  @Test("rung 7b · even history finds nothing, and the sentence is still true")
  func rung7b() {
    let p = payload(facts: quiet)
    let line = SeasonStoryCopy.line(p)
    #expect(line?.rung == 7)
    #expect(line?.text == "Week seven of twenty-six. Nothing has moved since Sunday.")
    #expect(line?.source == "standings_snapshots")
  }

  @Test("rung 7b with no snapshot at all says 'yet', not a weekday it cannot know")
  func rung7bNoClock() {
    let p = payload(facts: SeasonStory.Facts(week_no: 3, weeks_total: 13, weeks_left: 10, field: 2,
                                             leader: SeasonStory.Leader(name: "Galen", run_weeks: 1),
                                             runner_up: SeasonStory.Side(name: "You", points: 9), top_gap: 9))
    #expect(SeasonStoryCopy.line(p)?.text == "Week three of thirteen. Nothing has moved yet.")
  }
}

// MARK: - The arc, the dateline and the table's clause

@Suite("The arc, the dateline and the table's clause")
struct SeasonArcTests {

  @Test("the arc phrases its own facts and passes the server's sentence through")
  func arcLines() {
    #expect(SeasonStoryCopy.arc(SeasonStory.Arc(kind: "lead_change", source: "standings_snapshots",
                                                week: 5, subject: "Jade", other: "Galen"))
            == "Jade took the lead from Galen.")
    #expect(SeasonStoryCopy.arc(SeasonStory.Arc(kind: "clash", source: "week_clashes", week: 4,
                                                subject: "you", other: "Galen"))
            == "You took the week from Galen.")
    #expect(SeasonStoryCopy.arc(SeasonStory.Arc(kind: "clash", source: "week_clashes", week: 4,
                                                subject: nil, other: "Jade"))
            == "You and Jade halved the week.")
  }

  @Test("a scoreboard-voice post is eased into a sentence; a written one is left alone")
  func easedPosts() {
    #expect(SeasonStoryCopy.arc(SeasonStory.Arc(kind: "post", source: "posts",
                                                text: "JADE BROKE 90 FOR THE FIRST TIME — 86 GROSS"))
            == "Jade broke 90 for the first time — 86 gross")
    #expect(SeasonStoryCopy.arc(SeasonStory.Arc(kind: "post", source: "posts",
                                                text: "August is in the books. The ledger is posted."))
            == "August is in the books. The ledger is posted.")
  }

  @Test("an arc row whose source is not a named read renders nothing")
  func arcFence() {
    #expect(SeasonStoryCopy.arc(SeasonStory.Arc(kind: "post", source: "somewhere", text: "Trust me")) == nil)
  }

  @Test("the dateline carries the week ONCE, and only in a stage that has one")
  func dateline() {
    #expect(SeasonStoryCopy.dateline(name: "Fellas", stage: .season, week: 7, weeks: 26)
            == "FELLAS · WEEK 7 OF 26 · SEASON LIVE")
    #expect(SeasonStoryCopy.dateline(name: "Fellas", stage: .preseason, week: 1, weeks: 26)
            == "FELLAS · BEFORE FIRST TEE")
    #expect(SeasonStoryCopy.dateline(name: "Fellas", stage: .complete, week: 26, weeks: 26)
            == "FELLAS · SEASON COMPLETE")
  }

  @Test("the table's clause shows its work — the gap, and what is counting (L-01, L-44)")
  func rowClause() {
    let leader = row("Galen", 31, rank: 1)
    let mine = row("You", 27, rank: 2, me: true, counted: 2)
    #expect(SeasonStoryCopy.rowClause(mine, leader: leader, cap: 3) == "4 back · 2 of 3 counting this month")
    #expect(SeasonStoryCopy.rowClause(leader, leader: leader, cap: 3) == nil)
    // a leaver's row keeps its number and says what happened to it (D244)
    let gone = row("Jade", 9, rank: 3, left: true)
    #expect(SeasonStoryCopy.rowClause(gone, leader: leader, cap: 3) == "22 back · stopped scoring")
  }
}
