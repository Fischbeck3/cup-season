// Cup Season — what happened to the round I just finished (F12).
//
// The owner finished a booked round, was offered no photograph, could not find
// the round on Home, and went on being told a round was scheduled that day.
// Read-only evidence from production settled the facts before any of this was
// written: the round WAS posted, one round that day, no photograph attached,
// four board posts, and the booking still standing because **nothing in the
// schema can record that a booking was played** — `scheduled_rounds` has no
// completion column, and the post that would carry the pointer had none set.
//
// Two things follow, and they are separate:
//
// 1 · **The truth about the save is not a mood.** A recap that says "nothing
//     to post" and a recap that says "your round is on the books" are
//     different sentences, and the product must never infer the second from a
//     refreshed handicap or a cheerful title. `SaveStatus` is the only place
//     those words are chosen.
//
// 2 · **Which round is MINE cannot be guessed from a name.** `finish_live_round`
//     returns `{name, gross, holes}` per posted card — no round id, no profile
//     id — so the recap has never been able to open the viewer's own receipt.
//     Until that payload carries the id (a migration, written and not pushed),
//     the round is found by the evidence the finding itself sanctions: the same
//     golfer, the same COURSE ID and the same local played date. A course
//     label is not evidence, and two candidates are not a match — they are a
//     question.

import Foundation

public enum RoundReconcile {

  // MARK: - what happened to the card

  /// The three outcomes a golfer may be in after a finish, and the only
  /// sentences the product uses for them.
  public enum SaveStatus: Equatable, Sendable {
    /// On the books: the server took it and it is scoring.
    case posted
    /// On this phone, and not yet on the books — a real state, not a failure.
    case savedOnThisPhone
    /// Not posted, with the reason the server gave.
    case notPosted(reason: String)
    /// The server did not say WHOSE card it posted (a payload from before
    /// 20261105090000), and nothing authoritative has confirmed it yet. The
    /// product says so rather than guessing from a name.
    case unconfirmed

    public var title: String {
      switch self {
      case .posted:           return "Round posted"
      case .savedOnThisPhone: return "Saved on this phone"
      case .notPosted:        return "Not posted"
      case .unconfirmed:      return "Not confirmed yet"
      }
    }

    public var detail: String {
      switch self {
      case .posted:
        return "It's on the books and scoring."
      case .savedOnThisPhone:
        return "It's kept here. Review the scorecard and post it when you're connected."
      case .notPosted(let reason):
        return reason.isEmpty ? "Nothing was written down." : reason
      case .unconfirmed:
        return "Check your rounds before posting it again."
      }
    }

    /// Only a posted round has a receipt to open or a photograph to attach.
    public var hasRound: Bool { self == .posted }
  }

  /// One card the server reported. `profileId` is the identity; `name` is
  /// only what it printed, and two golfers may print the same name.
  public struct Card: Equatable, Sendable {
    public let name: String
    public let profileId: UUID?
    public let roundId: UUID?
    public let reason: String?
    public init(name: String, profileId: UUID? = nil, roundId: UUID? = nil, reason: String? = nil) {
      self.name = name; self.profileId = profileId; self.roundId = roundId; self.reason = reason
    }
  }

  /// The viewer's own status, decided by PROFILE ID — never by a display name,
  /// which another golfer in the group may share (Codex R3). A payload that
  /// carries no identities at all is `.unconfirmed` until `confirm(...)` finds
  /// the round by authoritative evidence; a shared name or somebody else's
  /// posted card is never enough to say "Round posted".
  ///
  /// A CASUAL round posts nothing by design, and that is not a failure: it is
  /// said as what it is rather than dressed as an error.
  public static func status(posted: [Card], skipped: [Card], casual: Bool, keptLocally: Bool, me: UUID?) -> SaveStatus {
    if keptLocally { return .savedOnThisPhone }
    if casual { return .notPosted(reason: "A casual round scores nothing — nobody's card was posted.") }
    let identified = posted.contains { $0.profileId != nil } || skipped.contains { $0.profileId != nil }
    if let me, identified {
      if posted.contains(where: { $0.profileId == me }) { return .posted }
      if let s = skipped.first(where: { $0.profileId == me }) { return .notPosted(reason: s.reason ?? "") }
      // identities were reported and mine is not among them
      return .notPosted(reason: "")
    }
    if posted.isEmpty && skipped.isEmpty { return .notPosted(reason: "") }
    return .unconfirmed
  }

