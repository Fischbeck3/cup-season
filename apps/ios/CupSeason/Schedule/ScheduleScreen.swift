// Cup Season — Your golf calendar (D93 `view-schedule` 3575; `renderCalendar`
// 12045–12170; `renderWatchList` 15761; `loadSchedule` 15685).
//
// Days carry rounds on the books — yours, buddies', league mates' (the RPC
// does the visibility math) — and season dates from every league you're in.
// A league mate's round glows gold: the "Logan's playing Pebble — get
// something on the books" loop.

import SwiftUI
import CSDesign
import CupSeasonKit

struct ScheduleScreen: View {
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var store
  @State private var vm: ScheduleModel
  @State private var toasts: CSToastCenter
  @State private var declare: DeclarePrefill? = nil
  @State private var day: DaySheet? = nil
  @State private var openRoundId: UUID? = nil
  @State private var retag: RetagRequest? = nil
  let links: CSLinks

  init(links: CSLinks = CSLinks()) {
    self.links = links
    let t = CSToastCenter()
    _toasts = State(initialValue: t)
    _vm = State(initialValue: ScheduleModel(toasts: t))
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        // N4-161 · the page names itself in the page (UI_SYSTEM §12.2)
        CSPageHeader("The schedule") { EmptyView() }
        Text("Yours, your buddies’, your seasons’").csType(.agate, caps: true).foregroundStyle(cs.mut)
        refreshFailed
        watch
        calendarHeader
        ScheduleMonthGrid(month: vm.month, byDay: vm.byDay, today: vm.today) { d in open(day: d) }
        Text("Tap any day.").csType(.bodyS).foregroundStyle(cs.mut)
          .frame(maxWidth: .infinity).multilineTextAlignment(.center)
        Button("Put a round on the schedule") { declare = DeclarePrefill() }.buttonStyle(.csPrimary())
        CSSectionHead("On the schedule")
        list
        weeks
      }
      .padding(20)
    }
    .background(cs.bg0)
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .refreshable { await vm.reload(me: store.me, current: store.preferredLeague) }
    .task { await vm.reload(me: store.me, current: store.preferredLeague) }
    .csToasts(toasts)
    .sheet(item: $declare, onDismiss: { Task { await vm.reload(me: store.me, current: store.preferredLeague) } }) { p in
      DeclareRoundSheet(prefill: p, leagueId: store.preferredLeague) { _ in }
    }
    .sheet(item: $day) { d in daySheet(d) }
    .sheet(item: $openRoundId, onDismiss: { Task { await vm.reload(me: store.me, current: store.preferredLeague) } }) { id in
      ScheduledRoundSheet(roundId: id, fallback: vm.row(id), leagueId: store.preferredLeague, links: links)
    }
    .sheet(item: $retag, onDismiss: { Task { await vm.reload(me: store.me, current: store.preferredLeague) } }) { r in
      RetagSheet(request: r, leagueId: store.preferredLeague)
    }
  }

  private func open(_ id: UUID) {
    if let f = links.openRound { f(id) } else { openRoundId = id }
  }

  // MARK: In your crew's plans (15761)

  @ViewBuilder private var watch: some View {
    let all = vm.watchRows
    let rows = Array(all[..<min(all.count, 6)])   // the web shows six (15768)
    if !rows.isEmpty {
      CSSectionHead("In your crew's plans")
      ForEach(rows) { sr in
        // W2 · A-7 · the tag names the crew, and a plan with no relation to
        // name carries no tag at all (`relTag`). The title's `name` role sets
        // the case, so the words go in as the web says them.
        let name = Text(sr.display_name ?? "A golfer")
        let title = relTag(sr).map { name + Text("  \($0)").font(CSType.font(.agateS)).foregroundStyle(cs.mut) } ?? name
        // N4-133 · the person is the row's one button, as PersonRow's is: it
        // opened on a tap gesture and was never a button to VoiceOver
        RoomLineRow(face: Faces.of(sr.profile_id, marker: sr.marker, name: sr.display_name), title: title,
                    sub: watchBits(sr), onTap: { if let id = sr.id { open(id) } }, hint: "Opens the plan") {
          // W2 · the slot holds the ANSWER when there is one (in, out) and the
          // act when there is not — never a tag read as a yes (`csPlanRowHtml`)
          if let a = answer(sr), a.settled {
            Text(a.said).csType(.agateS, caps: true).foregroundStyle(a == .yes ? cs.ink : cs.mut)   // F-10
          } else {
            CSMini("I’m in", busy: sr.id.map { vm.busy.contains($0) } ?? false) {
              // tagged: the same answer the plan's sheet gives (`set_round_rsvp`,
              // D69). Not tagged: your own round that day, tagging the host (D17).
              if sr.tagged_me == true, let id = sr.id {
                Task { if await vm.answerIn(id) { await vm.reload(me: store.me, current: store.preferredLeague) } }
              } else {
                declare = DeclarePrefill(iso: sr.play_on, course: sr.course_label ?? "", tee: sr.tee_time, courseId: sr.course_id,
                                         tagPids: [sr.profile_id].compactMap { $0 }, hostName: sr.display_name)
              }
            }
          }
        }
      }
    }
  }

  private func watchBits(_ sr: ScheduledRound) -> Text {
    // N4-135 · every piece in its own case, so the row's agate role sets the
    // whole line's (§1.3): a capped date and course beside "Maybe" and a
    // golfer's note was a tracked line in two cases
    var t = Text(sr.play_on.map { ScheduleDates.when($0) } ?? "")
    if let c = sr.course_label { t = t + Text(" · \(c)") }
    if let tee = sr.tee_time, !TeeTime.format(tee).isEmpty { t = t + Text(" · ") + Text(TeeTime.format(tee)).foregroundStyle(cs.ink) }   // F-10 · a clock
    // brand-canon §4 · a rivalry is a RELATIONSHIP, not something won: `ink`.
    if let r = RivalryTag.of(sr.profile_id, rivals: vm.rivals) { t = t + Text(" · ") + Text(r.text).foregroundStyle(cs.ink) }
    // W2 · an OPEN answer (asked, maybe) is named here so it is never silent;
    // a settled one is the slot's to say, once. A phrase, so the web's case.
    if let a = answer(sr), !a.settled { t = t + Text(" · ") + Text(a.said) }
    if let n = sr.note, !n.isEmpty { t = t + Text(" · “\(n)”") }
    return t
  }

  // MARK: W2 · the plan's state and its crew, said once (`csPlanMe` / `csPlanRel`)

  /// What the golfer said to a plan that names them.
  enum PlanAnswer: Equatable {
    case yes, no, maybe, asked
    /// The web's `CS_PLAN_ME`, word for word.
    var said: String {
      switch self {
      case .yes: "You’re in"
      case .no: "You’re out"
      case .maybe: "Maybe"
      case .asked: "Asked"
      }
    }
    /// An answer given, as opposed to one still open.
    var settled: Bool { self == .yes || self == .no }
  }

  /// **"IN" IS AN EXPLICIT YES AND NOTHING ELSE** (critique-B P0). The list
  /// printed YOU'RE IN off `tagged_me` for a golfer who had been asked and
  /// never answered, while the plan's own sheet said NO REPLY — two
  /// definitions of "in" printing contradictory facts about a real person's
  /// commitment. The answer is `my_rsvp`, read the way `PlanSeat` reads a
  /// seat; a tag with no answer is `Asked`, the server's own word (G7: the
  /// state of the invitation, never a verdict on the man). nil for your own
  /// plan — the host is in by declaring it — and for a plan that does not
  /// name you (`csPlanMe`).
  private func answer(_ sr: ScheduledRound) -> PlanAnswer? {
    guard !sr.isMine, sr.tagged_me == true else { return nil }
    let seat = PlanSeat(status: sr.my_rsvp)
    if seat.isIn { return .yes }
    if seat.isOut { return .no }
    return sr.my_rsvp == "maybe" ? .maybe : .asked
  }

  /// **A-7 · THE TAG NAMES THE CREW** (`IN NORTH GROVE`), never the retired
  /// compound. `my_schedule` says only THAT a season is shared, never which,
  /// so the name comes from what this client already holds: the one league the
  /// golfer is in. Where that cannot answer, the words the page already uses
  /// stand — `In your seasons` — rather than a guessed name. (The web also
  /// asks the roster of the league on screen; this screen holds no roster.)
  private func relTag(_ sr: ScheduledRound) -> String? {
    guard !sr.isMine else { return nil }
    if sr.is_friend == true { return "Buddy" }
    guard sr.shared_league == true else { return nil }
    let crews = (store.me?.memberships ?? []).filter { $0.sandbox != true }
    if crews.count == 1, !crews[0].name.isEmpty { return "In \(crews[0].name)" }
    return "In your seasons"
  }

  // MARK: the grid (12072–12088)

  private var calendarHeader: some View {
    HStack {
      Spacer()
      monthStep(back: true) { vm.page(-1, me: store.me, current: store.preferredLeague) }
      Text(vm.month.title).csType(.name).foregroundStyle(cs.ink).frame(minWidth: 84)
      monthStep(back: false) { vm.page(1, me: store.me, current: store.preferredLeague) }
    }
  }

  /// A day was tapped: an empty day opens a new plan on it, a day with
  /// something on it opens the day. The grid draws; the screen decides.
  private func open(day d: Int) {
    let iso = vm.month.iso(d)
    let items = vm.byDay[d] ?? []
    if items.isEmpty { declare = DeclarePrefill(iso: iso) }
    else { day = DaySheet(iso: iso, items: items, canAdd: iso >= vm.today) }
  }

  // MARK: the day sheet (12093–12130)

  private func daySheet(_ d: DaySheet) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        CSSheetHeader(title: ScheduleDates.long(d.iso), sub: "\(d.items.count) on the schedule")   // the sub's role sets the caps
        ForEach(Array(d.items.enumerated()), id: \.offset) { _, it in
          switch it {
          case .round(let sr):
            // N4-133 · the person is the row's one button (it was a tap gesture)
            RoomLineRow(face: Faces.of(sr.profile_id, marker: sr.marker, name: sr.display_name, isViewer: sr.isMine), title: rowTitle(sr), sub: dayBits(sr).map(Text.init),
                        onTap: { if let id = sr.id { day = nil; open(id) } }, hint: "Opens the plan") {
              if sr.isMine, let id = sr.id { ownerActions(sr, id: id) }
            }
          case .league(let text, let gold):
            HStack(spacing: CSTokens.Space.s3) {
              CSGlyph(.calendar, size: .row).foregroundStyle(cs.mut)
              // the flag used to paint the row's TITLE gold; a season date is a
              // date, so the row is ink and the flag is spent nowhere
              Text(text).csType(.name).foregroundStyle(cs.ink)
              Spacer()
            }
            .padding(.vertical, CSTokens.Space.s3).frame(minHeight: 52)
            .overlay(alignment: .bottom) { CSRule() }
          }
        }
        if d.canAdd {
          Button("Put your round on this day") { day = nil; declare = DeclarePrefill(iso: d.iso) }
            .buttonStyle(.csPrimary()).padding(.top, CSTokens.Space.s2)
        }
      }
      .padding(20)
    }
    .background(cs.bg0)
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }

  private func rowTitle(_ sr: ScheduledRound) -> Text {
    var t = Text(sr.who)
    // F-10 · one fact, one metal — and NEITHER of these is earned. A tee time
    // is a clock and a membership is a membership; the sibling producer two
    // functions up already draws both in `ink`, so the schedule was saying the
    // same two facts in two different metals on one screen.
    if let tee = sr.tee_time, !TeeTime.format(tee).isEmpty { t = t + Text(" · ") + Text(TeeTime.format(tee)).foregroundStyle(cs.ink) }
    // W2 · the answer off `my_rsvp` — YOU'RE IN only for an explicit yes,
    // ASKED for a tag nobody answered — and then the crew, both in the web's
    // words (`csPlanMe`, `csPlanRel`); the row's `name` role sets the case
    if let a = answer(sr) { t = t + Text(" · ") + Text(a.said).foregroundStyle(a == .yes ? cs.ink : cs.mut) }
    if let rel = relTag(sr) { t = t + Text(" · ") + Text(rel).foregroundStyle(cs.mut) }
    return t
  }

  /// N4-135 · nil when the plan has nothing more to say: every row of the
  /// day sheet under its "on the schedule" head said ON THE SCHEDULE again,
  /// where the title's own answer ("You’re in") already carries the state
  /// (L-34).
  private func dayBits(_ sr: ScheduledRound) -> String? {
    let bits = [sr.course_label, sr.withLine, sr.note.flatMap { $0.isEmpty ? nil : "“\($0)”" }].compactMap { $0 }
    return bits.isEmpty ? nil : bits.joined(separator: " · ")
  }

  private func ownerActions(_ sr: ScheduledRound, id: UUID) -> some View {
    HStack(spacing: CSTokens.Space.s2) {
      CSMini("", glyph: .plus) { day = nil; retag = RetagRequest(roundId: id, iso: sr.play_on ?? vm.today, courseLabel: sr.course_label, tagged: []) }
        .accessibilityLabel("Edit group")
      CSArmedButton(label: "✕", armedLabel: "Sure?", busy: vm.busy.contains(id)) {
        Task { if await vm.scratch(id) { day = nil } }
      }
      .accessibilityLabel("Cancel this round")
    }
  }

  /// W7-040 · rows on screen and a refresh that failed: the rows stay, and
  /// one line says so, with the way to ask again (the album's shape).
  @ViewBuilder private var refreshFailed: some View {
    if vm.failedWhy != nil, vm.hasRows {
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        Text(ScheduleCopy.refreshFailed).csType(.bodyS).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
        CSDoor(.link(ScheduleCopy.retry) { Task { await vm.reload(me: store.me, current: store.preferredLeague) } })
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier("schedule.refreshFailed")
    }
  }

  // MARK: on the schedule (12134–12153)

  @ViewBuilder private var list: some View {
    let rows = vm.listRows
    if rows.isEmpty, let why = vm.failedWhy, !vm.hasRows {
      // W7-040 · a failed read with nothing to show is never an empty one: the
      // album's failed shape, the head, the reason and Try again. "Put a round
      // on the schedule" stays the page's one primary (§7.1).
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        Text(ScheduleCopy.failedHead).csType(.lead).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityAddTraits(.isHeader)
        Text(why).csType(.bodyS).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
        CSMini(ScheduleCopy.retry) { Task { await vm.reload(me: store.me, current: store.preferredLeague) } }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier("schedule.failed")
    } else if rows.isEmpty {
      CSFine("Nothing on the schedule for \(vm.month.monthName). Put one up: buddies and the crews you play with see it the moment you do.")
    } else {
      ForEach(rows) { sr in
        // N4-133 · the person is the row's one button (it was a tap gesture)
        RoomLineRow(face: Faces.of(sr.profile_id, marker: sr.marker, name: sr.display_name, isViewer: sr.isMine), title: rowTitle(sr), sub: Text(listBits(sr)),
                    onTap: { if let id = sr.id { open(id) } }, hint: "Opens the plan") {
          HStack(spacing: CSTokens.Space.s2) {
            Text(sr.play_on.map { ScheduleDates.whenDays($0, today: vm.today) } ?? "").csType(.agateS, caps: true).foregroundStyle(cs.mut)
            if sr.isMine, let id = sr.id {
              CSMini("", glyph: .plus) { retag = RetagRequest(roundId: id, iso: sr.play_on ?? vm.today, courseLabel: sr.course_label, tagged: []) }
                .accessibilityLabel("Tag your group")
              CSArmedButton(label: "✕", armedLabel: "Sure?", busy: vm.busy.contains(id)) { Task { _ = await vm.scratch(id) } }
                .accessibilityLabel("Cancel this round")
            }
          }
        }
      }
    }
  }

  private func listBits(_ sr: ScheduledRound) -> String {
    var s = sr.play_on.map(ScheduleDates.long) ?? ""
    if let c = sr.course_label { s += " · \(c)" }
    if let w = sr.withLine { s += " · \(w)" }
    if let n = sr.note, !n.isEmpty { s += " · “\(n)”" }
    return s
  }

  // MARK: week by week (12155–12170)

  @ViewBuilder private var weeks: some View {
    if vm.inLeague {
      CSSectionHead("Week by week")
      if vm.weekLines.isEmpty {
        CSFine(WeekLine.empty)
      } else {
        // rows on ground with hairlines, not a card (IOS-019 rule 2)
        VStack(spacing: 0) {
          ForEach(Array(vm.weekLines.enumerated()), id: \.element.id) { i, w in
            CSRow(last: i == vm.weekLines.count - 1) {
              HStack(spacing: CSTokens.Space.s3) {
                Text(w.text).csType(.bodyS).foregroundStyle(cs.mut)
                Spacer()
                Text(w.points).csType(.columnM).foregroundStyle(cs.ink)
              }
            }
          }
        }
      }
    }
  }
}

