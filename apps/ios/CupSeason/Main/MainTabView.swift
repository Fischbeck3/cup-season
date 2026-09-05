// Cup Season — the FIVE places (D222 / R-A, R-D; IOS-028):
// Home · Compete · ⊕ Play · Golfers · You.
//
// D82's four places ruled for a year and D93 restated it ("NAV UNCHANGED — and
// that is the point"). The owner overrode it at level 3, because "who am I
// competing with" cost three screens and every walked persona paid for it. The
// one rule of D82 that survives is the one that mattered: **the ⊕ is a verb,
// not a place** — it presents, the selection snaps back, and it wears ember.
//
// Each tab owns a NavigationStack; objects push, actions present through the
// Presenter installed here. **Nothing pushes across a stack any more**: the two
// cross-tab doors are environment actions (`\.openCompetition`, `\.openGolfers`)
// rather than a `NavigationLink(value:)` declared in one stack and resolved in
// another — which is the whole of the D178 class of bug (a link SwiftUI logs a
// warning about and silently ignores).

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

/// Home pushes exactly one thing now: the calendar. `.people` became
/// `openGolfers()` (a tab, not a push), and `.league`/`.pot` became
/// `openCompetition(_:pane:)` — a season is Compete's object, and Home has no
/// open league to push into (D229).
enum HomeRoute: Hashable { case schedule }

/// Compete's own stack. `.season` lands on the pane a door asked for — D218's
/// rule survives restated: a door named for a table opens a table, so "See the
/// table →" anchors `.standings` and the hero's own door opens the room. The
/// pane is `RoomPane` today and becomes the season page's `Pane` in wave 4
/// (D223 / IOS-031), which changes the LANDING and not this enum's callers.
enum CompeteRoute: Hashable { case season(UUID, pane: RoomPane), board(UUID), schedule, album(UUID) }

/// `.addGhin` is Card & settings opened on the card pane with the GHIN field
/// focused (Y-30) — the You hero's "add your GHIN" lands on the field, not the screen.
/// `.people` retired: Golfers is a tab (D222).
enum YouRoute: Hashable { case settings, addGhin }

