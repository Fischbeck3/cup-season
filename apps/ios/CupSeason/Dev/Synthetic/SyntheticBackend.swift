// Cup Season — the synthetic router. Every request the app makes in a
// `-cs_dev_synthetic` launch lands here, is classified the way Supabase would
// route it (auth · PostgREST RPC · PostgREST table · storage · functions), has
// the scenario's policy applied (offline, one failure per read, a held read),
// and is answered from `SyntheticWorld` — or fails LOUDLY as a MISS.
//
// Writes are answered too, deterministically and on the device: a synthetic
// post, comment or setting change "succeeds" the way the fixture says it does,
// is logged as WRITE, and reaches nothing. See `SyntheticWorld.write(_:)`.

#if DEBUG
import Foundation
import CupSeasonKit

/// One request, as the router reads it.
struct SynthRequest: @unchecked Sendable {
  enum Kind: Equatable {
    case rpc(String)
    case table(String)
    case storageSign(bucket: String, path: String?)
    case storageObject(bucket: String, path: String)
    case function(String)
    case auth(String)
    case asset(String)
  }
  let method: String
  let url: URL
  let kind: Kind
  let query: [String: [String]]
  let headers: [String: String]
  let body: Data?

  init(_ r: URLRequest, _ body: Data?) {
    method = r.httpMethod ?? "GET"   // URLRequest already carries it in capitals
    url = r.url ?? SyntheticSeam.supabaseURL
    headers = r.allHTTPHeaderFields ?? [:]
    self.body = body
    var q: [String: [String]] = [:]
    for item in URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? [] {
      q[item.name, default: []].append(item.value ?? "")
    }
    query = q
    let p = url.path
    func tail(after prefix: String) -> String { String(p.dropFirst(prefix.count)) }
    if p.hasPrefix("/rest/v1/rpc/") { kind = .rpc(tail(after: "/rest/v1/rpc/")) }
    else if p.hasPrefix("/rest/v1/") { kind = .table(tail(after: "/rest/v1/")) }
    else if p.hasPrefix("/storage/v1/object/sign/") || p.hasPrefix("/storage/v1/render/image/sign/") {
      let rest = p.hasPrefix("/storage/v1/object/sign/") ? tail(after: "/storage/v1/object/sign/") : tail(after: "/storage/v1/render/image/sign/")
      let parts = rest.split(separator: "/", maxSplits: 1).map(String.init)
      // A GET with a token is the DOWNLOAD of a signed URL; a POST mints one.
      if method == "GET", url.query?.contains("token=") == true, parts.count == 2 {
        kind = .storageObject(bucket: parts[0], path: parts[1])
      } else {
        kind = .storageSign(bucket: parts.first ?? "", path: parts.count > 1 ? parts[1] : nil)
      }
    }
    else if p.hasPrefix("/storage/v1/object/") {
      let parts = tail(after: "/storage/v1/object/").split(separator: "/", maxSplits: 1).map(String.init)
      let bucketed = parts.first == "public" || parts.first == "authenticated" ? Array(parts.dropFirst()) : parts
      kind = .storageObject(bucket: bucketed.first ?? "", path: bucketed.count > 1 ? bucketed[1] : "")
    }
    else if p.hasPrefix("/functions/v1/") { kind = .function(tail(after: "/functions/v1/")) }
    else if p.hasPrefix("/auth/v1/") { kind = .auth(tail(after: "/auth/v1/")) }
    else { kind = .asset(url.absoluteString) }
  }

  /// The JSON body, when there is one.
  var json: Any? {
    guard let body, !body.isEmpty else { return nil }
    return try? JSONSerialization.jsonObject(with: body, options: [.fragmentsAllowed])
  }
  /// RPC params / an insert's row.
  var params: [String: Any] { (json as? [String: Any]) ?? [:] }
  func string(_ key: String) -> String? { params[key] as? String }
  func int(_ key: String) -> Int? { (params[key] as? NSNumber)?.intValue }

  /// `?col=eq.value` → "value" for the first filter on `col`.
  func filter(_ col: String) -> String? {
    guard let v = query[col]?.first else { return nil }
    if let dot = v.firstIndex(of: ".") { return String(v[v.index(after: dot)...]) }
    return v
  }
  /// `?col=in.(a,b)` → [a, b]
  func filterList(_ col: String) -> [String] {
    guard let v = filter(col) else { return [] }
    let trimmed = v.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
    return trimmed.split(separator: ",").map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\" ")) }
  }
  var wantsObject: Bool { (headers["Accept"] ?? headers["accept"] ?? "").contains("vnd.pgrst.object") }
  var label: String {
    switch kind {
    case .rpc(let n): "rpc/\(n)"
    case .table(let t): "\(method) \(t)"
    case .storageSign(let b, let p): "storage/sign/\(b)/\(p ?? "*")"
    case .storageObject(let b, let p): "storage/object/\(b)/\(p)"
    case .function(let f): "functions/\(f)"
    case .auth(let a): "auth/\(a)"
    case .asset(let u): "asset \(u)"
    }
  }
}

