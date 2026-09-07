// Cup Season — the ME strip's producer (D236, IOS-029a).
//
// The four rules these tests exist to hold:
//   · the four facts, in order, and no fifth
//   · a fact with NO READ renders nothing rather than a guess (L-44)
//   · the suppress set is honoured by whatever renders below (L-34)
//   · a $0 league shows no pot surface at all, and the unpaid line is derived
//     only from MY own row (D70, D23, L-10)
// plus the AX3 acceptance string — the rank-≥3 season row, which is the longest
// string the strip can produce.

import Testing
import Foundation
@testable import CupSeasonKit

// MARK: - Fixtures

private let me = UUID()

private func profile(index: Double? = 12.4, source: String? = "app", rounds: Int? = 9,
                     lastOn: String? = "2026-09-05", lastGross: Int? = 78,   // Sat, three days back
                     lastId: UUID? = UUID()) -> Me.Profile {
  Me.Profile(id: me, display_name: "Jerecho", handle: "jer", marker: "saguaro", city: "Tempe",
             home_course: "Papago", index_current: index, index_source: source, photo_path: nil,
             rounds_count: rounds, member_since: nil, is_founder: nil,
             last_round_on: lastOn, last_gross: lastGross, last_round_id: lastId, days_since_round: 1)
}

private func season(starts: String = "2026-07-05", ends: String = "2027-01-03", status: String = "active",
                    week: Int? = 9, weeks: Int? = 26, weekEnds: String? = "2026-09-13",
                    finalOpens: String? = "2026-12-07") -> Me.Season {
  Me.Season(id: UUID(), number: 3, starts_on: starts, ends_on: ends, status: status, timezone: "America/Phoenix",
            grace_hours: nil, champion_squad_id: nil, champion_member_id: nil, points_king_member_id: nil,
            tiebreak_rung: nil, week_no: week, weeks_total: weeks, week_ends_on: weekEnds,
            days_to_first_tee: nil, days_left: 120, final_opens_on: finalOpens)
}

private func standing(rank: Int, of: Int, points: Double, leader: String? = nil, leaderGap: Double? = nil,
                      up: (String, Double)? = nil, down: (String, Double)? = nil) -> Me.Standing {
  Me.Standing(rank: rank, of: of, points: points, prev_rank: nil, leader_squad_id: nil, leader_points: nil,
              gap_to_leader: leaderGap, gap_to_next: up.map { $0.1 - points },
              leader_name: leader, runner_up_name: nil, runner_up_points: nil, seed: nil, finalists: nil,
              next_up: up.map { Me.Standing.Neighbour(name: $0.0, points: $0.1) },
              next_down: down.map { Me.Standing.Neighbour(name: $0.0, points: $0.1) })
}

private func membership(name: String = "Fellas", stake: Int = 5000, paid: Bool? = false, phase: String = "season",
                        structure: String = "solo", finish: String = "cup_final",
                        season s: Me.Season? = season(), standing st: Me.Standing? = nil,
                        squad: Me.Squad? = nil, due: String? = nil) -> Me.Membership {
  Me.Membership(
    league_id: UUID(), name: name, code: "ABCD", phase: phase, sandbox: false, role: "member",
    member_id: UUID(), marker: "saguaro", commissioner_name: "Galen Ortiz",
    settings: Me.Settings(structure: structure, preset: nil, counting_cap: 4, participation_floor: 2,
                          floor_penalty: nil, handicap_allowance: 95, buyin_cents: stake,
                          payout_champ: 60, payout_runnerup: 25, payout_king: 15, finish: finish, locked_at: nil),
    season: s, squad: squad, standing: st, pulse: nil,
    buy_in: stake > 0 ? Me.BuyIn(paid: paid, note: "Venmo @ray-o", due_on: due, players: 8, paid_count: 6,
                                 collected_cents: 30000) : nil,
    roster: 8, members: 8, pro_name: "Galen")
}

