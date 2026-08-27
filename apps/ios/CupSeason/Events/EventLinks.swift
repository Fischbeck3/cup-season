// Cup Season — where an event surface goes when tapped. The shell wires
// these: the room is a pushed screen (`openEvent`), a leaderboard figure
// opens its round receipt (§16), a name opens the Tour Card.

import Foundation

struct EventLinks {
  var openEvent: (UUID) -> Void = { _ in }
  var openReceipt: (UUID) -> Void = { _ in }
  var openTourCard: (UUID) -> Void = { _ in }
}
