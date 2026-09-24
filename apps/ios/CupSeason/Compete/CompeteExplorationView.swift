// Three local compositions. Every type in this file disappears in Release.
#if DEBUG
import SwiftUI
import Charts
import CSDesign
import CupSeasonKit

struct CompeteExplorationView: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var type
  private let seasons = CompeteFixture.explorationSeasons(CompeteExploration.fixture)
  private let direction = CompeteExploration.direction
  var body: some View {
    NavigationStack {
      Group {
        if ["season", "entry"].contains(CompeteExploration.screen) {
          ExploreSeasonView(season: seasons[0], direction: direction)
        } else if CompeteExploration.screen == "receipt" {
          SeasonBookReceiptList(season: seasons[0], title: "Jerecho · Week 12",
            entries: seasons[0].memberEntries(1).filter { $0.week == 12 })
        } else if CompeteExploration.screen == "round" {
          if let entry = seasons[0].entries.first { SeasonBookEntryReceipt(season: seasons[0], entry: entry) }
        } else if ["book", "race", "adjustments", "book-bottom"].contains(CompeteExploration.screen) {
          if seasons[0].bookAvailable { SeasonBookView(season: seasons[0], direction: direction) }
          else { SeasonBookSmallView(season: seasons[0]) }
        } else { root }
      }
      .clipped() // Keep scrolling content out of the status-bar safe area.
      .toolbar(.hidden, for: .navigationBar)
      .foregroundStyle(cs.ink)
      .background(cs.bg0.ignoresSafeArea())
    }
    .tint(cs.act)
  }
  private var root: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          HStack(alignment: .firstTextBaseline) {
            Text("Compete").csType(.display)
            Spacer()
            Text(direction == "broadsheet" ? "THE FIELD" : direction == "race" ? "THE LONG GAME" : "IN SEASON")
              .csType(.agateS).foregroundStyle(cs.mut)
          }.padding(CSTokens.Space.gutter)
          if direction == "broadsheet" {
            CSRule(.heavy)
            HStack { Text("SEASON / STANDING"); Spacer(); Text("POINTS") }
              .csType(.agateS).foregroundStyle(cs.mut).padding(CSTokens.Space.gutter)
          }
          ForEach(Array(seasons.enumerated()), id: \.offset) { i, season in
            VStack(alignment: .leading, spacing: 0) {
              NavigationLink { ExploreSeasonView(season: season, direction: direction) } label: {
                if direction == "broadsheet" {
                  ExplorePressSeason(season: season)
                } else {
                  ExploreHead(season: season, direction: direction, compact: i > 0, look: season.squads ? "teams" : "oldest")
                }
              }.buttonStyle(.plain).accessibilityIdentifier("explore.season.\(i)")
              if i == 0 && !season.upcoming { SeasonBookDoor(season: season, direction: direction) }
            }.id("season-\(i)")
          }
          if direction == "broadsheet", !seasons[0].upcoming {
            Text("AT THE TOP · \(seasons[0].title.uppercased())").csType(.agateS)
              .foregroundStyle(cs.mut).padding(CSTokens.Space.gutter)
            HStack {
              Text("GOLFER / STANDING"); Spacer()
              if !type.isAccessibilitySize { Text("W\(seasons[0].currentWeek)").frame(width: 44) }
              Text("POINTS").frame(minWidth: 64, alignment: .trailing)
            }.csType(.agateS).foregroundStyle(cs.mut).padding(.horizontal, CSTokens.Space.gutter)
            ForEach(seasons[0].standings.prefix(4).filter { $0.id != seasons[0].model.myTeamId }) { team in
              ExploreStandingRow(season: seasons[0], team: team, direction: direction)
            }
          }
          if CompeteExploration.fixture == "multi" {
            VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
              CSRule(.heavy)
              Text("A MOMENT").csType(.agate).foregroundStyle(cs.mut)
              Text("Papago, Saturday").csType(.displayS)
              Text("The Dew Sweepers Cup · Sep 26").csType(.bodyS)
              Text("Teams named. Play begins Saturday.").csType(.story)
            }.padding(CSTokens.Space.gutter).id("moment")
          }
          Text("Local study · fixture golfers and rounds").csType(.agateS).foregroundStyle(cs.mut)
            .padding(CSTokens.Space.gutter)
        }
      }.task {
        if CompeteExploration.screen == "root-bottom" {
          try? await Task.sleep(for: .milliseconds(300)); proxy.scrollTo("moment", anchor: .bottom)
        }
      }
    }
    .safeAreaInset(edge: .bottom, spacing: 0) {
      HStack {
        if type.isAccessibilitySize {
          Text("Compete selected")
        } else {
          Text("Home"); Spacer(); Text("Compete").bold(); Spacer(); Text("Play"); Spacer(); Text("Golfers"); Spacer(); Text("You")
        }
      }.csType(.agateS).frame(maxWidth: .infinity).padding(CSTokens.Space.gutter).background(cs.bg1)
        .accessibilityLabel("Compete selected. Study navigation is limited to seasons and points.")
    }
  }
}

