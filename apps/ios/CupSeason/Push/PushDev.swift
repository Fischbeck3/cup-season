// Cup Season — push developer hatches (DEBUG only; the simulator receives
// no APNs, so a launch argument stands in for a tap):
//   -cs_dev_push '<json>'      the contract's `cs` object (or a whole
//                              `{aps, cs}` payload) routed as if tapped, two
//                              seconds after the session is ready
//   -cs_dev_push_prompt        the explainer sheet whatever the system says
//   -cs_dev_push_autoopen      a notification arriving in the FOREGROUND
//                              (`xcrun simctl push`) is routed as if tapped
//   -cs_dev_push_ids           print real ids the router can be fed
// None of these exist in Release.

#if DEBUG
import Foundation
import CupSeasonKit

enum PushDev {
  private static let args = ProcessInfo.processInfo.arguments
  static let forcePrompt = args.contains("-cs_dev_push_prompt")
  static let autoOpen = args.contains("-cs_dev_push_autoopen")
  static let printIds = args.contains("-cs_dev_push_ids")

  /// The payload behind `-cs_dev_push`, if any. Accepts `{ "v":1, "kind":… }`
  /// or the full `{ "aps": {…}, "cs": {…} }`.
  static var payload: PushPayload? {
    guard let i = args.firstIndex(of: "-cs_dev_push"), i + 1 < args.count,
          let data = args[i + 1].data(using: .utf8),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
    if obj["cs"] != nil { return PushPayload(userInfo: obj) }
    return PushPayload(cs: obj, category: obj["category"] as? String)
  }

  /// Real ids from the signed-in account, for the hatch above.
  @MainActor
  static func dumpIds(me: Me?, preferred: UUID?) async {
    let svc = SupabaseService.shared
    NSLog("[push-dev] preferred league: \(preferred?.uuidString.lowercased() ?? "nil")")
    for m in me?.memberships ?? [] { NSLog("[push-dev] league \(m.name): \(m.league_id.uuidString.lowercased())") }
    if let lr = me?.live_round { NSLog("[push-dev] live round: \(lr.id.uuidString.lowercased()) status=\(lr.status)") }
    for e in me?.events ?? [] { NSLog("[push-dev] event \(e.name): \(e.id.uuidString.lowercased())") }
    for d in me?.open_duels ?? [] { NSLog("[push-dev] duel session: \(d.session_id?.uuidString.lowercased() ?? "nil") closes \(d.closes_on ?? "?")") }
    if let feed = try? await svc.call(Rpc.home_feed(p_days: 60)) {
      for r in feed.prefix(3) { if let id = r.round_id { NSLog("[push-dev] round: \(id.uuidString.lowercased())") } }
    }
    let to = CSDate.iso(Calendar.current.date(byAdding: .day, value: 60, to: Date()) ?? Date())
    if let sched = try? await svc.call(Rpc.my_schedule(p_from: CSDate.today(), p_to: to)) {
      for r in sched.prefix(3) { NSLog("[push-dev] scheduled round: \(r.id?.uuidString.lowercased() ?? "nil") on \(r.play_on ?? "?")") }
    }
    if let inv = try? await svc.call(Rpc.my_invites()) {
      for i in inv.prefix(3) { NSLog("[push-dev] invite: \(i.id?.uuidString.lowercased() ?? "nil")") }
    }
  }
}
#endif
