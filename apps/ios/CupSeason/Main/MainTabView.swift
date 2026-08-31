// Cup Season — the four places (D82, IOS-011): Home · Clubhouse · ⊕ · You.
// Each tab owns a NavigationStack; objects push, actions present through
// the Presenter installed here.

import SwiftUI
import CSDesign
import CupSeasonKit

/// Developer hatches (DEBUG only; the shipped build has no such door):
/// `-cs_dev_open <place>` lands a simulator on a screen, `-cs_dev_bottom`
/// opens Home / You scrolled to the foot so the lower half can be seen
/// without a finger. Neither exists in Release.
enum CSDevHatch {
  static var bottom: Bool {
    #if DEBUG
    ProcessInfo.processInfo.arguments.contains("-cs_dev_bottom")
    #else
    false
    #endif
  }
  /// `-cs_dev_settings_pane 1` opens Card & settings on the Settings pane.
  static var settingsPane: Int {
    #if DEBUG
    let a = ProcessInfo.processInfo.arguments
    if let i = a.firstIndex(of: "-cs_dev_settings_pane"), i + 1 < a.count { return Int(a[i + 1]) ?? 0 }
    #endif
    return 0
  }
  /// `-cs_dev_live` seeds a live match-play round, 14 holes in, so the tee
  /// sheet — and D152's landscape card — can be seen without signing in and
  /// playing one. DEBUG only; it never touches the server.
  static var live: Bool {
    #if DEBUG
    ProcessInfo.processInfo.arguments.contains("-cs_dev_live")
    #else
    false
    #endif
  }
  /// `-cs_dev_nearby` opens the live SETUP screen with one seeded NEARBY golfer,
  /// so D158's ask-chip and its prompt can be reviewed without a second phone.
  /// DEBUG only; the seed never touches the server and never leaves setup.
  static var nearby: Bool {
    #if DEBUG
    ProcessInfo.processInfo.arguments.contains("-cs_dev_nearby")
    #else
    false
    #endif
  }
  /// `-cs_dev_developer` reveals the Developer section as the long press would (IOS-022 item 8).
  static var developer: Bool {
    #if DEBUG
    ProcessInfo.processInfo.arguments.contains("-cs_dev_developer")
    #else
    false
    #endif
  }
  /// `-cs_dev_dress` opens the Pro's "Dress the room" disclosure on the League pane.
  static var dress: Bool {
    #if DEBUG
    ProcessInfo.processInfo.arguments.contains("-cs_dev_dress")
    #else
    false
    #endif
  }
  /// The looks store with its two hatches (IOS-025): `-cs_dev_look <key|calendar|none>`
  /// sets the personal dial for this run only (UserDefaults untouched);
  /// `-cs_dev_date 2026-07-15` pins the resolver's date so a window can be seen out of season.
  @MainActor static func lookStore() -> LookStore {
    let s = LookStore()
    #if DEBUG
    let a = ProcessInfo.processInfo.arguments
    if let i = a.firstIndex(of: "-cs_dev_look"), i + 1 < a.count { s.setPersonalTransient(PersonalLook(rawValue: a[i + 1])) }
    if let i = a.firstIndex(of: "-cs_dev_date"), i + 1 < a.count, let d = CSDate.local(a[i + 1]) { s.pinnedDate = d }
    #endif
    return s
  }
}

enum HomeRoute: Hashable { case schedule, people, league(UUID) }
enum ClubRoute: Hashable { case board(UUID), schedule, album(UUID) }
enum YouRoute: Hashable { case people, settings }

struct MainTabView: View {
  @Environment(SessionStore.self) private var store
  @Environment(LookStore.self) private var looks
  @Environment(\.cs) private var cs
  @Environment(\.colorScheme) private var scheme
  @Environment(\.scenePhase) private var scenePhase
  @State private var tab: Tab = .home
  @State private var presenter = Presenter()
  /// D104: the tapped-notification route waiting to land, and the contextual ask.
  @State private var router = PushRouter.shared
  @State private var ask = PushAsk.shared
  @State private var homePath = NavigationPath()
  @State private var clubPath = NavigationPath()
  @State private var youPath = NavigationPath()
  #if DEBUG
  @State private var devOpened = false
  #endif
  enum Tab: Hashable { case home, clubhouse, post, you }

