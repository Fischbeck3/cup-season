// Cup Season — where an event surface goes when tapped. The shell wires
// these: the room is a pushed screen (`openEvent`), a leaderboard figure
// opens its round receipt (§16), a name opens the Tour Card.
//
// Wave 6 adds the three the title card's ONE PRIMARY needs. §2 E is *one
// primary, and it is the live thing you can do now* — which on every state of
// every event kind is one of: post a round, see the receipt you already have,
// or call him out again. Each was a `CSMini` in a `FlowRow` or nothing at all.

import Foundation

struct EventLinks {
  var openEvent: (UUID) -> Void = { _ in }
  var openReceipt: (UUID) -> Void = { _ in }
  var openTourCard: (UUID) -> Void = { _ in }
  /// **Add my round** — the surface's one ember act while a week is open.
  var addRound: () -> Void = { }
  /// The callout's foot door: the full record between the two of you.
  var openHeadToHead: (UUID) -> Void = { _ in }
  /// A closed callout's primary — **Call him out again**, the same door the
  /// person page raises, at the same length picker (R-F).
  var callOut: (UUID) -> Void = { _ in }
}