private func plan(_ playOn: String, tee: String? = "07:10:00", course: String? = "Gold Canyon",
                  mine: Bool? = true, rsvp: String? = "in") -> ScheduledRound {
  var json: [String: Any] = [
    "id": UUID().uuidString, "profile_id": me.uuidString, "display_name": "Jerecho", "marker": "saguaro",
    "play_on": playOn, "rsvp_in": 2,
  ]
  if let course { json["course_label"] = course }
  if let tee { json["tee_time"] = tee }
  if let mine { json["mine"] = mine }
  if let rsvp { json["my_rsvp"] = rsvp }
  let data = try! JSONSerialization.data(withJSONObject: json)
  return try! JSONDecoder().decode(ScheduledRound.self, from: data)
}

/// A Tuesday, three days after the fixture's last round and four before its
/// next one — so the strip's weekday tokens are real weekdays, not a coincidence.
private let today = "2026-09-08"

// MARK: - The four facts

@Suite struct MeStripSlotTests {

  @Test func fourFactsInOrder() {
    let m = Me(profile: profile(), memberships: [membership(standing: standing(rank: 2, of: 8, points: 27))])
    let s = MeStripCopy.make(m, upcoming: [plan("2026-09-12")], today: today)
    #expect(s.slots.map(\.fact) == [.myNumber, .myLastRound, .myNextRound, .myMoney])
    // non-negotiable 8 names the three money words exactly, and `YOU STILL
    // OWE` was a fourth. The *still* lives in `SeasonFacts.owe`'s sentence.
    #expect(s.slots.map(\.label) == ["YOUR NUMBER", "LAST", "NEXT", "YOU OWE"])
    // F-17 · every slot is DATUM over NOUN: the value is a figure, never a
    // figure with a word welded on ("$75 YOU" over "STILL OWE").
    #expect(s.slots.allSatisfy { !$0.value.contains(" YOU") })
    #expect(s.slots.map(\.value) == ["12.4", "78 SAT", "SAT 7:10", "$50"])
  }

  /// L-01 · every figure taps to its receipt. A slot with no door is a number
  /// a golfer cannot check.
  @Test func everySlotHasItsOwnDoor() {
    let rid = UUID()
    let mem = membership(standing: standing(rank: 2, of: 8, points: 27))
    let up = plan("2026-09-12")
    let s = MeStripCopy.make(Me(profile: profile(lastId: rid), memberships: [mem]), upcoming: [up], today: today)
    #expect(s.slots.map(\.door) == [.yourCard, .receipt(rid), .plan(up.id!), .pot(mem.league_id)])
  }

  // L-44 · A FACT WITH NO READ RENDERS NOTHING. Not a dash, not a zero, not a
  // guess. This is the deploy-skew case: the client is ahead of the migration.
  @Test func aFactWithNoReadRendersNothing() {
    let p = Me.Profile(id: me, display_name: "Jerecho", handle: "jer", marker: "saguaro", city: nil,
                       home_course: nil, index_current: 12.4, index_source: "app", photo_path: nil,
                       rounds_count: 9, member_since: nil, is_founder: nil)   // v2: no last_round_on
    let s = MeStripCopy.make(Me(profile: p), upcoming: [], today: today)
    // Nine rounds posted, but this payload cannot say which was last — so the
    // slot is absent. "NO ROUNDS YET" would be a lie and "—" would be a guess.
    #expect(s.slots.map(\.fact) == [.myNumber, .myNextRound])
    #expect(!s.slots.contains { $0.value.contains("NO ROUNDS YET") })
  }

  /// The three empty states are still BUILT, and still carry their doors —
  /// asserted on the producers, because the assembled strip now declines to
  /// render a row in which all three are all there is (`MeStripPlaceholderTests`).
  /// Each is right the moment one real fact stands beside it.
  @Test func aKnownZeroIsAnEmptyStateWithADoor() {
    let p = profile(index: nil, source: nil, rounds: 0, lastOn: nil, lastGross: nil, lastId: nil)
    let number = MeStripCopy.numberSlot(p)
    let last = MeStripCopy.lastSlot(p, today: today, calendar: .current)
    let next = MeStripCopy.nextSlot([], today: today, calendar: .current)
    #expect([number, last, next].compactMap { $0?.value } == ["—", "NO ROUNDS YET", "PLAN ONE"])
    #expect([number, last, next].compactMap { $0?.label } == ["BUILDING", "LAST", "NEXT"])
    #expect(last?.door == .composer)
    #expect(next?.door == .declare)
    #expect([number, last, next].compactMap { $0?.isPlaceholder } == [true, true, true])
  }

