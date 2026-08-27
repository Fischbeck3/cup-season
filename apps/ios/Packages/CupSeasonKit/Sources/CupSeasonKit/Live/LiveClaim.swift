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
  }
  public let face: Face

  public static let deadLine = "That scorecard link has expired or was already claimed. Whoever sent it can share a fresh one from the round."

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

  /// Both claim sources: tee-sheet guests, then scan partners.
  public static func load(token: UUID, repo: LiveRepository = LiveRepository()) async -> ClaimDoor {
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
    case failed(toast: String)
    case already(toast: String)
    case posted(gross: Int?, toast: String)
    case incomplete(toast: String)

    public var toast: String? {
      switch self {
      case .nothing: nil
      case .stillLive(let t), .failed(let t), .already(let t), .posted(_, let t), .incomplete(let t): t
      }
    }
  }

  public static let stillLiveToast = "They’re still out there — your card lands here when the round finishes"

  /// `livePencilToken`: the token the guest pencil is holding right now, if any.
  public static func consume(livePencilToken: UUID? = nil, repo: LiveRepository = LiveRepository(), defaults: UserDefaults = .standard) async -> Outcome {
    guard let tok = ClaimIntent.pending(defaults: defaults) else { return .nothing }
    if let livePencilToken, livePencilToken == tok { return .nothing }
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
    if data?["already"]?.bool == true { return .already(toast: "That round is already on your card") }
    if data?["posted"]?.bool == true {
      let g = data?["gross"]?.int
      return .posted(gross: g, toast: "Claimed ✓ — your \(g.map(String.init) ?? "round") is on your card")
    }
    return .incomplete(toast: "Round claimed — the card was incomplete, so nothing posted")
  }
}
