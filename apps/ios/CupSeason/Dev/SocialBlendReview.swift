#if DEBUG
import SwiftUI
import CSDesign
import CupSeasonKit

struct SocialBlendReview: View {
  @Environment(\.cs) private var cs
  @State private var presenter = Presenter()
  @State private var inbox = SocialInboxStore()
  private var activity: Bool { ProcessInfo.processInfo.arguments.contains("-cs_social_activity") }
  private var conversation: Bool { ProcessInfo.processInfo.arguments.contains("-cs_social_comments") }
  private var receipt: Bool { ProcessInfo.processInfo.arguments.contains("-cs_social_receipt") }
  var body: some View {
    Group {
      if activity { SocialActivitySheet(inbox: inbox) }
      else if conversation || receipt {
        RoundReceiptSheet(roundId: SocialBlendFixture.roundID, seed: nil, focusComments: conversation)
      } else {
        NavigationStack {
          VStack { CourseHomeLink() }
            .frame(maxWidth: .infinity, maxHeight: .infinity).background(cs.bg0)
        }
      }
    }
    .environment(\.presenter, presenter)
    .csSheet(item: $presenter.receipt) { id in RoundReceiptSheet(roundId: id, seed: nil) }
  }
}
#endif