  @Test func underThreeRoundsTheNumberIsBuilding() {
    let p = profile(index: nil, source: nil, rounds: 2)
    let s = MeStripCopy.make(Me(profile: p), upcoming: [], today: today)
    #expect(s.slots[0].value == "2 OF 3")
    #expect(s.slots[0].label == "BUILDING")
  }

  /// The `STARTER` label is reserved, not yet issued: nothing writes
  /// `index_source = 'starter'` until D247 ships. It exists so that the day a
  /// starter figure appears it is never dressed as an established index (L-14).
  @Test func aStarterIsLabelledStarterAndNeverYourNumber() {
    let p = profile(index: 13.0, source: "starter")
    let s = MeStripCopy.make(Me(profile: p), upcoming: [], today: today)
    #expect(s.slots[0].label == "STARTER")
    #expect(s.slots[0].value == "13.0")
  }

  @Test func noPlanOffersTheDeclareSheetAndAnUnreadSheetOffersNothing() {
    let m = Me(profile: profile())
    #expect(MeStripCopy.make(m, upcoming: [], today: today).slots.contains { $0.value == "PLAN ONE" })
    // nil = "the tee sheet is not known", which is not the same as "no plan"
    #expect(!MeStripCopy.make(m, upcoming: nil, today: today).slots.contains { $0.fact == .myNextRound })
  }

  /// SA-4 · `scheduled_rounds.tee_time` is nullable and real plans in prod have
  /// none. The slot names the course instead; it never guesses a tee time.
  @Test func aPlanWithNoTeeTimeNamesItsCourse() {
    let s = MeStripCopy.make(Me(profile: profile()), upcoming: [plan("2026-09-14", tee: nil)], today: today)
    #expect(s.slots.first { $0.fact == .myNextRound }?.value == "MON · GOLD CANYON")
  }

  @Test func aPlanIDeclinedIsNotMyNextRound() {
    let s = MeStripCopy.make(Me(profile: profile()),
                             upcoming: [plan("2026-09-10", rsvp: "out"), plan("2026-09-12")], today: today)
    #expect(s.slots.first { $0.fact == .myNextRound }?.value == "SAT 7:10")
  }

  @Test func anOldRoundSaysItsDateRatherThanAWeekday() {
    let s = MeStripCopy.make(Me(profile: profile(lastOn: "2026-08-21", lastGross: 88)), upcoming: [], today: today)
    #expect(s.slots.first { $0.fact == .myLastRound }?.value == "88 AUG 21")
  }

  /// L-22 · `days_since_round` is decoded for a ranker and NEVER rendered.
  /// "Nine days since you played" is the shame line the wall forbids.
  @Test func daysSinceIsNeverRendered() {
    let s = MeStripCopy.make(Me(profile: profile()), upcoming: [], today: today)
    for slot in s.slots {
      #expect(!slot.value.lowercased().contains("day"))
      #expect(!slot.voiceOver.lowercased().contains("days since"))
    }
  }
}

// MARK: - The money (D70, D23, L-10)

@Suite struct MeStripMoneyTests {

  @Test func aZeroDollarLeagueShowsNoPotSurfaceAtAll() {
    let m = Me(profile: profile(), memberships: [membership(stake: 0, paid: nil,
                                                            standing: standing(rank: 1, of: 2, points: 30))])
    let s = MeStripCopy.make(m, upcoming: [], today: today)
    #expect(!s.slots.contains { $0.fact == .myMoney })
    #expect(!s.suppress.contains(.myMoney))
    // and nothing anywhere in the strip prints a dollar sign
    #expect(!s.slots.contains { $0.value.contains("$") })
    #expect(s.seasonRow.map { !$0.text.contains("$") } ?? true)
  }

  @Test func aPaidStakeShowsNothing() {
    let m = Me(profile: profile(), memberships: [membership(paid: true)])
    #expect(!MeStripCopy.make(m, upcoming: [], today: today).slots.contains { $0.fact == .myMoney })
  }

