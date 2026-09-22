// Cup Season — the guest claim funnel (spec §13.3; index.html 17583–17632,
// 17664–17729; audit 04 §2.4, §6.2).
//
// `/?claim=<token>`: the token is stored, the round is either a live PENCIL
// (the guest scores from their own phone, no account) or a waiting CARD at the
// door, and it attaches after auth + the golfer card. Token-is-identity; the
// `member_id is null` guard on the guest RPCs is server-side and stays there.

import Foundation

public enum ClaimIntent {
  /// The web's `localStorage.cs_claim`; the app writes it on a Universal Link.
  public static let key = "cs_claim"

  public static func store(_ token: String, defaults: UserDefaults = .standard) {
    defaults.set(token.trimmingCharacters(in: .whitespacesAndNewlines), forKey: key)
  }
  public static func pending(defaults: UserDefaults = .standard) -> UUID? {
    defaults.string(forKey: key).flatMap { UUID(uuidString: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
  }
  public static func clear(defaults: UserDefaults = .standard) { defaults.removeObject(forKey: key) }

  /// `/?claim=TOKEN` (17583).
  public static func token(from url: URL) -> String? {
    guard let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
          let v = items.first(where: { $0.name == "claim" })?.value, !v.isEmpty else { return nil }
    return v.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// The link a guest gets (9330, 9277).
  public static func url(_ token: UUID) -> URL {
    URL(string: "https://cupseason.app/?claim=\(token.uuidString.lowercased())")!
  }
}

/// The door card for a finished claim (17700–17727).
public struct ClaimDoor: Sendable, Equatable {
  public enum Face: Sendable, Equatable {
    /// "NAME — 84 at COURSE, Sat Jul 25. Enter your email to keep it."
    case waiting(String)
    /// already claimed — the token is dropped silently
    case claimed
    /// dead / garbage token — said plainly, token dropped
    case dead(String)
    /// D374 · the round was never finished: no card was ever minted, the token is dropped
    case unfinished(String)
    /// D374 · the round has not teed off: the pencil is kept, the card lands when it finishes
    case notStarted(String)
  }
  public let face: Face

  public static let deadLine = "That scorecard link has expired or was already claimed. Whoever sent it can share a fresh one from the round."
  /// D374 · twins of the web's `CS_CLAIM_UNFINISHED` / `CS_CLAIM_NOT_STARTED`,
  /// verbatim (one producer per client, D297).
  public static let unfinishedLine = "This round was never finished, so there’s no card to keep. Whoever ran it can tee off again and send your link from the new round."
  public static let notStartedLine = "That round hasn’t teed off yet — your card lands here when it finishes."

  /// D374 · what `guest_live_state` says about the round behind the token,
  /// read BEFORE the door is asked for a card. `abandoned` → there is no card
  /// and never will be (the caller drops the token); `setup` → not yet (the
  /// token stays). Anything else — live, final, or a token that is not a guest
  /// seat (the RPC raises; the caller passes nil) — falls through to the door
  /// as before. Pure, so it is testable without a network.
  public static func gate(_ state: JSONValue?) -> Face? {
    switch state?["round"]?["status"]?.string {
    case "abandoned": return .unfinished(unfinishedLine)
    case "setup": return .notStarted(notStartedLine)
    default: return nil
    }
  }

  /// The first sentence a brand-new golfer ever reads from us (D77).
  public static func line(_ data: JSONValue, calendar: Calendar = .current) -> String {
    let name = data["guest_name"]?.string ?? "Your card"
    let gross = data["gross"]?.int
    let course = data["course_label"]?.string ?? "the course"
    var when = ""
    if let iso = data["played_on"]?.string, let d = CSDate.local(iso, calendar: calendar) {
      let f = DateFormatter()
      f.calendar = calendar
      f.setLocalizedDateFormatFromTemplate("EEE MMM d")
      when = ", " + f.string(from: d)
    }
    return "\(name) — \(gross.map { "\($0) at " } ?? "")\(course)\(when). Enter your email to keep it."
  }

  /// Both claim sources: tee-sheet guests, then scan partners. `state` is the
  /// `guest_live_state` answer when the host already holds it (the pencil
  /// screen reads it first); otherwise it is read here.
  public static func load(token: UUID, state: JSONValue? = nil, repo: LiveRepository = LiveRepository()) async -> ClaimDoor {
    // D374 · the first sentence a stranger reads from us must be true: a round
    // nobody finished mints no card, and the door says so instead of "expired".
    // `??` takes an autoclosure, and an autoclosure cannot await — so the
    // conditional read is spelled out (Codex's build-for-testing, 2026-09-22).
    let seen: JSONValue?
    if let state { seen = state } else { seen = try? await repo.guestState(token) }
    if let face = gate(seen) {
      if case .unfinished = face { ClaimIntent.clear() }
      return ClaimDoor(face: face)
    }
    var data = await repo.claimInfo(token)
    if data == nil { data = await repo.scanClaimInfo(token) }
    guard let data else { ClaimIntent.clear(); return ClaimDoor(face: .dead(deadLine)) }
    if data["claimed"]?.bool == true { ClaimIntent.clear(); return ClaimDoor(face: .claimed) }
    return ClaimDoor(face: .waiting(line(data)))
  }
}

/// `claimPendingRound` (17588): after auth + golfer card.
public enum ClaimFlow {
  public enum Outcome: Sendable, Equatable {
    /// nothing pending, or the pencil is holding that very token (D87)
    case nothing
    /// D86: a STILL-LIVE round is an early claim, not a failed one — the token stays
    case stillLive(toast: String)
    /// D374 · never finished — no card, the token dropped
    case unfinished(toast: String)
    /// D374 · not teed off yet — the token stays
    case notStarted(toast: String)
    case failed(toast: String)
    case already(toast: String)
    case posted(gross: Int?, toast: String)
    case incomplete(toast: String)

    public var toast: String? {
      switch self {
      case .nothing: nil
      case .stillLive(let t), .unfinished(let t), .notStarted(let t), .failed(let t), .already(let t), .posted(_, let t), .incomplete(let t): t
      }
    }
  }

  public static let stillLiveToast = "They’re still out there — your card lands here when the round finishes"

  /// D374 · the read before the claim, pure: what the round's state means for a
  /// signed-in claimer. Mirrors the web's `claimPendingRound`, which asks
  /// `guest_live_state` before `claim_round` instead of matching the "still
  /// live" raise and telling a golfer forever that the group is out there.
  public static func gate(_ state: JSONValue?) -> Outcome? {
    switch ClaimDoor.gate(state) {
    case .unfinished(let line)?: return .unfinished(toast: line)
    case .notStarted(let line)?: return .notStarted(toast: line)
    default: return nil
    }
  }

  /// `livePencilToken`: the token the guest pencil is holding right now, if any.
  public static func consume(livePencilToken: UUID? = nil, repo: LiveRepository = LiveRepository(), defaults: UserDefaults = .standard) async -> Outcome {
    guard let tok = ClaimIntent.pending(defaults: defaults) else { return .nothing }
    if let livePencilToken, livePencilToken == tok { return .nothing }
    // D374 · ask what the round is before claiming it. An abandoned round mints
    // no card: say so once and drop the token. A round still in setup keeps the
    // token and says when. A token that is not a guest seat raises here and
    // falls through to the claim as before.
    if let early = gate(try? await repo.guestState(tok)) {
      if case .unfinished = early { ClaimIntent.clear(defaults: defaults) }
      return early
    }
    var data: JSONValue?
    var firstErr: Error?
    do { data = try await repo.claimRound(tok) } catch {
      firstErr = error
      do { data = try await repo.claimScanRound(tok) } catch {
        let msg = ((firstErr as? RpcError)?.underlying ?? (error as? RpcError)?.underlying ?? error.localizedDescription)
        if msg.range(of: "still live|not live", options: [.regularExpression, .caseInsensitive]) != nil {
          return .stillLive(toast: stillLiveToast)
        }
        ClaimIntent.clear(defaults: defaults)
        return .failed(toast: HumanError.text(firstErr ?? error, prefix: "Claim failed."))
      }
    }
    ClaimIntent.clear(defaults: defaults)
    if data?["already"]?.bool == true { return .already(toast: "That round is already in your rounds") }
    if data?["posted"]?.bool == true {
      let g = data?["gross"]?.int
      return .posted(gross: g, toast: "Claimed ✓ — your \(g.map(String.init) ?? "round") is in your rounds")
    }
    return .incomplete(toast: "Round claimed — the card was incomplete, so nothing posted")
  }
}
