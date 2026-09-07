// Cup Season — the Clubhouse's event chips (`renderClubGroups` 9664–9677):
// "NAME · Ryder · Live|Forming|Final|Enter the field". Mine first, then the
// crew's attached events I have not joined (the Major's enter path). The
// Clubhouse's league chips are the switcher menu on the phone; these are
// the events beside it. Nothing to show → nothing drawn.
//
// IOS-019: small mono chips in the tab strip's voice — no borders.

import SwiftUI
import CSDesign
import CupSeasonKit

struct EventChips: View {
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var store
  @State private var events: [EventSummary] = []
  let leagueId: UUID?
  let links: EventLinks
  private let repo = EventsRepository()

  var body: some View {
    Group {
      if !events.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(ordered) { e in
              Button { links.openEvent(e.id) } label: {
                // Wave 6 · `CSChip` is the one chip. The hand-rolled capsule
                // with its own `bg2` fill and its own 32pt height was one of
                // five chip shapes in the product.
                CSChip("\(e.name) · \(EventCopy.chipSub(e))", selected: false)
              }
              .buttonStyle(.plain)
              .accessibilityLabel("\(e.name) — \(EventCopy.chipSub(e))")
            }
          }
          .padding(.horizontal, CSTokens.Space.gutter)
        }
      }
    }
    .task(id: store.me?.generated_at) { await load() }
  }

  /// The open league's attached events lead; then mine; then the rest.
  private var ordered: [EventSummary] {
    events.sorted { a, b in
      let la = a.leagueId == leagueId && leagueId != nil, lb = b.leagueId == leagueId && leagueId != nil
      if la != lb { return la }
      if a.mine != b.mine { return a.mine }
      return a.name < b.name
    }
  }

  private func load() async {
    guard let me = store.session?.user.id else { events = []; return }
    events = await repo.myEvents(profile: me, leagueIds: store.me?.memberships.map(\.league_id) ?? [])
  }
}
