// Cup Season — `native_home` v3 decodes both ways (D236, D246, R3).
//
// The owner deploys the DATABASE and the CLIENTS separately, and either order
// has to render an honest screen. So this suite is deliberately symmetrical:
//
//   · a v3 payload decodes with every new key present, and each one lands
//   · a v2 payload — the one in prod until the migration is pushed — decodes
//     with every new key ABSENT, and nothing in the model is left holding a
//     value the server never sent
//
// Both directions matter. A client ahead of the database must not crash or
// invent; a database ahead of the client must not be able to break a build
// that predates it (which is what makes every one of these keys optional).

import Testing
import Foundation
@testable import CupSeasonKit

private func decode(_ json: String) throws -> Me {
  try JSONDecoder().decode(Me.self, from: Data(json.utf8))
}

private let pid = "11111111-1111-1111-1111-111111111111"
private let lid = "22222222-2222-2222-2222-222222222222"
private let mid = "33333333-3333-3333-3333-333333333333"
private let sid = "44444444-4444-4444-4444-444444444444"
private let rid = "55555555-5555-5555-5555-555555555555"

@Suite struct NativeHomeV3DecodeTests {

  /// Every v3 key present, exactly as the migration writes it.
  @Test func aV3PayloadCarriesEveryNewKey() throws {
    let me = try decode("""
    {
      "profile": {
        "id": "\(pid)", "display_name": "Jerecho", "handle": "jer", "marker": "saguaro",
        "city": "Tempe", "home_course": "Papago", "index_current": 12.4, "index_source": "app",
        "photo_path": null, "rounds_count": 9, "is_founder": true,
        "last_round_on": "2026-09-05", "last_gross": 78, "last_round_id": "\(rid)",
        "days_since_round": 3
      },
      "memberships": [{
        "league_id": "\(lid)", "name": "Fellas", "code": "ABCD", "phase": "season", "sandbox": false,
        "role": "member", "member_id": "\(mid)", "marker": "saguaro", "commissioner_name": "Galen Ortiz",
        "settings": {"structure": "solo", "buyin_cents": 5000, "finish": "cup_final", "counting_cap": 4},
        "season": {
          "id": "\(sid)", "number": 3, "starts_on": "2026-07-05", "ends_on": "2027-01-03",
          "status": "active", "timezone": "America/Phoenix",
          "week_no": 9, "weeks_total": 26, "week_ends_on": "2026-09-13",
          "days_to_first_tee": null, "days_left": 117, "final_opens_on": "2026-12-07"
        },
        "squad": null,
        "standing": {
          "rank": 3, "of": 8, "points": 19, "prev_rank": 3,
          "leader_name": "Tommy", "gap_to_leader": 12, "gap_to_next": 4,
          "next_up": {"name": "Dre", "points": 23},
          "next_down": {"name": "Jade", "points": 15}
        },
        "pulse": null,
        "buy_in": {"paid": false, "note": "Venmo @ray-o", "players": 8, "paid_count": 6, "collected_cents": 30000},
        "roster": 8, "members": 8,
        "pro_name": "Galen",
        "last_season": {"number": 2, "ended_on": "2026-06-28", "champion_name": "Galen", "my_rank": 4, "of": 8},
        "clash": {
          "week_no": 9, "ends_on": "2026-09-13", "days_left": 5, "closes_today": false,
          "them_name": "Dre Ortiz", "them_marker": "cholla",
          "mine": {"round_id": "\(rid)", "played_on": "2026-09-05", "points": 12, "pvi": 1.4, "gross": 78},
          "theirs": null, "rivalry": "The Standoff"
        }
      }],
      "invites": [], "upcoming_rounds": [], "events": [], "open_duels": []
    }
    """)

    let p = try #require(me.profile)
    #expect(p.last_round_on == "2026-09-05")
    #expect(p.last_gross == 78)
    #expect(p.last_round_id?.uuidString.lowercased() == rid)
    #expect(p.days_since_round == 3)

    let m = try #require(me.memberships.first)
    #expect(m.pro_name == "Galen")
    #expect(m.last_season?.champion_name == "Galen")
    #expect(m.last_season?.my_rank == 4)
    #expect(m.clash?.them_name == "Dre Ortiz")
    #expect(m.clash?.mine?.gross == 78)
    #expect(m.clash?.theirs == nil)
    #expect(m.clash?.rivalry == "The Standoff")

    let s = try #require(m.season)
    #expect(s.week_no == 9)
    #expect(s.weeks_total == 26)
    #expect(s.week_ends_on == "2026-09-13")
    #expect(s.days_to_first_tee == nil)
    #expect(s.days_left == 117)
    #expect(s.final_opens_on == "2026-12-07")

    let st = try #require(m.standing)
    #expect(st.next_up == Me.Standing.Neighbour(name: "Dre", points: 23))
    #expect(st.next_down == Me.Standing.Neighbour(name: "Jade", points: 15))
  }

