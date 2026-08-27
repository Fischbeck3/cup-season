import Testing
import Foundation
@testable import CupSeasonKit

private func row(id: UUID = UUID(), name: String = "Galen", playOn: String, mine: Bool, friend: Bool = false, league: Bool = false,
                 taggedMe: Bool = false, course: String? = "Papago GC", tee: String? = nil, tagged: [String]? = nil) -> ScheduledRound {
  Rpc.my_schedule.Row(id: id, profile_id: UUID(), display_name: name, marker: "saguaro", play_on: playOn, course_label: course, note: nil,
                      tee_time: tee, mine: mine, is_friend: friend, shared_league: league, tagged_names: tagged, tagged_me: taggedMe,
                      course_id: nil, rsvp_in: nil, my_rsvp: nil, comment_n: nil)
}

@Suite struct TeeSheetDateTests {
  @Test func nextSaturdayRollsAWholeWeekOnASaturday() {
    #expect(ScheduleDates.nextSaturday(from: "2026-08-27") == "2026-08-29")   // Thursday → this Saturday
    #expect(ScheduleDates.nextSaturday(from: "2026-08-29") == "2026-09-05")   // Saturday → the one after (`|| 7`)
    #expect(ScheduleDates.nextSaturday(from: "2026-08-30") == "2026-09-05")   // Sunday
  }

  @Test func teeTimeFormatsLikeTheWeb() {
    #expect(TeeTime.format("07:40:00") == "7:40a")
    #expect(TeeTime.format("07:40") == "7:40a")
    #expect(TeeTime.format("12:05:00") == "12:05p")
    #expect(TeeTime.format("00:15:00") == "12:15a")
    #expect(TeeTime.format(nil) == "" && TeeTime.format("") == "" && TeeTime.format("x") == "")
    #expect(TeeTime.chip(nil) == "Tee TBD" && TeeTime.chip("13:30:00") == "1:30p tee")
    #expect(TeeTime.hhmm(hour: 7, minute: 5) == "07:05")
  }

  @Test func whenLabels() {
    #expect(ScheduleDates.when("2026-08-27", today: "2026-08-27") == "TODAY")
    #expect(ScheduleDates.when("2026-08-28", today: "2026-08-27") == "TOMORROW")
    #expect(ScheduleDates.when("2026-08-29", today: "2026-08-27") == "SAT AUG 29")
    #expect(ScheduleDates.whenDays("2026-08-30", today: "2026-08-27") == "3 DAYS")
    #expect(ScheduleDates.whenIn("2026-08-30", today: "2026-08-27") == "IN 3 DAYS")
    #expect(ScheduleDates.whenLower("2026-08-29", today: "2026-08-27") == "sat")
    #expect(ScheduleDates.long("2026-08-29") == "Sat Aug 29")
  }
}

@Suite struct CalendarGridTests {
  @Test func monthMathThroughCSDate() {
    let aug = CalendarMonth(year: 2026, month: 8)
    #expect(aug.title == "AUG 2026")
    #expect(aug.daysInMonth == 31)
    #expect(aug.leadingBlanks == 6)             // Aug 1 2026 is a Saturday; Sunday-first grid
    #expect(aug.firstISO == "2026-08-01" && aug.lastISO == "2026-08-31")
    #expect(aug.next == CalendarMonth(year: 2026, month: 9))
    #expect(CalendarMonth(year: 2026, month: 12).next == CalendarMonth(year: 2027, month: 1))
    #expect(CalendarMonth(year: 2026, month: 1).prev == CalendarMonth(year: 2025, month: 12))
    #expect(CalendarMonth(year: 2028, month: 2).daysInMonth == 29)
    #expect(aug.day(of: "2026-08-14") == 14 && aug.day(of: "2026-09-01") == nil)
    #expect(aug.previousMonthName == "Jul" && CalendarMonth(year: 2026, month: 1).previousMonthName == "Dec")
    #expect(ScheduleDates.endOfMonth("2026-02-10") == "2026-02-28")
  }

