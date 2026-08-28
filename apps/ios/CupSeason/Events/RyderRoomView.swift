// Cup Season — the Ryder room (`renderEvent` 12197–12356): the scoreboard
// `A 6½ – 4½ B`, the clinch line, the series line (D62), the rule sentence,
// the taunt toggle, the organizer's hands, the sessions with the number to
// beat (C10), the rosters with W-L-H, the event board.

import SwiftUI
import CSDesign
import CupSeasonKit

struct RyderRoomView: View {
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  @Environment(\.dismiss) private var dismiss
  @Environment(SessionStore.self) private var store
  let model: EventRoomModel
  let room: EventRoom
  let links: EventLinks
  @State private var invite = false
  @State private var scrapArmed = false
  @State private var runBack: RyderPrefill?

  private var me: UUID? { store.session?.user.id }
  private var iAmOrg: Bool { room.isOrganizer(me) }
  private var A: EventTeam { room.teamA }
  private var B: EventTeam { room.teamB }

  var body: some View {
    let target = RyderMath.target(room)
    let aP = room.points(A.id), bP = room.points(B.id)

    EventHeaderRow(name: room.event.name, chip: RyderMath.statusChip(room))

    // the scoreboard card
    CSCard(padding: 16) {
      VStack(spacing: 10) {
        HStack(alignment: .center, spacing: 14) {
          HStack(spacing: 8) {
            EventTeamSwatch(colorIndex: A.colorIndex)
            Text(A.name).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink).lineLimit(1)
          }
          .frame(maxWidth: .infinity, alignment: .trailing)
          HStack(spacing: 6) {
            Text(RyderMath.evHalf(aP)).font(CSFont.stat).csTabular().foregroundStyle(cs.ink)
            Text("–").font(CSFont.stat).foregroundStyle(cs.dimText)
            Text(RyderMath.evHalf(bP)).font(CSFont.stat).csTabular().foregroundStyle(cs.ink)
          }
          .fixedSize()
          HStack(spacing: 8) {
            Text(B.name).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink).lineLimit(1)
            EventTeamSwatch(colorIndex: B.colorIndex)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        Text(RyderMath.clinchLine(room)).font(CSFont.label).tracking(1.0).foregroundStyle(cs.mut)
          .multilineTextAlignment(.center)
      }
      .frame(maxWidth: .infinity)
    }
    .accessibilityElement(children: .combine)

    // D62: the series line — editions counted, the cup defended
    if let series = RyderMath.seriesLine(lineage: room.lineage, eventId: room.event.id, status: room.event.status, aName: A.name, bName: B.name) {
      Text(series).font(CSFont.label).tracking(0.8).foregroundStyle(cs.gold)
        .frame(maxWidth: .infinity).multilineTextAlignment(.center)
    }
    if room.event.isComplete {
      // D62: the rematch tap — benches re-invited, series line follows
      CSButton("Run it back — next year's benches", style: .quiet) { runBack = RyderPrefill(room, me: me) }
    }

    // how it scores — everyone sees the rule, not just the organizer
    RoomFine(RyderMath.ruleSentence(target))

    // the opt-in taunt (batch-3 #17): a standing target push must be CHOSEN
    if let meP = room.me(me), !room.event.isComplete {
      CSMini(RyderMath.tauntLabel(on: meP.notifyTarget), busy: model.isBusy("notify")) {
        let on = !meP.notifyTarget
        act(fail: nil, ok: RyderMath.tauntToast(on: on)) { try await model.notify(on: on) }
      }
    }

    // organizer controls — the event's creator runs the roster + sessions
    if iAmOrg {
      HStack(spacing: 8) {
        CSMini("Invite players", systemImage: "plus") { invite = true }
        if !room.event.isComplete && !room.anyClosed {
          CSArmedButton(label: "Scrap", armedLabel: "Sure? Scrap it", busy: model.isBusy("scrap"), onArm: { scrapArmed = $0 }) { scrap() }
        }
      }
      // the web's confirm() sentence (16265) rides the arm
      if scrapArmed { CSFine(RyderMath.scrapQuestion(room.event.name)).transition(.opacity) }
      let unassigned = room.unassigned
      if !unassigned.isEmpty {
        Text("Unassigned").csEyebrow().padding(.top, 4)
        ForEach(unassigned) { p in
          CSCheckRow(marker: p.marker, title: Text(p.name), sub: nil) {
            HStack(spacing: 6) {
              CSMini("→ \(A.name)", busy: model.isBusy("assign-\(p.id)")) { assign(p, to: A) }
              CSMini("→ \(B.name)", busy: model.isBusy("assign-\(p.id)")) { assign(p, to: B) }
            }
          }
        }
      }
    }

    // sessions — S5-02 order
    ForEach(RyderMath.ordered(room.sessions)) { s in session(s) }

    // rosters with each player's duel record
    ForEach([A, B]) { t in
      HStack(spacing: 6) {
        EventTeamSwatch(colorIndex: t.colorIndex)
        Text(t.name).csEyebrow()
      }
      .padding(.top, 6)
      let roster = room.roster(t.id)
      if roster.isEmpty {
        CSFine("No one assigned yet.")
      } else {
        ForEach(roster) { p in
          CSCheckRow(marker: p.marker, title: rosterTitle(p), sub: Text("\(RyderMath.record(of: p.id, duels: room.duels)) · W-L-H")) {
            EmptyView()
          }
          .contentShape(Rectangle())
          .onTapGesture { if let pid = p.profileId { links.openTourCard(pid) } }
        }
      }
    }

    // the event board: the engine's story — pairings, results, the cup
    if !room.posts.isEmpty {
      Text("The board").csEyebrow().padding(.top, 8)
      ForEach(room.posts) { p in SystemRow(text: BoardText.easeCaps(p.body ?? "", names: model.names)) }
    }

    Color.clear.frame(height: 0)
      .sheet(isPresented: $invite) {
        PeoplePickerSheet(mode: .invite(.event(room.event.id), excludeIds: Set(room.players.compactMap(\.profileId))),
                          title: "Add golfers", sub: "Invited golfers get a notification and choose to join",
                          onDone: { Task { await model.load() } })
      }
      .sheet(item: $runBack) { pf in
        RyderSetupSheet(leagueId: pf.league, prefill: pf) { id in links.openEvent(id) }
      }
  }