  /// D112 · the books open at lock. In `setup` the Pro is still writing the
  /// bylaws, the stake can change and the roster is one — nothing is owed.
  @Test func setupOwesNothing() {
    let m = Me(profile: profile(), memberships: [membership(phase: "setup", season: nil)])
    #expect(!MeStripCopy.make(m, upcoming: [], today: today).slots.contains { $0.fact == .myMoney })
  }

  /// D23 · the unpaid line is SELF-ONLY. It is derived from `buy_in.paid`,
  /// which is the caller's own row, and it never prints anyone else's state —
  /// the payload carries `paid_count: 6` of `players: 8` and the strip says
  /// nothing about the other two.
  @Test func theUnpaidStateIsSelfOnly() {
    let m = Me(profile: profile(), memberships: [membership()])
    let slot = MeStripCopy.make(m, upcoming: [], today: today).slots.first { $0.fact == .myMoney }
    #expect(slot?.value == "$50")
    #expect(slot?.value.contains("6") == false)
    #expect(slot?.value.contains("still owe") == false)
    #expect(slot?.voiceOver == "you still owe $50")
  }

  /// State L · with two seasons the figure is the SUM, and the tap lands on
  /// the season with the nearest due date. There is no tap-cycle — that is the
  /// switcher, reintroduced in the tightest row on the screen.
  @Test func twoSeasonsOweOneSumAndOneDoor() {
    let near = membership(name: "Fellas", stake: 5000, due: "2026-09-10")
    let far = membership(name: "Desert Dogs", stake: 2500, due: "2026-11-01")
    let s = MeStripCopy.make(Me(profile: profile(), memberships: [far, near]), upcoming: [], today: today)
    let slot = s.slots.first { $0.fact == .myMoney }
    #expect(slot?.value == "$75")
    #expect(slot?.door == .pot(near.league_id))
  }
}

// MARK: - The season context row

@Suite struct MeStripSeasonRowTests {

  @Test func theRowNamesTheLeagueTheRankBothGapsAndTheEndgame() {
    let st = standing(rank: 2, of: 8, points: 27, up: ("Galen", 31), down: ("Jade", 25))
    let s = MeStripCopy.make(Me(profile: profile(), memberships: [membership(standing: st)]),
                             upcoming: [], today: today)
    #expect(s.seasonRow?.text == "FELLAS · 2ND OF 8 · 4 BACK OF GALEN · 2 CLEAR OF JADE · TOP 2 INTO THE FINAL, OPENS DEC 7")
  }

  /// QB-03 · **THE CUT LINE IS NEVER THE CLAUSE THAT YIELDS.**
  ///
  /// The endgame clause used to be appended only `if st.rank < 3`, to make room
  /// for the leader's name — so the one seat that does not already know where
  /// it stands was the one seat guaranteed never to be told. A reader sitting
  /// in exactly that seat: *"I know I'm 3rd. Nothing on Home tells me 3rd is a
  /// losing position."* The leader's name yields instead, and he asked for
  /// precisely this string.
  ///
  /// It is also the AX3 acceptance string — the longest the row can produce —
  /// and this trade makes it shorter, which is why QB-03 and QB-11 were fixed
  /// together.
  @Test func theEndgameClauseSurvivesAtEveryRank() {
    let st = standing(rank: 3, of: 8, points: 19, leader: "Tommy", leaderGap: 12,
                      up: ("Dre", 23), down: ("Jade", 15))
    let s = MeStripCopy.make(Me(profile: profile(), memberships: [membership(name: "Desert Dogs", standing: st)]),
                             upcoming: [], today: today)
    #expect(s.seasonRow?.text == "DESERT DOGS · 3RD OF 8 · 4 BACK OF DRE · 4 CLEAR OF JADE · TOP 2 INTO THE FINAL, OPENS DEC 7")
    #expect(s.seasonRow?.text.contains("TOMMY LEADS") == false)
  }

