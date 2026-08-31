// Cup Season — Home (index.html 2792–2822 slot order; D81 one lane; D94
// doors; D27 the digest; IOS-012 hero first on the phone).
//
// Slots, top to bottom: invites banner → buddy requests (D177 — their OWN
// row; the banner above carries league and Ryder invites only, whatever this
// comment used to claim) → live-round banner → lead card (D176) → hero →
// occasion → Up Next → digest → the one feed → coming up. The doors (start a league · start an event · join with a code)
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
          if let lead = vm.lead {
            HomeLeadCard(lead: lead) { take(lead, league: mode.membership?.league_id) }
          }

          HomeHero(mode: mode, me: me)
            .environment(\.csLook, looks.look(for: mode.membership))

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

          // the section head: eyebrow + hairline (IOS-019 rule 2); THE BOARD ↗ is a push, so the
          // trailing slot is a NavigationLink rather than CSSectionHead's action closure
          HomeSectionHead("Around your buddies") {
            if let lid = mode.membership?.league_id {
              NavigationLink(value: HomeRoute.league(lid)) { Text("THE BOARD ↗").csEyebrow(cs.dawn) }
            }
          }

          if let d = vm.digest { CSRow(last: !vm.buckets.isEmpty) { HomeDigestRow(digest: d, openReceipt: { presenter.receipt = $0 }) } }

          if vm.loading && vm.buckets.isEmpty {
            ForEach(0..<3, id: \.self) { _ in skeleton }
          } else if vm.buckets.isEmpty {
            // the sentence and its link share a line where they fit; the link is a 44pt target either way
            A11yStack(alignment: .leading, rowAlignment: .firstTextBaseline, spacing: 4) {
              Text("No rounds from your buddies yet. Post one, or").font(CSFont.footnote).foregroundStyle(cs.mut)
              NavigationLink(value: HomeRoute.people) { Text("add some buddies.").font(CSFont.footnote).foregroundStyle(cs.brand).a11yHitSlop() }
            }
            .padding(.top, 4)
          } else {
            ForEach(vm.buckets) { b in FeedBucketView(bucket: b, presenter: presenter, vm: vm, only: vm.buckets.count == 1) }
          }

          UpcomingRoundsSection(links: links)
        }
        .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 32)
      }
    }
    .csLookGround()   // D103b: bg0 with the sky behind the page header
    .environment(\.csLook, looks.personalLook())
    .defaultScrollAnchor(CSDevHatch.bottom ? .bottom : .top)
    .refreshable { await store.reload(); await vm.load(me: store.me) }
    .task(id: store.me?.generated_at) { await vm.load(me: store.me) }
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
  var buckets: [HomeBucket] = []
  var digest: HomeDigest?
  var occasion: Occasion?
  /// D176 · the one card above the hero, or none. `HomeLead.choose` decides.
  var lead: HomeLead?
  var loading = false
  var social = HomeSocial.Snapshot()
  private var markRead = false
  private var mark: Date?
  private var rounds: [HomeFeedRow] = []
  private var posts: [HomePost] = []
  private var urls: [UUID: URL] = [:]
  private let repo = HomeStreamRepository()
  private let socialRepo = HomeSocial()

  func load(me: Me?) async {
    guard let me else { return }
    loading = true
    defer { loading = false }
    occasion = Occasion.current(leagueless: me.memberships.isEmpty)
    let r = await repo.load(memberships: me.memberships)
    buckets = HomeBuckets.bucket(r.items)
    rounds = r.rounds; posts = r.posts
    if !markRead { mark = HomeDigest.readAndMark(profile: me.profile?.id); markRead = true }
    urls = [:]
    for case .round(let row, let u) in r.items { if let id = row.round_id, let u { urls[id] = u } }
    digest = HomeDigest.make(rounds: rounds, posts: posts, photoURLs: urls, mark: mark)
    // circle reactions ride the rounds just loaded (round → shared-league post)
    social = await socialRepo.load(rounds: rounds, memberships: me.memberships, currentLeague: preferred(me))
    if let mark { digest = HomeDigest.make(rounds: rounds, posts: posts, photoURLs: urls, mark: mark, mentions: social.mentions(rounds: rounds, since: mark)) }
    await loadLead(me: me)
  }

  /// D176 · everything the ladder reads is already in hand but the clash, which
  /// is one RPC. It runs LAST so a slow or skewed clash read never delays the
  /// feed — the card simply appears a moment after the rest of Home.
  private func loadLead(me: Me) async {
    let lid = preferred(me)
    let m = me.memberships.first { $0.league_id == lid } ?? me.memberships.first
    let today = CSDate.today()
    let days = CSDate.days(from: today, to: ScheduleDates.endOfMonth(today)).map { max(0, $0) }
    // someone else's news, today, worth lifting out of the river
    let mile = rounds.first { $0.is_me != true && $0.played_on == today && HomeCopy.milestone($0) != nil }
    lead = HomeLead.choose(clash: await repo.clash(league: m?.league_id),
                           pulse: m?.pulse,
                           monthDaysLeft: days,
                           standing: m?.standing,
                           milestone: mile.map { (who: HomeCopy.who($0),
                                                  line: HomeCopy.milestone($0) ?? "",
                                                  roundId: $0.round_id,
                                                  marker: $0.marker) })
  }

  private func preferred(_ me: Me) -> UUID? {
    UserDefaults.standard.string(forKey: CSConfig.lastLeagueKey).flatMap(UUID.init) ?? me.memberships.first?.league_id
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
  let bucket: HomeBucket
  let presenter: Presenter
  let vm: HomeModel
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
          case .post(let p, let league):
            CSRow { FeedPostRow(p: p, leagueName: league, presenter: presenter) }
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

/// A league post as a row in the section (IOS-019 rule 2): glyph, the body, the league line.
private struct FeedPostRow: View {
  @Environment(\.cs) private var cs
  let p: HomePost
  let leagueName: String?
  let presenter: Presenter
  private var fresh: Bool { (p.created_at.map { Date().timeIntervalSince($0) } ?? .infinity) < 48 * 3600 }
  private var closed: Bool { (p.body ?? "").range(of: "\\bclosed\\b", options: [.regularExpression, .caseInsensitive]) != nil }

  var body: some View {
    // a row with a scorecard is a door; one without is a note — never a dimmed button
    if let lr = p.live_round_id {
      Button { presenter.scorecard = lr } label: { row }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the scorecard")
    } else {
      row.accessibilityElement(children: .combine)
    }
  }

  private var row: some View {
      HStack(alignment: .top, spacing: 12) {
        Text(p.kind == "announce" ? "📣" : "🏁").font(.system(size: 18))
          .frame(width: 40, height: 40).background(cs.bg2, in: Circle())
          .overlay(Circle().stroke(fresh ? cs.line2 : .clear, lineWidth: 1))
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 3) {
          Text(HomeCopy.easeCaps(p.body ?? "")).font(CSFont.subhead).foregroundStyle(cs.ink)
          HStack(spacing: 4) {
            Text([leagueName, p.created_at.map { CSDate.short(CSDate.iso($0)) }].compactMap { $0 }.joined(separator: " · "))
              .font(CSFont.footnote).foregroundStyle(cs.mut)
            if p.live_round_id != nil { Text("· SCORECARD ›").font(CSFont.label).foregroundStyle(cs.gold) }
          }
        }
        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .rotationEffect(.degrees(closed ? 1.4 : 0))   // the month seal keeps its cant — a hand set it
  }
}

/// The hero: the standing MOVE (D81 "the standing is a verb").
struct HomeHero: View {
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la
  let mode: HomeMode
  let me: Me

  var body: some View {
    // IOS-019 rule 1: the one hero on the screen wears the wash — gold when earned; otherwise the
    // look's accent from the environment, ember when none (IOS-025: a look never overrides gold)
    CSHero(spine: earned ? cs.gold : nil, padding: 20) {
      VStack(alignment: .leading, spacing: 10) {
        Text(eyebrow).csEyebrow(earned ? cs.gold : la.eyebrow)   // D103b: the eyebrow wears the look
        HStack(alignment: .firstTextBaseline, spacing: 12) {
          Text(figure).font(CSFont.hero).foregroundStyle(earned ? cs.gold : cs.ink).csTabular()
          if let move { moveChip(move) }
        }
        Text(line).font(CSFont.sentence).foregroundStyle(cs.ink)
        if let foot { Text(foot).font(CSFont.monoSmall).foregroundStyle(cs.mut).padding(.top, 2) }
      }
      .padding(.leading, 6)
    }
    .accessibilityElement(children: .combine)
  }

  /// Gold is EARNED only: the lead this season, the lead into the final, or your name on the cup.
  private var earned: Bool {
    switch mode {
    case .season(let m), .cupFinal(let m): return m.standing?.rank == 1
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
    case .season(let m), .cupFinal(let m), .wrapped(let m):
      if let r = m.standing?.rank { return CSCopy.ordinal(r) }
      return "—"
    }
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
    case .season(let m):
      guard let st = m.standing else { return "Standings start at the first posted round." }
      if st.rank == 1 {
        if let g = st.gap_to_next, g > 0 { return "You lead by \(CSCopy.points(g)) points." }
        // Q-26: spec §14.3's ladder is months won -> best single month -> fewest
        // rounds -> a coin flip. One round breaks nothing by itself.
        return "Level at the top. Months won breaks the tie."
      }
      if let g = st.gap_to_leader { return g == 0 ? "Level with the lead." : "\(CSCopy.points(g)) points back of the lead." }
      return "In the race."
    case .cupFinal(let m):
      if case .cupFinal(let w) = SeasonPhase.of(m) { return "Four weeks, scored fresh. Whoever's hottest takes the cup. \(w) left." }
      return "Four weeks, scored fresh."
    case .wrapped(let m):
      if let s = m.season, let champ = s.champion_squad_id, champ == m.squad?.id { return "Your name goes on the cup." }
      return "The cup's been lifted. Run it back."
    }
  }

  private var foot: String? {
    guard let m = mode.membership else { return nil }
    if let p = m.pulse, let floor = p.floor, floor > 0 {
      let credits = p.credits ?? 0
      if p.partial == true { return "Partial month · floors waived" }
      return credits >= Double(floor) ? "Month floor met · \(CSCopy.points(credits))/\(floor)" : "Month floor \(CSCopy.points(credits))/\(floor) · \(CSCopy.points(Double(floor) - credits)) more"
    }
    if let cap = m.settings?.counting_cap { return "Best \(cap) rounds a month count" }
    return nil
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
