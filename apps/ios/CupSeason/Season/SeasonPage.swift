// Cup Season — THE SEASON PAGE (D223, D230, D235, IOS-031).
//
// It replaces the league room. `LeagueRoomScreen`'s six-segment strip
// (STANDINGS · BOARD · SCHEDULE · POT · ALBUM · LEAGUE, two of which were
// doors) is one scrolling page with a story spine, and the segments become
// sections and doors inside it:
//
//   the dateline          FELLAS · WEEK 7 OF 26 · SEASON LIVE
//   the story line        one sentence about a person, in the serif voice,
//                         chosen by the seven-rung ladder (SeasonStoryCopy)
//   THIS WEEK             the clash, or the phase this season is actually in
//   THE TABLE             every rung, with the endgame PERMANENTLY beneath it
//   THE POT               the pot's two numbers and the ledger
//   the doors             the board · the schedule · the album · the rules
//   the Pro's verb row    a row at the foot, never a mode
//
// D93's "one authoritative surface per question" is UPHELD: standings, board,
// pot, schedule and rules each keep exactly one home. What is retired is the
// CONTAINER — the segmented control that mixed panes with doors, and the
// four-figure season strip whose every figure was already on the page or in
// the ME strip (L-34: the week is in the dateline, the pot is in THE POT, the
// index is the ME strip's, the counting figure is the table's own clause).
//
// D230 · every league door lands HERE. `openCompetition(id, pane:)` opens the
// page and scrolls to the section a door was named for; a door named for the
// board or the album pushes that surface ON TOP of the page, so back lands on
// the season rather than on the tab root.

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
  /// choice ≻ the person's dial". The deleted `ClubhouseView` set it; this page
  /// did not, and it is pushed by `competeDestination` — OUTSIDE the
  /// `.environment(\.csLook, …)` on `CompeteScreen`'s own ScrollView, which
  /// sits deeper than the navigationDestination and cannot reach a push. So a
  /// season's colour dressed its Compete row and vanished the moment you
  /// opened it. No entry retires IOS-025 for this surface.
  @Environment(LookStore.self) private var looks
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
        .navigationTitle(model.league?.name ?? "Season")
        .navigationBarTitleDisplayMode(.inline)
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
  /// nil while the session has not answered — the page then wears the personal
  /// look, which is what it wore before.
  private var seasonLook: CSLookSpec? {
    guard let m = store.me?.memberships.first(where: { $0.league_id == model.leagueId }) else { return nil }
    return looks.look(for: m)
  }

  private func page(_ proxy: ScrollViewProxy) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        if let err = model.error, !model.loaded {
          // L-32 · a failed read is never an empty one, and it ends in a move
          CSCard(spine: cs.neg) {
            VStack(alignment: .leading, spacing: 10) {
              Text("The season did not load").csEyebrow(cs.neg)
              Text(err).font(CSFont.body).foregroundStyle(cs.ink)
              CSButton("Try again", style: .quiet) { Task { await model.refresh() } }
            }
          }
        } else if !model.loaded {
          SeasonDateline(loading: true)
        } else {
          SeasonDateline(loading: false)
          SeasonVoteBanner()
          SeasonStoryLead(model: model)
          thisWeek
          table
          pot
          SeasonDoors()
          if model.isPro && !model.isComplete {
            ProVerbRow(scrollTo: { a in CSMotion.run { proxy.scrollTo(a, anchor: .top) } })
          }
        }
      }
      .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 40)
    }
    .environment(\.csLook, seasonLook)   // R-10 · before csLookGround, which reads it
    // R-11 · the keep list's own line: "the rank-up haptic, once, for the room
    // in hand". It went out with ClubhouseView and nothing replaced it. One
    // page, one rung, so the "only the room on screen" guard is the page.
    .csFeedback(.rankUp, trigger: climbs)
    .task(id: model.loaded) { if model.loaded && model.iClimbed { climbs += 1 } }
    .csLookGround()
    .environment(model)
    .environment(router)
    .environment(\.roomLinks, links)
    .refreshable { await model.refresh() }
    .task(id: model.leagueId) {
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

  // MARK: THIS WEEK — what is actually in front of this season right now

  @ViewBuilder private var thisWeek: some View {
    let c = model.clock
    switch c.phase {
    case .setup: SeasonSetupChecklist()
    case .draft: SeasonDraftHero()
    case .season:
      if model.isComplete {
        SeasonWrappedHero()
      } else {
        VStack(alignment: .leading, spacing: 10) {
          if c.atStarter {
            let k = LeagueCopy.kickoff(c)
            PhaseHero(k: "Before first tee", n: k.tee, m: k.count) { EmptyView() }
          } else {
            CSSectionHead("This week")
            if c.isCupFinal {
              PhaseHero(k: "Cup Final", n: "Four weeks, scored fresh.",
                        m: "FRESH SLATE · \(c.daysLeft) DAY\(c.daysLeft == 1 ? "" : "S") LEFT · WHOEVER'S HOTTEST TAKES THE CUP") { EmptyView() }
            }
            ClashCard()
            NextCard()
            PressMeter()
          }
        }
      }
    }
  }

  // MARK: THE TABLE — and the endgame, permanently beneath it (D235)

  @ViewBuilder private var table: some View {
    VStack(alignment: .leading, spacing: 10) {
      if model.clock.isCupFinal && !model.isComplete && (model.cupRace?.isLive ?? false) {
        // D105: the race leads while its window is open; the season table is the seed beneath it
        CSSectionHead("The Cup Final").id(SeasonPane.table.anchor)
        CupFinalRaceView()
        CSSectionHead("The weeks before the Final")
      } else {
        CSSectionHead("The table").id(SeasonPane.table.anchor)
      }
      StandingsTableView()
      SeasonEndgameFoot()
      CSSectionHead("The climb")
      ClimbView()
      CSSectionHead("Every golfer")   // LV-10 · row 121 rules the phrase
      IndividualRaceView()
    }
  }

  // MARK: THE POT — one home for the money (D93), nothing at all at $0 (L-10)

  @ViewBuilder private var pot: some View {
    if model.bylaws.stake > 0 {
      PotPane().id(SeasonPane.pot.anchor)
    }
  }
}

