// Cup Season — the one writer into `client_events` (IOS-024, the reliability
// floor). The web's `qaEvent` (index.html 6100) is a fire-and-forget insert
// whose every failure is swallowed, because a breadcrumb must never break a
// post; this is the same rule, in one place, so no service grows its own copy
// (PostService and WizardService each had one before this file).
//
// Row shape, matched to the web so the founder's desk reads phone rows like
// web rows: `{event, props}` — `profile_id` defaults to auth.uid() server-side
// and the insert is RLS'd to `authenticated` (`ce_insert_own`). A signed-out
// phone is therefore blind here, exactly as the web is; that gap is recorded
// in CLAUDE.md and left open on purpose.
//
// Never PII: no emails, no names, no handles ride in props. Crash rows carry a
// four-frame stack (the ghost lesson — a record with no origin cannot be
// chased) as `Binary+0xoffset`, which names code, never a person.

import Foundation
import Supabase

public enum CSTelemetry {
  /// The web's error rows are `client_error` with `{kind, msg, stack, step}`;
  /// the phone's crash and hang rows use the same event name.
  public static let clientError = "client_error"

  /// The five product events (IOS-024 §2). Props are `{build, league_id?}`.
  public enum Product: String, Sendable {
    case signedIn = "signed_in"
    case cardSet = "card_set"
    case leagueCreated = "league_created"
    case leagueLocked = "league_locked"
    case roundPosted = "round_posted"
  }

  /// `CFBundleVersion` as a number, 0 when unstamped (tests, previews).
  public static let build: Int = Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "") ?? 0

  struct Row: Encodable { let event: String; let props: JSONValue }

  /// Fire-and-forget. Never throws, never blocks the caller, and a burst of
  /// the same name+props inside two seconds writes one row.
  public static func event(_ name: String, _ props: [String: JSONValue] = [:]) {
    let key = TelemetryDedupe.key(name, props)
    let row = Row(event: name, props: .object(props))
    Task.detached(priority: .utility) {
      guard await dedupe.admit(key) else { return }
      _ = try? await SupabaseService.shared.client.from("client_events").insert(row).execute()
    }
  }

  /// One of the five, with the build stamped on — the only props they carry.
  public static func product(_ p: Product, leagueId: UUID? = nil) {
    var props: [String: JSONValue] = ["build": .number(Double(build))]
    if let leagueId { props["league_id"] = .string(leagueId.uuidString.lowercased()) }
    event(p.rawValue, props)
  }

  private static let dedupe = TelemetryDedupeActor()
}

// MARK: - the dedupe window

/// Pure: the two-second window, as a value so it can be tested without a clock.
public struct TelemetryDedupe: Sendable {
  public static let window: TimeInterval = 2

  private var lastSent: [String: TimeInterval] = [:]
  public init() {}

  /// Canonical `name` + props, key-sorted, so `[a:1, b:2]` and `[b:2, a:1]`
  /// are the same burst.
  public static func key(_ name: String, _ props: [String: JSONValue]) -> String {
    let enc = JSONEncoder()
    enc.outputFormatting = [.sortedKeys]
    let body = (try? enc.encode(JSONValue.object(props))).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    return name + "|" + body
  }

  /// true = send it (and remember it); false = a duplicate inside the window.
  public mutating func admit(_ key: String, at now: TimeInterval) -> Bool {
    if let t = lastSent[key], now - t < Self.window { return false }
    lastSent[key] = now
    if lastSent.count > 64 { lastSent = lastSent.filter { now - $0.value < Self.window } }
    return true
  }
}

private actor TelemetryDedupeActor {
  private var window = TelemetryDedupe()
  func admit(_ key: String) -> Bool { window.admit(key, at: Date().timeIntervalSince1970) }
}

// MARK: - the crash stack (pure — the app hands over MXCallStackTree's JSON)

/// MetricKit gives a call stack as a TREE (`jsonRepresentation()`), rooted at
/// the thread's entry and descending through `subFrames` to the crashing
/// frame. On-device frames are never symbolicated — a frame is a binary and an
/// offset, which is what `symbolicatecrash`/`atos` needs and nothing more.
public enum MetricsStack {
  /// The web keeps four frames and 400 characters (`trace`, index.html 3656);
  /// the phone keeps the same, innermost first, joined with ` <- `.
  public static let keptFrames = 4
  public static let maxLength = 400

  /// `Binary+0x1a2b` for each of the innermost frames of the attributed
  /// thread (the first thread when none is attributed). "" when the tree is
  /// empty or not a tree at all — a crash row with no stack still lands.
  public static func frames(fromCallStackTree data: Data) -> String {
    guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let stacks = root["callStacks"] as? [[String: Any]], !stacks.isEmpty else { return "" }
    let chosen = stacks.first { ($0["threadAttributed"] as? Bool) == true } ?? stacks[0]
    guard let roots = chosen["callStackRootFrames"] as? [[String: Any]] else { return "" }
    var path: [String] = []
    var level: [[String: Any]] = roots
    while let f = heaviest(level) {
      path.append(render(f))
      level = f["subFrames"] as? [[String: Any]] ?? []
    }
    return join(path)
  }

  /// The innermost `keptFrames` of an outer-to-inner path, innermost first,
  /// capped at `maxLength` — the same truncation the web applies.
  public static func join(_ outerToInner: [String]) -> String {
    let inner = outerToInner.suffix(keptFrames).reversed()
    return String(inner.joined(separator: " <- ").prefix(maxLength))
  }

  /// When a level forks (a sampled hang can), follow the branch that carried
  /// the most samples; a crash tree has one branch.
  private static func heaviest(_ frames: [[String: Any]]) -> [String: Any]? {
    frames.max { (($0["sampleCount"] as? Int) ?? 0) < (($1["sampleCount"] as? Int) ?? 0) }
  }

  private static func render(_ f: [String: Any]) -> String {
    let name = (f["binaryName"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "?"
    let offset = (f["offsetIntoBinaryTextSegment"] as? Int) ?? 0
    return "\(name)+0x\(String(offset, radix: 16))"
  }
}
