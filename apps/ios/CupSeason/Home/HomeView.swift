// Cup Season — Home (index.html 2792–2822 slot order; D81 one lane; D94
// doors; D27 the digest; IOS-012 hero first on the phone).
//
// Slots, top to bottom: invites banner → buddy requests (D177 — their OWN
// row; the banner above carries league and Ryder invites only, whatever this
// comment used to claim) → live-round banner → lead card (D176) → hero →
// the D121 rows (one per OTHER league) → occasion → Up Next → digest → the
// one feed (folded, D217) → coming up.
//
// The Home hard-look (2026-09-02, "build to your recommendations"): the hero
// speaks `HomeHeroCopy` and is one door to the table; a D121 row re-renders
// Home around its league; the buddies head opens the buddies (D218); a feed
// line is a door iff it knows its round (D219); league notes fold to one line
// per league (D217). The doors (start a league · start an event · join with a code)
// live in the header's `+` (IOS-022 item 1: the navigation bar is hidden on
// Home, so the wordmark sits at the top of the safe area; pushed screens
// keep their back bar — visibility is per destination).

import SwiftUI
import CSDesign
import CupSeasonKit

struct HomeView: View {
  @Environment(SessionStore.self) private var store
  @Environment(LookStore.self) private var looks
  @Environment(\.presenter) private var presenter
  @Environment(\.cs) private var cs
  let links: CSLinks
  /// D176 · a chip is a door. The tap pushes onto the tab's own path — the same
  /// pattern the Clubhouse destinations already use, rather than a second
  /// `navigationDestination` restating routes MainTabView already owns.
  var push: (HomeRoute) -> Void = { _ in }
  @State private var vm = HomeModel()
  /// The Coming-up card's model, owned here so the feed's fold can hide a
  /// booking line whose round is already a card (D217 rule 1).
  @State private var upcoming = UpcomingModel()
  /// What a stream load is FOR: this payload, rendered around this league.
  /// The pull and `.task(id:)` both load by it — see `HomeModel.load`.
  private var loadKey: HomeModel.LoadKey { .init(generated: store.me?.generated_at, league: store.preferredLeague) }

