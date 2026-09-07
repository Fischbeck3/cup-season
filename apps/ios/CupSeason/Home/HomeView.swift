// Cup Season — HOME, as an edition (IOS-046; D228, D229, D231 kept).
//
// **Home is the front page of an edition, not a stack of cards.** It opens
// with a masthead and a dateline, states one thing in the serif, prints the
// facts that are mine on a single rule, and then runs a wire whose items are
// deliberately unequal — a photograph, an editorial slat, a takeover band, a
// quiet line. There is no card and no border anywhere on it. Its character is
// **rhythm**: rule, type, photograph, rule, quiet line, so scrolling reads as
// a rundown rather than a scroll of tiles.
//
//   1  THE MASTHEAD    the wordmark over a 2pt rule, the dateline flush right.
//                      Stale rewrites the dateline IN PLACE and nothing else.
//   2  THE LEAD        weight 1 — the rank-1 item as a serif sentence with an
//                      84 × 90 chip. A ceremony leads as a takeover BAND, and
//                      a brand-new golfer's empty IS the page.
//   3  THE ME STRIP    two to four figures on ONE 2pt rule. A slot with no
//                      figure is absent; a numeral rail holds numerals.
//   4  THE WIRE        the five weights, in one list, running outward from
//                      today. The DECK IS DELETED: ranked items 2–5 enter the
//                      wire at the weight their kind earns rather than as four
//                      smaller copies of the lead (audit H-01).
//   5  THE FLOOR       four 44pt doors with glosses, at most one of them lit,
//                      on EVERY Home in every state (L-25, D94).
//
// WHAT SURVIVES THIS REWRITE, UNCHANGED, AND WHY IT HAD TO: `HomeModel`,
// `LoadKey`, `ranked()`, `feed(upcoming:spent:)`, `toggle(round:emoji:)`, the
// lead → deck → strip precedence, the `suppress` union, the failed-vs-empty
// branch, the widget snapshot and the refresh keys. **This wave replaced the
// view body and its seven row types; it did not touch the load.** One read,
// one arrangement, one instant — `home_dispatch(p_days)` returns
// `{me, items, lead_suppress}` and `HomeFallbackItems` composes what this
// client can honestly say when it cannot be reached, WITH NO LEAD CARD.
//
// AND ONE THING IN `ranked()` DID CHANGE, DELIBERATELY. It dropped every
// `invite:` route and every `friend:` key because the phone answered both IN
// PLACE, through `InvitesBanner` and `BuddyRequests` — two r10 boxes with
// 60%-ember borders that the design deletes (§3). With the banners gone the
// items have to render, or an invitation to a season would be the one Home
// state that shows a golfer nothing at all. The two clients now draw the same
// Home from the same payload, which is what D234 asked for in the first place.

import SwiftUI
import CSDesign
import CupSeasonKit

struct HomeView: View {
  @Environment(SessionStore.self) private var store
  @Environment(LookStore.self) private var looks
  @Environment(\.presenter) private var presenter
  @Environment(\.openCompetition) private var openCompetition
  @Environment(\.openGolfers) private var openGolfers
  @Environment(\.cs) private var cs
  let links: CSLinks
  /// A row is a door. The tap pushes onto the tab's own path.
  var push: (HomeRoute) -> Void = { _ in }
  @State private var vm = HomeModel()
  /// D229 · Home has NO open league. The key is the payload's stamp.
  private var loadKey: HomeModel.LoadKey { .init(generated: store.me?.generated_at) }

  /// The payload the strip and the wire are drawn from: the dispatch's own
  /// `me` when it served one (one read, one instant), the session's otherwise.
  private var me: Me? { vm.me ?? store.me }

