// Cup Season — D155 · the round on the lock screen and in the Dynamic Island.
//
// A golfer puts the phone away between every shot, so the one moment the app
// must be one tap away is the one moment it is furthest. This draws the three
// facts `LiveCopy.activity(_:)` produces — hole, thru, the side game's line —
// and nothing else. Season points are absent on purpose: they score per ROUND
// (§2.2 bands read a whole round's differential), so there is no per-hole
// figure to draw and inventing one would invent a competition nobody plays.
//
// Colours come from CSDesign's generated tokens, the same source the app uses,
// so the island cannot drift from the app's palette. The extension deliberately
// depends on CSDesign ONLY — it has no business holding a Supabase client.

import ActivityKit
import SwiftUI
import WidgetKit
import CSDesign

@main
struct CupSeasonWidgets: WidgetBundle {
  var body: some Widget {
    CSRoundLiveActivity()
    CSSeasonWidget()
  }
}

// MARK: - IOS-034 · the glanceable surface between rounds
//
// Two sizes off one snapshot the APP writes into the App Group after every
// successful `home_dispatch` (`DispatchSnapshotFeed`). The extension still
// holds no network client and no Supabase anything: it reads eight strings
// somebody else produced, and draws them.
//
// It never lies about time. `DispatchSnapshot.asOf` stamps the read, and past
// 24 hours it says AS OF SAT · OPEN TO REFRESH and `verb(now:)` returns nil —
// a day-old door is not offered. Money never appears: `DispatchSnapshot`
// cannot carry the owe fact at all (L-10).

struct CSSeasonEntry: TimelineEntry {
  let date: Date
  let snapshot: DispatchSnapshot?
}

struct CSSeasonProvider: TimelineProvider {
  func placeholder(in context: Context) -> CSSeasonEntry {
    CSSeasonEntry(date: Date(), snapshot: nil)
  }
  func getSnapshot(in context: Context, completion: @escaping (CSSeasonEntry) -> Void) {
    completion(CSSeasonEntry(date: Date(), snapshot: DispatchSnapshot.read()))
  }
  func getTimeline(in context: Context, completion: @escaping (Timeline<CSSeasonEntry>) -> Void) {
    let now = Date()
    let entry = CSSeasonEntry(date: now, snapshot: DispatchSnapshot.read())
    // one refresh an hour: the snapshot only changes when the app loads Home,
    // and the only thing time itself changes is the AS OF line going stale.
    completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(3600))))
  }
}

struct CSSeasonWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "CSSeasonWidget", provider: CSSeasonProvider()) { entry in
      CSSeasonWidgetView(entry: entry)
    }
    .configurationDisplayName("Your season")
    .description("The season row and what is up next — as of the last time you opened the app.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct CSSeasonWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: CSSeasonEntry

  private var ink: Color { CSTokens.dark.ink }
  private var mut: Color { CSTokens.dark.mut }
  private var gold: Color { CSTokens.dark.gold }
  private var brand: Color { CSTokens.dark.brand }
  private var bg: Color { CSTokens.dark.bg1 }

  var body: some View {
    content
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .containerBackground(bg, for: .widget)
      .widgetURL(entry.snapshot?.url(now: entry.date) ?? URL(string: "cupseason://home")!)
  }

  @ViewBuilder private var content: some View {
    if let s = entry.snapshot {
      VStack(alignment: .leading, spacing: family == .systemSmall ? 5 : 7) {
        if let row = s.seasonRow {
          Text(row.uppercased())
            .font(.system(size: family == .systemSmall ? 9 : 10, design: .monospaced)).tracking(0.9)
            .foregroundStyle(gold).lineLimit(family == .systemSmall ? 2 : 1).minimumScaleFactor(0.75)
        }
        if let head = s.leadHeadline {
          Text(head)
            .font(.system(size: family == .systemSmall ? 14 : 17, weight: .semibold))
            .foregroundStyle(ink).lineLimit(family == .systemSmall ? 3 : 2).minimumScaleFactor(0.8)
        }
        if family == .systemMedium {
          HStack(alignment: .top, spacing: 14) {
            ForEach(Array(s.facts.prefix(3).enumerated()), id: \.offset) { _, f in
              VStack(alignment: .leading, spacing: 2) {
                Text(f.value).font(.system(size: 15, weight: .semibold, design: .monospaced)).foregroundStyle(ink)
                  .lineLimit(1).minimumScaleFactor(0.7)
                Text(f.label.uppercased()).font(.system(size: 9, design: .monospaced)).tracking(0.8)
                  .foregroundStyle(mut).lineLimit(1)
              }
            }
          }
        }
        Spacer(minLength: 0)
        HStack(spacing: 6) {
          if let verb = s.verb(now: entry.date) {
            Text(verb.uppercased()).font(.system(size: 10, weight: .semibold, design: .monospaced))
              .foregroundStyle(brand).lineLimit(1)
            Text("·").font(.system(size: 10, design: .monospaced)).foregroundStyle(mut)
          }
          Text(s.asOf(now: entry.date)).font(.system(size: 9, design: .monospaced))
            .foregroundStyle(mut).lineLimit(1).minimumScaleFactor(0.7)
        }
      }
      .padding(14)
    } else {
      // L-32 · an empty state ends in a next move, and never pretends to be data
      VStack(alignment: .leading, spacing: 6) {
        Text("CUP SEASON").font(.system(size: 10, design: .monospaced)).tracking(1.1).foregroundStyle(mut)
        Text("Open the app to fill this in.").font(.system(size: 14, weight: .semibold)).foregroundStyle(ink)
      }
      .padding(14)
    }
  }
}