private struct ExploreTerrain: View {
  @Environment(\.colorScheme) private var scheme
  @Environment(\.cs) private var cs
  var look = "oldest"
  var ember = false
  var body: some View {
    // The same accepted geometry, at full scale; clipping a 44pt drawing
    // compressed the entire terrain into an illegible postage stamp.
    CSTopoField(.accent, tint: ember ? cs.brandInk.opacity(CSTokens.Alpha.a24) :
      (CSLooks.spec(look)?.accent(scheme == .dark ? .dark : .light) ?? cs.act).opacity(CSTokens.Alpha.a56))
      .frame(height: CSTokens.Space.s6).clipped()
  }
}

private struct ExploreHead: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var type
  let season: CompeteExplorationSeason
  let direction: String
  var compact = false
  var look = "oldest"
  var showStanding = true
  private var ember: Bool { direction == "scoreboard" && season.live && !compact }
  private var ink: Color { ember ? cs.brandInk : cs.ink }
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ExploreTerrain(look: look, ember: ember)
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        HStack {
          Text(season.upcoming ? "UPCOMING" : season.finished ? "FINAL TABLE" : "WEEK \(season.currentWeek) OF \(season.weeks)")
            .csType(.agate)
          Spacer(minLength: 0)
          if season.finished { Text("CHAMPION").csType(.agate).foregroundStyle(cs.gold) }
        }
        Text(season.title).csType(compact ? .displayS : .display).fixedSize(horizontal: false, vertical: true)
        if !compact { Text(season.story).csType(.story).fixedSize(horizontal: false, vertical: true) }
        if showStanding && !season.upcoming, let mine = season.mine {
          if direction == "race" && !compact {
            SeasonBookRace(season: season, rows: season.raceTeams.map {
              SeasonBookRow(id: $0.id.uuidString, name: $0.name, entries: season.teamEntries($0))
            }, compact: true)
            Text("You · \(season.rank(mine))").csType(.name, caps: false)
          } else {
            ViewThatFits(in: .horizontal) {
              HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s5) {
                points(mine); standing(mine)
              }
              VStack(alignment: .leading, spacing: CSTokens.Space.s3) { points(mine); standing(mine) }
            }
          }
        }
      }.padding(CSTokens.Space.gutter)
    }
    .foregroundStyle(ink)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(ember ? cs.brand : cs.bg1)
    .multilineTextAlignment(.leading)
  }
  private func standing(_ team: Team) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      Text(season.rank(team)).csType(.name, caps: false)
      Text(season.squads ? "YOUR SQUAD" : "YOUR STANDING").csType(.agateS)
    }.fixedSize(horizontal: false, vertical: true)
  }
  private func points(_ team: Team) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      Text(CSCopy.points(team.pts)).csType(compact ? .figureM : .figureXL)
      CSRule(.heavy, over: ember ? .ember : .page)
      Text("POINTS").csType(.agateS).foregroundStyle(ink)
    }
  }
}

private struct ExplorePressSeason: View {
  @Environment(\.cs) private var cs
  let season: CompeteExplorationSeason
  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s3) {
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        Text(season.title).csType(.displayS)
        if let mine = season.mine, !season.upcoming {
          Text(season.rank(mine)).csType(.nameS, caps: false)
        }
        Text(season.upcoming ? "First tee · Oct 5" : season.finished ? "Galen won the Cup." : "Week \(season.currentWeek) of \(season.weeks)")
          .csType(.bodyS).foregroundStyle(cs.mut)
      }
      Spacer(minLength: 0)
      if let mine = season.mine, !season.upcoming { Text(CSCopy.points(mine.pts)).csType(.figureL) }
    }.padding(CSTokens.Space.gutter)
      .overlay(alignment: .leading) {
        Rectangle().fill(season.live ? cs.brand : cs.rule).frame(width: CSTokens.Space.s1)
      }
      .overlay(alignment: .bottom) { CSRule() }.contentShape(Rectangle())
  }
}

