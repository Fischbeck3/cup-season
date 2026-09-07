// Cup Season — Home, as one ranked dispatch (D228, D229, D231, IOS-029b).
//
// Six slots, one order, every state (HOME_STATE_MATRIX.md §1). A state does
// not change the layout; it changes what fills it.
//
//   1  MASTHEAD      the wordmark and the dateline. Never a badge, never a
//                    count of my absence.
//   2  THE LEAD      the rank-1 item — a person's sentence with one verb.
//                    NO card is a legal answer.
//   3  THE ME STRIP  my number · my last round · my next round · my money,
//                    plus one season context row. Always present (D236).
//   4  THE DECK      items 2–5, ranked, each one sentence with one door.
//                    A shorter deck is a shorter deck; it is never padded.
//   5  THE WIRE      the feed, WHOLE — D217's fold and D218's head, kept.
//   6  THE FOUR DOORS  always present, never behind a `+` (L-32, D94).
//
// WHAT RETIRED WITH THIS FILE'S REWRITE, and why each had to go together:
//
//   · `HomeMode`'s six-case switch and its six heroes. A hero addressed to a
//     phase is a database record with a serif face on it, and it led with a
//     STANDING — which the veto now forbids outright (D231).
//   · The D121 compact rows. A row that re-rendered Home around another
//     league was a mode change disguised as a link; its content survives as
//     ranked items, each naming its own season (D229).
//   · The `+` menu. It hid three of the four doors behind a glyph; the doors
//     are the floor now and they are on the surface in every state.
//
// ONE READ. `home_dispatch(p_days)` returns `{me, items, lead_suppress}` — the
// ME facts and the ranked list in one payload, so nothing on this screen is
// composed twice and the strip and the cards describe one instant. When it
// cannot be reached, `HomeFallbackItems` composes what this client can honestly
// say from `native_home` + `home_feed`, in a static order, WITH NO LEAD CARD
// (a guessed lead is the exact failure the veto exists to prevent).

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
  /// A card is a door. The tap pushes onto the tab's own path — the pattern
  /// the Clubhouse destinations already use.
  var push: (HomeRoute) -> Void = { _ in }
  @State private var vm = HomeModel()
  /// The Coming-up card's model, owned here so the feed's fold can hide a
  /// booking line whose round is already a card (D217 rule 1).
  @State private var upcoming = UpcomingModel()
  /// D229 · Home has NO open league. The key is the payload's stamp and
  /// nothing else — `preferredLeague` is navigation memory now, and a screen
  /// that reloads around it is the switcher this wave deleted.
  private var loadKey: HomeModel.LoadKey { .init(generated: store.me?.generated_at) }

  /// The payload the strip and the cards are drawn from: the dispatch's own
  /// `me` when it served one (one read, one instant), the session's otherwise.
  private var me: Me? { vm.me ?? store.me }

  var body: some View {
    ScrollView {
      if let me {
        // D247 · the starter the golfer picked at onboarding lives on the
        // device and is spent the moment the engine has a number of its own.
        // **The column is arranged FIRST, and the strip yields to it.**
        // It used to run the other way — the strip was built, its four facts
        // became `stripSuppress`, and the deck was handed a set it never read.
        // `HOME_STATE_MATRIX` §3 row 3 states the precedence the other way
        // round: the strip may not render "any fact the lead or the deck also
        // renders". So: lead → deck → strip, one way, no negotiation.
        let ranked = vm.ranked()
        let strip = MeStripCopy.make(me,
                                     starter: StarterIndex.current(engineIndex: me.profile?.index_current),
                                     suppress: ranked.columnFacts,
                                     standingSaid: ranked.saysStanding)
        // IOS-034's widget snapshot and L-34's live-lead flag are BOTH written
        // from `HomeModel.run(...)`, never from here (C-05, C-11): a body is
        // evaluated on every scroll and on every observation change, and both
        // writes have consequences outside this view.
        VStack(alignment: .leading, spacing: 14) {
          // 1 · the masthead. IOS-019 rule 3: the wordmark lives in the
          // scroll, where the glass toolbar cannot clip it.
          CSPageHeader("Cup Season", eyebrow: CSHeaderDate.today()) { EmptyView() }.padding(.bottom, 2)

          // 2 · THE LEAD. One card, a human subject, one ember verb — or no
          // card at all, which is what a golfer with nothing pressing gets.
          if let lead = ranked.lead {
            HomeLeadCard(item: lead) { take(lead) }
              .environment(\.csLook, looks.look(for: league(lead)))
          }

          // An invitation and a buddy request are answered IN PLACE here, so
          // the ranker's own items for them stand down on the phone (L-34).
          // They are items on the web, which has no such banners.
          // D259 · under `-cs_dev_home_state` these two make their own reads, so
          // they would answer the signed-in account over a fixture screen.
          if !CSDevHatch.fixtureHome {
            InvitesBanner { _ in Task { await store.reload() } }
            BuddyRequests(links: links, head: true, onAnswered: { Task { await store.reload() } })
          }

          // 3 · THE ME STRIP. Four facts that are about ME, and one season
          // context row. It publishes `suppress`; the lead's set is UNIONED
          // onto it, never swapped for it.
          MeStrip(strip: strip, state: vm.stateKey, push: push)

          // 4 · THE DECK. At most four, ranked, never padded.
          ForEach(Array(ranked.deck.enumerated()), id: \.element.id) { idx, item in
            HomeDeckCard(item: item,
                         moreCut: idx == ranked.deck.count - 1 ? ranked.cut : 0,
                         moreLabel: ranked.overflow.first?.action,
                         act: { take(item) },
                         // QB-18 · it opened the GOLFERS TAB. The card that ran
                         // out of room was a season card, and the link sent the
                         // golfer to his address book: *"A link that lies about
                         // its destination is worse than a card that admits it
                         // ran out of room."* It opens the item it elided.
                         onMore: { if let o = ranked.overflow.first { take(o) } })
              .environment(\.csLook, looks.look(for: league(item)))
          }

          if let o = vm.occasion {
            OccasionCard(o: o, onGo: {
                           CSTelemetry.event("home_occasion_tap", ["win": .string(o.key), "act": .string("go")])
                           if o.go == .league { presenter.showIntent = true } else { presenter.showEventPicker = true }
                         },
                         onDismiss: {
                           CSTelemetry.event("home_occasion_tap", ["win": .string(o.key), "act": .string("dismiss")])
                           Occasion.dismiss(o); vm.occasion = nil
                         })
          }

          // L-34 · the strip owns NEXT and the lead may own the plan, so the
          // chips honour the UNION of both sets.
          if !CSDevHatch.fixtureHome {
          UpNextChips(leagueId: nil, links: links, suppress: ranked.suppress, go: { go in
            switch go {
            case .round(let id):  presenter.scheduledRound = id
            case .calendar:       push(.schedule)
            case .people:         openGolfers()
            case .standings:      break
            }
          })
          }

          // F-2 · the wire never re-tells a round the deck above already told.
          let buckets = vm.feed(upcoming: upcoming.ids, spent: ranked.spentRounds)

          // 5 · THE WIRE — the feed, whole. D218: the lane is cross-league, so
          // its door is the buddies.
          //
          // **A HEADING IS A LABEL FOR A LIST, AND THERE IS NO LIST.** With an
          // empty wire this rendered `AROUND YOUR BUDDIES`, a `YOUR BUDDIES ↗`
          // door beside it, and then *"No rounds from your buddies yet. Post
          // one, or add some buddies."* — three gestures at one absence, above
          // a fourth (`FIND GOLFERS`) in the foot doors. To a golfer who has
          // nobody, the word arrived four times in half a screen.
          //
          // The heading and its door are what a list needs. The empty branch
          // below is already one sentence carrying its own door, and it says
          // the same thing better because it says it once.
          if !buckets.isEmpty || vm.loading || vm.feedFailed {
            HomeSectionHead("Around your buddies") {
              // D222 · Golfers is a TAB. It was a push into a screen that lived
              // under You, declared here and resolved in three stacks — the shape
              // that made D178's dead link possible.
              Button { openGolfers() } label: { Text("YOUR BUDDIES ↗").csEyebrow(cs.ink).a11yHitSlop() }
                .buttonStyle(.plain)
                .accessibilityLabel("Your buddies")
                .accessibilityHint("Opens the Golfers tab")
            }
          }
          if let d = vm.digest { CSRow(last: !buckets.isEmpty) { HomeDigestRow(digest: d, openReceipt: { presenter.receipt = $0 }) } }

          if vm.loading && buckets.isEmpty {
            ForEach(0..<3, id: \.self) { _ in skeleton }
          } else if buckets.isEmpty && vm.feedFailed {
            // C-10 · a failed read is never an empty one (L-32). Saying "no
            // rounds from your buddies" over a dead network is a claim about
            // the golfer's buddies made from a read that never answered.
            let e = EmptyRoot.failedRead()
            // SB-1 / OE-5 · the head and its door are ONE SENTENCE, so they lay
            // out as one wrapping paragraph and never as two views on a shared
            // baseline. In an `A11yStack` — an `HStack` at every reading size —
            // a head that wraps to two lines leaves the door pinned to the
            // FIRST baseline, and the golfer reads the sentence out of order.
            // Composed as a single `Text`, it wraps as prose, stays one tap
            // target, and VoiceOver speaks it as one element.
            Button { Task { await vm.load(me: store.me, key: loadKey) } } label: {
              (Text(e.head).foregroundStyle(cs.mut) + Text(" ") + Text("Try again.").foregroundStyle(cs.brand))
                .font(CSFont.footnote)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .a11yHitSlop()
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
          } else if buckets.isEmpty {
            // QB-05 · **NEVER "add some buddies" TO A GOLFER WITH A ROSTER.**
            //
            // This branch rendered unconditionally, so a golfer ninety seconds
            // past a covenant that named all six of his season's golfers was
            // told he had none: *"which is worse than silence, because it tells
            // me I have no buddies ninety seconds after showing me six of them
            // by name."* The wire is honestly empty — nobody has posted — but
            // the SECOND clause is a claim about his life, and it was false.
            //
            // With a season, the move is his season's own roster; the buddies
            // door stays for a golfer who genuinely has nobody.
            let roster = EmptyRoot.wireEmpty(me: me)
            // SB-1 / OE-5 · one sentence, one paragraph. The no-season branch
            // is a 44-character head and an 18-character door; they cannot
            // share one 350pt line at the DEFAULT type size, so the row form
            // printed `No rounds from your buddies yet. Post   add some
            // buddies. / one, or`. See the failed-read branch above.
            Button {
              if let id = roster.leagueId { openCompetition(id, .table) } else { openGolfers() }
            } label: {
              (Text(roster.head).foregroundStyle(cs.mut) + Text(" ") + Text(roster.door).foregroundStyle(cs.brand))
                .font(CSFont.footnote)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .a11yHitSlop()
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
          } else {
            ForEach(buckets) { b in
              FeedBucketView(bucket: b, presenter: presenter, vm: vm, taggedIds: upcoming.taggedIds, only: buckets.count == 1)
            }
          }

          if !CSDevHatch.fixtureHome { UpcomingRoundsSection(links: links, model: upcoming) }

          // 6 · THE FLOOR (L-32, D94 restored): four live doors on every Home,
          // in every state including brand-new, offline and failed.
          HomeFootDoors(push: push, leadRoute: ranked.lead?.route)
        }
        .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 32)
      }
    }
    .csLookGround()   // D103b: bg0 with the sky behind the page header
    .environment(\.csLook, looks.personalLook())
    .defaultScrollAnchor(CSDevHatch.bottom ? .bottom : .top)
    .refreshable {
        // The pull refreshes the SESSION's payload (every other tab reads it)
        // and then the dispatch, whose own answer supersedes it for this
        // screen. `HomeModel.load` joins a load already in flight for its key
        // rather than running a second one.
        await store.reload()
        await vm.load(me: store.me, key: loadKey)
      }
    .task(id: loadKey) { await vm.load(me: store.me, key: loadKey) }
    .navigationTitle("")
    .toolbar(.hidden, for: .navigationBar)
  }

  /// The look an item wears: its own season's, when it names one.
  private func league(_ item: HomeDispatch.Item) -> Me.Membership? {
    guard let id = item.leagueId else { return nil }
    return me?.memberships.first { $0.league_id == id }
  }

  /// Every card's one door. The ranker chose it; this only opens it.
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
    // D222 · `HomeRoute.league` / `.pot` are gone; a season is Compete's object
    // and the pane is the one the door was named for (D218).
    case .season(let id, let pane): openCompetition(id, SeasonPane.named(pane))
    case .pot(let id):         openCompetition(id, .pot)
    case .invite(let id, _):   openCompetition(id, .table)
    case .none:                break
    }
  }

  private var skeleton: some View {
    RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).fill(cs.bg1).frame(height: 76)
      .redacted(reason: .placeholder)
  }
}