  var body: some View {
    // IOS-025: Home wears the PERSONAL dial; the hero alone follows its league (phase ≻ the Pro's look ≻ personal)
    ScrollView {
      if let me = store.me {
        let mode = HomeMode.of(me, preferredLeague: store.preferredLeague)
        VStack(alignment: .leading, spacing: 14) {
          // IOS-019 rule 3: the wordmark lives in the scroll, where the glass toolbar cannot clip it
          CSPageHeader("Cup Season", eyebrow: CSHeaderDate.today()) { plusMenu }.padding(.bottom, 2)

          InvitesBanner { id in store.preferredLeague = id; Task { await store.reload() } }

          // D177 · buddy requests reach you HERE. This file's header has
          // claimed since the port that InvitesBanner carried them "inside the
          // banner"; it never did — that banner is league and Ryder invites
          // only. Costs zero pixels on the days nobody has asked.
          BuddyRequests(links: links, head: true, onAnswered: { Task { await store.reload() } })

          LiveResumeBanner(links: LiveLinks(openReceipt: { presenter.receipt = $0 }, openTourCard: { presenter.tourCard = $0 },
                                            done: { presenter.showLive = false }),
                           open: { presenter.showLive = true })

          // D176 · the lead card. One slot, a fixed ladder, one card at a time —
          // and NO card is the resting state, because the hero below is already
          // a good one. It sits above the hero on purpose: the hero says where
          // you stand, the lead card says what today is asking of you.
          // The card is pinned to the league it was chosen for: a row tap flips
          // the hero at once, the card waits for its own league's read rather
          // than sit under the wrong hero (D218), and its door goes where the
          // card was built, never where the hero has since moved.
          if let lead = vm.lead, vm.leadLeague == mode.membership?.league_id {
            HomeLeadCard(lead: lead) { take(lead, league: vm.leadLeague) }
          }

          HomeHero(mode: mode, me: me, push: push)
            .environment(\.csLook, looks.look(for: mode.membership))

          // D121 · one quiet row per OTHER league. A tap re-renders Home —
          // hero AND lead card — around that league; it never leaves the screen.
          HomeLeagueRows(memberships: me.memberships, current: mode.membership?.league_id) { id in
            store.preferredLeague = id   // `.task(id:)` reloads around it
            CSHaptic.selection()
          }

          if let o = vm.occasion {
            // web 10082/10093: the wink's tap is an event, either way it goes
            OccasionCard(o: o, onGo: {
                           CSTelemetry.event("home_occasion_tap", ["win": .string(o.key), "act": .string("go"), "platform": .string("ios")])
                           if o.go == .league { presenter.wizard = .init(existingLeagueId: nil) } else { presenter.showEventPicker = true }
                         },
                         onDismiss: {
                           CSTelemetry.event("home_occasion_tap", ["win": .string(o.key), "act": .string("dismiss"), "platform": .string("ios")])
                           Occasion.dismiss(o); vm.occasion = nil
                         })
          }

          UpNextChips(leagueId: mode.membership?.league_id, links: links, go: { go in
            switch go {
            case .round(let id):  presenter.scheduledRound = id
            case .calendar:       push(.schedule)
            case .people:         push(.people)
            case .standings:      if let l = mode.membership?.league_id { push(.league(l)) }
            }
          })

          // the section head: eyebrow + hairline (IOS-019 rule 2). D218: the lane
          // is cross-league, so its door is the buddies, not one league's table
          // — the table is reached from the hero, the D121 row and the move card.
          HomeSectionHead("Around your buddies") {
            NavigationLink(value: HomeRoute.people) { Text("YOUR BUDDIES ↗").csEyebrow(cs.dawn).a11yHitSlop() }
              // VoiceOver reads the glyph as "north east arrow" — name the door instead
              .accessibilityLabel("Your buddies")
              .accessibilityHint("Opens your buddies")
          }

          let buckets = vm.feed(upcoming: upcoming.ids)
          if let d = vm.digest { CSRow(last: !buckets.isEmpty) { HomeDigestRow(digest: d, openReceipt: { presenter.receipt = $0 }) } }

          if vm.loading && buckets.isEmpty {
            ForEach(0..<3, id: \.self) { _ in skeleton }
          } else if buckets.isEmpty {
            // the sentence and its link share a line where they fit; the link is a 44pt target either way
            A11yStack(alignment: .leading, rowAlignment: .firstTextBaseline, spacing: 4) {
              Text("No rounds from your buddies yet. Post one, or").font(CSFont.footnote).foregroundStyle(cs.mut)
              NavigationLink(value: HomeRoute.people) { Text("add some buddies.").font(CSFont.footnote).foregroundStyle(cs.brand).a11yHitSlop() }
            }
            .padding(.top, 4)
          } else {
            ForEach(buckets) { b in
              FeedBucketView(bucket: b, presenter: presenter, vm: vm, taggedIds: upcoming.taggedIds, only: buckets.count == 1)
            }
          }

          UpcomingRoundsSection(links: links, model: upcoming)
        }
        .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 32)
      }
    }
    .csLookGround()   // D103b: bg0 with the sky behind the page header
    .environment(\.csLook, looks.personalLook())
    .defaultScrollAnchor(CSDevHatch.bottom ? .bottom : .top)
    .refreshable {
        // The pull's own load holds the spinner through the stream. A fresh
        // payload also changes `generated_at`, which fires `.task(id:)` below
        // with the SAME key — and `HomeModel.load` joins a load already in
        // flight for its key instead of running a second one (one load per
        // pull). A pull that gets no new payload (offline; a reload already
        // in flight elsewhere) still refreshes the stream from what it has.
        await store.reload()
        await vm.load(me: store.me, key: loadKey)
      }
    // Reload on a fresh payload OR a league flip — the Clubhouse pager sets
    // the preference too, with no payload change, and the lead card must
    // follow the hero to the new league.
    .task(id: loadKey) { await vm.load(me: store.me, key: loadKey) }
    .navigationTitle("")
    .toolbar(.hidden, for: .navigationBar)
  }

  /// D176 · the lead card's one action. Each face leads exactly one place, and
  /// never to a dead end: the clash sends you to the composer unless the round
  /// that would answer it already exists, in which case it opens that receipt.
  private func take(_ lead: HomeLead, league: UUID?) {
    switch lead {
    case .clash(let c):
      if c.mine == nil || c.edge != .me { presenter.postOnComposer = true; presenter.showPost = true }
      else if let r = c.mine?.roundId { presenter.receipt = r }
      else { presenter.postOnComposer = true; presenter.showPost = true }
    case .floor:
      presenter.postOnComposer = true; presenter.showPost = true
    case .move:
      if let l = league { push(.league(l)) }
    case .milestone(_, _, let rid, _):
      if let rid { presenter.receipt = rid }
    }
  }

  /// The doors, as the header row's trailing control (IOS-022 item 1).
  private var plusMenu: some View {
    Menu {
      Button { presenter.wizard = .init(existingLeagueId: nil) } label: { Label("Start a league", systemImage: "flag") }
      Button { presenter.showEventPicker = true } label: { Label("Start an event", systemImage: "trophy") }
      Button { presenter.join(code: nil) } label: { Label("Join with a code", systemImage: "key") }
      NavigationLink(value: HomeRoute.schedule) { Label("Your golf calendar", systemImage: "calendar") }
      NavigationLink(value: HomeRoute.people) { Label("Find golfers", systemImage: "magnifyingglass") }
    } label: {
      Image(systemName: "plus").font(.system(size: 20, weight: .semibold)).foregroundStyle(cs.brand)
        .frame(width: 44, height: 44).contentShape(Rectangle())
    }
    .accessibilityLabel("Start or join")
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

@MainActor
@Observable
final class HomeModel {
  /// The stream as loaded, newest first. The view folds it (`feed(upcoming:)`)
  /// against the Coming-up card, which loads on its own clock.
  var items: [HomeItem] = []
  var digest: HomeDigest?
  var occasion: Occasion?
  /// D176 · the one card above the hero, or none. `HomeLead.choose` decides.
  var lead: HomeLead?
  /// The league `lead` was chosen for — the view shows the card only while
  /// the hero is rendering that league.
  var leadLeague: UUID?
  var loading = false
  var social = HomeSocial.Snapshot()
  private var markRead = false
  private var mark: Date?
  private var rounds: [HomeFeedRow] = []
  private var posts: [HomePost] = []
  private var urls: [UUID: URL] = [:]
  private let repo = HomeStreamRepository()
  private let socialRepo = HomeSocial()
  /// Which load is current. A superseded run still comes back from its
  /// awaits, and without this it would write the OLD league's stream over
  /// the new one and clear `loading` under the run still in flight (a pull
  /// over a league flip does exactly that).
  private var generation = 0
  /// The load in flight, by the key it was started for — see `load(me:key:)`.
  private var inflight: (key: LoadKey, task: Task<Void, Never>)?

  /// One load per payload. A pull to refresh loads the stream itself (so its
  /// spinner lasts through it) and the fresh payload ALSO fires `.task(id:)`
  /// with the same key; the second caller joins the run in flight instead of
  /// racing it. A different key (a newer payload, a league flip) starts a new
  /// run, and the generation guard retires the old one. The run is its own
  /// task so a joiner's cancellation (`.task(id:)` moving on) cannot cut it
  /// short under the caller still waiting on it.
  func load(me: Me?, key: LoadKey) async {
    if let cur = inflight, cur.key == key { await cur.task.value; return }
    generation += 1
    let gen = generation
    let task = Task { [self] in
      await run(me: me, gen: gen)
      // MY entry, not "an entry with my key". A superseded run of the same
      // key (league A → B → A while the first A was still reading) would
      // otherwise clear the LIVE run's entry, and the next caller — a pull,
      // a tab return — could no longer join it. `inflight` always holds the
      // newest run, so "I am the current generation" is "the entry is mine".
      if gen == generation { inflight = nil }
    }
    inflight = (key, task)
    await task.value
  }

  private func run(me: Me?, gen: Int) async {
    guard let me else { return }
    // A run can be retired before its body is ever dequeued (two key changes
    // in a row). Nothing it writes — not even `loading` — is the screen's.
    guard live(gen) else { return }
    loading = true
    defer { if gen == generation { loading = false } }
    occasion = Occasion.current(leagueless: me.memberships.isEmpty)
    let r = await repo.load(memberships: me.memberships)
    guard live(gen) else { return }
    // A failed read is not an empty feed. With rounds already on screen, a
    // pull on a bad signal keeps them — writing `r.items` here would paint
    // "No rounds from your buddies yet." over the circle's week and call a
    // network error a quiet one. With nothing in hand the empty state is the
    // honest answer, and the next load fills it.
    if r.failed && !items.isEmpty { return }
    items = r.items
    rounds = r.rounds; posts = r.posts
    if !markRead { mark = HomeDigest.readAndMark(profile: me.profile?.id); markRead = true }
    urls = [:]
    for case .round(let row, let u) in r.items { if let id = row.round_id, let u { urls[id] = u } }
    digest = HomeDigest.make(rounds: rounds, posts: posts, photoURLs: urls, mark: mark)
    // circle reactions ride the rounds just loaded (round → shared-league post)
    let snap = await socialRepo.load(rounds: rounds, memberships: me.memberships, currentLeague: hero(me)?.league_id)
    guard live(gen) else { return }
    social = snap
    if let mark { digest = HomeDigest.make(rounds: rounds, posts: posts, photoURLs: urls, mark: mark, mentions: social.mentions(rounds: rounds, since: mark)) }
    await loadLead(me: me, gen: gen)
  }

  /// Still the current load — the only state a load may write from.
  private func live(_ gen: Int) -> Bool { gen == generation }

  /// D217 · the feed, folded: booking lines already on the Coming-up card are
  /// hidden, the same note across leagues is one line, and what is left is
  /// one line per league per bucket. Pure over what is already in hand.
  func feed(upcoming: Set<UUID>) -> [HomeFeedBucket] { HomeFeedFold.fold(items, upcoming: upcoming) }

  /// D176 · everything the ladder reads is already in hand but the clash, which
  /// is one RPC. It runs LAST so a slow or skewed clash read never delays the
  /// feed — the card simply appears a moment after the rest of Home.
  private func loadLead(me: Me, gen: Int) async {
    let m = hero(me)
    let today = CSDate.today()
    let days = CSDate.days(from: today, to: ScheduleDates.endOfMonth(today)).map { max(0, $0) }
    // someone else's news, today, worth lifting out of the river
    let mile = rounds.first { $0.is_me != true && $0.played_on == today && HomeCopy.milestone($0) != nil }
    // `phase` gates the move rung to a live season (the Kit's rule): a
    // prev_rank the server keeps carrying before first tee is not a move.
    // `solo` gates the floor rung off entirely (D140): a solo league has no
    // squads, so the floor its pulse still carries can never be owed.
    let chosen = HomeLead.choose(clash: await repo.clash(league: m?.league_id, roster: m?.headcount),
                           pulse: m?.pulse,
                           monthDaysLeft: days,
                           standing: m?.standing,
                           milestone: mile.map { (who: HomeCopy.who($0),
                                                  line: HomeCopy.milestone($0) ?? "",
                                                  roundId: $0.round_id,
                                                  marker: $0.marker) },
                           phase: m.map { SeasonPhase.of($0) },
                           solo: m?.isSolo ?? false)
    // one assignment, after the await, and only from the current load: a
    // flip mid-read cannot leave the old league's card pinned to the new league
    guard live(gen) else { return }
    lead = chosen; leadLeague = m?.league_id
  }

  /// What `.task(id:)` watches: the payload's stamp and the league in front.
  /// The stamp is `native_home`'s `now()`, so two payloads never share a key;
  /// a server that stopped sending it would collapse every payload to one key
  /// and only a league flip would reload. A league write followed by a reload
  /// (the invite banner's door) is deliberately TWO keys — the row's league
  /// re-renders Home at once and the fresh payload supersedes it a moment
  /// later, at the cost of one stream read whose result is dropped.
  struct LoadKey: Equatable { let generated: Date?; let league: UUID? }

  /// The membership the hero renders — `HomeMode.of` over the same stored
  /// preference the view reads, so the lead card, the circle and the hero can
  /// never speak for different leagues (a stored league that has WRAPPED
  /// falls to the live one in both places).
  private func hero(_ me: Me) -> Me.Membership? {
    HomeMode.of(me, preferredLeague: UserDefaults.standard.string(forKey: CSConfig.lastLeagueKey).flatMap(UUID.init)).membership
  }

  /// `toggleHomeRx` — optimistic flip, one write path, revert + toast on failure.
  func toggle(round: HomeFeedRow, emoji: String, me: Me, name: String) async -> String? {
    guard let rid = round.round_id, let t = social.targets[rid] else { return nil }
    var st = social.rx[t.postId, default: [:]][emoji, default: ReactionState()]
    let had = st.me
    st.flip(me: name, on: !had)
    social.rx[t.postId, default: [:]][emoji] = st
    do { try await socialRepo.write(target: t, memberships: me.memberships, emoji: emoji, had: had); return nil }
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
          Text("Show earlier · \(bucket.items.count)").font(CSFont.footnote).foregroundStyle(cs.dawn).frame(minHeight: 44).contentShape(Rectangle())
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
              .font(CSFont.footnote).foregroundStyle(cs.dawn).frame(minHeight: 44).contentShape(Rectangle())
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
  private var phrase: String? {
    guard let p = r.pvi else { return nil }
    let s = CSBands.vsPhrase(p)
    let out = r.is_me == true ? s : CSBands.theirs(s)
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
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                  Text(who).font(CSFont.button).foregroundStyle(CSTokens.dark.ink)
                  FoundingTag(badge: store.founding.badge(for: r.profile_id)).environment(\.cs, CSTokens.dark)
                }
                Text(meta + (milestone.map { " · \($0)" } ?? "")).font(CSFont.footnote).foregroundStyle(CSTokens.dark.mut)
              }
            }
            HStack(alignment: .lastTextBaseline, spacing: 8) {
              Text(r.gross.map(String.init) ?? "").font(CSFont.hero).foregroundStyle(CSTokens.dark.ink)
              if let phrase { Text(phrase.lowercased()).font(CSFont.footnote).foregroundStyle(CSTokens.dark.mut) }
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
                  HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(who).font(CSFont.button).foregroundStyle(cs.ink)
                    FoundingTag(badge: store.founding.badge(for: r.profile_id))
                  }
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
    .accessibilityLabel("\(who) — \(r.gross.map(String.init) ?? "") at \(r.course ?? "a round")" + (phrase.map { ", \($0.lowercased())" } ?? ""))
    .accessibilityHint("Opens the round")
    // VoiceOver reaches the nested doors through the rotor: the Tour Card and the six reactions
    .accessibilityAction(named: "\(who)'s Tour Card") { if let p = r.profile_id { presenter.tourCard = p } }
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
          .overlay(Circle().stroke(fresh ? cs.line2 : .clear, lineWidth: 1))
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
    switch d { case .live: "SCORECARD"; case .round: "THE ROUND"; case .scheduled: "THE TEE SHEET" }
  }
  static func hint(_ d: HomeFeedDoor) -> String {
    switch d { case .live: "Opens the scorecard"; case .round: "Opens the round"; case .scheduled: "Opens the round on the tee sheet" }
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
        Button { withAnimation(CSMotion.roll) { open.toggle() } } label: {
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
            // `ClubRoute.board` is the route Home already takes to a board
            // (`onOpenBoard`); both stacks resolve it.
            ForEach(Array(zip(notes.leagueIds, notes.leagueNames)), id: \.0) { pair in
              let (id, name) = pair
              let label = notes.leagueIds.count == 1 ? "THE BOARD ↗" : "\(name.uppercased()) · THE BOARD ↗"
              NavigationLink(value: ClubRoute.board(id)) {
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
          .overlay(alignment: .leading) { Rectangle().fill(cs.line).frame(width: 1) }
        }
      }
    }
  }
}