private struct SeasonBookSmallView: View {
  @Environment(\.cs) private var cs
  let season: CompeteExplorationSeason
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        ExploreBack(title: season.title)
        Text("Rounds & points").csType(.display).padding(.horizontal, CSTokens.Space.gutter)
        Text(season.rules).csType(.bodyS).padding(.horizontal, CSTokens.Space.gutter)
        ForEach(season.standings) { team in
          ExploreStandingRow(season: season, team: team, direction: "broadsheet")
        }
      }
    }.clipped().background(cs.bg0).toolbar(.hidden, for: .navigationBar)
  }
}

private struct SeasonBookDoor: View {
  @Environment(\.cs) private var cs
  let season: CompeteExplorationSeason
  let direction: String
  var body: some View {
    NavigationLink {
      if season.bookAvailable { SeasonBookView(season: season, direction: direction) }
      else { SeasonBookSmallView(season: season) }
    } label: {
      HStack(spacing: CSTokens.Space.s3) {
        VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
          Text(season.bookAvailable ? "Open the Book" : "Rounds & points").csType(.name)
          Text(season.bookAvailable ? "The whole season, week by week" : "Every round behind the standing")
            .csType(.bodyS).foregroundStyle(cs.mut)
        }
        Spacer(minLength: 0)
        Image(systemName: "arrow.right").foregroundStyle(cs.act)
      }.padding(CSTokens.Space.gutter).frame(minHeight: 44)
        .background(cs.bg0).overlay(alignment: .bottom) { CSRule() }.contentShape(Rectangle())
    }.buttonStyle(.plain).accessibilityIdentifier("explore.book")
  }
}

private struct ExploreSeasonView: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var type
  let season: CompeteExplorationSeason
  let direction: String
  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          ExploreBack(title: "Compete")
          if direction == "broadsheet" {
            ExploreTerrain(look: season.squads ? "teams" : "oldest")
            VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
              Text(season.title).csType(.display)
              Text(season.story).csType(.story)
            }.padding(CSTokens.Space.gutter)
            CSRule(.heavy)
          } else {
            ExploreHead(season: season, direction: direction, look: season.squads ? "teams" : "oldest", showStanding: direction == "race")
          }
          if !season.upcoming {
            SeasonBookDoor(season: season, direction: direction).id("book-door")
            HStack {
              Text(season.squads ? "SQUADS" : "GOLFERS")
              Spacer()
              if direction == "broadsheet" && !type.isAccessibilitySize { Text("W\(season.currentWeek)").frame(width: 44) }
              Text("POINTS").frame(minWidth: 64, alignment: .trailing)
            }.csType(.agateS).foregroundStyle(cs.mut).padding(CSTokens.Space.gutter)
            ForEach(season.standings) { team in
              ExploreStandingRow(season: season, team: team, direction: direction)
            }
          } else {
            Text("No standing yet. The Book opens when the first round counts.")
              .csType(.body).padding(CSTokens.Space.gutter).id("book-door")
          }
        }
      }.clipped().toolbar(.hidden, for: .navigationBar).background(cs.bg0)
        .task {
          if CompeteExploration.screen == "entry" {
            try? await Task.sleep(for: .milliseconds(300)); proxy.scrollTo("book-door", anchor: .top)
          }
        }
    }
  }
}

