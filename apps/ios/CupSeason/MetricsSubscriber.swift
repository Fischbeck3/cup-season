// Cup Season — the phone's crash source (IOS-024). MetricKit hands the app
// its own crash and hang diagnostics on the NEXT launch, at most once a day,
// already collected by the OS; each one becomes a `client_error` row in
// `client_events` shaped like the web's (`kind`, `msg`, `stack`) plus what a
// phone crash needs to be chased (`signal`, `exception`, `build`, `os`).
//
// Why MetricKit and nothing else: a Swift trap (`fatalError`, an unwrapped
// nil, an out-of-bounds index) is a SIGTRAP/SIGILL, not an NSException, so
// `NSSetUncaughtExceptionHandler` never sees it; and even for an ObjC
// exception the handler runs on a dying process where an async network
// insert cannot complete. There is no top-level `Task` error hook in Swift —
// an unhandled error in a Task is the Task's result, not a process event.
// So the OS records the crash, and the app reports it when it is next alive.
//
// The subscriber is `nonisolated`: MetricKit does not promise a thread, and
// `CSTelemetry.event` is safe from any of them. The diagnostic objects are
// read here, synchronously, and only plain values leave this file.

import Foundation
import MetricKit
import CupSeasonKit

final class MetricsSubscriber: NSObject, MXMetricManagerSubscriber, Sendable {
  func start() { MXMetricManager.shared.add(self) }

  /// The per-day metrics payload (launch times, hang rates) — not stored;
  /// the floor is crashes and hangs, not a metrics warehouse.
  nonisolated func didReceive(_ payloads: [MXMetricPayload]) {}

  nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
    for payload in payloads {
      for crash in payload.crashDiagnostics ?? [] { CSTelemetry.event(CSTelemetry.clientError, Self.props(crash: crash)) }
      for hang in payload.hangDiagnostics ?? [] { CSTelemetry.event(CSTelemetry.clientError, Self.props(hang: hang)) }
    }
  }

  // MARK: - the row shapes

  /// `{kind:"crash", msg, signal?, exception?, stack, build, os, device}`
  static func props(crash d: MXCrashDiagnostic) -> [String: JSONValue] {
    var p = base(kind: "crash", d)
    if let s = d.signal?.intValue { p["signal"] = .number(Double(s)) }
    if let t = d.exceptionType?.intValue { p["exception"] = .number(Double(t)) }
    if let c = d.exceptionCode?.intValue { p["exception_code"] = .number(Double(c)) }
    if let reason = d.exceptionReason {
      // the class + selector names code, never a person; composedMessage can
      // carry object descriptions, so it stays out
      p["exception_name"] = .string(String(reason.exceptionName.prefix(80)))
      p["exception_class"] = .string(String(reason.className.prefix(80)))
    }
    if let term = d.terminationReason, !term.isEmpty { p["termination"] = .string(String(term.prefix(120))) }
    p["msg"] = .string(Self.crashMessage(signal: d.signal?.intValue, exception: d.exceptionType?.intValue,
                                         name: d.exceptionReason?.exceptionName, termination: d.terminationReason))
    return p
  }

  /// `{kind:"hang", msg, duration_s, stack, build, os, device}`
  static func props(hang d: MXHangDiagnostic) -> [String: JSONValue] {
    var p = base(kind: "hang", d)
    let secs = d.hangDuration.converted(to: .seconds).value
    p["duration_s"] = .number((secs * 10).rounded() / 10)
    p["msg"] = .string("hang: \(String(format: "%.1f", secs))s on the main thread")
    return p
  }

  private static func base(kind: String, _ d: MXDiagnostic) -> [String: JSONValue] {
    let stack: String
    if let crash = d as? MXCrashDiagnostic { stack = MetricsStack.frames(fromCallStackTree: crash.callStackTree.jsonRepresentation()) }
    else if let hang = d as? MXHangDiagnostic { stack = MetricsStack.frames(fromCallStackTree: hang.callStackTree.jsonRepresentation()) }
    else { stack = "" }
    // the build the diagnostic came from, not the one reporting it — a crash
    // is reported on the next launch, which may be an update
    let build = Int(d.metaData.applicationBuildVersion) ?? CSTelemetry.build
    return [
      "kind": .string(kind),
      "stack": .string(stack),
      "build": .number(Double(build)),
      "os": .string(d.metaData.osVersion),
      "device": .string(d.metaData.deviceType),
    ]
  }

  /// The desk shows the first 120 characters of props — lead with what matters.
  static func crashMessage(signal: Int?, exception: Int?, name: String?, termination: String?) -> String {
    var parts: [String] = []
    if let name, !name.isEmpty { parts.append(name) }
    if let signal { parts.append("signal \(signal)" + (signalName(signal).map { " (\($0))" } ?? "")) }
    if let exception { parts.append("exception \(exception)") }
    if parts.isEmpty, let termination, !termination.isEmpty { parts.append(String(termination.prefix(80))) }
    return "crash: " + (parts.isEmpty ? "no signal recorded" : parts.joined(separator: " · "))
  }

  private static func signalName(_ s: Int) -> String? {
    switch s {
    case 4: "SIGILL"
    case 5: "SIGTRAP"
    case 6: "SIGABRT"
    case 9: "SIGKILL"
    case 10: "SIGBUS"
    case 11: "SIGSEGV"
    default: nil
    }
  }
}
