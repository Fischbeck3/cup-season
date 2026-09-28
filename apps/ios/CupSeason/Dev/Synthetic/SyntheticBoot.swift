// Cup Season — `-cs_dev_synthetic <scenario>`: the app's half of the fixture
// seam (S2/C3). The Kit's `SyntheticSeam` swaps the backend URL, the auth store
// and the transport; this file decides WHO is signed in and installs the
// router that answers every request from `SyntheticWorld`.
//
//   -cs_dev_synthetic brand-new | solo | season-live | season-final | ceremony
//                     | event-live | failures | offline | card-gate | signed-out
//   -cs_dev_open <place>            lands on a screen (MainTabView's hatch)
//   -cs_synth_fail <rpc,rpc|all>    which reads fail until the first retry
//   -cs_synth_delay <seconds>       hold every read (the loading geometry)
//   -cs_synth_reconnect_after <s>   offline, then back (offline scenario)
//   -cs_synth_long                  the viewer's own name is the long one
//   -cs_synth_post_fail             the server refuses a posted round
//   -cs_synth_must_update           the forced-update gate (min build above this one)
//
// Every identity here is invented and says so: "Avery Fixture", handle
// `fixture_avery`, `@example.invalid`, "North Grove (fixture)". Nothing in this
// folder is compiled into Release, and nothing it answers leaves the device.

#if DEBUG
import Foundation
import CupSeasonKit

enum SyntheticBoot {
  /// Called once from `CupSeasonApp.init()`. By then `SupabaseService.shared`
  /// exists (the store's initializer touched it) and the sandbox is clean.
  static func install() {
    guard let raw = SyntheticSeam.scenario else { return }
    SyntheticSeam.prepareSandboxOnce()
    guard let scenario = SynthScenario(rawValue: raw) else {
      SyntheticSeam.log("MISS scenario=\(raw) — unknown; known: \(SynthScenario.allCases.map(\.rawValue).joined(separator: ","))")
      SyntheticSeam.install { _, _ in SyntheticReply(status: 599, body: Data("{}".utf8), error: .cannotConnectToHost) }
      return
    }
    let world = SyntheticWorld(scenario)
    let backend = SyntheticBackend(world: world)
    SyntheticSeam.install { request, body in backend.respond(request, body) }
    if scenario.signedIn {
      SyntheticSeam.seedSession(userId: world.me.id, email: world.me.email)
    }
    seedDevice(world)
    // The system keeps Live Activities across launches and reinstalls; a
    // synthetic launch starts with none (and `LiveActivityHost` starts none).
    Task { @MainActor in await LiveActivityHost.clearStale() }
    SyntheticSeam.log("ready scenario=\(scenario.rawValue) route=\(route ?? "-") anchor=\(world.anchor) viewer=\(world.me.handle)")
  }

  /// `-cs_dev_open <place>` as the route the manifest names.
  static var route: String? {
    let a = ProcessInfo.processInfo.arguments
    guard let i = a.firstIndex(of: "-cs_dev_open"), i + 1 < a.count else { return nil }
    return a[i + 1]
  }

  /// On-device state a real phone would already hold at this point. The crew
  /// step is met once per device (D233); unless the route asks for it, the
  /// fixture phone has already met it, so a brand-new golfer lands on Home.
  private static func seedDevice(_ world: SyntheticWorld) {
    let d = UserDefaults.standard
    if route != "crew" && route != "crewstep" { d.set(true, forKey: CSConfig.crewKey) }
    if world.scenario == .offline {
      // What an earlier connected launch would have left on this phone: the
      // golfer for the offline scorecard, and the course books.
      OfflineGolfer(id: world.me.id, name: world.me.name, index: world.me.index, marker: world.me.marker).keep()
      let owner = world.me.id
      Task.detached(priority: .utility) {
        await CourseBookStore().claim(owner)
        _ = await CourseBookStore().refresh()
      }
    }
    switch route {
    case "invite", "join":
      // A tapped /?join= link, stored exactly as `onOpenURL` stores one.
      JoinIntent.store(SyntheticWorld.inviteCode, name: SyntheticWorld.inviteLeagueName)
    case "claim":
      ClaimIntent.store(SyntheticWorld.claimToken.uuidString.lowercased())
    default: break
    }
  }
}

/// The scenarios. Each one is a whole, consistent world — not a patch on one.
enum SynthScenario: String, CaseIterable, Sendable {
  /// Signed in, card done, no rounds, no season, no buddies.
  case brandNew = "brand-new"
  /// Rounds and buddies, no season.
  case solo
  /// Two live seasons (solo + squads), a Ryder, photos, long names.
  case seasonLive = "season-live"
  /// The same world in its Cup Final.
  case seasonFinal = "season-final"
  /// The same world with the season complete: champion, ceremony, trophies.
  case ceremony
  /// Season-live plus a live and a complete Ryder, and a Major.
  case eventLive = "event-live"
  /// Season-live, every read fails once and succeeds on the retry.
  case failures
  /// No signal: every request fails until `-cs_synth_reconnect_after`.
  case offline
  /// Signed in, card not made yet (marker and handle missing).
  case cardGate = "card-gate"
  /// No session at all: the door (and its invite / claim variants).
  case signedOut = "signed-out"

  var signedIn: Bool { self != .signedOut }
}
#endif
