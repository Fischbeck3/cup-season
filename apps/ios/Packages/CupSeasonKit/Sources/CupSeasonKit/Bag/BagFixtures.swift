// Cup Season — the bag's screenshot fixtures (D262, IOS-042, R-O).
//
// `-cs_dev_bag <id>` substitutes a Bag for `bag_of`'s answer, the way
// `-cs_dev_home_state <id>` substitutes Home's one read. It exists because the
// bag's states are the golfer's OWN DATA: an account with an empty bag cannot
// photograph a full one, and the only ways to fill it are to type fourteen
// clubs into a simulator with no keyboard, or to write fourteen clubs into
// production to take a picture of them. Neither is acceptable.
//
// **THIS IS NOT A BAG ANYBODY OWNS, AND IT NEVER REACHES THE SERVER.** D261's
// rule stands: a fabricated bag presented as a golfer's real one is a lie
// about the feature. A fixture used to photograph a STATE is not, provided it
// is DEBUG-only, never written, and always labelled as a fixture wherever the
// picture is shown. All three conditions hold here — `BagService.save` is
// untouched, so a fixture cannot be saved even by accident.
//
// The clubs are deliberately written the way a golfer types them, because the
// whole refusal in `Bag.swift` is that there is no equipment database: the
// point of the screenshot is that `label` is a sentence somebody wrote, not a
// row picked out of a catalogue.

import Foundation

public enum BagFixtures {

  /// The launch argument's word: `-cs_dev_bag <id>`.
  public static func named(_ id: String) -> Bag? {
    switch id {
    case "empty":  return Bag(visible: true, isMe: true)
    case "filled": return filled
    case "full":   return full
    case "short":  return short
    default:       return nil
    }
  }

  /// A bag somebody has actually thought about: fourteen minus one, two on the
  /// sideline, a ball, and the line the server computes about the newest club.
  public static var filled: Bag {
    Bag(visible: true, isMe: true,
        clubs: [
          item("Driver",  "TSR3 9° · Ventus Blue 6S", "2026-08-14"),
          item("3-wood",  "TSi2 15° · stiff"),
          item("5-wood",  "TSi2 18° — the one I actually hit"),
          item("4-iron",  "T200 · driving iron feel"),
          item("5-iron",  "T150"),
          item("6-iron",  "T150"),
          item("7-iron",  "T150"),
          item("8-iron",  "T150"),
          item("9-iron",  "T150"),
          item("PW",      "T150 · 46°"),
          item("50°",     "SM10 · F grind"),
          item("54°",     "SM10 · S grind"),
          item("58°",     "SM10 · M grind — new grind, still deciding"),
          item("Putter",  "Newport 2 · 34in"),
        ],
        sideline: [
          item("3-iron",  "T200 — swaps in for the 5-wood when it's windy"),
          item("60°",     "SM9 · L grind, for firm greens"),
        ],
        ball: Bag.Item(label: "Pro V1"),
        since: Bag.Since(slot: "Driver", label: "TSR3 9° · Ventus Blue 6S",
                         addedOn: "2026-08-14", rounds: 4, beat: 2))
  }

  /// Four clubs and two on the sideline — small enough that the sideline, the
  /// ball and the Save button are all on one screen, which is the shape of the
  /// feature rather than a state anybody is in.
  public static var short: Bag {
    Bag(visible: true, isMe: true,
        clubs: [
          item("Driver", "TSR3 9° · Ventus Blue", "2026-08-14"),
          item("5-wood", "TSi2 18°"),
          item("7-iron", "T150"),
          item("Putter", "Newport 2"),
        ],
        sideline: [
          item("3-iron", "T200 — in when it's windy"),
          item("60°",    "SM9 · L grind"),
        ],
        ball: Bag.Item(label: "Pro V1"),
        since: Bag.Since(slot: "Driver", label: "TSR3 9° · Ventus Blue",
                         addedOn: "2026-08-14", rounds: 4, beat: 2))
  }

  /// Fourteen in the bag, so the add control is gone and the cap's own
  /// sentence stands in its place.
  public static var full: Bag {
    let b = filled
    return Bag(visible: true, isMe: true,
               clubs: b.clubs + [item("64°", "the lob wedge I keep putting back in")],
               sideline: b.sideline, ball: b.ball, since: b.since)
  }

  private static func item(_ slot: String, _ label: String, _ added: String? = nil) -> Bag.Item {
    Bag.Item(serverId: UUID(), slot: slot, label: label, addedOn: added)
  }
}
