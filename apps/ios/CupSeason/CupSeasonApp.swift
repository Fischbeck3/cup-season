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

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(store)
        .environment(\.csAppearance, $appearance)
        .preferredColorScheme(appearance.colorScheme)
        .csTheme()
        .csToasts(toasts)
        .task { store.start() }
        .task { await PushService.shared.syncOnLaunch() }
        // Universal Links: /?join=CODE and /?claim=TOKEN (the AASA claims only these two).
        .onOpenURL { url in
          if let code = JoinIntent.code(from: url) { JoinIntent.store(code) ; Task { await store.reload() } }
          else if let claim = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "claim" })?.value {
            UserDefaults.standard.set(claim, forKey: "cs_claim")   // consumed by the live-round slice (wave 4)
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
