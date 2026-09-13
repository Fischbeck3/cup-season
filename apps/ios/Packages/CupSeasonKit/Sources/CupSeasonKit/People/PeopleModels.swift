// Cup Season — buddies, as shapes (audit 05 §2F, §8; index.html 13150–13210).
//
// The product noun is "buddies" (D80). `is_friend` / `my_friends` stay in the
// schema; nothing here puts the word "friend" on screen.

import Foundation

/// `search_golfers.rel` / what `friend_request` returns.
public enum Rel: String, Sendable, Equatable {
  case none, requested, incoming, friend

  public init(_ raw: String?) { self = Rel(rawValue: raw ?? "") ?? .none }

  /// `psFriendTag` (13156): the tag a row wears when there is no action left.
  public var tag: String? {
    switch self {
    case .friend: "Buddies"
    case .requested: "Requested"
    case .incoming: "Wants to add you"
    case .none: nil
    }
  }

  /// The action on a search row: Add (none) · Accept (incoming) · a tag otherwise.
  public var action: String? {
    switch self {
    case .none: "Add"
    case .incoming: "Accept"
    default: nil
    }
  }
}

/// One golfer row — the union of a `search_golfers` hit and a `my_friends` row
/// (`psRow` draws both, 13151).
public struct Person: Identifiable, Sendable, Hashable {
  public let id: UUID
  public let displayName: String?
  public let handle: String?
  public let city: String?
  public let marker: String?
  public var rel: Rel
  public let friendshipId: UUID?
  public let status: String?
  public let incoming: Bool

  public init(id: UUID, displayName: String?, handle: String?, city: String? = nil, marker: String?, rel: Rel = .none,
              friendshipId: UUID? = nil, status: String? = nil, incoming: Bool = false) {
    self.id = id; self.displayName = displayName; self.handle = handle; self.city = city; self.marker = marker
    self.rel = rel; self.friendshipId = friendshipId; self.status = status; self.incoming = incoming
  }

  public init?(_ r: Rpc.search_golfers.Row) {
    guard let id = r.profile_id else { return nil }
    self.init(id: id, displayName: r.display_name, handle: r.handle, city: r.city, marker: r.marker, rel: Rel(r.rel))
  }

  public init?(_ f: Rpc.my_friends.Row) {
    guard let id = f.profile_id else { return nil }
    let rel: Rel = f.status == "accepted" ? .friend : (f.incoming == true ? .incoming : .requested)
    self.init(id: id, displayName: f.display_name, handle: f.handle, city: f.city, marker: f.marker, rel: rel,
              friendshipId: f.friendship_id, status: f.status, incoming: f.incoming ?? false)
  }

  /// "Name" — the web prints '—' when a name is missing.
  public var name: String { displayName ?? "—" }
  /// "@handle · City" (13153).
  public var subline: String {
    let h = "@\(handle ?? "?")"
    return city.map { "\(h) · \($0)" } ?? h
  }
}

/// `renderCrewPeople`'s three lists (13173–13176).
public struct BuddyLists: Sendable, Equatable {
  public var requests: [Person]   // pending, incoming
  public var requested: [Person]  // pending, outgoing
  public var buddies: [Person]    // accepted

  public init(requests: [Person] = [], requested: [Person] = [], buddies: [Person] = []) {
    self.requests = requests; self.requested = requested; self.buddies = buddies
  }

  public static func partition(_ rows: [Rpc.my_friends.Row]) -> BuddyLists {
    var out = BuddyLists()
    for r in rows {
      guard let p = Person(r) else { continue }
      if r.status == "pending" { if r.incoming == true { out.requests.append(p) } else { out.requested.append(p) } }
      else if r.status == "accepted" { out.buddies.append(p) }
    }
    return out
  }
}

/// `profiles.discoverable` — "Findable by" (13541–13545).
public enum Discoverable: String, CaseIterable, Sendable {
  case everyone, friends, nobody

  public var label: String {
    switch self {
    case .everyone: "All"
    case .friends: "Buddies"
    case .nobody: "Nobody"
    }
  }
}

/// `my_invites` row, with the copy the banner prints (12596–12622).
public struct Invite: Identifiable, Sendable, Equatable {
  public let id: UUID
  public let kind: String          // 'league' | 'event'
  public let containerId: UUID?
  public let containerName: String
  public let inviter: String
  public let startsOn: String?
  /// D356 · the event's own kind (`ryder` | `major` …); nil for a league, and
  /// nil on a server that does not say — which is a different fact from
  /// "Ryder", and is never guessed into one.
  public let eventKind: String?
  /// D356 · the event's stake in dollars, as stored; nil when not said.
  public let buyIn: Double?

  public init(id: UUID, kind: String, containerId: UUID?, containerName: String, inviter: String, startsOn: String?,
              eventKind: String? = nil, buyIn: Double? = nil) {
    self.id = id; self.kind = kind; self.containerId = containerId; self.containerName = containerName; self.inviter = inviter; self.startsOn = startsOn
    self.eventKind = eventKind; self.buyIn = buyIn
  }

  public init?(_ r: Rpc.my_invites.Row) {
    guard let id = r.id else { return nil }
    self.init(id: id, kind: r.kind ?? "league", containerId: r.container_id, containerName: r.container_name ?? "",
              inviter: r.inviter ?? "a golfer", startsOn: r.starts_on)
  }

