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
  /// IOS-051 · `-cs_dev_appearance` wins over the stored choice for one
  /// launch, and it wins HERE rather than at `.preferredColorScheme`, so
  /// the Appearance selector in Settings shows the same answer the screen is
  /// actually rendering. Always the stored value in Release.
  @State private var appearance = CSDevHatch.appearance ?? CSAppearance.load()
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
        // IOS-051 · `-cs_dev_text_size <category>`. `.dynamicTypeSize(_:)`
        // with a single size PINS it, which is what a capture needs; nil
        // leaves the golfer's own setting alone, and in Release it is
        // always nil.
        .csDevTextSize(CSDevHatch.textSize)
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
          // QB-08 · the code is stored WITH THE SEASON'S NAME, because
          // `PendingLink.doorLine()` can only say "You're joining The Fellas"
          // if somebody told it the name. `store(code)` was called with none,
          // so the best the door could ever have managed was "a season" — and
          // it was rendering nothing at all. `league_by_code` is one of the
          // twelve anon endpoints, so this resolves BEFORE sign-in, which is
          // the whole point: the stranger who tapped a friend's link meets the
          // season's name above the email field rather than a bare box.
          else if let code = JoinIntent.code(from: url) {
            JoinIntent.store(code)
            CSGrowth.log(.linkOpened, kind: "join", token: code)
            Task {
              // A name that does not resolve leaves the generic line standing;
              // it never blocks the door and never invents a name (L-44).
              if let n = ((try? await JoinService().leagueName(code)) ?? nil), !n.isEmpty {
                JoinIntent.store(code, name: n)
              }
              await store.reload()
            }
          }
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

/// IOS-051 · the content-size hatch, as a modifier so the `nil` case adds
/// nothing to the view tree at all. `-UIPreferredContentSizeCategoryName` does
/// not take on a SwiftUI app launched by `simctl`, which is why this exists.
extension View {
  @ViewBuilder func csDevTextSize(_ size: DynamicTypeSize?) -> some View {
    if let size { self.dynamicTypeSize(size) } else { self }
  }

  /// **A sheet presents in its own host, so the hatch has to be re-applied at
  /// every presentation site** — Wave 7 found this the hard way, when the
  /// round receipt photographed at the reading size under `-cs_dev_text_size
  /// AX3` and nothing in the shot said so. A `fullScreenCover` inherits the
  /// app root's override; a `.sheet` does not.
  ///
  /// It must be applied to the CONTENT at the presentation site, never inside
  /// the sheet's own struct: `@Environment` in that struct resolves before its
  /// body's modifiers run, so the view's own accessibility branches would
  /// still read the device's size. These two wrappers are `.sheet` with the
  /// line already in place, so a new sheet on a host cannot forget it. In
  /// Release `CSDevHatch.textSize` is nil and the wrapper adds nothing.
  func csSheet<Item: Identifiable, C: View>(item: Binding<Item?>,
                                            @ViewBuilder content: @escaping (Item) -> C) -> some View {
    sheet(item: item) { content($0).csDevTextSize(CSDevHatch.textSize) }
  }
  func csSheet<C: View>(isPresented: Binding<Bool>,
                        @ViewBuilder content: @escaping () -> C) -> some View {
    sheet(isPresented: isPresented) { content().csDevTextSize(CSDevHatch.textSize) }
  }

  /// **And a `fullScreenCover` does not inherit it either.** Wave 7 recorded
  /// that a cover DOES and a sheet does not; the composer's first AX3 shot in
  /// Wave 8 was pixel-identical to its reading-size one, which is the same
  /// evidence-that-flatters the hatch exists to prevent. IOS-049's own note on
  /// the event room says the same thing and re-applies it by hand. Both
  /// presentations are wrapped here so no host has to remember which is which.
  func csCover<Item: Identifiable, C: View>(item: Binding<Item?>,
                                            @ViewBuilder content: @escaping (Item) -> C) -> some View {
    fullScreenCover(item: item) { content($0).csDevTextSize(CSDevHatch.textSize) }
  }
  func csCover<C: View>(isPresented: Binding<Bool>,
                        @ViewBuilder content: @escaping () -> C) -> some View {
    fullScreenCover(isPresented: isPresented) { content().csDevTextSize(CSDevHatch.textSize) }
  }
}
