// Cup Season — the season page's phase pieces (Wave 5, `surfaces/season.md`).
//
// WHAT THIS FILE HELD AND WHAT HAPPENED TO IT:
//
//   `PressMeter`  DELETED. A 6pt three-stop gradient capsule with no head,
//                 which the audit read as a warning bar and §4 of the brief
//                 names as a generic sports gradient (CS-12). `MonthClock`
//                 below replaces it: countable ticks grouped by the calendar
//                 month that does the counting, one live cell, and the same
//                 numbers it always drew — `LeagueCopy.pressMeter`'s facts and
//                 `nextUp`'s sentence, which live on.
//   `ClashCard`   → `ClashRows`. Loses the `CSCard`, the spine and the `W`
//                 gold letter; keeps `ClashMath.window` / `.bestSoFar`, the
//                 named bands and the receipt tap. Two rows on the page's own
//                 ground, and **the side that is ahead takes a panel**.
//   `NextCard`    → the counting sentence and the tertiary link inside
//                 `MonthClock`. Loses the `CSCard`, the spine and `RoomMini`.
//
// The three phase screens (setup, the draw, wrapped) are re-clothed to bands
// and rules and keep every behaviour they had.

import SwiftUI
import CSDesign
import CupSeasonKit

// MARK: - The month clock (§1.2)

/// **The tick row, given months.** One object answers "how far into the
/// season", "which month am I in" and "how long have I got" — and then says
/// what the golfer owes it, and gives him the one door that pays it.
///
/// The door is a **tertiary link**, not a primary: this surface is a board and
/// its live action belongs to the ⊕ (D-3). A primary appears only in the
/// states where the page genuinely owns one.
struct MonthClock: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.cs) private var cs

  var body: some View {
    let c = model.clock
    let months = SeasonCalendarMath.months(startsOn: c.startsOn, weeks: c.totalWeeks, today: c.today)
    let now = c.done || c.atStarter ? -1 : max(0, c.currentWeek - 1)
    let n = model.myMonth?.credits ?? 0
    let next = LeagueCopy.nextUp(c, b: model.bylaws, credits: n, partial: model.partialMonth)
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      if !months.isEmpty {
        CSSeasonCalendar(weeks: c.totalWeeks,
                         played: max(0, now < 0 ? c.totalWeeks : now),
                         now: now,
                         months: months.map { .init(label: $0.label, weeks: $0.weeks, note: $0.note, live: $0.live) })
      }
      Text(next.text).csType(.bodyS).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
      if let go = links.openRecord {
        CSDoor(.link("Add my round", go))
      }
    }
    .csGutter()
  }
}

// MARK: - The clash (§1.3)

