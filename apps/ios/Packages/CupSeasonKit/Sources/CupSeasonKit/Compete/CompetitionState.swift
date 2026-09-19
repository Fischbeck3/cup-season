// Cup Season — a competition says which state it is in, in words (F11).
//
// **Ember stopped meaning "live" on 2026-09-15.** The owner's Scoreboard
// direction makes ember the identity of a COMPETITION — a season, a clash, an
// event — before, during and after it is played. That broadens D359's
// active-only rule, and it creates an obligation the old rule did not have:
// if the colour no longer says whether the thing is running, THE WORDS MUST.
//
// So every surface that wears the competition treatment prints one of three
// words beside it. They are not new vocabulary — each is already what the
// product calls that state:
//
//   · Upcoming — a season before its first tee, an event still forming
//     (`seasons.status` before `starts_on`, `events.status = 'setup'`)
//   · Live     — running now (`active` · `cup_final` · `events.status = 'live'`)
//   · Final    — played out (`complete`, the client's `wrapped` phase). The
//     word is `EventCopy.momentLine`'s own, and the Compete section that
//     collects them is still headed FINISHED.
//
// A plain booked round is NOT a competition and takes none of this: it is a
// date in a diary until something is at stake on it.

import Foundation

public enum CompetitionState: String, Sendable, Equatable, CaseIterable {
  case upcoming, live, final

  /// The word a surface prints. Sentence case; a caps surface uppercases it
  /// through its own type role, never through `.uppercased()` (LINT-14).
  public var word: String {
    switch self {
    case .upcoming: return "Upcoming"
    case .live:     return "Live"
    case .final:    return "Final"
    }
  }

  /// What VoiceOver says before the competition's name, so the state is not
  /// carried by colour alone.
  public var spoken: String {
    switch self {
    case .upcoming: return "Upcoming competition"
    case .live:     return "Live competition"
    case .final:    return "Finished competition"
    }
  }

  /// A season, from the status the server already stores and the phase the
  /// client already derives. `nil` for a membership with no season — there is
  /// no competition to state.
  public static func season(status: String?, phase: SeasonPhase?) -> CompetitionState? {
    if let phase {
      switch phase {
      case .wrapped:                 return .final
      case .preseason, .forming:     return .upcoming
      case .season, .cupFinal:       return .live
      }
    }
    switch status {
    case "complete":                 return .final
    case "active", "cup_final":      return .live
    case .some:                      return .upcoming
    case nil:                        return nil
    }
  }

  /// An event (a Ryder, a Major, a callout), from `events.status`.
  /// `cancelled` is not a state a competition panel ever wears — a cancelled
  /// contest is gone, not finished.
  public static func event(status: String?) -> CompetitionState? {
    switch status {
    case "complete":  return .final
    case "live":      return .live
    case "setup":     return .upcoming
    default:          return nil
    }
  }

  /// A week's clash: settled is final, otherwise it is running.
  public static func clash(settled: Bool) -> CompetitionState { settled ? .final : .live }
}
