import Testing
@testable import CupSeasonKit

/// N4-099 (root's ruling) · an inbox at zero is a cleared queue, not an empty
/// object: it says the web's `CS_INBOX.empty`, and it has no door.
struct InboxCopyTests {
  @Test func anEmptyInboxIsCaughtUp() {
    #expect(SocialNotice.inboxEmpty == "You’re all caught up.")
  }
}
