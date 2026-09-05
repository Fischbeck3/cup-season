// Cup Season — THE LINK THAT SURVIVES THE BOOT (IOS-033).
//
// FOUR TOKENS ARRIVE BY URL — `?join=`, `?claim=`, `?p=`, `?plan=` — and each
// is stored in `UserDefaults` by `.onOpenURL` because a link tapped on a phone
// with no session has to survive the whole door: email, code, golfer card. This
// is the one place that answers "is anything waiting", so the boot can be
// reasoned about rather than re-derived in four branches.
//
// THE TITLE IS CORRECTED ON PURPOSE. iOS has NO deferred deep linking: after an
// App Store install the system passes nothing, `.onOpenURL` never fires and
// nothing is ever stored. So this helps only once an intent HAS been stored —
// by a Universal Link tapped on a phone that already has the app, or by the
// Smart App Banner's `app-argument` on a later Safari visit. The cold case's
// answer is the door's "I have a code", and re-tapping the original link, which
// does work once installed. A first-launch clipboard read would be a genuine
// deferred link and it is **its own entry with its own privacy note**, not a
// clause here.
//
// THE DEFECT THIS FILE EXISTS TO CLOSE. `RootView` cleared the join code on the
// tabs' `.onAppear` — BEFORE the covenant sheet had resolved. A golfer who
// backgrounded the app on the covenant, or whose join failed, lost the code
// they had been sent and had no way back to it. The clear moves to the moment
// the join actually resolves, and `spend` is the only door to it.

import Foundation

public enum PendingLink: String, Sendable, Equatable, CaseIterable {
  case join, claim, person, plan

  /// What arrived, in the order the boot should honour it. A claim is first
  /// because a guest pencil is already holding a round; a join is next because
  /// it carries a covenant; the two share links are drained by the shell.
  public static let order: [PendingLink] = [.claim, .join, .person, .plan]

  public static func first(defaults: UserDefaults = .standard) -> PendingLink? {
    order.first { $0.isPending(defaults: defaults) }
  }

  public func isPending(defaults: UserDefaults = .standard) -> Bool {
    switch self {
    case .join:   return JoinIntent.pending(defaults: defaults) != nil
    case .claim:  return ClaimIntent.pending(defaults: defaults) != nil
    case .person: return ShareIntent.person.pending(defaults: defaults) != nil
    case .plan:   return ShareIntent.plan.pending(defaults: defaults) != nil
    }
  }

  /// **The only door to a clear.** Named `spend` rather than `clear` because
  /// the rule is that a token is retired when it has been ANSWERED — joined,
  /// declined, redeemed — and never merely because a screen appeared.
  public func spend(defaults: UserDefaults = .standard) {
    switch self {
    case .join:   JoinIntent.clear(defaults: defaults)
    case .claim:  ClaimIntent.clear(defaults: defaults)
    case .person: ShareIntent.person.clear(defaults: defaults)
    case .plan:   ShareIntent.plan.clear(defaults: defaults)
    }
  }

  /// D116, carried forward from the retired orientation: a golfer who is
  /// already being taken somewhere is not asked who they play with. The crew
  /// step and the orientation shared this rule and it outlives the screen.
  public static func invited(defaults: UserDefaults = .standard) -> Bool {
    join.isPending(defaults: defaults) || claim.isPending(defaults: defaults)
      || person.isPending(defaults: defaults) || plan.isPending(defaults: defaults)
  }

  /// What the DOOR says above the email field when a token is waiting, so a
  /// stranger who tapped a friend's link is told what they are signing in for
  /// rather than meeting a bare email box (IOS-033).
  public static func doorLine(defaults: UserDefaults = .standard) -> String? {
    if let j = JoinIntent.pending(defaults: defaults) {
      return j.name.map { "You're joining \($0). Sign in and you're on the roster." }
        ?? "You're joining a season. Sign in and you're on the roster."
    }
    if claim.isPending(defaults: defaults) { return "A round is waiting to be yours. Sign in and it attaches." }
    if person.isPending(defaults: defaults) { return "Somebody sent you their card. Sign in and you're buddies." }
    if plan.isPending(defaults: defaults) { return "There's a round on. Sign in and take the seat." }
    return nil
  }
}
