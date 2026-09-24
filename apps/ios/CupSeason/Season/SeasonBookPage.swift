import SwiftUI
import Charts
import CSDesign
import CupSeasonKit

/// The real Book renderer. Fixtures enter only through the DEBUG initializer.
struct SeasonBookPage: View {
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var livery
  @Environment(\.dynamicTypeSize) private var type
  @Environment(\.dismiss) private var dismiss
  @State private var store: SeasonBookStore
  @State private var mode = "Weeks"
  @State private var group = "golfer"
  @State private var squad = "all"
  @State private var follow = "leaders"
  @State private var week = 1
  @ScaledMetric(relativeTo: .body) private var rowHeight = 64.0
  let leagueID: UUID
  let seasonID: UUID
  let openRound: @MainActor (UUID) -> Void
  #if DEBUG
  private var fixtureOnly = false
  init(fixture: SeasonBookSnapshot, openRound: @escaping @MainActor (UUID) -> Void = { _ in }) {
    leagueID=fixture.league_id; seasonID=fixture.season_id; self.openRound=openRound
    let value=SeasonBookStore(); value.seed(fixture); _store=State(initialValue:value)
    _group=State(initialValue:fixture.hasSquads ? "squad" : "golfer")
    _week=State(initialValue:max(1,fixture.current_week)); fixtureOnly=true
    _mode=State(initialValue:CompeteSelectedFixture.arg("-cs_selected_mode","Weeks"))
    if CompeteSelectedFixture.arg("-cs_selected_group","") == "golfers" { _group=State(initialValue:"golfer") }
  }
  #endif
  init(leagueID: UUID, seasonID: UUID, openRound: @escaping @MainActor (UUID) -> Void) {
    self.leagueID=leagueID; self.seasonID=seasonID; self.openRound=openRound
    let value=SeasonBookStore()
    #if DEBUG
    if CompeteSelectedFixture.on { value.seed(CompeteSelectedFixture.book(leagueID)); fixtureOnly=true; _group=State(initialValue:CompeteSelectedFixture.book(leagueID).hasSquads ? "squad" : "golfer") }
    #endif
    _store=State(initialValue:value)
  }
  private func load() async {
    #if DEBUG
    if fixtureOnly { return }
    #endif
    await store.load(league:leagueID,season:seasonID)
    if let book=store.snapshot { group=book.hasSquads ? "squad" : "golfer"; week=max(1,book.current_week); squad="all" }
  }
  var body: some View {
    ScrollView {
      VStack(alignment:.leading,spacing:CSTokens.Space.s3) {
        CSBackChevron { dismiss() }.padding(.horizontal,CSTokens.Space.gutter)
        CSTopoField(.accent,tint:livery.accent.opacity(CSTokens.Alpha.a56))
          .frame(height:CSTokens.Space.s6).clipped().accessibilityHidden(true)
        Text(store.snapshot.map { SeasonBookSnapshot.prominent(fieldSize:$0.field_size,hasSquads:$0.hasSquads) ? "the Book" : "Rounds & points" } ?? "the Book").csType(.display).accessibilityIdentifier("seasonBook.title").padding(.horizontal,CSTokens.Space.gutter)
        if let book=store.snapshot { content(book) }
        else if let error=store.error {
          VStack(alignment:.leading,spacing:CSTokens.Space.s3) {
            Text(error).csType(.body).accessibilityIdentifier("seasonBook.error")
            CSDoor(.primary("Try again") { Task { await load() } })
          }.padding(CSTokens.Space.gutter)
        } else {
          VStack(alignment:.leading,spacing:CSTokens.Space.s3) {
            Text("The whole season, week by week").csType(.story)
            ForEach(0..<5) { _ in HStack { Text("Golfer"); Spacer(); Text("Points") }.csType(.name).frame(minHeight:64) }
          }.padding(CSTokens.Space.gutter).csRedacted(true).accessibilityLabel("Loading the Book")
        }
      }.padding(.bottom,CSTokens.Space.s5)
    }.clipped().csLookGround().csBareBar().csStatusCap(cs.bg0)
      .task(id:seasonID) { if store.snapshot?.season_id != seasonID || store.snapshot?.league_id != leagueID { await load() } }
      .refreshable { await load() }
  }
  private func rows(_ book: SeasonBookSnapshot) -> [SeasonBookSnapshot.Row] {
    if group == "golfer", squad != "all" { return book.rows.filter { $0.kind == "contribution" && $0.squad_id?.uuidString == squad } }
    return book.rows.filter { $0.kind == group }
  }
  @ViewBuilder private func content(_ book: SeasonBookSnapshot) -> some View {
    let visible=rows(book)
    let prominent=SeasonBookSnapshot.prominent(fieldSize:book.field_size,hasSquads:book.hasSquads)
    VStack(alignment:.leading,spacing:CSTokens.Space.s2) {
      Text(book.name).csType(.story)
      Text(book.rules).csType(.bodyS).foregroundStyle(cs.mut)
      if let note=book.rules_note { Text(note).csType(.bodyS).foregroundStyle(cs.mut) }
      if book.hasSquads {
        Picker("View",selection:$group) { Text("Squads").tag("squad"); Text("Golfers").tag("golfer") }.pickerStyle(.segmented)
        if group == "golfer" {
          Picker("Squad contributions",selection:$squad) {
            Text("Every golfer").tag("all")
            ForEach(book.rows.filter { $0.kind == "squad" }) { Text($0.name).tag($0.squad_id?.uuidString ?? "all") }
          }
          if squad != "all" { Text("Round contributions. Squad adjustments follow below.").csType(.bodyS).foregroundStyle(cs.mut) }
        }
      }
      if prominent { Picker("Display",selection:$mode) { ForEach(["Weeks","Totals","Race"],id:\.self) { Text($0).tag($0) } }
        .pickerStyle(.segmented).accessibilityIdentifier("seasonBook.mode") }
    }.padding(.horizontal,CSTokens.Space.gutter)
    if book.current_week == 0 {
      Text("No standing yet. Weeks begin at first tee.").csType(.story).padding(CSTokens.Space.gutter)
    } else if !prominent {
      ForEach(visible) { row in
        NavigationLink { receipts(row.name,row.entries) } label: {
          HStack { VStack(alignment:.leading) { Text(row.name).csType(.name); Text(row.standing ?? "").csType(.bodyS) }; Spacer(); CSFigure(String(row.points),size:.l,label:"points") }.padding(CSTokens.Space.gutter).contentShape(Rectangle())
        }.buttonStyle(.plain)
      }
    } else if mode == "Race" { race(book,visible) }
    else if type.isAccessibilitySize { accessible(book,visible) }
    else { matrix(book,visible) }
    if book.current_week > 0 && prominent {
      Text("— No round · D Dropped · B Bye · * Adjustment · • Future week. Tap a cell for its rounds and adjustments.")
        .csType(.bodyS).foregroundStyle(cs.mut).padding(.horizontal,CSTokens.Space.gutter)
      adjustments(book,visible)
    }
    Text("Points counting today")
      .csType(.agateS).foregroundStyle(cs.mut).padding(CSTokens.Space.gutter)
  }
  private func matrix(_ book: SeasonBookSnapshot,_ rows: [SeasonBookSnapshot.Row]) -> some View {
    let width=max(64.0,Double(rows.flatMap { row in row.cells.map { SeasonBookSnapshot.label(row:row,cell:$0,cumulative:mode == "Totals").count } }.max() ?? 1)*12)
    return HStack(alignment:.top,spacing:0) {
      VStack(spacing:0) {
        Text(group == "squad" ? "SQUAD / TOTAL" : "GOLFER / TOTAL").csType(.agateS).frame(height:44)
        ForEach(rows) { row in
          NavigationLink { receipts(row.name,row.entries) } label: {
            VStack(alignment:.leading,spacing:CSTokens.Space.s1) {
              Text(short(row.name,squad:group == "squad")).csType(.nameS).lineLimit(2)
              Text("\(row.points) pts").csType(.columnS)
            }.frame(maxWidth:.infinity,alignment:.leading).frame(height:rowHeight)
              .padding(.horizontal,CSTokens.Space.s2).overlay(alignment:.bottom) { CSRule() }.contentShape(Rectangle())
          }.buttonStyle(.plain).accessibilityIdentifier("seasonBook.name.\(row.id)")
        }
      }.frame(width:140).background(cs.bg1)
      ScrollView(.horizontal) {
        VStack(spacing:0) {
          HStack(spacing:0) {
            ForEach(book.weeks) { w in
              VStack(spacing:0) { Text("W\(w.week)"); Text(CSDate.short(w.starts_on)) }.csType(.agateS)
                .frame(width:width,height:44)
                .foregroundStyle(book.live && w.week == book.current_week ? cs.brandInk : cs.ink)
                .background(book.live && w.week == book.current_week ? cs.brand : cs.bg1)
            }
          }
          ForEach(rows) { row in
            HStack(spacing:0) {
              ForEach(row.cells,id:\.week) { cell in
                NavigationLink { receipts("\(row.name) · Week \(cell.week)",SeasonBookSnapshot.selectedEntries(row,week:cell.week,cumulative:mode == "Totals")) } label: {
                  Text(SeasonBookSnapshot.label(row:row,cell:cell,cumulative:mode == "Totals")).csType(.columnM)
                    .frame(width:width,height:rowHeight).overlay(alignment:.bottom) { CSRule() }.contentShape(Rectangle())
                }.buttonStyle(.plain).disabled(cell.future)
                  .accessibilityLabel("\(row.name), \(SeasonBookSnapshot.spoken(row:row,cell:cell,cumulative:mode == "Totals"))")
                  .accessibilityIdentifier("seasonBook.cell.\(row.id).\(cell.week)")
              }
            }
          }
        }
      }
    }
  }
  private func accessible(_ book: SeasonBookSnapshot,_ rows: [SeasonBookSnapshot.Row]) -> some View {
    VStack(alignment:.leading,spacing:CSTokens.Space.s3) {
      Picker("Week",selection:$week) { ForEach(book.weeks) { Text("Week \($0.week)").tag($0.week) } }
        .accessibilityIdentifier("seasonBook.week")
      ForEach(rows) { row in
        if let cell=row.cells.first(where: { $0.week == week }) {
          NavigationLink { receipts("\(row.name) · Week \(week)",SeasonBookSnapshot.selectedEntries(row,week:week,cumulative:mode == "Totals")) } label: {
            VStack(alignment:.leading,spacing:CSTokens.Space.s2) {
              Text(row.name).csType(.name)
              Text(SeasonBookSnapshot.spoken(row:row,cell:cell,cumulative:mode == "Totals")).csType(.body)
            }.frame(maxWidth:.infinity,alignment:.leading).padding(.vertical,CSTokens.Space.s3).overlay(alignment:.bottom) { CSRule() }.contentShape(Rectangle())
          }.buttonStyle(.plain).disabled(cell.future)
        }
      }
    }.padding(.horizontal,CSTokens.Space.gutter)
  }
  private func race(_ book: SeasonBookSnapshot,_ rows: [SeasonBookSnapshot.Row]) -> some View {
    let selected=rows.first { $0.id == follow }
    let leaders=Array(rows.sorted { $0.points > $1.points }.prefix(3))
    let plotted=selected.map { [$0]+leaders.filter { $0.id != selected?.id }.prefix(2) } ?? leaders
    let domain=SeasonBookSnapshot.raceDomain(plotted)
    return VStack(alignment:.leading,spacing:CSTokens.Space.s3) {
      Text("Points counting today").csType(.displayS).accessibilityIdentifier("seasonBook.race.title")
      Text("Points included today, grouped by week played or assessed. Later drops restate earlier weeks; this is not a historical rank chart.").csType(.bodyS).foregroundStyle(cs.mut)
      Picker("Follow",selection:$follow) {
        Text("Leading three").tag("leaders")
        ForEach(rows) { Text($0.name).tag($0.id) }
      }
      if plotted.contains(where: { $0.unplaced_points != 0 }) {
        Text("Some adjustments fall outside the season weeks. Open the totals below for the complete record; a weekly curve would omit those points.").csType(.body)
      } else {
        Chart {
          ForEach(Array(plotted.enumerated()),id:\.element.id) { index,row in
            ForEach(row.cells.filter { !$0.future },id:\.week) { cell in
              if let value=cell.cumulative {
                LineMark(x:.value("Week",cell.week),y:.value("Points",value),series:.value("Golfer",row.id))
                  .foregroundStyle(cs.ink).lineStyle(StrokeStyle(lineWidth:index == 0 ? 3 : 2,dash:index == 0 ? [] : [CGFloat(index+2),3]))
              }
            }
          }
          if book.live { RuleMark(x:.value("Current week",book.current_week)).foregroundStyle(cs.brand) }
        }.chartXScale(domain:1...max(2,book.weeks.count)).chartYScale(domain:domain)
          .frame(height:210).padding(CSTokens.Space.s3)
          .background { CSTopoField(.page,tint:livery.accent.opacity(CSTokens.Alpha.a08)) }
        ForEach(Array(plotted.enumerated()),id:\.element.id) { i,row in
          Text("\(i == 0 ? "━" : i == 1 ? "┄" : "┈") \(row.name)").csType(.nameS)
        }
      }
      ForEach(rows) { row in
        NavigationLink { receipts(row.name,row.entries) } label: {
          HStack { Text(row.name); Spacer(); Text("\(row.points) pts") }.csType(.name).frame(minHeight:44).contentShape(Rectangle())
        }.buttonStyle(.plain)
      }
    }.padding(CSTokens.Space.gutter)
  }
  private func adjustments(_ book: SeasonBookSnapshot,_ rows: [SeasonBookSnapshot.Row]) -> some View {
    let sources = group == "golfer" && squad != "all"
      ? book.rows.filter { $0.kind == "squad" && $0.squad_id?.uuidString == squad } : rows
    let entries = sources.flatMap { row in row.entries.filter { !$0.isRound }.map { (name:row.name,entry:$0) } }
    return VStack(alignment:.leading,spacing:CSTokens.Space.s3) {
      Text("Adjustments in the totals").csType(.displayS)
      Text(squad != "all" && group == "golfer" ? "Add these squad adjustments to the round contributions above." : "Already included in the totals. Kept in their assessed week, with their reason.")
        .csType(.bodyS).foregroundStyle(cs.mut)
      if entries.isEmpty { Text("No adjustments recorded for this selection.").csType(.bodyS) }
      ForEach(Array(entries.enumerated()),id:\.offset) { _,item in
        let entry=item.entry
        NavigationLink { receipts(item.name + " · Adjustment",[entry]) } label: {
          VStack(alignment:.leading,spacing:CSTokens.Space.s1) {
            Text("\(item.name) · \(entry.dateLine) · \(entry.contribution) points").csType(.name)
            Text(entry.reason).csType(.bodyS).foregroundStyle(cs.mut)
          }.frame(maxWidth:.infinity,alignment:.leading).padding(.vertical,CSTokens.Space.s2).contentShape(Rectangle())
        }.buttonStyle(.plain)
      }
    }.padding(CSTokens.Space.gutter)
  }
  private func receipts(_ title: String,_ entries: [SeasonBookSnapshot.Entry]) -> some View {
    SeasonBookReceipts(title:title,entries:entries,names:Dictionary((store.snapshot?.rows ?? []).filter { $0.kind == "golfer" }.compactMap { row in row.member_id.map { ($0,row.name) } },uniquingKeysWith:{ a,_ in a }),openRound:openRound)
  }
  private func short(_ name: String,squad: Bool) -> String {
    let parts=name.split(separator:" ")
    return squad || parts.count < 2 ? name : "\(parts[0].prefix(1)). \(parts.dropFirst().joined(separator:" "))"
  }
}