  /// A-5 · a gap is always attached to a name. Without `next_up` (a v2 payload)
  /// the gap clause does not render at all — "4 back" with nobody on the end of
  /// it is a number a golfer cannot act on. QB-03 · and the endgame clause is
  /// what the row says when both gaps are nameless, which is exactly the state
  /// in which "am I in or out" is the only question left.
  @Test func aGapWithNoNameDoesNotRender() {
    let st = Me.Standing(rank: 3, of: 8, points: 19, prev_rank: nil, leader_squad_id: nil, leader_points: 31,
                         gap_to_leader: 12, gap_to_next: 4, leader_name: "Tommy")
    let s = MeStripCopy.make(Me(profile: profile(), memberships: [membership(standing: st)]),
                             upcoming: [], today: today)
    #expect(s.seasonRow?.text == "FELLAS · 3RD OF 8 · TOP 2 INTO THE FINAL, OPENS DEC 7")
    #expect(s.seasonRow?.text.contains("BACK OF") == false)
    #expect(s.seasonRow?.text.contains("TOMMY") == false)
  }

  /// At rank 1 or 2 `next_up` IS the leader, so no leader clause is needed.
  @Test func theLeaderSaysWhatTheyAreClearBy() {
    let st = standing(rank: 1, of: 8, points: 31, down: ("Jade", 9))
    let s = MeStripCopy.make(Me(profile: profile(), memberships: [membership(standing: st)]),
                             upcoming: [], today: today)
    #expect(s.seasonRow?.parts.contains("22 CLEAR OF JADE") == true)
    #expect(s.seasonRow?.text.contains("LEADS BY") == false)
  }

  /// SA-3 · at a field of two "the top two seed" is a tautology, and the
  /// shipped long string prints it. The short clause never does.
  @Test func atTwoTheEndgameNeverSaysTheTopTwoSeed() {
    let st = standing(rank: 2, of: 2, points: 27, up: ("Galen", 31))
    let s = MeStripCopy.make(Me(profile: profile(), memberships: [membership(standing: st)]),
                             upcoming: [], today: today)
    #expect(s.seasonRow?.text == "FELLAS · 2ND OF 2 · 4 BACK OF GALEN · A FINAL BETWEEN THE TWO OF YOU, OPENS DEC 7")
    #expect(s.seasonRow?.text.contains("TOP 2") == false)
  }

  @Test func aPointsTableSeasonSaysWhatCrownsIt() {
    let st = standing(rank: 2, of: 8, points: 27, up: ("Galen", 31))
    let m = membership(finish: "points_table", season: season(finalOpens: nil), standing: st)
    let s = MeStripCopy.make(Me(profile: profile(), memberships: [m]), upcoming: [], today: today)
    #expect(s.seasonRow?.parts.last == "POINTS TABLE CROWNS IT JAN 3")
  }

  /// Squads read the squad first. "You 3rd of 16" is a fact this payload does
  /// not have, and it is not invented (L-44).
  @Test func aSquadsRowNamesTheSquad() {
    let st = standing(rank: 1, of: 4, points: 61, down: ("The Frost", 55))
    let m = membership(structure: "squads2", standing: st,
                       squad: Me.Squad(id: UUID(), name: "Mudsharks", color: 2))
    let s = MeStripCopy.make(Me(profile: profile(), memberships: [m]), upcoming: [], today: today)
    #expect(s.seasonRow?.parts[1] == "MUDSHARKS 1ST OF 4")
    #expect(s.seasonRow?.text.contains("YOU ") == false)
  }

  /// With no season the row is ABSENT — not a row of zeroes (L-44).
  @Test func noSeasonIsNoRow() {
    #expect(MeStripCopy.make(Me(profile: profile()), upcoming: [], today: today).seasonRow == nil)
  }

  @Test func aWrappedSeasonNeverWinsTheRow() {
    let done = membership(name: "Old", phase: "complete",
                          season: season(status: "complete"), standing: standing(rank: 1, of: 8, points: 40))
    #expect(MeStripCopy.make(Me(profile: profile(), memberships: [done]), upcoming: [], today: today).seasonRow == nil)
  }

