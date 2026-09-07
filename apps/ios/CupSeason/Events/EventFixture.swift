// Cup Season — THE EVENT ROOM'S CAPTURE FIXTURE (Wave 6, DEBUG only).
//
// **Why this exists, stated plainly.** The signed-in simulator account has NO
// EVENT on its payload at all — `native_home` returns an empty `events` array —
// so `-cs_dev_open ryder` sets `presenter.event = nil` and falls through to
// Home, which is exactly what `SHOTS.md` caveat 1 recorded about the shipped
// `dark-ryder` capture. Every object this wave builds lives inside a room
// nobody on this Mac can open:
//
//   · the title card, the two-group roster and the score rail (§2),
//   · the callout's two-name head, its three cells and its record (§3),
//   · and every one of §15.5a's side rings — the fix for the failure two of
//     three blind reviewers filed against this surface.
//
// A wave whose signature object was never photographed is a wave nobody looked
// at, and the alternative — creating a real Ryder in the owner's account and
// inviting five invented golfers to it — is inventing golfers
// (`EVIDENCE_POLICY`). So the room runs on a named fixture instead, under a
// DEBUG launch argument, never written to the server, exactly the posture
// `-cs_dev_home_state`, `-cs_dev_h2h_fixture` and `-cs_dev_season_fixture`
// already take.
//
//   `-cs_dev_event_fixture`           the Dew Sweepers Cup — live, week 2 of 3,
//                                     six in the field, $480 pot
//   `-cs_dev_event_fixture complete`  the same event, settled
//   `-cs_dev_event_fixture callout`   one round each, closing Sunday
//   `-cs_dev_event_fixture major`     a championship window, four cards in
//
// The arithmetic is the artboards' own: 3½ – 2½, first to 5, and eight in at
// $60 → $480 wherever a pot appears in this deck.

#if DEBUG
import Foundation
import CupSeasonKit

@MainActor
enum EventFixture {
  /// nil unless the hatch is set.
  static var kind: String? {
    let a = ProcessInfo.processInfo.arguments
    guard let i = a.firstIndex(of: "-cs_dev_event_fixture") else { return nil }
    let next = i + 1 < a.count ? a[i + 1] : ""
    return ["complete", "callout", "major"].contains(next) ? next : "ryder"
  }

  /// A stable id so `-cs_dev_open ryder` has something to open. It is not a
  /// real event and no read is ever made against it.
  static let id = UUID(uuidString: "E0E0E0E0-0000-4000-8000-000000000006")!

  /// **Real keys from `CSMarkers`, or every face falls back to the saguaro** —
  /// which is the exact defect §6 exists to prevent, arriving through a fixture
  /// rather than through the product.
  private static let cast: [(String, String)] = [
    ("Galen Marr", "lonetree"), ("Jade Okafor", "shark"), ("Tash Bell", "dunes"),
    ("Jerecho", "saguaro"), ("Dev Rana", "azalea"), ("Mike Fenner", "pews"),
  ]

  private static let teamA = UUID(uuidString: "A0A0A0A0-0000-4000-8000-000000000001")!
  private static let teamB = UUID(uuidString: "B0B0B0B0-0000-4000-8000-000000000002")!
  private static let sess = UUID(uuidString: "50505050-0000-4000-8000-000000000003")!
  private static let sessPrior = UUID(uuidString: "50505050-0000-4000-8000-000000000004")!