/// D108: the week's matchup — two rows on the page's own ground. **No card, no
/// spine, no border.** Hidden without a row: deploy skew, pre-season, a field
/// too small to pair and a settled week where both sides were idle all render
/// nothing at all, head included, because a door with nothing behind it is
/// worse than no door.
struct ClashRows: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.cs) private var cs

  var body: some View {
    if let wc = model.weekClash, let s = model.season,
       !(wc.settled && wc.a_best == nil && wc.b_best == nil) {
      let win = ClashMath.window(startsOn: s.starts_on, week: wc.week_no)
      let aB = wc.settled ? wc.a_best : ClashMath.bestSoFar(model.rankedRounds, member: wc.a_member, window: win, capN: model.bylaws.capN)
      let bB = wc.settled ? wc.b_best : ClashMath.bestSoFar(model.rankedRounds, member: wc.b_member, window: win, capN: model.bylaws.capN)
      let ahead = leader(aB, bB)
      // DF-08 · the two sides of a clash are ONE object and sit at `s2`;
      // `season-top.png` puts 10pt between them and the shipped `s3` put 12
      // on top of each row's own height. The head keeps its `s3`.
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        CSSectionHead("This week · the clash", count: through(wc, weekEnd: win.end))
          .padding(.bottom, CSTokens.Space.s1)
        side(wc.a_member, best: aB, ahead: ahead == 0)
        side(wc.b_member, best: bB, ahead: ahead == 1)
      }
      .csGutter()
    }
  }

  /// 0 = the a side, 1 = the b side, nil = level or both idle. **Only one
  /// panel per clash**, which is what makes it the emphasis §13 asks for.
  private func leader(_ a: LeagueRoom.WeekClash.Best?, _ b: LeagueRoom.WeekClash.Best?) -> Int? {
    let pa = a?.points, pb = b?.points
    switch (pa, pb) {
    case let (x?, y?): return x == y ? nil : (x > y ? 0 : 1)
    case (_?, nil): return 0
    case (nil, _?): return 1
    default: return nil
    }
  }

  private func through(_ wc: LeagueRoom.WeekClash, weekEnd: String) -> String {
    wc.settled ? "settled" : "through \(ClashMath.dowShort(weekEnd))"
  }

  @ViewBuilder private func side(_ id: UUID, best: LeagueRoom.WeekClash.Best?, ahead: Bool) -> some View {
    let mine = model.myMember?.id == id
    let m = model.member(id)
    let sub: String = {
      guard let b = best else { return "No round yet" }
      // named bands, never raw differential (D1/D2); they/them for anyone else
      let band = b.band ?? b.pvi.map(CSBands.bandName) ?? ""
      let voiced = mine ? band : CSBands.theirs(band)
      let day = b.played_on.map { ClashMath.dowShort($0) } ?? ""
      return day.isEmpty ? voiced : "\(voiced) · \(day)"
    }()
    Button {
      if let rid = best?.round_id { links.openReceipt(rid) }
    } label: {
      // §3.1 · **at AX3 the figure drops BELOW the row and the row goes full
      // width.** Held on one line, a 38pt face beside a 44pt name, a 24pt
      // clause and a panel measured screen + 40 — and a vertical `ScrollView`
      // CENTRES content wider than itself, so the whole season page slid left
      // and lost its gutter. Every fixed-width row on this surface reflows
      // rather than overflowing; the clash was the last one that did not.
      A11yStack(rowAlignment: .center, spacing: CSTokens.Space.s3, columnSpacing: CSTokens.Space.s2) {
        HStack(spacing: CSTokens.Space.s3) {
          if let m {
            CSFace(.init(id: m.profile_id, marker: m.mk, photoURL: model.avatarURL[m.profile_id],
                         isViewer: model.viewer?.id == m.profile_id), size: .list)
          }
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            Text(mine ? "You" : (m?.name ?? "—")).csType(.name).foregroundStyle(cs.ink)
              .lineLimit(1).truncationMode(.tail)
            Text(sub).csType(.agateS, caps: true).foregroundStyle(cs.mut)
              .lineLimit(1).truncationMode(.tail)
          }
          .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        if ahead, let p = best?.points {
          CSPanel(unit: "pts") { Text(CSCopy.points(p)).csType(.figureM) }
        } else if let p = best?.points {
          Text(CSCopy.points(p)).csType(.figureM).foregroundStyle(cs.mut)
        } else {
          // idle: an em dash in `mut`, and it is the ONE place on this surface
          // a dash stands for a value nobody has posted yet
          Text("\u{2014}").csType(.figureS).foregroundStyle(cs.mut)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .frame(minHeight: 52)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(best?.round_id == nil)
    .accessibilityElement(children: .combine)
    .accessibilityHint(best?.round_id == nil ? "" : "Opens the round")
  }
}

// MARK: - The phases

/// `#homeSetup` — the three steps to first tee, for a season that has not
/// locked its bylaws yet. The Pro gets the verb; a member reads the state.
struct SeasonSetupChecklist: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.cs) private var cs

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      CSSectionHead("Three steps to first tee")
      RoomCheckRow("The rules", sub: "The stakes, the rules, the format") { num("1") } trail: {
        // §3 · setup is one of the four states where this page owns a primary
        if model.isPro { CSDoor(.primary("Continue", links.openWizard)) } else { Text("The Pro").csType(.agateS, caps: true).foregroundStyle(cs.mut) }
      }
      RoomCheckRow("Invite the crew", sub: "One link fills the season — it opens the moment you start the season") { num("2") } trail: {
        Text("After step 1").csType(.agateS, caps: true).foregroundStyle(cs.mut)
      }
      RoomCheckRow("Squads form", sub: "After the season starts") { num("3") } trail: {
        Text("After step 1").csType(.agateS, caps: true).foregroundStyle(cs.mut)
      }
      Text(LeagueCopy.seatFill(code: model.league?.code, members: model.members.count,
                               min: model.bylaws.structMin, locked: model.clock.phase != .setup))
        .csType(.agateS, caps: true).foregroundStyle(cs.mut).padding(.top, CSTokens.Space.s3)
    }
    .csGutter()
  }

  private func num(_ s: String) -> some View { Text(s).csType(.columnM).foregroundStyle(cs.ink) }
}

