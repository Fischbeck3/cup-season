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
  /// Contract v1.3 §1: how many came from the newest page, and whether older
  /// comments exist that were not sent. A server before `page` answers with
  /// the rows it sent and the count.
  public let newest: Int
  public let truncated: Bool
  /// `notify_prefs`: the switches the composer's line reports (on unless off)
  public let followedOn: Bool
  public let repliesOn: Bool
  public let ownRoundOn: Bool
  /// D405 · whose round it is and what it was, from `round` — the composer,
  /// the round's page and its conversation head say them
  public let ownerId: UUID?
  public let ownerName: String?
  public let ownerMarker: String?
  public let gross: Int?
  public let isMine: Bool
  public init(_ json: JSONValue) {
    visible = json["ok"]?.bool == true
    canComment = json["can_comment"]?.bool == true
    state = json["thread"]?["state"]?.string ?? "none"
    count = json["count"]?.int ?? 0
    comments = (json["comments"]?.array ?? []).compactMap(SocialComment.init)
    courseId = json["round"]?["course"]?["api_course_id"]?.string
    courseName = json["round"]?["course"]?["name"]?.string
    round = json["round"]
    newest = json["page"]?["newest"]?.int ?? comments.count
    truncated = json["page"]?["truncated"]?.bool ?? (count > comments.count)
    followedOn = json["notify_prefs"]?["followed"]?.bool != false
    repliesOn = json["notify_prefs"]?["replies"]?.bool != false
    ownRoundOn = json["notify_prefs"]?["own_round"]?.bool != false
    ownerId = json["round"]?["owner"]?["id"]?.string.flatMap(UUID.init)
    ownerName = json["round"]?["owner"]?["name"]?.string
    ownerMarker = json["round"]?["owner"]?["marker"]?.string
    gross = json["round"]?["gross"]?.int
    isMine = json["round"]?["is_mine"]?.bool == true
  }
  /// D405 · what this golfer will hear about (derived from the stored state)
  public var notify: TalkCopy.Notify { TalkCopy.notify(state: state, isMine: isMine, ownRoundOn: ownRoundOn) }
  public var notifyOptions: [TalkCopy.Notify] { TalkCopy.notifyOptions(isMine: isMine, ownRoundOn: ownRoundOn) }
  public var placeholder: String { TalkCopy.placeholder(owner: ownerName, gross: gross, mine: isMine) }
  public var conversationHead: String { TalkCopy.conversationHead(owner: ownerName, gross: gross, mine: isMine) }
  public var hint: String {
    TalkCopy.hint(state: state, followedOn: followedOn, repliesOn: repliesOn, isMine: isMine, ownRoundOn: ownRoundOn)
  }
  /// The in-line view (D405): the newest `limit` comments, flat, oldest first.
  /// A reply says "To Blake"; the round's own page keeps replies nested.
  public func recent(_ limit: Int = 3) -> [SocialComment] { Array(comments.suffix(limit)) }
  /// N in "Earlier comments (N)": the comments the server says exist that the
  /// in-line view is not showing.
  public func earlierCount(showing: Int) -> Int { max(0, count - showing) }
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
  /// D405 · `my_notifications` names the round's owner and says whether it is
  /// yours. nil on a server before the migration, which keeps the older sentences.
  public let roundOwnerName: String?
  public let roundIsMine: Bool?
  public init?(_ json: JSONValue) {
    guard let id = json["id"]?.string.flatMap(UUID.init), let actor = SocialPerson(json["actor"]),
          let roundId = json["round_id"]?.string.flatMap(UUID.init),
          let commentId = json["comment_id"]?.string.flatMap(UUID.init) else { return nil }
    self.id = id; self.actor = actor; self.roundId = roundId; self.commentId = commentId
    kind = json["kind"]?.string ?? "own_round"; excerpt = json["excerpt"]?.string ?? ""
    course = json["course_name"]?.string; createdAt = json["created_at"]?.string ?? ""
    read = json["read"]?.bool == true
    roundOwnerName = json["round_owner_name"]?.string
    roundIsMine = json["round_is_mine"]?.bool
  }
  /// The three sentences both clients print (contract §3), naming the round
  /// since D405: *"Blake replied to you on Theo’s round."*, *"Blake commented
  /// on Theo’s round at North Grove."*, *"Blake commented on your round."*.
  /// A server that predates D405 does not say whose round it is, and the older
  /// words stand rather than guess. When the commenter owns the round the
  /// sentence repeats the name — one rule, no special case.
  public var sentence: String {
    let name = CourseNames.first(actor.name)
    let owner = roundOwnerName.flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : TalkCopy.first($0) }
    switch kind {
    case "reply":
      if roundIsMine == true { return "\(name) replied to you on your round." }
      if roundIsMine == false, let owner { return "\(name) replied to you on \(owner)’s round." }
      return "\(name) replied to your comment."
    case "followed":
      // an older server does not say whether the round is yours (it does say whose it is), and a golfer
      // who chose Every comment on their own round would be named in the third person: until it does, the
      // older words stand
      guard let mine = roundIsMine else { return "\(name) commented in a conversation you’re in." }
      // a golfer who chose Every comment on their own round (their own-round notice off) is told
      // about it as a followed thread: it is their round
      if mine { return "\(name) commented on your round." }
      guard let owner else { return "\(name) commented in a conversation you’re in." }
      let at = course.flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
      return "\(name) commented on \(owner)’s round" + (at.map { " at \($0)" } ?? "") + "."
    default: return "\(name) commented on your round."
    }
  }
  /// N4-099 (root's ruling) · an inbox at zero is a cleared queue, not an
  /// empty object, so it has no door: the web's `CS_INBOX.empty`, word for word.
  public static let inboxEmpty = "You’re all caught up."
}

