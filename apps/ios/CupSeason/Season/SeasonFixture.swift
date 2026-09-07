// Cup Season — THE SEASON PAGE'S CAPTURE FIXTURE (Wave 5, DEBUG only).
//
// **Why this exists, stated plainly.** The signed-in simulator account plays a
// two-golfer FREE league. That is a real season and the page renders it
// correctly — but three of the things this wave built cannot appear in it:
//
//   · the CUT rule needs a field greater than two,
//   · the POT, its split and the printed leaf need a stake above zero (L-10
//     makes the whole section absent at `$0`, which is the correct behaviour),
//   · the SQUAD table needs a season whose structure is not solo.
//
// A wave whose signature objects were never photographed is a wave nobody
// looked at, and the alternative — writing a stake and seven golfers into the
// owner's real league to take a screenshot — is inventing golfers
// (`EVIDENCE_POLICY`). So the page runs on a named fixture instead, under a
// DEBUG launch argument, never written to the server, exactly the posture
// `-cs_dev_home_state` and `-cs_dev_h2h_fixture` already take.
//
//   `-cs_dev_season_fixture`         the Fellas — eight in at $60, solo, Cup Final
//   `-cs_dev_season_fixture squads`  the Dew Sweepers — twelve in, four squads
//
// The arithmetic is the blind review's own fixture (finding 3): **eight in at
// $60 → $480 → $288 / $120 / $72**, on every surface.

#if DEBUG
import Foundation
import CupSeasonKit

@MainActor
enum SeasonFixture {
  /// nil unless the hatch is set; `"solo"` or `"squads"` when it is.
  static var kind: String? {
    let a = ProcessInfo.processInfo.arguments
    guard let i = a.firstIndex(of: "-cs_dev_season_fixture") else { return nil }
    let next = i + 1 < a.count ? a[i + 1] : ""
    return next == "squads" ? "squads" : "solo"
  }

  private static let league = UUID(), season = UUID()
  private static func ids(_ n: Int) -> [UUID] {
    // stable within a launch; a fixture never has to survive one
    (0..<n).map { _ in UUID() }
  }

  static let names = ["Galen Marr", "Jerecho", "Jade Okafor", "Dev Rana", "Tash Bell",
                      "Mike Fenner", "Priya Raghunathan", "Sam Ridley",
                      "Nora Vance", "Eli Brandt", "Ruth Salas", "Owen Pike"]
  /// **Real keys from `CSMarkers`, or every face falls back to the saguaro** —
  /// which is what the first fixture shot showed: eight golfers wearing one
  /// glyph, the exact defect §6 exists to prevent, arriving through a fixture
  /// rather than through the product.
  static let markers = ["lonetree", "saguaro", "shark", "dunes", "azalea", "pews",
                        "island", "jug", "lighthouse", "beer", "stamp", "thistle"]

  static func apply(_ model: LeagueRoomModel, squads: Bool) {
    let n = squads ? 12 : 8
    let members = ids(n)
    let profiles = ids(n)
    let squadIds = ids(4)
    // the leader first; the viewer second, so the board photographs a gold rail
    // and a panel rail on adjacent rows
    let points: [Double] = squads
      ? [19, 15, 10, 8, 6, 1, 12, 9, 7, 5, 4, 2]
      : [19, 15, 10, 7, 6, 4, 3, 1]
    // last Sunday: you were third, Jade was second, Tash was ahead of Dev.
    // Two rows up, two rows down, four held — every state of `CSMovement` on
    // one board.
    let priorPoints: [Double] = [18, 9, 12, 7, 8, 4, 3, 1]
    model.seed(
      viewer: RoomViewer(id: profiles[1], displayName: "Jerecho", marker: "saguaro",
                         indexCurrent: 12.4, roundsCount: 9),
      league: .init(id: league, name: squads ? "The Dew Sweepers" : "The Fellas",
                    code: "FELLAS", phase: "season", commissioner_id: profiles[0]),
      settings: .init(league_id: league, preset: "standard", counting_cap: 4,
                      participation_floor: 2, buyin_cents: 6000,
                      structure: squads ? "squads4" : "solo", draft_type: "random",
                      payout_champ: 60, payout_runnerup: 25, payout_king: 15,
                      finish: "cup_final"),
      season: .init(id: season, number: 1, starts_on: "2026-08-03", ends_on: "2026-11-02", status: "active"),
      members: (0..<n).map { i in
        .init(id: members[i], role: i == 0 ? "commissioner" : "player", profile_id: profiles[i],
              profile: .init(display_name: names[i], marker: markers[i],
                             index_current: 8 + Double(i), handle: names[i].lowercased()))
      },
      squads: squads ? (0..<4).map { s in
        .init(id: squadIds[s], name: ["Mudsharks", "Saguaros", "Coyotes", "Roadrunners"][s],
              color: s, captain_member_id: members[s * 3],
              squad_members: (0..<3).map { .init(member_id: members[s * 3 + $0]) })
      } : [],
      squadStandings: squads ? [
        .init(squad_id: squadIds[0], points: 58), .init(squad_id: squadIds[1], points: 49),
        .init(squad_id: squadIds[2], points: 44), .init(squad_id: squadIds[3], points: 37),
      ] : [],
      indiv: (0..<n).map { .init(member_id: members[$0], points: points[$0], rounds_posted: max(0, 5 - $0 / 2)) },
      ranked: (0..<n).flatMap { i in
        (0..<max(1, 4 - i / 3)).map { k in
          LeagueRoom.RankedRound(member_id: members[i], round_id: UUID(), pvi: Double(3 - k),
                                 points: points[i] / Double(max(1, 4 - i / 3)), month_rank: k + 1,
                                 floor_credit: 1, played_on: "2026-08-\(String(format: "%02d", 8 + k * 5))",
                                 index_at_post: 8 + Double(i), holes_played: 18)
        }
      },
      // **Last Sunday's board, so the movement marks have something to be a
      // movement FROM.** A solo snapshot keys `individuals`/`member_id`; a
      // squads snapshot keys `squads`/`squad_id`, and passing the wrong pair
      // renders a table with no triangles at all — which is what the first
      // fixture shot showed.
      // …and it carries its `captured_at`, because Wave 7 made the movement
      // COLUMN conditional on the clock the section head names: a fixture that
      // seeds prior ranks and no snapshot date now draws no triangles at all,
      // which is correct behaviour and a useless screenshot.
      snapshots: [.init(week_no: 4, standings: .object([
        squads ? "squads" : "individuals": .array(
          (0..<(squads ? 4 : n)).map { i in
            let id = squads ? squadIds[i] : members[i]
            let prior = squads ? [58.0, 40, 47, 37][i] : priorPoints[i]
            return .object([(squads ? "squad_id" : "member_id"): .string(id.uuidString.lowercased()),
                            "points": .number(prior)])
          })]),
        captured_at: "2026-08-30T07:10:00.000+00:00")],
      // six of eight are in; the viewer is not, so the leaf photographs
      // `YOU OWE` beside `PAID` and `OWES` — the three words the sign takes
      buyIns: (0..<n).compactMap { i in
        i == 1 || i == 5 ? nil : .init(member_id: members[i], paid: true, amount_cents: 6000)
      },
      today: "2026-09-06")
  }
}
#endif
