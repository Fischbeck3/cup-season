// Cup Season — THE RYDER ROOM, rebuilt in Wave 6 as a title card.
//
// *Think tournament graphic, not database record.* One ceremony plate carrying
// the title, the dateline and the whole field; one rule-and-figure holding the
// score; a sentence; a stake; one primary; a week of clashes.
//
// WHAT WENT: the scoreboard `CSCard(padding:16)` with `A 6½ – 4½ B` inside a
// border, the 11pt tracked-mono clinch line under it, the duel rows in 9pt
// `RoundedRectangle().stroke(cs.line)` — box inside box inside box — the
// `CSMini` taunt, the `CSCheckRow` rosters, `cs.warm` on the risen chip, the
// `FlowRow` of four equally-loud minis, and the event name set as an eyebrow.
//
// **§15.5a IS THE POINT OF THIS FILE.** Two of three blind reviewers could not
// tell who was on which team, and one called it a failure at the surface's one
// job. The roster is two NAMED GROUPS under two squad rules, every disc ringed
// in its side's colour while keeping its own pigment and glyph — and the two
// squad names are the channel that hue cannot carry (`sq0` and `sq3` are
// 1.58:1 apart). The 14 × 4pt colour ticks that collided with the dateline are
// deleted, and so is the collision.
//
// **AND A COUNTDOWN IS NOT A SCORE.** `3½`, `2½` and `2 DAYS LEFT` sat under
// one rule as if they were one class of number. The rail is the two side
// scores; the deadline is in the live eyebrow with the other time facts.
//
// WHAT SURVIVES VERBATIM: every hand (`assign`, `pair`, `resolve`, `notify`,
// `scrap`), `RyderMath`'s arithmetic, C10's rise, `RyderPrefill`'s run-it-back
// path, the organiser gate and the taunt opt-in.

import SwiftUI
import CSDesign
import CupSeasonKit

struct RyderRoomView: View {
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  @Environment(\.dismiss) private var dismiss
  @Environment(\.dynamicTypeSize) private var typeSize
  @Environment(SessionStore.self) private var store
  let model: EventRoomModel
  let room: EventRoom
  let links: EventLinks
  let back: () -> Void
  @State private var invite = false
  @State private var scrapArmed = false
  @State private var runBack: RyderPrefill?

  private var me: UUID? { store.session?.user.id }
  private var iAmOrg: Bool { room.isOrganizer(me) }
  private var A: EventTeam { room.teamA }
  private var B: EventTeam { room.teamB }
  private var live: Bool { !room.event.isComplete && !room.event.isSetup }

