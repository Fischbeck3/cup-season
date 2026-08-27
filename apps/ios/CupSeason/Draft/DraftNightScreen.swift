// Cup Season — `#view-draft` (index.html 2936–2957), on the `.room-dusk`
// ground in every theme: squad formation for a real league (`renderFormation`
// 14607–14700 — blind draw · Pro assign · Start the season) and the snake
// board (`renderDraft` 5427–5548) over `drafts` / `draft_picks` for a league
// whose formation is `snake` or `live`. Members see the same view read-only
// (S3-04). Realtime rides the DEDICATED client; every pick and the draw
// reveal are board posts, so a `posts` INSERT reloads the room.

import SwiftUI
import CSDesign
import CupSeasonKit

struct DraftLinks {
  /// `start_season` succeeded — the web switches to Home with "The season is live — post a round".
  var onSeasonStarted: @MainActor @Sendable (UUID) -> Void
  /// Setup-phase bounce (4141): "Lock settings first: the draft opens after setup".
  var openWizard: @MainActor @Sendable () -> Void
  /// The members sheet's "Add golfers" (the people picker, another slice's sheet).
  var addGolfers: @MainActor @Sendable () -> Void
}

struct DraftNightScreen: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.toast) private var toast
  @State private var room: LeagueRoomModel
  @State private var board = DraftBoardModel()
  @State private var router = RoomRouter()
  @State private var members = false
  let links: DraftLinks
  private let dk = CSTokens.dark

  init(leagueId: UUID, links: DraftLinks) {
    _room = State(initialValue: LeagueRoomModel(leagueId: leagueId))
    self.links = links
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        if let err = room.error, !room.loaded {
          DraftClockCard(accent: dk.neg, k: "The room did not load", n: err, m: "") {
            CSButton("Try again", style: .quiet) { Task { await room.refresh() } }
          }
        } else if !room.loaded {
          Text(DraftCopy.eyebrow(room.bylaws.draftType)).csEyebrow()
          RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).fill(CSDusk.surface).frame(height: 120).redacted(reason: .placeholder)
        } else {
          switch room.clock.phase {
          case .setup: setupBounce
          case .draft, .season:
            if ["snake", "live"].contains(room.bylaws.draftType) { snakeBoard } else { formation }
          }
        }
      }
      .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 32)
    }
    .background(CSDusk.ground)
    .environment(\.cs, dk)                       // the ceremony ground keeps the charcoal palette in every theme
    .navigationTitle(room.league?.name ?? "Draft night")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button { members = true } label: { Image(systemName: "person.2").foregroundStyle(dk.brand) }
          .accessibilityLabel("Members & invites")
          .disabled(!room.loaded)
      }
    }
    .refreshable { await reload() }
    .task(id: room.leagueId) {
      guard !room.loaded, let me = store.me, let v = RoomViewer(me) else { return }
      await room.load(viewer: v)
      await board.attach(room: room)
    }
    .onDisappear { Task { await board.detach() } }
    .sheet(isPresented: $members) {
      MembersSheet()
        .environment(room).environment(router)
        .environment(\.roomLinks, LeagueRoomLinks(openBoard: {}, openSchedule: {}, openWizard: links.openWizard, openDraft: {},
                                                  openReceipt: { _ in }, openTourCard: { _ in }, addGolfers: links.addGolfers))
        .presentationDetents([.large]).presentationDragIndicator(.visible)
    }
  }

  private func reload() async {
    await room.refresh()
    await board.reload(room: room)
  }

  // MARK: setup — the web bounces to the wizard (4141)

  private var setupBounce: some View {
    DraftClockCard(accent: dk.brand, k: DraftCopy.boardWaitingK, n: DraftCopy.setupBounce, m: LeagueCopy.seatFill(code: room.league?.code, members: room.members.count, min: room.bylaws.structMin)) {
      if room.isPro { CSButton("Continue") { links.openWizard() } } else { CSFine(DraftCopy.memberReadOnly) }
    }
  }

  // MARK: formation (`renderFormation`)

  private var formation: some View {
    let pool = room.pool
    let assign = room.bylaws.draftType == "assign"
    let started = room.clock.phase == .season
    let blocker = DraftCopy.startBlocker(members: room.members.count, pool: pool.count, squads: room.squads, solo: room.solo)
    return VStack(alignment: .leading, spacing: 14) {
      Text(DraftCopy.eyebrow(room.bylaws.draftType)).csEyebrow()
      if started {
        DraftClockCard(accent: dk.gold, k: DraftCopy.doneK, n: DraftCopy.doneN, m: DraftCopy.doneM) { EmptyView() }
      } else {
        DraftClockCard(accent: dk.pos, k: DraftCopy.formK, n: DraftCopy.formN(pool: pool.count), m: DraftCopy.formM(room.bylaws.draftType)) {
          if room.isPro {
            VStack(alignment: .leading, spacing: 8) {
              if !pool.isEmpty && !assign {
                RoomMini(DraftCopy.draw, busy: board.busy) { draw() }
              }
              if pool.isEmpty && !room.squads.isEmpty {
                RoomMini(DraftCopy.start, busy: board.busy) { startSeason(blocker: blocker) }
              }
              // the server's own words, said before the tap (audit 02 §7.19)
              if let blocker, pool.isEmpty || room.members.count < 4 { CSFine(blocker, tone: dk.warm) }
            }
            .padding(.top, 6)
          }
        }
      }
      ForEach(Array(room.squads.enumerated()), id: \.element.id) { i, q in
        DraftSquadCard(squad: q, color: dk.squad(q.color ?? i), selected: board.selected != nil && room.isPro && assign && !started,
                       name: { room.memName($0) }, marker: { room.member($0)?.mk }, avatar: { room.member($0).flatMap { room.avatarURL[$0.profile_id] } }) {
          guard room.isPro, assign, let m = board.selected else { return }
          assignPlayer(m, to: q.id)
        }
      }
      if started {
        EmptyView()
      } else if pool.isEmpty {
        CSFine(DraftCopy.poolEmpty)
      } else {
        Text(DraftCopy.poolEyebrow).csEyebrow()
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 6, alignment: .leading)], alignment: .leading, spacing: 6) {
          ForEach(pool) { m in
            DraftPoolChip(name: m.name, marker: m.mk, avatar: room.avatarURL[m.profile_id], selected: board.selected == m.id) {
              guard room.isPro, assign else { return }
              CSHaptic.selection()
              board.selected = board.selected == m.id ? nil : m.id
            }
            .allowsHitTesting(room.isPro && assign)
          }
        }
      }
    }
  }

  private func draw() {
    guard let s = room.season else { return }
    board.run(toast: toast, fail: DraftCopy.drawFailed) {
      try await DraftService().draw(season: s.id)
      toast.show(DraftCopy.hatSpoken)
      CSHaptic.success()
      await reload()
    }
  }

  private func assignPlayer(_ member: UUID, to squad: UUID) {
    board.run(toast: toast, fail: DraftCopy.assignFailed) {
      try await DraftService().assign(squad: squad, member: member)
      board.selected = nil
      await reload()
    }
  }

  private func startSeason(blocker: String?) {
    guard let s = room.season else { return }
    if let blocker { toast.show(blocker); return }
    board.run(toast: toast, fail: nil) {
      try await DraftService().startSeason(season: s.id)
      CSHaptic.success()
      toast.show(DraftCopy.seasonLive)
      await store.reload()
      links.onSeasonStarted(room.leagueId)
    }
  }

  // MARK: the snake board (`renderDraft`, over the server's drafts)

  private var snakeBoard: some View {
    let d = board.draft
    let order = d?.order_squads ?? []
    let nSq = order.count
    let done = d.map { DraftSnake.done($0) } ?? false
    let onClock: UUID? = (d != nil && !done) ? DraftSnake.squadOnClock(pick: d!.current_pick, order: order) : nil
    let clockSquad = onClock.flatMap { id in room.squads.first { $0.id == id } }
    let captainId = clockSquad?.captain_member_id
    let captain = room.memName(captainId)
    let mine = !done && d != nil && (room.isPro || (captainId != nil && captainId == room.myMember?.id))
    let pool = room.pool
    return VStack(alignment: .leading, spacing: 14) {
      Text(DraftCopy.eyebrow(room.bylaws.draftType)).csEyebrow()
      if let d, !done {
        DraftLockBadge(text: mine ? DraftCopy.lockMine : DraftCopy.lockTheirs(captain), mine: mine)
        let lp = DraftSnake.label(pick: d.current_pick, squads: nSq)
        DraftClockCard(accent: clockSquad.map { dk.squad($0.color ?? 0) } ?? dk.brand, k: DraftCopy.onClockK, n: captain,
                       m: DraftCopy.clockM(round: lp.round, pick: lp.pick, of: nSq, squad: clockSquad?.name ?? "")) {
          DraftSnakeDots(total: DraftSnake.total(squads: nSq, rounds: d.rounds_count), made: d.current_pick)
        }
      } else if d != nil {
        DraftClockCard(accent: dk.gold, k: DraftCopy.doneK, n: DraftCopy.doneN, m: DraftCopy.doneM) {
          if room.isPro && room.clock.phase == .draft {
            RoomMini(DraftCopy.start, busy: board.busy) { startSeason(blocker: nil) }.padding(.top, 6)
          }
        }
      } else if room.squads.isEmpty {
        DraftClockCard(accent: dk.pos, k: DraftCopy.boardWaitingK, n: DraftCopy.boardWaitingN, m: DraftCopy.boardWaitingM) { EmptyView() }
      } else {
        DraftLockBadge(text: DraftCopy.lockIdle, mine: false)
        DraftClockCard(accent: dk.pos, k: DraftCopy.boardWaitingK, n: DraftCopy.formN(pool: pool.count), m: DraftCopy.boardWaitingM) { EmptyView() }
      }
      ForEach(Array(room.squads.enumerated()), id: \.element.id) { i, q in
        DraftSnakeSquadCard(squad: q, color: dk.squad(q.color ?? i), onClock: q.id == onClock, rounds: d?.rounds_count ?? 3,
                            picks: board.picks.filter { $0.squad_id == q.id }, name: { room.memName($0) },
                            index: { room.member($0)?.profile?.index_current })
      }
      if let d, !done {
        Text(DraftCopy.poolEyebrow).csEyebrow()
        if pool.isEmpty { CSFine(DraftCopy.poolDone) } else {
          ForEach(pool) { m in
            DraftPoolRow(name: m.name, idx: DraftCopy.idx(m.profile?.index_current), allowed: mine) {
              guard mine else { toast.show(DraftCopy.notYourPick(captain)); return }
              pick(d, m, captainId: captainId, captain: captain)
            }
          }
        }
      } else if d == nil, !room.squads.isEmpty, !room.isPro {
        CSFine(DraftCopy.memberReadOnly)
      }
      if room.isPro && (d == nil || !done) { proAdmin(d) }
    }
  }

  /// `#draftAdmin` — Randomize order · Pick for captain · the log note; Undo when picks exist.
  private func proAdmin(_ d: DraftRow?) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(DraftCopy.proEyebrow).csEyebrow()
      HStack(spacing: 6) {
        RoomMini(DraftCopy.randomizeOrder, busy: board.busy) {
          if let d, d.current_pick > 0 { toast.show(DraftCopy.orderLocked); return }
          guard let s = room.season else { return }
          board.run(toast: toast, fail: nil) {
            _ = try await DraftService().startDraft(season: s.id, shuffle: true)
            toast.show(DraftCopy.orderRandomized)
            await reload()
          }
        }
        RoomMini(DraftCopy.pickForCaptain) { toast.show(DraftCopy.pickForToast) }
        if let d, d.current_pick > 0 {
          ArmedMini(DraftCopy.undoPick, armedLabel: "Sure? Undo it", busy: board.busy) {
            board.run(toast: toast, fail: nil) { try await DraftService().undoPick(draft: d.id); await reload() }
          }
        }
      }
      CSFine(DraftCopy.proNote)
    }
    .padding(.top, 4)
  }

  private func pick(_ d: DraftRow, _ m: LeagueRoom.Member, captainId: UUID?, captain: String) {
    let override = room.isPro && captainId != room.myMember?.id
    board.run(toast: toast, fail: nil) {
      try await DraftService().makePick(draft: d.id, member: m.id)
      CSHaptic.impact(.medium)
      toast.show(override ? DraftCopy.proPicked(m.name, for: captain) : DraftCopy.drafted(captain, m.name, CSCopy.index(m.profile?.index_current)))
      await reload()
    }
  }
}