  /// The season with the NEAREST deadline wins the row — one row, never a
  /// per-league switcher.
  @Test func theNearestDeadlineTakesTheRow() {
    let far = membership(name: "Far", season: season(weekEnds: "2026-09-20"),
                         standing: standing(rank: 1, of: 4, points: 20))
    let near = membership(name: "Near", season: season(weekEnds: "2026-09-09"),
                          standing: standing(rank: 4, of: 9, points: 5))
    let s = MeStripCopy.make(Me(profile: profile(), memberships: [far, near]), upcoming: [], today: today)
    #expect(s.seasonRow?.parts.first == "NEAR")
    #expect(s.seasonRow?.leagueId == near.league_id)
  }
}

// MARK: - L-34 · the suppress set is honoured below the strip

@Suite struct MeStripSuppressTests {

  @Test func theStripPublishesWhatItSpent() {
    let m = Me(profile: profile(), memberships: [membership()])
    let s = MeStripCopy.make(m, upcoming: [plan("2026-09-12")], today: today)
    #expect(s.suppress == [.myNumber, .myLastRound, .myNextRound, .myMoney])
  }

  /// HM-35 was the live door offered twice on one screen. The chip strip is
  /// the same defect one slot over: with the strip carrying NEXT, the "Next
  /// round" chip stands down and the rest of the strip is untouched.
  @Test func theNextRoundChipStandsDownUnderTheStrip() {
    let rows = [plan("2026-09-12")]
    let without = UpNext.chips(watch: rows, invites: 1, requests: 0, hasMemberships: true, today: today)
    let with = UpNext.chips(watch: rows, invites: 1, requests: 0, hasMemberships: true, today: today,
                            suppress: [.myNextRound])
    #expect(without.contains { $0.k == "Next round" })
    #expect(!with.contains { $0.k == "Next round" })
    #expect(with.contains { $0.k == "Needs you" })
  }

  @Test func suppressingSomethingElseLeavesTheChipAlone() {
    let with = UpNext.chips(watch: [plan("2026-09-12")], invites: 0, requests: 0, hasMemberships: true,
                            today: today, suppress: [.myMoney, .myNumber])
    #expect(with.contains { $0.k == "Next round" })
  }
}

// MARK: - The empty payload

@Suite struct MeStripEmptyTests {
  @Test func noPayloadIsAnEmptyStripAndNotACrash() {
    let s = MeStripCopy.make(nil, upcoming: nil, today: today)
    #expect(s.isEmpty)
    #expect(s.suppress.isEmpty)
  }

  @Test func noProfileIsNoFacts() {
    // The tee sheet is still readable, so NEXT still has an honest empty state
    // — but `PLAN ONE` alone is a row of one absence, and the strip stands
    // down rather than render it. The slot itself is still produced.
    let s = MeStripCopy.make(Me(profile: nil), upcoming: [], today: today)
    #expect(s.slots.isEmpty)
    #expect(MeStripCopy.nextSlot([], today: today, calendar: .current)?.fact == .myNextRound)
  }
}

// MARK: - DEF-1 / DEF-2 · the two defects a screenshot found and no test did

/// BUILD_PLAN §2.z: "a producer that interpolates a server string into a slot
/// sized for a short one will look correct in a test and wrong on a phone."
/// Both were photographed on the owner's real account at three consecutive
/// tips before anything caught them, so both become values here.
@Suite("The strip and the lead survive a long course name")
struct LongCourseNameTests {

  /// Prod's longest label today, and the one that wrapped the NEXT slot to
  /// three lines at the DEFAULT type size on the widest phone.
  static let longest = "Gold Canyon — Dinosaur Mountain · Black/Blue"

  @Test func theShortNameIsTheClubAndNothingElse() {
    #expect(MeStripCopy.shortCourse(Self.longest) == "Gold Canyon")
    #expect(MeStripCopy.shortCourse("Troon North Golf Course — Pinnacle Course · Gold") == "Troon North Golf Course")
    #expect(MeStripCopy.shortCourse("Raven Golf Club-Phoenix · Silver") == "Raven Golf Club-Phoenix")
    // a plain name is left exactly as it is
    #expect(MeStripCopy.shortCourse("Papago Golf Course") == "Papago Golf Course")
    // and nothing is invented from nothing
    #expect(MeStripCopy.shortCourse(nil) == nil)
    #expect(MeStripCopy.shortCourse("   ") == nil)
  }

