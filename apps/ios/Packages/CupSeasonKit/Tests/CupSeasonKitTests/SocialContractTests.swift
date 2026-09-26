import Foundation
import Testing
@testable import CupSeasonKit

struct SocialContractTests {
  private func json(_ value: String) throws -> JSONValue { try JSONDecoder().decode(JSONValue.self, from: Data(value.utf8)) }
  @Test func orphanedReplyRemainsVisibleAndLegacyCannotReply() throws {
    let thread = PostedRoundThread(try json("""
      {"ok":true,"can_comment":true,"count":2,"comments":[
      {"id":"11111111-1111-4111-8111-111111111111","root_id":"22222222-2222-4222-8222-222222222222","author":{"id":"33333333-3333-4333-8333-333333333333","name":"Alex"},"body":"A reply","can_reply":true},
      {"id":"44444444-4444-4444-8444-444444444444","author":{"id":"33333333-3333-4333-8333-333333333333","name":"Alex"},"body":"League only","origin":"board","can_reply":false}]}
      """))
    #expect(thread.roots.count == 2)
    #expect(thread.comments[1].fromBoard)
    #expect(!thread.comments[1].canReply)
  }
  @Test func invisibleThreadNeverClaimsCommentPermission() throws {
    let thread = PostedRoundThread(try json("{\"ok\":false,\"reason\":\"not_visible\"}"))
    #expect(!thread.visible && !thread.canComment && thread.comments.isEmpty)
  }
  @Test func courseBestComesFromServerNotRecentHistory() throws {
    let page = CourseCirclePage(try json("""
      {"best":{"gross":68},"selection":{"tee_name":"White","holes":18},"people":[]}
      """))
    #expect(page.best == 68)
    #expect(page.people.isEmpty)
    #expect(page.selectionLine == "White · 18 holes · Gross")
  }
}