/// The draft night's own state: the `drafts` row and its picks, the assign
/// selection (`CS.sel`), the in-flight flag, and the channel.
@MainActor
@Observable
final class DraftBoardModel {
  var draft: DraftRow?
  var picks: [DraftPickRow] = []
  var selected: UUID?
  var busy = false
  private let svc = DraftService()
  private let rt = DraftRealtime()

  func attach(room: LeagueRoomModel) async {
    await reload(room: room)
    guard let s = room.season else { return }
    rt.onChange = { [weak self, weak room] in
      guard let self, let room else { return }
      Task { await room.refresh(); await self.reload(room: room) }
    }
    await rt.start(leagueId: room.leagueId, seasonId: s.id)
  }

  func detach() async { await rt.stop() }

  func reload(room: LeagueRoomModel) async {
    guard let s = room.season, ["snake", "live"].contains(room.bylaws.draftType) else { draft = nil; picks = []; return }
    draft = try? await svc.draft(season: s.id)
    picks = draft == nil ? [] : ((try? await svc.picks(draft: draft!.id)) ?? [])
  }

  /// One in-flight action at a time; the server's text is the error copy.
  func run(toast: CSToastCenter, fail: String?, _ op: @escaping @MainActor () async throws -> Void) {
    guard !busy else { return }
    busy = true
    Task {
      defer { busy = false }
      do { try await op() } catch { toast.show(roomError(error, fail)) }
    }
  }
}