  var body: some View {
    ScrollView {
      if let me {
        let ranked = vm.ranked()
        let strip = MeStripCopy.make(me,
                                     starter: StarterIndex.current(engineIndex: me.profile?.index_current),
                                     suppress: ranked.columnFacts,
                                     standingSaid: ranked.saysStanding)
        let buckets = vm.feed(upcoming: [], spent: ranked.spentRounds)
        let page = HomePage.make(me: me, strip: strip, ranked: ranked, buckets: buckets,
                                 digest: vm.digest, occasion: vm.occasion,
                                 loading: vm.loading, feedFailed: vm.feedFailed)
        VStack(alignment: .leading, spacing: 0) {
          // 1 · THE MASTHEAD. It needs no read, so it paints immediately —
          // the loading state is the destination's own geometry, redacted,
          // and this is the part of it that is never redacted at all.
          CSMasthead(date: Date(), asOf: staleAt)
            .padding(.horizontal, CSTokens.Space.gutter)

          // 2 · THE LEAD, in one of its three forms.
          lead(page, me: me)

          // 3 · THE ME STRIP.
          if !strip.isEmpty {
            HomeFacts(strip: strip, state: vm.stateKey,
                      leadIsLive: page.leadIsLive, starterLine: page.starter)
              .padding(.horizontal, CSTokens.Space.gutter)
              .padding(.top, CSTokens.Space.s5)
              .csRedacted(page.redacted)
          }

          // 4 · THE WIRE.
          wire(page, me: me, strip: strip)

          // 5 · THE FLOOR. On every Home, in every state.
          HomeFloor(offered: page.offered, pageHasPrimary: page.hasPrimary, pageHasEmber: page.hasEmber)
            .padding(.horizontal, CSTokens.Space.gutter)
            .padding(.top, CSTokens.Space.s4)
        }
        .padding(.bottom, CSTokens.Space.s5)
        .csPage("home")
      }
    }
    .background(cs.bg0)
    .environment(\.csLook, looks.personalLook())
    .defaultScrollAnchor(CSDevHatch.bottom ? .bottom : .top)
    // §1.6 · Home ends in a 28pt fade to `bg0`, so the tab band's rule never
    // guillotines a row mid-glyph (problem 10).
    .overlay(alignment: .bottom) {
      LinearGradient(colors: [cs.bg0.opacity(0), cs.bg0], startPoint: .top, endPoint: .bottom)
        .frame(height: 28).allowsHitTesting(false)
    }
    .refreshable {
      // The pull refreshes the SESSION's payload (every other tab reads it)
      // and then the dispatch, whose own answer supersedes it for this screen.
      await store.reload()
      await vm.load(me: store.me, key: loadKey)
    }
    .task(id: loadKey) { await vm.load(me: store.me, key: loadKey) }
    .navigationTitle("")
    .toolbar(.hidden, for: .navigationBar)
  }

  /// §13.3 · the read did not land and there is something on screen. The
  /// dateline says so and **no action is disabled**.
  private var staleAt: Date? {
    guard vm.feedFailed, !vm.dispatch.isEmpty || vm.digest != nil else { return nil }
    return store.me?.generated_at ?? Date()
  }

  // MARK: - 2 · the lead

  @ViewBuilder private func lead(_ page: HomePage, me: Me) -> some View {
    switch page.lead {
    case .none:
      EmptyView()

    // A CEREMONY IS A PHYSICAL OBJECT. The night a season ends leads with the
    // takeover band on the pinned `ceremony` ground in BOTH themes — which is
    // what makes ceremony night and a brand-new account two visibly different
    // surfaces rather than one card with a different eyebrow word (H-03).
    case .ceremony(let item):
      HomeWireTakeover(item: item) { take(item) }
        .padding(.top, CSTokens.Space.s4)

    // THE EMPTY IS THE PAGE. A drawn scorecard at 78pt, the producer's own
    // eyebrow and sentences, and ONE primary — never a link pretending to be
    // one on the emptiest screen in the product.
    case .empty(let item):
      VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
        CSGlyph(.scorecard, points: 78, labelled: true).foregroundStyle(cs.mut)
        VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
          Text(item.eyebrow).csType(.agate, caps: true).foregroundStyle(cs.mut)
          Text(item.headline).csType(.lead).foregroundStyle(cs.ink)
            .fixedSize(horizontal: false, vertical: true)
          if let s = item.standfirst, !s.isEmpty {
            Text(s).csType(.body).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        if let a = item.action, !a.isEmpty {
          CSDoor(.primary(a) { take(item) })
        }
      }
      .padding(.horizontal, CSTokens.Space.gutter)
      .padding(.top, CSTokens.Space.s5)
      .accessibilityElement(children: .contain)

    case .block(let item):
      HomeLead(item: item, membership: league(item)) { take(item) }
        .padding(.horizontal, CSTokens.Space.gutter)
        .padding(.top, CSTokens.Space.s4)
        .csRedacted(page.redacted)
    }
  }

  // MARK: - 4 · the wire

  @ViewBuilder private func wire(_ page: HomePage, me: Me, strip: MeStripCopy.Strip) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HomeSectionRule(page.wireTitle)
        .padding(.horizontal, CSTokens.Space.gutter)
        .padding(.bottom, CSTokens.Space.s3)