private struct ExploreStandingRow: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var type
  let season: CompeteExplorationSeason
  let team: Team
  let direction: String
  var body: some View {
    NavigationLink { SeasonBookReceiptList(season: season, title: team.name, entries: season.teamEntries(team)) } label: {
      HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s3) {
        VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
          Text(team.id == season.model.myTeamId && !season.squads ? "You" : team.name)
            .csType(direction == "scoreboard" ? .displayS : .name)
          Text(season.rank(team)).csType(.agate)
        }
        Spacer(minLength: 0)
        if direction == "broadsheet" && !type.isAccessibilitySize {
          Text(SeasonBookCell.label(season.teamEntries(team), week: season.currentWeek, currentWeek: season.currentWeek))
            .csType(.columnS).frame(width: 44)
        }
        Text(CSCopy.points(team.pts)).csType(direction == "scoreboard" ? .figureL : .figureM)
          .frame(minWidth: 44, alignment: .trailing)
      }
      .padding(.horizontal, CSTokens.Space.gutter)
      .padding(.vertical, direction == "broadsheet" ? CSTokens.Space.s2 : CSTokens.Space.s3)
      .frame(minHeight: 44)
      .background(team.id == season.model.myTeamId ? cs.bg2 : cs.bg0)
      .overlay(alignment: .leading) {
        Rectangle().fill(team.id == season.model.myTeamId ? cs.act : cs.rule).frame(width: CSTokens.Space.s1)
      }
      .overlay(alignment: .bottom) { CSRule() }.contentShape(Rectangle())
    }.buttonStyle(.plain)
  }
}

private struct ExploreBack: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  var title: String
  var body: some View {
    Button { dismiss() } label: {
      Label(title, systemImage: "chevron.left").csType(.nameS).foregroundStyle(cs.ink)
        .frame(minHeight: 44).padding(.horizontal, CSTokens.Space.gutter)
    }.buttonStyle(.plain)
  }
}

private struct SeasonBookRace: View {
  @Environment(\.cs) private var cs
  @Environment(\.colorScheme) private var scheme
  let season: CompeteExplorationSeason
  let rows: [SeasonBookRow]
  var compact = false
  private var domain: ClosedRange<Int> { SeasonBookRaceScale.domain(rows: rows.map(\.entries), currentWeek: season.currentWeek) }
  var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      Text("POINTS COUNTING TODAY").csType(.agateS).foregroundStyle(cs.mut)
      Chart {
        ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
          ForEach(0...max(1, season.currentWeek), id: \.self) { week in
            LineMark(x: .value("Week", week), y: .value("Points", season.total(row.entries, through: week)),
                     series: .value("Golfer", row.name))
              .foregroundStyle(cs.ink)
              .lineStyle(StrokeStyle(lineWidth: index == 0 ? 3 : 2, dash: index == 0 ? [] : [CGFloat(index + 2), 3]))
          }
        }
        if season.live { RuleMark(x: .value("Current week", season.currentWeek)).foregroundStyle(cs.brand) }
      }
      .chartXScale(domain: 0...season.weeks).chartYScale(domain: domain)
      .chartXAxis { AxisMarks(values: Array(Set([1, max(1, season.weeks / 3), max(1, season.weeks * 2 / 3), season.weeks])).sorted()) { _ in AxisValueLabel().foregroundStyle(cs.mut) } }
      .chartYAxis { AxisMarks(position: .leading, values: Array(Set([domain.lowerBound, 0, domain.upperBound])).sorted()) { _ in AxisValueLabel().foregroundStyle(cs.mut) } }
      .frame(height: compact ? 150 : 210)
      .padding(CSTokens.Space.s2)
      .background {
        cs.bg0
        CSTopoField(.page, tint: (CSLooks.spec(season.squads ? "teams" : "oldest")?.accent(scheme == .dark ? .dark : .light) ?? cs.act).opacity(CSTokens.Alpha.a08))
      }
      .accessibilityLabel("Cumulative points from rounds counting now, through week \(season.currentWeek). Lines are differentiated by dash pattern. Exact totals and receipts follow.")
      ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
        HStack {
          Text("\(index == 0 ? "━" : index == 1 ? "┄" : "┈") \(row.name)")
          Spacer()
          Text("\(season.total(row.entries)) pts")
        }.csType(.nameS).frame(minHeight: 44)
      }
    }
  }
}

private struct SeasonBookRow: Identifiable {
  let id: String
  let name: String
  let entries: [SeasonBookEntry]
}

