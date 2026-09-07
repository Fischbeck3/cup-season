// Cup Season — THE SEASON PAGE (D223, D230, D235, IOS-031; rebuilt Wave 5).
//
// **A season is a story with a leaderboard, not a spreadsheet.** One scrolling
// page: a sentence, a clock, a matchup, a board, a pot. The board is the hero
// and it begins inside the first viewport — the card stack, the press meter and
// the second serif sentence that pushed the table 74% down the screen (CS-06, a
// P0) are gone, and the section head now lands around 61% with the leader, you
// and two more above the fold.
//
// GOLD APPEARS EXACTLY TWICE — the leader's rail field and the pot — and that
// pair is `LINT-17`'s one sanctioned exception, whitelisted by name (D-6:
// `SeasonPage.leaderRail`, `SeasonPage.potFigure`). Ember appears twice and
// they are one clock: the live eyebrow's dot and the current week's tick.
//
// WHAT SURVIVES VERBATIM: `SeasonPane` routing, `RoomRouter`, the `.task`
// loads, every `navigationDestination`, the rank-up haptic and the ceremony
// announcement. What went: the `.padding(.horizontal, 20)` on the whole
// `VStack` — slats and bands are FULL-BLEED and only wrapped content takes the
// gutter — the `CSCard(spine:)` on the error and the vote banner, the second
// standings table, the third, and the Pro's seven-capsule verb row (CS-38),
// which is one secondary door to the rules page where his controls already
// live.

import SwiftUI
import CSDesign
import CupSeasonKit

/// Where a door asked the page to land. It replaces `RoomPane`: the six
/// segments are gone and these are SECTIONS AND DOORS, which is the whole
/// difference D223 makes.
enum SeasonPane: String, CaseIterable, Identifiable, Hashable {
  case story, table, board, schedule, pot, album, rules

  /// The server's own pane word (`home_dispatch`'s `route.pane`, a free string
  /// so the ranker can name a pane this build does not know). An unknown name
  /// lands on the table, which is what a season door means when it says
  /// nothing more — never a blank screen.
  static func named(_ raw: String?) -> SeasonPane {
    switch (raw ?? "").lowercased() {
    case "story":            return .story
    case "board":            return .board
    case "schedule":         return .schedule
    case "pot":              return .pot
    case "album":            return .album
    case "rules", "league":  return .rules
    default:                 return .table
    }
  }

  var id: String { rawValue }
  /// The scroll anchor on the page. The doors (board, schedule, album) are
  /// pushed rather than scrolled to, and land on the table underneath.
  var anchor: String { "season-\(rawValue)" }
}

/// The two pages the season pushes. Compete's stack is a `NavigationPath`, so
/// these ride it beside `CompeteRoute` without widening that enum.
enum SeasonSubRoute: Hashable { case story(UUID), rules(UUID) }

struct SeasonPage: View {
  @Environment(SessionStore.self) private var store
  /// R-10 · IOS-025: "the room wears its league's look — phase ≻ the Pro's
  /// choice ≻ the person's dial".
  @Environment(LookStore.self) private var looks
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  @State private var model: LeagueRoomModel
  @State private var router: RoomRouter
  /// R-11 · the rank-up haptic, once per load, for the season in hand.
  @State private var climbs = 0
  let links: LeagueRoomLinks
  let pane: SeasonPane

  init(leagueId: UUID, links: LeagueRoomLinks, pane: SeasonPane = .table) {
    _model = State(initialValue: LeagueRoomModel(leagueId: leagueId))
    _router = State(initialValue: RoomRouter(pane: pane))
    self.links = links
    self.pane = pane
  }

