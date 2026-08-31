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
  var loaded = false
  private let repo = YouRepository()

  func load(me: Me, uid: UUID, leagueId: UUID?) async {
    data = await repo.load(me: me, userId: uid, leagueId: leagueId)
    await ReceiptCache.shared.put((data.career?.recent ?? []).map { $0.seed(marker: me.profile?.marker, isMine: true) })
    loaded = true
  }

  /// `delete_round`, then the engine re-reads the index; the card reloads.
  func deleteRound(_ r: RoundRow, me: Me, uid: UUID, leagueId: UUID?) async -> Bool {
    do {
      try await repo.deleteRound(r.id, profile: uid)
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

  var body: some View {
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
          CSSectionHead("Your buddies")
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
          CSGroupHead("Your golf")

          // "The record" (silverware counts + money) and "Your display case"
          // (the same trophies as objects) were two sections about one subject,
          // adjacent, under different names. The counts are now the case's top
          // strip and the objects sit under them.
          CSSectionHead("Display case")
          CareerRecordView(record: model.data.careerRecord)
          TrophyCaseView(trophies: model.data.trophies, achievements: model.data.achievements, userId: uid)

          // "Lifetime" → "All time": the same rows, a name that states the
          // scope out loud. It shares two row LABELS with "This season" below
          // ("Rounds posted", "Avg vs index"), and until now the only thing
          // telling them apart was a small grey sub four sections away.
          CSSectionHead("All time")
          LifetimeTiles(career: model.data.career)

          CSSectionHead("Recent rounds")
          RecentRoundsList(recent: model.data.career?.recent ?? [], open: { r in
            Task { await ReceiptCache.shared.put(r.seed(marker: p.marker, isMine: true)); links.openReceipt(r.id) }
          }, delete: { r in
            if let uid { _ = await model.deleteRound(r, me: me, uid: uid, leagueId: leagueId) }
          }, postFirst: links.postRound)
          // the "Post a round" button that sat here is gone: the ⊕ is a
          // permanent tab one inch below it, and this is a page about the past.

          // ── D177 · YOUR SEASONS ──────────────────────────────────────────
          CSGroupHead("Your seasons")

          if league != nil {
            SeasonStatsStrip(stats: model.data.seasonStats, leagueName: league?.name ?? "your league")
            RivalriesSection(rivalries: model.data.rivalries, openTourCard: links.openTourCard)
          }
          // "League record" → "Every season": it is a season-by-season list of
          // where you finished, in every league. Calling it a record put a
          // THIRD "record" on one page.
          LeagueRecordView(rows: model.data.leagueRecord)
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
  }

  private func reload() async {
    guard let me = store.me, let uid else { return }
    await model.load(me: me, uid: uid, leagueId: leagueId)
  }

  /// C4: your own credential — the same facts your buddies see on your Tour Card,
  /// as the screen's one hero (IOS-019).
  private func hero(_ me: Me, _ p: Me.Profile) -> some View {
    let x = model.data.extras
    let since = (x?.createdAt ?? p.member_since).map { "Member since " + TourCard.monthYear($0) }
    let meta = [p.handle.map { "@\($0)" }, p.city, p.home_course].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    let rounds = model.data.career?.rounds ?? p.rounds_count ?? 0
    let lines = TrophyMeta.credLines(model.data.achievements, max: 3, moreSuffix: " more in the case")
    let more = model.data.achievements.count > 3 ? lines.last : nil
    return YouHero(
      photoURL: x?.avatarURL, marker: p.marker, name: p.display_name ?? "Your card", meta: meta,
      indexCurrent: p.index_current, rounds: rounds,
      trophyChips: more == nil ? lines : Array(lines.dropLast()), moreChip: more,
      form: FormRow.from(beats: (model.data.career?.recent ?? []).map(\.beat)),
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