  /// The viewer's own player id, so the roster ring and the ink both know which
  /// disc is yours.
  /// **THE IDS ARE FIXED, AND THAT IS NOT TIDINESS.** `CSFace` keys its pigment
  /// to the PROFILE id, so a fixture minting a fresh `UUID()` per launch gave
  /// Galen a different coin in every screenshot — §6.2a's "a marker that
  /// drifts is not an identity system" arriving through the capture harness,
  /// and two of the wave's own shots disagreed about the cast before this was
  /// caught.
  private static func players(_ me: UUID?, field: Int) -> [EventPlayer] {
    cast.prefix(field).enumerated().map { i, who in
      EventPlayer(id: UUID(uuidString: String(format: "11111111-0000-4000-8000-00000000000%d", i)) ?? UUID(),
                  profileId: i == 3 ? me
                    : UUID(uuidString: String(format: "22222222-0000-4000-8000-00000000000%d", i)),
                  teamId: i < 3 ? teamA : teamB,
                  role: i == 0 ? "captain" : "player",
                  seed: i, name: who.0, marker: who.1)
    }
  }

  static func room(_ kind: String, me: UUID?) -> EventRoom {
    switch kind {
    case "callout":  return callout(me: me)
    case "major":    return major(me: me)
    case "complete": return ryder(me: me, complete: true)
    default:         return ryder(me: me, complete: false)
    }
  }

  // MARK: the Ryder — the flagship

  private static func ryder(me: UUID?, complete: Bool) -> EventRoom {
    let ps = players(me, field: 6)
    let a = Array(ps.prefix(3)), b = Array(ps.suffix(3))
    let today = CSDate.today()
    let opens = LeagueDates.addDays(today, -1)
    let closes = LeagueDates.addDays(today, 2)
    let sessions = [
      EventSession(id: sessPrior, session_no: 1, opens_on: LeagueDates.addDays(today, -8),
                   closes_on: LeagueDates.addDays(today, -2), status: "closed"),
      EventSession(id: sess, session_no: 2, opens_on: opens, closes_on: closes,
                   status: complete ? "closed" : "open"),
    ]
    // week 2's three clashes — yours OPEN, one resolved, one still to post
    let duels = [
      EventDuel(id: UUID(uuidString: "33333333-0000-4000-8000-000000000001")!, session_id: sess, a_player: ps[3].id, b_player: ps[2].id,
                a_pvi: nil, b_pvi: complete ? -0.6 : nil, result: complete ? "a" : "pending"),
      EventDuel(id: UUID(uuidString: "33333333-0000-4000-8000-000000000002")!, session_id: sess, a_player: ps[0].id, b_player: ps[5].id,
                a_pvi: 2.1, b_pvi: -0.4, result: "a"),
      EventDuel(id: UUID(uuidString: "33333333-0000-4000-8000-000000000003")!, session_id: sess, a_player: ps[1].id, b_player: ps[4].id,
                a_pvi: nil, b_pvi: nil, result: "pending"),
    ]
    let targets: [UUID: EventTarget] = [duels[0].id: EventTarget(a: nil, b: 0.8),
                                        duels[2].id: EventTarget(a: nil, b: nil)]
    return EventRoom(
      event: EventRow(id: id, name: "The Dew Sweepers Cup", created_by: me, league_id: nil,
                      kind: "ryder", status: complete ? "complete" : "live",
                      starts_on: LeagueDates.addDays(today, -8), session_count: 3, session_weeks: 1,
                      winner_team_id: complete ? teamA : nil, buy_in: 80, pot_split: "places",
                      course_id: "gold-canyon-dinosaur", course_label: "Gold Canyon — Dinosaur Mountain"),
      teams: [EventTeam(id: teamA, slot: 0, name: "Saguaros", color: 0, captain_player_id: a.first?.id),
              EventTeam(id: teamB, slot: 1, name: "Coyotes", color: 3, captain_player_id: b.first?.id)],
      players: ps, sessions: sessions, duels: duels,
      scoreboard: [teamA: complete ? 5 : 3.5, teamB: complete ? 4 : 2.5],
      targets: targets,
      posts: [EventPost(id: UUID(uuidString: "44444444-0000-4000-8000-000000000001")!, kind: "event",
                        body: "WEEK 2 IS OPEN — THREE CLASHES, BEST ROUND EACH.", created_at: Date())])
  }