  var body: some View {
    ScrollViewReader { proxy in
      page(proxy)
        // LINT-24 · the season's name is printed ONCE, in `display` 34 (CS-07:
        // it was set three times in 50pt of vertical space).
        //
        // **AND THE BAR CARRIES NOTHING** (DF-09). iOS 26 wrapped the system
        // back button in a translucent `bg2` capsule, so this page's chevron
        // arrived boxed while the course page's — the same gesture, one push
        // away — did not. One back button in the product: the family's own
        // chevron, no field behind it. The ~40pt the bar's chrome was taking
        // goes back to the table, which is the object this page is for.
        .csBareBar()
        .csStatusCap(cs.bg0)
        .task(id: model.loaded) {
          // the door that named a section lands on it, once the section exists
          guard model.loaded, pane == .pot || pane == .story else { return }
          try? await Task.sleep(for: .milliseconds(250))
          CSMotion.run { proxy.scrollTo(pane.anchor, anchor: .top) }
        }
        #if DEBUG
        // Developer hatch: `-cs_dev_scroll <anchor>` (story · table · pot) scrolls a simulator there.
        .task(id: model.loaded) {
          let a = ProcessInfo.processInfo.arguments
          guard model.loaded, let i = a.firstIndex(of: "-cs_dev_scroll"), i + 1 < a.count else { return }
          try? await Task.sleep(for: .seconds(1))
          proxy.scrollTo("season-" + a[i + 1], anchor: .top)
        }
        #endif
    }
  }

  /// R-10 · the membership's own look, resolved the way `CompeteScreen` does.
  private var seasonLook: CSLookSpec? {
    guard let m = store.me?.memberships.first(where: { $0.league_id == model.leagueId }) else { return nil }
    return looks.look(for: m)
  }