/// The hero: the standing MOVE (D81 "the standing is a verb"). The whole card
/// is ONE door to the league's table (D218; `HomeRoute.league` lands on
/// STANDINGS). Its words come from `HomeHeroCopy`, in season; the stages
/// before and after keep the sentences D119/D122 set.
struct HomeHero: View {
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la
  let mode: HomeMode
  let me: Me
  /// Home's push. The hero and its owe line are the only two doors in it.
  var push: (HomeRoute) -> Void = { _ in }

  var body: some View {
    if let lid = mode.membership?.league_id {
      Button { push(.league(lid)) } label: { card }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(a11y)
        .accessibilityHint("Opens the table")
        .accessibilityAction(named: "See the table") { push(.league(lid)) }
        .modifier(OweAction(owe: owe, act: { push(.pot(lid)) }))
    } else {
      card.accessibilityElement(children: .combine)
    }
  }

  private var card: some View {
    // IOS-019 rule 1: the one hero on the screen wears the wash — gold when earned; otherwise the
    // look's accent from the environment, ember when none (IOS-025: a look never overrides gold)
    CSHero(spine: earned ? cs.gold : nil, padding: 20) {
      VStack(alignment: .leading, spacing: 10) {
        Text(eyebrow).csEyebrow(earned ? cs.gold : la.eyebrow)   // D103b: the eyebrow wears the look
        HStack(alignment: .firstTextBaseline, spacing: 12) {
          Text(figure).font(CSFont.hero).foregroundStyle(earned ? cs.gold : cs.ink).csTabular()
          if let of = captionTail { Text(of).font(CSFont.sentence).foregroundStyle(cs.mut) }
          if let move { moveChip(move) }
        }
        Text(line).font(CSFont.sentence).foregroundStyle(cs.ink)
        // the foot, rung by rung: rule · endgame · money · owe — then the door's word
        if !foots.isEmpty || owe != nil || mode.membership != nil {
          VStack(alignment: .leading, spacing: 4) {
            ForEach(foots, id: \.self) { Text($0).font(CSFont.monoSmall).foregroundStyle(cs.mut) }
            if let owe, let lid = mode.membership?.league_id {
              // D129 / D23 · self-only, and a door of its own: the books
              Button { push(.pot(lid)) } label: {
                Text(owe).font(CSFont.monoSmall).foregroundStyle(cs.warm).frame(minHeight: 28, alignment: .leading).contentShape(Rectangle())
              }
              .buttonStyle(.plain)
              .accessibilityHidden(true)   // reached through the hero's action instead
            }
            if mode.membership != nil {
              HStack { Spacer(); Text("See the table →").font(CSFont.monoSmall).foregroundStyle(cs.brand) }
                .padding(.top, 2)
            }
          }
          .padding(.top, 2)
        }
      }
      .padding(.leading, 6)
    }
  }

