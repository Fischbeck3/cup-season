// Cup Season — what the first round turns on (IOS-046, `surfaces/home.md` §2).
//
// The brand-new Home is the one screen in the product with nothing on it: no
// number, no round, no season, no buddies. The blind review measured the void
// at ~350pt and said so in three different words, and the answer the design
// drew is three rule-separated rows — **your number moves · the course keeps
// it · your friends see it** — which are three facts about the product rather
// than three promises about the golfer.
//
// It lives in the Kit and not in the view for the reason every sentence on
// Home does: the desk prints the same three rows in its right column, off the
// same payload, and a sentence produced twice is a sentence that drifts.
//
// **EVERY GLOSS DEGRADES TO A TRUE SENTENCE.** A golfer who picked no band has
// no starter figure and a golfer who named no home course has no course, and
// neither absence may print a blank, a dash or a guessed name (L-44).

import Foundation

public enum HomeFirstRound {

  /// One row: the verb, and the fact under it.
  public struct Row: Sendable, Equatable, Identifiable {
    public let key: String
    public let verb: String
    public let gloss: String
    public var id: String { key }
    public init(key: String, verb: String, gloss: String) {
      self.key = key; self.verb = verb; self.gloss = gloss
    }
  }

  /// The section's own eyebrow.
  public static let eyebrow = "One round from here"

  /// The line under the starter figure in the ME strip. It is agate in
  /// **sentence** case (§1.3): a phrase a person could read aloud, not a label.
  public static let starterLine = "A starter, until three rounds land."

  /// The three rows.
  ///
  /// - `starter` is D247's band, held on the device — `StarterIndex.current`.
  /// - `homeCourse` is `profiles.home_course`, and it is a name the golfer
  ///   typed, so it is printed as they typed it.
  public static func rows(starter: String? = nil, homeCourse: String? = nil) -> [Row] {
    [
      Row(key: "number", verb: "Your number moves",
          gloss: starter.map { "\($0) becomes yours, not ours" } ?? "It stops being a guess"),
      Row(key: "course", verb: "The course keeps it",
          gloss: homeCourse.map { "\($0) remembers your best" } ?? "Every course remembers your best"),
      Row(key: "friends", verb: "Your friends see it",
          gloss: "The moment you join a season"),
    ]
  }
}
