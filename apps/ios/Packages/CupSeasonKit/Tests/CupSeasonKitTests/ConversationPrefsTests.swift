import Testing
@testable import CupSeasonKit

/// TEN / W6 · the three conversation switches are Settings' (W2, owner C), in
/// the web's words, and a flag the server leaves out reads as on.
@Suite struct ConversationPrefsTests {
  @Test func theThreeSwitchesInTheWebsWords() {
    #expect(ConversationPrefs.all.map(\.key) == ["own_round", "replies", "followed"])
    #expect(ConversationPrefs.all.map(\.name) == ["Comments on my rounds", "Replies to me", "Conversations I follow"])
    #expect(ConversationPrefs.door == "Notification settings")
  }

  @Test func aFlagTheServerLeavesOutIsOn() {
    let v = ConversationPrefs.values(.object(["own_round": .bool(false), "replies": .bool(true)]))
    #expect(v == ["own_round": false, "replies": true, "followed": true])
  }
}
