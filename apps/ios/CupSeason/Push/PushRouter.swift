// Cup Season — where a tapped notification lands (push-contract §2, D104).
// The delegate hands a payload in from whatever thread UserNotifications
// uses; the router keeps ONE pending route on the main actor and the tab
// shell drains it once the session is `.ready` (a cold-start tap is stashed
// here until Home exists). Foreground and background taps take the same
// path; a payload the router cannot read lands Home, never a blank.

import Foundation
import Observation
import CupSeasonKit

@MainActor
@Observable
final class PushRouter {
  static let shared = PushRouter()

  /// The route waiting for the tab shell. Set by a tap; cleared by `apply`.
  var pending: PushRoute?

  /// A tap (the default action) or the launch-options payload.
  func open(userInfo: [AnyHashable: Any]) {
    guard let p = PushPayload(userInfo: userInfo) else {
      CSTelemetry.event("push_opened", ["kind": .string("unreadable"), "route": .string("home")])
      pending = .home
      return
    }
    open(p)
  }

  func open(_ payload: PushPayload) {
    let route = PushRoute.from(payload)
    CSTelemetry.event("push_opened", ["kind": .string(payload.kind?.rawValue ?? "unknown"), "route": .string(route.name)])
    pending = route
  }
}
