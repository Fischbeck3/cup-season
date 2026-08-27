// Cup Season — `#room-standings` (index.html 3435–3496), phase-dispatched by
// `renderPhase` (11985): the setup checklist · the formation hero · the
// season body (kickoff hero · stats strip · press meter · next up · on the
// line · the climb · the table · the individual race).

import SwiftUI
import CSDesign
import CupSeasonKit

struct StandingsPane: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.roomLinks) private var links
  @Environment(\.cs) private var cs

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      switch model.clock.phase {
      case .setup: setupChecklist
      case .draft: draftHero
      case .season: seasonBody
      }
    }
  }

  // MARK: `#homeSetup` (3436–3441)

  private var setupChecklist: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("League setup · three steps to first tee").csEyebrow()
      RoomCheckRow("Season settings", sub: "Stakes · rules · format") { num("1") } trail: {
        if model.isPro { RoomMini("Continue") { links.openWizard() } } else { Text("THE PRO").csEyebrow(cs.gold) }
      }
      RoomCheckRow("Invite the crew", sub: "One link fills the league — it opens the moment you lock") { num("2") } trail: {
        Text("At lock").font(CSFont.monoSmall).foregroundStyle(cs.dimText)
      }
      RoomCheckRow("Squad formation", sub: "Unlocks when settings lock") { num("3") } trail: {
        Text("Locked").font(CSFont.monoSmall).foregroundStyle(cs.dimText)
      }
      Text(LeagueCopy.seatFill(code: model.league?.code, members: model.members.count, min: model.bylaws.structMin))
        .font(CSFont.label).tracking(1.2).foregroundStyle(cs.dimText).padding(.top, 10)
    }
  }

  private func num(_ s: String) -> some View { Text(s).font(CSFont.monoMediumBody).foregroundStyle(cs.ink) }

  // MARK: `#homeDraft` (3443–3452)

  private var draftHero: some View {
    PhaseHero(k: "Squads are forming", n: "The Pro has the list.",
              m: LeagueCopy.draftPoolSub(pool: model.pool.count, members: model.members.count, min: model.bylaws.structMin)) {
      VStack(spacing: 10) {
        // S3-04: a member's tap opens a read-only draw view — say so on the button
        CSButton(model.isPro ? "Form the squads" : "See the squads") { links.openDraft() }
        if let url = model.inviteURL {
          ShareLink(item: url, subject: Text("Cup Season"), message: Text(model.inviteText)) {
            Text("Share the invite link").font(CSFont.button).frame(maxWidth: .infinity, minHeight: 50)
              .foregroundStyle(cs.ink).background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
              .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: 1))
          }
        }
        if joinsQuiet { RoomFine("Joins have gone quiet — a nudge in the group chat usually does it.") }
      }
      .padding(.top, 8)
    }
  }

  /// 48h since the last join, still short, pre-draw (12654–12662).
  private var joinsQuiet: Bool {
    let short = max(0, model.bylaws.structMin - model.members.count)
    guard short > 0, !model.members.isEmpty, let last = model.members.compactMap(\.joined_at).max() else { return false }
    return Date().timeIntervalSince(last) > 48 * 3600
  }

  // MARK: `#homeSeason`

  @ViewBuilder private var seasonBody: some View {
    let c = model.clock
    if c.atStarter {
      let k = LeagueCopy.kickoff(c)
      PhaseHero(k: "Before first tee", n: k.tee, m: k.count) { EmptyView() }
    }
    if model.isComplete { wrappedHero }
    if c.isCupFinal && !model.isComplete {
      PhaseHero(k: "Cup Final", n: "Four weeks, scored fresh.", m: "FRESH SLATE · \(model.clock.daysLeft) DAY\(model.clock.daysLeft == 1 ? "" : "S") LEFT · WHOEVER'S HOTTEST TAKES THE CUP") { EmptyView() }
    }
    StatsStrip()
    if !(c.done || c.atStarter || c.isCupFinal) { PressMeter() }
    NextCard()
    if model.bylaws.stake > 0 { onTheLine }
    Text("Season race · the climb").csEyebrow()
    CSCard { ClimbView() }
    Text("Standings").csEyebrow()
    StandingsTableView()
    Text("The individual race · every player").csEyebrow()
    IndividualRaceView()
    if c.phase == .season && !model.isComplete {
      // #14: once the season is live, setup tools live down here
      HStack(spacing: 8) {
        if let url = model.inviteURL, let code = model.league?.code {
          ShareLink(item: url, subject: Text("Cup Season"), message: Text(model.inviteText)) {
            Text("Code · \(code)").font(CSFont.monoSmall).foregroundStyle(cs.ink).padding(.horizontal, 12).frame(minHeight: 36)
              .background(cs.bg2, in: Capsule()).overlay(Capsule().stroke(cs.line2, lineWidth: 1)).frame(minHeight: 44)
          }
        }
        RoomMini("Add golfers") { links.addGolfers() }
      }
    }
  }

  /// The Trophy Room (D66): the stored result, never re-derived.
  private var wrappedHero: some View {
    let st = model.settlement
    return CSCard(spine: cs.gold, padding: 20) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Season wrapped").csEyebrow(cs.gold)
        Text(st?.champName ?? "The champion").font(CSFont.heroSmall).foregroundStyle(cs.ink)
        Text(model.bylaws.finish == "cup_final" ? "take the Cup Final" : "take the Cup").font(CSFont.sentence).foregroundStyle(cs.mut)
        if let s1 = st?.s1, let s2 = st?.s2 {
          Text("\(PotMath.score(s1))–\(PotMath.score(s2))").font(CSFont.stat).csTabular().foregroundStyle(cs.gold)
        }
        RoomMini("See how it ended") { router.open(.ceremony) }.padding(.top, 6)
        if let rb = links.runItBack { CSButton("Run it back — Season 2", style: .gold) { rb() }.padding(.top, 4) }
      }
    }
  }

  /// `.ontheline` (3446–3453) → the Pot pane.
  private var onTheLine: some View {
    Button { router.pane = .pot; CSHaptic.selection() } label: {
      HStack(alignment: .center, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text("On the line").csEyebrow(cs.gold)
          Text(PotMath.dollars(model.potTotal)).font(CSFont.heroSmall).csTabular().foregroundStyle(cs.gold)
        }
        Spacer()
        Text(LeagueCopy.lineSplit(total: model.potTotal, payout: model.bylaws.payout))
          .font(CSFont.label).tracking(0.8).foregroundStyle(cs.mut).multilineTextAlignment(.trailing)
        Text("→").font(CSFont.mono).foregroundStyle(cs.gold)
      }
      .padding(16)
      .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).stroke(cs.gold.opacity(0.45), lineWidth: 1))
    }
    .buttonStyle(.plain)
  }
}

