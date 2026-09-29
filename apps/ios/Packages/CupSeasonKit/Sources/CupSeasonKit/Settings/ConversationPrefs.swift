import Foundation

/// TEN / W6 · **ONE NOTIFICATIONS SECTION** (W2, owner C). The three
/// conversation switches (D391, `social_notify_prefs` /
/// `set_social_notify_prefs`) are Settings' now. The inbox used to draw a
/// second set over the same flags — two controls for one setting, which could
/// disagree on screen — and carries one door to Settings instead. The web's
/// `CS_INBOX.prefs` / `prefsDoor` are the twin, word for word.
public enum ConversationPrefs {
  public struct Pref: Sendable, Identifiable, Equatable {
    public let key: String
    public let name: String
    public let sub: String
    public var id: String { key }
  }

  public static let all: [Pref] = [
    Pref(key: "own_round", name: "Comments on my rounds",
         sub: "When someone joins the conversation on a round you posted."),
    Pref(key: "replies", name: "Replies to me",
         sub: "When someone replies directly to one of your comments."),
    Pref(key: "followed", name: "Conversations I follow",
         sub: "New comments in threads you’ve chosen to follow."),
  ]

  /// The inbox's one door to them.
  public static let door = "Notification settings"

  /// A switch that did not save — it stays where it was.
  public static let didNotChange = "That didn’t change — try again."

  /// Reads a `social_notify_prefs` answer. A flag the server leaves out is on,
  /// as the web reads it (`data[k] !== false`).
  public static func values(_ json: JSONValue) -> [String: Bool] {
    Dictionary(uniqueKeysWithValues: all.map { ($0.key, json[$0.key]?.bool ?? true) })
  }
}
