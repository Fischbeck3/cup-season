// Cup Season — WHAT A TAB SAYS WHEN IT HAS NOTHING (L-32, pattern P-11).
//
// L-32 has two halves and the second is the one that keeps getting lost:
//
//   1 · every empty state ends in a NEXT MOVE. Not an illustration, not an
//       apology, not a disabled control — a door a finger can land on.
//   2 · a FAILED READ IS NEVER AN EMPTY ONE. "No buddies yet" over a network
//       error is a lie the golfer cannot tell is a lie, and they will go and
//       add the friends they already have.
//
// So the two are different values of the same type, and every producer that
// can return one can return the other. The door list is never empty — the
// initialiser has no way to express that, because a state with no move is the
// defect this file exists to make unwritable.

import Foundation

public struct EmptyRoot: Sendable, Equatable {
  /// What a door is FOR. The screen wires the verb; the producer never holds a
  /// closure, so an empty root stays a value a test can hold.
  public enum Door: Sendable, Equatable {
    case startSomething, joinWithCode, findGolfers, personLink, addMyRound, retry

    public var title: String {
      switch self {
      case .startSomething: "Start something"
      case .joinWithCode:   "I have a code"
      case .findGolfers:    "Find golfers"
      case .personLink:     "Text someone a link"
      case .addMyRound:     "Add my round"
      case .retry:          "Try again"
      }
    }
  }

  /// The bold line. A sentence, always — never a noun on its own.
  public let head: String
  /// A TRUE fact about the golfer, or nil. Never a guess and never a
  /// consolation: with nothing real to say the line is omitted (L-44).
  public let fact: String?
  /// The line that says what this place is for.
  public let sub: String
  /// At least one, and the first is the primary.
  public let doors: [Door]

  public init(head: String, fact: String? = nil, sub: String, doors: [Door]) {
    self.head = head; self.fact = fact; self.sub = sub
    self.doors = doors.isEmpty ? [.addMyRound] : doors
  }

  /// QB-05 · **WHAT THE WIRE SAYS WHEN NO BUDDY HAS POSTED.**
  ///
  /// It said, unconditionally, *"No rounds from your buddies yet. Post one, or
  /// add some buddies."* The first sentence is true and fine. The second is a
  /// claim about the golfer's life, and for a member of a season it is false:
  /// a blind walker met it ninety seconds after a covenant that had named all
  /// six golfers in his season, and wrote that it was *"worse than silence"*.
  ///
  /// So the second clause branches on the roster. With a season the next move
  /// is that season's own roster — which for a golfer whose season has not
  /// teed off is the only true, interesting, non-empty thing about his account.
  /// With genuinely nobody, the buddies door is still exactly right.
  ///
  /// The head never claims anything about people: an empty wire is an empty
  /// wire in both branches.
  public struct WireEmpty: Sendable, Equatable {
    public let head: String
    public let door: String
    /// nil means the door is the buddies list.
    public let leagueId: UUID?
  }

  public static func wireEmpty(me: Me?, today: String = CSDate.today()) -> WireEmpty {
    let seasons = (me?.memberships ?? []).filter { m in
      if case .wrapped = SeasonPhase.of(m, today: today) { return false }
      return (m.members ?? m.headcount ?? 0) >= 2
    }
    let pick = seasons.min { a, b in
      (a.season?.starts_on ?? "9999-12-31") < (b.season?.starts_on ?? "9999-12-31")
    }
    guard let m = pick else {
      return WireEmpty(head: "No rounds from your buddies yet. Post one, or",
                       door: "add some buddies.", leagueId: nil)
    }
    return WireEmpty(head: "No rounds from your buddies yet.",
                     door: "See who\u{2019}s in \(m.name).", leagueId: m.league_id)
  }

  /// The failed read, said plainly, with the only honest next move on it.
  /// Deliberately NOT parameterised by tab: a read that failed failed the same
  /// way everywhere, and a per-screen apology is a per-screen voice.
  public static func failedRead(retry: String = Door.retry.title) -> EmptyRoot {
    EmptyRoot(head: "Couldn’t load this.",
              fact: nil,
              sub: "That is us, not you — your seasons and your buddies are all still there.",
              doors: [.retry])
  }
}
