// Cup Season — the phone (D99). Composition root.

import SwiftUI
import CSDesign
import CupSeasonKit

@main
struct CupSeasonApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
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
        // Universal Links: /?join=CODE, /?claim=TOKEN and /?share=TOKEN.
        // D188 added the third, and it was gated on the phone being able to
        // RENDER a shared card (SharedCardSheet) — opening the app to Home
        // from a card link is worse than opening Safari, which shows the card
        // and takes the tap.
        .onOpenURL { url in
          // D155 · the Live Activity's own scheme — the one tap back from a
          // locked phone. Checked first: it carries no query to misread.
          if url.scheme == "cupseason", url.host == CSRoundActivityLink.host {
            NotificationCenter.default.post(name: .csOpenLiveRound, object: nil)
          }
          else if let code = JoinIntent.code(from: url) { JoinIntent.store(code); CSGrowth.log(.linkOpened, kind: "join", token: code); Task { await store.reload() } }
          else if let claim = ClaimIntent.token(from: url) { ClaimIntent.store(claim); CSGrowth.log(.linkOpened, kind: "claim", token: claim) }   // consumed by the tee sheet (wave 4)
          else if let share = ShareIntent.token(from: url), let tok = UUID(uuidString: share) {
            // stored first, then raised: a signed-out reader still sees the
            // card, and the token survives the door if they go and make one.
            ShareIntent.store(share)
            // `share` generically, matching the web's own `?share=` open
            // (index.html:19702) — the KIND is not known until share_info
            // answers, and the funnel must not guess.
            CSGrowth.log(.linkOpened, kind: "share", token: share)
            NotificationCenter.default.post(name: .csOpenSharedCard, object: tok)
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
