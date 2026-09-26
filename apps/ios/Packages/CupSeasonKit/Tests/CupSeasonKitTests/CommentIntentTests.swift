import Foundation
import Testing
@testable import CupSeasonKit

struct CommentIntentTests {
  @Test func ambiguousSendRetainsIdentityForExactRetry() {
    let parent = UUID()
    let first = CommentIntent(body: " Great round! \n", parentId: parent)
    #expect(first.body == "Great round!")
    #expect(first.forRetry(body: "Great round!", parentId: parent).id == first.id)
  }

  @Test func changedMessageOrReplyTargetIsANewIntent() {
    let first = CommentIntent(body: "Great round!", parentId: nil)
    #expect(first.forRetry(body: "See you Saturday", parentId: nil).id != first.id)
    #expect(first.forRetry(body: first.body, parentId: UUID()).id != first.id)
  }
}
