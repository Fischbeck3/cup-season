// Cup Season — the phone (D99). Composition root.

import SwiftUI
import CSDesign
import CupSeasonKit

@main
struct CupSeasonApp: App {
  @State private var store = SessionStore()
  @State private var appearance = CSAppearance.load()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(store)
        .environment(\.csAppearance, $appearance)
        .preferredColorScheme(appearance.colorScheme)
        .csTheme()
        .task { store.start() }
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
