// Cup Season — You: "your card, your record, your trophies and your buddies"
// (index.html `#view-stats` 2829–2917). The You page IS the public profile —
// card, case, record. Everything editable + app settings live behind the ⚙.

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
  @Environment(\.cs) private var cs
  let leagueId: UUID?
  let links: YouLinks

  @State private var model = YouModel()
  @State private var sheet: Sheet?

  enum Sheet: Identifiable {
    case guide(GuideSheet), scoring
    var id: String { if case .guide(let g) = self { return "g:\(g.key)" }; return "scoring" }
  }

  private var uid: UUID? { store.session?.user.id }
  private var league: Me.Membership? {
    store.me?.memberships.first { $0.league_id == leagueId } ?? store.me?.memberships.first
  }

  var body: some View {
    ScrollView {
      if let me = store.me, let p = me.profile {
        VStack(alignment: .leading, spacing: 14) {
          credential(me, p)
          FeedbackChip(action: links.openFeedback)
          if model.data.isFounder { FounderDeskCard(openDesk: links.openFounderDesk, fieldNote: links.founderNote) }

          Text("Your display case").csEyebrow()
          TrophyCaseView(trophies: model.data.trophies, achievements: model.data.achievements, userId: uid)

          if let lrw = model.data.lastRoundWith {
            LastRoundWithCard(lrw: lrw, stage: links.stageRound) { if let uid { model.dismissLRW(uid: uid) } }
          }

          Text("The record").csEyebrow()
          CareerRecordView(record: model.data.careerRecord)

          Text("Lifetime").csEyebrow()
          LifetimeTiles(career: model.data.career)

          Text("Recent rounds").csEyebrow()
          RecentRoundsList(recent: model.data.career?.recent ?? [], open: { r in
            Task { await ReceiptCache.shared.put(r.seed(marker: p.marker, isMine: true)); links.openReceipt(r.id) }
          }, delete: { r in
            if let uid { _ = await model.deleteRound(r, me: me, uid: uid, leagueId: leagueId) }
          }, postFirst: links.postRound)
          CSButton("Post a round", action: links.postRound)

          Text("Your buddies").csEyebrow()
          CheckDoor(glyph: Text(Image(systemName: "person.2")), title: "Your buddies", sub: "Find golfers, see who you play with", action: links.openBuddies)

          if league != nil {
            RivalriesSection(rivalries: model.data.rivalries, openTourCard: links.openTourCard)
            SeasonStatsStrip(stats: model.data.seasonStats, leagueName: league?.name ?? "your league")
          }
          LeagueRecordView(rows: model.data.leagueRecord)

          Text("How it works").csEyebrow()
          HowItWorks { row in
            if row.key == "scoring" { sheet = .scoring } else if let g = GuideCopy.sheets[row.key] { sheet = .guide(g) }
          }
        }
        .padding(20)
      }
    }
    .background(cs.bg0)
    .navigationTitle("You")
    .navigationBarTitleDisplayMode(.inline)
    .sliceToastHost()
    .refreshable { await reload() }
    .task(id: store.me?.profile?.id) { await reload() }
    .sheet(item: $sheet) { s in
      switch s {
      case .guide(let g): GuideSheetView(sheet: g)
      case .scoring: ScoringHelpSheet()
      }
    }
  }

  private func reload() async {
    guard let me = store.me, let uid else { return }
    await model.load(me: me, uid: uid, leagueId: leagueId)
  }

  /// C4: your own credential — the same object your buddies see on your Tour Card.
  private func credential(_ me: Me, _ p: Me.Profile) -> some View {
    let x = model.data.extras
    let since = (x?.createdAt ?? p.member_since).map { "Member since " + TourCard.monthYear($0) }
    let meta = [p.handle.map { "@\($0)" }, p.city, p.home_course].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    let rounds = model.data.career?.rounds ?? p.rounds_count ?? 0
    let dark = CSTokens.dark
    return CredentialCard(
      photoURL: x?.avatarURL, marker: p.marker, name: p.display_name ?? "Your card", meta: meta,
      indexCurrent: p.index_current, rounds: rounds,
      trophyLines: TrophyMeta.credLines(model.data.achievements, max: 3, moreSuffix: " more in the case"),
      form: FormRow.from(beats: (model.data.career?.recent ?? []).map(\.beat)),
      anchor: {
        if let g = x?.ghinNumber, !g.isEmpty {
          Text(["GHIN \(g)", since].compactMap { $0 }.joined(separator: " · ")).font(CSFont.footnote).foregroundStyle(dark.mut)
        } else {
          HStack(spacing: 0) {
            if let since { Text(since + " · ").font(CSFont.footnote).foregroundStyle(dark.mut) }
            Button("add your GHIN") { (links.addGhin ?? links.openSettings)() }
              .font(CSFont.footnote).foregroundStyle(dark.brand).buttonStyle(.plain)
          }
          .frame(minHeight: 28)
        }
      },
      extra: { EmptyView() },
      settings: links.openSettings)
  }
}

#Preview {
  NavigationStack { YouScreen(leagueId: nil, links: .none) }
    .environment(SessionStore())
    .csTheme()
}