/// The dateline: the season's name, its week and its stage, on one row and in
/// one vocabulary (D120, D246). Nothing below it prints the week again (L-34).
struct SeasonDateline: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.cs) private var cs
  let loading: Bool

  var body: some View {
    let stage = LeagueCopy.stage(model.clock)
    VStack(alignment: .leading, spacing: 6) {
      Text(loading ? "LOADING THE SEASON…"
                   : SeasonStoryCopy.dateline(name: model.league?.name, stage: stage,
                                              week: model.seasonStory?.facts?.week_no ?? model.clock.currentWeek,
                                              weeks: model.seasonStory?.facts?.weeks_total ?? model.clock.totalWeeks))
        .font(CSFont.label).tracking(1.2).foregroundStyle(model.isComplete ? cs.gold : cs.dimText)
        .fixedSize(horizontal: false, vertical: true)
      if !loading {
        Text("\(model.clock.spanText) · THE PRO · \(model.proName.uppercased())")
          .font(CSFont.label).tracking(0.8).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
  }
}

/// The story line — the page's own lead. One sentence about a person, in the
/// serif voice, with the arc one tap behind it. A payload that cannot say
/// anything renders NOTHING here rather than a placeholder (L-44).
struct SeasonStoryLead: View {
  @Environment(\.cs) private var cs
  let model: LeagueRoomModel

  var body: some View {
    if let line = model.storyLine {
      VStack(alignment: .leading, spacing: 8) {
        Text(line.text).font(CSFont.sentence).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
          .id(SeasonPane.story.anchor)
        if let id = model.league?.id {
          NavigationLink(value: SeasonSubRoute.story(id)) {
            Text("The season's story →").font(CSFont.monoMediumBody).foregroundStyle(cs.ink)
              .frame(minHeight: 44).contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

/// D235 · the endgame, whole, permanently under the table. The ME strip's
/// clause is the same fact at the other grain; both are produced from the same
/// finish, structure and dates, so they can never say different things.
struct SeasonEndgameFoot: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.cs) private var cs

  var body: some View {
    let b = model.bylaws
    Text(LeagueCopy.endgame(finish: b.finish, structure: b.structure,
                            startsOn: model.clock.startsOn, endsOn: model.clock.endsOn))
      .font(CSFont.footnote).foregroundStyle(cs.dimText)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, 2)
  }
}

/// The four doors, as rows rather than segments: each says where it goes
/// (D218) and each has exactly one home (D93).
struct SeasonDoors: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.cs) private var cs

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      CSSectionHead("The rest of the season")
      door("The board", sub: "Every round, every notice, in one thread") { links.openBoard() }
      door("The schedule", sub: "Who is playing, and when") { links.openSchedule() }
      // a door with nothing behind it is worse than no door (L-32): the album
      // row renders only where the shell has somewhere to send it.
      if let album = links.openAlbum {
        door("The album", sub: "Every round photo this season") { album() }
      }
      if let id = model.league?.id {
        NavigationLink(value: SeasonSubRoute.rules(id)) { rowLabel("The rules", sub: "How this season scores, and how it ends") }
          .buttonStyle(.plain)
      }
    }
  }

  @ViewBuilder private func door(_ title: String, sub: String, action: @escaping () -> Void) -> some View {
    Button(action: action) { rowLabel(title, sub: sub) }.buttonStyle(.plain)
  }

  private func rowLabel(_ title: String, sub: String) -> some View {
    A11yStack(rowAlignment: .firstTextBaseline, spacing: 12, columnSpacing: 4) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
        Text(sub).font(CSFont.footnote).foregroundStyle(cs.dimText).fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      Text("→").font(CSFont.mono).foregroundStyle(cs.mut).accessibilityHidden(true)
    }
    .padding(.vertical, 12)
    .frame(minHeight: 56)
    .contentShape(Rectangle())
    .overlay(alignment: .bottom) { Rectangle().fill(cs.rule).frame(height: 1) }
    .accessibilityElement(children: .combine)
  }
}

