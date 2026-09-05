// Cup Season — You: "your card, your record, your trophies and your buddies"
// (index.html `#view-stats` 2829–2917). The You page IS the public profile —
// card, case, record. Everything editable + app settings live behind the ⚙,
// which rides the header row (IOS-022 item 1). The feedback door and the
// founder's desk live behind the build line in Settings (item 8).

import SwiftUI
import CSDesign
import CupSeasonKit

@MainActor
@Observable
final class YouModel {
  var data = YouData()
  /// Y-17 · the first load has returned (whole or partial)
  var loaded = false
  /// Y-17 · at least one block did not load — the screen offers one Retry
  var failed: Bool { data.isPartial }
  private let repo = YouRepository()

  func load(me: Me, uid: UUID, leagueId: UUID?) async {
    data = await repo.load(me: me, userId: uid, leagueId: leagueId)
    await ReceiptCache.shared.put((data.career?.recent ?? []).map { $0.seed(marker: me.profile?.marker, isMine: true) })
    loaded = true
  }

  /// `delete_round`, then a full reload of the card — Y-19 dropped the
  /// `handicap_index` read that used to follow the delete and changed nothing.
  func deleteRound(_ r: RoundRow, me: Me, uid: UUID, leagueId: UUID?) async -> Bool {
    do {
      try await repo.deleteRound(r.id)
      ToastCenter.shared.show("Round deleted")
      await load(me: me, uid: uid, leagueId: leagueId)
      return true
    } catch {
      ToastCenter.shared.show(SliceFormat.human(error, "Delete failed."))
      return false
    }
  }

  func dismissLRW(uid: UUID) {
    LRWQuietStore(userId: uid).dismiss()
    data.lastRoundWith = nil
  }
}

struct YouScreen: View {
  @Environment(SessionStore.self) private var store
  @Environment(LookStore.self) private var looks
  @Environment(\.cs) private var cs
  let leagueId: UUID?
  let links: YouLinks

  @State private var model = YouModel()
  @State private var reqs = BuddyRequestsModel()

  // D177 · "How it works" and its sheets moved into ⚙ Card & settings. It is
  // reference material — the same rows the Pro reads and a brand-new golfer
  // reads — and it is not part of your card. Settings is already the drawer.

  private var uid: UUID? { store.session?.user.id }
  private var league: Me.Membership? {
    store.me?.memberships.first { $0.league_id == leagueId } ?? store.me?.memberships.first
  }
  /// Y-29 · a card with no rounds on it — one empty state stands in for the
  /// three record sections. Only once the rounds read has ANSWERED: a career
  /// read that failed is nil too, and a failed read is not an empty card.
  private var noRounds: Bool { model.loaded && model.data.career.map { $0.rounds == 0 } == true }

