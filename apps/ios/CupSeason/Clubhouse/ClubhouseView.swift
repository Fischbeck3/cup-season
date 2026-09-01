// Cup Season — the Clubhouse tab: the league room for the open league
// (IOS-002 §5), with the league switcher and the league-less doors. A rank
// that moved UP since the last load gets one `.impact(.light)` as the room
// opens (IOS-003 §2.8 "rank moved up on open"; IOS-022 item 6).
//
// D203 — the leagues sit SIDE BY SIDE and you swipe between them. A menu is a
// fine way to jump to a league you named; it is a poor way to find out you
// have another one. The dots say how many rooms there are before you touch
// anything, and the menu stays for the jump — swipe is the discovery, the
// menu is the aim, and VoiceOver keeps the menu either way.
//
// Only the TAB pages. Pushed in at a named league (Home → a league), the
// Clubhouse shows that league and nothing beside it: you already chose.

import SwiftUI
import CSDesign
import CupSeasonKit

struct ClubhouseView: View {
  @Environment(SessionStore.self) private var store
  @Environment(LookStore.self) private var looks
  @Environment(\.presenter) private var presenter
  @Environment(\.cs) private var cs
  let leagueId: UUID?
  /// The tab root pages between leagues; a pushed league does not.
  var paged: Bool = false
  var onOpenBoard: (UUID) -> Void = { _ in }
  var onOpenSchedule: () -> Void = {}
  var onAddGolfers: (UUID) -> Void = { _ in }
  /// Bumps once per load in which the standing's rank beat `prev_rank`.
  @State private var rankUps = 0
  /// The page in hand. Seeded from the preferred league and written back to it
  /// as you swipe, so the rest of the app follows you out of the room.
  @State private var open: UUID?

  var body: some View {
    if let me = store.me, !me.memberships.isEmpty {
      let ms = me.memberships
      let wanted = open ?? leagueId ?? store.preferredLeague
      let current = ms.first(where: { $0.league_id == wanted }) ?? ms[0]
      Group {
        if paged && ms.count > 1 {
          VStack(spacing: 0) {
            dots(ms, current: current.league_id)
            TabView(selection: page(ms, current: current)) {
              ForEach(ms) { m in
                room(m, isCurrent: m.league_id == current.league_id, generatedAt: me.generated_at)
                  .tag(m.league_id)
              }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
          }
          // the strip above the pages wears the league you are looking at
          .environment(\.csLook, looks.look(for: current))
          .navigationTitle(current.name)
          .navigationBarTitleDisplayMode(.inline)
        } else {
          room(current, isCurrent: true, generatedAt: me.generated_at)
        }
      }
      .csFeedback(.rankUp, trigger: rankUps)
      .task(id: leagueId ?? store.preferredLeague) { open = leagueId ?? store.preferredLeague }
      .toolbar {
        if ms.count > 1 {
          ToolbarItem(placement: .topBarTrailing) {
            Menu {
              ForEach(ms) { m in
                Button { select(m.league_id) } label: {
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

  /// One league's room: its events, its board, its look.
  private func room(_ m: Me.Membership, isCurrent: Bool, generatedAt: Date?) -> some View {
    VStack(spacing: 0) {
      EventChips(leagueId: m.league_id, links: EventLinks(openEvent: { presenter.event = $0 },
                                                          openReceipt: { presenter.receipt = $0 },
                                                          openTourCard: { presenter.tourCard = $0 }))
      // paged: the title is set once, above, for the league in hand — six room
      // screens all claiming the navigation title is a race with no winner
      LeagueRoomScreen(leagueId: m.league_id, links: links(for: m), titled: !paged)
    }
    // IOS-025: the room wears its league's look — phase ≻ the Pro's choice ≻ the person's dial
    .environment(\.csLook, looks.look(for: m))
    .id(m.league_id)
    .task(id: generatedAt) {
      // only the room you are looking at may buzz: a paged TabView hosts the
      // neighbours too, and a haptic from a league off-screen is a ghost
      guard isCurrent, let st = m.standing, let prev = st.prev_rank, st.rank < prev else { return }
      rankUps += 1
    }
  }

  private func page(_ ms: [Me.Membership], current: Me.Membership) -> Binding<UUID> {
    Binding(get: { current.league_id },
            set: { id in guard id != current.league_id else { return }; select(id) })
  }

  private func select(_ id: UUID) {
    open = id
    store.preferredLeague = id
    CSHaptic.selection()
  }

  /// How many rooms there are, and which one you are in — the swipe's only
  /// advertisement. Tiny, above the events, out of the room's way.
  private func dots(_ ms: [Me.Membership], current: UUID) -> some View {
    let i = (ms.firstIndex { $0.league_id == current } ?? 0) + 1
    return HStack(spacing: 6) {
      ForEach(ms) { m in
        Circle()
          .fill(m.league_id == current ? cs.ink.opacity(0.7) : cs.ink.opacity(0.2))
          .frame(width: 5, height: 5)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 6).padding(.bottom, 8)
    // the room paints its own ground below; the strip has to stand on the same
    // one or it reads as a band bolted above the screen
    .background(cs.bg0)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("League \(i) of \(ms.count). Swipe left or right to change leagues.")
  }

  /// `#hubLeagueless` — Start a league · I have an invite code · Add golfers (wave 5's doors).
  private var leagueless: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        LeaguelessDoors(links: WizardLinks(
          onLocked: { id in store.preferredLeague = id; Task { await store.reload() } },
          onCancelled: { Task { await store.reload() } },
          startEvent: { presenter.showEventPicker = true },
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
      openRecord: { p.postOnComposer = false; p.showPost = true },
      runItBack: { p.runBack = lid },
      leagueGone: { Task { await store.reload() } }
    )
  }
}
