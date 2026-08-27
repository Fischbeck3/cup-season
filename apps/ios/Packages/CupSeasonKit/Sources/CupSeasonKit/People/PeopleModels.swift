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

  public init(id: UUID, kind: String, containerId: UUID?, containerName: String, inviter: String, startsOn: String?) {
    self.id = id; self.kind = kind; self.containerId = containerId; self.containerName = containerName; self.inviter = inviter; self.startsOn = startsOn
  }

  public init?(_ r: Rpc.my_invites.Row) {
    guard let id = r.id else { return nil }
    self.init(id: id, kind: r.kind ?? "league", containerId: r.container_id, containerName: r.container_name ?? "",
              inviter: r.inviter ?? "a golfer", startsOn: r.starts_on)
  }

  public var isLeague: Bool { kind == "league" }
  /// "League invite" / "Ryder invite"
  public var title: String { isLeague ? "League invite" : "Ryder invite" }
  /// "from X · first tee YYYY-MM-DD"
  public var subline: String {
    var s = "from \(inviter)"
    if !isLeague, let d = startsOn { s += " · first tee \(d)" }
    return s
  }
  /// The Details sheet line.
  public var detail: String {
    var s = (isLeague ? "A season-long league." : "A Ryder event — two teams, vs-index duels.") + " Invited by \(inviter)"
    if let d = startsOn { s += ". First tee \(d)." }
    return s
  }
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
      msg = "Only the host and the players they tagged can RSVP."
    } else if m.range(of: "duplicate key|already exists|unique constraint", options: .regularExpression) != nil {
      msg = "That already exists."
    } else if m.range(of: "violates|constraint|not-null|null value|invalid input", options: .regularExpression) != nil {
      msg = "That didn't go through — please try again."
    } else {
      msg = "Something went wrong — please try again."
    }
    return prefix.map { "\($0) \(msg)" } ?? msg
  }
}
