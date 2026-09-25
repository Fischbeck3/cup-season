#if DEBUG
import SwiftUI
import CSDesign
import CupSeasonKit

@MainActor enum LiveIslandReviewFixture {
  static var on: Bool { ProcessInfo.processInfo.arguments.contains("-cs_dev_island") }
  static var variant: String { CompeteSelectedFixture.arg("-cs_island_state", "missed") }
  static let owner = UUID(uuidString: "aaaaaaaa-3333-4444-8888-111111111111")!
  static func sample() -> LiveRoundState {
    var me = LivePlayer(n: "You", i: 0, ci: 1, guest: false, me: true, locked: true, mk: nil)
    me.pid = owner
    var other = LivePlayer(n: variant == "long" ? "Alexandra Montgomery-Williams" : "Galen", i: 0, ci: 2, guest: false)
    other.pid = UUID()
    var s = LiveRoundState.fresh(players: [me, other])
    s.lr = UUID(); s.code = "PREVIEW"; s.pmap = [UUID(), UUID()]
    s.active = true; s.stage = .live; s.game = .match; s.hole = 2
    s.course.label = "Papago · sample round"
    s.course.save(front: [4,4,3,5,4,4,4,3,5], back: [4,4,3,4,5,4,3,4,5], nine: false)
    s.scores[0][0] = 4; s.scores[1][0] = 5; s.scores[1][1] = 4
    s.scts[0][0] = 1; s.scts[1][0] = 1; s.scts[1][1] = 1
    if variant == "square" { s.scores[1][0] = 4 }
    if variant == "down" { s.scores[0][0] = 6 }
    if variant == "nine" { s.holes = 9; s.hole = 8 }
    if variant == "last" { s.hole = 17 }
    if variant == "solo" { s.game = .score }
    if variant == "closed" {
      for h in 0..<10 { s.scores[0][h] = 3; s.scores[1][h] = 4 }
      s.hole = 10
    }
    s.ts = LiveFmt.now()
    return s
  }
}

struct LiveIslandReviewFixtureView: View {
  @Environment(\.cs) private var cs
  @State private var live: LiveRoundStore
  @State private var error: String?
  init() {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("cs-island-review-\(UUID())")
    let store = LiveRoundStore(disk: LiveDisk(directory: dir))
    store.adoptActivityRound(LiveIslandReviewFixture.sample(), owner: LiveIslandReviewFixture.owner)
    _live = State(initialValue: store)
  }
  private var presentation: LiveMatchActivityView {
    let (attrs, state) = LiveActivityHost.facts(live.state, saveState: live.queued > 0 ? "Saved on phone" : nil)
    return LiveMatchActivityView(attributes: attrs, state: state, stale: LiveIslandReviewFixture.variant == "stale", previewAction: { action in
      guard let action = LiveIsland.Action(rawValue: action), let round = live.state.lr else { return }
      let hole = live.state.hole + 1
      Task {
        do {
          try await live.activityAction(action, round: round, owner: LiveIslandReviewFixture.owner, hole: hole,
            currentOwner: { LiveIslandReviewFixture.owner }, sync: false)
          error = nil
        } catch { self.error = error.localizedDescription }
      }
    })
  }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
        Text("Match first").csType(.display)
        Text("Native Live Activity review · sample round").csType(.agate).foregroundStyle(cs.mut)
        Text("Compact").csType(.agate)
        HStack {
          Text("H\(live.state.hole + 1)").foregroundStyle(CSTokens.dark.brand)
          Spacer(minLength: CSTokens.Space.s6)
          Text(presentation.compact).foregroundStyle(CSTokens.dark.ink)
        }.csType(.agate).padding(CSTokens.Space.s3)
          .frame(maxWidth: 230).modifier(CSActivityReviewSurface(compact: true))
        Text("Expanded").csType(.agate)
        VStack(spacing: CSTokens.Space.s1) {
          HStack { presentation.leading; Spacer(minLength: CSTokens.Space.s6); presentation.trailing }
          presentation.controls
        }
        .padding(.horizontal, CSTokens.Space.s3)
        .padding(.vertical, CSTokens.Space.s2)
        .modifier(CSActivityReviewSurface())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("islandControls")
        Text("Hole 2 · \(live.state.scores[0][1].map(String.init) ?? "not entered")")
          .csType(.agate).accessibilityIdentifier("savedHoleTwo")
        if let error { Text(error).csType(.bodyS) }
      }.padding(CSTokens.Space.s4)
    }.background(cs.bg1).accessibilityIdentifier("islandReview")
  }
}
#endif