  var body: some View {
    ScrollViewReader { proxy in
    ScrollView {
      if let me = store.me, let p = me.profile {
        VStack(alignment: .leading, spacing: 14) {
          // IOS-019 rule 3: the page header lives in the scroll
          CSPageHeader("You") {
            Button(action: links.openSettings) {
              Image(systemName: "gearshape").font(.system(size: 20, weight: .semibold)).foregroundStyle(cs.ink)
                .frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Card & settings")
          }
          .padding(.bottom, 2)

          hero(me, p)

          // D176 · buddies sat SEVENTH, under five sections of record — and it
          // is the only DOOR on a page that is otherwise all reading. You do
          // not scroll past your trophy case to reach a person. Everything
          // below this line is the record; this is the way out of it.
          // D177 · the door REPORTS. A buddy request now reaches Home on its
          // own row, and this says so before you open it.
          // Y-27 · no CSSectionHead here: the row below already says "Your
          // buddies", and a head that repeats its one row is one fact twice.
          CSRow(last: true) {
            YouDoorRow(glyph: Text(Image(systemName: "person.2")),
                       title: "Your buddies",
                       sub: reqs.requests.isEmpty
                            ? "Find golfers, see who you play with"
                            : "\(reqs.requests.count) request\(reqs.requests.count == 1 ? "" : "s") waiting",
                       action: links.openBuddies)
          }

          if let lrw = model.data.lastRoundWith {
            LastRoundWithCard(lrw: lrw, stage: links.stageRound) { if let uid { model.dismissLRW(uid: uid) } }
          }

          // ── D177 · YOUR GOLF ─────────────────────────────────────────────
          // The page had FIVE sections about your history under FOUR names,
          // interleaved with people and with the app's manual. Two group heads
          // give it a spine, and they group by SCOPE rather than by league —
          // because only ONE section below is league-scoped. `my_rivalries()`
          // takes no league argument and `loadLeagueRecord` returns a row per
          // membership; an "In <league>" head would have been a lie over two
          // of its three children.
          CSGroupHead("Your golf").id("you-case")

          // Y-17 · one quiet line when a block did not load; the rest of the
          // page is whole, and this is the way to ask again.
          if model.failed { retryLine }

          // Y-17 · the RECORD reads as placeholder bars until the first load
          // answers — never as "nothing yet" while the reads are still out.
          // The header, the hero and the buddies door render from `store.me`,
          // which is in memory before this view appears and is never part of
          // `model.data`; greying them out would be a lie about facts that
          // were never out.
          Group {
            if noRounds {
              // Y-29 · nothing on the card yet: one empty state, the Post door,
              // and no three sections each saying "not yet" in its own words.
              // A case with trophies in it (rare without a round) still hangs.
              if !TrophyCase.tiles(trophies: model.data.trophies, achievements: model.data.achievements).isEmpty {
                CSSectionHead("Trophies")
                TrophyCaseView(trophies: model.data.trophies, achievements: model.data.achievements, userId: uid, openReceipt: links.openReceipt)
              }
              CSEmptyState(icon: "⛳", line: YouCopy.noRoundsLine, cta: YouCopy.postFirst, action: links.postRound).id("you-recent")
            } else {
              // "The record" (silverware counts + money) and "Your display case"
              // (the same trophies as objects) were two sections about one subject,
              // adjacent, under different names. The counts are now the case's top
              // strip and the objects sit under them.
              CSSectionHead("Trophies")
              CareerRecordView(record: model.data.careerRecord)
              TrophyCaseView(trophies: model.data.trophies, achievements: model.data.achievements, userId: uid, openReceipt: links.openReceipt)

              // "Lifetime" → "All time": the same rows, a name that states the
              // scope out loud. It shares two row LABELS with "This season" below
              // ("Rounds posted", "Avg vs your playing number"), and until now the
              // only thing telling them apart was a small grey sub four sections away.
              CSSectionHead("All time").id("you-alltime")
              LifetimeTiles(career: model.data.career, failed: model.data.failed.contains("career"))

              CSSectionHead("Recent rounds").id("you-recent")
              RecentRoundsList(recent: model.data.career?.recent ?? [], figure: { model.data.career?.figure(for: $0) }, open: { r in
                Task { await ReceiptCache.shared.put(r.seed(marker: p.marker, isMine: true)); links.openReceipt(r.id) }
              }, delete: { r in
                if let uid { _ = await model.deleteRound(r, me: me, uid: uid, leagueId: leagueId) }
              })
              // the "Add my round" button that sat here is gone: the ⊕ is a
              // permanent tab one inch below it, and this is a page about the past.
              // No "All rounds →" door either: the only list screen the app has is
              // the season ALBUM (photos), and a door named for rounds cannot open it.
            }
          }
          .redacted(reason: model.loaded ? [] : .placeholder)

          // D232 · the season strip is a NOW fact and belongs under "Your
          // golf" — where you sit this week is not history. It keeps its own
          // head, which names the league, because it is the one league-scoped
          // block on the page.
          Group {
            if league != nil {
              SeasonStatsStrip(stats: model.data.seasonStats, leagueName: league?.name ?? "your league",
                               failed: model.data.failed.contains("season"))
            }
          }
          .redacted(reason: model.loaded ? [] : .placeholder)

          // ── D232 · YOUR RECORD ───────────────────────────────────────────
          // The second head was a SECTION where a destination belongs: the
          // career, the trophies, the head-to-heads, the side games, the books
          // and the courses were six things under one eyebrow, and the thing a
          // golfer comes back for in February should not be something they
          // scroll past their trophy case to reach.
          //
          // Two on a page is still a spine (D177's own rule): "Your golf"
          // above, and this door. `RivalriesSection` and `LeagueRecordView`
          // moved to the page it opens — they are not rendered twice.
          CSGroupHead("Your record").id("you-seasons")
          CSRow(last: true) {
            YouDoorRow(glyph: Text(Image(systemName: "trophy")),
                       title: "Everything you’ve played",
                       sub: recordSub,
                       action: links.openRecord ?? links.openSettings)
              .accessibilityHint("Opens your record")
          }
          .redacted(reason: model.loaded ? [] : .placeholder)
        }
        .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 32)
      }
    }
    .csLookGround()   // D103b: bg0 with the sky behind the page header
    .environment(\.csLook, looks.personalLook())   // IOS-025: You is the person's, so it wears the personal dial
    .defaultScrollAnchor(CSDevHatch.bottom ? .bottom : .top)
    .navigationTitle("")
    // the same chrome as Home: no bar; the ⚙ (the door to "Card & settings") rides the header row
    .toolbar(.hidden, for: .navigationBar)
    .sliceToastHost()
    .refreshable { await reload() }
    .task(id: store.me?.profile?.id) { await reload(); await reqs.load() }
    #if DEBUG
    // Developer hatch: `-cs_dev_scroll <anchor>` (case · alltime · recent ·
    // seasons) scrolls a simulator there — the same door LeagueRoomScreen has,
    // because a page three screens tall cannot be judged from its top and its
    // bottom. `case` and `recent` sit on views that render on EVERY card (the
    // group head and, on an empty card, the empty state); `alltime` and
    // `seasons` exist only where their sections do — a brand-new golfer has
    // neither, and the hatch there is a no-op by construction.
    .task(id: model.loaded) {
      let a = ProcessInfo.processInfo.arguments
      guard model.loaded, let i = a.firstIndex(of: "-cs_dev_scroll"), i + 1 < a.count else { return }
      try? await Task.sleep(for: .seconds(1))
      proxy.scrollTo("you-" + a[i + 1], anchor: .top)
    }
    #endif
    }
  }

