// Cup Season — D155 · the round on the lock screen and in the Dynamic Island.
//
// A golfer puts the phone away between every shot, so the one moment the app
// must be one tap away is the one moment it is furthest. IOS-083 brings match
// status and the golfer's own score controls to the expanded surface. The app
// publishes facts and executes authenticated intents. Season points stay absent:
// they score per ROUND
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
    BetweenRoundsWidget(kind: .race)
    BetweenRoundsWidget(kind: .nextTee)
    BetweenRoundsWidget(kind: .record)
    BetweenRoundsWidget(kind: .rivalry)
  }
}

struct BetweenRoundsEntry: TimelineEntry {
  let date: Date
  let snapshot: BetweenRoundsSnapshot?
}
struct BetweenRoundsProvider: TimelineProvider {
  func placeholder(in context: Context) -> BetweenRoundsEntry { .init(date: Date(), snapshot: nil) }
  func getSnapshot(in context: Context, completion: @escaping (BetweenRoundsEntry) -> Void) {
    completion(.init(date: Date(), snapshot: BetweenRoundsSnapshot.read()))
  }
  func getTimeline(in context: Context, completion: @escaping (Timeline<BetweenRoundsEntry>) -> Void) {
    let now = Date(), snapshot = BetweenRoundsSnapshot.read()
    let entries = (snapshot?.timelineDates(now: now) ?? [now]).map { BetweenRoundsEntry(date: $0, snapshot: snapshot) }
    completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(3600))))
  }
}
struct BetweenRoundsWidget: Widget {
  let kind: BetweenRoundsKind
  init() { kind = .race }
  init(kind: BetweenRoundsKind) { self.kind = kind }
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind.rawValue, provider: BetweenRoundsProvider()) { entry in
      BetweenRoundsWidgetView(kind: kind, snapshot: entry.snapshot, date: entry.date)
    }
    .configurationDisplayName(kind.title)
    .description(description)
    .supportedFamilies(kind == .race || kind == .nextTee ? [.systemSmall, .systemMedium, .accessoryRectangular] : [.systemSmall, .systemMedium])
    .contentMarginsDisabled()
  }
  private var description: String {
    switch kind {
    case .race: "Your place in the season, with the points and names around you."
    case .nextTee: "Your next tee time. Reply to an invitation right here."
    case .record: "A round to keep, from your own record."
    case .rivalry: "The weekly clash record between you and a familiar rival."
    }
  }
}

struct CSRoundLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: CSRoundActivity.self) { ctx in
      let p = LiveMatchActivityView(attributes: ctx.attributes, state: ctx.state, stale: ctx.isStale)
      VStack(spacing: CSTokens.Space.s1) {
        HStack { p.leading; Spacer(minLength: 0); p.trailing }
        p.controls
      }
      .padding(.horizontal, CSTokens.Space.s3)
      .padding(.vertical, CSTokens.Space.s2)
      .activityBackgroundTint(CSTokens.dark.bg0)
      .activitySystemActionForegroundColor(CSTokens.dark.ink)
      .widgetURL(CSRoundActivityLink.url(round: ctx.attributes.round, owner: ctx.attributes.owner))
    } dynamicIsland: { ctx in
      let p = LiveMatchActivityView(attributes: ctx.attributes, state: ctx.state, stale: ctx.isStale)
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) { p.leading }
        DynamicIslandExpandedRegion(.trailing) { p.trailing }
        DynamicIslandExpandedRegion(.bottom) { p.controls }
      } compactLeading: {
        Text("H\(ctx.state.hole)").csType(.agate).foregroundStyle(CSTokens.dark.brand)
      } compactTrailing: {
        Text(p.compact).csType(.agateS).foregroundStyle(CSTokens.dark.ink)
          .lineLimit(1).minimumScaleFactor(0.75).privacySensitive()
      } minimal: {
        Text("\(ctx.state.hole)").csType(.agate).foregroundStyle(CSTokens.dark.brand)
      }
      .widgetURL(CSRoundActivityLink.url(round: ctx.attributes.round, owner: ctx.attributes.owner))
      .keylineTint(CSTokens.dark.brand)
    }
  }
}