/// A section head whose trailing slot is a view (a NavigationLink), not a closure —
/// the same eyebrow + hairline shape as `CSSectionHead`.
private struct HomeSectionHead<Trailing: View>: View {
  @Environment(\.csLookAccent) private var la
  let title: String
  @ViewBuilder let trailing: () -> Trailing
  init(_ title: String, @ViewBuilder trailing: @escaping () -> Trailing) { self.title = title; self.trailing = trailing }
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline) {
        Text(title).csEyebrow(la.eyebrow)   // D103b: the look's accent, mut on homebase
        Spacer()
        trailing()
      }
      CSHairline()
    }
    .padding(.top, 10)
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
    // The invitation and the buddy request are answered in place on the phone
    // (`InvitesBanner`, `BuddyRequests`), so their items stand down here
    // rather than saying the same thing twice on one screen (L-34). The web
    // has no such banners and renders them as items.
    let mine = dispatch.filter { item in
      if case .invite = item.route { return false }
      return !item.key.hasPrefix("friend:")
    }
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
    guard let m = p.me else { return }
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

// MARK: - occasion (occCard 10052–10060)

private struct OccasionCard: View {
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la
  let o: Occasion
  let onGo: () -> Void
  let onDismiss: () -> Void
  /// IOS-025: under a calendar look the eyebrow carries the look's motif ("🌬 The oldest one").
  private var eyebrow: String {
    if let l = la.look, l.window != nil { return "\(l.motif) \(o.k)" }
    return o.k
  }
  var body: some View {
    CSCard(spine: la.spine(earned: o.earned)) {
      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .top) {
          Text(eyebrow).csEyebrow(o.earned ? cs.gold : la.eyebrow)
          Spacer()
          if let m = o.marker { CSMarkerView(key: m, size: 22).foregroundStyle(o.earned ? cs.gold : cs.ink).accessibilityHidden(true) }
          Button(action: onDismiss) { Image(systemName: "xmark").font(.caption).foregroundStyle(cs.mut).a11yHitSlop(vertical: 14, horizontal: 14) }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        Text(o.h).font(CSFont.sentenceBold).foregroundStyle(cs.ink)
        Text(o.p).font(CSFont.subhead).foregroundStyle(cs.mut)
        Button(action: onGo) {
          HStack { Text(o.act); Text("→") }.font(CSFont.button).foregroundStyle(cs.brand).a11yHitSlop()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(o.act)
        .padding(.top, 4)
      }
    }
  }
}

