// Cup Season — WHICH OF THE FIVE SLOTS DOES THIS LAND IN (D222, IOS-028).
//
// The nav went from four places to five, and the expensive half of that change
// is not the bar — it is that every push route, every deep link and every door
// the shell hands a screen has to point somewhere that still exists. The old
// shape answered that question in one `switch` inside `MainTabView.apply` and
// in a second, silent one wherever a `NavigationLink(value:)` was declared —
// which is exactly how D178's dead link happened: a link declared in a stack
// that did not resolve its type does nothing, logs a line nobody reads, and
// ships.
//
// So the answer is a PRODUCER, here, and the shell derives its tab from it
// rather than deciding a second time. `RouteMapTests` walks every case of every
// enum below; a route that resolves to a slot that no longer exists is a
// failing test rather than a blank screen.
//
// The slots are the destinations, not the sheets. A Tour Card, a receipt, the
// composer's cover and the live round are PRESENTED over whatever tab is on —
// IOS-002 §2's rule, unchanged — so their slot is the tab the golfer stays on,
// which is the tab the verb belongs to.

import Foundation

/// The five destinations (D222 / R-A, with R-D settling the two names).
/// `rawValue` is the word telemetry and the tests use; the label is the word
/// on the bar.
public enum NavSlot: String, Sendable, CaseIterable {
  case home, compete, play, golfers, you

  /// The word the tab item wears. Never "Clubhouse" (O-06), never "Post" —
  /// the tab is labelled Play because it does not post (D222).
  public var label: String {
    switch self {
    case .home:    "Home"
    case .compete: "Compete"
    case .play:    "Play"
    case .golfers: "Golfers"
    case .you:     "You"
    }
  }
}

/// The five URLs this app claims, classified once.
///
/// The AASA claims `?join=`, `?claim=` and — from wave 6 — `?p=` and `?plan=`;
/// `cupseason://live` is the Live Activity's tap-back (D155), checked FIRST
/// because it carries no query to misread. The parsers themselves are not
/// duplicated here — this calls `JoinIntent.code(from:)`,
/// `ClaimIntent.token(from:)` and `ShareIntent.of(_:)`, which are the
/// producers, so a change to what a link looks like is still made in one place.
public enum DeepLink: Sendable, Equatable, CaseIterable {
  /// `cupseason://live` — the island, the lock-screen card.
  case liveRound
  /// `/?join=CODE`
  case join
  /// `/?claim=TOKEN`
  case claim
  /// D241 · `/?p=TOKEN` — a golfer's own card. Signed in, it mints a buddy
  /// request; signed out, the web's landing page is what the sender's friend
  /// actually sees, and this is only the app's half.
  case person
  /// D253 · `/?plan=TOKEN` — a weekend. It takes the seat and mints the
  /// request, in that order, in one transaction on the server.
  case plan

  /// The scheme and host of the Live Activity's tap-back. `CSRoundActivityLink`
  /// carries the same pair for the widget extension, which cannot depend on
  /// this package; `RouteMapTests` asserts the two agree on the literal URL.
  public static let liveScheme = "cupseason"
  public static let liveHost = "live"

  /// Nil for a URL this app does not claim — the caller does nothing, which is
  /// what it does today.
  public static func of(_ url: URL) -> DeepLink? {
    if url.scheme == liveScheme, url.host == liveHost { return .liveRound }
    if JoinIntent.code(from: url) != nil { return .join }
    if ClaimIntent.token(from: url) != nil { return .claim }
    switch ShareIntent.of(url)?.kind {
    case .person: return .person
    case .plan:   return .plan
    case nil:     break
    }
    return nil
  }
}

public extension NavSlot {

  // MARK: push (D104, push-contract §2)

  /// Where a tapped notification lands. **Five retarget under D222** and the
  /// contract's own rule is unchanged: an unknown `v`, an unknown kind or a
  /// missing id lands `.home`, never a blank.
  static func of(_ route: PushRoute) -> NavSlot {
    switch route {
    // The receipt, the scorecard and the plan are SHEETS over wherever you
    // were, and a tap from the lock screen lands you on Home under them.
    case .receipt, .scorecard, .scheduledRound: .home
    // O-06 · the board is a season's board, and a season lives in Compete.
    // `chat`, `announce`, `moment` and `system` all arrive here.
    case .board: .compete
    // The live round is a full-screen cover; the ⊕ is its home.
    case .live: .play
    // A moment is a competition (IA §8) — the same slot as a season.
    case .event: .compete
    // An invitation is answered at the head of Home, where the banner is and
    // where the ranker makes it Tier 1.
    case .invites: .home
    // D222's whole point: a person waiting on you is a COMMUNITY object, and
    // it stops being a cross-stack push into a screen that lived under You.
    case .requests: .golfers
    case .home: .home
    }
  }

  // MARK: deep links (§13.5)

  static func of(_ link: DeepLink) -> NavSlot {
    switch link {
    case .liveRound: .play          // the cover opens over the tab you are on
    case .join:      .compete       // a code joins a season, and a season is Compete's
    case .claim:     .play          // a claimed round is the tee sheet's business
    // D241 · a person link ends in a buddy request, and a person waiting on
    // you is Golfers' — the same slot `PushRoute.requests` lands in.
    case .person:    .golfers
    // D253 · a plan link ends in a SEAT on a round, and the tee sheet is the
    // ⊕'s. It is the same landing `.claim` has for the same reason.
    case .plan:      .play
    }
  }

  // MARK: the shell's own doors

  /// Every door `home_dispatch` can name (`HomeView.take`). The ranker chooses
  /// the door; this says which of the five it opens onto.
  static func of(_ route: HomeDispatch.Route) -> NavSlot {
    switch route {
    case .composer, .declare: .play          // the verb, in both tenses
    case .live:               .play
    case .people:             .golfers       // was a push into People under You
    case .receipt, .plan:     .home          // sheets, over Home
    case .season, .pot:       .compete       // was `HomeRoute.league` / `.pot`
    case .invite:             .compete       // an invitation opens the season it is to
    }
  }

  /// The ME strip's four facts and their doors (D236).
  static func of(_ door: MeStripCopy.Door) -> NavSlot {
    switch door {
    case .yourCard:            .you          // the card IS the You tab's object
    case .composer, .declare:  .play
    case .receipt, .plan:      .home
    case .pot:                 .compete
    }
  }
}