  /// One label for the one button: the league, the line and the caption.
  private var a11y: String {
    var parts = [eyebrow]
    if let c = caption { parts.append(c) } else { parts.append(figure) }
    if let m = move { parts.append(m.0) }
    parts.append(line)
    parts += foots
    if let owe { parts.append(owe) }
    return parts.joined(separator: ". ")
  }

  /// Gold is EARNED only: the lead this season, the top seed into the Final
  /// (the LOCKED seed — `cup_finalists`, never the table, which keeps moving
  /// through the Final), or your name on the cup.
  private var earned: Bool {
    switch mode {
    case .season(let m): return m.standing?.rank == 1
    case .cupFinal(let m): return m.standing?.seed == 1
    case .wrapped(let m): return m.season?.champion_squad_id != nil && m.season?.champion_squad_id == m.squad?.id
    default: return false
    }
  }
  private var eyebrow: String {
    switch mode {
    case .leagueless: return "Your card"
    /* D120 · the shared stage vocabulary. `forming` here covers setup AND
       draft (SeasonPhase does not split them), so it reports the one the
       league is actually in; `preseason` said "season live", which is the
       exact contradiction the audit logged on the web — a hero claiming the
       season was on while the Clubhouse said practice rounds do not count. */
    case .forming(let m):
      return "\(m.name) · \((m.phase == "draft" ? LeagueCopy.Stage.drawing : .forming).label.lowercased())"
    case .preseason(let m): return "\(m.name) · \(LeagueCopy.Stage.preseason.label.lowercased())"
    case .season(let m):
      // ONE week producer: `SeasonPhase.of` → `LeagueDates.currentWeek/totalWeeks`
      if case .season(let w, let of) = SeasonPhase.of(m) { return "\(m.name) · week \(w) of \(of)" }
      return m.name
    case .cupFinal(let m): return "\(m.name) · cup final"
    case .wrapped(let m): return "\(m.name) · season wrapped"
    }
  }