struct DaySheet: Identifiable {
  let iso: String
  let items: [CalendarItem]
  let canAdd: Bool
  var id: String { iso }
}


@MainActor
@Observable
final class ScheduleModel {
  var month = CalendarMonth.of(CSDate.today())
  var today = CSDate.today()
  var schedule: [ScheduledRound] = []
  var watchAll: [ScheduledRound] = []
  var rivals: [Rpc.my_rivalries.Row] = []
  var byDay: [Int: [CalendarItem]] = [:]
  var weekLines: [WeekLine] = []
  var inLeague = false
  var busy = Set<UUID>()
  /// W7-040 · why the last read failed (the month's or the next fortnight's),
  /// in the product's words. A failed read is never an empty one: the rows
  /// the page had stay, and the page says it could not read them.
  var failedWhy: String?
  var hasRows: Bool { !watchRows.isEmpty || !listRows.isEmpty }
  /// N4-136 · the first load may move the calendar to the next plan's month
  private var openingSettled = false
  private let toasts: CSToastCenter
  private let sched = ScheduleService()

  init(toasts: CSToastCenter) { self.toasts = toasts }

  var watchRows: [ScheduledRound] { CalendarBuilder.watchRows(watchAll, today: today) }
  var listRows: [ScheduledRound] { CalendarBuilder.listRows(month: month, schedule: schedule, today: today) }
  func row(_ id: UUID) -> ScheduledRound? { (schedule + watchAll).first { $0.id == id } }

