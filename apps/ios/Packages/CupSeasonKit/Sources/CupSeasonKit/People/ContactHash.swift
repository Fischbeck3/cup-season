// Cup Season — A HASH IS NOT A CONTACT (D251 / R-G; C-11).
//
// This file is the CLIENT'S HALF of contacts matching, and the whole of what
// the client is trusted with: **normalisation, and a plain SHA-256.**
//
// THE SALT IS SERVER-SIDE AND NEVER REACHES HERE. What the database stores is
// `sha256(salt || sha256(normalised))`, and the salt lives in `contact_pepper`,
// a table with no grant to anybody. So nothing in this file — and nothing a
// stolen phone can compute — produces a value the column holds. That is the
// property that makes the digest safe to send, and it is asserted two ways:
// `ContactHashTests` pins `digest("abc")` against the published SHA-256 test
// vector, and the migration's own self-check pins the SAME vector server-side.
// A salt smuggled into either half breaks both at once.
//
// WHAT TRAVELS. `sha256(normalised)` in lower-case hex. Never an email, never a
// phone number, never a name. That is what makes the consent sentence — *"We
// send hashes, never your contacts"* — literally true of the wire rather than
// a way of describing it.
//
// NORMALISATION IS THE CONTRACT. `cs_normalise_email` / `cs_normalise_phone`
// in `20260928100000_a_hash_is_not_a_contact.sql` are the same rules, and the
// migration's self-check runs the same cases these tests do. If they ever
// disagree, a golfer's own email stops matching their own row and NOTHING
// visible breaks — which is exactly why the cases are pinned on both sides.

import Foundation
import CryptoKit

public enum ContactHash {

  // MARK: normalisation

  /// Trim, lower-case. No provider-specific cleverness (no Gmail dot-stripping,
  /// no plus-tag removal): a guess about somebody's mail provider is a guess
  /// about their identity, and a guess that silently widens a match is worse
  /// than one that narrows it.
  public static func normaliseEmail(_ raw: String) -> String? {
    let s = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !s.isEmpty, s.contains("@"), !s.hasPrefix("@"), !s.hasSuffix("@") else { return nil }
    return s
  }

  /// Digits only; a bare ten-digit number is North American and takes a 1; the
  /// result is "+" and digits. Fewer than nine digits is a local fragment, not
  /// a number anybody can be reached on, and it normalises to nothing rather
  /// than to a short string thousands of contact books would collide on.
  public static func normalisePhone(_ raw: String) -> String? {
    let d = raw.filter(\.isNumber)
    guard d.count >= 9 else { return nil }
    return d.count == 10 ? "+1\(d)" : "+\(d)"
  }

  // MARK: the digest

  /// Plain SHA-256 of the normalised value, lower-case hex. **No salt.** The
  /// server applies the pepper; this cannot.
  public static func digest(_ normalised: String) -> String {
    SHA256.hash(data: Data(normalised.utf8)).map { String(format: "%02x", $0) }.joined()
  }

  /// Everything a contact card can offer, normalised and hashed, de-duplicated
  /// and capped. The cap is the RPC's own (`ord <= 1000`), stated here so the
  /// phone does not send what the server will silently drop.
  public static let maxHashes = 1000

  public static func hashes(emails: [String], phones: [String]) -> [String] {
    var seen = Set<String>()
    var out: [String] = []
    for n in emails.compactMap(normaliseEmail) + phones.compactMap(normalisePhone) {
      let h = digest(n)
      if seen.insert(h).inserted { out.append(h) }
      if out.count >= maxHashes { break }
    }
    return out
  }
}

// MARK: - the RPC

/// C-11 · `match_contacts(p_hashes text[])` — returns ONLY golfers who match,
/// on `nearby_resolve`'s envelope. Hand-declared: the function is unpushed, so
/// it is not in `contract.psv` and `Rpc.swift` cannot carry it.
public struct MatchContactsCall: RpcCall {
  public static let name = "match_contacts"
  /// Nothing is droppable — a skew retry that sheds the hashes would ask the
  /// server to match nothing and get a confident empty answer.
  public static let optionalArgs: [String] = []
  public typealias Returns = [MatchedGolfer]
  public var p_hashes: [String]
  public init(p_hashes: [String]) { self.p_hashes = p_hashes }
}

/// The row `match_contacts` returns — `nearby_resolve`'s shape, so the two
/// consent-envelope reads decode the same way. Every field but the id is
/// optional: a golfer with no city renders no city, never "—".
public struct MatchedGolfer: Decodable, Sendable, Equatable {
  public let id: UUID
  public let handle: String?
  public let display_name: String?
  public let city: String?
  public let home_course: String?
  public let marker: String?
  public let index_current: Double?
  /// `friend` · `league` · `contact` — the relation the caller ALREADY has.
  public let rel: String?

  public var person: Person {
    Person(id: id, displayName: display_name, handle: handle, city: city, marker: marker,
           rel: rel == "friend" ? .friend : .none)
  }
}

public struct ContactMatchService: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  /// The THREE-VALUED answer every unpushed read on this build uses (wave 5's
  /// lesson): matched, matched-nobody, and "the function is not deployed yet",
  /// which is not a failure and must not be narrated as one.
  public enum Result: Sendable, Equatable {
    case matched([MatchedGolfer])
    case none
    case notYet
    case failed(String)
  }

  public func match(_ hashes: [String]) async throws -> Result {
    guard !hashes.isEmpty else { return .none }
    do {
      let people = try await svc.call(MatchContactsCall(p_hashes: hashes))
      return people.isEmpty ? .none : .matched(people)
    } catch {
      if PostService.fallbackFires(on: error) { return .notYet }
      return .failed(AuthRules.human(error, fallback: "Couldn't check your contacts."))
    }
  }

  /// The sentence each outcome renders. One place, so the phone and the web
  /// cannot describe the same answer two ways (D234).
  public static func line(_ r: Result) -> String? {
    switch r {
    case .matched(let p): return OnboardingCopy.contactsFound(p.count)
    case .none:           return OnboardingCopy.contactsNone
    case .notYet:         return OnboardingCopy.contactsNotYet
    case .failed(let m):  return m
    }
  }
}
