// Cup Season — the League Room (`#view-hub`, index.html 3333–3620; IA P2 "one
// door, five segments"). Header card · the D71 cancel banner · Standings /
// Board / Schedule / Pot / Album / League. Board and Schedule are other
// slices — this screen calls their links.

import SwiftUI
import CSDesign
import CupSeasonKit

struct LeagueRoomScreen: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @State private var model: LeagueRoomModel
  @State private var router = RoomRouter()
  let links: LeagueRoomLinks

  init(leagueId: UUID, links: LeagueRoomLinks) {
    _model = State(initialValue: LeagueRoomModel(leagueId: leagueId))
    self.links = links
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        if let err = model.error, !model.loaded {
          CSCard(spine: cs.neg) {
            VStack(alignment: .leading, spacing: 10) {
              Text("The room did not load").csEyebrow(cs.neg)
              Text(err).font(CSFont.body).foregroundStyle(cs.ink)
              CSButton("Try again", style: .quiet) { Task { await model.refresh() } }
            }
          }
        } else if !model.loaded {
          LeagueHeaderCard(loading: true)
          Text("Loading the room…").csEyebrow()
        } else {
          LeagueHeaderCard(loading: false)
          CancelBanner()
          roomSeg
          switch router.pane {
          case .standings: StandingsPane()
          case .board: EmptyView()
          case .schedule: EmptyView()
          case .pot: PotPane()
          case .album: RoomAlbumPane()
          case .league: LeaguePane()
          }
        }
      }
      .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 32)
    }
    .background(cs.bg0)
    .navigationTitle(model.league?.name ?? "League")
    .navigationBarTitleDisplayMode(.inline)
    .environment(model)
    .environment(router)
    .environment(\.roomLinks, links)
    .refreshable { await model.refresh() }
    .task(id: model.leagueId) {
      guard !model.loaded, let me = store.me, let v = RoomViewer(me) else { return }
      await model.load(viewer: v)
      // D66: a finished season announces itself ONCE per member, after the room's data is in
      if model.ceremonyDue {
        try? await Task.sleep(for: .milliseconds(400))
        router.open(.ceremony)
      }
    }
    .sheet(item: $router.sheet) { s in
      Group {
        switch s {
        case .squad(let t): SquadReceiptSheet(team: t)
        case .member(let r): MemberHistorySheet(row: r)
        case .scoringHelp: RoomScoringHelpSheet()
        case .ceremony: SeasonCeremonyView()
        case .members: MembersSheet()
        case .forfeitCreate: ForfeitCreateSheet()
        case .forfeitSettle(let f): ForfeitSettleSheet(forfeit: f)
        case .cancelLeague: CancelLeagueSheet()
        case .deleteLeague(let others): DeleteLeagueSheet(others: others)
        }
      }
      .environment(model)
      .environment(router)
      .environment(\.roomLinks, links)
      .presentationDetents([.large])
      .presentationDragIndicator(.visible)
    }
  }

  /// `#roomSeg` — six segments; the Pot tab hides at $0 (D70).
  private var roomSeg: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 6) {
        ForEach(RoomPane.allCases) { p in
          if p == .pot && model.bylaws.stake == 0 { EmptyView() } else {
            Button {
              CSHaptic.selection()
              switch p {
              case .board: links.openBoard()
              case .schedule: links.openSchedule()
              default: router.pane = p
              }
            } label: {
              Text(p.rawValue).font(CSFont.monoSmall)
                .foregroundStyle(router.pane == p ? cs.bg0 : cs.ink)
                .padding(.horizontal, 12).frame(minHeight: 36)
                .background(router.pane == p ? cs.ink : cs.bg2, in: Capsule())
                .overlay(Capsule().stroke(cs.line2, lineWidth: router.pane == p ? 0 : 1))
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(router.pane == p ? [.isSelected] : [])
          }
        }
      }
    }
  }
}

