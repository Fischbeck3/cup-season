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
