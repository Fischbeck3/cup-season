// Cup Season — when the phone may ask for notifications (push-contract §6).
// Never on launch. After one of three moments — and only if the system has not
// already answered and "Not now" is older than fourteen days. Pure: the
// decision is a function of (reason, status, last decline, now), so it can
// be tested without a clock or a notification center.
//
// D247 MOVED THE FIRST MOMENT AND KEPT EVERYTHING ELSE. The ask used to follow
// the CARD — which is to say it arrived over a golfer's first Home, before they
// had done anything, asking to be interrupted about a season they were not in
// yet. It follows the first moment that EARNS it now: the first round, the
// first accepted buddy, the first join. D104 §6's rule (never on launch,
// contextual, ≥14 days after "Not now") and the explainer's copy — the
// best-written screen in the app — are untouched; only the trigger moved.

import Foundation

/// The three moments the ask may follow. Never anything else — and saving the
/// card is deliberately not one of them (D247).
public enum PushAskReason: String, Sendable, Equatable, Identifiable, CaseIterable {
  case firstRound = "first_round"
  /// D247 · somebody said yes to you. The first moment the product has
  /// somebody else in it, which is the first moment a notification is about a
  /// person rather than about the app.
  case buddyAccepted = "buddy_accepted"
  case leagueJoined = "league_joined"
  public var id: String { rawValue }
}

public enum PushAskPolicy {
  /// "Not now" is remembered this long.
  public static let snooze: TimeInterval = 14 * 86_400
  /// The UserDefaults key the decline lives under.
  public static let declinedKey = "cs_push_ask_declined_at"

  /// What the system has already said. `.undetermined` is the only state the
  /// ask is for; `.denied` means Settings is the only door left.
  public enum Status: Sendable { case undetermined, authorized, denied }

  /// true = show the explainer now.
  public static func shouldAsk(status: Status, declinedAt: Date?, now: Date = Date()) -> Bool {
    guard status == .undetermined else { return false }
    if let d = declinedAt, now.timeIntervalSince(d) < snooze { return false }
    return true
  }
}
