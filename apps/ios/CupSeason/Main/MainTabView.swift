// Cup Season — the four places (D82, IOS-011): Home · Clubhouse · ⊕ · You.
// Each tab owns a NavigationStack; objects push, actions present through
// the Presenter installed here.

import SwiftUI
import CSDesign
import CupSeasonKit

enum HomeRoute: Hashable { case schedule, people, league(UUID) }
enum ClubRoute: Hashable { case board(UUID), schedule, album(UUID) }
enum YouRoute: Hashable { case people, settings }

struct MainTabView: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @State private var tab: Tab = .home
  @State private var presenter = Presenter()
  @State private var homePath = NavigationPath()
  @State private var clubPath = NavigationPath()
  @State private var youPath = NavigationPath()
  enum Tab: Hashable { case home, clubhouse, post, you }

  var body: some View {
    TabView(selection: $tab) {
      NavigationStack(path: $homePath) {
        HomeView(links: csLinks)
          .navigationDestination(for: ClubRoute.self) { r in
            switch r {
            case .board(let id): BoardScreen(leagueId: id, links: boardLinks)
            case .schedule: ScheduleScreen(links: csLinks)
            case .album(let id): AlbumScreen(leagueId: id)
            }
          }
          .navigationDestination(for: HomeRoute.self) { r in
            switch r {
            case .schedule: ScheduleScreen(links: csLinks)
            case .people: PeopleScreen(links: csLinks)
            case .league(let id): ClubhouseView(leagueId: id, onOpenBoard: { homePath.append(ClubRoute.board($0)) },
                                                onOpenSchedule: { homePath.append(HomeRoute.schedule) },
                                                onAddGolfers: { presenter.inviteTo = $0 })
            }
          }
      }
      .tabItem { Label("Home", systemImage: "house") }
      .tag(Tab.home)

      NavigationStack(path: $clubPath) {
        ClubhouseView(leagueId: store.preferredLeague,
                      onOpenBoard: { clubPath.append(ClubRoute.board($0)) },
                      onOpenSchedule: { clubPath.append(ClubRoute.schedule) },
                      onAddGolfers: { presenter.inviteTo = $0 })
          .navigationDestination(for: ClubRoute.self) { r in
            switch r {
            case .board(let id): BoardScreen(leagueId: id, links: boardLinks)
            case .schedule: ScheduleScreen(links: csLinks)
            case .album(let id): AlbumScreen(leagueId: id)
            }
          }
      }
      .tabItem { Label("Clubhouse", systemImage: "flag") }
      .tag(Tab.clubhouse)

      Color.clear
        .tabItem { Label("Post", systemImage: "plus.circle.fill") }
        .tag(Tab.post)

      NavigationStack(path: $youPath) {
        YouScreen(leagueId: store.preferredLeague, links: youLinks)
          .navigationDestination(for: YouRoute.self) { r in
            switch r {
            case .people: PeopleScreen(links: csLinks)
            case .settings: CardAndSettingsScreen()
            }
          }
      }
      .tabItem { Label("You", systemImage: "person.text.rectangle") }
      .tag(Tab.you)
    }
    .tint(cs.brand)
    .environment(\.presenter, presenter)
    .onChange(of: tab) { old, new in
      // the ⊕ is a verb, not a place: it presents, and the selection snaps back
      if new == .post { presenter.showPost = true; tab = old == .post ? .home : old }
    }
    .sheet(item: $presenter.tourCard) { TourCardSheet(profileId: $0, links: youLinks) }
    .sheet(item: $presenter.receipt) { RoundReceiptSheet(roundId: $0, seed: nil, openScorecard: { presenter.scorecard = $0 }) }
    .sheet(item: $presenter.scorecard) { ScorecardSheet(liveRoundId: $0) }
    .sheet(item: $presenter.scheduledRound) { ScheduledRoundSheet(roundId: $0, leagueId: store.preferredLeague, links: csLinks) }
    .sheet(item: $presenter.declare) { DeclareRoundSheet(prefill: $0, leagueId: store.preferredLeague) { _ in } }
    .sheet(isPresented: $presenter.showJoin) {
      JoinLeagueFlow(code: presenter.joinCode) { id in
        store.preferredLeague = id
        Task { await store.reload() }
      }
    }
    .sheet(isPresented: $presenter.showFeedback) {
      FeedbackSheet(screen: presenter.feedbackScreen, leagueId: store.preferredLeague,
                    leagueName: store.me?.memberships.first { $0.league_id == store.preferredLeague }?.name)
    }
    .sheet(isPresented: $presenter.showDesk) { FounderDeskSheet() }
    .sheet(isPresented: $presenter.showNote) { FounderNoteSheet() }
    .sheet(item: $presenter.inviteTo) { lid in
      let m = store.me?.memberships.first { $0.league_id == lid }
      PeoplePickerSheet(mode: .invite(.league(lid), share: m.flatMap { mm in mm.code.map { (name: mm.name, code: $0) } }),
                        onDone: { presenter.inviteTo = nil })
    }
    .sheet(item: $presenter.handoff) { HandoffSheet(kind: $0) }
    .fullScreenCover(item: $presenter.wizard) { t in
      WizardScreen(existingLeagueId: t.existingLeagueId, links: wizardLinks, initialStep: t.initialStep)
    }
    .fullScreenCover(item: $presenter.draft) { lid in
      NavigationStack {
        DraftNightScreen(leagueId: lid, links: DraftLinks(
          onSeasonStarted: { id in presenter.draft = nil; store.preferredLeague = id; Task { await store.reload() }; tab = .home },
          openWizard: { presenter.draft = nil; presenter.wizard = .init(existingLeagueId: lid) },
          addGolfers: { presenter.inviteTo = lid }))
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { presenter.draft = nil } } }
      }
    }
    .sheet(item: $presenter.runBack) { lid in
      NavigationStack {
        ScrollView { RunItBackCard(leagueId: lid, links: wizardLinks).padding(20) }
          .background(cs.bg0)
          .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { presenter.runBack = nil } } }
      }
      .presentationDetents([.medium, .large])
    }
    .fullScreenCover(isPresented: $presenter.showPost) { PostCoverView() }
  }

  // MARK: links

  private var csLinks: CSLinks {
    CSLinks(openTourCard: { presenter.tourCard = $0 },
            openRound: nil,      // a nil openRound presents the scheduled-round sheet in place
            openLeague: { id in store.preferredLeague = id; tab = .clubhouse })
  }

  private var wizardLinks: WizardLinks {
    WizardLinks(
      onLocked: { id in presenter.wizard = nil; presenter.runBack = nil; store.preferredLeague = id; Task { await store.reload() }; tab = .clubhouse },
      onCancelled: { presenter.wizard = nil; Task { await store.reload() } },
      startEvent: { presenter.handoff = .event },
      onJoined: { id in store.preferredLeague = id; Task { await store.reload() }; tab = .clubhouse })
  }

  private var boardLinks: BoardLinks {
    BoardLinks(openReceipt: { presenter.receipt = $0 }, openTourCard: { presenter.tourCard = $0 })
  }

  private var youLinks: YouLinks {
    YouLinks(
      openBuddies: { tab = .you; youPath.append(YouRoute.people) },
      openSettings: { tab = .you; youPath.append(YouRoute.settings) },
      openFeedback: { presenter.feedbackScreen = "you"; presenter.showFeedback = true },
      openFounderDesk: { presenter.showDesk = true },
      postRound: { presenter.showPost = true },
      openTourCard: { presenter.tourCard = $0 },
      openReceipt: { presenter.receipt = $0 },
      addGhin: { tab = .you; youPath.append(YouRoute.settings) },
      founderNote: { presenter.showNote = true },
      stageRound: { playOn, tag in presenter.declare = DeclarePrefill(iso: playOn, tagPids: [tag]) }
    )
  }
}

/// Wave 5/6 hand-off (the wizard, the event picker): honest, and a real
/// action — the web does it today.
struct HandoffSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  let kind: Presenter.Handoff
  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 14) {
        Text(kind == .league ? "Start a league" : "Start an event").csEyebrow()
        Text(kind == .league ? "The wizard lands on the phone in wave 5." : "Events land on the phone in wave 6.")
          .font(CSFont.title).foregroundStyle(cs.ink)
        Text(kind == .league
             ? "Until then, name your league at cupseason.app — three steps, lock it, and the invite link is yours."
             : "Until then, start a Ryder or a Major at cupseason.app; it shows up here the moment it exists.")
          .font(CSFont.body).foregroundStyle(cs.mut)
        Link(destination: CSConfig.webOrigin) {
          Text("Open cupseason.app").font(CSFont.button).frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(cs.bg0).background(cs.brand, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        }
        Spacer()
      }
      .padding(24).background(cs.bg0)
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
    }
    .presentationDetents([.medium])
  }
}