/// Y-16, retargeted by D222 · "open this competition", callable from ANY
/// screen: remembers it, clears Compete's stack so the object is what shows,
/// and selects the tab. Installed once by `MainTabView`; the default is a no-op
/// so previews and slices compile without the shell.
///
///     @Environment(\.openCompetition) private var openCompetition
///     openCompetition(id, .standings)
private struct OpenCompetitionKey: EnvironmentKey {
  static let defaultValue: @MainActor @Sendable (UUID, RoomPane) -> Void = { _, _ in }
}
/// The second cross-tab door: Golfers, from Home's wire, from You's hero and
/// from every "Find golfers" in the app. It replaces the `HomeRoute.people`
/// push, which had to be declared in three separate stacks and was dead in a
/// fourth (D178).
private struct OpenGolfersKey: EnvironmentKey {
  static let defaultValue: @MainActor @Sendable () -> Void = {}
}
extension EnvironmentValues {
  var openCompetition: @MainActor @Sendable (UUID, RoomPane) -> Void {
    get { self[OpenCompetitionKey.self] }
    set { self[OpenCompetitionKey.self] = newValue }
  }
  var openGolfers: @MainActor @Sendable () -> Void {
    get { self[OpenGolfersKey.self] }
    set { self[OpenGolfersKey.self] = newValue }
  }
}

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
  @State private var competePath = NavigationPath()
  @State private var golfersPath = NavigationPath()
  @State private var youPath = NavigationPath()
  /// What the floating bar covers that the system does not already reserve —
  /// measured from the live bar (`CSTabBarProbe`), never guessed. 0 until the
  /// bar exists, which is exactly the behaviour the app had before.
  @State private var barRoom: CGFloat = 0
  #if DEBUG
  @State private var devOpened = false
  #endif
  /// D222 · five slots. The order is the bar's order and the ⊕ is the middle
  /// of the five, which is what keeps `CSTabBarLongPress.plusIndex(of:)`
  /// pointing at it without a constant to forget.
  enum Tab: Hashable {
    case home, compete, play, golfers, you
    /// The Kit's slot for this tab. One vocabulary, so `NavSlot` can decide
    /// where a route lands and this shell only obeys.
    init(_ slot: NavSlot) {
      switch slot {
      case .home: self = .home
      case .compete: self = .compete
      case .play: self = .play
      case .golfers: self = .golfers
      case .you: self = .you
      }
    }
  }

  var body: some View {
    // D163 · the round follows you. The bar sits ABOVE the tab view so it is
    // present on every tab, and stands down while the round is on screen.
    VStack(spacing: 0) {
      // L-34 · and while the live round is HOME's LEAD, the bar stands down
      // too: today both render and the same door is offered twice on one
      // screen (HM-35). `HomeLeadFlag` is written by Home when its rank-1
      // item is the live round and cleared the moment it is not.
      LiveNowBar(presented: presenter.showLive || (tab == .home && HomeLeadFlag.shared.liveIsLead)) { presenter.showLive = true }
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
      // ---- 1 · HOME. The dispatch. One push: the calendar. ----
      NavigationStack(path: $homePath) {
        HomeView(links: csLinks, push: { homePath.append($0) })
          .navigationDestination(for: HomeRoute.self) { r in
            switch r {
            case .schedule: ScheduleScreen(links: csLinks)
            }
          }
      }
      .csTabBarEdge()
      .tabItem { Label(NavSlot.home.label, systemImage: "house") }
      .tag(Tab.home)

      // ---- 2 · COMPETE. Every season and moment I am in, as peers. ----
      // O-06 · the slot's own name in the IA blueprint, and D11 retired
      // "clubhouse" from prose the day the tab kept the word.
      NavigationStack(path: $competePath) {
        CompeteScreen(links: csLinks,
                      push: { competePath.append($0) },
                      openGolfers: { openGolfers() })
          .navigationDestination(for: CompeteRoute.self) { r in competeDestination(r) }
      }
      .csTabBarEdge()
      .tabItem { Label(NavSlot.compete.label, systemImage: "flag") }
      .tag(Tab.compete)

      // ---- 3 · ⊕ PLAY. A verb, not a place (D82's one surviving rule). ----
      Color.clear
        .tabItem { Label { Text(NavSlot.play.label) } icon: { Image(uiImage: emberPlus) } }
        .tag(Tab.play)

      // ---- 4 · GOLFERS. The COMMUNITY destination (D222). ----
      NavigationStack(path: $golfersPath) {
        GolfersScreen(links: csLinks)
      }
      .csTabBarEdge()
      .tabItem { Label(NavSlot.golfers.label, systemImage: "person.2") }
      .tag(Tab.golfers)

      // ---- 5 · YOU. The card, the number, the record. ----
      NavigationStack(path: $youPath) {
        YouScreen(leagueId: store.preferredLeague, links: youLinks)
          .navigationDestination(for: YouRoute.self) { r in
            switch r {
            case .settings: CardAndSettingsScreen()
            case .addGhin: CardAndSettingsScreen(focus: .ghin)
            }
          }
      }
      .csTabBarEdge()
      .tabItem { Label(NavSlot.you.label, systemImage: "person.text.rectangle") }
      .tag(Tab.you)
    }
    // Room at the foot for the floating bar, answered in ONE place. Applied to
    // the TabView, so every tab and every screen pushed inside one — Card &
    // settings and People included, which paint their own ground and would
    // otherwise each have to know the number — leaves the bar its space.
    // `barRoom` is the measured SHORTFALL, so a screen the system already
    // clears gets nothing added and cannot be inset twice. (The other half —
    // the page not reading THROUGH the pill — is `.csTabBarEdge()`, per stack,
    // so the full-screen covers below never inherit it.)
    .csTabBarRoom(barRoom)
    .tint(cs.brand)
    .environment(\.presenter, presenter)
    .environment(\.openCompetition, { id, pane in openCompetition(id, pane: pane) })
    .environment(\.openGolfers, { openGolfers() })
    // Measure the bar once it exists, and dress it on the way past. The bar is
    // built after the first layout, so this polls briefly and then stops; a
    // shell that never finds one leaves `barRoom` at 0.
    .task(id: scenePhase) {
      guard scenePhase == .active, barRoom == 0 else { return }
      for _ in 0..<25 {
        if let room = CSTabBarProbe.dressAndMeasure(), room > 0 { barRoom = room; return }
        do { try await Task.sleep(for: .milliseconds(120)) } catch { return }
      }
    }
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
      case "compete", "clubhouse": tab = .compete
      case "you": tab = .you
      case "board": tab = .compete; if let l = store.preferredLeague { competePath.append(CompeteRoute.board(l)) }
      case "schedule": tab = .compete; competePath.append(CompeteRoute.schedule)
      case "settings": tab = .you; youPath.append(YouRoute.settings)
      case "golfers", "people": tab = .golfers; golfersPath = NavigationPath()
      case "post": presenter.postOnComposer = false; presenter.showPost = true
      case "postround": presenter.postOnComposer = true; presenter.showPost = true
      case "live": presenter.showLive = true
      case "wizard": presenter.wizard = .init(existingLeagueId: nil)
      case "events": presenter.showEventPicker = true
      // D199: the credential is the one surface that cannot be reached without
      // a finger — it opens from a name, and a name has to be tapped. Judging a
      // card design from a screenshot needed a door.
      case "tourcard": presenter.tourCard = store.me?.profile?.id
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
    // D179 · opening the live round IS seeing it; closing it just recounts.
    .onChange(of: presenter.showLive) { _, up in
      Task { up ? await PushBadge.markSeen() : await PushBadge.refresh() }
    }
    // ---- D104 §6: the contextual ask, raised only on a clear stage ----
    .task(id: ask.pending) { await drainAsk() }
    .onChange(of: presenter.anythingUp) { _, up in
      guard !up else { return }
      Task { try? await Task.sleep(for: .milliseconds(500)); await drainAsk() }   // let the curtain close first
    }
    .sheet(item: $ask.presented) { PushPromptSheet(reason: $0) }
    .onChange(of: tab) { old, new in
      // the ⊕ is a verb, not a place: it presents, and the selection snaps back (IOS-022 item 3: with a haptic)
      if new == .play {
        CSHaptic.present()
        tab = old == .play ? .home : old
        // D227 · with a round live, the ⊕ OPENS THE ROUND. It used to offer
        // the cover, whose first row is the same door `LiveNowBar` is already
        // offering two rows above it — the same act, twice, on one screen.
        if LiveRoundStore.shared.state.active {
          presenter.showLive = true
        } else {
          presenter.postOnComposer = false
          presenter.showPost = true
        }
      }
    }
    // D227 · a LONG-PRESS on the ⊕ opens the composer with the score focused.
    // The system tab bar has no gesture of its own, so the recogniser is
    // attached to the live `UITabBar` and answers only for the ⊕'s own item.
    // The 90 % case in one gesture, without spending L-40's clause.
    .task(id: barRoom) {
      CSTabBarLongPress.install(onPlus: {
        CSHaptic.present()
        presenter.postOnComposer = true
        presenter.showPost = true
      })
    }
    .sheet(item: $presenter.tourCard) { TourCardSheet(profileId: $0, links: youLinks) }
    .sheet(item: $presenter.receipt) { RoundReceiptSheet(roundId: $0, seed: nil, openScorecard: { presenter.scorecard = $0 }) }
    .sheet(item: $presenter.scorecard) { ScorecardSheet(liveRoundId: $0) }
    .sheet(item: $presenter.scheduledRound) { ScheduledRoundSheet(roundId: $0, leagueId: store.preferredLeague, links: csLinks) }
    .sheet(item: $presenter.declare) { DeclareRoundSheet(prefill: $0, leagueId: store.preferredLeague) { _ in } }
    .sheet(isPresented: $presenter.showJoin) {
      JoinLeagueFlow(code: presenter.joinCode) { id in
        Task { await store.reload() }
        openCompetition(id)
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
                                     openPeople: { presenter.showPost = false; openGolfers() },
                                     openCompetition: { presenter.showPost = false; openCompetition($0) },
                                     openTourCard: { presenter.showPost = false; presenter.tourCard = $0 }))
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
    // D222 · the SLOT is decided once, in the Kit, so a route that lands on a
    // destination that no longer exists is a failing `RouteMapTests` case and
    // not a blank screen. What happens INSIDE the slot is this switch's job.
    tab = Tab(NavSlot.of(route))
    switch route {
    case .receipt(let id): presenter.receipt = id
    case .scorecard(let id): presenter.scorecard = id
    // A board is a season's board, and a season is Compete's (route map §13.2).
    case .board(let league):
      store.preferredLeague = league
      competePath = NavigationPath()
      competePath.append(CompeteRoute.board(league))
    case .live(let lr):
      LiveRoundStore.shared.handleLiveOpen(lr: lr)
      presenter.showLive = true
    case .event(let id): presenter.event = id
    case .invites:
      homePath = NavigationPath()   // the banner sits at the top of Home
    // D222 · a person waiting on you is a COMMUNITY object. It was a push into
    // People, which lived under You; requests are the head of Golfers now.
    case .requests:
      golfersPath = NavigationPath()
    case .scheduledRound(let id): presenter.scheduledRound = id
    case .home:
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

  /// Y-16, retargeted · the ONE way a competition is opened (`CSLinks
  /// .openCompetition` and the `\.openCompetition` environment action both land
  /// here). The stack is cleared first, so a board pushed earlier cannot sit
  /// over the object you asked for.
  ///
  /// `preferredLeague` is written as NAVIGATION MEMORY and nothing else (D229):
  /// it decides which season Compete shows on arrival with no deeper intent,
  /// and no read on any other screen depends on it.
  private func openCompetition(_ id: UUID, pane: RoomPane = .standings) {
    store.preferredLeague = id
    competePath = NavigationPath()
    competePath.append(CompeteRoute.season(id, pane: pane))
    tab = .compete
  }

  /// The other cross-tab door. Requests sit at the head of the tab, so landing
  /// on the root IS landing on them.
  private func openGolfers() {
    golfersPath = NavigationPath()
    tab = .golfers
  }

  /// Compete's pushed destinations. `.season` is `LeagueRoomScreen` inside
  /// `ClubhouseView` today; wave 4 (D223 / IOS-031) swaps the landing for the
  /// season page and every caller here is unchanged by that.
  @ViewBuilder private func competeDestination(_ r: CompeteRoute) -> some View {
    switch r {
    case .season(let id, let pane):
      ClubhouseView(leagueId: id, pane: pane,
                    onOpenBoard: { competePath.append(CompeteRoute.board($0)) },
                    onOpenSchedule: { competePath.append(CompeteRoute.schedule) },
                    onAddGolfers: { presenter.inviteTo = $0 })
    case .board(let id): BoardScreen(leagueId: id, links: boardLinks)
    case .schedule: ScheduleScreen(links: csLinks)
    case .album(let id): AlbumScreen(leagueId: id)
    }
  }

  private var liveLinks: LiveLinks {
    LiveLinks(openReceipt: { presenter.receipt = $0 }, openTourCard: { presenter.tourCard = $0 }, done: { presenter.showLive = false })
  }

  private var csLinks: CSLinks {
    CSLinks(openTourCard: { presenter.tourCard = $0 },
            openRound: nil,      // a nil openRound presents the scheduled-round sheet in place
            openCompetition: { openCompetition($0) })
  }

  private var wizardLinks: WizardLinks {
    WizardLinks(
      onLocked: { id in presenter.wizard = nil; presenter.runBack = nil; Task { await store.reload() }; openCompetition(id) },
      onCancelled: { presenter.wizard = nil; Task { await store.reload() } },
      startEvent: { presenter.wizard = nil; presenter.showEventPicker = true },
      onJoined: { id in PushAsk.shared.request(.leagueJoined); Task { await store.reload() }; openCompetition(id) })
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
      openBuddies: { openGolfers() },
      openSettings: { tab = .you; youPath.append(YouRoute.settings) },
      openFeedback: { presenter.feedbackScreen = "you"; presenter.showFeedback = true },
      openFounderDesk: { presenter.showDesk = true },
      postRound: { presenter.postOnComposer = true; presenter.showPost = true },
      openTourCard: { presenter.tourCard = $0 },
      openReceipt: { presenter.receipt = $0 },
      addGhin: { tab = .you; youPath.append(YouRoute.addGhin) },   // Y-30: lands ON the field
      founderNote: { presenter.showNote = true },
      stageRound: { playOn, tag in presenter.declare = DeclarePrefill(iso: playOn, tagPids: [tag]) }
    )
  }
}