  /// The viewer's round id straight from the payload, when the server named it.
  public static func namedRound(posted: [Card], me: UUID?) -> UUID? {
    guard let me else { return nil }
    return posted.first { $0.profileId == me }?.roundId
  }

  /// Resolve an `.unconfirmed` status against authoritative evidence: my own
  /// rounds, this course id, this day. Exactly one match confirms a post;
  /// anything else stays unconfirmed — the product never becomes more sure
  /// than the receipt it can open.
  public static func confirm(_ status: SaveStatus, match: Match) -> SaveStatus {
    guard status == .unconfirmed else { return status }
    if case .one = match { return .posted }
    return status
  }

  // MARK: - which round is mine

  /// The least a candidate must carry to be matched. Deliberately not the
  /// course NAME: "Bajamar" is written four ways and matches the wrong round.
  public struct Candidate: Equatable, Sendable {
    public let id: UUID
    public let courseId: String?
    public let playedOn: String?
    public init(id: UUID, courseId: String?, playedOn: String?) {
      self.id = id; self.courseId = courseId; self.playedOn = playedOn
    }
  }

  public enum Match: Equatable, Sendable {
    /// Exactly one round matches on golfer, course id and played date.
    case one(UUID)
    /// More than one could be it. **Ask**; never link the wrong round.
    case ambiguous([UUID])
    /// Nothing matches — the round may be local, skipped, or not there yet.
    case none
  }

  /// The viewer's round for a course and a day, from rounds already in hand.
  /// `courseId` nil means the booking or the live round never named a course
  /// id, and then there is no evidence to match on: the answer is `none`,
  /// not a guess from the label.
  public static func mine(_ rounds: [Candidate], courseId: String?, playedOn: String?) -> Match {
    guard let courseId, !courseId.isEmpty, let playedOn, !playedOn.isEmpty else { return .none }
    let hits = rounds.filter { $0.courseId == courseId && $0.playedOn == playedOn }
    switch hits.count {
    case 0:  return .none
    case 1:  return .one(hits[0].id)
    default: return .ambiguous(hits.map(\.id))
    }
  }

  // MARK: - has this booking been played, by ME

  public enum Booking: Equatable, Sendable {
    /// This golfer played it: one round, same course, same day.
    case played(UUID)
    /// Candidates exist but more than one — the golfer is asked, not told.
    case askWhich([UUID])
    /// Nothing says it was played, so it keeps prompting.
    case open
  }

  /// **Per golfer, never for the whole group.** A host finishing a round says
  /// nothing about whether an invited golfer played; each reconciles against
  /// their OWN rounds. A cancelled booking is not reconciled at all — it is
  /// gone, which is a different thing from played.
  public static func booking(courseId: String?, playOn: String?, myRounds: [Candidate]) -> Booking {
    switch mine(myRounds, courseId: courseId, playedOn: playOn) {
    case .one(let id):        return .played(id)
    case .ambiguous(let ids): return .askWhich(ids)
    case .none:               return .open
    }
  }

  /// The one question an ambiguous match is allowed to ask.
  public static let askWhichRound = "Which round was this?"
  /// What the booking says once it is reconciled — it stops prompting, and it
  /// does not claim a result it has not read.
  public static let bookingPlayed = "You played this one"
}

// MARK: - Home: a booking I have played stops prompting me

extension RoundReconcile {
  /// F12 · drop every `plan:` item on Home whose booking THIS golfer has
  /// already played — matched on the booking's course id and day against the
  /// golfer's own rounds. Everything else passes through untouched, including
  /// a plan whose course id is unknown (no evidence, so it keeps prompting)
  /// and an ambiguous day (two rounds on that course: asked, not dropped).
  public static func droppingPlayedPlans(_ items: [HomeDispatch.Item], myRounds: [Candidate]) -> [HomeDispatch.Item] {
    // Codex R5 · one round and TWO bookings at that course on that day: the
    // round cannot be assigned to either, so neither is dropped — the golfer
    // keeps both reminders rather than losing the one they have not played.
    var competing: [String: Int] = [:]
    for it in items where it.key.hasPrefix("plan:") {
      if let p = it.plan, let c = p.courseId, let d = p.playOn { competing["\(c)#\(d)", default: 0] += 1 }
    }
    return items.filter { it in
      guard it.key.hasPrefix("plan:"), let p = it.plan else { return true }
      if let c = p.courseId, let d = p.playOn, competing["\(c)#\(d)", default: 0] > 1 { return true }
      if case .played = booking(courseId: p.courseId, playOn: p.playOn, myRounds: myRounds) { return false }
      return true
    }
  }
}