      if page.firstRound {
        // The three rows a first round turns on — three facts about the
        // product, not three promises about the golfer.
        HomeFirstRoundRows(rows: HomeFirstRound.rows(
          starter: strip.slots.first { $0.fact == .myNumber }?.value,
          homeCourse: me.profile?.home_course))
          .padding(.horizontal, CSTokens.Space.gutter)
      } else if page.redacted {
        // The destination's own geometry, redacted — never a spinner and never
        // three grey rectangles (H-21).
        ForEach(0..<3, id: \.self) { i in
          if i > 0 { CSRule() }
          HomeWireLine(marker: "Mon", text: "A round is landing on the wire.")
            .padding(.horizontal, CSTokens.Space.gutter)
        }
        .csRedacted(true)
      } else if let failed = page.failed {
        // C-10 · a failed read is never an empty one. Saying "no rounds from
        // your buddies" over a dead network is a claim about the golfer's
        // buddies made from a read that never answered.
        VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
          Text(failed.head).csType(.lead).foregroundStyle(cs.ink)
            .fixedSize(horizontal: false, vertical: true)
          Text(failed.sub).csType(.body).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
          CSDoor(.link("Try again") { Task { await vm.load(me: store.me, key: loadKey) } })
        }
        .padding(.horizontal, CSTokens.Space.gutter)
      } else if let block = page.wireEmptyItem {
        // The wire's own empty, as the design draws it: an eyebrow, a headline
        // that is a fact about the WORLD, and a body. Its door is the lit door
        // in the floor beneath, so the screen carries one act and not two.
        VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
          Text(block.eyebrow).csType(.agate, caps: true).foregroundStyle(cs.mut)
          Text(block.headline).csType(.lead).foregroundStyle(cs.ink)
            .fixedSize(horizontal: false, vertical: true)
          if let s = block.standfirst, !s.isEmpty {
            Text(s).csType(.body).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        .padding(.horizontal, CSTokens.Space.gutter)
        .accessibilityElement(children: .combine)
      } else if page.wireEmpty {
        // QB-05 · **NEVER "add some buddies" TO A GOLFER WITH A ROSTER**, and
        // the producer already branches on it. It is set as a SENTENCE with a
        // link and not as a serif headline: `head` and `door` are two halves
        // of one clause ("No rounds from your buddies yet. Post one, or / add
        // some buddies."), and New York at 28 breaks that clause in half and
        // spends the viewport's one serif appearance on it.
        let roster = EmptyRoot.wireEmpty(me: me)
        VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
          Text(roster.head).csType(.body).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
          CSDoor(.link(roster.door) {
            if let id = roster.leagueId { openCompetition(id, .table) } else { openGolfers() }
          })
        }
        .padding(.horizontal, CSTokens.Space.gutter)
      } else {
        ForEach(Array(page.rows.enumerated()), id: \.element.id) { i, row in
          if i > 0 || !row.leadsWithRule { CSRule() }
          wireRow(row)
        }
      }

    }
    .padding(.top, CSTokens.Space.s5)
  }

  @ViewBuilder private func wireRow(_ row: HomeWireRow) -> some View {
    switch row.body {
    case .round(let r, let url):
      VStack(alignment: .leading, spacing: 0) {
        if let url {
          HomeWireBand(row: r, photo: url,
                       open: { if let id = r.round_id { presenter.receipt = id } },
                       openPerson: { if let p = r.profile_id { presenter.tourCard = p } })
        } else {
          HomeWireSlat(row: r,
                       open: { if let id = r.round_id { presenter.receipt = id } },
                       openPerson: { if let p = r.profile_id { presenter.tourCard = p } })
            .padding(.horizontal, CSTokens.Space.gutter)
        }
        if let rid = r.round_id, let state = vm.social.state(for: rid) {
          HomeWireReactions(state: state, day: HomeWireCopy.dayMarker(r.played_on)) { emoji in
            react(r, emoji)
          }
          .padding(.horizontal, CSTokens.Space.gutter)
        }
      }
      .contextMenu {
        // "add a reaction" — the six named emoji, on a long press; same write path
        if let rid = r.round_id, let state = vm.social.state(for: rid) {
          ForEach(CSReactions.all) { rx in
            Button { react(r, rx.emoji) } label: { Label { Text(rx.label) } icon: { Text(rx.emoji) } }
              .disabled(state[rx.emoji]?.me == true)
          }
        }
      }

    case .takeover(let item):
      HomeWireTakeover(item: item) { take(item) }

    case .line(let marker, let text, let door):
      HomeWireLine(marker: marker, text: text, act: door.map { d in { open(d) } })
        .padding(.horizontal, CSTokens.Space.gutter)

    case .digest(let d):
      HomeWireLine(marker: nil, text: d.body, ink: cs.ink,
                   act: d.roundId.map { id in { presenter.receipt = id } })
        .padding(.horizontal, CSTokens.Space.gutter)

    case .occasion(let o):
      HomeWireLine(marker: nil, text: o.h, ink: cs.ink) {
        CSTelemetry.event("home_occasion_tap", ["win": .string(o.key), "act": .string("go")])
        if o.go == .league { presenter.showIntent = true } else { presenter.showEventPicker = true }
      }
      .padding(.horizontal, CSTokens.Space.gutter)
      .accessibilityAction(named: Text("Not this time")) { dismiss(o) }
      .contextMenu { Button("Not this time") { dismiss(o) } }
    }
  }

  // MARK: - doors

  private func open(_ door: HomeWireDoor) {
    switch door {
    case .feed(let d): FeedDoors.open(d, presenter: presenter)
    case .item(let i): take(i)
    }
  }

  private func dismiss(_ o: Occasion) {
    CSTelemetry.event("home_occasion_tap", ["win": .string(o.key), "act": .string("dismiss")])
    Occasion.dismiss(o); vm.occasion = nil
  }

  private func react(_ r: HomeFeedRow, _ emoji: String) {
    Task {
      guard let me = store.me else { return }
      _ = await vm.toggle(round: r, emoji: emoji, me: me, name: me.profile?.display_name ?? "You")
    }
  }

  /// The look an item wears: its own season's, when it names one.
  private func league(_ item: HomeDispatch.Item) -> Me.Membership? {
    guard let id = item.leagueId else { return nil }
    return me?.memberships.first { $0.league_id == id }
  }

  /// Every item's one door. The ranker chose it; this only opens it.
  private func take(_ item: HomeDispatch.Item) {
    CSTelemetry.event(CSTelemetry.Metric.ctaTapped.rawValue,
                      ["door": .string(item.key.split(separator: ":").first.map(String.init) ?? item.key),
                       "tier": .string(item.tier.rawValue)])
    switch item.route {
    case .composer:            presenter.postOnComposer = true; presenter.showPost = true
    case .people:              openGolfers()
    case .declare:             presenter.declare = DeclarePrefill()
    case .live:                presenter.showLive = true
    case .receipt(let id):     presenter.receipt = id
    case .plan(let id):        presenter.scheduledRound = id
    case .season(let id, let pane): openCompetition(id, SeasonPane.named(pane))
    case .pot(let id):         openCompetition(id, .pot)
    case .invite(let id, _):   openCompetition(id, .table)
    case .none:                break
    }
  }
}

