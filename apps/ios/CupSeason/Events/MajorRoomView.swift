// Cup Season — THE MAJOR'S ROOM, re-clothed in Wave 6 (surfaces/event.md §6.1).
//
// Same title card as the Ryder. The eyebrow is `MajorMath.statusChip`, which
// D252 already made plain English and which needs no rewording. Section B
// becomes **two cells** — the leading gross and the days left — and the board
// below is a real leaderboard, so it DOES take `CSSlat` and the 44pt rank rail:
// `POS · face · name/sub · CARDS · NET`, the net in `figure` right-flush.
//
// WHAT WENT: the `CSCard` head with a 🏆 at `.system(size: 34)` (an emoji
// carrying the surface's meaning — `LINT-12`), the three gold tracked-mono card
// lines under it, the `EventFineCard` paragraph in a bordered `bg2` tile, and
// the bordered `bg1` board rows with a `#3` in mono where the rank rail goes.
//
// **A LIVE MAJOR'S LEADER TAKES NO GOLD** (D-6). §9.1 paints the rail gold
// "when the position was earned"; on a live window nothing is earned yet, so
// every rail is unpainted (bone for yours) while play is open and the champion's
// paints gold at `complete`, when the jug has a name and the pot is paid.
//
// `MajorJugCard.swift` KEEPS its 1080 × 1350 share artifact. §6.1's "MajorJugCard
// is deleted" is about the JUG CARD IN THE ROOM — the emoji tile above — and
// deleting the share export, which no part of this design replaces, would remove
// a shipped feature to satisfy a sentence about a head.

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
  let back: () -> Void
  @State private var invite = false
  @State private var scrapArmed = false
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
    let live = ev.isLive && !f.complete

    // ---- A · the title card -------------------------------------------------
    EventTitleCard(eyebrow: MajorMath.statusChip(room, f), live: live,
                   title: ev.name,
                   dateline: dateline(f),
                   seed: ev.course_id ?? ev.course_label,
                   back: back) {
      if !room.majorBoard.isEmpty {
        CSFaceRow(room.majorBoard.prefix(4).map { face($0) }, style: .roster,
                  names: room.majorBoard.prefix(4).map { CSBands.fn1($0.displayName) })
      }
    }

    // ---- B · two cells on one rule -----------------------------------------
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      CSScoreRail(cells(f), size: .l, metal: live ? .live : .ink)
      if let pot = potFigure(f) {
        A11yStack(rowAlignment: .firstTextBaseline, spacing: CSTokens.Space.s2, columnSpacing: CSTokens.Space.s1) {
          Text(pot).csType(.figureS).foregroundStyle(f.complete ? cs.ink : cs.gold)
          Text(MajorMath.money(f.buyIn) + " each · " + (ev.pot_split == "wta" ? "winner takes all" : "60/25/15"))
            .csType(.agate, caps: true).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
        }
        .csBudget(gold: f.complete ? 0 : 1)
        .accessibilityElement(children: .combine)
      }
      // D61 · the annual voice — chain position and the defender.
      if let line = MajorMath.lineageLine(lineage: room.lineage, eventId: ev.id, complete: f.complete) {
        Text(line).csType(.bodyS).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true)
      }
      primary(f)
    }
    .csGutter()
    .padding(.top, CSTokens.Space.s4)

    // ---- the board ---------------------------------------------------------
    board(f, byPlayer: byPlayer)

    // D61 · the champions roll — the page the crew reads out loud every year
    let priors = MajorMath.priors(lineage: room.lineage, eventId: ev.id)
    if !priors.isEmpty {
      CSSectionHead("The champions roll", count: "\(priors.count)").csGutter()
      ForEach(priors) { r in
        CSSlat(rank: 0, field: .none, face: nil, name: r.champion ?? "—",
               sub: [r.year.map(String.init), r.champGross.map { "\($0)" },
                     r.champPvi.map { MajorMath.vs($0).lowercased() },
                     r.eventId == priors.last?.eventId ? "defending" : nil]
                 .compactMap { $0 }.joined(separator: " · "),
               movement: nil, gap: nil, railHidesNumeral: true) { EmptyView() }
      }
    }

    // the fine print — chosen, not discovered (D45), on the page's own ground
    EventFinePrint(text: MajorMath.finePrint(buyIn: f.buyIn, potSplit: ev.pot_split))
      .csGutter().padding(.top, CSTokens.Space.s4)

    if !room.posts.isEmpty {
      CSSectionHead("The board", count: "\(room.posts.count)").csGutter()
      ForEach(room.posts) { p in
        SystemRow(text: BoardText.easeCaps(p.body ?? "", names: model.names)).csGutter()
      }
    }

    organiserHands(f)

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

  // MARK: the head

  private func dateline(_ f: MajorMath.Facts) -> [String] {
    var lines: [String] = []
    if let place = room.event.course_label, !place.isEmpty { lines.append(place) }
    var second: [String] = []
    if let s = f.session {
      second.append(EventDates.windowSpaced(s.opens_on, s.closes_on))
    }
    if f.field > 0 { second.append("\(RyderMath.spelled(f.field)) playing") }
    if !second.isEmpty { lines.append(second.joined(separator: " · ")) }
    return lines
  }

  private func face(_ r: MajorBoardRow) -> CSFace.Model {
    CSFace.Model(id: r.profileId ?? r.playerId, marker: r.marker,
                 initials: Initials.of(r.displayName), isViewer: r.profileId != nil && r.profileId == me)
  }

  /// **Two cells** — the leading card and the clock.
  private func cells(_ f: MajorMath.Facts) -> [CSScoreRail.Cell] {
    let contenders = room.majorBoard.filter { !$0.exhibition && $0.pvi != nil }
      .sorted { ($0.pvi ?? -99) > ($1.pvi ?? -99) }
    var out: [CSScoreRail.Cell] = []
    if let leader = contenders.first, let g = leader.gross {
      out.append(.init(id: "lead", value: String(g), label: "\(CSBands.fn1(leader.displayName)) leads",
                       spoken: "\(leader.displayName) leads on \(g), \(MajorMath.vs(leader.pvi).lowercased())"))
    } else {
      out.append(.init(id: "cards", value: String(room.majorBoard.filter { $0.pvi != nil }.count),
                       label: "Cards in", spoken: "No card leads yet"))
    }
    if !f.complete, let d = f.daysLeft, d >= 0 {
      out.append(.init(id: "clock", value: String(d), label: d == 0 ? "The final day" : "Days left",
                       labelLive: true, spoken: d == 0 ? "The final day" : "\(d) days left"))
    }
    return out
  }

  private func potFigure(_ f: MajorMath.Facts) -> String? {
    f.pot > 0 ? MajorMath.money(f.pot) : nil
  }

  // MARK: the one primary

  @ViewBuilder private func primary(_ f: MajorMath.Facts) -> some View {
    let mine = room.majorBoard.contains { $0.profileId == me }
    if f.complete {
      CSDoor(.secondary("Run it back", { runBack = MajorPrefill(room, me: me) }))
    } else if !mine && inLeague && !f.horn && me != nil {
      CSDoor(.primary(EventCopy.joinVerb, {
        act(fail: nil, ok: "You’re in") { try await model.enter(); await store.reload() }
      }))
    } else if mine && room.event.isLive {
      CSDoor(.primary("Add my round", { links.addRound() }))
    } else if iAmOrg && room.event.isSetup {
      CSDoor(.primary("Invite golfers", { invite = true }))
    }
  }

  // MARK: the board — slats, and the rank rail

  @ViewBuilder private func board(_ f: MajorMath.Facts, byPlayer: [UUID: MajorBoardRow]) -> some View {
    if f.complete && !room.majorCards.isEmpty {
      let ranked = room.majorCards.filter { $0.rank != nil }.sorted { ($0.rank ?? 0) < ($1.rank ?? 0) }
      CSSectionHead("Final", count: "\(ranked.count)", trailing: nil).csGutter()
      boardHead
      ForEach(ranked) { c in
        let r = byPlayer[c.player_id]
        slat(rank: c.rank ?? 0, row: r, gross: c.gross, cards: c.cards ?? 0, pvi: c.pvi,
             prize: c.prize, round: c.round_id, champion: c.rank == 1, exhibition: false)
      }
      let ex = room.majorCards.filter { $0.rank == nil && $0.no_card != true }
        .sorted { ($0.pvi ?? -99) > ($1.pvi ?? -99) }
      if !ex.isEmpty {
        CSSectionHead("Doesn’t count this year", count: "\(ex.count)").csGutter()
        ForEach(ex) { c in
          slat(rank: 0, row: byPlayer[c.player_id], gross: c.gross, cards: c.cards ?? 0,
               pvi: c.pvi, prize: nil, round: c.round_id, champion: false, exhibition: true)
        }
      }
      let nc = room.majorCards.filter { $0.no_card == true }
      if !nc.isEmpty {
        CSSectionHead("No card", count: "\(nc.count)").csGutter()
        ForEach(nc) { c in
          slat(rank: 0, row: byPlayer[c.player_id], gross: nil, cards: 0, pvi: nil,
               prize: nil, round: nil, champion: false, exhibition: c.exhibition == true)
        }
      }
      if let champ = f.champion, let card = f.championCard {
        MajorShareButton(data: MajorShareData(room: room, champ: champ, card: card, when: f.when,
                                              pot: f.pot > 0 ? MajorMath.money(f.pot) : nil))
          .csGutter().padding(.top, CSTokens.Space.s4)
      }
    } else {
      let carded = room.majorBoard.filter { $0.pvi != nil }
      let waiting = room.majorBoard.filter { $0.pvi == nil }
      let contenders = carded.filter { !$0.exhibition }
      CSSectionHead("Leaderboard", count: room.event.isLive ? "Live" : nil).csGutter()
      if carded.isEmpty {
        CSEmpty(glyph: .emptyRail, eyebrow: "The window",
                headline: MajorMath.noCardsLine(live: room.event.isLive),
                fact: "Your best 18-hole card inside the window is your score.",
                door: room.event.isLive ? .primary("Add my round", { links.addRound() })
                                        : .elsewhere("The window opens when the organiser says so."))
          .csGutter()
      } else {
        boardHead
        ForEach(carded) { r in
          let pos = r.exhibition ? 0 : (contenders.firstIndex { $0.playerId == r.playerId } ?? 0) + 1
          slat(rank: pos, row: r, gross: r.gross, cards: r.cards, pvi: r.pvi, prize: nil,
               round: r.roundId, champion: false, exhibition: r.exhibition)
        }
      }
      if !waiting.isEmpty {
        CSSectionHead("Still to post", count: "\(waiting.count)").csGutter()
        ForEach(waiting) { r in
          slat(rank: 0, row: r, gross: nil, cards: 0, pvi: nil, prize: nil, round: nil,
               champion: false, exhibition: r.exhibition)
        }
        if room.event.isLive, let d = f.daysLeft, d >= 0 {
          Text(MajorMath.stillToPost(waiting.map(\.displayName), daysLeft: d))
            .csType(.bodyS).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
            .csGutter().padding(.top, CSTokens.Space.s3)
        }
      }
    }
  }

  /// The header row at EVERY field size — the single most confusing element a
  /// blind reviewer named was an unlabelled trailing column.
  private var boardHead: some View {
    HStack(spacing: 0) {
      Text("Pos").csType(.agateS, caps: true).foregroundStyle(cs.mut)
        .frame(width: CSTokens.Space.rail, alignment: .center)
      // the name column starts after the rail, the face and the gap — the head
      // sits over the column it names or it is not a head
      Text("Golfer").csType(.agateS, caps: true).foregroundStyle(cs.mut)
        .padding(.leading, CSFace.Size.slat.rawValue + CSSlatMetrics.railGap)
        .frame(maxWidth: .infinity, alignment: .leading)
      Text("Cards").csType(.agateS, caps: true).foregroundStyle(cs.mut)
        .frame(width: CSSlatMetrics.changeWidth, alignment: .trailing)
      Text("Net").csType(.agateS, caps: true).foregroundStyle(cs.mut)
        .frame(width: CSSlatMetrics.trailingWidth, alignment: .trailing)
    }
    .padding(.trailing, CSTokens.Space.gutter)
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityHidden(true)
  }

  @ViewBuilder private func slat(rank: Int, row: MajorBoardRow?, gross: Int?, cards: Int, pvi: Double?,
                                 prize: Double?, round: UUID?, champion: Bool, exhibition: Bool) -> some View {
    let name = row?.displayName ?? "—"
    let sub = [gross.map { "\($0) gross" },
               cards > 0 ? "\(cards) card\(cards == 1 ? "" : "s")" : nil,
               prize.flatMap { $0 > 0 ? MajorMath.money($0) : nil },
               exhibition ? "exhibition" : nil,
               gross == nil ? "the window is open" : nil]
      .compactMap { $0 }.joined(separator: " · ")
    Button {
      if let round { links.openReceipt(round) }
      else if let p = row?.profileId { links.openTourCard(p) }
    } label: {
      CSSlat(rank: rank, field: champion ? .earned : (row?.profileId == me ? .mine : .none),
             face: row.map { face($0) }, name: name, sub: sub,
             movement: nil, gap: cards > 0 ? String(cards) : nil,
             variant: champion ? .leader : .table, railHidesNumeral: rank == 0) {
        VStack(alignment: .trailing, spacing: CSTokens.Space.s1) {
          if champion { CSSlot("The jug") }
          if let pvi {
            Text(RoundCopy.signed(pvi)).csType(.figureS).foregroundStyle(cs.ink)
          }
        }
      }
    }
    .buttonStyle(.plain)
    .csBudget(gold: champion ? 1 : 0)
  }

  // MARK: the organiser's hands, at the foot

  @ViewBuilder private func organiserHands(_ f: MajorMath.Facts) -> some View {
    if iAmOrg && !f.complete {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        CSDoor(.link("Invite golfers", { invite = true }))
        if room.event.isSetup, let s = f.session, !f.opensAhead {
          if room.majorBoard.count >= 2 {
            CSDoor(.link("Open the window now", {
              act(fail: nil, ok: "The window is open") { try await model.openWindow(session: s.id) }
            }))
          } else {
            Text("Needs 2 playing to open.").csType(.bodyS).foregroundStyle(cs.mut)
          }
        }
        if room.event.isLive, let s = f.session, let d = f.daysLeft, d < 0 {
          CSDoor(.link("Settle it — name the champion", {
            act(fail: nil, ok: "Settled — the jug has a name") { try await model.settle(session: s.id) }
          }))
        }
        if !f.horn {
          CSArmedButton(label: "Scrap", armedLabel: "Sure? Scrap it", busy: model.isBusy("scrap"),
                        onArm: { scrapArmed = $0 }) { scrap() }
          if scrapArmed {
            Text(RyderMath.scrapQuestion(room.event.name)).csType(.bodyS).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true).transition(.opacity)
          }
        }
      }
      .csGutter()
      .padding(.top, CSTokens.Space.s4)
    }
  }

  private func act(fail: String?, ok: String?, _ op: @escaping @MainActor () async throws -> Void) {
    Task {
      do { try await op(); if let ok { toast.show(ok) } }
      catch { toast.show(BoardText.humanError(error, fail), kind: .failed) }
    }
  }

  private func scrap() {
    let name = room.event.name
    Task {
      do {
        try await model.scrap()
        toast.show("\(name) scrapped", kind: .confirmed)
        await store.reload()
        dismiss()
      } catch { toast.show(BoardText.humanError(error), kind: .failed) }
    }
  }
}