/// `#homeDraft` — the draw. S3-04: a member's tap opens a read-only view, and
/// the button says so.
struct SeasonDraftHero: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.cs) private var cs

  var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      CSSectionHead("Squads drawing")
      Text("It’s random — nobody picks.").csType(.story).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
      Text(LeagueCopy.draftPoolSub(pool: model.pool.count, members: model.members.count, min: model.bylaws.structMin))
        .csType(.agateS, caps: true).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
      CSDoor(.primary(model.isPro ? "Draw the squads" : "See the squads", links.openDraft))
      if let url = model.inviteURL {
        ShareLink(item: url, subject: Text("Cup Season"), message: Text(model.inviteText)) {
          Text("Share the invite link")
        }
        .buttonStyle(.csSecondary)
        .simultaneousGesture(TapGesture().onEnded { CSGrowth.log(.artifactShared, kind: "join", token: model.league?.code, league: model.league?.id) })
      }
      if joinsQuiet {
        Text("Joins have gone quiet — a nudge in the group chat usually does it.")
          .csType(.bodyS).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true)
      }
    }
    .csGutter()
  }

  /// 48h since the last join, still short, pre-draw.
  private var joinsQuiet: Bool {
    let short = max(0, model.bylaws.structMin - model.members.count)
    guard short > 0, !model.members.isEmpty, let last = model.members.compactMap(\.joined_at).max() else { return false }
    return Date().timeIntervalSince(last) > 48 * 3600
  }
}

/// The Trophy Room (D66): the stored result, never re-derived. **No card** —
/// the champion's name is the object, and the one gold on the viewport is the
/// leader's rail below it.
struct SeasonWrappedHero: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.roomLinks) private var links
  @Environment(\.cs) private var cs

  var body: some View {
    let st = model.settlement
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      CSSectionHead("Season complete")
      Text(st?.champName ?? "The champion").csType(.displayS).foregroundStyle(cs.ink)
      Text(model.bylaws.finish == "cup_final" ? "took the Cup Final" : "took the Cup")
        .csType(.story).foregroundStyle(cs.mut)
      if let s1 = st?.s1, let s2 = st?.s2 {
        Text("\(PotMath.score(s1))–\(PotMath.score(s2))").csType(.figureM).csTabular().foregroundStyle(cs.ink)
      }
      // §3 · complete is one of the four states where this page owns a primary
      CSDoor(.primary("See how it ended") { router.open(.ceremony) })
      // D243 · role-gated. The Pro runs it back; a member ASKS.
      if let rb = links.runItBack {
        CSDoor(.link(RunItBack.title(isPro: model.isPro, proFirstName: model.proName == "—" ? nil : model.proName), rb))
      }
    }
    .csGutter()
  }
}