private struct SeasonBookView: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var type
  @State private var teams: Bool
  @State private var mode: String
  @State private var selectedWeek: Int
  @State private var memberFilter = CompeteExploration.argument("-cs_explore_squad", fallback: "all")
  @State private var follow = "leaders"
  @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 64
  let season: CompeteExplorationSeason
  let direction: String
  init(season: CompeteExplorationSeason, direction: String) {
    self.season = season; self.direction = direction
    _selectedWeek = State(initialValue: max(1, min(season.currentWeek, season.weeks)))
    _teams = State(initialValue: season.squads && CompeteExploration.argument("-cs_explore_group", fallback: "squads") != "golfers")
    _mode = State(initialValue: CompeteExploration.argument("-cs_explore_mode", fallback: CompeteExploration.screen == "race" || direction == "race" ? "Race" : "Weeks"))
  }
  private var rows: [SeasonBookRow] {
    if teams && season.squads {
      return season.standings.map { .init(id: $0.id.uuidString, name: $0.name, entries: season.teamEntries($0)) }
    }
    return season.names.indices.filter { memberFilter == "all" || $0 / 4 == Int(memberFilter) }.map {
      .init(id: "member-\($0)", name: season.names[$0], entries: season.memberEntries($0))
    }
  }
  var body: some View {
    ScrollViewReader { reader in
      ScrollView {
        VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
          ExploreBack(title: season.title)
          if direction != "broadsheet" { ExploreTerrain(look: season.squads ? "teams" : "oldest") }
          VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
            Text("the Book").csType(.display)
            Text(season.title).csType(.story)
            Text(season.rules).csType(.bodyS).foregroundStyle(cs.mut)
            if season.squads {
              Picker("View", selection: $teams) { Text("Squads").tag(true); Text("Golfers").tag(false) }.pickerStyle(.segmented)
              if !teams {
                Picker("Squad", selection: $memberFilter) {
                  Text("Every squad").tag("all")
                  ForEach(0..<4) { i in Text(["Mudsharks", "Roadrunners", "Coyotes", "Saguaros"][i]).tag(String(i)) }
                }
              }
            }
            Picker("Display", selection: $mode) { ForEach(["Weeks", "Totals", "Race"], id: \.self) { Text($0).tag($0) } }
              .pickerStyle(.segmented).accessibilityIdentifier("explore.mode")
          }.padding(.horizontal, CSTokens.Space.gutter)
          if season.upcoming {
            Text("No rounds yet. Weeks appear after first tee.").csType(.story).padding(CSTokens.Space.gutter)
          } else if mode == "Race" {
            VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
              Text("How the season added up").csType(.story)
              Picker("Follow", selection: $follow) {
                Text("Leading three").tag("leaders")
                ForEach(rows) { row in Text(row.name).tag(row.id) }
              }.pickerStyle(.menu)
              SeasonBookRace(season: season, rows: raceRows)
              Text("Points included today, grouped by week played. Later drops restate earlier weeks; this is not a historical rank chart.")
                .csType(.bodyS).foregroundStyle(cs.mut)
              ForEach(rows) { row in
                NavigationLink { SeasonBookReceiptList(season: season, title: row.name, entries: row.entries) } label: {
                  HStack { Text(row.name); Spacer(); Text("\(season.total(row.entries)) pts") }.csType(.name).frame(minHeight: 44)
                }.buttonStyle(.plain)
                  .accessibilityIdentifier("explore.race.receipts.\(row.id)")
              }
            }.padding(CSTokens.Space.gutter)
          } else if type.isAccessibilitySize {
            accessibleWeeks
          } else {
            matrix
          }
          if !season.upcoming {
            Text("— No round · D Dropped · B Bye · * Adjustment · • Future week. Tap a cell for its rounds and adjustments.")
              .csType(.bodyS).foregroundStyle(cs.mut).padding(.horizontal, CSTokens.Space.gutter)
            adjustments.id("adjustments")
          }
          Text("Fixture data · as of \(season.finished ? "Oct 20" : "Sep 24"), 2026")
            .csType(.agateS).foregroundStyle(cs.mut).padding(CSTokens.Space.gutter)
        }
      }
      .task {
        if ["adjustments", "book-bottom"].contains(CompeteExploration.screen) {
          try? await Task.sleep(for: .milliseconds(400)); reader.scrollTo("adjustments", anchor: .top)
        }
      }
    }
    .clipped().toolbar(.hidden, for: .navigationBar).background(cs.bg0)
  }
  private var matrix: some View {
    HStack(alignment: .top, spacing: 0) {
      VStack(spacing: 0) {
        Text(teams ? "SQUAD / TOTAL" : "GOLFER / TOTAL").csType(.agateS).frame(height: 44)
        ForEach(rows) { row in
          NavigationLink { SeasonBookReceiptList(season: season, title: row.name, entries: row.entries) } label: {
            VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
              Text(short(row.name)).csType(.nameS).lineLimit(2).minimumScaleFactor(0.85)
              Text("\(season.total(row.entries)) pts").csType(.columnS)
            }.frame(maxWidth: .infinity, alignment: .leading).frame(height: rowHeight).padding(.horizontal, CSTokens.Space.s2)
              .overlay(alignment: .bottom) { CSRule() }.contentShape(Rectangle())
          }.buttonStyle(.plain).accessibilityIdentifier("explore.name.\(row.id)")
        }
      }.frame(width: 140).background(cs.bg1)
      ScrollViewReader { weekProxy in
      ScrollView(.horizontal) {
        VStack(spacing: 0) {
          HStack(spacing: 0) {
            ForEach(1...season.weeks, id: \.self) { w in
              VStack(spacing: 0) { Text("W\(w)"); Text(String(season.weekDate(w).suffix(5))) }
                .csType(.agateS).frame(width: 64, height: 44)
                .foregroundStyle(w == season.currentWeek && season.live ? cs.brandInk : cs.ink)
                .background(w == season.currentWeek && season.live ? cs.brand : cs.bg1)
                .id("week-\(w)")
            }
          }
          ForEach(rows) { row in
            HStack(spacing: 0) {
              ForEach(1...season.weeks, id: \.self) { w in
                NavigationLink {
                  SeasonBookReceiptList(season: season, title: "\(row.name) · Week \(w)", entries: row.entries.filter { mode == "Totals" ? $0.week <= w : $0.week == w })
                } label: {
                  Text(cell(row.entries, w)).csType(.columnM)
                    .frame(width: 64, height: rowHeight)
                    .background(w == season.currentWeek && season.live ? cs.bg2 : cs.bg0)
                    .overlay(alignment: .bottom) { CSRule() }.contentShape(Rectangle())
                }.buttonStyle(.plain)
                  .accessibilityLabel("\(row.name), week \(w), \(SeasonBookCell.spoken(row.entries, week: w, currentWeek: season.currentWeek, cumulative: mode == "Totals")). Opens receipt.")
                  .accessibilityIdentifier("explore.cell.\(row.id).\(w)")
              }
            }
          }
        }
      }.task {
        let week = CompeteExploration.argument("-cs_explore_week", fallback: "1")
        if week != "1" { try? await Task.sleep(for: .milliseconds(300)); weekProxy.scrollTo("week-" + week, anchor: .leading) }
      }
      }
    }
  }
  private var accessibleWeeks: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      Picker("Week", selection: $selectedWeek) {
        ForEach(1...season.weeks, id: \.self) { Text("Week \($0)").tag($0) }
      }.pickerStyle(.menu).accessibilityIdentifier("explore.week.picker")
      ForEach(rows) { row in
        NavigationLink {
          SeasonBookReceiptList(season: season, title: "\(row.name) · Week \(selectedWeek)", entries: row.entries.filter { mode == "Totals" ? $0.week <= selectedWeek : $0.week == selectedWeek })
        } label: {
          VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
            Text(row.name).csType(.name)
            Text(SeasonBookCell.spoken(row.entries, week: selectedWeek, currentWeek: season.currentWeek, cumulative: mode == "Totals")).csType(.body)
          }.padding(.vertical, CSTokens.Space.s3).frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottom) { CSRule() }.contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityIdentifier("explore.ax.row.\(row.id)")
      }
    }.padding(.horizontal, CSTokens.Space.gutter)
  }
  private var adjustments: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      Text("Adjustments in the totals").csType(.displayS)
      Text("Already included above. Shown in the week recorded, with the month they apply to.")
        .csType(.bodyS).foregroundStyle(cs.mut)
      ForEach(rows.flatMap(\.entries).filter { !$0.round }) { entry in
        NavigationLink { SeasonBookEntryReceipt(season: season, entry: entry) } label: {
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            Text("W\(entry.week) · \(entry.member.map { season.names[$0] } ?? "Squad") · \(entry.kind == "bye" ? "Bye" : String(entry.points))")
              .csType(.name)
            Text(entry.reason).csType(.bodyS).foregroundStyle(cs.mut)
          }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, CSTokens.Space.s2).contentShape(Rectangle())
        }.buttonStyle(.plain)
      }
      if rows.flatMap(\.entries).allSatisfy(\.round) { Text("No adjustments recorded for this selection.").csType(.bodyS) }
    }.padding(CSTokens.Space.gutter)
  }
  private var raceRows: [SeasonBookRow] {
    let ordered = rows.sorted { season.total($0.entries) > season.total($1.entries) }
    guard follow != "leaders", let selected = rows.first(where: { $0.id == follow }) else { return Array(ordered.prefix(3)) }
    return [selected] + ordered.filter { $0.id != selected.id }.prefix(2)
  }
  private func cell(_ entries: [SeasonBookEntry], _ week: Int) -> String {
    SeasonBookCell.label(entries, week: week, currentWeek: season.currentWeek, cumulative: mode == "Totals")
  }
  private func short(_ name: String) -> String {
    if teams { return name }
    let bits = name.split(separator: " ")
    return bits.count > 1 ? "\(bits[0].prefix(1)). \(bits.dropFirst().joined(separator: " "))" : name
  }
}

