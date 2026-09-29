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
  /// W5 · the payload the app already holds, for the one fact the Book's own
  /// read does not carry: the crown its season stores. Optional, so a Book
  /// drawn anywhere without a session still draws.
  @Environment(SessionStore.self) private var session: SessionStore?
  @State private var store: SeasonBookStore
  @State private var mode = "Weeks"
  @State private var group = "golfer"
  @State private var squad = "all"
  @State private var follow = "leaders"
  @State private var week = 1
  @ScaledMetric(relativeTo: .body) private var rowHeight = 64.0
  /// F11 · how far a cell's status marks sit above the figure's baseline — a
  /// record note beside the number, never another digit of it.
  @ScaledMetric(relativeTo: .caption2) private var marksLift = 5.0
  /// W5 · the race's end labels: one label's run per character, and the
  /// distance between two labels in their column (the desk's 6.8 and 16 at
  /// 12pt), both growing with the text.
  @ScaledMetric(relativeTo: .caption) private var raceChar: CGFloat = 6.8
  @ScaledMetric(relativeTo: .caption) private var raceLine: CGFloat = 16
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
        VStack(alignment:.leading,spacing:CSTokens.Space.s3) {
          CSBackChevron { dismiss() }
          // W5 · a display title that opened on a lowercase article read as a
          // typo: the page is "The Book"; running copy keeps "the Book"
          Text(store.snapshot.map { SeasonBookSnapshot.prominent(fieldSize:$0.field_size,hasSquads:$0.hasSquads) ? "The Book" : "Rounds & points" } ?? "The Book")
            .csType(.display).accessibilityIdentifier("seasonBook.title")
              .accessibilityAddTraits(.isHeader)   // N4-093 · a screen names itself as a heading
        }.padding(CSTokens.Space.gutter).frame(maxWidth:.infinity,alignment:.leading)
          .background { CSTopoField(.accent,tint:livery.accent).opacity(CSTokens.Alpha.a24) }
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
  /// The crown the Book's season stores, from the league's own season in the
  /// payload — nil for any other season, as on the desk (`CS.season`).
  private func storedSeason(_ book: SeasonBookSnapshot) -> Me.Season? {
    session?.me?.memberships.first { $0.league_id == book.league_id }?.season
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
      Text("Season \(book.number) · \(book.span)").csType(.agateS).foregroundStyle(cs.mut)
      Text(book.rules).csType(.bodyS).foregroundStyle(cs.mut)
      if let note=book.rules_note { Text(note).csType(.bodyS).foregroundStyle(cs.mut) }
      // W5 · a finished Book names its crown: the champion the season stores
      // and the rung that settled a level top, else what the D388 ladder does
      // with a tie. Two "1st · Tied" rows and no champion left it to a guess.
      if let crown=book.crown(stored:storedSeason(book)) {
        VStack(alignment:.leading,spacing:CSTokens.Space.s1) {
          Text(crown.label).csType(.agateS,caps:true).foregroundStyle(cs.mut)
          Text(crown.text).csType(.bodyS).foregroundStyle(cs.ink).fixedSize(horizontal:false,vertical:true)
        }.accessibilityElement(children:.combine).accessibilityIdentifier("seasonBook.crown")
      }
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
      // F11 · the key sits directly ABOVE the grid, beside the Display control
      // that changes what a cell holds. Under a long table it was out of the
      // first view. It explains the marks, so it shows only where marks are
      // drawn: the week grid. Totals carry none, Race has no cells, and the
      // accessibility list speaks every status in words.
      if book.current_week > 0 && prominent && mode == "Weeks" && !type.isAccessibilitySize {
        Text("— No round · D Dropped · B Bye · * Adjustment · • Future week. Tap a cell for its rounds and adjustments.")
          .csType(.bodyS).foregroundStyle(cs.mut).fixedSize(horizontal:false,vertical:true)
          .accessibilityIdentifier("seasonBook.key")
      }
    }.padding(.horizontal,CSTokens.Space.gutter)
    if book.current_week == 0 {
      Text("No standing yet. Weeks begin at first tee.").csType(.story).padding(CSTokens.Space.gutter)
    } else if !prominent {
      ForEach(visible) { row in
        NavigationLink { receipts(row.name,row.entries) } label: {
          HStack { VStack(alignment:.leading) { Text(row.name).csType(.name); Text(row.standingLine ?? "").csType(.bodyS) }; Spacer(); CSFigure(SeasonBookSnapshot.num(row.points),size:.l,label:"points") }.padding(CSTokens.Space.gutter).contentShape(Rectangle())
        }.buttonStyle(.plain)
      }
    } else if mode == "Race" { race(book,visible) }
    else if type.isAccessibilitySize { accessible(book,visible) }
    else { matrix(book,visible) }
    if book.current_week > 0 && prominent {
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
              // W5 twin · the reader's own row is marked, as the web's is
              Text((row.mine ? "You · " : "") + "\(SeasonBookSnapshot.num(row.points)) pts").csType(.columnS)
            }.frame(maxWidth:.infinity,alignment:.leading).frame(height:rowHeight)
              .padding(.horizontal,CSTokens.Space.s2).overlay(alignment:.bottom) { CSRule() }.contentShape(Rectangle())
          }.buttonStyle(.plain).accessibilityIdentifier("seasonBook.name.\(row.id)")
        }
      }.frame(width:140).background(cs.bg1)
      ScrollView(.horizontal) {
        VStack(spacing:0) {
          HStack(spacing:0) {
            ForEach(book.weeks) { w in
              VStack(spacing:0) { Text("W\(w.week)"); Text(CSDate.local(w.starts_on)?.formatted(.dateTime.month(.abbreviated).day()) ?? w.starts_on) }.csType(.agateS)
                .frame(width:width,height:44)
                .accessibilityLabel("Week \(w.week), starting \(CSDate.short(w.starts_on))")
                .foregroundStyle(book.live && w.week == book.current_week ? cs.brandInk : cs.ink)
                .background(book.live && w.week == book.current_week ? cs.brand : cs.bg1)
            }
          }
          ForEach(rows) { row in
            HStack(spacing:0) {
              ForEach(row.cells,id:\.week) { cell in
                NavigationLink { receipts("\(row.name) · Week \(cell.week)",SeasonBookSnapshot.selectedEntries(row,week:cell.week,cumulative:mode == "Totals"),week:true) } label: {
                  cellFace(SeasonBookSnapshot.parts(row:row,cell:cell,cumulative:mode == "Totals"))
                    .frame(width:width,height:rowHeight).overlay(alignment:.bottom) { CSRule() }.contentShape(Rectangle())
                }.buttonStyle(.plain).disabled(cell.future)
                  // F11 · the cell SAYS its status: a mark is never only a letter
                  .accessibilityLabel("\(row.name), \(SeasonBookSnapshot.spoken(row:row,cell:cell,cumulative:mode == "Totals"))")
                  .accessibilityHint(cell.future ? "" : "Opens its rounds and adjustments")
                  .accessibilityIdentifier("seasonBook.cell.\(row.id).\(cell.week)")
              }
            }
          }
        }
      }
    }
  }
  /// F11 · the figure in the column face, its marks beside it in the smaller
  /// agate role and `mut`, lifted off the baseline. The marks are hidden from
  /// assistive tech: the cell's own label already says them in words.
  private func cellFace(_ p: SeasonBookSnapshot.CellParts) -> some View {
    HStack(alignment:.firstTextBaseline,spacing:CSTokens.Space.s1) {
      Text(p.fig).csType(.columnM)
      if !p.marks.isEmpty {
        Text(p.marks).csType(.agateS).foregroundStyle(cs.mut).baselineOffset(marksLift)
          .accessibilityHidden(true)
      }
    }
  }
  private func accessible(_ book: SeasonBookSnapshot,_ rows: [SeasonBookSnapshot.Row]) -> some View {
    VStack(alignment:.leading,spacing:CSTokens.Space.s3) {
      Picker("Week",selection:$week) { ForEach(book.weeks) { Text("Week \($0.week)").tag($0.week) } }
        .accessibilityIdentifier("seasonBook.week")
      ForEach(rows) { row in
        if let cell=row.cells.first(where: { $0.week == week }) {
          NavigationLink { receipts("\(row.name) · Week \(week)",SeasonBookSnapshot.selectedEntries(row,week:week,cumulative:mode == "Totals"),week:true) } label: {
            VStack(alignment:.leading,spacing:CSTokens.Space.s2) {
              Text(row.name).csType(.name)
              Text(SeasonBookSnapshot.spoken(row:row,cell:cell,cumulative:mode == "Totals")).csType(.body)
            }.frame(maxWidth:.infinity,alignment:.leading).padding(.vertical,CSTokens.Space.s3).overlay(alignment:.bottom) { CSRule() }.contentShape(Rectangle())
          }.buttonStyle(.plain).disabled(cell.future)
        }
      }
    }.padding(.horizontal,CSTokens.Space.gutter)
  }
  /// W5 · the race is a printed diagram (§9.10): each line is LABELLED AT ITS
  /// END, in a gutter the x scale leaves beside the plot, hung from the line's
  /// last point by a hairline. The legend of box-drawing glyphs (━ ┄ ┈) under
  /// it had to be matched by eye to three near-identical dashes. The first
  /// line (the golfer followed, or the leader) is ink, the other two mut, the
  /// third dashed as a second channel; the y axis reads from the leading edge
  /// so the labels are the plot's last word. Twin: `csSeasonBookRace`.
  private func race(_ book: SeasonBookSnapshot,_ rows: [SeasonBookSnapshot.Row]) -> some View {
    let plotted=SeasonBookSnapshot.racePlotted(rows,follow:follow)
    let domain=SeasonBookSnapshot.raceDomain(plotted)
    return VStack(alignment:.leading,spacing:CSTokens.Space.s3) {
      Text("Points counting today").csType(.displayS).accessibilityIdentifier("seasonBook.race.title")
      Text("Each golfer’s points as they count today, week by week. A better round later in a month can push an earlier one out, so a past week can change.").csType(.bodyS).foregroundStyle(cs.mut)
      Picker("Follow",selection:$follow) {
        Text("Leading three").tag("leaders")
        ForEach(rows) { Text($0.name).tag($0.id) }
      }
      if plotted.contains(where: { $0.unplaced_points != 0 }) {
        Text("Some adjustments fall outside the season weeks. Open the totals below for the complete record; a weekly curve would omit those points.").csType(.body)
      } else {
        GeometryReader { geo in
          let gutter=raceGutter(plotted,width:geo.size.width)
          Chart {
            ForEach(Array(plotted.enumerated()),id:\.element.id) { index,row in
              ForEach(row.cells.filter { !$0.future },id:\.week) { cell in
                if let value=cell.cumulative {
                  LineMark(x:.value("Week",cell.week),y:.value("Points",value),series:.value("Golfer",row.id))
                    .foregroundStyle(index == 0 ? cs.ink : cs.mut)
                    .lineStyle(StrokeStyle(lineWidth:index == 0 ? 2.5 : 1.75,lineCap:.round,lineJoin:.round,dash:index == 2 ? [5,4] : []))
                }
              }
            }
            if book.live {
              // W5 twin · the live week says so above its rule, "Now · W13",
              // as the web's `.sb-race-now` does (the live week is competition,
              // so its rule and label keep the ember)
              RuleMark(x:.value("Current week",book.current_week)).foregroundStyle(cs.brand)
                .annotation(position:.top,alignment:.center,spacing:CSTokens.Space.s1,
                            overflowResolution:.init(x:.fit(to:.chart),y:.disabled)) {
                  Text("Now · W\(book.current_week)").csType(.agateS,caps:false).foregroundStyle(cs.brand)
                }
            }
          }
          .chartXScale(domain:1...max(2,book.weeks.count),range:.plotDimension(endPadding:gutter+10))
          .chartYScale(domain:domain)
          // room above the plot for the live week's label
          .chartPlotStyle { plot in plot.padding(.top, book.live ? CSTokens.Space.s4 : 0) }
          .chartYAxis {
            AxisMarks(position:.leading) { value in
              AxisGridLine()
              AxisValueLabel { if let points=value.as(Int.self) { Text(SeasonBookSnapshot.num(points)) } }
            }
          }
          .chartOverlay { proxy in raceLabels(proxy,plotted,gutter:gutter) }
        }
        .frame(height:210).padding(CSTokens.Space.s3)
        .background { CSTopoField(.page,tint:livery.accent.opacity(CSTokens.Alpha.a08)) }
      }
      ForEach(rows) { row in
        NavigationLink { receipts(row.name,row.entries) } label: {
          HStack { Text(row.name); Spacer(); Text("\(SeasonBookSnapshot.num(row.points)) pts") }.csType(.name).frame(minHeight:44).contentShape(Rectangle())
        }.buttonStyle(.plain)
      }
    }.padding(CSTokens.Space.gutter)
  }
  /// One race line's end, placed: which line (0 is the ink one), its label,
  /// and the point it hangs from, in the overlay's own space.
  private struct RaceEnd { let line: Int; let label: String; let at: CGPoint }
  /// The label gutter: the longest label's run, never under 60pt and never
  /// over 42% of the chart — the desk's own rule, measured the desk's way.
  private func raceGutter(_ plotted: [SeasonBookSnapshot.Row],width: CGFloat) -> CGFloat {
    let run=plotted.map { (CGFloat(SeasonBookSnapshot.raceLabel($0).count)*raceChar).rounded(.up)+14 }.max() ?? 0
    return min(max(run,60),(width*0.42).rounded())
  }
  private func raceEnds(_ proxy: ChartProxy,_ plotted: [SeasonBookSnapshot.Row],in frame: CGRect) -> [RaceEnd] {
    var ends: [RaceEnd]=[]
    for (i,row) in plotted.enumerated() {
      guard let end=SeasonBookSnapshot.raceEnd(row),let at=proxy.position(for:(x:end.week,y:end.points)) else { continue }
      ends.append(RaceEnd(line:i,label:SeasonBookSnapshot.raceLabel(row),at:CGPoint(x:frame.minX+at.x,y:frame.minY+at.y)))
    }
    return ends
  }
  /// The end labels, in one column that never overlaps itself
  /// (`SeasonBookSnapshot.raceSlots`), each in its line's own ink or mut. The
  /// rows under the chart say every name and total, so the drawing is hidden
  /// from assistive tech rather than read twice.
  private func raceLabels(_ proxy: ChartProxy,_ plotted: [SeasonBookSnapshot.Row],gutter: CGFloat) -> some View {
    GeometryReader { geo in
      if let anchor=proxy.plotFrame {
        let frame=geo[anchor]
        let ends=raceEnds(proxy,plotted,in:frame)
        let slots=SeasonBookSnapshot.raceSlots(ends.map { Double($0.at.y) },gap:Double(raceLine),
                                               top:Double(frame.minY+raceLine/2),bottom:Double(frame.maxY-raceLine/2))
        let edge=frame.maxX-gutter-10   // where the season's last week sits
        ForEach(Array(ends.enumerated()),id:\.offset) { k,end in
          Path { p in
            p.move(to:CGPoint(x:end.at.x+3,y:end.at.y))
            p.addLine(to:CGPoint(x:edge+4,y:CGFloat(slots[k])))
          }.stroke(cs.rule,lineWidth:1)
          Text(end.label).csType(.agate,caps:false).foregroundStyle(end.line == 0 ? cs.ink : cs.mut)
            .lineLimit(1).minimumScaleFactor(0.75)
            .frame(width:gutter,alignment:.leading)
            .position(x:edge+8+gutter/2,y:CGFloat(slots[k]))
        }
      }
    }
    .accessibilityHidden(true)
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
            Text("\(item.name) · \(entry.dateLine) · \(SeasonBookSnapshot.num(entry.contribution)) points").csType(.name)
            Text(entry.reason).csType(.bodyS).foregroundStyle(cs.mut)
          }.frame(maxWidth:.infinity,alignment:.leading).padding(.vertical,CSTokens.Space.s2).contentShape(Rectangle())
        }.buttonStyle(.plain)
      }
    }.padding(CSTokens.Space.gutter)
  }
  private func receipts(_ title: String,_ entries: [SeasonBookSnapshot.Entry],week: Bool = false) -> some View {
    SeasonBookReceipts(title:title,entries:entries,inWeek:week,names:Dictionary((store.snapshot?.rows ?? []).filter { $0.kind == "golfer" }.compactMap { row in row.member_id.map { ($0,row.name) } },uniquingKeysWith:{ a,_ in a }),openRound:openRound)
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
  /// W5 · a week's receipt says the week once, in its head
  var inWeek = false
  let names: [UUID:String]
  let openRound: @MainActor (UUID) -> Void
  var body: some View {
    ScrollView {
      VStack(alignment:.leading,spacing:CSTokens.Space.s3) {
        CSBackChevron { dismiss() }
        Text(title).csType(.displayS)
        if entries.isEmpty { Text("No round or adjustment recorded for this selection.").csType(.body) }
        else { Text("\(SeasonBookSnapshot.num(entries.reduce(0) { $0+$1.contribution })) points").csType(.figureL).accessibilityIdentifier("seasonBook.receipt.total") }
        ForEach(entries) { entry in
          VStack(alignment:.leading,spacing:CSTokens.Space.s2) {
            // W5 twin · a receipt dates its rounds as every receipt does ("Mon Sep 21")
            Text([entry.member_id.flatMap { names[$0] },entry.recorded_on.map { LeagueDates.roundDay($0) }].compactMap { $0 }.joined(separator:" · ")).csType(.name)
            if let place = entry.place(inWeek:inWeek) { Text(place).csType(.agateS).foregroundStyle(cs.mut) }
            Text("\(SeasonBookSnapshot.num(entry.points)) points · \(entry.count_state == "dropped" ? "dropped" : "\(SeasonBookSnapshot.num(entry.contribution)) included")").csType(.body)
            Text(entry.reason).csType(.bodyS).foregroundStyle(cs.mut)
            if !entry.isRound,let month=entry.affected_month { Text("Applies to \(SeasonBookSnapshot.month(month))").csType(.agateS).foregroundStyle(cs.mut) }
            if entry.withdrawn == true {
              Text("Round withdrawn. Its recorded points remain in this season’s Book.").csType(.bodyS).foregroundStyle(cs.mut)
            } else if let round=entry.round_id {
              CSDoor(.link("Open the round’s receipt") { openRound(round) })   // W5 twin · the web's words
            }
          }.padding(.vertical,CSTokens.Space.s3).frame(maxWidth:.infinity,alignment:.leading).overlay(alignment:.bottom) { CSRule() }
        }
      }.padding(CSTokens.Space.gutter)
    }.clipped().csLookGround().csBareBar().csStatusCap(cs.bg0)
  }
}