/// D227 · the ⊕'s long-press.
///
/// SwiftUI's `tabItem` takes no gesture, so the recogniser goes on the live
/// `UITabBar` and decides for itself whether the press landed on the ⊕: the
/// bar's own item buttons, sorted left to right, and `Tab.play` is the MIDDLE
/// one — the third of five since D222, and the third of four before it, which
/// is why `plusIndex(of:)` derives the index rather than naming it.
/// `cancelsTouchesInView` stays false, so an ordinary tap is
/// untouched and the ⊕ still presents the cover. A bar it cannot find means no
/// gesture at all — the cover's second row is the same door, one tap further.
@MainActor enum CSTabBarLongPress {
  @MainActor private final class Target: NSObject {
    let onPlus: () -> Void
    init(onPlus: @escaping () -> Void) { self.onPlus = onPlus }
    @objc @MainActor func fire(_ g: UILongPressGestureRecognizer) {
      guard g.state == .began, let bar = g.view as? UITabBar else { return }
      let point = g.location(in: bar)
      let buttons = bar.subviews
        .filter { String(describing: type(of: $0)).contains("TabBarButton") && $0.bounds.width > 1 }
        .sorted { $0.frame.minX < $1.frame.minX }
      guard let hit = buttons.firstIndex(where: { $0.frame.contains(point) }) else { return }
      guard hit == CSTabBarLongPress.plusIndex(of: buttons.count) else { return }
      onPlus()
    }
  }