  var body: some View {
    // D163 · the round follows you. The bar sits ABOVE the tab view so it is
    // present on every tab, and stands down while the round is on screen.
    VStack(spacing: 0) {
      LiveNowBar(presented: presenter.showLive) { presenter.showLive = true }
      tabs
    }
    // D175 · the doorbell rings wherever you are. Advertising has followed the
    // app since D168/D170, but the alert that answers it lived only on the tee
    // sheet — so a golfer was findable on every screen and askable on one. It
    // stands down while the live cover is up; `LiveSetupView` carries it there,
    // because an alert cannot present from underneath a full-screen cover.
    .csNearbyInvite(LiveRoundStore.shared, enabled: !presenter.showLive)
  }

  private var tabs: some View {
    TabView(selection: $tab) {
      NavigationStack(path: $homePath) {
        HomeView(links: csLinks, push: { homePath.append($0) })
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
          // D178 · ClubhouseView:65 emits `NavigationLink(value: HomeRoute.people)`
          // for "Add golfers", and this stack declared only ClubRoute — so the
          // link was INERT: SwiftUI logs "the link will not work" and the tap
          // does nothing. The league-less Clubhouse offers four affordances and
          // the last one was dead, on exactly the screen a brand-new tester
          // lands on.
          .navigationDestination(for: HomeRoute.self) { r in
            switch r {
            case .schedule: ScheduleScreen(links: csLinks)
            case .people: PeopleScreen(links: csLinks)
            case .league(let id): ClubhouseView(leagueId: id, onOpenBoard: { clubPath.append(ClubRoute.board($0)) },
                                                onOpenSchedule: { clubPath.append(ClubRoute.schedule) },
                                                onAddGolfers: { presenter.inviteTo = $0 })
            }
          }
      }
      .tabItem { Label("Clubhouse", systemImage: "flag") }
      .tag(Tab.clubhouse)

      Color.clear
        .tabItem { Label { Text("Post") } icon: { Image(uiImage: emberPlus) } }
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
    // D155 · tapping the Dynamic Island or the lock-screen card opens the round
    .onReceive(NotificationCenter.default.publisher(for: .csOpenLiveRound)) { _ in
      presenter.showLive = true
    }
    // D168 · nearby follows the APP. Foreground and opted in = discoverable to
    // your buddies; backgrounded = nothing, by construction (MultipeerConnectivity
    // has no background mode, and this app will never ask for one).
    .onChange(of: scenePhase) { _, phase in
      switch phase {
      case .active:     LiveRoundStore.shared.startNearby()
      case .background: LiveRoundStore.shared.stopNearby()
      default: break
      }
    }
    // D170 · keyed on IDENTITY, not on the view appearing. startNearby() bails
    // when myPid is nil, and a bare .task fires long before the session has
    // loaded — so nearby never actually started until the golfer opened the tee
    // sheet, whose onAppear called it again. That is why both phones still had
    // to be on the same screen after D168 said they would not.
    .task(id: store.me?.profile?.id) {
      guard store.me?.profile?.id != nil else { return }
      await LiveRoundStore.shared.configure(me: store.me, preferredLeague: store.preferredLeague)
      LiveRoundStore.shared.startNearby()
    }
    // D163 · a round you ACCEPTED has teed off — land in it without a tap. This
    // is the whole point of the handshake: you said yes, so the app takes you
    // there rather than leaving you to discover it.
    .onChange(of: LiveRoundStore.shared.openRequested) { _, want in
      guard want else { return }
      LiveRoundStore.shared.openRequested = false
      presenter.showLive = true
    }
    #if DEBUG
    // Developer hatch: `-cs_dev_open <place>` lands a simulator on a screen
    // without a finger. DEBUG-only; the shipped build has no such door.
    .task(id: store.me?.generated_at) {
      let a = ProcessInfo.processInfo.arguments
      guard !devOpened, store.me != nil, let i = a.firstIndex(of: "-cs_dev_open"), i + 1 < a.count else { return }
      try? await Task.sleep(for: .seconds(2))
      devOpened = true
      switch a[i + 1] {
      case "clubhouse": tab = .clubhouse
      case "you": tab = .you
      case "board": tab = .clubhouse; if let l = store.preferredLeague { clubPath.append(ClubRoute.board(l)) }
      case "schedule": tab = .clubhouse; clubPath.append(ClubRoute.schedule)
      case "settings": tab = .you; youPath.append(YouRoute.settings)
      case "people": tab = .you; youPath.append(YouRoute.people)
      case "post": presenter.postOnComposer = false; presenter.showPost = true
      case "postround": presenter.postOnComposer = true; presenter.showPost = true
      case "live": presenter.showLive = true
      case "wizard": presenter.wizard = .init(existingLeagueId: nil)
      case "events": presenter.showEventPicker = true
      default: break
      }
    }
    // `-cs_dev_push '<json>'` / `-cs_dev_push_prompt` / `-cs_dev_push_ids` (PushDev): the
    // simulator receives no APNs, so a launch argument stands in for the tap.
    .task(id: store.me?.generated_at) {
      guard store.me != nil else { return }
      if PushDev.printIds { await PushDev.dumpIds(me: store.me, preferred: store.preferredLeague) }
      try? await Task.sleep(for: .seconds(2))
      if let p = PushDev.payload { router.open(p) }
      if PushDev.forcePrompt { ask.force() }
    }
    #endif
    // ---- D104: a tapped notification lands here once the session is ready ----
    .task(id: router.pending) {
      guard let route = router.pending, store.me != nil else { return }
      router.pending = nil
      await apply(route)
    }
    // ---- D104 §4: the badge is the actionable count; recompute on foreground and around the live round ----
    .onChange(of: scenePhase) { _, phase in if phase == .active { Task { await PushBadge.refresh() } } }
    .onChange(of: presenter.showLive) { _, _ in Task { await PushBadge.refresh() } }
    // ---- D104 §6: the contextual ask, raised only on a clear stage ----
    .task(id: ask.pending) { await drainAsk() }
    .onChange(of: presenter.anythingUp) { _, up in
      guard !up else { return }
      Task { try? await Task.sleep(for: .milliseconds(500)); await drainAsk() }   // let the curtain close first
    }
    .sheet(item: $ask.presented) { PushPromptSheet(reason: $0) }
    .onChange(of: tab) { old, new in
      // the ⊕ is a verb, not a place: it presents, and the selection snaps back (IOS-022 item 3: with a haptic)
      if new == .post { CSHaptic.present(); presenter.postOnComposer = false; presenter.showPost = true; tab = old == .post ? .home : old }
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
    .sheet(isPresented: $presenter.showEventPicker) { EventPickerSheet(links: eventLinks) }
    .fullScreenCover(item: $presenter.event) { eid in
      NavigationStack {
        EventRoomScreen(eventId: eid, links: eventLinks)
          .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { presenter.event = nil } } }
      }
    }
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
    .fullScreenCover(isPresented: $presenter.showPost) {
      PostCoverView(startOnComposer: presenter.postOnComposer, links: PostLinks(openLive: { presenter.showLive = true },
                                     openReceipt: { presenter.receipt = $0 },
                                     openPeople: { presenter.showPost = false; tab = .you; youPath.append(YouRoute.people) }))
    }
    .fullScreenCover(isPresented: $presenter.showLive) { LiveRoundHost(links: liveLinks) }
  }