/// `.stats` — the four tiles (3459–3464, `renderStats` 9406–9495).
struct StatsStrip: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.cs) private var cs

  var body: some View {
    let c = model.clock, b = model.bylaws
    let dl = LeagueCopy.deadline(c, b: b)
    let est = !model.establishedIndex
    let capN = b.capN
    let credits = model.myMonth?.credits ?? 0
    let used = min(Double(model.myMonth?.counting ?? 0), Double(capN == Int.max ? Int.max : capN))
    VStack(spacing: 10) {
      HStack(spacing: 10) {
        tile("Season", value: LeagueCopy.weekValue(c), small: "/ \(c.totalWeeks)", sub: dl.text, subTone: dl.gold ? cs.gold : cs.mut)
        tile("The pot", value: b.stake == 0 ? "None" : PotMath.dollars(model.potTotal), small: nil,
             sub: b.stake == 0 ? "Bragging rights" : "\(model.paidCount)/\(model.potPlayers) buy-ins in", tone: b.stake == 0 ? cs.ink : cs.gold)
      }
      HStack(spacing: 10) {
        tile("Your index", value: est ? "\(min(model.viewer?.roundsCount ?? 0, 3)) of 3" : CSCopy.index(model.viewer?.indexCurrent), small: nil,
             sub: LeagueCopy.indexSub(established: !est, delta: model.myIndexDelta),
             subTone: (model.myIndexDelta ?? 0) < -0.05 && !est ? cs.pos : cs.mut)
        VStack(alignment: .leading, spacing: 6) {
          Text("Counting rounds").font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.dimText)
          HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(capN == Int.max ? LeagueCopy.fmtN(credits) : LeagueCopy.fmtN(used)).font(CSFont.stat).csTabular().foregroundStyle(cs.ink)
            Text(capN == Int.max ? "rounds" : "/ \(capN)").font(CSFont.monoSmall).foregroundStyle(cs.mut)
          }
          if capN != Int.max {
            // D3: the month is a fill meter — slots you can see filling
            HStack(spacing: 3) {
              ForEach(0..<capN, id: \.self) { i in
                Circle().fill(Double(i) < used ? cs.pos : .clear).frame(width: 7, height: 7)
                  .overlay(Circle().stroke(Double(i) < used ? .clear : cs.dim, lineWidth: 1).opacity(0.55))
              }
            }
            .accessibilityLabel("\(LeagueCopy.fmtN(used)) of \(capN) counting rounds")
          }
          Text(LeagueCopy.countingSub(month: LeagueDates.monthLong(c.today), capN: capN)).font(CSFont.monoSmall).foregroundStyle(cs.mut)
        }
        .padding(.vertical, 14).padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).stroke(cs.line, lineWidth: 1))
      }
    }
  }

  private func tile(_ label: String, value: String, small: String?, sub: String, tone: Color? = nil, subTone: Color? = nil) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label).font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.dimText)
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text(value).font(CSFont.stat).csTabular().foregroundStyle(tone ?? cs.ink)
        if let small { Text(small).font(CSFont.monoSmall).foregroundStyle(cs.mut) }
      }
      Text(sub).font(CSFont.monoSmall).foregroundStyle(subTone ?? cs.mut).fixedSize(horizontal: false, vertical: true)
    }
    .padding(.vertical, 14).padding(.horizontal, 14)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).stroke(cs.line, lineWidth: 1))
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

/// `.nextcard` — "Next up · this month" + Live round.
struct NextCard: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.cs) private var cs
  var body: some View {
    let n = LeagueCopy.nextUp(model.clock, b: model.bylaws, credits: model.myMonth?.credits ?? 0, partial: model.partialMonth)
    CSCard(spine: cs.brand) {
      HStack(alignment: .center, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text(n.k).csEyebrow(cs.brand)
          Text(n.text).font(CSFont.subhead).foregroundStyle(cs.ink).fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: 0)
        if let go = links.openRecord { RoomMini("Live round") { go() } }
      }
    }
  }
}