  private var figure: String {
    switch mode {
    case .leagueless(let rung): return rung == 7 ? "\(min(me.profile?.rounds_count ?? 0, 3)) of 3" : CSCopy.index(me.profile?.index_current)
    case .forming(let m):
      if let s = m.season, let d = CSDate.days(from: CSDate.today(), to: s.starts_on), d >= 0 { return "\(d)d" }
      return "—"
    case .preseason(let m):
      if let s = m.season, let d = CSDate.days(from: CSDate.today(), to: s.starts_on) { return "\(max(d, 0))d" }
      return "—"
    case .season(let m), .wrapped(let m):
      if let r = m.standing?.rank { return CSCopy.ordinal(r) }
      return "—"
    // D138 · a finalist's figure is their locked seed; anyone else's is their
    // place on the table, which is still live (§14.3 — the Final is scored fresh)
    case .cupFinal(let m):
      return HomeHeroCopy.finalFigure(m) ?? "—"
    }
  }

  /// "2nd of 2" — `HomeHeroCopy.caption`, once a standing exists. In the Final
  /// a finalist reads "1st seed"; everyone else keeps their place (§14.3).
  private var caption: String? {
    switch mode {
    case .season(let m), .wrapped(let m): return HomeHeroCopy.caption(m)
    case .cupFinal(let m): return HomeHeroCopy.seedCaption(m)
    default: return nil
    }
  }
  /// The caption's "of 2", set beside the ordinal figure (D81 keeps the ordinal big).
  private var captionTail: String? {
    guard let c = caption, c.hasPrefix(figure) else { return caption }
    let t = c.dropFirst(figure.count).trimmingCharacters(in: .whitespaces)
    return t.isEmpty ? nil : t
  }