struct SeasonBookReceipts: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let title: String
  let entries: [SeasonBookSnapshot.Entry]
  let names: [UUID:String]
  let openRound: @MainActor (UUID) -> Void
  var body: some View {
    ScrollView {
      VStack(alignment:.leading,spacing:CSTokens.Space.s3) {
        CSBackChevron { dismiss() }
        Text(title).csType(.displayS)
        if entries.isEmpty { Text("No round or adjustment recorded for this selection.").csType(.body) }
        else { Text("\(entries.reduce(0) { $0+$1.contribution }) points").csType(.figureL).accessibilityIdentifier("seasonBook.receipt.total") }
        ForEach(entries) { entry in
          VStack(alignment:.leading,spacing:CSTokens.Space.s2) {
            Text([entry.member_id.flatMap { names[$0] },entry.recorded_on.map { CSDate.short($0) }].compactMap { $0 }.joined(separator:" · ")).csType(.name)
            Text(entry.dateLine).csType(.agateS).foregroundStyle(cs.mut)
            Text("\(entry.points) points · \(entry.count_state == "dropped" ? "dropped" : "\(entry.contribution) included")").csType(.body)
            Text(entry.reason).csType(.bodyS).foregroundStyle(cs.mut)
            if !entry.isRound,let month=entry.affected_month { Text("Applies to \(String(month.prefix(7)))").csType(.agateS).foregroundStyle(cs.mut) }
            if let round=entry.round_id {
              CSDoor(.link("Open round receipt") { openRound(round) })
            }
          }.padding(.vertical,CSTokens.Space.s3).frame(maxWidth:.infinity,alignment:.leading).overlay(alignment:.bottom) { CSRule() }
        }
      }.padding(CSTokens.Space.gutter)
    }.clipped().csLookGround().csBareBar().csStatusCap(cs.bg0)
  }
}