  /// The ⊕ wears the live metal whether or not it is selected (IOS-003: ember = the ⊕).
  /// An original-rendering UIImage is the one way to colour a tab glyph without a custom bar.
  /// IOS-025: under a personal look the halo tints to the look's accent (100%); ember when none.
  private var emberPlus: UIImage {
    let cfg = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
    let tint = looks.personalLook()?.accent(scheme == .light ? .light : .dark) ?? cs.brand
    return UIImage(systemName: "plus.circle.fill", withConfiguration: cfg)?
      .withTintColor(UIColor(tint), renderingMode: .alwaysOriginal) ?? UIImage()
  }

  // MARK: push (D104)

  /// One function lands every route (push-contract §2). Whatever is on stage
  /// comes down first, so the destination can rise; unknown → Home, never a
  /// blank.
  private func apply(_ route: PushRoute) async {
    if case .live = route {} else if presenter.dismissAll() {
      try? await Task.sleep(for: .milliseconds(450))   // the curtain closes before the next sheet
    }
    switch route {
    case .receipt(let id): presenter.receipt = id
    case .scorecard(let id): presenter.scorecard = id
    case .board(let league):
      store.preferredLeague = league
      tab = .clubhouse
      clubPath = NavigationPath()
      clubPath.append(ClubRoute.board(league))
    case .live(let lr):
      LiveRoundStore.shared.handleLiveOpen(lr: lr)
      presenter.showLive = true
    case .event(let id): presenter.event = id
    case .invites:
      tab = .home
      homePath = NavigationPath()   // the banner sits at the top of Home
    case .requests:
      tab = .home
      homePath = NavigationPath()
      homePath.append(HomeRoute.people)
    case .scheduledRound(let id): presenter.scheduledRound = id
    case .home:
      tab = .home
      homePath = NavigationPath()
    }
  }