/// L-34 · while the live round IS the lead, `LiveNowBar` stands down. Today
/// both render and the same door is offered twice on one screen (HM-35). The
/// bar lives above the TabView, so the fact has to travel: Home writes it,
/// `MainTabView` reads it, and it is false the moment Home is not showing a
/// live lead.
@MainActor
@Observable
final class HomeLeadFlag {
  static let shared = HomeLeadFlag()
  var liveIsLead = false
  private init() {}
}

@MainActor
@Observable
final class HomeModel {
  /// The wire as loaded, newest first. The view folds it (`feed(upcoming:)`)
  /// against the Coming-up card, which loads on its own clock.
  var items: [HomeItem] = []
  var digest: HomeDigest?
  var occasion: Occasion?
  /// The ranked dispatch, served or composed. Empty is a legal answer.
  var dispatch: [HomeDispatch.Item] = []
  /// The lead's own suppress set, as the server published it.
  var leadSuppress: Set<MeStripCopy.Fact> = []
  /// The payload the dispatch came back with — nil while it has not served
  /// one, and then the view falls back to the session's.
  var me: Me?
  /// True while the client is composing the dispatch itself. It is not an
  /// error state; it is a shorter, honest Home with no lead card.
  var usedFallback = false
  /// F-2 · the rounds the ranked cards have already told a story about. Set
  /// when the arrangement settles, so the DIGEST (which reaches for the best
  /// round in the feed on a quiet day) yields the same fact the deck spent.
  var spentRounds: Set<UUID> = []
  /// C-10 · the wire read did not answer. A DIFFERENT answer from "your buddies
  /// have posted nothing", which is what the screen used to say over a dead
  /// network (L-32's second half).
  var feedFailed = false
  var loading = false
  var social = HomeSocial.Snapshot()
  private var markRead = false
  /// D252 · `app_flags.ios.major`, read once per model and only when a card
  /// that sells a Major is actually in its window. nil = not read yet.
  /// **Carried through wave 1b's rewrite on purpose**: dropping it would leave
  /// the four gated cards dark for ever after wave 3 opens the flag.
  private var majorOpen: Bool?
  private var mark: Date?
  private var rounds: [HomeFeedRow] = []
  private var posts: [HomePost] = []
  private var urls: [UUID: URL] = [:]
  private let repo = HomeStreamRepository()
  private let socialRepo = HomeSocial()
  /// Which load is current. A superseded run still comes back from its awaits,
  /// and without this it would write the old stream over the new one.
  private var generation = 0
  /// The load in flight, by the key it was started for.
  private var inflight: (key: LoadKey, task: Task<Void, Never>)?

