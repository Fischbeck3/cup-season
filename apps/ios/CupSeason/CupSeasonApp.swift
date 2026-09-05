// Cup Season — the phone (D99). Composition root.

import SwiftUI
import CSDesign
import CupSeasonKit

@main
struct CupSeasonApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
  /// D234 · `app_open` is the denominator of every funnel in the overhaul, so
  /// it is counted here — at the scene, once per foreground — rather than at a
  /// screen that a golfer may or may not reach.
  @Environment(\.scenePhase) private var scenePhase
  @State private var store = SessionStore()
  @State private var appearance = CSAppearance.load()
  @State private var toasts = CSToastCenter()
  /// The looks (IOS-025): the personal dial + every league's curated look, one read per session.
  @State private var looks = CSDevHatch.lookStore()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(store)
        .environment(looks)
        .task(id: store.session?.user.id) { await looks.load(userId: store.session?.user.id) }
        .environment(\.csAppearance, $appearance)
        .preferredColorScheme(appearance.colorScheme)
        .csTheme()
        .csToasts(toasts)
        .task { store.start() }
        .task { await PushService.shared.syncOnLaunch() }
        // One row per FOREGROUND, not per `.active`: a banner, the app
        // switcher and Face ID all bounce through `.inactive` and back, and
        // counting those as opens would inflate the number every rate in the
        // design set is divided by. `AppOpenGate` holds that rule.
        .onChange(of: scenePhase, initial: true) { _, phase in
          switch phase {
          case .active:     CSTelemetry.sceneBecameActive()
          case .background: CSTelemetry.sceneEnteredBackground()
          default:          break
          }
        }
        // Universal Links: /?join=CODE, /?claim=TOKEN, and — D241/D253 — /?p=
        // and /?plan=. The AASA claims exactly these four queries.
        .onOpenURL { url in
          // D155 · the Live Activity's own scheme — the one tap back from a
          // locked phone. Checked first: it carries no query to misread.
          if url.scheme == "cupseason", url.host == CSRoundActivityLink.host {
            NotificationCenter.default.post(name: .csOpenLiveRound, object: nil)
          }
          else if let code = JoinIntent.code(from: url) { JoinIntent.store(code); CSGrowth.log(.linkOpened, kind: "join", token: code); Task { await store.reload() } }
          else if let claim = ClaimIntent.token(from: url) { ClaimIntent.store(claim); CSGrowth.log(.linkOpened, kind: "claim", token: claim) }   // consumed by the tee sheet (wave 4)
          // D241 / D253 · the token is STORED, never spent here: a link tapped
          // on a phone with no session must survive the whole door — email,
          // code, golfer card — and be spent once the golfer has a name on
          // them. `MainTabView` drains it, the same place the claim is drained.
          else if let (kind, token) = ShareIntent.of(url) {
            kind.store(token)
            CSGrowth.log(.linkOpened, kind: kind.growthKind, token: token.uuidString.lowercased())
            NotificationCenter.default.post(name: .csShareTokenPending, object: nil)
          }
        }
    }
  }
}

/// The appearance setting, bindable from Settings. Device-local (D76).
private struct CSAppearanceKey: EnvironmentKey {
  static let defaultValue: Binding<CSAppearance> = .constant(.charcoal)
}
extension EnvironmentValues {
  var csAppearance: Binding<CSAppearance> {
    get { self[CSAppearanceKey.self] }
    set { self[CSAppearanceKey.self] = newValue }
  }
}