  @Test func seasonDatesAndRoundsLandOnTheirDays() {
    let month = CalendarMonth(year: 2026, month: 9)
    let cur = UUID()
    let spans = [LeagueSpan(leagueId: cur, name: "PIGL", startsOn: "2026-05-03", endsOn: "2026-09-26", finish: "cup_final"),
                 LeagueSpan(leagueId: UUID(), name: "The Sunday Cup", startsOn: "2026-09-13", endsOn: "2027-01-10")]
    let rounds = [row(playOn: "2026-09-05", mine: true), row(name: "Marco", playOn: "2026-09-05", mine: false, league: true),
                  row(name: "Buddy", playOn: "2026-09-06", mine: false, friend: true)]   // pure buddy: Home, not the room
    let byDay = CalendarBuilder.items(month: month, schedule: rounds, spans: spans, current: cur)
    #expect(byDay[26]?.contains(.league(text: "PIGL — season ends, cup decided", gold: true)) == true)
    #expect(byDay[1]?.contains(.league(text: "Aug closes — floors & bonuses assessed", gold: false)) == true)
    #expect(byDay[6]?.contains(.league(text: "Week closes — snapshot recorded", gold: false)) == true)   // a Sunday inside the season
    #expect(byDay[6]?.contains(where: { if case .round = $0 { return true }; return false }) == false)
    #expect(byDay[13]?.contains(.league(text: "The Sunday Cup — first tee", gold: false)) == true)
    #expect(byDay[5]?.filter { if case .round = $0 { return true }; return false }.count == 2)
    // Cup Final begins = ends_on − 27 → Aug 30, outside September
    #expect(byDay.values.flatMap { $0 }.contains(.league(text: "PIGL — Cup Final begins", gold: true)) == false)
    let aug = CalendarBuilder.items(month: CalendarMonth(year: 2026, month: 8), schedule: [], spans: spans, current: cur)
    #expect(aug[30]?.contains(.league(text: "PIGL — Cup Final begins", gold: true)) == true)
    // the dot: a league mate's round glows gold
    #expect(byDay[5]?.map(\.dot).contains(.leagueMate) == true)
  }

  @Test func listAndWatchRowsAreScoped() {
    let rows = [row(playOn: "2026-08-20", mine: true), row(playOn: "2026-08-29", mine: true),
                row(name: "Marco", playOn: "2026-08-30", mine: false, league: true), row(name: "B", playOn: "2026-08-31", mine: false, friend: true)]
    let list = CalendarBuilder.listRows(month: CalendarMonth(year: 2026, month: 8), schedule: rows, today: "2026-08-27")
    #expect(list.map(\.play_on) == ["2026-08-29", "2026-08-30"])
    #expect(CalendarBuilder.watchRows(rows, today: "2026-08-27").map(\.display_name) == ["Marco"])
    #expect(CalendarBuilder.homeRounds(rows, today: "2026-08-27").count == 3)
  }
}

@Suite struct UpNextTests {
  @Test func theFourChipsInOrder() {
    let watch = [row(playOn: "2026-08-29", mine: true, course: "Encanto"), row(name: "Galen Ortiz", playOn: "2026-08-28", mine: false, friend: true)]
    let chips = UpNext.chips(watch: watch, invites: 1, requests: 1, hasMemberships: true, today: "2026-08-27")
    #expect(chips.map(\.k) == ["Next round", "Buddy's playing", "Needs you", "Month closes"])
    #expect(chips[0].v == "Encanto · in 2 days")
    #expect(chips[1].v == "Galen · tomorrow")
    #expect(chips[2].v == "2 invites")
    #expect(chips[3].v == "in 4 days")
  }

  @Test func hidesWhatIsNotComing() {
    #expect(UpNext.chips(watch: [], invites: 0, requests: 0, hasMemberships: false, today: "2026-08-27").isEmpty)
    let far = UpNext.chips(watch: [], invites: 1, requests: 0, hasMemberships: true, today: "2026-08-05")
    #expect(far.map(\.k) == ["Needs you"] && far[0].v == "1 invite")
    let last = UpNext.chips(watch: [], invites: 0, requests: 0, hasMemberships: true, today: "2026-08-31")
    #expect(last.first?.v == "today")
    // a tagged buddy's round is YOUR plan, not a "Buddy's playing" nudge
    let tagged = [row(name: "Galen", playOn: "2026-08-28", mine: false, friend: true, taggedMe: true)]
    #expect(UpNext.chips(watch: tagged, invites: 0, requests: 0, hasMemberships: false, today: "2026-08-27").isEmpty)
  }
}

