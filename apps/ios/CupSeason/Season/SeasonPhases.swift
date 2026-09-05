// Cup Season — the season page's phase pieces (D223, IOS-031).
//
// This file WAS `StandingsPane` — the six-segment room's standings pane, which
// dispatched on phase and then rendered a four-figure season strip, a press
// meter, a next-up card, an "on the line" door, the climb, the table and the
// individual race, one under the other. The page took its sections
// (`SeasonPage.swift`); what stays here are the pieces that page composes:
//
//   the three PHASE screens — setup, the draw, wrapped
//   `ClashCard`   THIS WEEK's spotlight pairing (D108)
//   `NextCard`    the month's floor sentence (D14)
//   `PressMeter`  the month burning down (D76)
//
// WHAT WENT, AND WHY. `RoomSeasonStrip`'s four figures are all somewhere else
// on the redesigned page and every one of them was a second render of one fact
// (L-34): the week is the dateline's, the pot is THE POT's, the index is the ME
// strip's on Home, and the counting figure is the table's own clause. The
// "On the line" door pointed at a pane one scroll below it. D3's fill meter
// retires with the strip; the figure it drew survives as the table's clause
// ("2 of 3 counting this month"), which is the same count with its unit said.

import SwiftUI
import CSDesign
import CupSeasonKit

/// `#homeSetup` — the three steps to first tee, for a season that has not
/// locked its bylaws yet. The Pro gets the verb; a member reads the state.
struct SeasonSetupChecklist: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.cs) private var cs

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      CSSectionHead("Three steps to first tee")
      RoomCheckRow("Season settings", sub: "The stakes, the rules, the format") { num("1") } trail: {
        if model.isPro { RoomMini("Continue") { links.openWizard() } } else { Text("THE PRO").csEyebrow(cs.gold) }
      }
      RoomCheckRow("Invite the crew", sub: "One link fills the season — it opens the moment you lock") { num("2") } trail: {
        Text("At lock").font(CSFont.monoSmall).foregroundStyle(cs.dimText)
      }
      RoomCheckRow("Squad formation", sub: "Unlocks when settings lock") { num("3") } trail: {
        Text("Locked").font(CSFont.monoSmall).foregroundStyle(cs.dimText)
      }
      Text(LeagueCopy.seatFill(code: model.league?.code, members: model.members.count,
                               min: model.bylaws.structMin, locked: model.clock.phase != .setup))
        .font(CSFont.label).tracking(1.2).foregroundStyle(cs.dimText).padding(.top, 10)
    }
  }

  private func num(_ s: String) -> some View { Text(s).font(CSFont.monoMediumBody).foregroundStyle(cs.ink) }
}

/// `#homeDraft` — the draw. S3-04: a member's tap opens a read-only view, and
/// the button says so.
struct SeasonDraftHero: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.cs) private var cs

  var body: some View {
    PhaseHero(k: "Squads are forming", n: "The Pro has the list.",
              m: LeagueCopy.draftPoolSub(pool: model.pool.count, members: model.members.count, min: model.bylaws.structMin)) {
      VStack(spacing: 10) {
        CSButton(model.isPro ? "Form the squads" : "See the squads") { links.openDraft() }
        if let url = model.inviteURL {
          ShareLink(item: url, subject: Text("Cup Season"), message: Text(model.inviteText)) {
            Text("Share the invite link").font(CSFont.button).frame(maxWidth: .infinity, minHeight: 50)
              .foregroundStyle(cs.ink).background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
              .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: 1))
          }
          .simultaneousGesture(TapGesture().onEnded { CSGrowth.log(.artifactShared, kind: "join", token: model.league?.code, league: model.league?.id) })
        }
        if joinsQuiet { RoomFine("Joins have gone quiet — a nudge in the group chat usually does it.") }
      }
      .padding(.top, 8)
    }
  }

  /// 48h since the last join, still short, pre-draw.
  private var joinsQuiet: Bool {
    let short = max(0, model.bylaws.structMin - model.members.count)
    guard short > 0, !model.members.isEmpty, let last = model.members.compactMap(\.joined_at).max() else { return false }
    return Date().timeIntervalSince(last) > 48 * 3600
  }
}

/// The Trophy Room (D66): the stored result, never re-derived.
struct SeasonWrappedHero: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.roomLinks) private var links
  @Environment(\.cs) private var cs

  var body: some View {
    let st = model.settlement
    CSCard(spine: cs.gold, padding: 20) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Season wrapped").csEyebrow(cs.gold)
        Text(st?.champName ?? "The champion").font(CSFont.heroSmall).foregroundStyle(cs.ink)
        Text(model.bylaws.finish == "cup_final" ? "took the Cup Final" : "took the Cup").font(CSFont.sentence).foregroundStyle(cs.mut)
        if let s1 = st?.s1, let s2 = st?.s2 {
          Text("\(PotMath.score(s1))–\(PotMath.score(s2))").font(CSFont.stat).csTabular().foregroundStyle(cs.gold)
        }
        RoomMini("See how it ended") { router.open(.ceremony) }.padding(.top, 6)
        if let rb = links.runItBack { CSButton("Run it back — Season 2", style: .gold) { rb() }.padding(.top, 4) }
      }
    }
  }
}

