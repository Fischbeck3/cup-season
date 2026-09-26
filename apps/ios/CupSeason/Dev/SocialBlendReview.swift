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
  var body: some View {
    Group {
      if activity { SocialActivitySheet(inbox: inbox) }
      else if conversation {
        RoundReceiptSheet(roundId: SocialBlendFixture.roundID, seed: nil, focusComments: true)
      } else {
        NavigationStack {
          ScrollView {
            VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
              Text("North Grove").csType(.display)
              Text("Example records · UI review").csType(.agateS).foregroundStyle(cs.mut)
              CourseCircleSection(courseId: "fixture-north-grove", courseName: "North Grove")
            }.padding(CSTokens.Space.gutter)
          }.background(cs.bg0)
        }
      }
    }
    .environment(\.presenter, presenter)
    .csSheet(item: $presenter.receipt) { id in RoundReceiptSheet(roundId: id, seed: nil) }
  }
}
#endif
