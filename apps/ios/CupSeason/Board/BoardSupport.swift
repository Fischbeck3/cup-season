// Cup Season — the board's small shared pieces: the links out, the squad
// colour, the founder tag, and a toast host for the store's one-shot lines.

import SwiftUI
import CSDesign
import CupSeasonKit

/// Where the board hands off: a points figure opens its receipt (§16), a
/// name opens the Tour Card. Both are owned by other slices.
struct BoardLinks {
  let openReceipt: (UUID) -> Void
  let openTourCard: (UUID) -> Void
  init(openReceipt: @escaping (UUID) -> Void = { _ in }, openTourCard: @escaping (UUID) -> Void = { _ in }) {
    self.openReceipt = openReceipt; self.openTourCard = openTourCard
  }
}

extension CSPalette {
  /// `SQHEX[ci]` — the squad bar colour by squad position.
  func squad(_ ci: Int) -> Color { [sq0, sq1, sq2, sq3][max(0, min(3, ci))] }
}

/// `founderTag` (10115): "✦ Founder" beside the one founder's name.
struct FounderTag: View {
  @Environment(\.cs) private var cs
  var body: some View {
    Text("✦ Founder").font(CSFont.label).foregroundStyle(cs.gold)
      .accessibilityLabel("Cup Season founder")
  }
}

/// The store's one-shot toast, as the web's `toast()`: a pill above the
/// composer that rolls out. Local to the board until the shared toast lands.
struct BoardToastHost: ViewModifier {
  @Environment(\.cs) private var cs
  @Bindable var store: BoardStore
  @State private var hide: Task<Void, Never>?

  func body(content: Content) -> some View {
    content
      .overlay(alignment: .bottom) {
        if let text = store.toast {
          Text(text)
            .font(CSFont.subhead)
            .foregroundStyle(cs.bg0)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(cs.ink, in: Capsule())
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityAddTraits(.updatesFrequently)
            .id(text)
        }
      }
      .animation(.timingCurve(0.16, 0.84, 0.36, 1, duration: 0.32), value: store.toast)
      .onChange(of: store.toast) { _, new in
        hide?.cancel()
        guard new != nil else { return }
        hide = Task {
          try? await Task.sleep(for: .seconds(2.6))
          if !Task.isCancelled { store.toast = nil }
        }
      }
  }
}

extension View {
  func boardToasts(_ store: BoardStore) -> some View { modifier(BoardToastHost(store: store)) }
}

/// The store a screen builds for a league, from what the session knows.
@MainActor
func makeBoardStore(leagueId: UUID, session: SessionStore) -> BoardStore {
  let m = session.me?.memberships.first { $0.league_id == leagueId }
  return BoardStore(leagueId: leagueId, leagueName: m?.name ?? "", membership: m,
                    profileId: session.me?.profile?.id ?? session.session?.user.id)
}