struct CSRoundLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: CSRoundActivity.self) { ctx in
      lockScreen(ctx.attributes, ctx.state)
        .widgetURL(CSRoundActivityLink.url)
    } dynamicIsland: { ctx in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          VStack(alignment: .leading, spacing: 2) {
            Text("HOLE \(ctx.state.hole)").font(.system(size: 15, weight: .semibold, design: .monospaced))
              .foregroundStyle(ink)
            if let p = ctx.state.par {
              Text("PAR \(p)").font(.system(size: 11, design: .monospaced)).foregroundStyle(mut)
            }
          }
        }
        DynamicIslandExpandedRegion(.trailing) {
          VStack(alignment: .trailing, spacing: 2) {
            Text("THRU \(ctx.state.thru)").font(.system(size: 15, weight: .semibold, design: .monospaced))
              .foregroundStyle(gold)
            Text("OF \(ctx.state.holes)").font(.system(size: 11, design: .monospaced)).foregroundStyle(mut)
          }
        }
        DynamicIslandExpandedRegion(.bottom) {
          if let g = ctx.state.game {
            Text(g).font(.system(size: 16, weight: .semibold, design: .monospaced))
              .foregroundStyle(ink).lineLimit(1).minimumScaleFactor(0.7)
          } else {
            Text(ctx.attributes.course.uppercased())
              .font(.system(size: 11, design: .monospaced)).foregroundStyle(mut).lineLimit(1)
          }
        }
      } compactLeading: {
        Text("\(ctx.state.hole)").font(.system(size: 13, weight: .semibold, design: .monospaced))
          .foregroundStyle(brand)
      } compactTrailing: {
        // the compact island is a few characters wide: the match state earns
        // them when there is one, otherwise the count of holes played does
        Text(compact(ctx.state)).font(.system(size: 12, design: .monospaced))
          .foregroundStyle(gold).lineLimit(1)
      } minimal: {
        Text("\(ctx.state.hole)").font(.system(size: 12, weight: .semibold, design: .monospaced))
          .foregroundStyle(brand)
      }
      .widgetURL(CSRoundActivityLink.url)
      .keylineTint(brand)
    }
  }

  private func compact(_ s: CSRoundActivity.ContentState) -> String {
    // D178 · the app AUTHORS this now (LiveCopy.compactStatus). This used to
    // keep the last two words of any hero over 12 characters, which are the
    // worst ten characters in it: "NO SKINS CLAIMED YET" — the state of every
    // skins round until the first skin falls — rendered as "CLAIMED YET".
    // `compact` is nil for a plain scorecard and on any activity started by an
    // older build, so the thru/holes fraction stays the floor.
    if let c = s.compact, !c.isEmpty { return c }
    guard let g = s.game, !g.isEmpty else { return "\(s.thru)/\(s.holes)" }
    return g.count <= 12 ? g : "\(s.thru)/\(s.holes)"
  }

  private func lockScreen(_ a: CSRoundActivity, _ s: CSRoundActivity.ContentState) -> some View {
    HStack(alignment: .center, spacing: 14) {
      VStack(alignment: .leading, spacing: 3) {
        Text(a.course.uppercased())
          .font(.system(size: 10, design: .monospaced)).tracking(1.1)
          .foregroundStyle(mut).lineLimit(1)
        Text("HOLE \(s.hole)")
          .font(.system(size: 22, weight: .semibold, design: .monospaced)).foregroundStyle(ink)
        if let g = s.game {
          Text(g).font(.system(size: 13, design: .monospaced)).foregroundStyle(gold)
            .lineLimit(1).minimumScaleFactor(0.7)
        }
      }
      Spacer(minLength: 0)
      VStack(alignment: .trailing, spacing: 3) {
        Text("THRU").font(.system(size: 10, design: .monospaced)).tracking(1.1).foregroundStyle(mut)
        Text("\(s.thru)").font(.system(size: 22, weight: .semibold, design: .monospaced))
          .foregroundStyle(gold)
        if let p = s.par {
          Text("PAR \(p)").font(.system(size: 11, design: .monospaced)).foregroundStyle(mut)
        }
      }
    }
    .padding(.horizontal, 16).padding(.vertical, 12)
    .activityBackgroundTint(bg)
    .activitySystemActionForegroundColor(ink)
  }

  // the app's palette, read from the generated tokens — never a literal
  private var ink: Color { CSTokens.dark.ink }
  private var mut: Color { CSTokens.dark.mut }
  private var gold: Color { CSTokens.dark.gold }
  private var brand: Color { CSTokens.dark.brand }
  private var bg: Color { CSTokens.dark.bg1 }
}
