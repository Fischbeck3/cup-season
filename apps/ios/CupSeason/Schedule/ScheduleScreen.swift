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
        Text("Yours, your buddies’, your seasons’").csType(.agate, caps: true).foregroundStyle(cs.mut)
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
    .navigationTitle("The schedule")
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
        let rel = sr.is_friend == true ? "BUDDY" : "IN YOUR SEASONS"
        RoomLineRow(face: Faces.of(sr.profile_id, marker: sr.marker, name: sr.display_name), title: Text(sr.display_name ?? "A golfer") + Text("  \(rel)").font(CSType.font(.agateS)).foregroundStyle(cs.mut),
                    sub: watchBits(sr)) {
          if sr.tagged_me == true { Text("On the schedule").csType(.agateS, caps: true).foregroundStyle(cs.ink) }   // F-10
          else {
            CSMini("I’m in") {
              declare = DeclarePrefill(iso: sr.play_on, course: sr.course_label ?? "", tee: sr.tee_time, courseId: sr.course_id,
                                       tagPids: [sr.profile_id].compactMap { $0 }, hostName: sr.display_name)
            }
          }
        }
        .contentShape(Rectangle())
        .onTapGesture { if let id = sr.id { open(id) } }
      }
    }
  }

  private func watchBits(_ sr: ScheduledRound) -> Text {
    var t = Text(sr.play_on.map { ScheduleDates.when($0) } ?? "")
    if let c = sr.course_label { t = t + Text(" · \(c.uppercased())") }
    if let tee = sr.tee_time, !TeeTime.format(tee).isEmpty { t = t + Text(" · ") + Text(TeeTime.format(tee)).foregroundStyle(cs.ink) }   // F-10 · a clock
    // brand-canon §4 · a rivalry is a RELATIONSHIP, not something won: `ink`.
    if let r = RivalryTag.of(sr.profile_id, rivals: vm.rivals) { t = t + Text(" · ") + Text(r.text).foregroundStyle(cs.ink) }
    if sr.tagged_me == true { t = t + Text(" · ") + Text("YOU’RE IN").foregroundStyle(cs.ink) }   // F-10
    if let n = sr.note, !n.isEmpty { t = t + Text(" · “\(n)”") }
    return t
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
        CSSheetHeader(title: ScheduleDates.long(d.iso), sub: "\(d.items.count) ON THE SCHEDULE")
        ForEach(Array(d.items.enumerated()), id: \.offset) { _, it in
          switch it {
          case .round(let sr):
            CSCheckRow(face: Faces.of(sr.profile_id, marker: sr.marker, name: sr.display_name, isViewer: sr.isMine), title: rowTitle(sr), sub: Text(dayBits(sr))) {
              if sr.isMine, let id = sr.id { ownerActions(sr, id: id) }
            }
            .contentShape(Rectangle())
            .onTapGesture { if let id = sr.id { day = nil; open(id) } }
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
    if sr.tagged_me == true { t = t + Text(" · ") + Text("YOU’RE IN").foregroundStyle(cs.ink) }
    else if sr.shared_league == true && !sr.isMine { t = t + Text(" · ") + Text("IN YOUR SEASONS").foregroundStyle(cs.mut) }
    else if sr.is_friend == true && !sr.isMine { t = t + Text(" · ") + Text("BUDDY").foregroundStyle(cs.mut) }
    return t
  }

  private func dayBits(_ sr: ScheduledRound) -> String {
    let bits = [sr.course_label?.uppercased(), sr.withLine, sr.note.flatMap { $0.isEmpty ? nil : "“\($0)”" }].compactMap { $0 }
    return bits.isEmpty ? "ON THE SCHEDULE" : bits.joined(separator: " · ")
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

  // MARK: on the schedule (12134–12153)

  @ViewBuilder private var list: some View {
    let rows = vm.listRows
    if rows.isEmpty {
      CSFine("Nothing on the schedule for \(vm.month.monthName). Put one up: buddies and the crews you play with see it the moment you do.")
    } else {
      ForEach(rows) { sr in
        RoomLineRow(face: Faces.of(sr.profile_id, marker: sr.marker, name: sr.display_name, isViewer: sr.isMine), title: rowTitle(sr), sub: Text(listBits(sr))) {
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
        .contentShape(Rectangle())
        .onTapGesture { if let id = sr.id { open(id) } }
      }
    }
  }

  private func listBits(_ sr: ScheduledRound) -> String {
    var s = sr.play_on.map(ScheduleDates.longUpper) ?? ""
    if let c = sr.course_label { s += " · \(c.uppercased())" }
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
    if let rows = try? await m { schedule = rows }
    if let rows = try? await w { watchAll = rows }
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
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
          ForEach(ScheduleDates.dow, id: \.self) { d in
            Text(String(d.prefix(1))).csType(.agateS, caps: true).foregroundStyle(cs.mut)
          }
          // **A BLANK IS NEVER A DAY.** The lazy grid keys its children across
          // both `ForEach`es, and the blanks were keyed 0, 1, 2… — the same
          // keys as the 1st, 2nd, 3rd — so a month that opens mid-week lost
          // its first days: September 2026 drew no 1st, May 2026 no 1st to
          // 4th. Blanks are keyed below zero, where no date lives.
          ForEach((0..<month.leadingBlanks).map { -1 - $0 }, id: \.self) { _ in Color.clear.frame(height: 44) }
          ForEach(1...month.daysInMonth, id: \.self) { d in cell(d) }
        }
        // **A LEGEND KEY IS TAXONOMY, AND TAXONOMY IS NEVER GOLD** (§4,
        // D269: gold reachable from a legend key is gold as chrome). The
        // three channels are the live metal, ink and `mut` — three tones a
        // golfer can tell apart without one of them being the earned one.
        //
        // The keys FLOW (F15): each key is one unbreakable unit and a key
        // that does not fit the line starts the next one. Three keys in one
        // row broke `SCHEDULE` into `SCHEDU/LE` and `SEASON` into `SEASO/N`
        // at AX3, and a row-or-column `ViewThatFits` here drew the column
        // while the band had been measured for the row, so the last key
        // printed under the band. A layout sizes what it places.
        FlowLayout(spacing: CSTokens.Space.s3) { legends }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.top, 4)
      }
    }
    .padding(CSTokens.Space.s3)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(cs.bg1)
  }

  @ViewBuilder private var legends: some View {
    legend(cs.act, "ON THE SCHEDULE"); legend(cs.ink, "IN YOUR SEASONS"); legend(cs.mut, "SEASON DATE")
  }

  private func legend(_ c: Color, _ t: String) -> some View {
    HStack(spacing: CSTokens.Space.s1) { Circle().fill(c).frame(width: 6, height: 6); Text(t).csType(.agateS, caps: true).foregroundStyle(cs.mut) }
  }

  private func dot(_ k: CalendarItem.Dot) -> Color {
    // D359 / F4 · a routine plan is not competition: the ordinary colour, never ember
    switch k { case .round: cs.act; case .leagueMate: cs.ink; case .season: cs.mut }
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
        Text("\(d)").csType(.columnS)
          .foregroundStyle(isToday ? cs.panelInk : (isPast && items.isEmpty ? cs.mut : cs.ink))
        HStack(spacing: 2) {
          ForEach(Array(items.prefix(3).enumerated()), id: \.offset) { _, it in Circle().fill(dot(it.dot)).frame(width: 5, height: 5) }
        }
        .frame(height: 6)
      }
      .frame(maxWidth: .infinity, minHeight: 44)
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
    .buttonStyle(.plain)
    .disabled(!tappable)
    .accessibilityLabel("\(ScheduleDates.long(iso))\(items.isEmpty ? "" : ", \(items.count) on the schedule")")
    .accessibilityIdentifier("schedule.day.\(d)")
  }
}
