import Foundation

public struct SocialPerson: Sendable, Equatable, Identifiable {
  public let id: UUID
  public let name: String
  public let marker: String?
  public init?(_ json: JSONValue?) {
    guard let json, let id = json["id"]?.string.flatMap(UUID.init) else { return nil }
    self.id = id; name = json["name"]?.string ?? "Golfer"; marker = json["marker"]?.string
  }
}

public struct SocialComment: Sendable, Equatable, Identifiable {
  public let id: UUID
  public let parentId: UUID?
  public let rootId: UUID?
  public let author: SocialPerson
  public let body: String
  public let createdAt: String
  public let replyTo: String?
  public let isMine: Bool
  public let canReply: Bool
  public let fromBoard: Bool
  public init?(_ json: JSONValue) {
    guard let id = json["id"]?.string.flatMap(UUID.init), let author = SocialPerson(json["author"]) else { return nil }
    self.id = id; self.author = author
    parentId = json["parent_id"]?.string.flatMap(UUID.init)
    rootId = json["root_id"]?.string.flatMap(UUID.init)
    body = json["body"]?.string ?? ""; createdAt = json["created_at"]?.string ?? ""
    replyTo = json["reply_to"]?["name"]?.string
    isMine = json["is_mine"]?.bool == true; canReply = json["can_reply"]?.bool == true
    fromBoard = json["origin"]?.string == "board"
  }
}

public struct PostedRoundThread: Sendable, Equatable {
  public let visible: Bool
  public let canComment: Bool
  public let state: String
  public let count: Int
  public let comments: [SocialComment]
  public let courseId: String?
  public let courseName: String?
  public let round: JSONValue?
  public init(_ json: JSONValue) {
    visible = json["ok"]?.bool == true
    canComment = json["can_comment"]?.bool == true
    state = json["thread"]?["state"]?.string ?? "none"
    count = json["count"]?.int ?? 0
    comments = (json["comments"]?.array ?? []).compactMap(SocialComment.init)
    courseId = json["round"]?["course"]?["api_course_id"]?.string
    courseName = json["round"]?["course"]?["name"]?.string
    round = json["round"]
  }
  /// An unavailable root must not make its visible replies disappear.
  public var roots: [SocialComment] {
    let ids = Set(comments.map(\.id))
    return comments.filter { $0.rootId == nil || !ids.contains($0.rootId!) }
  }
  public func replies(to id: UUID) -> [SocialComment] { comments.filter { $0.rootId == id && $0.id != id } }
}

public struct SocialNotice: Sendable, Equatable, Identifiable {
  public let id: UUID
  public let actor: SocialPerson
  public let roundId: UUID
  public let commentId: UUID
  public let kind: String
  public let excerpt: String
  public let course: String?
  public let createdAt: String
  public var read: Bool
  public init?(_ json: JSONValue) {
    guard let id = json["id"]?.string.flatMap(UUID.init), let actor = SocialPerson(json["actor"]),
          let roundId = json["round_id"]?.string.flatMap(UUID.init),
          let commentId = json["comment_id"]?.string.flatMap(UUID.init) else { return nil }
    self.id = id; self.actor = actor; self.roundId = roundId; self.commentId = commentId
    kind = json["kind"]?.string ?? "own_round"; excerpt = json["excerpt"]?.string ?? ""
    course = json["course_name"]?.string; createdAt = json["created_at"]?.string ?? ""
    read = json["read"]?.bool == true
  }
  public var sentence: String {
    let name = CourseNames.first(actor.name)
    switch kind {
    case "reply": return "\(name) replied to your comment."
    case "followed": return "\(name) commented in a conversation you follow."
    default: return "\(name) commented on your round."
    }
  }
}

/// Writes use the complete request once. In particular a retry must never drop
/// the idempotency key or reply target to accommodate an older server.
public struct RoundSocialService: Sendable {
  public init() {}
  public func request(_ name: String, _ params: [String: JSONValue] = [:]) async throws -> JSONValue {
    #if DEBUG
    if SocialBlendFixture.enabled { return try await SocialBlendFixture.shared.response(name, params) }
    #endif
    switch name {
    case "posted_round_thread": return try await call(Rpc.posted_round_thread.self, params)
    case "add_posted_round_comment": return try await call(Rpc.add_posted_round_comment.self, params)
    case "set_round_thread_state": return try await call(Rpc.set_round_thread_state.self, params)
    case "remove_posted_round_comment": return try await call(Rpc.remove_posted_round_comment.self, params)
    case "my_notifications": return try await call(Rpc.my_notifications.self, params)
    case "mark_notifications_read": return try await call(Rpc.mark_notifications_read.self, params)
    case "notification_badge": return try await call(Rpc.notification_badge.self, params)
    case "social_notify_prefs": return try await call(Rpc.social_notify_prefs.self, params)
    case "set_social_notify_prefs": return try await call(Rpc.set_social_notify_prefs.self, params)
    case "course_page": return try await call(Rpc.course_page.self, params)
    case "posted_rounds_social": return try await call(Rpc.posted_rounds_social.self, params)
    default: throw RpcError(name: name, underlying: "Unknown social request.", droppedArgs: [])
    }
  }
  private func call<C: RpcCall>(_ endpoint: C.Type, _ params: [String: JSONValue]) async throws -> JSONValue where C.Returns == JSONValue {
    try await SupabaseService.shared.callJSON(endpoint, params: .object(params))
  }
  public func thread(_ id: UUID, focus: UUID? = nil) async throws -> PostedRoundThread {
    var params: [String: JSONValue] = ["p_round": .string(id.uuidString)]
    if let focus { params["p_focus"] = .string(focus.uuidString) }
    do { return PostedRoundThread(try await request("posted_round_thread", params)) }
    catch {
      // Only this additive read argument may fall back on an older server.
      guard focus != nil, (error as? RpcError)?.isMissingFunction == true else { throw error }
      return PostedRoundThread(try await request("posted_round_thread", ["p_round": .string(id.uuidString)]))
    }
  }
  public func send(_ round: UUID, intent: CommentIntent) async throws -> UUID? {
    let answer = try await request("add_posted_round_comment", [
      "p_round": .string(round.uuidString), "p_body": .string(intent.body),
      "p_parent": intent.parentId.map { .string($0.uuidString) } ?? .null,
      "p_client_id": .string(intent.id.uuidString)])
    guard answer["ok"]?.bool == true else { throw RpcError(name: "comment", underlying: "Could not send this comment.", droppedArgs: []) }
    return answer["comment"]?["id"]?.string.flatMap(UUID.init)
  }
  public func state(_ round: UUID, _ state: String) async throws {
    _ = try await request("set_round_thread_state", ["p_round": .string(round.uuidString), "p_state": .string(state)])
  }
  public func remove(_ comment: UUID) async throws {
    _ = try await request("remove_posted_round_comment", ["p_comment": .string(comment.uuidString)])
  }
  public func report(_ comment: UUID, reason: String) async throws {
    _ = try await SupabaseService.shared.callJSON(Rpc.report_content.self, params: .object([
      "p_kind": .string("comment"), "p_comment": .string(comment.uuidString), "p_reason": .string(reason)]))
  }
}