  /// The other order: the client is ahead of the migration. This is the exact
  /// v2 payload in prod today, and it must decode without a single new key.
  @Test func aV2PayloadDecodesWithEveryNewKeyAbsent() throws {
    let me = try decode("""
    {
      "profile": {
        "id": "\(pid)", "display_name": "Jerecho", "handle": "jer", "marker": "saguaro",
        "city": "Tempe", "home_course": "Papago", "index_current": 12.4, "index_source": "app",
        "photo_path": null, "rounds_count": 9, "is_founder": true
      },
      "memberships": [{
        "league_id": "\(lid)", "name": "Fellas", "code": "ABCD", "phase": "season", "sandbox": false,
        "role": "member", "member_id": "\(mid)", "marker": "saguaro", "commissioner_name": "Galen Ortiz",
        "settings": {"structure": "solo", "buyin_cents": 5000, "finish": "cup_final", "counting_cap": 4},
        "season": {
          "id": "\(sid)", "number": 3, "starts_on": "2026-07-05", "ends_on": "2027-01-03",
          "status": "active", "timezone": "America/Phoenix"
        },
        "squad": null,
        "standing": {"rank": 3, "of": 8, "points": 19, "prev_rank": 3, "leader_name": "Tommy",
                     "gap_to_leader": 12, "gap_to_next": 4},
        "pulse": null,
        "buy_in": {"paid": false, "players": 8, "paid_count": 6, "collected_cents": 30000},
        "roster": 8, "members": 8
      }],
      "invites": [], "upcoming_rounds": [], "events": [], "open_duels": []
    }
    """)

    let p = try #require(me.profile)
    #expect(p.last_round_on == nil && p.last_gross == nil && p.last_round_id == nil && p.days_since_round == nil)

    let m = try #require(me.memberships.first)
    #expect(m.pro_name == nil && m.last_season == nil && m.clash == nil)
    // The v2 keys still land — the replace kept them byte for byte.
    #expect(m.commissioner_name == "Galen Ortiz" && m.roster == 8 && m.buy_in?.paid == false)

    let s = try #require(m.season)
    #expect(s.week_no == nil && s.weeks_total == nil && s.week_ends_on == nil)
    #expect(s.days_to_first_tee == nil && s.days_left == nil && s.final_opens_on == nil)

    let st = try #require(m.standing)
    #expect(st.next_up == nil && st.next_down == nil)
    #expect(st.leader_name == "Tommy" && st.gap_to_next == 4)
  }

  /// An explicit `null` is not the same as a missing key to a JSON decoder,
  /// and the server writes both — `days_to_first_tee` is null once a season
  /// has started, `clash` is null unless I am in this week's, `next_up` is null
  /// at the top of the table.
  @Test func explicitNullsDecodeAsAbsent() throws {
    let me = try decode("""
    {
      "profile": {"id": "\(pid)", "display_name": null, "handle": null, "marker": null, "city": null,
                  "home_course": null, "index_current": null, "index_source": null, "photo_path": null,
                  "rounds_count": 0, "is_founder": null, "last_round_on": null, "last_gross": null,
                  "last_round_id": null, "days_since_round": null},
      "memberships": [{
        "league_id": "\(lid)", "name": "Fellas", "code": null, "phase": "setup", "sandbox": null,
        "role": "commissioner", "member_id": "\(mid)", "marker": null, "commissioner_name": null,
        "settings": null, "season": null, "squad": null, "standing": null, "pulse": null,
        "buy_in": null, "roster": null, "members": null,
        "pro_name": null, "last_season": null, "clash": null
      }],
      "invites": [], "upcoming_rounds": [], "events": [], "open_duels": []
    }
    """)
    let m = try #require(me.memberships.first)
    #expect(m.pro_name == nil && m.last_season == nil && m.clash == nil)
    #expect(me.profile?.last_round_on == nil)
  }

  /// The whole point of the strip's decode suite: whichever half of the deploy
  /// has landed, the producer renders something honest off it.
  @Test func theStripIsHonestOnEitherHalfOfTheDeploy() throws {
    let v2 = try decode("""
    {"profile": {"id": "\(pid)", "display_name": "J", "handle": "j", "marker": "m", "city": null,
      "home_course": null, "index_current": 12.4, "index_source": "app", "photo_path": null,
      "rounds_count": 9, "is_founder": null},
     "memberships": [], "invites": [], "upcoming_rounds": [], "events": [], "open_duels": []}
    """)
    let a = MeStripCopy.make(v2, upcoming: [], today: "2026-09-08")
    #expect(a.slots.map(\.fact) == [.myNumber, .myNextRound])   // LAST is not knowable, so it is not there

    let v3 = try decode("""
    {"profile": {"id": "\(pid)", "display_name": "J", "handle": "j", "marker": "m", "city": null,
      "home_course": null, "index_current": 12.4, "index_source": "app", "photo_path": null,
      "rounds_count": 9, "is_founder": null, "last_round_on": "2026-09-05", "last_gross": 78,
      "last_round_id": "\(rid)", "days_since_round": 3},
     "memberships": [], "invites": [], "upcoming_rounds": [], "events": [], "open_duels": []}
    """)
    let b = MeStripCopy.make(v3, upcoming: [], today: "2026-09-08")
    #expect(b.slots.map(\.fact) == [.myNumber, .myLastRound, .myNextRound])
    #expect(b.slots[1].value == "78 SAT")
  }

  /// `upcoming_rounds` is the tee sheet the payload already carries, so the
  /// NEXT slot costs no second read.
  @Test func theTeeSheetRidesThePayload() throws {
    let me = try decode("""
    {"profile": {"id": "\(pid)", "display_name": "J", "handle": "j", "marker": "m", "city": null,
      "home_course": null, "index_current": null, "index_source": null, "photo_path": null,
      "rounds_count": 0, "is_founder": null},
     "memberships": [], "invites": [],
     "upcoming_rounds": [{"id": "\(rid)", "play_on": "2026-09-12", "tee_time": "07:10:00",
                          "course_label": "Gold Canyon", "mine": true, "my_rsvp": "in"}],
     "events": [], "open_duels": []}
    """)
    #expect(me.upcoming.count == 1)
    #expect(MeStripCopy.make(me, today: "2026-09-08").slots.first { $0.fact == .myNextRound }?.value == "SAT 7:10")
  }
}
