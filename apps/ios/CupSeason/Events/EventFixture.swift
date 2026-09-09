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
  ///
  /// **AND FOR ONE DAY IT DID.** Four of the twelve carried `cactus`, `arroyo`,
  /// `mesa` and `bloom` — none of which are among the fourteen — so those four
  /// faces fell back to the saguaro under a comment saying they would not.
  /// Found on re-reading during D309's wave and recorded in D308's backfilled
  /// entry. There is **no check that a marker key resolves**; until there is,
  /// a key added here is verified against `CSMarkers.all` by hand.
  /// **TWELVE, SO EVERY SHAPE THE PRODUCT SELLS CAN BE LOOKED AT** (D308).
  /// The owner: *"I also want to see examples from more diverse league/event
  /// types (2v2, 6v6, 12 individuals)."* The cast was six, which could only
  /// ever draw a 3v3 and a five-player major — so the two-a-side room, the
  /// six-a-side room and a full individual field had never been photographed
  /// by anybody, and no screenshot in this repo shows what the app does when a
  /// roster is longer than a screen.
  private static let cast: [(String, String)] = [
    ("Galen Marr", "lonetree"), ("Jade Okafor", "shark"), ("Tash Bell", "dunes"),
    ("Jerecho", "saguaro"), ("Dev Rana", "azalea"), ("Mike Fenner", "pews"),
    ("Ruth Alderi", "island"), ("Cam Petrie", "lighthouse"), ("Noor Haddad", "thistle"),
    ("Sol Barrera", "weebridge"), ("Wes Tanaka", "no2"), ("Priya Anand", "stamp"),
  ]

  /// `-cs_dev_field <n>` — how many golfers are in the room. The Ryder splits
  /// it down the middle (4 = 2v2, 12 = 6v6); the major runs it as one field.
  /// Clamped to the cast, and to an even number for a team room.
  static var devField: Int? {
    let a = ProcessInfo.processInfo.arguments
    guard let i = a.firstIndex(of: "-cs_dev_field"), i + 1 < a.count, let n = Int(a[i + 1]) else { return nil }
    return max(2, min(cast.count, n))
  }

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
  /// **THE IDS STAY FIXED AT ANY FIELD SIZE.** The old format padded to eleven
  /// zeros and appended one digit, so a twelfth player produced a 13-character
  /// tail, an invalid UUID and a random one per launch — which is exactly the
  /// drift the note below says the fixed ids exist to prevent. `%012d` is the
  /// same value for i < 10 and correct above it.
  private static func players(_ me: UUID?, field: Int) -> [EventPlayer] {
    let n = max(2, min(cast.count, field))
    let half = n / 2
    // The viewer sits on side B when the field has one, so a roster always
    // shows "you" against somebody rather than captaining from row one.
    let mineIdx = min(3, n - 1)
    return cast.prefix(n).enumerated().map { i, who in
      EventPlayer(id: UUID(uuidString: String(format: "11111111-0000-4000-8000-%012d", i)) ?? UUID(),
                  profileId: i == mineIdx ? me
                    : UUID(uuidString: String(format: "22222222-0000-4000-8000-%012d", i)),
                  teamId: i < half ? teamA : teamB,
                  role: (i == 0 || i == half) ? "captain" : "player",
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
    let n = devField ?? 6
    let ps = players(me, field: n)
    let half = ps.count / 2
    let a = Array(ps.prefix(half)), b = Array(ps.suffix(half))
    let today = CSDate.today()
    let opens = LeagueDates.addDays(today, -1)
    let closes = LeagueDates.addDays(today, 2)
    let sessions = [
      EventSession(id: sessPrior, session_no: 1, opens_on: LeagueDates.addDays(today, -8),
                   closes_on: LeagueDates.addDays(today, -2), status: "closed"),
      EventSession(id: sess, session_no: 2, opens_on: opens, closes_on: closes,
                   status: complete ? "closed" : "open"),
    ]
    // **ONE CLASH PER PAIR, AT ANY SIZE.** The week used to be three hand-built
    // duels indexed at 0..5, which is why the fixture could only ever be a 3v3.
    // The pairing is captain-against-captain down the order, and the STATES are
    // held: the viewer's own clash is open, one is resolved, one is unposted,
    // and the rest fill in behind them so a long roster looks like a real week
    // rather than a column of pending.
    let mineIdx = min(3, ps.count - 1)
    let duels: [EventDuel] = (0..<half).map { k in
      let x = a[k], y = b[k]
      let isMine = x.id == ps[mineIdx].id || y.id == ps[mineIdx].id
      let resolved = !isMine && k % 2 == 1
      return EventDuel(id: UUID(uuidString: String(format: "33333333-0000-4000-8000-%012d", k + 1)) ?? UUID(),
                       session_id: sess, a_player: x.id, b_player: y.id,
                       a_pvi: resolved ? 2.1 : nil,
                       b_pvi: resolved ? -0.4 : (isMine && complete ? -0.6 : nil),
                       result: resolved ? "a" : (isMine && complete ? "b" : "pending"))
    }
    let targets: [UUID: EventTarget] = duels.isEmpty ? [:]
      : [duels[0].id: EventTarget(a: nil, b: 0.8)]
    return EventRoom(
      event: EventRow(id: id, name: "The Dew Sweepers Cup", created_by: me, league_id: nil,
                      kind: "ryder", status: complete ? "complete" : "live",
                      starts_on: LeagueDates.addDays(today, -8), session_count: 3, session_weeks: 1,
                      winner_team_id: complete ? teamA : nil, buy_in: 80, pot_split: "places",
                      course_id: "gold-canyon-dinosaur", course_label: "Gold Canyon — Dinosaur Mountain"),
      teams: [EventTeam(id: teamA, slot: 0, name: "Saguaros", color: 0, captain_player_id: a.first?.id),
              EventTeam(id: teamB, slot: 1, name: "Coyotes", color: 3, captain_player_id: b.first?.id)],
      players: ps, sessions: sessions, duels: duels,
      scoreboard: [teamA: complete ? Double(half) + 1 : Double(half) / 2 + 0.5,
                   teamB: complete ? Double(half) : Double(half) / 2 - 0.5],
      targets: targets,
      posts: [EventPost(id: UUID(uuidString: "44444444-0000-4000-8000-000000000001")!, kind: "event",
                        body: "Week 2 is open — three clashes, best round each.", created_at: Date())])
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
    let ps = players(me, field: devField ?? 5)
    // **A LEADERBOARD THE LENGTH OF ITS FIELD.** Five rows were hand-written and
    // hand-ordered, so a twelve-golfer major could not be drawn at all — and
    // §15 (a leaderboard is scannable) has never been judged against a field
    // that runs past the fold. The shape is kept exactly: a leader with two
    // cards, a spread of grosses, ONE exhibition row that scores nothing, and
    // one golfer who has not posted.
    let card = UUID(uuidString: "55555555-0000-4000-8000-000000000001")!
    let grosses = [76, 79, 81, 83, 84, 86, 88, 90, 91, 93, 95, 97]
    let board: [MajorBoardRow] = ps.enumerated().map { i, p in
      // the last golfer has not posted; the second-to-last is an exhibition
      if i == ps.count - 1 {
        return MajorBoardRow(playerId: p.id, profileId: p.profileId, displayName: p.name, marker: p.marker)
      }
      let gross = grosses[min(i, grosses.count - 1)]
      return MajorBoardRow(playerId: p.id, profileId: p.profileId, displayName: p.name, marker: p.marker,
                           exhibition: i == ps.count - 2,
                           roundId: i == ps.count - 2 ? UUID() : card,
                           gross: gross, pvi: Double(82 - gross) / 2,   // lands on .0 or .5 — one decimal by construction
                           cards: i == 0 ? 2 : 1)
    }
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