  private func page(_ proxy: ScrollViewProxy) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
        // **THE PAGE DRAWS ITS OWN BACK CHEVRON** (DF-09). iOS 26 wraps every
        // toolbar button in a glass capsule, so the system's back button
        // arrived inside a translucent `bg2` disc while the course page's —
        // the same gesture, one push away — did not. One back button in the
        // product: the family's chevron, no field, riding the head. It also
        // hands ~40pt of the first viewport back to the table, which is the
        // object this page is for.
        // DF-08 · the chevron's 44pt target is kept and its BOX is not: the
        // negative insets pull the head up ~28pt, which is the difference
        // between `season-top.png`'s eyebrow at 64pt and the build's at 92.
        CSBackChevron { dismiss() }
          .padding(.top, -CSTokens.Space.s2)
          .padding(.bottom, -(CSTokens.Space.s4 + CSTokens.Space.s2))
        if let err = model.error, !model.loaded {
          // L-32 · a failed read is never an empty one, and it ends in a move.
          // §3 · "one lead line, one body line, and Try again as the surface's
          // primary" — type on the ground, no spine, no card.
          VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
            Text("The season did not load").csType(.lead).foregroundStyle(cs.ink)
              .fixedSize(horizontal: false, vertical: true)
            Text(err).csType(.bodyS).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)
            CSDoor(.primary("Try again") { Task { await model.refresh() } })
          }
          .csGutter()
        } else if !model.loaded {
          // §3 · loading is THE DESTINATION'S OWN GEOMETRY, redacted — the
          // head's lines, the ticks and six slats with their rails and rules
          // present. No spinner; `ProgressView` is banned in content.
          SeasonLoading()
        } else {
          SeasonHead()
          SeasonVoteBanner()
          thisWeek
          table
          pot
          SeasonDoors()
        }
      }
      .padding(.top, CSTokens.Space.s2).padding(.bottom, CSTokens.Space.s6)
      // **THE PAGE IS THE WIDTH OF THE PAGE**, and WAVE 10 found the half of
      // this Wave 5 could not. A vertical `ScrollView` sizes its content box
      // to its widest child and CENTRES a box wider than itself, so one row
      // that overflows by forty points slides the whole page twenty to the
      // left and takes the gutter with it. Wave 5 pinned the width with a
      // bare `containerRelativeFrame(.horizontal)` — which **defaults to
      // `.center`**, so the frame was the right width and its content was
      // still centred inside it, and the twenty-point offset survived every
      // clamp that wave tried. One argument: `alignment: .leading`. It lives
      // in `csPage` now, with the measure and the breach log.
      .csPage("season")
    }
    .environment(\.csLook, seasonLook)   // R-10 · before csLookGround, which reads it
    .csFeedback(.rankUp, trigger: climbs)
    .task(id: model.loaded) { if model.loaded && model.iClimbed { climbs += 1 } }
    .csLookGround()
    .environment(model)
    .environment(router)
    .environment(\.roomLinks, links)
    .refreshable { await model.refresh() }
    .task(id: model.leagueId) {
      #if DEBUG
      // `-cs_dev_season_fixture [squads]` — the cut, the pot and the squad
      // table need a field, a stake and a structure the signed-in account does
      // not have. DEBUG only, never written, and the shot is a fixture.
      if let kind = SeasonFixture.kind, !model.loaded {
        SeasonFixture.apply(model, squads: kind == "squads")
        return
      }
      #endif
      guard !model.loaded, let me = store.me, let v = RoomViewer(me) else { return }
      await model.load(viewer: v)
      // D66: a finished season announces itself ONCE per member, after the data is in
      if model.ceremonyDue {
        try? await Task.sleep(for: .milliseconds(400))
        router.open(.ceremony)
      }
    }
    .navigationDestination(for: SeasonSubRoute.self) { r in
      switch r {
      case .story: SeasonStoryPane(model: model, links: links)
      case .rules: SeasonRulesPage(model: model, router: router, links: links)
      }
    }
    .sheet(item: $router.sheet) { s in
      Group {
        switch s {
        case .squad(let t): SquadReceiptSheet(team: t)
        case .member(let r): MemberHistorySheet(row: r)
        case .finalist(let f): FinalistReceiptSheet(finalist: f)
        case .scoringHelp: ScoringHelpSheet(solo: model.bylaws.solo)
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

  // MARK: THIS WEEK — the clock and the matchup

  @ViewBuilder private var thisWeek: some View {
    let c = model.clock
    switch c.phase {
    case .setup: SeasonSetupChecklist()
    case .draft: SeasonDraftHero()
    case .season:
      if model.isComplete {
        SeasonWrappedHero()
      } else {
        MonthClock()
        // §3 · pre-season, a field too small to pair and a settled quiet week
        // all render NOTHING here, head included.
        ClashRows()
      }
    }
  }

  // MARK: THE TABLE — and what it is running toward, permanently beneath it

  @ViewBuilder private var table: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      if model.clock.isCupFinal && !model.isComplete && (model.cupRace?.isLive ?? false) {
        // D105: the race leads while its window is open; the season table is
        // the seed beneath it, under its own head.
        CSSectionHead("The Cup Final", count: "two seats")
          .csGutter()
          .id(SeasonPane.table.anchor)
        CupFinalRaceView()
        CSSectionHead("The weeks before the Final", count: fieldCount)
          .csGutter()
      } else {
        // 1.4a · in a squads season the SQUAD table comes first (it is what
        // `model.teams` already IS when the structure is not solo), and the
        // individual table prints beneath it under EVERY GOLFER. In a solo
        // season neither the squad layer nor the swatch renders at all and the
        // head stays THE TABLE — which is what CS-11 actually asked for.
        // **THE MOVEMENT CLOCK RIDES THE SECTION HEAD** (`leaderboard.md` D-2,
        // and the one idea this surface adds to the system). The shipped board
        // printed `HELD SINCE SUN` eleven times at 11pt beside eleven ranks;
        // the clock is a property of the SNAPSHOT, not of a row, so it is
        // named ONCE for the whole table and the rows carry a drawn mark.
        // `StandingsMath`'s absolute rule survives the move: no clock, no
        // claim — with none the head falls back to the field count and the
        // movement column does not render either.
        CSSectionHead(model.bylaws.solo ? "The table" : "The squads",
                      count: StandingsMath.movedSince(model.priorSince)
                        ?? (model.bylaws.solo ? fieldCount : SeasonBoardCopy.sides(model.teams.count)))
          .csGutter()
          .id(SeasonPane.table.anchor)
      }
      StandingsTableView()
      if !model.bylaws.solo && !model.indRows.isEmpty {
        CSSectionHead("Every golfer", count: SeasonBoardCopy.field(model.indRows.count))
          .csGutter()
          .padding(.top, CSTokens.Space.s4)
        GolferTableView()
      }
      endgame
    }
  }

  private var fieldCount: String? {
    let n = model.bylaws.solo ? model.teams.count : model.indRows.count
    return n > 0 ? SeasonBoardCopy.field(n) : nil
  }

  /// §1.5 · what the board is running toward: the countdown as a rule-and-
  /// figure in ember, the endgame sentence verbatim, and the scenario line as
  /// ONE agate line (CS-20 — it was a 13–14pt mono console message).
  @ViewBuilder private var endgame: some View {
    let b = model.bylaws
    let f = model.seasonStory?.facts
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      CSRule()
      if !model.isComplete,
         let cd = SeasonBoardCopy.countdown(finish: b.finish, inWeeks: f?.final?.in_weeks,
                                            weeksLeft: f?.weeks_left ?? weeksLeftFallback) {
        // a clock that is running is ember (§2.6). Rule, not a fill.
        CSFigure(cd.figure, size: .l, metal: .live, label: cd.label)
          .padding(.top, CSTokens.Space.s3)
      }
      Text(LeagueCopy.endgame(finish: b.finish, structure: b.structure,
                              startsOn: model.clock.startsOn, endsOn: model.clock.endsOn))
        .csType(.bodyS).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
      ScenarioLineView(parts: ScenarioLine.parts(model.scenarios))
    }
    .csGutter()
    .padding(.top, CSTokens.Space.s4)
  }

  private var weeksLeftFallback: Int? {
    let c = model.clock
    guard c.hasSeason else { return nil }
    return max(0, c.totalWeeks - c.currentWeek)
  }

  // MARK: THE POT — one home for the money (D93), nothing at all at $0 (L-10)

  @ViewBuilder private var pot: some View {
    if model.bylaws.stake > 0 {
      PotPane().id(SeasonPane.pot.anchor)
    }
  }
}

