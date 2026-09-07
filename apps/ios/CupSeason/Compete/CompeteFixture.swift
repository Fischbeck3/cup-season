// Cup Season — COMPETE'S CAPTURE FIXTURE (D286, DEBUG only).
//
// **Why this exists, stated plainly.** Compete is a tab behind the tab bar, and
// the tab bar only exists for a signed-in session. Every other surface this
// overhaul rebuilt could be photographed because the simulator held one; when
// this wave opened, that session's refresh token had expired (`/auth/v1/token`
// → 401) and the simulator was at the door. A wave that rebuilds a screen and
// cannot photograph it has not looked at it, and the alternative — writing
// seasons into the owner's real account to take a screenshot — is inventing
// golfers (`EVIDENCE_POLICY`).
//
// So the tab runs on a named fixture instead, over the root, under a DEBUG
// launch argument, never written to the server — exactly the posture
// `-cs_dev_home_state`, `-cs_dev_season_fixture`, `-cs_dev_event_fixture` and
// `-cs_dev_open ceremony` already take.
//
//   `-cs_dev_compete_fixture`   three live seasons, a moment, a finished season
//
// **IT IS A PAYLOAD, NOT A LIST.** The fixture builds `native_home`'s own JSON
// and decodes it with the app's own decoder, so `CompeteRoot.make` — the
// producer this wave changed — is the thing under the camera. A fixture that
// hand-wrote `CompeteRoot.Row` values would photograph the fixture's opinion of
// the screen rather than the product's.
//
// The five rows are chosen to carry every branch the wave built:
//   · a season where I am 2ND OF 2      — the owner's own shape, the figure
//   · a season where I am 1ST OF 8      — the leader's grain, and the long sub
//   · a season in PRESEASON             — NO figure: nobody is 1st of 8 on zero
//   · a moment (an event)               — no figure, and quieter for it
//   · a WRAPPED season                  — the finish, from `last_season`
//
// Every claim a screenshot taken through this hatch makes is a claim about a
// fixture, and the report says so.

#if DEBUG
import Foundation
import CupSeasonKit

@MainActor
enum CompeteFixture {
  static var on: Bool { ProcessInfo.processInfo.arguments.contains("-cs_dev_compete_fixture") }

  /// The decoded payload, or nil if the hatch is off. Built once per launch.
  static let me: Me? = on ? decode() : nil

  /// Dates are relative to TODAY, so week 8 of 15 is still week 8 of 15 next
  /// month and the fixture never photographs a season that ended in the past.
  private static func day(_ offset: Int) -> String {
    CSDate.iso(Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date())
  }

