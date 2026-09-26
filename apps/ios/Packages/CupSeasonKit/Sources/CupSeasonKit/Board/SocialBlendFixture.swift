#if DEBUG
import Foundation

/// Synthetic contract responses for simulator UI checks. This actor does no I/O
/// and is absent from Release. Production view code consumes the same shapes.
public actor SocialBlendFixture {
  public static let shared = SocialBlendFixture()
  public static var enabled: Bool { ProcessInfo.processInfo.arguments.contains("-cs_dev_social_review") }
  public static let roundID = UUID(uuidString: "22222222-2222-4222-8222-222222222222")!
  private static let personID = "11111111-1111-4111-8111-111111111111"
  private var extra: [JSONValue] = []
  private var read = false
  private var state = "none"
  private var prefs: [String: JSONValue] = ["own_round": .bool(true), "replies": .bool(true), "followed": .bool(true)]
  private func json(_ text: String) -> JSONValue { try! JSONDecoder().decode(JSONValue.self, from: Data(text.utf8)) }
  public func response(_ name: String, _ params: [String: JSONValue]) throws -> JSONValue {
    let author = json("{\"id\":\"\(Self.personID)\",\"name\":\"Theo Park\",\"marker\":\"lonetree\"}")
    let round = Self.roundID.uuidString
    switch name {
    case "posted_round_thread":
      let first = json("""
      {"id":"33333333-3333-4333-8333-333333333333","body":"Did the putt on 18 drop?","created_at":"2026-09-25T17:02:11Z","is_mine":false,"can_reply":true,"origin":"round"}
      """)
      let comments = [adding(first, ["author": author])] + extra
      return .object(["ok": .bool(true), "can_comment": .bool(true), "count": .number(Double(comments.count)),
        "thread": .object(["state": .string(state)]), "comments": .array(comments),
        "round": .object(["id": .string(round), "owner": author, "gross": .number(79), "holes": .number(18),
          "played_on": .string("2026-09-24"), "is_mine": .bool(false),
          "course": .object(["api_course_id": .string("fixture-north-grove"), "name": .string("North Grove")])])])
    case "add_posted_round_comment":
      if params["p_body"]?.string == "Offline check" {
        throw RpcError(name: name, underlying: "The connection was lost.", droppedArgs: [])
      }
      let comment: JSONValue = .object(["id": params["p_client_id"] ?? .string(UUID().uuidString),
        "author": author, "body": params["p_body"] ?? .string(""), "parent_id": params["p_parent"] ?? .null,
        "root_id": params["p_parent"] ?? .null, "created_at": .string("2026-09-25T18:10:00Z"),
        "is_mine": .bool(true), "can_reply": .bool(true), "origin": .string("round")])
      extra.append(comment); return .object(["ok": .bool(true), "comment": comment])
    case "set_round_thread_state": state = params["p_state"]?.string ?? "none"; return .object(["ok": .bool(true)])
    case "remove_posted_round_comment": extra.removeAll { $0["id"] == params["p_comment"] }; return .object(["ok": .bool(true)])
    case "my_notifications":
      return .object(["ok": .bool(true), "unread": .number(read ? 0 : 1), "items": .array([.object([
        "id": .string("44444444-4444-4444-8444-444444444444"), "kind": .string("reply"), "actor": author,
        "round_id": .string(round), "comment_id": .string("33333333-3333-4333-8333-333333333333"),
        "created_at": .string("2026-09-25T17:02:11Z"), "read": .bool(read),
        "excerpt": .string("Did the putt on 18 drop?"), "course_name": .string("North Grove")])])])
    case "mark_notifications_read": read = true; return .object(["ok": .bool(true), "unread": .number(0)])
    case "social_notify_prefs": return .object(prefs)
    case "set_social_notify_prefs":
      for key in Array(prefs.keys) { if let value = params["p_" + key] { prefs[key] = value } }
      return .object(prefs)
    case "course_page":
      let holes = params["p_holes"]?.int ?? 18
      let tee = params["p_tee"]?.string ?? "white@70.1/124"
      let white = tee.hasPrefix("white")
      let teeName = white ? "White" : "Blue"
      let score = white ? 72 : 76
      let best: JSONValue = holes == 18 ? .object(["gross": .number(Double(score)), "holders": .array([
        .object(["round_id": .string(round), "person": author, "played_on": .string("2026-09-20")])])]) : .null
      let history = json("""
      [{"round_id":"\(round)","gross":72,"holes":18,"played_on":"2026-09-20","tee_name":"White","in_selection":true},
       {"round_id":"55555555-5555-4555-8555-555555555555","gross":78,"holes":18,"played_on":"2026-09-10","tee_name":"White","in_selection":true}]
      """)
      return .object(["ok": .bool(true), "selection": .object(["tee_key": .string(tee), "tee_name": .string(teeName), "holes": .number(Double(holes))]),
        "scope": .object(["best_label": .string("Your circle best"), "note": .string("From your rounds, your friends' rounds and the rounds of the golfers in your seasons, Ryders and Majors. Not an official course record.")]),
        "best": best, "my_best": .null, "unknown_tee_rounds": .number(1),
        "best_unavailable": holes == 9 ? .string("nine_side_unrecorded") : .null,
        "tees": json("[{\"key\":\"white@70.1/124\",\"name\":\"White\"},{\"key\":\"blue@72.0/130\",\"name\":\"Blue\"}]"),
        "people": .array([.object(["person": author, "relation": .string("friend"), "rounds_total": .number(2),
          "best_in_selection": holes == 18 ? .object(["gross": .number(Double(score)), "round_id": .string(round)]) : .null, "rounds": history])])])
    default: return .null
    }
  }
  private func adding(_ value: JSONValue, _ fields: [String: JSONValue]) -> JSONValue {
    guard case .object(var object) = value else { return value }
    object.merge(fields) { _, new in new }; return .object(object)
  }
}
#endif
