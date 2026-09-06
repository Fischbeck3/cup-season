// Cup Season — a weekend's identity (D240 / C-3 + R22; IA §8.4; CORE_FLOWS §8.1).
//
// A planned round had a course, a date and tagged golfers — no name, no game
// and nothing on it. `scheduled_rounds` gains `name` and `game` (two columns,
// NOT a third: `stake_cents` is declined in writing, D250 ⑨), and `my_schedule`
// gains `name`, `game`, `tagged_pids` and `rsvp[]` — because the table's only
// SELECT policy is `sched_own` (profile_id = auth.uid()) and a TAGGED golfer
// cannot read the row at all, so two columns no read returns are two columns
// nobody outside the host can see.
//
// THE READ IS HAND-DECLARED, not generated. `my_schedule`'s return type changed
// and the function is unpushed, so `contract.psv` — a verbatim snapshot of prod
// — cannot carry it yet. Every new column is OPTIONAL, so this decodes the OLD
// seventeen-column shape too and simply renders nothing for a plan with no name,
// which is every plan in prod today (L-44).
//
// THREE RULES THE ROSTER OBEYS, each closing a defect a verifier found:
//   1. NO SEAT COUNT. There is no capacity column and C-3 adds none, so "2
//      SEATS" was an assumed foursome — a number that counts nothing (L-44).
//      The head reads `4 IN`.
//   2. NO ABSENCE COLUMN AND NO NUDGE. "Dev — hasn't said" named another
//      golfer's failure on a surface (G7). An asked golfer reads `Dev is asked`
//      — the state of the INVITATION, never a verdict on the man — and there is
//      no chase control and no RPC minted to do it.
//   3. THE INVITE IS A LINK, not a seat (D253's `?plan=` token).

import Foundation

/// One golfer on a plan, and what they said.
public struct PlanSeat: Decodable, Sendable, Equatable, Identifiable {
  public let profile_id: UUID?
  public let display_name: String?
  public let marker: String?
  /// `in` · `out` · `asked` — the host is always `in`; a tagged golfer with no
  /// answer is `asked`, which is a state, not a verdict.
  public let status: String?
  public var id: String { (profile_id?.uuidString ?? "") + (status ?? "") }

  public init(profile_id: UUID? = nil, display_name: String? = nil, marker: String? = nil, status: String? = nil) {
    self.profile_id = profile_id; self.display_name = display_name
    self.marker = marker; self.status = status
  }

  public var isIn: Bool { status == "in" }
  public var isOut: Bool { status == "out" }
  public var isAsked: Bool { !isIn && !isOut }
}

/// `my_schedule`'s row. The seventeen columns the shipped function returns, plus
/// R22's four — every one of the four optional, so the old shape decodes.
public struct SchedulePlan: Decodable, Sendable, Equatable, Identifiable {
  public let id: UUID?
  public let profile_id: UUID?
  public let display_name: String?
  public let marker: String?
  public let play_on: String?
  public let course_label: String?
  public let note: String?
  public let tee_time: String?
  public let mine: Bool?
  public let is_friend: Bool?
  public let shared_league: Bool?
  public let tagged_names: [String]?
  public let tagged_me: Bool?
  public let course_id: String?
  public let rsvp_in: Int?
  public let my_rsvp: String?
  public let comment_n: Int?
  // R22
  public let name: String?
  public let game: String?
  public let tagged_pids: [UUID]?
  public let rsvp: [PlanSeat]?

  public init(id: UUID? = nil, profile_id: UUID? = nil, display_name: String? = nil, marker: String? = nil,
              play_on: String? = nil, course_label: String? = nil, note: String? = nil, tee_time: String? = nil,
              mine: Bool? = nil, is_friend: Bool? = nil, shared_league: Bool? = nil,
              tagged_names: [String]? = nil, tagged_me: Bool? = nil, course_id: String? = nil,
              rsvp_in: Int? = nil, my_rsvp: String? = nil, comment_n: Int? = nil,
              name: String? = nil, game: String? = nil, tagged_pids: [UUID]? = nil, rsvp: [PlanSeat]? = nil) {
    self.id = id; self.profile_id = profile_id; self.display_name = display_name; self.marker = marker
    self.play_on = play_on; self.course_label = course_label; self.note = note; self.tee_time = tee_time
    self.mine = mine; self.is_friend = is_friend; self.shared_league = shared_league
    self.tagged_names = tagged_names; self.tagged_me = tagged_me; self.course_id = course_id
    self.rsvp_in = rsvp_in; self.my_rsvp = my_rsvp; self.comment_n = comment_n
    self.name = name; self.game = game; self.tagged_pids = tagged_pids; self.rsvp = rsvp
  }
}

/// R22 · `my_schedule(p_from, p_to)`, read into the widened row.
public struct MyScheduleCall: RpcCall {
  public static let name = "my_schedule"
  public static let optionalArgs: [String] = []
  public typealias Returns = [SchedulePlan]
  public var p_from: String
  public var p_to: String
  public init(p_from: String, p_to: String) { self.p_from = p_from; self.p_to = p_to }
}

