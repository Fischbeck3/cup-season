// Cup Season — the Major's championship room (`renderMajorRoom` 12374–12529,
// D42–D46, gameplay-modes §10). One window, the whole field on one board,
// best 18-hole card vs your own number. Speaks UNDER/OVER in words; every
// figure taps to its round (§16). Exhibition rows are on the board and never
// paid (D44).

import SwiftUI
import CSDesign
import CupSeasonKit

struct MajorRoomView: View {
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  @Environment(\.dismiss) private var dismiss
  @Environment(SessionStore.self) private var store
  let model: EventRoomModel
  let room: EventRoom
  let links: EventLinks
  @State private var invite = false
  @State private var runBack: MajorPrefill?

  private var me: UUID? { store.session?.user.id }
  private var iAmOrg: Bool { room.isOrganizer(me) }
  private var inLeague: Bool {
    guard let lid = room.event.league_id else { return false }
    return store.me?.memberships.contains { $0.league_id == lid } ?? false
  }

  var body: some View {
    let f = MajorMath.facts(room)
    let ev = room.event
    let byPlayer = Dictionary(room.majorBoard.map { ($0.playerId, $0) }, uniquingKeysWith: { a, _ in a })

    EventHeaderRow(name: ev.name, chip: MajorMath.statusChip(room, f))

    // the card
    CSCard(padding: 16) {
      VStack(spacing: 4) {
        Text("🏆").font(.system(size: 34))
        let lines = MajorMath.cardLines(days: f.days, when: f.when, field: f.field, contenders: f.contenders, buyIn: f.buyIn, pot: f.pot, potSplit: ev.pot_split)
        Text(lines[0]).font(CSFont.monoSmall).tracking(1.8).foregroundStyle(cs.gold).padding(.top, 2)
        Text(lines[1]).font(CSFont.footnote).foregroundStyle(cs.dimText).padding(.top, 2)
        Text(lines[2]).font(CSFont.footnote).foregroundStyle(cs.dimText)
      }
      .frame(maxWidth: .infinity).multilineTextAlignment(.center)
    }
    .accessibilityElement(children: .combine)

    // D61: the annual voice — chain position + the defender, rematch-linked only
    if let line = MajorMath.lineageLine(lineage: room.lineage, eventId: ev.id, complete: f.complete) {
      Text(line).font(CSFont.label).tracking(0.8).foregroundStyle(cs.gold).frame(maxWidth: .infinity).multilineTextAlignment(.center)
    }

    RoomFine("Your best 18-hole card inside the window, scored against your own number. Post as many as the weekend allows — the best one stands.")

    // enter / organizer controls
    let mine = room.majorBoard.contains { $0.profileId == me }
    if !mine && inLeague && !f.complete && !f.horn && me != nil {
      CSButton("Enter the field", busy: model.isBusy("enter")) {
        act(fail: nil, ok: "You're in the field") { try await model.enter(); await store.reload() }
      }
    }
    if iAmOrg && !f.complete {
      FlowLayout(spacing: 8) {
        CSMini("Invite golfers", systemImage: "plus") { invite = true }
        if ev.isSetup, let s = f.session, !f.opensAhead {
          if room.majorBoard.count >= 2 {
            CSMini("Open the window now", busy: model.isBusy("open")) {
              act(fail: nil, ok: "The window is open") { try await model.openWindow(session: s.id) }
            }
          } else {
            CSFine("Needs 2 in the field to open.")
          }
        }
        if ev.isLive, let s = f.session, let d = f.daysLeft, d < 0 {
          CSMini("Sound the horn — settle", busy: model.isBusy("settle")) {
            act(fail: nil, ok: "Settled — the jug has a name") { try await model.settle(session: s.id) }
          }
        }
        // escape hatch: only while nothing has been scored (the RPC re-validates)
        if !f.horn {
          CSArmedButton(label: "Scrap", armedLabel: "Sure? Scrap it", busy: model.isBusy("scrap")) { scrap() }
        }
      }
    }

    // ---- the leaderboard ----
    if f.complete && !room.majorCards.isEmpty {
      Text("Final — every card counts").csEyebrow().padding(.top, 4)
      let ranked = room.majorCards.filter { $0.rank != nil }.sorted { ($0.rank ?? 0) < ($1.rank ?? 0) }
      ForEach(ranked) { c in
        let r = byPlayer[c.player_id]
        boardRow(pos: c.rank == 1 ? "🏆" : "#\(c.rank ?? 0)", name: r?.displayName ?? "—", marker: r?.marker ?? "saguaro", profile: r?.profileId,
                 line: MajorMath.cardsLine(gross: c.gross, cards: c.cards ?? 0, prize: c.prize), pvi: c.pvi, round: c.round_id)
      }
      let ex = room.majorCards.filter { $0.rank == nil && $0.no_card != true }.sorted { ($0.pvi ?? -99) > ($1.pvi ?? -99) }
      if !ex.isEmpty {
        Text("Exhibition — official by the next one").csEyebrow().padding(.top, 4)
        ForEach(ex) { c in
          let r = byPlayer[c.player_id]
          boardRow(pos: "EX", name: r?.displayName ?? "—", marker: r?.marker ?? "saguaro", profile: r?.profileId,
                   line: MajorMath.cardsLine(gross: c.gross, cards: c.cards ?? 0), pvi: c.pvi, round: c.round_id)
        }
      }
      let nc = room.majorCards.filter { $0.no_card == true }
      if !nc.isEmpty {
        Text("No card").csEyebrow().padding(.top, 4)
        ForEach(nc) { c in
          let r = byPlayer[c.player_id]
          boardRow(pos: "—", name: r?.displayName ?? "—", marker: r?.marker ?? "saguaro", profile: r?.profileId,
                   line: f.buyIn > 0 && c.exhibition != true ? "No card · buy-in stays in the pot" : "No card this time", pvi: nil, round: nil)
        }
      }
      if let champ = f.champion, let card = f.championCard {
        MajorShareButton(data: MajorShareData(room: room, champ: champ, card: card, when: f.when, pot: f.pot > 0 ? MajorMath.money(f.pot) : nil))
          .padding(.top, 8)
      }
      // D61: the rematch tap — the only door into a lineage
      CSButton("Run it back — same jug, next year", style: .quiet) { runBack = MajorPrefill(room, me: me) }
    } else {
      Text("The clubhouse\(ev.isLive ? " — live" : "")").csEyebrow().padding(.top, 4)
      let carded = room.majorBoard.filter { $0.pvi != nil }
      let waiting = room.majorBoard.filter { $0.pvi == nil }
      let contenders = carded.filter { !$0.exhibition }
      ForEach(carded) { r in
        let pos = r.exhibition ? "EX" : "#\((contenders.firstIndex { $0.playerId == r.playerId } ?? 0) + 1)"
        boardRow(pos: pos, name: r.displayName, marker: r.marker, profile: r.profileId,
                 line: MajorMath.cardsLine(gross: r.gross, cards: r.cards, exhibition: r.exhibition), pvi: r.pvi, round: r.roundId)
      }
      if carded.isEmpty { CSFine(MajorMath.noCardsLine(live: ev.isLive)) }
      if !waiting.isEmpty {
        Text("Yet to card").csEyebrow().padding(.top, 4)
        ForEach(waiting) { r in
          boardRow(pos: "—", name: r.displayName, marker: r.marker, profile: r.profileId,
                   line: r.exhibition ? "Exhibition — official by the next one" : "The window is open", pvi: nil, round: nil)
        }
      }
      if ev.isLive, !waiting.isEmpty, let d = f.daysLeft, d >= 0 {
        CSFine(MajorMath.stillToCard(waiting.map(\.displayName), daysLeft: d)).padding(.top, 2)
      }
    }

    // D61: the champions roll — the page the crew reads out loud every year
    let priors = MajorMath.priors(lineage: room.lineage, eventId: ev.id)
    if !priors.isEmpty {
      Text("The champions roll").csEyebrow().padding(.top, 8)
      ForEach(priors) { r in
        let sub = [r.champGross.map { "\($0)" }, r.champPvi.map { MajorMath.vs($0) }, r.eventId == priors.last?.eventId ? "DEFENDING" : nil]
          .compactMap { $0 }.joined(separator: " · ")
        HStack(spacing: 12) {
          Text(r.year.map { String($0) } ?? "—").font(CSFont.label).foregroundStyle(cs.dimText).frame(width: 40, alignment: .center)
          VStack(alignment: .leading, spacing: 3) {
            Text(r.champion ?? "—").font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
            if !sub.isEmpty { Text(sub).font(CSFont.monoSmall).foregroundStyle(cs.mut) }
          }
          Spacer()
        }
        .padding(.vertical, 8).padding(.horizontal, 12).frame(minHeight: 52)
        .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line, lineWidth: 1))
      }
    }

    // the fine print — chosen, not discovered (D45)
    EventFineCard(markdown: MajorMath.finePrint(buyIn: f.buyIn, potSplit: ev.pot_split)
      .replacingOccurrences(of: "The fine print.", with: "**The fine print.**")
      .replacingOccurrences(of: "your own number", with: "*your own* number")
      .replacingOccurrences(of: "play exhibition", with: "play **exhibition**"))
      .padding(.top, 8)

    // the event board: the window narrating itself
    if !room.posts.isEmpty {
      Text("The board").csEyebrow().padding(.top, 8)
      ForEach(room.posts) { p in SystemRow(text: BoardText.easeCaps(p.body ?? "", names: model.names)) }
    }

    Color.clear.frame(height: 0)
      .sheet(isPresented: $invite) {
        PeoplePickerSheet(mode: .invite(.event(ev.id), excludeIds: Set(room.players.compactMap(\.profileId))),
                          title: "Add golfers", sub: "Invited golfers get a notification and choose to join",
                          onDone: { Task { await model.load() } })
      }
      .sheet(item: $runBack) { pf in
        MajorSetupSheet(leagueId: pf.league, prefill: pf) { id in links.openEvent(id) }
      }
  }

  /// `rowHtml(pos, r, extra, tap)` — position · marker + name · the line · UNDER/OVER.
  private func boardRow(pos: String, name: String, marker: String, profile: UUID?, line: String, pvi: Double?, round: UUID?) -> some View {
    let row = HStack(spacing: 12) {
      Text(pos).font(CSFont.monoSmall).foregroundStyle(pos == "🏆" ? cs.gold : cs.dimText).frame(minWidth: 26, alignment: .center)
      CSMarkerView(key: marker, size: 18).foregroundStyle(cs.ink)
      VStack(alignment: .leading, spacing: 3) {
        Text(name).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
        Text(line).font(CSFont.monoSmall).foregroundStyle(cs.mut)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      if let pvi {
        Text(MajorMath.vs(pvi)).font(CSFont.monoSmall).foregroundStyle(pvi > 0 ? cs.pos : cs.mut).fixedSize()
      }
    }
    .padding(.vertical, 8).padding(.horizontal, 12)
    .frame(minHeight: 52)
    .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line, lineWidth: 1))
    .contentShape(Rectangle())

    return Group {
      if let round {
        Button { links.openReceipt(round) } label: { row }.buttonStyle(.plain)
          .accessibilityHint("Opens the round receipt")
      } else if let profile {
        Button { links.openTourCard(profile) } label: { row }.buttonStyle(.plain)
      } else {
        row
      }
    }
  }

  private func act(fail: String?, ok: String?, _ op: @escaping @MainActor () async throws -> Void) {
    Task {
      do { try await op(); if let ok { toast.show(ok) } }
      catch { toast.show(BoardText.humanError(error, fail)) }
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