  /// D234 · which Home this is, for `home_state_seen`. It is the LEAD's own
  /// tier and key now, which is the state matrix's own answer to "which Home
  /// is this" — and it carries no name, no handle and no id.
  var stateKey: String {
    guard let lead = HomeRank.arrange(dispatch, leadSuppress: leadSuppress).lead else {
      return usedFallback ? "fallback_no_lead" : "quiet"
    }
    return "\(lead.tier.rawValue)_\(lead.key.split(separator: ":").first.map(String.init) ?? "item")"
  }

  /// The screen, arranged. Pure over what is in hand, so the same items always
  /// produce the same Home.
  func ranked() -> HomeRank.Ranked {
    // IOS-046 · the two banners are GONE FROM HOME (`home.md` §3), so the items they
    // used to answer in place have to render, or an invitation to a season is
    // the one Home state that shows a golfer nothing at all. `InvitesBanner`
    // and `BuddyRequests` were an r10 box with a 60%-ember border and a read
    // of their own (they stay on Golfers and You, where the list IS the
    // screen); an invitation is a weight-1 block now, and it is the same
    // object on both clients from the same payload. Everything else about the
    // arrangement is untouched.
    let mine = dispatch
    // R-06 · `allowLead: !usedFallback` — UX_PRINCIPLES §5.4 rule 2, which this
    // file's own header restates: the declared fallback renders NO LEAD CARD,
    // because a guessed lead is the exact failure the veto exists to prevent.
    // The web obeyed it and the phone did not, so on the day the ranker cannot
    // be reached the two clients drew a structurally different Home.
    return HomeRank.arrange(mine, leadSuppress: leadSuppress,
                            useServerRank: !usedFallback, allowLead: !usedFallback)
  }

  /// C-05 / C-11 · the two writes that reach OUTSIDE this screen, made once per
  /// load instead of once per body evaluation.
  ///
  /// `HomeLeadFlag` is `@Observable` and `MainTabView.body` reads it, so
  /// assigning it from `HomeView.body` invalidated the ancestor mid-render —
  /// "Modifying state during view update", and at worst a loop. The widget
  /// snapshot is an App-Group `UserDefaults` write, which has no business
  /// happening on a scroll.
  ///
  /// The widget is handed a LEAD only when the ranker actually served one: a
  /// sentence composed by the declared fallback is honest on Home, where the
  /// screen around it says what it is, and is not a sentence to put on a home
  /// screen as though the server said it.
  private func publishOutwards(me m: Me) {
    let r = ranked()
    let strip = MeStripCopy.make(m, starter: StarterIndex.current(engineIndex: m.profile?.index_current),
                                 suppress: r.columnFacts, standingSaid: r.saysStanding)
    let lead = r.lead
    spentRounds = r.spentRounds
    if let mark { digest = HomeDigest.make(rounds: rounds, posts: posts, photoURLs: urls, mark: mark,
                                           mentions: social.mentions(rounds: rounds, since: mark),
                                           spent: r.spentRounds) }
    if case .live = lead?.route { HomeLeadFlag.shared.liveIsLead = true }
    else { HomeLeadFlag.shared.liveIsLead = false }
    DispatchSnapshotFeed.publish(strip: strip, lead: usedFallback ? nil : lead)
  }