  /// DEF-1 · the slot with a real plan on it. With a tee time the strip says
  /// the day and the tee; WITHOUT one — which is every real plan in prod —
  /// it says the day and the CLUB, never the layout and never the tee variant.
  @Test func theNextSlotNeverPrintsTheFullLabel() {
    let noTee = plan("2026-09-07", tee: nil, course: Self.longest)
    let slot = MeStripCopy.nextSlot([noTee], today: "2026-09-05", calendar: .current)
    #expect(slot?.value == "MON · GOLD CANYON")
    #expect(slot?.value.contains("DINOSAUR") == false)
    #expect(slot?.value.contains("BLACK/BLUE") == false)
    // the tee wins the slot outright — a time is shorter and more useful than a place
    #expect(MeStripCopy.nextSlot([plan("2026-09-07", course: Self.longest)],
                                 today: "2026-09-05", calendar: .current)?.value == "MON 7:10")
  }

  /// The day as a WORD, for a sentence. `home_dispatch` computes the same
  /// three cases in SQL, and `HomeFallbackItems` uses this one, so the ranker
  /// and the declared fallback say the same thing about the same plan.
  @Test func theDayWordIsASentenceNotASlot() {
    #expect(MeStripCopy.dayWord("2026-09-05", today: "2026-09-05") == "today")
    #expect(MeStripCopy.dayWord("2026-09-06", today: "2026-09-05") == "tomorrow")
    #expect(MeStripCopy.dayWord("2026-09-07", today: "2026-09-05") == "Monday")
    // past a week it is a date, never a weekday that could mean either week
    #expect(MeStripCopy.dayWord("2026-09-20", today: "2026-09-05").contains("Sep"))
  }

  /// DEF-2 (L-34) · the lead card said its course TWICE — once in full in the
  /// eyebrow and once in full in the headline. The eyebrow keeps the venue;
  /// the headline names the person and the day; the standfirst carries the
  /// tee time and who else is in.
  @Test func theLeadCardNeverSaysItsCourseTwice() throws {
    let row: [String: Any] = [
      "id": UUID().uuidString, "display_name": "Galen Fischbeck", "play_on": "2026-09-07",
      "course_label": Self.longest, "tee_time": "07:10:00", "rsvp_in": 2,
      "mine": false, "tagged_me": true,
    ]
    let json = try JSONSerialization.data(withJSONObject: ["memberships": [], "invites": [],
                                                          "events": [], "open_duels": [],
                                                          "upcoming_rounds": [row]])
    let me = try JSONDecoder().decode(Me.self, from: json)
    let items = HomeFallbackItems.make(me, feed: [], today: "2026-09-05")
    let lead = items.first { $0.key.hasPrefix("plan:") }
    #expect(lead != nil)
    #expect(lead?.headline == "Galen has you down for Monday.")
    #expect(lead?.eyebrow.contains("GOLD CANYON") == true)          // the venue, once
    #expect(lead?.headline.contains("Gold Canyon") == false)        // and not twice
    #expect(lead?.standfirst == "7:10 tee · 2 of you on the sheet.")
  }
}

// MARK: - the strip yields, and its supporting rows earn their place

@Suite struct MeStripYieldTests {
  private let today = "2026-09-06"

  @Test("the strip drops a fact the lead or the deck already rendered")
  func theStripYields() {
    let me = Me(profile: profile(), memberships: [membership()])
    let full = MeStripCopy.make(me, upcoming: [], today: today)
    let cut  = MeStripCopy.make(me, upcoming: [], today: today, suppress: [.myLastRound])
    #expect(full.slots.contains { $0.fact == .myLastRound })
    #expect(cut.slots.contains { $0.fact == .myLastRound } == false)
    // Everything else is untouched — this suppresses a slot, not the strip.
    #expect(cut.slots.contains { $0.fact == .myNumber })
  }