  private var move: (String, Color)? {
    guard case .season(let m) = mode, let st = m.standing, let prev = st.prev_rank else { return nil }
    if st.rank < prev { return ("▲ up \(prev - st.rank)", prev - st.rank >= 2 ? cs.hot : cs.warm) }
    if st.rank > prev { return ("▼ down \(st.rank - prev)", cs.cool) }
    return ("— held", cs.mut)
  }

  private func moveChip(_ m: (String, Color)) -> some View {
    Text(m.0).font(CSFont.monoMediumBody).foregroundStyle(m.1)
      .padding(.horizontal, 8).padding(.vertical, 3)
      .overlay(Capsule().stroke(m.1.opacity(0.5), lineWidth: 1))
  }

  /// D119 · the Pro by name where the copy names them; "the Pro" when the
  /// server has not sent one, never a guess.
  private func proName(_ m: Me.Membership) -> String {
    let n = (m.commissioner_name ?? "").trimmingCharacters(in: .whitespaces)
    return n.isEmpty ? "The Pro" : n
  }

  private var line: String {
    switch mode {
    case .leagueless(let rung):
      return rung == 7 ? "Three rounds and your index goes live. Nothing else needed."
                       : "Established. Nobody's seen it yet — you haven't joined a league."
    /* D119 · a member is told who is doing what and by when, not handed the
       Pro's job description. Four of four player personas met the Pro's lock
       button on their own Home in the audit. */
    case .forming(let m):
      if m.isPro {
        return m.phase == "draft" ? "Bylaws locked. Draw the squads when the crew is in."
                                  : "Your league is still forming. Lock the bylaws and the invite link is yours."
      }
      if m.phase == "draft" { return "\(proName(m)) draws the squads before first tee — it's random." }
      return "\(proName(m)) is setting the bylaws. You'll see them the moment they lock."
    /* D122 · "The season's on" before first tee is the contradiction itself */
    case .preseason(let m):
      guard let s = m.season, let d = CSDate.days(from: CSDate.today(), to: s.starts_on), d >= 0 else {
        return "Rounds before first tee build your number."
      }
      return "First tee in \(d) day\(d == 1 ? "" : "s"). Rounds before it build your number."
    // D130 / D47 · "10 back of Galen · 9 – 19" — the leader by name, the score
    // as the sentence at n = 2; the pre-v2 sentences on a payload without names.
    case .season(let m):
      return HomeHeroCopy.line(m)
    case .cupFinal(let m):
      // D138 · a finalist gets the Final's sentence; a non-finalist is told
      // whose cup it is and that the table race is still theirs. The clock
      // is the D121 row's clock (`HomeHeroCopy.finalClock`) — never "0 left".
      if case .cupFinal(let w) = SeasonPhase.of(m) { return HomeHeroCopy.finalLine(m, weeksLeft: w) }
      return "Four weeks, scored fresh."
    case .wrapped(let m):
      if let s = m.season, let champ = s.champion_squad_id, champ == m.squad?.id { return "Your name goes on the cup." }
      return "The cup's been lifted. Run it back."
    }
  }