  /// D356 · the extended row (20261031090000), hand-declared until the
  /// contract refresh. Every new field optional: an older server says neither.
  public init?(_ r: InviteRow) {
    guard let id = r.id else { return nil }
    self.init(id: id, kind: r.kind ?? "league", containerId: r.container_id, containerName: r.container_name ?? "",
              inviter: r.inviter ?? "a golfer", startsOn: r.starts_on, eventKind: r.event_kind, buyIn: r.buy_in)
  }

  public var isLeague: Bool { kind == "league" }
  public var isMajor: Bool { eventKind == "major" }
  /// "League invite" / "Ryder invite" / "Major invite" — and, for one the
  /// server has not named, just "Invite" rather than a guess.
  public var title: String {
    if isLeague { return "League invite" }
    switch eventKind {
    case "major": return "Major invite"
    case "ryder": return "Ryder invite"
    default: return "Invite"
    }
  }
  /// "from X · first tee YYYY-MM-DD"
  public var subline: String {
    var s = "from \(inviter)"
    if !isLeague, let d = startsOn { s += " · first tee \(d)" }
    return s
  }
  /// What it IS, in one sentence. nil when the server has not said (or has
  /// said a kind this build cannot describe) — and nil is a shut door.
  public var eventLine: String? {
    switch eventKind {
    // D357 · "one week" was never true: a Major's window is two to four days
    // (`create_major`'s clamp, and the setup sheet's only choices). The
    // invitation says what the payload can establish and no more.
    case "major": return "A Major — a short window, one card, the best round takes it."
    case "ryder": return "A Ryder — two teams, one clash each week."
    default: return nil
    }
  }
  /// The stake, above $0 only (L-10). nil when the server has not said.
  public var stakeLine: String? {
    guard let b = buyIn else { return nil }
    return b > 0 ? "$\(Int(b.rounded())) each." : "No buy-in."
  }
  /// D356 · the terms an EVENT invitation can show before the tap: what it
  /// is, when, and what it costs. Empty when the server has not said what the
  /// event is — and an empty list is a door that stays shut (fail-closed),
  /// never a one-tap accept.
  public var eventTerms: [String] {
    guard let line = eventLine else { return [] }
    var out = [line]
    if let d = startsOn { out.append("First tee \(LeagueDates.dowMonDay(d)).") }
    if let s = stakeLine { out.append(s) }
    if let b = buyIn, b > 0 { out.append(MoneyCopy.ledger) }
    return out
  }
  /// The Details sheet line.
  public var detail: String {
    var s = (isLeague ? "A season-long league." : (eventLine ?? "This server hasn’t said whether it’s a Ryder or a Major yet.")) + " Invited by \(inviter)"
    if let d = startsOn { s += ". First tee \(d)." }
    return s
  }
}

/// D356 · `my_invites` with `event_kind` and `buy_in` (20261031090000).
public struct InviteRow: Decodable, Sendable {
  public let id: UUID?
  public let kind: String?
  public let container_id: UUID?
  public let container_name: String?
  public let inviter: String?
  public let starts_on: String?
  public let created_at: Date?
  public let event_kind: String?
  public let buy_in: Double?
  public init(id: UUID?, kind: String?, container_id: UUID?, container_name: String?, inviter: String?, starts_on: String?,
              created_at: Date? = nil, event_kind: String? = nil, buy_in: Double? = nil) {
    self.id = id; self.kind = kind; self.container_id = container_id; self.container_name = container_name
    self.inviter = inviter; self.starts_on = starts_on; self.created_at = created_at; self.event_kind = event_kind; self.buy_in = buy_in
  }
}
struct MyInvitesCall: RpcCall {
  static let name = "my_invites"
  static let optionalArgs: [String] = []
  typealias Returns = [InviteRow]
}

/// `humanError` (index.html 4084) — the transport-failure phrasings, verbatim.
public enum HumanError {
  public static func text(_ error: Error, prefix: String? = nil) -> String {
    let raw = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
    let m = raw.lowercased()
    let msg: String
    if m.range(of: "failed to fetch|networkerror|network request|load failed|timeout|offline|could not connect", options: .regularExpression) != nil {
      msg = "Connection hiccup — check your signal and try again."
    } else if m.range(of: "jwt|not authenticated|auth session|invalid.*token|permission denied|row-level|not logged in", options: .regularExpression) != nil {
      msg = "Please sign in again."
    } else if m.range(of: "schema cache|does not exist|could not find the|no function matches|column .* does not", options: .regularExpression) != nil {
      msg = "Just updated — give it a second and try again."
    } else if m.range(of: "can rsvp to this round|only the host and tagged", options: .regularExpression) != nil {
      msg = "Only the host and tagged golfers can RSVP to this round."
    } else if m.range(of: "duplicate key|already exists|unique constraint", options: .regularExpression) != nil {
      msg = "That already exists."
    } else if m.range(of: "violates|constraint|not-null|null value|invalid input", options: .regularExpression) != nil {
      msg = "That didn't go through — please try again."
    } else if let ours = BoardText.ourSentence(raw) {
      // D161/D112 · our own raise-exception lines are written for golfers —
      // pass them through verbatim, exactly as the web's allowlist does.
      // D297 class 5: the allowlist and the shape gate are `BoardText`'s,
      // one gate for the three mappers (ruling row 60).
      msg = ours
    } else {
      msg = "Something went wrong — please try again."
    }
    return prefix.map { "\($0) \(msg)" } ?? msg
  }
}
