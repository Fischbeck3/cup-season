// Cup Season — the Clubhouse tab: the league room for the open league
// (IOS-002 §5), with the league switcher and the league-less doors.

import SwiftUI
import CSDesign
import CupSeasonKit

struct ClubhouseView: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.presenter) private var presenter
  @Environment(\.cs) private var cs
  let leagueId: UUID?
  var onOpenBoard: (UUID) -> Void = { _ in }
  var onOpenSchedule: () -> Void = {}
  var onAddGolfers: (UUID) -> Void = { _ in }

  var body: some View {
    if let me = store.me, !me.memberships.isEmpty,
       let current = me.memberships.first(where: { $0.league_id == (leagueId ?? store.preferredLeague) }) ?? me.memberships.first {
      LeagueRoomScreen(leagueId: current.league_id, links: links(for: current))
        .id(current.league_id)
        .toolbar {
          if me.memberships.count > 1 {
            ToolbarItem(placement: .topBarTrailing) {
              Menu {
                ForEach(me.memberships) { m in
                  Button { store.preferredLeague = m.league_id; CSHaptic.selection() } label: {
                    Label(m.name, systemImage: m.league_id == current.league_id ? "checkmark" : "flag")
                  }
                }
              } label: { Image(systemName: "arrow.left.arrow.right").foregroundStyle(cs.brand) }
            }
          }
        }
    } else {
      leagueless
    }
  }

  /// `#hubLeagueless` — Start a league · I have an invite code · Add golfers (wave 5's doors).
  private var leagueless: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        LeaguelessDoors(links: WizardLinks(
          onLocked: { id in store.preferredLeague = id; Task { await store.reload() } },
          onCancelled: { Task { await store.reload() } },
          startEvent: { presenter.handoff = .event },
          onJoined: { id in store.preferredLeague = id; Task { await store.reload() } }))
        NavigationLink(value: HomeRoute.people) {
          Text("Add golfers").font(CSFont.button).frame(maxWidth: .infinity, minHeight: 50).foregroundStyle(cs.ink)
            .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: 1))
        }
        .buttonStyle(.plain)
      }
      .padding(20)
    }
    .background(cs.bg0)
    .navigationTitle("Clubhouse")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func links(for m: Me.Membership) -> LeagueRoomLinks {
    let p = presenter
    let lid = m.league_id
    let board = onOpenBoard, schedule = onOpenSchedule, add = onAddGolfers
    return LeagueRoomLinks(
      openBoard: { board(lid) },
      openSchedule: { schedule() },
      openWizard: { p.wizard = .init(existingLeagueId: lid) },
      openDraft: { p.draft = lid },
      openReceipt: { p.receipt = $0 },
      openTourCard: { p.tourCard = $0 },
      addGolfers: { add(lid) },
      openRecord: { p.showPost = true },
      runItBack: { p.runBack = lid },
      leagueGone: { Task { await store.reload() } }
    )
  }
}