// MARK: - The head (§1.1)

/// The eyebrow, the season's name in `display`, the dateline, and **the chapter
/// line in the serif** — the audit's "best line on the phone", finally at lead
/// size instead of body size (CS-08). One `display` and one serif appearance
/// per viewport, which is what §1.4 budgets.
struct SeasonHead: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la

  /// The one sentence, from the one producer. `ClimbMath.closer` decides; this
  /// only hands it the gap the board is already printing and the month's own
  /// counting rounds.
  private var closerLine: String? {
    guard !model.isComplete,
          let mineId = model.myTeamId,
          let meIdx = model.teams.firstIndex(where: { $0.id == mineId }),
          meIdx > 0, let leader = model.teams.first else { return nil }
    return ClimbMath.closer(gap: leader.pts - model.teams[meIdx].pts,
                            countingPoints: model.myCountingPoints,
                            capN: model.bylaws.cap)
  }

  var body: some View {
    let stage = LeagueCopy.stage(model.clock)
    let complete = model.isComplete
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      HStack(spacing: CSTokens.Space.s1) {
        // **The dot IS the ember**, and LINT-18 counts it and its own eyebrow
        // as ONE mark: both are the same clock and the eyebrow names it.
        if !complete {
          Circle().fill(la.accent ?? cs.brand).frame(width: 7, height: 7)
        }
        Text(SeasonBoardCopy.eyebrow(stage: stage,
                                     week: model.seasonStory?.facts?.week_no ?? model.clock.currentWeek,
                                     weeks: model.seasonStory?.facts?.weeks_total ?? model.clock.totalWeeks))
          .csType(.agate, caps: true)
          .foregroundStyle(complete ? cs.gold : (la.accent ?? cs.brand))
          .fixedSize(horizontal: false, vertical: true)
      }
      .csBudget(gold: complete ? 1 : 0, ember: complete ? 0 : 1)
      Text(model.league?.name ?? "The season").csType(.display)
        .foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
      Text(SeasonBoardCopy.dateline(number: model.season?.number,
                                    span: SeasonBoardCopy.span(startsOn: model.clock.startsOn,
                                                               endsOn: model.clock.endsOn) ?? model.clock.spanText,
                                    pro: model.proName,
                                    squads: model.bylaws.solo ? nil : model.squads.count))
        .csType(.agate, caps: true).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
      if let line = model.storyLine {
        Text(line.text).csType(.lead).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.top, CSTokens.Space.s2)
          .id(SeasonPane.story.anchor)
      }
      // **QB-12 · TURN THE GAP INTO A MOVE**, and this is the chapter line's
      // half of it (`season.md` §5: the climb's `closer` clause moves here).
      // It rode `ClimbView`, which the table replaced, and it stopped
      // rendering anywhere — so the app went back to telling a golfer he was
      // four back without ever telling him one good round covers it. It speaks
      // only when ONE round genuinely closes the gap; silence is the honest
      // answer for a gap bigger than that.
      if let closer = closerLine {
        Text(closer).csType(.bodyS).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.top, CSTokens.Space.s2)
      }
    }
    // **PAD FIRST, THEN TAKE THE MEASURE.** `.frame(maxWidth: .infinity)`
    // followed by `.padding(.horizontal, 20)` is a block the width of the
    // screen with twenty points added to each side — it overflows by forty, and
    // at the reading sizes nothing is wide enough to show it. At AX3 the whole
    // head sheared to the left edge and the month clock's ticks ran off the
    // right. The padding goes inside the frame.
    .csGutter()
  }
}

