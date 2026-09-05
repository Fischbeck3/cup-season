// Cup Season — THE TWO NEW LINKS (D241 the person link, D253 the plan link).
//
// The only account-to-account link in the product was a SEASON's, and it
// renders only if a league has a code. A golfer with no season could not bring
// anybody in — SP-1's fourth rail, and the reason 27 of 39 prod profiles have
// no accepted buddy. D177 filed it as "a decision, not a tidy"; D241 is that
// decision, and D253 is the same mechanism one more time for a weekend.
//
// WHAT IS NEW HERE IS ONE VALUE ON ONE CHECK, TWICE. `shares.kind` gains
// 'person' and 'plan'; the landing page is a BRANCH inside `share_info`, which
// is already one of L-45's twelve anon endpoints. **The signed-out surface
// stays at twelve** — a thirteenth is declined in writing (D250).
//
// THE HALF THAT WRITES IS NOT ANONYMOUS. `redeem_share(p_token)` is granted to
// `authenticated` and revoked from `public, anon`: a signed-out page never
// learns the profile id behind a card (that id is the key to every
// authenticated read about that golfer), and the sign-in that follows
// exchanges the same token for the buddy request — and, for a plan, the seat.
// Consent stays two-sided (D80): a REQUEST, never a friendship.
//
// This file is the producer for both: the query name, the URL, the pending
// token a cold boot has to survive, and every sentence the outcome can say.
// The parsers are here rather than in a screen for the same reason
// `JoinIntent.code(from:)` and `ClaimIntent.token(from:)` are: a link's shape
// is one fact, and `RouteMapTests` walks it.

import Foundation

/// The two link kinds, and everything that is different between them.
public enum ShareIntent: String, Sendable, CaseIterable {
  /// `/?p=TOKEN` — a golfer's own card. It mints a buddy request on sign-in.
  case person
  /// `/?plan=TOKEN` — a weekend. It takes a seat AND mints a buddy request.
  case plan

  /// The query key the AASA claims. Deliberately short for the person link:
  /// it is the one a golfer types into a text message beside their name.
  public var query: String { self == .person ? "p" : "plan" }

  /// Where the pending token waits between the tap and the sign-in. Same
  /// shape as `cs_code` and `cs_claim`, so a cold boot recovers it the same
  /// way and the web reads the same names.
  public var storageKey: String { self == .person ? "cs_person" : "cs_plan" }

  /// `shares.kind` — the value the CHECK gained.
  public var shareKind: String { rawValue }

  /// The growth kind logged when the link is opened (`log_growth_event`, one
  /// of the twelve; a made-up token logs nothing and returns the same void).
  public var growthKind: String { rawValue }

  // MARK: - The link itself

  /// The URL that goes in a text message. The host matches the AASA's, and
  /// the token is lower-cased because that is the form `share_info` compares
  /// and the form the web's `URLSearchParams` will hand back.
  public func url(_ token: UUID) -> URL {
    URL(string: "https://cupseason.app/?\(query)=\(token.uuidString.lowercased())")!
  }

  /// Nil for a URL that is not this kind of link. An empty value is not a
  /// token — a bare `/?p=` is somebody's truncated paste, not a card.
  public func token(from url: URL) -> UUID? {
    guard let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
          let v = items.first(where: { $0.name == query })?.value else { return nil }
    return UUID(uuidString: v.trimmingCharacters(in: .whitespacesAndNewlines))
  }

  /// The first of the two this URL is. Checked in declaration order, and the
  /// two keys cannot collide.
  public static func of(_ url: URL) -> (kind: ShareIntent, token: UUID)? {
    for k in allCases { if let t = k.token(from: url) { return (k, t) } }
    return nil
  }

  // MARK: - The token that has to survive a cold boot