  private func reload() async {
    guard let me = store.me, let uid else { return }
    await model.load(me: me, uid: uid, leagueId: leagueId)
  }

  /// What is behind the door, in facts the page already holds — never a
  /// promise about what might be in there (L-44). With nothing to count yet
  /// the line says what the record is FOR.
  private var recordSub: String {
    var bits: [String] = []
    let seasons = model.data.leagueRecord.count
    if seasons > 0 { bits.append("\(seasons) season\(seasons == 1 ? "" : "s")") }
    let rivals = model.data.rivalries.count
    if rivals > 0 { bits.append("\(rivals) head-to-head\(rivals == 1 ? "" : "s")") }
    if let n = model.data.careerRecord?.items.reduce(0, { $0 + $1.n }), n > 0 {
      bits.append("\(n) title\(n == 1 ? "" : "s")")
    }
    return bits.isEmpty ? "Seasons, trophies, head-to-heads and the books"
                        : bits.joined(separator: " · ")
  }

  /// Y-17 · "Some of your card did not load. · Retry" — one line, no banner.
  private var retryLine: some View {
    A11yStack(rowAlignment: .firstTextBaseline, spacing: 0, columnSpacing: 4) {
      Text(YouCopy.partialLine + " ").font(CSFont.footnote).foregroundStyle(cs.mut)
      Button { Task { await reload() } } label: {
        Text(YouCopy.retry).font(CSFont.footnote).foregroundStyle(cs.brand).a11yHitSlop()
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Retry loading your card")
    }
    .frame(minHeight: 28)
  }

  /// C4: your own credential — the same facts your buddies see on your Tour Card,
  /// as the screen's one hero (IOS-019).
  private func hero(_ me: Me, _ p: Me.Profile) -> some View {
    let x = model.data.extras
    // Y-26 · "est. Jul 2026" from the one producer; TourCard.established carries
    // its own non-breaking spaces, so the phrase never breaks across two lines.
    let since = (x?.createdAt ?? p.member_since).map { TourCard.established($0) }
    let meta = [p.handle.map { "@\($0)" }, p.city, p.home_course].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    let rounds = model.data.career?.rounds ?? p.rounds_count ?? 0
    return YouHero(
      photoURL: x?.avatarURL, marker: p.marker, name: p.display_name ?? "Your card", meta: meta,
      indexCurrent: p.index_current, rounds: rounds,
      trophyChips: TrophyMeta.credChips(model.data.achievements),
      // D209 · FORM off the same allowance figures as every other You number
      form: model.data.career?.form,
      anchor: {
        if let g = x?.ghinNumber, !g.isEmpty {
          Text(["GHIN \(g)", since].compactMap { $0 }.joined(separator: " · ")).font(CSFont.footnote).foregroundStyle(cs.mut)
        } else {
          A11yStack(rowAlignment: .firstTextBaseline, spacing: 0, columnSpacing: 2) {
            if let since { Text(since + " · ").font(CSFont.footnote).foregroundStyle(cs.mut) }
            Button { (links.addGhin ?? links.openSettings)() } label: {
              Text("add your GHIN").font(CSFont.footnote).foregroundStyle(cs.brand).a11yHitSlop()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add your GHIN")
          }
          .frame(minHeight: 28)
        }
      })
  }
}

#Preview {
  NavigationStack { YouScreen(leagueId: nil, links: .none) }
    .environment(SessionStore())
    .csTheme()
}