private struct SeasonBookReceiptList: View {
  @Environment(\.cs) private var cs
  let season: CompeteExplorationSeason
  let title: String
  let entries: [SeasonBookEntry]
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        ExploreBack(title: "the Book")
        Text(title).csType(.displayS)
        if !entries.isEmpty {
          Text("\(season.total(entries)) points").csType(.figureL)
            .accessibilityIdentifier("explore.receipt.total")
        }
        if entries.isEmpty { Text("No round or adjustment recorded for this selection.").csType(.body) }
        ForEach(entries) { entry in
          NavigationLink { SeasonBookEntryReceipt(season: season, entry: entry) } label: {
            VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
              Text("Week \(entry.week) · \(entry.member.map { season.names[$0] } ?? "Squad")").csType(.name)
              Text(entry.kind == "bye" ? "Bye · no points added" : "\(entry.points) points · \(entry.counted ? "included" : "dropped")")
                .csType(.body)
              Text(entry.reason).csType(.bodyS).foregroundStyle(cs.mut)
            }.padding(.vertical, CSTokens.Space.s3).frame(maxWidth: .infinity, alignment: .leading)
              .overlay(alignment: .bottom) { CSRule() }.contentShape(Rectangle())
          }.buttonStyle(.plain).accessibilityIdentifier("explore.receipt.\(entry.id)")
        }
      }.padding(CSTokens.Space.gutter)
    }.clipped().background(cs.bg0).toolbar(.hidden, for: .navigationBar)
  }
}