  // MARK: the callout — a field of two, one session, no league

  private static func callout(me: UUID?) -> EventRoom {
    let today = CSDate.today()
    let closes = CalloutLength.defaultClose(today: today)
    let mine = EventPlayer(id: UUID(uuidString: "11111111-0000-4000-8000-000000000000")!, profileId: me,
                           teamId: teamA, seed: 0, name: "Sam Ridley", marker: "island")
    let his = EventPlayer(id: UUID(uuidString: "11111111-0000-4000-8000-000000000001")!,
                          profileId: UUID(uuidString: "22222222-0000-4000-8000-000000000001")!,
                          teamId: teamB, seed: 1, name: "Galen Marr", marker: "lonetree")
    let duel = EventDuel(id: UUID(uuidString: "33333333-0000-4000-8000-000000000001")!, session_id: sess,
                         a_player: his.id, b_player: mine.id,
                         a_pvi: 2.1, b_pvi: nil, result: "pending")
    return EventRoom(
      event: EventRow(id: id, name: "Sam v Galen", created_by: me, league_id: nil, kind: "ryder",
                      status: "live", starts_on: today, session_count: 1, session_weeks: 1),
      teams: [EventTeam(id: teamA, slot: 0, name: "Sam", color: 0),
              EventTeam(id: teamB, slot: 1, name: "Galen", color: 1)],
      players: [mine, his],
      sessions: [EventSession(id: sess, session_no: 1, opens_on: today, closes_on: closes, status: "open")],
      duels: [duel],
      scoreboard: [:],
      targets: [duel.id: EventTarget(a: 2.1, b: nil)],
      posts: [EventPost(id: UUID(uuidString: "44444444-0000-4000-8000-000000000002")!, kind: "callout",
                        body: "Galen called Sam out. “Loser buys the beers.”", created_at: Date())])
  }

  // MARK: the Major — a window and a board

  private static func major(me: UUID?) -> EventRoom {
    let today = CSDate.today()
    let ps = players(me, field: 5)
    let board: [MajorBoardRow] = [
      MajorBoardRow(playerId: ps[0].id, profileId: ps[0].profileId, displayName: ps[0].name, marker: ps[0].marker,
                    roundId: UUID(uuidString: "55555555-0000-4000-8000-000000000001")!, gross: 76, pvi: 4.2, cards: 2),
      MajorBoardRow(playerId: ps[3].id, profileId: ps[3].profileId, displayName: ps[3].name, marker: ps[3].marker,
                    roundId: UUID(uuidString: "55555555-0000-4000-8000-000000000001")!, gross: 81, pvi: 2.4, cards: 1),
      MajorBoardRow(playerId: ps[1].id, profileId: ps[1].profileId, displayName: ps[1].name, marker: ps[1].marker,
                    roundId: UUID(uuidString: "55555555-0000-4000-8000-000000000001")!, gross: 88, pvi: -1.0, cards: 1),
      MajorBoardRow(playerId: ps[4].id, profileId: ps[4].profileId, displayName: ps[4].name, marker: ps[4].marker,
                    exhibition: true, roundId: UUID(), gross: 84, pvi: 1.1, cards: 1),
      MajorBoardRow(playerId: ps[2].id, profileId: ps[2].profileId, displayName: ps[2].name, marker: ps[2].marker),
    ]
    return EventRoom(
      event: EventRow(id: id, name: "The Saguaro Jug", created_by: me, league_id: nil, kind: "major",
                      status: "live", starts_on: LeagueDates.addDays(today, -2), session_count: 1,
                      buy_in: 20, pot_split: "places",
                      course_id: "papago-blue", course_label: "Papago"),
      players: ps,
      sessions: [EventSession(id: sess, session_no: 1, opens_on: LeagueDates.addDays(today, -2),
                              closes_on: LeagueDates.addDays(today, 2), status: "open")],
      majorBoard: board)
  }
}
#endif