  // MARK: sessions

  @ViewBuilder private func session(_ s: EventSession) -> some View {
    let ds = room.duels(in: s.id)
    // the chip and the nag list, computed once per duel
    let rows: [(duel: EventDuel, a: EventPlayer, b: EventPlayer, chip: RyderMath.DuelChip)] = ds.map { d in
      let a = room.player(d.a_player), b = room.player(d.b_player)
      return (d, a, b, RyderMath.chip(d, sessionOpen: s.isOpen, target: room.targets[d.id], aName: a.name, bName: b.name))
    }
    let waiting = rows.flatMap { $0.chip.waiting }
    VStack(alignment: .leading, spacing: 6) {
      Text(RyderMath.sessionHeader(s)).font(CSFont.label).tracking(1.0).foregroundStyle(cs.dimText)
      if ds.isEmpty { CSFine("Pairings not set.") }
      ForEach(rows, id: \.duel.id) { r in
        duelRow(r.duel, a: r.a, b: r.b, chip: r.chip.text)
      }
      if s.isOpen, let nag = RyderMath.nagLine(waiting: waiting, closesOn: s.closes_on) {
        CSFine(nag).padding(.top, 2)
      }
      if iAmOrg {
        if ds.isEmpty {
          CSMini("Generate pairings", busy: model.isBusy("pair-\(s.id)")) { pair(s) }
        } else if !s.isClosed {
          CSMini("Score this session", busy: model.isBusy("resolve-\(s.id)")) {
            act(fail: "Score failed.", ok: "Session scored") { try await model.resolve(session: s.id) }
          }
        }
      }
    }
    .padding(.top, 8)
  }

  private func duelRow(_ d: EventDuel, a: EventPlayer, b: EventPlayer, chip: String?) -> some View {
    let aw = d.result == "a", bw = d.result == "b", hv = d.result == "halve"
    return HStack(spacing: 8) {
      HStack(spacing: 4) {
        CSMarkerView(key: a.marker, size: 14).foregroundStyle(cs.ink)
        Text(a.name).font(aw ? CSFont.footnote.weight(.bold) : CSFont.footnote).foregroundStyle(cs.ink).lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      Text(RyderMath.mid(d.result)).font(CSFont.label).tracking(0.6)
        .foregroundStyle(hv ? cs.gold : cs.dimText).fontWeight(hv ? .bold : .regular).fixedSize()
      HStack(spacing: 4) {
        Text(b.name).font(bw ? CSFont.footnote.weight(.bold) : CSFont.footnote).foregroundStyle(cs.ink).lineLimit(1)
        CSMarkerView(key: b.marker, size: 14).foregroundStyle(cs.ink)
      }
      .frame(maxWidth: .infinity, alignment: .trailing)
      if let chip {
        let rose = model.risen.contains(d.id)
        Text(chip).font(CSFont.label).csTabular().foregroundStyle(rose ? cs.warm : cs.mut).fixedSize()
          .eventRise(rose)
          .id("\(d.id)-\(chip)")
      }
    }
    .padding(.horizontal, 10).padding(.vertical, 8)
    .frame(minHeight: 44)
    .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(cs.line, lineWidth: 1))
    .accessibilityElement(children: .combine)
  }

  private func rosterTitle(_ p: EventPlayer) -> Text {
    p.isCaptain ? Text(p.name) + Text(" · ") + Text("CAPTAIN").foregroundStyle(cs.gold) : Text(p.name)
  }

  // MARK: hands

  private func act(fail: String?, ok: String?, _ op: @escaping @MainActor () async throws -> Void) {
    Task {
      do { try await op(); if let ok { toast.show(ok) } }
      catch { toast.show(BoardText.humanError(error, fail)) }
    }
  }

  private func assign(_ p: EventPlayer, to t: EventTeam) {
    act(fail: nil, ok: nil) { try await model.assign(player: p.id, team: t.id) }
  }

  private func pair(_ s: EventSession) {
    Task {
      do { let n = try await model.pair(session: s.id); toast.show(RyderMath.pairingsToast(n)) }
      catch { toast.show(BoardText.humanError(error, "Pairing failed.")) }
    }
  }

  private func scrap() {
    let name = room.event.name
    Task {
      do {
        try await model.scrap()
        toast.show("\(name) scrapped")
        await store.reload()
        dismiss()
      } catch { toast.show(BoardText.humanError(error)) }
    }
  }
}
