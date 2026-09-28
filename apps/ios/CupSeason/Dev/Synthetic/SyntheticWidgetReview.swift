// Cup Season — `-cs_dev_widgets -cs_dev_synthetic <scenario>`: the widget
// review host, fed by the REAL producer.
//
// The pre-seam review host (`WidgetReviewFixture`) draws a hand-typed
// snapshot whose names belong to real golfers, so its populated states could
// not be used as evidence. This host instead runs `BetweenRoundsFeed.refresh`
// — the exact producer Home runs — against the synthetic world, reads back the
// snapshot it wrote to this app's own defaults, and renders the production
// `BetweenRoundsWidgetView` with it. The system widget host (the home screen
// and its timeline) is NOT exercised here; that stays device evidence.

#if DEBUG
import SwiftUI
import WidgetKit
import CSDesign
import CupSeasonKit

struct SyntheticWidgetReview: View {
  @Environment(\.cs) private var cs
  @State private var snapshot: BetweenRoundsSnapshot?
  @State private var loaded = false
  private var kind: BetweenRoundsKind { WidgetReviewFixture.kind }
  private var empty: Bool { WidgetReviewFixture.state == "empty" }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
        Text(kind.title).csType(.display)
        Text("Native widget review · synthetic records from the app's own producer").csType(.agate).foregroundStyle(cs.mut)
        if loaded {
          widget(.systemMedium).frame(height: 170)
          HStack(alignment: .top, spacing: CSTokens.Space.s3) {
            widget(.systemSmall).frame(width: 162, height: 170)
            if kind == .race || kind == .nextTee { widget(.accessoryRectangular).frame(height: 84) }
          }
        }
      }
      .padding(CSTokens.Space.s4)
    }
    .background(cs.bg1)
    .accessibilityIdentifier("widgetReview")
    .csScreenMark("widget")
    .task { await produce() }
  }

  private func widget(_ family: WidgetFamily) -> some View {
    BetweenRoundsWidgetView(previewFamily: family, kind: kind, snapshot: empty ? nil : snapshot, date: Date())
      .background(cs.bg0)
      .allowsHitTesting(false)
  }

  /// Boot the synthetic `Me`, claim the widget's owner, run the producer.
  private func produce() async {
    defer { loaded = true }
    guard !empty, let uid = SyntheticWorld.viewerID,
          let me = try? await SupabaseMeRepository().load(userId: uid) else { return }
    DispatchSnapshot.claim(owner: uid)
    await BetweenRoundsFeed.shared.refresh(me: me, preferredLeague: me.memberships.first?.league_id)
    snapshot = BetweenRoundsSnapshot.read()
  }
}
#endif