@Suite struct TagAndCopyTests {
  @Test func sevenTagsMax() {
    #expect(TagRules.cap == 7)
    #expect(TagRules.capToast == "Seven tags max. It’s golf, not a scramble league")
  }

  @Test func covenantCopy() {
    let c = Covenant(.object(["name": .string("PIGL"), "buyin_cents": .number(5000), "preset": .string("standard"), "floor": .number(2), "finish": .string("points_table")]))!
    #expect(c.usd == 50 && c.buyinLine == "$50 / player · on the pot sheet")
    #expect(c.presetLine == "Standard" && c.floorLine == "2 rounds / mo" && c.finishLine == "Points table crowns it")
    #expect(c.joinLabel == "Join — I’m in for $50")
    #expect(Covenant(.null) == nil)
    let free = Covenant(.object(["name": .string("Free"), "buyin_cents": .number(0)]))!
    #expect(free.floorLine == nil && free.finishLine == "Cup Final · final 4 weeks")
  }

  @Test func joinIntentRoundTrips() {
    let d = UserDefaults(suiteName: "cs-test-join")!
    JoinIntent.clear(defaults: d)
    #expect(JoinIntent.pending(defaults: d) == nil)
    JoinIntent.store(" pigl2026 ", name: "PIGL", defaults: d)
    #expect(JoinIntent.pending(defaults: d)?.code == "PIGL2026")
    #expect(JoinIntent.pending(defaults: d)?.name == "PIGL")
    JoinIntent.clear(defaults: d)
    #expect(JoinIntent.pending(defaults: d) == nil)
    #expect(JoinIntent.code(from: URL(string: "https://cupseason.app/?join=abc123")!) == "ABC123")
    #expect(JoinIntent.code(from: URL(string: "https://cupseason.app/?claim=x")!) == nil)
  }

  @Test func inviteAndPersonCopy() {
    let i = Invite(id: UUID(), kind: "event", containerId: nil, containerName: "Desert Ryder", inviter: "Galen", startsOn: "2026-09-12")
    #expect(i.title == "Ryder invite" && i.subline == "from Galen · first tee 2026-09-12")
    #expect(i.detail == "A Ryder event — two teams, vs-index duels. Invited by Galen. First tee 2026-09-12.")
    let l = Invite(id: UUID(), kind: "league", containerId: nil, containerName: "PIGL", inviter: "a golfer", startsOn: nil)
    #expect(l.subline == "from a golfer" && l.detail == "A season-long league. Invited by a golfer")
    #expect(Rel("incoming").tag == "Wants to add you" && Rel("none").action == "Add" && Rel("incoming").action == "Accept" && Rel("friend").action == nil)
    let lists = BuddyLists.partition([
      Rpc.my_friends.Row(friendship_id: UUID(), profile_id: UUID(), handle: "a", display_name: "A", city: nil, marker: nil, index_current: nil, status: "pending", incoming: true),
      Rpc.my_friends.Row(friendship_id: UUID(), profile_id: UUID(), handle: "b", display_name: "B", city: nil, marker: nil, index_current: nil, status: "pending", incoming: false),
      Rpc.my_friends.Row(friendship_id: UUID(), profile_id: UUID(), handle: "c", display_name: "C", city: "Tempe", marker: nil, index_current: nil, status: "accepted", incoming: false),
    ])
    #expect(lists.requests.count == 1 && lists.requested.count == 1 && lists.buddies.count == 1)
    #expect(lists.buddies[0].subline == "@c · Tempe")
  }

  @Test func courseLabelsAndMerge() {
    #expect(CourseHit.label(club: "Papago", course: "Papago") == "Papago")
    #expect(CourseHit.label(club: "Troon North", course: "Monument") == "Troon North — Monument")
    let t = CourseTee(tee_name: "Blue", gender: "male", course_rating: 71.2, slope_rating: 131, number_of_holes: 18)
    let unrated = CourseTee(tee_name: "Red", gender: "female", course_rating: nil, slope_rating: nil, number_of_holes: 18)
    let a = CourseHit(id: "1", club: "Papago", course: nil, city: "Phoenix", state: "AZ", tees: [t, unrated])
    #expect(a.tees.count == 1 && a.subline == "Phoenix, AZ · 1 tee")
    let merged = ScheduleService.merge(local: [a], remote: [a, CourseHit(id: "2", label: "Encanto", place: "", tees: [t])])
    #expect(merged.map(\.id) == ["1", "2"])
  }

