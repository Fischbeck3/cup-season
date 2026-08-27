// Cup Season — D63: last round with — the reunion whisper (index.html
// `renderLRW` 10908–10933, `loadLastRoundWith` 16201–16217).
//
// Threshold-fired by the server read (12mo · ≥3 shared cards); one name; in-app
// only; dismiss = 90 days of device-local quiet. Never a nudge.

import Foundation

public struct LastRoundWith: Sendable, Equatable {
  public let profileId: UUID
  public let displayName: String
  public let marker: String?
  public let lastOn: String
  public let sharedCards: Int

  public init?(_ r: Rpc.last_round_with.Row) {
    guard let pid = r.profile_id, let on = r.last_on else { return nil }
    profileId = pid; displayName = r.display_name ?? "—"; marker = r.marker; lastOn = on; sharedCards = r.shared_cards ?? 0
  }

  /// `Math.max(12, Math.round((now − last_on) / 2592e6))` — months, floored at
  /// the threshold the server fires on.
  public func months(now: Date = Date(), calendar: Calendar = .current) -> Int {
    guard let d = CSDate.local(lastOn, calendar: calendar) else { return 12 }
    return max(12, Int((now.timeIntervalSince(d) / 2_592_000).rounded()))
  }

  /// "You and NAME — last card together N months ago."
  public func line(now: Date = Date()) -> (lead: String, name: String, tail: String) {
    ("You and ", displayName, " — last card together \(months(now: now)) months ago.")
  }
  public var sub: String { "\(sharedCards) rounds shared · one tap stages a Saturday" }

  /// Next Saturday from today (the web's `lrwGo`), as a calendar string.
  public static func nextSaturday(from today: Date = Date(), calendar: Calendar = .current) -> String {
    let wd = calendar.component(.weekday, from: today)   // 1 = Sunday … 7 = Saturday
    let jsDay = wd - 1
    var add = ((6 - jsDay) + 7) % 7
    if add == 0 { add = 7 }
    let d = calendar.date(byAdding: .day, value: add, to: today) ?? today
    return CSDate.iso(d, calendar: calendar)
  }
}

/// The 90-day quiet, device-local (`cs_lrw_quiet_<uid>`).
public struct LRWQuietStore: Sendable {
  let key: String
  public init(userId: UUID) { key = "cs_lrw_quiet_\(userId.uuidString)" }
  public func isQuiet(now: Date = Date()) -> Bool {
    let t = UserDefaults.standard.double(forKey: key)
    return t > 0 && now.timeIntervalSince1970 - t < 90 * 86_400
  }
  public func dismiss(now: Date = Date()) { UserDefaults.standard.set(now.timeIntervalSince1970, forKey: key) }
}
