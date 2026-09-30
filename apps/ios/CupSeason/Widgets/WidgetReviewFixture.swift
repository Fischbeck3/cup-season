#if DEBUG
import SwiftUI
import WidgetKit
import CSDesign
import CupSeasonKit

/// In-memory review records only. Never written to the App Group or sent to a service.
@MainActor enum WidgetReviewFixture {
  static var on: Bool { ProcessInfo.processInfo.arguments.contains("-cs_dev_widgets") }
  static var kind: BetweenRoundsKind {
    BetweenRoundsKind(rawValue: CompeteSelectedFixture.arg("-cs_widget_kind", "CSSeasonWidget")) ?? .race
  }
  static var state: String { CompeteSelectedFixture.arg("-cs_widget_state", "full") }
  static var now: Date { Date(timeIntervalSince1970: 1_790_352_000) }
  static var snapshot: BetweenRoundsSnapshot? {
    if state == "empty" { return nil }
    let id = UUID(uuidString: "aaaaaaaa-2222-4444-8888-111111111111")!
    let long = state == "long"
    var s = BetweenRoundsSnapshot(owner: id)
    s.race = .init(.init(league: id, name: long ? "The Saturday Morning Golf Society" : "North Grove (fixture)", context: "Week 7 · Cup points", standing: "2nd of 8", story: "3 back of Blake.", rows: [
      .init(id: "1", name: long ? "Alexandra Montgomery-Williams" : "Blake", rank: "01", points: 118, mine: false),
      .init(id: "2", name: "You", rank: "02", points: 115, mine: true),
      .init(id: "3", name: "Emery", rank: "03", points: 109, mine: false)
    ]), at: now)
    s.nextTee = .init(.init(id: id, playOn: "2026-09-26", day: "26", month: "Sep", dateLine: "Sat Sep 26", time: "7:10 AM",
      course: long ? "The Championship Course at Whispering Pines" : "Saguaro Flats", company: "Blake · Emery", closesAt: now.addingTimeInterval(86_400),
      status: state == "confirmed" ? "in" : nil, canReply: true, replyError: state == "error" ? "Couldn’t confirm. Open the plan." : nil), at: now)
    s.record = .init(.init(id: id, headline: state == "nine" ? "Your last round." : "Broke 80", course: "Saguaro Flats · with Blake", date: "Sep 19", gross: state == "nine" ? 39 : 79,
      holes: state == "nine" ? 9 : 18, out: state == "nine" ? nil : 38, inn: state == "nine" ? nil : 41, earned: state != "nine"), at: now)
    s.rivalry = .init(.init(opponent: id, name: long ? "Alexandra Montgomery-Williams" : "Blake", scope: "Weekly clashes · All time",
      story: "Blake took the last one.", detail: "Week of Sep 14", wins: 6, losses: 5, ties: 1), at: now)
    // D400 · What's On: Home's own sentences, in the ranker's order
    s.hasSeason = true
    s.whatsOn = .init(.init(items: [
      .init(key: "clash:1", eyebrow: "Clash week", headline: long ? "You and Alexandra Montgomery-Williams, two days left in the week’s clash." : "You and Blake, two days left.",
            action: "See the clash", spine: "ember", route: "season", routeId: id, pane: "table"),
      .init(key: "circle:1", eyebrow: "Your circle", headline: "Emery posted 78 at Saguaro Flats. Her best this year.",
            action: "See the round", spine: "gold", route: "receipt", routeId: id, pane: nil),
      .init(key: "plan:1", eyebrow: "Sat · Saguaro Flats", headline: "Saturday 7:10 at Saguaro Flats with Blake and Emery.",
            action: "Reply", spine: "mut", route: "plan", routeId: id, pane: nil),
      .init(key: "floor:1", eyebrow: "October closes Sat", headline: "One round to your October minimum.",
            action: "Add my round", spine: "mut", route: "home", routeId: nil, pane: nil),
    ]), at: now)
    return s
  }
}

struct WidgetReviewFixtureView: View {
  @Environment(\.cs) private var cs
  private var date: Date { WidgetReviewFixture.now.addingTimeInterval(WidgetReviewFixture.state == "stale" ? 90_000 : 0) }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
        Text(WidgetReviewFixture.kind.title).csType(.display)
        Text("Native widget review · sample records").csType(.agate).foregroundStyle(cs.mut)
        widget(.systemMedium).frame(height: 170)
        if WidgetReviewFixture.kind == .whatsOn { widget(.systemLarge).frame(height: 364) }
        HStack(alignment: .top, spacing: CSTokens.Space.s3) {
          widget(.systemSmall).frame(width: 162, height: 170)
          if WidgetReviewFixture.kind == .race || WidgetReviewFixture.kind == .nextTee || WidgetReviewFixture.kind == .whatsOn {
            widget(.accessoryRectangular).frame(height: 84)
          }
        }
      }.padding(CSTokens.Space.s4)
    }
    .background(cs.bg1)
    .accessibilityIdentifier("widgetReview")
  }
  private func widget(_ family: WidgetFamily) -> some View {
    BetweenRoundsWidgetView(previewFamily: family, kind: WidgetReviewFixture.kind, snapshot: WidgetReviewFixture.snapshot, date: date)
      .background(cs.bg0, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r))
      .allowsHitTesting(false)
  }
}
#endif