  @Test func weekLines() {
    let a = UUID(), b = UUID()
    let snaps = [WeekSnapshot(week_no: 1, standings: .object(["squads": .array([.object(["squad_id": .string(a.uuidString), "points": .number(12)]),
                                                                                 .object(["squad_id": .string(b.uuidString), "points": .number(12)])])])),
                 WeekSnapshot(week_no: 2, standings: .object(["squads": .array([.object(["squad_id": .string(a.uuidString), "points": .number(20)]),
                                                                                 .object(["squad_id": .string(b.uuidString), "points": .number(16)])])]))]
    let lines = WeekLine.build(snaps, squadNames: [a: "The Pines", b: "Dunes"])
    #expect(lines.map(\.week) == [2, 1])
    #expect(lines[0].text == "WK 2 · THE PINES LED · BY 4" && lines[0].points == "20 PTS")
    #expect(lines[1].text == "WK 1 · THE PINES LED · TIED AT THE TOP")
  }

  @Test func roundDetailAndWeather() {
    let id = UUID()
    let d = RoundDetail(.object(["id": .string(id.uuidString), "mine": .bool(false), "tagged_me": .bool(true), "play_on": .string("2026-08-29"),
                                 "course": .object(["name": .string("Papago"), "tee": .string("blue"), "rating": .number(71.2), "slope": .number(131), "par": .number(72)]),
                                 "rsvp": .array([.object(["name": .string("J"), "status": .string("in")]), .object(["name": .string("K"), "status": .null])]),
                                 "comments": .array([])]))!
    #expect(d.canRsvp && d.inCount == 1 && d.title == "Sat Aug 29")
    #expect(d.course?.meta == "BLUE · 71.2 / 131 · PAR 72")
    #expect(d.rsvp[1].label == "No reply")
    #expect(RoundDetail(.object(["id": .string(id.uuidString)]))?.courseName == "A round")
    let w = Weather(hi: 71, lo: 55, wind: 9, summary: "Clear", icon: "sun")
    #expect(w.line == "☀ 71° Clear · 9mph" && w.glance == "☀ 71° · 9mph")
  }

  @Test func rivalryTag() {
    let pid = UUID()
    let r = Rpc.my_rivalries.Row(opponent: pid, display_name: "Galen Ortiz", handle: nil, marker: nil, wins: 3, losses: 1, ties: 0, meetings: 4, lead: nil,
                                 duel_wins: nil, duel_losses: nil, duel_halves: nil, rivalry_name: "The Grudge")
    #expect(RivalryTag.of(pid, rivals: [r])?.text == "“The Grudge” · you lead 3–1")
    let d = Rpc.my_rivalries.Row(opponent: pid, display_name: "Galen Ortiz", handle: nil, marker: nil, wins: 0, losses: 0, ties: 0, meetings: 0, lead: nil,
                                 duel_wins: 0, duel_losses: 2, duel_halves: nil, rivalry_name: nil)
    #expect(RivalryTag.of(pid, rivals: [d])?.text == "Galen leads duels 2–0")
    #expect(RivalryTag.of(UUID(), rivals: [r]) == nil)
  }

  @Test func humanErrorPhrasings() {
    struct E: LocalizedError { let m: String; var errorDescription: String? { m } }
    #expect(HumanError.text(E(m: "Failed to fetch")) == "Connection hiccup — check your signal and try again.")
    #expect(HumanError.text(E(m: "only the host and tagged players can rsvp to this round")) == "Only the host and the players they tagged can RSVP.")
    #expect(HumanError.text(E(m: "boom"), prefix: "Could not join.") == "Could not join. Something went wrong — please try again.")
    #expect(JoinService.joinError(E(m: "invalid code")) == "No league with that code. Check with your Pro")
  }
}
