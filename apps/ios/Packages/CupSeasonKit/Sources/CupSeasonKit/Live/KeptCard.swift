// Cup Season — the round the server could not take, handed back to the golfer.
//
// A live round dies server-side twenty-four hours after tee-off. Until now the
// strokes died with it: the queue dropped them one by one on "Round is not
// live" and the next cold launch deleted the snapshot. They are KEPT now
// (`LiveDisk.retire`) — but a card kept with no door is bytes in Application
// Support, and the toast that promises "saved on this phone to post yourself"
// is only true if there is a way to post it.
//
// This is that way: a kept `LiveRoundState` becomes a `PostCard`, and the
// golfer posts it himself through the composer he already knows.
//
// **IT NEVER POSTS BY ITSELF, AND THAT IS THE WHOLE DESIGN.** `rounds` has one
// unique index — `rounds_pkey` on a random uuid — so there is no idempotency
// key and no server-side dedupe. An automatic sync would be a duplicate-round
// machine. Worse, the round's scoring window has usually closed: the weekly
// clash is settled by the daily tick the morning after its last day and
// `settle_week_clash` never re-settles, and `run_event_sessions` resolves duels
// on the same spine. A round that arrives after those is not a late score, it
// is a different round. So the golfer is shown what he has and decides.

import Foundation

public struct KeptCard: Sendable, Equatable, Identifiable {
  /// The live round this came from — the key for dismissing it.
  public let lr: UUID
  public let course: String
  public let courseId: String?
  /// YYYY-MM-DD, from tee-off. Nil on a card written before `startedAt`
  /// existed: the composer then opens on today and the golfer sets the date,
  /// which is honest, where a guessed date would not be (L-07, L-44).
  public let playedOn: String?
  /// My strokes, hole by hole. Zero means "not written", never a score.
  public let scores: [Int]
  public let holesPlayed: Int
  public let total: Int
  public let rating: Double?
  public let slope: Int?
  public let pars: [Int]
  public var id: UUID { lr }

  /// An 18-hole card with every hole written. A card with gaps is still worth
  /// keeping and still worth showing — it is just not a round to post whole.
  public var isComplete: Bool { holesPlayed == 18 }

  /// "Papago Golf Course · Sunday · 14 of 18 holes" — what the row says.
  public var line: String {
    let holes = isComplete ? "\(total)" : "\(holesPlayed) of 18 holes"
    return [course.isEmpty ? "A round" : course, holes].joined(separator: " · ")
  }
}

public enum KeptCards {

  /// The kept cards, newest first, as rows a golfer can act on. A card with no
  /// strokes of MINE on it is dropped: somebody else's scoring is not my round
  /// to post (L-19 — never a vouch, and never somebody else's number).
  public static func rows(_ states: [LiveRoundState]) -> [KeptCard] {
    states.compactMap(card(from:))
  }

  public static func card(from s: LiveRoundState) -> KeptCard? {
    guard let lr = s.lr else { return nil }
    // My seat. `me` is set by the roster prime on every phone that has one;
    // a solo pencil is seat 0 by construction.
    let seat = s.players.firstIndex(where: { $0.me }) ?? (s.players.count == 1 ? 0 : nil)
    guard let seat, s.scores.indices.contains(seat) else { return nil }
    let raw = s.scores[seat]
    let scores = (0..<18).map { i in raw.indices.contains(i) ? (raw[i] ?? 0) : 0 }
    let played = scores.filter { $0 > 0 }.count
    guard played > 0 else { return nil }
    return KeptCard(lr: lr,
                    course: s.course.label.trimmingCharacters(in: .whitespaces),
                    courseId: s.course.courseId,
                    playedOn: s.startedAt.flatMap(day(fromMillis:)),
                    scores: scores,
                    holesPlayed: played,
                    total: scores.reduce(0, +),
                    rating: s.course.rating,
                    slope: s.course.slope,
                    pars: s.course.pars.count == 18 ? s.course.pars : PostCard.parStd)
  }

  /// The composer, seeded. Holes mode with the strokes in the grid, so the
  /// golfer SEES what was kept and can fix a gap before he posts — rather than
  /// being handed a total he has to trust.
  public static func compose(_ k: KeptCard) -> PostCard {
    var c = PostCard()
    c.mode = .holes
    c.side = 18
    c.pars = k.pars
    c.parsCourse = k.course
    c.scores = k.scores
    c.touched = true
    c.course = k.course
    c.courseId = k.courseId
    c.date = k.playedOn
    if let r = k.rating { c.rating = String(r) }
    if let s = k.slope { c.slope = String(s) }
    return c
  }

  /// A calendar day from a millisecond stamp, in the phone's own zone. L-07:
  /// the day is a String from here on and never goes back through a parser.
  static func day(fromMillis ms: Int64) -> String {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = .current
    return CSDate.iso(Date(timeIntervalSince1970: Double(ms) / 1000), calendar: cal)
  }
}