/// What a handler hands back.
enum SynthOut {
  static func encode(_ any: Any) -> Data {
    if any is NSNull { return Data("null".utf8) }
    return (try? JSONSerialization.data(withJSONObject: any, options: [.sortedKeys, .fragmentsAllowed])) ?? Data("null".utf8)
  }
  static func json(_ any: Any, status: Int = 200) -> SyntheticReply {
    SyntheticReply(status: status, body: encode(any))
  }
  /// PostgREST's answer to a table read: an array, or an object under
  /// `.single()`, or only a count under `head: true`.
  static func rows(_ rows: [[String: Any]], _ r: SynthRequest) -> SyntheticReply {
    var headers = ["Content-Type": "application/json", "Content-Range": rows.isEmpty ? "*/0" : "0-\(rows.count - 1)/\(rows.count)"]
    if r.method == "HEAD" { return SyntheticReply(status: 200, headers: headers, body: Data()) }
    if r.wantsObject {
      guard let first = rows.first else {
        return error("JSON object requested, multiple (or no) rows returned", code: "PGRST116", status: 406)
      }
      headers["Content-Type"] = "application/vnd.pgrst.object+json"
      return SyntheticReply(status: 200, headers: headers, body: encode(first))
    }
    return SyntheticReply(status: 200, headers: headers, body: encode(rows))
  }
  static let void = SyntheticReply(status: 204, headers: [:], body: Data())
  static func error(_ message: String, code: String = "FX500", status: Int = 500) -> SyntheticReply {
    json(["code": code, "message": message, "details": NSNull(), "hint": NSNull()], status: status)
  }
  static func bytes(_ data: Data, type: String) -> SyntheticReply {
    SyntheticReply(status: 200, headers: ["Content-Type": type, "Content-Length": "\(data.count)"], body: data)
  }
}

/// The router and its policies. One per launch.
final class SyntheticBackend: @unchecked Sendable {
  let world: SyntheticWorld
  private let lock = NSLock()
  private let booted = Date()
  /// failures policy: when each read last failed, and which ones are spent.
  private var lastFail: [String: Date] = [:]
  private var spent: Set<String> = []

  init(world: SyntheticWorld) { self.world = world }

  private static let args = ProcessInfo.processInfo.arguments
  private static func arg(_ name: String) -> String? {
    guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
    return args[i + 1]
  }
  private let delay = Double(SyntheticBackend.arg("-cs_synth_delay") ?? "") ?? 0
  private let reconnectAfter = Double(SyntheticBackend.arg("-cs_synth_reconnect_after") ?? "")
  private let failList: Set<String>? = SyntheticBackend.arg("-cs_synth_fail").map { Set($0.split(separator: ",").map(String.init)) }

  /// The reads a boot needs. In `failures` they succeed unless named, so the
  /// failure lands on the ROUTE's own read and not on the door.
  private static let bootReads: Set<String> = ["native_home", "founding_ids", "founder_id", "league_looks", "door_flags"]

  func respond(_ request: URLRequest, _ body: Data?) -> SyntheticReply {
    let r = SynthRequest(request, body)
    let key = r.label

    // 1 · no signal. The one exemption is the course books the boot seeds
    // (`SyntheticBoot`): books a phone kept on an earlier, connected day.
    if world.scenario == .offline, key != "rpc/my_course_books" {
      let back = reconnectAfter.map { Date().timeIntervalSince(booted) >= $0 } ?? false
      if !back {
        SyntheticSeam.log("OFFLINE \(key)")
        return SyntheticReply(error: .notConnectedToInternet)
      }
    }

    // 2 · answer it
    let isWrite = world.isWrite(r)
    guard var reply = world.answer(r) else {
      SyntheticSeam.log("MISS \(key) body=\(String(data: r.body ?? Data(), encoding: .utf8)?.prefix(300) ?? "")")
      SyntheticStats.record(miss: true)
      return SynthOut.error("The fixture has no answer for \(key).", code: "FX404", status: 500)
    }

    // 3 · one failure per read, then the retry lands
    if !isWrite, shouldFail(r) {
      SyntheticSeam.log("FAIL \(key) (first attempt; the retry succeeds)")
      SyntheticStats.record(miss: false)
      // 500, not 503: the SDK retries a GET on 503/520 by itself, and the
      // failure has to reach the screen for its retry to be the golfer's.
      return SynthOut.error("Could not load this right now.", code: "FX500", status: 500)
    }

    // 4 · a held read shows the loading geometry
    if !isWrite, delay > 0 { reply.delay = delay }
    SyntheticSeam.log("\(isWrite ? "WRITE" : "HIT") \(key) \(reply.status)\(isWrite ? " (answered on device)" : "")")
    return reply
  }

  /// `failures`: a read fails on its first attempt — and on any retry the
  /// client fires within a second of that (the skew retry) — and succeeds on
  /// the next attempt. Named reads only when `-cs_synth_fail` names them.
  private func shouldFail(_ r: SynthRequest) -> Bool {
    let name: String
    switch r.kind {
    case .rpc(let n): name = n
    case .table(let t): name = t.components(separatedBy: "?").first ?? t
    case .storageSign, .storageObject: name = "storage"
    case .function(let f): name = f
    case .auth, .asset: return false
    }
    if let list = failList {
      guard list.contains(name) || list.contains("all") else { return false }
    } else {
      guard world.scenario == .failures, !Self.bootReads.contains(name) else { return false }
    }
    lock.lock(); defer { lock.unlock() }
    if spent.contains(name) { return false }
    if let last = lastFail[name] {
      if Date().timeIntervalSince(last) < 1.0 { lastFail[name] = Date(); return true }
      spent.insert(name)
      return false
    }
    lastFail[name] = Date()
    return true
  }
}
#endif