  /// The ⊕ is the middle slot: index 2 of five since D222, and index 2 of four
  /// before it — the derivation is what carried the gesture through the change
  /// instead of silently moving it onto Golfers.
  static func plusIndex(of count: Int) -> Int { count <= 0 ? 0 : count / 2 }

  private static var target: Target?

  static func install(onPlus: @escaping () -> Void) {
    guard let bar = liveBar() else { return }
    if let existing = bar.gestureRecognizers?.first(where: { $0.name == "cs.plus.longpress" }) {
      bar.removeGestureRecognizer(existing)
    }
    let t = Target(onPlus: onPlus)
    target = t   // the recogniser holds its target weakly
    let g = UILongPressGestureRecognizer(target: t, action: #selector(Target.fire(_:)))
    g.name = "cs.plus.longpress"
    g.minimumPressDuration = 0.35
    g.cancelsTouchesInView = false
    g.delaysTouchesBegan = false
    bar.addGestureRecognizer(g)
  }

  private static func liveBar() -> UITabBar? {
    guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).flatMap(\.windows).first(where: \.isKeyWindow) else { return nil }
    return controller(in: window.rootViewController)?.tabBar
  }

  private static func controller(in vc: UIViewController?) -> UITabBarController? {
    guard let vc else { return nil }
    if let t = vc as? UITabBarController { return t }
    for child in vc.children { if let t = controller(in: child) { return t } }
    return controller(in: vc.presentedViewController)
  }
}