// MARK: - Loading (§3)

/// The destination's own geometry, redacted. The head's three lines, the
/// ticks, the section heads, and **six slats with their rails and rules
/// present**. The shipped `"LOADING THE SEASON…"` string is deleted.
struct SeasonLoading: View {
  @Environment(\.cs) private var cs
  var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        Text("Season live · week 5 of 13").csType(.agate, caps: true).foregroundStyle(cs.mut)
        Text("The season").csType(.display).foregroundStyle(cs.ink)
        Text("Season one · the dates · the Pro").csType(.agate, caps: true).foregroundStyle(cs.mut)
      }
      .csGutter()
      CSSeasonCalendar(weeks: 13, played: 0, now: -1,
                       months: [.init(label: "One", weeks: 4), .init(label: "Two", weeks: 5),
                                .init(label: "Three", weeks: 4)])
        .csGutter()
      CSSectionHead("The table").csGutter()
      VStack(spacing: 0) {
        ForEach(0..<6, id: \.self) { i in
          CSSlat(rank: i + 1, field: .none, face: nil, name: "Golfer name",
                 sub: "A clause of why", movement: .held, gap: "+0") {
            CSFigure("00", size: .m, label: nil)
          }
        }
      }
    }
    .csRedacted(true)
    .accessibilityLabel("Loading the season")
  }
}

// MARK: - The doors (§1.7)

