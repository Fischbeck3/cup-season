// Cup Season — `#room-standings` (index.html 3435–3496), phase-dispatched by
// `renderPhase` (11985): the setup checklist · the formation hero · the
// season body (kickoff hero · the season strip · press meter · next up · on
// the line · the climb · the table · the individual race).
//
// IOS-019: the four stat tiles are ONE season strip (no KPI grid); sections
// are an eyebrow over a hairline; rows sit on ground, not in borders.

import SwiftUI
import CSDesign
import CupSeasonKit

struct StandingsPane: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.roomLinks) private var links
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize

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
      CSSectionHead("League setup · three steps to first tee")
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
          .simultaneousGesture(TapGesture().onEnded { CSGrowth.log(.artifactShared, kind: "join", token: model.league?.code, league: model.league?.id) })
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
    VStack(alignment: .leading, spacing: 10) {
      RoomSeasonStrip()
      if !(c.done || c.atStarter || c.isCupFinal) { PressMeter() }
    }
    NextCard()
    if model.bylaws.stake > 0 { onTheLine }
    CSSectionHead("Season race · the climb").id("room-climb")
    ClimbView()
    if c.isCupFinal && !model.isComplete && (model.cupRace?.isLive ?? false) {
      // D105: the race leads the room; the full-season table is the seed beneath it
      CSSectionHead("The Cup Final").id("room-standings")
      CupFinalRaceView()
      CSSectionHead("The regular season — final")
    } else {
      CSSectionHead("Standings").id("room-standings")
    }
    ClashCard()
    StandingsTableView()
    CSSectionHead("The individual race · every player").id("room-race")
    IndividualRaceView()
    if c.phase == .season && !model.isComplete {
      // #14: once the season is live, setup tools live down here (stacked at the accessibility sizes)
      A11yStack(spacing: 8) {
        if let url = model.inviteURL, let code = model.league?.code {
          ShareLink(item: url, subject: Text("Cup Season"), message: Text(model.inviteText)) {
            Text("Code · \(code)").font(CSFont.monoSmall).foregroundStyle(cs.ink).padding(.horizontal, 12).frame(minHeight: 36)
              .background(cs.bg2, in: Capsule()).overlay(Capsule().stroke(cs.line2, lineWidth: 1)).frame(minHeight: 44)
          }
          .simultaneousGesture(TapGesture().onEnded { CSGrowth.log(.artifactShared, kind: "join", token: code, league: model.league?.id) })
        }
        RoomMini("Add golfers") { links.addGolfers() }
      }
      .padding(.top, 4)
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

  /// `.ontheline` (3446–3453) → the Pot pane. A door, so it keeps its line;
  /// the gold is earned — it is the pot.
  private var onTheLine: some View {
    Button { router.pane = .pot; CSHaptic.selection() } label: {
      CSCard(spine: cs.gold) {
        A11yStack(spacing: 12, columnSpacing: 6) {
          VStack(alignment: .leading, spacing: 4) {
            Text("On the line").csEyebrow(cs.gold)
            Text(PotMath.dollars(model.potTotal)).font(CSFont.heroSmall).csTabular().foregroundStyle(cs.gold)
          }
          Spacer()
          // D106: the bar says what was collected when it is short of the pot
          Text(LeagueCopy.lineSplit(total: model.potTotal, payout: model.bylaws.payout)
               + (model.collectedShort ? " · \(model.collectedText.uppercased()) COLLECTED" : ""))
            .font(CSFont.label).tracking(0.8).foregroundStyle(cs.mut).multilineTextAlignment(typeSize.isA11y ? .leading : .trailing)
          Text("→").font(CSFont.mono).foregroundStyle(cs.gold).accessibilityHidden(true)
        }
      }
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityHint("Opens the pot")
  }
}

/// `.stats` (3459–3464, `renderStats` 9406–9495) — the four figures as ONE
/// season strip: a hairline above and below, four mono columns, the month's
/// fill meter under the counting figure. Not a grid of tiles (IOS-003 §4).
struct RoomSeasonStrip: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize

  var body: some View {
    let c = model.clock, b = model.bylaws
    let dl = LeagueCopy.deadline(c, b: b)
    let est = !model.establishedIndex
    let capN = b.capN
    let credits = model.myMonth?.credits ?? 0
    let used = min(Double(model.myMonth?.counting ?? 0), Double(capN == Int.max ? Int.max : capN))
    VStack(alignment: .leading, spacing: 0) {
      // IOS-022 item 9: four across at reading sizes; at accessibility sizes the strip
      // wraps to two by two, so a figure is never clipped — each cell is one VoiceOver element
      PolishWrapRow(wrap: typeSize.isAccessibilitySize) {
        column("Season", value: LeagueCopy.weekValue(c), small: "/ \(c.totalWeeks)",
               sub: dl.text, subTone: dl.gold ? cs.gold : cs.mut)
        column("The pot", value: b.stake == 0 ? "None" : PotMath.dollars(model.potTotal), small: nil,
               sub: b.stake == 0 ? "Bragging rights" : "\(model.paidCount)/\(model.potPlayers) buy-ins in",
               tone: b.stake == 0 ? cs.ink : cs.gold)
        column("Your index", value: est ? "\(min(model.viewer?.roundsCount ?? 0, 3)) of 3" : CSCopy.index(model.viewer?.indexCurrent), small: nil,
               sub: LeagueCopy.indexSub(established: !est, delta: model.myIndexDelta),
               subTone: (model.myIndexDelta ?? 0) < -0.05 && !est ? cs.pos : cs.mut)
        VStack(alignment: .leading, spacing: 5) {
          label("Counting rounds")
          HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(capN == Int.max ? LeagueCopy.fmtN(credits) : LeagueCopy.fmtN(used)).font(CSFont.stat).csTabular().foregroundStyle(cs.ink)
            Text(capN == Int.max ? "rounds" : "/ \(capN)").font(CSFont.label).foregroundStyle(cs.mut)
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
          Text(LeagueCopy.countingSub(month: LeagueDates.monthLong(c.today), capN: capN))
            .font(CSFont.label).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
      }
      .padding(.vertical, 12)
      CSHairline()
    }
    .accessibilityElement(children: .contain)
  }

  /// Two lines of room, bottom-aligned, so the four figures sit on one baseline whatever the label's length.
  private func label(_ s: String) -> some View {
    Text(s).font(CSFont.label).tracking(1.0).textCase(.uppercase).foregroundStyle(cs.dimText)
      .lineLimit(2).fixedSize(horizontal: false, vertical: true)
      .frame(minHeight: 30, alignment: .bottomLeading)
  }

  private func column(_ k: String, value: String, small: String?, sub: String, tone: Color? = nil, subTone: Color? = nil) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      label(k)
      HStack(alignment: .firstTextBaseline, spacing: 3) {
        Text(value).font(CSFont.stat).csTabular().foregroundStyle(tone ?? cs.ink).lineLimit(1).minimumScaleFactor(0.7)
        if let small { Text(small).font(CSFont.label).foregroundStyle(cs.mut) }
      }
      Text(sub).font(CSFont.label).foregroundStyle(subTone ?? cs.mut).fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .topLeading)
    .accessibilityElement(children: .combine)
  }
}

