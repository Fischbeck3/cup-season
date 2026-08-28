// Cup Season — when the phone may ask for notifications (push-contract §6).
// Never on launch. After one of three moments — the card is saved, the first
// round is posted, a league is joined — and only if the system has not
// already answered and "Not now" is older than fourteen days. Pure: the
// decision is a function of (reason, status, last decline, now), so it can
// be tested without a clock or a notification center.

import Foundation

/// The three moments the ask may follow. Never anything else.
public enum PushAskReason: String, Sendable, Equatable, Identifiable {
  case cardSaved = "card_saved"
  case firstRound = "first_round"
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