private struct SeasonBookEntryReceipt: View {
  @Environment(\.cs) private var cs
  let season: CompeteExplorationSeason
  let entry: SeasonBookEntry
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
        ExploreBack(title: "Points")
        Text(entry.round ? "Round receipt" : "Adjustment receipt").csType(.display)
        Text(entry.member.map { season.names[$0] } ?? "Squad").csType(.story)
        Text("\(entry.points)").csType(.figureXL)
        Text(entry.kind == "bye" ? "BYE · NO POINTS ADDED" : entry.counted ? "POINTS INCLUDED" : "POINTS SCORED · NOT COUNTING")
          .csType(.agate)
        Text(entry.reason).csType(.body)
        Text("Week \(entry.week) began \(CSDate.short(season.weekDate(entry.week)))").csType(.bodyS)
        if entry.round {
          Text(season.rules).csType(.bodyS)
          Text("This local fixture contains scored points, not a gross score, rating, slope or holes. Those facts are not supplied.")
            .csType(.bodyS).foregroundStyle(cs.mut)
        }
        Text("Receipt \(entry.id.uuidString)").csType(.columnS).foregroundStyle(cs.mut)
        Text("Local proposal fixture").csType(.agateS).foregroundStyle(cs.mut)
      }.padding(CSTokens.Space.gutter)
    }.clipped().background(cs.bg0).toolbar(.hidden, for: .navigationBar)
  }
}
#endif
