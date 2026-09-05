import Testing
import Foundation
@testable import CupSeasonKit

/// D222 / IOS-028 · the nav went from four slots to five, and the expensive
/// half of that change is not the bar — it is that every route still points
/// somewhere that exists.
///
/// These are the assertions that make the retarget structural instead of
/// remembered. `MainTabView.apply(_:)` derives its tab from `NavSlot.of(_:)`,
/// so a case that resolves to a slot that no longer exists cannot compile, and
/// a case that resolves to the WRONG slot fails here.
@Suite struct RouteMapTests {

  private static let L = UUID(), R = UUID(), LR = UUID(), E = UUID(), SR = UUID()

  /// The five, and only the five.
  @Test func thereAreExactlyFiveSlots() {
    #expect(NavSlot.allCases.count == 5)
    #expect(NavSlot.allCases.map(\.rawValue) == ["home", "compete", "play", "golfers", "you"])
    // R-D settled the two names. "Clubhouse" is retired from every user
    // surface (O-06) and "Post" is retired because the tab does not post.
    #expect(NavSlot.allCases.map(\.label) == ["Home", "Compete", "Play", "Golfers", "You"])
    #expect(!NavSlot.allCases.map(\.label).contains("Clubhouse"))
    #expect(!NavSlot.allCases.map(\.label).contains("Post"))
  }

  /// Every `PushRoute` resolves, and resolves to exactly the slot the route
  /// map (`INFORMATION_ARCHITECTURE.md` §13.4) says it does.
  @Test func everyPushRouteLandsInOneOfTheFive() {
    let every: [(PushRoute, NavSlot)] = [
      (.receipt(Self.R), .home),
      (.scorecard(Self.LR), .home),
      (.board(Self.L), .compete),          // was Clubhouse → board
      (.live(Self.LR), .play),
      (.event(Self.E), .compete),          // a moment is a competition
      (.invites, .home),
      (.requests, .golfers),               // was a push into People, under You
      (.scheduledRound(Self.SR), .home),
      (.home, .home),
    ]
    for (route, want) in every {
      #expect(NavSlot.of(route) == want, "\(route.name) → \(want.rawValue)")
      #expect(NavSlot.allCases.contains(NavSlot.of(route)))
    }
    // Enumerated, so a case ADDED to `PushRoute` without a line here is a
    // failure rather than an omission: `name` is exhaustive over the enum and
    // every one of its words must appear above.
    let named = Set(every.map(\.0.name))
    #expect(named == ["receipt", "scorecard", "board", "live", "event", "invites", "requests", "scheduled_round", "home"])
  }

  /// The two routes D222 actually moved, said out loud so a later wave that
  /// "tidies" them fails here rather than in the field.
  @Test func theTwoRoutesThatMovedAreTheTwoThatMoved() {
    #expect(NavSlot.of(PushRoute.board(Self.L)) != .home)
    #expect(NavSlot.of(PushRoute.requests) != .home)
    #expect(NavSlot.of(PushRoute.requests) != .you)
  }

  /// Every deep link the app claims. The AASA claims FOUR queries — `?join=`,
  /// `?claim=` and, from wave 6, D241's `?p=` and D253's `?plan=` — and the
  /// Live Activity's scheme is the fifth link; nothing else is claimed, and a
  /// URL this app does not claim classifies as nil so the caller does nothing.
  @Test func everyDeepLinkLandsInOneOfTheFive() {
    #expect(DeepLink.allCases.count == 5)
    for link in DeepLink.allCases { #expect(NavSlot.allCases.contains(NavSlot.of(link))) }
    #expect(NavSlot.of(DeepLink.liveRound) == .play)
    #expect(NavSlot.of(DeepLink.join) == .compete)
    #expect(NavSlot.of(DeepLink.claim) == .play)
    #expect(NavSlot.of(DeepLink.person) == .golfers)
    #expect(NavSlot.of(DeepLink.plan) == .play)
  }

  @Test func theUrlsThemselvesClassify() {
    #expect(DeepLink.of(URL(string: "https://cupseason.app/?join=ABC123")!) == .join)
    #expect(DeepLink.of(URL(string: "https://cupseason.app/?claim=" + UUID().uuidString)!) == .claim)
    // The Live Activity's tap-back, checked FIRST because it carries no query
    // to misread. The literal is `CSRoundActivityLink.url`'s, which lives in
    // the app target (the widget extension cannot see this package).
    #expect(DeepLink.of(URL(string: "cupseason://live")!) == .liveRound)
    // Not ours: the caller does nothing, which is what it does today.
    #expect(DeepLink.of(URL(string: "https://cupseason.app/")!) == nil)
    #expect(DeepLink.of(URL(string: "https://example.com/?join=X")!) == .join)   // the AASA is the gate, not this
  }

  /// Every door `home_dispatch` can name — which is every `openLeague(_:)`
  /// call site Home had, plus the ones the ranker added.
  @Test func everyDispatchDoorLandsInOneOfTheFive() {
    let every: [(HomeDispatch.Route, NavSlot)] = [
      (.composer, .play),
      (.declare, .play),
      (.live(Self.LR), .play),
      (.people, .golfers),
      (.receipt(Self.R), .home),
      (.plan(Self.SR), .home),
      (.season(Self.L, pane: nil), .compete),
      (.season(Self.L, pane: "board"), .compete),
      (.pot(Self.L), .compete),
      (.invite(Self.L, kind: nil), .compete),
    ]
    for (route, want) in every {
      #expect(NavSlot.of(route) == want, "\(route) → \(want.rawValue)")
    }
    // The three that USED to be `HomeRoute` cases and are now cross-tab doors.
    #expect(NavSlot.of(HomeDispatch.Route.people) != .home)
    #expect(NavSlot.of(HomeDispatch.Route.season(Self.L, pane: nil)) != .home)
    #expect(NavSlot.of(HomeDispatch.Route.pot(Self.L)) != .home)
  }

  /// The ME strip's four doors (D236) — the other set of call sites that used
  /// to push `HomeRoute`.
  @Test func everyStripDoorLandsInOneOfTheFive() {
    let every: [(MeStripCopy.Door, NavSlot)] = [
      (.yourCard, .you),
      (.composer, .play),
      (.declare, .play),
      (.receipt(Self.R), .home),
      (.plan(Self.SR), .home),
      (.pot(Self.L), .compete),
    ]
    for (door, want) in every { #expect(NavSlot.of(door) == want, "\(door) → \(want.rawValue)") }
  }

  /// A season door carries a PANE, and an unknown pane lands on the table
  /// rather than on nothing — the deploy-skew rule applied to navigation: the
  /// server may name a pane before the client knows it.
  @Test func aSeasonDoorAlwaysLandsSomewhere() {
    for pane in [nil, "", "board", "pot", "album", "schedule", "rules", "a-pane-from-the-future"] {
      #expect(NavSlot.of(HomeDispatch.Route.season(Self.L, pane: pane)) == .compete)
    }
  }
}