// MARK: - digest

/// The digest as a row in the section (IOS-019 rule 2) — no card of its own.
private struct HomeDigestRow: View {
  @Environment(\.cs) private var cs
  let digest: HomeDigest
  let openReceipt: (UUID) -> Void
  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      if let u = digest.photoURL, let id = digest.roundId {
        Button { openReceipt(id) } label: {
          AsyncImage(url: u) { $0.resizable().scaledToFill() } placeholder: { cs.bg2 }
            .frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
      }
      VStack(alignment: .leading, spacing: 3) {
        Text(digest.label).font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.dimText)
        Text(attributed).font(CSFont.subhead).foregroundStyle(cs.ink)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  /// The web's `<b>` on the count and the name (10538–10600).
  private var attributed: AttributedString {
    var a = AttributedString(digest.body)
    for s in digest.strong {
      if let r = a.range(of: s) { a[r].font = CSFont.subhead.weight(.semibold) }
    }
    return a
  }
}

// MARK: - the feed (feedRow · postRow · feedBuckets)

private struct FeedBucketView: View {
  @Environment(\.cs) private var cs
  let bucket: HomeFeedBucket
  let presenter: Presenter
  let vm: HomeModel
  /// Bookings on the watch list that name you — a surviving booking line says "with you".
  var taggedIds: Set<UUID> = []
  /// Web 10479: when Today and This week are empty, Earlier opens on its own so the feed never looks empty.
  var only = false
  @State private var expanded = false