  var body: some View {
    let target = RyderMath.target(room)
    let aP = room.points(A.id), bP = room.points(B.id)

    // ---- A · the title card -------------------------------------------------
    EventTitleCard(eyebrow: RyderMath.eyebrow(room), live: live,
                   title: room.event.name,
                   dateline: dateline,
                   seed: room.event.course_id ?? room.event.course_label,
                   back: back) {
      if room.players.isEmpty {
        Text("Nobody is in it yet.").csType(.bodyS).foregroundStyle(CSTokens.dark.ceremonyMut)
      } else {
        CSSideRoster(left: side(A), right: side(B))
      }
    }

    // ---- B · the score, on one rule ----------------------------------------
    Group {
      if room.event.isSetup {
        // §6.3 · forming has no score to show, so section B is the empty state
        // and the primary is **Invite players**. The title card is unchanged —
        // a forming event still gets its graphic, which is most of the reason
        // anyone joins one.
        CSEmpty(glyph: .emptyRail, eyebrow: "The field",
                headline: room.players.isEmpty ? "Nobody is in it yet." : "It hasn't teed off.",
                fact: "A Ryder needs two sides.",
                door: iAmOrg ? .primary("Invite golfers", { invite = true })
                             : .elsewhere("The organiser opens it when both sides are in."))
          .csGutter()
      } else {
        VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
          CSScoreRail(scoreCells(aP, bP), size: .l, metal: live ? .live : .ink)
          // C · the clinch sentence. The sentence is the story; the figures
          // above it are the record (§9.9).
          Text(RyderMath.clinchLine(room)).csType(.bodyS).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
          // D · the stakes line — the pot is the surface's ONE gold object, and
          // it is gold ink on a NUMERAL: never a fill, never a chip.
          if let pot = potFigure {
            A11yStack(rowAlignment: .firstTextBaseline, spacing: CSTokens.Space.s2, columnSpacing: CSTokens.Space.s1) {
              Text(pot).csType(.figureS).foregroundStyle(room.event.isComplete ? cs.ink : cs.gold)
              Text(RyderMath.stakesTail(potSplit: room.event.pot_split))
                .csType(.agate, caps: true).foregroundStyle(cs.mut)
                .fixedSize(horizontal: false, vertical: true)
            }
            .csBudget(gold: room.event.isComplete ? 0 : 1)
            .accessibilityElement(children: .combine)
          }
          // D62 · the series line — editions counted, the cup defended.
          if let series = RyderMath.seriesLine(lineage: room.lineage, eventId: room.event.id,
                                               status: room.event.status, aName: A.name, bName: B.name) {
            Text(series).csType(.bodyS).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        .csGutter()
      }
    }
    .padding(.top, CSTokens.Space.s4)


    // ---- E · the one primary -----------------------------------------------
    primary.csGutter().padding(.top, CSTokens.Space.s4)

    // ---- F/G/H · the weeks --------------------------------------------------
    ForEach(RyderMath.ordered(room.sessions)) { s in session(s) }

    // ---- below the fold ----------------------------------------------------
    rosters
    if !room.posts.isEmpty {
      CSSectionHead("The board", count: "\(room.posts.count)").csGutter()
      ForEach(room.posts) { p in
        SystemRow(text: BoardText.easeCaps(p.body ?? "", names: model.names)).csGutter()
      }
    }
    // how it scores — everyone sees the rule, not just the organiser
    EventFinePrint(text: RyderMath.ruleSentence(target)).csGutter().padding(.top, CSTokens.Space.s4)

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

  // MARK: the title card's parts

  private var dateline: [String] {
    var lines: [String] = []
    if let place = room.event.course_label, !place.isEmpty { lines.append(place) }
    let d = RyderMath.dateline(room)
    if !d.isEmpty { lines.append(d) }
    return lines
  }

  /// §15.5a · one side, as a named group. The disc keeps the golfer's own
  /// pigment and glyph; the RING is the side, and it exists only inside a team
  /// competition.
  private func side(_ t: EventTeam) -> CSSideRoster.Side {
    let roster = room.roster(t.id)
    return CSSideRoster.Side(
      id: t.id.uuidString,
      name: t.name,
      color: CSTokens.dark.ceremonySquad(t.colorIndex),
      faces: roster.map { face($0) },
      // **The viewer is `You`**, here and on every board in the product — the
      // one place a golfer is not called by their own name, because the row
      // they are IN is the row they are looking for.
      names: roster.map { $0.profileId != nil && $0.profileId == me ? "You" : CSBands.fn1($0.name) })
  }

  private func face(_ p: EventPlayer) -> CSFace.Model {
    CSFace.Model(id: p.profileId ?? p.id, marker: p.marker,
                 initials: Initials.of(p.name), isViewer: p.profileId != nil && p.profileId == me)
  }

  /// **Two cells, not three** (§15.5a finding 3). The clock left the rail.
  private func scoreCells(_ aP: Double, _ bP: Double) -> [CSScoreRail.Cell] {
    // §6.2 · **the winner's cell paints gold at `complete`, and the pot goes to
    // ink** — the pot has been paid and the RESULT is now the earned thing. One
    // gold object per viewport in both states, and "gold means earned" true
    // across time rather than only across space.
    let winner = room.event.isComplete ? room.event.winner_team_id : nil
    return [(A, aP), (B, bP)].map { t, points in
      let parts = RyderMath.evHalfParts(points)
      return CSScoreRail.Cell(id: t.id.uuidString,
                              value: parts.whole.isEmpty ? "0" : parts.whole,
                              half: parts.half,
                              label: t.name,
                              tick: cs.squadMark(t.colorIndex),
                              earned: winner == t.id,
                              spoken: "\(t.name), \(RyderMath.evHalf(points))")
    }
  }

  /// `$480`, or nothing at all. **A surface with no gold is a correct surface.**
  private var potFigure: String? {
    let buyIn = room.event.buy_in ?? 0
    guard buyIn > 0 else { return nil }
    return MajorMath.money(buyIn * Double(room.players.count))
  }

  // MARK: E · the one primary

  @ViewBuilder private var primary: some View {
    let myClash = openClashOfMine
    if room.event.isComplete {
      // **Nothing on a completed event is ember** — a completed event is not
      // live, which is the mechanism §2.4 describes rather than a taste call.
      CSDoor(.secondary("Run it back", { runBack = RyderPrefill(room, me: me) }))
    } else if room.event.isSetup {
      EmptyView()   // the empty state above carries the door
    } else if let d = myClash, d.posted {
      // your clash is already posted: the primary drops to a secondary and the
      // ember goes with it. The live dot stays — the WEEK is still live.
      CSDoor(.secondary("See the receipt", { if let r = d.round { links.openReceipt(r) } }))
    } else {
      CSDoor(.primary("Add my round", { links.addRound() }))
    }
  }

  /// My open clash this week, and whether I have posted in it.
  private var openClashOfMine: (posted: Bool, round: UUID?)? {
    guard let mine = room.me(me), let s = room.sessions.first(where: { $0.isOpen }) else { return nil }
    guard let d = room.duels(in: s.id).first(where: { $0.a_player == mine.id || $0.b_player == mine.id }) else { return nil }
    let isA = d.a_player == mine.id
    return ((isA ? d.a_pvi : d.b_pvi) != nil, isA ? d.a_round : d.b_round)
  }

  // MARK: F/G/H · a week

  @ViewBuilder private func session(_ s: EventSession) -> some View {
    let ds = ordered(room.duels(in: s.id))
    let rows: [(duel: EventDuel, a: EventPlayer, b: EventPlayer, chip: RyderMath.DuelChip)] = ds.map { d in
      let a = room.player(d.a_player), b = room.player(d.b_player)
      return (d, a, b, RyderMath.chip(d, sessionOpen: s.isOpen, target: room.targets[d.id], aName: a.name, bName: b.name))
    }
    let waiting = rows.flatMap { $0.chip.waiting }
    CSSectionHead(RyderMath.sessionHeader(s), count: RyderMath.sessionSlot(s)).csGutter()
    if ds.isEmpty {
      // **A CLOSED week offers no pairing and no ember.** The first build gave
      // every unpaired week the organiser's ember primary, including one that
      // had already closed — a live-metal control on a thing that is over, and
      // the fourth ember mark on a viewport budgeted for two.
      CSEmpty(glyph: .emptyRail, eyebrow: "Week \(s.session_no)",
              headline: s.isClosed ? "The week wasn't paired." : "The week hasn't been paired.",
              fact: s.isClosed ? "It closed with nobody drawn against anybody."
                               : "Both teams need golfers before pairings can be drawn.",
              door: s.isClosed ? .elsewhere("The two rosters are at the foot of this page.")
                               : (iAmOrg ? .primary("Generate pairings", { pair(s) })
                                         : .elsewhere("The organiser draws them.")))
        .csGutter()
    } else {
      ForEach(rows, id: \.duel.id) { r in clash(r.duel, a: r.a, b: r.b, chip: r.chip.text) }
      if s.isOpen, let nag = RyderMath.nagLine(waiting: waiting, closesOn: s.closes_on) {
        // H · prose, not agate — it is a sentence a person reads (§1.3), which
        // is also what keeps the viewport inside its agate budget.
        Text(nag).csType(.bodyS).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
          .csGutter().padding(.top, CSTokens.Space.s3)
      }
      if iAmOrg, !s.isClosed {
        CSDoor(.link("Score this week", {
          act(fail: "Score failed.", ok: "Week scored") { try await model.resolve(session: s.id) }
        }))
        .csGutter().padding(.top, CSTokens.Space.s3)
      }
    }
  }

  /// **Your clash is the first row of the week**, regardless of pairing order —
  /// it is the only row on the surface the reader is IN, and it was the row the
  /// scroll fade cut when it sat third.
  private func ordered(_ ds: [EventDuel]) -> [EventDuel] {
    guard let mine = room.me(me)?.id else { return ds }
    return ds.sorted { a, b in
      let am = a.a_player == mine || a.b_player == mine
      let bm = b.a_player == mine || b.b_player == mine
      return am && !bm
    }
  }

  /// G · the clash. Not a `CSSlat`: **a clash has no rank, so it does not take
  /// the rail** (D-4).
  @ViewBuilder private func clash(_ d: EventDuel, a: EventPlayer, b: EventPlayer, chip: String?) -> some View {
    let figures = split(chip)
    CSClashRow(left: face(a), leftName: who(a), right: face(b), rightName: who(b),
               mid: RyderMath.mid(d.result),
               leftFigure: figures.0, rightFigure: figures.1,
               result: d.result == "a" ? .left : d.result == "b" ? .right : d.result == "halve" ? .halved : .open,
               risen: model.risen.contains(d.id))
      .id("\(d.id)-\(chip ?? "")")
  }

  /// The viewer reads `You` on their own row.
  private func who(_ p: EventPlayer) -> String {
    p.profileId != nil && p.profileId == me ? "You" : p.name
  }

  /// `RyderMath.chip` produces one string — `+2.1 / –0.4` — because the shipped
  /// row printed it in one 11pt cell. The two figures sit under their own names
  /// now, so the producer's pair is split rather than re-derived: the arithmetic
  /// stays in the Kit and only the punctuation is the view's.
  private func split(_ chip: String?) -> (String?, String?) {
    guard let chip else { return (nil, nil) }
    let parts = chip.components(separatedBy: " / ")
    guard parts.count == 2 else { return (chip, nil) }
    return (parts[0], parts[1])
  }

  // MARK: below the fold — the two rosters with W-L-H

  @ViewBuilder private var rosters: some View {
    ForEach([A, B]) { t in
      let roster = room.roster(t.id)
      CSSectionHead(t.name, count: roster.isEmpty ? nil : "\(roster.count)").csGutter()
      EventTeamSwatch(colorIndex: t.colorIndex, width: 44).csGutter().padding(.bottom, CSTokens.Space.s2)
      if roster.isEmpty {
        Text("No one assigned yet.").csType(.bodyS).foregroundStyle(cs.mut).csGutter()
      } else {
        ForEach(roster) { p in
          Button {
            if let pid = p.profileId { links.openTourCard(pid) }
          } label: {
            CSSlat(rank: 0, field: .none, face: face(p), name: p.name,
                   sub: RyderMath.record(of: p.id, duels: room.duels) + " · won, lost, halved",
                   movement: nil, gap: nil, railHidesNumeral: true) {
              if p.isCaptain {
                Text("Captain").csType(.agateS, caps: true).foregroundStyle(cs.mut)
              }
            }
          }
          .buttonStyle(.plain)
          .disabled(p.profileId == nil)
          .accessibilityHint(p.profileId == nil ? "" : GolfersRoot.CardName.hint())
        }
      }
      // the organiser's unassigned bench, under the side it can join
      if iAmOrg, t.slot == 1, !room.unassigned.isEmpty {
        CSSectionHead("Unassigned", count: "\(room.unassigned.count)").csGutter()
        ForEach(room.unassigned) { p in
          CSSlat(rank: 0, field: .none, face: face(p), name: p.name, sub: "not on a side yet",
                 movement: nil, gap: nil, railHidesNumeral: true) {
            EmptyView()
          }
          HStack(spacing: CSTokens.Space.s3) {
            CSDoor(.link(A.name, { assign(p, to: A) }))
            CSDoor(.link(B.name, { assign(p, to: B) }))
            Spacer(minLength: 0)
          }
          .csGutter()
        }
      }
    }
    // the organiser's hands and the taunt opt-in, at the foot where the rest of
    // the pushed doors live — never four equally-loud minis under the score.
    organiserHands
  }

  @ViewBuilder private var organiserHands: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      if let meP = room.me(me), !room.event.isComplete {
        // **A TERTIARY LINK HUGS ITS LABEL, AND THIS LABEL IS A SENTENCE.**
        // `CSTertiaryStyle` sets `fixedSize(horizontal: true)` at the reading
        // sizes so the 2px rule is as wide as the words and no wider — correct,
        // and it means a 57-character label measures ~490pt on a 362pt page.
        // A vertical `ScrollView` then sizes its content box to that row and
        // CENTRES it, so **every block on the screen slid 65 points left and
        // ran off the right edge.** It cost this wave a screenshot and a probe
        // to find, and it is Wave 5's own unfinished trap with a name at last.
        //
        // The producer's string is `head: tail` — a control and its gloss —
        // and the view splits it there. No copy is invented; the same split
        // the clash row does to `RyderMath.chip`'s pair.
        let label = RyderMath.tauntLabel(on: meP.notifyTarget)
        let cut = label.firstIndex(of: ":")
        VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
          CSDoor(.link(cut.map { String(label[label.startIndex..<$0]) } ?? label, {
            let on = !meP.notifyTarget
            act(fail: nil, ok: RyderMath.tauntToast(on: on)) { try await model.notify(on: on) }
          }))
          if let cut {
            Text(label[label.index(after: cut)...].trimmingCharacters(in: .whitespaces))
              .csType(.bodyS).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
      if iAmOrg {
        CSDoor(.link("Invite golfers", { invite = true }))
        if !room.event.isComplete && !room.anyClosed {
          CSArmedButton(label: "Scrap", armedLabel: "Sure? Scrap it", busy: model.isBusy("scrap"),
                        onArm: { scrapArmed = $0 }) { scrap() }
          if scrapArmed {
            Text(RyderMath.scrapQuestion(room.event.name)).csType(.bodyS).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true).transition(.opacity)
          }
        }
      }
    }
    .csGutter()
    .padding(.top, CSTokens.Space.s4)
  }

  // MARK: hands — every one of these is unchanged

  private func act(fail: String?, ok: String?, _ op: @escaping @MainActor () async throws -> Void) {
    Task {
      do { try await op(); if let ok { toast.show(ok) } }
      catch { toast.show(BoardText.humanError(error, fail), kind: .failed) }
    }
  }

  private func assign(_ p: EventPlayer, to t: EventTeam) {
    act(fail: nil, ok: nil) { try await model.assign(player: p.id, team: t.id) }
  }

  private func pair(_ s: EventSession) {
    Task {
      do { let n = try await model.pair(session: s.id); toast.show(RyderMath.pairingsToast(n)) }
      catch { toast.show(BoardText.humanError(error, "Pairing failed."), kind: .failed) }
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