  private static func decode() -> Me? {
    let json = """
    {
      "profile": { "id": "C50F0000-0000-4000-8000-000000000001",
                   "display_name": "Jerecho", "handle": "jerecho", "marker": "saguaro",
                   "city": "Tempe", "home_course": "Papago", "index_current": 12.4,
                   "index_source": "derived", "photo_path": null, "rounds_count": 9,
                   "member_since": null, "is_founder": true },
      "memberships": [
        {
          "league_id": "C50F0000-0000-4000-8000-000000000010",
          "name": "Who's the bitch?", "code": "BITCH", "phase": "season", "sandbox": false,
          "role": "player", "member_id": "C50F0000-0000-4000-8000-000000000011",
          "marker": "saguaro", "commissioner_name": "Galen", "members": 2, "roster": 2,
          "settings": { "structure": "solo", "buyin_cents": 0, "counting_cap": 4,
                        "participation_floor": 2, "finish": "cup_final" },
          "season": { "id": "C50F0000-0000-4000-8000-000000000012", "number": 2,
                      "starts_on": "\(day(-52))", "ends_on": "\(day(+53))", "status": "active",
                      "week_no": 8, "weeks_total": 15, "days_left": 53 },
          "standing": { "rank": 2, "of": 2, "points": 15, "prev_rank": 2,
                        "leader_squad_id": null, "leader_points": 19,
                        "gap_to_leader": 4, "gap_to_next": null, "leader_name": "Galen" }
        },
        {
          "league_id": "C50F0000-0000-4000-8000-000000000020",
          "name": "The Fellas", "code": "FELLAS", "phase": "season", "sandbox": false,
          "role": "commissioner", "member_id": "C50F0000-0000-4000-8000-000000000021",
          "marker": "lonetree", "commissioner_name": "Jerecho", "members": 8, "roster": 8,
          "settings": { "structure": "solo", "buyin_cents": 6000, "counting_cap": 4,
                        "participation_floor": 2, "finish": "cup_final" },
          "buy_in": { "paid": true, "players": 8, "paid_count": 6, "collected_cents": 36000 },
          "season": { "id": "C50F0000-0000-4000-8000-000000000022", "number": 2,
                      "starts_on": "\(day(-16))", "ends_on": "\(day(+166))", "status": "active",
                      "week_no": 3, "weeks_total": 26, "days_left": 166 },
          "standing": { "rank": 1, "of": 8, "points": 25, "prev_rank": 2,
                        "leader_squad_id": null, "leader_points": 25,
                        "gap_to_leader": 0, "gap_to_next": 6, "leader_name": "Jerecho",
                        "runner_up_name": "Jade", "runner_up_points": 19 }
        },
        {
          "league_id": "C50F0000-0000-4000-8000-000000000030",
          "name": "The Dew Sweepers", "code": "DEWSW", "phase": "season", "sandbox": false,
          "role": "player", "member_id": "C50F0000-0000-4000-8000-000000000031",
          "marker": "dunes", "commissioner_name": "Tash", "members": 12, "roster": 12,
          "settings": { "structure": "squads4", "buyin_cents": 0, "counting_cap": 4,
                        "participation_floor": 2, "finish": "points" },
          "season": { "id": "C50F0000-0000-4000-8000-000000000032", "number": 1,
                      "starts_on": "\(day(+11))", "ends_on": "\(day(+193))", "status": "active",
                      "week_no": 0, "weeks_total": 26, "days_to_first_tee": 11 },
          "standing": { "rank": 1, "of": 4, "points": 0, "prev_rank": null,
                        "leader_squad_id": null, "leader_points": 0,
                        "gap_to_leader": null, "gap_to_next": null }
        },
        {
          "league_id": "C50F0000-0000-4000-8000-000000000040",
          "name": "Sunningdale Society", "code": "SUNNI", "phase": "complete", "sandbox": false,
          "role": "player", "member_id": "C50F0000-0000-4000-8000-000000000041",
          "marker": "pews", "commissioner_name": "Mike", "members": 8, "roster": 8,
          "settings": { "structure": "solo", "buyin_cents": 6000, "finish": "cup_final" },
          "season": { "id": "C50F0000-0000-4000-8000-000000000042", "number": 1,
                      "starts_on": "\(day(-240))", "ends_on": "\(day(-58))", "status": "complete" },
          "last_season": { "number": 1, "ended_on": "\(day(-58))", "champion_name": "Mike",
                           "champion_is_me": false, "my_rank": 3, "of": 8 }
        }
      ],
      "invites": [], "upcoming_rounds": [], "open_duels": [],
      "events": [
        { "id": "C50F0000-0000-4000-8000-000000000050", "name": "The Dew Sweepers Cup",
          "kind": "ryder", "status": "live", "starts_on": "\(day(+2))",
          "league_id": "C50F0000-0000-4000-8000-000000000030",
          "my_team_slot": 1, "is_organizer": false }
      ]
    }
    """
    do { return try JSONDecoder().decode(Me.self, from: Data(json.utf8)) }
    catch {
      // A fixture that silently decodes to nil is a screen that silently
      // renders its skeleton forever — which is exactly what the first shot
      // through this hatch showed.
      NSLog("[compete-fixture] payload did not decode: \(error)")
      return nil
    }
  }
}
#endif
