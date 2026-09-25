import SwiftUI
import WidgetKit
import CSDesign
#if !CS_WIDGET_EXTENSION
import CupSeasonKit
#endif

/// Shared with the DEBUG gallery so the review renders the actual widget views.
struct BetweenRoundsWidgetView: View {
  @Environment(\.widgetFamily) private var systemFamily
  var previewFamily: WidgetFamily? = nil
  private var family: WidgetFamily { previewFamily ?? systemFamily }
  @Environment(\.colorScheme) private var scheme
  @Environment(\.colorSchemeContrast) private var contrast
  @Environment(\.dynamicTypeSize) private var typeSize
  let kind: BetweenRoundsKind
  let snapshot: BetweenRoundsSnapshot?
  let date: Date
  private var cs: CSPalette {
    let base = scheme == .light ? CSTokens.light : CSTokens.dark
    return contrast == .increased ? base.increasedContrast : base
  }
  private var small: Bool { family == .systemSmall }
  private var stale: Bool { snapshot?.isStale(kind, at: date) ?? true }

  var body: some View {
    Group {
      if family == .accessoryRectangular { accessory }
      else {
        VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
          if typeSize.isAccessibilitySize { accessibleContent } else { content }
          Spacer(minLength: 0)
          if let snapshot {
            Text(snapshot.asOf(kind, at: date)).csType(.agateS).foregroundStyle(cs.mut)
              .lineLimit(1).minimumScaleFactor(0.85)
          }
        }
        .padding(CSTokens.Space.s3)
        .foregroundStyle(cs.ink)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .containerBackground(cs.bg0, for: .widget)
    .widgetURL(snapshot?.link(for: kind) ?? URL(string: "cupseason://home")!)
    .privacySensitive()
  }

  @ViewBuilder private var content: some View {
    switch kind {
    case .race:
      if let race = snapshot?.race?.value { raceView(race) }
      else { empty("Your season takes shape here.", action: "Open your season") }
    case .nextTee:
      if let tee = snapshot?.nextTee?.value, date < tee.closesAt { teeView(tee) }
      else { empty("The next round is yours to make.", action: "Open your schedule") }
    case .record:
      if let record = snapshot?.record?.value { recordView(record) }
      else { empty("A round worth keeping.", action: "Post your first round") }
    case .rivalry:
      if let rival = snapshot?.rivalry?.value { rivalryView(rival) }
      else { empty("Every rivalry starts somewhere.", action: "See your golfers") }
    }
  }

  // Widgets cannot grow with a page. At accessibility sizes keep the primary
  // facts, rather than letting secondary detail push the controls off the tile.
  @ViewBuilder private var accessibleContent: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      switch kind {
      case .race:
        if let race = snapshot?.race?.value {
          accessibleLabel(race.name)
          accessibleFigure(race.standing)
          accessibleLabel(race.story)
        } else { accessibleEmpty }
      case .nextTee:
        if let tee = snapshot?.nextTee?.value, date < tee.closesAt {
          if small {
            accessibleLabel(tee.dateLine)
            accessibleFigure(tee.time)
            accessibleLabel(tee.course)
          } else {
            accessibleLabel(tee.course)
            HStack {
              accessibleLabel(tee.dateLine)
              Spacer(minLength: 0)
              accessibleFigure(tee.time)
            }
            if let error = tee.replyError { accessibleLabel(error) }
            else if !stale, tee.allowsReply(at: date), let owner = snapshot?.owner {
              HStack(spacing: CSTokens.Space.s2) {
                reply(tee.status == "in" ? "You’re in" : "I’m in", status: "in", tee: tee, owner: owner, primary: tee.status != "in")
                reply(tee.status == "out" ? "You’re out" : "Can’t", status: "out", tee: tee, owner: owner, primary: false)
              }
            }
          }
        } else { accessibleEmpty }
      case .record:
        if let record = snapshot?.record?.value {
          accessibleLabel(record.headline)
          accessibleFigure("\(record.gross) · \(record.holes) holes")
          accessibleLabel(record.course)
        } else { accessibleEmpty }
      case .rivalry:
        if let rival = snapshot?.rivalry?.value {
          accessibleLabel("Weekly clashes")
          accessibleFigure("\(rival.wins)–\(rival.losses)" + (rival.ties > 0 ? "–\(rival.ties)" : ""))
            .accessibilityLabel("\(rival.wins) wins, \(rival.losses) losses, \(rival.ties) ties")
          accessibleLabel("You and \(rival.name)")
        } else { accessibleEmpty }
      }
    }
  }
  private var accessibleEmpty: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      accessibleLabel(kind.title)
      accessibleLabel("Open Cup Season to catch up.")
    }
  }
  private func accessibleLabel(_ value: String) -> some View {
    Text(value).csType(.agateS).lineLimit(1).minimumScaleFactor(0.75)
  }
  private func accessibleFigure(_ value: String) -> some View {
    Text(value).csType(.figureM).lineLimit(1).minimumScaleFactor(0.75)
  }

  private func head(_ left: String, _ right: String? = nil) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s2) {
      Text(left).csType(.agate).textCase(.uppercase).lineLimit(1)
      if let right { Spacer(minLength: 0); Text(right).csType(.agateS).lineLimit(1) }
    }.foregroundStyle(cs.mut)
  }
  private func empty(_ story: String, action: String) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      head(kind.title)
      Text(snapshot?.savedAt(for: kind) == nil ? "Open Cup Season to catch up." : story)
        .csType(.story).lineLimit(3).minimumScaleFactor(0.85)
      Text(snapshot?.savedAt(for: kind) == nil ? "Open to refresh" : action)
        .csType(.agate).foregroundStyle(cs.act)
    }
  }

  private func raceView(_ race: BetweenRoundsSnapshot.Race) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      head(race.name, small ? nil : race.context)
      if small {
        if let mine = race.rows.first(where: \.mine) {
          Text(mine.rank).csType(.figureXL)
            .accessibilityLabel(race.standing)
          Text(race.standing).csType(.agate)
        }
      } else {
        VStack(spacing: 0) {
          ForEach(race.rows) { row in
            HStack(spacing: CSTokens.Space.s2) {
              Text(row.rank).csType(.figureS).frame(width: CSTokens.Space.s5, alignment: .leading)
              Text(row.name).csType(.nameS).lineLimit(1)
              Spacer(minLength: 0)
              Text(String(row.points)).csType(.figureS)
            }
            .padding(.horizontal, CSTokens.Space.s1)
            .foregroundStyle(row.mine ? cs.panelInk : cs.ink)
            .background(row.mine ? cs.panel : .clear)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(row.name), rank \(row.rank), \(row.points) Cup points")
          }
        }
      }
      Text(race.story).csType(small ? .bodyS : .story).lineLimit(small ? 2 : 1).minimumScaleFactor(0.8)
    }
  }

  private func teeView(_ tee: BetweenRoundsSnapshot.Tee) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      head(small ? kind.title : tee.dateLine, small || tee.status == "in" || tee.status == "out" ? nil : tee.response)
      HStack(alignment: .center, spacing: CSTokens.Space.s3) {
        if !small {
          VStack(spacing: 0) {
            Text(tee.day).csType(.figureL).lineLimit(1).minimumScaleFactor(0.75)
            Text(tee.month).csType(.agate).textCase(.uppercase)
          }.frame(width: CSTokens.Space.rail)
          Rectangle().fill(cs.rule).frame(width: CSTokens.Space.hair)
        }
        VStack(alignment: .leading, spacing: 0) {
          Text(tee.time).csType(.figureM).lineLimit(1).minimumScaleFactor(0.65)
          Text(tee.course).csType(.nameS).lineLimit(1)
          if !tee.company.isEmpty, !small { Text(tee.company).csType(.agateS).foregroundStyle(cs.mut).lineLimit(1) }
          if small { Text(tee.dateLine).csType(.agateS).foregroundStyle(cs.mut).lineLimit(1) }
        }
      }.fixedSize(horizontal: false, vertical: true)
      if let error = tee.replyError {
        Text(error).csType(.agateS).lineLimit(2).fixedSize(horizontal: false, vertical: true)
      } else if !stale, tee.allowsReply(at: date), let owner = snapshot?.owner {
        if tee.status == "in" || tee.status == "out" {
          HStack {
            Text(tee.response).csType(.agate).foregroundStyle(cs.mut)
            Spacer(minLength: 0)
            reply(tee.status == "in" ? "Can’t make it" : "I’m in", status: tee.status == "in" ? "out" : "in", tee: tee, owner: owner, primary: false)
          }
        } else {
          HStack(spacing: CSTokens.Space.s2) {
            reply("I’m in", status: "in", tee: tee, owner: owner, primary: true)
            reply(small ? "Can’t" : "Can’t make it", status: "out", tee: tee, owner: owner, primary: false)
          }
        }
      }
    }
  }

  private func reply(_ label: String, status: String, tee: BetweenRoundsSnapshot.Tee, owner: UUID, primary: Bool) -> some View {
    Button(intent: ReplyToTeeIntent(round: tee.id, owner: owner, status: status)) {
      Text(label).csType(.agate).lineLimit(1)

    }
    .buttonStyle(CSWidgetReplyStyle(primary: primary, palette: cs))
    .accessibilityLabel("\(label), \(tee.course), \(tee.dateLine)")
    .accessibilityHint("Saves your RSVP")
  }

  private func recordView(_ record: BetweenRoundsSnapshot.Record) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      head("A round to keep", small ? nil : record.date)
      Text(record.headline).csType(.story).lineLimit(1).minimumScaleFactor(0.75)
      HStack(spacing: CSTokens.Space.s3) {
        if !small, let out = record.out, let inn = record.inn {
          score(out, label: "Out", earned: false)
          score(inn, label: "In", earned: false)
        }
        score(record.gross, label: record.holes == 9 ? "9 holes" : "Total", earned: record.earned)
      }
      .padding(.horizontal, CSTokens.Space.s3).padding(.vertical, CSTokens.Space.s1)
      .background(cs.leaf)
      Text([record.course, small ? nil : record.company].compactMap { $0 }.joined(separator: " · ")).csType(.agateS).foregroundStyle(cs.mut).lineLimit(1)
    }
  }

  private func score(_ value: Int, label: String, earned: Bool) -> some View {
    VStack(spacing: 0) {
      Text(String(value)).csType(.figureL).foregroundStyle(cs.leafInk)
      Text(label).csType(.agateS).foregroundStyle(cs.leafMut)
      Rectangle().fill(earned ? cs.leafGold : .clear).frame(height: CSTokens.Space.hair)
    }.frame(maxWidth: .infinity)
  }

  private func rivalryView(_ rival: BetweenRoundsSnapshot.Rivalry) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      head(small ? "Weekly clashes" : rival.scope, !small && rival.ties > 0 ? "\(rival.ties) tied" : nil)
      HStack(spacing: CSTokens.Space.s3) {
        rivalryFigure(rival.wins, name: "You")
        Rectangle().fill(cs.rule).frame(width: CSTokens.Space.hair)
        rivalryFigure(rival.losses, name: rival.name)
      }.fixedSize(horizontal: false, vertical: true)
      if small, rival.ties > 0 { Text("\(rival.ties) tied").csType(.agateS).foregroundStyle(cs.mut) }
      Text(rival.story).csType(small ? .bodyS : .story).lineLimit(small ? 2 : 1).minimumScaleFactor(0.8)
      if !small, let detail = rival.detail { Text(detail).csType(.agateS).foregroundStyle(cs.mut).lineLimit(1) }
    }
  }
  private func rivalryFigure(_ value: Int, name: String) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(String(value)).csType(.figureL)
      Text(name).csType(.nameS).lineLimit(1)
    }.frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder private var accessory: some View {
    VStack(alignment: .leading, spacing: 0) {
      if typeSize.isAccessibilitySize {
        if !stale, kind == .race, let race = snapshot?.race?.value {
          Text(race.standing).font(.caption2).lineLimit(1).minimumScaleFactor(0.75)
        } else if !stale, kind == .nextTee, let tee = snapshot?.nextTee?.value, date < tee.closesAt {
          Text("\(tee.month) \(tee.day) · \(tee.time)").font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
        } else { Text("Open to refresh").font(.caption2).lineLimit(1) }
      } else if !stale, kind == .race, let race = snapshot?.race?.value {
        Text(race.name).font(.caption).lineLimit(1)
        Text(race.standing).font(.headline).lineLimit(1)
        Text(race.story).font(.caption2).lineLimit(1)
      } else if !stale, kind == .nextTee, let tee = snapshot?.nextTee?.value, date < tee.closesAt {
        Text(tee.dateLine).font(.caption).lineLimit(1)
        Text(tee.time).font(.headline).lineLimit(1)
        Text(tee.course).font(.caption2).lineLimit(1)
      } else {
        Text(kind.title).font(.headline)
        Text("Open to refresh").font(.caption)
      }
      if let snapshot { Text(snapshot.asOf(kind, at: date)).font(.caption2).lineLimit(1).minimumScaleFactor(0.75) }
    }
    .accessibilityElement(children: .combine)
    // System white/tint owns this surface; no Home-screen panel colours.
  }
}