/// D71 · the cancellation vote. IA §7.5: while a vote is open the season says
/// so at the top of the page, in one sentence, with the two facts that decide
/// whether a member should agree — the money comes back, the rounds stay.
struct SeasonVoteBanner: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  @State private var busy = false

  var body: some View {
    if let cr = model.cancel, cr.open == true {
      let v = SeasonVote.item(cr, league: model.league?.name, pro: model.proName)
      CSCard(spine: cs.neg) {
        VStack(alignment: .leading, spacing: 6) {
          Text(v.eyebrow).csEyebrow(cs.neg)
          Text(v.headline).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
            .fixedSize(horizontal: false, vertical: true)
          RoomFine(v.standfirst)
          FlowRow(spacing: 8) {
            switch v.act {
            case .withdraw: RoomMini("Call it off", busy: busy) { run { try await model.withdrawCancel(); toast.show("Cancellation called off.") } }
            case .vote:
              RoomMini("Agree", busy: busy) { vote(true) }
              RoomMini("Decline", busy: busy) { vote(false) }
            case .wait: EmptyView()
            }
            Text(v.tally).font(CSFont.footnote).foregroundStyle(cs.dimText)
          }
          .padding(.top, 4)
        }
      }
    }
  }

  private func vote(_ approve: Bool) {
    run {
      let r = try await model.voteCancel(approve: approve)
      if r == "done" { toast.show("\(model.league?.name ?? "The season") ended. Every round stays on its golfer."); links.leagueGone() }
      else if r == "declined" { toast.show("You declined — the cancellation is off.") }
      else { toast.show("Agreed — waiting on the rest.") }
    }
  }

  private func run(_ op: @escaping @MainActor () async throws -> Void) {
    busy = true
    Task { defer { busy = false }; do { try await op() } catch { toast.show(roomError(error)) } }
  }
}