  public func store(_ token: UUID, defaults: UserDefaults = .standard) {
    defaults.set(token.uuidString.lowercased(), forKey: storageKey)
  }
  public func pending(defaults: UserDefaults = .standard) -> UUID? {
    defaults.string(forKey: storageKey).flatMap { UUID(uuidString: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
  }
  public func clear(defaults: UserDefaults = .standard) { defaults.removeObject(forKey: storageKey) }

  // MARK: - The share sheet's own copy

  /// What the golfer sends with the link. Two sentences: what it is, and what
  /// happens if they tap it. Never "check out my profile" — the product's
  /// voice does not sell itself to somebody's friend (L-33).
  public func message(name: String?, course: String? = nil, day: String? = nil) -> String {
    switch self {
    case .person:
      let who = (name?.trimmingCharacters(in: .whitespaces)).flatMap { $0.isEmpty ? nil : $0 }
      return (who.map { "\($0) wants you in their golf." } ?? "Come and play.")
        + " Cup Season keeps score for a group of friends — every round, against everyone’s own number."
    case .plan:
      let where_ = (course?.trimmingCharacters(in: .whitespaces)).flatMap { $0.isEmpty ? nil : $0 }
      let when = (day?.trimmingCharacters(in: .whitespaces)).flatMap { $0.isEmpty ? nil : $0 }
      switch (where_, when) {
      case let (w?, d?): return "Golf at \(w), \(d). Tap to take the seat."
      case let (w?, nil): return "Golf at \(w). Tap to take the seat."
      case let (nil, d?): return "Golf on \(d). Tap to take the seat."
      default:           return "There’s a round on. Tap to take the seat."
      }
    }
  }
}

/// What `redeem_share` did, as a value. The RPC returns `{kind, result, seat}`
/// and every dead path returns `{kind: null}` — a made-up token, a revoked
/// one, a deleted golfer, all the same shape (D57), so nothing here can be
/// read as "that token exists".
public struct ShareRedeem: Sendable, Equatable {
  public enum Outcome: Sendable, Equatable {
    /// The token resolved to nothing at all. Say so plainly; never "error".
    case dead
    /// A buddy request went out.
    case requested
    /// They had already asked you — mutual intent, instant buddies
    /// (`friend_request` answers 'friend').
    case buddies
    /// Your own link, on your own phone.
    case mine
    /// A seat on a plan, plus whatever the request did.
    case seated(alreadyIn: Bool, request: String?)
    /// The plan's day has been and gone.
    case planPast
  }

  public let kind: ShareIntent?
  public let outcome: Outcome
  public init(kind: ShareIntent?, outcome: Outcome) { self.kind = kind; self.outcome = outcome }

  /// Parse the RPC's payload. An unknown `result` or an unknown `seat` is not
  /// a failure — the server may ship a new word before the client knows it —
  /// so it lands on the nearest true thing rather than on nothing.
  public static func parse(_ v: JSONValue?) -> ShareRedeem {
    guard let v, !v.isNull else { return ShareRedeem(kind: nil, outcome: .dead) }
    guard let kindStr = v["kind"]?.string, let kind = ShareIntent(rawValue: kindStr) else {
      return ShareRedeem(kind: nil, outcome: .dead)
    }
    let result = v["result"]?.string
    let seat = v["seat"]?.string

    if kind == .plan {
      switch seat {
      case "host":    return ShareRedeem(kind: .plan, outcome: .mine)
      case "past":    return ShareRedeem(kind: .plan, outcome: .planPast)
      case "already": return ShareRedeem(kind: .plan, outcome: .seated(alreadyIn: true, request: result))
      case "in":      return ShareRedeem(kind: .plan, outcome: .seated(alreadyIn: false, request: result))
      default:        return ShareRedeem(kind: .plan, outcome: .seated(alreadyIn: true, request: result))
      }
    }
    switch result {
    case "self":      return ShareRedeem(kind: .person, outcome: .mine)
    case "friend":    return ShareRedeem(kind: .person, outcome: .buddies)
    case "requested": return ShareRedeem(kind: .person, outcome: .requested)
    default:          return ShareRedeem(kind: .person, outcome: .requested)
    }
  }

  /// The one line the golfer sees when they land. L-44: it says what actually
  /// happened and nothing that did not — a request is never called a friend,
  /// and a seat is never called a confirmation from the host.
  public var line: String? {
    switch outcome {
    case .dead:      return "That link has expired. Whoever sent it can share a fresh one."
    case .mine:      return nil                       // your own link — nothing to say
    case .requested: return "Asked to join their crew. They’ll get the nudge."
    case .buddies:   return "You’re in each other’s crew now."
    case .planPast:  return "That round has already been played."
    case .seated(let already, let request):
      let seat = already ? "You’re already down for that round." : "You’re in for that round."
      switch request {
      case "requested": return seat + " The host has your buddy request."
      case "friend":    return seat
      default:          return seat
      }
    }
  }
}