  /// The foot: rule (D140 — a solo league gets the cap line, never a floor) ·
  /// endgame (D126) · money (D106, every member, never on a $0 league — D70;
  /// the hero also carries the Pot pane's "· N still owe" while cash is short).
  private var foots: [String] {
    guard let m = mode.membership else { return [] }
    if case .wrapped = mode { return [] }
    return [HomeHeroCopy.footRule(m), HomeHeroCopy.footEndgame(m), HomeHeroCopy.footMoney(m, stillOwe: true)].compactMap { $0 }
  }

  /// D129 / D23 · "You still owe $75 · …" — self-only, unpaid only.
  private var owe: String? {
    guard let m = mode.membership else { return nil }
    if case .wrapped = mode { return nil }
    return HomeHeroCopy.owe(m)
  }
}

/// The owe line as a VoiceOver action on the hero — the eye taps the line, the rotor names it.
private struct OweAction: ViewModifier {
  let owe: String?
  let act: () -> Void
  func body(content: Content) -> some View {
    if let owe { content.accessibilityAction(named: owe) { act() } } else { content }
  }
}

/// D121 · one 44-pt row per league other than the one the hero wears. Quiet:
/// the league in the display face, the standing line in the label face, a
/// chevron. Three rows, then "and N more → Clubhouse". Hidden with one league.
/// Money on the line is `HomeHeroCopy.footMoney` — nothing on a $0 league (D70).
struct HomeLeagueRows: View {
  @Environment(\.cs) private var cs
  @Environment(\.openLeague) private var openLeague
  let memberships: [Me.Membership]
  let current: UUID?
  /// The tap: re-render Home around this league.
  let lens: (UUID) -> Void
  static let cap = 3