/// Each door says where it goes (D218) and each has exactly one home (D93).
/// **No capsules, no icon circles, no system disclosure indicator**, and no
/// section head over them: the blind review filed a two-item nav menu bolted
/// to the end of a content page, and what it was objecting to was the HEAD
/// that framed four content-free rows as a section of the season.
///
/// The Pro's verb row (up to seven equally weighted capsules, one of them red,
/// under a gold eyebrow — CS-38) is one secondary door, `Season settings`,
/// which pushes the rules page where his controls already live.
struct SeasonDoors: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.cs) private var cs

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      CSRule()
      // the story is a pushed screen, so its door lives with the other pushed
      // screens rather than 60pt into the first viewport (§1.1 draws four
      // elements in the head and this was a fifth)
      if let id = model.league?.id {
        NavigationLink(value: SeasonSubRoute.story(id)) {
          rowLabel("The season's story", sub: "Week by week, and every season before it")
        }
        .buttonStyle(.plain)
      }
      door("The board", sub: "Every round, every notice, in one thread") { links.openBoard() }
      door("The schedule", sub: "Who is playing, and when") { links.openSchedule() }
      // a door with nothing behind it is worse than no door (L-32)
      if let album = links.openAlbum {
        door("The album", sub: "Every round photo this season") { album() }
      }
      if let id = model.league?.id {
        NavigationLink(value: SeasonSubRoute.rules(id)) {
          rowLabel(model.isPro ? "Season settings" : "The rules",
                   sub: model.isPro ? "The stakes, the dial, and everything you run"
                                    : "How this season scores, and how it ends")
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.top, CSTokens.Space.s4)
  }

  @ViewBuilder private func door(_ title: String, sub: String, action: @escaping () -> Void) -> some View {
    Button(action: action) { rowLabel(title, sub: sub) }.buttonStyle(.plain)
  }

  private func rowLabel(_ title: String, sub: String) -> some View {
    A11yStack(rowAlignment: .center, spacing: CSTokens.Space.s3, columnSpacing: CSTokens.Space.s1) {
      VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
        Text(title).csType(.social).foregroundStyle(cs.ink)
        Text(sub).csType(.agateS, caps: false).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      CSGlyph(.chevron, size: .inline).foregroundStyle(cs.mut).accessibilityHidden(true)
    }
    .csGutter()
    .padding(.vertical, CSTokens.Space.s3)
    .frame(minHeight: 52)
    .contentShape(Rectangle())
    .overlay(alignment: .bottom) { CSRule() }
    .accessibilityElement(children: .combine)
  }
}

// MARK: - The cancellation vote (§3)

/// D71 · IA §7.5: while a vote is open the season says so at the top of the
/// page, in one sentence, with the two facts that decide whether a member
/// should agree — the money comes back, the rounds stay. **One `body` sentence
/// and two tertiary links on the ground**: no `CSCard`, no `neg` spine.
struct SeasonVoteBanner: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  @State private var busy = false

  var body: some View {
    if let cr = model.cancel, cr.open == true {
      let v = SeasonVote.item(cr, league: model.league?.name, pro: model.proName)
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        Text(v.headline).csType(.body).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
        Text(v.standfirst).csType(.bodyS).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
        HStack(spacing: CSTokens.Space.s4) {
          switch v.act {
          case .withdraw:
            CSDoor(.link("Call it off") { run { try await model.withdrawCancel(); toast.show("Cancellation called off.", kind: .confirmed) } })
          case .vote:
            CSDoor(.link("Agree") { vote(true) })
            CSDoor(.link("Decline") { vote(false) })
          case .wait: EmptyView()
          }
          Spacer(minLength: 0)
        }
        Text(v.tally).csType(.agateS, caps: true).foregroundStyle(cs.mut)
      }
      .csGutter()
      .disabled(busy)
    }
  }

  private func vote(_ approve: Bool) {
    run {
      let r = try await model.voteCancel(approve: approve)
      if r == "done" { toast.show("\(model.league?.name ?? "The season") ended. Every round stays on its golfer.", kind: .confirmed); links.leagueGone() }
      else if r == "declined" { toast.show("You declined — the cancellation is off.", kind: .confirmed) }
      else { toast.show("Agreed — waiting on the rest.", kind: .confirmed) }
    }
  }

  private func run(_ op: @escaping @MainActor () async throws -> Void) {
    busy = true
    Task { defer { busy = false }; do { try await op() } catch { toast.show(roomError(error), kind: .failed) } }
  }
}