  /// The ask rises only when nothing else is presented (§6: never inside
  /// another sheet's presentation).
  private func drainAsk() async {
    guard ask.pending != nil, !presenter.anythingUp, ask.presented == nil, router.pending == nil else { return }
    await ask.presentIfDue()
  }

  // MARK: links

  private var liveLinks: LiveLinks {
    LiveLinks(openReceipt: { presenter.receipt = $0 }, openTourCard: { presenter.tourCard = $0 }, done: { presenter.showLive = false })
  }

  private var csLinks: CSLinks {
    CSLinks(openTourCard: { presenter.tourCard = $0 },
            openRound: nil,      // a nil openRound presents the scheduled-round sheet in place
            openLeague: { id in store.preferredLeague = id; tab = .clubhouse })
  }

  private var wizardLinks: WizardLinks {
    WizardLinks(
      onLocked: { id in presenter.wizard = nil; presenter.runBack = nil; store.preferredLeague = id; Task { await store.reload() }; tab = .clubhouse },
      onCancelled: { presenter.wizard = nil; Task { await store.reload() } },
      startEvent: { presenter.wizard = nil; presenter.showEventPicker = true },
      onJoined: { id in PushAsk.shared.request(.leagueJoined); store.preferredLeague = id; Task { await store.reload() }; tab = .clubhouse })
  }

  private var eventLinks: EventLinks {
    EventLinks(openEvent: { presenter.showEventPicker = false; presenter.event = $0 },
               openReceipt: { presenter.receipt = $0 },
               openTourCard: { presenter.tourCard = $0 })
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
      postRound: { presenter.postOnComposer = true; presenter.showPost = true },
      openTourCard: { presenter.tourCard = $0 },
      openReceipt: { presenter.receipt = $0 },
      addGhin: { tab = .you; youPath.append(YouRoute.settings) },
      founderNote: { presenter.showNote = true },
      stageRound: { playOn, tag in presenter.declare = DeclarePrefill(iso: playOn, tagPids: [tag]) }
    )
  }
}

/// Wave 5/6 hand-off (the wizard, the event picker): honest, and a real