  var body: some View {
    let rows = HomeLeagueRow.rows(memberships, excluding: current)
    if !rows.isEmpty {
      VStack(spacing: 0) {
        ForEach(rows.prefix(Self.cap)) { r in
          Button { lens(r.id) } label: {
            HStack(alignment: .center, spacing: 10) {
              VStack(alignment: .leading, spacing: 2) {
                Text(r.name).font(CSFont.sentenceBold).foregroundStyle(cs.ink).lineLimit(1)
                // the standing line runs long at AX sizes ("Week 7 of 26 · 1st of 2, 22 clear
                // of Jade · $150 on the books · $0 collected") — wrap it whole, never clip it
                Text(r.sub).font(CSFont.label).foregroundStyle(cs.mut)
                  .fixedSize(horizontal: false, vertical: true)
              }
              Spacer(minLength: 0)
              Text("›").font(CSFont.subhead).foregroundStyle(cs.brand)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel("\(r.name). \(r.sub)")
          .accessibilityHint("Shows this league on Home")
          if r.id != rows.prefix(Self.cap).last?.id || rows.count > Self.cap { CSHairline() }
        }
        if rows.count > Self.cap, let first = rows.dropFirst(Self.cap).first {
          Button { openLeague(first.id) } label: {
            HStack {
              Text("and \(rows.count - Self.cap) more → Clubhouse").font(CSFont.label).foregroundStyle(cs.brand)
              Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          // the arrow glyph does not read; say where the door goes
          .accessibilityLabel("And \(rows.count - Self.cap) more leagues, in the Clubhouse")
          .accessibilityHint("Opens the Clubhouse")
        }
      }
      .padding(.horizontal, 6)
      .accessibilityElement(children: .contain)
      .accessibilityLabel("Your other leagues")
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
          .overlay(Capsule().stroke(st.me ? cs.brand : cs.line2, lineWidth: 1))
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
            .overlay(Capsule().stroke(cs.line2, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(CSReactions.all.first { $0.emoji == CSReactions.quick }?.label ?? "heater")
      }
    }
    .padding(.top, 6)
  }
}
