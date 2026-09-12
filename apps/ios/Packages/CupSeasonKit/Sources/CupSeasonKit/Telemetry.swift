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
// D234 · EVERY row carries `props.platform`, stamped here and only here. The
// web's `qaEvent` stamps `'web'` in exactly the same one place. Before this,
// four callers wrote it by hand and nothing else did, so no event in
// `client_events` could be split by client — the phone's rows and the web's
// were the same rows. Preflight check 22 fails the push if anyone stamps
// their own again.
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

  /// D234 · the four events the overhaul is measured by. Until these exist no
  /// claim in the design set is checkable: nobody can say what a golfer saw on
  /// Home, whether a door was tapped, or whether anything followed it.
  ///
  /// `app_open` fires once per FOREGROUND (`AppOpenGate`), `home_state_seen`
  /// once per Home render with the state's letter, `cta_tapped` with the door
  /// that was pressed, and `first_act` the first consequential thing an
  /// account ever does. None of them carries a name, a handle or an email —
  /// the file's own rule, unchanged.
  public enum Metric: String, Sendable {
    case appOpen = "app_open"
    case homeStateSeen = "home_state_seen"
    case ctaTapped = "cta_tapped"
    case firstAct = "first_act"
  }

  /// The client this row came from. Stamped CENTRALLY, on every row, by
  /// `event(_:_:)` — never by a caller.
  ///
  /// D234: it was hand-written in four places and nowhere else, so the founder's
  /// desk could not split ANY event by client and the two clients' rows were
  /// indistinguishable in `client_events`. A caller-written value is now
  /// overwritten rather than merged (see `stamped`), and preflight check 22
  /// fails the push on a literal `"platform"` key anywhere but this file.
  public static let platform = "ios"

  /// Pure, so the rule is a test rather than a comment: whatever the caller
  /// passed, the row carries this client's `platform`. A caller that writes
  /// its own is OVERWRITTEN — the stamp is the one place this is decided, and
  /// two clients disagreeing about their own names is the defect this closes.
  public static func stamped(_ props: [String: JSONValue]) -> [String: JSONValue] {
    var p = props
    p["platform"] = .string(platform)
    return p
  }

  /// `CFBundleVersion` as a number, 0 when unstamped (tests, previews).
  public static let build: Int = Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "") ?? 0

  struct Row: Encodable { let event: String; let props: JSONValue }

  /// Fire-and-forget. Never throws, never blocks the caller, and a burst of
  /// the same name+props inside two seconds writes one row.
  public static func event(_ name: String, _ props: [String: JSONValue] = [:]) {
    // The stamp goes on BEFORE the key, so the row that is written and the
    // row the window remembers are the same row. The window itself is
    // unchanged: `platform` is a constant on every key, so it collapses no
    // burst that was not already collapsing and splits none that was not.
    #if DEBUG
    return
    #endif
    let stampedProps = stamped(props)
    let key = TelemetryDedupe.key(name, stampedProps)
    let row = Row(event: name, props: .object(stampedProps))
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

  /// `app_open`, once per foreground (D234). Called from the scene phase, so
  /// the gate lives on the main actor beside it.
  @MainActor private static var openGate = AppOpenGate()

  /// The scene came forward. Writes at most one `app_open` per foreground.
  @MainActor public static func sceneBecameActive() {
    guard openGate.foreground() else { return }
    event(Metric.appOpen.rawValue, ["build": .number(Double(build))])
  }

  /// The scene went to the background — the next `.active` is a new open.
  @MainActor public static func sceneEnteredBackground() { openGate.background() }

  private static let dedupe = TelemetryDedupeActor()
}

// MARK: - once per foreground

/// SwiftUI hands a scene FOUR phases and `.active` arrives more often than a
/// golfer opens the app: a notification banner, the app switcher, a share
/// sheet from another app and Face ID all pass through `.inactive` and back.
/// Counting those as opens would inflate the one number every funnel in the
/// design set is divided by. Only a trip through `.background` re-arms.
///
/// Pure, so "once per foreground" is a test rather than a comment.
public struct AppOpenGate: Sendable {
  private var armed = true
  public init() {}

  /// true exactly once per foreground.
  public mutating func foreground() -> Bool {
    defer { armed = false }
    return armed
  }

  /// The app left the screen; the next foreground counts again.
  public mutating func background() { armed = true }
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

/// MetricKit gives a call stack as a TREE (`jsonRepresentation()`) that is
/// UPSIDE DOWN: `callStackRootFrames` is the innermost frame — the crash site
/// (`__pthread_kill`, the hang's busy frame) — and each `subFrames` step is
/// that frame's CALLER, walking out toward `main` and `start`. The first
/// build of this walk read it the other way and kept the tail, so every crash
/// row named `dyld` and `main` and dropped the one frame worth chasing. On-
/// device frames are never symbolicated — a frame is a binary and an offset,
/// which is what `symbolicatecrash`/`atos` needs and nothing more.
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
    // root → subFrames is inner → outer; stop once the kept frames are in hand
    var path: [String] = []
    var level: [[String: Any]] = roots
    while path.count < keptFrames, let f = heaviest(level) {
      path.append(render(f))
      level = f["subFrames"] as? [[String: Any]] ?? []
    }
    return join(path)
  }

  /// The first `keptFrames` of an inner-to-outer path, in that order (the
  /// crash site first), capped at `maxLength` — the same truncation the web
  /// applies.
  public static func join(_ innerToOuter: [String]) -> String {
    String(innerToOuter.prefix(keptFrames).joined(separator: " <- ").prefix(maxLength))
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