/// The floating tab bar, measured rather than guessed.
///
/// The bar floats OVER the page on this OS, so nothing downstream of it in
/// SwiftUI can see where its top edge is: a `GeometryReader` inside a tab
/// reports the safe area the system reserves, which is the very thing that is
/// too small. The live `UITabBar` knows both numbers, so it is asked for both:
/// what the pill COVERS (the screen's bottom edge up to the bar's top) and
/// what the system already RESERVES. The difference is what a page owes its
/// foot — 0 when the system already clears the bar, which is what keeps this
/// from ever insetting a screen twice.
///
/// Read once and held. The bar does not change height while the app runs (no
/// minimise behaviour is asked for), and re-reading after `csTabBarRoom` has
/// landed would measure our own inset back into the reserve.
@MainActor private enum CSTabBarProbe {
  /// Dress the bar and return the room it costs the page,
  /// or nil while there is no bar to read.
  static func dressAndMeasure() -> CGFloat? {
    guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow),
          let controller = tabController(in: window.rootViewController)
    else { return nil }
    let bar = controller.tabBar
    CSTabBarChrome.dress(bar)
    guard bar.bounds.height > 0 else { return nil }
    let frame = bar.convert(bar.bounds, to: window)
    let covers = max(0, window.bounds.maxY - frame.minY)
    // the tab's own bottom safe area: the bar's reservation plus the home
    // indicator. Zero means layout has not settled — do not trust it yet.
    let reserved = controller.selectedViewController?.view.safeAreaInsets.bottom ?? 0
    guard reserved > 0 else { return nil }
    return max(0, covers - reserved)
  }

  private static func tabController(in vc: UIViewController?) -> UITabBarController? {
    guard let vc else { return nil }
    if let t = vc as? UITabBarController { return t }
    for child in vc.children { if let t = tabController(in: child) { return t } }
    return tabController(in: vc.presentedViewController)
  }
}
