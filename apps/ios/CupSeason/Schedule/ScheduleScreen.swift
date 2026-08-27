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
        Text("Your golf calendar · yours, your buddies’, your leagues’").csEyebrow()
        watch
        calendarHeader
        grid
        Text("Tap any day to put a round on the tee sheet.").font(CSFont.footnote).foregroundStyle(cs.dimText)
          .frame(maxWidth: .infinity).multilineTextAlignment(.center)
        CSButton("Put a round on the tee sheet") { declare = DeclarePrefill() }
        Text("On the tee sheet").csEyebrow().padding(.top, 6)
        list
        weeks
      }
      .padding(20)
    }
    .background(cs.bg0)
    .navigationTitle("Your golf calendar")
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
      Text("In your crew's plans").csEyebrow()
      ForEach(rows) { sr in
        let rel = sr.is_friend == true ? "BUDDY" : "LEAGUE MATE"
        CSCheckRow(marker: sr.marker, title: Text(sr.display_name ?? "A golfer") + Text("  \(rel)").font(CSFont.label).foregroundStyle(cs.dimText),
                   sub: watchBits(sr)) {
          if sr.tagged_me == true { Text("ON THE TEE SHEET").font(CSFont.label).foregroundStyle(cs.gold) }
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
    if let tee = sr.tee_time, !TeeTime.format(tee).isEmpty { t = t + Text(" · ") + Text(TeeTime.format(tee)).foregroundStyle(cs.gold) }
    if let r = RivalryTag.of(sr.profile_id, rivals: vm.rivals) { t = t + Text(" · ") + Text(r.text).foregroundStyle(cs.gold) }
    if sr.tagged_me == true { t = t + Text(" · ") + Text("YOU’RE IN").foregroundStyle(cs.gold) }
    if let n = sr.note, !n.isEmpty { t = t + Text(" · “\(n)”") }
    return t
  }

  // MARK: the grid (12072–12088)

  private var calendarHeader: some View {
    HStack {
      Text("The calendar").csEyebrow()
      Spacer()
      CSMini("", systemImage: "arrow.left") { vm.page(-1, me: store.me, current: store.preferredLeague) }.accessibilityLabel("Previous month")
      Text(vm.month.title).font(CSFont.monoMediumBody).tracking(1.2).foregroundStyle(cs.ink).frame(minWidth: 84)
      CSMini("", systemImage: "arrow.right") { vm.page(1, me: store.me, current: store.preferredLeague) }.accessibilityLabel("Next month")
    }
  }

  private var grid: some View {
    CSCard(padding: 12) {
      VStack(spacing: 8) {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
          ForEach(ScheduleDates.dow, id: \.self) { d in
            Text(String(d.prefix(1))).font(CSFont.label).foregroundStyle(cs.dimText)
          }
          ForEach(0..<vm.month.leadingBlanks, id: \.self) { _ in Color.clear.frame(height: 44) }
          ForEach(1...vm.month.daysInMonth, id: \.self) { d in cell(d) }
        }
        HStack(spacing: 12) {
          legend(cs.brand, "ON THE TEE SHEET"); legend(cs.gold, "LEAGUE MATE"); legend(cs.dawn, "SEASON DATE")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
      }
    }
  }

  private func legend(_ c: Color, _ t: String) -> some View {
    HStack(spacing: 5) { Circle().fill(c).frame(width: 6, height: 6); Text(t).font(CSFont.label).foregroundStyle(cs.dimText) }
  }

  private func dot(_ k: CalendarItem.Dot) -> Color {
    switch k { case .round: cs.brand; case .leagueMate: cs.gold; case .season: cs.dawn }
  }

  private func cell(_ d: Int) -> some View {
    let iso = vm.month.iso(d)
    let items = vm.byDay[d] ?? []
    let isToday = iso == vm.today
    let isPast = iso < vm.today
    let tappable = !items.isEmpty || !isPast
    return Button {
      if items.isEmpty { declare = DeclarePrefill(iso: iso) }
      else { day = DaySheet(iso: iso, items: items, canAdd: !isPast) }
    } label: {
      VStack(spacing: 3) {
        Text("\(d)").font(CSFont.monoSmall).csTabular().foregroundStyle(isPast && items.isEmpty ? cs.dimText : cs.ink)
        HStack(spacing: 2) {
          ForEach(Array(items.prefix(3).enumerated()), id: \.offset) { _, it in Circle().fill(dot(it.dot)).frame(width: 5, height: 5) }
        }
        .frame(height: 6)
      }
      .frame(maxWidth: .infinity, minHeight: 44)
      .background(isToday ? cs.bg2 : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(isToday ? cs.brand : .clear, lineWidth: 1))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(!tappable)
    .accessibilityLabel("\(ScheduleDates.long(iso))\(items.isEmpty ? "" : ", \(items.count) on the sheet")")
  }

  // MARK: the day sheet (12093–12130)

  private func daySheet(_ d: DaySheet) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        CSSheetHeader(title: ScheduleDates.long(d.iso), sub: "\(d.items.count) ON THE SHEET")
        ForEach(Array(d.items.enumerated()), id: \.offset) { _, it in
          switch it {
          case .round(let sr):
            CSCheckRow(marker: sr.marker, title: rowTitle(sr), sub: Text(dayBits(sr))) {
              if sr.isMine, let id = sr.id { ownerActions(sr, id: id) }
            }
            .contentShape(Rectangle())
            .onTapGesture { if let id = sr.id { day = nil; open(id) } }
          case .league(let text, let gold):
            HStack(spacing: 12) {
              Text("⛳").font(.system(size: 20))
              Text(text).font(CSFont.subhead.weight(.semibold)).foregroundStyle(gold ? cs.gold : cs.ink)
              Spacer()
            }
            .padding(12).frame(minHeight: 52)
            .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
          }
        }
        if d.canAdd {
          CSButton("Put your round on this day", style: .quiet) { day = nil; declare = DeclarePrefill(iso: d.iso) }.padding(.top, 8)
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
    if let tee = sr.tee_time, !TeeTime.format(tee).isEmpty { t = t + Text(" · ") + Text(TeeTime.format(tee)).foregroundStyle(cs.gold) }
    if sr.tagged_me == true { t = t + Text(" · ") + Text("YOU’RE IN").foregroundStyle(cs.gold) }
    else if sr.shared_league == true && !sr.isMine { t = t + Text(" · ") + Text("LEAGUE MATE").foregroundStyle(cs.gold) }
    else if sr.is_friend == true && !sr.isMine { t = t + Text(" · ") + Text("BUDDY").foregroundStyle(cs.mut) }
    return t
  }

  private func dayBits(_ sr: ScheduledRound) -> String {
    let bits = [sr.course_label?.uppercased(), sr.withLine, sr.note.flatMap { $0.isEmpty ? nil : "“\($0)”" }].compactMap { $0 }
    return bits.isEmpty ? "ON THE TEE SHEET" : bits.joined(separator: " · ")
  }

  private func ownerActions(_ sr: ScheduledRound, id: UUID) -> some View {
    HStack(spacing: 6) {
      CSMini("", systemImage: "plus") { day = nil; retag = RetagRequest(roundId: id, iso: sr.play_on ?? vm.today, courseLabel: sr.course_label, tagged: []) }
        .accessibilityLabel("Edit group")
      CSArmedButton(label: "✕", armedLabel: "Sure?", busy: vm.busy.contains(id)) {
        Task { if await vm.scratch(id) { day = nil } }
      }
      .accessibilityLabel("Cancel this round")
    }
  }

  // MARK: on the tee sheet (12134–12153)

  @ViewBuilder private var list: some View {
    let rows = vm.listRows
    if rows.isEmpty {
      CSFine("Nothing on the tee sheet for \(vm.month.monthName). Put one up: league mates and buddies see it the moment you do.")
    } else {
      ForEach(rows) { sr in
        CSCheckRow(marker: sr.marker, title: rowTitle(sr), sub: Text(listBits(sr))) {
          HStack(spacing: 6) {
            Text(sr.play_on.map { ScheduleDates.whenDays($0, today: vm.today) } ?? "").font(CSFont.label).tracking(0.6).foregroundStyle(cs.mut)
            if sr.isMine, let id = sr.id {
              CSMini("", systemImage: "plus") { retag = RetagRequest(roundId: id, iso: sr.play_on ?? vm.today, courseLabel: sr.course_label, tagged: []) }
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
      Text("Week by week").csEyebrow().padding(.top, 6)
      CSCard {
        if vm.weekLines.isEmpty {
          CSFine(WeekLine.empty)
        } else {
          VStack(spacing: 0) {
            ForEach(vm.weekLines) { w in
              HStack(spacing: 10) {
                Text(w.text).font(CSFont.footnote).foregroundStyle(cs.dimText)
                Spacer()
                Text(w.points).font(CSFont.monoSmall).foregroundStyle(cs.ink).csTabular()
              }
              .padding(.vertical, 5)
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