/// `#pressMeter` (D76): the month burning down under your number.
struct PressMeter: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.cs) private var cs
  var body: some View {
    let pm = LeagueCopy.pressMeter(today: model.clock.today)
    VStack(alignment: .leading, spacing: 6) {
      GeometryReader { g in
        ZStack(alignment: .leading) {
          Capsule().fill(cs.bg2)
          Capsule().fill(LinearGradient(colors: [cs.warm, cs.hot, cs.fire], startPoint: .leading, endPoint: .trailing))
            .frame(width: max(6, g.size.width * pm.fill))
        }
      }
      .frame(height: 6)
      Text(pm.legend).font(CSFont.label).tracking(1.0).foregroundStyle(pm.hot ? cs.hot : cs.mut)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(pm.legend)
  }
}

/// `.nextcard` — "Next up · this month" + Live round. The live spine (the
/// room's look, ember when none — D103b), no wash — the hero has the wash.
struct NextCard: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la
  var body: some View {
    let n = LeagueCopy.nextUp(model.clock, b: model.bylaws, credits: model.myMonth?.credits ?? 0, partial: model.partialMonth)
    CSCard(spine: la.spine(earned: false)) {
      A11yStack(spacing: 12, columnSpacing: 8) {
        VStack(alignment: .leading, spacing: 4) {
          Text(n.k).csEyebrow(la.accent)
          Text(n.text).font(CSFont.subhead).foregroundStyle(cs.ink).fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: 0)
        if let go = links.openRecord { RoomMini("Live round") { go() } }
      }
    }
  }
}

/// D108: the weekly clash — the spotlight pairing as a compact card over the
/// table, mirroring the web chip (`renderClash`): "THE CLASH · YOU v MARCUS ·
/// THROUGH SAT" with each side's best counting round so far mid-week (the
/// same pick `settle_week_clash` makes — the BAND decides, D2), the result
/// once settled. Receipts tap through (§16). Hidden without a row — deploy
/// skew, pre-season, and a quiet settled week (both idle) all render nothing.
struct ClashCard: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la

  var body: some View {
    if let wc = model.weekClash, let s = model.season,
       !(wc.settled && wc.a_best == nil && wc.b_best == nil) {   // both idle settles quiet (D52)
      let win = ClashMath.window(startsOn: s.starts_on, week: wc.week_no)
      let aB = wc.settled ? wc.a_best : ClashMath.bestSoFar(model.rankedRounds, member: wc.a_member, window: win, capN: model.bylaws.capN)
      let bB = wc.settled ? wc.b_best : ClashMath.bestSoFar(model.rankedRounds, member: wc.b_member, window: win, capN: model.bylaws.capN)
      CSCard(spine: la.spine(earned: false)) {
        VStack(alignment: .leading, spacing: 4) {
          Text(headline(wc, weekEnd: win.end)).csEyebrow(la.accent)
          sideRow(wc.a_member, best: aB, won: wc.settled && wc.winner_member == wc.a_member, settled: wc.settled)
          sideRow(wc.b_member, best: bB, won: wc.settled && wc.winner_member == wc.b_member, settled: wc.settled)
        }
      }
    }
  }

  /// First names in the chip (D77); "you" when the viewer is in the spotlight.
  private func first(_ id: UUID) -> String {
    if model.myMember?.id == id { return "you" }
    let n = model.memName(id)
    return n.split(separator: " ").first.map(String.init) ?? n
  }

  private func headline(_ wc: LeagueRoom.WeekClash, weekEnd: String) -> String {
    if wc.settled {
      if let w = wc.winner_member { return "The clash · \(first(w)) took the week" }
      return "The clash · \(first(wc.a_member)) v \(first(wc.b_member)) · all square"
    }
    return "The clash · \(first(wc.a_member)) v \(first(wc.b_member)) · through \(ClashMath.dowShort(weekEnd))"
  }

  @ViewBuilder
  private func sideRow(_ id: UUID, best: LeagueRoom.WeekClash.Best?, won: Bool, settled: Bool) -> some View {
    let mine = model.myMember?.id == id
    let sub: String = {
      guard let b = best else { return settled ? "Idle — no round" : "No round yet" }
      // named bands, never raw differential (D1/D2); they/them for anyone else
      let band = b.band ?? b.pvi.map(CSBands.bandName) ?? ""
      let voiced = mine ? band : CSBands.theirs(band)
      let day = b.played_on.map { ClashMath.dowShort($0) } ?? ""
      return day.isEmpty ? voiced : "\(voiced) · \(day)"
    }()
    Button {
      if let rid = best?.round_id { links.openReceipt(rid) }
    } label: {
      HStack(spacing: 10) {
        Text(won ? "W" : "").font(CSFont.monoSmall).csTabular().foregroundStyle(cs.gold).frame(width: 14, alignment: .leading)
        VStack(alignment: .leading, spacing: 1) {
          Text(first(id)).font(CSFont.subhead.weight(won ? .semibold : .regular)).foregroundStyle(cs.ink)
          Text(sub.uppercased()).font(CSFont.label).tracking(0.8).foregroundStyle(cs.dimText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        Text(best?.points.map { CSCopy.points($0) } ?? "—").font(CSFont.monoMediumBody).csTabular().foregroundStyle(cs.ink)
      }
      .padding(.vertical, 6)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(best?.round_id == nil)
    .accessibilityElement(children: .combine)
    .accessibilityHint(best?.round_id == nil ? "" : "Opens the round")
  }
}