  /// One load per payload. A pull and `.task(id:)` share a key; the second
  /// caller joins the run in flight instead of racing it.
  func load(me sessionMe: Me?, key: LoadKey) async {
    if let cur = inflight, cur.key == key { await cur.task.value; return }
    generation += 1
    let gen = generation
    let task = Task { [self] in
      await run(me: sessionMe, gen: gen)
      if gen == generation { inflight = nil }
    }
    inflight = (key, task)
    await task.value
  }

  #if DEBUG
  /// The Home-state hatch's substitution (D259). The wire, the social read and
  /// the occasion are CLEARED rather than faked: a fixture that invented a feed
  /// would be inventing golfers, and `EVIDENCE_POLICY.md` forbids exactly that.
  /// The widget snapshot is not written either — a fixture is not a fact to put
  /// on a home screen.
  private func runFixture(_ id: String) {
    guard let p = HomeStateFixtures.payload(id) else {
      NSLog("[home-state] no fixture named \(id). Try one of: \(HomeStateFixtures.all.map(\.id).joined(separator: ", "))")
      return
    }
    if let s = HomeStateFixtures.state(id) { NSLog("[home-state] \(s.matrix) · \(s.title) — \(s.note)") }
    me = p.me
    dispatch = p.items
    leadSuppress = p.leadSuppress
    usedFallback = false
    occasion = nil
    items = []; digest = nil; feedFailed = false
    social = HomeSocial.Snapshot()
    guard p.me != nil else { return }
    let r = ranked()
    spentRounds = r.spentRounds
    if case .live = r.lead?.route { HomeLeadFlag.shared.liveIsLead = true }
    else { HomeLeadFlag.shared.liveIsLead = false }
  }
  #endif

  private func run(me sessionMe: Me?, gen: Int) async {
    guard let sessionMe else { return }
    guard live(gen) else { return }
    loading = true
    defer { if gen == generation { loading = false } }

    #if DEBUG
    // D259 · `-cs_dev_home_state <id>`. ONE READ is substituted and nothing
    // else changes: the same arrangement rule, the same producers, the same
    // six slots. It is the only way twelve of the seventeen states in
    // `HOME_STATE_MATRIX.md` can be looked at, and it never writes anything.
    if let want = CSDevHatch.homeState { runFixture(want); return }
    #endif

    // D252 · a card whose act is a Major or a jug does not render until the
    // Major's door opens. The WINDOW is checked first — pure, no I/O — so the
    // flag is fetched only on the days one of the four gated cards would
    // otherwise show. Fail-closed: an unreadable flag leaves the card down.
    // B-1 / QB-19 · "has a league" and "has a season running" are different
    // questions, and this asked the first while meaning the second. A golfer
    // between seasons answered "has a league" — so the one Home card written
    // for her state could never reach her, and neither could the one written
    // for a golfer with friends and no competition.
    let leagueless = Occasion.nothingRunning((self.me ?? sessionMe).memberships)
    if majorOpen == nil, Occasion.needsMajorToday(leagueless: leagueless) {
      majorOpen = await EventFlags.majorEnabled()
      guard live(gen) else { return }
    }
    occasion = Occasion.current(leagueless: leagueless, majorOpen: majorOpen ?? false)

    // R1 · the one read. `nil` is "the ranker could not be reached", which is
    // a different answer from "the ranker returned nothing".
    let served = await repo.dispatch(days: 21)
    guard live(gen) else { return }
    if let served {
      me = served.me
      dispatch = served.items
      leadSuppress = served.leadSuppress
      usedFallback = false
    }

    let r = await repo.load(memberships: (me ?? sessionMe).memberships)
    guard live(gen) else { return }
    // A failed read is not an empty feed. With rounds already on screen, a
    // pull on a bad signal keeps them.
    feedFailed = r.failed
    if !(r.failed && !items.isEmpty) {
      items = r.items
      rounds = r.rounds; posts = r.posts
      if !markRead { mark = HomeDigest.readAndMark(profile: (me ?? sessionMe).profile?.id); markRead = true }
      urls = [:]
      for case .round(let row, let u) in r.items { if let id = row.round_id, let u { urls[id] = u } }
      digest = HomeDigest.make(rounds: rounds, posts: posts, photoURLs: urls, mark: mark, spent: spentRounds)
    }

    // The DECLARED FALLBACK (preflight 23). It runs after the wire, because
    // its CIRCLE item is composed from the same rows.
    if served == nil {
      // R-04 · the live item has two faces and the invitation's needs a name.
      // `native_home.live_round` carries `mine` but no host, and the device
      // already knows who started the round it is seated in.
      dispatch = HomeFallbackItems.make(me ?? sessionMe, feed: rounds,
                                        liveHost: LiveRoundStore.shared.state.host)
      leadSuppress = []
      usedFallback = true
    }

    // D238 · `me` is passed now, because the reaction is keyed on the PERSON.
    // Without it a leagueless friend's round would carry a strip whose own
    // flame did not read as mine.
    let snap = await socialRepo.load(rounds: rounds, memberships: (me ?? sessionMe).memberships,
                                     currentLeague: nil, me: (me ?? sessionMe).profile?.id)
    guard live(gen) else { return }
    social = snap
    // F-2 · the digest is rebuilt inside `publishOutwards`, where the ranked
    // arrangement is in hand and the rounds it spent are known.
    publishOutwards(me: me ?? sessionMe)
  }

