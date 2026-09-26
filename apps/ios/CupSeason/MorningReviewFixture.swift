#if DEBUG
import SwiftUI
import CSDesign
import CupSeasonKit

/// Production views on invented records for the morning design review.
/// The composition root bypasses auth, push, links, and launch telemetry.
/// Setup does not create a round; no round ID is supplied to sharing.
@MainActor enum MorningReviewFixture {
  static var on: Bool { ProcessInfo.processInfo.arguments.contains("-cs_dev_morning_review") || ProcessInfo.processInfo.arguments.contains("-cs_dev_round_share_fixture") || SocialBlendFixture.enabled }
  static var scene: String { CompeteSelectedFixture.arg("-cs_review_scene", ProcessInfo.processInfo.arguments.contains("-cs_dev_round_share_fixture") ? "share" : "setup") }
  static var long: Bool { ProcessInfo.processInfo.arguments.contains("-cs_review_long") }
  static var photo: UIImage? { (ProcessInfo.processInfo.arguments.contains("-cs_review_photo") || ProcessInfo.processInfo.arguments.contains("-cs_dev_share_photo")) ? ReceiptPhotoDev.image : nil }
  static var recap: PostRecap {
    PostRecap(name: long ? "Alexandra Montgomery-Williams" : "Alex Morgan", marker: "lonetree", gross: 84, pvi: 2.4, points: 9,
      course: long ? "The Championship Course at Whispering Pines" : "Encanto Golf Course", date: "2026-09-24", badge: nil)
  }
  static let receiptID = UUID(uuidString: "99999999-2222-4444-8888-111111111111")!
  static var receipt: ReceiptSeed {
    ReceiptSeed(id: receiptID, gross: 84, differential: 13.1, indexAtPost: 16.3,
      playedOn: "2026-09-24", courseLabel: "Encanto Golf Course", holesPlayed: 18,
      rating: 70.2, slope: 119, pvi: 2.4, playingIndex: 15.5, points: 9,
      monthRank: 2, countingCap: 3, attested: true, playedWith: ["Danny", "Chuck", "Gary"],
      isMine: true, marker: "lonetree")
  }
  static func liveStore() -> LiveRoundStore {
    let s = LiveRoundStore()
    s.seedMorningReview(live: scene != "setup")
    if scene == "score" { s.state.game = .score }
    if scene == "offline" { s.state.lr = UUID(); s.syncStatus = "CLOSED"; s.queued = 3 }
    if scene == "kept" { s.scoreOnPhone = true }
    return s
  }
}

struct MorningReviewFixtureView: View {
  @State private var store = MorningReviewFixture.liveStore()
  var body: some View {
    if SocialBlendFixture.enabled {
      SocialBlendReview()
    } else if MorningReviewFixture.scene == "receipt" {
      RoundReceiptSheet(roundId: MorningReviewFixture.receiptID, seed: MorningReviewFixture.receipt)
        .allowsHitTesting(false) // Capture-only receipt; no pretend accepted writes.
    } else if MorningReviewFixture.scene == "share" {
      RoundSharePreview(recap: MorningReviewFixture.recap, photo: MorningReviewFixture.photo)
    } else {
      NavigationStack {
        if store.state.active { LivePlayView(store: store, links: LiveLinks()) }
        else { LiveSetupView(store: store) }
      }
    }
  }
}
#endif