/// Four cells in a row, or two by two when `wrap` — the season strip at
/// accessibility sizes (IOS-022 item 9). A `Layout`, so the cells stay the
/// same views either way.
struct PolishWrapRow: Layout {
  let wrap: Bool
  let spacing: CGFloat = 8

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let width = proposal.width ?? 0
    let perRow = wrap ? 2 : max(1, subviews.count)
    let cellW = max(0, (width - spacing * CGFloat(perRow - 1)) / CGFloat(perRow))
    var height: CGFloat = 0
    for start in stride(from: 0, to: subviews.count, by: perRow) {
      let row = subviews[start..<min(start + perRow, subviews.count)]
      let h = row.map { $0.sizeThatFits(ProposedViewSize(width: cellW, height: nil)).height }.max() ?? 0
      height += h + (start == 0 ? 0 : spacing)
    }
    return CGSize(width: width, height: height)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let perRow = wrap ? 2 : max(1, subviews.count)
    let cellW = max(0, (bounds.width - spacing * CGFloat(perRow - 1)) / CGFloat(perRow))
    var y = bounds.minY
    for start in stride(from: 0, to: subviews.count, by: perRow) {
      let row = subviews[start..<min(start + perRow, subviews.count)]
      let h = row.map { $0.sizeThatFits(ProposedViewSize(width: cellW, height: nil)).height }.max() ?? 0
      for (i, v) in row.enumerated() {
        v.place(at: CGPoint(x: bounds.minX + CGFloat(i) * (cellW + spacing), y: y), anchor: .topLeading,
                proposal: ProposedViewSize(width: cellW, height: h))
      }
      y += h + spacing
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
