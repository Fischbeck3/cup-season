// Cup Season — the badge (push-contract §4). Actionable items ONLY: pending
// buddy requests to me + open league invites to me + live rounds I am on
// that are still open. Never chat, never rounds. Seeing the list clears it —
// acting is not required — so the app recomputes on foreground, after the
// Requests screen and the invites banner load, after a live round opens or
// finishes, and after any lock-screen action.
//
// `my_actionable_count()` is hand-declared: the wave-7 migration creates it
// and Rpc.swift regenerates from the next snapshot (the documented exception,
// LiveRepository has the same shape). Preflight 17 still holds it to a grant.
// Fail closed: an error leaves the badge exactly where it was.

import Foundation
import UserNotifications

public enum PushBadge {
  /// Ask the server, set the badge. Silent on any failure.
  @MainActor
  public static func refresh(_ svc: SupabaseService = .shared) async {
    guard await svc.currentSession() != nil else { return }
    guard let n = try? await svc.call(Rpc.my_actionable_count()) else { return }
    try? await UNUserNotificationCenter.current().setBadgeCount(max(0, n))
  }

  /// D179 · "I have seen the list." The badge means UNSEEN (owner ruling), so
  /// LOOKING clears it — acting is not required, exactly as push-contract §4
  /// has always said. The SQL disagreed with that sentence until now.
  ///
  /// Call this only where a golfer can actually READ the rows: a list that
  /// rendered empty was not seen, it was absent, and marking it would silence
  /// an invite sitting on another surface. The RPC returns the count AFTER
  /// marking, so the phone can never paint a number the server has superseded.
  ///
  /// Fail closed, like `refresh`: an error leaves the badge exactly where it was.
  @MainActor
  public static func markSeen(_ svc: SupabaseService = .shared) async {
    guard await svc.currentSession() != nil else { return }
    guard let n = try? await svc.call(Rpc.mark_actionable_seen()) else { return }
    try? await UNUserNotificationCenter.current().setBadgeCount(max(0, n))
  }
}