/// C-3 · `declare_round` with the two new arguments. Hand-declared for the same
/// reason: the eight-argument overload is unpushed.
///
/// C-06 · NOTHING is droppable. `SupabaseService.call(_:)` sheds every
/// droppable key on ANY first error, so a 500 or a dropped connection lost the
/// plan's whole D240 identity and could book the weekend twice. The skew the
/// two arguments needed is served instead by a DECLARED fallback in
/// `ScheduleService.declare(...)`, which fires on PGRST202/42883 alone.
public struct DeclarePlanCall: RpcCall {
  public static let name = "declare_round"
  public static let optionalArgs: [String] = []
  public typealias Returns = UUID
  public var p_play_on: String
  public var p_course: String
  public var p_note: String
  public var p_tagged: [UUID]
  public var p_tee: String?
  public var p_course_id: String?
  public var p_name: String?
  public var p_game: String?
}

// MARK: - what a plan says about itself

public extension SchedulePlan {
  /// The name, when it has one. A plan with no name renders NOTHING here — it
  /// is not "Untitled" and it is not the course (L-44).
  var planName: String? {
    guard let n = name?.trimmingCharacters(in: .whitespaces), !n.isEmpty else { return nil }
    return n
  }

  /// The game, as the live round's own noun. `null` is just golf, and just golf
  /// says nothing at all rather than "Just golf" — the absence IS the answer.
  var planGame: LiveGame? {
    guard let g = game, !g.isEmpty, g != "just_golf" else { return nil }
    return LiveGame(rawValue: g)
  }

  /// "Skins" — the one line under the head, when there is a game.
  var gameLine: String? { planGame?.segLabel }

  /// Everyone on it, host first. Falls back to the names-only shape a
  /// pre-migration read returns, so the roster is never blank on an old payload.
  var seats: [PlanSeat] {
    if let r = rsvp, !r.isEmpty { return r }
    var out: [PlanSeat] = []
    if let p = profile_id { out.append(PlanSeat(profile_id: p, display_name: display_name, marker: marker, status: "in")) }
    for n in tagged_names ?? [] { out.append(PlanSeat(display_name: n, status: "asked")) }
    return out
  }

  /// `4 IN` — a COUNT OF ANSWERS, never a count of seats. There is no capacity
  /// column and there is not going to be one.
  var inCount: Int {
    if let r = rsvp, !r.isEmpty { return r.filter(\.isIn).count }
    return max(1, rsvp_in ?? 1)
  }
  var inLine: String { "\(inCount) IN" }

  /// "Dev is asked" — the state of the invitation. G7: a surface never names
  /// another golfer's failure, and there is no nudge control anywhere near it.
  static func askedLine(_ names: [String]) -> String? {
    guard !names.isEmpty else { return nil }
    let firsts = names.map { CSBands.fn1($0) }
    if firsts.count == 1 { return "\(firsts[0]) is asked" }
    if firsts.count == 2 { return "\(firsts[0]) and \(firsts[1]) are asked" }
    return firsts.dropLast().joined(separator: ", ") + " and \(firsts.last!) are asked"
  }
  var askedLine: String? { Self.askedLine(seats.filter(\.isAsked).compactMap(\.display_name)) }
}

/// The weekend sheet's own copy (CORE_FLOWS §8.1).
public enum PlanCopy {
  public static let nameLabel = "Call it something"
  public static let nameOptional = "optional"
  public static let namePlaceholder = "Saturday at Papago"
  public static let gameLabel = "Playing anything?"
  public static let justGolf = "Just golf"
  public static let stakeDoor = "Put something on it"
  /// L-32 · the door says what it opens: a forfeit, not a fourth money noun.
  public static let stakeGloss = "a forfeit — a bet in words"

  /// The four the plan may carry, in the sheet's order. `nil` is Just golf.
  public static let games: [LiveGame?] = [nil, .skins, .match, .wolf]
  public static func gameLabelFor(_ g: LiveGame?) -> String { g?.segLabel ?? justGolf }
  /// The server's own value. "Just golf" is the ABSENCE of a game, and the
  /// migration turns `just_golf` into null rather than storing a fifth word.
  public static func gameValue(_ g: LiveGame?) -> String? { g?.rawValue }

  /// The pre-fill: the course and the day, which is what an organiser would
  /// have typed. Never minted for them — it is a placeholder, not a value.
  public static func suggestedName(course: String?, playOn: String?) -> String? {
    guard let c = course?.trimmingCharacters(in: .whitespaces), !c.isEmpty, let d = playOn,
          let dow = ScheduleDates.jsDay(d) else { return nil }
    let day = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][dow]
    let club = c.components(separatedBy: " — ").first ?? c
    return "\(day) at \(club.components(separatedBy: " · ").first ?? club)"
  }

  /// Nobody tagged, and this is the organiser the brief describes.
  public static let justYou = "Just you so far. The link works for anyone."
  /// When it finishes, once (D240: a weekend may be promoted; never the reverse).
  public static func promotion(_ n: Int) -> String { "\(WizardCopy.numberWord(n).capitalized) of you played. Make it a thing?" }
}