/// `#hubHeader` — name, phase, the code, the span, THE PRO, Add golfers, the danger link.
struct LeagueHeaderCard: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.roomLinks) private var links
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  let loading: Bool

  var body: some View {
    CSCard(spine: model.isComplete ? cs.gold : nil, padding: 16) {
      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .top, spacing: 10) {
          VStack(alignment: .leading, spacing: 2) {
            Text(model.league?.name ?? "—").font(CSFont.title).foregroundStyle(cs.ink)
            Text(loading ? "Loading the room…" : LeagueCopy.phaseHeader(model.clock)).font(CSFont.footnote).foregroundStyle(cs.mut)
          }
          Spacer(minLength: 8)
          if let code = model.league?.code, let url = model.inviteURL {
            // `.copycode` (12727): in a real league the tap IS the share sheet
            ShareLink(item: url, subject: Text("Cup Season"), message: Text(model.inviteText)) {
              Text("Code · ").font(CSFont.monoSmall).foregroundStyle(cs.ink) + Text(code).font(CSFont.monoMediumBody).foregroundStyle(cs.ink)
            }
            .padding(.horizontal, 12).frame(minHeight: 36)
            .background(cs.bg2, in: Capsule()).overlay(Capsule().stroke(cs.line2, lineWidth: 1))
            .frame(minHeight: 44)
          }
        }
        if !loading {
          Text(LeagueCopy.phaseSub(model.clock, b: model.bylaws, code: model.league?.code, members: model.members.count))
            .font(CSFont.label).tracking(1.2).foregroundStyle(cs.dimText).padding(.top, 4)
          Text(model.clock.spanText).font(CSFont.footnote).foregroundStyle(cs.mut).padding(.top, 2)
          Text("THE PRO · \(model.proName.uppercased())").font(CSFont.label).tracking(1.2).foregroundStyle(cs.dimText)
          HStack(spacing: 8) {
            RoomMini("Add golfers") { links.addGolfers() }
          }
          .padding(.top, 6)
          // D71: the Pro can end a league in ANY phase but 'complete' (the record book)
          if model.isPro && !model.isComplete {
            let d = LeagueCopy.danger(model.clock)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
              Button(d.link) {
                if d.preTee { Task { router.open(.deleteLeague(others: await model.othersCount())) } } else { router.open(.cancelLeague) }
              }
              .font(CSFont.footnote).foregroundStyle(cs.neg).frame(minHeight: 44)
              Text(d.note).font(CSFont.footnote).foregroundStyle(cs.dimText)
            }
          }
        }
      }
    }
  }
}

/// `#cancelBanner` (15563–15587, D71): approve / decline / withdraw.
struct CancelBanner: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  @State private var busy = false

  var body: some View {
    if let cr = model.cancel, cr.open == true {
      CSCard(spine: cs.neg) {
        VStack(alignment: .leading, spacing: 6) {
          Text("The Pro wants to cancel \(model.league?.name ?? "the league").").font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
          RoomFine(((cr.you_refund_cents ?? 0) > 0 ? "You get back \(PotMath.money(cr.you_refund_cents!)) — your buy-in. " : "")
               + "The season won't be played; nobody won and every buy-in comes back. Your rounds stay on your card.")
          HStack(spacing: 8) {
            if cr.is_pro == true {
              RoomMini("Call it off", busy: busy) { run { try await model.withdrawCancel(); toast.show("Cancellation called off.") } }
              Text("\(cr.approved ?? 0) of \(cr.members ?? 0) approved").font(CSFont.footnote).foregroundStyle(cs.dimText)
            } else if cr.you_approved == true {
              Text("You approved — waiting on the rest (\(cr.approved ?? 0) of \(cr.members ?? 0)).").font(CSFont.footnote).foregroundStyle(cs.dimText)
            } else {
              RoomMini("Approve", busy: busy) { vote(true) }
              RoomMini("Decline", busy: busy) { vote(false) }
              Text("\(cr.approved ?? 0) of \(cr.members ?? 0) approved").font(CSFont.footnote).foregroundStyle(cs.dimText)
            }
          }
          .padding(.top, 4)
        }
      }
    }
  }

  private func vote(_ approve: Bool) {
    run {
      let r = try await model.voteCancel(approve: approve)
      if r == "done" { toast.show("\(model.league?.name ?? "The league") cancelled. Every round stays on its golfer."); links.leagueGone() }
      else if r == "declined" { toast.show("You declined — the cancellation is off.") }
      else { toast.show("Approved — waiting on the rest.") }
    }
  }

  private func run(_ op: @escaping @MainActor () async throws -> Void) {
    busy = true
    Task { defer { busy = false }; do { try await op() } catch { toast.show(roomError(error)) } }
  }
}