  /// L-34, one row apart: `$75 · YOU OWE` and then, directly beneath it,
  /// "You still owe $75 · …". The instruction survives; the echo does not.
  @Test("the owe line does not repeat the figure standing above it")
  func theFigureIsSaidOnce() {
    let me = Me(profile: profile(), memberships: [membership()])
    let s = MeStripCopy.make(me, upcoming: [], today: today)
    #expect(s.slots.contains { $0.fact == .myMoney })
    #expect(s.oweRow?.hasPrefix("You still owe") == false)
    #expect(s.oweRow?.contains("Venmo @ray-o") == true)
  }

  /// With the money slot suppressed there is no figure above the line, so the
  /// sentence has to carry it again.
  @Test("with no money slot on screen the owe line keeps its figure")
  func theFigureReturnsWhenTheSlotIsGone() {
    let me = Me(profile: profile(), memberships: [membership()])
    let s = MeStripCopy.make(me, upcoming: [], today: today, suppress: [.myMoney])
    #expect(s.oweRow?.hasPrefix("You still owe") == true)
  }

  @Test("the season row stands down when the column already said where I stand")
  func theStandingIsSaidOnce() {
    let me = Me(profile: profile(), memberships: [membership(standing: standing(rank: 2, of: 8, points: 30,
                                                                                leader: "Galen", leaderGap: 4))])
    #expect(MeStripCopy.make(me, upcoming: [], today: today).seasonRow != nil)
    #expect(MeStripCopy.make(me, upcoming: [], today: today, standingSaid: true).seasonRow == nil)
  }

  /// An unpaid buy-in sits there for weeks. Ranking money above standing would
  /// have hidden the competition behind a chore for most of a season.
  @Test("money never outranks the standing")
  func moneyDoesNotMaskTheSeason() {
    let me = Me(profile: profile(), memberships: [membership(standing: standing(rank: 2, of: 8, points: 30,
                                                                                leader: "Galen", leaderGap: 4))])
    let s = MeStripCopy.make(me, upcoming: [], today: today)
    #expect(s.oweRow != nil)
    #expect(s.seasonRow != nil)
  }

  @Test("the month row is the weakest and renders only when the others did not")
  func theMonthRowYieldsToBoth() {
    let me = Me(profile: profile(), memberships: [membership()])
    #expect(MeStripCopy.make(me, upcoming: [], today: today).monthRow == nil)
  }
}

// MARK: - a row of absences is not an anchor

@Suite struct MeStripPlaceholderTests {
  private let today = "2026-09-06"

  /// Brand new: `— BUILDING · NO ROUNDS YET · PLAN ONE`, set under a lead card
  /// that has just said "your first round is the only thing missing". Three
  /// doors wearing a data row's clothes, saying the lead's sentence back.
  @Test("with nothing true yet the strip renders nothing at all")
  func theEmptyStripStandsDown() {
    let me = Me(profile: profile(index: nil, rounds: 0, lastOn: nil, lastGross: nil, lastId: nil), memberships: [])
    let s = MeStripCopy.make(me, upcoming: [], today: today)
    #expect(s.slots.isEmpty)
    #expect(s.isEmpty)
  }

  /// One real fact is enough to bring it back — and `PLAN ONE` beside a number
  /// and a last round is an invitation, not a fourth way of saying "nothing".
  @Test("one real fact brings the whole strip back, placeholders included")
  func oneFactIsEnough() {
    let me = Me(profile: profile(), memberships: [])
    let s = MeStripCopy.make(me, upcoming: [], today: today)
    #expect(s.slots.contains { $0.fact == .myNumber && !$0.isPlaceholder })
    #expect(s.slots.contains { $0.value == "PLAN ONE" && $0.isPlaceholder })
  }

  /// A membership with something to say keeps the strip even at zero rounds:
  /// the supporting row is a fact, and standing down would delete it.
  @Test("a supporting row keeps the strip up even with every slot empty")
  func aRealRowKeepsIt() {
    let me = Me(profile: profile(index: nil, rounds: 0, lastOn: nil, lastGross: nil, lastId: nil), memberships: [membership()])
    let s = MeStripCopy.make(me, upcoming: [], today: today)
    #expect(s.isEmpty == false)
    #expect(s.oweRow != nil)
  }
}