  func page(_ by: Int, me: Me?, current: UUID?) {
    month = by < 0 ? month.prev : month.next
    CSHaptic.selection()
    Task { await reload(me: me, current: current) }
  }

  func reload(me: Me?, current: UUID?) async {
    today = CSDate.today()
    async let m = sched.month(month)
    async let w = sched.watch(today: today)
    async let r = RivalsCache.shared.rivals()
    var why: String?
    do { schedule = try await m } catch { why = HumanError.text(error) }
    do { watchAll = try await w } catch { why = why ?? HumanError.text(error) }
    failedWhy = why
    // N4-136 · on the first load, a month with no plan still ahead opens on
    // the month of the next one instead (September was shown while the
    // plans were in October); paging is the golfer's from then on
    if !openingSettled {
      openingSettled = true
      let ahead = schedule.contains { ($0.play_on ?? "") >= today }
      if !ahead, let next = watchAll.compactMap(\.play_on).filter({ $0 >= today }).min() {
        let target = CalendarMonth.of(next)
        if target != month {
          month = target
          if let rows = try? await sched.month(month) { schedule = rows }
        }
      }
    }
    rivals = await r
    let memberships = me?.memberships ?? []
    let cur = memberships.first { $0.league_id == current } ?? memberships.first
    let spans = LeagueSpan.from(memberships)
    byDay = CalendarBuilder.items(month: month, schedule: schedule, spans: spans, current: cur?.league_id)
    // week-by-week history: league seasons only (state.phase==='season' && seasonStart)
    inLeague = cur?.phase == "season" && cur?.season != nil
    if inLeague, let s = cur?.season {
      async let snaps = sched.snapshots(season: s.id)
      async let names = sched.squadNames(season: s.id)
      weekLines = WeekLine.build((try? await snaps) ?? [], squadNames: (try? await names) ?? [:])
    } else { weekLines = [] }
  }