/// A server timestamp (`2026-09-25T17:02:11.123456+00:00`, with or without the
/// fraction) as a Date — one parser for the notices, the digest and the door.
public enum SocialStamp {
  public static func parse(_ text: String) -> Date? {
    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return fractional.date(from: text) ?? ISO8601DateFormatter().date(from: text)
  }
}

public extension SocialStamp {
  /// How long ago a comment was said, in the web's words (`csTalkWhen`): "Now",
  /// "12m", "2h", then the day, "Sep 20". A thread reads like a record of who
  /// said what, and an absolute clock time on every line read like a log.
  static func when(_ text: String, now: Date = Date()) -> String {
    guard let date = parse(text) else { return "" }
    let seconds = max(0, now.timeIntervalSince(date))
    if seconds < 60 { return "Now" }
    if seconds < 3600 { return "\(Int(seconds / 60))m" }
    if seconds < 86_400 { return "\(Int(seconds / 3600))h" }
    return date.formatted(.dateTime.month(.abbreviated).day())
  }
}

/// D405 · one item of `posted_rounds_social`, the read that draws a round's door
/// on Home and the board: how many comments, the newest one (so the banter shows
/// before anyone taps), and this golfer's setting. `latest` is absent from a
/// server before the migration, and the door then says the count alone.
public struct RoundSocialDoor: Sendable, Equatable {
  public struct Latest: Sendable, Equatable {
    public let id: UUID
    public let author: SocialPerson
    public let body: String
    public let createdAt: String
    public init(id: UUID, author: SocialPerson, body: String, createdAt: String) {
      self.id = id; self.author = author; self.body = body; self.createdAt = createdAt
    }
  }
  public let roundId: UUID?
  public let commentCount: Int
  public let latest: Latest?
  public let threadState: String
  /// Whether the server sends a newest comment at all: it does from D405 on, and says so
  /// with the `latest` key (null for a round with no comment). An older server never does,
  /// and a door it sent stays a count: the phone does not draw a preview its web twin would not.
  public let sendsLatest: Bool
  public init(roundId: UUID?, commentCount: Int, latest: Latest?, threadState: String = "none", sendsLatest: Bool = true) {
    self.roundId = roundId; self.commentCount = commentCount; self.latest = latest; self.threadState = threadState
    self.sendsLatest = sendsLatest
  }
  /// The door after the open thread reported a new count and newest comment
  /// (a comment sent or removed in line), without another read. The body is
  /// cut as the server cuts it.
  public func updating(count: Int, newest: SocialComment?) -> RoundSocialDoor {
    RoundSocialDoor(roundId: roundId, commentCount: count,
                    latest: sendsLatest ? newest.map { Latest(id: $0.id, author: $0.author, body: String($0.body.prefix(140)), createdAt: $0.createdAt) } : nil,
                    threadState: threadState, sendsLatest: sendsLatest)
  }
  public init(_ json: JSONValue) {
    roundId = json["round_id"]?.string.flatMap(UUID.init)
    commentCount = json["comment_count"]?.int ?? 0
    threadState = json["thread_state"]?.string ?? "none"
    sendsLatest = json["latest"] != nil
    if let l = json["latest"], let id = l["id"]?.string.flatMap(UUID.init), let author = SocialPerson(l["author"]),
       let body = l["body"]?.string, !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      latest = Latest(id: id, author: author, body: body, createdAt: l["created_at"]?.string ?? "")
    } else { latest = nil }
  }
  /// *"Blake: Did the putt on 18 drop?"* — only when there is a comment to show
  public var previewLine: String? {
    guard commentCount > 0, let latest else { return nil }
    return TalkCopy.preview(author: latest.author.name, body: latest.body)
  }
}

/// Writes use the complete request once. In particular a retry must never drop
/// the idempotency key or reply target to accommodate an older server.
public struct RoundSocialService: Sendable {
  public init() {}
  public func request(_ name: String, _ params: [String: JSONValue] = [:]) async throws -> JSONValue {
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
    case "course_home": return try await call(Rpc.course_home.self, params)
    case "course_page": return try await call(Rpc.course_page.self, params)
    case "posted_rounds_social": return try await call(Rpc.posted_rounds_social.self, params)
    default: throw RpcError(name: name, underlying: "Unknown social request.", droppedArgs: [])
    }
  }
  private func call<C: RpcCall>(_ endpoint: C.Type, _ params: [String: JSONValue]) async throws -> JSONValue where C.Returns == JSONValue {
    #if DEBUG
    if SocialBlendFixture.enabled { return try await SocialBlendFixture.shared.response(C.name, params) }
    #endif
    return try await SupabaseService.shared.callJSON(endpoint, params: .object(params))
  }
  private func write<C: RpcCall>(_ endpoint: C.Type, _ params: [String: JSONValue]) async throws where C.Returns == RpcVoid {
    #if DEBUG
    if SocialBlendFixture.enabled {
      _ = try await SocialBlendFixture.shared.response(C.name, params)
      return
    }
    #endif
    _ = try await SupabaseService.shared.callJSON(endpoint, params: .object(params))
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
    try await write(Rpc.report_content.self, [
      "p_kind": .string("comment"), "p_comment": .string(comment.uuidString), "p_reason": .string(reason)])
  }
  public func block(_ profile: UUID) async throws {
    try await write(Rpc.set_mute.self, ["p_profile": .string(profile.uuidString), "p_on": .bool(true)])
  }
}