  /// Still the current load — the only state a load may write from.
  private func live(_ gen: Int) -> Bool { gen == generation }

  /// D217 · the wire, folded: booking lines already on the Coming-up card are
  /// hidden, the same note across leagues is one line. Pure over what is in hand.
  func feed(upcoming: Set<UUID>, spent: Set<UUID> = []) -> [HomeFeedBucket] {
    HomeFeedFold.fold(items, upcoming: upcoming, spent: spent)
  }

  /// What `.task(id:)` watches: the payload's stamp. D229 — no league.
  struct LoadKey: Equatable { let generated: Date? }

  /// `toggleHomeRx` — optimistic flip, one write path, revert + toast on failure.
  func toggle(round: HomeFeedRow, emoji: String, me who: Me, name: String) async -> String? {
    guard let rid = round.round_id, let t = social.targets[rid] else { return nil }
    var st = social.rx[t.postId, default: [:]][emoji, default: ReactionState()]
    let had = st.me
    st.flip(me: name, on: !had)
    social.rx[t.postId, default: [:]][emoji] = st
    do { try await socialRepo.write(target: t, memberships: who.memberships, me: who.profile?.id, emoji: emoji, had: had); return nil }
    catch {
      st.flip(me: name, on: had)
      social.rx[t.postId, default: [:]][emoji] = st
      return AuthRules.human(error, fallback: "Reaction did not save.")
    }
  }
}

/// The six reactions as VoiceOver actions on a Home round (the tray is a long press for the eye).
private struct A11yReactionActions: ViewModifier {
  let enabled: Bool
  let toggle: (String) -> Void
  func body(content: Content) -> some View {
    if enabled {
      content
        .accessibilityAction(named: CSReactions.all[0].label) { toggle(CSReactions.all[0].emoji) }
        .accessibilityAction(named: CSReactions.all[1].label) { toggle(CSReactions.all[1].emoji) }
        .accessibilityAction(named: CSReactions.all[2].label) { toggle(CSReactions.all[2].emoji) }
        .accessibilityAction(named: CSReactions.all[3].label) { toggle(CSReactions.all[3].emoji) }
        .accessibilityAction(named: CSReactions.all[4].label) { toggle(CSReactions.all[4].emoji) }
        .accessibilityAction(named: CSReactions.all[5].label) { toggle(CSReactions.all[5].emoji) }
    } else {
      content
    }
  }
}


/// Where a feed door leads — the routes the rest of Home already uses: the
/// scorecard sheet, the round receipt (`FeedRoundCard`), the scheduled-round
/// sheet (`UpNextChips` · `.round`).
@MainActor private enum FeedDoors {
  static func open(_ d: HomeFeedDoor, presenter: Presenter) {
    switch d {
    case .live(let id):      presenter.scorecard = id
    case .round(let id):     presenter.receipt = id
    case .scheduled(let id): presenter.scheduledRound = id
    }
  }
  static func tag(_ d: HomeFeedDoor) -> String {
    switch d { case .live: "SCORECARD"; case .round: "THE ROUND"; case .scheduled: "THE SCHEDULE" }
  }
  static func hint(_ d: HomeFeedDoor) -> String {
    switch d { case .live: "Opens the scorecard"; case .round: "Opens the round"; case .scheduled: "Opens the round on the schedule" }
  }
}
