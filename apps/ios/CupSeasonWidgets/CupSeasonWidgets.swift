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
  var body: some Widget { CSRoundLiveActivity() }
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
