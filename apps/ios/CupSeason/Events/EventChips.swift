// Cup Season — the Clubhouse's event chips (`renderClubGroups` 9664–9677):
// "NAME · Ryder · Live|Forming|Final|Enter the field". Mine first, then the
// crew's attached events I have not joined (the Major's enter path). The
// Clubhouse's league chips are the switcher menu on the phone; these are
// the events beside it. Nothing to show → nothing drawn.

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
                VStack(alignment: .leading, spacing: 2) {
                  Text(e.name).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink).lineLimit(1)
                  Text(EventCopy.chipSub(e)).font(CSFont.label).tracking(0.5).textCase(.uppercase).foregroundStyle(cs.mut).lineLimit(1)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .frame(minHeight: 44)
                .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line, lineWidth: 1))
              }
              .buttonStyle(.plain)
              .accessibilityLabel("\(e.name) — \(EventCopy.chipSub(e))")
            }
          }
          .padding(.horizontal, 20)
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