  func scratch(_ id: UUID) async -> Bool {
    busy.insert(id); defer { busy.remove(id) }
    do {
      try await sched.scratch(id)
      toasts.show("Round scratched")
      schedule.removeAll { $0.id == id }; watchAll.removeAll { $0.id == id }
      return true
    } catch { toasts.show(HumanError.text(error, prefix: "Scratch failed.")); return false }
  }

  /// W2 · "I'm in" on a plan that names you is the same answer the plan's
  /// sheet gives (`set_round_rsvp`, D69), never a second booking beside it.
  /// The caller reloads, so the row then says "You're in" off `my_rsvp`.
  func answerIn(_ id: UUID) async -> Bool {
    busy.insert(id); defer { busy.remove(id) }
    do {
      try await sched.rsvp(id, status: "in")
      CSHaptic.selection()
      toasts.show("You’re in")
      return true
    } catch { toasts.show(HumanError.text(error, prefix: "RSVP did not save.")); return false }
  }
}

#Preview("Calendar") {
  NavigationStack { ScheduleScreen() }.environment(SessionStore()).csTheme()
}

// MARK: - the calendar's own two parts (Wave 8)

extension ScheduleScreen {
  /// The month pager's step. A `CSMini` with a chevron pointed one way for
  /// both directions was two controls saying the same thing; the glyph turns.
  @ViewBuilder func monthStep(back: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      CSGlyph(.chevron, size: .row)
        .rotationEffect(.degrees(back ? 180 : 0))
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(back ? "Previous month" : "Next month")
  }
}