  var body: some View {
    let cap = HomeBuckets.cap
    let showAll = bucket.label == "Earlier" ? (expanded || only) : (expanded || bucket.items.count <= cap + 1)
    let shown = showAll ? bucket.items : Array(bucket.items.prefix(cap))
    VStack(alignment: .leading, spacing: 0) {
      if bucket.label == "Earlier" && !expanded && !only {
        Button { expanded = true } label: {
          Text("Show earlier · \(bucket.items.count)").font(CSFont.footnote).foregroundStyle(cs.ink).frame(minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      } else {
        CSSectionHead(bucket.label)
        ForEach(shown) { item in
          switch item {
          case .round(let r, let url):
            FeedRoundCard(r: r, photoURL: url, presenter: presenter, vm: vm).padding(.vertical, 6)
          case .moment(let p, let league):
            CSRow { FeedPostRow(p: p, leagueName: league, withYou: withYou(p), presenter: presenter) }
          case .notes(let n):
            CSRow { FeedNotesRow(notes: n, bucket: bucket.label, taggedIds: taggedIds, presenter: presenter) }
          }
        }
        if !showAll {
          Button { expanded = true } label: {
            Text("Show \(bucket.items.count - cap) more · \(bucket.label.lowercased())")
              .font(CSFont.footnote).foregroundStyle(cs.ink).frame(minHeight: 44).contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  private func withYou(_ p: HomePost) -> Bool { p.scheduled_round_id.map { taggedIds.contains($0) } ?? false }
}

private struct FeedRoundCard: View {
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la
  @Environment(SessionStore.self) private var store
  @Environment(\.toast) private var toast
  let r: HomeFeedRow
  let photoURL: URL?
  let presenter: Presenter
  let vm: HomeModel

  private var reactions: [String: ReactionState]? { r.round_id.flatMap { vm.social.state(for: $0) } }
  private var canReact: Bool { reactions != nil }

  /// The chips present plus the bare 🔥 — F11 3.1: the heater is the one-thumb
  /// chip, always on the card face (rxChipsHtml 4708). Never a lone "+".
  @ViewBuilder private var strip: some View {
    if let state = reactions {
      HomeReactionStrip(state: state, onToggle: toggle)
    }
  }

  private func toggle(_ emoji: String) {
    Task {
      guard let me = store.me else { return }
      if let e = await vm.toggle(round: r, emoji: emoji, me: me, name: me.profile?.display_name ?? "You") { toast.show(e) }
    }
  }

  private var who: String { HomeCopy.who(r) }
  private var milestone: String? { HomeCopy.milestone(r) }
  /// The gloss as its producer writes it — "beat their playing HCP by 2.4".
  ///
  /// R-M · the two forms are SEPARATE rather than one lower-cased on the way
  /// out. The noun is now an acronym, and `phrase.lowercased()` shipped
  /// "playing hcp" onto the feed card and into its VoiceOver label.
  private var phraseRaw: String? {
    guard let p = r.pvi else { return nil }
    let s = CSBands.vsPhrase(p)
    return r.is_me == true ? s : CSBands.theirs(s)
  }
  /// The same gloss opening a sentence.
  private var phrase: String? {
    guard let out = phraseRaw else { return nil }
    return out.prefix(1).uppercased() + out.dropFirst()
  }
  private var meta: String { "\(r.course ?? "a round") · \(CSDate.short(r.played_on ?? ""))" }

  var body: some View {
    Button { if let id = r.round_id { presenter.receipt = id } } label: {
      if let photoURL {
        // the photo is the GROUND: the text decides the height (220 at least), so nothing overflows at the accessibility sizes
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
              faceButton(size: 36)
              VStack(alignment: .leading, spacing: 1) {
                // F-15 · the name TRUNCATES and the capsule keeps its size.
                // Both were unconstrained, so the row overflowed its column and
                // the name rendered as orphaned glyph fragments behind the ✦
                // FOUNDER chip. The chip takes the priority because it is
                // fixed-width; the name is the half that can give.
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                  Text(who).font(CSFont.button).foregroundStyle(CSTokens.dark.ink)
                    .lineLimit(1).truncationMode(.tail)
                  FoundingTag(badge: store.founding.badge(for: r.profile_id)).environment(\.cs, CSTokens.dark)
                    .layoutPriority(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(meta + (milestone.map { " · \($0)" } ?? "")).font(CSFont.footnote).foregroundStyle(CSTokens.dark.mut)
              }
            }
            HStack(alignment: .lastTextBaseline, spacing: 8) {
              Text(r.gross.map(String.init) ?? "").font(CSFont.hero).foregroundStyle(CSTokens.dark.ink)
              if let phraseRaw { Text(phraseRaw).font(CSFont.footnote).foregroundStyle(CSTokens.dark.mut) }
              Spacer()
              CSMarkerView(key: r.marker, size: 22).foregroundStyle(CSTokens.dark.ink).accessibilityHidden(true)
            }
            strip
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .bottomLeading)
        .background {
          ZStack {
            AsyncImage(url: photoURL) { $0.resizable().scaledToFill() } placeholder: { CSDusk.surface }
            LinearGradient(colors: [.clear, CSDusk.ground.opacity(0.85)], startPoint: .top, endPoint: .bottom)
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
      } else {
        // a milestone is gold; under a look every live card wears the accent's spine (D103b); no spine on homebase
        CSCard(spine: milestone != nil ? cs.gold : (la.active ? la.accent : nil)) {
          VStack(alignment: .leading, spacing: 6) {
            // face + name across; the gross drops under them at the accessibility sizes
            A11yStack(spacing: 10) {
              HStack(spacing: 10) {
                faceButton(size: 44)
                VStack(alignment: .leading, spacing: 2) {
                  HStack(alignment: .firstTextBaseline, spacing: 6) {   // F-15
                    Text(who).font(CSFont.button).foregroundStyle(cs.ink)
                      .lineLimit(1).truncationMode(.tail)
                    FoundingTag(badge: store.founding.badge(for: r.profile_id)).layoutPriority(1)
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                  if let line = milestone ?? phrase { Text(line).font(CSFont.footnote).foregroundStyle(milestone != nil ? cs.gold : cs.mut) }
                }
              }
              Spacer(minLength: 0)
              if let g = r.gross {
                VStack(alignment: .trailing, spacing: 0) {
                  Text(String(g)).font(CSFont.heroSmall).foregroundStyle(cs.ink).csTabular()
                  Text("gross").font(CSFont.label).foregroundStyle(cs.dimText)
                }
              }
            }
            Text(meta).font(CSFont.monoSmall).foregroundStyle(cs.mut)
            strip
          }
        }
      }
    }
    .buttonStyle(.plain)
    .contextMenu {
      // "add a reaction" — the six named emoji, on a long press (rxPaletteHtml); same write path
      if let state = reactions {
        ForEach(CSReactions.all) { rx in
          Button { toggle(rx.emoji) } label: {
            Label { Text(rx.label) } icon: { Text(rx.emoji) }
          }
          .disabled(state[rx.emoji]?.me == true)
        }
      }
    }
    .accessibilityLabel("\(who) — \(r.gross.map(String.init) ?? "") at \(r.course ?? "a round")" + (phraseRaw.map { ", \($0)" } ?? ""))
    .accessibilityHint("Opens the round")
    // VoiceOver reaches the nested doors through the rotor: the card and the six reactions
    .accessibilityAction(named: GolfersRoot.CardName.title(who)) { if let p = r.profile_id { presenter.tourCard = p } }
    .modifier(A11yReactionActions(enabled: canReact, toggle: toggle))
  }

  private func faceButton(size: CGFloat) -> some View {
    Button { if let p = r.profile_id { presenter.tourCard = p } } label: {
      CSFace(marker: r.marker, size: size)
    }
    .buttonStyle(.plain)
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

/// A league post as a row in the section (IOS-019 rule 2). D219: the row is a
/// door iff it knows its round — live → the scorecard, posted → the receipt,
/// booked → the scheduled-round sheet. A line that knows nothing is a NOTE:
/// plain text, no glyph disc, no chevron, never a dimmed button.
private struct FeedPostRow: View {
  @Environment(\.cs) private var cs
  let p: HomePost
  let leagueName: String?
  /// The booking names you (the watch list's `tagged_me`) — "with you" on the league line.
  var withYou = false
  let presenter: Presenter
  private var fresh: Bool { (p.created_at.map { Date().timeIntervalSince($0) } ?? .infinity) < 48 * 3600 }
  private var closed: Bool { (p.body ?? "").range(of: "\\bclosed\\b", options: [.regularExpression, .caseInsensitive]) != nil }
  private var door: HomeFeedDoor? { HomeFeedFold.door(for: p) }

  var body: some View {
    if let door {
      Button { FeedDoors.open(door, presenter: presenter) } label: { row(door: door) }
        .buttonStyle(.plain)
        // body, then league/date — the "· THE ROUND ›" tag is decoration; the hint says where it goes
        .accessibilityLabel(HomeCopy.easeCaps(p.body ?? "") + ", " + meta)
        .accessibilityHint(FeedDoors.hint(door))
    } else {
      note.accessibilityElement(children: .combine)
    }
  }

  private var meta: String {
    [leagueName, p.created_at.map { CSDate.short(CSDate.iso($0)) }, withYou ? "with you" : nil].compactMap { $0 }.joined(separator: " · ")
  }

  private func row(door: HomeFeedDoor) -> some View {
      HStack(alignment: .top, spacing: 12) {
        Text(p.kind == "announce" ? "📣" : "🏁").font(.system(size: 18))
          .frame(width: 40, height: 40).background(cs.bg2, in: Circle())
          .overlay(Circle().stroke(fresh ? cs.rule : .clear, lineWidth: 1))
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 3) {
          Text(HomeCopy.easeCaps(p.body ?? "")).font(CSFont.subhead).foregroundStyle(cs.ink)
          HStack(spacing: 4) {
            Text(meta).font(CSFont.footnote).foregroundStyle(cs.mut)
            Text("· \(FeedDoors.tag(door)) ›").font(CSFont.label).foregroundStyle(cs.gold)
          }
        }
        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .rotationEffect(.degrees(closed ? 1.4 : 0))   // the month seal keeps its cant — a hand set it
  }

  private var note: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(HomeCopy.easeCaps(p.body ?? "")).font(CSFont.subhead).foregroundStyle(cs.ink)
      Text(meta).font(CSFont.footnote).foregroundStyle(cs.mut)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .rotationEffect(.degrees(closed ? 1.4 : 0))
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

/// D217 · a league's notes, folded to one line — "Fellas · 2 league notes this
/// week" — with a disclosure that opens the notes in place. The group's notes
/// are the league's Notices, and under them sits ONE door per league to its
/// board (D217: "in place, then one door to the board"). Disclosure state lives
/// here, per item; only the board door navigates. A group of exactly ONE note
/// that knows its round is that note's door (the Kit's `door`), so the line is
/// the row.
private struct FeedNotesRow: View {
  @Environment(\.cs) private var cs
  @Environment(\.openCompetition) private var openCompetition
  let notes: HomeFeedNotes
  let bucket: String
  var taggedIds: Set<UUID> = []
  let presenter: Presenter
  @State private var open = false

  var body: some View {
    if notes.count == 1, let p = notes.rows.first, HomeFeedFold.door(for: p) != nil {
      FeedPostRow(p: p, leagueName: notes.leagueNames.joined(separator: " & "),
                  withYou: p.scheduled_round_id.map { taggedIds.contains($0) } ?? false, presenter: presenter)
    } else {
      VStack(alignment: .leading, spacing: 0) {
        Button { CSMotion.run { open.toggle() } } label: {
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(notes.line(bucket: bucket)).font(CSFont.subhead).foregroundStyle(cs.ink)
            Spacer(minLength: 0)
            Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold)).foregroundStyle(cs.mut)
              .rotationEffect(.degrees(open ? 180 : 0))
          }
          .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(notes.line(bucket: bucket))
        .accessibilityValue(open ? "expanded" : "collapsed")
        .accessibilityHint("Shows the notes")
        if open {
          VStack(alignment: .leading, spacing: 0) {
            ForEach(notes.rows) { p in
              // the line above already names the league; the note carries its date
              FeedPostRow(p: p, leagueName: nil,
                          withYou: p.scheduled_round_id.map { taggedIds.contains($0) } ?? false, presenter: presenter)
                .padding(.vertical, 8)
            }
            // D217 · the one door: the notes are the league's Notices, the board
            // is where they live. A merged group (two leagues' notes in one
            // fold) gets one door per league, each named, so nobody guesses.
            // D222 · a board is a SEASON's board and a season is Compete's, so
            // the door crosses tabs through the one environment action rather
            // than a link declared in a stack that no longer resolves it.
            ForEach(Array(zip(notes.leagueIds, notes.leagueNames)), id: \.0) { pair in
              let (id, name) = pair
              let label = notes.leagueIds.count == 1 ? "THE BOARD ↗" : "\(name.uppercased()) · THE BOARD ↗"
              Button { openCompetition(id, .board) } label: {
                HStack(spacing: 0) {
                  Text(label).font(CSFont.label).foregroundStyle(cs.gold)
                  Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
              }
              .buttonStyle(.plain)
              .accessibilityLabel("\(name) board")
              .accessibilityHint("Opens the league's board")
            }
          }
          .padding(.leading, 12)
          .overlay(alignment: .leading) { Rectangle().fill(cs.rule).frame(width: 1) }
        }
      }
    }
  }
}

/// The reaction strip on a Home round (rxChipsHtml 4695–4740): chips for the
/// reactions present, mine highlighted. Rendered only when one exists — the
/// tray of six lives on the card's long press (IOS-019).
private struct HomeReactionStrip: View {
  @Environment(\.cs) private var cs
  let state: [String: ReactionState]
  let onToggle: (String) -> Void
  var body: some View {
    HStack(spacing: 6) {
      ForEach(CSReactions.all.filter { (state[$0.emoji]?.n ?? 0) > 0 }) { rx in
        let st = state[rx.emoji] ?? ReactionState()
        Button { CSHaptic.selection(); onToggle(rx.emoji) } label: {
          HStack(spacing: 4) {
            Text(rx.emoji)
            Text("\(st.n)").font(CSFont.label).csTabular()
          }
          .padding(.horizontal, 8).padding(.vertical, 5)
          .frame(minHeight: 30)
          .background(cs.bg2, in: Capsule())
          .overlay(Capsule().stroke(st.me ? cs.brand : cs.rule, lineWidth: 1))
          .foregroundStyle(st.me ? cs.brand : cs.ink)
          .a11yHitSlop(vertical: 7, horizontal: 0)   // a 30pt chip, a 44pt target
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(rx.label), \(st.n)\(st.me ? ", yours" : "")")
        .accessibilityValue(st.me ? "on" : "off")
      }
      // the bare heater: nobody has fired yet, the chip is still there to fire (web 4708–4710)
      if (state[CSReactions.quick]?.n ?? 0) == 0 {
        Button { CSHaptic.selection(); onToggle(CSReactions.quick) } label: {
          Text(CSReactions.quick)
            .padding(.horizontal, 8).padding(.vertical, 5)
            .frame(minHeight: 30)
            .background(cs.bg2, in: Capsule())
            .overlay(Capsule().stroke(cs.rule, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(CSReactions.all.first { $0.emoji == CSReactions.quick }?.label ?? "heater")
      }
    }
    .padding(.top, 6)
  }
}
