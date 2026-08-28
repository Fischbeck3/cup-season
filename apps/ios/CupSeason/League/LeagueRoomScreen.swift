// Cup Season — the League Room (`#view-hub`, index.html 3333–3620; IA P2 "one
// door, five segments"). The hero · the D71 cancel banner · the tab strip ·
// Standings / Board / Schedule / Pot / Album / League. Board and Schedule are
// other slices — this screen calls their links.
//
// IOS-019: one hero with the wash opens the scroll; the panes are a tab
// strip, not pills; everything under it sits on ground, not in borders.

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
    ScrollViewReader { proxy in
      room
        #if DEBUG
        // Developer hatch: `-cs_dev_scroll <anchor>` (climb · standings · race) scrolls a simulator there.
        .task(id: model.loaded) {
          let a = ProcessInfo.processInfo.arguments
          guard model.loaded, let i = a.firstIndex(of: "-cs_dev_scroll"), i + 1 < a.count else { return }
          try? await Task.sleep(for: .seconds(1))
          proxy.scrollTo("room-" + a[i + 1], anchor: .top)
        }
        #endif
    }
  }

  private var room: some View {
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
        } else {
          LeagueHeaderCard(loading: false)
          CancelBanner()
          roomTabs
          Group {
            switch router.pane {
            case .standings: StandingsPane()
            case .board: EmptyView()
            case .schedule: EmptyView()
            case .pot: PotPane()
            case .album: RoomAlbumPane()
            case .league: LeaguePane()
            }
          }
          .animation(CSMotion.roll, value: router.pane)
        }
      }
      .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 32)
    }
    .csLookGround()   // D103b: bg0 with the sky behind the league hero
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

  /// `#roomSeg` — six segments as a tab strip (IOS-019 rule 4); the Pot tab
  /// hides at $0 (D70). Board and Schedule are doors, not panes: their taps
  /// navigate and the strip's selection never lands on them.
  private var roomTabs: some View {
    let items: [(RoomPane, String)] = RoomPane.allCases
      .filter { !($0 == .pot && model.bylaws.stake == 0) }
      .map { ($0, $0.rawValue) }
    let selection = Binding<RoomPane>(
      get: { router.pane },
      set: { p in
        switch p {
        case .board: links.openBoard()
        case .schedule: links.openSchedule()
        default: router.pane = p
        }
      })
    return CSTabStrip(items, selection: selection)
      .padding(.horizontal, -20)   // the strip and its hairline run edge to edge
  }
}

/// `#hubHeader` — the room's ONE hero (IOS-019 rule 1): the name in the honor
/// voice, the phase line, the meta as a mono eyebrow, the code as a chip on
/// the trailing edge, "Add golfers" as a quiet link, the danger link. The
/// spine is gold only once the season is wrapped (earned); while live it is the
/// room's look from the environment — ember when none (IOS-025).
struct LeagueHeaderCard: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.roomLinks) private var links
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  let loading: Bool

  var body: some View {
    CSHero(spine: model.isComplete ? cs.gold : nil, padding: 20) {
      VStack(alignment: .leading, spacing: 6) {
        // the name takes the whole line; the code chip rides the phase line's trailing edge —
        // and its own line at the accessibility sizes, so neither the phase nor the code breaks mid-word
        Text(model.league?.name ?? "—").font(CSFont.heroSmall).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
        A11yStack(spacing: 12, columnSpacing: 8) {
          Text(loading ? "Loading the room…" : LeagueCopy.phaseHeader(model.clock))
            .font(CSFont.sentence).foregroundStyle(model.isComplete ? cs.gold : cs.mut)
            .fixedSize(horizontal: false, vertical: true)
          Spacer(minLength: 8)
          if let code = model.league?.code, let url = model.inviteURL {
            // `.copycode` (12727): in a real league the tap IS the share sheet
            ShareLink(item: url, subject: Text("Cup Season"), message: Text(model.inviteText)) {
              RoomCodeChip(code: code)
            }
            .accessibilityLabel("Code \(code) — share the invite")
          }
        }
        if !loading {
          Text(LeagueCopy.phaseSub(model.clock, b: model.bylaws, code: model.league?.code, members: model.members.count))
            .font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.dimText)
            .fixedSize(horizontal: false, vertical: true).padding(.top, 8)
          Text("\(model.clock.spanText) · THE PRO · \(model.proName.uppercased())")
            .font(CSFont.label).tracking(0.8).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
          A11yStack(rowAlignment: .firstTextBaseline, spacing: 16, columnSpacing: 0) {
            Button { links.addGolfers() } label: {
              Text("Add golfers").font(CSFont.monoMediumBody).foregroundStyle(cs.dawn).frame(minHeight: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // D71: the Pro can end a league in ANY phase but 'complete' (the record book)
            if model.isPro && !model.isComplete {
              let d = LeagueCopy.danger(model.clock)
              Button {
                if d.preTee { Task { router.open(.deleteLeague(others: await model.othersCount())) } } else { router.open(.cancelLeague) }
              } label: {
                Text(d.link).font(CSFont.footnote).foregroundStyle(cs.neg).frame(minHeight: 44).contentShape(Rectangle())
              }
              .buttonStyle(.plain)
              .accessibilityHint(d.note)
            }
          }
          .padding(.top, 2)
          if model.isPro && !model.isComplete {
            Text(LeagueCopy.danger(model.clock).note).font(CSFont.footnote).foregroundStyle(cs.dimText)
              .fixedSize(horizontal: false, vertical: true).padding(.top, -8)
          }
        }
      }
    }
  }
}

/// The league code as a small mono chip — `bg2` ground, no border.
struct RoomCodeChip: View {
  @Environment(\.cs) private var cs
  let code: String
  var body: some View {
    // one Text, so the chip never breaks "Code ·" from its code; the code itself stays on one line
    (Text("Code · ").font(CSFont.label).tracking(0.6).foregroundStyle(cs.mut)
      + Text(code).font(CSFont.monoMediumBody).foregroundStyle(cs.ink))
      .lineLimit(1).minimumScaleFactor(0.7)
      .padding(.horizontal, 10).frame(minHeight: 32)
      .background(cs.bg2.opacity(0.85), in: Capsule())
      .frame(minHeight: 44)
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
          FlowRow(spacing: 8) {
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