// MARK: - the month grid (F15)

/// **One month, seven columns, and every day a 44 × 44 target** (F15,
/// 2026-09-28).
///
/// The grid laid seven flexible columns across the band with a 4pt gap between
/// each, so on a 375pt phone the page's two 20s, the band's two 12s and six 4s
/// left (375 − 40 − 24 − 24) / 7 = **41pt** a day — a `minHeight: 44` on a
/// 41pt-wide target is not a 44pt target. The columns now touch: seven days
/// share the band's whole width, 44.4pt each at 375 and 48.3 at 402, and each
/// day's tap region is its own column, edge to edge, so two dates never share
/// a point of hit space and none has less than 44. The 4pt the eye saw between
/// tiles is kept where it was visible — today's panel is inset s1/2 a side
/// inside its own target — so the drawing does not change and the target does.
struct ScheduleMonthGrid: View {
  @Environment(\.cs) private var cs
  let month: CalendarMonth
  let byDay: [Int: [CalendarItem]]
  let today: String
  let open: (Int) -> Void

  var body: some View {
    // The month grid sits on the raised ground with no border — a card round a
    // calendar is a container with no job (non-negotiable 1).
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      VStack(spacing: 8) {
        // **A MONTH IS A GRID OF WEEKS, LAID OUT WHOLE.** It was a
        // `LazyVGrid`, and on a real phone the band measured it at one height
        // and drew it at another on some launches — the band's ground stopped
        // short of the weekday letters and the last legend key (F15's capture
        // round). Six weeks of seven days is nothing to be lazy about: a
        // `Grid` sizes what it draws, every time. It also retires the lazy
        // grid's key collision, which keyed the leading blanks 0, 1, 2… like
        // the 1st, 2nd, 3rd and dropped a mid-week month's first days
        // (September 2026 drew no 1st, May 2026 no 1st to 4th): each week is
        // its own row now, and a blank is a place in a row, not a key.
        Grid(horizontalSpacing: 0, verticalSpacing: 4) {
          GridRow {
            ForEach(ScheduleDates.dow, id: \.self) { d in
              Text(String(d.prefix(1))).csType(.agateS, caps: true).foregroundStyle(cs.mut)
                .frame(maxWidth: .infinity)
            }
          }
          ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
            GridRow {
              ForEach(0..<7, id: \.self) { i in
                if let d = week[i] { cell(d) } else { Color.clear.frame(maxWidth: .infinity, minHeight: 44) }
              }
            }
          }
        }
        // **A LEGEND KEY IS TAXONOMY, AND TAXONOMY IS NEVER GOLD** (§4,
        // D269: gold reachable from a legend key is gold as chrome). The
        // three channels are the live metal, ink and `mut` — three tones a
        // golfer can tell apart without one of them being the earned one.
        //
        // The keys are a COLUMN, one to a line, at every size (F15). In one
        // row they broke `SCHEDULE` into `SCHEDU/LE` and `SEASON` into
        // `SEASO/N` at AX3; and both a row-or-column `ViewThatFits` and a
        // wrapping flow here were measured by the band at one width and
        // drawn at another on a real phone — the last key printed under
        // the band, on some launches and not others. A column's height does
        // not depend on the width it is offered, so the band always holds it.
        VStack(alignment: .leading, spacing: CSTokens.Space.s2) { legends }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.top, 4)
      }
    }
    .padding(CSTokens.Space.s3)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(cs.bg1)
  }

  /// The month as weeks of seven places: the leading blanks, the days, and
  /// the blanks that close the last week.
  private var weeks: [[Int?]] {
    let places: [Int?] = Array(repeating: nil, count: month.leadingBlanks) + (1...month.daysInMonth).map { Optional($0) }
    return stride(from: 0, to: places.count, by: 7).map { i in
      let week = Array(places[i..<min(i + 7, places.count)])
      return week + Array(repeating: nil, count: 7 - week.count)
    }
  }

  @ViewBuilder private var legends: some View {
    legend(.round, "ON THE SCHEDULE"); legend(.leagueMate, "IN YOUR SEASONS"); legend(.season, "SEASON DATE")
  }

  private func legend(_ k: CalendarItem.Dot, _ t: String) -> some View {
    HStack(spacing: CSTokens.Space.s1) { mark(k).frame(width: 9, alignment: .center); Text(t).csType(.agateS, caps: true).foregroundStyle(cs.mut) }
  }

  /// N4-132 · **COLOUR IS NEVER THE ONLY CHANNEL** (UI_SYSTEM §16.4): the three
  /// kinds of day were one dot in three tints. As the web's `.caldot` draws
  /// them: a round you are on is a filled disc (act), a round in your seasons
  /// a ring (ink), a season date a bar (mut). D359 / F4 · a routine plan is
  /// not competition: the ordinary colour, never ember.
  @ViewBuilder private func mark(_ k: CalendarItem.Dot) -> some View {
    switch k {
    case .round: Circle().fill(cs.act).frame(width: 7, height: 7)
    case .leagueMate: Circle().strokeBorder(cs.ink, lineWidth: 1.5).frame(width: 7, height: 7)
    case .season: Rectangle().fill(cs.mut).frame(width: 9, height: 2)
    }
  }

  private func cell(_ d: Int) -> some View {
    let iso = month.iso(d)
    let items = byDay[d] ?? []
    let isToday = iso == today
    let isPast = iso < today
    let tappable = !items.isEmpty || !isPast
    return Button { open(d) } label: {
      VStack(spacing: CSTokens.Space.s1) {
        // on the panel the ink inverts — a `mut` numeral on bone is the light
        // theme's worst contrast, and today's cell is the one that must read
        // N4-131 · a date is capped to its own cell: at SE3 AX3 the two-digit
        // numerals ran into their neighbours ('101112'). It shrinks only when
        // it would not fit, and never wraps.
        Text("\(d)").csType(.columnS)
          .lineLimit(1).minimumScaleFactor(0.5)
          .frame(maxWidth: .infinity)
          .foregroundStyle(isToday ? cs.panelInk : (isPast && items.isEmpty ? cs.mut : cs.ink))
        HStack(spacing: 2) {
          ForEach(Array(items.prefix(3).enumerated()), id: \.offset) { _, it in mark(it.dot) }
        }
        .frame(height: 7)
      }
      .frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
      // today is the panel, not an ember outline — a day is not a live action.
      // The panel is inset inside the day's own target, so the tile keeps the
      // gap the eye knew while the target keeps the whole column.
      .background {
        if isToday {
          RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous)
            .fill(cs.panel)
            .padding(.horizontal, CSTokens.Space.s1 / 2)
        }
      }
      .contentShape(Rectangle())
    }
    // N4-132 · a past, empty day is still not a target (`.disabled`, which
    // VoiceOver reads as dimmed), but the plain style's system dimming sat on
    // top of the numeral's own mut — dimmed twice, ~2.6:1 dark and 2.1:1
    // light. This style draws the day as it is, and mut is the only tier.
    .buttonStyle(CalendarDayStyle())
    .disabled(!tappable)
    .accessibilityLabel("\(ScheduleDates.long(iso))\(items.isEmpty ? "" : ", \(items.count) on the schedule")")
    .accessibilityIdentifier("schedule.day.\(d)")
  }
}

/// N4-132 · a calendar day drawn as it is, enabled or not: a custom style is
/// never dimmed by the system, so a past day's mut is the one tier it wears.
/// Pressed, it answers the finger.
private struct CalendarDayStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.opacity(configuration.isPressed ? 0.7 : 1)
  }
}

/// W7-040 · the schedule's failed read, in the desk's words (`csRenderPlanLead`)
enum ScheduleCopy {
  static let failedHead = "The schedule didn\u{2019}t load"
  static let refreshFailed = "The schedule didn\u{2019}t refresh."
  static let retry = "Try again"
}
